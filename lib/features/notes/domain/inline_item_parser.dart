import 'package:flutter/foundation.dart';

import '../../../core/utils/spoken_datetime.dart';
import '../data/quick_entry_memory.dart';
import 'list_mode.dart';
import 'note_item.dart';
import 'quick_entry.dart';

/// Satır içi ayrıştırıcının yakaladığı tek bir yapısal çip türü.
enum InlineParsedChipKind { quantity, price, dueDate, priority, tag, category }

@immutable
class InlineParsedChip {
  const InlineParsedChip({
    required this.kind,
    required this.label,
    this.tagValue,
  });

  final InlineParsedChipKind kind;
  final String label;

  /// Yalnız [InlineParsedChipKind.tag] için etiketin ham adı.
  final String? tagValue;

  @override
  bool operator ==(Object other) =>
      other is InlineParsedChip &&
      other.kind == kind &&
      other.label == label &&
      other.tagValue == tagValue;

  @override
  int get hashCode => Object.hash(kind, label, tagValue);
}

/// Satır içi doğal dil ayrıştırma sonucu (tamamen cihazda, 0 kredi).
@immutable
class InlineParsedItem {
  const InlineParsedItem({
    required this.raw,
    required this.title,
    this.quantity,
    this.unit = '',
    this.price,
    this.dueDate,
    this.hasDueTime = false,
    this.priority = ItemPriority.none,
    this.tags = const [],
    this.category = '',
    this.chips = const [],
  });

  final String raw;
  final String title;
  final double? quantity;
  final String unit;
  final double? price;
  final DateTime? dueDate;
  final bool hasDueTime;
  final ItemPriority priority;
  final List<String> tags;
  final String category;
  final List<InlineParsedChip> chips;

  bool get hasAnyMeta =>
      quantity != null ||
      price != null ||
      dueDate != null ||
      priority.isSet ||
      tags.isNotEmpty;

  /// Kullanıcı belirli çipleri (`×`) kapattıysa ham metni koruyarak [NoteItem]
  /// üretir.
  NoteItem toNoteItem({
    required String id,
    Set<InlineParsedChipKind> dismissed = const {},
    bool includeQtyInText = false,
  }) {
    final keepQty = !dismissed.contains(InlineParsedChipKind.quantity);
    final keepPrice = !dismissed.contains(InlineParsedChipKind.price);
    final keepDue = !dismissed.contains(InlineParsedChipKind.dueDate);
    final keepPrio = !dismissed.contains(InlineParsedChipKind.priority);
    final keepCat = !dismissed.contains(InlineParsedChipKind.category);

    final useQty = keepQty ? quantity : null;
    final useUnit = keepQty && useQty != null ? unit : '';
    final usePrice = keepPrice ? price : null;
    final useDue = keepDue ? dueDate : null;
    final usePrio = keepPrio ? priority : ItemPriority.none;
    final useCat = keepCat ? category : '';

    // Tüm çipler reddedildiyse ham metin aynen yazılır.
    final baseText =
        (dismissed.isNotEmpty &&
            useQty == null &&
            usePrice == null &&
            useDue == null &&
            !usePrio.isSet)
        ? quickCapitalize(raw.trim())
        : title;
    final displayText = includeQtyInText && useQty != null
        ? quickCompose(
            baseText,
            useUnit.isEmpty
                ? formatQuickNumber(useQty)
                : '${formatQuickNumber(useQty)} $useUnit',
          )
        : baseText;

    return NoteItem(
      id: id,
      text: displayText.isEmpty ? quickCapitalize(raw.trim()) : displayText,
      quantity: useQty,
      unit: useUnit,
      price: usePrice,
      dueDate: useDue,
      priority: usePrio,
      category: useCat,
    );
  }
}

/// Yazarken miktar (`2 kg domates`), fiyat (`kahve 180 tl`), zaman
/// (`yarın 10:00 kargo`), `#etiket` ve `!öncelik` kalıplarını yakalayan
/// kip-farkındalıklı yerel ayrıştırıcı.
class InlineItemParser {
  InlineItemParser._();

  static const _unitMap = <String, String>{
    'kg': 'kg',
    'kilo': 'kg',
    'kilogram': 'kg',
    'g': 'g',
    'gr': 'g',
    'gram': 'g',
    'lt': 'lt',
    'l': 'lt',
    'litre': 'lt',
    'liter': 'lt',
    'ml': 'ml',
    'adet': 'adet',
    'tane': 'tane',
    'paket': 'paket',
    'kutu': 'kutu',
    'sise': 'şişe',
    'şişe': 'şişe',
    'demet': 'demet',
    'koli': 'koli',
    'poset': 'poşet',
    'poşet': 'poşet',
    'kavanoz': 'kavanoz',
    'rulo': 'rulo',
    'tup': 'tüp',
    'tüp': 'tüp',
    'dilim': 'dilim',
    'pcs': 'pcs',
    'pack': 'pack',
    'bottle': 'bottle',
    'box': 'box',
    'bag': 'bag',
    'bunch': 'bunch',
  };

  static final _unitPattern = _unitMap.keys.join('|');

  static final _tagRe = RegExp(
    r'(?:^|\s)#([a-zA-Z0-9çğıöşüÇĞİÖŞÜ_-]{1,24})(?=\s|$)',
  );

  static final _priorityRe = RegExp(
    r'(?:^|\s)(?:!(acil|urgent|yuksek|yüksek|high|onemli|önemli|important|orta|medium|dusuk|düşük|low)|(!{2,3}))(?=\s|$)',
    caseSensitive: false,
  );

  static final _qtyWithUnitRe = RegExp(
    '(?:^|\\s)(½|¼|¾|yarım|yarim|çeyrek|ceyrek|\\d+(?:[.,]\\d{1,2})?)\\s*($_unitPattern)(?=\\s|\$)',
    caseSensitive: false,
  );

  static final _multQtyRe = RegExp(
    r'(?:^|\s)(?:(\d{1,3})[x×]|[x×](\d{1,3}))(?=\s|$)',
    caseSensitive: false,
  );

  static final _leadingBareQtyRe = RegExp(r'^(\d{1,2})\s+(.+)$');
  static final _trailingBareQtyRe = RegExp(r'^(.+?)\s+(\d{1,2})$');

  static double? _parseNum(String token) {
    final t = quickFold(token);
    if (t == '½' || t == 'yarım' || t == 'yarim') return 0.5;
    if (t == '¼' || t == 'çeyrek' || t == 'ceyrek') return 0.25;
    if (t == '¾') return 0.75;
    return double.tryParse(t.replaceAll(',', '.'));
  }

  static InlineParsedItem parse(
    String raw, {
    ListMode mode = ListMode.general,
    String locale = 'tr',
    DateTime? now,
    Map<String, int> learnedGroups = const {},
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return InlineParsedItem(raw: raw, title: '');
    }

    var working = trimmed;

    // 1) #etiket
    final tags = <String>[];
    final seenTags = <String>{};
    working = working.replaceAllMapped(_tagRe, (m) {
      final tag = m.group(1)!.trim();
      final key = quickAscii(tag);
      if (tag.isNotEmpty && seenTags.add(key)) tags.add(tag);
      return ' ';
    });

    // 2) !öncelik
    var priority = ItemPriority.none;
    working = working.replaceAllMapped(_priorityRe, (m) {
      final word = quickAscii(m.group(1) ?? '');
      final bangs = m.group(2) ?? '';
      if (bangs.isNotEmpty || word == 'acil' || word == 'urgent') {
        priority = ItemPriority.urgent;
      } else if (word == 'yuksek' ||
          word == 'high' ||
          word == 'onemli' ||
          word == 'important') {
        priority = ItemPriority.high;
      } else if (word == 'orta' || word == 'medium') {
        priority = ItemPriority.medium;
      } else if (word == 'dusuk' || word == 'low') {
        priority = ItemPriority.low;
      }
      return ' ';
    });

    // 3) Fiyat (yalnız açık para birimi: tl, ₺, $, €, £ — çıplak sayı değil!)
    final priced = extractInlinePrice(working);
    final price = priced.price;
    if (price != null && priced.text != working) {
      working = priced.text;
    }

    // 4) Miktar + birim (`2 kg`, `500 g`, `1,5 lt`, `yarım kg`, `3x`)
    double? quantity;
    var unit = '';
    final qtyUnitMatch = _qtyWithUnitRe.firstMatch(working);
    if (qtyUnitMatch != null) {
      final parsedVal = _parseNum(qtyUnitMatch.group(1)!);
      final rawUnit = quickAscii(qtyUnitMatch.group(2)!);
      final canonicalUnit = _unitMap[rawUnit] ?? qtyUnitMatch.group(2)!;
      if (parsedVal != null && parsedVal > 0) {
        final candidate =
            '${working.substring(0, qtyUnitMatch.start)} ${working.substring(qtyUnitMatch.end)}'
                .replaceAll(RegExp(r'\s+'), ' ')
                .trim();
        if (candidate.isNotEmpty) {
          quantity = parsedVal;
          unit = canonicalUnit;
          working = candidate;
        }
      }
    } else {
      final multMatch = _multQtyRe.firstMatch(working);
      if (multMatch != null) {
        final val = double.tryParse(multMatch.group(1) ?? multMatch.group(2)!);
        if (val != null && val > 0) {
          final candidate =
              '${working.substring(0, multMatch.start)} ${working.substring(multMatch.end)}'
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
          if (candidate.isNotEmpty) {
            quantity = val;
            working = candidate;
          }
        }
      }
    }

    // 5) Tarih / saat (`yarın 10:00 kargo`, `cuma akşamı sunum`)
    DateTime? dueDate;
    var hasDueTime = false;
    final dtHit = parseSpokenDateTimeWithSpan(
      working,
      languageCode: locale,
      now: now,
    );
    if (dtHit != null && dtHit.spans.isNotEmpty) {
      final buf = StringBuffer();
      var cursor = 0;
      for (final sp in dtHit.spans) {
        if (sp.start > cursor) buf.write(working.substring(cursor, sp.start));
        buf.write(' ');
        cursor = sp.end;
      }
      if (cursor < working.length) buf.write(working.substring(cursor));
      final candidate = buf
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'^[,;:-]+|[,;:-]+$'), '')
          .trim();
      if (candidate.isNotEmpty) {
        dueDate = dtHit.at;
        hasDueTime = dtHit.hasTime;
        working = candidate;
      }
    }

    // 6) Birimsiz çıplak sayı miktarı YALNIZ alışveriş ve şablon kiplerinde
    //    ("2 süt", "ekmek 3"); proje/genel notlarda "Faz 2" / "Rapor 2026" korunur.
    if (quantity == null &&
        (mode == ListMode.shopping || mode == ListMode.template)) {
      final lead = _leadingBareQtyRe.firstMatch(working);
      if (lead != null) {
        final v = double.tryParse(lead.group(1)!);
        final rest = lead.group(2)!.trim();
        if (v != null &&
            v > 0 &&
            rest.isNotEmpty &&
            !RegExp(r'^\d').hasMatch(rest)) {
          quantity = v;
          working = rest;
        }
      } else {
        final trail = _trailingBareQtyRe.firstMatch(working);
        if (trail != null) {
          final v = double.tryParse(trail.group(2)!);
          final rest = trail.group(1)!.trim();
          if (v != null && v > 0 && rest.isNotEmpty) {
            quantity = v;
            working = rest;
          }
        }
      }
    }

    final cleanTitle = quickCapitalize(
      working.replaceAll(RegExp(r'\s+'), ' ').trim(),
    );
    final finalTitle = cleanTitle.isEmpty
        ? quickCapitalize(trimmed)
        : cleanTitle;

    // 7) Otomatik kategori (alışveriş kipinde reyon anahtarı).
    var category = '';
    if (mode == ListMode.shopping) {
      final key = quickItemKey(finalTitle);
      final learned = learnedGroups[key];
      final aisle = learned ?? groceryLexicon(locale).groupOf(finalTitle);
      category = aisleCategoryKey(aisle) ?? '';
    }

    final chips = <InlineParsedChip>[
      if (quantity != null)
        InlineParsedChip(
          kind: InlineParsedChipKind.quantity,
          label: unit.isEmpty
              ? formatQuickNumber(quantity)
              : '${formatQuickNumber(quantity)} $unit',
        ),
      if (price != null)
        InlineParsedChip(
          kind: InlineParsedChipKind.price,
          label: '${formatQuickNumber(price)} ₺',
        ),
      if (dueDate != null)
        InlineParsedChip(
          kind: InlineParsedChipKind.dueDate,
          label: formatInlineDueChip(
            dueDate,
            hasTime: hasDueTime,
            now: now,
            locale: locale,
          ),
        ),
      if (priority.isSet)
        InlineParsedChip(
          kind: InlineParsedChipKind.priority,
          label: '!${priority.id}',
        ),
      for (final tag in tags)
        InlineParsedChip(
          kind: InlineParsedChipKind.tag,
          label: '#$tag',
          tagValue: tag,
        ),
    ];

    return InlineParsedItem(
      raw: raw,
      title: finalTitle,
      quantity: quantity,
      unit: unit,
      price: price,
      dueDate: dueDate,
      hasDueTime: hasDueTime,
      priority: priority,
      tags: tags,
      category: category,
      chips: chips,
    );
  }

  /// Kısa tarih çip metni (saf Dart; UI'da yerelleştirilmiş etiketle de gösterilebilir).
  static String formatInlineDueChip(
    DateTime at, {
    required bool hasTime,
    DateTime? now,
    String locale = 'tr',
  }) {
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final target = DateTime(at.year, at.month, at.day);
    final diff = target.difference(today).inDays;
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    final timePart = hasTime ? ' $hh:$mm' : '';
    final isTr = locale.startsWith('tr');
    if (diff == 0) return '${isTr ? 'Bugün' : 'Today'}$timePart';
    if (diff == 1) return '${isTr ? 'Yarın' : 'Tomorrow'}$timePart';
    final dd = at.day.toString().padLeft(2, '0');
    final mo = at.month.toString().padLeft(2, '0');
    return '$dd.$mo$timePart';
  }
}
