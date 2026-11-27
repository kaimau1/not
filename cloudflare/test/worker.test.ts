import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { DatabaseSync } from "node:sqlite";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { clearJwksCache } from "../src/auth.ts";
import { bytesToBase64Url, sha256Hex } from "../src/crypto.ts";
import worker from "../src/index.ts";
import { MAX_USER_QUOTA_BYTES } from "../src/media.ts";
import type {
  AuthUser,
  D1DatabaseLike,
  D1PreparedStatementLike,
  Env,
  PlayProductStatus,
  R2BucketLike,
  R2ObjectBodyLike,
} from "../src/types.ts";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const INIT_SQL = fs.readFileSync(
  path.join(__dirname, "..", "migrations", "0001_init.sql"),
  "utf8",
);

/** Gerçek SQLite 3.54 üstünde D1 bağdaştırıcısı — birebir SQL sorguları çalışır. */
function createSqliteD1(): { db: D1DatabaseLike; raw: DatabaseSync } {
  const raw = new DatabaseSync(":memory:");
  raw.exec(INIT_SQL);

  function makeStmt(query: string, params: unknown[] = []): D1PreparedStatementLike {
    return {
      bind(...values: unknown[]) {
        return makeStmt(query, values);
      },
      async first<T = Record<string, unknown>>(column?: string): Promise<T | null> {
        const stmt = raw.prepare(query);
        const row = stmt.get(...(params as Array<string | number | null | Uint8Array>)) as
          | Record<string, unknown>
          | undefined;
        if (!row) return null;
        if (column) return (row[column] as T) ?? null;
        return row as T;
      },
      async all<T = Record<string, unknown>>(): Promise<{ results: T[] }> {
        const stmt = raw.prepare(query);
        const rows = stmt.all(...(params as Array<string | number | null | Uint8Array>));
        return { results: rows as T[] };
      },
      async run(): Promise<{ success: boolean; meta?: { changes?: number } }> {
        const stmt = raw.prepare(query);
        const info = stmt.run(...(params as Array<string | number | null | Uint8Array>));
        return { success: true, meta: { changes: Number(info.changes ?? 0) } };
      },
    };
  }

  const db: D1DatabaseLike = {
    prepare(query: string) {
      return makeStmt(query);
    },
    async batch<T = unknown>(statements: D1PreparedStatementLike[]): Promise<T[]> {
      const out: T[] = [];
      for (const s of statements) {
        out.push((await s.run()) as unknown as T);
      }
      return out;
    },
  };
  return { db, raw };
}

function createMemoryR2(): R2BucketLike {
  const store = new Map<
    string,
    { bytes: Uint8Array; contentType?: string }
  >();
  return {
    async put(key, value, options) {
      let bytes: Uint8Array;
      if (value instanceof Uint8Array) {
        bytes = new Uint8Array(value);
      } else if (value instanceof ArrayBuffer) {
        bytes = new Uint8Array(value.slice(0));
      } else if (typeof value === "string") {
        bytes = new TextEncoder().encode(value);
      } else {
        const chunks: Uint8Array[] = [];
        const reader = value.getReader();
        while (true) {
          const { done, value: chunk } = await reader.read();
          if (done) break;
          chunks.push(chunk);
        }
        const total = chunks.reduce((s, c) => s + c.byteLength, 0);
        bytes = new Uint8Array(total);
        let offset = 0;
        for (const c of chunks) {
          bytes.set(c, offset);
          offset += c.byteLength;
        }
      }
      store.set(key, { bytes, contentType: options?.httpMetadata?.contentType });
      return { key, size: bytes.byteLength };
    },
    async get(key): Promise<R2ObjectBodyLike | null> {
      const item = store.get(key);
      if (!item) return null;
      return {
        key,
        size: item.bytes.byteLength,
        httpMetadata: { contentType: item.contentType },
        body: null,
        async arrayBuffer() {
          return item.bytes.buffer.slice(
            item.bytes.byteOffset,
            item.bytes.byteOffset + item.bytes.byteLength,
          );
        },
      };
    },
    async delete(key) {
      store.delete(key);
    },
  };
}

function createTestEnv(overrides: Partial<Env> = {}): {
  env: Env;
  raw: DatabaseSync;
  setNow: (ms: number) => void;
} {
  const { db, raw } = createSqliteD1();
  let currentNow = Date.UTC(2026, 10, 25, 12, 0, 0);
  const env: Env = {
    DB: db,
    MEDIA: createMemoryR2(),
    FIREBASE_PROJECT_ID: "notlar-play-test",
    PLAY_PACKAGE_NAME: "dev.kaimau.notlar.play",
    GEMINI_API_KEY: "test-gemini-key",
    RTDN_SHARED_SECRET: "super-secret-rtdn",
    AI_KILL_SWITCH: "false",
    ENFORCE_APP_CHECK: "true",
    __now: () => currentNow,
    __verifyAuth: async (req) => {
      const uid = req.headers.get("x-test-uid") || "user-a";
      const anon = req.headers.get("x-test-anon") === "true";
      const user: AuthUser = {
        uid,
        email: `${uid}@example.com`,
        name: `User ${uid}`,
        isAnonymous: anon,
        appCheckToken: req.headers.get("x-firebase-appcheck"),
      };
      return user;
    },
    ...overrides,
  };
  return {
    env,
    raw,
    setNow: (ms: number) => {
      currentNow = ms;
    },
  };
}

async function reqJson(
  env: Env,
  method: string,
  urlPath: string,
  body?: unknown,
  headers: Record<string, string> = {},
) {
  const res = await worker.fetch(
    new Request(`https://sync.notlar.test${urlPath}`, {
      method,
      headers: {
        ...(body !== undefined ? { "content-type": "application/json" } : {}),
        ...headers,
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    }),
    env,
  );
  const json = await res.json();
  return { status: res.status, json: json as Record<string, unknown>, headers: res.headers };
}

test("GET /v1/health ve OPTIONS CORS çalışır", async () => {
  const { env } = createTestEnv();
  const health = await reqJson(env, "GET", "/v1/health");
  assert.equal(health.status, 200);
  assert.equal(health.json.ok, true);
  assert.equal(health.headers.get("access-control-allow-origin"), "*");

  const preflight = await worker.fetch(
    new Request("https://sync.notlar.test/v1/sync", { method: "OPTIONS" }),
    env,
  );
  assert.equal(preflight.status, 204);
});

test("Hibrit Firebase RS256 JWT doğrulaması (gerçek RSA-2048 imza + JWKS + süre dolumu)", async () => {
  clearJwksCache();
  const keyPair = await crypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const publicJwk = (await crypto.subtle.exportKey(
    "jwk",
    keyPair.publicKey,
  )) as JsonWebKey & { kid?: string };
  publicJwk.kid = "kid-2026-1";

  const nowSec = Math.floor(Date.UTC(2026, 10, 25, 12, 0, 0) / 1000);
  async function signJwt(payload: Record<string, unknown>, kid = "kid-2026-1") {
    const enc = new TextEncoder();
    const h = bytesToBase64Url(enc.encode(JSON.stringify({ alg: "RS256", typ: "JWT", kid })));
    const p = bytesToBase64Url(enc.encode(JSON.stringify(payload)));
    const sig = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      keyPair.privateKey,
      enc.encode(`${h}.${p}`),
    );
    return `${h}.${p}.${bytesToBase64Url(new Uint8Array(sig))}`;
  }

  const { env } = createTestEnv({
    __verifyAuth: undefined, // Gerçek JWT doğrulayıcıyı çalıştır!
    __fetch: async () =>
      new Response(JSON.stringify({ keys: [publicJwk] }), {
        status: 200,
        headers: { "content-type": "application/json", "cache-control": "max-age=3600" },
      }),
  });

  const validToken = await signJwt({
    iss: "https://securetoken.google.com/notlar-play-test",
    aud: "notlar-play-test",
    sub: "uid-real-jwt",
    email: "fatih@example.com",
    name: "Fatih",
    iat: nowSec - 10,
    exp: nowSec + 3600,
    firebase: { sign_in_provider: "google.com" },
  });

  const okRes = await reqJson(
    env,
    "GET",
    "/v1/entitlement",
    undefined,
    { authorization: `Bearer ${validToken}` },
  );
  assert.equal(okRes.status, 200);
  assert.equal(okRes.json.tier, "free");

  // Süresi dolmuş token reddedilir.
  const expiredToken = await signJwt({
    iss: "https://securetoken.google.com/notlar-play-test",
    aud: "notlar-play-test",
    sub: "uid-real-jwt",
    iat: nowSec - 7200,
    exp: nowSec - 10,
  });
  const expRes = await reqJson(
    env,
    "GET",
    "/v1/entitlement",
    undefined,
    { authorization: `Bearer ${expiredToken}` },
  );
  assert.equal(expRes.status, 401);

  // Yanlış proje (aud) reddedilir.
  const wrongAud = await signJwt({
    iss: "https://securetoken.google.com/baska-proje",
    aud: "baska-proje",
    sub: "uid-real-jwt",
    iat: nowSec - 10,
    exp: nowSec + 3600,
  });
  const audRes = await reqJson(
    env,
    "GET",
    "/v1/entitlement",
    undefined,
    { authorization: `Bearer ${wrongAud}` },
  );
  assert.equal(audRes.status, 401);
});

test("POST /v1/sync: delta pull, 2 cihaz çakışma bildirimi, paylaşım deltası ve 30 günlük GC", async () => {
  const { env, setNow } = createTestEnv();

  // 1. Cihaz A (Android) iki not yazar.
  const pushA = await reqJson(env, "POST", "/v1/sync", {
    cursorSeq: 0,
    changes: [
      { kind: "note", id: "n1", baseVersion: 0, payload: { title: "Market", content: "Süt\nEkmek" } },
      { kind: "note", id: "n2", baseVersion: 0, payload: { title: "İş", content: "Rapor" } },
    ],
  });
  assert.equal(pushA.status, 200);
  assert.equal((pushA.json.applied as unknown[]).length, 2);
  assert.equal((pushA.json.conflicts as unknown[]).length, 0);
  assert.equal(pushA.json.cursorSeq, 2);
  assert.equal((pushA.json.policy as { mode: string }).mode, "lite");

  // 2. 30 dakika sonra tekrar açılışta değişiklik yoksa 0 kayıt okunur!
  setNow(Date.UTC(2026, 10, 25, 12, 30, 0));
  const reopen = await reqJson(env, "POST", "/v1/sync", { cursorSeq: 2, changes: [] });
  assert.equal((reopen.json.entities as unknown[]).length, 0);
  assert.equal(reopen.json.cursorSeq, 2);

  // 3. Cihaz A n1'i günceller (version 1 → 2).
  const editA = await reqJson(env, "POST", "/v1/sync", {
    cursorSeq: 2,
    changes: [
      { kind: "note", id: "n1", baseVersion: 1, payload: { title: "Market", content: "Süt\nEkmek\nYumurta" } },
    ],
  });
  assert.equal(editA.status, 200);
  assert.equal(editA.json.cursorSeq, 3);

  // 4. Cihaz B (Web) çevrimdışı eski baseVersion=1 ile gönderir → conflicts[] döner, sunucu verisi korunur!
  const conflictB = await reqJson(env, "POST", "/v1/sync", {
    cursorSeq: 2,
    changes: [
      { kind: "note", id: "n1", baseVersion: 1, payload: { title: "Market", content: "Süt\nEkmek\nPeynir" } },
    ],
  });
  assert.equal(conflictB.status, 200);
  const conflicts = conflictB.json.conflicts as Array<Record<string, unknown>>;
  assert.equal(conflicts.length, 1);
  assert.equal(conflicts[0].serverVersion, 2);
  assert.deepEqual(conflicts[0].serverPayload, {
    title: "Market",
    content: "Süt\nEkmek\nYumurta",
  });

  // 5. Cihaz B 3-yönlü birleştirip baseVersion=2 ile tekrar yazar → version 3 olur!
  const mergedB = await reqJson(env, "POST", "/v1/sync", {
    cursorSeq: 3,
    changes: [
      {
        kind: "note",
        id: "n1",
        baseVersion: 2,
        payload: { title: "Market", content: "Süt\nEkmek\nYumurta\nPeynir" },
      },
    ],
  });
  assert.equal((mergedB.json.applied as Array<{ version: number }>)[0].version, 3);
  assert.equal(mergedB.json.cursorSeq, 4);

  // 6. Paylaşım: user-a n1'i user-b ile paylaşır → user-b delta pull'da alır.
  const shareRes = await reqJson(env, "POST", "/v1/shares", {
    entityKind: "note",
    entityId: "n1",
    memberUid: "user-b",
    role: "both",
    status: "active",
  });
  assert.equal(shareRes.status, 200);

  const pullB = await reqJson(
    env,
    "POST",
    "/v1/sync",
    { cursorSeq: 0, sharedCursorMs: 0, changes: [] },
    { "x-test-uid": "user-b" },
  );
  const shared = pullB.json.sharedEntities as Array<{ id: string; ownerUid: string }>;
  assert.equal(shared.length, 1);
  assert.equal(shared[0].id, "n1");
  assert.equal(shared[0].ownerUid, "user-a");

  // 7. Soft delete + 31 gün sonra cron GC temizliği.
  await reqJson(env, "POST", "/v1/sync", {
    cursorSeq: 4,
    changes: [{ kind: "note", id: "n2", baseVersion: 1, payload: {}, deleted: true }],
  });
  setNow(Date.UTC(2026, 11, 27, 12, 0, 0)); // +32 gün
  await worker.scheduled({ scheduledTime: Date.now(), cron: "0 3 * * *" }, env);
  const afterGc = await reqJson(env, "POST", "/v1/sync", { cursorSeq: 0, changes: [] });
  const ids = (afterGc.json.entities as Array<{ id: string }>).map((e) => e.id);
  assert.deepEqual(ids, ["n1"]);
});

test("Billing verify (lifetime + idempotent decision_pack_1000) + RTDN iade iptali + Full sync politikası", async () => {
  const uidA = "buyer-1";
  const tagA = await sha256Hex(uidA);
  let ackCount = 0;
  let consumeCount = 0;
  const playProducts = new Map<string, PlayProductStatus>([
    ["tok-lifetime-1", { owned: true, pending: false, needsAck: true, accountTag: tagA }],
    ["tok-pack-1", { owned: true, pending: false, needsAck: false, accountTag: tagA }],
  ]);

  const { env } = createTestEnv({
    __playVerifier: {
      async verifyOneTimeProduct(_pkg, _pid, token) {
        return playProducts.get(token) ?? null;
      },
      async acknowledgeProduct() {
        ackCount++;
      },
      async consumeProduct() {
        consumeCount++;
      },
    },
  });

  // 1. Lifetime doğrulama
  const lt = await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "lifetime", purchaseToken: "tok-lifetime-1" },
    { "x-test-uid": uidA },
  );
  assert.equal(lt.status, 200);
  assert.equal((lt.json.entitlement as { tier: string }).tier, "lifetime");
  assert.equal(ackCount, 1);

  // Sync politikası artık "full" döner!
  const syncFull = await reqJson(
    env,
    "POST",
    "/v1/sync",
    { cursorSeq: 0, changes: [] },
    { "x-test-uid": uidA },
  );
  assert.equal((syncFull.json.policy as { mode: string; liveShoppingWs: boolean }).mode, "full");
  assert.equal((syncFull.json.policy as { liveShoppingWs: boolean }).liveShoppingWs, true);

  // 2. Başka kullanıcı aynı belirteci çalamaz!
  const theft = await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "lifetime", purchaseToken: "tok-lifetime-1" },
    { "x-test-uid": "thief-2" },
  );
  assert.equal(theft.status, 403);

  // 3. +1.000 Karar Paketi idempotent: iki kez doğrulanırsa yalnız 1 kez +1.000 ekler!
  const pack1 = await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "decision_pack_1000", purchaseToken: "tok-pack-1" },
    { "x-test-uid": uidA },
  );
  assert.equal(pack1.status, 200);
  assert.equal((pack1.json.entitlement as { decisionCredits: number }).decisionCredits, 1000);
  assert.equal(consumeCount, 1);

  const pack2 = await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "decision_pack_1000", purchaseToken: "tok-pack-1" },
    { "x-test-uid": uidA },
  );
  assert.equal(pack2.status, 200);
  assert.equal((pack2.json.entitlement as { decisionCredits: number }).decisionCredits, 1000);

  // 4. RTDN iade bildirimi lifetime hakkını kaldırır (gizli anahtar yanlışsa 401).
  const rtdnBody = {
    message: {
      data: btoa(
        JSON.stringify({
          voidedPurchaseNotification: { purchaseToken: "tok-lifetime-1" },
        }),
      ),
    },
  };
  const badSecret = await reqJson(env, "POST", "/v1/billing/rtdn", rtdnBody, {
    "x-rtdn-secret": "wrong",
  });
  assert.equal(badSecret.status, 401);

  const goodRtdn = await reqJson(env, "POST", "/v1/billing/rtdn", rtdnBody, {
    "x-rtdn-secret": "super-secret-rtdn",
  });
  assert.equal(goodRtdn.status, 200);
  assert.equal(goodRtdn.json.revoked, true);

  const entAfter = await reqJson(env, "GET", "/v1/entitlement", undefined, {
    "x-test-uid": uidA,
  });
  assert.equal(entAfter.json.tier, "free");
  assert.equal(entAfter.json.lifetimeOwned, false);
});

test("POST /v1/decide: App Check, kill switch, 8K sınırı, 750/600K çift kilit ve token_hash kalıcılığı", async () => {
  let upstreamTokens = 250_000;
  let upstreamFail = false;
  const uid = "decider-1";
  const tag = await sha256Hex(uid);

  const { env, raw } = createTestEnv({
    __playVerifier: {
      async verifyOneTimeProduct() {
        return { owned: true, pending: false, needsAck: false, accountTag: tag };
      },
    },
    __fetch: async () => {
      if (upstreamFail) {
        return new Response("upstream error", { status: 500 });
      }
      return new Response(
        JSON.stringify({
          answers: { aisle: { value: "sut" } },
          usage: { total_input_tokens: upstreamTokens },
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    },
  });

  const sampleBody = {
    model: "gemini-decision-1",
    input: "Yarım yağlı süt 1 lt",
    questions: {
      aisle: { type: "choice", choices: ["sut", "manav", "diger"] },
    },
  };

  // 1. App Check eksikse 401.
  const noAppCheck = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
  });
  assert.equal(noAppCheck.status, 401);

  // 2. Ücretsiz kullanıcıya 403.
  const freeDenied = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
    "x-firebase-appcheck": "valid-appcheck",
  });
  assert.equal(freeDenied.status, 403);

  // 3. Lifetime satın alma doğrula.
  await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "lifetime", purchaseToken: "tok-lt-decide" },
    { "x-test-uid": uid },
  );

  // 4. 8.000 karakteri aşan payload reddedilir (400).
  const huge = await reqJson(
    env,
    "POST",
    "/v1/decide",
    { ...sampleBody, input: "a".repeat(8001) },
    { "x-test-uid": uid, "x-firebase-appcheck": "valid-appcheck" },
  );
  assert.equal(huge.status, 400);

  // 5. İlk çağrı başarılı: 250K jeton düşer (749 çağrı, 350K jeton kalır).
  const call1 = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
    "x-firebase-appcheck": "valid-appcheck",
  });
  assert.equal(call1.status, 200);
  assert.equal((call1.json.remaining as { once: number }).once, 749);
  assert.equal((call1.json.remainingTokens as { once: number }).once, 350_000);

  // 6. Upstream hata verirse ayrılan çağrı iade edilir (hâlâ 749 kalır)!
  upstreamFail = true;
  const failed = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
    "x-firebase-appcheck": "valid-appcheck",
  });
  assert.equal(failed.status, 502);
  upstreamFail = false;

  // 7. Hesap silinip (entitlements silinip) aynı purchaseToken geri yüklense bile sayaç SIFIRLANMAZ!
  raw.prepare("DELETE FROM entitlements WHERE uid = ?").run(uid);
  await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "lifetime", purchaseToken: "tok-lt-decide" },
    { "x-test-uid": uid },
  );
  const afterRestore = await reqJson(env, "GET", "/v1/entitlement", undefined, {
    "x-test-uid": uid,
  });
  assert.equal((afterRestore.json.remaining as { once: number }).once, 749);
  assert.equal((afterRestore.json.remainingTokens as { once: number }).once, 350_000);

  // 8. 350K jeton daha harcanınca toplam 600K jeton dolmuş olur → 3. çağrı 429 (748 çağrı kalsa bile çift kilit durdurur!).
  upstreamTokens = 350_000;
  const call2 = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
    "x-firebase-appcheck": "valid-appcheck",
  });
  assert.equal(call2.status, 200);
  assert.equal((call2.json.remaining as { once: number }).once, 0);
  assert.equal((call2.json.remainingTokens as { once: number }).once, 0);

  const call3 = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
    "x-firebase-appcheck": "valid-appcheck",
  });
  assert.equal(call3.status, 429);

  // 9. Kill switch açıkken anında 503.
  env.AI_KILL_SWITCH = "true";
  const killed = await reqJson(env, "POST", "/v1/decide", sampleBody, {
    "x-test-uid": uid,
    "x-firebase-appcheck": "valid-appcheck",
  });
  assert.equal(killed.status, 503);
});

test("D1 indeksli kullanıcı arama (GET /v1/users/search) ve R2 250 MB medya kotası", async () => {
  const { env, raw } = createTestEnv();

  // Kullanıcı dizini doldur.
  await reqJson(
    env,
    "PUT",
    "/v1/users/me",
    { name: "Ayşe Yılmaz", email: "ayse@example.com", discoverable: true },
    { "x-test-uid": "u-ayse" },
  );
  await reqJson(
    env,
    "PUT",
    "/v1/users/me",
    { name: "Gizli Kullanıcı", email: "gizli@example.com", discoverable: false },
    { "x-test-uid": "u-gizli" },
  );

  // Ad önekiyle arama (discoverable=true bulunur, discoverable=false çıkmaz).
  const byName = await reqJson(env, "GET", "/v1/users/search?q=ay%C5%9F", undefined, {
    "x-test-uid": "u-arayan",
  });
  assert.equal(byName.status, 200);
  assert.equal((byName.json.results as Array<{ uid: string }>).length, 1);
  assert.equal((byName.json.results as Array<{ uid: string }>)[0].uid, "u-ayse");

  const hiddenByName = await reqJson(env, "GET", "/v1/users/search?q=giz", undefined, {
    "x-test-uid": "u-arayan",
  });
  assert.equal((hiddenByName.json.results as unknown[]).length, 0);

  // Tam e-posta ile gizli kullanıcı bulunabilir.
  const byEmail = await reqJson(
    env,
    "GET",
    "/v1/users/search?q=gizli%40example.com",
    undefined,
    { "x-test-uid": "u-arayan" },
  );
  assert.equal((byEmail.json.results as Array<{ uid: string }>)[0].uid, "u-gizli");

  // Anonim kullanıcı arama yapamaz.
  const anonSearch = await reqJson(env, "GET", "/v1/users/search?q=ay%C5%9F", undefined, {
    "x-test-uid": "u-anon",
    "x-test-anon": "true",
  });
  assert.equal(anonSearch.status, 403);

  // R2 ortak medya yükleme, paylaşım bazlı okuma ve 250 MB kota koruması.
  const imgBytes = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4]);
  const putRes = await worker.fetch(
    new Request("https://sync.notlar.test/v1/media/u-ayse/note-1/foto.png", {
      method: "PUT",
      headers: {
        "x-test-uid": "u-ayse",
        "content-type": "image/png",
        "x-notlar-note-id": "note-1",
      },
      body: imgBytes,
    }),
    env,
  );
  assert.equal(putRes.status, 201);

  // Yetkisiz kullanıcı okuyamaz (403).
  const deniedGet = await worker.fetch(
    new Request("https://sync.notlar.test/v1/media/u-ayse/note-1/foto.png", {
      method: "GET",
      headers: { "x-test-uid": "u-yabanci" },
    }),
    env,
  );
  assert.equal(deniedGet.status, 403);

  // Paylaşım açılınca üye okuyabilir (200).
  await reqJson(
    env,
    "POST",
    "/v1/shares",
    { entityKind: "note", entityId: "note-1", memberUid: "u-arayan", role: "read", status: "active" },
    { "x-test-uid": "u-ayse" },
  );
  const sharedGet = await worker.fetch(
    new Request("https://sync.notlar.test/v1/media/u-ayse/note-1/foto.png", {
      method: "GET",
      headers: { "x-test-uid": "u-arayan" },
    }),
    env,
  );
  assert.equal(sharedGet.status, 200);
  assert.equal((await sharedGet.arrayBuffer()).byteLength, imgBytes.byteLength);

  // 250 MB kota sınırına yaklaştır → aşan yükleme 413 döner!
  raw
    .prepare("UPDATE r2_quota SET bytes_used = ? WHERE uid = ?")
    .run(MAX_USER_QUOTA_BYTES - 4, "u-ayse");

  const overQuota = await worker.fetch(
    new Request("https://sync.notlar.test/v1/media/u-ayse/note-1/buyuk.png", {
      method: "PUT",
      headers: { "x-test-uid": "u-ayse", "content-type": "image/png" },
      body: new Uint8Array(10),
    }),
    env,
  );
  assert.equal(overQuota.status, 413);

  // Silme işlemi kotayı düşürür.
  const delRes = await reqJson(
    env,
    "DELETE",
    "/v1/media/u-ayse/note-1/foto.png",
    undefined,
    { "x-test-uid": "u-ayse" },
  );
  assert.equal(delRes.status, 200);
  assert.equal(delRes.json.deleted, true);
  assert.equal(delRes.json.bytesUsed, MAX_USER_QUOTA_BYTES - 12);
});

test("POST /v1/decide dizi input, sahip dışı POST /v1/shares 403, paket RTDN iadesi ve DELETE /v1/users/me", async () => {
  const uid = "u-owner";
  const tag = await sha256Hex(uid);
  const { env, raw } = createTestEnv({
    __playVerifier: {
      async verifyOneTimeProduct() {
        return { owned: true, pending: false, needsAck: false, accountTag: tag };
      },
    },
    __fetch: async () =>
      new Response(
        JSON.stringify({
          answers: { aisle: { value: "sut" } },
          usage: { total_input_tokens: 100 },
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      ),
  });

  // 1. +1.000 paket doğrula ve Dart DecisionService biçimiyle (dizi input) /v1/decide çağır.
  const buyPack = await reqJson(
    env,
    "POST",
    "/v1/billing/verify",
    { productId: "decision_pack_1000", purchaseToken: "tok-pack-rtdn-1" },
    { "x-test-uid": uid },
  );
  assert.equal(buyPack.status, 200);

  const arrayCall = await reqJson(
    env,
    "POST",
    "/v1/decide",
    {
      model: "gemini-decision-1",
      input: [{ type: "text", text: "Tam yağlı süt 1 lt" }],
      questions: {
        aisle: { type: "choice", choices: ["sut", "manav", "diger"] },
      },
    },
    { "x-test-uid": uid, "x-firebase-appcheck": "valid-appcheck" },
  );
  assert.equal(arrayCall.status, 200);

  // 2. Paket iadesi (RTDN) ek karar kredisini idempotent biçimde düşer.
  const packRtdn = {
    message: {
      data: btoa(
        JSON.stringify({
          oneTimeProductNotification: {
            notificationType: 2,
            purchaseToken: "tok-pack-rtdn-1",
            sku: "decision_pack_1000",
          },
        }),
      ),
    },
  };
  const rtdn1 = await reqJson(env, "POST", "/v1/billing/rtdn", packRtdn, {
    "x-rtdn-secret": "super-secret-rtdn",
  });
  assert.equal(rtdn1.status, 200);
  assert.equal(rtdn1.json.revoked, true);

  const rtdnRepeat = await reqJson(env, "POST", "/v1/billing/rtdn", packRtdn, {
    "x-rtdn-secret": "super-secret-rtdn",
  });
  assert.equal(rtdnRepeat.status, 200);
  assert.equal(rtdnRepeat.json.revoked, false);

  const entAfterRefund = await reqJson(env, "GET", "/v1/entitlement", undefined, {
    "x-test-uid": uid,
  });
  assert.equal((entAfterRefund.json.decisionCredits as number), 0);

  // 3. Sahip olunmayan not için /v1/shares 403 döner.
  const deniedShare = await reqJson(
    env,
    "POST",
    "/v1/shares",
    { entityKind: "note", entityId: "not-owned", memberUid: "u-other" },
    { "x-test-uid": uid },
  );
  assert.equal(deniedShare.status, 403);

  // 4. Kullanıcı not ekler ve DELETE /v1/users/me sonrası entities boşalır, decision_usage korunur.
  await reqJson(
    env,
    "POST",
    "/v1/sync",
    {
      cursorSeq: 0,
      changes: [{ kind: "note", id: "n-del", baseVersion: 0, payload: { title: "Sil" } }],
    },
    { "x-test-uid": uid },
  );
  const delUser = await reqJson(env, "DELETE", "/v1/users/me", undefined, {
    "x-test-uid": uid,
  });
  assert.equal(delUser.status, 200);
  const remainingEntities = raw
    .prepare("SELECT COUNT(*) AS c FROM entities WHERE uid = ?")
    .get(uid) as { c: number };
  assert.equal(remainingEntities.c, 0);
  const keptUsage = raw
    .prepare("SELECT COUNT(*) AS c FROM decision_usage")
    .get() as { c: number };
  assert.ok(keptUsage.c >= 1);
});
