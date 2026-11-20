# DEVIR — P85 PL6 Play Billing (dal oto/P85-play-billing)

- Yapılan: Kuyruk satırı P85 eklendi (sürüyor).
- Şu an: mevcut `EntitlementService` + `functions/entitlements.js` taslağı incelendi; kural zaten
  istemciye yazmayı kapatıyor (`firestore.rules` `match /entitlements/{uid}`) → kural değişmeyecek.
- Sıradaki: istemci ürün sabitleri + `in_app_purchase` satın alma servisi → Function `verifyPurchase`
  + RTDN → Pro ekranı (yalnız Play) + bekçi testi → belgeler.
- Test: `flutter test test/entitlement_test.dart --reporter failures-only` (+ `--dart-define=NOTLAR_PLAY=true`),
  `cd functions && node --test`.
