import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/crash_reporting.dart';
import '../../../core/utils/diagnostics.dart';
import '../../../core/utils/firestore_size.dart';
import '../../../core/utils/local_file.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_heavy.dart';
import '../domain/notebook_migration.dart';
import '../domain/note_item.dart';
import '../domain/note_version.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'drive_store.dart' show driveFileDeleter;
import 'local_notes_store.dart';

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
  return NotesRepository(
    FirebaseFirestore.instance,
    uid,
    local: LocalNotesStore.forUid(uid),
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
  return repo.watchNotes().map((notes) {
    final now = DateTime.now();
    if (now.difference(lastCleanup) > const Duration(seconds: 30)) {
      lastCleanup = now;
      unawaited(
        Future(() => repo.cleanupEmptyNotes(notes)).catchError((Object _) {}),
      );
    }
    return notes;
  });
});

/// Notların eklerinin BULUTTA kapladığı toplam alan (bayt).
///
/// Görüntülü notlar sayılmaz: Storage'a hiç yüklenmiyorlar (bkz.
/// [AttachmentKind.video]), yani depolama faturasına da girmiyorlar.
int cloudAttachmentBytes(List<Note> notes) {
  var total = 0;
  for (final note in notes) {
    // Yalnız bu cihazdaki notun ekleri bulutta yer tutmaz.
    if (note.localOnly) continue;
    for (final attachment in note.attachments) {
      // Metin eki de: içeriği not belgesinde, Storage'da değil.
      if (attachment.skipsUpload) continue;
      total += attachment.sizeBytes;
    }
  }
  return total;
}

/// Kullanılan bulut depolama alanı (bayt) — tavan denetiminin ve Ayarlar'daki
/// göstergenin kaynağı.
///
/// Çöp kutusundaki notlar SAYILMAZ: sayılsaydı "yer açmak için sil" işe
/// yaramaz görünürdü (çöp 30 gün sonra boşalıyor). Karşılığında gerçek Storage
/// kullanımı bu sayının biraz üstünde olabilir; istemci tarafı sayım zaten
/// yaklaşık (bkz. [AppConstants.maxFreeStorageBytes]).
final storageUsedBytesProvider = Provider<int>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  return cloudAttachmentBytes(notes);
});

/// Çöp kutusundaki (soft-delete edilmiş) notlar.
///
/// autoDispose ŞART: watchTrash tüm koleksiyonu dinleyen İKİNCİ bir
/// dinleyicidir. Kalıcı provider'da çöp ekranı bir kez açılınca oturum boyu
/// açık kalıyor, her not düzenlemesi koleksiyonun ikinci kez indirilip
/// ayrıştırılmasına mal oluyordu. Ekran kapanınca dinleyici de kapanır.
final trashStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchTrash();
});

/// Tek bir notun canlı akışı (editör bunu izler).
final noteStreamProvider = StreamProvider.autoDispose.family<Note?, String>((
  ref,
  noteId,
) {
  if (Diagnostics.enabled) {
    Diagnostics.openNoteStreams++;
    ref.onDispose(() => Diagnostics.openNoteStreams--);
  }
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchNote(noteId);
});

/// Listeden gelen (bölünmüşse HAFİF) notu tam hâline getirir (F3.13);
/// [ownerId] doluysa not onun koleksiyonundandır (paylaşılan klasör).
Future<Note> hydrateNote(WidgetRef ref, Note note, {String? ownerId}) {
  if (!note.heavyMissing) return Future.value(note);
  final repo = ownerId == null
      ? ref.read(notesRepositoryProvider)
      : NotesRepository(FirebaseFirestore.instance, ownerId);
  return repo?.hydrate(note) ?? Future.value(note);
}

/// **BAŞKASININ notunun** canlı akışı — paylaşılan klasördeki not, sahibinin
/// koleksiyonunda yaşıyor (bkz. `NoteFolder.ownerId`). [noteStreamProvider]
/// her zaman GİRİŞ YAPMIŞ kullanıcının koleksiyonuna bakar; paylaşılan bir
/// notu onunla açmak "not bulunamadı" demekti ve editördeki her yazım kendi
/// koleksiyonumda HAYALET bir kopya yaratıyordu.
final ownedNoteStreamProvider = StreamProvider.autoDispose
    .family<Note?, ({String ownerId, String noteId})>(
      (ref, key) => NotesRepository(
        FirebaseFirestore.instance,
        key.ownerId,
      ).watchNote(key.noteId),
    );

/// [pendingWritesProvider]'ın başka bir sahibin notu için karşılığı.
final ownedPendingWritesProvider = StreamProvider.autoDispose
    .family<bool, ({String ownerId, String noteId})>(
      (ref, key) => NotesRepository(
        FirebaseFirestore.instance,
        key.ownerId,
      ).watchPendingWrites(key.noteId),
    );

/// Editördeki senkron göstergesi: true = yerel değişiklik sunucuya yazılmayı
/// bekliyor.
final pendingWritesProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  noteId,
) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchPendingWrites(noteId);
});

/// Notlar üzerindeki tüm Firestore işlemleri. Yazımlar bilinçli olarak
/// beklenmez (fire-and-forget): yerel önbellek anında güncellenir, SDK
/// bağlantı gelince arka planda senkronlar — kesintisiz otomatik senkronun
/// temeli budur.
class NotesRepository {
  NotesRepository(
    this._firestore,
    this.uid, {
    String? editorUid,
    this.local,
  }) : editorUid = editorUid ?? uid;

  /// YALNIZ BU CİHAZDA tutulan notlar (bkz. [LocalNotesStore]). Doluysa her
  /// yazım kimliğe bakar: yerel notun yazımı Firestore'a HİÇ gitmez.
  final LocalNotesStore? local;

  /// [noteId] yalnız bu cihazda mı tutuluyor?
  bool isLocal(String noteId) => local?.contains(noteId) ?? false;

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

  /// ARTIMLI ayrıştırma: her snapshot'ta yalnız değişen dokümanlar
  /// `Note.fromDoc`tan geçer. Editörde yazarken 3 sn'de bir snapshot düşer;
  /// eskiden her seferinde TÜM koleksiyon (items + attachments + zaman
  /// damgaları) yeniden ayrıştırılıyordu — maliyet nota değil koleksiyona
  /// orantılıydı. Önbellek akış (dolayısıyla oturum/uid) başına birdir;
  /// ilk snapshot'ta tüm dokümanlar "added" olarak gelir ve haritayı doldurur.
  Stream<List<Note>> watchNotes() {
    final cache = <String, Note>{};
    final cloud = _notes.where('deletedAt', isNull: true).snapshots().map((
      snapshot,
    ) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          cache.remove(change.doc.id);
        } else {
          cache[change.doc.id] = Note.fromDoc(change.doc);
        }
      }
      return cache.values.toList();
    });
    return _withLocal(cloud, (List<Note> cloudNotes) {
      final store = local;
      if (store == null || store.isEmpty) {
        return [...cloudNotes]..sort(_compare);
      }
      // Aynı kimlik iki yerde (senkron kapatılırken bir an) → YEREL kazanır.
      final localNotes = store.notes();
      final ids = {for (final n in localNotes) n.id};
      return [
        ...localNotes,
        for (final n in cloudNotes)
          if (!ids.contains(n.id)) n,
      ]..sort(_compare);
    });
  }

  /// **TEK BİR KLASÖRÜN notları.** [watchNotes]'un dar kapsamlı ikizi.
  ///
  /// KÖK NEDEN (paylaşılan klasör "Missing or insufficient permissions"
  /// veriyordu — kullanıcı bulgusu 2026-08-18): paylaşılan klasör ekranı
  /// sahibin notlarını [watchNotes] ile, yani KOLEKSİYONUN TAMAMINI
  /// isteyerek okuyordu. Firestore'da bir liste sorgusu, sonuçları kurala
  /// göre AYIKLAMAZ; kural sonuçtaki HER doküman için geçmiyorsa sorgunun
  /// TAMAMI reddedilir. Kural ise erişimi yalnız "paylaşılan klasöre ait"
  /// notlara veriyor (bkz. firestore.rules) — sahibin öbür notları sorguya
  /// girdiği an istek çöküyordu ve ekran hep hata gösteriyordu.
  ///
  /// Sorgu `folderId`ye daraltılınca sonuçtaki her doküman kuralın kapsamına
  /// girer ve izin verilir.
  ///
  /// Çöp kutusu süzgeci SUNUCUDA DEĞİL istemcide: tek eşitlik süzgeci
  /// otomatik tek-alan indeksiyle karşılanır, ikinci bir süzgeç eklemek
  /// bileşik indeks sorusunu açardı (bu depoda `firestore.indexes.json`
  /// bilerek boş). Klasör başına not sayısı küçük olduğundan ayıklama
  /// istemcide ucuz.
  ///
  /// Ayrıştırma [watchNotes] gibi ARTIMLI (F6.7): her anlık görüntüde
  /// klasörün bütün notları yeniden ayrıştırılıyordu.
  Stream<List<Note>> watchFolderNotes(String folderId) {
    final cache = _IncrementalNotes();
    return _notes
        .where('folderId', isEqualTo: folderId)
        .snapshots()
        .map((snapshot) {
          final notes = [
            for (final n in cache.apply(snapshot))
              if (n.deletedAt == null) n,
          ];
          notes.sort(_compare);
          return notes;
        });
  }

  /// Çöp kutusu: yalnız silinmiş belgeler sorgulanır (F6.7 — eskiden
  /// KOLEKSİYONUN TAMAMI dinlenip istemcide ayıklanıyordu; eşitsizlik
  /// süzgecini [purgeOldTrash] de kullanıyor, tek alan indeksi otomatik).
  /// `deletedAt` hep istemci saatiyle yazılır (sunucu damgası değil), yerel
  /// önbellekte de hemen eşleşir.
  Stream<List<Note>> watchTrash() {
    final cache = _IncrementalNotes();
    return _withLocal(
      _notes
          .where('deletedAt', isGreaterThan: Timestamp(0, 0))
          .snapshots()
          .map(cache.apply),
      (List<Note> cloudTrash) {
        final localTrash = local?.notes(deleted: true) ?? const <Note>[];
        final ids = {for (final n in localTrash) n.id};
        final notes = [
          ...localTrash,
          for (final n in cloudTrash)
            if (n.deletedAt != null && !ids.contains(n.id)) n,
        ];
        notes.sort((a, b) {
          final aTime = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return notes;
      },
    );
  }

  Stream<Note?> watchNote(String noteId) => _withLocal(
    _hydratedDoc(noteId),
    (({DocumentSnapshot<Map<String, dynamic>> doc, Map<String, dynamic>? heavy})
            e) =>
        local?.note(noteId) ??
        (e.doc.exists
            ? Note.fromMap(
                noteId,
                mergeHeavy(e.doc.data()!, e.heavy),
                pending: e.doc.metadata.hasPendingWrites,
                heavyLoaded: e.heavy != null,
              )
            : null),
  );

  DocumentReference<Map<String, dynamic>> _heavyDoc(String noteId) =>
      _notes.doc(noteId).collection(kHeavyCollection).doc(kHeavyDocId);

  /// Not belgesi + (bölünmüşse) ağır belgesi, birlikte (F3.13). Ağır belge
  /// yalnız ana belgede `heavyRef` varken dinlenir; ilk anlık görüntüsü
  /// gelene dek not HAFİF yayınlanır (`heavy: null` — yazım ağır belgeye
  /// dokunmaz, bkz. [updateNote]).
  Stream<({DocumentSnapshot<Map<String, dynamic>> doc, Map<String, dynamic>? heavy})>
  _hydratedDoc(String noteId) {
    late StreamController<
      ({DocumentSnapshot<Map<String, dynamic>> doc, Map<String, dynamic>? heavy})
    >
    controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? mainSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? heavySub;
    DocumentSnapshot<Map<String, dynamic>>? last;
    Map<String, dynamic>? heavy;
    void emit() {
      final doc = last;
      if (doc != null) controller.add((doc: doc, heavy: heavy));
    }

    controller = StreamController(
      onListen: () {
        mainSub = _notes.doc(noteId).snapshots().listen((doc) {
          last = doc;
          final split = doc.data()?['heavyRef'] == true;
          if (split && heavySub == null) {
            heavySub = _heavyDoc(noteId).snapshots().listen((h) {
              heavy = h.data() ?? const <String, dynamic>{};
              emit();
            }, onError: controller.addError);
          }
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await mainSub?.cancel();
        await heavySub?.cancel();
      },
    );
    return controller.stream;
  }

  /// Listedeki HAFİF (bölünmüş) notun tamamı: ağır belge okunup işlenir.
  /// Bölünmemiş, zaten yüklü ya da yerel not olduğu gibi döner. Paylaşım,
  /// dışa aktarma, çoğaltma, yedek ve "yalnız bu cihaz" bunu çağırır.
  Future<Note> hydrate(Note note) async {
    if (!note.heavyMissing || isLocal(note.id)) return note;
    final main = await _notes.doc(note.id).get();
    final data = main.data();
    if (data == null) return note;
    final heavy = await _heavyDoc(note.id).get();
    return Note.fromMap(
      note.id,
      mergeHeavy(data, heavy.data() ?? const <String, dynamic>{}),
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
    _notes.doc(noteId).snapshots(includeMetadataChanges: true),
    (DocumentSnapshot<Map<String, dynamic>> doc) =>
        !isLocal(noteId) && doc.metadata.hasPendingWrites,
  ).distinct();

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
  }) async {
    final doc = _notes.doc();
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
        'createdBy': editorUid,
      }),
    );
    return doc.id;
  }

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
  Future<String> duplicateNote(Note note) async {
    final doc = _notes.doc();
    final copy = Note(
      id: doc.id,
      type: note.type,
      title: note.title,
      body: note.body,
      // Madde kimlikleri YENİDEN üretilir: aynı id iki notta dolaşırsa
      // editörün madde eşlemesi (ve sürükle-sırala) karışır.
      items: [
        for (final item in note.items)
          NoteItem(
            id: _uuid.v4(),
            text: item.text,
            checked: item.checked,
            starred: item.starred,
            section: item.section,
            title: item.title,
            divider: item.divider,
          ),
      ],
      tags: List<String>.from(note.tags),
      folderId: note.folderId,
      color: note.color,
      frameColor: note.frameColor,
      customColor: note.customColor,
      customFrameColor: note.customFrameColor,
      pinned: note.pinned,
      starred: note.starred,
      fontFamily: note.fontFamily,
      fontScale: note.fontScale,
      textOpacity: note.textOpacity,
      titleFontFamily: note.titleFontFamily,
      titleFontScale: note.titleFontScale,
      titleTextOpacity: note.titleTextOpacity,
      listColumns: note.listColumns,
      orderIndex: -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    unawaited(
      doc.set({
        ...copy.toMap(),
        'updatedBy': editorUid,
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
  Future<void> updateNote(Note note) {
    if (isLocal(note.id)) {
      local!.merge(note.id, note.toMap());
      return Future.value();
    }
    _maybeVersion(note);
    _rememberWrite(note);
    final fields = {...note.toMap(), 'updatedBy': editorUid};
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
    final writtenCopy = unchanged
        ? null
        : copyFirestoreValue(attachmentsField);
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

  /// Editör notu açınca çağırır: notun AÇILDIĞI hâli, ilk değişiklikte
  /// sürüm olarak saklanır ("dünkü hâline dön").
  void rememberVersionBase(Note note) =>
      _versionBase.putIfAbsent(note.id, () => versionPayload(note, reason: ''));

  void _maybeVersion(Note note) {
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
      _addVersion(note.id, {
        ...base,
        'reason': last == null ? 'open' : 'auto',
      }),
    );
  }

  CollectionReference<Map<String, dynamic>> _versions(String noteId) =>
      _notes.doc(noteId).collection(kVersionsCollection);

  /// [note]un metnini sürüm olarak saklar (yalnız-bu-cihaz notunda yok).
  /// Sahip yazınca eski sürümler [kMaxVersions]'a budanır.
  Future<void> saveVersion(Note note, {required String reason}) =>
      _addVersion(note.id, versionPayload(note, reason: reason));

  Future<void> _addVersion(String noteId, Map<String, dynamic> payload) async {
    if (isLocal(noteId)) return;
    try {
      await _versions(noteId).add({
        ...payload,
        'by': editorUid,
        'at': FieldValue.serverTimestamp(),
      });
      if (editorUid != uid) return;
      final old = await _versions(
        noteId,
      ).orderBy('at', descending: true).limit(kMaxVersions + 10).get();
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
    final snap = await _versions(
      noteId,
    ).orderBy('at', descending: true).limit(kMaxVersions).get();
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
  Future<void> updateFieldsAndWait(
    String noteId,
    Map<String, dynamic> fields,
  ) {
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
      batchUpdate(noteIds, {'archivedAt': archived ? Timestamp.now() : null});

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

  /// Zemin rengi; çerçeveden bağımsız. [custom]: paletten özel renk (ARGB)
  /// — null yazılır ki hazır renge dönünce eski özel renk silinsin.
  void setColor(String noteId, NoteColor color, {int? custom}) =>
      updateFields(noteId, {'color': color.id, 'customColor': custom});

  /// Ana ekran kartının çerçeve rengi (editörde çizilmez).
  void setFrameColor(String noteId, NoteColor color, {int? custom}) =>
      updateFields(noteId, {'frameColor': color.id, 'customFrameColor': custom});

  /// **F3.5 GÖÇÜ**: eski defterler (`type: archive`) sayfalı not olur
  /// (bkz. `notebookToPagedNote`). Editör de açılışta çevirir; bu, hiç
  /// açılmayan defterleri de çevirir ki liste/arama/dışa aktarma tek modeli
  /// görsün. Döner: çevrilen defter sayısı.
  Future<int> migrateNotebooks() async {
    var count = 0;
    final snapshot = await _notes
        .where('type', isEqualTo: NoteType.archive.id)
        .get();
    for (final doc in snapshot.docs) {
      final note = Note.fromMap(doc.id, doc.data());
      await updateNote(
        notebookToPagedNote(note, pageId: (_) => _uuid.v4()),
      );
      count++;
    }
    final store = local;
    if (store != null) {
      for (final e in store.rawEntries().entries) {
        final note = Note.fromMap(e.key, e.value, localOnly: true);
        if (note.type != NoteType.archive) continue;
        await updateNote(
          notebookToPagedNote(note, pageId: (_) => _uuid.v4()),
        );
        count++;
      }
    }
    return count;
  }

  void setAiSummary(String noteId, AiSummary summary) =>
      updateFields(noteId, {'aiSummary': summary.toMap()});

  /// Yumuşak silme — dashboard'daki "Geri Al" bunun üzerine kuruludur.
  void softDelete(String noteId) =>
      updateFields(noteId, {'deletedAt': Timestamp.now()});

  void restore(String noteId) => updateFields(noteId, {'deletedAt': null});

  void setArchived(String noteId, bool archived) =>
      updateFields(noteId, {'archivedAt': archived ? Timestamp.now() : null});

  void setReminder(String noteId, DateTime? reminderAt) => updateFields(
    noteId,
    {'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt) : null},
  );

  /// Boş notlar editörden çıkarken tamamen silinir.
  /// Bir etiketi TÜM notlarda yeniden adlandırır. Aynı ada sahip bir etiket
  /// zaten varsa ikisi BİRLEŞİR (küme mantığı — bir notta aynı etiket iki kez
  /// duramaz).
  ///
  /// NEDEN: etiketler yalnız notlardan türetiliyordu; yazım hatasıyla açılmış
  /// bir etiketi ("prjeler") düzeltmenin tek yolu onu taşıyan HER notu tek tek
  /// açıp elle değiştirmekti. Etiket düzeni bu yüzden bozuluyordu.
  ///
  /// [notes] çağıranın elindeki liste: depo zaten canlı akışı besliyor, ikinci
  /// bir sunucu okuması yapmaya gerek yok (çevrimdışıyken de çalışır).
  Future<void> renameTag(List<Note> notes, String from, String to) async {
    final target = to.trim();
    if (target.isEmpty || target == from) return;
    for (final note in notes) {
      if (!note.tags.contains(from)) continue;
      final next = <String>[];
      for (final tag in note.tags) {
        final mapped = tag == from ? target : tag;
        if (!next.contains(mapped)) next.add(mapped);
      }
      await updateFieldsAndWait(note.id, {'tags': next});
    }
  }

  /// Etiketi TÜM notlardan kaldırır. Notlar silinmez, yalnız etiket düşer.
  Future<void> deleteTag(List<Note> notes, String tag) async {
    for (final note in notes) {
      if (!note.tags.contains(tag)) continue;
      await updateFieldsAndWait(note.id, {
        'tags': [
          for (final t in note.tags)
            if (t != tag) t,
        ],
      });
    }
  }

  void hardDelete(String noteId) {
    if (isLocal(noteId)) {
      local!.remove(noteId);
      return;
    }
    _deleteCloudCopy(noteId);
  }

  /// Notun buluttaki HER şeyi: belge + alt koleksiyonlar. Alt koleksiyon
  /// belgeyle silinmez (Firestore) — ağır belge, sürümler (F4.2, notun
  /// METNİNİ taşır) ve "düzenliyor" nabızları ayrıca gider. Kalıcı silme ve
  /// "yalnız bu cihaz"a alma ORTAK yolu (F5.4: ikincisi sürümleri bulutta
  /// bırakıyordu).
  void _deleteCloudCopy(String noteId) {
    unawaited(_notes.doc(noteId).delete());
    unawaited(_heavyDoc(noteId).delete().catchError((Object _) {}));
    for (final sub in [
      _versions(noteId),
      _notes.doc(noteId).collection(kPresenceCollection),
    ]) {
      unawaited(
        sub.get().then((snap) {
          for (final doc in snap.docs) {
            unawaited(doc.reference.delete().catchError((Object _) {}));
          }
        }, onError: (Object _) {}),
      );
    }
  }

  /// Notu Storage'daki ekleriyle birlikte kalıcı siler (çöp ekranındaki
  /// "kalıcı sil" ve otomatik çöp boşaltma kullanır).
  Future<void> deleteNotePermanently(Note note) async {
    // Ek silmeleri paralel: sıralı bekleyiş, çok ekli notlarda (çöp boşaltma
    // açılışta çalıştığı için) ilk senkronla yarışan uzun bir ağ kuyruğu
    // oluşturuyordu.
    final deleteDrive = driveFileDeleter;
    await Future.wait([
      for (final attachment in note.attachments)
        if (attachment.storagePath.isNotEmpty)
          FirebaseStorage.instance
              .ref(attachment.storagePath)
              .delete()
              .catchError((Object _) {}),
      // Google Drive kopyası (bkz. drive_store.dart). Drive bağlı değilse
      // dosya Drive'da kalır — yalnız yer kaplar.
      for (final attachment in note.attachments)
        if (attachment.isInDrive && deleteDrive != null)
          deleteDrive(attachment.driveId).catchError((Object _) {}),
    ]);
    // Cihazdaki ek klasörü de gitsin: yalnız bulut temizliği, her kalıcı
    // silmede `<destek>/attachments/<noteId>/` altında yetim dosya bırakıyor
    // ve büyük PDF/görsellerle görünmez bir disk sızıntısına dönüşüyordu.
    // ASYNC G/Ç: purgeOldTrash açılışta koşuyor; senkron listeleme/silme çok
    // ekli çöpte açılış karesini kilitlerdi.
    final base = appSupportPath;
    if (base != null) {
      final dir = Directory(p.join(base, 'attachments', note.id));
      try {
        if (await dir.exists()) {
          await for (final f in dir.list()) {
            forgetLocalFile(f.path);
          }
          await dir.delete(recursive: true);
        }
      } catch (_) {
        // Dosya kilitli/erişilemez olabilir (Windows'ta açık görüntüleyici);
        // silme bir sonraki kalıcı silmede yeniden denenir, veri riski yok.
      }
    }
    hardDelete(note.id);
  }

  /// Çöp kutusunda [trashRetention] süresini doldurmuş notları ekleriyle
  /// birlikte kalıcı siler. Her uygulama açılışında çağrılır.
  ///
  /// Süre 24 SAATTEN 30 GÜNE çıkarıldı (kullanıcı isteği): bir haftalık
  /// tatilden dönen kullanıcı yanlışlıkla sildiği notu bulamıyordu. Depolama
  /// bedeli önemsiz — silinen notlar zaten ana listede görünmüyor.
  static const trashRetention = Duration(days: 30);

  Future<void> purgeOldTrash() async {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(trashRetention));
    for (final note in local?.notes(deleted: true) ?? const <Note>[]) {
      final deleted = note.deletedAt;
      if (deleted != null && deleted.isBefore(cutoff.toDate())) {
        await deleteNotePermanently(note);
      }
    }
    final snapshot = await _notes.where('deletedAt', isLessThan: cutoff).get();
    for (final doc in snapshot.docs) {
      await deleteNotePermanently(Note.fromDoc(doc));
    }
  }

  /// Boş kalıp unutulmuş notları siler. Şu an editörde yazılıyor olabilecek
  /// taze notlara dokunmaz: not [openEditorNoteIds] içinde OLMAMALI ve son
  /// düzenlemesi 2 dakikadan eski olmalı.
  ///
  /// Açık not koruması sonradan eklendi: kullanıcı yeni nota yazmaya
  /// başladığında doküman bir süre boş kalır (ilk kayıt henüz yapılmamıştır);
  /// o sırada silinmesi, editörün sonraki merge'lü yazımı dokümanı yeniden
  /// yaratsa bile klasör/renk/sıra gibi alanları sıfırlıyordu.
  Future<void> cleanupEmptyNotes(List<Note> notes) async {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
    for (final note in notes) {
      if (openEditorNoteIds.contains(note.id)) continue;
      final updated = note.updatedAt;
      if (note.isEmpty && updated != null && updated.isBefore(cutoff)) {
        try {
          await _deleteIfStillEmpty(note.id, cutoff);
        } catch (_) {
          // Çevrimdışı (transaction ağ ister) ya da geçici hata: not kalır,
          // sonraki turda yeniden denenir. Kalıcı silmede aceleye yer yok.
        }
      }
    }
  }

  /// Boş-not kararı bayat bir anlık görüntüyle verilmiş olabilir: başka
  /// cihaz notu TAM BU SIRADA doldurduysa düz `delete()` içerikli notu
  /// kalıcı götürürdü (çöpe bile uğramadan). Transaction sunucudaki güncel
  /// hâli okuyup "hâlâ boş ve eski" önkoşulunu doğrular; koşul bozulduysa
  /// silme sessizce vazgeçer.
  Future<void> _deleteIfStillEmpty(String noteId, DateTime cutoff) async {
    if (isLocal(noteId)) {
      final note = local!.note(noteId);
      final updated = note?.updatedAt;
      if (note != null &&
          note.isEmpty &&
          updated != null &&
          updated.isBefore(cutoff)) {
        local!.remove(noteId);
      }
      return;
    }
    await _firestore.runTransaction((tx) async {
        final ref = _notes.doc(noteId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) return;
        final note = Note.fromDoc(snapshot);
        final updated = note.updatedAt;
        if (!note.isEmpty || updated == null || !updated.isBefore(cutoff)) {
          return;
        }
        tx.delete(ref);
      });
  }

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
        'attachments': [
          for (final a in note.attachments)
            (a.id == updated.id ? a.withUploadOf(updated) : a).toMap(),
        ],
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
          'attachments': [for (final a in attachments) a.toMap()],
        'updatedBy': editorUid,
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
        'attachments': [
          for (final a in note.attachments) a.toMap(),
          for (final a in added)
            if (!ids.contains(a.id)) a.toMap(),
        ],
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
        final hasFile = a.localPath.isNotEmpty && await File(a.localPath).exists();
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
        kept.add(a.copyWith(storagePath: '', downloadUrl: '', driveId: ''));
      }
      store.put(note.id, {
        ...note.copyWith(attachments: kept).toMap(),
        'updatedBy': editorUid,
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
      }
      _deleteCloudCopy(note.id);
      return;
    }
    if (!store.contains(note.id)) return;
    final current = store.note(note.id) ?? note;
    final doc = _notes.doc(note.id);
    unawaited(doc.set({...current.toMap(), 'updatedBy': editorUid}));
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

/// Sorgu anlık görüntülerini ARTIMLI ayrıştırır: yalnız değişen belgeler
/// `Note.fromDoc`tan geçer (bkz. [NotesRepository.watchNotes]). Akış başına
/// bir örnek.
class _IncrementalNotes {
  final _cache = <String, Note>{};

  List<Note> apply(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        _cache.remove(change.doc.id);
      } else {
        _cache[change.doc.id] = Note.fromDoc(change.doc);
      }
    }
    return _cache.values.toList();
  }
}

/// Senkron kapatılırken bir ek bu cihaza indirilemedi (çevrimdışı ya da
/// buluttaki dosya yok). Not OLDUĞU GİBİ bırakıldı.
class LocalOnlyException implements Exception {
  const LocalOnlyException();
}

enum NotePartKind { body, items, pageNotes, attachment }

/// Notun boyut kalemi (bkz. [NotesRepository.largestPart]).
class NotePart {
  const NotePart(this.kind, this.name, this.bytes);

  final NotePartKind kind;

  /// Ek ise dosya adı; öbür kalemlerde boş.
  final String name;
  final int bytes;
}

/// Not yazımıyla ilgili kullanıcıya söylenmesi gereken durum (F1.6).
class NoteWriteIssue {
  const NoteWriteIssue.tooLarge({
    required this.noteId,
    required int this.bytes,
    required NotePart this.largest,
  }) : reason = null;

  const NoteWriteIssue.rejected({
    required this.noteId,
    required String this.reason,
  }) : bytes = null,
       largest = null;

  final String noteId;
  final int? bytes;
  final NotePart? largest;

  /// Red nedeni (Firestore hata kodu; boyut reddinde `too-large`).
  final String? reason;

  bool get isRejected => reason != null;
}
