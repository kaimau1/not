# DEVİR — P15 Kalem akışları (F63.3, F63.4, F63.5) · dal `oto/P15-kalem-akislari`

## Yapılanlar
- **F63.3** sabit görsele kalem — `pinned_media_pane.dart` (`_imageInkLayer`, `_inkableImage`),
  `note_media_box.dart` (`imageInk: false` → çizimi bölme boyar). Test `test/pinned_image_ink_test.dart`.

## Şu an
- **F63.4** tam ekran görüntüleyicilerde yüzen düğme. Kanıt testleri YAZILDI ve KIRMIZI
  (`test/viewer_stylus_toggle_test.dart`, `test/pen_policy_test.dart` görüntüleyici satırı);
  düzeltme yazılıyor: `PenPolicy.viewer` = sabit belge kuralı + düğme; üç görüntüleyiciye ortak
  `ViewerPen` mixin'i (`viewers/viewer_pen.dart`): `StylusToggleOverlay`, ilk kalemde `stylusEver`,
  kip kapalıyken `InkClaim` (kalem yazar, parmak gezinir).

## Kök neden / kanıt
- Sabit görselde mürekkep katmanı yoktu; `_ImageBox` çizimi kutunun tamamına boyuyordu
  (`note_media_box.dart` `Positioned.fill` + `InkPainter`) — bölme görselin oranında değilken kayık.
- Tam ekranda `InkPageLayer` `IgnorePointer(!editing)`: kip kapalıyken kalemi hiç görmez →
  `stylusEver` orada işaretlenemiyordu.

## Denenip işe yaramayan
- Testte kalemden hemen sonra parmakla çift dokunuş: avuç reddi GERÇEK saate bakar (400 ms) →
  `tester.runAsync(Future.delayed(500 ms))` gerekir.

## Sıradaki
- F63.4 bitir → F63.5 (K-O5 "En güvenli: dokunma" + "sabah bakılacak"; ipucu + sayfa altı boşluğu).

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/pinned_image_ink_test.dart test/viewer_stylus_toggle_test.dart test/pen_policy_test.dart --reporter failures-only`
