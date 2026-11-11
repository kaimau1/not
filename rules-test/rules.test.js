/**
 * FIRESTORE KURALLARI — emülatör testleri (F4.9, 2026-10-19).
 *
 * 28 KB'lık kuralın hiç testi yoktu; değişiklikler ancak cihazda "permission
 * denied" görülünce fark ediliyordu. Çalıştırma (depo kökünden):
 *   cd rules-test && npm ci && npm test
 * (`firebase emulators:exec` Firestore emülatörünü açar, Java 11+ ister.)
 * CI'da `test` işinde koşar.
 */
const { readFileSync } = require("node:fs");
const path = require("node:path");
const { before, after, beforeEach, test } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  query,
  where,
  Timestamp,
} = require("firebase/firestore");
const { ref, uploadString, getBytes } = require("firebase/storage");

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-not",
    firestore: {
      rules: readFileSync(path.join(__dirname, "..", "firestore.rules"), "utf8"),
    },
    storage: {
      rules: readFileSync(path.join(__dirname, "..", "storage.rules"), "utf8"),
    },
  });
});

after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
});

const as = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
/** Google ile girmiş kullanıcı: jetonda doğrulanmış e-posta var. */
const asEmail = (uid, email) =>
  env.authenticatedContext(uid, { email, email_verified: true }).firestore();

/** Kuralları atlayarak tohum verisi. */
async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

test("kullanıcı yalnız kendi notunu okur/yazar", async () => {
  await assertSucceeds(setDoc(doc(as("a"), "users/a/notes/n1"), { title: "x" }));
  await assertFails(getDoc(doc(as("b"), "users/a/notes/n1")));
  await assertFails(setDoc(doc(as("b"), "users/a/notes/n2"), { title: "y" }));
  await assertFails(getDoc(doc(anon(), "users/a/notes/n1")));
});

test("sahip: çöp sorgusu ve notun alt koleksiyonlarını temizleme (F5.4, F6.7)", async () => {
  await seed(async (db) => {
    await setDoc(doc(db, "users/a/notes/n1"), { title: "x", deletedAt: Timestamp.now() });
    await setDoc(doc(db, "users/a/notes/n1/versions/v1"), { body: "eski" });
    await setDoc(doc(db, "users/a/notes/n1/presence/b"), { at: 1 });
  });
  const trash = query(
    collection(as("a"), "users/a/notes"),
    where("deletedAt", ">", new Timestamp(0, 0)),
  );
  await assertSucceeds(getDocs(trash));
  await assertFails(
    getDocs(query(collection(as("b"), "users/a/notes"), where("deletedAt", ">", new Timestamp(0, 0)))),
  );
  // "Yalnız bu cihaz"a alma sürümleri ve BAŞKASININ nabzını da siler.
  await assertSucceeds(deleteDoc(doc(as("a"), "users/a/notes/n1/versions/v1")));
  await assertSucceeds(deleteDoc(doc(as("a"), "users/a/notes/n1/presence/b")));
});

test("premiumUntil istemciden yazılamaz", async () => {
  await assertFails(setDoc(doc(as("a"), "users/a"), { premiumUntil: 1 }));
  await assertSucceeds(setDoc(doc(as("a"), "users/a"), { name: "A" }));
});

test("ayar senkronu ve itme jetonu yalnız sahibinde (F4.5, F4.6)", async () => {
  await assertSucceeds(
    setDoc(doc(as("a"), "users/a/meta/prefs"), { values: { font_scale: 1.15 } }),
  );
  await assertFails(getDoc(doc(as("b"), "users/a/meta/prefs")));
  await assertSucceeds(setDoc(doc(as("a"), "users/a/fcmTokens/t1"), { platform: "android" }));
  await assertFails(setDoc(doc(as("b"), "users/a/fcmTokens/t2"), { platform: "android" }));
});

test("takvim ve görevler yalnız sahibinde (TAKVIM_PLANI F46.4)", async () => {
  for (const c of ["events", "tasks", "taskLists", "dayLinks"]) {
    await assertSucceeds(setDoc(doc(as("a"), `users/a/${c}/x`), { title: "t" }));
    await assertSucceeds(getDoc(doc(as("a"), `users/a/${c}/x`)));
    await assertFails(getDoc(doc(as("b"), `users/a/${c}/x`)));
    await assertFails(setDoc(doc(as("b"), `users/a/${c}/y`), { title: "t" }));
    await assertFails(getDoc(doc(anon(), `users/a/${c}/x`)));
  }
});

test("kullanıcı dizini taranamaz, yalnız kendi kaydı yazılır (F1.1)", async () => {
  await assertSucceeds(
    setDoc(doc(asEmail("a", "a@x"), "userSearch/a"), {
      uid: "a", name: "A", email: "a@x", nameLower: "a", emailLower: "a@x",
    }),
  );
  await assertFails(getDoc(doc(as("b"), "userSearch/a")));
  await assertFails(
    setDoc(doc(as("b"), "userSearch/a"), {
      uid: "a", name: "B", email: "b@x", nameLower: "b", emailLower: "b@x",
    }),
  );
});

test("klasör aynası: sahip siler, var olmayanı da (klasör silme, 2026-11-06)", async () => {
  await seed(async (db) => {
    await setDoc(doc(db, "users/a/folders/f1"), { name: "İş" });
    await setDoc(doc(db, "folderShares/f1"), {
      ownerId: "a", name: "İş", icon: "folder", sharedWith: ["b"], pending: [], roles: {},
    });
  });
  await assertFails(deleteDoc(doc(as("b"), "folderShares/f1")));
  await assertSucceeds(deleteDoc(doc(as("a"), "folderShares/f1")));
  // Hiç paylaşılmamış klasörün aynası yok: silme yine geçer.
  await assertSucceeds(deleteDoc(doc(as("a"), "folderShares/f2")));
  await assertSucceeds(deleteDoc(doc(as("a"), "users/a/folders/f1")));
});

test("config okunur, yazılamaz; rateLimits kapalı", async () => {
  await assertSucceeds(getDoc(doc(anon(), "config/app")));
  await assertFails(setDoc(doc(as("a"), "config/app"), { minClient: 1 }));
  await assertFails(getDoc(doc(as("a"), "rateLimits/a")));
});

async function seedSharedNote() {
  await seed(async (db) => {
    await setDoc(doc(db, "users/a/notes/n1"), {
      title: "ortak", body: "", createdBy: "a", updatedBy: "a", folderId: null,
    });
    await setDoc(doc(db, "noteShares/a_n1"), {
      ownerId: "a", noteId: "n1", ownerName: "A", sharedWith: ["b"], names: {},
    });
  });
}

test("ortak not: ortak çalışan okur ve düzenler, yabancı giremez", async () => {
  await seedSharedNote();
  await assertSucceeds(getDoc(doc(as("b"), "users/a/notes/n1")));
  await assertSucceeds(
    updateDoc(doc(as("b"), "users/a/notes/n1"), { body: "B yazdı", updatedBy: "b" }),
  );
  // updatedBy kendisi olmalı.
  await assertFails(
    updateDoc(doc(as("b"), "users/a/notes/n1"), { body: "x", updatedBy: "a" }),
  );
  // Kalıcı silme yalnız sahipte.
  await assertFails(deleteDoc(doc(as("b"), "users/a/notes/n1")));
  await assertFails(getDoc(doc(as("c"), "users/a/notes/n1")));
});

test("ortak not alt belgeleri: ağır belge, sürüm, düzenliyor nabzı (F3.13, F4.1, F4.2)", async () => {
  await seedSharedNote();
  const b = as("b");
  await assertSucceeds(setDoc(doc(b, "users/a/notes/n1/heavy/data"), { attachments: {} }));
  await assertSucceeds(setDoc(doc(b, "users/a/notes/n1/versions/v1"), { body: "eski" }));
  // Sürüm değiştirilemez / ortak çalışan silemez.
  await assertFails(updateDoc(doc(b, "users/a/notes/n1/versions/v1"), { body: "sahte" }));
  await assertFails(deleteDoc(doc(b, "users/a/notes/n1/versions/v1")));
  // Nabız: yalnız kendi belgesi.
  await assertSucceeds(setDoc(doc(b, "users/a/notes/n1/presence/b"), { name: "B" }));
  await assertFails(setDoc(doc(b, "users/a/notes/n1/presence/a"), { name: "A" }));
  // Bilinmeyen alt koleksiyon kapalı.
  await assertFails(setDoc(doc(b, "users/a/notes/n1/other/x"), { v: 1 }));
  // Yabancı hiçbirine erişemez.
  const c = as("c");
  await assertFails(getDoc(doc(c, "users/a/notes/n1/heavy/data")));
  await assertFails(getDoc(doc(c, "users/a/notes/n1/versions/v1")));
  await assertFails(setDoc(doc(c, "users/a/notes/n1/presence/c"), { name: "C" }));
});

test("ortak not aynası yalnız sahibince, gerçek nota yaratılır", async () => {
  await seed((db) => setDoc(doc(db, "users/a/notes/n1"), { title: "x" }));
  await assertSucceeds(
    setDoc(doc(as("a"), "noteShares/a_n1"), {
      ownerId: "a", noteId: "n1", ownerName: "A", sharedWith: ["b"], names: {},
    }),
  );
  // Başkasının notu için sahte ayna.
  await assertFails(
    setDoc(doc(as("c"), "noteShares/a_n1"), {
      ownerId: "a", noteId: "n1", ownerName: "C", sharedWith: ["c"], names: {},
    }),
  );
  // Var olmayan not.
  await assertFails(
    setDoc(doc(as("a"), "noteShares/a_n9"), {
      ownerId: "a", noteId: "n9", ownerName: "A", sharedWith: ["b"], names: {},
    }),
  );
});

// ── F71.2 güvenlik denetimi (2026-11-11) ───────────────────────────────

test("F71.2 e-posta dizini: yalnız KENDİ doğrulanmış e-postasının kaydı", async () => {
  const a = asEmail("a", "a@x.com");
  await assertSucceeds(setDoc(doc(a, "userDirectory/a@x.com"), { uid: "a" }));
  // Başkasının e-postasını kendine yönlendirme (yaratma ve ÜSTÜNE yazma).
  const b = asEmail("b", "b@x.com");
  await assertFails(setDoc(doc(b, "userDirectory/kurban@x.com"), { uid: "b" }));
  await assertFails(setDoc(doc(b, "userDirectory/a@x.com"), { uid: "b" }));
  // E-postasız (misafir) ve doğrulanmamış e-posta yazamaz.
  await assertFails(setDoc(doc(as("m"), "userDirectory/m@x.com"), { uid: "m" }));
  const d = env.authenticatedContext("d", { email: "d@x.com", email_verified: false }).firestore();
  await assertFails(setDoc(doc(d, "userDirectory/d@x.com"), { uid: "d" }));
  // Tek belge okunur, liste yok; yalnız sahibi siler.
  await assertSucceeds(getDoc(doc(b, "userDirectory/a@x.com")));
  await assertFails(getDocs(collection(b, "userDirectory")));
  await assertFails(deleteDoc(doc(b, "userDirectory/a@x.com")));
  await assertSucceeds(deleteDoc(doc(a, "userDirectory/a@x.com")));
});

test("F71.2 arama dizini: başkasının e-postasıyla kayıt açılamaz", async () => {
  await assertFails(
    setDoc(doc(asEmail("b", "b@x.com"), "userSearch/b"), {
      uid: "b", name: "Kurban", email: "kurban@x.com",
      nameLower: "kurban", emailLower: "kurban@x.com",
    }),
  );
});

test("F71.2 arkadaşlık isteği: sahte e-posta ve şişkin alan reddedilir", async () => {
  const b = asEmail("b", "b@x.com");
  const istek = (o) => ({ fromEmail: "b@x.com", fromName: "B", createdAt: Timestamp.now(), ...o });
  await assertFails(setDoc(doc(b, "users/a/friendRequests/b"), istek({ fromEmail: "patron@x.com" })));
  await assertFails(setDoc(doc(b, "users/a/friendRequests/b"), istek({ fromName: "x".repeat(201) })));
  // Başkası adına istek.
  await assertFails(setDoc(doc(b, "users/a/friendRequests/c"), istek({})));
  await assertSucceeds(setDoc(doc(b, "users/a/friendRequests/b"), istek({})));
  await assertFails(updateDoc(doc(b, "users/a/friendRequests/b"), { fromName: "Z" }));
  // Misafir (e-postasız) boş e-postayla gönderebilir — davranış değişmedi.
  await assertSucceeds(
    setDoc(doc(as("m"), "users/a/friendRequests/m"), istek({ fromEmail: "", fromName: "" })),
  );
  // Kabul: A, B'nin listesine yalnız İSTEK VARSA ve kendi e-postasıyla yazar.
  const a = asEmail("a", "a@x.com");
  const kayit = (o) => ({ email: "a@x.com", name: "A", since: Timestamp.now(), ...o });
  await assertFails(setDoc(doc(a, "users/b/friends/a"), kayit({ email: "patron@x.com" })));
  await assertSucceeds(setDoc(doc(a, "users/b/friends/a"), kayit({})));
  // İstek yokken başkasının arkadaş listesine girilemez.
  await assertFails(setDoc(doc(a, "users/c/friends/a"), kayit({})));
});

/** A'nın f1 klasörü: b 'read', c 'write', d 'both', p davetli (bekliyor). */
async function seedSharedFolder() {
  await seed(async (db) => {
    const paylasim = { sharedWith: ["b", "c", "d"], pending: ["p"], roles: { b: "read", c: "write" } };
    await setDoc(doc(db, "users/a/folders/f1"), { name: "Ortak", icon: "folder", ...paylasim });
    await setDoc(doc(db, "folderShares/f1"), { ownerId: "a", name: "Ortak", icon: "folder", ...paylasim });
    await setDoc(doc(db, "users/a/notes/n1"), { title: "A'nın", folderId: "f1", createdBy: "a" });
    await setDoc(doc(db, "users/a/notes/nc"), { title: "C'nin", folderId: "f1", createdBy: "c" });
    await setDoc(doc(db, "users/a/notes/ozel"), { title: "özel" });
    await setDoc(doc(db, "users/v/notes/n1"), { title: "kurban", folderId: "f1" });
  });
}

test("F71.2 paylaşılan klasör: rol matrisi (read / write / both / davetli / yabancı)", async () => {
  await seedSharedFolder();
  const not = (uid) => doc(as(uid), "users/a/notes/n1");
  // Okuma: read + both; write, davetli ve yabancı okuyamaz.
  await assertSucceeds(getDoc(not("b")));
  await assertSucceeds(getDoc(not("d")));
  await assertFails(getDoc(not("c")));
  await assertFails(getDoc(not("p")));
  await assertFails(getDoc(not("x")));
  // Klasör dışındaki nota ve başka kullanıcının aynı folderId'li notuna erişim yok.
  await assertFails(getDoc(doc(as("d"), "users/a/notes/ozel")));
  await assertFails(getDoc(doc(as("d"), "users/v/notes/n1")));
  await assertFails(
    setDoc(doc(as("d"), "users/v/notes/yeni"), { folderId: "f1", createdBy: "d", updatedBy: "d" }),
  );
  // Yazma: read yazamaz; write yalnız KENDİ notunu; both hepsini.
  await assertFails(updateDoc(not("b"), { title: "x", updatedBy: "b" }));
  await assertFails(updateDoc(not("c"), { title: "x", updatedBy: "c" }));
  await assertSucceeds(updateDoc(doc(as("c"), "users/a/notes/nc"), { title: "y", updatedBy: "c" }));
  await assertSucceeds(updateDoc(not("d"), { title: "z", updatedBy: "d" }));
  // Not klasörden çıkarılamaz, createdBy değişemez, kalıcı silinemez.
  await assertFails(updateDoc(not("d"), { folderId: null, updatedBy: "d" }));
  await assertFails(updateDoc(not("d"), { createdBy: "d", updatedBy: "d" }));
  await assertFails(deleteDoc(not("d")));
  // Yaratma: createdBy kendisi olmalı; read rolü yaratamaz.
  await assertSucceeds(
    setDoc(doc(as("c"), "users/a/notes/c2"), { folderId: "f1", createdBy: "c", updatedBy: "c" }),
  );
  await assertFails(
    setDoc(doc(as("c"), "users/a/notes/c3"), { folderId: "f1", createdBy: "a", updatedBy: "c" }),
  );
  await assertFails(
    setDoc(doc(as("b"), "users/a/notes/b1"), { folderId: "f1", createdBy: "b", updatedBy: "b" }),
  );
});

test("F71.2 paylaşılan klasör: üye rolünü yükseltemez, klasörü yeniden adlandıramaz", async () => {
  await seedSharedFolder();
  for (const yol of ["users/a/folders/f1", "folderShares/f1"]) {
    await assertFails(updateDoc(doc(as("b"), yol), { roles: { b: "both", c: "write" } }));
    await assertFails(updateDoc(doc(as("b"), yol), { sharedWith: ["b", "c", "d", "x"] }));
    await assertFails(updateDoc(doc(as("b"), yol), { name: "Ele geçirildi" }));
    await assertFails(updateDoc(doc(as("x"), yol), { sharedWith: ["b", "c", "d", "x"] }));
  }
  await assertFails(updateDoc(doc(as("b"), "users/a/folders/f1"), { hidden: true }));
  await assertFails(updateDoc(doc(as("b"), "folderShares/f1"), { ownerId: "b" }));
  // Davetli yalnız kendi davetini yanıtlar: kabul edebilir, başkasını ekleyemez.
  await assertFails(
    updateDoc(doc(as("p"), "folderShares/f1"), { pending: [], sharedWith: ["b", "c", "d", "p", "x"] }),
  );
  await assertFails(updateDoc(doc(as("p"), "folderShares/f1"), { pending: [], roles: { p: "both" } }));
  await assertSucceeds(
    updateDoc(doc(as("p"), "folderShares/f1"), { pending: [], sharedWith: ["b", "c", "d", "p"] }),
  );
  await assertSucceeds(
    updateDoc(doc(as("p"), "users/a/folders/f1"), { pending: [], sharedWith: ["b", "c", "d", "p"] }),
  );
});

test("F71.2 klasör aynası: sahte ayna yaratılamaz", async () => {
  await seed((db) => setDoc(doc(db, "users/a/folders/f9"), { name: "A'nın" }));
  const ayna = (ownerId) => ({ ownerId, name: "x", icon: "folder", sharedWith: ["c"], pending: [], roles: {} });
  // Klasörü olmayan biri başkasının folderId'siyle ayna açamaz; başkası adına da.
  await assertFails(setDoc(doc(as("c"), "folderShares/f9"), ayna("c")));
  await assertFails(setDoc(doc(as("c"), "folderShares/f9"), ayna("a")));
  await assertSucceeds(setDoc(doc(as("a"), "folderShares/f9"), ayna("a")));
});

test("F71.2 klasör sohbeti: yalnız üyeler, gönderen sahte olamaz, tavanlar", async () => {
  await seedSharedFolder();
  const ileti = (o) => ({ senderId: "b", senderName: "B", text: "selam", createdAt: Timestamp.now(), ...o });
  const b = as("b");
  await assertSucceeds(setDoc(doc(b, "folderShares/f1/messages/m1"), ileti({})));
  await assertFails(setDoc(doc(b, "folderShares/f1/messages/m2"), ileti({ senderId: "a" })));
  await assertFails(setDoc(doc(b, "folderShares/f1/messages/m3"), ileti({ text: "x".repeat(2001) })));
  await assertFails(setDoc(doc(b, "folderShares/f1/messages/m4"), ileti({ text: "" })));
  await assertFails(setDoc(doc(b, "folderShares/f1/messages/m5"), ileti({ senderName: "x".repeat(201) })));
  await assertFails(updateDoc(doc(b, "folderShares/f1/messages/m1"), { text: "değişti" }));
  // Davetli ve yabancı okuyamaz/yazamaz; yazar ve sahip siler.
  await assertFails(getDoc(doc(as("p"), "folderShares/f1/messages/m1")));
  await assertFails(setDoc(doc(as("x"), "folderShares/f1/messages/m6"), ileti({ senderId: "x" })));
  await assertFails(deleteDoc(doc(as("d"), "folderShares/f1/messages/m1")));
  await assertSucceeds(deleteDoc(doc(as("a"), "folderShares/f1/messages/m1")));
});

test("F71.2 gelen notlar: yalnız arkadaş, gönderen sahte olamaz, tavan", async () => {
  await seed((db) => setDoc(doc(db, "users/a/friends/b"), { email: "b@x.com", name: "B" }));
  const not = (o) => ({ fromUid: "b", fromName: "B", fromEmail: "b@x.com", title: "t", body: "g", ...o });
  await assertSucceeds(setDoc(doc(as("b"), "users/a/inboxNotes/i1"), not({})));
  await assertFails(setDoc(doc(as("b"), "users/a/inboxNotes/i2"), not({ fromUid: "c" })));
  await assertFails(setDoc(doc(as("b"), "users/a/inboxNotes/i3"), not({ body: "x".repeat(100001) })));
  await assertFails(setDoc(doc(as("b"), "users/a/inboxNotes/i4"), not({ ek: 1 })));
  // Arkadaş olmayan gönderemez; gönderen yolladığını okuyamaz/değiştiremez.
  await assertFails(setDoc(doc(as("c"), "users/a/inboxNotes/i5"), not({ fromUid: "c" })));
  await assertFails(getDoc(doc(as("b"), "users/a/inboxNotes/i1")));
  await assertFails(updateDoc(doc(as("b"), "users/a/inboxNotes/i1"), { body: "y" }));
});

test("F71.2 AI kotası: sayaç geri alınamaz, silinemez, başkası okuyamaz", async () => {
  await seed((db) =>
    setDoc(doc(db, "aiQuota/a"), { dayStart: Timestamp.now(), points: 50 }),
  );
  const q = doc(as("a"), "aiQuota/a");
  await assertFails(updateDoc(q, { points: 0 }));
  await assertFails(updateDoc(q, { points: 50 }));
  await assertSucceeds(updateDoc(q, { points: 51 }));
  await assertFails(updateDoc(q, { points: 1001 }));
  await assertFails(updateDoc(q, { points: 52, ek: "x" }));
  await assertFails(deleteDoc(q));
  await assertFails(getDoc(doc(as("b"), "aiQuota/a")));
});

// ── Storage ────────────────────────────────────────────────────────────

const store = (uid) => env.authenticatedContext(uid).storage();
const png = { contentType: "image/png" };

test("F71.2 Storage: klasör sohbeti görseli yalnız üyede, yalnız görsel", async () => {
  await seedSharedFolder();
  const yol = "folderChats/f1/g.png";
  await assertSucceeds(uploadString(ref(store("b"), yol), "veri", "raw", png));
  await assertSucceeds(getBytes(ref(store("a"), yol)));
  await assertFails(getBytes(ref(store("p"), yol)));
  await assertFails(getBytes(ref(store("x"), yol)));
  await assertFails(uploadString(ref(store("x"), "folderChats/f1/x.png"), "veri", "raw", png));
  await assertFails(
    uploadString(ref(store("b"), "folderChats/f1/b.pdf"), "veri", "raw", { contentType: "application/pdf" }),
  );
});

test("F71.2 Storage: paylaşılan klasörde rol — read yükleyemez, yabancı okuyamaz", async () => {
  await seedSharedFolder();
  const yol = "users/a/notes/n1/ek.png";
  await assertSucceeds(uploadString(ref(store("a"), yol), "veri", "raw", png));
  await assertSucceeds(getBytes(ref(store("b"), yol)));
  await assertFails(uploadString(ref(store("b"), "users/a/notes/n1/b.png"), "veri", "raw", png));
  await assertSucceeds(uploadString(ref(store("d"), "users/a/notes/n1/d.png"), "veri", "raw", png));
  await assertFails(getBytes(ref(store("x"), yol)));
  await assertFails(getBytes(ref(store("p"), yol)));
  // Klasör dışındaki notun eki paylaşım üyesine kapalı.
  await assertSucceeds(uploadString(ref(store("a"), "users/a/notes/ozel/e.png"), "veri", "raw", png));
  await assertFails(getBytes(ref(store("d"), "users/a/notes/ozel/e.png")));
});

test("Storage: sahip kendi ekini yükler/okur, yabancı okuyamaz", async () => {
  await assertSucceeds(uploadString(ref(store("a"), "users/a/notes/n1/x.png"), "x", "raw", png));
  await assertSucceeds(getBytes(ref(store("a"), "users/a/notes/n1/x.png")));
  await assertFails(getBytes(ref(store("b"), "users/a/notes/n1/x.png")));
  await assertFails(uploadString(ref(store("b"), "users/a/notes/n1/y.png"), "y", "raw", png));
});

test("Storage: izinsiz dosya türü reddedilir", async () => {
  await assertFails(
    uploadString(ref(store("a"), "users/a/notes/n1/x.exe"), "x", "raw", {
      contentType: "application/x-msdownload",
    }),
  );
});

test("Storage: ortak çalışan sahibin notuna ek yükler ve okur", async () => {
  await seedSharedNote();
  await assertSucceeds(uploadString(ref(store("b"), "users/a/notes/n1/b.png"), "b", "raw", png));
  await assertSucceeds(getBytes(ref(store("b"), "users/a/notes/n1/b.png")));
  await assertFails(getBytes(ref(store("c"), "users/a/notes/n1/b.png")));
});

// F28.2-B: önizlemeler (≤ 40 KB, yalnız JPEG/PNG/WebP), sahibine açık.
test("Storage: önizleme 40 KB tavanı ve yalnız görsel", async () => {
  const jpg = { contentType: "image/jpeg" };
  await assertSucceeds(
    uploadString(ref(store("a"), "users/a/thumbs/e1.jpg"), "x".repeat(30 * 1024), "raw", jpg),
  );
  await assertSucceeds(getBytes(ref(store("a"), "users/a/thumbs/e1.jpg")));
  await assertFails(getBytes(ref(store("b"), "users/a/thumbs/e1.jpg")));
  await assertFails(
    uploadString(ref(store("a"), "users/a/thumbs/e2.jpg"), "x".repeat(41 * 1024), "raw", jpg),
  );
  await assertFails(
    uploadString(ref(store("a"), "users/a/thumbs/e3.pdf"), "x", "raw", {
      contentType: "application/pdf",
    }),
  );
  await assertFails(
    uploadString(ref(store("b"), "users/a/thumbs/e4.jpg"), "x", "raw", jpg),
  );
});
