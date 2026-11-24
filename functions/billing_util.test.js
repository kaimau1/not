const test = require("node:test");
const assert = require("node:assert");
const u = require("./billing_util");

const now = new Date("2026-11-20T12:00:00Z");
const day = 24 * 60 * 60 * 1000;
const future = new Date(now.getTime() + 30 * day);
const past = new Date(now.getTime() - day);

const sub = (state, expiry, extra = {}) => ({
  subscriptionState: state,
  acknowledgementState: "ACKNOWLEDGEMENT_STATE_PENDING",
  lineItems: [{ productId: "pro", expiryTime: expiry && expiry.toISOString() }],
  ...extra,
});

test("etkin / iptal edilmiş ama süresi süren abonelik ödenmiş sayılır", () => {
  for (const s of [
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_CANCELED",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  ]) {
    const r = u.readSubscription(sub(s, future), now);
    assert.strictEqual(r.paidUntil.getTime(), future.getTime(), s);
    assert.strictEqual(r.needsAck, true, s);
  }
});

test("askı / süresi dolmuş / geri alınmış abonelik en geç şimdi biter", () => {
  for (const s of [
    "SUBSCRIPTION_STATE_ON_HOLD",
    "SUBSCRIPTION_STATE_EXPIRED",
    "SUBSCRIPTION_STATE_PAUSED",
  ]) {
    const r = u.readSubscription(sub(s, future), now);
    assert.ok(r.paidUntil.getTime() <= now.getTime(), s);
    assert.strictEqual(r.needsAck, false, s);
  }
});

test("bekleyen ödeme hak vermez; yanlış ürün reddedilir", () => {
  const p = u.readSubscription(sub("SUBSCRIPTION_STATE_PENDING", null), now);
  assert.strictEqual(p.paidUntil, null);
  assert.strictEqual(p.pending, true);
  const wrong = sub("SUBSCRIPTION_STATE_ACTIVE", future);
  wrong.lineItems[0].productId = "baska";
  assert.strictEqual(u.readSubscription(wrong, now), null);
});

test("ömür boyu: alındı / iptal / bekliyor", () => {
  assert.deepStrictEqual(
    u.readProduct({ purchaseState: 0, acknowledgementState: 0 }),
    { owned: true, pending: false, needsAck: true, accountTag: null },
  );
  assert.strictEqual(u.readProduct({ purchaseState: 1 }).owned, false);
  assert.strictEqual(u.readProduct({ purchaseState: 2 }).pending, true);
});

test("Pro alınca katman pro; ömür boyu varsa kalır, Pro bitince döner", () => {
  const withLifetime = { tier: "lifetime", lifetimeOwned: true };
  const e = u.mergeEntitlement(
    withLifetime,
    { sub: { tokenKey: "a", paidUntil: future } },
    now,
  );
  assert.strictEqual(e.tier, "pro");
  assert.strictEqual(e.lifetimeOwned, true);
  const lapsed = u.mergeEntitlement(
    e,
    { sub: { tokenKey: "a", paidUntil: now } },
    now,
  );
  assert.strictEqual(lapsed.lifetimeOwned, true);
  assert.ok(lapsed.proUntil.getTime() <= now.getTime());
});

test("iade edilen ömür boyu kalkar; başka belirtecin iptali dokunmaz", () => {
  const owned = u.mergeEntitlement(
    null,
    { lifetime: { tokenKey: "L1", owned: true } },
    now,
  );
  assert.strictEqual(owned.tier, "lifetime");
  const other = u.mergeEntitlement(
    owned,
    { lifetime: { tokenKey: "L2", owned: false } },
    now,
  );
  assert.strictEqual(other.lifetimeOwned, true);
  const refunded = u.mergeEntitlement(
    owned,
    { lifetime: { tokenKey: "L1", owned: false } },
    now,
  );
  assert.strictEqual(refunded.tier, "free");
  assert.strictEqual(refunded.lifetimeOwned, false);
});

test("plan değişimi: eski belirtecin bitişi yeni aboneliği ezmez", () => {
  const current = u.mergeEntitlement(
    null,
    { sub: { tokenKey: "yeni", paidUntil: future } },
    now,
  );
  const old = u.mergeEntitlement(
    current,
    { sub: { tokenKey: "eski", paidUntil: past } },
    now,
  );
  assert.strictEqual(old.subTokenKey, "yeni");
  assert.strictEqual(old.proUntil.getTime(), future.getTime());
  // Aynı belirteç bitince (iptal/iade) Pro biter.
  const voided = u.mergeEntitlement(
    current,
    { sub: { tokenKey: "yeni", paidUntil: now } },
    now,
  );
  assert.ok(voided.proUntil.getTime() <= now.getTime());
});

test("elle verilen süre (geliştirici) satın almayla kısalmaz", () => {
  const far = new Date("2100-01-01T00:00:00Z");
  const e = u.mergeEntitlement(
    { tier: "pro", proUntil: far, grantUntil: far },
    { sub: { tokenKey: "a", paidUntil: past } },
    now,
  );
  assert.strictEqual(e.tier, "pro");
  assert.strictEqual(e.proUntil.getTime(), far.getTime());
});

test("RTDN iletisi çözülür", () => {
  assert.deepStrictEqual(
    u.parseRtdn({
      packageName: "p",
      subscriptionNotification: { notificationType: 2, purchaseToken: "t" },
    }),
    { packageName: "p", kind: "sub", token: "t" },
  );
  assert.strictEqual(
    u.parseRtdn({
      voidedPurchaseNotification: { purchaseToken: "t", productType: 2 },
    }).subscription,
    false,
  );
  assert.strictEqual(u.parseRtdn({ testNotification: {} }).kind, "test");
  assert.strictEqual(u.parseRtdn({}), null);
});

test("hesap etiketi ve belirteç anahtarı 64 onaltılık karakter", () => {
  assert.match(u.accountTag("uid-1"), /^[0-9a-f]{64}$/);
  assert.notStrictEqual(u.tokenKey("a"), u.tokenKey("b"));
});

test("çoklu uygulama paketi çözümlemesi: Notlar + Dosyalarım izin listesi", () => {
  const allowed = u.parseAllowedPackages({
    PLAY_PACKAGE_NAMES: "dev.kaimau.notlar, com.dosyaokuyucu.dosya_okuyucu",
    PLAY_PACKAGE_NAME: "dev.kaimau.notlar",
  });
  assert.deepStrictEqual(allowed, [
    "dev.kaimau.notlar",
    "com.dosyaokuyucu.dosya_okuyucu",
  ]);
  assert.strictEqual(u.resolvePackageName("", allowed), "dev.kaimau.notlar");
  assert.strictEqual(
    u.resolvePackageName("com.dosyaokuyucu.dosya_okuyucu", allowed),
    "com.dosyaokuyucu.dosya_okuyucu",
  );
  assert.strictEqual(u.resolvePackageName("evil.pkg", allowed), null);
});
