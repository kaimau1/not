/**
 * PLAY BILLING DOĞRULAMA & RTDN (`GET /v1/entitlement`, `POST /v1/billing/verify`,
 * `POST /v1/billing/rtdn`, PLAN §5.4 & Faz 1+2).
 *
 * 2-katmanlı hak modeli:
 *  - `lifetime` (50 TL tek sefer, tüketilmez) → `lifetime_owned = 1`,
 *    `lifetime_token_hash = sha256(purchaseToken)`. Hesap silinip yeniden
 *    açılsa da `decision_usage` aynı `lt_<token_hash>` satırını korur!
 *  - `decision_pack_1000` (30 TL tüketilebilir) → idempotent `+1.000` çağrı,
 *    `+800.000` girdi jetonu (`credited_pack_tokens` tablosu aynı belirteci
 *    ikinci kez eklemez).
 */

import {
  bytesToBase64Url,
  constantTimeEqual,
  sha256Hex,
} from "./crypto.ts";
import { computeQuotaView } from "./decisions.ts";
import {
  type AuthUser,
  type Env,
  type PlayProductStatus,
  type PlayPurchaseVerifier,
  errorResponse,
  jsonResponse,
  nowMs,
} from "./types.ts";

export const LIFETIME_PRODUCT = "lifetime";
export const DECISION_PACK_1000 = "decision_pack_1000";
export const DECISION_PACK_CALLS = 1000;
export const DECISION_PACK_TOKENS = 800_000;

interface EntitlementRow {
  uid: string;
  lifetime_owned: number;
  lifetime_token_hash: string | null;
  extra_decisions: number;
  extra_tokens: number;
  pro_until: number | null;
  trial_ends_at: number | null;
  updated_at: number;
}

interface UsageRow {
  token_hash: string;
  calls_used: number;
  tokens_used: number;
  pack_calls_used: number;
  pack_tokens_used: number;
}

interface ServiceAccountJson {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) {
    bytes[i] = bin.charCodeAt(i);
  }
  return bytes.buffer;
}

async function getGooglePlayAccessToken(env: Env): Promise<string> {
  const raw = (env.GOOGLE_PLAY_SA_JSON ?? "").trim();
  if (!raw) throw new Error("GOOGLE_PLAY_SA_JSON eksik");
  const sa = JSON.parse(raw) as ServiceAccountJson;
  const nowSec = Math.floor(nowMs(env) / 1000);
  const tokenUri = sa.token_uri || "https://oauth2.googleapis.com/token";

  const header = bytesToBase64Url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const claim = bytesToBase64Url(
    new TextEncoder().encode(
      JSON.stringify({
        iss: sa.client_email,
        scope: "https://www.googleapis.com/auth/androidpublisher",
        aud: tokenUri,
        iat: nowSec,
        exp: nowSec + 3600,
      }),
    ),
  );
  const signingInput = `${header}.${claim}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sigBuf = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const assertion = `${signingInput}.${bytesToBase64Url(new Uint8Array(sigBuf))}`;

  const fetchFn = env.__fetch ?? fetch;
  const res = await fetchFn(tokenUri, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) {
    throw new Error(`oauth_token_failed_${res.status}`);
  }
  const data = (await res.json()) as { access_token?: string };
  if (!data.access_token) throw new Error("oauth_missing_access_token");
  return data.access_token;
}

function createGooglePlayVerifier(env: Env): PlayPurchaseVerifier {
  if (env.__playVerifier) return env.__playVerifier;
  const fetchFn = env.__fetch ?? fetch;
  const base = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications";

  return {
    async verifyOneTimeProduct(
      packageName: string,
      productId: string,
      purchaseToken: string,
    ): Promise<PlayProductStatus | null> {
      const accessToken = await getGooglePlayAccessToken(env);
      const url =
        `${base}/${encodeURIComponent(packageName)}/purchases/products/` +
        `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;
      const res = await fetchFn(url, {
        headers: { authorization: `Bearer ${accessToken}` },
      });
      if (res.status === 404) return null;
      if (!res.ok) throw new Error(`play_api_${res.status}`);
      const data = (await res.json()) as {
        purchaseState?: number;
        acknowledgementState?: number;
        obfuscatedExternalAccountId?: string;
      };
      const owned = data.purchaseState === 0;
      return {
        owned,
        pending: data.purchaseState === 2,
        needsAck: owned && data.acknowledgementState === 0,
        accountTag: data.obfuscatedExternalAccountId ?? null,
      };
    },

    async acknowledgeProduct(
      packageName: string,
      productId: string,
      purchaseToken: string,
    ): Promise<void> {
      const accessToken = await getGooglePlayAccessToken(env);
      const url =
        `${base}/${encodeURIComponent(packageName)}/purchases/products/` +
        `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
      const res = await fetchFn(url, {
        method: "POST",
        headers: {
          authorization: `Bearer ${accessToken}`,
          "content-type": "application/json",
        },
        body: "{}",
      });
      if (!res.ok) {
        throw new Error(`play_ack_failed_${res.status}`);
      }
    },

    async consumeProduct(
      packageName: string,
      productId: string,
      purchaseToken: string,
    ): Promise<void> {
      const accessToken = await getGooglePlayAccessToken(env);
      const url =
        `${base}/${encodeURIComponent(packageName)}/purchases/products/` +
        `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:consume`;
      const res = await fetchFn(url, {
        method: "POST",
        headers: { authorization: `Bearer ${accessToken}` },
      });
      if (!res.ok) {
        throw new Error(`play_consume_failed_${res.status}`);
      }
    },
  };
}

async function readEntitlementPayload(env: Env, uid: string) {
  const ent = await env.DB.prepare(
    `SELECT uid, lifetime_owned, lifetime_token_hash, extra_decisions, extra_tokens,
            pro_until, trial_ends_at, updated_at
     FROM entitlements WHERE uid = ?`,
  )
    .bind(uid)
    .first<EntitlementRow>();

  const lifetimeKey = ent?.lifetime_token_hash
    ? `lt_${ent.lifetime_token_hash}`
    : `uid_${uid}`;
  const packKey = `uid_${uid}`;

  const [ltUsage, pkUsage] = await Promise.all([
    env.DB.prepare(
      `SELECT token_hash, calls_used, tokens_used, pack_calls_used, pack_tokens_used
       FROM decision_usage WHERE token_hash = ?`,
    )
      .bind(lifetimeKey)
      .first<UsageRow>(),
    packKey === lifetimeKey
      ? Promise.resolve(null)
      : env.DB.prepare(
          `SELECT token_hash, calls_used, tokens_used, pack_calls_used, pack_tokens_used
           FROM decision_usage WHERE token_hash = ?`,
        )
          .bind(packKey)
          .first<UsageRow>(),
  ]);

  const quota = computeQuotaView(
    ent,
    ltUsage,
    packKey === lifetimeKey ? ltUsage : pkUsage,
  );
  const lifetimeOwned = ent?.lifetime_owned === 1;
  return {
    tier: lifetimeOwned ? "lifetime" : "free",
    lifetimeOwned,
    decisionCredits: Number(ent?.extra_decisions ?? 0),
    decisionTokenCredits: Number(ent?.extra_tokens ?? 0),
    proUntil: ent?.pro_until ?? null,
    trialEndsAt: ent?.trial_ends_at ?? null,
    updatedAt: ent?.updated_at ?? null,
    remaining: quota.remaining,
    remainingTokens: quota.remainingTokens,
  };
}

export async function handleGetEntitlement(
  env: Env,
  user: AuthUser,
): Promise<Response> {
  const data = await readEntitlementPayload(env, user.uid);
  return jsonResponse(data);
}

export async function handleBillingVerify(
  request: Request,
  env: Env,
  user: AuthUser,
): Promise<Response> {
  if (user.isAnonymous) {
    return errorResponse(
      "anonymous_not_allowed",
      "Satın alma doğrulaması için oturum açılmalıdır",
      403,
    );
  }
  let body: { productId?: unknown; purchaseToken?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return errorResponse("invalid_json", "Geçersiz JSON gövdesi", 400);
  }
  const productId = typeof body.productId === "string" ? body.productId.trim() : "";
  const purchaseToken =
    typeof body.purchaseToken === "string" ? body.purchaseToken.trim() : "";

  if (
    (productId !== LIFETIME_PRODUCT && productId !== DECISION_PACK_1000) ||
    purchaseToken.length < 8 ||
    purchaseToken.length > 4096
  ) {
    return errorResponse(
      "invalid_argument",
      "Geçersiz productId veya purchaseToken",
      400,
    );
  }

  const packageName = (env.PLAY_PACKAGE_NAME ?? "dev.kaimau.notlar.play").trim();
  const verifier = createGooglePlayVerifier(env);
  let status: PlayProductStatus | null;
  try {
    status = await verifier.verifyOneTimeProduct(
      packageName,
      productId,
      purchaseToken,
    );
  } catch (err) {
    return errorResponse(
      "play_verify_failed",
      `Google Play doğrulaması başarısız: ${err instanceof Error ? err.message : "hata"}`,
      502,
    );
  }

  if (!status) {
    return errorResponse("purchase_not_found", "Satın alma bulunamadı", 404);
  }
  if (status.pending) {
    return errorResponse("purchase_pending", "Ödeme henüz onaylanmadı", 409);
  }
  if (!status.owned) {
    return errorResponse("purchase_not_owned", "Satın alma geçerli değil", 402);
  }

  const expectedTag = await sha256Hex(user.uid);
  if (status.accountTag && status.accountTag !== expectedTag) {
    return errorResponse(
      "other_account",
      "Bu satın alma başka bir hesaba ait",
      403,
    );
  }

  const tokenHash = await sha256Hex(purchaseToken);
  const existingToken = await env.DB.prepare(
    "SELECT uid, product_id FROM purchase_tokens WHERE token_hash = ?",
  )
    .bind(tokenHash)
    .first<{ uid: string; product_id: string }>();

  if (existingToken && existingToken.uid !== user.uid) {
    return errorResponse(
      "other_account",
      "Bu belirteç zaten başka bir kullanıcıya bağlı",
      403,
    );
  }

  const now = nowMs(env);
  await env.DB.prepare(
    `INSERT INTO purchase_tokens (token_hash, uid, product_id, status, updated_at)
     VALUES (?, ?, ?, 'owned', ?)
     ON CONFLICT(token_hash) DO UPDATE SET status = 'owned', updated_at = excluded.updated_at`,
  )
    .bind(tokenHash, user.uid, productId, now)
    .run();

  if (productId === LIFETIME_PRODUCT) {
    await env.DB.prepare(
      `INSERT INTO entitlements (uid, lifetime_owned, lifetime_token_hash, extra_decisions, extra_tokens, updated_at)
       VALUES (?, 1, ?, 0, 0, ?)
       ON CONFLICT(uid) DO UPDATE SET
         lifetime_owned = 1,
         lifetime_token_hash = excluded.lifetime_token_hash,
         updated_at = excluded.updated_at`,
    )
      .bind(user.uid, tokenHash, now)
      .run();

    if (status.needsAck && verifier.acknowledgeProduct) {
      await verifier.acknowledgeProduct(packageName, productId, purchaseToken);
    }
  } else if (productId === DECISION_PACK_1000) {
    // İdempotency: aynı belirteç iki kez eklenmez!
    const alreadyCredited = await env.DB.prepare(
      "SELECT token_hash FROM credited_pack_tokens WHERE token_hash = ?",
    )
      .bind(tokenHash)
      .first<{ token_hash: string }>();

    if (!alreadyCredited) {
      await env.DB.prepare(
        `INSERT INTO credited_pack_tokens (token_hash, uid, calls_added, tokens_added, created_at)
         VALUES (?, ?, ?, ?, ?)`,
      )
        .bind(
          tokenHash,
          user.uid,
          DECISION_PACK_CALLS,
          DECISION_PACK_TOKENS,
          now,
        )
        .run();

      await env.DB.prepare(
        `INSERT INTO entitlements (uid, lifetime_owned, extra_decisions, extra_tokens, updated_at)
         VALUES (?, 0, ?, ?, ?)
         ON CONFLICT(uid) DO UPDATE SET
           extra_decisions = extra_decisions + excluded.extra_decisions,
           extra_tokens = extra_tokens + excluded.extra_tokens,
           updated_at = excluded.updated_at`,
      )
        .bind(user.uid, DECISION_PACK_CALLS, DECISION_PACK_TOKENS, now)
        .run();
    }

    if (verifier.consumeProduct) {
      await verifier.consumeProduct(packageName, productId, purchaseToken);
    }
  }

  const entitlement = await readEntitlementPayload(env, user.uid);
  return jsonResponse({ ok: true, productId, entitlement });
}

/**
 * Google Play Real-Time Developer Notifications (RTDN) webhook'u.
 * Pub/Sub push isteği `X-RTDN-Secret` (ya da `?secret=...`) ile doğrulanır;
 * iade/iptal (`voidedPurchaseNotification` veya `ONE_TIME_PRODUCT_CANCELED`)
 * yalnız ilgili `lifetime_token_hash` eşleşiyorsa ömür boyu hakkı geri alır.
 */
export async function handleBillingRtdn(
  request: Request,
  env: Env,
): Promise<Response> {
  const configuredSecret = (env.RTDN_SHARED_SECRET ?? "").trim();
  if (!configuredSecret) {
    return errorResponse("rtdn_not_configured", "RTDN gizli anahtarı tanımlı değil", 503);
  }
  const url = new URL(request.url);
  const supplied =
    request.headers.get("x-rtdn-secret")?.trim() ||
    url.searchParams.get("secret")?.trim() ||
    "";
  if (!supplied || !constantTimeEqual(supplied, configuredSecret)) {
    return errorResponse("unauthorized", "Geçersiz RTDN anahtarı", 401);
  }

  let envelope: { message?: { data?: string } };
  try {
    envelope = (await request.json()) as typeof envelope;
  } catch {
    return errorResponse("invalid_json", "Geçersiz RTDN JSON gövdesi", 400);
  }
  const b64 = envelope.message?.data;
  if (!b64 || typeof b64 !== "string") {
    return jsonResponse({ ok: true, ignored: "empty_message" });
  }

  let notification: {
    packageName?: string;
    voidedPurchaseNotification?: { purchaseToken?: string };
    oneTimeProductNotification?: {
      notificationType?: number;
      purchaseToken?: string;
      sku?: string;
    };
  };
  try {
    notification = JSON.parse(atob(b64)) as typeof notification;
  } catch {
    return errorResponse("invalid_rtdn_payload", "Base64 RTDN verisi çözümlenemedi", 400);
  }

  const now = nowMs(env);
  const voidToken = notification.voidedPurchaseNotification?.purchaseToken;
  const otp = notification.oneTimeProductNotification;
  // notificationType === 2 → ONE_TIME_PRODUCT_CANCELED
  const revokedToken =
    voidToken || (otp && otp.notificationType === 2 ? otp.purchaseToken : null);

  if (!revokedToken) {
    return jsonResponse({ ok: true, ignored: "non_revocation_event" });
  }

  const tokenHash = await sha256Hex(revokedToken);
  const existingToken = await env.DB.prepare(
    "SELECT uid, product_id, status FROM purchase_tokens WHERE token_hash = ?",
  )
    .bind(tokenHash)
    .first<{ uid: string; product_id: string; status: string }>();

  if (existingToken?.status === "revoked") {
    return jsonResponse({ ok: true, revoked: false, ignored: "already_revoked" });
  }

  await env.DB.prepare(
    "UPDATE purchase_tokens SET status = 'revoked', updated_at = ? WHERE token_hash = ?",
  )
    .bind(now, tokenHash)
    .run();

  // Ömür boyu hakkını kaldır.
  const ltRes = await env.DB.prepare(
    `UPDATE entitlements
     SET lifetime_owned = 0, updated_at = ?
     WHERE lifetime_token_hash = ?`,
  )
    .bind(now, tokenHash)
    .run();

  let packChanges = 0;
  if (
    existingToken?.product_id === DECISION_PACK_1000 ||
    otp?.sku === DECISION_PACK_1000
  ) {
    const credited = await env.DB.prepare(
      "SELECT uid, calls_added, tokens_added FROM credited_pack_tokens WHERE token_hash = ?",
    )
      .bind(tokenHash)
      .first<{ uid: string; calls_added: number; tokens_added: number }>();
    if (credited) {
      const packRes = await env.DB.prepare(
        `UPDATE entitlements
         SET extra_decisions = MAX(0, extra_decisions - ?),
             extra_tokens = MAX(0, extra_tokens - ?),
             updated_at = ?
         WHERE uid = ?`,
      )
        .bind(credited.calls_added, credited.tokens_added, now, credited.uid)
        .run();
      packChanges = Number(packRes.meta?.changes ?? 0);
    }
  }

  return jsonResponse({
    ok: true,
    revoked: Number(ltRes.meta?.changes ?? 0) + packChanges > 0,
  });
}
