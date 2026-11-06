import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// F45.2: arayüz metni cümle düzeninde (TERIMLER.md). Büyük harf yalnız rozette
/// ve kısaltmada; vurgu büyük harfle yapılmaz, Başlık Düzeni yok.
void main() {
  const badges = {
    'captureModeNew',
    'cardBubbleDocument',
    'cardBubbleSlides',
    'cardKindPdf',
    'cardKindSlides',
    'uiItemVideoBadge',
  };
  const acronyms = {'API', 'PDF', 'WAV', 'OCR', 'IBAN'};
  // Özel ad ve virgüllü örnek listeleri (tek tek düşünülmüş).
  const titleCaseOk = {
    'tplShoppingItems',
    'tplGiftsItems',
    'unpinMediaRelease',
    'driveSectionTitle',
    // Google ürün adları (TAKVIM Faz 48/50).
    'gcalTitle',
    'gtasksTitle',
  };

  Map<String, String> arb(String lang) => {
    for (final e in (jsonDecode(
      File('lib/l10n/app_$lang.arb').readAsStringSync(),
    ) as Map<String, dynamic>).entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };

  for (final lang in ['tr', 'en']) {
    test('$lang: büyük harfli sözcük yalnız rozette ve kısaltmada', () {
      final upper = RegExp(r'[A-ZÇĞİÖŞÜ]{3,}');
      expect([
        for (final e in arb(lang).entries)
          if (!badges.contains(e.key) &&
              upper
                  .allMatches(e.value)
                  .any((m) => !acronyms.contains(m.group(0))))
            '${e.key}: ${e.value}',
      ], isEmpty);
    });
  }

  test('tr: Başlık Düzeni yok', () {
    final capital = RegExp(r'^[A-ZÇĞİÖŞÜ]');
    expect([
      for (final e in arb('tr').entries)
        if (!badges.contains(e.key) &&
            !titleCaseOk.contains(e.key) &&
            !e.value.contains('{') &&
            !e.value.endsWith('.'))
          if (e.value.split(' ') case final w
              when w.length >= 2 && w.length <= 5 && w.every(capital.hasMatch))
            '${e.key}: ${e.value}',
    ], isEmpty);
  });
}
