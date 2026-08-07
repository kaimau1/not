import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/rich_text.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_similarity.dart';
import '../domain/note_type.dart';

/// [others] = hiçbir klasöre ve etikete girmemiş notlar. Çip barındaki
/// klasör/etiket çipleri notları düzenli tutuyor ama düzene HİÇ girmemiş
/// notları görünür kılmıyordu; bu süzgeç "kalanlar"ı tek dokunuşta getirir.
/// Süz levhasının DURUM bölümü. `reminded` ve `locked` yeni tasarımla eklendi;
/// tür süzgeçleri (text/checklist/ordered) tasarımın listesinde yok ama
/// silinmedi — bugün kullanılan bir yetenek, levhada aynı bölümde duruyorlar.
enum NoteFilter {
  all,
  text,
  checklist,
  ordered,
  pinned,
  starred,
  reminded,
  locked,
  others,
}

/// Dashboard sıralama ölçütü. [manual] = akışın varsayılanı (elle sürükleme /
/// oluşturma sırası); diğerleri istemci tarafında yeniden sıralar.
enum NoteSort { manual, updated, created, title, color }

/// FAVORİ SÜZGEÇLER (kalıcı): kullanıcının Süz levhasında yıldızladığı
/// seçenekler. Ana ekranda "Süz" düğmesinin sağında tek dokunuşluk çip olarak
/// dururlar — sık kullanılan bir süzgeç için levhayı açmak gerekmesin.
///
/// Jeton biçimi tür + değer: `filter:starred`, `tag:iş`, `folder:<id>`,
/// `sort:title`. Tek düz metin kümesi olarak saklanır; klasör/etiket silinirse
/// jeton çözülemez ve ÇİZİLMEZ (temizlemeye gerek yok).
final favoriteFiltersProvider =
    NotifierProvider<FavoriteFiltersNotifier, Set<String>>(
      FavoriteFiltersNotifier.new,
    );

class FavoriteFiltersNotifier extends Notifier<Set<String>> {
  static const _key = 'favorite_filters';

  @override
  Set<String> build() =>
      (ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [])
          .toSet();

  void toggle(String token) {
    final next = {...state};
    if (!next.remove(token)) next.add(token);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next.toList());
  }

  bool contains(String token) => state.contains(token);
}

String filterFavoriteToken(NoteFilter filter) => 'filter:${filter.name}';
String tagFavoriteToken(String tag) => 'tag:$tag';
String folderFavoriteToken(String folderId) => 'folder:$folderId';
String sortFavoriteToken(NoteSort sort) => 'sort:${sort.name}';

/// Seçili sıralama ölçütü (kalıcı). Sabitlenmiş notlar dashboard'da yine ayrı
/// bir bölümde toplanır; sıralama her bölümün kendi içinde uygulanır.
final noteSortProvider = NotifierProvider<NoteSortNotifier, NoteSort>(
  NoteSortNotifier.new,
);

class NoteSortNotifier extends Notifier<NoteSort> {
  static const _key = 'note_sort';

  @override
  NoteSort build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return NoteSort.values.firstWhere(
      (s) => s.name == stored,
      orElse: () => NoteSort.manual,
    );
  }

  void set(NoteSort value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value.name);
  }
}

/// Ana ekran ızgarasının sütun sayısı. 0 = otomatik (ekran genişliğinden
/// hesaplanır); 1–4 arası değer kullanıcının iki parmakla yaptığı zoom
/// hareketiyle seçilir ve kalıcıdır.
final gridColumnsProvider = NotifierProvider<GridColumnsNotifier, int>(
  GridColumnsNotifier.new,
);

class GridColumnsNotifier extends Notifier<int> {
  static const _key = 'grid_columns';

  /// İki parmak zoom ile gezilebilen aralık.
  static const minColumns = 1;
  static const maxColumns = 4;

  @override
  int build() => ref.watch(sharedPreferencesProvider).getInt(_key) ?? 0;

  void set(int value) {
    final next = value <= 0 ? 0 : value.clamp(minColumns, maxColumns);
    if (next == state) return;
    state = next;
    ref.read(sharedPreferencesProvider).setInt(_key, next);
  }
}

/// Ana ekrandaki tarih grupları.
enum NoteBucket { today, thisWeek, earlier }

/// Notları son güncelleme tarihine göre üç kovaya böler; her kovanın kendi
/// içindeki sıra KORUNUR (çağıran zaten sıralanmış liste verir).
///
/// Sınırlar takvim gününe göre: "bugün" = [now] ile aynı gün, "bu hafta" =
/// son 7 günün başlangıcından bugüne kadar. Saat farkıyla değil gün farkıyla
/// hesaplanır — 23:59'da yazılan not ertesi sabah 00:01'de "bugün" olmamalı.
/// Tarihi olmayan not en eskiye düşer.
List<(NoteBucket, List<Note>)> dateBuckets(List<Note> notes, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(const Duration(days: 6));
  final result = {
    NoteBucket.today: <Note>[],
    NoteBucket.thisWeek: <Note>[],
    NoteBucket.earlier: <Note>[],
  };
  for (final note in notes) {
    final at = note.updatedAt;
    if (at == null) {
      result[NoteBucket.earlier]!.add(note);
      continue;
    }
    final day = DateTime(at.year, at.month, at.day);
    if (!day.isBefore(today)) {
      result[NoteBucket.today]!.add(note);
    } else if (!day.isBefore(weekStart)) {
      result[NoteBucket.thisWeek]!.add(note);
    } else {
      result[NoteBucket.earlier]!.add(note);
    }
  }
  return [for (final entry in result.entries) (entry.key, entry.value)];
}

/// Ana ekran ızgara mı liste mi (kullanıcı tercihi, kalıcı).
///
/// Izgara masonry kartlar, liste tek sütun kompakt satırlar. Sütun SAYISI
/// ayrı bir tercih ([gridColumnsProvider], iki parmak zoom) — liste görünümü
/// "1 sütunluk ızgara" DEĞİL, satır yerleşimi bambaşka.
final noteListViewProvider = NotifierProvider<NoteListViewNotifier, bool>(
  NoteListViewNotifier.new,
);

class NoteListViewNotifier extends Notifier<bool> {
  static const _key = 'note_list_view';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

/// Editörün dibindeki ek şeridi açık mı (kullanıcı tercihi, kalıcı)? Şerit
/// artık sayfanın altında durur ve kapatılabilir; tercih notlar arasında
/// korunur — her notta yeniden kapatmak gerekmesin.
final attachmentsExpandedProvider =
    NotifierProvider<AttachmentsExpandedNotifier, bool>(
      AttachmentsExpandedNotifier.new,
    );

class AttachmentsExpandedNotifier extends Notifier<bool> {
  static const _key = 'attachments_expanded';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

/// [duplicateNotesProvider]'ın trigram önbelleği: not içeriği değişmedikçe
/// kümeler yeniden hesaplanmaz. Ayrı bir autoDispose sağlayıcıda ki harita
/// örneği, duplicates sağlayıcısı her yeniden çalıştığında (her snapshot)
/// sıfırlanmasın; ikisi birlikte yaşayıp birlikte ölür.
final _trigramCacheProvider =
    Provider.autoDispose<Map<String, (DateTime?, Set<String>)>>((ref) => {});

/// Birbirinin kopyası olan not kümeleri (bkz. [duplicateNoteGroups]).
///
/// Sağlayıcıda: hesap O(n²) ve her çizimde yeniden yapılamaz. Riverpod
/// sonucu önbelleğe alır, yalnız not listesi değişince yeniden hesaplanır.
///
/// autoDispose ŞART: kalıcı sürümde AI Hub bir kez açılınca sağlayıcı oturum
/// boyu abone kalıyor ve kullanıcı BAŞKA bir notta yazarken bile her
/// snapshot'ta O(n²) kopya taraması dönüyordu. Ekran kapanınca durur.
final duplicateNotesProvider = Provider.autoDispose<List<List<Note>>>((ref) {
  // Gizli klasör bastırması burada da geçerli: kopya kümeleri gizli notun
  // başlığını/içeriğini doğrulamasız gösteriyordu ("Tümünü sil" onları çöpe
  // de atabiliyordu).
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  final notes = [
    for (final n in ref.watch(notesStreamProvider).value ?? const <Note>[])
      if (n.folderId == null || !suppressed.contains(n.folderId)) n,
  ];
  return duplicateNoteGroups(
    notes,
    trigramCache: ref.watch(_trigramCacheProvider),
  );
});

/// Gizli klasörlerin kimlikleri (bkz. [NoteFolder.hidden]).
final hiddenFolderIdsProvider = Provider<Set<String>>((ref) {
  final folders =
      ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
  return {
    for (final f in folders)
      if (f.hidden) f.id,
  };
});

/// Gizli klasörler bu oturumda gösteriliyor mu? Kalıcı DEĞİL: uygulama
/// yeniden açıldığında gizli klasörler yine saklıdır — "gizli" olmanın anlamı
/// bu. ⋮ → "Gizli klasörler" kimlik doğrulamasından sonra açar.
final hiddenFoldersRevealedProvider =
    NotifierProvider<HiddenFoldersRevealedNotifier, bool>(
      HiddenFoldersRevealedNotifier.new,
    );

class HiddenFoldersRevealedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Ana ekranda görünmesi gereken (gizli olmayan ya da gizliliği o oturumda
/// açılmış) notlar için süzgeç: kimliği bu kümede olan klasörün notları
/// listelerden ve aramadan düşer.
final suppressedFolderIdsProvider = Provider<Set<String>>((ref) {
  if (ref.watch(hiddenFoldersRevealedProvider)) return const <String>{};
  return ref.watch(hiddenFolderIdsProvider);
});

/// Seçili klasör (null = klasör filtresi yok).
final selectedFolderProvider =
    NotifierProvider<SelectedFolderNotifier, String?>(
      SelectedFolderNotifier.new,
    );

class SelectedFolderNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// Not kartlarının elle sıralama modu (⋮ → "Notları sırala").
///
/// Eskiden sürükle-sırala kalıcı olarak açıktı ve uzun basış SÜRÜKLEMEYİ
/// başlatıyordu; toplu seçim ise yalnızca parmak yerinde bırakılırsa (24 px
/// altı hareket) gerçekleşen bir yan üründü — kullanıcı seçmek isterken
/// kartı kazara taşıyordu. Artık uzun basış her zaman SEÇER; sıralama bu
/// bayrakla açılan ayrı bir moda çekildi.
final reorderModeProvider = NotifierProvider<ReorderModeNotifier, bool>(
  ReorderModeNotifier.new,
);

class ReorderModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Ana ekran mikrofon widget'ı (notlar://voice) dokunulunca ayarlanan
/// tüketilebilir bayrak; dashboard bunu görüp Sesli Not Asistanı'nı bas-başlat
/// modunda başlatır (ayrı /voice ekranı yerine tek tutarlı sistem).
/// [take] tam bir kez tüketir: uygulama başka ekrandayken gelen istek de
/// (dashboard henüz dinlemiyorken) kaybolmaz — dashboard mount olunca okur;
/// dashboard'a her dönüşte yeniden tetiklenmez (bayrak tüketilmiştir).
final voiceAutostartProvider = NotifierProvider<VoiceAutostartNotifier, bool>(
  VoiceAutostartNotifier.new,
);

class VoiceAutostartNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  /// İstek varsa true döner ve bayrağı düşürür (tek seferlik).
  bool take() {
    if (!state) return false;
    state = false;
    return true;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

/// [searchQueryProvider]'ın GECİKTİRİLMİŞ kopyası — süzme ve anlamsal arama
/// bunu izler, arama KUTUSU anlık olanı.
///
/// Kutu her tuş vuruşunda sorguyu güncelliyor; süzme doğrudan onu izleseydi
/// (eskiden öyleydi) her karakter tüm notların taranmasını, anlamsal modda da
/// AYRI BİR EMBEDDING HTTP İSTEĞİNİ tetiklerdi — 17 karakterlik bir arama 15
/// ağ isteği demekti (radyoyu her seferinde uyandırdığı için pil de yiyor).
/// Kullanıcı yazmayı bıraktıktan sonra tek güncelleme düşer; temizlenen sorgu
/// beklemeden yansır ki ekran anında normale dönsün.
final debouncedSearchQueryProvider =
    NotifierProvider<DebouncedSearchQueryNotifier, String>(
      DebouncedSearchQueryNotifier.new,
    );

class DebouncedSearchQueryNotifier extends Notifier<String> {
  static const _delay = Duration(milliseconds: 350);

  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(searchQueryProvider, (_, next) {
      _timer?.cancel();
      if (next.trim().isEmpty) {
        state = next;
        return;
      }
      _timer = Timer(_delay, () => state = next);
    });
    return ref.read(searchQueryProvider);
  }
}

final noteFilterProvider = NotifierProvider<NoteFilterNotifier, NoteFilter>(
  NoteFilterNotifier.new,
);

class NoteFilterNotifier extends Notifier<NoteFilter> {
  @override
  NoteFilter build() => NoteFilter.all;

  void set(NoteFilter value) => state = value;
}

/// Anlamsal (AI) arama modu açık mı?
final semanticSearchEnabledProvider =
    NotifierProvider<SemanticSearchEnabledNotifier, bool>(
      SemanticSearchEnabledNotifier.new,
    );

class SemanticSearchEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// Çoklu seçim modu: seçili not id'leri (boş küme = seçim modu kapalı).
/// Ana ekranın "şu nota bak" işareti: sesli asistan bir notu oluşturup
/// güncelleyince o notu görünür alana kaydırıp kısa süre vurgulamak için
/// kullanılır. Asistan "ekledim" diyor ama hangi nota eklediği görünmüyordu.
///
/// Vurgu kendiliğinden söner: kullanıcı kapatmakla uğraşmasın.
final focusedNoteProvider = NotifierProvider<FocusedNoteNotifier, String?>(
  FocusedNoteNotifier.new,
);

class FocusedNoteNotifier extends Notifier<String?> {
  static const _duration = Duration(seconds: 4);
  Timer? _timer;

  @override
  String? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void focus(String noteId) {
    _timer?.cancel();
    state = noteId;
    _timer = Timer(_duration, () => state = null);
  }

  void clear() {
    _timer?.cancel();
    state = null;
  }
}

final selectedNoteIdsProvider =
    NotifierProvider<SelectedNoteIdsNotifier, Set<String>>(
      SelectedNoteIdsNotifier.new,
    );

class SelectedNoteIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    state = state.contains(id)
        ? {
            for (final s in state)
              if (s != id) s,
          }
        : {...state, id};
  }

  void clear() => state = const {};
}

/// Seçili etiket (null = etiket filtresi yok).
final selectedTagProvider = NotifierProvider<SelectedTagNotifier, String?>(
  SelectedTagNotifier.new,
);

class SelectedTagNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

/// Aktif (arşivlenmemiş) notlarda geçen tüm etiketler, alfabetik.
/// Gizli klasördeki notların etiketleri sızmaz — çip barında görünen bir
/// etiket, gizli notun varlığını ele verirdi.
final allTagsProvider = Provider.autoDispose<List<String>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  final tags = <String>{
    for (final note in notes)
      if (note.archivedAt == null && !suppressed.contains(note.folderId))
        ...note.tags,
  };
  final sorted = tags.toList()..sort();
  return sorted;
});

// Etiket → kullanım sayısı sağlayıcısı (tagCountsProvider) kaldırıldı: tek
// tüketicisi çip satırıydı ("+N" arkasına gizlenen etiketleri sıralamak için).
// Süz levhası etiketleri alfabetik listeliyor, sayıya ihtiyaç duymuyor.

/// Not, seçilen durum süzgecine uyuyor mu? Hem [filteredNotesProvider] hem
/// anlamsal arama sonuçları (dashboard) aynı tanımı kullanır — iki mod
/// sessizce farklı davranmasın.
bool noteMatchesFilter(Note n, NoteFilter filter) => switch (filter) {
  NoteFilter.all => true,
  NoteFilter.text => n.type == NoteType.text,
  NoteFilter.checklist => n.type == NoteType.checklist,
  NoteFilter.ordered => n.type == NoteType.ordered,
  NoteFilter.pinned => n.pinned,
  NoteFilter.starred => n.starred,
  NoteFilter.reminded => n.reminderAt != null,
  NoteFilter.locked => n.locked,
  // Düzene girmemiş notlar: ne klasörü ne etiketi var.
  NoteFilter.others => n.folderId == null && n.tags.isEmpty,
};

/// Arşivlenmiş notlar (arşiv ekranı için). Gizli klasör bastırması burada da
/// geçerli — arşiv, gizli notların içeriğini doğrulamasız sızdırıyordu.
final archivedNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  final suppressed = ref.watch(suppressedFolderIdsProvider);
  return notes.whenData(
    (list) => [
      for (final n in list)
        if (n.archivedAt != null &&
            (n.folderId == null || !suppressed.contains(n.folderId)))
          n,
    ],
  );
});

/// Arama + filtre + etiket + klasör uygulanmış, arşiv dışı not listesi.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  // Geciktirilmiş sorgu: her tuş vuruşunda tüm notları taramamak için
  // (bkz. debouncedSearchQueryProvider).
  final query = ref.watch(debouncedSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(noteFilterProvider);
  final tag = ref.watch(selectedTagProvider);
  final folderId = ref.watch(selectedFolderProvider);
  final sort = ref.watch(noteSortProvider);
  final suppressed = ref.watch(suppressedFolderIdsProvider);

  return notes.whenData((list) {
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
      result = [
        for (final n in result)
          if (_matches(n, query)) n,
      ];
    }
    return _sortedNotes(result, sort);
  });
});

/// Seçili ölçüte göre notları sıralar. [NoteSort.manual] akıştan gelen sırayı
/// (orderIndex → updatedAt) korur; başlığa göre sıralamada başlıksız notlar
/// sona düşer.
List<Note> _sortedNotes(List<Note> notes, NoteSort sort) {
  if (sort == NoteSort.manual) return notes;
  final list = [...notes];
  int dateDesc(DateTime? a, DateTime? b) {
    final at = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  }

  switch (sort) {
    case NoteSort.manual:
      break;
    case NoteSort.updated:
      list.sort((a, b) => dateDesc(a.updatedAt, b.updatedAt));
    case NoteSort.created:
      list.sort((a, b) => dateDesc(a.createdAt, b.createdAt));
    case NoteSort.title:
      list.sort((a, b) {
        final at = a.title.trim().toLowerCase();
        final bt = b.title.trim().toLowerCase();
        if (at.isEmpty && bt.isEmpty) return dateDesc(a.updatedAt, b.updatedAt);
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
        return dateDesc(a.updatedAt, b.updatedAt);
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
final Map<String, (DateTime?, String)> _searchBodyCache = {};

String _searchableBody(Note note) {
  final cached = _searchBodyCache[note.id];
  if (cached != null && cached.$1 == note.updatedAt) return cached.$2;
  final buffer = StringBuffer(stripRichMarkers(note.body));
  for (final item in note.items) {
    buffer
      ..write('\n')
      ..write(stripRichMarkers(item.text));
  }
  final text = buffer.toString().toLowerCase();
  _searchBodyCache[note.id] = (note.updatedAt, text);
  return text;
}

bool _matches(Note note, String query) {
  if (note.title.toLowerCase().contains(query)) return true;
  // Kilitli notun içeriği aramaya sızmasın; yalnızca başlıktan bulunur.
  if (note.locked) return false;
  // Arama biçim İŞARETLERİNİ görmez: "558" araması `**558**` yazan notu da
  // bulmalı (işaret metnin içinde taşınıyor, bkz. rich_text.dart).
  if (_searchableBody(note).contains(query)) return true;
  for (final attachment in note.attachments) {
    if (attachment.fileName.toLowerCase().contains(query)) return true;
  }
  for (final tag in note.tags) {
    if (tag.toLowerCase().contains(query)) return true;
  }
  return false;
}
