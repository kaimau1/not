/**
 * Ortak AI Havuzu (Shared AI Pool) saf yardımcıları: Notlar ve Dosyalarım aynı
 * Google hesabı (`uid`) altında paylaşılan kredi bakiyesini kullanır.
 *
 * Güvenlik ve maliyet kuralları:
 *  - Yeni hesapta [STARTER_CREDITS] yalnız BİR kez verilir (`starterGranted`).
 *  - Etkin Pro/deneme kullanıcıya ayda bir [PRO_MONTHLY_BONUS_CREDITS] yüklenir.
 *  - Model izin listesi ve girdi tavanları dışındaki istek reddedilir.
 *  - Bakiye < maliyetse yukarı akış API çağrısı ASLA yapılmaz (sunucuda pre-deduct).
 */

const STARTER_CREDITS = 500;
const PRO_MONTHLY_BONUS_CREDITS = 2000;

const ALLOWED_APPS = new Set(["notlar", "dosya_okuyucu"]);
const ALLOWED_MODELS = new Set([
  "gemini-2.5-flash-lite",
  "gemini-2.5-flash",
  "gemini-2.5-pro",
]);
const MODEL_COST = {
  "gemini-2.5-flash-lite": 1,
  "gemini-2.5-flash": 2,
  "gemini-2.5-pro": 8,
};

const MAX_PROMPT_CHARS = 32000;
const MAX_PARTS = 12;
const MAX_INLINE_BASE64_CHARS = 22 * 1024 * 1024;
const MAX_OUTPUT_TOKENS = 4096;
const RATE_LIMIT_PER_MINUTE = 25;
const RATE_WINDOW_MS = 60 * 1000;

/**
 * Akıllı liste AI görev profilleri: daima en ucuz model (`gemini-2.5-flash-lite`,
 * 1 kredi), sıkı girdi/çıktı tavanı ve günlük profil kotası.
 */
const LIST_TASK_PROFILES = {
  list_breakdown: {
    model: "gemini-2.5-flash-lite",
    maxPromptChars: 2500,
    maxOutputTokens: 350,
    dailyLimitFree: 5,
    dailyLimitPro: 25,
  },
  list_extract: {
    model: "gemini-2.5-flash-lite",
    maxPromptChars: 2500,
    maxOutputTokens: 350,
    dailyLimitFree: 5,
    dailyLimitPro: 25,
  },
};

function num(v) {
  return typeof v === "number" && Number.isFinite(v) && v >= 0
    ? Math.floor(v)
    : 0;
}

function toDate(v) {
  if (!v) return null;
  if (v instanceof Date) return v;
  if (typeof v.toDate === "function") return v.toDate();
  return null;
}

function dayKey(now) {
  const t = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  const y = t.getUTCFullYear();
  const m = String(t.getUTCMonth() + 1).padStart(2, "0");
  const d = String(t.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function monthKey(now) {
  const t = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  return `${t.getUTCFullYear()}-${String(t.getUTCMonth() + 1).padStart(2, "0")}`;
}

function proActive(ent, now) {
  if (!ent) return false;
  const until = toDate(ent.proUntil);
  const trial = toDate(ent.trialEndsAt);
  return (
    (ent.tier === "pro" && !!until && until > now) ||
    (!!trial && trial > now)
  );
}

function normalizeAppId(raw) {
  if (typeof raw !== "string") return null;
  const clean = raw.trim().toLowerCase();
  return ALLOWED_APPS.has(clean) ? clean : null;
}

function ensurePoolState(poolDoc, entDoc, now) {
  const d = poolDoc || {};
  let balance = num(d.balance);
  let starterGranted = d.starterGranted === true;
  if (!starterGranted) {
    balance += STARTER_CREDITS;
    starterGranted = true;
  }
  const month = monthKey(now);
  let lastProRefillMonth =
    typeof d.lastProRefillMonth === "string" ? d.lastProRefillMonth : null;
  if (proActive(entDoc, now) && lastProRefillMonth !== month) {
    balance += PRO_MONTHLY_BONUS_CREDITS;
    lastProRefillMonth = month;
  }
  return {
    balance,
    starterGranted,
    lastProRefillMonth,
    lifetimeSpent: num(d.lifetimeSpent),
    lastAppId: typeof d.lastAppId === "string" ? d.lastAppId : null,
  };
}

function sanitizeGenerateRequest(data) {
  if (!data || typeof data !== "object") return null;
  const appId = normalizeAppId(data.appId);
  if (!appId) return null;

  let taskProfile = null;
  let profileSpec = null;
  if (data.taskProfile !== undefined && data.taskProfile !== null) {
    if (typeof data.taskProfile !== "string") return null;
    const cleanedProfile = data.taskProfile.trim();
    if (!Object.prototype.hasOwnProperty.call(LIST_TASK_PROFILES, cleanedProfile)) {
      return null;
    }
    taskProfile = cleanedProfile;
    profileSpec = LIST_TASK_PROFILES[taskProfile];
  }

  const model = profileSpec
    ? profileSpec.model
    : typeof data.model === "string" && data.model.trim()
      ? data.model.trim()
      : "gemini-2.5-flash";
  if (!ALLOWED_MODELS.has(model)) return null;

  const promptLimit = profileSpec ? profileSpec.maxPromptChars : MAX_PROMPT_CHARS;
  const outputLimit = profileSpec ? profileSpec.maxOutputTokens : MAX_OUTPUT_TOKENS;

  let contents;
  if (typeof data.prompt === "string") {
    const prompt = data.prompt.trim();
    if (!prompt || prompt.length > promptLimit) return null;
    contents = [{ parts: [{ text: prompt }] }];
  } else if (Array.isArray(data.contents) && data.contents.length > 0 && data.contents.length <= 6) {
    let totalText = 0;
    let totalParts = 0;
    contents = [];
    for (const msg of data.contents) {
      if (!msg || typeof msg !== "object" || !Array.isArray(msg.parts)) return null;
      const parts = [];
      for (const p of msg.parts) {
        totalParts += 1;
        if (totalParts > MAX_PARTS || !p || typeof p !== "object") return null;
        if (typeof p.text === "string") {
          totalText += p.text.length;
          if (totalText > promptLimit) return null;
          parts.push({ text: p.text });
        } else if (p.inline_data && typeof p.inline_data === "object") {
          if (profileSpec) return null; // Liste metin profillerinde medya kabul edilmez.
          const mime = p.inline_data.mime_type;
          const b64 = p.inline_data.data;
          if (
            typeof mime !== "string" ||
            !mime.trim() ||
            mime.length > 100 ||
            typeof b64 !== "string" ||
            b64.length === 0 ||
            b64.length > MAX_INLINE_BASE64_CHARS
          ) {
            return null;
          }
          parts.push({
            inline_data: { mime_type: mime.trim(), data: b64 },
          });
        } else {
          return null;
        }
      }
      if (parts.length === 0) return null;
      const role = msg.role === "model" ? "model" : msg.role === "user" ? "user" : undefined;
      contents.push(role ? { role, parts } : { parts });
    }
  } else {
    return null;
  }

  const payload = { contents };
  const gc = {};
  if (data.generationConfig && typeof data.generationConfig === "object") {
    const cfg = data.generationConfig;
    if (typeof cfg.temperature === "number" && Number.isFinite(cfg.temperature)) {
      gc.temperature = Math.min(2, Math.max(0, cfg.temperature));
    }
    if (typeof cfg.maxOutputTokens === "number" && Number.isFinite(cfg.maxOutputTokens)) {
      gc.maxOutputTokens = Math.min(outputLimit, Math.max(1, Math.floor(cfg.maxOutputTokens)));
    }
    if (cfg.responseMimeType === "application/json" || cfg.responseMimeType === "text/plain") {
      gc.responseMimeType = cfg.responseMimeType;
    }
  }
  if (profileSpec && gc.maxOutputTokens === undefined) {
    gc.maxOutputTokens = outputLimit;
  }
  if (Object.keys(gc).length > 0) payload.generationConfig = gc;

  return taskProfile
    ? { appId, model, payload, taskProfile }
    : { appId, model, payload };
}

function costForRequest(sanitized) {
  const base = MODEL_COST[sanitized.model] || 2;
  let inlineBytesApprox = 0;
  for (const c of sanitized.payload.contents) {
    for (const p of c.parts) {
      if (p.inline_data && typeof p.inline_data.data === "string") {
        inlineBytesApprox += Math.floor((p.inline_data.data.length * 3) / 4);
      }
    }
  }
  const mediaExtra = inlineBytesApprox > 512 * 1024 ? 1 : 0;
  return base + mediaExtra;
}

function checkRateLimit(rateDoc, now) {
  const nowMs = now.getTime();
  const d = rateDoc || {};
  const start = typeof d.aiPoolWindowStart === "number" ? d.aiPoolWindowStart : 0;
  const count = typeof d.aiPoolCount === "number" ? d.aiPoolCount : 0;
  if (nowMs - start >= RATE_WINDOW_MS) {
    return {
      ok: true,
      rate: { aiPoolWindowStart: nowMs, aiPoolCount: 1 },
    };
  }
  if (count >= RATE_LIMIT_PER_MINUTE) {
    return {
      ok: false,
      retryAfterMs: Math.max(1000, RATE_WINDOW_MS - (nowMs - start)),
    };
  }
  return {
    ok: true,
    rate: { aiPoolWindowStart: start, aiPoolCount: count + 1 },
  };
}

function checkDailyProfileQuota(rateDoc, taskProfile, entDoc, now) {
  if (!taskProfile || !Object.prototype.hasOwnProperty.call(LIST_TASK_PROFILES, taskProfile)) {
    return { ok: true, daily: null };
  }
  const spec = LIST_TASK_PROFILES[taskProfile];
  const limit = proActive(entDoc, now) ? spec.dailyLimitPro : spec.dailyLimitFree;
  const today = dayKey(now);
  const d = rateDoc || {};
  const used = d.aiListDailyKey === today && typeof d.aiListDailyCount === "number"
    ? Math.max(0, Math.floor(d.aiListDailyCount))
    : 0;
  if (used >= limit) {
    return { ok: false, reason: "daily-quota-exceeded", limit, used };
  }
  return {
    ok: true,
    daily: { aiListDailyKey: today, aiListDailyCount: used + 1 },
    remaining: limit - (used + 1),
  };
}

function reserveCredits(poolDoc, entDoc, rateDoc, cost, appId, now, taskProfile = null) {
  const state = ensurePoolState(poolDoc, entDoc, now);
  const rateCheck = checkRateLimit(rateDoc, now);
  if (!rateCheck.ok) {
    return { ok: false, reason: "rate-limited", retryAfterMs: rateCheck.retryAfterMs, state };
  }
  const dailyCheck = checkDailyProfileQuota(rateDoc, taskProfile, entDoc, now);
  if (!dailyCheck.ok) {
    return { ok: false, reason: "daily-quota-exceeded", limit: dailyCheck.limit, state };
  }
  if (state.balance < cost) {
    return { ok: false, reason: "insufficient-credits", balance: state.balance, state };
  }
  const nextState = {
    ...state,
    balance: state.balance - cost,
    lifetimeSpent: state.lifetimeSpent + cost,
    lastAppId: appId,
  };
  return {
    ok: true,
    remainingCredits: nextState.balance,
    state: nextState,
    rate: dailyCheck.daily ? { ...rateCheck.rate, ...dailyCheck.daily } : rateCheck.rate,
  };
}

function refundCredits(poolDoc, cost) {
  const d = poolDoc || {};
  const spent = num(d.lifetimeSpent);
  return {
    balance: num(d.balance) + cost,
    starterGranted: d.starterGranted === true,
    lastProRefillMonth: d.lastProRefillMonth || null,
    lifetimeSpent: Math.max(0, spent - cost),
    lastAppId: d.lastAppId || null,
  };
}

module.exports = {
  STARTER_CREDITS,
  PRO_MONTHLY_BONUS_CREDITS,
  ALLOWED_APPS,
  ALLOWED_MODELS,
  LIST_TASK_PROFILES,
  MAX_PROMPT_CHARS,
  MAX_OUTPUT_TOKENS,
  RATE_LIMIT_PER_MINUTE,
  dayKey,
  normalizeAppId,
  ensurePoolState,
  sanitizeGenerateRequest,
  costForRequest,
  checkRateLimit,
  checkDailyProfileQuota,
  reserveCredits,
  refundCredits,
};
