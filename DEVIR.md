# DEVIR — P07 pencere sınıfı + telefon yatay + tur boyutları

Dal: oto/P07-pencere-sinifi

Yapılanlar
- F67.1: lib/app/window_class.dart (WindowClass, WindowWidth/Height, compactDevice,
  splitActiveFor(Size)). 12 dağınık koşul çevrildi; sabitler taşındı (split_shell,
  pinned_side, note_editor_screen yeniden export ediyor).
- F66.7 kök: telefon cihazı (en kısa kenar < 600, web değil) yatayda bölünmüyor;
  pen_tray.useRail yatay telefonda false; note_open_route aynı kuralı kullanıyor.
- Yan etki düzeltmesi: dashboard_screen LayoutBuilder — genişlik+sütun değişince
  kaydırma oranı yeniden uygulanır (_gridColumnsAt). wide_screen_doors F18.11 testi
  bunu yakaladı (kırmızı → yeşil).
- F67.2: tur boyutları + TOUR_KEYBOARD + TOUR_SIZES.

Kanıt
- test/split_layout_rules_test.dart "telefon yatayda bölünmez" (eski kodda 851 → true).
- test/window_class_guard_test.dart: eski koşul ↔ yeni sınıf denkliği + bekçi.

Kalan (sabah bakılacak, F66.7 alt maddeleri ≈ F67.4)
- kısa yükseklikte üst çubuk 40 dp, yazarken alt çubuk gizli, sabit ek yanda,
  takvim/zamanı gelen şeridi kapalı. Cihaz A/B gerekli (yürütücü).

Komutlar
- flutter test test/window_class_guard_test.dart test/split_layout_rules_test.dart test/wide_screen_doors_test.dart
- TOUR_SIZES=telefon-yatay TOUR_KEYBOARD=220 flutter test tool/tour/screen_tour_test.dart
