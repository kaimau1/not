/**
 * PLAY BILLING yardımcıları — PLAN §1.5 PL6. Saf: Firebase'e / ağa bağlı
 * değil, `node --test` ile sınanır. Ağ ve Firestore `billing.js`'te.
 *
 * Sözleşme (`docs/play_hazirlik.md` "Hak sözleşmesi"): istemci
 * `entitlements/{uid}`'den yalnız `tier`, `proUntil`, `lifetimeOwned`,
 * `trialEndsAt` okur; gerisi denetim izi.
 */
const crypto = require("node:crypto");

/**
 * Ürün kimlikleri — istemcideki `BillingProducts` ile AYNI olmalı (bekçi
 * `test/billing_test.dart`). Play Console'da bir kez verilen kimlik bir daha
 * kullanılamaz: değiştirme.
 */
const PRO_SUBSCRIPTION = "pro"; // temel planlar: monthly, yearly (+7 gün deneme teklifi)
const LIFETIME_PRODUCT = "lifetime"; // tek sefer, tüketilmez

/** Ödenmiş süresi işleyen abonelik durumları (Play `subscriptionsv2`). */
const PAID_STATES = new Set([
  "SUBSCRIPTION_STATE_ACTIVE",
  // Ödeme alınamadı, Play yeniden deniyor: Google erişimin sürmesini önerir.
  "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  // Kullanıcı iptal etti ama ödediği süre bitmedi: süre sonuna dek Pro.
  "SUBSCRIPTION_STATE_CANCELED",
]);

/** Belirteç (purchaseToken) belge kimliği: uzun ve gizli, düz yazılmaz. */
function tokenKey(token) {
  return crypto.createHash("sha256").update(String(token)).digest("hex");
}

/**
 * Play'e satın almada verilen `obfuscatedAccountId`: uid'in tek yönlü özeti
 * (Play kişisel veriyi düz istemiyor; 64 karakter = Play sınırı). İstemci
 * aynısını üretir (`billing_service.dart` `billingAccountTag`).
 */
function accountTag(uid) {
  return crypto.createHash("sha256").update(String(uid)).digest("hex");
}

/**
 * `purchases.subscriptionsv2.get` yanıtı → hak değişikliği.
 * `paidUntil`: ödenmiş süre bitişi; ödenmiş süre işlemiyorsa (askıda,
 * duraklatılmış, süresi dolmuş, iade/iptalle geri alınmış) en geç `now`
 * (bitmiş sayılır). Bekleyen (PENDING) ödeme: `paidUntil` null, hak yok.
 * Pro aboneliği değilse null (yanlış ürün kimliği).
 */
function readSubscription(res, now) {
  if (!res) return null;
  const item = (res.lineItems || []).find(
    (i) => i && i.productId === PRO_SUBSCRIPTION,
  );
  if (!item) return null;
  const expiry = item.expiryTime ? new Date(item.expiryTime) : null;
  const paid = PAID_STATES.has(res.subscriptionState);
  let paidUntil = null;
  if (expiry && !Number.isNaN(expiry.getTime())) {
    paidUntil = paid
      ? expiry
      : new Date(Math.min(expiry.getTime(), now.getTime()));
  }
  const ids = res.externalAccountIdentifiers || {};
  return {
    paidUntil,
    pending: res.subscriptionState === "SUBSCRIPTION_STATE_PENDING",
    needsAck:
      paid && res.acknowledgementState === "ACKNOWLEDGEMENT_STATE_PENDING",
    accountTag: ids.obfuscatedExternalAccountId || null,
    linkedToken: res.linkedPurchaseToken || null,
  };
}

/**
 * `purchases.products.get` yanıtı (ömür boyu) → hak değişikliği.
 * purchaseState 0 = alındı, 1 = iptal, 2 = bekliyor.
 */
function readProduct(res) {
  if (!res) return null;
  const owned = res.purchaseState === 0;
  return {
    owned,
    pending: res.purchaseState === 2,
    needsAck: owned && res.acknowledgementState === 0,
    accountTag: res.obfuscatedExternalAccountId || null,
  };
}

const isAfter = (d, now) => d instanceof Date && d.getTime() > now.getTime();
const later = (a, b) => {
  if (!(a instanceof Date)) return b instanceof Date ? b : null;
  if (!(b instanceof Date)) return a;
  return a.getTime() >= b.getTime() ? a : b;
};

/**
 * Var olan hak belgesine bir değişikliği uygular → yazılacak alanlar.
 *
 * @param {object|null} existing  Firestore verisi (zamanlar Date'e çevrilmiş)
 * @param {{sub?: {tokenKey: string, paidUntil: Date|null},
 *          lifetime?: boolean}} change
 * @param {Date} now
 *
 * Kurallar (PLAN §1.5):
 * - Ömür boyudan Pro'ya geçene ömür boyu kalır; Pro bitince ömür boyu döner
 *   (istemci `effectiveTier`: Pro süresi bitti → lifetimeOwned → ücretsiz).
 * - Abonelik değişince (aylık → yıllık) Play YENİ belirteç verir; ESKİ
 *   belirtecin "bitti" bildirimi yenisinin süresini EZMEZ.
 * - `grantUntil` (elle: geliştirici hesabı) satın almayla kısalmaz:
 *   `proUntil` = en geç(ödenmiş süre, elle verilen süre).
 * - `trialEndsAt` (hesap denemesi taslağı) dokunulmaz.
 */
function mergeEntitlement(existing, change, now) {
  const prev = existing || {};
  let subTokenKey = prev.subTokenKey || null;
  let paidUntil = prev.paidUntil instanceof Date ? prev.paidUntil : null;
  if (change.sub) {
    const other = subTokenKey && subTokenKey !== change.sub.tokenKey;
    const apply =
      !other || isAfter(change.sub.paidUntil, now) || !isAfter(paidUntil, now);
    if (apply) {
      subTokenKey = change.sub.tokenKey;
      paidUntil = change.sub.paidUntil || null;
    }
  }
  const lifetimeOwned =
    typeof change.lifetime === "boolean"
      ? change.lifetime
      : prev.lifetimeOwned === true || prev.tier === "lifetime";
  const grantUntil = prev.grantUntil instanceof Date ? prev.grantUntil : null;
  const proUntil = later(paidUntil, grantUntil);
  return {
    // `pro` + geçmiş `proUntil` = Pro bitti (istemci "Drive'a taşı" önerir).
    tier: proUntil ? "pro" : lifetimeOwned ? "lifetime" : "free",
    proUntil,
    paidUntil,
    subTokenKey,
    lifetimeOwned,
    source: "play",
  };
}

/**
 * RTDN (Gerçek Zamanlı Geliştirici Bildirimi) iletisi → ne yapılacak.
 * Abonelik: durum Play'den yeniden okunur (bildirim türüne güvenilmez —
 * sıra karışabilir, tek doğru kaynak API). Ömür boyu: aynı. İade/geri alma
 * (voided): hak hemen kalkar.
 */
function parseRtdn(msg) {
  if (!msg || typeof msg !== "object") return null;
  const base = { packageName: msg.packageName || null };
  const sub = msg.subscriptionNotification;
  if (sub && sub.purchaseToken) {
    return { ...base, kind: "sub", token: sub.purchaseToken };
  }
  const one = msg.oneTimeProductNotification;
  if (one && one.purchaseToken) {
    return { ...base, kind: "product", token: one.purchaseToken, productId: one.sku };
  }
  const voided = msg.voidedPurchaseNotification;
  if (voided && voided.purchaseToken) {
    return {
      ...base,
      kind: "voided",
      token: voided.purchaseToken,
      // 1 = abonelik, 2 = tek sefer.
      subscription: voided.productType === 1,
    };
  }
  if (msg.testNotification) return { ...base, kind: "test" };
  return null;
}

module.exports = {
  PRO_SUBSCRIPTION,
  LIFETIME_PRODUCT,
  tokenKey,
  accountTag,
  readSubscription,
  readProduct,
  mergeEntitlement,
  parseRtdn,
};
