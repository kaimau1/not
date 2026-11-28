/**
 * Ortak AI Havuzu sunucu geçidi — Notlar & Dosyalarım tek Google hesabı
 * (`uid`) üzerinden şirket Gemini anahtarını hiç istemciye indirmeden kullanır.
 *
 * Güvenlik sözleşmesi:
 *  - `GEMINI_SHARED_POOL_KEY` Secret Manager'da saklanır (repoda/istemcide YOK).
 *  - `enforceAppCheck: true` + anonim olmayan Firebase Auth şart.
 *  - Atomik ön kesinti (`reserveCredits`) + upstream hatasında otomatik iade.
 *  - Bakiye 0 ise upstream isteği ASLA yapılmaz.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const u = require("./ai_pool_util");

const SHARED_POOL_KEY = defineSecret("GEMINI_SHARED_POOL_KEY");
const UPSTREAM_TIMEOUT_MS = 25000;

function requireSignedIn(request) {
  const auth = request.auth;
  if (!auth || auth.token?.firebase?.sign_in_provider === "anonymous") {
    throw new HttpsError("unauthenticated", "Google hesabı gerekli.");
  }
  return auth.uid;
}

function extractGeminiText(data) {
  const parts =
    data &&
    Array.isArray(data.candidates) &&
    data.candidates[0] &&
    data.candidates[0].content &&
    data.candidates[0].content.parts;
  if (!Array.isArray(parts)) return "";
  return parts
    .map((p) => (p && typeof p.text === "string" ? p.text : ""))
    .join("")
    .trim();
}

async function refundPool(poolRef, cost) {
  const db = getFirestore();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(poolRef);
    const next = u.refundCredits(snap.exists ? snap.data() : null, cost);
    tx.set(
      poolRef,
      { ...next, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
}

exports.sharedAiPoolStatus = onCall(
  {
    enforceAppCheck: true,
    timeoutSeconds: 10,
    maxInstances: 10,
    memory: "256MiB",
  },
  async (request) => {
    const uid = requireSignedIn(request);
    const db = getFirestore();
    const poolRef = db.collection("sharedAiPool").doc(uid);
    const entRef = db.collection("entitlements").doc(uid);
    const state = await db.runTransaction(async (tx) => {
      const [poolSnap, entSnap] = await Promise.all([
        tx.get(poolRef),
        tx.get(entRef),
      ]);
      const now = new Date();
      const next = u.ensurePoolState(
        poolSnap.exists ? poolSnap.data() : null,
        entSnap.exists ? entSnap.data() : null,
        now,
      );
      tx.set(
        poolRef,
        { ...next, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return next;
    });
    return {
      balance: state.balance,
      starterGranted: state.starterGranted,
      lastProRefillMonth: state.lastProRefillMonth,
      apps: ["notlar", "dosya_okuyucu"],
    };
  },
);

exports.sharedAiPoolGenerate = onCall(
  {
    enforceAppCheck: true,
    secrets: [SHARED_POOL_KEY],
    timeoutSeconds: 30,
    maxInstances: 10,
    memory: "256MiB",
  },
  async (request) => {
    const uid = requireSignedIn(request);
    const sanitized = u.sanitizeGenerateRequest(request.data);
    if (!sanitized) {
      throw new HttpsError("invalid-argument", "Geçersiz AI isteği.");
    }
    const cost = u.costForRequest(sanitized);
    const db = getFirestore();
    const poolRef = db.collection("sharedAiPool").doc(uid);
    const entRef = db.collection("entitlements").doc(uid);
    const rateRef = db.collection("rateLimits").doc(uid);

    const reservation = await db.runTransaction(async (tx) => {
      const [poolSnap, entSnap, rateSnap] = await Promise.all([
        tx.get(poolRef),
        tx.get(entRef),
        tx.get(rateRef),
      ]);
      const r = u.reserveCredits(
        poolSnap.exists ? poolSnap.data() : null,
        entSnap.exists ? entSnap.data() : null,
        rateSnap.exists ? rateSnap.data() : null,
        cost,
        sanitized.appId,
        new Date(),
        sanitized.taskProfile || null,
      );
      if (!r.ok) {
        if (!poolSnap.exists) {
          tx.set(
            poolRef,
            { ...r.state, updatedAt: FieldValue.serverTimestamp() },
            { merge: true },
          );
        }
        return r;
      }
      tx.set(
        poolRef,
        { ...r.state, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      tx.set(
        rateRef,
        { ...r.rate, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return r;
    });

    if (!reservation.ok) {
      if (reservation.reason === "rate-limited") {
        throw new HttpsError("resource-exhausted", "rate-limited");
      }
      if (reservation.reason === "daily-quota-exceeded") {
        throw new HttpsError("resource-exhausted", "daily-quota-exceeded");
      }
      throw new HttpsError("resource-exhausted", "insufficient-credits");
    }

    const endpoint =
      "https://generativelanguage.googleapis.com/v1beta/models/" +
      `${encodeURIComponent(sanitized.model)}:generateContent`;

    let res;
    try {
      res = await fetch(endpoint, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-goog-api-key": SHARED_POOL_KEY.value(),
        },
        body: JSON.stringify(sanitized.payload),
        signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
      });
    } catch (_) {
      await refundPool(poolRef, cost);
      throw new HttpsError("unavailable", "upstream-network-error");
    }

    if (!res.ok) {
      await refundPool(poolRef, cost);
      throw new HttpsError("unavailable", "upstream-http-error");
    }

    let json;
    try {
      json = await res.json();
    } catch (_) {
      await refundPool(poolRef, cost);
      throw new HttpsError("unavailable", "upstream-parse-error");
    }

    const text = extractGeminiText(json);
    if (!text) {
      await refundPool(poolRef, cost);
      throw new HttpsError("unavailable", "empty-response");
    }

    return {
      text,
      remainingCredits: reservation.remainingCredits,
      cost,
      model: sanitized.model,
      appId: sanitized.appId,
    };
  },
);
