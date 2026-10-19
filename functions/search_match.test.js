const test = require("node:test");
const assert = require("node:assert");
const { matchKind } = require("./search_match");

test("e-posta yalnız tam eşleşir", () => {
  assert.strictEqual(matchKind("ali@x.com", "ali veli", "ali@x.com"), "prefix");
  assert.strictEqual(matchKind("ali@x", "ali veli", "ali@x.com"), null);
  assert.strictEqual(matchKind("@x.com", "ali veli", "ali@x.com"), null);
});

test("ad en az 3 harf ister, e-postada parça araması yok", () => {
  assert.strictEqual(matchKind("al", "ali veli", "ali@x.com"), null);
  assert.strictEqual(matchKind("ali", "ali veli", "ali@x.com"), "prefix");
  assert.strictEqual(matchKind("x.com", "ali veli", "ali@x.com"), null);
});

test("adın kelime öneki eşleşir, kelime ortası eşleşmez", () => {
  assert.strictEqual(matchKind("mehmet", "ali mehmet", "a@b.c"), "inside");
  assert.strictEqual(matchKind("ehm", "ali mehmet", "a@b.c"), null);
});
