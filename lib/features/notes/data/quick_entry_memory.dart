import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/spell_learn.dart';
import '../../settings/settings_providers.dart';
import '../domain/note_templates.dart';
import '../domain/quick_entry.dart';
import '../domain/quick_lexicon_data.dart';
import '../presentation/editor/auto_spell.dart';

/// **HIZLI GİRİŞ HAFIZASI** (kullanıcı isteği 2026-11-15: "kişinin en çok
/// ekledikleri favori kısmına girecek"; "yazım öğrenmemiz de var, bununla da
/// bağlı olur").
///
/// Şablon başına ([kind]: `b:shopping`, `u:<kimlik>`, `drop`) kullanıcının
/// eklediği maddeler ve kaç kez eklediği. İki işe yarar:
///
/// * "Sık eklediklerin" çipleri ([top]);
/// * ayrıştırıcının sözlüğü — bir kez eklenen madde ("fıstık ezmesi") sonraki
///   sefer TANINIR, yakın eşleşmede kullanıcının sık eklediği önce gelir.
///
/// Geri alınan yazım düzeltmeleri ([rejected]) bir daha uygulanmaz.
///
/// Cihaz yerel (SharedPreferences): alışkanlık verisi, senkronu yok.
@immutable
class QuickEntryMemory {
  const QuickEntryMemory({
    this.kinds = const {},
    this.rejected = const {},
    this.itemGroups = const {},
    this.purchaseDays = const {},
  });

  /// kind → (madde anahtarı → (yazılışı, sayı)).
  final Map<String, Map<String, (String, int)>> kinds;

  /// `yazılan>düzeltilen` (anahtar hâlinde).
  final Set<String> rejected;

  /// AL-4: kullanıcının öğrettiği kişisel kategori/reyon eşlemesi
  /// (madde anahtarı → grup numarası).
  final Map<String, int> itemGroups;

  /// AL-4: tahmin için madde anahtarı → en son satın alma günleri (epoch günü,
  /// en çok 6 kayıt). Tamamen cihazda hesaplanır, ağ/AI yok.
  final Map<String, List<int>> purchaseDays;

  static const maxPerKind = 300;
  static const maxKinds = 24;
  static const _maxDaysPerItem = 6;
  static const _maxTrackedDays = 200;

  /// En çok eklenenler (sayı, sonra alfabe). [min]: en az kaç kez.
  List<String> top(String kind, {int count = 12, int min = 1}) {
    final entries =
        [
          for (final e in (kinds[kind] ?? const {}).values)
            if (e.$2 >= min) e,
        ]..sort((a, b) {
          final c = b.$2.compareTo(a.$2);
          return c != 0 ? c : quickAscii(a.$1).compareTo(quickAscii(b.$1));
        });
    return [for (final e in entries.take(count)) e.$1];
  }

  /// Bu türde bilinen bütün maddeler (yazılışı, sayı).
  Iterable<(String, int)> all(String kind) => (kinds[kind] ?? const {}).values;

  bool isRejected(String typed, String corrected) =>
      rejected.contains('${quickAscii(typed)}>${quickAscii(corrected)}');

  QuickEntryMemory recorded(
    String kind,
    Iterable<String> items, {
    DateTime? at,
  }) {
    final next = {...?kinds[kind]};
    final days = {
      for (final e in purchaseDays.entries) e.key: [...e.value],
    };
    final day = at != null ? _epochDay(at) : null;
    for (final raw in items) {
      final name = quickBaseName(raw);
      final key = quickAscii(name);
      if (key.isEmpty) continue;
      final old = next[key];
      next[key] = (old?.$1 ?? name, (old?.$2 ?? 0) + 1);
      if (day != null) {
        final list = days.putIfAbsent(key, () => []);
        if (list.isEmpty || list.last != day) {
          list.add(day);
          if (list.length > _maxDaysPerItem) {
            list.removeRange(0, list.length - _maxDaysPerItem);
          }
        }
      }
    }
    if (next.length > maxPerKind) {
      final sorted = next.entries.toList()
        ..sort((a, b) => a.value.$2.compareTo(b.value.$2));
      for (final e in sorted.take(next.length - maxPerKind)) {
        next.remove(e.key);
      }
    }
    if (days.length > _maxTrackedDays) {
      final sorted = days.entries.toList()
        ..sort(
          (a, b) =>
              (a.value.lastOrNull ?? 0).compareTo(b.value.lastOrNull ?? 0),
        );
      for (final e in sorted.take(days.length - _maxTrackedDays)) {
        days.remove(e.key);
      }
    }
    final all = {...kinds, kind: next};
    while (all.length > maxKinds) {
      all.remove(all.keys.firstWhere((k) => k != kind));
    }
    return QuickEntryMemory(
      kinds: all,
      rejected: rejected,
      itemGroups: itemGroups,
      purchaseDays: days,
    );
  }

  /// AL-4: maddenin kişisel reyon/grup numarasını öğrenir.
  QuickEntryMemory withItemGroup(String itemText, int group) {
    final key = quickItemKey(itemText);
    if (key.isEmpty) return this;
    final next = {...itemGroups, key: group};
    return QuickEntryMemory(
      kinds: kinds,
      rejected: rejected,
      itemGroups: next,
      purchaseDays: purchaseDays,
    );
  }

  QuickEntryMemory rejecting(String typed, String corrected) =>
      QuickEntryMemory(
        kinds: kinds,
        rejected: {
          ...rejected.skip(rejected.length > 200 ? 50 : 0),
          '${quickAscii(typed)}>${quickAscii(corrected)}',
        },
        itemGroups: itemGroups,
        purchaseDays: purchaseDays,
      );

  /// AL-4 tahmin: düzenli alınan ve ortalama aralığı dolmuş maddeleri
  /// gecikme oranına göre döndürür (ör. "her 7 günde süt, 9 gündür yok").
  List<({String name, int avgDays, int daysSince})> predictDue(
    String kind, {
    DateTime? now,
    int maxItems = 5,
  }) {
    final kindMap = kinds[kind];
    if (kindMap == null || kindMap.isEmpty || purchaseDays.isEmpty) {
      return const [];
    }
    final today = _epochDay(now ?? DateTime.now());
    final due = <({String name, int avgDays, int daysSince, double ratio})>[];
    for (final e in kindMap.entries) {
      final hist = purchaseDays[e.key];
      if (hist == null || hist.length < 2) continue;
      var totalGap = 0;
      var gaps = 0;
      for (var i = 1; i < hist.length; i++) {
        final d = hist[i] - hist[i - 1];
        if (d > 0) {
          totalGap += d;
          gaps++;
        }
      }
      if (gaps == 0) continue;
      final avg = (totalGap / gaps).round().clamp(2, 365);
      final since = today - hist.last;
      if (since >= avg) {
        due.add((
          name: e.value.$1,
          avgDays: avg,
          daysSince: since,
          ratio: since / avg,
        ));
      }
    }
    due.sort((a, b) => b.ratio.compareTo(a.ratio));
    return [
      for (final d in due.take(maxItems))
        (name: d.name, avgDays: d.avgDays, daysSince: d.daysSince),
    ];
  }

  static int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  String encode() => jsonEncode({
    'k': {
      for (final k in kinds.entries)
        k.key: {
          for (final e in k.value.entries) e.key: [e.value.$1, e.value.$2],
        },
    },
    'r': rejected.toList(),
    if (itemGroups.isNotEmpty) 'g': itemGroups,
    if (purchaseDays.isNotEmpty) 't': purchaseDays,
  });

  /// Bozuk kayıt sessizce boş hafıza olur.
  static QuickEntryMemory decode(String? raw) {
    if (raw == null || raw.isEmpty) return const QuickEntryMemory();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final kinds = <String, Map<String, (String, int)>>{};
      (j['k'] as Map?)?.forEach((k, v) {
        final m = <String, (String, int)>{};
        (v as Map).forEach((key, val) {
          final l = val as List;
          m['$key'] = ('${l[0]}', (l[1] as num).toInt());
        });
        kinds['$k'] = m;
      });
      final groups = <String, int>{};
      (j['g'] as Map?)?.forEach((k, v) {
        if (v is num) groups['$k'] = v.toInt();
      });
      final days = <String, List<int>>{};
      (j['t'] as Map?)?.forEach((k, v) {
        if (v is List) {
          days['$k'] = [
            for (final n in v)
              if (n is num) n.toInt(),
          ];
        }
      });
      return QuickEntryMemory(
        kinds: kinds,
        rejected: {for (final r in (j['r'] as List?) ?? const []) '$r'},
        itemGroups: groups,
        purchaseDays: days,
      );
    } catch (_) {
      return const QuickEntryMemory();
    }
  }
}

final quickEntryMemoryProvider =
    NotifierProvider<QuickEntryMemoryNotifier, QuickEntryMemory>(
      QuickEntryMemoryNotifier.new,
    );

class QuickEntryMemoryNotifier extends Notifier<QuickEntryMemory> {
  static const _key = 'quick_entry_memory_v1';

  @override
  QuickEntryMemory build() => QuickEntryMemory.decode(
    ref.watch(sharedPreferencesProvider).getString(_key),
  );

  void _save(QuickEntryMemory next) {
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, next.encode());
  }

  /// Oluşturulan veya tamamlanan listenin maddeleri sayılır (+ AL-4 tarih).
  void record(String kind, Iterable<String> items, {DateTime? at}) =>
      _save(state.recorded(kind, items, at: at ?? DateTime.now()));

  /// AL-4: maddenin kişisel reyon/grup numarasını kaydeder.
  void learnGroup(String itemText, int group) =>
      _save(state.withItemGroup(itemText, group));

  /// Kullanıcı düzeltmeyi geri aldı: bir daha uygulanmaz; yazım hafızası da
  /// öğrenir (editörde de düzeltilmesin).
  void reject(String typed, String corrected) {
    _save(state.rejecting(typed, corrected));
    AutoSpell.memory.rejectPair(typed, corrected);
    AutoSpell.changed();
  }
}

/// Hızlı ekle düğmesinin tercihleri: açılınca dinlesin mi, klavye açılsın mı
/// (kullanıcı isteği 2026-11-15: "hem yazma hem dinleme açılır, kişinin
/// isteğine göre biri kapatılabilir").
final quickDropMicProvider = boolPref('quick_drop_mic', defaultValue: true);
final quickDropKeyboardProvider = boolPref(
  'quick_drop_keyboard',
  defaultValue: true,
);

/// Hızlı ekle: hedef bulunamayınca/başa baş kalınca yapay zekâya sorsun mu
/// (kullanıcı isteği 2026-11-16; yalnız not başlıkları gider).
final quickDropAiProvider = boolPref('quick_drop_ai', defaultValue: true);

/// Hızlı ekle v2: ekledikten sonra levhayı açık bırak (seri giriş).
final quickDropKeepOpenProvider = boolPref(
  'quick_drop_keep_open',
  defaultValue: false,
);

/// Hızlı liste ekranı: reyon sırasına dizsin mi, kaç sütun.
final quickListAisleSortProvider = boolPref(
  'quick_list_aisle_sort',
  defaultValue: true,
);
final quickListTwoColumnsProvider = boolPref(
  'quick_list_two_columns',
  defaultValue: true,
);

/// Sözlüğü kurar: (isteğe bağlı) hazır market sözlüğü + şablonun öneri
/// grupları + kullanıcının bu türde daha önce ekledikleri.
///
/// [grocery]: hazır market sözlüğü ve reyon sırası katılır. Öneri grupları
/// alışverişte reyonlara eşlenir ([kShoppingSuggestionAisles]); başka
/// şablonda grup sırası 100'den başlar (kendi konu sırası).
QuickLexicon buildQuickLexicon({
  required String locale,
  bool grocery = false,
  List<TemplateSuggestionGroup> groups = const [],
  Iterable<(String, int)> learned = const [],
  Iterable<String> extra = const [],
}) {
  final lex = QuickLexicon();
  if (grocery) {
    final tr = locale.startsWith('tr');
    // Uygulamanın dili önce: aynı anahtara düşen yazılışta o dil kazanır.
    for (final data
        in tr
            ? [kQuickLexiconTr, kQuickLexiconEn]
            : [kQuickLexiconEn, kQuickLexiconTr]) {
      for (final e in data.entries) {
        for (final item in e.value.split(',')) {
          lex.add(item, group: e.key.index);
        }
      }
    }
  }
  for (var g = 0; g < groups.length; g++) {
    final group = grocery && g < kShoppingSuggestionAisles.length
        ? kShoppingSuggestionAisles[g].index
        : 100 + g;
    lex.addAll(groups[g].items, group: group);
  }
  lex.addAll(extra);
  for (final (text, count) in learned) {
    lex.add(text, weight: count);
  }
  return lex;
}

/// Ayrıştırıcıyı kişisel yazım hafızasına bağlar: öğretilen düzeltme
/// uygulanır, kullanıcının kendi kelimesi ve geri aldığı düzeltme ellenmez.
QuickParser buildQuickParser(
  QuickLexicon lexicon, {
  QuickEntryMemory memory = const QuickEntryMemory(),
  SpellMemory? spell,
  bool phrasesOnly = false,
}) {
  final sm = spell ?? AutoSpell.memory;
  return QuickParser(
    lexicon,
    phrasesOnly: phrasesOnly,
    learnedFix: sm.learned,
    // Yalnız kullanıcının KENDİ yazdığı/öğrettiği kelime: yerleşik sık
    // kelimeler ("süre", "kola" gibi) yakın eşleşmeyi kapatmasın diye
    // `SpellMemory.known` değil, kişisel sayaç ve "dokunma" listesi.
    isUserWord: (w) {
      final l = trLower(w);
      return (sm.words[l] ?? 0) >= 3 || sm.keep.contains(l);
    },
    isRejected: (typed, corrected) =>
        memory.isRejected(typed, corrected) ||
        sm.rejected.contains('${trLower(typed)}>${trLower(corrected)}'),
  );
}

/// Liste kabul edilince yazım hafızası da öğrenir: düzeltilip listede KALAN
/// madde bir "yanlış → doğru" gözlemidir (iki kez görülünce editörde de
/// uygulanır), eklenen kelimeler kullanıcının kelimesi sayılır.
void teachSpellFromQuickItems(Iterable<QuickItem> items, {SpellMemory? spell}) {
  final sm = spell ?? AutoSpell.memory;
  if (!AutoSpell.learning.value && spell == null) return;
  var touched = false;
  for (final item in items) {
    if (item.how == QuickHow.fuzzy &&
        item.typed.isNotEmpty &&
        !item.name.contains(' ')) {
      sm.learnFix(item.typed, trLower(item.name));
      touched = true;
    } else if (item.how == QuickHow.typed) {
      for (final w in item.name.split(' ')) {
        if (w.length >= 3) {
          sm.addWord(w);
          touched = true;
        }
      }
    }
  }
  if (touched && spell == null) AutoSpell.changed();
}

final Map<String, QuickLexicon> _groceryCache = {};

/// Hazır market sözlüğü (dil başına bir kez kurulur).
QuickLexicon groceryLexicon(String locale) =>
    _groceryCache[locale.startsWith('tr') ? 'tr' : 'en'] ??= buildQuickLexicon(
      locale: locale,
      grocery: true,
    );

/// Liste bir ALIŞVERİŞ listesine benziyor mu: başlığı öyle diyor ya da
/// maddelerinin en az yarısı (ve en az ikisi) market sözlüğünde. Benzemeyen
/// listede (yapılacaklar gibi cümleli) kelimeler ayrı maddeye BÖLÜNMEZ.
bool looksLikeGrocery(String title, Iterable<String> items, String locale) {
  final t = quickAscii(title);
  for (final hint in const [
    'alisveris',
    'market',
    'pazar',
    'bakkal',
    'manav',
    'shopping',
    'grocer',
  ]) {
    if (t.contains(hint)) return true;
  }
  final lex = groceryLexicon(locale);
  var total = 0;
  var hits = 0;
  for (final i in items) {
    if (i.trim().isEmpty) continue;
    total++;
    if (lex.exact(quickBaseName(i)) != null) hits++;
  }
  return hits >= 2 && hits * 2 >= total;
}
