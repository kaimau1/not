# DEVİR — P15 Kalem akışları (F63.3, F63.4, F63.5) · dal `oto/P15-kalem-akislari`

## Yapılanlar (üçü de bitti; plan `[x]`, cihazda doğrulanmadı)
- **F63.3** sabit görsele kalem — `pinned_media_pane.dart` (`_imageInkLayer`, `_inkableImage`),
  `note_media_box.dart` (`imageInk`). Test `test/pinned_image_ink_test.dart`.
- **F63.4** tam ekranda yüzen kalem düğmesi — `viewers/viewer_pen.dart` (`ViewerPen`), `pen_policy.dart`,
  üç görüntüleyici, `ink_layer.dart` (`noteStylusEver`). Testler `test/viewer_stylus_toggle_test.dart`,
  `test/pen_policy_test.dart`.
- **F63.5** telefonda elle yazma — `tips.dart` (`penTwoFinger`), `note_editor_screen.dart`
  (`_penModeOpened`). Test `test/editor_pen_tablet_test.dart`. K-O5: "En güvenli: dokunma" → alt çubuk
  aynı, **sabah bakılacak**. Sayfa altı boşluğu: sorun üretilemedi (zaten ekranın %70'i), dokunulmadı.

## Kök neden / kanıt
- Sabit görselde mürekkep katmanı yoktu; `_ImageBox` çizimi kutunun tamamına boyuyordu.
- Tam ekranda `InkPageLayer` `IgnorePointer(!editing)`: kip kapalıyken kalemi hiç görmez.

## Denenip işe yaramayan
- Testte kalemden hemen sonra parmak: avuç reddi gerçek saate bakar → `tester.runAsync(delay 500 ms)`.

## Bilerek yapılmayan
- Bölme çubuğuna görsel için kalem düğmesi (K-O6 açık); tam ekranda kip kapalıyken kalem tepsisi.
- PDF/slayt tam ekranı için widget testi (pdfrx) — yalnız görsel görüntüleyici testli.

## Sıradaki
- Yürütücü: CI yeşilse birleştir; sürüm notu maddeleri raporda. Cihaz: `docs/regresyon_listesi.md` son satır.

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/pinned_image_ink_test.dart test/viewer_stylus_toggle_test.dart test/pen_policy_test.dart test/editor_pen_tablet_test.dart --reporter failures-only`

## YÜRÜTÜCÜ NOTU (2026-11-11 ~16:05)
Kod işi BİTTİ (F63.3–F63.5, son 22161e3b). Kalan yalnız yürütücü adımları: CI (43054698694) yeşilse OTOMASYON P15 satırı bitti + regresyon/HAFIZA kontrol, DEVIR.md sil, main birleştir. Sürüm notu borcu (P05 maddeleri + P15: sabit görsele kalem, tam ekranda yüzen kalem düğmesi, telefonda iki parmak ipucu) bir sonraki [apk]. Tur limit freninde (%98) durdu.
