/**
 * KURAL TESTİ KAPSAM ÖZETİ (F71.8). Testlerden sonra, emülatör kapanmadan koşar
 * (`npm test`): Firestore emülatörünün kapsam raporundan hangi `allow` koşulunun
 * testlerde HİÇ değerlendirilmediğini yazar. Bilgi amaçlı — işi düşürmez.
 * Storage emülatörü kapsam raporu vermiyor; yalnız firestore.rules.
 */
const { readFileSync, appendFileSync } = require("node:fs");
const path = require("node:path");

const host = process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";
const url = `http://${host}/emulator/v1/projects/demo-not:ruleCoverage`;

(async () => {
  const { report = [] } = await (await fetch(url)).json();
  const lines = readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8").split("\n");
  // Üst düzey girdi = bir `allow` koşulu; `values` yoksa hiç değerlendirilmedi.
  const allows = report.filter((r) => /^\s*allow\b/.test(lines[r.sourcePosition.line - 1] || ""));
  const cold = allows.filter((r) => !(r.values || []).length);
  const out = [
    `Kural kapsamı (firestore.rules): ${allows.length - cold.length}/${allows.length} allow koşulu testlerde değerlendirildi.`,
    ...cold.map((r) => `  değerlendirilmedi → satır ${r.sourcePosition.line}: ${lines[r.sourcePosition.line - 1].trim()}`),
  ].join("\n");
  console.log(out);
  if (process.env.GITHUB_STEP_SUMMARY) {
    appendFileSync(process.env.GITHUB_STEP_SUMMARY, "### Kural testi kapsamı\n```\n" + out + "\n```\n");
  }
})().catch((e) => console.log(`Kural kapsamı okunamadı: ${e.message}`));
