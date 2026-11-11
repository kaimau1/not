# DEVİR — P18 Telefon/tablet (kalan) · dal oto/P18-telefon-tablet

## Yapılanlar
- F67.4 (kısa pencere + klavye): `ShortKeyboardBarHide` (note_editor_parts.dart) alt çubuğu kararlı klavye boşluğuyla gizler (Offstage, tek adım); sabit medya en küçük pencerede (pinned_media_pane.dart `_visibleHeight`); pencere < 480 dp iken üst çubuk 40 dp (note_editor_screen.dart `toolbarHeight`). Tur matepad-yatay+klavye300 e-image-sabit: yazı alanı 73 → 197 dp.
- F66.4: telefon-kucuk/uzun turu taşmasız; tek hata turun kendisi (`n4-paylas` `.first` boş bulucuda atıyordu) düzeltildi.

## Nerede kalındı / sıradaki
- F66.6, F67.3, F67.7, F67.9 sırada.

## İşe yaramayan
- Alt çubuk gizleyici kararlı boşluğa her boyda bağlanınca S17 geçiş karesi 323→324 (bütçe aşımı): uzun pencerede (≥873 dp) bağlanmıyor.

## Test
`flutter test test/short_keyboard_bar_test.dart test/keyboard_jank_guard_test.dart test/perf_budget_test.dart --reporter failures-only`
Tur: `TOUR_SIZES=matepad-yatay TOUR_KEYBOARD=300 TOUR_ONLY=e-image-sabit flutter test tool/tour/screen_tour_test.dart`
