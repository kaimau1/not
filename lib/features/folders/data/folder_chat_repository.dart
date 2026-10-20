import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/error_log.dart';
import '../../auth/presentation/auth_providers.dart';

/// **PAYLAŞILAN KLASÖRÜN SOHBETİ** — kullanıcı isteği 2026-08-18: "birde
/// birbirine mesaj gönderme alanı olabilir."
///
/// Mesajlar `folderShares/{folderId}/messages` altında durur, klasörün kendi
/// dokümanının altında DEĞİL: erişim sorusunun ("bu klasöre kim bakabilir")
/// cevabı zaten aynada ve kural tek `get()` ile çözüyor. Klasörün altında
/// olsalardı paylaşılan kullanıcının SAHİBİN koleksiyonuna yazma yetkisi
/// gerekirdi — kural yüzeyini notların ötesine genişletmemek için değil.
///
/// Sohbet yetkiden BAĞIMSIZ: yalnız okuma yetkisi olan kişi de yazabilir
/// ("nota dokunma ama soru sor" bu alanın var olma nedeni).
class FolderMessage {
  const FolderMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl = '',
    this.imagePath = '',
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;

  /// **GÖRSEL MESAJ** (kullanıcı isteği 2026-09-04: "sohbette görsel
  /// gönderilebilir olsun ve kopyalanabilsin"). Boşsa düz metin mesajı.
  ///
  /// İndirme adresi mesajda durur; dosyanın kendisi Storage'da
  /// `folderChats/{folderId}/…` altında (klasörün ÜYELERİNE açık — bkz.
  /// storage.rules). Not eklerinin `users/{uid}/…` yolu burada işe yaramaz:
  /// oraya yalnız sahibi erişebilir, karşı taraf görseli göremezdi.
  final String imageUrl;

  /// Storage'daki yol — mesaj silinince dosya da silinsin diye.
  final String imagePath;

  bool get hasImage => imageUrl.isNotEmpty;

  final DateTime? createdAt;

  factory FolderMessage.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data();
    return FolderMessage(
      id: doc.id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Mesajın en fazla uzunluğu — kuralın tavanıyla AYNI (bkz. firestore.rules).
/// Arayüzde de sınırlanır ki kullanıcı yazdığını gönderemediğini sonradan
/// öğrenmesin.
const int kFolderMessageMaxLength = 2000;

/// Bir klasörün sohbeti, eskiden yeniye. autoDispose: sohbet ekranı
/// kapanınca dinleyici de kapanır — arka planda açık kalan bir abonelik her
/// mesajda uygulamayı boşuna uyandırırdı.
final folderMessagesProvider =
    StreamProvider.autoDispose.family<List<FolderMessage>, String>((
      ref,
      folderId,
    ) {
      final repo = ref.watch(folderChatRepositoryProvider);
      if (repo == null) return const Stream.empty();
      return repo.watchMessages(folderId);
    });

final folderChatRepositoryProvider = Provider<FolderChatRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  final user = ref.watch(authStateProvider).value;
  if (uid == null) return null;
  final name = (user?.displayName?.trim().isNotEmpty ?? false)
      ? user!.displayName!.trim()
      : (user?.email ?? '');
  return FolderChatRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
    uid: uid,
    name: name,
  );
});

class FolderChatRepository {
  FolderChatRepository(
    this._firestore,
    this._storage, {
    required this.uid,
    required this.name,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _uuid = Uuid();

  /// Sohbet görselinin tavanı. Not eklerinden (10/50 MB) çok daha dar:
  /// sohbet bir dosya deposu değil, üstelik her üye görseli indiriyor.
  static const int maxImageBytes = 8 * 1024 * 1024;
  final String uid;
  final String name;

  CollectionReference<Map<String, dynamic>> _messages(String folderId) =>
      _firestore
          .collection(AppConstants.folderSharesCollection)
          .doc(folderId)
          .collection(AppConstants.folderMessagesCollection);

  /// Son [limit] mesaj, ESKİDEN YENİYE. Sorgu yeniden eskiye sıralanıp
  /// istemcide ters çevrilir: "son 200 mesaj" ancak azalan sırayla alınır,
  /// listede ise sohbet doğal yönde okunur.
  Stream<List<FolderMessage>> watchMessages(
    String folderId, {
    int limit = 200,
  }) => _messages(folderId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs.reversed) FolderMessage.fromDoc(doc),
        ],
      );

  Future<void> send(String folderId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _messages(folderId).add({
      'senderId': uid,
      'senderName': name,
      'text': trimmed.length > kFolderMessageMaxLength
          ? trimmed.substring(0, kFolderMessageMaxLength)
          : trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// **GÖRSEL GÖNDERİR.** Dosya önce Storage'a çıkar, sonra mesaj yazılır:
  /// ters sırada olsaydı adresi henüz olmayan bir mesaj bir an "kırık
  /// görsel" olarak görünürdü.
  ///
  /// [text] açıklama olarak mesajın altına düşer (boş olabilir).
  Future<void> sendImage(
    String folderId,
    Uint8List bytes, {
    String text = '',
    String contentType = 'image/png',
  }) async {
    if (bytes.isEmpty) return;
    if (bytes.length > maxImageBytes) {
      throw FolderImageTooLargeException(maxImageBytes);
    }
    final path =
        '${AppConstants.folderChatStoragePrefix}/$folderId/${_uuid.v4()}.png';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final url = await ref.getDownloadURL();
    final trimmed = text.trim();
    await _messages(folderId).add({
      'senderId': uid,
      'senderName': name,
      'text': trimmed.length > kFolderMessageMaxLength
          ? trimmed.substring(0, kFolderMessageMaxLength)
          : trimmed,
      'imageUrl': url,
      'imagePath': path,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kendi mesajını siler (klasör sahibi başkasınınkini de silebilir —
  /// bkz. firestore.rules). Görselli mesajda DOSYA da silinir; silinemezse
  /// mesaj yine gider (yetim dosya, görünen bir çöpten iyidir).
  Future<void> delete(String folderId, String messageId, {String path = ''}) async {
    await _messages(folderId).doc(messageId).delete();
    if (path.isEmpty) return;
    try {
      await _storage.ref(path).delete();
    } catch (e) {
      ErrorLog.record('folder-chat-file-delete', e);
    }
  }
}


/// Sohbete sığmayacak kadar büyük görsel.
class FolderImageTooLargeException implements Exception {
  const FolderImageTooLargeException(this.maxBytes);

  final int maxBytes;
}
