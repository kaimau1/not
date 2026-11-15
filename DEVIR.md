# DEVIR — oto/G3-bildirim-kaydirma (P62 G3: PA5–PA8)

Plan: `docs/plan_tasarim_A.md` §5 (PA5, PA6), §6 (PA7, PA8), §7.3 (S31–S35), §8.3.

## Yapılanlar
- PA5 bildirim hunisi (commit "G3 PA5"): S31 0/0/28/10 → 0/0/20/0; S33 16 → 10; S37 499/1363/57 → 487/1337/56.
  Sapma: TipOnce.show şerit doluyken ipucunu erteler (sabah bakılacak, plan Durum).

## Şu anki adım
- PA6 kalıcı şeritler: S32 26 → hedef 2; AnimatedSize mandalı 2 → 1.

## Sıradaki
- PA7 (S33 taban 10), PA8 (S34 yeni, S35 28 → 2).

## Komutlar
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --plain-name "S3" --reporter failures-only`
- Tur: `TOUR_ONLY=ana-ipucu,ana-gerial,ana-yenilikler TOUR_SIZES=telefon-kucuk TOUR_OUT=build/tour_pa5 flutter test tool/tour/screen_tour_test.dart`
