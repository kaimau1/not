const test = require("node:test");
const assert = require("node:assert");
const u = require("./decisions_util");

const now = new Date("2026-11-22T12:00:00Z");
const later = new Date("2027-01-01T00:00:00Z");
const pro = { tier: "pro", proUntil: later };
const lifetime = { tier: "free", lifetimeOwned: true };

test("ücretsiz: hak yok", () => {
  assert.strictEqual(u.reserve(null, null, now).ok, false);
  assert.strictEqual(u.reserve({ tier: "free" }, {}, now).ok, false);
  // Süresi bitmiş Pro da ücretsizdir.
  const lapsed = { tier: "pro", proUntil: new Date("2026-01-01T00:00:00Z") };
  assert.strictEqual(u.reserve(lapsed, {}, now).ok, false);
});

test("Pro: ayda 500, ay başında yenilenir", () => {
  let usage = {};
  for (let i = 0; i < u.PRO_MONTHLY; i++) {
    const r = u.reserve(pro, usage, now);
    assert.ok(r.ok);
    assert.strictEqual(r.bucket, "monthly");
    usage = r.usage;
  }
  assert.strictEqual(u.reserve(pro, usage, now).ok, false);
  const dec = new Date("2026-12-01T00:00:00Z"); // TR 03:00, yeni ay
  assert.ok(u.reserve(pro, usage, dec).ok);
});

test("ay sınırı Türkiye saatiyle", () => {
  assert.strictEqual(u.monthKey(new Date("2026-11-30T20:59:00Z")), "2026-11");
  assert.strictEqual(u.monthKey(new Date("2026-11-30T21:00:00Z")), "2026-12");
});

test("deneme süresi Pro sayılır", () => {
  const trial = { tier: "free", trialEndsAt: later };
  assert.strictEqual(u.reserve(trial, {}, now).bucket, "monthly");
});

test("ömür boyu: bir kerelik 750, ayla yenilenmez", () => {
  assert.strictEqual(u.LIFETIME_ONCE, 750);
  const usage = { month: "2026-10", onceUsed: u.LIFETIME_ONCE - 1 };
  const r = u.reserve(lifetime, usage, now);
  assert.ok(r.ok);
  assert.strictEqual(r.bucket, "once");
  assert.strictEqual(u.reserve(lifetime, r.usage, now).ok, false);
  assert.strictEqual(u.reserve(lifetime, r.usage, later).ok, false);
});

test("çift kilit: 600K girdi jetonu dolunca çağrı hakkı kalsa da engellenir", () => {
  let usage = { onceUsed: 120, onceTokensUsed: u.LIFETIME_MAX_INPUT_TOKENS - 500 };
  const r1 = u.reserve(lifetime, usage, now);
  assert.ok(r1.ok);
  assert.strictEqual(r1.bucket, "once");
  usage = u.addTokens(r1.usage, "once", 500, now);
  assert.strictEqual(usage.onceTokensUsed, u.LIFETIME_MAX_INPUT_TOKENS);
  assert.strictEqual(u.remaining(lifetime, usage, now).once, 0);
  assert.strictEqual(u.reserve(lifetime, usage, now).ok, false);
});

test("Pro aylık jeton tavanı ay başında sıfırlanır", () => {
  const maxed = {
    month: "2026-11",
    monthUsed: 10,
    monthTokensUsed: u.PRO_MONTHLY_MAX_INPUT_TOKENS,
  };
  assert.strictEqual(u.reserve(pro, maxed, now).ok, false);
  const dec = new Date("2026-12-01T00:00:00Z");
  assert.ok(u.reserve(pro, maxed, dec).ok);
});

test("lifetimeTokenKey belge kimliği ve sayaç birleştirme (hesap silmede sıfırlanmaz)", () => {
  assert.strictEqual(u.lifetimeUsageDocId({ lifetimeOwned: true }), null);
  assert.strictEqual(
    u.lifetimeUsageDocId({ lifetimeOwned: true, lifetimeTokenKey: "abc123" }),
    "lt_abc123",
  );
  const merged = u.mergeLifetimeUsage(
    { month: "2026-11", monthUsed: 2, onceUsed: 0, onceTokensUsed: 0 },
    { onceUsed: 750, onceTokensUsed: 420000 },
    now,
  );
  assert.strictEqual(merged.monthUsed, 2);
  assert.strictEqual(merged.onceUsed, 750);
  assert.strictEqual(merged.onceTokensUsed, 420000);
  assert.strictEqual(u.reserve(lifetime, merged, now).ok, false);
});

test("sunucu aiKillSwitch: yalnız tam true kapatır", () => {
  assert.strictEqual(u.isKillSwitchEnabled(null), false);
  assert.strictEqual(u.isKillSwitchEnabled({}), false);
  assert.strictEqual(u.isKillSwitchEnabled({ aiKillSwitch: "true" }), false);
  assert.strictEqual(u.isKillSwitchEnabled({ aiKillSwitch: false }), false);
  assert.strictEqual(u.isKillSwitchEnabled({ aiKillSwitch: true }), true);
});

test("extractInputTokens: gerçek usage.total_input_tokens veya güvenli tahmin", () => {
  assert.strictEqual(
    u.extractInputTokens({ usage: { total_input_tokens: 412, total_output_tokens: 0 } }, 900),
    412,
  );
  assert.strictEqual(
    u.extractInputTokens({ usageMetadata: { promptTokenCount: 250 } }, 900),
    250,
  );
  assert.strictEqual(u.extractInputTokens({}, 900), 300);
});

test("sıra: Pro aylık → bir kerelik → paket; iade", () => {
  const both = { tier: "pro", proUntil: later, lifetimeOwned: true, decisionCredits: 2 };
  let usage = { month: "2026-11", monthUsed: u.PRO_MONTHLY, onceUsed: u.LIFETIME_ONCE };
  const r = u.reserve(both, usage, now);
  assert.strictEqual(r.bucket, "pack");
  assert.strictEqual(r.usage.packUsed, 1);
  usage = u.refund(r.usage, r.bucket, now);
  assert.strictEqual(usage.packUsed, 0);
  assert.deepStrictEqual(u.remaining(both, usage, now), { monthly: 0, once: 0, pack: 2 });
});

test("Firestore Timestamp kabul edilir", () => {
  const ts = { tier: "pro", proUntil: { toDate: () => later } };
  assert.ok(u.proActive(ts, now));
});

test("istek süzme: yalnız izinli model/alanlar, 8000 toplam JSON tavanı", () => {
  const ok = {
    model: "gemini-decision-1",
    input: [{ type: "text", text: "süt al" }],
    questions: { a_yok: { type: "noul", instructions: "Uygun mu?", extra: 1 } },
    tools: ["x"],
  };
  const clean = u.sanitizeRequest(ok);
  assert.deepStrictEqual(clean, {
    model: "gemini-decision-1",
    input: [{ type: "text", text: "süt al" }],
    questions: { a_yok: { type: "noul", instructions: "Uygun mu?" } },
  });
  assert.strictEqual(u.sanitizeRequest({ ...ok, model: "gemini-3.5-pro" }), null);
  assert.strictEqual(
    u.sanitizeRequest({ ...ok, input: [{ type: "text", text: "x".repeat(u.MAX_INPUT_CHARS + 1) }] }),
    null,
  );
  assert.strictEqual(
    u.sanitizeRequest({ ...ok, input: [{ type: "image", text: "x" }] }),
    null,
  );
  // P0-1: Tek tek 4000 altı soruların toplamı 8000 karakteri aşarsa reddedilir.
  const bloated = {};
  for (let i = 0; i < 4; i++) {
    bloated[`q${i}`] = { type: "noul", instructions: "a".repeat(2500) };
  }
  assert.strictEqual(u.sanitizeRequest({ ...ok, questions: bloated }), null);
  const many = {};
  for (let i = 0; i <= u.MAX_QUESTIONS; i++) many[`q${i}`] = { type: "noul", instructions: "?" };
  assert.strictEqual(u.sanitizeRequest({ ...ok, questions: many }), null);
  assert.strictEqual(
    u.sanitizeRequest({ ...ok, questions: { "Bad-Key": { type: "noul", instructions: "?" } } }),
    null,
  );
});
