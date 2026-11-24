/**
 * KARAR (Decisions) KOTASI yardımcıları — PLAN U8 KARAR (kullanıcı,
 * 2026-11-22). Saf: Firebase'e / ağa bağlı değil, `node --test` ile sınanır.
 * Ağ ve Firestore `decisions.js`'te.
 *
 * Haklar (yalnız dahili anahtar, yani kullanıcının KENDİ Gemini anahtarı
 * yokken; kendi anahtarı olan istemci sunucuya hiç gelmez):
 *  - ücretsiz: yok;
 *  - Pro abonelik (deneme dahil): takvim ayı başına [PRO_MONTHLY] çağrı ve
 *    [PRO_MONTHLY_MAX_INPUT_TOKENS] girdi jetonu;
 *  - ömür boyu (50 TL tek seferlik): BİR KERELİK toplam [LIFETIME_ONCE] (750)
 *    çağrı VE [LIFETIME_MAX_INPUT_TOKENS] (600.000) girdi jetonu çift kilidi
 *    (en fazla 0,06 $ maliyet tavanı), yenilenmez;
 *  - karar paketi: `entitlements/{uid}.decisionCredits` (sunucunun yazdığı
 *    satın alınmış toplam; jeton tavanı `decisionTokenCredits` ya da kredi ×
 *    [PACK_TOKENS_PER_CALL]).
 * Harcama sırası: Pro aylık → ömür boyu bir kerelik → paket.
 *
 * Sayaç:
 *  - `decisionUsage/{uid}` = aylık + paket sayacı;
 *  - `decisionUsage/lt_{lifetimeTokenKey}` = ömür boyu sayaç (satın alma
 *    belirteci özetine bağlı — hesap silip geri yükleyerek sıfırlanamaz).
 * Yalnız Admin SDK yazar/okur (firestore.rules'da eşleşme yok = istemciye
 * kapalı).
 */

const PRO_MONTHLY = 500;
const PRO_MONTHLY_MAX_INPUT_TOKENS = 400000;
const LIFETIME_ONCE = 750;
const LIFETIME_MAX_INPUT_TOKENS = 600000;
const PACK_TOKENS_PER_CALL = 800;

/** Maliyet tavanları: bir çağrının girdi, soru ve TOPLAM JSON boyu. */
const MAX_INPUT_CHARS = 8000;
const MAX_TOTAL_PAYLOAD_CHARS = 8000;
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

/** `config/app.aiKillSwitch`: yalnız tam `true` sunucu çağrısını durdurur. */
function isKillSwitchEnabled(configData) {
  return !!configData && configData.aiKillSwitch === true;
}

/**
 * Ömür boyu kullanım sayacının belge kimliği: satın alma belirteci özetine
 * (`lifetimeTokenKey`) bağlıysa hesap silmeyle sıfırlanamaz.
 */
function lifetimeUsageDocId(ent) {
  const key = ent && typeof ent.lifetimeTokenKey === "string"
    ? ent.lifetimeTokenKey.trim()
    : "";
  return key ? `lt_${key}` : null;
}

/** Ay değiştiyse aylık çağrı + jeton sayaçları sıfır; diğerleri kalıcı. */
function normalizeUsage(usage, now) {
  const month = monthKey(now);
  const u = usage || {};
  const sameMonth = u.month === month;
  return {
    month,
    monthUsed: sameMonth ? num(u.monthUsed) : 0,
    monthTokensUsed: sameMonth ? num(u.monthTokensUsed) : 0,
    onceUsed: num(u.onceUsed),
    onceTokensUsed: num(u.onceTokensUsed),
    packUsed: num(u.packUsed),
    packTokensUsed: num(u.packTokensUsed),
  };
}

/**
 * Kullanıcı (`uid`) ve belirteç (`lt_<lifetimeTokenKey>`) sayaçlarını birleştirir.
 * Ömür boyu sayacı iki belgeden büyük olanı esas alır (eski kayıtlar da korunur).
 */
function mergeLifetimeUsage(userUsage, lifetimeUsage, now) {
  const u = normalizeUsage(userUsage, now);
  if (!lifetimeUsage) return u;
  const lt = normalizeUsage(lifetimeUsage, now);
  return {
    ...u,
    onceUsed: Math.max(u.onceUsed, lt.onceUsed),
    onceTokensUsed: Math.max(u.onceTokensUsed, lt.onceTokensUsed),
  };
}

function packTokenBudget(ent) {
  if (!ent) return 0;
  const explicit = num(ent.decisionTokenCredits);
  if (explicit > 0) return explicit;
  return num(ent.decisionCredits) * PACK_TOKENS_PER_CALL;
}

/** Kova başına kalan girdi jetonu tavanları (çift kilit). */
function remainingTokens(ent, usage, now) {
  const u = normalizeUsage(usage, now);
  return {
    monthly: proActive(ent, now)
      ? Math.max(0, PRO_MONTHLY_MAX_INPUT_TOKENS - u.monthTokensUsed)
      : 0,
    once: lifetimeOwned(ent)
      ? Math.max(0, LIFETIME_MAX_INPUT_TOKENS - u.onceTokensUsed)
      : 0,
    pack: Math.max(0, packTokenBudget(ent) - u.packTokensUsed),
  };
}

/**
 * Kalan haklar (istemciye bilgi; karar sunucuda).
 * Çift kilit: kovanın girdi jeton tavanı dolduysa çağrı hakkı da 0 döner.
 */
function remaining(ent, usage, now) {
  const u = normalizeUsage(usage, now);
  const tok = remainingTokens(ent, u, now);
  return {
    monthly: proActive(ent, now) && tok.monthly > 0
      ? Math.max(0, PRO_MONTHLY - u.monthUsed)
      : 0,
    once: lifetimeOwned(ent) && tok.once > 0
      ? Math.max(0, LIFETIME_ONCE - u.onceUsed)
      : 0,
    pack: tok.pack > 0
      ? Math.max(0, num(ent && ent.decisionCredits) - u.packUsed)
      : 0,
  };
}

/**
 * Bir karar hakkı ayırır. `{ok: true, bucket, usage}` (yazılacak yeni sayaç)
 * ya da `{ok: false}` (hak veya jeton tavanı doldu).
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

/** Başarılı yanıttan sonra harcanan gerçek girdi jetonunu ekler. */
function addTokens(usage, bucket, inputTokens, now) {
  const u = normalizeUsage(usage, now);
  const add = num(inputTokens);
  const field = {
    monthly: "monthTokensUsed",
    once: "onceTokensUsed",
    pack: "packTokensUsed",
  }[bucket];
  if (field && add > 0) u[field] += add;
  return u;
}

/**
 * Google Decisions API yanıtındaki gerçek girdi jetonu sayısını okur
 * (`usage.total_input_tokens`). Yanıtta yoksa gövde uzunluğundan güvenli üst
 * tahmin (`ceil(chars / 3)`) üretir ki eksik alan tavanı delemesin.
 */
function extractInputTokens(apiResponse, fallbackPayloadChars) {
  const u = apiResponse && typeof apiResponse === "object" ? apiResponse.usage : null;
  const direct = num(u && u.total_input_tokens);
  if (direct > 0) return direct;
  const meta = apiResponse && typeof apiResponse === "object"
    ? apiResponse.usageMetadata
    : null;
  const prompt = num(meta && meta.promptTokenCount);
  if (prompt > 0) return prompt;
  const chars = num(fallbackPayloadChars);
  return chars > 0 ? Math.max(1, Math.ceil(chars / 3)) : 1;
}

/**
 * İstemci gövdesini doğrular ve YALNIZ izinli alanlarla yeniden kurar
 * (vekil, bizim anahtarla keyfi ya da aşırı büyük istek atmak için
 * kullanılamasın). Toplam JSON gövdesi [MAX_TOTAL_PAYLOAD_CHARS]'ı aşamaz.
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
  const cleanReq = { model, input: [{ type: "text", text }], questions };
  if (JSON.stringify(cleanReq).length > MAX_TOTAL_PAYLOAD_CHARS) return null;
  return cleanReq;
}

module.exports = {
  PRO_MONTHLY,
  PRO_MONTHLY_MAX_INPUT_TOKENS,
  LIFETIME_ONCE,
  LIFETIME_MAX_INPUT_TOKENS,
  PACK_TOKENS_PER_CALL,
  MAX_INPUT_CHARS,
  MAX_TOTAL_PAYLOAD_CHARS,
  MAX_QUESTIONS,
  monthKey,
  proActive,
  lifetimeOwned,
  isKillSwitchEnabled,
  lifetimeUsageDocId,
  normalizeUsage,
  mergeLifetimeUsage,
  remainingTokens,
  remaining,
  reserve,
  refund,
  addTokens,
  extractInputTokens,
  sanitizeRequest,
};
