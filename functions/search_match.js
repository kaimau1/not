/** Ad aramasında en kısa sorgu (F1.1: kısa öneklerle dizin toplanamasın). */
const MIN_NAME_QUERY = 3;

/**
 * Sorgunun eşleşme kuralı (F1.1, 2026-10-19 kararı):
 * - '@' içeren sorgu E-POSTA aramasıdır ve yalnız TAM eşleşir — e-posta
 *   öneki/parçasıyla tarama yapılamaz.
 * - Diğerleri AD aramasıdır: en az 3 harf, adın herhangi bir kelimesinin
 *   ÖNEKİ (ya da adın tamamının öneki). E-postada hiç parça araması yok.
 * Saf fonksiyon — `node --test` ile sınanır (search_match.test.js).
 */
function matchKind(query, nameLower, emailLower) {
  if (query.includes("@")) {
    return emailLower === query ? "prefix" : null;
  }
  if (query.length < MIN_NAME_QUERY) return null;
  if (nameLower.startsWith(query)) return "prefix";
  const words = nameLower.split(/\s+/);
  for (const w of words) {
    if (w.startsWith(query)) return "inside";
  }
  return null;
}

module.exports = { matchKind, MIN_NAME_QUERY };
