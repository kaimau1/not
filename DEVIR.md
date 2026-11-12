# DEVİR — P42 (DENEYIM Faz 80: koyu tema, küçük ekran, web, önce/sonra)

Dal: `oto/P42-koyu-kucuk-web` (main 5f4e0cd4'ten, 2026-11-12). main'e birleştirilmedi; CI bakılmadı.

## Yapılan
- F80.1: `docs/deneyim/koyu.md`; 4 ailenin koyu kartı +1/kanal (ΔL ≥ 0,04), PDF önizlemesi
  koyuda %8 perde, `DestructiveRow` koyuda %24. Bekçiler `theme_contrast_test`, `dark_theme_polish_test`.
- F80.2: tura `TOUR_FONT=1.3`; takvim şeridi gün adı büyük yazıda küçülür.
- F80.3: D22 (≥ 840 dp başlıkta çizgi yok), `KeyboardFocusRing`, kısayollar tek tablo `kAppShortcuts`.
- F80.4: `test/tap_targets_test.dart` (27 gerekçeli istisna).
- F80.5 kısmi: `docs/cihaz_turu.md` web 21–23, tablet 28.

## Kalan (sabah bakılacak)
- `docs/deneyim/once-sonra.md` yazılmadı. Önce turları `build/tour-once{,-koyu,-yazi}`;
  sonra: koyu ve yazı turları `build/tour-koyu`, `build/tour-yazi` bitti (taşma yok, bilinenler
  dışında); açık tam tur (`TOUR_COMPARE=build/tour-once`) yarıda kaldı — yeniden koş.
- Sabit PDF çubuğu 1,3× + 360/393 dp'de 46/13 dp taşıyor (`pinned_media_pane.dart:1226`, K-O6 alanı).
- Klasör şeridi çipleri 32 dp (K-D3); not alt çubuğu 40 dp (P36).

## Bilinen
- Turda `e-pdf-balonlu` hatası tabanda da var (pdfium yok).
