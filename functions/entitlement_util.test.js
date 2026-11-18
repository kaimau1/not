const test = require("node:test");
const assert = require("node:assert");
const u = require("./entitlement_util");

test("Google hesabına 7 günlük deneme, katman ücretsiz", () => {
  const now = new Date("2026-11-18T12:00:00Z");
  const doc = u.trialEntitlement({ isAnonymous: false }, now);
  assert.strictEqual(doc.tier, "free");
  assert.strictEqual(doc.trialEndsAt.getTime() - now.getTime(), 7 * u.DAY_MS);
});

test("misafire deneme yazılmaz", () => {
  assert.strictEqual(u.trialEntitlement({ isAnonymous: true }, new Date()), null);
  assert.strictEqual(u.isAnonymousUser({ providerData: [] }), true);
  assert.strictEqual(
    u.isAnonymousUser({ providerData: [{ providerId: "google.com" }] }),
    false,
  );
});
