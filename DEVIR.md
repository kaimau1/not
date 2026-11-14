# DEVIR — P63 / PB0 iskelet (dal oto/PB0-iskelet, taban 4d56c9ab)

Tarif: `docs/plan_tasarim_B.md` §6 + §7.1. Bileşenler ekrana BAĞLANMAZ.

## Yapılanlar
- ColorDot `lib/core/widgets/color_dot.dart` + `test/color_dot_test.dart`
- CustomizeBoard `lib/core/widgets/customize_board.dart` + `test/customize_board_test.dart`

## Şu anki adım
TemplatePreviewCard → PenStrokePreview → VoiceLevelWave → DividerKindPicker → çeviri (tek commit) → plan [x].

## Kararlar / kanıt
- P62 iskeleti main'de (yürütücü talimatı): §6.0 "eşdeğer belirteç" tablosu yerine doğrudan
  `AppMotion.selection` kullanılıyor.
- `ReorderableListView.onReorder` bu Flutter'da kullanımdan kalktı → `onReorderItem`; panonun
  `onReorder(old, new)` dizini öğe çıkarıldıktan SONRAKİ yer.
- Kırmızı kanıt: her test, bileşeni yazılmadan önce derlenmiyor (dosya yok).

## Test
`"C:/src/flutter/bin/flutter.bat" test test/color_dot_test.dart test/customize_board_test.dart --reporter failures-only`
