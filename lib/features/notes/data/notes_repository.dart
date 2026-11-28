import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/crash_reporting.dart';
import '../../../core/error_log.dart';
import '../../../core/personalize.dart';
import '../../../core/sync/sync_outbox.dart';
import '../../../core/utils/diagnostics.dart';
import '../../../core/utils/firestore_size.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/note_e2ee_session.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/attachment.dart';
import '../domain/ink_plan.dart';
import '../domain/list_mode.dart';
import '../domain/note.dart';
import '../domain/note_heavy.dart';
import '../domain/notebook_migration.dart';
import '../domain/note_item.dart';
import '../domain/note_version.dart';
import '../domain/note_type.dart';
import '../domain/routine_reset.dart';
import 'attachment_repository.dart';
import 'drive_store.dart' show driveFileDeleter;
import 'local_notes_store.dart';
import 'note_format_memory.dart';
import 'notes_delta_sync.dart';

part 'notes_repository_helpers.dart';
part 'notes_repository_ops.dart';

/// Şu an bir editörde AÇIK olan notların id'leri; `cleanupEmptyNotes` bunlara
/// dokunmaz. Editör açılırken ekler, kapanırken çıkarır. Provider değil düz
/// bir liste, çünkü değişimi hiçbir arayüzü yeniden çizmemeli.
///
/// LİSTE, küme değil: aynı not (geniş ekranda karta iki kez dokununca) üst
/// üste İKİ editörde açılabiliyor. Kümede ilk kapanan editör id'yi düşürür ve
/// hâlâ açık olan İKİNCİ editörün koruması kalkardı; listede her editör kendi
/// kaydını düşürür, id son editör kapanana dek listede kalır.
final openEditorNoteIds = <String>[];

final notesRepositoryProvider = Provider<NotesRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  // Yalnız KENDİ notlarımın deposu yerel notları bilir (bkz.
  // LocalNotesStore); başkasının koleksiyonuna açılan depolar bilmez.
  final fileJournal = LocalNotesStore.journalFor(uid);
  final webJournal = kIsWeb && fileJournal == null
      ? WebLiteJournal(ref.watch(sharedPreferencesProvider), uid: uid)
      : null;
  return NotesRepository(
    FirebaseFirestore.instance,
    uid,
    local: LocalNotesStore.forUid(uid),
    journal: fileJournal,
    webJournal: webJournal,
  );
});

/// Silinmemiş tüm notların canlı akışı — arşivlenenler DAHİL (yükleme
/// kuyruğu ve arşiv ekranı da bunu kullanır). Dashboard, arşivlenenleri
/// [filteredNotesProvider] içinde ayıklar. Sıralama istemci tarafında
/// yapılır ki bileşik Firestore indeksi gerekmesin.
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  // Günde en fazla bir kez: çöp kutusunda 30 günü doldurmuş notları ekleriyle
  // birlikte kalıcı sil. Her açılışta koşturmak, soğuk başlangıçta ilk
  // senkronla yarışan bir sunucu okuması demekti; süre 30 gün olduğuna göre
  // günlük tarama fazlasıyla yeterli.
  final prefs = ref.watch(sharedPreferencesProvider);
  const purgeKey = 'last_trash_purge_ms';
  final lastPurge = prefs.getInt(purgeKey) ?? 0;
  if (DateTime.now().millisecondsSinceEpoch - lastPurge >
      const Duration(hours: 24).inMilliseconds) {
    unawaited(() async {
      try {
        await repo.purgeOldTrash();
        await prefs.setInt(purgeKey, DateTime.now().millisecondsSinceEpoch);
      } catch (_) {
        // Ağ yoksa sonraki açılışta yeniden denenir.
      }
    }());
  }
  // Boş kalıp unutulmuş notları temizle (editör açıkken uygulama
  // kapatılırsa dispose'daki silme çalışmaz, kalıntı burada gider).
  // Her emisyonda değil, en fazla 30 saniyede bir çalışır.
  var lastCleanup = DateTime.fromMillisecondsSinceEpoch(0);
  // S1 "yalnız değişeni dinle": uzak bayrak + yerel geri alma; kapalıysa
  // bugünkü yol AYNEN (bkz. NotesDeltaFeed). Web'de ListenSource.cache Wasm
  // hatası verebildiğinden standart anlık görüntü akışı kullanılır.
  return repo.watchNotes(delta: !kIsWeb && SyncDeltaFlag.enabled(prefs)).map((
    notes,
  ) {
    final now = DateTime.now();
    // ZAMANLI NOT: her yayında ucuz tarama (O(n), yazım yalnız süresi
    // dolmuş not varsa). Öne gelişte dashboard da çağırır.
    if (expiredNotes(notes, now).isNotEmpty) {
      unawaited(repo.archiveExpired(notes, now: now).catchError((Object _) {}));
    }
    // RUTİN SIFIRLAMA: yeni döneme geçmiş rutin listelerin eski tiklerini
    // temizler (doneDays geçmişini korur, açık editördekini atlar).
    if (RoutineResetEngine.dueResets(notes, now).isNotEmpty) {
      unawaited(
        repo.resetDueRoutines(notes, now: now).catchError((Object _) {}),
      );
    }
    if (now.difference(lastCleanup) > const Duration(seconds: 30)) {
      lastCleanup = now;
      unawaited(
        Future(() => repo.cleanupEmptyNotes(notes)).catchError((Object _) {}),
      );
    }
    return notes;
  });
});

/// Notlar üzerindeki tüm Firestore işlemleri. Yazımlar bilinçli olarak
/// beklenmez (fire-and-forget): yerel önbellek anında güncellenir, SDK
/// bağlantı gelince arka planda senkronlar — kesintisiz otomatik senkronun
/// temeli budur.
class NotesRepository {
  /// Son DOĞAN notun kimliği (hangi yoldan olursa olsun: "+", şablon, ses,
  /// paylaşım, tarama, içe aktarma). Editör kapanırken bu notsa ve boş
  /// atılmadıysa ana ekran kartı odaklar (bkz. `NoteEditorScreen.dispose`,
  /// `focusedNoteProvider`). Tek yer: her oluşturma yoluna ayrı yama yok.
  static String? lastCreatedId;

  /// Son kurulan S1 akışı (tanı/test; bayrak kapalıyken null).
  static NotesDeltaFeed? lastFeed;

  /// Çöp kutusunda notların kalma süresi.
  static const trashRetention = Duration(days: 30);

  NotesRepository(
    this._firestore,
    this.uid, {
    String? editorUid,
    this.local,
    this.journal,
    this.webJournal,
  }) : editorUid = editorUid ?? uid;

  /// YALNIZ BU CİHAZDA tutulan notlar (bkz. [LocalNotesStore]). Doluysa her
  /// yazım kimliğe bakar: yerel notun yazımı Firestore'a HİÇ gitmez.
  final LocalNotesStore? local;

  /// [noteId] yalnız bu cihazda mı tutuluyor?
  bool isLocal(String noteId) => local?.contains(noteId) ?? false;

  /// **LITE KAYIT GÜNLÜĞÜ** (bkz. `lite_sync.dart`): editörün buluta henüz
  /// yazmadığı içeriğin diskteki kopyası. Mobilde [journal] (`LocalNotesStore`),
  /// Web'de [webJournal] (`WebLiteJournal` — tarayıcı kalıcı deposu) kullanılır.
  /// Her tam not yazımı ([updateNote]) notun girdisini siler: günlükte kalan =
  /// buluta ulaşmamış yazı.
  final LocalNotesStore? journal;
  final WebLiteJournal? webJournal;

  /// Lite seyreltmesinin güvenli olması için günlük hazır mı (mobil dosya
  /// günlüğü ya da Web kalıcı toplu yazım günlüğü).
  bool get canJournal => journal != null || webJournal != null;

  /// Notun bulutta bekleyen hâlini diske / Web günlüğüne yazar (çökmeye karşı).
  void journalNote(Note note) {
    final map = note.toMap();
    if (journal != null) {
      journal!.put(note.id, map);
    } else {
      webJournal?.put(note.id, map);
    }
  }

  /// Bulut akışını yerel depoyla birleştirir: bulut ilk kez yayınlayınca ve
  /// sonra iki kaynaktan biri değiştikçe [merge] yeniden çalışır. Yerel
  /// depo yoksa bulut akışı olduğu gibi döner.
  Stream<T> _withLocal<C, T>(Stream<C> cloud, T Function(C cloud) merge) {
    final store = local;
    if (store == null) return cloud.map(merge);
    late StreamController<T> controller;
    StreamSubscription<C>? cloudSub;
    StreamSubscription<void>? localSub;
    var hasCloud = false;
    late C last;
    controller = StreamController<T>(
      onListen: () {
        cloudSub = cloud.listen((value) {
          last = value;
          hasCloud = true;
          controller.add(merge(value));
        }, onError: controller.addError);
        localSub = store.changes.listen((_) {
          // Bulut henüz yayınlamadıysa bekle: yalnız yerel notlarla dolu
          // bir ilk kare (ve ardından sıçrama) olmasın.
          if (hasCloud) controller.add(merge(last));
        });
      },
      onCancel: () async {
        await cloudSub?.cancel();
        await localSub?.cancel();
      },
    );
    return controller.stream;
  }

  /// **YAZAN kişinin uid'i** — [uid] (koleksiyonun SAHİBİ) ile aynı olmak
  /// zorunda değil: paylaşılan bir klasörde not, klasörün SAHİBİNİN
  /// koleksiyonuna yazılır ama yazan bir başkasıdır (bkz.
  /// `sharedFolderNotesProvider`, `FolderScreen`).
  ///
  /// Her yazımda `updatedBy` olarak kayda geçer; paylaşılan klasör rozeti ve
  /// bildirimi "bu değişikliği ben mi yaptım" sorusunu buradan yanıtlar —
  /// yoksa kendi düzenlemem kendi telefonuma bildirim düşerdi.
  ///
  /// **KURAL ZORUNLU KILIYOR (F1.4, 2026-10-19):** paylaşılan yollarda
  /// (klasör + ortak not) `firestore.rules` `updatedBy == request.auth.uid`
  /// istiyor — bu sınıftaki HER bulut yazımı `updatedBy` taşımalı, yoksa
  /// paylaşılan notta reddedilir. Oluşturmada ayrıca `createdBy` yazılır
  /// ('write' rolü yalnız kendi oluşturduğu notu güncelleyebilir).
  final String editorUid;

  final FirebaseFirestore _firestore;
  final String uid;

  static const _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> get _notes => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.notesCollection);

  Stream<Note?> watchNote(String noteId) => _withLocal(
    _hydratedDoc(noteId),
    (_NoteDocs e) =>
        local?.note(noteId) ??
        (e.doc.exists
            ? Note.fromMap(
                noteId,
                mergeInkV2(mergeHeavy(e.doc.data()!, e.heavy), e.ink),
                pending: e.doc.metadata.hasPendingWrites,
                heavyLoaded: e.loaded,
              )
            : null),
  );

  /// Mürekkep v2 çizgi sırası (F61.3): örnek kimliğiyle, bütün notlar için
  /// tek tablo (Expando — çizgi bırakılınca kaydı da gider).
  final _inkOrder = InkOrder();

  CollectionReference<Map<String, dynamic>> _inkDocs(String noteId) =>
      _notes.doc(noteId).collection(kInkCollection);

  /// `ink` koleksiyonu anlık görüntüsü → docId → paket. Bilinmeyen sürüm /
  /// biçim atlanır ve kayda yazılır (Ek B: çökme yok).
  Map<String, Uint8List> _inkPacks(
    String noteId,
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final out = <String, Uint8List>{};
    for (final d in docs) {
      final data = d.data();
      final b = data['b'];
      if (data['v'] == 1 && b is Blob) {
        out[d.id] = b.bytes;
      } else {
        ErrorLog.record(
          'ink_v2',
          'okunamayan mürekkep belgesi $noteId/${d.id}',
        );
      }
    }
    return out;
  }

  void _badInk(String noteId, String docId, Object error) =>
      ErrorLog.record('ink_v2', 'bozuk mürekkep paketi $noteId/$docId: $error');

  DocumentReference<Map<String, dynamic>> _heavyDoc(String noteId) =>
      _notes.doc(noteId).collection(kHeavyCollection).doc(kHeavyDocId);

  /// Not belgesi + (bölünmüşse) ağır belgesi, birlikte (F3.13). Ağır belge
  /// yalnız ana belgede `heavyRef` varken dinlenir; ilk anlık görüntüsü
  /// gelene dek not HAFİF yayınlanır (`heavy: null` — yazım ağır belgeye
  /// dokunmaz, bkz. [updateNote]).
  ///
  /// **Mürekkep v2** (F61.5): ana belgede `inkV: 2` varsa `ink` koleksiyonu
  /// da TEK dinleyiciyle dinlenir; yalnız değişen bant çözülür
  /// ([InkDocCache]). Not, ilk mürekkep görüntüsü de gelince yüklü sayılır.
  Stream<_NoteDocs> _hydratedDoc(String noteId) {
    late StreamController<_NoteDocs> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? mainSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? heavySub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? inkSub;
    DocumentSnapshot<Map<String, dynamic>>? last;
    Map<String, dynamic>? heavy;
    Map<String, List<InkStroke>>? ink;
    final inkCache = InkDocCache();
    void emit() {
      final doc = last;
      if (doc == null) return;
      final data = doc.data();
      final split = data?['heavyRef'] == true;
      final v2 = data?['inkV'] == 2;
      controller.add((
        doc: doc,
        heavy: heavy,
        ink: ink,
        // v1: bugünkü anlam AYNEN (`heavy != null`; editörün "ağır veri ilk
        // kez geldi" dalı buna bağlı). v2: mürekkep de beklenir.
        loaded: v2 ? (!split || heavy != null) && ink != null : heavy != null,
      ));
    }

    controller = StreamController(
      onListen: () {
        mainSub = _dataChangesOnly(_sharedDoc(noteId)).listen((doc) {
          last = doc;
          final split = doc.data()?['heavyRef'] == true;
          if (split && heavySub == null) {
            heavySub = _heavyDoc(noteId).snapshots().listen((h) {
              heavy = h.data() ?? const <String, dynamic>{};
              emit();
            }, onError: controller.addError);
          }
          if (doc.data()?['inkV'] == 2 && inkSub == null) {
            inkSub = _inkDocs(noteId).snapshots().listen((q) {
              ink = inkCache.apply(
                _inkPacks(noteId, q.docs),
                _inkOrder,
                onBad: (id, e) => _badInk(noteId, id, e),
              );
              emit();
            }, onError: controller.addError);
          }
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await mainSub?.cancel();
        await heavySub?.cancel();
        await inkSub?.cancel();
      },
    );
    return controller.stream;
  }

  /// Listedeki HAFİF (bölünmüş) notun tamamı: ağır belge okunup işlenir.
  /// Bölünmemiş, zaten yüklü ya da yerel not olduğu gibi döner. Paylaşım,
  /// dışa aktarma, çoğaltma, yedek ve "yalnız bu cihaz" bunu çağırır.
  Future<Note> hydrate(Note note) async {
    if (!needsHydrate(note) || isLocal(note.id)) return note;
    final main = await _notes.doc(note.id).get();
    final data = main.data();
    if (data == null) return note;
    final heavy = await _heavyDoc(note.id).get();
    Map<String, List<InkStroke>>? ink;
    if (data['inkV'] == 2) {
      final q = await _inkDocs(note.id).get();
      ink = InkDocCache().apply(
        _inkPacks(note.id, q.docs),
        _inkOrder,
        onBad: (id, e) => _badInk(note.id, id, e),
      );
    }
    return Note.fromMap(
      note.id,
      mergeInkV2(
        mergeHeavy(data, heavy.data() ?? const <String, dynamic>{}),
        ink,
      ),
      heavyLoaded: true,
    );
  }

  /// Belgedeki yerel değişiklikler sunucuya ulaştı mı? (editördeki
  /// bulut/senkron göstergesi için)
  ///
  /// distinct ŞART: includeMetadataChanges her metadata geçişinde (cache'ten
  /// geldi bayrağı dahil) olay üretir; boolean değişmeden editörün göstergesi
  /// boşuna yeniden çizilirdi.
  Stream<bool> watchPendingWrites(String noteId) => _withLocal(
    _sharedDoc(noteId),
    (DocumentSnapshot<Map<String, dynamic>> doc) =>
        !isLocal(noteId) && doc.metadata.hasPendingWrites,
  ).distinct();

  /// F22.6: editörün iki belge dinleyicisi (not verisi + senkron göstergesi)
  /// AYNI yerel Firestore dinleyicisini paylaşır. Eskiden kayıt başına 3 yerel
  /// olay vardı (yazım: veri + metadata dinleyicisi, onay: metadata) ve her
  /// biri tüm belgeyi platform kanalından kodluyordu; şimdi 2 (yazım + onay).
  /// Firestore örneğine bağlı (paylaşılan klasördeki not için her seferinde
  /// yeni [NotesRepository] kurulur, örnek aynıdır).
  static final Expando<Map<String, _DocHub>> _hubs = Expando();

  /// Testler için: açık paylaşılan belge dinleyicisi sayısı.
  @visibleForTesting
  static int debugSharedDocListeners = 0;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _sharedDoc(String noteId) {
    final ref = _notes.doc(noteId);
    final hubs = _hubs[_firestore] ??= <String, _DocHub>{};
    var hub = hubs[ref.path];
    if (hub == null) {
      late final _DocHub created;
      created = _DocHub(ref, () {
        if (identical(hubs[ref.path], created)) hubs.remove(ref.path);
      });
      hubs[ref.path] = hub = created;
    }
    return hub.stream();
  }

  /// `includeMetadataChanges` akışından yalnız VERİSİ değişen olaylar —
  /// varsayılan `snapshots()` ile aynı anlam (yalnız metadata değişen onay /
  /// önbellek→sunucu olayı editörü yeniden kurmaz). İlk olay hep geçer.
  static Stream<DocumentSnapshot<Map<String, dynamic>>> _dataChangesOnly(
    Stream<DocumentSnapshot<Map<String, dynamic>>> source,
  ) {
    DocumentSnapshot<Map<String, dynamic>>? prev;
    return source.where((doc) {
      final p = prev;
      prev = doc;
      if (p == null) return true;
      return p.exists != doc.exists || !deepDataEquals(p.data(), doc.data());
    });
  }

  static int _compare(Note a, Note b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final byOrder = a.orderIndex.compareTo(b.orderIndex);
    if (byOrder != 0) return byOrder;
    final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  /// Yeni not oluşturur ve id'sini döner; editör bu id ile açılır.
  ///
  /// [body] ve [folderId] İÇERİKLİ oluşturma içindir (ana ekrandaki "Yeni
  /// not…" satırı gibi). Ayrı bir `updateFields` çağrısı yerine TEK yazımda
  /// geçmeleri önemli: iki yazım arasında doküman bir an BOŞ kalıyor, o anda
  /// yayınlanan akış anlık görüntüsünde not "boş" olduğu için ana ekran
  /// süzgecinden (`!n.isEmpty`) düşüyor ve — zamanlamaya göre — kullanıcıya
  /// hiç görünmeyebiliyordu ("bazen oluşuyor bazen oluşmuyor").
  Future<String> createNote(
    NoteType type, {
    double? orderIndex,
    String title = '',
    String body = '',
    List<String>? items,
    String? folderId,
    DateTime? reminderAt,
    int listColumns = 1,
    String? listKind,
    ListMode? listMode,
    ResetSchedule? resetSchedule,
    List<int> resetCustomDays = const [],
    ContextTimeSlot contextTimeSlot = ContextTimeSlot.any,
    bool isQuickInbox = false,
  }) async {
    final doc = _notes.doc();
    lastCreatedId = doc.id;
    final resolvedMode = listMode ?? listModeFromLegacyKind(listKind);
    final resolvedReset =
        resetSchedule ?? defaultResetScheduleForLegacyKind(listKind);
    // [items]: ŞABLONDAN doğan listenin maddeleri (bkz. note_templates) —
    // not TEK yazımda dolu doğar; ardından ayrı bir güncelleme yazılsaydı
    // arada boş not görünüp boş-not temizliğine yakalanabilirdi.
    final note = Note(
      id: doc.id,
      type: type,
      title: title,
      body: body,
      folderId: folderId,
      reminderAt: reminderAt,
      listColumns: listColumns == 2 ? 2 : 1,
      listKind: listKind,
      listMode: resolvedMode,
      resetSchedule: resolvedReset,
      resetCustomDays: resetCustomDays,
      contextTimeSlot: contextTimeSlot,
      isQuickInbox: isQuickInbox,
      // Son kullanılan gövde yazı boyutu (F56.3, [NoteFormatMemory]); yazı
      // tipi bilerek taşınmaz — her not varsayılan tiple doğar.
      fontScale: NoteFormatMemory.fontScale,
      items: items != null && items.isNotEmpty
          ? [for (final t in items) NoteItem(id: _uuid.v4(), text: t)]
          : type == NoteType.text
          ? const []
          : [NoteItem(id: _uuid.v4(), text: '')],
      orderIndex:
          orderIndex ?? -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    // Bekletmeden yaz: çevrimdışıyken de anında açılabilsin.
    unawaited(
      doc.set({
        ...note.toMap(),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
        'createdBy': editorUid,
      }),
    );
    return doc.id;
  }

  /// Hızlı liste ve akıllı çalışma alanlarından doğan zengin maddeleri,
  /// etiketleri ve aciliyet işaretini TEK atomik yazımda kaydeder.
  Future<String> createRichNote(
    NoteType type, {
    double? orderIndex,
    String title = '',
    String body = '',
    List<NoteItem>? items,
    List<String> tags = const [],
    bool urgent = false,
    String? folderId,
    DateTime? reminderAt,
    int listColumns = 1,
    String? listKind,
    ListMode? listMode,
    ResetSchedule? resetSchedule,
    List<int> resetCustomDays = const [],
    ContextTimeSlot contextTimeSlot = ContextTimeSlot.any,
    bool isQuickInbox = false,
  }) async {
    final doc = _notes.doc();
    lastCreatedId = doc.id;
    final resolvedMode = listMode ?? listModeFromLegacyKind(listKind);
    final resolvedReset =
        resetSchedule ?? defaultResetScheduleForLegacyKind(listKind);
    final note = Note(
      id: doc.id,
      type: type,
      title: title,
      body: body,
      folderId: folderId,
      reminderAt: reminderAt,
      tags: tags,
      urgent: urgent,
      listColumns: listColumns == 2 ? 2 : 1,
      listKind: listKind,
      listMode: resolvedMode,
      resetSchedule: resolvedReset,
      resetCustomDays: resetCustomDays,
      contextTimeSlot: contextTimeSlot,
      isQuickInbox: isQuickInbox,
      fontScale: NoteFormatMemory.fontScale,
      items: items != null && items.isNotEmpty
          ? items
          : type == NoteType.text
          ? const []
          : [NoteItem(id: _uuid.v4(), text: '')],
      orderIndex:
          orderIndex ?? -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    unawaited(
      doc.set({
        ...note.toMap(),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
        'createdBy': editorUid,
      }),
    );
    return doc.id;
  }

  /// "Hızlı Not" klasöründeki yuvarlanan gelen kutusu checklist notunu bulur;
  /// yoksa tek atomik yazımda oluşturup döndürür.
  Future<Note> ensureQuickInboxNote({
    required String folderId,
    required String title,
    required Iterable<Note> existingNotes,
  }) async {
    for (final n in existingNotes) {
      if (n.deletedAt != null || n.archivedAt != null || n.locked) continue;
      if (n.isQuickInbox && n.folderId == folderId) return n;
    }
    for (final n in existingNotes) {
      if (n.deletedAt != null || n.archivedAt != null || n.locked) continue;
      if (n.isQuickInbox) return n;
    }
    final id = await createRichNote(
      NoteType.checklist,
      title: title,
      items: const [],
      folderId: folderId,
      listMode: ListMode.general,
      isQuickInbox: true,
    );
    return Note(
      id: id,
      type: NoteType.checklist,
      title: title,
      folderId: folderId,
      isQuickInbox: true,
    );
  }

  /// Liste kipini merge-güvenli günceller (`general`a dönüşte eski `listMode`
  /// ve `listKind` kayıtta kalmasın).
  void setListMode(
    String noteId,
    ListMode mode, {
    String? listKind,
    ResetSchedule? resetSchedule,
  }) {
    final fields = <String, dynamic>{
      'listMode': mode.id,
      if (mode == ListMode.general) 'listKind': null,
      if (mode == ListMode.shopping) 'listKind': listKind ?? 'shopping',
      if (listKind != null && mode != ListMode.general) 'listKind': listKind,
      if (resetSchedule != null) 'resetSchedule': resetSchedule.id,
    };
    updateFields(noteId, fields);
  }

  /// Rutin sıfırlama takvimini merge-güvenli günceller.
  void setResetSchedule(
    String noteId,
    ResetSchedule schedule, {
    List<int> customDays = const [],
  }) {
    updateFields(noteId, {
      'resetSchedule': schedule.id,
      'resetCustomDays': schedule == ResetSchedule.customDays
          ? customDays
          : const <int>[],
    });
  }

  /// Günün saatine göre öne çıkma bağlamını merge-güvenli günceller.
  void setContextTimeSlot(String noteId, ContextTimeSlot slot) {
    updateFields(noteId, {'contextTimeSlot': slot.id});
  }

  /// Yazmadan YENİ not kimliği: not sonra TEK yazımda doğar
  /// (`updateNote`, `createdBy` [Note.extras] içinde). [createNote] + ayrı
  /// içerik yazımı yerine bu: Android eklentisi her yazımı ayrı iş parçacığında başlatır,
  /// beklenmeyen boş oluşturma yazımı içerik yazımından SONRA düşüp içeriği
  /// silebiliyordu (P60, 2026-11-14: içe aktarmada 240 nottan 67'si kayıp).
  String newNoteId() => lastCreatedId = _notes.doc().id;

  /// Notun bir KOPYASINI oluşturur ve yeni id'sini döner.
  ///
  /// NEDEN: bir notu şablon gibi kullanmanın (haftalık liste, alışveriş
  /// listesi, toplantı notu) tek yolu metnini kopyalayıp yeni bir nota
  /// yapıştırmaktı — biçim, renk, etiket ve madde işaretleri yolda kayboluyordu.
  ///
  /// **EKLER KOPYALANMAZ** (bilinçli): ek dosyaları Storage'da notun id'si
  /// altında durur; kopyalamak her dosyayı indirip yeniden yüklemek demektir
  /// (kota + süre) ve yarıda kalırsa kopyanın ekleri kırık kalır. Kopyada
  /// bunun yerine metin, maddeler, etiketler, renkler ve tipografi taşınır.
  /// Sayfa notları (`pageNotes`) da ekle bağlı olduğu için dışarıda kalır.
  ///
  /// Hatırlatıcı da taşınmaz: aynı anda iki kez çalan bir hatırlatıcı istenen
  /// şey değil. Kopya ARŞİVLENMİŞ/SİLİNMİŞ olarak doğmaz; kaynağın çöpteki
  /// hâli kopyalansa bile kopya ana listeye gelir.
  Future<String> duplicateNote(Note note, {bool resetChecked = false}) async {
    final doc = _notes.doc();
    lastCreatedId = doc.id;
    NoteItem cloneItem(NoteItem item) => NoteItem(
      id: _uuid.v4(),
      text: item.text,
      checked: resetChecked ? false : item.checked,
      starred: item.starred,
      section: item.section,
      title: item.title,
      divider: item.divider,
      header: item.header,
      package: item.package,
      align: item.align,
      category: item.category,
      quantity: item.quantity,
      unit: item.unit,
      price: item.price,
      doneDays: resetChecked ? const [] : List<String>.from(item.doneDays),
      priority: item.priority,
      dueDate: item.dueDate,
      extras: Map<String, dynamic>.from(item.extras),
    );
    final copy = Note(
      id: doc.id,
      type: note.type,
      title: note.title,
      body: note.body,
      // Madde kimlikleri YENİDEN üretilir: aynı id iki notta dolaşırsa
      // editörün madde eşlemesi (ve sürükle-sırala) karışır.
      items: [for (final item in note.items) cloneItem(item)],
      tags: List<String>.from(note.tags),
      folderId: note.folderId,
      color: note.color,
      frameColor: note.frameColor,
      customColor: note.customColor,
      customFrameColor: note.customFrameColor,
      pinned: note.pinned,
      starred: note.starred,
      urgent: note.urgent,
      fontFamily: note.fontFamily,
      fontScale: note.fontScale,
      textOpacity: note.textOpacity,
      titleFontFamily: note.titleFontFamily,
      titleFontScale: note.titleFontScale,
      titleTextOpacity: note.titleTextOpacity,
      listColumns: note.listColumns,
      listKind: note.listKind,
      listMode: note.listMode,
      resetSchedule: note.resetSchedule,
      resetCustomDays: List<int>.from(note.resetCustomDays),
      contextTimeSlot: note.contextTimeSlot,
      // Sayfalar da kopyalanır (F18.8 akış testi yakaladı: iki sayfalı notun
      // kopyası yalnız ilk sayfayla doğuyordu). Madde kimlikleri yine yeni.
      textPages: [
        for (final page in note.textPages)
          page.copyWith(
            items: [for (final item in page.items) cloneItem(item)],
          ),
      ],
      activePage: note.activePage,
      theme: note.theme,
      orderIndex: -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    unawaited(
      doc.set({
        ...copy.toMap(),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
        'createdBy': editorUid,
      }),
    );
    return doc.id;
  }

  /// Notun tamamını yazar. Dönen future SUNUCU onayında tamamlanır —
  /// çevrimdışıyken hiç tamamlanmayabilir; olağan çağrılar bekletmeden
  /// çalışır (çevrimdışı-önce), yalnız pencere kapanışı gibi "süreç ölmeden
  /// diske insin" noktaları kısa bir zaman aşımıyla bekler.
  ///
  /// **DEĞİŞMEYEN EK LİSTESİ YAZILMAZ** (pil/veri — 2026-10-17). Editör her
  /// kayıtta (yazarken birkaç saniyede bir) notun TAMAMINI gönderiyordu; ek
  /// listesi PDF çizimlerinin nokta dizilerini, balonları ve transkript
  /// metinlerini taşıdığından tek bir harf için yüzlerce KB yeniden yazılıyor,
  /// yerel önbelleğe işleniyor ve ağdan gidiyordu. Listenin İÇERİK özeti son
  /// BAŞARILI yazımdakiyle aynıysa alan `merge` yazımından çıkarılır (sunucuda
  /// olduğu gibi kalır). Liste örneğine (identical) bakılamaz: editör her
  /// yankı anlık görüntüsünde ekleri yeniden birleştirip YENİ liste kuruyor.
  /// Özet yalnız sunucu onayında saklanır: yazım reddedilirse (ya da
  /// çevrimdışı bekliyorsa) sonraki kayıt listeyi yine tam gönderir.
  ///
  /// [clientTime] (F22.3): `updatedAt` sunucu zamanı yerine İSTEMCİ saatiyle
  /// yazılır. Sunucu zamanı yerelde tahminle görünüp onayda GERÇEK değerle
  /// değiştiği için her kayıt dinleyicilere İKİ olay (iki tam koleksiyon
  /// kodlaması) üretiyordu; istemci saatinde onay yalnız meta veriyi
  /// değiştirir. Editörün otomatik kaydı bunu kullanır, kapanışta sunucu
  /// zamanı yine yazılır (bkz. editörde `_stampServerTimeOnExit`).
  Future<void> updateNote(Note note, {bool clientTime = false}) {
    final deleteE2ee =
        !note.locked ||
        (note.locked &&
            NoteE2eeSession.key != null &&
            !note.extras.containsKey('e2ee') &&
            note.body.isEmpty &&
            note.items.isEmpty &&
            note.textPages.isEmpty &&
            note.pageNotes.isEmpty);
    final deletePlainPageNotes =
        note.locked && NoteE2eeSession.key != null && note.pageNotes.isNotEmpty;
    final serialized = note.toMap();
    if (isLocal(note.id)) {
      local!.merge(note.id, {
        ...serialized,
        if (deleteE2ee) 'e2ee': FieldValue.delete(),
        if (deletePlainPageNotes) 'pageNotes': FieldValue.delete(),
      });
      return Future.value();
    }
    journal?.remove(note.id);
    webJournal?.remove(note.id);
    _maybeVersion(note);
    _rememberWrite(note);
    final fields = {
      ...serialized,
      if (deleteE2ee) 'e2ee': FieldValue.delete(),
      if (deletePlainPageNotes) 'pageNotes': FieldValue.delete(),
      'updatedBy': editorUid,
      kSyncAtField: FieldValue.serverTimestamp(),
      if (clientTime) 'updatedAt': Timestamp.now(),
    };
    // AĞIR ALANLAR (F3.13): bölünmüş ya da ağır kısmı eşiği aşan not iki
    // belgeye yazılır. HAFİF not (ağır belge işlenmemiş) yalnız ana belgeye
    // yazılır — eksik veriyle ağır belgenin üstüne yazılmasın.
    final maps = [
      for (final a in fields['attachments'] as List) a as Map<String, dynamic>,
    ];
    Map<String, dynamic>? heavyPayload;
    if (note.heavyMissing) {
      fields['attachments'] = splitAttachmentMaps(maps).light;
    } else if (note.heavyRef || heavyBytesOf(maps) > kHeavySplitBytes) {
      final split = splitAttachmentMaps(maps);
      fields['attachments'] = split.light;
      fields['heavyRef'] = true;
      heavyPayload = {'attachments': split.heavy};
    }
    // F6.1: özet (jsonEncode + SHA-1, büyük notta ~50 ms) yerine son yazılan
    // kopyayla ayırmasız karşılaştırma (~1 ms); bayt tahmini de liste
    // değişmedikçe yeniden yürünmez.
    final attachmentsField = fields['attachments'];
    final written = _writtenAttachments[note.id];
    final unchanged =
        written != null && sameFirestoreValue(written.value, attachmentsField);
    final attachmentBytes = unchanged
        ? written.bytes
        : estimateValueBytes(attachmentsField);
    _checkSize(note, fields, attachmentBytes);
    final writtenCopy = unchanged ? null : copyFirestoreValue(attachmentsField);
    if (unchanged) fields.remove('attachments');
    final Future<void> write;
    final heavyWritten = _writtenHeavy[note.id];
    if (heavyPayload != null &&
        !(heavyWritten != null &&
            sameFirestoreValue(heavyWritten, heavyPayload))) {
      final heavyCopy = copyFirestoreValue(heavyPayload);
      // Tek batch: ana belge ağır belgeyi gösterirken ağır belge eksik kalmasın.
      final batch = _firestore.batch()
        ..set(_heavyDoc(note.id), heavyPayload)
        ..set(_notes.doc(note.id), fields, SetOptions(merge: true));
      write = batch.commit();
      final session = _session[note.id];
      write.then<void>(
        (_) {
          if (_session[note.id] == session) _writtenHeavy[note.id] = heavyCopy;
        },
        onError: (Object _) {
          _writtenHeavy.remove(note.id);
        },
      );
    } else {
      write = _notes.doc(note.id).set(fields, SetOptions(merge: true));
    }
    final session = _session[note.id];
    write.then(
      (_) {
        // Editör bu arada kapandıysa ([releaseNote]) kopya saklanmaz.
        if (writtenCopy != null && _session[note.id] == session) {
          _writtenAttachments[note.id] = (
            value: writtenCopy,
            bytes: attachmentBytes,
          );
        }
      },
      // Blok gövde ŞART: `=> map.remove(...)` String? döndürüyordu ve
      // `onError`ın dönüş türüyle uyuşmayınca reddin üstüne ikinci,
      // yakalanmamış bir hata doğuyordu (F1.7). Red artık YUTULMUYOR (F1.6).
      onError: (Object e, StackTrace st) {
        _writtenAttachments.remove(note.id);
        _reportRejected(note.id, e, st);
      },
    );
    unawaited(write);
    return write;
  }

  // ── Kendi yazımının yankısı (F4.1) ─────────────────────────────────────

  /// Not kimliği → bu oturumda yazılan son içeriklerin anahtarları. Editör
  /// gelen anlık görüntünün BAŞKASINDAN mı (birleştir) yoksa kendi
  /// yazımının yankısı mı (taban ilerler) olduğunu buradan anlar.
  /// İçeriğin kendisi değil SHA-1 özeti (F6.2): not başına 12 TAM metin
  /// oturum boyu bellekte duruyordu.
  final Map<String, List<String>> _recentWrites = {};

  static String _contentKey(Note note) => sha1
      .convert(
        utf8.encode(
          '${note.title}\u0001${note.body}\u0001'
          '${[for (final i in note.items) '${i.id}:${i.checked}:${i.text}'].join('\u0002')}',
        ),
      )
      .toString();

  /// Not kimliği → editör oturumu sayacı; [releaseNote] artırır. Kapanıştan
  /// SONRA dönen yazım onayı (kapanıştaki son kayıt) kopya bırakmasın.
  final Map<String, int> _session = {};

  /// Editör kapanınca (F6.2): o notun oturum kayıtları bırakılır — son
  /// yazımların özetleri, sürüm tabanı ve ek listesinin/ağır belgenin son
  /// yazılan kopyaları (büyük çizimli notta MB'larca). Yeniden açılışta
  /// taban yine "açıldığı hâl" olur (F4.2); bir sonraki kayıt ek listesini
  /// bir kez tam yazar. Son sürüm zamanı ([_versionAt]) KALIR: aç-kapa
  /// 30 dk aralığını delmesin.
  void releaseNote(String noteId) {
    _session[noteId] = (_session[noteId] ?? 0) + 1;
    _recentWrites.remove(noteId);
    _versionBase.remove(noteId);
    _writtenAttachments.remove(noteId);
    _writtenHeavy.remove(noteId);
  }

  void _rememberWrite(Note note) {
    final list = _recentWrites.putIfAbsent(note.id, () => []);
    list.add(_contentKey(note));
    if (list.length > 12) list.removeAt(0);
  }

  /// [incoming] bu oturumda bu depodan yazılmış bir içerik mi?
  bool isOwnEcho(Note incoming) =>
      _recentWrites[incoming.id]?.contains(_contentKey(incoming)) ?? false;

  // ── Sürüm geçmişi (F4.2, bkz. note_version.dart) ───────────────────────

  /// Not kimliği → bir sonraki sürüme yazılacak hâlin YÜKÜ (editör
  /// açılışta verir). `Note` değil (F6.2): ağır alanlar dahil tam not
  /// oturum boyu tutuluyordu; sürüm yalnız metni yazar.
  final Map<String, Map<String, dynamic>> _versionBase = {};

  /// Not kimliği → bu oturumda son sürümün alındığı an.
  final Map<String, DateTime> _versionAt = {};

  /// Not kimliği → bu oturumda eklenen sürüm sayısı (budama seyreltme).
  final Map<String, int> _versionAdds = {};

  /// Kilit bayrağını değiştirir ve tam gövdeyi (E2EE zarfını şifreleyip
  /// veya `e2ee` alanını temizleyerek) kalıcı kaydeder.
  Future<void> setLocked(Note note, bool locked) async {
    final decrypted = note.decryptWithKey(NoteE2eeSession.key);
    await updateNote(decrypted.copyWith(locked: locked));
  }

  /// Editör notu açınca çağırır: notun AÇILDIĞI hâli, ilk değişiklikte
  /// sürüm olarak saklanır ("dünkü hâline dön"). Kilitli (E2EE) notlarda
  /// düz metin sürüm sızıntısını önlemek için sürüm alınmaz.
  void rememberVersionBase(Note note) {
    if (note.locked) return;
    _versionBase.putIfAbsent(note.id, () => versionPayload(note, reason: ''));
  }

  void _maybeVersion(Note note) {
    if (note.locked) return;
    final base = _versionBase[note.id];
    if (base == null) return;
    final current = versionPayload(note, reason: '');
    if (sameFirestoreValue(base, current)) return;
    final now = DateTime.now();
    final last = _versionAt[note.id];
    if (last != null && now.difference(last) < kVersionInterval) return;
    _versionAt[note.id] = now;
    _versionBase[note.id] = current;
    unawaited(
      _addVersion(note.id, {...base, 'reason': last == null ? 'open' : 'auto'}),
    );
  }

  CollectionReference<Map<String, dynamic>> _versions(String noteId) =>
      _notes.doc(noteId).collection(kVersionsCollection);

  /// [note]un metnini sürüm olarak saklar (yalnız-bu-cihaz notunda yok).
  /// Sahip yazınca eski sürümler [kMaxVersions]'a budanır. Kilitli notta
  /// düz metin sürümü yazılmaz.
  Future<void> saveVersion(Note note, {required String reason}) {
    if (note.locked) return Future.value();
    return _addVersion(note.id, versionPayload(note, reason: reason));
  }

  Future<void> _addVersion(String noteId, Map<String, dynamic> payload) async {
    if (isLocal(noteId)) return;
    try {
      await _versions(
        noteId,
      ).add({...payload, 'by': editorUid, 'at': FieldValue.serverTimestamp()});
      if (editorUid != uid) return;
      // Budama sorgusu en çok 40 belge OKUR; her sürümde koşmak boşa okuma
      // (senkron maliyeti S3, 2026-11-17). Oturumda notun ilk sürümünde ve
      // sonra her 5. sürümde budanır; arada sınır en çok 4 aşılır.
      final n = _versionAdds[noteId] = (_versionAdds[noteId] ?? 0) + 1;
      if (n % 5 != 1) return;
      final old = await _versions(noteId)
          .orderBy('at', descending: true)
          .limit(kMaxVersions + 10)
          .get();
      for (final doc in old.docs.skip(kMaxVersions)) {
        unawaited(doc.reference.delete());
      }
    } catch (e) {
      // Sürüm bir güvencedir; yazılamaması notun kaydını engellemez.
      CrashReporting.recordNonFatal('note-version', e, StackTrace.current);
    }
  }

  /// Notun sürümleri, yeniden eskiye.
  Future<List<NoteVersion>> listVersions(String noteId) async {
    final snap = await _versions(noteId)
        .orderBy('at', descending: true)
        .limit(kMaxVersions)
        .get();
    return [
      for (final doc in snap.docs)
        NoteVersion.fromMap(
          doc.id,
          doc.data(),
          (doc.data()['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        ),
    ];
  }

  /// Not kimliği → sunucuya son BAŞARIYLA yazılan ek listesinin DERİN
  /// kopyası ve bayt tahmini (bkz. [updateNote], [copyFirestoreValue]).
  final Map<String, ({Object? value, int bytes})> _writtenAttachments = {};

  /// Not kimliği → sunucuya son BAŞARIYLA yazılan ağır belgenin kopyası.
  final Map<String, Object?> _writtenHeavy = {};

  /// **1 MiB BELGE SINIRI** (F1.6). Firestore tek belgeyi 1 MiB'te keser;
  /// çizim/balon/transkript/sayfa notu aynı belgede büyüyen not bu eşiği
  /// geçince kullanıcı uyarılır (en büyük kalem söylenerek). Kalıcı çözüm
  /// büyük kalemleri ayrı belgelere bölmek (YOL_HARITASI F3.13).
  static const docWarnBytes = 900 * 1024;

  /// Uyarı/red olayları — arayüz tek yerden dinler (bkz.
  /// `NoteWriteIssueListener`). Statik: depo örnekleri kısa ömürlü ve
  /// birden çok (sahip başına) kurulabiliyor.
  static final _issues = StreamController<NoteWriteIssue>.broadcast();
  static Stream<NoteWriteIssue> get writeIssues => _issues.stream;

  /// [attachmentBytes]: ek listesinin bayt tahmini — liste son yazımdan beri
  /// değişmediyse önbellekten (ek listesi büyük ve çoğu kayıtta değişmiyor).
  void _checkSize(Note note, Map<String, dynamic> fields, int attachmentBytes) {
    final rest = Map<String, dynamic>.of(fields)..remove('attachments');
    final total = estimateFirestoreBytes(rest) + attachmentBytes;
    if (total < docWarnBytes) return;
    _issues.add(
      NoteWriteIssue.tooLarge(
        noteId: note.id,
        bytes: total,
        largest: largestPart(note),
      ),
    );
  }

  void _reportRejected(String noteId, Object error, StackTrace stack) {
    CrashReporting.recordNonFatal('firestore-write', error, stack);
    final reason = error is FirebaseException
        ? (error.code == 'invalid-argument' &&
                  (error.message ?? '').contains('exceeds the maximum')
              ? 'too-large'
              : error.code)
        : '$error';
    _issues.add(NoteWriteIssue.rejected(noteId: noteId, reason: reason));
  }

  /// Notun en büyük kalemi: gövde, maddeler, sayfa notları ya da tek bir ek
  /// (dosya adıyla).
  static NotePart largestPart(Note note) {
    var best = NotePart(NotePartKind.body, '', estimateValueBytes(note.body));
    void consider(NotePart p) {
      if (p.bytes > best.bytes) best = p;
    }

    consider(
      NotePart(
        NotePartKind.items,
        '',
        estimateValueBytes([for (final i in note.items) i.toMap()]),
      ),
    );
    consider(
      NotePart(NotePartKind.pageNotes, '', estimateValueBytes(note.pageNotes)),
    );
    for (final a in note.attachments) {
      consider(
        NotePart(
          NotePartKind.attachment,
          a.fileName,
          estimateValueBytes(a.toMap()),
        ),
      );
    }
    return best;
  }

  void updateFields(String noteId, Map<String, dynamic> fields) {
    unawaited(updateFieldsAndWait(noteId, fields));
  }

  /// [updateFields]'in BEKLENEBİLİR hâli. Yazımın yerel önbelleğe düştüğünü
  /// görmesi gereken çağıranlar (ör. paylaşım alımı, yazımdan hemen sonra
  /// editörü açıyor) bunu kullanır; ateşle-unut yol için [updateFields] var.
  ///
  /// `set(merge: true)` çevrimdışıyken de anında yerel önbelleğe yazar ve
  /// dönen Future sunucu onayını bekler — bu yüzden çağıran tarafta zaman
  /// aşımı/hata yutma sorumluluğu kalır (bkz. `updateNote` yorumu).
  Future<void> updateFieldsAndWait(String noteId, Map<String, dynamic> fields) {
    if (isLocal(noteId)) {
      local!.merge(noteId, {
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Future.value();
    }
    final write = _notes.doc(noteId).set({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': editorUid,
      kSyncAtField: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    // Red yutulmasın (F1.6): kullanıcıya ve hata günlüğüne. Çağıranın kendi
    // beklemesi/yakalaması etkilenmez — bu ayrı bir dinleyici.
    write.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) => _reportRejected(noteId, e, st),
    );
    return write;
  }

  /// **TOPLU YAZIM** (F2.3): her nota kendi alan haritası, TEK `WriteBatch`
  /// ile (450'şer parça). Not başına ayrı `updateFields` N akış yayını →
  /// N ana ekran yeniden kurulumu demekti ve geri alma atomik değildi.
  /// Yerel (senkronu kapalı) notlar tek değişiklik bildirimiyle yerel depoya.
  Future<void> batchUpdateEach(Map<String, Map<String, dynamic>> fieldsById) {
    if (fieldsById.isEmpty) return Future.value();
    final localFields = <String, Map<String, dynamic>>{};
    final commits = <Future<void>>[];
    var batch = _firestore.batch();
    var ops = 0;
    for (final e in fieldsById.entries) {
      if (isLocal(e.key)) {
        localFields[e.key] = {
          ...e.value,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        continue;
      }
      batch.set(_notes.doc(e.key), {
        ...e.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (++ops == 450) {
        commits.add(batch.commit());
        batch = _firestore.batch();
        ops = 0;
      }
    }
    if (ops > 0) commits.add(batch.commit());
    if (localFields.isNotEmpty) local!.mergeAll(localFields);
    final all = Future.wait(commits);
    all.then<void>(
      (_) {},
      onError: (Object e, StackTrace st) =>
          _reportRejected(fieldsById.keys.first, e, st),
    );
    return all;
  }

  /// [batchUpdateEach]'in aynı alanları bütün notlara yazan hâli.
  Future<void> batchUpdate(
    Iterable<String> noteIds,
    Map<String, dynamic> fields,
  ) => batchUpdateEach({for (final id in noteIds) id: fields});

  Future<void> softDeleteAll(Iterable<String> noteIds) =>
      batchUpdate(noteIds, {'deletedAt': Timestamp.now()});

  Future<void> restoreAll(Iterable<String> noteIds) =>
      batchUpdate(noteIds, {'deletedAt': null});

  Future<void> setArchivedAll(Iterable<String> noteIds, bool archived) =>
      batchUpdate(noteIds, {
        'archivedAt': archived ? Timestamp.now() : null,
        if (archived) 'expiresAt': null,
      });

  /// **ZAMANLI NOT**: süresi dolmuş notları arşive taşır, süreyi temizler.
  /// `archivedAt` = süre anı (şimdi değil): iki cihaz aynı anda yazsa da aynı
  /// değer — idempotent. Açık editördeki not atlanır (yazarken kaybolmasın;
  /// editör kapanınca gelen yayında arşivlenir).
  // ponytail: yalnız açılış / öne geliş / akış yayınında denetlenir; uygulama
  // kapalıyken arşivleme yok (açılınca hemen olur). Arka planda gerekirse
  // WorkManager benzeri periyodik iş eklenir.
  Future<void> archiveExpired(List<Note> notes, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return batchUpdateEach({
      for (final n in expiredNotes(notes, at))
        if (!openEditorNoteIds.contains(n.id))
          n.id: {
            'archivedAt': Timestamp.fromDate(n.expiresAt!),
            'expiresAt': null,
          },
    });
  }

  /// **RUTİN SIFIRLAMA**: yeni döneme geçen rutin listelerin önceki dönemden
  /// kalan tiklerini atomik batch ile temizler; `doneDays` geçmişi korunur.
  Future<void> resetDueRoutines(Iterable<Note> notes, {DateTime? now}) {
    final at = now ?? DateTime.now();
    return batchUpdateEach({
      for (final due in RoutineResetEngine.dueResets(notes, at))
        if (!openEditorNoteIds.contains(due.note.id))
          due.note.id: {
            'items': [for (final i in due.items) i.toMap()],
            'lastResetAt': Timestamp.fromDate(due.periodStart),
          },
    });
  }

  void setExpiry(String noteId, DateTime? at) => updateFields(noteId, {
    'expiresAt': at != null ? Timestamp.fromDate(at) : null,
  });

  /// Notların elle sıralamasını (madde 1: basılı tutup sürükle) kalıcılaştırır.
  /// Verilen liste yeni görünüm sırasıdır; her nota eşit aralıklı bir
  /// [Note.orderIndex] atanır. Yalnız değeri değişen notlar yazılır — sürükleme
  /// başına gereksiz Firestore yazımı olmaz. Sıralama, akıştaki `_compare`
  /// tarafından (sabitliler önce, sonra orderIndex artan) uygulanır.
  /// Yazımlar TEK batch'te gider ve `updatedAt`'e DOKUNULMAZ: sürükleme salt
  /// sıra değişikliğidir; eskiden not başına ayrı yazım + serverTimestamp
  /// gidiyordu, onlarca not tek tek snapshot yayını tetikliyor ve "son
  /// güncellenene göre" sıralamada notların düzenlenme tarihi bozuluyordu.
  void reorderNotes(List<Note> ordered) {
    var batch = _firestore.batch();
    var ops = 0;
    for (var i = 0; i < ordered.length; i++) {
      final want = i * 1000.0;
      if (ordered[i].orderIndex != want && isLocal(ordered[i].id)) {
        local!.merge(ordered[i].id, {'orderIndex': want});
      } else if (ordered[i].orderIndex != want) {
        // `updatedBy` paylaşılan yolda kural gereği ZORUNLU (F1.4).
        batch.set(_notes.doc(ordered[i].id), {
          'orderIndex': want,
          'updatedBy': editorUid,
          kSyncAtField: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // Firestore batch tavanı 500 işlem; taşarsa parça parça gönder.
        if (++ops == 450) {
          unawaited(batch.commit());
          batch = _firestore.batch();
          ops = 0;
        }
      }
    }
    if (ops > 0) unawaited(batch.commit());
  }

  void setPinned(String noteId, bool pinned) =>
      updateFields(noteId, {'pinned': pinned});

  /// Yıldız sabitlemeden AYRI bir bayrak (2026-10-20'de geri geldi).
  void setStarred(String noteId, bool starred) =>
      updateFields(noteId, {'starred': starred});

  /// Acil bayrağı (bkz. `Note.urgent`).
  /// Gövde yazı tipini VARSAYILANA döndürür: `toMap` alanı yalnız doluyken
  /// yazar, birleştirme yazımı eksik alanı silmez — açıkça null yazılır
  /// (kullanıcı bulgusu 2026-11-22: "Varsayılan"a dokununca eski tipe
  /// geri sıçrıyordu).
  void clearFontFamily(String noteId) =>
      updateFields(noteId, {'fontFamily': null});

  void setUrgent(String noteId, bool urgent) =>
      updateFields(noteId, {'urgent': urgent});

  /// Kartta bu notun görsel önizlemesi gizli mi (bkz. `Note.cardMediaHidden`).
  void setCardMediaHidden(String noteId, bool hidden) =>
      updateFields(noteId, {'cardMediaHidden': hidden});

  /// Zemin rengi; çerçeveden bağımsız. [custom]: paletten özel renk (ARGB)
  /// — null yazılır ki hazır renge dönünce eski özel renk silinsin.
  /// Zemin rengi seçilince çizilmiş TEMA kalkar (tema rengin önünde
  /// çizildiğinden yeni renk görünmezdi — bkz. `Note.theme`).
  void setColor(String noteId, NoteColor color, {int? custom}) => updateFields(
    noteId,
    {'color': color.id, 'customColor': custom, 'theme': ''},
  );

  /// Ana ekran kartının çerçeve rengi (editörde çizilmez).
  void setFrameColor(String noteId, NoteColor color, {int? custom}) =>
      updateFields(noteId, {
        'frameColor': color.id,
        'customFrameColor': custom,
      });

  void setAiSummary(String noteId, AiSummary summary) =>
      updateFields(noteId, {'aiSummary': summary.toMap()});

  /// Yumuşak silme — dashboard'daki "Geri Al" bunun üzerine kuruludur.
  void softDelete(String noteId) =>
      updateFields(noteId, {'deletedAt': Timestamp.now()});

  void restore(String noteId) => updateFields(noteId, {'deletedAt': null});

  void setArchived(String noteId, bool archived) => updateFields(noteId, {
    'archivedAt': archived ? Timestamp.now() : null,
    if (archived) 'expiresAt': null,
  });

  /// [repeat] verilmezse tekrar alanına dokunulmaz (ertele/ilerlet); hatırlatıcı
  /// kaldırılınca (null) tekrar da silinir (F18.14).
  void setReminder(
    String noteId,
    DateTime? reminderAt, {
    String? repeat,
    String? level,
  }) => updateFields(noteId, {
    'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
    if (reminderAt == null) 'reminderRepeat': '' else 'reminderRepeat': ?repeat,
    if (reminderAt == null) 'reminderLevel': '' else 'reminderLevel': ?level,
  });

  /// Boş notlar editörden çıkarken tamamen silinir.

  /// Ek metadata'sındaki tek bir girişi günceller (yükleme kuyruğu kullanır).
  /// Yüklemesi biten ekin DEPO alanlarını yazar.
  ///
  /// Transaction burada bilerek: listenin tek bir elemanını değiştirmek
  /// oku-değiştir-yaz gerektiriyor. Çevrimdışı çalışmaması sorun DEĞİL —
  /// yalnız Storage yüklemesi BİTTİKTEN sonra çağrılır, yani ağ zaten vardır
  /// (tek çağıran: `UploadQueue`). Ek EKLEME yolları ayrıdır ve çevrimdışı
  /// çalışır: paylaşım `arrayUnion`, editör merge'lü yazım.
  ///
  /// KÖK NEDEN (görsel düzeni kayboluyordu): eski hâli, işlemin okuduğu güncel
  /// eki [updated] ile OLDUĞU GİBİ değiştiriyordu. [updated], kuyruğun yüklemeye
  /// başladığı andaki KOPYAdır; yükleme sürerken kullanıcı görseli taşıyıp
  /// boyutlandırdıysa (saniyeler sürer) o düzen burada geri alınıyordu — not
  /// yeniden açıldığında görsel ilk konumuna, yani sayfanın üstüne dönüyor ve
  /// boyutu "kaydedilmemiş" görünüyordu. Artık yalnız yüklemenin ürettiği
  /// alanlar geçirilir; düzen (x/pageY/displayWidth/hiza/çizim) belgede ne ise
  /// o kalır.
  Future<void> patchAttachment(String noteId, Attachment updated) async {
    if (isLocal(noteId)) {
      final note = local!.note(noteId);
      if (note == null) return;
      local!.merge(noteId, {
        'attachments': note.attachmentsField([
          for (final a in note.attachments)
            a.id == updated.id ? a.withUploadOf(updated) : a,
        ]),
      });
      return;
    }
    await _firestore.runTransaction((tx) async {
      final ref = _notes.doc(noteId);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      final note = Note.fromDoc(snapshot);
      final attachments = [
        for (final a in note.attachments)
          a.id == updated.id ? a.withUploadOf(updated) : a,
      ];
      tx.update(ref, {
        'attachments': note.attachmentsField(attachments),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
      });
    });
  }

  /// Yeni ek senkronunun sonucunu (`sync`) ekin kaydına yazar; başka alana
  /// dokunmaz (F28.2). Çağrıldığında ağ vardır: yükleme yeni bitti.
  Future<void> patchAttachmentSync(
    String noteId,
    String attachmentId,
    Map<String, dynamic> sync,
  ) async {
    List<Map<String, dynamic>> merged(Note note) => [
      for (final m in note.attachmentsField())
        m['id'] == attachmentId ? {...m, 'sync': sync} : m,
    ];
    if (isLocal(noteId)) {
      final note = local!.note(noteId);
      if (note != null) local!.merge(noteId, {'attachments': merged(note)});
      return;
    }
    await _firestore.runTransaction((tx) async {
      final ref = _notes.doc(noteId);
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;
      tx.update(ref, {
        'attachments': merged(Note.fromDoc(snapshot)),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
      });
    });
  }

  /// Nota ek EKLER (var olanlara dokunmadan). Bulutta `arrayUnion` —
  /// eklemeyle aynı anda yazılan başka bir değişikliği geri almaz; yerel
  /// notta mevcut listenin sonuna.
  Future<void> appendAttachments(String noteId, List<Attachment> added) {
    if (added.isEmpty) return Future.value();
    if (isLocal(noteId)) {
      final note = local!.note(noteId);
      if (note == null) return Future.value();
      final ids = {for (final a in note.attachments) a.id};
      local!.merge(noteId, {
        'attachments': note.attachmentsField([
          ...note.attachments,
          for (final a in added)
            if (!ids.contains(a.id)) a,
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Future.value();
    }
    return updateFieldsAndWait(noteId, {
      'attachments': FieldValue.arrayUnion([for (final a in added) a.toMap()]),
    });
  }

  /// **SENKRONU KAPAT / AÇ** — notu yalnız bu cihaza taşır ya da buluta
  /// geri gönderir (kullanıcı isteği 2026-09-26: "senkronizasyon kapatma
  /// nota özel").
  ///
  /// KAPATIRKEN sıra önemli: (1) bu cihazda dosyası olmayan her ek buluttan
  /// İNDİRİLİR — indirilemezse ([LocalOnlyException]) hiçbir şey
  /// değişmez, yoksa not buluttan silinince ek kaybolurdu; (2) not yerel
  /// depoya yazılır (akış artık yereli gösterir); (3) buluttaki ek dosyaları
  /// ve belge silinir — başka cihazlarda not kaybolur.
  ///
  /// AÇARKEN: belge buluta yazılır, yerel kopya ancak buluttaki belge
  /// (çevrimdışıysa yerel önbellekte) görünür olunca silinir — arada not
  /// bir an ekrandan kaybolmasın. Ekler yükleme kuyruğuyla buluta gider.
  Future<void> setLocalOnly(
    Note note, {
    required bool localOnly,
    AttachmentRepository? attachments,
  }) async {
    final store = local;
    if (store == null) return;
    if (localOnly) {
      if (store.contains(note.id)) return;
      // Bölünmüş notun ağır kısmı da cihaza (F3.13); yerel not bölünmez.
      note = (await hydrate(note)).copyWith(heavyRef: false);
      final kept = <Attachment>[];
      for (final a in note.attachments) {
        final hasFile =
            a.localPath.isNotEmpty && await File(a.localPath).exists();
        // Yalnız Drive'da duran ek de (storagePath boş, driveId dolu) İNER:
        // yoksa bu cihazda dosyası olmayan, hiç inmeyecek bir ek kalıyordu
        // (yerel notlar indirme kuyruğunda atlanır) (F5.4).
        if (!hasFile && (a.storagePath.isNotEmpty || a.isInDrive)) {
          final bytes = await attachments?.readBytes(a);
          if (bytes == null || a.localPath.isEmpty) {
            throw const LocalOnlyException();
          }
          final file = File(a.localPath);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes, flush: true);
          forgetLocalFile(a.localPath);
        }
        kept.add(
          a.copyWith(
            storagePath: '',
            downloadUrl: '',
            driveId: '',
            thumbUrl: '',
          ),
        );
      }
      store.put(note.id, {
        ...note.copyWith(attachments: kept).toMap(),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
      });
      await store.flush();
      final deleteDrive = driveFileDeleter;
      for (final a in note.attachments) {
        if (a.storagePath.isNotEmpty) {
          unawaited(
            FirebaseStorage.instance
                .ref(a.storagePath)
                .delete()
                .catchError((Object _) {}),
          );
        }
        // Drive kopyası da (bulutta kalmasın). Drive bağlı değilse kalır.
        if (a.isInDrive && deleteDrive != null) {
          unawaited(deleteDrive(a.driveId).catchError((Object _) {}));
        }
        unawaited(deleteThumb(a));
      }
      _deleteCloudCopy(note.id);
      return;
    }
    if (!store.contains(note.id)) return;
    final current = store.note(note.id) ?? note;
    final doc = _notes.doc(note.id);
    unawaited(
      doc.set({
        ...current.toMap(),
        'updatedBy': editorUid,
        kSyncAtField: FieldValue.serverTimestamp(),
      }),
    );
    try {
      await doc
          .snapshots()
          .firstWhere((d) => d.exists)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Görünmediyse de yerel kopya bırakılır: belge yerel önbelleğe zaten
      // yazıldı, akış ilk fırsatta getirir.
    }
    store.remove(note.id);
  }
}
