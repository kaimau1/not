import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';

/// **ORTAK NOT** — kullanıcı isteği 2026-09-22: "ortak not butonu keepteki
/// gibi". Klasör paylaşımının (bkz. `FoldersRepository`) TEK NOT düzeyindeki
/// karşılığı: sahip notu arkadaşlarıyla paylaşır, onlar notu kendi ana
/// ekranlarında "Benimle paylaşılanlar" altında görür ve CANLI düzenler.
///
/// Not TAŞINMAZ, kopyalanmaz: sahibinin `users/{sahip}/notes/{id}` altında
/// kalır; ortak çalışanlar oraya `?owner=` yoluyla yazar (editör bunu klasör
/// paylaşımından zaten biliyor, bkz. `NoteEditorScreen.ownerId`). Erişim
/// sorusunun cevabı bu aynada durur — kurallar tek `get()` ile okur.
///
/// Keep'le aynı karar: davet/kabul adımı YOK, eklenen kişi notu hemen görür.
/// Klasör paylaşımındaki kabul akışı bir ALANI (klasör) ortaklaştırıyordu;
/// tek not için o tören ağır kalıyordu. Seçim yalnız ARKADAŞ listesinden
/// yapılır — rastgele birine not yağdırmak mümkün değil.
class NoteShare {
  const NoteShare({
    required this.ownerId,
    required this.noteId,
    this.ownerName = '',
    this.sharedWith = const [],
    this.names = const {},
  });

  final String ownerId;
  final String noteId;

  /// Sahibin görünen adı — ortak çalışan "kim paylaştı"yı buradan okur;
  /// sahibin kullanıcı dokümanını okuma izni yok.
  final String ownerName;

  /// Notu canlı gören/düzenleyen kişilerin uid'leri (sahip HARİÇ).
  final List<String> sharedWith;

  /// uid → görünen ad. Ortak çalışanlar birbirini tanısın diye sahip yazar
  /// (arkadaş listesini yalnız sahip görüyor).
  final Map<String, String> names;

  String get id => shareIdOf(ownerId, noteId);

  static String shareIdOf(String ownerId, String noteId) =>
      '${ownerId}_$noteId';

  factory NoteShare.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return NoteShare(
      ownerId: map['ownerId'] as String? ?? '',
      noteId: map['noteId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      sharedWith: [
        for (final uid in (map['sharedWith'] as List<dynamic>? ?? const []))
          if (uid is String) uid,
      ],
      names: {
        for (final e
            in ((map['names'] as Map<String, dynamic>?) ?? const {}).entries)
          if (e.value is String) e.key: e.value as String,
      },
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'noteId': noteId,
    'ownerName': ownerName,
    'sharedWith': sharedWith,
    'names': names,
  };
}

final noteSharesRepositoryProvider = Provider<NoteSharesRepository?>((ref) {
  final uid = ref.watch(currentUidProvider);
  final user = ref.watch(authStateProvider).value;
  if (uid == null || user == null) return null;
  final name = user.displayName?.trim() ?? '';
  return NoteSharesRepository(
    FirebaseFirestore.instance,
    uid: uid,
    name: name.isNotEmpty ? name : (user.email ?? ''),
  );
});

/// BENİM paylaştığım notlar: notId → ayna. Kart rozeti ve editördeki
/// ortak çalışan düğmesi buradan okur (not başına ayrı dinleyici açmamak
/// için tek sorgu).
final myNoteSharesProvider = StreamProvider<Map<String, NoteShare>>((ref) {
  final repo = ref.watch(noteSharesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchMine();
});

/// BAŞKALARININ benimle paylaştığı notlar.
final sharedNotesWithMeProvider = StreamProvider<List<NoteShare>>((ref) {
  final repo = ref.watch(noteSharesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchSharedWithMe();
});

/// Tek bir notun aynası (sahip + not kimliğiyle). Ortak çalışan kendi
/// açtığı notun kimlerle paylaşıldığını buradan görür.
final noteShareProvider =
    StreamProvider.family<NoteShare?, ({String ownerId, String noteId})>((
      ref,
      key,
    ) {
      final repo = ref.watch(noteSharesRepositoryProvider);
      if (repo == null) return const Stream.empty();
      return repo.watch(key.ownerId, key.noteId);
    });

class NoteSharesRepository {
  NoteSharesRepository(this._firestore, {required this.uid, this.name = ''});

  final FirebaseFirestore _firestore;
  final String uid;
  final String name;

  CollectionReference<Map<String, dynamic>> get _shares =>
      _firestore.collection(AppConstants.noteSharesCollection);

  Stream<Map<String, NoteShare>> watchMine() => _shares
      .where('ownerId', isEqualTo: uid)
      .snapshots()
      .map(
        (snap) => {
          for (final share in snap.docs.map(NoteShare.fromDoc))
            if (share.sharedWith.isNotEmpty) share.noteId: share,
        },
      );

  Stream<List<NoteShare>> watchSharedWithMe() => _shares
      .where('sharedWith', arrayContains: uid)
      .snapshots()
      .map((snap) => [for (final doc in snap.docs) NoteShare.fromDoc(doc)]);

  Stream<NoteShare?> watch(String ownerId, String noteId) => _shares
      .doc(NoteShare.shareIdOf(ownerId, noteId))
      .snapshots()
      // Ayna yoksa ya da okuma reddedildiyse (paylaşımdan çıkarıldım) not
      // "paylaşılmamış" sayılır; akış hata verip ekranı düşürmesin.
      .map((doc) => doc.exists ? NoteShare.fromDoc(doc) : null)
      .handleError((Object _) {});

  /// Sahip: notun ortak çalışan listesini TOPTAN yazar. Liste boşalırsa ayna
  /// silinir — "paylaşılmamış not" ile "boş listeli ayna" ayrı durumlar
  /// olmasın.
  Future<void> setCollaborators(
    String noteId,
    Map<String, String> collaborators,
  ) async {
    final doc = _shares.doc(NoteShare.shareIdOf(uid, noteId));
    if (collaborators.isEmpty) {
      await doc.delete();
      return;
    }
    await doc.set(
      NoteShare(
        ownerId: uid,
        noteId: noteId,
        ownerName: name,
        sharedWith: collaborators.keys.toList(),
        names: collaborators,
      ).toMap(),
    );
  }

  /// Ortak çalışan: paylaşımdan KENDİNİ çıkarır. `arrayRemove` — mevcut
  /// listeyi okumadan yalnız kendi satırına dokunur (kural da yalnız bunu
  /// izin veriyor).
  Future<void> leave(String ownerId, String noteId) =>
      _shares.doc(NoteShare.shareIdOf(ownerId, noteId)).update({
        'sharedWith': FieldValue.arrayRemove([uid]),
      });
}
