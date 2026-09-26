import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

/// BANA GELEN, henüz yanıtlanmamış klasör davetleri (kullanıcı isteği
/// 2026-08-18: "klasör paylaşıldığında kabul et veya reddet seçeneği olsun").
/// Ana ekranın tepesinde kart olarak belirir (bkz. `HomeInvites`).
final folderInvitesProvider = StreamProvider<List<SharedFolderRef>>((ref) {
  final repo = ref.watch(foldersRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchInvites();
});

/// [folderShares] dokümanının hafif yansıması — sahibi, adı ve BENİM
/// yetkim; klasörün tamamını okumadan "bana ne paylaşıldı" listesini kurmaya
/// yeter.
class SharedFolderRef {
  const SharedFolderRef({
    required this.folderId,
    required this.ownerId,
    required this.name,
    required this.icon,
    this.role = FolderRole.both,
  });

  final String folderId;
  final String ownerId;
  final String name;
  final String icon;

  /// Bu klasörde BENİM yetkim (aynadaki `roles` haritasından çözülür).
  final FolderRole role;

  factory SharedFolderRef.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String uid,
  }) {
    final map = doc.data() ?? const <String, dynamic>{};
    return SharedFolderRef(
      folderId: doc.id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? NoteFolder.defaultIcon,
      role: parseFolderRoles(map['roles'])[uid] ?? FolderRole.both,
    );
  }

  IconData get iconData =>
      NoteFolder.iconChoices[icon] ?? Icons.folder_outlined;
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
        (snap) => [
          for (final doc in snap.docs) SharedFolderRef.fromDoc(doc, uid: uid),
        ],
      );

  /// Bana GÖNDERİLMİŞ ama henüz kabul/ret edilmemiş davetler.
  Stream<List<SharedFolderRef>> watchInvites() => _shares
      .where('pending', arrayContains: uid)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs) SharedFolderRef.fromDoc(doc, uid: uid),
        ],
      );

  /// Daveti KABUL eder: kendini `pending`den düşürüp `sharedWith`e ekler.
  /// Hem aynaya hem klasörün kendi dokümanına yazılır (sahibin arayüzü
  /// klasör dokümanını okuyor; ayna erişim kurallarını besliyor).
  ///
  /// `arrayUnion`/`arrayRemove` ŞART: davetli klasör dokümanını OKUYAMAZ
  /// (henüz erişimi yok), yani "oku-değiştir-yaz" yapamaz — alan dönüşümü
  /// mevcut diziyi görmeden kendi satırını değiştirir.
  Future<void> acceptInvite(SharedFolderRef invite) async {
    final update = {
      'pending': FieldValue.arrayRemove([uid]),
      'sharedWith': FieldValue.arrayUnion([uid]),
    };
    await _shares.doc(invite.folderId).set(update, SetOptions(merge: true));
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(invite.ownerId)
        .collection(AppConstants.foldersCollection)
        .doc(invite.folderId)
        .set(update, SetOptions(merge: true));
  }

  /// Daveti REDDEDER: yalnız `pending`den düşer, erişim açılmaz.
  Future<void> declineInvite(SharedFolderRef invite) async {
    final update = {
      'pending': FieldValue.arrayRemove([uid]),
    };
    await _shares.doc(invite.folderId).set(update, SetOptions(merge: true));
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(invite.ownerId)
        .collection(AppConstants.foldersCollection)
        .doc(invite.folderId)
        .set(update, SetOptions(merge: true));
  }

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
    int? color,
  }) async {
    final doc = _folders.doc();
    unawaited(
      doc.set(
        NoteFolder(
          id: doc.id,
          name: name.trim(),
          icon: icon,
          hidden: hidden,
          color: color,
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
    int? color,
    bool clearColor = false,
  }) {
    final data = <String, dynamic>{};
    // Renk "otomatik"e dönünce alan SİLİNİR (null yazmak yerine): eski
    // sürümler alanı hiç tanımıyor, yeni sürüm de yokluğu otomatik sayıyor.
    if (color != null) data['color'] = color;
    if (clearColor) data['color'] = FieldValue.delete();
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

  /// Klasörlerin ELLE sırasını yazar: [orderedIds]'deki konum `order` olur.
  /// Tek batch — klasör başına ayrı yazım her biri ayrı akış yayını demekti
  /// ve sürükleme sırasında raf birkaç kez yeniden dizilirdi.
  void reorderFolders(List<String> orderedIds) {
    final batch = _firestore.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.set(_folders.doc(orderedIds[i]), {
        'order': i,
      }, SetOptions(merge: true));
    }
    unawaited(batch.commit());
  }

  /// [folder]ü [friendUid] ile paylaşmak için DAVET gönderir: uid klasörün
  /// `pending` listesine düşer ve `folderShares` aynası KURULUR/GÜNCELLENİR
  /// (yoksa arkadaş daveti hiç göremez — bkz. [folderInvitesProvider]).
  ///
  /// Erişim daveti KABUL EDİLİNCE açılır (kullanıcı isteği 2026-08-18:
  /// "klasör paylaşıldığında kabul et veya reddet seçeneği olsun"); [role]
  /// ise sahibin verdiği yetkidir (okuma / yazma / her ikisi) ve davetliyi
  /// kabul ettikten SONRA da bağlar — davetli kendi rolünü değiştiremez
  /// (bkz. firestore.rules).
  Future<void> shareFolder(
    NoteFolder folder,
    String friendUid, {
    FolderRole role = FolderRole.both,
  }) async {
    // Zaten kabul etmiş bir kişiye yeniden davet gönderilmez — yalnız rolü
    // tazelenir; yoksa erişimi olan kişi "bekleyen davet" durumuna düşerdi.
    final accepted = folder.sharedWith.contains(friendUid);
    final pending = accepted
        ? folder.pending
        : {...folder.pending, friendUid}.toList();
    await _writeShare(
      folder,
      sharedWith: folder.sharedWith,
      pending: pending,
      roles: {...folder.roles, friendUid: role},
    );
  }

  /// Paylaşımı kaldırır: kişi hem üyelerden hem bekleyen davetlerden düşer.
  Future<void> unshareFolder(NoteFolder folder, String friendUid) async {
    final sharedWith = folder.sharedWith
        .where((u) => u != friendUid)
        .toList();
    final pending = folder.pending.where((u) => u != friendUid).toList();
    final roles = {...folder.roles}..remove(friendUid);
    if (sharedWith.isEmpty && pending.isEmpty) {
      await _folders.doc(folder.id).set({
        'sharedWith': const <String>[],
        'pending': const <String>[],
        'roles': const <String, String>{},
      }, SetOptions(merge: true));
      // Sohbet AYNADAN ÖNCE silinir: mesaj kuralı "bu klasöre kim erişebilir"
      // sorusunu aynaya sorar, ayna gidince kimse (sahip bile) silemez.
      await _deleteMessages(folder.id);
      // Kimse kalmadıysa ayna büsbütün kalkar: klasör yine özel bir klasör.
      await _shares.doc(folder.id).delete();
      return;
    }
    await _writeShare(
      folder,
      sharedWith: sharedWith,
      pending: pending,
      roles: roles,
    );
  }

  /// Paylaşılan bir kişinin YETKİSİNİ değiştirir (kullanıcı isteği
  /// 2026-08-18: "klasör sahibi paylaşılan klasörde yetki belirleyebilsin").
  Future<void> setFolderRole(
    NoteFolder folder,
    String friendUid,
    FolderRole role,
  ) => _writeShare(
    folder,
    sharedWith: folder.sharedWith,
    pending: folder.pending,
    roles: {...folder.roles, friendUid: role},
  );

  /// Klasör dokümanı ile paylaşım aynasını BİRLİKTE yazar — ikisi ayrı ayrı
  /// güncellenirse kurallar (ayna) ile arayüz (klasör) farklı şeyler söyler.
  Future<void> _writeShare(
    NoteFolder folder, {
    required List<String> sharedWith,
    required List<String> pending,
    required Map<String, FolderRole> roles,
  }) async {
    final roleMap = {for (final e in roles.entries) e.key: e.value.id};
    await _folders.doc(folder.id).set({
      'sharedWith': sharedWith,
      'pending': pending,
      'roles': roleMap,
    }, SetOptions(merge: true));
    await _shares.doc(folder.id).set({
      'ownerId': uid,
      'name': folder.name,
      'icon': folder.icon,
      'sharedWith': sharedWith,
      'pending': pending,
      'roles': roleMap,
    });
  }

  /// Klasörü siler; içindeki notlar SİLİNMEZ, klasörsüz kalır
  /// (folderId temizlenir).
  ///
  /// Tek batch'te: not başına ayrı yazım, her biri ayrı snapshot yayını
  /// tetikliyordu (kalabalık klasörde onlarca ardışık liste yeniden çizimi).
  ///
  /// [shared] yalnız PAYLAŞILMIŞ klasörde true olmalı: sohbeti temizlemek
  /// için mesaj koleksiyonunu sorgulamak gerekiyor ve o sorgu ayna dokümanı
  /// YOKSA izin hatası verir (kural erişimi aynadan çözüyor) — paylaşılmamış
  /// her klasörün silinmesi patlardı.
  Future<void> deleteFolder(String folderId, {bool shared = false}) async {
    // SIRA ÖNEMLİ — sohbet, ayna dokümanı DURURKEN silinir: mesaj kuralı
    // erişim sorusunu `folderShares/{id}` üzerinden yanıtlıyor, ayna
    // silindikten sonra o kural kimseye (sahibe bile) izin vermez ve
    // mesajlar erişilemez çöp olarak kalırdı.
    if (shared) await _deleteMessages(folderId);
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

  /// Klasörün sohbetini siler. Alt koleksiyonlar Firestore'da üst doküman
  /// silinince kendiliğinden GİTMEZ; elde temizlenir.
  ///
  /// Hata YUTULUR: sohbetin temizlenememesi (ağ yok, ayna çoktan gitmiş)
  /// klasörün silinmesini engellememeli — geride kalan mesajlar zaten hiç
  /// kimsenin erişemediği ölü veridir.
  Future<void> _deleteMessages(String folderId) async {
    try {
      final messages = await _shares
          .doc(folderId)
          .collection(AppConstants.folderMessagesCollection)
          // Sohbetin tamamını tek seferde çekmemek için tavan; kalanı erişimi
          // olmayan ölü veridir.
          .limit(400)
          .get();
      if (messages.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (_) {
      // Bilerek sessiz (yukarıdaki gerekçe).
    }
  }
}
