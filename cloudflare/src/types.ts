/**
 * Cloudflare Worker ortam bağlamı ve paylaşılan veri sözleşmeleri.
 * Harici bağımlılık olmadan hem Wrangler hem Node 22 yerel testlerinde çalışır.
 */

export interface D1PreparedStatementLike {
  bind(...values: unknown[]): D1PreparedStatementLike;
  first<T = Record<string, unknown>>(column?: string): Promise<T | null>;
  all<T = Record<string, unknown>>(): Promise<{ results: T[] }>;
  run(): Promise<{ success: boolean; meta?: { changes?: number } }>;
}

export interface D1DatabaseLike {
  prepare(query: string): D1PreparedStatementLike;
  batch<T = unknown>(statements: D1PreparedStatementLike[]): Promise<T[]>;
}

export interface R2ObjectBodyLike {
  key: string;
  size: number;
  httpMetadata?: { contentType?: string };
  arrayBuffer(): Promise<ArrayBuffer>;
  body: ReadableStream<Uint8Array> | null;
}

export interface R2BucketLike {
  put(
    key: string,
    value: ArrayBuffer | Uint8Array | string | ReadableStream<Uint8Array>,
    options?: {
      httpMetadata?: { contentType?: string };
      customMetadata?: Record<string, string>;
    },
  ): Promise<{ key: string; size: number }>;
  get(key: string): Promise<R2ObjectBodyLike | null>;
  delete(key: string): Promise<void>;
}

export interface DurableObjectStubLike {
  fetch(request: Request): Promise<Response>;
}

export interface DurableObjectNamespaceLike {
  idFromName(name: string): unknown;
  get(id: unknown): DurableObjectStubLike;
}

export interface AuthUser {
  uid: string;
  email: string;
  name: string;
  isAnonymous: boolean;
  appCheckToken: string | null;
}

export interface PlayProductStatus {
  owned: boolean;
  pending: boolean;
  needsAck: boolean;
  accountTag: string | null;
}

export interface PlayPurchaseVerifier {
  verifyOneTimeProduct(
    packageName: string,
    productId: string,
    purchaseToken: string,
  ): Promise<PlayProductStatus | null>;
  acknowledgeProduct?(
    packageName: string,
    productId: string,
    purchaseToken: string,
  ): Promise<void>;
  consumeProduct?(
    packageName: string,
    productId: string,
    purchaseToken: string,
  ): Promise<void>;
}

export interface Env {
  DB: D1DatabaseLike;
  MEDIA?: R2BucketLike;
  SHOPPING_ROOM?: DurableObjectNamespaceLike;
  FIREBASE_PROJECT_ID?: string;
  PLAY_PACKAGE_NAME?: string;
  GEMINI_API_KEY?: string;
  GOOGLE_PLAY_SA_JSON?: string;
  RTDN_SHARED_SECRET?: string;
  AI_KILL_SWITCH?: string;
  ENFORCE_APP_CHECK?: string;
  CORS_ORIGIN?: string;
  // Test enjeksiyon kancaları (üretimde tanımsız).
  __fetch?: typeof fetch;
  __now?: () => number;
  __verifyAuth?: (request: Request, env: Env) => Promise<AuthUser>;
  __playVerifier?: PlayPurchaseVerifier;
}

export function nowMs(env: Env): number {
  return env.__now ? env.__now() : Date.now();
}

export function jsonResponse(
  body: unknown,
  status = 200,
  extraHeaders?: Record<string, string>,
): Response {
  const headers = new Headers({
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    ...extraHeaders,
  });
  return new Response(JSON.stringify(body), { status, headers });
}

export function errorResponse(
  code: string,
  message: string,
  status: number,
  details?: Record<string, unknown>,
): Response {
  return jsonResponse(
    { error: { code, message, ...(details ? { details } : {}) } },
    status,
  );
}
