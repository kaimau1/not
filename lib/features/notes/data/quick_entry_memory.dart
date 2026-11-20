import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/spell_learn.dart';
import '../../settings/settings_providers.dart';
import '../domain/note_templates.dart';
import '../domain/quick_entry.dart';
import '../domain/quick_lexicon_data.dart';
import '../domain/note.dart';
import '../domain/smart_list.dart';
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
  const QuickEntryMemory({this.kinds = const {}, this.rejected = const {}});

  /// kind → (madde anahtarı → (yazılışı, sayı)).
  final Map<String, Map<String, (String, int)>> kinds;

  /// `yazılan>düzeltilen` (anahtar hâlinde).
  final Set<String> rejected;

  static const maxPerKind = 300;
  static const maxKinds = 24;

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

  QuickEntryMemory recorded(String kind, Iterable<String> items) {
    final next = {...?kinds[kind]};
    for (final raw in items) {
      final name = quickBaseName(raw);
      final key = quickAscii(name);
      if (key.isEmpty) continue;
      final old = next[key];
      next[key] = (old?.$1 ?? name, (old?.$2 ?? 0) + 1);
    }
    if (next.length > maxPerKind) {
      final sorted = next.entries.toList()
        ..sort((a, b) => a.value.$2.compareTo(b.value.$2));
      for (final e in sorted.take(next.length - maxPerKind)) {
        next.remove(e.key);
      }
    }
    final all = {...kinds, kind: next};
    while (all.length > maxKinds) {
      all.remove(all.keys.firstWhere((k) => k != kind));
    }
    return QuickEntryMemory(kinds: all, rejected: rejected);
  }

  QuickEntryMemory rejecting(String typed, String corrected) =>
      QuickEntryMemory(
        kinds: kinds,
        rejected: {
          ...rejected.skip(rejected.length > 200 ? 50 : 0),
          '${quickAscii(typed)}>${quickAscii(corrected)}',
        },
      );

  String encode() => jsonEncode({
    'k': {
      for (final k in kinds.entries)
        k.key: {
          for (final e in k.value.entries) e.key: [e.value.$1, e.value.$2],
        },
    },
    'r': rejected.toList(),
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
      return QuickEntryMemory(
        kinds: kinds,
        rejected: {for (final r in (j['r'] as List?) ?? const []) '$r'},
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

  /// Oluşturulan listenin maddeleri sayılır.
  void record(String kind, Iterable<String> items) =>
      _save(state.recorded(kind, items));

  /// Önceki hâline döner (bir kaydın Geri al'ı — "Alışverişi bitir").
  void restore(QuickEntryMemory previous) => _save(previous);

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
///
/// Başlık KÖKTEN eşlenir (2026-11-20): içerir-araması "Pazartesi işleri",
/// "Marketing planı" gibi başlıkları da alışveriş sayıyordu — o listede
/// kelimeler bölünüyor, "kitap al"daki "al" (alışveriş sözü) atılıyordu.
bool looksLikeGrocery(String title, Iterable<String> items, String locale) {
  if (titleSaysShopping(title)) return true;
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

/// LİSTE notunun türü (hızlı eklemede ayrıştırma ve reyon yerleşimi, editörde
/// "Alışverişi bitir"):
/// başlık türü söylüyorsa o ([smartKindOfTitle]: "Bavul listesi", "Antalya
/// tatili", "Market listesi"); yoksa maddeler — yalnız bavul sözlüğünde olan
/// en az iki madde ve maddelerin yarısı tanınıyorsa bavul,
/// [looksLikeGrocery] ise alışveriş, değilse düz liste (yapılacaklar gibi
/// cümleli: kelimeler bölünmez).
///
/// 2026-11-20: akıllı listenin kurduğu "Bavul listesi"ne hızlı ekleme
/// cümleli kipe düşüyordu — "şort mayo şarj aleti" TEK madde oluyordu.
SmartListKind noteListKind(Note note, String locale) {
  final byTitle = smartKindOfTitle(note.displayTitle);
  if (byTitle != null) return byTitle;
  final texts = [
    for (final i in note.items)
      if (!i.header && i.text.trim().isNotEmpty) i.text,
  ];
  final grocery = groceryLexicon(locale);
  final packing = packingLexicon(locale);
  var onlyPacking = 0;
  var onlyGrocery = 0;
  var known = 0;
  for (final t in texts) {
    final g = grocery.groupOf(t) >= 0;
    final p = packing.groupOf(t) >= 0;
    if (g || p) known++;
    if (p && !g) onlyPacking++;
    if (g && !p) onlyGrocery++;
  }
  if (onlyPacking >= 2 &&
      onlyPacking > onlyGrocery &&
      known * 2 >= texts.length) {
    return SmartListKind.packing;
  }
  if (looksLikeGrocery(note.displayTitle, texts, locale)) {
    return SmartListKind.shopping;
  }
  return SmartListKind.generic;
}
