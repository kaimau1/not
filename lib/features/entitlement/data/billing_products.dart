// PLAY BILLING ÜRÜNLERİ — PLAN §2.3 & §3 (Faz 1). Ürün kimliklerinin TEK yeri
// (sunucu eşi `functions/billing_util.js`; bekçi `test/billing_test.dart`).
// Play Console'da bir kez verilen kimlik bir daha kullanılamaz: değiştirme.
//
// FİYAT KODDA YOK: mağazadan okunur (`ProductDetails`), kullanıcının
// ülkesine/para birimine göre Play biçimler.

/// Satın alınabilen ürünler (ekrandaki sırayla). Abonelik YOKTUR.
enum BillingPlan {
  /// Tam Sürüm — 50 TL tek seferlik, ömür boyu (tüketilmez).
  lifetime(BillingProducts.lifetime, consumable: false),

  /// +1.000 Akıllı Karar Paketi — 30 TL, tüketilebilir.
  decisionPack1000(BillingProducts.decisionPack1000, consumable: true);

  const BillingPlan(this.productId, {required this.consumable});

  /// Play ürün kimliği.
  final String productId;

  /// Tüketilebilir ek paket mi (tekrar alınabilir).
  final bool consumable;
}

abstract final class BillingProducts {
  /// Tam Sürüm: tek sefer, ömür boyu, tüketilmez (750 akıllı karar dahil).
  static const lifetime = 'lifetime';

  /// +1.000 Akıllı Karar Paketi: isteğe bağlı tüketilebilir ek kredi paketi.
  static const decisionPack1000 = 'decision_pack_1000';

  static const all = {lifetime, decisionPack1000};
}
