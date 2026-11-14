# DEVIR — P62 Görsel tasarım A (plan + iskelet)

Dal: `oto/P62-tasarim-A`. Bu paket YALNIZ plan + iskelet; uygulama `docs/plan_tasarim_A.md` paketleriyle alt modellerde.

## Plan durumu (`docs/plan_tasarim_A.md`)
- BİTTİ: §0 kurallar, §1 ortak dil, §2 ayarlar, §3 hesap levhası, §4 Ayarlar → Hesap, §5 ipucu / uyarı, **§6 kaydırma** (2026-11-14).
- YAZILMADI: **§7 kasma + bütçe senaryoları, §8 uygulama paketleri.** Kalan kanıt ve paket taslağı planın sonundaki "YARIM" bölümünde.
- Model kararı (kullanıcı, 2026-11-14): görünüşü belirleyen paket = fable; opus yalnız görsel olmayan altyapı / ölçüm; sonnet yalnız CI / test / mekanik.
- Düzeltilecek: §2.4 "S28" ve §3.3 "S29" atıfları → P62 numaraları S29–S39 (öneri YARIM bölümünde); bitince baştaki "Durum" satırı.

## İskelet (commit 12b1842d + 07f9429e)
- `app_design.dart` (`AppTone`, `AppSurface`, `AppSwipe`), `AppMotion.selection/emphasized/exitOf`, `app_banner.dart`, `app_notice.dart` (`app.dart`a BAĞLI DEĞİL), `test/app_notice_test.dart` (yeşil).
- 07f9429e: dip bildirimi alt-baş köşe, alt-son 144 × 72 dp yüzen düğme bölgesine girmez (duyuru üstünde); `AppNoticeController.hosted` / `clear()`; şerit sökülünce temizlenir.

## Tuzaklar
- `snackBarBottomObstacle` DİZİLİM sırasında yazılır → dinleyici ekleme.
- Bildirim göçü çağrı yerlerinden DEĞİL dört huniden (§5.3); 237 çağrının 70'i P63 çitinde.
- Worktree'de heredoc içinde kesme işareti / `python - <<EOF` reddediliyor: içeriği Write ile scratchpad'e yaz, `cat >>` ile ekle.

## Sıradaki adım
§6–§8'i yaz (Opus) → Durum satırı → yürütücü Kuyruk'a PA1… paketlerini açar (PA1 önce).

## Komutlar
- `flutter test test/app_notice_test.dart test/design_tokens_guard_test.dart --reporter failures-only`
- Tur: `TOUR_ONLY=ayarlar,ayarlar-account,hesap-levhasi TOUR_SIZES=telefon-kucuk,matepad-yatay TOUR_OUT=build/tour_p62 flutter test tool/tour/screen_tour_test.dart`
