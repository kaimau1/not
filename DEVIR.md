# DEVIR — P38 Hareket ve dokunsal dil (dal `oto/P38-hareket`)

## Yapılan (her madde ayrı commit)
- F77.2 `lib/core/haptics.dart` `AppHaptics` (tick/thud/heavy + `heaviest` = çöpe bırakmanın heavyImpact'i, tür korundu). 53 çağrı göçtü; mandal `haptic` 88 → 35.
- F77.2 eksik: hatırlatıcı kaydet `thud`, kart ⋮/işlem levhası sabitle/yıldızla `tick`, balon yıldızı `tick`.
- F77.1 ayar/rehber/AI/klasör sohbet/ipucu/düzen kipi/bölünmüş kabuk süre-eğri `AppMotion.of`'a; mandal süre 219→207, eğri 94→90.
- F77.3 `TogglePop` (yıldız 1→1,15→1), levha karosu `PressScale(0.97)`, görev Google simgesi `AnimatedSwitcher`. Klasör çipi 0,97 + sayı solması S24 (soğuk açılış) bütçesini aştı → geri alındı.
- F77.4 `theme_motion_test` quick/long da kapsar.

## ÇİT — P55/P56 sonrasına bırakılan
- 35 doğrudan `HapticFeedback`: `dashboard_screen.dart` (+ `dashboard_selection/shelf.dart`), `dashboard_widgets.dart`,
  `note_editor_screen.dart` (+ `note_editor_flow/gestures/media_view.dart`), `items_editor.dart`, `items_editor_actions.dart`.
  Göç: selectionClick→`AppHaptics.tick`, light→thud, medium→heavy; import kütüphane dosyasına; bütçe 0.
- Eksik denetim çitte: madde işaretleme `thud`, madde yıldızı `tick`, kart bırakma `thud`; editör iğne/yıldız `TogglePop`; ana/editör bulut simgesi `AnimatedSwitcher`.

## Sabah bakılacak
- F77.3-5 bildirim şeridi 8 dp kayma yapılmadı (SnackBar hareketi Material içinde).
- Çekirdek bileşen varsayılan süreleri (pop_in/expand_reveal/scale_settle) editörde de kullanılıyor — dokunulmadı.

## Doğrulanmadı
- Cihazda titreşim/A/B ölçümü yok (yürütücü yaptıracak). Yerelde `folder_strip_fixed_test` CRLF yüzünden kırmızı (önceden de; dokunulmadı).
