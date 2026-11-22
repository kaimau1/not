/**
 * decide — Gemini Decisions API VEKİLİ (PLAN U8 KARAR, 2026-11-22).
 *
 * Kendi Gemini anahtarı OLMAYAN ücretli kullanıcının karar çağrısını
 * uygulamanın anahtarıyla yapar. Anahtar YALNIZ burada (Secret Manager:
 * `GEMINI_DECISIONS_KEY`), istemciye hiç inmez. Kota `decisions_util.js`.
 *
 * Maliyet korumaları: App Check zorunlu, giriş zorunlu (misafir yok), istek
 * süzülür (yalnız `gemini-decision-1`, girdi ≤ 8000 karakter, ≤ 60 soru),
 * hak İSTEKTEN ÖNCE işlemle ayrılır (aynı anda iki çağrı aynı hakkı
 * harcayamaz), yukarı akış hatasında iade, `maxInstances` tavanı, 5 sn zaman
 * aşımı. Bütçe tavanı/uyarısı Google Cloud konsolunda (KONTROL_LISTEM).
 *
 * YALNIZ Play projesinde bağlanır (index.js): kişisel projede gizli anahtar
 * yok, deploy kırılmasın.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const u = require("./decisions_util");

const GEMINI_KEY = defineSecret("GEMINI_DECISIONS_KEY");
const ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/decisions";
const UPSTREAM_TIMEOUT_MS = 5000;

async function refundOne(ref, bucket) {
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const next = u.refund(snap.exists ? snap.data() : null, bucket, new Date());
    tx.set(ref, { ...next, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  });
}

exports.decide = onCall(
  {
    enforceAppCheck: true,
    secrets: [GEMINI_KEY],
    timeoutSeconds: 10,
    maxInstances: 5,
    memory: "256MiB",
  },
  async (request) => {
    const auth = request.auth;
    if (!auth || auth.token.firebase?.sign_in_provider === "anonymous") {
      throw new HttpsError("unauthenticated", "Giriş gerekli.");
    }
    const body = u.sanitizeRequest(request.data);
    if (!body) throw new HttpsError("invalid-argument", "Geçersiz istek.");

    const db = getFirestore();
    const usageRef = db.collection("decisionUsage").doc(auth.uid);
    const entRef = db.collection("entitlements").doc(auth.uid);
    let bucket;
    let left;
    await db.runTransaction(async (tx) => {
      const [ent, usage] = await Promise.all([tx.get(entRef), tx.get(usageRef)]);
      const now = new Date();
      const r = u.reserve(ent.exists ? ent.data() : null, usage.exists ? usage.data() : null, now);
      if (!r.ok) {
        throw new HttpsError("resource-exhausted", "Karar hakkı bitti.");
      }
      bucket = r.bucket;
      left = u.remaining(ent.exists ? ent.data() : null, r.usage, now);
      tx.set(usageRef, { ...r.usage, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    });

    let res;
    try {
      res = await fetch(ENDPOINT, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": GEMINI_KEY.value(),
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
      });
    } catch (e) {
      await refundOne(usageRef, bucket);
      throw new HttpsError("unavailable", "Karar servisine ulaşılamadı.");
    }
    if (!res.ok) {
      await refundOne(usageRef, bucket);
      // İçerik günlüğe YAZILMAZ: yalnız durum kodu.
      console.warn(`decide: yukarı akış ${res.status}`);
      // `resource-exhausted` YALNIZ "hak bitti" demek (istemci uzun susar);
      // yukarı akış 429'u geçici → `unavailable`.
      throw new HttpsError("unavailable", "Karar servisi şu an yanıt vermiyor.");
    }
    const data = await res.json();
    return { response: data, remaining: left };
  },
);
