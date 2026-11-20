# DEVIR — P85 PL6 Play Billing (dal oto/P85-play-billing)

- Yapılan (commit sırası): Kuyruk satırı P85 · sunucu `functions/billing.js` + `billing_util.js`
  (+test) — `verifyPurchase` (onCall, App Check), `playRtdn` (Pub/Sub); `index.js` yalnız
  `PLAY_PACKAGE_NAME` varken bağlar · istemci `in_app_purchase` 3.3.1 + `_android` 0.5.5,
  `billing_products.dart` (kimlikler tek yer; fiyat mağazadan), `billing_service.dart`
  (satın al → doğrula → onayla; doğrulanamayan ONAYLANMAZ; açılışta 20 sn sonra sessiz onarım,
  yalnız Play) · AI katman kapısı (`AiAvailability.needsPro`, `AiAdmission.checkTier`, Play'de
  `premiumProvider` = entitlement Pro) · Pro ekranı (`/premium` Play'de ProScreen), Ayarlar
  kısayolu yalnız Play.
- Kural değişmedi: `entitlements/{uid}` istemciye yazılamaz; `purchaseTokens` eşleşmesiz (RET).
- KARAR (en güvenli, sabah bakılacak): deneme = Play aboneliğinin 7 gün teklifi; `startTrial`
  bağlanmadı. Diğer `ProFeature` kapıları (yedek, görünüm, eşitleme, bulut eki) bağlanmadı.
- Testler: `flutter test test/billing_test.dart` (bayraksız 6 + 6 atlandı; `--dart-define=NOTLAR_PLAY=true`
  11 yeşil), ai_policy/entitlement/play_build iki kipte yeşil; `dart analyze` temiz;
  `cd functions && node --test billing_util.test.js` 10 yeşil.
- Sıradaki: CI izle → belgeler (Kuyruk bitti, PLAN PL6, regresyon, play_hazirlik kurulum, KONTROL).
