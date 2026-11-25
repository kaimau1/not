/**
 * NOTLAR CLOUDFLARE WORKER ANA GİRİŞ NOKTASI (PLAN §5 & Faz 2).
 *
 * Tek Worker uç noktaları:
 *  - GET    /v1/health
 *  - POST   /v1/sync              (delta pull/push + çakışma + Lite/Tam politika)
 *  - POST   /v1/shares            (ortak not/klasör paylaşımı)
 *  - POST   /v1/decide            (Decisions API vekili, 750/600K çift kilit + kill switch)
 *  - GET    /v1/entitlement       (kullanıcı hak ve karar kotası özeti)
 *  - POST   /v1/billing/verify    (Play Billing lifetime + decision_pack_1000 doğrulaması)
 *  - POST   /v1/billing/rtdn      (Google Play RTDN webhook / iade iptali)
 *  - PUT    /v1/users/me          (kullanıcı arama dizini kaydı)
 *  - GET    /v1/users/search      (D1 indeksli hızlı kullanıcı arama)
 *  - PUT    /v1/media/:key        (R2 ortak medya yükleme, kişi başı 250 MB kota)
 *  - GET    /v1/media/:key        (R2 ortak medya okuma, $0 egress)
 *  - DELETE /v1/media/:key        (R2 ortak medya silme + kota iadesi)
 *  - GET    /v1/rooms/shopping/:id (Durable Object WebSocket canlı alışveriş odası)
 */

import { AuthError, authenticateRequest } from "./auth.ts";
import {
  handleBillingRtdn,
  handleBillingVerify,
  handleGetEntitlement,
} from "./billing.ts";
import { handleDecide } from "./decisions.ts";
import {
  handleMediaDelete,
  handleMediaGet,
  handleMediaPut,
} from "./media.ts";
import { ShoppingRoom } from "./shopping_room.ts";
import {
  handleSync,
  handleUpsertShare,
  purgeExpiredSoftDeletes,
} from "./sync.ts";
import {
  type Env,
  errorResponse,
  jsonResponse,
  nowMs,
} from "./types.ts";
import {
  handleSearchUsers,
  handleUpsertUserDirectory,
} from "./users.ts";

export { ShoppingRoom };

function withCors(response: Response, env: Env): Response {
  const origin = env.CORS_ORIGIN || "*";
  const headers = new Headers(response.headers);
  headers.set("access-control-allow-origin", origin);
  headers.set(
    "access-control-allow-methods",
    "GET, POST, PUT, DELETE, OPTIONS",
  );
  headers.set(
    "access-control-allow-headers",
    "authorization, content-type, x-firebase-appcheck, x-notlar-note-id, x-rtdn-secret",
  );
  headers.set("x-content-type-options", "nosniff");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

async function route(request: Request, env: Env): Promise<Response> {
  const method = request.method.toUpperCase();
  if (method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }

  const url = new URL(request.url);
  const path = url.pathname.replace(/\/+$/, "") || "/";

  if (method === "GET" && path === "/v1/health") {
    return jsonResponse({
      ok: true,
      service: "notlar-sync",
      serverTimeMs: nowMs(env),
      aiKillSwitch: (env.AI_KILL_SWITCH ?? "").toLowerCase() === "true",
    });
  }

  // RTDN webhook'u Pub/Sub gizli anahtarıyla doğrulanır (Firebase JWT yok).
  if (method === "POST" && path === "/v1/billing/rtdn") {
    return handleBillingRtdn(request, env);
  }

  // Tüm diğer uç noktalar Hibrit Firebase ID Token ister.
  let user;
  try {
    user = await authenticateRequest(request, env);
  } catch (err) {
    if (err instanceof AuthError) {
      return errorResponse(err.code, err.message, err.status);
    }
    return errorResponse("auth_failed", "Kimlik doğrulanamadı", 401);
  }

  if (method === "POST" && path === "/v1/sync") {
    return handleSync(request, env, user);
  }
  if (method === "POST" && path === "/v1/shares") {
    return handleUpsertShare(request, env, user);
  }
  if (method === "POST" && path === "/v1/decide") {
    return handleDecide(request, env, user);
  }
  if (method === "GET" && path === "/v1/entitlement") {
    return handleGetEntitlement(env, user);
  }
  if (method === "POST" && path === "/v1/billing/verify") {
    return handleBillingVerify(request, env, user);
  }
  if (method === "PUT" && path === "/v1/users/me") {
    return handleUpsertUserDirectory(request, env, user);
  }
  if (method === "GET" && path === "/v1/users/search") {
    return handleSearchUsers(request, env, user);
  }

  if (path.startsWith("/v1/media/")) {
    const rawKey = path.slice("/v1/media/".length);
    if (method === "PUT") return handleMediaPut(request, env, user, rawKey);
    if (method === "GET") return handleMediaGet(env, user, rawKey);
    if (method === "DELETE") return handleMediaDelete(env, user, rawKey);
    return errorResponse("method_not_allowed", "Desteklenmeyen HTTP yöntemi", 405);
  }

  if (path.startsWith("/v1/rooms/shopping/")) {
    if (!env.SHOPPING_ROOM) {
      return errorResponse(
        "room_unconfigured",
        "Canlı alışveriş odası yapılandırılmamış",
        503,
      );
    }
    const noteId = path.slice("/v1/rooms/shopping/".length).trim();
    if (!noteId || noteId.includes("/")) {
      return errorResponse("invalid_room", "Geçersiz oda kimliği", 400);
    }
    const id = env.SHOPPING_ROOM.idFromName(noteId);
    const stub = env.SHOPPING_ROOM.get(id);
    const forwardedHeaders = new Headers(request.headers);
    forwardedHeaders.set("x-notlar-uid", user.uid);
    forwardedHeaders.set("x-notlar-name", user.name);
    return stub.fetch(new Request(request.url, { headers: forwardedHeaders }));
  }

  return errorResponse("not_found", `Bilinmeyen uç nokta: ${method} ${path}`, 404);
}

const worker = {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      const res = await route(request, env);
      return withCors(res, env);
    } catch (err) {
      return withCors(
        errorResponse(
          "internal_error",
          err instanceof Error ? err.message : "Beklenmeyen sunucu hatası",
          500,
        ),
        env,
      );
    }
  },

  async scheduled(
    _event: { scheduledTime: number; cron: string },
    env: Env,
  ): Promise<void> {
    await purgeExpiredSoftDeletes(env, 30);
  },
};

export default worker;
