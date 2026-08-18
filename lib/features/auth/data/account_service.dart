import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../presentation/auth_providers.dart';
import 'auth_repository.dart';

final accountServiceProvider = Provider<AccountService>(
  (ref) => AccountService(ref.watch(authRepositoryProvider)),
);

/// Hesabın ve tüm kullanıcı verilerinin kalıcı silinmesi. Google Play,
/// hesap oluşturan uygulamaların uygulama içinden hesap silme sunmasını
/// zorunlu kılar; bu servis Storage ekleri + Firestore notları + Auth
/// hesabını sırayla ve geri dönüşsüz siler.
class AccountService {
  AccountService(this._auth);

  final AuthRepository _auth;

  Future<void> deleteAccountAndData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    // 1) Storage: kullanıcının tüm ekleri (users/{uid} altı, özyinelemeli).
    await _deleteStorageFolder(FirebaseStorage.instance.ref('users/$uid'));

    // 2) Firestore: tüm alt koleksiyonlar (notlar/klasörler/AI bildirimleri)
    // + kök doküman. Firestore'da bir dokümanı silmek alt koleksiyonlarını
    // SİLMEZ; bu yüzden her alt koleksiyon tek tek boşaltılır — aksi hâlde
    // hesap silindikten sonra Firebase'de yetim veri kalırdı.
    final userDoc = firestore
        .collection(AppConstants.usersCollection)
        .doc(uid);
    for (final name in const [
      AppConstants.notesCollection,
      AppConstants.foldersCollection,
      AppConstants.friendsCollection,
      AppConstants.friendRequestsCollection,
      // Bana gönderilmiş, henüz kabul edilmemiş notlar da benim verimdir.
      AppConstants.inboxNotesCollection,
      'aiReports',
    ]) {
      final snapshot = await userDoc.collection(name).get();
      // Batch sınırı 500; 400'erlik güvenli gruplar.
      for (var i = 0; i < snapshot.docs.length; i += 400) {
        final batch = firestore.batch();
        for (final doc in snapshot.docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    // 2b) KÖK koleksiyonlardaki kendi kayıtları: `folderShares` (sahip
    // olduğum paylaşımlar) ve `userDirectory` (e-posta → uid kaydım).
    //
    // **BİLİNEN SINIR (client-only mimari, Cloud Function yok):** bu adım
    // yalnız KENDİ dokümanlarımı temizler. Başka bir kullanıcının `friends`
    // alt koleksiyonundaki bana ait ayna kaydı ya da benim paylaştığım bir
    // klasörün arkadaşımın ekranındaki referansı burada SİLİNMEZ — o
    // kullanıcının kendi koleksiyonuna yazma yetkim yok (kural yalnız kabul
    // akışı için dar bir istisna tanıyor, silme için değil). Kalıntı zararsız
    // (isim/e-posta + artık var olmayan bir uid); firestore.rules zaten yeni
    // erişim vermez, karşı taraf bir dahaki senkronda ya da kendi
    // kaldırmasında temizlenir.
    final shares = await firestore
        .collection(AppConstants.folderSharesCollection)
        .where('ownerId', isEqualTo: uid)
        .get();
    for (var i = 0; i < shares.docs.length; i += 400) {
      final batch = firestore.batch();
      for (final doc in shares.docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    final email = user.email;
    if (email != null && email.trim().isNotEmpty) {
      await firestore
          .collection(AppConstants.userDirectoryCollection)
          .doc(email.trim().toLowerCase())
          .delete()
          .catchError((_) {});
    }

    await userDoc.delete();

    // 3) Auth hesabı. Firebase güvenlik gereği taze oturum ister; oturum
    // eskiyse yeniden Google girişi yaptırılıp tekrar denenir.
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code != 'requires-recent-login') rethrow;
      // Anonim hesapta Google'a yönlendirme YANLIŞ hesabı siler: giriş yeni
      // bir uid açar ve delete() o hesabı götürür (asıl anonim kayıt yetim
      // kalır). Aynı risk, istemde FARKLI Google hesabı seçilirse de var —
      // silmeden önce uid'in silinmek istenenle aynı olduğu doğrulanır.
      if (user.isAnonymous) rethrow;
      await _auth.signInWithGoogle();
      final fresh = FirebaseAuth.instance.currentUser;
      if (fresh == null || fresh.uid != uid) {
        throw FirebaseAuthException(
          code: 'user-mismatch',
          message: 'Yeniden giriş farklı bir hesapla yapıldı; silme iptal.',
        );
      }
      await fresh.delete();
    }

    // Yerel oturum kalıntısını temizle (google_sign_in oturumu vb.);
    // hesap zaten silindiği için hatası önemsizdir.
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  Future<void> _deleteStorageFolder(Reference ref) async {
    final ListResult listing;
    try {
      listing = await ref.listAll();
    } catch (_) {
      return; // Klasör hiç oluşmamış olabilir.
    }
    await Future.wait([
      for (final item in listing.items) item.delete().catchError((Object _) {}),
    ]);
    for (final prefix in listing.prefixes) {
      await _deleteStorageFolder(prefix);
    }
  }
}
