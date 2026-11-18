/**
 * HAK (entitlement) yardımcıları — PLAN §1.5 PL14. Saf: Firebase'e bağlı
 * değil, `node --test` ile sınanır. Tetikleyici taslağı `entitlements.js`.
 */

const TRIAL_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * İlk girişte yazılacak deneme belgesi. Anonim (misafir) hesaba deneme
 * VERİLMEZ: misafir hesap sınırsız ve bedavaca açılabildiğinden deneme her
 * seferinde yenilenip dahili AI faturası şişirilebilirdi. (Misafir sonradan
 * Google'a bağlanınca `onCreate` tetiklenmez — o yol PL6'da, sabah bakılacak.)
 *
 * @param {{isAnonymous: boolean}} user
 * @param {Date} now
 * @returns {object|null} null = belge yazılmaz
 */
function trialEntitlement(user, now) {
  if (!user || user.isAnonymous) return null;
  return {
    tier: "free",
    trialEndsAt: new Date(now.getTime() + TRIAL_DAYS * DAY_MS),
    createdAt: now,
  };
}

/** Auth kaydından anonimlik: sağlayıcısı olmayan hesap misafirdir. */
function isAnonymousUser(userRecord) {
  return !userRecord || !(userRecord.providerData || []).length;
}

module.exports = { TRIAL_DAYS, DAY_MS, trialEntitlement, isAnonymousUser };
