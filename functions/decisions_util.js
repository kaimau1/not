/**
 * KARAR (Decisions) KOTASI yardımcıları — PLAN U8 KARAR (kullanıcı,
 * 2026-11-22). Saf: Firebase'e / ağa bağlı değil, `node --test` ile sınanır.
 * Ağ ve Firestore `decisions.js`'te.
 *
 * Haklar (yalnız dahili anahtar, yani kullanıcının KENDİ Gemini anahtarı
 * yokken; kendi anahtarı olan istemci sunucuya hiç gelmez):
 *  - ücretsiz: yok;
 *  - Pro abonelik (deneme dahil): takvim ayı başına [PRO_MONTHLY];
 *  - ömür boyu (tek seferlik): BİR KERELİK toplam [LIFETIME_ONCE], yenilenmez;
 *  - karar paketi: `entitlements/{uid}.decisionCredits` (sunucunun yazdığı
 *    satın alınmış toplam; satın alma akışı henüz YOK, alan yoksa 0).
 * Harcama sırası: Pro aylık → ömür boyu bir kerelik → paket.
 *
 * Sayaç `decisionUsage/{uid}` = {month, monthUsed, onceUsed, packUsed};
 * yalnız Admin SDK yazar/okur (firestore.rules'da eşleşme yok = istemciye
 * kapalı; silip sıfırlayamaz).
 */

const PRO_MONTHLY = 500;
const LIFETIME_ONCE = 1000;

/** Maliyet tavanları: bir çağrının girdi boyu ve soru sayısı. */
const MAX_INPUT_CHARS = 8000;
const MAX_QUESTIONS = 60;
const ALLOWED_MODELS = new Set(["gemini-decision-1"]);
const QUESTION_KEY = /^[a-z][a-z0-9_]{0,62}$/;
const QUESTION_TYPES = new Set(["noul", "choice", "score"]);
const MAX_QUESTION_JSON = 4000;

/** Firestore Timestamp / Date / yok → Date|null. */
function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v.toDate === "function") return v.toDate();
  return null;
}

/** Türkiye saatiyle (UTC+3, yaz saati yok) "YYYY-MM": ay başında yenilenir. */
function monthKey(now) {
  const t = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  return `${t.getUTCFullYear()}-${String(t.getUTCMonth() + 1).padStart(2, "0")}`;
}

function proActive(ent, now) {
  if (!ent) return false;
  const until = toDate(ent.proUntil);
  const trial = toDate(ent.trialEndsAt);
  return (ent.tier === "pro" && !!until && until > now) || (!!trial && trial > now);
}

function lifetimeOwned(ent) {
  return !!ent && (ent.tier === "lifetime" || ent.lifetimeOwned === true);
}

function num(v) {
  return typeof v === "number" && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0;
}

/** Ay değiştiyse aylık sayaç sıfır; diğerleri kalıcı. */
function normalizeUsage(usage, now) {
  const month = monthKey(now);
  const u = usage || {};
  return {
    month,
    monthUsed: u.month === month ? num(u.monthUsed) : 0,
    onceUsed: num(u.onceUsed),
    packUsed: num(u.packUsed),
  };
}

/** Kalan haklar (istemciye bilgi; karar sunucuda). */
function remaining(ent, usage, now) {
  const u = normalizeUsage(usage, now);
  return {
    monthly: proActive(ent, now) ? Math.max(0, PRO_MONTHLY - u.monthUsed) : 0,
    once: lifetimeOwned(ent) ? Math.max(0, LIFETIME_ONCE - u.onceUsed) : 0,
    pack: Math.max(0, num(ent && ent.decisionCredits) - u.packUsed),
  };
}

/**
 * Bir karar hakkı ayırır. `{ok: true, bucket, usage}` (yazılacak yeni sayaç)
 * ya da `{ok: false}` (hak yok).
 */
function reserve(ent, usage, now) {
  const u = normalizeUsage(usage, now);
  const left = remaining(ent, u, now);
  for (const [bucket, field] of [
    ["monthly", "monthUsed"],
    ["once", "onceUsed"],
    ["pack", "packUsed"],
  ]) {
    if (left[bucket] > 0) {
      return { ok: true, bucket, usage: { ...u, [field]: u[field] + 1 } };
    }
  }
  return { ok: false, usage: u };
}

/** Yukarı akış hatasında ayrılan hakkı geri verir. */
function refund(usage, bucket, now) {
  const u = normalizeUsage(usage, now);
  const field = { monthly: "monthUsed", once: "onceUsed", pack: "packUsed" }[bucket];
  if (field && u[field] > 0) u[field] -= 1;
  return u;
}

/**
 * İstemci gövdesini doğrular ve YALNIZ izinli alanlarla yeniden kurar
 * (vekil, bizim anahtarla keyfi istek atmak için kullanılamasın).
 * Geçersizse null.
 */
function sanitizeRequest(data) {
  if (!data || typeof data !== "object") return null;
  const model = data.model;
  if (!ALLOWED_MODELS.has(model)) return null;
  const input = Array.isArray(data.input) ? data.input : null;
  if (!input || input.length !== 1) return null;
  const part = input[0];
  if (!part || part.type !== "text" || typeof part.text !== "string") return null;
  const text = part.text;
  if (!text.trim() || text.length > MAX_INPUT_CHARS) return null;
  const qs = data.questions;
  if (!qs || typeof qs !== "object" || Array.isArray(qs)) return null;
  const keys = Object.keys(qs);
  if (!keys.length || keys.length > MAX_QUESTIONS) return null;
  const questions = {};
  for (const k of keys) {
    const q = qs[k];
    if (!QUESTION_KEY.test(k) || !q || !QUESTION_TYPES.has(q.type)) return null;
    if (typeof q.instructions !== "string" || !q.instructions.trim()) return null;
    if (JSON.stringify(q).length > MAX_QUESTION_JSON) return null;
    const clean = { type: q.type, instructions: q.instructions };
    if (q.criteria !== undefined) clean.criteria = q.criteria;
    questions[k] = clean;
  }
  return { model, input: [{ type: "text", text }], questions };
}

module.exports = {
  PRO_MONTHLY,
  LIFETIME_ONCE,
  MAX_INPUT_CHARS,
  MAX_QUESTIONS,
  monthKey,
  proActive,
  lifetimeOwned,
  normalizeUsage,
  remaining,
  reserve,
  refund,
  sanitizeRequest,
};
