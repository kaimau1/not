import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/friend.dart';

/// KİŞİLER (arkadaşlar) — kullanıcı isteği 2026-08-18: "ortak notlar klasörü
/// kişiler bağlanır notları ortak görür … kişiler kullanıcıya dışarıdan
/// (e-postayla) belirlenebilmeli."
///
/// **Tasarım — neden e-posta dizini + istek/kabul (Cloud Function YOK):**
/// bu proje sunucusuz (yalnız Firestore/Storage/Auth) çalışıyor, yani "bana
/// bir e-posta gönderilince kimin uid'si olduğunu bul" işini bir Cloud
/// Function yapamıyor. Çözüm: her kullanıcı GİRİŞTE kendi
/// `userDirectory/{eposta}` = `{uid}` kaydını KENDİSİ yazar (bkz.
/// [syncOwnDirectoryEntry]); e-postadan arkadaş eklemek istenince bu kayıt
/// okunur. İstek/kabul iki taraflı olduğu için (biri davet eder, öbürü kabul
/// eder) tek bir "arkadaş ekle" YAZMAZ — [sendRequest] alıcının
/// `friendRequests` alt koleksiyonuna GÖNDERENİN kimliğiyle bir doküman
/// bırakır; [acceptRequest] o dokümanın VARLIĞINI kanıt sayıp KARŞILIKLI iki
/// `friends` dokümanını birlikte yazar (bkz. firestore.rules — kabul eden
/// kullanıcı gönderenin `friends` alt koleksiyonuna da yazabilir, ama YALNIZ
/// böyle bir istek zaten varsa).
final friendsRepositoryProvider = Provider<FriendsRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  final user = ref.watch(authStateProvider).value;
  if (uid == null || user == null) return null;
  return FriendsRepository(
    FirebaseFirestore.instance,
    uid: uid,
    email: user.email ?? '',
    name: (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.email ?? ''),
  );
});

/// Kabul edilmiş arkadaşlar, ada göre sıralı canlı akış.
final friendsStreamProvider = StreamProvider<List<Friend>>((ref) {
  final repo = ref.watch(friendsRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchFriends();
});

/// Bana gelen bekleyen arkadaşlık istekleri.
final incomingFriendRequestsProvider = StreamProvider<List<FriendRequest>>((
  ref,
) {
  final repo = ref.watch(friendsRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchIncomingRequests();
});

class FriendNotFoundException implements Exception {
  const FriendNotFoundException();
}

class AlreadyFriendException implements Exception {
  const AlreadyFriendException();
}

class SelfFriendException implements Exception {
  const SelfFriendException();
}

class FriendsRepository {
  FriendsRepository(
    this._firestore, {
    required this.uid,
    required this.email,
    required this.name,
  });

  final FirebaseFirestore _firestore;
  final String uid;
  final String email;
  final String name;

  static String _normalizeEmail(String email) => email.trim().toLowerCase();

  CollectionReference<Map<String, dynamic>> get _directory =>
      _firestore.collection(AppConstants.userDirectoryCollection);

  DocumentReference<Map<String, dynamic>> _userDoc(String otherUid) =>
      _firestore.collection(AppConstants.usersCollection).doc(otherUid);

  CollectionReference<Map<String, dynamic>> get _myFriends =>
      _userDoc(uid).collection(AppConstants.friendsCollection);

  CollectionReference<Map<String, dynamic>> get _myRequests =>
      _userDoc(uid).collection(AppConstants.friendRequestsCollection);

  /// Kendi e-posta → uid kaydını yazar/tazeler. `DashboardScreen.initState`
  /// içinden her açılışta çağrılır (ucuz — tek doküman, `merge`); e-postası
  /// olmayan (anonim/yerel) hesapta hiçbir şey yapmaz.
  ///
  /// [discoverable] açıksa `userSearch/{uid}` de yazılır: bu koleksiyon
  /// istemciden OKUNAMAZ (bkz. firestore.rules), yalnız `functions/searchUsers`
  /// callable'ı Admin SDK ile okuyup sınırlı sonuç döner. Kapalıysa
  /// (Ayarlar → "Adımla bulunabilirim", F1.1) belge SİLİNİR; tam e-postayla
  /// `userDirectory` araması yine çalışır.
  Future<void> syncOwnDirectoryEntry({required bool discoverable}) async {
    if (email.isEmpty) return;
    await _directory.doc(_normalizeEmail(email)).set({
      'uid': uid,
    }, SetOptions(merge: true));
    final search = _firestore.collection('userSearch').doc(uid);
    if (!discoverable) {
      await search.delete();
      return;
    }
    await search.set({
      'uid': uid,
      'name': name,
      'email': email,
      'nameLower': name.trim().toLowerCase(),
      'emailLower': _normalizeEmail(email),
    }, SetOptions(merge: true));
  }

  /// Sunucuya gidecek kadar anlamlı bir sorgu mu? `functions/search_match.js`
  /// ile AYNI kural (F1.1): '@' içeren sorgu tam e-posta, diğerleri en az 3
  /// harfli ad öneki.
  static bool isSearchableQuery(String query) => query.trim().length >= 3;

  /// Ad önekiyle ya da TAM e-postayla KULLANICI ARAR (Cloud Function
  /// üzerinden — istemci `userSearch`i doğrudan okuyamaz). Sunucu anonim
  /// oturumu reddeder ve uid başına dakikada 10 aramayla sınırlar; en fazla
  /// 15 sonuç döner.
  Future<List<UserSearchResult>> searchUsers(String query) async {
    final q = query.trim();
    if (!isSearchableQuery(q)) return const [];
    final callable = FirebaseFunctions.instance.httpsCallable('searchUsers');
    final result = await callable.call<Map<String, dynamic>>({'query': q});
    final raw = (result.data['results'] as List?) ?? const [];
    return [
      for (final r in raw)
        UserSearchResult.fromMap(Map<String, dynamic>.from(r as Map)),
    ];
  }

  /// [targetUid]'ye doğrudan istek gönderir (arama sonucundan — e-posta
  /// dizini araya girmiyor, uid zaten [searchUsers]'dan biliniyor).
  Future<void> sendRequestToUid(String targetUid) async {
    if (targetUid == uid) throw const SelfFriendException();
    final already = await _myFriends.doc(targetUid).get();
    if (already.exists) throw const AlreadyFriendException();
    await _userDoc(
      targetUid,
    ).collection(AppConstants.friendRequestsCollection).doc(uid).set(
      FriendRequest(fromUid: uid, fromEmail: email, fromName: name).toMap(),
    );
  }

  Future<String?> _lookupUidByEmail(String targetEmail) async {
    final doc = await _directory.doc(_normalizeEmail(targetEmail)).get();
    return doc.data()?['uid'] as String?;
  }

  Stream<List<Friend>> watchFriends() => _myFriends.snapshots().map((snap) {
    final list = [for (final doc in snap.docs) Friend.fromDoc(doc)];
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  });

  Stream<List<FriendRequest>> watchIncomingRequests() =>
      _myRequests.snapshots().map(
        (snap) => [for (final doc in snap.docs) FriendRequest.fromDoc(doc)],
      );

  /// [targetEmail] sahibine istek gönderir. Kayıtlı değilse (uygulamayı hiç
  /// açmamış/e-postasını hiç senkronlamamış) [FriendNotFoundException],
  /// kendi e-postasıysa [SelfFriendException], zaten arkadaşsa
  /// [AlreadyFriendException] fırlatır.
  Future<void> sendRequest(String targetEmail) async {
    final targetUid = await _lookupUidByEmail(targetEmail);
    if (targetUid == null) throw const FriendNotFoundException();
    if (targetUid == uid) throw const SelfFriendException();
    final already = await _myFriends.doc(targetUid).get();
    if (already.exists) throw const AlreadyFriendException();
    await _userDoc(
      targetUid,
    ).collection(AppConstants.friendRequestsCollection).doc(uid).set(
      FriendRequest(fromUid: uid, fromEmail: email, fromName: name).toMap(),
    );
  }

  /// [request] i kabul eder: KARŞILIKLI iki `friends` dokümanı yazılır, istek
  /// silinir. Sıra ÖNEMLİ — önce karşı tarafın dokümanı (kural onun VARLIĞINI
  /// isteğe bakarak doğruluyor), sonra kendi dokümanımız, en son istek silinir
  /// (silinirse ve arada bir adım başarısız olursa ikinci deneme için kanıt
  /// kaybolmasın).
  Future<void> acceptRequest(FriendRequest request) async {
    final now = DateTime.now();
    await _userDoc(request.fromUid).collection(AppConstants.friendsCollection).doc(uid).set(
      Friend(uid: uid, email: email, name: name, since: now).toMap(),
    );
    await _myFriends.doc(request.fromUid).set(
      Friend(
        uid: request.fromUid,
        email: request.fromEmail,
        name: request.fromName,
        since: now,
      ).toMap(),
    );
    await _myRequests.doc(request.fromUid).delete();
  }

  Future<void> declineRequest(String fromUid) =>
      _myRequests.doc(fromUid).delete();

  /// Arkadaşlığı kaldırır. İki taraf da kaldırma yetkisine sahip olduğundan
  /// (bkz. firestore.rules) her iki ayna doküman burada silinir; karşı taraf
  /// o an çevrimdışıysa kalıntı doküman zararsızdır (yalnız isim/e-posta),
  /// bir sonraki senkronda ya da karşı tarafın kendi kaldırmasında temizlenir.
  Future<void> removeFriend(String friendUid) async {
    await _myFriends.doc(friendUid).delete();
    await _userDoc(
      friendUid,
    ).collection(AppConstants.friendsCollection).doc(uid).delete().catchError(
      (_) {},
    );
  }
}

/// [FriendsRepository.searchUsers] sonucundaki tek kullanıcı.
class UserSearchResult {
  const UserSearchResult({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory UserSearchResult.fromMap(Map<String, dynamic> map) =>
      UserSearchResult(
        uid: map['uid'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
      );

  final String uid;
  final String name;
  final String email;
}
