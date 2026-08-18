import 'package:cloud_firestore/cloud_firestore.dart';

/// Kabul edilmiş bir arkadaşlık. Karşılıklı iki dokümanla temsil edilir —
/// `users/{ben}/friends/{o}` ve `users/{o}/friends/{ben}` — kabul akışı
/// ikisini birlikte yazar (bkz. `FriendsRepository.acceptRequest`).
class Friend {
  const Friend({
    required this.uid,
    required this.email,
    required this.name,
    this.since,
  });

  final String uid;
  final String email;
  final String name;
  final DateTime? since;

  factory Friend.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return Friend(
      uid: doc.id,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      since: (map['since'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'name': name,
    'since': since != null ? Timestamp.fromDate(since!) : FieldValue.serverTimestamp(),
  };
}

/// Bekleyen bir arkadaşlık isteği — `users/{alıcı}/friendRequests/{gönderen}`.
/// GÖNDERENİN kendi bilgileri taşınır ki alıcı kim olduğunu görebilsin.
class FriendRequest {
  const FriendRequest({
    required this.fromUid,
    required this.fromEmail,
    required this.fromName,
    this.createdAt,
  });

  final String fromUid;
  final String fromEmail;
  final String fromName;
  final DateTime? createdAt;

  factory FriendRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return FriendRequest(
      fromUid: doc.id,
      fromEmail: map['fromEmail'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'fromEmail': fromEmail,
    'fromName': fromName,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
