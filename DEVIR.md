# DEVIR — P62 Görsel tasarım A (plan + iskelet)

Dal: `oto/P62-tasarim-A`. Bu paket YALNIZ plan + iskelet; uygulama `docs/plan_tasarim_A.md` §8 paketleriyle (PA0–PA9).

## Yapılanlar
- Plan TAMAM (2026-11-14): §0–§5 (c4ac9440 ve öncesi), §6 kaydırma (029437c7), §7 kasma + bütçe S29–S36 (33a21ade), §8 paketler + Durum satırı (bu commit). "YARIM" bölümü eritildi; S atıfları düzeltildi (§2.4 → S29, S36; §3.3 → S30; §5.6 → S31, S32).
- İskelet (12b1842d, 07f9429e): `app_design.dart` (`AppTone`, `AppSurface`, `AppSwipe`), `AppMotion.selection/emphasized/exitOf`, `app_banner.dart`, `app_notice.dart` (`app.dart`a BAĞLI DEĞİL), `test/app_notice_test.dart` yeşil. Bu turda koda DOKUNULMADI.

## Kararlar
- Model (kullanıcı, 2026-11-14): görünüşü belirleyen paket = fable; opus yalnız görsel olmayan altyapı / ölçüm; sonnet yalnız CI / test / mekanik. PA0, PA5 opus; PA9 sonnet; PA1–PA4, PA6–PA8 fable.

## Kanıt / kök neden (yeni bulunanlar)
- `FolderSwipe.commitFraction` testlerde kullanılmıyor (yalnız `dashboard_widgets.dart:1360, 1362`) → sabit silinir, `AppSwipe` kullanılır.
- `_NoticeLane` şerit boşken de `MediaQuery.viewInsetsOf` okuyor (`app_notice.dart:202-205`) → klavye karesinde kurulur (R5; PA5'in ilk işi, S31 `klavye_karesi_kurulum`).
- `_pumpHome` yalnız `/` ve `/note/:id` kurar → ayar / takvim bütçeleri ekranı doğrudan kurar (S22 kalıbı).
- §7.3 "beklenen bugün" sütunu HİPOTEZ (ölçülmedi) — PA0 ölçer.

## Açık noktalar (yürütücü / kullanıcı)
- PA5 modeli opus yazıldı (kılık iskelette); "bildirimin yeri de görünüş" denirse fable.
- `KONTROL_LISTEM.md` 42 açık madde (eşik 40, F58.4); P62 en az 8 madde ekler.

## Sıradaki adım
Yürütücü: bu dalı CI yeşilken main'e `[apk]`sız birleştir (DEVIR.md'yi sil) → Kuyruk'a PA0…PA9 satırlarını aç (§8.2 tablosu: model, bağımlılık, A/B, `[apk]` noktası) → PA0 (opus) önce → A: PA1 → (PA2 ∥ PA3) · B: PA5 → PA6 → PA7 · boş yuvaya PA4, PA8.

Test (kod değişirse): `flutter test test/app_notice_test.dart test/design_tokens_guard_test.dart --reporter failures-only`
