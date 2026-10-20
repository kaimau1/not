const test = require("node:test");
const assert = require("node:assert");
const _test = require("./push_util");

test("yalnız YENİ eklenen üyeler bildirilir", () => {
  assert.deepStrictEqual(_test.addedMembers(["a"], ["a", "b", "c"]), ["b", "c"]);
  assert.deepStrictEqual(_test.addedMembers(undefined, ["a"]), ["a"]);
  assert.deepStrictEqual(_test.addedMembers(["a", "b"], ["a"]), []);
});

test("bildirim metni kısaltılır, boşluk sadeleşir", () => {
  assert.strictEqual(_test.clip("  a \n b  "), "a b");
  assert.strictEqual(_test.clip("x".repeat(200), 10).length, 10);
});
