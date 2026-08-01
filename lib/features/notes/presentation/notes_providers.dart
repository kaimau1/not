import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/rich_text.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../settings/settings_providers.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// [others] = hiçbir klasöre ve etikete girmemiş notlar. Çip barındaki
/// klasör/etiket çipleri notları düzenli tutuyor ama düzene HİÇ girmemiş
/// notları görünür kılmıyordu; bu süzgeç "kalanlar"ı tek dokunuşta getirir.
enum NoteFilter { all, text, checklist, ordered, pinned, starred, others }

/// Dashboard sıralama ölçütü. [manual] = akışın varsayılanı (elle sürükleme /
/// oluşturma sırası); diğerleri istemci tarafında yeniden sıralar.
enum NoteSort { manual, updated, created, title }

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

/// Ana ekranda görünen filtre çipleri. "Tümü" her zaman görünür; gerisi
/// kullanıcı isteğine bağlıdır. Varsayılanda tip filtreleri (metin/liste/
/// sıralı) gizlidir — sayfa sade kalır, isteyen filtre menüsünden ekler.
///
/// Sıralı liste (Set değil): kullanıcı filtre menüsünden çipleri sürükleyip
/// yeniden dizebilir; sıra kalıcıdır ve çip barında aynen uygulanır.
final visibleNoteFiltersProvider =
    NotifierProvider<VisibleNoteFiltersNotifier, List<NoteFilter>>(
      VisibleNoteFiltersNotifier.new,
    );

class VisibleNoteFiltersNotifier extends Notifier<List<NoteFilter>> {
  static const _key = 'visible_filters';
  static const _defaults = [
    NoteFilter.pinned,
    NoteFilter.starred,
    NoteFilter.others,
  ];

  @override
  List<NoteFilter> build() {
    final stored = ref.watch(sharedPreferencesProvider).getStringList(_key);
    if (stored == null) return _defaults;
    // Kayıtlı sırayı koru; geçersiz/yinelenen adları ve "Tümü"yü ele.
    final result = <NoteFilter>[];
    for (final name in stored) {
      for (final filter in NoteFilter.values) {
        if (filter.name == name &&
            filter != NoteFilter.all &&
            !result.contains(filter)) {
          result.add(filter);
        }
      }
    }
    // Sonradan eklenen "Diğerleri" çipi, kayıtlı listesi olan kullanıcılarda
    // sessizce eksik kalırdı (yalnız yeni kurulumlarda varsayılana giriyor).
    // Bir kez eklenir; kullanıcı gizlerse bayrak sayesinde geri gelmez.
    final prefs = ref.watch(sharedPreferencesProvider);
    if (!(prefs.getBool(_othersAddedKey) ?? false)) {
      prefs.setBool(_othersAddedKey, true);
      if (!result.contains(NoteFilter.others)) {
        result.add(NoteFilter.others);
        _persist(result);
      }
    }
    return result;
  }

  /// "Diğerleri" çipinin mevcut kullanıcılara bir kez eklendiğini işaretler.
  static const _othersAddedKey = 'visible_filters_others_added';

  void _persist(List<NoteFilter> next) {
    ref.read(sharedPreferencesProvider).setStringList(_key, [
      for (final f in next) f.name,
    ]);
  }

  void toggle(NoteFilter filter) {
    if (filter == NoteFilter.all) return;
    final next = state.contains(filter)
        ? [
            for (final f in state)
              if (f != filter) f,
          ]
        : [...state, filter];
    state = next;
    _persist(next);
    // Gizlenen filtre o an seçiliyse listeyi kilitlemesin.
    if (!next.contains(ref.read(noteFilterProvider)) &&
        ref.read(noteFilterProvider) != NoteFilter.all) {
      ref.read(noteFilterProvider.notifier).set(NoteFilter.all);
    }
  }

  /// Görünür filtrelerin sırasını değiştirir (filtre menüsünde sürükle-bırak).
  void reorder(int oldIndex, int newIndex) {
    final next = [...state];
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    final item = next.removeAt(oldIndex);
    next.insert(target, item);
    state = next;
    _persist(next);
  }
}

/// Ana ekran filtre barı genişletildi mi? (madde 4) Kapalıyken tek satır
/// kompakt çip; açıkken klasör ve etiketler bölümler hâlinde tam görünür.
/// Çip barında etiket çipleri görünsün mü (kullanıcı tercihi, kalıcı).
/// Filtreler gibi gizlenebilir: çok etiketi olan kullanıcıda satır şişiyordu.
final showTagChipsProvider = NotifierProvider<ShowTagChipsNotifier, bool>(
  ShowTagChipsNotifier.new,
);

class ShowTagChipsNotifier extends Notifier<bool> {
  static const _key = 'show_tag_chips';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Çip barında klasör çipleri görünsün mü (kullanıcı tercihi, kalıcı).
final showFolderChipsProvider = NotifierProvider<ShowFolderChipsNotifier, bool>(
  ShowFolderChipsNotifier.new,
);

class ShowFolderChipsNotifier extends Notifier<bool> {
  static const _key = 'show_folder_chips';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Çip barından TEK TEK kapatılmış etiketler (kalıcı). "Etiket çiplerini
/// göster" anahtarı hepsini birden kapatıyordu; kullanıcı yalnız birkaç
/// etiketin çipini gizlemek istediğinde çare yoktu (madde 5).
final hiddenTagChipsProvider =
    NotifierProvider<HiddenChipsNotifier, Set<String>>(
      () => HiddenChipsNotifier('hidden_tag_chips'),
    );

/// Çip barından tek tek kapatılmış klasörler (kalıcı). Klasörün KENDİSİ
/// gizlenmez, yalnız ana ekrandaki çipi görünmez olur — gizli klasör bambaşka
/// bir şey (bkz. [NoteFolder.hidden]).
final hiddenFolderChipsProvider =
    NotifierProvider<HiddenChipsNotifier, Set<String>>(
      () => HiddenChipsNotifier('hidden_folder_chips'),
    );

class HiddenChipsNotifier extends Notifier<Set<String>> {
  HiddenChipsNotifier(this._key);

  final String _key;

  @override
  Set<String> build() =>
      ref.watch(sharedPreferencesProvider).getStringList(_key)?.toSet() ??
      const <String>{};

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next.toList());
  }

  /// Verilen kimliklerin tamamını göster (kümeyi boşalt) ya da tamamını gizle.
  void setAll(Iterable<String> ids, {required bool visible}) {
    final next = visible ? <String>{} : {...ids};
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next.toList());
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

final filtersExpandedProvider = NotifierProvider<FiltersExpandedNotifier, bool>(
  FiltersExpandedNotifier.new,
);

class FiltersExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

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
final _suppressedFolderIdsProvider = Provider<Set<String>>((ref) {
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
final focusedNoteProvider =
    NotifierProvider<FocusedNoteNotifier, String?>(FocusedNoteNotifier.new);

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
final allTagsProvider = Provider<List<String>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final suppressed = ref.watch(_suppressedFolderIdsProvider);
  final tags = <String>{
    for (final note in notes)
      if (note.archivedAt == null && !suppressed.contains(note.folderId))
        ...note.tags,
  };
  final sorted = tags.toList()..sort();
  return sorted;
});

/// Etiket → kullanım sayısı (aktif notlarda). Ana sayfadaki çip satırı en
/// sık kullanılanları öne alıp gerisini "+N" arkasına gizler.
final tagCountsProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  final suppressed = ref.watch(_suppressedFolderIdsProvider);
  final counts = <String, int>{};
  for (final note in notes) {
    if (note.archivedAt != null) continue;
    if (suppressed.contains(note.folderId)) continue;
    for (final tag in note.tags) {
      counts[tag] = (counts[tag] ?? 0) + 1;
    }
  }
  return counts;
});

/// Arşivlenmiş notlar (arşiv ekranı için).
final archivedNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  return notes.whenData(
    (list) => [
      for (final n in list)
        if (n.archivedAt != null) n,
    ],
  );
});

/// Arama + filtre + etiket + klasör uygulanmış, arşiv dışı not listesi.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final notes = ref.watch(notesStreamProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(noteFilterProvider);
  final tag = ref.watch(selectedTagProvider);
  final folderId = ref.watch(selectedFolderProvider);
  final sort = ref.watch(noteSortProvider);
  final suppressed = ref.watch(_suppressedFolderIdsProvider);

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
    result = switch (filter) {
      NoteFilter.all => result,
      NoteFilter.text => [
        for (final n in result)
          if (n.type == NoteType.text) n,
      ],
      NoteFilter.checklist => [
        for (final n in result)
          if (n.type == NoteType.checklist) n,
      ],
      NoteFilter.ordered => [
        for (final n in result)
          if (n.type == NoteType.ordered) n,
      ],
      NoteFilter.pinned => [
        for (final n in result)
          if (n.pinned) n,
      ],
      NoteFilter.starred => [
        for (final n in result)
          if (n.starred) n,
      ],
      // Düzene girmemiş notlar: ne klasörü ne etiketi var.
      NoteFilter.others => [
        for (final n in result)
          if (n.folderId == null && n.tags.isEmpty) n,
      ],
    };
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
  }
  return list;
}

bool _matches(Note note, String query) {
  if (note.title.toLowerCase().contains(query)) return true;
  // Kilitli notun içeriği aramaya sızmasın; yalnızca başlıktan bulunur.
  if (note.locked) return false;
  // Arama biçim İŞARETLERİNİ görmez: "558" araması `**558**` yazan notu da
  // bulmalı (işaret metnin içinde taşınıyor, bkz. rich_text.dart).
  if (stripRichMarkers(note.body).toLowerCase().contains(query)) return true;
  for (final item in note.items) {
    if (stripRichMarkers(item.text).toLowerCase().contains(query)) return true;
  }
  for (final attachment in note.attachments) {
    if (attachment.fileName.toLowerCase().contains(query)) return true;
  }
  for (final tag in note.tags) {
    if (tag.toLowerCase().contains(query)) return true;
  }
  return false;
}
