// PLAY BILLING ÜRÜNLERİ — PLAN §1.5 PL6. Ürün kimliklerinin TEK yeri
// (sunucu eşi `functions/billing_util.js`; bekçi `test/billing_test.dart`).
// Play Console'da bir kez verilen kimlik bir daha kullanılamaz: değiştirme.
//
// FİYAT KODDA YOK: mağazadan okunur (`ProductDetails`), kullanıcının
// ülkesine/para birimine göre Play biçimler. Fiyat kararı açık (PLAN §1.5).

/// Satın alınabilen planlar (ekrandaki sırayla).
enum BillingPlan {
  monthly(BillingProducts.pro, BillingProducts.monthlyPlan),
  yearly(BillingProducts.pro, BillingProducts.yearlyPlan),
  lifetime(BillingProducts.lifetime, null);

  const BillingPlan(this.productId, this.basePlanId);

  /// Play ürün kimliği.
  final String productId;

  /// Abonelikte temel plan kimliği; tek seferde null.
  final String? basePlanId;

  bool get isSubscription => basePlanId != null;
}

abstract final class BillingProducts {
  /// Pro aboneliği (dahili AI + bulut ekleri + ömür boyunun hepsi). İki temel
  /// plan; her birinde 7 gün ücretsiz deneme TEKLİFİ (Play Console'da, "yeni
  /// müşteri" uygunluğuyla — Play denemeyi yalnız uygun olana listeler).
  static const pro = 'pro';
  static const monthlyPlan = 'monthly';
  static const yearlyPlan = 'yearly';

  /// Ömür boyu: tek sefer, tüketilmez (kendi Gemini anahtarı, yedek, görünüm).
  static const lifetime = 'lifetime';

  static const all = {pro, lifetime};

  /// Play'in abonelik yönetimi sayfası (plan değiştir / iptal).
  static Uri manageUrl(String packageName) => Uri.https(
    'play.google.com',
    '/store/account/subscriptions',
    {'sku': pro, 'package': packageName},
  );
}
