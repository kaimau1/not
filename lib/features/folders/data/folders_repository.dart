import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/note_folder.dart';

final foldersRepositoryProvider = Provider<FoldersRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return null;
  return FoldersRepository(FirebaseFirestore.instance, uid);
});

/// Kullanıcının klasörleri, ada göre sıralı canlı akış.
final foldersStreamProvider = StreamProvider<List<NoteFolder>>((ref) {
  final repo = ref.watch(foldersRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchFolders();
});

/// Klasör CRUD işlemleri. Notlar gibi fire-and-forget yazar: yerel önbellek
/// anında güncellenir, senkron arka planda sürer.
class FoldersRepository {
  FoldersRepository(this._firestore, this.uid);

  final FirebaseFirestore _firestore;
  final String uid;

  CollectionReference<Map<String, dynamic>> get _folders => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.foldersCollection);

  CollectionReference<Map<String, dynamic>> get _notes => _firestore
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection(AppConstants.notesCollection);

  Stream<List<NoteFolder>> watchFolders() => _folders.snapshots().map((
    snapshot,
  ) {
    final folders = [for (final doc in snapshot.docs) NoteFolder.fromDoc(doc)];
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return folders;
  });

  Future<String> createFolder(
    String name, {
    String icon = NoteFolder.defaultIcon,
    bool hidden = false,
  }) async {
    final doc = _folders.doc();
    unawaited(
      doc.set(
        NoteFolder(
          id: doc.id,
          name: name.trim(),
          icon: icon,
          hidden: hidden,
        ).toMap(),
      ),
    );
    return doc.id;
  }

  void updateFolder(
    String folderId, {
    String? name,
    String? icon,
    bool? hidden,
  }) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (icon != null) data['icon'] = icon;
    if (hidden != null) data['hidden'] = hidden;
    if (data.isEmpty) return;
    unawaited(_folders.doc(folderId).set(data, SetOptions(merge: true)));
  }

  /// Klasörü siler; içindeki notlar SİLİNMEZ, klasörsüz kalır
  /// (folderId temizlenir).
  ///
  /// Tek batch'te: not başına ayrı yazım, her biri ayrı snapshot yayını
  /// tetikliyordu (kalabalık klasörde onlarca ardışık liste yeniden çizimi).
  Future<void> deleteFolder(String folderId) async {
    final notes = await _notes.where('folderId', isEqualTo: folderId).get();
    var batch = _firestore.batch();
    var ops = 0;
    for (final doc in notes.docs) {
      batch.set(doc.reference, {'folderId': null}, SetOptions(merge: true));
      // Firestore batch tavanı 500 işlem; taşarsa parça parça gönder.
      if (++ops == 450) {
        unawaited(batch.commit());
        batch = _firestore.batch();
        ops = 0;
      }
    }
    batch.delete(_folders.doc(folderId));
    unawaited(batch.commit());
  }
}
