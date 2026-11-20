/**
 * PLAY BILLING SUNUCUSU — PLAN §1.5 PL6. YALNIZ Play projesinde yayınlanır:
 * `index.js` bu dosyayı `PLAY_PACKAGE_NAME` ortam değişkeni varsa bağlar
 * (`functions/.env.<play-proje-kimliği>`); kişisel proje `notlar-kaimau`
 * deploy'unda hiçbiri yok. Kurulum adımları `docs/play_hazirlik.md`.
 *
 * - `verifyPurchase` (onCall): istemci satın alınca / geri yükleyince
 *   belirteci gönderir → Google Play Developer API ile doğrulanır →
 *   `entitlements/{uid}` yazılır (yazan YALNIZ burası; kurallar istemciye
 *   kapalı) → onaylanmamışsa onaylanır (3 gün içinde onaylanmayan satın
 *   almayı Play iade eder).
 * - `playRtdn` (Pub/Sub): yenileme / iptal / askı / iade bildirimleri aynı
 *   belgeyi günceller. Durum hep API'den yeniden okunur.
 *
 * GİZLİ ANAHTAR YOK: API'ye Functions'ın çalışma hizmet hesabıyla (ADC)
 * gidilir; o hesap Play Console → Kullanıcılar ve izinler'e eklenir.
 *
 * `purchaseTokens/{sha256(belirteç)}` = {uid, productId}: belirteç hangi
 * hesaba bağlı (kurallarda eşleşme yok → istemciye tamamen kapalı). Başka
 * hesaba bağlı belirteç reddedilir (aile/arkadaşla hesap paylaşımı ya da
 * çalınmış belirteç); RTDN uid'i buradan bulur.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onMessagePublished } = require("firebase-functions/v2/pubsub");
const logger = require("firebase-functions/logger");
const { getFirestore, Timestamp, FieldValue } = require("firebase-admin/firestore");
const { GoogleAuth } = require("google-auth-library");
const u = require("./billing_util");

const PACKAGE = process.env.PLAY_PACKAGE_NAME;
const RTDN_TOPIC = process.env.PLAY_RTDN_TOPIC || "play-rtdn";
const API =
  "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" +
  `${encodeURIComponent(PACKAGE || "")}/purchases`;
const googleAuth = new GoogleAuth({
  scopes: ["https://www.googleapis.com/auth/androidpublisher"],
});

const db = () => getFirestore();
const enc = encodeURIComponent;

async function play(path, method = "GET") {
  const client = await googleAuth.getClient();
  const res = await client.request({
    url: `${API}/${path}`,
    method,
    ...(method === "POST" ? { data: {} } : {}),
  });
  return res.data;
}

/** 400/404/410: belirteç geçersiz ya da bu pakete ait değil (kalıcı). */
const isInvalidToken = (e) => {
  const status = (e && (e.status || (e.response && e.response.status))) || 0;
  return status === 400 || status === 404 || status === 410;
};

const toDate = (v) => (v && typeof v.toDate === "function" ? v.toDate() : v);
const toStore = (v) => (v instanceof Date ? Timestamp.fromDate(v) : v);

/** Belirtecin bağlı olduğu uid (yoksa null). */
async function ownerOf(token) {
  if (!token) return null;
  const snap = await db().doc(`purchaseTokens/${u.tokenKey(token)}`).get();
  return snap.exists ? snap.data().uid : null;
}

/** Belirteci uid'e bağlar; başka hesaba bağlıysa `permission-denied`. */
async function bindToken(token, uid, productId) {
  const ref = db().doc(`purchaseTokens/${u.tokenKey(token)}`);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) {
      if (snap.data().uid !== uid) {
        throw new HttpsError("permission-denied", "other-account");
      }
      return;
    }
    tx.create(ref, { uid, productId, createdAt: FieldValue.serverTimestamp() });
  });
}

/** Hak belgesine değişikliği işler (işlem içinde) → istemciye dönüş. */
async function applyChange(uid, change) {
  const ref = db().doc(`entitlements/${uid}`);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const prev = {};
    for (const [k, v] of Object.entries(snap.exists ? snap.data() : {})) {
      prev[k] = toDate(v);
    }
    const next = u.mergeEntitlement(prev, change, new Date());
    const doc = { updatedAt: FieldValue.serverTimestamp() };
    for (const [k, v] of Object.entries(next)) doc[k] = toStore(v);
    tx.set(ref, doc, { merge: true });
    return {
      tier: next.tier,
      proUntil: next.proUntil ? next.proUntil.getTime() : null,
      lifetimeOwned: next.lifetimeOwned,
    };
  });
}

/**
 * Play'den okur, belirteci uid'e bağlar ([bind]; doğrulanmamış belirteç
 * HİÇ yazılmaz), hakkı yazar, gerekirse onaylar.
 */
async function syncPurchase(uid, productId, token, bind = false) {
  if (productId === u.PRO_SUBSCRIPTION) {
    const s = u.readSubscription(
      await play(`subscriptionsv2/tokens/${enc(token)}`),
      new Date(),
    );
    if (!s) throw new HttpsError("invalid-argument", "wrong-product");
    if (s.accountTag && s.accountTag !== u.accountTag(uid)) {
      throw new HttpsError("permission-denied", "other-account");
    }
    if (bind) await bindToken(token, uid, productId);
    const result = await applyChange(uid, {
      sub: { tokenKey: u.tokenKey(token), paidUntil: s.paidUntil },
    });
    if (s.needsAck) {
      await play(
        `subscriptions/${u.PRO_SUBSCRIPTION}/tokens/${enc(token)}:acknowledge`,
        "POST",
      ).catch((e) => logger.warn("abonelik onaylanamadı", e.message));
    }
    return { ...result, pending: s.pending };
  }
  const p = u.readProduct(
    await play(`products/${u.LIFETIME_PRODUCT}/tokens/${enc(token)}`),
  );
  if (p.accountTag && p.accountTag !== u.accountTag(uid)) {
    throw new HttpsError("permission-denied", "other-account");
  }
  if (bind) await bindToken(token, uid, productId);
  // Bekleyen ödeme hakkı ne verir ne alır (onaylanınca RTDN gelir).
  const result = p.pending
    ? await applyChange(uid, {})
    : await applyChange(uid, {
        lifetime: { tokenKey: u.tokenKey(token), owned: p.owned },
      });
  if (p.needsAck) {
    await play(
      `products/${u.LIFETIME_PRODUCT}/tokens/${enc(token)}:acknowledge`,
      "POST",
    ).catch((e) => logger.warn("ömür boyu onaylanamadı", e.message));
  }
  return { ...result, pending: p.pending };
}

exports.verifyPurchase = onCall({ enforceAppCheck: true }, async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "sign-in");
  const provider =
    auth.token && auth.token.firebase && auth.token.firebase.sign_in_provider;
  // Misafir hesap kaybolabilir (cihaz değişimi): satın alma ona bağlanmaz.
  if (provider === "anonymous") {
    throw new HttpsError("permission-denied", "guest");
  }
  const data = request.data || {};
  const productId = data.productId;
  const token = data.purchaseToken;
  if (
    (productId !== u.PRO_SUBSCRIPTION && productId !== u.LIFETIME_PRODUCT) ||
    typeof token !== "string" ||
    token.length < 10 ||
    token.length > 4096
  ) {
    throw new HttpsError("invalid-argument", "bad-request");
  }
  // Ucuz ön eleme; asıl bağlama Play doğruladıktan sonra, işlem içinde.
  const owner = await ownerOf(token);
  if (owner && owner !== auth.uid) {
    throw new HttpsError("permission-denied", "other-account");
  }
  try {
    return await syncPurchase(auth.uid, productId, token, true);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    if (isInvalidToken(e)) {
      throw new HttpsError("invalid-argument", "invalid-token");
    }
    logger.error("verifyPurchase", e);
    throw new HttpsError("unavailable", "play-api");
  }
});

/**
 * RTDN. Play Console → Para kazanma kurulumu → konu
 * `projects/<proje>/topics/<PLAY_RTDN_TOPIC>`. Geçici hata fırlatılır
 * (Pub/Sub yeniden dener; işlem tekrarlansa da sonuç aynı); geçersiz
 * belirteç ve bağlanmamış belirteç yutulur (istemci açılışta geri yükleyip
 * bağlar).
 */
exports.playRtdn = onMessagePublished(
  { topic: RTDN_TOPIC, retry: true },
  async (event) => {
    let msg;
    try {
      msg = u.parseRtdn(event.data.message.json);
    } catch (e) {
      logger.warn("RTDN okunamadı", e.message);
      return;
    }
    if (!msg || msg.packageName !== PACKAGE) return;
    if (msg.kind === "test") {
      logger.info("RTDN deneme bildirimi geldi");
      return;
    }
    try {
      if (msg.kind === "voided") {
        const uid = await ownerOf(msg.token);
        if (!uid) return;
        await applyChange(
          uid,
          msg.subscription
            ? { sub: { tokenKey: u.tokenKey(msg.token), paidUntil: new Date() } }
            : { lifetime: { tokenKey: u.tokenKey(msg.token), owned: false } },
        );
        return;
      }
      if (msg.kind === "product") {
        if (msg.productId !== u.LIFETIME_PRODUCT) return;
        const uid = await ownerOf(msg.token);
        if (uid) await syncPurchase(uid, u.LIFETIME_PRODUCT, msg.token);
        return;
      }
      // Abonelik: plan değişimi / Play'den yeniden abonelikte belirteç yeni;
      // uid önceki belirteçten (`linkedPurchaseToken`) devralınır.
      let uid = await ownerOf(msg.token);
      if (!uid) {
        const res = await play(`subscriptionsv2/tokens/${enc(msg.token)}`);
        uid = await ownerOf(res && res.linkedPurchaseToken);
        if (!uid) {
          logger.info("RTDN: belirteç bir hesaba bağlı değil (henüz)");
          return;
        }
      }
      await syncPurchase(uid, u.PRO_SUBSCRIPTION, msg.token, true);
    } catch (e) {
      if (isInvalidToken(e) || e instanceof HttpsError) {
        logger.warn("RTDN atlandı", e.message);
        return;
      }
      throw e;
    }
  },
);
