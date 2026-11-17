import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:notlar/core/utils/note_fonts.dart';

/// T3 / K-54 (kasma envanteri §G): `google_fonts` pakette bulamadığı kesimi
/// ÇALIŞMA ANINDA fonts.gstatic.com'dan indirir; gelince motor "yazı tipleri
/// değişti" der ve ekrandaki bütün metin yeniden dizilir (çevrimdışıyken
/// sessizce sistem yazı tipi). Bekçi: indirme kapalıyken uygulamanın
/// GoogleFonts'a İSTEDİĞİ her kesim (tek stil 400/500 + metin teması) paketten
/// yüklenir. Kalın (w600+) metin GoogleFonts'a gitmez: kesime özgü aile adı
/// (`Lora_regular`) üzerinden motor kalınlaştırır — bkz. `note_fonts.dart`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uygulama çalışma anı indirmesini kapatır', () {
    disableFontRuntimeFetching();
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('her katalog ailesinin istenen kesimleri paketten yüklenir', () async {
    disableFontRuntimeFetching();
    final failed = <String>[];
    for (final font in kCatalogFonts) {
      final id = font.id!;
      for (final weight in [FontWeight.w400, FontWeight.w500]) {
        try {
          applyNoteFont(TextStyle(fontWeight: weight, fontSize: 13.25), id);
          await GoogleFonts.pendingFonts();
        } catch (_) {
          failed.add('$id ${weight.value}');
        }
      }
      try {
        appFontTextTheme(ThemeData().textTheme, id);
        await GoogleFonts.pendingFonts();
      } catch (_) {
        failed.add('$id metin teması');
      }
    }
    expect(failed, isEmpty, reason: 'pakette olmayan kesim (ağdan inerdi)');
  });

  test(
    'kalın taban stil pakette olmayan kesimi istemez, kalınlık korunur',
    () async {
      disableFontRuntimeFetching();
      for (final font in kCatalogFonts) {
        final styled = applyNoteFont(
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 17.5),
          font.id,
        );
        expect(styled.fontWeight, FontWeight.w700, reason: font.id);
        await GoogleFonts.pendingFonts();
      }
    },
  );
}
