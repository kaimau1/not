/**
 * DECISIONS API VEKİLİ (`POST /v1/decide`, PLAN §4.2, §5.4, Faz 0+1+2).
 *
 * `functions/decisions_util.js` ile birebir sözleşme:
 *  - `AI_KILL_SWITCH === "true"` → anında 503.
 *  - `ENFORCE_APP_CHECK === "true"` → `X-Firebase-AppCheck` zorunlu.
 *  - Toplam JSON payload ≤ 8.000 karakter, `model === "gemini-decision-1"`,
 *    `questions` 1..60 ve geçerli türler (`noul` / `choice` / `score`).
 *  - Çift kilitli bütçe:
 *      * 50 TL Ömür Boyu (`lifetime`): 750 çağrı VE 600.000 girdi jetonu
 *        (`decision_usage.token_hash = lifetime_token_hash` — hesap silinip
 *        yeniden açılsa bile sayaç sıfırlanmaz!).
 *      * +1.000 Ek Karar Paketi (`decision_pack_1000`): `extra_decisions`
 *        çağrı VE `extra_tokens` (varsayılan 800 jeton/çağrı) girdi jetonu.
 *  - Yanıt biçimi: `{ response, remaining: { monthly, once, pack },
 *    remainingTokens: { monthly, once, pack } }`.
 */

import {
  type AuthUser,
  type Env,
  errorResponse,
  jsonResponse,
  nowMs,
} from "./types.ts";

export const LIFETIME_ONCE_CALLS = 750;
export const LIFETIME_MAX_INPUT_TOKENS = 600_000;
export const PACK_TOKENS_PER_CALL = 800;
export const MAX_INPUT_CHARS = 8_000;
export const MAX_TOTAL_PAYLOAD_CHARS = 8_000;
export const MAX_QUESTIONS = 60;
export const MAX_QUESTION_JSON = 4_000;

const ALLOWED_MODELS = new Set(["gemini-decision-1"]);
const QUESTION_KEY_RE = /^[a-z][a-z0-9_]{0,62}$/;
const QUESTION_TYPES = new Set(["noul", "choice", "score"]);

const DECISIONS_ENDPOINT =
  "https://generativelanguage.googleapis.com/v1beta/decisions";

interface EntitlementRow {
  uid: string;
  lifetime_owned: number;
  lifetime_token_hash: string | null;
  extra_decisions: number;
  extra_tokens: number;
}

interface UsageRow {
  token_hash: string;
  calls_used: number;
  tokens_used: number;
  pack_calls_used: number;
  pack_tokens_used: number;
}

export function validateDecisionPayload(
  raw: unknown,
): { ok: true; body: Record<string, unknown> } | { ok: false; reason: string } {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
    return { ok: false, reason: "body_not_object" };
  }
  const body = raw as Record<string, unknown>;
  if (typeof body.model !== "string" || !ALLOWED_MODELS.has(body.model)) {
    return { ok: false, reason: "unsupported_model" };
  }
  if (
    typeof body.input !== "string" ||
    !body.input.trim() ||
    body.input.length > MAX_INPUT_CHARS
  ) {
    return { ok: false, reason: "invalid_input" };
  }
  const questions = body.questions;
  if (
    !questions ||
    typeof questions !== "object" ||
    Array.isArray(questions)
  ) {
    return { ok: false, reason: "invalid_questions" };
  }
  const entries = Object.entries(questions as Record<string, unknown>);
  if (entries.length === 0 || entries.length > MAX_QUESTIONS) {
    return { ok: false, reason: "question_count_out_of_range" };
  }
  const cleanQuestions: Record<string, unknown> = {};
  for (const [k, q] of entries) {
    if (!QUESTION_KEY_RE.test(k)) {
      return { ok: false, reason: "invalid_question_key" };
    }
    if (!q || typeof q !== "object" || Array.isArray(q)) {
      return { ok: false, reason: "invalid_question" };
    }
    const qObj = q as Record<string, unknown>;
    if (typeof qObj.type !== "string" || !QUESTION_TYPES.has(qObj.type)) {
      return { ok: false, reason: "invalid_question_type" };
    }
    if (JSON.stringify(qObj).length > MAX_QUESTION_JSON) {
      return { ok: false, reason: "question_too_large" };
    }
    cleanQuestions[k] = qObj;
  }

  const sanitized: Record<string, unknown> = {
    model: body.model,
    input: body.input,
    questions: cleanQuestions,
  };
  if (typeof body.system_instruction === "string" && body.system_instruction.length <= 2000) {
    sanitized.system_instruction = body.system_instruction;
  }

  if (JSON.stringify(sanitized).length > MAX_TOTAL_PAYLOAD_CHARS) {
    return { ok: false, reason: "payload_too_large" };
  }
  return { ok: true, body: sanitized };
}

export function extractInputTokens(res: unknown): number {
  if (!res || typeof res !== "object") return 0;
  const usage = (res as Record<string, unknown>).usage;
  if (!usage || typeof usage !== "object") return 0;
  const u = usage as Record<string, unknown>;
  const v =
    u.total_input_tokens ??
    u.totalInputTokens ??
    u.input_tokens ??
    u.promptTokenCount;
  return typeof v === "number" && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0;
}

export function computeQuotaView(
  ent: EntitlementRow | null,
  lifetimeUsage: UsageRow | null,
  packUsage: UsageRow | null,
) {
  const hasLifetime = !!ent && ent.lifetime_owned === 1;
  const onceCallsUsed = Math.max(0, Number(lifetimeUsage?.calls_used ?? 0));
  const onceTokensUsed = Math.max(0, Number(lifetimeUsage?.tokens_used ?? 0));

  const extraCalls = Math.max(0, Number(ent?.extra_decisions ?? 0));
  const extraTokensBudget =
    Number(ent?.extra_tokens ?? 0) > 0
      ? Number(ent?.extra_tokens ?? 0)
      : extraCalls * PACK_TOKENS_PER_CALL;
  const packCallsUsed = Math.max(0, Number(packUsage?.pack_calls_used ?? 0));
  const packTokensUsed = Math.max(0, Number(packUsage?.pack_tokens_used ?? 0));

  const onceTokensLeft = hasLifetime
    ? Math.max(0, LIFETIME_MAX_INPUT_TOKENS - onceTokensUsed)
    : 0;
  const onceCallsLeft =
    hasLifetime && onceTokensLeft > 0
      ? Math.max(0, LIFETIME_ONCE_CALLS - onceCallsUsed)
      : 0;

  const packTokensLeft = Math.max(0, extraTokensBudget - packTokensUsed);
  const packCallsLeft =
    packTokensLeft > 0 ? Math.max(0, extraCalls - packCallsUsed) : 0;

  return {
    remaining: { monthly: 0, once: onceCallsLeft, pack: packCallsLeft },
    remainingTokens: {
      monthly: 0,
      once: onceTokensLeft,
      pack: packTokensLeft,
    },
  };
}

async function getUsageRow(env: Env, key: string): Promise<UsageRow | null> {
  return env.DB.prepare(
    `SELECT token_hash, calls_used, tokens_used, pack_calls_used, pack_tokens_used
     FROM decision_usage WHERE token_hash = ?`,
  )
    .bind(key)
    .first<UsageRow>();
}

export async function handleDecide(
  request: Request,
  env: Env,
  user: AuthUser,
): Promise<Response> {
  if ((env.AI_KILL_SWITCH ?? "").toLowerCase() === "true") {
    return errorResponse(
      "ai_kill_switch",
      "Akıllı karar servisi geçici olarak durduruldu",
      503,
    );
  }
  if ((env.ENFORCE_APP_CHECK ?? "").toLowerCase() === "true" && !user.appCheckToken) {
    return errorResponse(
      "app_check_required",
      "App Check / bütünlük doğrulaması eksik",
      401,
    );
  }

  let rawBody: unknown;
  try {
    rawBody = await request.json();
  } catch {
    return errorResponse("invalid_json", "Geçersiz JSON gövdesi", 400);
  }
  const validated = validateDecisionPayload(rawBody);
  if (!validated.ok) {
    return errorResponse(
      "invalid_argument",
      `Geçersiz karar isteği: ${validated.reason}`,
      400,
    );
  }

  const ent = await env.DB.prepare(
    `SELECT uid, lifetime_owned, lifetime_token_hash, extra_decisions, extra_tokens
     FROM entitlements WHERE uid = ?`,
  )
    .bind(user.uid)
    .first<EntitlementRow>();

  if (!ent || (ent.lifetime_owned !== 1 && (ent.extra_decisions ?? 0) <= 0)) {
    return errorResponse(
      "permission_denied",
      "Sunucu karar kotası için Tam Sürüm ya da Karar Paketi gerekli",
      403,
    );
  }

  const lifetimeKey = ent.lifetime_token_hash
    ? `lt_${ent.lifetime_token_hash}`
    : `uid_${user.uid}`;
  const packKey = `uid_${user.uid}`;

  const [ltUsage, pkUsage] = await Promise.all([
    getUsageRow(env, lifetimeKey),
    packKey === lifetimeKey
      ? Promise.resolve(null)
      : getUsageRow(env, packKey),
  ]);
  const effectivePackUsage = packKey === lifetimeKey ? ltUsage : pkUsage;
  const before = computeQuotaView(ent, ltUsage, effectivePackUsage);

  let bucket: "once" | "pack" | null = null;
  if (before.remaining.once > 0 && before.remainingTokens.once > 0) {
    bucket = "once";
  } else if (before.remaining.pack > 0 && before.remainingTokens.pack > 0) {
    bucket = "pack";
  }
  if (!bucket) {
    return errorResponse(
      "resource_exhausted",
      "Akıllı karar hakkı veya girdi jetonu tavanı doldu",
      429,
      {
        remaining: before.remaining,
        remainingTokens: before.remainingTokens,
      },
    );
  }

  const apiKey = (env.GEMINI_API_KEY ?? "").trim();
  if (!apiKey) {
    return errorResponse(
      "service_unconfigured",
      "Sunucu karar anahtarı yapılandırılmamış",
      503,
    );
  }

  // Atomik ön rezervasyon (eşzamanlı çağrılarda tavan aşımını engeller).
  const now = nowMs(env);
  const reserveKey = bucket === "once" ? lifetimeKey : packKey;
  if (bucket === "once") {
    await env.DB.prepare(
      `INSERT INTO decision_usage (token_hash, calls_used, tokens_used, pack_calls_used, pack_tokens_used, updated_at)
       VALUES (?, 1, 0, 0, 0, ?)
       ON CONFLICT(token_hash) DO UPDATE SET calls_used = calls_used + 1, updated_at = excluded.updated_at`,
    )
      .bind(reserveKey, now)
      .run();
  } else {
    await env.DB.prepare(
      `INSERT INTO decision_usage (token_hash, calls_used, tokens_used, pack_calls_used, pack_tokens_used, updated_at)
       VALUES (?, 0, 0, 1, 0, ?)
       ON CONFLICT(token_hash) DO UPDATE SET pack_calls_used = pack_calls_used + 1, updated_at = excluded.updated_at`,
    )
      .bind(reserveKey, now)
      .run();
  }

  // Upstream Gemini Decisions API çağrısı
  const fetchFn = env.__fetch ?? fetch;
  let upstreamJson: unknown;
  try {
    const upstreamRes = await fetchFn(
      `${DECISIONS_ENDPOINT}?key=${encodeURIComponent(apiKey)}`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(validated.body),
      },
    );
    if (!upstreamRes.ok) {
      throw new Error(`upstream_${upstreamRes.status}`);
    }
    upstreamJson = await upstreamRes.json();
  } catch (err) {
    // Başarısız çağrıda rezerve edilen 1 hakkı iade et.
    if (bucket === "once") {
      await env.DB.prepare(
        `UPDATE decision_usage SET calls_used = MAX(0, calls_used - 1), updated_at = ?
         WHERE token_hash = ?`,
      )
        .bind(nowMs(env), reserveKey)
        .run();
    } else {
      await env.DB.prepare(
        `UPDATE decision_usage SET pack_calls_used = MAX(0, pack_calls_used - 1), updated_at = ?
         WHERE token_hash = ?`,
      )
        .bind(nowMs(env), reserveKey)
        .run();
    }
    return errorResponse(
      "upstream_unavailable",
      `Karar servisi yanıt vermedi: ${err instanceof Error ? err.message : "hata"}`,
      502,
    );
  }

  // Gerçek `usage.total_input_tokens` değerini sayaca işle (çift kilit).
  const inputTokens = extractInputTokens(upstreamJson);
  if (inputTokens > 0) {
    if (bucket === "once") {
      await env.DB.prepare(
        `UPDATE decision_usage SET tokens_used = tokens_used + ?, updated_at = ?
         WHERE token_hash = ?`,
      )
        .bind(inputTokens, nowMs(env), reserveKey)
        .run();
    } else {
      await env.DB.prepare(
        `UPDATE decision_usage SET pack_tokens_used = pack_tokens_used + ?, updated_at = ?
         WHERE token_hash = ?`,
      )
        .bind(inputTokens, nowMs(env), reserveKey)
        .run();
    }
  }

  const [afterLt, afterPk] = await Promise.all([
    getUsageRow(env, lifetimeKey),
    packKey === lifetimeKey
      ? Promise.resolve(null)
      : getUsageRow(env, packKey),
  ]);
  const afterView = computeQuotaView(
    ent,
    afterLt,
    packKey === lifetimeKey ? afterLt : afterPk,
  );

  return jsonResponse({
    response: upstreamJson,
    remaining: afterView.remaining,
    remainingTokens: afterView.remainingTokens,
  });
}
