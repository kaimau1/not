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

/// Kullanıcının KENDİ klasörleri, ada göre sıralı canlı akış.
final foldersStreamProvider = StreamProvider<List<NoteFolder>>((ref) {
  final repo = ref.watch(foldersRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchFolders();
});

/// Bir arkadaşın BENİMLE paylaştığı klasörler — kısa referans (ad, simge,
/// sahip) `folderShares` KÖK koleksiyonundan gelir; klasörün TAMAMI (ve
/// notları) [sharedFolderProvider] ile sahibinin koleksiyonundan okunur.
///
/// Kullanıcı isteği 2026-08-18: "ortak notlar klasörü kişiler bağlanır
/// notları ortak görür." Ayrı bir sağlayıcı: kendi klasörlerimden BAĞIMSIZ
/// (bkz. [foldersStreamProvider]) çünkü kaynak farklı bir koleksiyon
/// (`users/{ben}/folders` değil, herkese açık `folderShares`).
final sharedFolderRefsProvider = StreamProvider<List<SharedFolderRef>>((ref) {
  final repo = ref.watch(foldersRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchSharedWithMe();
});

/// [folderShares] dokümanının hafif yansıması — sahibi ve adı, klasörün
/// tamamını okumadan "bana ne paylaşıldı" listesini kurmaya yeter.
class SharedFolderRef {
  const SharedFolderRef({
    required this.folderId,
    required this.ownerId,
    required this.name,
    required this.icon,
  });

  final String folderId;
  final String ownerId;
  final String name;
  final String icon;

  factory SharedFolderRef.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return SharedFolderRef(
      folderId: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? NoteFolder.defaultIcon,
    );
  }
}

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

  CollectionReference<Map<String, dynamic>> get _shares =>
      _firestore.collection(AppConstants.folderSharesCollection);

  Stream<List<NoteFolder>> watchFolders() => _folders.snapshots().map((
    snapshot,
  ) {
    final folders = [
      for (final doc in snapshot.docs) NoteFolder.fromDoc(doc, ownerId: uid),
    ];
    folders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return folders;
  });

  Stream<List<SharedFolderRef>> watchSharedWithMe() => _shares
      .where('sharedWith', arrayContains: uid)
      .snapshots()
      .map(
        (snap) => [for (final doc in snap.docs) SharedFolderRef.fromDoc(doc)],
      );

  /// Bir arkadaşın klasörünü canlı okur (sahibinin koleksiyonundan —
  /// klasör KOPYALANMAZ). Kullanıcı erişimi yoksa (paylaşım kaldırıldıysa)
  /// Firestore izin hatasıyla akışı kapatır; çağıran (`FolderScreen`) bunu
  /// "klasör artık yok" gibi ele alır.
  static Stream<NoteFolder?> watchSharedFolder(
    FirebaseFirestore firestore,
    String ownerId,
    String folderId,
  ) => firestore
      .collection(AppConstants.usersCollection)
      .doc(ownerId)
      .collection(AppConstants.foldersCollection)
      .doc(folderId)
      .snapshots()
      .map((doc) => doc.exists ? NoteFolder.fromDoc(doc, ownerId: ownerId) : null);

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
          ownerId: uid,
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
    // Ad/simge değiştiyse paylaşım aynası da tazelenir — aksi hâlde
    // arkadaşın rafında eski ad görünmeye devam ederdi.
    if ((name != null || icon != null)) {
      unawaited(
        _shares.doc(folderId).set({
          if (name != null) 'name': name.trim(),
          'icon': ?icon,
        }, SetOptions(merge: true)),
      );
    }
  }

  /// [folder]ü [friendUid] ile paylaşır: klasör dokümanına eklenir VE
  /// `folderShares` aynası KURULUR/GÜNCELLENİR (yoksa arkadaş klasörü hiç
  /// bulamaz — bkz. [sharedFolderRefsProvider]).
  ///
  /// Bu turun kapsamı (kullanıcı seçimi 2026-08-18): tek kişiyle paylaşım,
  /// rol ayrımı yok — paylaşılan kişi klasörü OKUR VE YAZAR (bkz.
  /// firestore.rules). Birden çok kişiyle paylaşmak da ÇALIŞIR (liste
  /// büyür), yalnız arayüz bu turda tek kişi seçtiriyor.
  Future<void> shareFolder(NoteFolder folder, String friendUid) async {
    final sharedWith = {...folder.sharedWith, friendUid}.toList();
    final data = {'sharedWith': sharedWith};
    await _folders.doc(folder.id).set(data, SetOptions(merge: true));
    await _shares.doc(folder.id).set({
      'ownerId': uid,
      'name': folder.name,
      'icon': folder.icon,
      'sharedWith': sharedWith,
    });
  }

  Future<void> unshareFolder(NoteFolder folder, String friendUid) async {
    final sharedWith = folder.sharedWith.where((u) => u != friendUid).toList();
    await _folders.doc(folder.id).set({
      'sharedWith': sharedWith,
    }, SetOptions(merge: true));
    if (sharedWith.isEmpty) {
      await _shares.doc(folder.id).delete();
    } else {
      await _shares.doc(folder.id).set({
        'sharedWith': sharedWith,
      }, SetOptions(merge: true));
    }
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
    // Paylaşım aynası da silinir — yoksa arkadaşın rafında var olmayan bir
    // klasöre giden ölü bir kart kalırdı.
    batch.delete(_shares.doc(folderId));
    unawaited(batch.commit());
  }
}
