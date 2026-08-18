import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
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
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
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
  return FolderChatRepository(FirebaseFirestore.instance, uid: uid, name: name);
});

class FolderChatRepository {
  FolderChatRepository(
    this._firestore, {
    required this.uid,
    required this.name,
  });

  final FirebaseFirestore _firestore;
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

  /// Kendi mesajını siler (klasör sahibi başkasınınkini de silebilir —
  /// bkz. firestore.rules).
  Future<void> delete(String folderId, String messageId) =>
      _messages(folderId).doc(messageId).delete();
}
