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

  Stream<List<NoteFolder>> watchFolders() => _folders.snapshots().map(
        (snapshot) {
          final folders = [
            for (final doc in snapshot.docs) NoteFolder.fromDoc(doc),
          ];
          folders.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return folders;
        },
      );

  Future<String> createFolder(String name,
      {String icon = NoteFolder.defaultIcon}) async {
    final doc = _folders.doc();
    unawaited(
      doc.set(NoteFolder(id: doc.id, name: name.trim(), icon: icon).toMap()),
    );
    return doc.id;
  }

  void updateFolder(String folderId, {String? name, String? icon}) {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (icon != null) data['icon'] = icon;
    if (data.isEmpty) return;
    unawaited(_folders.doc(folderId).set(data, SetOptions(merge: true)));
  }

  /// Klasörü siler; içindeki notlar SİLİNMEZ, klasörsüz kalır
  /// (folderId temizlenir).
  Future<void> deleteFolder(String folderId) async {
    final notes = await _notes.where('folderId', isEqualTo: folderId).get();
    for (final doc in notes.docs) {
      unawaited(doc.reference.set(
        {'folderId': null},
        SetOptions(merge: true),
      ));
    }
    unawaited(_folders.doc(folderId).delete());
  }
}
