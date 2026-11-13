# DEVIR — P38 Hareket ve dokunsal dil (dal `oto/P38-hareket`)

## Yapılan
- F77.2 `lib/core/haptics.dart` `AppHaptics` (tick/thud/heavy + `heaviest` = çöpe bırakmanın heavyImpact'i, tür korundu). 53 çağrı göçtü; mandal `haptic` 88 → 35.
- F77.2 eksik: hatırlatıcı kaydet `thud`, kart ⋮/işlem levhası sabitle/yıldızla `tick`, balon yıldızı `tick`.

## ÇİT — P55/P56 sonrasına bırakılan (35 doğrudan çağrı)
- `dashboard_screen.dart` (+ parçaları `dashboard_selection.dart`, `dashboard_shelf.dart`), `dashboard_widgets.dart`,
  `note_editor_screen.dart` (+ parçaları `note_editor_flow/gestures/media_view.dart`), `items_editor.dart`, `items_editor_actions.dart`, `bubble_pin.dart` hariç (göçtü).
- Kalan eksik denetim: madde işaretleme `thud`, madde yıldızı `tick`, kart bırakma `thud` (hepsi çitteki dosyalarda).
- Göç: aynı sed (`HapticFeedback.selectionClick→AppHaptics.tick`, light→thud, medium→heavy), import kütüphane dosyasına; bütçeyi 0'a indir.

## Doğrulanmadı
- Cihazda titreşim/A/B ölçümü yok (yürütücü yaptıracak).
