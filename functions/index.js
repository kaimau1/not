const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { matchKind, MIN_NAME_QUERY } = require("./search_match");

initializeApp();
const db = getFirestore();

const RESULT_LIMIT = 15;
const MAX_QUERY_LEN = 60;

/**
 * Bellekte taranacak EN FAZLA kullanıcı sayısı.
 *
 * ponytail: "içinde geçen" araması Firestore'da yerel olarak YOK — dizin
 * yalnız ÖNEKE göre sıralanabilir. Bu yüzden dizin okunup süzme burada
 * yapılıyor. Tavan: kullanıcı sayısı bunu aşınca arama son eklenenleri
 * kaçırmaya başlar ve her sorgu bu kadar okuma harcar. Yükseltme yolu:
 * `userSearch` belgelerine ad/e-posta parçalarından (n-gram) bir dizi alan
 * yazıp `array-contains` ile sorgulamak — o zaman bu tarama tamamen kalkar.
 */
const SCAN_LIMIT = 1000;

/** uid başına dakikada en fazla arama (F1.1 hız sınırı). */
const RATE_LIMIT_PER_MINUTE = 10;
const RATE_WINDOW_MS = 60 * 1000;

/**
 * uid başına sabit pencereli hız sınırı. Sayaç `rateLimits/{uid}` belgesinde,
 * yalnız Admin SDK yazar (kural: istemciye tamamen kapalı). Sınır aşıldıysa
 * `resource-exhausted` fırlatır.
 */
async function enforceRateLimit(uid) {
  const ref = db.collection("rateLimits").doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const data = snap.exists ? snap.data() : null;
    const windowStart =
      data && typeof data.searchWindowStart === "number"
        ? data.searchWindowStart
        : 0;
    const count =
      data && typeof data.searchCount === "number" ? data.searchCount : 0;
    if (now - windowStart >= RATE_WINDOW_MS) {
      tx.set(
        ref,
        {
          searchWindowStart: now,
          searchCount: 1,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      return;
    }
    if (count >= RATE_LIMIT_PER_MINUTE) {
      throw new HttpsError(
        "resource-exhausted",
        "Çok fazla arama yaptınız, bir dakika sonra tekrar deneyin.",
      );
    }
    tx.set(
      ref,
      { searchCount: count + 1, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  });
}

/**
 * searchUsers — arkadaş eklemede "tüm kullanıcılar içinde arama".
 *
 * NEDEN CLOUD FUNCTION: `userSearch/{uid}` koleksiyonu istemciden hiç
 * okunamaz (bkz. firestore.rules) — aksi hâlde `list` izni verilince tüm
 * kullanıcı tabanı taranabilirdi (bu proje daha önce `userDirectory`
 * koleksiyonunda TAM olarak bu riskten kaçınmak için `get`-only bir tasarım
 * seçmişti, bkz. friends_repository.dart üstündeki not). Bu fonksiyon Admin
 * SDK ile kuralları atlayıp okur, ama SONUCU sınırlar (en fazla 15, yalnız
 * giriş yapmış kullanıcı) — yani dizinin tamamı değil, tek bir arama
 * sorgusunun cevabı dışarı çıkar.
 *
 * GÜVENLİK (F1.1): anonim (misafir) oturum aramaz — web'de herkes ilk
 * açılışta otomatik anonim hesap aldığı için yalnız `request.auth` bakmak
 * dizini dünyaya açıyordu. uid başına dakikada 10 arama. Eşleşme
 * [matchKind]: e-posta yalnız TAM, ad en az 3 harfli kelime öneki. Ad
 * eşleşmesinde kelimenin başı yeterli ("mehmet" → "Ali Mehmet"); adın
 * başından eşleşenler ÖNCE gelir.
 */
exports.searchUsers = onCall(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmış olmalısınız.");
  }
  const provider =
    auth.token && auth.token.firebase && auth.token.firebase.sign_in_provider;
  if (provider === "anonymous") {
    throw new HttpsError(
      "permission-denied",
      "Kişi aramak için Google hesabıyla giriş yapın.",
    );
  }
  const rawQuery = (request.data && request.data.query) || "";
  const query = String(rawQuery).trim().toLowerCase().slice(0, MAX_QUERY_LEN);
  if (!query.includes("@") && query.length < MIN_NAME_QUERY) {
    return { results: [] };
  }
  await enforceRateLimit(auth.uid);

  const snap = await db
    .collection("userSearch")
    .orderBy("nameLower")
    .limit(SCAN_LIMIT)
    .get();

  // Önek eşleşmeleri ayrı torbada toplanır ve listenin BAŞINA konur.
  const prefix = new Map();
  const inside = new Map();
  for (const doc of snap.docs) {
    const data = doc.data();
    if (!data || data.uid === auth.uid) continue; // kendini gösterme
    if (prefix.has(data.uid) || inside.has(data.uid)) continue;
    const name = (data.nameLower || "").toLowerCase();
    const email = (data.emailLower || "").toLowerCase();
    const kind = matchKind(query, name, email);
    if (kind === null) continue;
    const hit = kind === "prefix" ? prefix : inside;
    hit.set(data.uid, {
      uid: data.uid,
      name: data.name || "",
      email: data.email || "",
    });
    if (prefix.size >= RESULT_LIMIT) break;
  }

  const results = [...prefix.values(), ...inside.values()].slice(
    0,
    RESULT_LIMIT,
  );

  return { results: results };
});

