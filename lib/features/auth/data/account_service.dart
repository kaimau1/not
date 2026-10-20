import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../notes/data/drive_store.dart';
import '../../notes/data/local_notes_store.dart';
import '../../notes/domain/note_heavy.dart';
import '../presentation/auth_providers.dart';
import 'auth_repository.dart';

final accountServiceProvider = Provider<AccountService>(
  (ref) => AccountService(
    ref.watch(authRepositoryProvider),
    drive: () => ref.read(driveStoreProvider),
  ),
);

/// Hesabın ve tüm kullanıcı verilerinin kalıcı silinmesi. Google Play,
/// hesap oluşturan uygulamaların uygulama içinden hesap silme sunmasını
/// zorunlu kılar; bu servis Storage ekleri + Drive ekleri + Firestore
/// notları + paylaşım aynaları + arama kaydı + Auth hesabını sırayla ve geri
/// dönüşsüz siler.
class AccountService {
  AccountService(this._auth, {DriveStore? Function()? drive})
    // ignore: prefer_initializing_formals
    : _drive = drive;

  final AuthRepository _auth;
  final DriveStore? Function()? _drive;

  /// `users/{uid}` altında boşaltılan alt koleksiyonlar. TEK KAYNAK (F1.2):
  /// `account_service_test` kod tabanındaki her `collection(...)` adının ya
  /// burada, ya [deletedRootCollections]da, ya da [keptCollections]da
  /// olduğunu doğrular — yeni bir koleksiyon eklenip silmeye unutulursa test
  /// kırılır.
  static const deletedUserSubcollections = <String>[
    AppConstants.notesCollection,
    AppConstants.foldersCollection,
    AppConstants.friendsCollection,
    AppConstants.friendRequestsCollection,
    // Bana gönderilmiş, henüz kabul edilmemiş notlar da benim verimdir.
    AppConstants.inboxNotesCollection,
    'aiReports',
    // Ayar senkronu, kilit sırrı (F4.5, F4.8).
    'meta',
  ];

  /// Her notun altında boşaltılan alt koleksiyonlar (F3.13 ağır belge).
  static const deletedNoteSubcollections = <String>[kHeavyCollection];

  /// Kök koleksiyonlarda silinen KENDİ kayıtlarım (sırası
  /// [deleteAccountAndData]da): sahip olduğum `folderShares` (+ `messages`
  /// alt koleksiyonu + Storage `folderChats/{id}/`), `ownerId == uid` olan
  /// `noteShares`, `userDirectory/{eposta}`, `userSearch/{uid}`, `users/{uid}`.
  static const deletedRootCollections = <String>[
    AppConstants.folderSharesCollection,
    AppConstants.folderMessagesCollection,
    AppConstants.noteSharesCollection,
    AppConstants.userDirectoryCollection,
    'userSearch',
    AppConstants.usersCollection,
  ];

  /// BİLEREK silinmeyenler: `aiQuota/{uid}` ve `rateLimits/{uid}` kurallarda
  /// istemciye silmeye kapalı (silip sayacı sıfırlamak kotayı/hız sınırını
  /// delerdi) ve kişisel içerik taşımaz — yalnız sayaç + zaman damgası.
  static const keptCollections = <String>[
    AppConstants.aiQuotaCollection,
    'rateLimits',
    // Uygulama yapılandırması — kullanıcı verisi değil (bkz. app_update.dart).
    'config',
  ];

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
    // Yalnız bu cihazda tutulan notlar da hesabın verisidir.
    await LocalNotesStore.forUid(uid)?.clearAll();
    // Drive'daki ekler (bağlıysa): appDataFolder yalnız bu uygulamaya ait,
    // içindeki her şey bu hesabın ekleri. Bağlı değilse/ulaşılamazsa
    // atlanır — dosyalar kullanıcının KENDİ Drive'ında, uygulama silinince
    // Google hesabından "Uygulama verileri" ile silinebilir.
    await _drive?.call()?.deleteAllAppData();

    for (final name in deletedUserSubcollections) {
      final docs = (await userDoc.collection(name).get()).docs;
      // Notun alt koleksiyonları (ağır belge — F3.13) notla silinmez.
      if (name == AppConstants.notesCollection) {
        for (final note in docs) {
          for (final sub in deletedNoteSubcollections) {
            await _deleteDocs(
              firestore,
              (await note.reference.collection(sub).get()).docs,
            );
          }
        }
      }
      await _deleteDocs(firestore, docs);
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
    for (final share in shares.docs) {
      // Sıra ÖNEMLİ: sohbet görsellerinin Storage kuralı üyeliği aynadan
      // okuyor — ayna silinince dosyalara artık kimse (ben de) dokunamaz.
      await _deleteStorageFolder(
        FirebaseStorage.instance.ref(
          '${AppConstants.folderChatStoragePrefix}/${share.id}',
        ),
      );
      final messages = await share.reference
          .collection(AppConstants.folderMessagesCollection)
          .get();
      await _deleteDocs(firestore, messages.docs);
    }
    await _deleteDocs(firestore, shares.docs);
    final noteShares = await firestore
        .collection(AppConstants.noteSharesCollection)
        .where('ownerId', isEqualTo: uid)
        .get();
    await _deleteDocs(firestore, noteShares.docs);
    // Silinen kullanıcı aramada çıkmaya devam etmesin.
    await firestore
        .collection('userSearch')
        .doc(uid)
        .delete()
        .catchError((_) {});
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

  /// Batch sınırı 500; 400'erlik güvenli gruplar.
  static Future<void> _deleteDocs(
    FirebaseFirestore firestore,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    for (var i = 0; i < docs.length; i += 400) {
      final batch = firestore.batch();
      for (final doc in docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
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
