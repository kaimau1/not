import 'package:flutter/foundation.dart';

import 'inline_item_parser.dart';
import 'list_mode.dart';
import 'note_item.dart';
import 'quick_entry.dart';

/// Yapıştırılan uzun mesaj, WhatsApp sohbeti, yemek tarifi veya not paragrafından
/// ayıklanan tek bir madde önerisi.
@immutable
class ExtractedItemDraft {
  const ExtractedItemDraft({
    required this.item,
    required this.rawText,
    this.selected = true,
  });

  final NoteItem item;
  final String rawText;
  final bool selected;

  ExtractedItemDraft copyWith({NoteItem? item, bool? selected}) =>
      ExtractedItemDraft(
        item: item ?? this.item,
        rawText: rawText,
        selected: selected ?? this.selected,
      );
}

/// **METİNDEN AYIKLA — ÇEVRİMDIŞI MOTOR (0 KREDİ)** (Faz 3):
///
/// WhatsApp sohbet dökümlerinden, tariflerden, numaralı/madde imli listelerden
/// veya virgüllü cümlelerden temiz liste maddeleri çıkarır; her maddeyi
/// [InlineItemParser] ile zenginleştirir (miktar, birim, fiyat, tarih, öncelik,
/// reyon/kategori).
abstract final class TextItemExtractor {
  /// Yapıştırılan metnin "Metinden ayıkla" akışını tetikleyecek kadar uzun
  /// olup olmadığını kontrol eder.
  static bool isExtractablePaste(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length >= 80) return true;
    final nonEmptyLines = trimmed
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .length;
    return nonEmptyLines >= 3;
  }

  /// `[14:20] Ahmet: ...`, `[12.05.2026 14:20] Ayşe: ...`
  static final _waBracketRe = RegExp(
    r'^\[?\d{1,2}[./-]\d{1,2}(?:[./-]\d{2,4})?,?\s+\d{1,2}:\d{2}(?::\d{2})?(?:\s*[APap][Mm])?\]?\s*[-–]?\s*[^:\n]{1,40}:\s*',
  );

  /// `14:20 Ahmet:` veya `[14:20] Ahmet:`
  static final _waTimeOnlyRe = RegExp(
    r'^\[?\d{1,2}:\d{2}(?::\d{2})?\]?\s*[-–]?\s*[^:\n]{1,40}:\s*',
  );

  /// Satır başı madde imi / numara / kutucuk: `- `, `* `, `• `, `1. `, `2) `, `[ ] `, `☐ `
  static final _bulletPrefixRe = RegExp(
    r'^(?:[-*•▪▸►✓✔☐☑]|\[[ xX]?\]|\d{1,3}[.)])\s*',
  );

  /// Sohbet başlangıcı / selamlaşma gürültü kalıpları.
  static final _greetingLineRe = RegExp(
    r'^(?:merhaba|selam|slm|mrb|iyi\s+g[uü]nler|g[uü]nayd[iı]n|iyi\s+ak[sş]amlar|te[sş]ekk[uü]r(?:ler)?|sa[gğ]\s*ol|tamam|olur|peki|hello|hi|hey|thanks|ok|okay)[!.?\s]*$',
    caseSensitive: false,
  );

  /// Tarif / liste giriş başlığı ("Malzemeler:", "Ingredients:", "Alınacaklar:")
  static final _sectionHeaderRe = RegExp(
    r'^(?:malzemeler|i[cç]indekiler|al[iı]nacaklar|yap[iı]lacaklar|ingredients|shopping\s*list|to[\s-]*do|liste)\s*:?\s*$',
    caseSensitive: false,
  );

  /// Başlangıç cümlesi kalıpları ("akşama şunları al:", "lütfen al:", "alınacaklar:")
  static final _leadInColonRe = RegExp(r'^[^:\n]{3,42}:\s*(.+)$');

  /// Sonda veya başta konuşma dolgusu ("alabilir misin", "lazım", "almayı unutma").
  static final _trailingFluffRe = RegExp(
    r'\s*(?:al[iı]r\s+m[iı]s[iı]n|alabilir\s+misin|almay[iı]\s+unutma|laz[iı]m|gerek(?:li|iyor)?|l[uü]tfen|please|needed|buy)\s*[?.!]*$',
    caseSensitive: false,
  );

  static final _markupOrCodeRe = RegExp(
    r'(?:##|%%|==|&&|```|=>|::|/\*|\*/|\{|\})',
  );

  /// Ham metinden 0 krediyle temiz [ExtractedItemDraft] listesi çıkarır.
  static List<ExtractedItemDraft> extractLocal(
    String rawText, {
    required ListMode mode,
    String locale = 'tr',
    Map<String, int> learnedGroups = const {},
    DateTime? now,
    int maxItems = 40,
  }) {
    final cleanedInput = rawText.replaceAll('\r\n', '\n').trim();
    if (cleanedInput.isEmpty) return const [];

    final candidateStrings = <String>[];
    final lines = cleanedInput.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // WhatsApp zaman damgası + gönderici öneki temizle.
      line = line.replaceFirst(_waBracketRe, '').trim();
      line = line.replaceFirst(_waTimeOnlyRe, '').trim();
      if (line.isEmpty) continue;

      // Selamlaşma / boş sohbet satırlarını atla.
      if (_greetingLineRe.hasMatch(line)) continue;

      // "Malzemeler:" / "Alınacaklar:" tek başına başlık satırını atla.
      if (_sectionHeaderRe.hasMatch(line)) continue;

      // "Akşama şunları al: süt, yumurta, ekmek" → iki nokta sonrasını al.
      final colonMatch = _leadInColonRe.firstMatch(line);
      if (colonMatch != null) {
        final after = colonMatch.group(1)!.trim();
        // URL veya saat (10:30) bozulmasın.
        final before = line.substring(0, line.indexOf(':')).trim();
        if (after.length >= 2 &&
            !before.endsWith('http') &&
            !before.endsWith('https') &&
            !RegExp(r'\d$').hasMatch(before)) {
          line = after;
        }
      }

      // Satır başı madde imi / numara / kutucuk temizle.
      line = line.replaceFirst(_bulletPrefixRe, '').trim();
      if (line.isEmpty) continue;

      // Satır içinde virgül / noktalı virgül veya " ve " ayırıcıları varsa böl.
      final subParts = _splitClause(line, mode: mode);
      for (var part in subParts) {
        part = part.replaceFirst(_bulletPrefixRe, '').trim();
        part = part.replaceFirst(_trailingFluffRe, '').trim();
        part = _trimEdgePunct(part);
        if (part.isEmpty) continue;
        if (_greetingLineRe.hasMatch(part)) continue;
        if (_markupOrCodeRe.hasMatch(part)) continue;
        candidateStrings.add(part);
      }
    }

    // Yineleyenleri temizle (normalize edilmiş anahtar üzerinden) ve
    // InlineItemParser ile miktar/fiyat/tarih/öncelik/kategori bağla.
    final seen = <String>{};
    final out = <ExtractedItemDraft>[];
    var seq = 0;

    for (final raw in candidateStrings) {
      if (out.length >= maxItems) break;
      final parsed = InlineItemParser.parse(
        raw,
        mode: mode,
        locale: locale,
        now: now,
        learnedGroups: learnedGroups,
      );
      final title = _capitalizeFirst(parsed.title.trim());
      if (title.length < 2) continue;
      final dedupKey = quickAscii(title);
      if (dedupKey.isEmpty || !seen.add(dedupKey)) continue;

      final item = parsed.toNoteItem(id: 'ext_${seq++}_$dedupKey');
      out.add(
        ExtractedItemDraft(
          item: item.copyWith(text: title),
          rawText: raw,
        ),
      );
    }

    return out;
  }

  /// Yapay zekâdan dönen düz satır listesini [ExtractedItemDraft] listesine
  /// dönüştürür (miktar/fiyat/tarih yine yerel ayrıştırıcıyla bağlanır).
  static List<ExtractedItemDraft> fromCleanLines(
    List<String> lines, {
    required ListMode mode,
    String locale = 'tr',
    Map<String, int> learnedGroups = const {},
    DateTime? now,
    int maxItems = 40,
  }) {
    final seen = <String>{};
    final out = <ExtractedItemDraft>[];
    var seq = 0;
    for (final raw in lines) {
      if (out.length >= maxItems) break;
      var cleaned = raw.trim().replaceFirst(_bulletPrefixRe, '').trim();
      cleaned = _trimEdgePunct(cleaned);
      if (cleaned.length < 2) continue;
      final parsed = InlineItemParser.parse(
        cleaned,
        mode: mode,
        locale: locale,
        now: now,
        learnedGroups: learnedGroups,
      );
      final title = _capitalizeFirst(parsed.title.trim());
      if (title.length < 2) continue;
      final key = quickAscii(title);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(
        ExtractedItemDraft(
          item: parsed
              .toNoteItem(id: 'ai_ext_${seq++}_$key')
              .copyWith(text: title),
          rawText: cleaned,
        ),
      );
    }
    return out;
  }

  static List<String> _splitClause(String line, {required ListMode mode}) {
    // Önce noktalı virgül ve nokta+boşluk (uzun paragrafta cümle bölme).
    final primaryParts = line.contains(';')
        ? line.split(';')
        : line.length > 90 && line.contains('. ')
        ? line.split(RegExp(r'\.\s+'))
        : [line];

    final out = <String>[];
    for (final p in primaryParts) {
      final t = p.trim();
      if (t.isEmpty) continue;
      // Virgüllü ayrım: ondalık sayıyı (2,5 kg) koruyarak yalnız gerçek
      // liste virgüllerinden böl.
      final commaSplit = t.split(RegExp(r'(?<!\d),(?!\d)'));
      if (commaSplit.length > 1) {
        for (final seg in commaSplit) {
          out.addAll(_splitConjunction(seg.trim(), mode: mode));
        }
      } else {
        out.addAll(_splitConjunction(t, mode: mode));
      }
    }
    return out;
  }

  static List<String> _splitConjunction(String s, {required ListMode mode}) {
    if (s.isEmpty) return const [];
    // Yalnız kısa "X ve Y" / "X and Y" alışveriş-stil birleşimleri böl;
    // uzun proje görevlerini bozma.
    if (mode == ListMode.shopping || s.length <= 42) {
      final parts = s.split(
        RegExp(r'\s+(?:ve|and|&)\s+', caseSensitive: false),
      );
      if (parts.length > 1 &&
          parts.every(
            (p) => p.trim().length >= 2 && p.trim().split(' ').length <= 4,
          )) {
        return [for (final p in parts) p.trim()];
      }
    }
    return [s];
  }

  static String _trimEdgePunct(String s) =>
      s.replaceAll(RegExp(r'^[,;:.•\-–—\s]+|[,;:.•\-–—\s]+$'), '').trim();

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    final first = s[0];
    final upper = first == 'i' ? 'İ' : first.toUpperCase();
    return '$upper${s.substring(1)}';
  }
}
