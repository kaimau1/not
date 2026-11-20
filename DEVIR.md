# DEVIR — P85 PL6 Play Billing (dal oto/P85-play-billing)

- Yapılan (commit sırası): Kuyruk P85 · sunucu `functions/billing.js` + `billing_util.js` (+test;
  ömür boyu `lifetimeTokenKey`, abonelik `subTokenKey` korumaları) — `verifyPurchase`, `playRtdn`;
  `index.js` yalnız `PLAY_PACKAGE_NAME` varken bağlar · istemci `in_app_purchase` + `billing_service`
  · AI katman kapısı · Pro ekranı (`/premium` Play'de) + Ayarlar kısayolu yalnız Play · bildirim
  hunisi düzeltmesi · belgeler (Kuyruk bitti, PLAN PL6 [~], regresyon, play_hazirlik kurulum, KONTROL,
  veri.md).
- CI 44756241480: tek kırmızı `notice_paths_guard_test` (pro_screen ham `showSnackBar`) → `showAppMessage`,
  yerelde yeşil. Yerel `flutter build web --release --wasm` yeşil (in_app_purchase web'de derleniyor).
- Kural değişmedi; `purchaseTokens` eşleşmesiz (RET).
- KARAR (en güvenli, sabah bakılacak): deneme = Play aboneliğinin 7 gün teklifi; `startTrial` bağlanmadı;
  yalnız AI kapısı bağlı.
- Doğrulanamayan: gerçek satın alma, RTDN, Play API izni (Play hesabı yok); cihaz yok.
- Test: `flutter test test/billing_test.dart` (+ `--dart-define=NOTLAR_PLAY=true`),
  `cd functions && node --test billing_util.test.js`.
