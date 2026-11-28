import '../../../core/utils/rich_text.dart';
import '../data/quick_entry_memory.dart';
import 'list_mode.dart';
import 'quick_entry.dart';
import 'smart_list.dart';

/// "Sık eklediklerin" ve geçmiş hafıza önerilerini temizleyen saf süzgeç.
///
/// Kök neden koruması: `rich_text.dart` satır içi biçim işaretleri
/// (`##3:...##`, `%%...%%`, `==...==`, `&&...&&`, `**`, `_`, `~`), uzun
/// cümleler (> 4 kelime), kod/URL parçaları ve aktif liste kipiyle uyumsuz
/// girdiler öneri havuzuna asla girmez.
class QuickSuggestionSanitizer {
  QuickSuggestionSanitizer._();

  static const int maxWords = 4;
  static const int maxChars = 36;
  static const int minChars = 2;

  /// Bozuk/yarım kalmış veya adlandırılmış rich_text belirteçlerini de temizler.
  static final _namedRichPrefixRe = RegExp(
    r'(?:##|%%|==|&&)[a-zA-Z0-9#_-]{1,12}:',
  );
  static final _residualRichRe = RegExp(
    r'(?:##|%%|==|&&)[a-zA-Z0-9#_-]{0,12}:?',
  );
  static final _leadingBulletRe = RegExp(r'^\s*(?:[-*•·]+|\d+[.)]|#+\s*)\s*');
  static final _urlOrCodeRe = RegExp(
    r'(?:https?://|www\.|\.[a-z]{2,4}/|@|`|=>|::|//|/\*|\*/|\{|\}|\[|\]|<|>|\||;|\\)',
    caseSensitive: false,
  );
  static final _hasLetterRe = RegExp(r'\p{L}', unicode: true);
  static final _sentencePunctRe = RegExp(r'[?!\n\r\t]');

  /// Alışveriş modunda görev/eylem cümlelerini ayıklamak için yaygın fiil sonları.
  static const _taskVerbs = {
    'yap',
    'yapmak',
    'et',
    'etmek',
    'kontrol',
    'gonder',
    'gönder',
    'ara',
    'aramak',
    'ode',
    'öde',
    'oku',
    'yaz',
    'bitir',
    'tamamla',
    'hazirla',
    'hazırla',
    'gorus',
    'görüş',
    'toplanti',
    'toplantı',
    'send',
    'check',
    'call',
    'finish',
    'review',
    'pay',
    'email',
  };

  /// Ham madde metnini temizler; öneri olarak geçersizse `null` döner.
  static String? cleanItem(String raw) {
    if (raw.trim().isEmpty) return null;
    var s = raw.replaceAll(_namedRichPrefixRe, ' ');
    s = stripRichMarkers(s);
    s = s.replaceAll(_residualRichRe, ' ');
    s = s.replaceAll(RegExp(r'[*_~]+'), ' ');
    s = s.replaceFirst(_leadingBulletRe, '');
    s = quickBaseName(s);
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!isValidSuggestionText(s)) return null;
    return quickCapitalize(s);
  }

  /// Temizlenmiş bir metnin kısa, temiz bir liste önerisi olup olmadığını sınar.
  static bool isValidSuggestionText(String text) {
    final s = text.trim();
    if (s.length < minChars || s.length > maxChars) return false;
    if (_sentencePunctRe.hasMatch(s)) return false;
    if (_urlOrCodeRe.hasMatch(s)) return false;
    if (s.contains('##') ||
        s.contains('%%') ||
        s.contains('==') ||
        s.contains('&&')) {
      return false;
    }
    if (!_hasLetterRe.hasMatch(s)) return false;
    final words = [
      for (final w in s.split(RegExp(r'\s+')))
        if (w.isNotEmpty) w,
    ];
    if (words.isEmpty || words.length > maxWords) return false;
    // Görev eki/kod kalıntısı gibi tek kelimede 2+ iki nokta üst üste.
    if (':'.allMatches(s).isNotEmpty && RegExp(r'\w:\w').hasMatch(s)) {
      return false;
    }
    return true;
  }

  /// Mevcut [QuickEntryMemory] içindeki kirli girdileri temizler ve aynı
  /// temiz anahtara düşen sayaçları birleştirir.
  static QuickEntryMemory sanitizeMemory(QuickEntryMemory memory) {
    final cleanedKinds = <String, Map<String, (String, int)>>{};
    final validKeys = <String>{};
    for (final kindEntry in memory.kinds.entries) {
      final out = <String, (String, int)>{};
      for (final itemEntry in kindEntry.value.entries) {
        final cleaned = cleanItem(itemEntry.value.$1);
        if (cleaned == null) continue;
        final key = quickAscii(cleaned);
        if (key.isEmpty) continue;
        final prev = out[key];
        final count = (prev?.$2 ?? 0) + itemEntry.value.$2;
        out[key] = (prev?.$1 ?? cleaned, count);
        validKeys.add(key);
      }
      if (out.isNotEmpty) cleanedKinds[kindEntry.key] = out;
    }
    final cleanedDays = <String, List<int>>{
      for (final e in memory.purchaseDays.entries)
        if (validKeys.contains(e.key)) e.key: e.value,
    };
    return QuickEntryMemory(
      kinds: cleanedKinds,
      rejected: memory.rejected,
      itemGroups: memory.itemGroups,
      purchaseDays: cleanedDays,
    );
  }

  /// Bir önerinin aktif [mode] / [kind] bağlamıyla uyumlu olup olmadığını sınar.
  static bool isCompatibleWithMode(
    String text, {
    required ListMode mode,
    SmartListKind? kind,
    required String locale,
  }) {
    final cleaned = cleanItem(text);
    if (cleaned == null) return false;
    final words = [
      for (final w in quickAscii(cleaned).split(RegExp(r'[^a-z0-9]+')))
        if (w.isNotEmpty) w,
    ];
    if (words.isEmpty) return false;

    if (mode == ListMode.shopping || kind == SmartListKind.shopping) {
      final inGrocery = groceryLexicon(locale).groupOf(cleaned) >= 0;
      if (inGrocery) return true;
      // Market sözlüğünde değilse görev fiili veya > 3 kelimelik cümle elenir.
      if (words.length > 3) return false;
      if (words.any(_taskVerbs.contains)) return false;
      return true;
    }
    if (mode == ListMode.template &&
        kind != null &&
        kind != SmartListKind.generic) {
      final lex = lexiconForSmartKind(kind, locale);
      if (lex.groupOf(cleaned) >= 0) return true;
      if (words.length > 3) return false;
      return !words.any(_taskVerbs.contains);
    }
    return true;
  }

  /// Öneri listesini temizler, tekrarları giderir ve aktif kiple süzer.
  static List<String> filterSuggestions(
    Iterable<String> rawItems, {
    required ListMode mode,
    SmartListKind? kind,
    required String locale,
    int limit = 12,
  }) {
    final out = <String>[];
    final seen = <String>{};
    for (final raw in rawItems) {
      final cleaned = cleanItem(raw);
      if (cleaned == null) continue;
      if (!isCompatibleWithMode(
        cleaned,
        mode: mode,
        kind: kind,
        locale: locale,
      )) {
        continue;
      }
      final key = quickAscii(cleaned);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(cleaned);
      if (out.length >= limit) break;
    }
    return out;
  }
}
