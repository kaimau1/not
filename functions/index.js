const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");

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
 * EŞLEŞME "İÇİNDE GEÇEN" (kullanıcı isteği 2026-08-29: "kişi arama doğru
 * çalışmıyor, içinde geçen şeklinde aranmalı kolayca"). Eskiden yalnız ÖNEK
 * eşleşiyordu: "mehmet" araması "Ali Mehmet"i hiç bulmuyordu. Önek eşleşmeleri
 * yine ÖNCE gelir — "ali" yazan çoğu zaman "Ali ..."yi arıyordur.
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
    const hit =
      name.startsWith(query) || email.startsWith(query)
        ? prefix
        : name.includes(query) || email.includes(query)
          ? inside
          : null;
    if (hit === null) continue;
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
