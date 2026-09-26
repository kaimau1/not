import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/rich_text.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/settings_providers.dart';
import '../../ai/data/attachment_text_index.dart';
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
/// [active] = EN ÇOK ÇALIŞILAN: notun kaç kez açıldığı/düzenlendiği
/// ([noteActivityProvider]). Ölçüt cihaz yereldir — hangi notla uğraştığın
/// kişisel bir kullanım izi, buluta yazılmaz.
enum NoteSort { manual, updated, created, title, color, active }

/// Not başına "çalışma sayacı" (cihaz yerel, kalıcı).
///
/// Notu editörde AÇMAK bir puan, o oturumda gerçekten DEĞİŞTİRMEK bir puan
/// daha ekler (bkz. [NoteActivityNotifier.touch]) — böylece göz atılan not ile
/// üzerinde çalışılan not aynı ağırlıkta olmaz. Sayaçlar Firestore'a
/// yazılmaz: her cihazın kendi çalışma alışkanlığı ayrıdır ve not belgesini
/// her açılışta güncellemek `updatedAt`i bozup "son güncellenen" sıralamasını
/// anlamsızlaştırırdı.
final noteActivityProvider =
    NotifierProvider<NoteActivityNotifier, Map<String, int>>(
      NoteActivityNotifier.new,
    );

class NoteActivityNotifier extends Notifier<Map<String, int>> {
  static const _key = 'note_activity';

  /// Sözlük sınırsız büyümesin: en çok çalışılan bu kadar not tutulur, gerisi
  /// budanır (sıralama için zaten yalnız tepe uçtakiler anlamlı).
  static const _maxEntries = 400;

  @override
  Map<String, int> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is num)
            entry.key.toString(): (entry.value as num).toInt(),
      };
    } catch (_) {
      return const {};
    }
  }

  /// Notla çalışıldı: sayacı bir artırır.
  void touch(String noteId) {
    if (noteId.isEmpty) return;
    var next = {...state, noteId: (state[noteId] ?? 0) + 1};
    if (next.length > _maxEntries) {
      final entries = next.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      next = {for (final e in entries.take(_maxEntries)) e.key: e.value};
    }
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(next));
  }

  /// Not silindiğinde sayacı da düşer (ölü kayıt birikmesin).
  void forget(String noteId) {
    if (!state.containsKey(noteId)) return;
    final next = {...state}..remove(noteId);
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(next));
  }
}

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

/// **KLASÖR RAFI AÇIK MI** (kalıcı) — kullanıcı isteği 2026-08-18:
/// "klasörler ana ekranda çok fazla yer kaplıyor, farklı bir çözüm bulalım."
///
/// Kapalıyken (VARSAYILAN) klasörler tek satırlık yatay bir çip şeridine
/// iner: on klasör bile ~46 px yer kaplar, oysa karo ızgarası her üç klasör
/// için 92 px'lik bir satır açıyor ve notlar ekranın altına düşüyordu.
/// Açıkken eski karo rafı geri gelir — klasörleri bir arada görmek isteyen
/// kullanıcı tek dokunuşla ona geçer ve tercihi hatırlanır.
final folderShelfExpandedProvider =
    NotifierProvider<FolderShelfExpandedNotifier, bool>(
      FolderShelfExpandedNotifier.new,
    );

class FolderShelfExpandedNotifier extends Notifier<bool> {
  static const _key = 'folder_shelf_expanded';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void toggle() => set(!state);

  /// Ayarlar → Notlar ve klasörler'den doğrudan seçim.
  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
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

  void toggle() => set(!state);

  /// Ayarlar → Notlar ve klasörler'den doğrudan seçim.
  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
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

/// **SON ARAMALAR** (kalıcı, cihaz yerel).
///
/// NEDEN: arama kutusu her açılışta bomboş açılıyordu. Aynı sorgu ("fatura",
/// bir kişi adı, bir proje kodu) günde birkaç kez elle yeniden yazılıyor;
/// üstelik notlarda aranan şey çoğu zaman uzun bir özel ad. Sorgular buluta
/// YAZILMAZ: ne aradığın kişisel bir kullanım izidir.
final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
      SearchHistoryNotifier.new,
    );

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'search_history';

  /// Kutunun altında tek satırda kalsın: daha fazlası hem yer kaplar hem
  /// "son" olmaktan çıkar.
  static const maxEntries = 8;

  @override
  List<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key) ?? const [];

  /// Sorguyu listenin başına alır. Aynı sorgu zaten varsa TAŞINIR (kopya
  /// birikmez). Çok kısa sorgular kaydedilmez: tek harf "geçmiş" değildir.
  void remember(String query) {
    final value = query.trim();
    if (value.length < 2) return;
    final next = [
      value,
      for (final q in state)
        if (q.toLowerCase() != value.toLowerCase()) q,
    ].take(maxEntries).toList();
    if (next.length == state.length &&
        next.isNotEmpty &&
        state.isNotEmpty &&
        next.first == state.first) {
      return;
    }
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }

  void forget(String query) {
    final next = [
      for (final q in state)
        if (q != query) q,
    ];
    if (next.length == state.length) return;
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next);
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
    ref.read(sharedPreferencesProvider).setStringList(_key, const []);
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

  /// Ekranda GÖRÜNEN notların tamamını seçer (ya da hepsi zaten seçiliyse
  /// seçimi kaldırır). Çağıran görünür listeyi verir: süzgeç/arama açıkken
  /// "tümü", kullanıcının o an gördüğü kümedir — ekran dışındaki notları
  /// sessizce seçmek toplu silmeyi tehlikeli yapardı.
  void selectAll(Iterable<String> ids) {
    final next = ids.toSet();
    state = next.every(state.contains) && next.length == state.length
        ? const {}
        : next;
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

/// Ana ekranda yana çekişin durduğu yer: bir durum süzgeci ya da bir etiket.
typedef SwipeStop = ({NoteFilter filter, String? tag});

/// Ana ekranı yana çekince gidilecek SONRAKİ durak ([direction] +1 sonraki,
/// -1 önceki). Gezilecek yer yoksa null.
///
/// KÖK NEDENLER (kullanıcı bulgusu 2026-09-23: "ana ekranda sağa sola
/// kaydırmada mantık hatası var"), eski kural dört yerden bozuktu:
///  1. **Boş duraklar.** Dokuz durum süzgecinin HEPSİ geziliyordu; kilitli ya
///     da hatırlatıcılı notu olmayan kullanıcı her çekişte boş bir "not yok"
///     ekranına düşüyordu. Artık yalnız en az bir notu olan süzgeçler durak
///     (Tümü ve o an açık olan süzgeç her zaman durak kalır).
///  2. **Klasör siliniyordu.** Klasör bu gezide yok ama çekiş seçili klasörü
///     sessizce `null` yapıyordu: Süz levhasından bir klasör seçen kullanıcı
///     yana çekince bütün notlara dönüyordu. Klasör artık KORUNUR ve duraklar
///     o klasörün notlarından hesaplanır.
///  3. **Birleşik süzgeç.** Süz levhası "yıldızlı + #iş" gibi birleşik bir
///     görünüm kurabiliyor; eski eşleşme üçlüyü birebir aradığı için bu hâl
///     hiçbir durağa uymuyor ve çekiş kullanıcıyı listenin BAŞINA (ya da
///     sonuna) fırlatıyordu. Etiket seçiliyse etiketin durağından, değilse
///     süzgecin durağından devam edilir.
///  4. Yön ve animasyon düzeltmeleri dashboard'da (bkz. `_cycleFilterFolder`).
///
/// [notes], çekişin gezdiği görünümün adayları: arşivlenmemiş, boş olmayan,
/// gizli klasörde olmayan (ve klasör seçiliyse o klasördeki) notlar.
SwipeStop? nextSwipeStop({
  required List<Note> notes,
  required NoteFilter filter,
  required String? tag,
  required int direction,
}) {
  final stops = swipeFilterStops(notes: notes, filter: filter, tag: tag);
  if (stops.length < 2) return null;
  var index = tag != null
      ? stops.indexWhere((s) => s.tag == tag)
      : stops.indexWhere((s) => s.tag == null && s.filter == filter);
  if (index < 0) index = 0;
  var next = (index + direction) % stops.length;
  if (next < 0) next += stops.length;
  return stops[next];
}

/// Süzgeç çekişinin durakları: Tümü, notu olan durum süzgeçleri (o an açık
/// olan her zaman), sonra etiketler (bkz. [nextSwipeStop]).
List<SwipeStop> swipeFilterStops({
  required List<Note> notes,
  required NoteFilter filter,
  required String? tag,
}) {
  final tags = <String>{
    for (final n in notes) ...n.tags,
    ?tag,
  }.toList()..sort();
  return [
    for (final f in NoteFilter.values)
      if (f == NoteFilter.all ||
          (f == filter && tag == null) ||
          notes.any((n) => noteMatchesFilter(n, f)))
        (filter: f, tag: null),
    for (final t in tags) (filter: NoteFilter.all, tag: t),
  ];
}

/// Ana ekranı yana çekince NE arasında gezilir (Ayarlar → Notlar).
///
/// Kullanıcı isteği 2026-09-26: "sağ sol kaydırmada klasörler arası geçiş".
/// 2026-08-18'de klasörler bu geziden bilerek çıkarılmıştı (klasör bir
/// süzgeç değil, bir YER); kullanıcı artık klasörler arasında çekerek
/// gezmek istiyor. Eski davranış kaybolmasın diye seçim ayarda.
enum SwipeMode {
  /// Tümü → klasörler (kullanıcının klasör sırasıyla). VARSAYILAN.
  folders,

  /// Tümü → durum süzgeçleri → etiketler (2026-09-23 davranışı).
  filters,

  /// Tümü → klasörler → süzgeçler → etiketler.
  both,

  /// Yana çekiş hiçbir şey yapmaz.
  off,
}

final swipeModeProvider = NotifierProvider<SwipeModeNotifier, SwipeMode>(
  SwipeModeNotifier.new,
);

class SwipeModeNotifier extends Notifier<SwipeMode> {
  static const _key = 'swipe_mode';

  @override
  SwipeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return SwipeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => SwipeMode.folders,
    );
  }

  void set(SwipeMode value) {
    state = value;
    ref.read(sharedPreferencesProvider).setString(_key, value.name);
  }
}

/// Ana ekran çekişinin bir durağı: klasör (varsa) + süzgeç + etiket.
typedef HomeSwipeStop = ({String? folderId, NoteFilter filter, String? tag});

/// [mode]a göre SONRAKİ durak ([direction] +1 sonraki, -1 önceki); gezilecek
/// yer yoksa null.
///
/// [notes] ana ekranın adayları (arşivsiz, boş olmayan, gizli klasörde
/// olmayan) — KLASÖRE GÖRE SÜZÜLMEMİŞ; [folderIds] görünen kendi
/// klasörlerim, kullanıcının sırasıyla.
///
/// * [SwipeMode.folders]: Tümü ↔ klasörler. Klasöre geçince süzgeç/etiket
///   sıfırlanır — "İş" klasörüne çekip boş bir "yıldızlı" görünümüne düşmek
///   anlamsız olurdu.
/// * [SwipeMode.filters]: seçili klasör KORUNUR, duraklar o klasörün
///   notlarından (2026-09-23 kuralı, bkz. [nextSwipeStop]).
/// * [SwipeMode.both]: tek halka — Tümü, klasörler, süzgeçler, etiketler.
HomeSwipeStop? nextHomeSwipeStop({
  required SwipeMode mode,
  required List<Note> notes,
  required List<String> folderIds,
  required String? folderId,
  required NoteFilter filter,
  required String? tag,
  required int direction,
}) {
  switch (mode) {
    case SwipeMode.off:
      return null;
    case SwipeMode.filters:
      final scoped = folderId == null
          ? notes
          : [
              for (final n in notes)
                if (n.folderId == folderId) n,
            ];
      final stop = nextSwipeStop(
        notes: scoped,
        filter: filter,
        tag: tag,
        direction: direction,
      );
      if (stop == null) return null;
      return (folderId: folderId, filter: stop.filter, tag: stop.tag);
    case SwipeMode.folders:
    case SwipeMode.both:
      final stops = <HomeSwipeStop>[
        (folderId: null, filter: NoteFilter.all, tag: null),
        for (final id in folderIds)
          (folderId: id, filter: NoteFilter.all, tag: null),
        if (mode == SwipeMode.both)
          for (final s in swipeFilterStops(
            notes: notes,
            filter: folderId == null ? filter : NoteFilter.all,
            tag: folderId == null ? tag : null,
          ))
            if (s.filter != NoteFilter.all || s.tag != null)
              (folderId: null, filter: s.filter, tag: s.tag),
      ];
      if (stops.length < 2) return null;
      int index;
      if (folderId != null) {
        index = stops.indexWhere((s) => s.folderId == folderId);
      } else if (tag != null) {
        index = stops.indexWhere((s) => s.folderId == null && s.tag == tag);
      } else {
        index = stops.indexWhere(
          (s) => s.folderId == null && s.tag == null && s.filter == filter,
        );
      }
      // Durakta olmayan bir görünümden (ör. [SwipeMode.folders]'ta açık bir
      // süzgeç ya da gizlenmiş bir klasör) çekiş Tümü'nün komşusuna gider.
      if (index < 0) index = 0;
      var next = (index + direction) % stops.length;
      if (next < 0) next += stops.length;
      return stops[next];
  }
}

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

/// **BİR KLASÖRÜN İÇİ** (klasörün kendi sayfası — bkz. `FolderScreen`).
///
/// Ana ekranın süzgeçlerinden (arama, durum, etiket) BAĞIMSIZ: klasöre giren
/// kullanıcı orada duran her şeyi görmek ister; dışarıda bırakılmış bir
/// süzgecin klasörün içini de budaması "notum kayboldu" demekti. Yalnız
/// sıralama ortak — kullanıcının seçtiği düzen her yerde aynı olsun.
final folderNotesProvider = Provider.family<AsyncValue<List<Note>>, String>((
  ref,
  folderId,
) {
  final notes = ref.watch(notesStreamProvider);
  final sort = ref.watch(noteSortProvider);
  final activity = sort == NoteSort.active
      ? ref.watch(noteActivityProvider)
      : const <String, int>{};
  return notes.whenData(
    (list) => _sortedNotes([
      for (final n in list)
        if (n.folderId == folderId && n.archivedAt == null && !n.isEmpty) n,
    ], sort, activity),
  );
});

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
    StreamProvider.family<List<Note>, ({String ownerId, String folderId})>((
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
              const {},
            ),
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
  // Sayaçlar YALNIZ o sıralamada izlenir: her not açılışında sayaç değişiyor,
  // koşulsuz izlense süzgeç sağlayıcısı (ve tüm dashboard) boşuna yeniden
  // hesaplanırdı.
  final activity = sort == NoteSort.active
      ? ref.watch(noteActivityProvider)
      : const <String, int>{};

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
    } else if (query.isEmpty && tag == null && filter == NoteFilter.all) {
      // **KLASÖRDEKİ NOT ANA EKRANDA DURMAZ** (kullanıcı isteği 2026-08-18:
      // "klasör dashboard'ta bir not gibi yer kaplar, basılınca kendi
      // içerisindeki notlar görülür ayrı bir sayfada"). Klasör artık bir
      // süzgeç değil bir YER: notu klasöre koymak onu ana ekrandan KALDIRIR,
      // yoksa aynı not iki yerde birden durur ve klasörün "toplama" işi
      // anlamsızlaşırdı.
      //
      // ARAMA VE SÜZGEÇ BUNUN DIŞINDA: bir şey ARAYAN kullanıcı klasörün
      // içindekini de bulmalı — "notum kayboldu" en pahalı hata.
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
      final extra = ref.watch(attachmentTextProvider);
      result = [
        for (final n in result)
          if (_matches(n, query) ||
              (extra[n.id]?.toLowerCase().contains(query) ?? false))
            n,
      ];
    }
    return _sortedNotes(result, sort, activity);
  });
});

/// Seçili ölçüte göre notları sıralar. [NoteSort.manual] akıştan gelen sırayı
/// (orderIndex → updatedAt) korur; başlığa göre sıralamada başlıksız notlar
/// sona düşer.
List<Note> _sortedNotes(
  List<Note> notes,
  NoteSort sort, [
  Map<String, int> activity = const {},
]) {
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
    // En çok çalışılan: sayaç büyükten küçüğe. Hiç açılmamış notlar (sayaç
    // yok = 0) sona düşer ve KENDİ ARALARINDA son güncellenene göre dizilir —
    // yeni bir not, sayacı sıfır diye listenin en dibine gömülmesin.
    case NoteSort.active:
      list.sort((a, b) {
        final av = activity[a.id] ?? 0;
        final bv = activity[b.id] ?? 0;
        if (av != bv) return bv.compareTo(av);
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
  final text = buffer.toString().toLowerCase();
  _searchBodyCache[note.id] = (note.updatedAt, text);
  return text;
}

/// **Not, arama sorgusuna uyuyor mu** — ana ekranın süzgeciyle AYNI kural.
///
/// Klasörün kendi sayfası da bunu kullanır (kullanıcı bulgusu 2026-09-01:
/// "klasör içerisinde … arama yok"): iki yerde iki farklı eşleşme kuralı
/// olsaydı aynı sorgu ana ekranda bulup klasörde bulamayabilirdi. [query]
/// KÜÇÜK HARFE ÇEVRİLMİŞ ve kırpılmış gelmelidir (çağıran bir kez yapar,
/// her not için değil).
bool noteMatchesQuery(Note note, String query) => _matches(note, query);

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
