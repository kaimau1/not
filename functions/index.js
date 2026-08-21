const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

const RESULT_LIMIT = 15;
const MAX_QUERY_LEN = 60;

/**
 * searchUsers — arkadaş eklemede "tüm kullanıcılar içinde arama".
 *
 * NEDEN CLOUD FUNCTION: `userSearch/{uid}` koleksiyonu istemciden hiç
 * okunamaz (bkz. firestore.rules) — aksi hâlde `list` izni verilince tüm
 * kullanıcı tabanı taranabilirdi (bu proje daha önce `userDirectory`
 * koleksiyonunda TAM olarak bu riskten kaçınmak için `get`-only bir tasarım
 * seçmişti, bkz. friends_repository.dart üstündeki not). Bu fonksiyon Admin
 * SDK ile kuralları atlayıp okur, ama SONUCU sınırlar (en fazla 15,
 * yalnız giriş yapmış kullanıcı, yalnız ad/e-posta ÖNEKİ eşleşmesi) — yani
 * dizinin tamamı değil, tek bir arama sorgusunun cevabı dışarı çıkar.
 */
exports.searchUsers = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmış olmalısınız.");
  }
  const rawQuery = (request.data && request.data.query) || "";
  const query = String(rawQuery).trim().toLowerCase().slice(0, MAX_QUERY_LEN);
  if (query.length < 2) {
    return { results: [] };
  }

  const end = query + "";
  const collection = db.collection("userSearch");

  const [byName, byEmail] = await Promise.all([
    collection
      .orderBy("nameLower")
      .startAt(query)
      .endAt(end)
      .limit(RESULT_LIMIT)
      .get(),
    collection
      .orderBy("emailLower")
      .startAt(query)
      .endAt(end)
      .limit(RESULT_LIMIT)
      .get(),
  ]);

  const byUid = new Map();
  for (const doc of [...byName.docs, ...byEmail.docs]) {
    const data = doc.data();
    if (data.uid === auth.uid) continue; // kendini arama sonucunda gösterme
    if (byUid.has(data.uid)) continue;
    byUid.set(data.uid, {
      uid: data.uid,
      name: data.name || "",
      email: data.email || "",
    });
    if (byUid.size >= RESULT_LIMIT) break;
  }

  return { results: [...byUid.values()] };
});
