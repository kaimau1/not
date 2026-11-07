// Takvim tatil düzeltmelerini (`tool/tatiller.json`) Firestore
// `config/holidays` belgesine yazar; içerik değişmediyse YAZMAZ (her
// istemcinin dinleyicisi boşuna tetiklenmesin). CI `deploy` işi çağırır:
//   node tool/set_holidays.js
// Kimlik: GOOGLE_APPLICATION_CREDENTIALS (hizmet hesabı). `config/` istemciye
// salt okunur (firestore.rules); yönetici SDK'sı kuralları atlar.
const fs = require('fs');
const path = require('path');
const admin = require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));

const raw = JSON.parse(fs.readFileSync(path.join(__dirname, 'tatiller.json'), 'utf8'));
const day = /^\d{4}-\d{2}-\d{2}$/;
const religious = {};
for (const [year, v] of Object.entries(raw.religious || {})) {
  if (!/^\d{4}$/.test(year) || typeof v !== 'object' || v === null) continue;
  const e = {};
  if (day.test(v.ramazan || '')) e.ramazan = v.ramazan;
  if (day.test(v.kurban || '')) e.kurban = v.kurban;
  religious[year] = e;
}
const extra = {};
for (const [k, v] of Object.entries(raw.extra || {})) {
  if (day.test(k) && typeof v === 'string' && v.trim()) extra[k] = v.trim();
}
const removed = (raw.removed || []).filter((k) => day.test(k)).sort();
const doc = { religious, extra, removed };

admin.initializeApp();
const ref = admin.firestore().collection('config').doc('holidays');
ref
  .get()
  .then((snap) => {
    const cur = snap.exists ? snap.data() : null;
    const same =
      cur &&
      JSON.stringify({ religious: cur.religious || {}, extra: cur.extra || {}, removed: cur.removed || [] }) ===
        JSON.stringify(doc);
    if (same) {
      console.log('config/holidays güncel — yazılmadı.');
      return null;
    }
    return ref.set(doc).then(() => console.log('config/holidays yazıldı:', JSON.stringify(doc)));
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
