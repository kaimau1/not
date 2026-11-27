import 'package:flutter/foundation.dart';

import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';
import '../domain/shop_item_meta.dart';

/// Fiş satırındaki fiyat, `g`/`ml` dışındaki çoklu alımlarda (`2 adet ekmek 20 ₺`)
/// birim fiyata bölünerek madde başına unitPrice üretir.
double receiptUnitPriceForItem(ReceiptLine line, ShopItemMeta itemMeta) {
  final unitAscii = quickAscii(itemMeta.unit);
  final isPack =
      unitAscii == 'g' ||
      unitAscii == 'gr' ||
      unitAscii == 'gram' ||
      unitAscii == 'ml';
  if (!isPack && line.qty > 1) {
    return line.price / line.qty;
  }
  return line.price;
}

@immutable
class ReceiptLine {
  const ReceiptLine({required this.rawName, required this.price, this.qty = 1});

  final String rawName;
  final double price;
  final double qty;
}

@immutable
class ReceiptParseResult {
  const ReceiptParseResult({
    this.storeId = '',
    required this.lines,
    this.detectedTotal,
  });

  final String storeId;
  final List<ReceiptLine> lines;
  final double? detectedTotal;
}

@immutable
class ReceiptItemMatch {
  const ReceiptItemMatch({
    required this.itemId,
    required this.itemText,
    required this.receiptLine,
    required this.score,
  });

  final String itemId;
  final String itemText;
  final ReceiptLine receiptLine;
  final double score;
}

const _ignoredReceiptWords = <String>{
  'toplam',
  'top',
  'topkdv',
  'kdv',
  'nakit',
  'kredi',
  'kart',
  'banka',
  'para ustu',
  'paraustu',
  'tarih',
  'saat',
  'fis',
  'belge',
  'mersis',
  'vkn',
  'tckn',
  'vergi',
  'tesekkur',
  'sube',
  'kasiyer',
  'pos',
  'onay',
  'eku',
  'z no',
  'indirimi',
  'indirim',
  'ara toplam',
  'odenecek',
};

final _priceTailRe = RegExp(
  r'(?:%\s*\d+\s*)?(?:\*\s*)?(\d{1,5}[.,]\d{2})\s*(?:tl|₺)?\s*$',
  caseSensitive: false,
);
final _totalLineRe = RegExp(
  r'\b(toplam|genel\s+toplam|odenecek|total)\b',
  caseSensitive: false,
);
final _qtyPrefixRe = RegExp(
  r'^(\d+(?:[.,]\d+)?)\s*(?:x|adet|kg|gr|g|lt|l)\b',
  caseSensitive: false,
);

/// Türkiye market fişlerinden (BİM, A101, ŞOK, Migros, CarrefourSA vb.)
/// sıfır maliyetli yerel regex/satır çözümleyici ile market + ürün + fiyat çıkarır.
ReceiptParseResult parseTurkishReceipt(String ocrText) {
  final rawLines = [
    for (final l in ocrText.split(RegExp(r'\r?\n')))
      if (l.trim().isNotEmpty) l.trim(),
  ];
  if (rawLines.isEmpty) {
    return const ReceiptParseResult(lines: []);
  }

  final storeId = _detectStoreId(rawLines.take(8));
  final items = <ReceiptLine>[];
  double? detectedTotal;

  for (var i = 0; i < rawLines.length; i++) {
    final line = rawLines[i];
    final folded = quickAscii(line);

    final m = _priceTailRe.firstMatch(line);
    if (m != null) {
      final price = double.tryParse(m.group(1)!.replaceAll(',', '.'));
      if (price == null || price <= 0 || price > 50000) continue;

      if (_totalLineRe.hasMatch(folded) && !folded.contains('ara toplam')) {
        detectedTotal ??= price;
        continue;
      }
      if (_isIgnoredReceiptLine(folded)) continue;

      var namePart = line.substring(0, m.start).trim();
      namePart = namePart
          .replaceAll(RegExp(r'%\s*\d+\s*$'), '')
          .replaceAll(RegExp(r'[*#]+$'), '')
          .trim();

      var qty = 1.0;
      final qMatch = _qtyPrefixRe.firstMatch(namePart);
      if (qMatch != null) {
        qty = double.tryParse(qMatch.group(1)!.replaceAll(',', '.')) ?? 1.0;
        namePart = namePart.substring(qMatch.end).trim();
      } else if (i > 0) {
        final prevQty = _qtyPrefixRe.firstMatch(rawLines[i - 1]);
        if (prevQty != null && !_priceTailRe.hasMatch(rawLines[i - 1])) {
          qty = double.tryParse(prevQty.group(1)!.replaceAll(',', '.')) ?? 1.0;
        }
      }

      if (namePart.length < 2 || RegExp(r'^[\d\s.,/*-]+$').hasMatch(namePart)) {
        continue;
      }
      items.add(ReceiptLine(rawName: namePart, price: price, qty: qty));
    }
  }

  return ReceiptParseResult(
    storeId: storeId,
    lines: items,
    detectedTotal: detectedTotal,
  );
}

String _detectStoreId(Iterable<String> topLines) {
  final head = quickAscii(topLines.join(' '));
  if (head.contains('bim') || head.contains('birlesik magaza')) return 'bim';
  if (head.contains('a101') || head.contains('yeni magazacilik')) return 'a101';
  if (head.contains('sok market') || RegExp(r'\bsok\b').hasMatch(head)) {
    return 'sok';
  }
  if (head.contains('migros')) return 'migros';
  if (head.contains('carrefour')) return 'carrefour';
  return '';
}

final _ignoredReceiptPatterns = [
  for (final w in _ignoredReceiptWords)
    RegExp(r'\b' + RegExp.escape(w) + r'\b'),
];

bool _isIgnoredReceiptLine(String folded) {
  for (final re in _ignoredReceiptPatterns) {
    if (re.hasMatch(folded)) return true;
  }
  return false;
}

/// Fiş satırlarını alışveriş listesindeki maddelerle token örtüşmesi / önek
/// benzerliğiyle eşler.
List<ReceiptItemMatch> matchReceiptToList(
  List<ReceiptLine> lines,
  List<NoteItem> items,
) {
  final candidates = [
    for (final i in items)
      if (!i.header && i.text.trim().isNotEmpty) i,
  ];
  if (lines.isEmpty || candidates.isEmpty) return const [];

  final matches = <ReceiptItemMatch>[];
  final usedItemIds = <String>{};

  for (final line in lines) {
    final lineTokens = _receiptTokens(line.rawName);
    if (lineTokens.isEmpty) continue;

    NoteItem? bestItem;
    var bestScore = 0.0;

    for (final item in candidates) {
      if (usedItemIds.contains(item.id)) continue;
      final itemTokens = _receiptTokens(quickBaseName(item.text));
      if (itemTokens.isEmpty) continue;

      var hits = 0.0;
      for (final it in itemTokens) {
        var tokenBest = 0.0;
        for (final lt in lineTokens) {
          if (lt == it) {
            tokenBest = 1.0;
            break;
          }
          if (it.length >= 3 &&
              lt.length >= 3 &&
              (lt.startsWith(it) || it.startsWith(lt))) {
            tokenBest = 0.85;
          }
        }
        hits += tokenBest;
      }
      final score = hits / itemTokens.length;
      if (score >= 0.5 && score > bestScore) {
        bestScore = score;
        bestItem = item;
      }
    }

    if (bestItem != null) {
      usedItemIds.add(bestItem.id);
      matches.add(
        ReceiptItemMatch(
          itemId: bestItem.id,
          itemText: bestItem.text,
          receiptLine: line,
          score: bestScore,
        ),
      );
    }
  }
  return matches;
}

List<String> _receiptTokens(String raw) => [
  for (final t in quickAscii(raw).split(RegExp(r'[^a-z0-9]+')))
    if (t.length >= 2 && !_unitStopTokens.contains(t)) t,
];

const _unitStopTokens = {'kg', 'gr', 'lt', 'ml', 'ad', 'adet', 'pkt', 'tl'};
