import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';

/// Şu an bir editörde AÇIK olan notların id'leri; `cleanupEmptyNotes` bunlara
/// dokunmaz. Editör açılırken ekler, kapanırken çıkarır. Provider değil düz
/// bir küme, çünkü değişimi hiçbir arayüzü yeniden çizmemeli.
final openEditorNoteIds = <String>{};

final notesRepositoryProvider = Provider<NotesRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return NotesRepository(FirebaseFirestore.instance, uid);
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
    for (final attachment in note.attachments) {
      if (attachment.kind == AttachmentKind.video) continue;
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
final noteStreamProvider = StreamProvider.family<Note?, String>((ref, noteId) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchNote(noteId);
});

/// Editördeki senkron göstergesi: true = yerel değişiklik sunucuya yazılmayı
/// bekliyor.
final pendingWritesProvider = StreamProvider.family<bool, String>((
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
  NotesRepository(this._firestore, this.uid);

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
    return _notes.where('deletedAt', isNull: true).snapshots().map((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          cache.remove(change.doc.id);
        } else {
          cache[change.doc.id] = Note.fromDoc(change.doc);
        }
      }
      final notes = cache.values.toList()..sort(_compare);
      return notes;
    });
  }

  /// Çöp kutusu: Firestore null-olmayan filtreyi desteklemediği için tüm
  /// koleksiyon izlenip istemcide ayıklanır (kişisel not sayısı küçüktür).
  Stream<List<Note>> watchTrash() => _notes.snapshots().map((snapshot) {
    final notes = [
      for (final doc in snapshot.docs)
        if (doc.data()['deletedAt'] != null) Note.fromDoc(doc),
    ];
    notes.sort((a, b) {
      final aTime = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return notes;
  });

  Stream<Note?> watchNote(String noteId) => _notes
      .doc(noteId)
      .snapshots()
      .map((doc) => doc.exists ? Note.fromDoc(doc) : null);

  /// Belgedeki yerel değişiklikler sunucuya ulaştı mı? (editördeki
  /// bulut/senkron göstergesi için)
  ///
  /// distinct ŞART: includeMetadataChanges her metadata geçişinde (cache'ten
  /// geldi bayrağı dahil) olay üretir; boolean değişmeden editörün göstergesi
  /// boşuna yeniden çizilirdi.
  Stream<bool> watchPendingWrites(String noteId) => _notes
      .doc(noteId)
      .snapshots(includeMetadataChanges: true)
      .map((doc) => doc.metadata.hasPendingWrites)
      .distinct();

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
    String body = '',
    String? folderId,
  }) async {
    final doc = _notes.doc();
    final note = Note(
      id: doc.id,
      type: type,
      body: body,
      folderId: folderId,
      items: type == NoteType.text
          ? const []
          : [NoteItem(id: _uuid.v4(), text: '')],
      orderIndex:
          orderIndex ?? -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    // Bekletmeden yaz: çevrimdışıyken de anında açılabilsin.
    unawaited(doc.set(note.toMap()));
    return doc.id;
  }

  void updateNote(Note note) {
    unawaited(_notes.doc(note.id).set(note.toMap(), SetOptions(merge: true)));
  }

  void updateFields(String noteId, Map<String, dynamic> fields) {
    unawaited(
      _notes.doc(noteId).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
    );
  }

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
      if (ordered[i].orderIndex != want) {
        batch.set(_notes.doc(ordered[i].id), {
          'orderIndex': want,
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

  void setStarred(String noteId, bool starred) =>
      updateFields(noteId, {'starred': starred});

  void setColor(String noteId, NoteColor color) =>
      updateFields(noteId, {'color': color.id});

  void setFrameColor(String noteId, NoteColor color) =>
      updateFields(noteId, {'frameColor': color.id});

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
  void hardDelete(String noteId) {
    unawaited(_notes.doc(noteId).delete());
  }

  /// Notu Storage'daki ekleriyle birlikte kalıcı siler (çöp ekranındaki
  /// "kalıcı sil" ve otomatik çöp boşaltma kullanır).
  Future<void> deleteNotePermanently(Note note) async {
    // Ek silmeleri paralel: sıralı bekleyiş, çok ekli notlarda (çöp boşaltma
    // açılışta çalıştığı için) ilk senkronla yarışan uzun bir ağ kuyruğu
    // oluşturuyordu.
    await Future.wait([
      for (final attachment in note.attachments)
        if (attachment.storagePath.isNotEmpty)
          FirebaseStorage.instance
              .ref(attachment.storagePath)
              .delete()
              .catchError((Object _) {}),
    ]);
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
        hardDelete(note.id);
      }
    }
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
  Future<void> patchAttachment(String noteId, Attachment updated) =>
      _firestore.runTransaction((tx) async {
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
        });
      });
}
