/** İtme bildirimlerinin saf yardımcıları (bağımlılıksız, `node --test`). */

/** Yeni eklenen kullanıcılar (saf, test edilir). */
function addedMembers(before, after) {
  const old = new Set(before || []);
  return (after || []).filter((uid) => typeof uid === "string" && !old.has(uid));
}

/** Bildirim metni kısaltma (saf). */
function clip(text, max = 160) {
  const t = String(text || "").replace(/\s+/g, " ").trim();
  return t.length > max ? `${t.slice(0, max - 1)}…` : t;
}

module.exports = { addedMembers, clip };
