part of 'notes_repository.dart';

/// Notların eklerinin BULUTTA kapladığı toplam alan (bayt).
///
/// Görüntülü notlar sayılmaz: Storage'a hiç yüklenmiyorlar (bkz.
/// [AttachmentKind.video]), yani depolama faturasına da girmiyorlar.
int cloudAttachmentBytes(List<Note> notes) {
  var total = 0;
  for (final note in notes) {
    // Yalnız bu cihazdaki notun ekleri bulutta yer tutmaz.
    if (note.localOnly) continue;
    for (final attachment in note.attachments) {
      // Metin eki de: içeriği not belgesinde, Storage'da değil.
      if (attachment.skipsUpload) continue;
      // Drive'daki ek Storage'da yer tutmaz. KÖK NEDEN (2026-11-02, "web'de
      // ekler yüklenmiyor"): web kotası Storage'a göre ama sayaç Drive'daki
      // ekleri de sayıyordu; 50 MB'ı aşan Google hesabı web'den hiç ek
      // yükleyemiyordu (StorageFullException).
      if (attachment.isInDrive && !attachment.isUploaded) continue;
      total += attachment.sizeBytes;
    }
  }
  return total;
}

/// Kullanılan bulut depolama alanı (bayt) — tavan denetiminin ve Ayarlar'daki
/// göstergenin kaynağı.
///
/// Çöp kutusundaki notlar SAYILMAZ: sayılsaydı "yer açmak için sil" işe
/// yaramaz görünürdü (çöp 30 gün sonra boşalıyor). Karşılığında gerçek Storage
/// kullanımı bu sayının biraz üstünde olabilir; istemci tarafı sayım zaten
/// yaklaşık (bkz. [AppConstants.maxFreeStorageBytes]).
final storageUsedBytesProvider = Provider<int>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  return cloudAttachmentBytes(notes);
});

/// Çöp kutusundaki (soft-delete edilmiş) notlar.
///
/// autoDispose ŞART: watchTrash tüm koleksiyonu dinleyen İKİNCİ bir
/// dinleyicidir. Kalıcı provider'da çöp ekranı bir kez açılınca oturum boyu
/// açık kalıyor, her not düzenlemesi koleksiyonun ikinci kez indirilip
/// ayrıştırılmasına mal oluyordu. Ekran kapanınca dinleyici de kapanır.
final trashStreamProvider = StreamProvider.autoDispose<List<Note>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchTrash();
});

/// Tek bir notun canlı akışı (editör bunu izler).
final noteStreamProvider = StreamProvider.autoDispose.family<Note?, String>((
  ref,
  noteId,
) {
  if (Diagnostics.enabled) {
    Diagnostics.openNoteStreams++;
    ref.onDispose(() => Diagnostics.openNoteStreams--);
  }
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchNote(noteId);
});

/// Listeden gelen (bölünmüşse HAFİF) notu tam hâline getirir (F3.13);
/// [ownerId] doluysa not onun koleksiyonundandır (paylaşılan klasör).
Future<Note> hydrateNote(WidgetRef ref, Note note, {String? ownerId}) {
  if (!needsHydrate(note)) return Future.value(note);
  final repo = ownerId == null
      ? ref.read(notesRepositoryProvider)
      : NotesRepository(FirebaseFirestore.instance, ownerId);
  return repo?.hydrate(note) ?? Future.value(note);
}

/// **BAŞKASININ notunun** canlı akışı — paylaşılan klasördeki not, sahibinin
/// koleksiyonunda yaşıyor (bkz. `NoteFolder.ownerId`). [noteStreamProvider]
/// her zaman GİRİŞ YAPMIŞ kullanıcının koleksiyonuna bakar; paylaşılan bir
/// notu onunla açmak "not bulunamadı" demekti ve editördeki her yazım kendi
/// koleksiyonumda HAYALET bir kopya yaratıyordu.
final ownedNoteStreamProvider = StreamProvider.autoDispose
    .family<Note?, ({String ownerId, String noteId})>(
      (ref, key) => NotesRepository(
        FirebaseFirestore.instance,
        key.ownerId,
      ).watchNote(key.noteId),
    );

/// [pendingWritesProvider]'ın başka bir sahibin notu için karşılığı.
final ownedPendingWritesProvider = StreamProvider.autoDispose
    .family<bool, ({String ownerId, String noteId})>(
      (ref, key) => NotesRepository(
        FirebaseFirestore.instance,
        key.ownerId,
      ).watchPendingWrites(key.noteId),
    );

/// Editördeki senkron göstergesi: true = yerel değişiklik sunucuya yazılmayı
/// bekliyor.
final pendingWritesProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  noteId,
) {
  final repo = ref.watch(notesRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchPendingWrites(noteId);
});


/// Sorgu anlık görüntülerini ARTIMLI ayrıştırır: yalnız değişen belgeler
/// `Note.fromDoc`tan geçer (bkz. [NotesRepository.watchNotes]). Akış başına
/// bir örnek.
class _IncrementalNotes {
  final _cache = <String, Note>{};

  List<Note> apply(QuerySnapshot<Map<String, dynamic>> snapshot) {
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) {
        _cache.remove(change.doc.id);
      } else {
        _cache[change.doc.id] = Note.fromDoc(change.doc);
      }
    }
    return _cache.values.toList();
  }
}

/// Senkron kapatılırken bir ek bu cihaza indirilemedi (çevrimdışı ya da
/// buluttaki dosya yok). Not OLDUĞU GİBİ bırakıldı.
class LocalOnlyException implements Exception {
  const LocalOnlyException();
}

enum NotePartKind { body, items, pageNotes, attachment }

/// Notun boyut kalemi (bkz. [NotesRepository.largestPart]).
class NotePart {
  const NotePart(this.kind, this.name, this.bytes);

  final NotePartKind kind;

  /// Ek ise dosya adı; öbür kalemlerde boş.
  final String name;
  final int bytes;
}

/// Not yazımıyla ilgili kullanıcıya söylenmesi gereken durum (F1.6).
class NoteWriteIssue {
  const NoteWriteIssue.tooLarge({
    required this.noteId,
    required int this.bytes,
    required NotePart this.largest,
  }) : reason = null;

  const NoteWriteIssue.rejected({
    required this.noteId,
    required String this.reason,
  }) : bytes = null,
       largest = null;

  final String noteId;
  final int? bytes;
  final NotePart? largest;

  /// Red nedeni (Firestore hata kodu; boyut reddinde `too-large`).
  final String? reason;

  bool get isRejected => reason != null;
}

/// Firestore belge verisinin derin eşitliği (Map/List iç içe; diğer
/// değerler `==` — `Timestamp`, `GeoPoint`, `Blob` değer eşitliği taşır).
@visibleForTesting
bool deepDataEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !deepDataEquals(e.value, b[e.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepDataEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Bir belgenin tek `includeMetadataChanges` dinleyicisi, birden çok aboneye
/// dağıtılır; geç gelen abone son anlık görüntüyü hemen alır (F22.6).
class _DocHub {
  _DocHub(this.ref, this._onEmpty);

  final DocumentReference<Map<String, dynamic>> ref;
  final void Function() _onEmpty;
  final _sinks = <StreamController<DocumentSnapshot<Map<String, dynamic>>>>[];
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  DocumentSnapshot<Map<String, dynamic>>? _last;

  Stream<DocumentSnapshot<Map<String, dynamic>>> stream() {
    late StreamController<DocumentSnapshot<Map<String, dynamic>>> c;
    c = StreamController(
      onListen: () {
        _sinks.add(c);
        final last = _last;
        if (last != null) c.add(last);
        if (_sub == null) {
          NotesRepository.debugSharedDocListeners++;
          _sub = ref
              .snapshots(includeMetadataChanges: true)
              .listen(
                (doc) {
                  _last = doc;
                  for (final s in List.of(_sinks)) {
                    s.add(doc);
                  }
                },
                onError: (Object e, StackTrace st) {
                  for (final s in List.of(_sinks)) {
                    s.addError(e, st);
                  }
                },
              );
        }
      },
      onCancel: () async {
        _sinks.remove(c);
        if (_sinks.isNotEmpty) return;
        if (_sub == null) return;
        final cancelled = _sub?.cancel();
        _sub = null;
        _last = null;
        NotesRepository.debugSharedDocListeners--;
        _onEmpty();
        await cancelled;
      },
    );
    return c.stream;
  }
}

/// Not belgesi + ağır belge + v2 mürekkebi ([NotesRepository._hydratedDoc]).
typedef _NoteDocs = ({
  DocumentSnapshot<Map<String, dynamic>> doc,
  Map<String, dynamic>? heavy,
  Map<String, List<InkStroke>>? ink,
  bool loaded,
});

/// Not tam değil mi: bölünmüş ağır kısmı ya da v2 mürekkebi (F61.5) henüz
/// okunmadı. Hafif listedeki v2 not `heavyRef` taşımayabilir; `inkV`
/// tanınmayan alan olarak [Note.extras]'ta durur.
bool needsHydrate(Note note) =>
    !note.heavyLoaded && (note.heavyRef || note.extras['inkV'] == 2);
