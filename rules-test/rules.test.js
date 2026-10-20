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
const { doc, getDoc, setDoc, updateDoc, deleteDoc } = require("firebase/firestore");
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
