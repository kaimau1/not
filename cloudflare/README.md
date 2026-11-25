# Notlar Cloudflare Senkron Arka Ucu (Faz 2)

Cloudflare **Workers + D1 + R2 + Durable Objects** tabanlı birleşik arka uç (`PLAN.md` §5).
Kişisel APK (`NOTLAR_PLAY=false`, `CLOUDFLARE_API_BASE` boş) Firestore'u bozmadan kullanmaya devam eder; Play sürümü (`--dart-define=NOTLAR_PLAY=true --dart-define=CLOUDFLARE_API_BASE=https://...`) bu Worker'a bağlanır.

## Uç Noktalar

| Yöntem & Yol | Amaç |
|---|---|
| `GET /v1/health` | Sağlık ve `aiKillSwitch` durumu |
| `POST /v1/sync` | Tek uç noktalı delta pull/push + iyimser sürüm çakışması + paylaşılan kayıtlar + Lite/Tam politika |
| `POST /v1/shares` | Ortak not/klasör paylaşım kaydı |
| `POST /v1/decide` | Decisions API (`gemini-decision-1`) vekili — 750 çağrı / 600K jeton çift kilit (`token_hash` bazlı) + `aiKillSwitch` + App Check |
| `GET /v1/entitlement` | Hak ve kalan karar kotası özeti |
| `POST /v1/billing/verify` | Google Play `lifetime` (50 TL) ve `decision_pack_1000` (30 TL, idempotent) doğrulaması |
| `POST /v1/billing/rtdn` | Google Play RTDN iade/iptal webhook'u |
| `PUT /v1/users/me` | D1 kullanıcı arama dizini güncelleme |
| `GET /v1/users/search` | D1 indeksli tam e-posta / ≥3 harf ad öneki araması |
| `PUT/GET/DELETE /v1/media/:key` | R2 ortak medya deposu (kişi başı 250 MB kota, \$0 egress) |
| `GET /v1/rooms/shopping/:noteId` | Durable Object canlı alışveriş listesi WebSocket odası |

## Kurulum ve Yayın

```bash
cd cloudflare
npm install
npx wrangler d1 create notlar-db        # dönen database_id'yi wrangler.toml'a yaz
npx wrangler r2 bucket create notlar-media
npm run migrate:remote

npx wrangler secret put GEMINI_API_KEY
npx wrangler secret put GOOGLE_PLAY_SA_JSON
npx wrangler secret put RTDN_SHARED_SECRET

npm run deploy
```

## Yerel Test (Gerçek SQLite Üzerinde)

Harici paket ya da internet gerektirmez (Node 22 yerleşik `node:sqlite` + `node:test`):

```bash
cd cloudflare
node --test test/*.test.ts
```
