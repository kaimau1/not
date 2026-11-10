# DEVIR — P05 (F60.S4, F63.1, F63.2) · dal `oto/P05-silgi-penpolicy`

## Yapılanlar
- F63.1: `viewers/pen_policy.dart` (`PenPolicy.resolve`) + `test/pen_policy_test.dart` (tablo + "yerel kopya yok" bekçisi).
  Sayfa (`note_editor_flow._penPolicy`), sabit (`pinned_media_pane._policy`), gömülü (`note_images._docInkFor`),
  paket (`note_package` build) oradan okur. Görüntüleyici/çizim `allowedKinds` hiç atamıyor (kopya yoktu; F63.4 bağlar).

- F60.S4 + F63.2: araç alanları `InkController`'da getter → `InkToolMemory` (eraser/arrow/shape/lasso/pen/color/
  width…); `InkToolMemory.toolRev` bütün açık denetleyicileri uyarır; `InkController.active` (son dokunulan yüzey);
  editör tepsisi `followActive` ile geri al/yineleyi ona yollar. Test `test/pen_single_tool_test.dart` (9 yeşil;
  düzeltmeden önce silgi/renk testleri kırmızıydı: çizgi 2, renk siyah).
- Kök neden: denetleyici aracı KURULUMDA kopyalıyordu; tepsi yalnız sayfa denetleyicisini sürüyordu.
- Geçici araç (silgi/ok/şekil/kement) açık denetleyici kalmayınca sıfırlanır (`openSession`); testte denetleyiciyi
  dispose etmeyen dosya `InkToolMemory.reset()` çağırmalı.

## Şu an
- Belgeler: plan `[x]`, regresyon listesi, hafıza satırı.

## Sıradaki
- Plan `[x]`, `docs/regresyon_listesi.md`, `docs/hafiza/kalem.md` tek satır, tam `flutter analyze`.

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/pen_policy_test.dart test/pen_single_tool_test.dart --reporter failures-only`
