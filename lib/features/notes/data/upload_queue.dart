import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/local_file.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/settings_providers.dart';
import '../presentation/notes_providers.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import 'attachment_repository.dart';
import 'drive_store.dart';
import 'note_shares_repository.dart';
import 'notes_repository.dart';

/// Bir ekin buluttaki HEDEFİ.
enum UploadTarget {
  /// Firebase Storage (web, ve ortak çalışanların görmesi gereken
  /// paylaşılan notlar).
  storage,

  /// Kullanıcının Google Drive'ı (Google hesabının kendi notları).
  drive,
}

/// Notun eklerinin nereye gideceği; null = hiçbir yere (yalnız bu cihaz).
///
/// Kullanıcı isteği 2026-10-15: "Google ile giriş yapanlarda Drive kotası,
/// diğerlerinde yalnız metin senkronu". [shared]: not başkalarıyla
/// paylaşılıyor (ortak not ya da paylaşılan klasör) — ortak çalışan benim
/// Drive'ıma erişemez, o notun ekleri Storage'a gider.
UploadTarget? uploadTargetFor({
  required AttachmentSyncMode mode,
  required bool localOnly,
  required bool shared,
}) {
  if (localOnly) return null;
  return switch (mode) {
    AttachmentSyncMode.storage => UploadTarget.storage,
    AttachmentSyncMode.textOnly => null,
    AttachmentSyncMode.drive =>
      shared ? UploadTarget.storage : UploadTarget.drive,
  };
}

/// Ek, [target] hedefinde ZATEN var mı.
bool syncedTo(Attachment a, UploadTarget target) => switch (target) {
  UploadTarget.storage => a.isUploaded,
  UploadTarget.drive => a.isInDrive,
};

/// Benim paylaştığım notların ve klasörlerin kimlikleri — "bu notu başkası
/// da görüyor mu" sorusunun tek kaynağı (kuyruk ve gösterge aynı kuralı
/// kullanır).
({Set<String> notes, Set<String> folders}) _sharedByMe(Ref ref) => (
  notes: ref.watch(myNoteSharesProvider).value?.keys.toSet() ?? const {},
  folders: {
    for (final f in ref.watch(foldersStreamProvider).value ?? const [])
      if (f.isShared) f.id,
  },
);

bool _isShared(Note note, ({Set<String> notes, Set<String> folders}) shared) =>
    shared.notes.contains(note.id) ||
    (note.folderId != null && shared.folders.contains(note.folderId));

/// Bekleyen ekleri arka planda Firebase Storage'a taşıyan kuyruk.
/// Not akışını ve bağlantı durumunu izler; yüklenmemiş yerel eki olan her
/// notu yakalayıp sırayla yükler. Dashboard açıkken kendiliğinden çalışır.
final uploadQueueProvider = Provider<UploadQueue>((ref) {
  final queue = UploadQueue(ref);
  ref.onDispose(queue.dispose);
  queue.start();
  return queue;
});

/// Yüklenemeyen ekler: ek id'si → ARKA ARKAYA başarısız deneme sayısı.
///
/// Kuyruk kalıcı hatada (Storage kural reddi, bozuk dosya) sessizce yeniden
/// denemeye devam ediyordu; arayüzde ise ilk günden beri aynı dönen çark
/// vardı, yani kullanıcı "yükleniyor" ile "hiç yüklenmeyecek"i ayırt
/// edemiyor ve elle müdahale edemiyordu.
///
/// Anahtar ek id'si (uuid): not id'siyle birleşik anahtar kuyruğun İÇİNDE
/// kalır — şeride kadar `noteId` taşımak iki widget katmanını değiştirmek
/// demekti, ek id'leri zaten benzersiz.
final uploadFailuresProvider =
    NotifierProvider<UploadFailuresNotifier, Map<String, int>>(
      UploadFailuresNotifier.new,
    );

class UploadFailuresNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};

  void fail(String attachmentId, int attempts) =>
      state = {...state, attachmentId: attempts};

  void clear(String attachmentId) {
    if (!state.containsKey(attachmentId)) return;
    state = {...state}..remove(attachmentId);
  }

  /// Silinen notların/eklerin artığı birikmesin.
  void retain(Set<String> liveIds) {
    if (state.keys.every(liveIds.contains)) return;
    state = {
      for (final entry in state.entries)
        if (liveIds.contains(entry.key)) entry.key: entry.value,
    };
  }
}

/// **BU CİHAZDA yüklenmeyi bekleyen ek sayısı** (kullanıcı isteği
/// 2026-09-23: "çevrimdışı durum — senkron bekleyen ekler için belirgin
/// gösterge"). Kuyruğun kendi süzgeciyle aynı kural: video buluta gitmez,
/// senkron sınırını aşan ek cihazda kalır; dosyası BU cihazda olmayan ek
/// (başka cihazın henüz yüklemediği) bu cihazın işi değil, sayılmaz.
///
/// `failed`: en az bir kez yüklenemeyenler (bağlantı yok, kural reddi) —
/// gösterge bunları ayrı söyler.
///
/// `needsDrive`: Google hesabı ama Drive henüz BAĞLANMADI — bekleyenler
/// bağlantı bekliyor; gösterge "Bağla" der (misafir hesapta ekler zaten
/// buluta gitmez, sayılmaz).
final pendingUploadsProvider =
    Provider<({int pending, int failed, bool needsDrive})>((ref) {
      final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
      final failures = ref.watch(uploadFailuresProvider);
      final limitMb = ref.watch(syncLimitMbProvider);
      final limitBytes = limitMb <= 0 ? null : limitMb * 1024 * 1024;
      final mode = ref.watch(attachmentSyncModeProvider);
      final driveReady = ref.watch(driveConnectedProvider);
      final shared = _sharedByMe(ref);
      var pending = 0;
      var failed = 0;
      var waitingDrive = false;
      for (final note in notes) {
        final target = uploadTargetFor(
          mode: mode,
          localOnly: note.localOnly,
          shared: _isShared(note, shared),
        );
        if (target == null) continue;
        for (final a in note.attachments) {
          if (a.kind == AttachmentKind.video || syncedTo(a, target)) continue;
          if (limitBytes != null && a.sizeBytes > limitBytes) continue;
          if (!localFileExists(a.localPath)) continue;
          pending++;
          if (failures.containsKey(a.id)) failed++;
          if (target == UploadTarget.drive && !driveReady) waitingDrive = true;
        }
      }
      return (pending: pending, failed: failed, needsDrive: waitingDrive);
    });

/// BAŞKASININ koleksiyonunda yaşayıp BENİM düzenleyebildiğim notlar: ortak
/// notlar ve yazma yetkim olan paylaşılan klasörlerin notları.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-09-23: "ortak nottaki görsel sorunu"):
/// kuyruk yalnız KENDİ not akışımı tarıyordu. Paylaşılan nota eklediğim
/// görsel cihazımda "yüklenmeyi bekliyor" olarak sonsuza dek kalıyor, notun
/// sahibi ve diğer ortak çalışanlar onu hiç göremiyordu. Bu notların
/// bekleyen ekleri de artık yüklenir — sahibin Storage yoluna
/// (`AttachmentRepository.forOwner`) ve sahibin dokümanına.
///
/// Başkasının eklediği ekin `localPath`'i onun cihazını gösterir; bu cihazda
/// dosya olmadığı için `upload` onu zaten atlar — yalnız BENİM eklediklerim
/// yüklenir.
final foreignEditableNotesProvider =
    Provider<List<({String ownerId, Note note})>>((ref) {
      final out = <({String ownerId, Note note})>[];
      for (final share
          in ref.watch(sharedNotesWithMeProvider).value ??
              const <NoteShare>[]) {
        final note = ref
            .watch(
              ownedNoteStreamProvider((
                ownerId: share.ownerId,
                noteId: share.noteId,
              )),
            )
            .value;
        if (note != null) out.add((ownerId: share.ownerId, note: note));
      }
      for (final folder
          in ref.watch(sharedFolderRefsProvider).value ??
              const <SharedFolderRef>[]) {
        // Yalnız okuyup yazabildiğim klasör: salt-okurda eklenecek bir şey
        // yok, salt-yazarda notlar okunamıyor (kural reddeder).
        if (!folder.role.canRead || !folder.role.canWrite) continue;
        for (final note
            in ref
                    .watch(
                      sharedFolderNotesProvider((
                        ownerId: folder.ownerId,
                        folderId: folder.folderId,
                      )),
                    )
                    .value ??
                const <Note>[]) {
          out.add((ownerId: folder.ownerId, note: note));
        }
      }
      return out;
    });

class UploadQueue {
  UploadQueue(this._ref);

  final Ref _ref;
  final Set<String> _inFlight = {};

  /// Son başarısız deneme + deneme sayısı (ek başına): not akışı her tuş
  /// vuruşunda snapshot ürettiğinden, kalıcı olarak başarısız bir yükleme
  /// aralıksız yeniden denenip ağ/pil yakıyordu. Bekleme ÜSTEL büyür
  /// (1-2-4-… dk, tavan 6 saat): bozuk dosya/kural reddi gibi hiç
  /// düzelmeyecek bir hata sabit 1 dk'da bir Storage'a tam yükleme denemesi
  /// yapıyordu. Bağlantı gelince connectivity tetiği yine dener; kalıcı "pes
  /// et" YOK — geçici hatayı kalıcıdan istemcide ayırt edemeyiz, 6 saatlik
  /// tavan zaten zararsız.
  final Map<String, ({DateTime at, int attempts})> _lastFailure = {};
  static const _baseRetryDelay = Duration(minutes: 1);
  static const _maxRetryDelay = Duration(hours: 6);

  Duration _retryDelayFor(int attempts) {
    final scaled = _baseRetryDelay * (1 << (attempts - 1).clamp(0, 12));
    return scaled > _maxRetryDelay ? _maxRetryDelay : scaled;
  }

  ProviderSubscription<AsyncValue<List<Note>>>? _notesSub;
  ProviderSubscription<List<({String ownerId, Note note})>>? _foreignSub;
  Timer? _foreignDebounce;
  ProviderSubscription<int>? _limitSub;
  ProviderSubscription<DriveStore?>? _driveSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// KÖK NEDEN (kasma): not akışı HER TUŞ VURUŞUNDA anlık görüntü üretiyor
  /// (dosyanın başındaki nota bak) ve [_process] her seferinde tüm notlar ×
  /// tüm ekler üzerinde küme kurup haritalar tahsis ediyordu. Yazarken bu,
  /// karakter başına binlerce dizgi birleştirme ve GC baskısı demekti.
  /// Tarama artık geciktiriliyor: yükleme birkaç saniye sonra başlasa da
  /// kullanıcı bunu görmez, kare kaçırmayı ise görür.
  Timer? _processDebounce;

  void _scheduleProcess(List<Note> notes) {
    _processDebounce?.cancel();
    _processDebounce = Timer(const Duration(seconds: 2), () {
      _process(notes);
    });
  }

  void start() {
    _notesSub = _ref.listen(notesStreamProvider, (previous, next) {
      final notes = next.value;
      if (notes != null) _scheduleProcess(notes);
    }, fireImmediately: true);

    // Sınır yükseltilince bekleyen büyük ekler hemen sıraya girsin (yoksa bir
    // sonraki not değişikliğine kadar cihazda beklerlerdi).
    _limitSub = _ref.listen(syncLimitMbProvider, (previous, next) {
      // Sınır değişimi kullanıcı eylemidir, geciktirilmez.
      final notes = _ref.read(notesStreamProvider).value;
      if (notes != null) _process(notes);
    });

    // Drive bağlanınca bekleyen ekler hemen yola çıksın, öbür cihazın
    // ekleri insin.
    _driveSub = _ref.listen(driveStoreProvider, (previous, next) {
      if (next == null) return;
      final notes = _ref.read(notesStreamProvider).value;
      if (notes != null) _process(notes);
    });

    _foreignSub = _ref.listen(foreignEditableNotesProvider, (previous, next) {
      _foreignDebounce?.cancel();
      _foreignDebounce = Timer(
        const Duration(seconds: 2),
        () => _processForeign(next),
      );
    }, fireImmediately: true);

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        final notes = _ref.read(notesStreamProvider).value;
        if (notes != null) _process(notes);
        _processForeign(_ref.read(foreignEditableNotesProvider));
      }
    });
  }

  /// Paylaşılan notların bekleyen ekleri (bkz. [foreignEditableNotesProvider]).
  /// Kendi notlarımın yolundan tek farkı: dosya ve kayıt notun SAHİBİNE
  /// yazılır. Bekleme/deneme kayıtları aynı haritada tutulur (anahtar not +
  /// ek kimliği, ikisi de benzersiz).
  Future<void> _processForeign(
    List<({String ownerId, Note note})> entries,
  ) async {
    if (entries.isEmpty) return;
    final baseRepo = _ref.read(attachmentRepositoryProvider);
    final me = _ref.read(currentUidProvider);
    if (baseRepo == null || me == null) return;
    for (final (:ownerId, :note) in entries) {
      for (final attachment in note.attachments) {
        if (attachment.kind == AttachmentKind.video) continue;
        if (attachment.isUploaded || attachment.localPath.isEmpty) continue;
        final key = '${note.id}/${attachment.id}';
        final lastFailure = _lastFailure[key];
        if (lastFailure != null &&
            DateTime.now().difference(lastFailure.at) <
                _retryDelayFor(lastFailure.attempts)) {
          continue;
        }
        if (!_inFlight.add(key)) continue;
        try {
          final uploaded = await baseRepo
              .forOwner(ownerId)
              .upload(note.id, attachment);
          if (uploaded != null) {
            await NotesRepository(
              FirebaseFirestore.instance,
              ownerId,
              editorUid: me,
            ).patchAttachment(note.id, uploaded);
          }
          _lastFailure.remove(key);
        } catch (e) {
          final attempts = (lastFailure?.attempts ?? 0) + 1;
          _lastFailure[key] = (at: DateTime.now(), attempts: attempts);
          debugPrint('Paylaşılan notun eki yüklenemedi ($key): $e');
        } finally {
          _inFlight.remove(key);
        }
      }
    }
  }

  /// Kullanıcı "yeniden dene" dedi: üstel bekleme SIFIRLANIR ve kuyruk hemen
  /// tetiklenir. Bekleme tavanı 6 saate tırmanmış bir ekte, kullanıcı sorunu
  /// (kota/kural/bağlantı) düzeltmiş olsa bile saatlerce hiçbir şey olmuyordu.
  void retryNow(String attachmentId) {
    _lastFailure.removeWhere((key, _) => key.endsWith('/$attachmentId'));
    _ref.read(uploadFailuresProvider.notifier).clear(attachmentId);
    final notes = _ref.read(notesStreamProvider).value;
    if (notes != null) unawaited(_process(notes));
  }

  Future<void> _process(List<Note> notes) async {
    final attachmentRepo = _ref.read(attachmentRepositoryProvider);
    final notesRepo = _ref.read(notesRepositoryProvider);
    if (attachmentRepo == null || notesRepo == null) return;
    unawaited(_processDownloads(notes, attachmentRepo));

    // Kullanıcının senkron boyut sınırı (MB, 0 = sınırsız): sınırı aşan ek
    // cihazda kalır, buluta hiç yüklenmez. Ayar değişince bir sonraki not
    // akışı/bağlantı tetiğinde yeniden değerlendirilir.
    final limitMb = _ref.read(syncLimitMbProvider);
    final limitBytes = limitMb <= 0 ? null : limitMb * 1024 * 1024;
    final mode = _ref.read(attachmentSyncModeProvider);
    final driveReady = attachmentRepo.drive != null;
    final shared = (
      notes: _ref.read(myNoteSharesProvider).value?.keys.toSet() ?? <String>{},
      folders: {
        for (final f
            in _ref.read(foldersStreamProvider).value ?? const <NoteFolder>[])
          if (f.isShared) f.id,
      },
    );

    // Silinen notların artıkları birikmesin: harita yalnız hâlâ var olan
    // ekler için kayıt tutar.
    final liveKeys = <String>{
      for (final note in notes)
        for (final attachment in note.attachments)
          '${note.id}/${attachment.id}',
    };
    _lastFailure.removeWhere(
      (key, _) => !liveKeys.contains(key.replaceFirst('dl:', '')),
    );
    _ref.read(uploadFailuresProvider.notifier).retain({
      for (final note in notes)
        for (final attachment in note.attachments) attachment.id,
    });

    // **PARALEL YÜKLEME** (kullanıcı isteği 2026-09-23: "görseller
    // firebase senkronu yapılırken çok gecikiyor"). Ekler eskiden TEK TEK
    // yükleniyordu: altı fotoğraflı bir not, her biri yükleme + indirme
    // adresi + Firestore işlemi (üç gidiş-dönüş) bekleyerek sırayla
    // gidiyordu. Artık aynı anda [_parallelUploads] ek; KÜÇÜK olan önce —
    // görseller PDF/ses kuyruğunun arkasında beklemesin.
    final jobs = <({Note note, Attachment attachment, UploadTarget target})>[];
    for (final note in notes) {
      // HEDEF (2026-10-15): Google hesabı → Drive; paylaşılan not →
      // Storage (ortak çalışan Drive'ıma erişemez); misafir → hiçbir yer;
      // yalnız bu cihazdaki not (LocalNotesStore) → hiçbir yer.
      final target = uploadTargetFor(
        mode: mode,
        localOnly: note.localOnly,
        shared: _isShared(note, shared),
      );
      if (target == null) continue;
      // Drive bağlanmadıysa Drive'a gidecekler bekler (gösterge "Bağla"
      // der) — sessizce Storage'a düşmek kullanıcının kararını yok saymak
      // olurdu.
      if (target == UploadTarget.drive && !driveReady) continue;
      for (final attachment in note.attachments) {
        // Görüntülü not buluta hiç gitmez (yalnızca cihazda saklanır).
        if (attachment.kind == AttachmentKind.video) continue;
        if (syncedTo(attachment, target) || attachment.localPath.isEmpty) {
          continue;
        }
        if (limitBytes != null && attachment.sizeBytes > limitBytes) continue;
        final key = '${note.id}/${attachment.id}';
        final lastFailure = _lastFailure[key];
        if (lastFailure != null &&
            DateTime.now().difference(lastFailure.at) <
                _retryDelayFor(lastFailure.attempts)) {
          continue;
        }
        jobs.add((note: note, attachment: attachment, target: target));
      }
    }
    jobs.sort(
      (a, b) => a.attachment.sizeBytes.compareTo(b.attachment.sizeBytes),
    );
    await _runPool(jobs, (job) async {
      final note = job.note;
      final attachment = job.attachment;
      final key = '${note.id}/${attachment.id}';
      if (!_inFlight.add(key)) return;
      final lastFailure = _lastFailure[key];
      try {
        final uploaded = job.target == UploadTarget.drive
            ? await attachmentRepo.uploadToDrive(note.id, attachment)
            : await attachmentRepo.upload(note.id, attachment);
        if (uploaded != null) {
          await notesRepo.patchAttachment(note.id, uploaded);
        }
        _lastFailure.remove(key);
        _ref.read(uploadFailuresProvider.notifier).clear(attachment.id);
      } catch (e) {
        // Bağlantı yoksa veya yükleme başarısızsa bir sonraki tetikte
        // (üstel bekleme dolduysa) yeniden denenir.
        final attempts = (lastFailure?.attempts ?? 0) + 1;
        _lastFailure[key] = (at: DateTime.now(), attempts: attempts);
        _ref
            .read(uploadFailuresProvider.notifier)
            .fail(attachment.id, attempts);
        debugPrint('Ek yüklenemedi ($key): $e');
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  /// **DRIVE'DAN İNDİRME** — başka cihazda Drive'a yüklenmiş eklerin bu
  /// cihazda yerel kopyası yoksa indirilir. Drive dosyası özeldir (herkese
  /// açık adresi yok); ekranlar yerel kopyadan çizer. İndirme bitince
  /// [localFilesRevisionProvider] artar, kartlar ve editör yeniden bakar.
  Future<void> _processDownloads(
    List<Note> notes,
    AttachmentRepository repo,
  ) async {
    if (kIsWeb || repo.drive == null) return;
    final jobs = <({Note note, Attachment attachment})>[];
    for (final note in notes) {
      if (note.localOnly) continue;
      for (final a in note.attachments) {
        if (!a.isInDrive || a.kind == AttachmentKind.video) continue;
        if (a.localPath.isEmpty || localFileExists(a.localPath)) continue;
        final key = 'dl:${note.id}/${a.id}';
        final lastFailure = _lastFailure[key];
        if (lastFailure != null &&
            DateTime.now().difference(lastFailure.at) <
                _retryDelayFor(lastFailure.attempts)) {
          continue;
        }
        jobs.add((note: note, attachment: a));
      }
    }
    if (jobs.isEmpty) return;
    jobs.sort(
      (a, b) => a.attachment.sizeBytes.compareTo(b.attachment.sizeBytes),
    );
    var fetched = 0;
    await _runPool(jobs, (job) async {
      final key = 'dl:${job.note.id}/${job.attachment.id}';
      if (!_inFlight.add(key)) return;
      final lastFailure = _lastFailure[key];
      try {
        if (await repo.fetchFromDrive(job.attachment)) fetched++;
        _lastFailure.remove(key);
      } catch (e) {
        final attempts = (lastFailure?.attempts ?? 0) + 1;
        _lastFailure[key] = (at: DateTime.now(), attempts: attempts);
        debugPrint('Drive eki indirilemedi ($key): $e');
      } finally {
        _inFlight.remove(key);
      }
    });
    if (fetched > 0) _ref.read(localFilesRevisionProvider.notifier).bump();
  }

  /// Aynı anda en çok kaç ek yüklenir. 3: mobil bağlantıda bant genişliğini
  /// paylaştırıp gidiş-dönüş beklemelerini örtüşür; daha fazlası tek tek
  /// yüklemeleri yavaşlatıp ilk görselin görünmesini geciktirir.
  static const _parallelUploads = 3;

  static Future<void> _runPool<T>(
    List<T> items,
    Future<void> Function(T item) task,
  ) async {
    var next = 0;
    Future<void> worker() async {
      while (next < items.length) {
        final item = items[next++];
        await task(item);
      }
    }

    await Future.wait([
      for (var i = 0; i < _parallelUploads && i < items.length; i++) worker(),
    ]);
  }

  void dispose() {
    _processDebounce?.cancel();
    _notesSub?.close();
    _foreignSub?.close();
    _foreignDebounce?.cancel();
    _limitSub?.close();
    _driveSub?.close();
    _connectivitySub?.cancel();
  }
}
