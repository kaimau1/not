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
    setDoc(doc(as("a"), "userSearch/a"), {
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

// ── Storage ────────────────────────────────────────────────────────────

const store = (uid) => env.authenticatedContext(uid).storage();
const png = { contentType: "image/png" };

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
