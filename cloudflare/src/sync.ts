/**
 * TEK UÇ NOKTALI DELTA SENKRON PROTOKOLÜ (`POST /v1/sync`, PLAN §5.5).
 *
 * - İstemci `cursorSeq` + yerel Outbox `changes[]` listesini gönderir.
 * - Her değişiklik için iyimser eşzamanlılık (`baseVersion === current.version`)
 *   denetlenir: eşleşirse yazılır ve monotonik `seq` atanır; eski sürümse
 *   sunucu kopyası `conflicts[]` dizisinde döner (istemci `text_merge.dart`
 *   ile 3-yönlü birleştirip tekrar gönderir — sıfır veri kaybı).
 * - Kendi kayıtları (`seq > cursorSeq`) + aktif paylaşılan kayıtlar tek JSON
 *   yanıtında döner.
 * - Lite (5 dk + arka plan) vs Tam Sürüm (2,5 sn debounce + canlı alışveriş)
 *   senkron hız politikası yanıtın `policy` alanında iletilir.
 */

import {
  type AuthUser,
  type Env,
  errorResponse,
  jsonResponse,
  nowMs,
} from "./types.ts";

export const ALLOWED_ENTITY_KINDS = new Set([
  "note",
  "folder",
  "event",
  "task",
  "task_list",
  "routine",
  "pref",
  "shop_price",
  "shop_meta",
  "friend",
]);

export const MAX_CHANGES_PER_PUSH = 100;
export const MAX_ENTITY_PAYLOAD_BYTES = 512 * 1024;
export const DEFAULT_PULL_LIMIT = 200;
export const MAX_PULL_LIMIT = 500;
const ENTITY_ID_RE = /^[A-Za-z0-9_.:-]{1,128}$/;

export interface IncomingSyncChange {
  kind: string;
  id: string;
  baseVersion: number;
  payload: unknown;
  deleted?: boolean;
  encrypted?: boolean;
}

export interface SyncEntityRow {
  uid: string;
  kind: string;
  id: string;
  seq: number;
  version: number;
  updated_at: number;
  deleted_at: number | null;
  encrypted: number;
  payload: string;
}

export interface SyncPolicy {
  mode: "lite" | "full";
  debounceMs: number;
  intervalSec: number;
  flushOnBackground: boolean;
  liveShoppingWs: boolean;
}

function serializePayload(raw: unknown): string {
  if (typeof raw === "string") return raw;
  return JSON.stringify(raw ?? {});
}

function parsePayloadForWire(text: string, encrypted: boolean): unknown {
  if (encrypted) return text;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

async function allocateNextSeq(env: Env, uid: string): Promise<number> {
  await env.DB.prepare(
    `INSERT INTO user_seq (uid, seq) VALUES (?, 1)
     ON CONFLICT(uid) DO UPDATE SET seq = seq + 1`,
  )
    .bind(uid)
    .run();
  const row = await env.DB.prepare("SELECT seq FROM user_seq WHERE uid = ?")
    .bind(uid)
    .first<{ seq: number }>();
  return Number(row?.seq ?? 1);
}

async function resolvePolicy(env: Env, uid: string, now: number): Promise<SyncPolicy> {
  const ent = await env.DB.prepare(
    "SELECT lifetime_owned, pro_until, trial_ends_at FROM entitlements WHERE uid = ?",
  )
    .bind(uid)
    .first<{
      lifetime_owned: number;
      pro_until: number | null;
      trial_ends_at: number | null;
    }>();

  const hasFull =
    !!ent &&
    (ent.lifetime_owned === 1 ||
      (typeof ent.pro_until === "number" && ent.pro_until > now) ||
      (typeof ent.trial_ends_at === "number" && ent.trial_ends_at > now));

  if (hasFull) {
    return {
      mode: "full",
      debounceMs: 2500,
      intervalSec: 30,
      flushOnBackground: true,
      liveShoppingWs: true,
    };
  }
  return {
    mode: "lite",
    debounceMs: 1500,
    intervalSec: 300,
    flushOnBackground: true,
    liveShoppingWs: false,
  };
}

export async function handleSync(
  request: Request,
  env: Env,
  user: AuthUser,
): Promise<Response> {
  let body: {
    cursorSeq?: unknown;
    sharedCursorMs?: unknown;
    limit?: unknown;
    changes?: unknown;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return errorResponse("invalid_json", "Geçersiz JSON gövdesi", 400);
  }

  const cursorSeq =
    typeof body.cursorSeq === "number" &&
    Number.isFinite(body.cursorSeq) &&
    body.cursorSeq >= 0
      ? Math.floor(body.cursorSeq)
      : 0;
  const sharedCursorMs =
    typeof body.sharedCursorMs === "number" &&
    Number.isFinite(body.sharedCursorMs) &&
    body.sharedCursorMs >= 0
      ? Math.floor(body.sharedCursorMs)
      : 0;
  const limitRaw =
    typeof body.limit === "number" && Number.isFinite(body.limit)
      ? Math.floor(body.limit)
      : DEFAULT_PULL_LIMIT;
  const limit = Math.max(1, Math.min(limitRaw, MAX_PULL_LIMIT));

  const changesRaw = Array.isArray(body.changes) ? body.changes : [];
  if (changesRaw.length > MAX_CHANGES_PER_PUSH) {
    return errorResponse(
      "too_many_changes",
      `Tek istekte en fazla ${MAX_CHANGES_PER_PUSH} değişiklik gönderilebilir`,
      400,
    );
  }

  const now = nowMs(env);
  const applied: Array<{
    kind: string;
    id: string;
    version: number;
    seq: number;
    updatedAt: number;
    deletedAt: number | null;
  }> = [];
  const conflicts: Array<{
    kind: string;
    id: string;
    clientBaseVersion: number;
    serverVersion: number;
    serverSeq: number;
    serverUpdatedAt: number;
    serverDeletedAt: number | null;
    serverEncrypted: boolean;
    serverPayload: unknown;
  }> = [];

  for (const item of changesRaw) {
    if (!item || typeof item !== "object") {
      return errorResponse("invalid_change", "Değişiklik nesnesi geçersiz", 400);
    }
    const c = item as IncomingSyncChange;
    const kind = typeof c.kind === "string" ? c.kind.trim() : "";
    const id = typeof c.id === "string" ? c.id.trim() : "";
    if (!ALLOWED_ENTITY_KINDS.has(kind) || !ENTITY_ID_RE.test(id)) {
      return errorResponse(
        "invalid_entity",
        `Geçersiz kayıt türü/kimliği: ${kind}/${id}`,
        400,
      );
    }
    const baseVersion =
      typeof c.baseVersion === "number" &&
      Number.isFinite(c.baseVersion) &&
      c.baseVersion >= 0
        ? Math.floor(c.baseVersion)
        : 0;
    const encrypted = c.encrypted === true;
    const deleted = c.deleted === true;
    const payloadStr = serializePayload(c.payload);
    if (new TextEncoder().encode(payloadStr).byteLength > MAX_ENTITY_PAYLOAD_BYTES) {
      return errorResponse(
        "payload_too_large",
        `Kayıt gövdesi 512 KB sınırını aşıyor (${kind}/${id})`,
        413,
      );
    }

    const existing = await env.DB.prepare(
      `SELECT uid, kind, id, seq, version, updated_at, deleted_at, encrypted, payload
       FROM entities WHERE uid = ? AND kind = ? AND id = ?`,
    )
      .bind(user.uid, kind, id)
      .first<SyncEntityRow>();

    if (!existing) {
      const seq = await allocateNextSeq(env, user.uid);
      const deletedAt = deleted ? now : null;
      await env.DB.prepare(
        `INSERT INTO entities
           (uid, kind, id, seq, version, updated_at, deleted_at, encrypted, payload)
         VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)`,
      )
        .bind(
          user.uid,
          kind,
          id,
          seq,
          now,
          deletedAt,
          encrypted ? 1 : 0,
          payloadStr,
        )
        .run();
      applied.push({
        kind,
        id,
        version: 1,
        seq,
        updatedAt: now,
        deletedAt,
      });
      continue;
    }

    if (baseVersion !== existing.version) {
      conflicts.push({
        kind,
        id,
        clientBaseVersion: baseVersion,
        serverVersion: existing.version,
        serverSeq: existing.seq,
        serverUpdatedAt: existing.updated_at,
        serverDeletedAt: existing.deleted_at,
        serverEncrypted: existing.encrypted === 1,
        serverPayload: parsePayloadForWire(
          existing.payload,
          existing.encrypted === 1,
        ),
      });
      continue;
    }

    const nextVersion = existing.version + 1;
    const seq = await allocateNextSeq(env, user.uid);
    const deletedAt = deleted ? now : null;
    await env.DB.prepare(
      `UPDATE entities
       SET seq = ?, version = ?, updated_at = ?, deleted_at = ?, encrypted = ?, payload = ?
       WHERE uid = ? AND kind = ? AND id = ?`,
    )
      .bind(
        seq,
        nextVersion,
        now,
        deletedAt,
        encrypted ? 1 : 0,
        payloadStr,
        user.uid,
        kind,
        id,
      )
      .run();
    applied.push({
      kind,
      id,
      version: nextVersion,
      seq,
      updatedAt: now,
      deletedAt,
    });
  }

  // Delta pull: yalnız `seq > cursorSeq` olan kayıtlar (30 dk kapalı kaldıktan
  // sonra açılışta değişmeyen notlar HİÇ okunmaz!).
  const pulled = await env.DB.prepare(
    `SELECT uid, kind, id, seq, version, updated_at, deleted_at, encrypted, payload
     FROM entities
     WHERE uid = ? AND seq > ?
     ORDER BY seq ASC
     LIMIT ?`,
  )
    .bind(user.uid, cursorSeq, limit + 1)
    .all<SyncEntityRow>();

  const hasMore = pulled.results.length > limit;
  const slice = hasMore ? pulled.results.slice(0, limit) : pulled.results;
  const maxPulledSeq =
    slice.length > 0 ? slice[slice.length - 1].seq : cursorSeq;

  // Aktif paylaşılan kayıtların deltası (ortak not / klasör).
  const sharedRes = await env.DB.prepare(
    `SELECT e.uid, e.kind, e.id, e.seq, e.version, e.updated_at, e.deleted_at,
            e.encrypted, e.payload, s.role AS share_role
     FROM shares s
     INNER JOIN entities e
       ON e.uid = s.owner_uid
      AND e.kind = s.entity_kind
      AND e.id = s.entity_id
     WHERE s.member_uid = ? AND s.status = 'active' AND e.updated_at > ?
     ORDER BY e.updated_at ASC
     LIMIT 100`,
  )
    .bind(user.uid, sharedCursorMs)
    .all<SyncEntityRow & { share_role: string }>();

  let nextSharedCursorMs = sharedCursorMs;
  const sharedEntities = sharedRes.results.map((r) => {
    if (r.updated_at > nextSharedCursorMs) nextSharedCursorMs = r.updated_at;
    return {
      ownerUid: r.uid,
      kind: r.kind,
      id: r.id,
      role: r.share_role,
      version: r.version,
      updatedAt: r.updated_at,
      deletedAt: r.deleted_at,
      encrypted: r.encrypted === 1,
      payload: parsePayloadForWire(r.payload, r.encrypted === 1),
    };
  });

  const policy = await resolvePolicy(env, user.uid, now);

  return jsonResponse({
    cursorSeq: maxPulledSeq,
    sharedCursorMs: nextSharedCursorMs,
    serverTimeMs: now,
    hasMore,
    applied,
    conflicts,
    entities: slice.map((r) => ({
      kind: r.kind,
      id: r.id,
      seq: r.seq,
      version: r.version,
      updatedAt: r.updated_at,
      deletedAt: r.deleted_at,
      encrypted: r.encrypted === 1,
      payload: parsePayloadForWire(r.payload, r.encrypted === 1),
    })),
    sharedEntities,
    policy,
  });
}

/** Paylaşım kaydı ekleme/güncelleme (`POST /v1/shares`). */
export async function handleUpsertShare(
  request: Request,
  env: Env,
  user: AuthUser,
): Promise<Response> {
  let body: {
    entityKind?: string;
    entityId?: string;
    memberUid?: string;
    role?: string;
    status?: string;
  };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return errorResponse("invalid_json", "Geçersiz JSON gövdesi", 400);
  }
  const kind = body.entityKind === "folder" ? "folder" : "note";
  const entityId = (body.entityId ?? "").trim();
  const memberUid = (body.memberUid ?? "").trim();
  const role =
    body.role === "read" || body.role === "write" || body.role === "both"
      ? body.role
      : "both";
  const status = body.status === "pending" ? "pending" : "active";

  if (!ENTITY_ID_RE.test(entityId) || !memberUid || memberUid === user.uid) {
    return errorResponse("invalid_share", "Geçersiz paylaşım parametreleri", 400);
  }

  const shareId = `${user.uid}:${kind}:${entityId}:${memberUid}`;
  const now = nowMs(env);
  await env.DB.prepare(
    `INSERT INTO shares (share_id, owner_uid, entity_kind, entity_id, member_uid, role, status, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(share_id) DO UPDATE SET role = excluded.role, status = excluded.status, updated_at = excluded.updated_at`,
  )
    .bind(shareId, user.uid, kind, entityId, memberUid, role, status, now)
    .run();

  return jsonResponse({ shareId, status, updatedAt: now });
}

/** 30 günü aşan soft-delete kayıtlarını temizler (gece cron görevi). */
export async function purgeExpiredSoftDeletes(
  env: Env,
  retentionDays = 30,
): Promise<number> {
  const cutoff = nowMs(env) - retentionDays * 24 * 60 * 60 * 1000;
  const res = await env.DB.prepare(
    "DELETE FROM entities WHERE deleted_at IS NOT NULL AND deleted_at < ?",
  )
    .bind(cutoff)
    .run();
  return Number(res.meta?.changes ?? 0);
}
