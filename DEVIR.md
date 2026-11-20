# DEVIR — P85 PL6 Play Billing (dal oto/P85-play-billing)

- Yapılan: Kuyruk satırı P85 (sürüyor). Sunucu: `functions/billing_util.js` (+test, 10 yeşil),
  `functions/billing.js` (`verifyPurchase` onCall App Check zorunlu, `playRtdn` Pub/Sub), `index.js`
  yalnız `PLAY_PACKAGE_NAME` varken bağlar (kişisel proje deploy'u değişmez), `dropEntitlement`
  bağları da siler; `google-auth-library` (firebase-admin'in sürümü), CI node --test satırı.
- Kural değişmedi: `entitlements/{uid}` zaten istemciye yazılamaz; `purchaseTokens` için eşleşme yok
  (varsayılan RET).
- KARAR (en güvenli, sabah bakılacak): deneme = Play aboneliğinin 7 gün teklifi; `startTrial` (hesap
  denemesi) bağlanmadı (çifte deneme + yeni hesapla yenilenebilir).
- Sıradaki: istemci `in_app_purchase` (pubspec eklendi) servis + ürün sabitleri → Pro ekranı (yalnız
  Play) + AI katman kapısı → bekçi testleri → belgeler.
- Test: `cd functions && node --test billing_util.test.js`; `flutter test test/entitlement_test.dart`.
