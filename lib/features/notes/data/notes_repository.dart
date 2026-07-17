import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';

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

/// Çöp kutusundaki (soft-delete edilmiş) notlar.
final trashStreamProvider = StreamProvider<List<Note>>((ref) {
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
final pendingWritesProvider = StreamProvider.family<bool, String>((ref, noteId) {
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

  Stream<List<Note>> watchNotes() =>
      _notes.where('deletedAt', isNull: true).snapshots().map((snapshot) {
        final notes = [for (final doc in snapshot.docs) Note.fromDoc(doc)];
        notes.sort(_compare);
        return notes;
      });

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
  Stream<bool> watchPendingWrites(String noteId) => _notes
      .doc(noteId)
      .snapshots(includeMetadataChanges: true)
      .map((doc) => doc.metadata.hasPendingWrites);

  static int _compare(Note a, Note b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final byOrder = a.orderIndex.compareTo(b.orderIndex);
    if (byOrder != 0) return byOrder;
    final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  /// Yeni boş not oluşturur ve id'sini döner; editör bu id ile açılır.
  Future<String> createNote(NoteType type, {double? orderIndex}) async {
    final doc = _notes.doc();
    final note = Note(
      id: doc.id,
      type: type,
      items: type == NoteType.text
          ? const []
          : [NoteItem(id: _uuid.v4(), text: '')],
      orderIndex: orderIndex ?? -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    // Bekletmeden yaz: çevrimdışıyken de anında açılabilsin.
    unawaited(doc.set(note.toMap()));
    return doc.id;
  }

  void updateNote(Note note) {
    unawaited(_notes.doc(note.id).set(note.toMap(), SetOptions(merge: true)));
  }

  void updateFields(String noteId, Map<String, dynamic> fields) {
    unawaited(_notes.doc(noteId).set(
      {...fields, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    ));
  }

  void setPinned(String noteId, bool pinned) =>
      updateFields(noteId, {'pinned': pinned});

  void setColor(String noteId, NoteColor color) =>
      updateFields(noteId, {'color': color.id});

  void setAiSummary(String noteId, AiSummary summary) =>
      updateFields(noteId, {'aiSummary': summary.toMap()});

  /// Yumuşak silme — dashboard'daki "Geri Al" bunun üzerine kuruludur.
  void softDelete(String noteId) =>
      updateFields(noteId, {'deletedAt': Timestamp.now()});

  void restore(String noteId) => updateFields(noteId, {'deletedAt': null});

  void setArchived(String noteId, bool archived) => updateFields(
        noteId,
        {'archivedAt': archived ? Timestamp.now() : null},
      );

  void setReminder(String noteId, DateTime? reminderAt) => updateFields(
        noteId,
        {
          'reminderAt':
              reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
        },
      );

  /// Boş notlar editörden çıkarken tamamen silinir.
  void hardDelete(String noteId) {
    unawaited(_notes.doc(noteId).delete());
  }

  /// Boş kalıp unutulmuş notları siler. Şu an editörde yazılıyor olabilecek
  /// taze notlara dokunmaz: son düzenleme 2 dakikadan eskiyse silinir.
  /// (Editörde açık boş bir not yanlışlıkla silinse bile editörün merge'lü
  /// yazımları dokümanı yeniden oluşturur — veri kaybı olmaz. Boş notlar
  /// ayrıca dashboard listesinde hiç gösterilmez.)
  Future<void> cleanupEmptyNotes(List<Note> notes) async {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 2));
    for (final note in notes) {
      final updated = note.updatedAt;
      if (note.isEmpty && updated != null && updated.isBefore(cutoff)) {
        hardDelete(note.id);
      }
    }
  }

  /// Ek metadata'sındaki tek bir girişi günceller (yükleme kuyruğu kullanır).
  Future<void> patchAttachment(String noteId, Attachment updated) =>
      _firestore.runTransaction((tx) async {
        final ref = _notes.doc(noteId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) return;
        final note = Note.fromDoc(snapshot);
        final attachments = [
          for (final a in note.attachments) a.id == updated.id ? updated : a,
        ];
        tx.update(ref, {
          'attachments': [for (final a in attachments) a.toMap()],
        });
      });
}
