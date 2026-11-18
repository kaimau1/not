# DEVIR — P71 PL14 hak (entitlement) altyapısı (dal oto/P71-hak-altyapisi)

Durum: BİTTİ (push yok, bulut işçisi). Taban `ccr-bde27ee2-8r5lmj`.

Yapılanlar:
1. `0c780212` firestore.rules `entitlements/{uid}`: sahibi get, list/yazma yok (Admin SDK).
   rules-test PL14 testi (okuma/başkası/anon/liste/sorgu/yaratma/güncelleme/silme) → 27/27.
2. `c0930e0b` `lib/features/entitlement/` model + sağlayıcılar; kapı `EntitlementGate.active =
   PlayBuild.enabled`; bayraksızda Firestore okunmaz, her özellik açık. `ProFeature` listesi
   yer tutucu (sabah bakılacak). Hesap silme `keptCollections`'a eklendi (account_deletion_test).
3. `01deca88` functions/entitlements.js tetikleyici TASLAĞI (index.js'e bağlı değil) + saf
   yardımcı + node testi (7/7).
4. `c8a71757` regresyon satırı + docs/hafiza/veri.md; `135382a4` play_hazirlik.md sözleşme.

Kök neden/kanıt: hak belgesi `users/{uid}`'ye konamaz — o belge istemciden silinebiliyor
(firestore.rules `match /users/{uid}` allow delete) → deneme sıfırlanırdı; ayrı kök.
İşe yaramayan: testte `read(entitlementProvider.future)` takıldı — Riverpod 3 dinleyicisiz
sağlayıcıyı duraklatıyor → `container.listen` ile çözüldü.

Kalan (başka paket): ekranlara kapı bağlama (PL2/PL6), `premiumUntil` → entitlement taşıma
(AI dosyası, paralel işçi), Storage'da yeni ek yükleme kapısı, misafir→Google denemesi.

Test komutları:
- `cd rules-test && npm ci && npm test`
- `flutter test test/entitlement_test.dart test/account_deletion_test.dart --reporter failures-only`
- `flutter test test/entitlement_test.dart --dart-define=NOTLAR_PLAY=true --reporter failures-only`
- `cd functions && node --test` · `flutter analyze` temiz.
