part of 'notes_providers.dart';

/// Arşivlenmiş notlar (arşiv ekranı için). Gizli klasör bastırması burada da
/// geçerli — arşiv, gizli notların içeriğini doğrulamasız sızdırıyordu.
final archivedNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  final box = ref.watch(_archivedNotesBox);
  return notes.whenData(
    (list) => box.keep([
      for (final n in list)
        if (n.archivedAt != null &&
            (n.folderId == null || !suppressed.contains(n.folderId)))
          n,
    ], sameInstances),
  );
});

/// Geri bağlantı O(1) dizini (K-26): her not açılışında ve anlık görüntüde
/// tüm notları baştan taramak yerine liste başına tek geçiş.
final backlinksIndexProvider = Provider<Map<String, List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  return buildBacklinksIndex(notes);
});

final _archivedNotesBox = Provider<StableBox<List<Note>>>(
  (ref) => StableBox(),
);

/// **BİR KLASÖRÜN İÇİ** (klasörün kendi sayfası — bkz. `FolderScreen`).
///
/// Ana ekranın süzgeçlerinden (arama, durum, etiket) BAĞIMSIZ: klasöre giren
/// kullanıcı orada duran her şeyi görmek ister; dışarıda bırakılmış bir
/// süzgecin klasörün içini de budaması "notum kayboldu" demekti. Yalnız
/// sıralama ortak — kullanıcının seçtiği düzen her yerde aynı olsun.
final folderNotesProvider = Provider.autoDispose.family<AsyncValue<List<Note>>, String>((
  ref,
  folderId,
) {
  final notes = ref.watch(notesStreamProvider);
  final sort = ref.watch(noteSortProvider);
  final activity = sort == NoteSort.active
      ? ref.watch(noteActivityProvider)
      : const <String, int>{};
  final box = ref.watch(_folderNotesBox(folderId));
  return notes.whenData(
    (list) => box.keep(
      _sortedNotes(
        [
          for (final n in list)
            if (n.folderId == folderId && n.archivedAt == null && !n.isEmpty)
              n,
        ],
        sort,
        activity,
      ),
      sameInstances,
    ),
  );
});

final _folderNotesBox = Provider.autoDispose.family<StableBox<List<Note>>, String>(
  (ref, _) => StableBox(),
);

/// **PAYLAŞILAN bir klasörün içi.** [folderNotesProvider]'ın ikizi — tek
/// fark, notların BENİM koleksiyonumdan değil klasörün SAHİBİNİN
/// koleksiyonundan okunması. Anahtar `(ownerId, folderId)`: aynı ekranın
/// (`FolderScreen`) hem kendi hem paylaşılan klasörlerde çalışabilmesi için.
///
/// Kullanıcı isteği 2026-08-18: "kişiler bağlanır notları ortak görür."
/// Sahiplik notların Firestore konumunu belirler (bkz. `NoteFolder.ownerId`
/// açıklaması) — paylaşılan kullanıcı buraya not eklerse o not de SAHİBİNİN
/// koleksiyonuna yazılır, kopya oluşmaz.
final sharedFolderNotesProvider =
    StreamProvider.autoDispose.family<List<Note>, ({String ownerId, String folderId})>((
      ref,
      key,
    ) {
      final repo = NotesRepository(FirebaseFirestore.instance, key.ownerId);
      // **KLASÖRE DARALTILMIŞ sorgu** (`watchNotes` DEĞİL): sahibin tüm
      // notlarını istemek Firestore kuralları tarafından TÜMDEN reddediliyor
      // ve ekran "Missing or insufficient permissions" gösteriyordu — kök
      // neden ve gerekçe `NotesRepository.watchFolderNotes`ta.
      return repo
          .watchFolderNotes(key.folderId)
          .map(
            (list) => _sortedNotes(
              [
                for (final n in list)
                  if (n.archivedAt == null && !n.isEmpty) n,
              ],
              NoteSort.updated,
            ),
          );
    });

/// Arama + filtre + etiket + klasör uygulanmış, arşiv dışı not listesi.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  // Geciktirilmiş sorgu: her tuş vuruşunda tüm notları taramamak için
  // (bkz. debouncedSearchQueryProvider).
  final query = foldForSearch(ref.watch(debouncedSearchQueryProvider).trim());
  final filter = ref.watch(noteFilterProvider);
  final tag = ref.watch(selectedTagProvider);
  final folderId = ref.watch(selectedFolderProvider);
  final showAll = ref.watch(showAllNotesProvider);
  final sort = ref.watch(noteSortProvider);
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  // Sayaçlar YALNIZ o sıralamada izlenir: her not açılışında sayaç değişiyor,
  // koşulsuz izlense süzgeç sağlayıcısı (ve tüm dashboard) boşuna yeniden
  // hesaplanırdı.
  final activity = sort == NoteSort.active
      ? ref.watch(noteActivityProvider)
      : const <String, int>{};
  final box = ref.watch(_filteredNotesBox);
  final held = ref.watch(sortHeldNoteIdsProvider);
  final anchors = ref.watch(_sortAnchorsBox);
  final previewHeld = ref.watch(heldNotePreviewProvider);

  return notes.whenData((list) {
    _pruneSearchBodyCache(list);
    // F68.1: az önce değişen açık not listede eski örneğiyle durur.
    if (previewHeld.isNotEmpty) {
      list = [for (final n in list) previewHeld[n.id] ?? n];
    }
    anchors.removeWhere((id, _) => !held.contains(id));
    if (held.length > anchors.length) {
      for (final n in list) {
        if (held.contains(n.id)) anchors.putIfAbsent(n.id, () => n.updatedAt);
      }
    }
    // Boş notlar (yeni oluşturulup hiç doldurulmamış) listede gösterilmez;
    // editörden çıkışta zaten silinirler, arka plan temizliği de kalıntıyı
    // toplar. Böylece boş kart dashboard'da hiç belirmez.
    //
    // Gizli klasördeki notlar da burada düşer: arama dahil hiçbir ana ekran
    // görünümünde belirmezler (bkz. [hiddenFoldersRevealedProvider]).
    var result = [
      for (final n in list)
        if (n.archivedAt == null &&
            !n.isEmpty &&
            !suppressed.contains(n.folderId))
          n,
    ];
    if (folderId != null) {
      result = [
        for (final n in result)
          if (n.folderId == folderId) n,
      ];
    } else if (!showAll &&
        query.isEmpty &&
        tag == null &&
        filter == NoteFilter.all) {
      // **KLASÖRDEKİ NOT ANA EKRANDA DURMAZ** (kullanıcı isteği 2026-08-18:
      // "klasör dashboard'ta bir not gibi yer kaplar, basılınca kendi
      // içerisindeki notlar görülür ayrı bir sayfada"). Klasör artık bir
      // süzgeç değil bir YER: notu klasöre koymak onu ana ekrandan KALDIRIR,
      // yoksa aynı not iki yerde birden durur ve klasörün "toplama" işi
      // anlamsızlaşırdı.
      //
      // ARAMA VE SÜZGEÇ BUNUN DIŞINDA: bir şey ARAYAN kullanıcı klasörün
      // içindekini de bulmalı — "notum kayboldu" en pahalı hata. "Tümü"
      // çipi ([showAllNotesProvider]) açıkken de klasördekiler görünür.
      result = [
        for (final n in result)
          if (n.folderId == null) n,
      ];
    }
    if (tag != null) {
      result = [
        for (final n in result)
          if (n.tags.contains(tag)) n,
      ];
    }
    result = [
      for (final n in result)
        if (noteMatchesFilter(n, filter)) n,
    ];
    if (query.isNotEmpty) {
      // **EK İÇERİĞİ** (seçenek, varsayılan kapalı): açıkken PDF metni ve
      // görsel OCR'ı da aranır — bkz. [attachmentTextProvider].
      final extra = ref.watch(attachmentFoldedTextProvider);
      result = [
        for (final n in result)
          if (_matches(n, query) || (extra[n.id]?.contains(query) ?? false))
            n,
      ];
    }
    // İçerik (not örnekleri ve sıraları) aynıysa ÖNCEKİ liste (F2.1):
    // ilgisiz bir yayın (ör. arşivdeki/klasördeki notun yazımı) ana ekranı
    // yeniden kurmaz.
    return box.keep(
      _sortedNotes(result, sort, activity, anchors),
      sameInstances,
    );
  });
});

final _filteredNotesBox = Provider<StableBox<List<Note>>>(
  (ref) => StableBox(),
);

/// Seçili ölçüte göre notları sıralar. [NoteSort.manual] akıştan gelen sırayı
/// (orderIndex → updatedAt) korur; başlığa göre sıralamada başlıksız notlar
/// sona düşer.
List<Note> _sortedNotes(
  List<Note> notes,
  NoteSort sort, [
  Map<String, int> activity = const {},
  Map<String, DateTime?> anchors = const {},
]) {
  // Tutulan (editörü açık) notun sıralama zamanı açıldığı andaki değer.
  DateTime? upd(Note n) =>
      anchors.containsKey(n.id) ? anchors[n.id] : n.updatedAt;
  int dateDesc(DateTime? a, DateTime? b) {
    final at = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  }

  if (sort == NoteSort.manual) {
    // Akışın sırası (depo: sabit → orderIndex → updatedAt). Tutulan not
    // tazelendiyse aynı ölçütle, onun için açılış zamanıyla yeniden dizilir.
    final drifted = anchors.isNotEmpty &&
        notes.any(
          (n) => anchors.containsKey(n.id) && anchors[n.id] != n.updatedAt,
        );
    if (!drifted) return notes;
    return [...notes]..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final byOrder = a.orderIndex.compareTo(b.orderIndex);
      if (byOrder != 0) return byOrder;
      return dateDesc(upd(a), upd(b));
    });
  }
  final list = [...notes];

  switch (sort) {
    case NoteSort.manual:
      break;
    case NoteSort.updated:
      list.sort((a, b) => dateDesc(upd(a), upd(b)));
    case NoteSort.created:
      list.sort((a, b) => dateDesc(a.createdAt, b.createdAt));
    case NoteSort.title:
      list.sort((a, b) {
        final at = a.title.trim().toLowerCase();
        final bt = b.title.trim().toLowerCase();
        if (at.isEmpty && bt.isEmpty) return dateDesc(upd(a), upd(b));
        if (at.isEmpty) return 1;
        if (bt.isEmpty) return -1;
        return at.compareTo(bt);
      });
    // Renge göre: aynı renkli notlar bir arada. Renksiz (none) notlar SONA
    // düşer — renk verilmemiş olması bir renk değil, "belirtilmemiş"tir;
    // başa gelseydi kullanıcı renkli grupları görmek için kaydırırdı.
    case NoteSort.color:
      list.sort((a, b) {
        final ai = a.color == NoteColor.none ? 999 : a.color.index;
        final bi = b.color == NoteColor.none ? 999 : b.color.index;
        if (ai != bi) return ai.compareTo(bi);
        return dateDesc(upd(a), upd(b));
      });
    // En çok çalışılan: sayaç büyükten küçüğe. Hiç açılmamış notlar (sayaç
    // yok = 0) sona düşer ve KENDİ ARALARINDA son güncellenene göre dizilir —
    // yeni bir not, sayacı sıfır diye listenin en dibine gömülmesin.
    case NoteSort.active:
      list.sort((a, b) {
        final av = activity[a.id] ?? 0;
        final bv = activity[b.id] ?? 0;
        if (av != bv) return bv.compareTo(av);
        return dateDesc(upd(a), upd(b));
      });
  }
  return list;
}

/// Not başına "aranabilir gövde" önbelleği: `<notId> → (updatedAt, düz metin)`.
///
/// KÖK NEDEN (kasma): [_matches] her notun gövdesini ve HER MADDESİNİ
/// `stripRichMarkers`'tan geçiriyordu; o da işaret varsa metnin tamamını
/// ayrıştırıyor. Süzgeç, sorgu yazılı olduğu sürece HER Firestore anlık
/// görüntüsünde (yani editörde yazarken de) tüm notlar için baştan koşuyordu.
/// Debounce yalnız tuş vuruşunu bastırıyor, snapshot'ı bastırmıyor.
///
/// Anahtar `updatedAt`: not değişmedikçe yeniden ayrıştırma yok, bayatlama da
/// yok. Küresel ve sınırsız DEĞİL — girdi sayısı not sayısıyla sınırlı.
/// Üçüncü alan işaretleri sökülmüş GÖVDE: kartın arama kesiti (F21.3) onu
/// buradan alır (işaretsiz gövdede aynı örnek, kopya değil).
final Map<String, (DateTime?, String, String)> _searchBodyCache = {};

/// Hesap değişince (F5.5): önbellek her notun katlanmış TAM metnini
/// (transkriptler dahil) tutuyor — öbür hesabınki bellekte kalmasın.
void clearSearchBodyCache() => _searchBodyCache.clear();

/// Silinen notların girdileri kalmasın (F5.5). Ucuz denetim önce: önbellek
/// canlı listeden büyük değilse dokunulmaz.
void _pruneSearchBodyCache(List<Note> live) {
  if (_searchBodyCache.length <= live.length) return;
  final ids = {for (final n in live) n.id};
  _searchBodyCache.removeWhere((id, _) => !ids.contains(id));
}

@visibleForTesting
int get searchBodyCacheSize => _searchBodyCache.length;

@visibleForTesting
String searchableBodyForTest(Note note) => _searchableBody(note);

String _searchableBody(Note note) => _searchEntry(note).$2;

/// Sorgunun not GÖVDESİNDEKİ ilk eşleşmesi (F21.3, kartın arama kesiti):
/// işaretleri sökülmüş gövde ve eşleşmenin oradaki konumu; gövdede yoksa ya
/// da not kilitliyse null. Süzgecin önbelleğinden — kart uzun gövdeyi her
/// tuşta yeniden taramaz. [query] [foldForSearch] ile katlanmış gelir.
(String, int)? bodySearchMatch(Note note, String query) {
  if (query.isEmpty || note.locked) return null;
  final (_, folded, plain) = _searchEntry(note);
  final index = folded.indexOf(query);
  return index >= 0 && index + query.length <= plain.length
      ? (plain, index)
      : null;
}

(DateTime?, String, String) _searchEntry(Note note) {
  final cached = _searchBodyCache[note.id];
  if (cached != null && cached.$1 == note.updatedAt) return cached;
  final plainBody = stripRichMarkers(note.body);
  final buffer = StringBuffer(plainBody);
  for (final item in note.items) {
    buffer
      ..write('\n')
      ..write(stripRichMarkers(item.title))
      ..write('\n')
      ..write(stripRichMarkers(item.text));
  }
  // **ARŞİV DEFTERİNİN SAYFA ADLARI** (kullanıcı isteği 2026-09-04: "ana
  // sayfadaki aramada arşiv defterlerinin içeriğini arayabilmeli").
  // Sayfanın YAZISI zaten `items` içinde; ama sayfanın ADI kaydın ayrı bir
  // alanında duruyordu ve hiçbir aramaya girmiyordu — "Faturalar" sayfası
  // olan bir defter "fatura" aramasında çıkmıyordu.
  if (note.archiveGeneralName.trim().isNotEmpty) {
    buffer
      ..write('\n')
      ..write(note.archiveGeneralName);
  }
  for (final page in note.archivePages) {
    buffer
      ..write('\n')
      ..write(page);
  }
  // Sayfa balonlarının (PDF/sunum notlarındaki) metni de aranabilir: not
  // gövdesinde durmuyor ama kullanıcı için notun İÇERİĞİ.
  for (final text in note.pageNotes.values) {
    buffer
      ..write('\n')
      ..write(stripRichMarkers(text));
  }
  // TRANSKRİPTLER (metin ekleri): ses kaydında geçen bir söz, kaydı içeren
  // notu bulur — metin kayıtta duruyor, çıkarmak için hiçbir bedel yok.
  // Görsel AÇIKLAMALARI da (kullanıcının görsele yazdığı söz).
  for (final attachment in note.attachments) {
    if (attachment.caption.isNotEmpty) {
      buffer
        ..write('\n')
        ..write(attachment.caption);
    }
    if (attachment.kind != AttachmentKind.text) continue;
    buffer
      ..write('\n')
      ..write(attachment.text);
  }
  final entry = (note.updatedAt, foldForSearch(buffer.toString()), plainBody);
  _searchBodyCache[note.id] = entry;
  return entry;
}

/// **Not, arama sorgusuna uyuyor mu** — ana ekranın süzgeciyle AYNI kural.
///
/// Klasörün kendi sayfası da bunu kullanır (kullanıcı bulgusu 2026-09-01:
/// "klasör içerisinde … arama yok"): iki yerde iki farklı eşleşme kuralı
/// olsaydı aynı sorgu ana ekranda bulup klasörde bulamayabilirdi. [query]
/// [foldForSearch] ile KATLANMIŞ ve kırpılmış gelmelidir (çağıran bir kez
/// yapar, her not için değil) — Türkçe ı/I ve aksan farkı yok sayılır (F1.8).
bool noteMatchesQuery(Note note, String query) => _matches(note, query);

bool _matches(Note note, String query) {
  if (foldForSearch(note.title).contains(query)) return true;
  // Kilitli notun içeriği aramaya sızmasın; yalnızca başlıktan bulunur.
  if (note.locked) return false;
  // Arama biçim İŞARETLERİNİ görmez: "558" araması `**558**` yazan notu da
  // bulmalı (işaret metnin içinde taşınıyor, bkz. rich_text.dart).
  if (_searchableBody(note).contains(query)) return true;
  for (final attachment in note.attachments) {
    if (foldForSearch(attachment.fileName).contains(query)) return true;
  }
  for (final tag in note.tags) {
    if (foldForSearch(tag).contains(query)) return true;
  }
  return false;
}
