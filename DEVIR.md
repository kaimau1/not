# DEVIR — P50 Düzenleme modu baştan + hızlı menü (dal `oto/P50-duzenleme`)

Main'de ZATEN vardı (yeniden yapılmadı): hızlı menünün kendi düzenleme levhası
(`quick_row_editor.dart`, ⋮ + Kişiselleştir), alt çubuk sırala/ekle/çıkar (P57).

## Yapılan
- [x] Alt çubuk: düğme iki kapsül arasında taşınır (`UiPrefs.barSides` /
  `withBarSide`; Ayarlar → Kişiselleştir → alt çubuk satırındaki ok). Test:
  `test/editor_bar_customize_test.dart`.

## Sırada
- [ ] Düzenleme modu: aç-düzenle-KAYDET yerine anında uygulanan (Bitti / Geri al).
- [ ] Eksik `Customizable` sarmaları (editör üst çubuğu: ana sayfa, tam ekran).
- [ ] Belgeler, sürüm notu, CI.

## Yapılmadı / devir
- Ana ekran (`dashboard_*`) sarmaları: P56 çiti — dokunulmadı.
- Üst çubuk SIRALAMA listesi: `note_editor_screen.dart` yapısı P20'nin.
- Yeni haptik eklenmedi (`customizable.dart`'taki `HapticFeedback` P38'in göçü).
- Cihazda doğrulanmadı (telefon ölçüm ajanında).
