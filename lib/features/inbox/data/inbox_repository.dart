import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/note_type.dart';

/// **GELEN NOTLAR** — kullanıcı isteği 2026-08-18: "not paylaş seçeneği de
/// lazım; paylaşılan not alıcıda farklı 'gelen notlar' klasöründe görülsün ve
/// oradan normal dashboard'a taşınabilsin."
///
/// **Neden KOPYA, klasör paylaşımı gibi canlı bağ değil:** gönderilen not bir
/// ARMAĞANDIR — alıcı onu kendi notu gibi düzenler, gönderen sonradan
/// değiştirse bile alıcının eline geçen metin değişmez. Canlı bağ olsaydı
/// gönderen notu silince alıcının notu da yok olurdu.
///
/// Ekler (görsel/PDF/ses) TAŞINMAZ: ikili veriler gönderenin Storage yolunda
/// duruyor ve o yolu yalnız sahibi okuyabiliyor (bkz. storage.rules). Kopya
/// alıcının hesabına yazılsaydı hem alıcının kotasından yenirdi hem de
/// paylaşımın en sık kullanıldığı yerde (kısa metin/liste) gereksiz bir
/// yükleme turu olurdu. Arayüz bunu gönderirken açıkça söyler.
class InboxNote {
  const InboxNote({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromEmail,
    required this.title,
    required this.body,
    required this.items,
    required this.type,
    required this.tags,
    required this.color,
    this.sentAt,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String fromEmail;
  final String title;
  final String body;
  final List<NoteItem> items;
  final NoteType type;
  final List<String> tags;
  final NoteColor color;
  final DateTime? sentAt;

  /// Gönderenin görünen adı; adı yoksa e-postası.
  String get senderLabel => fromName.trim().isEmpty ? fromEmail : fromName;

  /// Listede gösterilecek başlık — boşsa gövdenin ilk satırı.
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    final firstLine = body.trim().split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
    for (final item in items) {
      if (item.text.trim().isNotEmpty) return item.text.trim();
    }
    return '';
  }

  factory InboxNote.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    return InboxNote(
      id: doc.id,
      fromUid: map['fromUid'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      fromEmail: map['fromEmail'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      items: [
        for (final raw in (map['items'] as List<dynamic>? ?? const []))
          if (raw is Map)
            NoteItem.fromMap(Map<String, dynamic>.from(raw)),
      ],
      type: NoteType.fromId(map['type'] as String?),
      tags: [
        for (final tag in (map['tags'] as List<dynamic>? ?? const []))
          tag.toString(),
      ],
      color: NoteColor.fromId(map['color'] as String?),
      sentAt: (map['sentAt'] as Timestamp?)?.toDate(),
    );
  }
}

final inboxRepositoryProvider = Provider<InboxRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  final user = ref.watch(authStateProvider).value;
  if (uid == null) return null;
  return InboxRepository(
    FirebaseFirestore.instance,
    uid: uid,
    email: user?.email ?? '',
    name: (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? ''),
  );
});

/// Bana gelen, henüz kabul edilmemiş notlar (yeniden eskiye).
final inboxNotesProvider = StreamProvider<List<InboxNote>>((ref) {
  final repo = ref.watch(inboxRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchInbox();
});

class InboxRepository {
  InboxRepository(
    this._firestore, {
    required this.uid,
    required this.email,
    required this.name,
  });

  final FirebaseFirestore _firestore;
  final String uid;
  final String email;
  final String name;

  static const _uuid = Uuid();

  /// Kuralın gövde tavanıyla AYNI (bkz. firestore.rules) — kullanıcı
  /// gönderemeyeceği bir notu göndermeye çalışıp sessiz hataya düşmesin.
  static const int maxBodyChars = 100000;

  CollectionReference<Map<String, dynamic>> _inboxOf(String ownerUid) =>
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(ownerUid)
          .collection(AppConstants.inboxNotesCollection);

  Stream<List<InboxNote>> watchInbox() => _inboxOf(uid)
      .snapshots()
      .map((snap) {
        final list = [for (final doc in snap.docs) InboxNote.fromDoc(doc)];
        // Sıralama istemcide: `orderBy` bileşik indeks gerektirmesin ve
        // damgası henüz sunucudan dönmemiş kayıt listeden düşmesin.
        list.sort((a, b) {
          final at = a.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bt = b.sentAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bt.compareTo(at);
        });
        return list;
      });

  /// [note]u [friendUid] kişisine gönderir. Yalnız arkadaşlara gönderilebilir
  /// (kural, alıcının `friends` listesinde gönderenin olmasını arar).
  Future<void> sendNote(Note note, String friendUid) async {
    final body = note.body.length > maxBodyChars
        ? note.body.substring(0, maxBodyChars)
        : note.body;
    await _inboxOf(friendUid).add({
      'fromUid': uid,
      'fromName': name,
      'fromEmail': email,
      'sentAt': FieldValue.serverTimestamp(),
      // Başlık kuralın tavanına (500) sığdırılır.
      'title': note.title.length > 500
          ? note.title.substring(0, 500)
          : note.title,
      'body': body,
      'items': [for (final item in note.items) item.toMap()],
      'type': note.type.id,
      'tags': note.tags,
      'color': note.color.id,
    });
  }

  /// Gelen notu KENDİ notlarıma taşır ve gelen kutusundan düşürür — kullanıcı
  /// isteği 2026-08-18: "oradan normal dashboard'a taşınabilsin."
  ///
  /// Madde kimlikleri YENİDEN üretilir: gönderenin kimlikleri onun
  /// dokümanında da duruyor ve iki taraf aynı notu düzenlerken kimliklerin
  /// çakışması karışıklık yaratabilir (kopyalar bağımsız olmalı).
  ///
  /// Dönen değer yeni notun kimliğidir; çağıran isterse notu doğrudan açar.
  Future<String> acceptNote(InboxNote inbox) async {
    final notes = _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.notesCollection);
    final doc = notes.doc();
    final note = Note(
      id: doc.id,
      type: inbox.type,
      title: inbox.title,
      body: inbox.body,
      items: [
        for (final item in inbox.items)
          NoteItem(
            id: _uuid.v4(),
            text: item.text,
            checked: item.checked,
            starred: item.starred,
            divider: item.divider,
          ),
      ],
      tags: inbox.tags,
      color: inbox.color,
      // Yeni notlar gibi listenin BAŞINA düşsün (bkz. createNote).
      orderIndex: -DateTime.now().millisecondsSinceEpoch.toDouble(),
    );
    await doc.set(note.toMap());
    await _inboxOf(uid).doc(inbox.id).delete();
    return doc.id;
  }

  /// Gelen notu kabul etmeden siler.
  Future<void> decline(String inboxId) => _inboxOf(uid).doc(inboxId).delete();
}
