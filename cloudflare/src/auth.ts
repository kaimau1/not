/**
 * HİBRİT KİMLİK DOĞRULAMA (PLAN §5.3 Seçenek B & §9 Karar #1):
 * Firebase Auth ücretsiz katmanda kalır; Cloudflare Worker gelen
 * `Authorization: Bearer <firebase_id_token>` JWT'sini Google'ın resmi
 * JWKS uç noktasından RS256 ile doğrular (sıfır dış bağımlılık, Web Crypto).
 */

import { base64UrlToJson, verifyRs256Signature } from "./crypto.ts";
import { type AuthUser, type Env, nowMs } from "./types.ts";

export const FIREBASE_JWKS_URL =
  "https://www.googleapis.com/robot/v1/metadata/jwk/securetoken@system.gserviceaccount.com";

interface JwksResponse {
  keys: Array<JsonWebKey & { kid?: string }>;
}

interface JwksCacheEntry {
  keys: Map<string, JsonWebKey>;
  expiresAtMs: number;
}

let jwksCache: JwksCacheEntry | null = null;

export function clearJwksCache(): void {
  jwksCache = null;
}

export class AuthError extends Error {
  readonly status: number;
  readonly code: string;

  constructor(code: string, message: string, status = 401) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

function parseMaxAgeSeconds(cacheControl: string | null): number {
  if (!cacheControl) return 3600;
  const m = /max-age=(\d+)/i.exec(cacheControl);
  if (!m) return 3600;
  const sec = Number.parseInt(m[1], 10);
  return Number.isFinite(sec) && sec > 60 ? Math.min(sec, 86400) : 3600;
}

async function fetchFirebaseJwks(
  env: Env,
  forceRefresh = false,
): Promise<Map<string, JsonWebKey>> {
  const now = nowMs(env);
  if (!forceRefresh && jwksCache && jwksCache.expiresAtMs > now) {
    return jwksCache.keys;
  }
  const fetchFn = env.__fetch ?? fetch;
  const res = await fetchFn(FIREBASE_JWKS_URL, { method: "GET" });
  if (!res.ok) {
    throw new AuthError(
      "auth_jwks_unavailable",
      `JWKS alınamadı (${res.status})`,
      503,
    );
  }
  const data = (await res.json()) as JwksResponse;
  const keys = new Map<string, JsonWebKey>();
  for (const k of data.keys ?? []) {
    if (k.kid) keys.set(k.kid, k);
  }
  const ttlSec = parseMaxAgeSeconds(res.headers.get("cache-control"));
  jwksCache = { keys, expiresAtMs: now + ttlSec * 1000 };
  return keys;
}

interface JwtHeader {
  alg?: string;
  kid?: string;
  typ?: string;
}

interface FirebaseJwtPayload {
  iss?: string;
  aud?: string;
  sub?: string;
  exp?: number;
  iat?: number;
  auth_time?: number;
  email?: string;
  name?: string;
  firebase?: {
    sign_in_provider?: string;
  };
}

export async function verifyFirebaseIdToken(
  token: string,
  env: Env,
): Promise<Omit<AuthUser, "appCheckToken">> {
  const projectId = (env.FIREBASE_PROJECT_ID ?? "").trim();
  if (!projectId) {
    throw new AuthError(
      "auth_not_configured",
      "FIREBASE_PROJECT_ID tanımlı değil",
      500,
    );
  }
  const parts = token.split(".");
  if (parts.length !== 3) {
    throw new AuthError("auth_invalid_token", "Geçersiz JWT biçimi");
  }
  const [headerSeg, payloadSeg, sigSeg] = parts;
  let header: JwtHeader;
  let payload: FirebaseJwtPayload;
  try {
    header = base64UrlToJson<JwtHeader>(headerSeg);
    payload = base64UrlToJson<FirebaseJwtPayload>(payloadSeg);
  } catch {
    throw new AuthError("auth_invalid_token", "JWT çözümlenemedi");
  }

  if (header.alg !== "RS256" || !header.kid) {
    throw new AuthError("auth_invalid_alg", "Yalnız RS256 Firebase JWT kabul edilir");
  }

  const nowSec = Math.floor(nowMs(env) / 1000);
  if (typeof payload.exp !== "number" || payload.exp <= nowSec) {
    throw new AuthError("auth_token_expired", "Oturum belirtecinin süresi dolmuş");
  }
  if (typeof payload.iat !== "number" || payload.iat > nowSec + 300) {
    throw new AuthError("auth_invalid_iat", "Belirteç zaman damgası geçersiz");
  }
  const expectedIss = `https://securetoken.google.com/${projectId}`;
  if (payload.iss !== expectedIss || payload.aud !== projectId) {
    throw new AuthError("auth_invalid_audience", "Belirteç proje kimliği uyuşmuyor");
  }
  const uid = typeof payload.sub === "string" ? payload.sub.trim() : "";
  if (!uid || uid.length > 128) {
    throw new AuthError("auth_invalid_subject", "Kullanıcı kimliği (sub) geçersiz");
  }

  let keys = await fetchFirebaseJwks(env, false);
  let jwk = keys.get(header.kid);
  if (!jwk) {
    // Anahtar rotasyonu olabilir — tek sefer tazele.
    keys = await fetchFirebaseJwks(env, true);
    jwk = keys.get(header.kid);
  }
  if (!jwk) {
    throw new AuthError("auth_unknown_kid", "Bilinmeyen imzalama anahtarı (kid)");
  }

  const ok = await verifyRs256Signature(jwk, `${headerSeg}.${payloadSeg}`, sigSeg);
  if (!ok) {
    throw new AuthError("auth_bad_signature", "JWT imzası doğrulanamadı");
  }

  const provider = payload.firebase?.sign_in_provider ?? "";
  return {
    uid,
    email: typeof payload.email === "string" ? payload.email.trim() : "",
    name: typeof payload.name === "string" ? payload.name.trim() : "",
    isAnonymous: provider === "anonymous",
  };
}

export async function authenticateRequest(
  request: Request,
  env: Env,
): Promise<AuthUser> {
  if (env.__verifyAuth) {
    return env.__verifyAuth(request, env);
  }
  const authHeader = request.headers.get("authorization") ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(authHeader.trim());
  if (!match) {
    throw new AuthError("auth_missing", "Authorization Bearer belirteci eksik");
  }
  const verified = await verifyFirebaseIdToken(match[1].trim(), env);
  const appCheck = request.headers.get("x-firebase-appcheck")?.trim() || null;
  return { ...verified, appCheckToken: appCheck };
}
