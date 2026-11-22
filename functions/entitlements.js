/**
 * HAK TETİKLEYİCİLERİ (PLAN §1.5 PL14). `dropEntitlement` Play projesinde
 * `index.js`'te bağlı (`PLAY_PACKAGE_NAME` varsa, PL6). `startTrial` TASLAK,
 * HİÇBİR projede bağlı değil: deneme Play aboneliğinin 7 günlük ücretsiz
 * deneme teklifiyle veriliyor (P85 KARAR, en güvenli: ödeme yöntemi ister,
 * yeni hesap açarak yenilenemez; ikisi birden çifte deneme olurdu — sabah
 * bakılacak). Kişisel proje bu belgeyi hiç okumaz (istemci kapısı yalnız
 * `NOTLAR_PLAY` derlemesinde).
 *
 * `entitlements/{uid}` yalnız Admin SDK ile yazılır (kurallar istemciye
 * kapalı). Satın alma doğrulama Function'ı (PL6) aynı belgeye `tier`,
 * `proUntil`, `lifetimeOwned` yazar — sözleşme `docs/play_hazirlik.md`.
 */
const functionsV1 = require("firebase-functions/v1");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { trialEntitlement, isAnonymousUser } = require("./entitlement_util");

/** İlk giriş = Auth hesabının yaratılması: 7 günlük Pro denemesi. */
exports.startTrial = functionsV1.auth.user().onCreate(async (user) => {
  const doc = trialEntitlement({ isAnonymous: isAnonymousUser(user) }, new Date());
  if (!doc) return;
  try {
    // `create`: belge varsa (yeniden deneme / elle yazılmış hak) DOKUNMAZ.
    await getFirestore()
      .doc(`entitlements/${user.uid}`)
      .create({
        tier: doc.tier,
        trialEndsAt: Timestamp.fromDate(doc.trialEndsAt),
        createdAt: Timestamp.fromDate(doc.createdAt),
      });
  } catch (e) {
    if (e.code !== 6 /* ALREADY_EXISTS */) throw e;
  }
});

/**
 * Hesap silinince hak belgesi ve satın alma bağları da silinir (istemci
 * silemez — kural). Bağ kalkınca aynı Play hesabıyla açılan YENİ hesap
 * "Satın alımları geri yükle" ile ödediğini geri alır (PL6).
 */
exports.dropEntitlement = functionsV1.auth.user().onDelete(async (user) => {
  const db = getFirestore();
  const tokens = await db
    .collection("purchaseTokens")
    .where("uid", "==", user.uid)
    .get();
  const batch = db.batch();
  for (const doc of tokens.docs) batch.delete(doc.ref);
  batch.delete(db.doc(`entitlements/${user.uid}`));
  // Karar sayacı (decisions.js). Takas: silip yeni hesapla "geri yükle"
  // bir kerelik 1000'i yeniler — maliyeti ~0,03 $, satın alma bağına
  // bağlamak gerekirse sabah bakılacak.
  batch.delete(db.doc(`decisionUsage/${user.uid}`));
  await batch.commit();
});
