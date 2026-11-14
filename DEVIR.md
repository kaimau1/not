# DEVIR — P62 Görsel tasarım A (plan + iskelet)

Dal: `oto/P62-tasarim-A`. Bu paket YALNIZ plan + iskelet (Fable); uygulama `docs/plan_tasarim_A.md` §8 paketleriyle alt modellerde.

## Yapılanlar
- İskelet (commit 1): `lib/app/theme/app_design.dart` (`AppTone`, `AppSurface`, `AppSwipe`), `AppMotion.selection/emphasized/exitOf` (`app_tokens.dart`), `lib/core/widgets/app_banner.dart` (`AppBanner`), `lib/core/widgets/app_notice.dart` (`AppNoticeController`, `appNotice`, `AppNoticeHost` — `app.dart`a BAĞLI DEĞİL, görünür davranış değişmedi), `test/app_notice_test.dart` (13 test yeşil).
- Tur: `tool/tour/screen_tour_test.dart` — `ayarlar-<alan>` (9 alan, `?area=`) ve `hesap-levhasi` sahneleri.
- Plan: `docs/plan_tasarim_A.md` (bkz. dosyadaki "Durum" satırı).

## Kanıt (kök nedenler)
- Ayar alan sayfası tek dev kart, içinde düzensiz satırlar: `settings_area.dart:225-262` (`_RowsCard`), hesap alanı 16 `TextButton` (`settings_account.dart`).
- İpucu üstte arama hapını örter: `tips.dart:196-199`; bildirimler ayrı ayrı yollar (156 çağrı / 68 dosya), sıra/koordinasyon yok.
- Yana kaydırma eşikleri dağınık: `dashboard_widgets.dart:1371` (300), `month_grid.dart:68` (200, parmağı izlemez), `app_frame.dart:393,419` (300/200).

## İşe yaramayan / tuzak
- `snackBarBottomObstacle` DİZİLİM sırasında yazılır → dinleyici eklenirse "setState during layout". `AppNoticeHost` değeri yalnız kurulurken okur.
- Turda `/settings?area=` çalışmıyordu (rota `const SettingsScreen()`); düzeltildi.
- Worktree'de `python - <<EOF` ve bileşik komutlar reddediliyor; betiği scratchpad'e yaz, yalın çağır.

## Sıradaki adım
Plan bölümlerini bitir → commit/push. Sonra yürütücü: Kuyruk satırı + uygulama paketlerini aç (PA1 önce).

## Komutlar
- `flutter test test/app_notice_test.dart test/design_tokens_guard_test.dart --reporter failures-only`
- Tur: `TOUR_ONLY=ayarlar,ayarlar-account,hesap-levhasi TOUR_SIZES=telefon-kucuk,matepad-yatay TOUR_OUT=build/tour_p62 flutter test tool/tour/screen_tour_test.dart`
