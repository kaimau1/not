# DEVIR — G2 şablon+çizgi (PBT + PB4 + PB6), dal oto/G2-sablon-cizgi

Plan: `docs/plan_tasarim_B.md` §7.2 (PBT), §7.6 (PB4), §7.8 (PB6).

## Yapılanlar
- PBT bitti (6 commit; plan §7.2 Durum). S41 taban: fazla kart 0/0, açılış Text 60 (23 kart).
  S44 taban: seçim satır 3, kök 3, ItemsEditor 3, tepsi satır 0, tepsi gövde boy karesi 14, klavye 0.
- Tur "önce": `TOUR_ONLY=sablon-galeri,sablon-onizleme-liste,sablon-onizleme-yazi,sablon-bos,sablon-duzenle,cizgi-satirlar,cizgi-tepsi,cizgi-levha TOUR_SIZES=telefon-kucuk,matepad-yatay TOUR_OUT=build/tour_p63_once`
  (bulgu: 360×640'ta çizgi levhası alttan taşıyor — "önce" görüntüsünde sarı-siyah şerit).

## Şu an
- PB4 şablonlar. Not: `note_templates_test` CheckboxListTile + `Icons.check` + `Icons.star_outline` bulucuları
  kullanıyor → sıkı satır yerine CheckboxListTile korunur (test değişmeden yeşil kalmalı).

## Sıradaki
- PB6 çizgiler. Test: `flutter test test/<ilgili>_test.dart --reporter failures-only`;
  bütçe `flutter test test/perf_budget_test.dart --plain-name S4`
