/**
 * HAK TETİKLEYİCİLERİ — TASLAK (PLAN §1.5 PL14). **DEPLOY EDİLMEZ**:
 * `index.js` bunu dışa aktarmıyor; Play'in ayrı Firebase projesi (PL13)
 * kurulunca orada `exports.startTrial` / `exports.dropEntitlement` ile
 * bağlanır. Kişisel proje bu belgeyi hiç okumaz (istemci kapısı yalnız
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

/** Hesap silinince hak belgesi de silinir (istemci silemez — kural). */
exports.dropEntitlement = functionsV1.auth.user().onDelete(async (user) => {
  await getFirestore().doc(`entitlements/${user.uid}`).delete();
});
