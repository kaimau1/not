/**
 * R2 ORTAK MEDYA DEPOSU (`PUT /v1/media/:key`, `GET /v1/media/:key`,
 * `DELETE /v1/media/:key`, PLAN §5.2 & Faz 2).
 *
 * - Kişisel büyük ekler Google Drive'da kalır; R2 yalnızca ortak notlardaki
 *   görseller / sesler / küçük PDF'ler için ($0 egress).
 * - Kullanıcı başına **250 MB** (`MAX_USER_QUOTA_BYTES`) sert kota `r2_quota`
 *   tablosunda izlenir; tek dosya tavanı **25 MB**.
 * - Anahtar biçimi: `<uid>/<dosya_yolu>` (yol geçişi `..` engellenir).
 *   Yalnız sahibi yükler/siler; aktif paylaşım üyesi (`shares` + `note_id`)
 *   okuyabilir.
 */

import {
  type AuthUser,
  type Env,
  errorResponse,
  jsonResponse,
  nowMs,
} from "./types.ts";

export const MAX_USER_QUOTA_BYTES = 250 * 1024 * 1024; // 250 MB
export const MAX_OBJECT_BYTES = 25 * 1024 * 1024; // 25 MB

const ALLOWED_CONTENT_TYPE_PREFIXES = [
  "image/",
  "audio/",
  "application/pdf",
  "application/octet-stream",
];

function sanitizeMediaKey(raw: string): string | null {
  let decoded: string;
  try {
    decoded = decodeURIComponent(raw).replace(/^\/+/, "");
  } catch {
    return null;
  }
  if (!decoded || decoded.length > 256) return null;
  if (decoded.includes("..") || decoded.includes("\\") || decoded.includes("\0")) {
    return null;
  }
  const parts = decoded.split("/");
  if (parts.length < 2 || parts.some((p) => !p || p === ".")) return null;
  return decoded;
}

function isAllowedContentType(ct: string): boolean {
  const lower = ct.toLowerCase().split(";")[0].trim();
  return ALLOWED_CONTENT_TYPE_PREFIXES.some((p) => lower.startsWith(p));
}

export async function handleMediaPut(
  request: Request,
  env: Env,
  user: AuthUser,
  rawKey: string,
): Promise<Response> {
  if (!env.MEDIA) {
    return errorResponse("media_unconfigured", "R2 kovası bağlı değil", 503);
  }
  const key = sanitizeMediaKey(rawKey);
  if (!key || !key.startsWith(`${user.uid}/`)) {
    return errorResponse(
      "forbidden_key",
      "Medya anahtarı kendi kullanıcı önekinizle (<uid>/...) başlamalı",
      403,
    );
  }

  const contentType =
    request.headers.get("content-type")?.trim() || "application/octet-stream";
  if (!isAllowedContentType(contentType)) {
    return errorResponse(
      "unsupported_media_type",
      `Desteklenmeyen içerik türü: ${contentType}`,
      415,
    );
  }

  const bytes = await request.arrayBuffer();
  const size = bytes.byteLength;
  if (size <= 0) {
    return errorResponse("empty_body", "Boş dosya yüklenemez", 400);
  }
  if (size > MAX_OBJECT_BYTES) {
    return errorResponse(
      "object_too_large",
      `Tek medya nesnesi en fazla ${MAX_OBJECT_BYTES} bayt olabilir`,
      413,
    );
  }

  const existing = await env.DB.prepare(
    "SELECT size_bytes FROM media_objects WHERE object_key = ?",
  )
    .bind(key)
    .first<{ size_bytes: number }>();

  const quota = await env.DB.prepare(
    "SELECT bytes_used, object_count FROM r2_quota WHERE uid = ?",
  )
    .bind(user.uid)
    .first<{ bytes_used: number; object_count: number }>();

  const currentUsed = Number(quota?.bytes_used ?? 0);
  const previousSize = Number(existing?.size_bytes ?? 0);
  const delta = size - previousSize;
  const projected = currentUsed + delta;

  if (projected > MAX_USER_QUOTA_BYTES) {
    return errorResponse(
      "quota_exceeded",
      "250 MB ortak medya kotası aşıldı; eski ekleri temizleyin veya Drive kullanın",
      413,
      {
        bytesUsed: currentUsed,
        quotaBytes: MAX_USER_QUOTA_BYTES,
        requestedBytes: size,
      },
    );
  }

  const noteId = request.headers.get("x-notlar-note-id")?.trim() || null;
  await env.MEDIA.put(key, bytes, {
    httpMetadata: { contentType },
    customMetadata: {
      ownerUid: user.uid,
      ...(noteId ? { noteId } : {}),
    },
  });

  const now = nowMs(env);
  const countDelta = existing ? 0 : 1;
  await env.DB.prepare(
    `INSERT INTO media_objects (object_key, owner_uid, note_id, content_type, size_bytes, created_at)
     VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(object_key) DO UPDATE SET
       note_id = excluded.note_id,
       content_type = excluded.content_type,
       size_bytes = excluded.size_bytes,
       created_at = excluded.created_at`,
  )
    .bind(key, user.uid, noteId, contentType, size, now)
    .run();

  await env.DB.prepare(
    `INSERT INTO r2_quota (uid, bytes_used, object_count, updated_at)
     VALUES (?, ?, ?, ?)
     ON CONFLICT(uid) DO UPDATE SET
       bytes_used = MAX(0, bytes_used + ?),
       object_count = MAX(0, object_count + ?),
       updated_at = excluded.updated_at`,
  )
    .bind(user.uid, Math.max(0, projected), existing ? 1 : 1, now, delta, countDelta)
    .run();

  return jsonResponse(
    {
      ok: true,
      key,
      sizeBytes: size,
      bytesUsed: Math.max(0, projected),
      quotaBytes: MAX_USER_QUOTA_BYTES,
    },
    201,
  );
}

export async function handleMediaGet(
  env: Env,
  user: AuthUser,
  rawKey: string,
): Promise<Response> {
  if (!env.MEDIA) {
    return errorResponse("media_unconfigured", "R2 kovası bağlı değil", 503);
  }
  const key = sanitizeMediaKey(rawKey);
  if (!key) {
    return errorResponse("invalid_key", "Geçersiz medya anahtarı", 400);
  }

  const meta = await env.DB.prepare(
    "SELECT owner_uid, note_id, content_type FROM media_objects WHERE object_key = ?",
  )
    .bind(key)
    .first<{ owner_uid: string; note_id: string | null; content_type: string }>();

  if (!meta) {
    return errorResponse("not_found", "Medya bulunamadı", 404);
  }

  if (meta.owner_uid !== user.uid) {
    // Ortak not paylaşımı varsa okuma izni ver.
    let shared = false;
    if (meta.note_id) {
      const share = await env.DB.prepare(
        `SELECT share_id FROM shares
         WHERE owner_uid = ? AND entity_id = ? AND member_uid = ? AND status = 'active'
         LIMIT 1`,
      )
        .bind(meta.owner_uid, meta.note_id, user.uid)
        .first<{ share_id: string }>();
      shared = !!share;
    }
    if (!shared) {
      return errorResponse("forbidden", "Bu medyaya erişim izniniz yok", 403);
    }
  }

  const obj = await env.MEDIA.get(key);
  if (!obj) {
    return errorResponse("not_found", "Medya nesnesi R2'de bulunamadı", 404);
  }
  const body = await obj.arrayBuffer();
  return new Response(body, {
    status: 200,
    headers: {
      "content-type": obj.httpMetadata?.contentType || meta.content_type,
      "cache-control": "private, max-age=3600",
    },
  });
}

export async function handleMediaDelete(
  env: Env,
  user: AuthUser,
  rawKey: string,
): Promise<Response> {
  if (!env.MEDIA) {
    return errorResponse("media_unconfigured", "R2 kovası bağlı değil", 503);
  }
  const key = sanitizeMediaKey(rawKey);
  if (!key || !key.startsWith(`${user.uid}/`)) {
    return errorResponse("forbidden_key", "Yalnız kendi medyanızı silebilirsiniz", 403);
  }

  const meta = await env.DB.prepare(
    "SELECT size_bytes FROM media_objects WHERE object_key = ? AND owner_uid = ?",
  )
    .bind(key, user.uid)
    .first<{ size_bytes: number }>();

  await env.MEDIA.delete(key);
  if (meta) {
    const now = nowMs(env);
    await env.DB.prepare("DELETE FROM media_objects WHERE object_key = ?")
      .bind(key)
      .run();
    await env.DB.prepare(
      `UPDATE r2_quota
       SET bytes_used = MAX(0, bytes_used - ?),
           object_count = MAX(0, object_count - 1),
           updated_at = ?
       WHERE uid = ?`,
    )
      .bind(meta.size_bytes, now, user.uid)
      .run();
  }

  const quota = await env.DB.prepare(
    "SELECT bytes_used FROM r2_quota WHERE uid = ?",
  )
    .bind(user.uid)
    .first<{ bytes_used: number }>();

  return jsonResponse({
    ok: true,
    deleted: !!meta,
    bytesUsed: Number(quota?.bytes_used ?? 0),
    quotaBytes: MAX_USER_QUOTA_BYTES,
  });
}
