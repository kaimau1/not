/**
 * **ARKA PLAN İTME BİLDİRİMLERİ (FCM)** — F4.6, 2026-10-19.
 *
 * Paylaşım bildirimleri eskiden yalnız uygulama AÇIKKEN düşüyordu (yerel
 * Firestore dinleyicisi). Bu tetikleyiciler uygulama kapalıyken de telefona
 * bildirim gönderir. Cihaz jetonları `users/{uid}/fcmTokens/{jeton}`
 * belgelerinde (istemci yazar); kullanıcı "Paylaşım bildirimleri"ni
 * kapattıysa (ayar senkronu: `users/{uid}/meta/prefs.values
 * .shared_notifications == false`) gönderilmez. Geçersiz jetonlar silinir.
 *
 * BİLİNÇLİ OLARAK YOK: ortak notun her DÜZENLEMESİ için itme — not belgesi
 * yazarken saniyeler içinde defalarca yazılır, her yazım bir fonksiyon
 * çağrısı ve bildirim olurdu. Düzenleme bildirimi uygulama açıkken yerel
 * servisten gelir.
 */
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

const CHANNEL = "shared_folders";
const DEAD_TOKEN = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
  "messaging/invalid-argument",
]);

const { addedMembers, clip } = require("./push_util");

async function tokensFor(db, uid) {
  const prefs = await db.doc(`users/${uid}/meta/prefs`).get();
  if (prefs.exists && prefs.get("values.shared_notifications") === false) {
    return [];
  }
  const snap = await db.collection(`users/${uid}/fcmTokens`).get();
  return snap.docs.map((d) => d.id);
}

async function push(uids, { title, body, payload, tag }) {
  const db = getFirestore();
  for (const uid of new Set(uids)) {
    const tokens = await tokensFor(db, uid);
    if (tokens.length === 0) continue;
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: clip(title, 80), body: clip(body) },
      data: { payload },
      android: {
        priority: "high",
        notification: { channelId: CHANNEL, icon: "ic_stat_notlar", tag },
      },
    });
    await Promise.all(
      res.responses.map((r, i) =>
        !r.success && r.error && DEAD_TOKEN.has(r.error.code)
          ? db.doc(`users/${uid}/fcmTokens/${tokens[i]}`).delete()
          : null,
      ),
    );
  }
}

/** Paylaşılan klasörün sohbetine mesaj → öbür üyeler. */
exports.pushFolderMessage = onDocumentCreated(
  "folderShares/{folderId}/messages/{messageId}",
  async (event) => {
    const msg = event.data && event.data.data();
    if (!msg) return;
    const { folderId } = event.params;
    const share = (await getFirestore().doc(`folderShares/${folderId}`).get()).data();
    if (!share) return;
    const members = [share.ownerId, ...(share.sharedWith || [])].filter(
      (uid) => uid && uid !== msg.senderId,
    );
    await push(members, {
      title: share.name || "Paylaşılan klasör",
      body: `${msg.senderName || "Biri"}: ${msg.text || "📷"}`,
      payload: `folder:${folderId}`,
      tag: `folder:${folderId}`,
    });
  },
);

/** Klasör daveti (pending'e eklenen) → davetli. */
exports.pushFolderInvite = onDocumentWritten("folderShares/{folderId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : {};
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after) return;
  const invited = addedMembers(before.pending, after.pending);
  if (invited.length === 0) return;
  const owner = await getFirestore().doc(`userSearch/${after.ownerId}`).get();
  const who = (owner.exists && owner.get("name")) || "Biri";
  await push(invited, {
    title: after.name || "Paylaşılan klasör",
    body: `${who} seni bu klasöre davet etti`,
    payload: `folder:${event.params.folderId}`,
    tag: `invite:${event.params.folderId}`,
  });
});

/** Ortak not: sharedWith'e eklenen → yeni ortak çalışan. */
exports.pushNoteShared = onDocumentWritten("noteShares/{shareId}", async (event) => {
  const before = event.data.before.exists ? event.data.before.data() : {};
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after) return;
  const added = addedMembers(before.sharedWith, after.sharedWith);
  if (added.length === 0) return;
  const note = await getFirestore().doc(`users/${after.ownerId}/notes/${after.noteId}`).get();
  const title = (note.exists && String(note.get("title") || "").trim()) || "Ortak not";
  await push(added, {
    title,
    body: `${after.ownerName || "Biri"} seninle bir not paylaştı`,
    payload: `shared:${after.ownerId}/${after.noteId}`,
    tag: `note:${event.params.shareId}`,
  });
});

/** Arkadaştan gelen not kopyası → alıcı. */
exports.pushInboxNote = onDocumentCreated("users/{uid}/inboxNotes/{noteId}", async (event) => {
  const data = event.data && event.data.data();
  if (!data) return;
  await push([event.params.uid], {
    title: String(data.title || "").trim() || "Yeni not",
    body: `${data.fromName || "Biri"} sana bir not gönderdi`,
    payload: "inbox",
    tag: `inbox:${event.params.noteId}`,
  });
});

