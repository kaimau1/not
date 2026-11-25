-- Notlar Cloudflare D1 Şeması (PLAN §5.4, Faz 2)
-- Tek tablo (entities) + monotonik kullanıcı içi seq = 33 Firestore dinleyicisi
-- yerine tek delta sorgusu (POST /v1/sync).

-- 1. Tüm kullanıcı verisi (note, folder, event, task, task_list, routine, pref, shop_price, shop_meta, friend)
CREATE TABLE IF NOT EXISTS entities (
  uid         TEXT NOT NULL,
  kind        TEXT NOT NULL,
  id          TEXT NOT NULL,
  seq         INTEGER NOT NULL,
  version     INTEGER NOT NULL DEFAULT 1,
  updated_at  INTEGER NOT NULL,
  deleted_at  INTEGER,
  encrypted   INTEGER NOT NULL DEFAULT 0,
  payload     TEXT NOT NULL,
  PRIMARY KEY (uid, kind, id)
);
CREATE INDEX IF NOT EXISTS idx_entities_sync ON entities (uid, seq);
CREATE INDEX IF NOT EXISTS idx_entities_deleted ON entities (deleted_at) WHERE deleted_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_entities_updated ON entities (uid, kind, updated_at);

-- Kullanıcı içi monotonik senkron sayacı (kayıtlar silinse de asla geriye gitmez).
CREATE TABLE IF NOT EXISTS user_seq (
  uid         TEXT PRIMARY KEY,
  seq         INTEGER NOT NULL DEFAULT 0
);

-- 2. Ortak not / ortak alışveriş listesi / klasör paylaşımı
CREATE TABLE IF NOT EXISTS shares (
  share_id    TEXT PRIMARY KEY,
  owner_uid   TEXT NOT NULL,
  entity_kind TEXT NOT NULL,
  entity_id   TEXT NOT NULL,
  member_uid  TEXT NOT NULL,
  role        TEXT NOT NULL,
  status      TEXT NOT NULL,
  updated_at  INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_shares_member ON shares (member_uid, status);
CREATE INDEX IF NOT EXISTS idx_shares_entity ON shares (owner_uid, entity_kind, entity_id);

-- 3. Haklar & Decisions Token Sayacı (purchase_token_hash bazlı — hesap silmede sıfırlanamaz!)
CREATE TABLE IF NOT EXISTS entitlements (
  uid                 TEXT PRIMARY KEY,
  lifetime_owned      INTEGER NOT NULL DEFAULT 0,
  lifetime_token_hash TEXT,
  extra_decisions     INTEGER NOT NULL DEFAULT 0,
  extra_tokens        INTEGER NOT NULL DEFAULT 0,
  pro_until           INTEGER,
  trial_ends_at       INTEGER,
  updated_at          INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS decision_usage (
  token_hash          TEXT PRIMARY KEY,
  calls_used          INTEGER NOT NULL DEFAULT 0,
  tokens_used         INTEGER NOT NULL DEFAULT 0,
  pack_calls_used     INTEGER NOT NULL DEFAULT 0,
  pack_tokens_used    INTEGER NOT NULL DEFAULT 0,
  updated_at          INTEGER NOT NULL
);

-- Satın alma belirteci sahipliği (çapraz hesap hırsızlığı koruması + RTDN eşlemesi)
CREATE TABLE IF NOT EXISTS purchase_tokens (
  token_hash          TEXT PRIMARY KEY,
  uid                 TEXT NOT NULL,
  product_id          TEXT NOT NULL,
  status              TEXT NOT NULL,
  updated_at          INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_purchase_tokens_uid ON purchase_tokens (uid);

-- Tüketilebilir +1.000 Akıllı Karar Paketi idempotency tablosu (aynı token iki kez eklenmez)
CREATE TABLE IF NOT EXISTS credited_pack_tokens (
  token_hash          TEXT PRIMARY KEY,
  uid                 TEXT NOT NULL,
  calls_added         INTEGER NOT NULL,
  tokens_added        INTEGER NOT NULL,
  created_at          INTEGER NOT NULL
);

-- 4. Kullanıcı arama dizini (indeksli, 1.000 belge taraması yok!)
CREATE TABLE IF NOT EXISTS user_directory (
  uid          TEXT PRIMARY KEY,
  email_lower  TEXT UNIQUE NOT NULL,
  name         TEXT NOT NULL,
  name_lower   TEXT NOT NULL,
  discoverable INTEGER NOT NULL DEFAULT 1,
  updated_at   INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_user_name ON user_directory (name_lower);

-- 5. R2 ortak medya kotası (kişi başı 250 MB, $0 egress)
CREATE TABLE IF NOT EXISTS r2_quota (
  uid          TEXT PRIMARY KEY,
  bytes_used   INTEGER NOT NULL DEFAULT 0,
  object_count INTEGER NOT NULL DEFAULT 0,
  updated_at   INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS media_objects (
  object_key   TEXT PRIMARY KEY,
  owner_uid    TEXT NOT NULL,
  note_id      TEXT,
  content_type TEXT NOT NULL,
  size_bytes   INTEGER NOT NULL,
  created_at   INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_media_owner ON media_objects (owner_uid);
