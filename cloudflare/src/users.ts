/**
 * KULLANICI ARAMA DİZİNİ (`PUT /v1/users/me`, `GET /v1/users/search`, PLAN §5.4).
 *
 * Firestore'da 1.000 belge tarayan `searchUsers` yerine D1 indeksli
 * (`email_lower` UNIQUE + `idx_user_name` B-Tree) milisaniyelik arama.
 *  - Anonim oturum arama yapamaz.
 *  - `@` içeren sorgu: TAM e-posta eşleşmesi (`email_lower = ?`).
 *  - Diğer sorgular: en az 3 karakterli ad öneki (`discoverable = 1` ve
 *    `name_lower >= prefix AND name_lower < prefix + '\uffff'`, en fazla 15 sonuç).
 */

import {
  type AuthUser,
  type Env,
  errorResponse,
  jsonResponse,
  nowMs,
} from "./types.ts";

export const MAX_SEARCH_RESULTS = 15;
export const MIN_SEARCH_LEN = 3;

export async function handleUpsertUserDirectory(
  request: Request,
  env: Env,
  user: AuthUser,
): Promise<Response> {
  if (user.isAnonymous) {
    return errorResponse("anonymous_not_allowed", "Anonim hesap dizine yazılamaz", 403);
  }
  let body: { name?: unknown; email?: unknown; discoverable?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return errorResponse("invalid_json", "Geçersiz JSON gövdesi", 400);
  }
  const email = (
    (typeof body.email === "string" && body.email.trim()) ||
    user.email ||
    ""
  ).trim();
  if (!email || !email.includes("@")) {
    return errorResponse("invalid_email", "Geçerli e-posta gerekli", 400);
  }
  const name = (
    (typeof body.name === "string" && body.name.trim()) ||
    user.name ||
    email
  )
    .trim()
    .slice(0, 120);
  const discoverable = body.discoverable === false ? 0 : 1;
  const now = nowMs(env);

  await env.DB.prepare(
    `INSERT INTO user_directory (uid, email_lower, name, name_lower, discoverable, updated_at)
     VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(uid) DO UPDATE SET
       email_lower = excluded.email_lower,
       name = excluded.name,
       name_lower = excluded.name_lower,
       discoverable = excluded.discoverable,
       updated_at = excluded.updated_at`,
  )
    .bind(
      user.uid,
      email.toLowerCase(),
      name,
      name.toLowerCase(),
      discoverable,
      now,
    )
    .run();

  return jsonResponse({ ok: true, uid: user.uid, discoverable: discoverable === 1 });
}

interface UserDirectoryRow {
  uid: string;
  email_lower: string;
  name: string;
}

export async function handleSearchUsers(
  request: Request,
  env: Env,
  user: AuthUser,
): Promise<Response> {
  if (user.isAnonymous) {
    return errorResponse("anonymous_not_allowed", "Anonim oturumla arama yapılamaz", 403);
  }
  const url = new URL(request.url);
  const rawQuery = (url.searchParams.get("q") ?? "").trim();
  if (rawQuery.length < MIN_SEARCH_LEN || rawQuery.length > 120) {
    return jsonResponse({ results: [] });
  }
  const qLower = rawQuery.toLowerCase();

  let rows: UserDirectoryRow[];
  if (qLower.includes("@")) {
    const res = await env.DB.prepare(
      `SELECT uid, email_lower, name
       FROM user_directory
       WHERE email_lower = ? AND uid != ?
       LIMIT 1`,
    )
      .bind(qLower, user.uid)
      .all<UserDirectoryRow>();
    rows = res.results;
  } else {
    const upper = `${qLower}\uffff`;
    const res = await env.DB.prepare(
      `SELECT uid, email_lower, name
       FROM user_directory
       WHERE discoverable = 1
         AND name_lower >= ?
         AND name_lower < ?
         AND uid != ?
       ORDER BY name_lower ASC
       LIMIT ?`,
    )
      .bind(qLower, upper, user.uid, MAX_SEARCH_RESULTS)
      .all<UserDirectoryRow>();
    rows = res.results;
  }

  return jsonResponse({
    results: rows.map((r) => ({
      uid: r.uid,
      name: r.name,
      email: r.email_lower,
    })),
  });
}

/**
 * Kullanıcı verisinin kalıcı silinmesi (`DELETE /v1/users/me`).
 * R2 eklerini, D1 varlık/paylaşım/dizin/yetki satırlarını siler;
 * kötüye kullanımı engellemek için kota/token sayaçlarını korur.
 */
export async function handleDeleteUser(
  env: Env,
  user: AuthUser,
): Promise<Response> {
  const mediaRows = await env.DB.prepare(
    "SELECT object_key FROM media_objects WHERE owner_uid = ?",
  )
    .bind(user.uid)
    .all<{ object_key: string }>();

  if (env.MEDIA && mediaRows.results.length > 0) {
    await Promise.all(
      mediaRows.results.map((r) =>
        env.MEDIA!.delete(r.object_key).catch(() => {}),
      ),
    );
  }

  await env.DB.batch([
    env.DB.prepare("DELETE FROM media_objects WHERE owner_uid = ?").bind(
      user.uid,
    ),
    env.DB.prepare("DELETE FROM r2_quota WHERE uid = ?").bind(user.uid),
    env.DB.prepare("DELETE FROM entities WHERE uid = ?").bind(user.uid),
    env.DB.prepare("DELETE FROM user_seq WHERE uid = ?").bind(user.uid),
    env.DB.prepare(
      "DELETE FROM shares WHERE owner_uid = ? OR member_uid = ?",
    ).bind(user.uid, user.uid),
    env.DB.prepare("DELETE FROM user_directory WHERE uid = ?").bind(user.uid),
    env.DB.prepare("DELETE FROM entitlements WHERE uid = ?").bind(user.uid),
  ]);

  return jsonResponse({ ok: true, deletedUid: user.uid });
}
