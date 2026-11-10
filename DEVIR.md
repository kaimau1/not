# DEVIR — P05 (F60.S4, F63.1, F63.2) · dal `oto/P05-silgi-penpolicy`

## Yapılanlar
- F63.1: `viewers/pen_policy.dart` (`PenPolicy.resolve`) + `test/pen_policy_test.dart` (tablo + "yerel kopya yok" bekçisi).
  Sayfa (`note_editor_flow._penPolicy`), sabit (`pinned_media_pane._policy`), gömülü (`note_images._docInkFor`),
  paket (`note_package` build) oradan okur. Görüntüleyici/çizim `allowedKinds` hiç atamıyor (kopya yoktu; F63.4 bağlar).

## Şu an
- F60.S4 kırmızı test (`test/pen_single_tool_test.dart`) → F63.2 tek araç durumu.
- Kök neden: `InkController` (viewers/ink_layer.dart) araç alanlarını (eraser/pen/color/widthPx…) KURULUMDA
  `InkToolMemory`'den kopyalıyor; tepsi yalnız sayfa denetleyicisini sürüyor (`PenTray(controller: _pageInkOf(note))`).
- Tasarım: alanlar `InkToolMemory`'yi okuyan getter; `InkToolMemory.toolRev` bildirici; `InkController.active`
  (son dokunulan yüzey), editör tepsisi geri al/yineleyi ona yollar.

## Sıradaki
- Plan `[x]`, `docs/regresyon_listesi.md`, `docs/hafiza/kalem.md` tek satır, tam `flutter analyze`.

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/pen_policy_test.dart test/pen_single_tool_test.dart --reporter failures-only`
