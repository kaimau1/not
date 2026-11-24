const test = require("node:test");
const assert = require("node:assert");
const u = require("./ai_pool_util");

const now = new Date("2026-11-24T12:00:00Z");

test("başlangıç kredisi yalnız bir kez verilir, sıfırlanınca yinelenmez", () => {
  const first = u.ensurePoolState(null, null, now);
  assert.strictEqual(first.balance, u.STARTER_CREDITS);
  assert.strictEqual(first.starterGranted, true);

  const depleted = u.ensurePoolState(
    { balance: 0, starterGranted: true, lifetimeSpent: 500 },
    null,
    now,
  );
  assert.strictEqual(depleted.balance, 0);
  assert.strictEqual(depleted.starterGranted, true);
});

test("Pro kullanıcı ayda bir ek havuz kredisi alır", () => {
  const pro = { tier: "pro", proUntil: new Date("2027-01-01T00:00:00Z") };
  const s1 = u.ensurePoolState({ balance: 100, starterGranted: true }, pro, now);
  assert.strictEqual(s1.balance, 100 + u.PRO_MONTHLY_BONUS_CREDITS);

  // Aynı ay içinde ikinci çağrı yeniden eklemez.
  const s2 = u.ensurePoolState(s1, pro, now);
  assert.strictEqual(s2.balance, s1.balance);
});

test("isteği süzer: uygulama, model ve boyut tavanları", () => {
  const ok = u.sanitizeGenerateRequest({
    appId: "dosya_okuyucu",
    model: "gemini-2.5-flash",
    prompt: "Özetle",
  });
  assert.ok(ok);
  assert.strictEqual(ok.appId, "dosya_okuyucu");
  assert.strictEqual(ok.model, "gemini-2.5-flash");

  assert.strictEqual(
    u.sanitizeGenerateRequest({ appId: "baska", prompt: "x" }),
    null,
  );
  assert.strictEqual(
    u.sanitizeGenerateRequest({
      appId: "notlar",
      model: "gemini-3-ultra-secret",
      prompt: "x",
    }),
    null,
  );
  assert.strictEqual(
    u.sanitizeGenerateRequest({
      appId: "notlar",
      prompt: "a".repeat(u.MAX_PROMPT_CHARS + 1),
    }),
    null,
  );
});

test("0 bakiye engellenir, harcama sonrası iade çalışır", () => {
  const emptyPool = { balance: 1, starterGranted: true, lifetimeSpent: 499 };
  const fail = u.reserveCredits(emptyPool, null, null, 2, "notlar", now);
  assert.strictEqual(fail.ok, false);
  assert.strictEqual(fail.reason, "insufficient-credits");

  const ok = u.reserveCredits(
    { balance: 10, starterGranted: true, lifetimeSpent: 10 },
    null,
    null,
    2,
    "dosya_okuyucu",
    now,
  );
  assert.strictEqual(ok.ok, true);
  assert.strictEqual(ok.remainingCredits, 8);
  assert.strictEqual(ok.state.lastAppId, "dosya_okuyucu");

  const refunded = u.refundCredits(ok.state, 2);
  assert.strictEqual(refunded.balance, 10);
  assert.strictEqual(refunded.lifetimeSpent, 10);
});

test("hız sınırı dakikadaki tavanı aşanı durdurur", () => {
  let rate = null;
  const pool = { balance: 1000, starterGranted: true };
  for (let i = 0; i < u.RATE_LIMIT_PER_MINUTE; i++) {
    const r = u.reserveCredits(pool, null, rate, 1, "notlar", now);
    assert.strictEqual(r.ok, true);
    rate = r.rate;
  }
  const blocked = u.reserveCredits(pool, null, rate, 1, "notlar", now);
  assert.strictEqual(blocked.ok, false);
  assert.strictEqual(blocked.reason, "rate-limited");
});
