# Hafıza — Veri modeli, Yedek, Ek senkronu

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Veri modeli ve Firestore
- **İleri uyum (F1.5):** `Note`/`Attachment`/`NoteItem` tanımadığını
  `extras`ta saklayıp aynen yazar; yeni alan → `knownKeys` (`forward_compat_test`).
  Bilinmeyen ek türü `unknown` + `rawKind`.
- **`kClientDataVersion` = 3**; `config/app.minClient` konsoldan elle
  (telefonlar v1.1.N'e geçince 3).
- `merge` yazımında kaldırılabilir alan KOŞULSUZ yazılır (`fontScale`,
  `theme`, `customColor`, `cardMediaHidden`, `reminderRepeat`, `cards`…).
- Paylaşılan-yol yazımı `updatedBy == auth.uid` taşır; 'write' rolü yalnız
  `createdBy == uid` notu günceller (F1.4).
- `updateNote`: ek listesi son başarılı yazımın DERİN KOPYASIYLA aynıysa
  `attachments` yazılmaz. TUZAK: kopya şart (etkin çizgi listesi yerinde
  büyür). `localPath` Firestore'a yazılmaz.
- Ek `createdAt` boşsa `toMap` dizinin içine `serverTimestamp` yazar —
  Firestore dizide kabul etmez: paket/yedek içe aktarma (`NoteShare.import`)
  boş tarihi doldurur (F18.4).
- Çizim noktaları kayıttan `Float32List`; `toMap` `UnmodifiableListView`
  verir (tipli dizi sunucuda reddedilir); kayıttan okunanı yerinde
  değiştirme. Kalem basıncı `pressures` (`q`).
- 1 MiB sınırı: ≥ 900 KB'ta uyarı; yazım reddi yutulmaz.
- **Ağır alanlar ayrı belgede (F3.13):** ek `ink/bubbles/pdfMarks` 16 KB'ı
  aşınca `notes/{id}/heavy/data`, ana belgede `heavyRef`. Liste akışı HAFİF
  not verir (`heavyMissing`); dışarı metin/veri üreten her yol önce
  `hydrateNote` (paylaş, kopya, toplu seçim — F18.12, yedek). Hafif not
  yazılırken ağır belgeye dokunulmaz. Kalıcı silme / yalnız bu cihaz / hesap
  silme alt koleksiyonları (`heavy`, `versions`, `presence`) ayrıca siler
  (`_deleteCloudCopy`).
- `starred` sabitlemeden ayrı; `frameColor` yalnız ana ekran kartında.
- Defter = `Note.paged` (+ `archivePaper`); eski defter `notebookToPagedNote`.
  Bir defalık göçler `data_migrations.dart` (bayrak cihazda; `updatedAt`e
  dokunmaz). Çizgili kâğıt satırı İÇERİKTEN çizer (`RuledLines`).
- Madde ayırıcı `NoteItem.divider` = `tür|c:AARRGGBB|w:1.50`; satırı çizen
  YENİ alan `_cachedItemRow` anahtarına + `sameItemsVisually`e.
- Sayfalar `textPages`: ETKİN sayfa içeriği `body/items`'ta; ilk sayfa
  kimliği ''. Kopya (`duplicateNote`) sayfaları da taşır (F18.8 yakaladı).
- Satır içi biçim metnin İÇİNDE işaretle (`**`, `_`, `~`, `==k:`, `%%k:`,
  `##k:`, `&&k:`; özel renk `#RRGGBB`); önekli işaret öneksiz eşleşmez.
- **Ek etiketi / not bağlantısı:** metinde `📎 etiket`, notta `tagLinks`
  (label → `attachmentId`). Not bağlantısında kimlik `note:<id>` (F18.16) —
  bağ KİMLİKLE, başlık değişse de kalır; eski sürüm düz metin görür. Geri
  bağlantılar istemcide türetilir (`backlinksTo`). `[[` not seçiciyi açar.
- Yerel notlar `LocalNotesStore` (haritayı yerinde değiştirme).
- `authStateProvider` `userChanges` üzerinden (anonim → Google bağlanınca
  uid aynı, `authStateChanges` tetiklenmez).
- Hesap silme listeleri `AccountService`'te; yeni koleksiyon
  `account_deletion_test`i kırar (bilinçli). `premiumUntil` istemciden
  yazılamaz. Kural tuzağı: `{document=**}` sıfır parçayı da eşler.
- Sürümler (F4.2) `notes/{id}/versions` yalnız metin, 30 tavan. Eşzamanlı
  düzenleme üç yönlü birleştirme (`text_merge.dart`), `presence/{uid}`.
- Ayar senkronu `users/{uid}/meta/prefs.values`; cihaza özgü anahtar
  (kalem, uygulama kilidi, Gelen klasörü…) listeye EKLENMEZ.
- Not kilidi (F4.8) cihaz/şifre/desen, ŞİFRELEME DEĞİL. **Uygulama kilidi**
  (F18.6, varsayılan kapalı, cihaza özgü `app_lock_*`): aynı yöntem,
  `AppLockGate` kapağı gezginin ÜSTÜNDE (bildirim/widget/kısayol açılışı
  da takılır) ve kendi `Navigator`ü var (şifre penceresi kapağın üstünde).
  Web'de cihaz kilidi yok → yalnız şifre/desenle. Biyometrik pencere yaşam
  döngüsünü oynatır: sorarken sayaç başlamaz. Android `setSecure`
  (FLAG_SECURE).
- FCM jetonu `users/{uid}/fcmTokens`; not düzenlemesi için itme yok.
- **Tekrarlayan hatırlatıcı** (F18.14): `reminderAt` hep SONRAKİ çalma,
  `reminderRepeat` dizesi (`daily`, `weekdays`, `weekly:1,3`, `monthly:31`,
  `yearly:2-29`) — ay/yıl GÜNÜ dizede (çapa kısa ayda 28'e kıstırılır).
  Servis sonraki 7 çalmayı önceden kurar (kimlik `noteId#k`), geçmişte
  kalanı nota ilerletir; "Tamam" sonrakine kaydırır, "Ertele" tek seferlik
  `#snooze` bildirimi (reminderAt'i kaydırmak saati kaydırırdı).
  `orphanReminderIds` not başına kimlik KÜMESİ alır. Yeni planlı bildirim
  türünün yükü `note:` ile BAŞLAMAZ. Eski istemci yalnız ilk çalmayı bilir.
- **Takvim + görevler** (TAKVIM_PLANI, 2026-11-06, K1–K10 hepsi önerilen):
  `lib/features/calendar/`. Koleksiyonlar `events`, `tasks`, `taskLists`,
  `dayLinks/{YYYY-MM-DD}` (genel `users/{uid}/**` kuralı yeter; silme listesinde).
  `Note`'a alan EKLENMEDİ: bağ kayıt tarafında (`noteIds`, `noteId`, `dayLinks`).
  Tüm gün = gün dizesi, bitiş HARİÇ; tekrar `Recurrence` = `reminderRepeat`
  dizesi + `;every=;until=;count=` (notlara YAZILMAZ). Tekrarlı görevi
  tamamlamak ilerletir + geçmiş kopyası (`completeTask`). Veri küçük: dört
  koleksiyon tek dinleyici, aralık bellekte (`buildAgenda`). Takvim bildirimi
  `ReminderService`te, yük `cal:` (yalnız cihazda). Rayda Hatırlatıcılar'ın
  yerine Takvim (`/reminders` takvim bölümü sayılır).
  Görünümler yıl/ay/hafta/ajanda; iki parmak `PinchZoomDetector` = `Listener`
  (yarışmaya girmez, kaydırma bozulmaz; iki parmak inince `PageView`
  kilitlenir). Hedef `ZoomTargets` (GlobalKey → tarih). TUZAK: aynı görünümü
  yeniden açmak (aynı tür iki sayfa geçişte birlikte) GlobalKey çakıştırır —
  aynı görünüme geçiş engelli; eski görünümün `itemBuilder`ı `_view`i değil
  yerel kopyayı okur.
- **Aralıklı tekrar kartları** (F18.19, kullanıcı: basit sürüm): `Note.cards`
  (`StudyCard`, SM-2 `reviewCard`), yeni koleksiyon yok (hesap silme/kural
  değişmedi). Editör ⋮ "Kart üret" (AI), `/cards` "Bugünün kartları".

### Zamanlı not `expiresAt` (2026-11-16, oto/sureli-not)
- Not alanı `expiresAt` (Timestamp, isteğe bağlı). Süre dolunca `NotesRepository.archiveExpired` → `archivedAt = expiresAt` (şimdi değil: iki cihaz aynı değeri yazar, idempotent) + `expiresAt: null`. Tetik: `notesStreamProvider` her yayın (O(n) tarama) + dashboard öne geliş. Açık editördeki not atlanır. Arka plan işi YOK (uygulama kapalıyken arşivlenmez, açılışta olur).
- `toMap` boş süreyi YAZMAZ (S16 bayt bütçesi) → kaldırma her zaman açık `{'expiresAt': null}` (`setExpiry`, editör `_clearExpiry`, `setArchived(true)`/`setArchivedAll`, editör `_toggleArchive`). Editör uzak birleştirmesi `expiresAt`ı benimser; iki "aynı mı" karşılaştırmasında var. Kural değişmedi (not alanları serbest).
- Kart ⋮ menüsüne EKLENMEDİ: menü boyu bekçisi (`note_menu_sheet_height_test`) ve S37 aşılıyordu; yer editörün "+" menüsü (Hatırlat'ın grubu). Test `test/sureli_not_test.dart`.

## Yedek ve içe aktarma (F18.4/F18.5/F18.15, 2026-11-02)
- Tam yedek `.notyedek` (ZIP): `yedek.json` (`kind: full-backup`, not
  girdisi = `encodeNoteJson` + hesap alanları + içerik özeti) +
  `dosyalar/<not>/<ek>`. Cihazda `FileBackupSink` dosyaya akıtır, web'de
  bellekte. Geri yükleme kimlik / `restoredFrom` / içerik özetiyle (`noteDigest`:
  tür+başlık+gövde+madde) çift kaydı atlar; klasörler ADLA eşlenir. Eski
  JSON yedek de okunur (`sniffBackup`: `PK` / `{`). Kilitli not varsa dışa
  aktarma kimlik ister.
- `BackupService` arayüzden bağımsız; misafir → var olan Google hesabı
  (`credential-already-in-use`) "Notları yanıma al": giriş ÖNCESİ bellekte
  yedek, sonra hedefe yükleme. Misafirin bulut kopyası kalır (oturum
  değişince silinemez).
- İçe aktarma `import_service.dart`: Keep Takeout (renk eşlemesi, sabit,
  arşiv, çöp, etiket, görsel/ses, tarih), Markdown/txt (`# başlık`,
  `- [ ]`, `__x__`→`**x**`, `*x*`→`_x_`), Evernote `.enex` (ENML → metin).
  Aynı özet atlaması.
- **KÖK NEDEN (P60, 2026-11-14: taze kurulumda 240 notluk Keep içe
  aktarmasından 67 not sessizce kayboldu, ikinci deneme "67 içe aktarıldı").**
  `cloud_firestore` Android eklentisi her yazımı `cachedThreadPool`ta AYRI iş
  parçacığında başlatır (`FlutterFirebaseFirestorePlugin.java`
  `documentReferenceSet`): Dart'ta art arda verilen iki yazımın SIRASI
  garanti DEĞİL. `NoteShare.import` önce beklenmeyen boş `createNote`
  (birleştirmesiz `set`) sonra içerikli `updateNote` yazıyordu; boş yazım geç
  düşünce içerik silindi, boş not 2 dk sonra `cleanupEmptyNotes`la gitti.
  Artık `newNoteId()` + TEK `updateNote` (`createdBy` `extras`te); bekçi
  `import_service_test` "geç düşen ilk yazım" (ilk yazımı geciktiren sarmalayıcı).
  **Kural:** aynı belgeye beklenmeyen yazımdan hemen sonra çakışan alanlı
  ikinci yazım verme — not tek yazımda doğsun (`createNote(title/body/items)`
  ya da `newNoteId`). `createNote`+hemen `updateNote` yapan diğer çağıranlar
  (gmail, asistan, editör eylemleri) aynı riski taşır — açık iş.
  "Hepsi Bugün'de" hata DEĞİL: kovalar `updatedAt`'e göre (`dateBuckets`).

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- `CustomizeModeHost` alanın kendi boyunu `MediaQuery.size` verir (alt çubuk
  ekran dışına itiliyordu).

## Güvenlik denetimi (Faz 71, 2026-11-11)

- Rapor `docs/guvenlik_denetimi.md`, tehdit modeli `docs/guvenlik.md`. Yeni dışa açık
  bileşen / kural eşleşmesi / kilitli notu gösteren yüzey eklerken
  `test/security_guard_test.dart` kırmızı olur: liste aynı commit'te güncellenir.
- **Kök neden (G-01):** kuralın YORUMU doğrulamayı anlatıyordu, kuralın kendisi yapmıyordu
  (`userDirectory` kimliği e-postayla karşılaştırılmıyordu). Kural yorumuna güvenme; her
  "yapamaz" cümlesinin `rules-test`te bir `assertFails`i olsun.
- İstemcinin yazdığı "ben kimim" alanları (e-posta) kuralda `request.auth.token.email` ile
  karşılaştırılır (`tokenEmail()`); misafirde ikisi de boş, eşleşir. Yalnız Google girişi
  var — başka giriş yolu eklenirse `email_verified` şartı gözden geçirilmeli.
- Kural testi yerelde: Java yok sanma — Android Studio JBR:
  `JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"`. `npm test` sonunda kapsam özeti.
- CI `guvenlik` işi uyarı düzeyinde (işi düşürmez); yanlış alarm `.gitleaks.toml`.
  Action sürümü yükseltirken etiketi değil SHA'yı değiştir
  (`gh api repos/<sahip>/<ad>/commits/<etiket> --jq .sha`).
- **Acil not (`Note.urgent`, alan `urgent`, 2026-11-16):** sabit/yıldız gibi not bayrağı; ana
  ekranda `homeSections` (note.dart) sırası acil → sabit → diğer (acil+sabit yalnız acilde),
  kartta ünlem (durum simgeleri kapalıyken de). `toMap` alanı YALNIZ açıkken yazar (S16 bayt
  bütçesi) — merge yazımı eksik alanı silmediği için kapatma `NotesRepository.setUrgent(false)`
  ile açıkça yazılır (editörde `_setUrgent`). ⋮ menüsüne konmadı: levha boyu bütçesi
  (`note_menu_sheet_height_test`, S37) aşıldı; yalnız + levhası, editör göstergesi ve kart sağ tık.
  PDF balonunun `PageBubble.urgent`'iyle ilgisi yok.

## 2026-11-17 — Senkron maliyeti S2/S3 + korkuluklar
- Otomatik kayıt sıklığı `lib/core/save_cadence.dart` (`SaveCadence`): sessizlik 2 sn, aralıksız
  yazımda üst sınır 20 sn (10 idi). `config/app` isteğe bağlı `saveDelaySec` (2–120) /
  `saveMaxWaitSec` (sessizlik–300) = UZAKTAN FREN; yeni açılan editörde geçerli. İstemci yazamaz.
  Bu iki alan kullanıcıya ait karar; `minClient`/`inkV2Write` kuralı (HAFIZA 17) aynen geçerli.
- Sürüm budama sorgusu (40 belge okur) oturumda notun 1., 6., 11.… sürümünde (`_versionAdds`).
- Ortak düzenleme nabzı arka planda durur (`AppLifecycleListener` onHide/onShow).
- Bekçi: `test/idle_write_guard_test.dart` — editör 2 dk boşta → updateNote/updateFields 0.
- Yapılmadı (bilerek): kuralda yazma hız sınırı — reddedilen yazım çevrimdışı kuyrukta yerel
  değişikliği geri alır (veri kaybı). S1 → aşağıdaki bölüm (P67).

## 2026-11-17 — S1 "yalnız değişeni dinle" (P67, bayrak KAPALI)
- **Damga:** her not belgesi yazımı `syncAt: serverTimestamp` (`kSyncAtField`, `note.dart`).
  `updatedAt` YETMEZ: istemci saatiyle yazılabiliyor (F22.3), sıralama/ek sonucu dokunmuyor.
  Yazanlar: `Note.toMap`, depodaki her `updatedBy` yazımı, klasör silme, video transkript
  işçisi, Kotlin `YerelNot.belge` + `HaritaNotlari`. Bekçi `test/notes_sync_stamp_test.dart`
  (kaynak sayımı dahil). YENİ yazım yolu damgasızsa bayrak açık cihazda değişiklik GÖRÜNMEZ.
- **Akış** `notes_delta_sync.dart` (`NotesDeltaFeed`): liste `deletedAt==null` sorgusunu
  `ListenSource.cache` ile dinler; imleç = önbellekteki en büyük `syncAt` (sunucu saati;
  bekleyen yazımın damgası null → sayılmaz); besleyici `syncAt > imleç−10 dk` (tek alan dizini,
  `firestore.indexes.json` değişmedi, kural değişmedi); `count()` güvenlik ağı.
  Eski yola dönüş (bugünkü sunucu dinleyicisi, `reset` ile liste sıfırdan): önbellek boş ·
  damga yok · imleç >30 gün (cihaz saatiyle; ileri saat = güvenli taraf) · sayım alınamadı
  (çevrimdışı) / tutmadı · besleyici ya da önbellek dinleyicisi hatası.
- **Bayrak:** `config/app.syncDeltaListen` (yalnız `true` açar) → `saveCadenceSyncProvider`
  yerele `sync_delta_listen` yazar → SONRAKİ açılışta geçerli. **2026-11-22 (kullanıcı kararı): VARSAYILAN AÇIK** — alan yok = açık, yalnız `syncDeltaListen: false` kapatır. Yerel geri alma prefs
  `sync_delta_off=true`. Kapalıyken `watchNotes()` kodu eskisinin aynısı.
- **Okuma hesabı** (sahte Firestore, önbellek ayrı sahte DB; `notes_delta_sync_test`):
  300 not soğuk açılış: önce 300 okuma → sonra 0 değişiklik 2, 5 değişiklik 6, 50 değişiklik
  51 (değişenler + örtüşmedeki son not + 1 sayım). Günde 3 soğuk açılışta ~900 → ~10–20.
- **Bilinen sınır:** oturum sürerken başka cihazda doğrudan KALICI silinen (senkronu kapat)
  not bu oturum boyu listede kalır; sonraki açılışta sayım tutmaz → eski yol. O hayalet not
  düzenlenirse buluta yeniden yazılır (diriliş; kayıp değil).
- **Açmadan önce (cihaz bekliyor):** (1) bütün istemciler damgalı sürümde → `minClient`
  yükseltilmeden AÇMA (eski istemci damgasız yazar, değişikliği görünmez); (2) iki cihaz
  (tablet + web) testi: düzenleme, çöpe at/geri al, çevrimdışı düzenleme sonra bağlan, saat
  farkı, uzun kapalı cihaz, senkronu kapat, hesap değiştir; (3) `ListenSource.cache` dinleyicisinin
  besleyiciden dolan önbelleği gösterdiği cihazda doğrulanmadı (sahte Firestore ayırmıyor).

## Hak (entitlement) — PL14 (2026-11-18, P71)
- **Belge:** kök `entitlements/{uid}` = `tier` (free|pro|lifetime), `proUntil`, `trialEndsAt`,
  `lifetimeOwned`. Kural: sahibi `get`, `list`/yazma YOK (Admin SDK yazar). `users/{uid}`
  içinde DEĞİL: o belge istemciden silinebiliyor, deneme sıfırlanırdı (aiQuota ile aynı kök neden).
  Hesap silmede `keptCollections`'ta; silmeyi sunucu yapar (`functions/entitlements.js` taslağı).
- **İstemci:** `lib/features/entitlement/` — `EntitlementGate.active = PlayBuild.enabled`;
  bayraksızda `entitlementProvider` Firestore'a HİÇ gitmez, `proFeatureProvider` hep `true`.
  Okunamayan/eksik belge = ücretsiz (Pro vermemek güvenli). Deneme/Pro bitiş anında sağlayıcı
  kendini yeniler (Timer, en çok 20 gün).
- **Yanlış yol (test):** Riverpod 3 dinleyicisiz `StreamProvider`'ı duraklatır; `read(.future)`
  takılır → testte önce `container.listen`.
- **Eski `users/{uid}.premiumUntil`**: kişisel APK'da aynen; Play'de `premiumProvider` = hak belgesindeki Pro
  (P85, 2026-11-20).
## Satın alma — PL6 (2026-11-20, P85; Play'de denenmedi)
- **Yazan yalnız Function:** `functions/billing.js` `verifyPurchase` (onCall, App Check) + `playRtdn` (Pub/Sub);
  `index.js` YALNIZ `PLAY_PACKAGE_NAME` varken bağlar — kişisel proje deploy'una girmez. Gizli anahtar yok (ADC +
  Play Console izni). Saf birleştirme `billing_util.mergeEntitlement` (`node --test`).
- **Kalıcı kurallar:** doğrulanamayan satın alma ONAYLANMAZ (Play 3 günde iade eder); belirteç `purchaseTokens/{sha256}`
  ile tek hesaba bağlı, Play doğrulamadan YAZILMAZ; plan değişiminde eski belirtecin bitişi yenisini ezmez
  (`subTokenKey`), ömür boyunu yalnız onu veren belirtecin iadesi kaldırır (`lifetimeTokenKey`); elle Pro `grantUntil` (satın alma kısaltmaz); misafire satılmaz. Durum hep API'den okunur, RTDN
  türüne güvenilmez.
- **İstemci:** `billing_service.dart` — `BillingNotifier.debugStore/debugVerify` test kancası; bayraksızda
  `InAppPurchase.instance` HİÇ çağrılmaz (çağrılsa Billing bağlantısı açılırdı: `BillingClientManager` kurucuda
  bağlanır). Açılışta 20 sn sonra sessiz onarım (yalnız Play kademesi).
- **Yanlış yol (test):** iki kapsayıcı aynı sahte mağazanın yayın akışını dinlerse birinin geri yüklemesi öbürüne
  de düşer → her kapsayıcıya ayrı sahte mağaza. Play koşusu `--dart-define=NOTLAR_PLAY=true`; CI bayraksız koşar.
- **KARAR (sabah bakılacak):** deneme = Play'in 7 gün teklifi, `startTrial` bağlı değil; yalnız AI kapısı bağlı.

## Lite eşitleme + ek deposu kapısı (P99, 2026-11-23; `lite_sync.dart`)
- **Kapı:** `liteSyncProvider = !proFeature(instantSync)`; bayraksız derlemede (kişisel APK/web) hep false → editör yolu
  AYNEN. Seyrelen YALNIZ editörün otomatik kaydı: `_mutate` Lite'ta `_debouncer.delay = maxWait =
  SaveCadence.liteInterval` (5 dk, `config/app.liteSaveSec` 30–900 freni) kurar; kapanış / arka plan (`_saveNow`) /
  bulut simgesine dokunuş ("şimdi eşitle") hemen yazar. Kart eylemleri (yıldız, arşiv…), okuma/dinleme değişmez.
- **Veri kaybı güvencesi:** Firestore yerel önbelleği ağdan AYRILAMAZ (yazım = hemen ağa), bu yüzden bekleyen
  içerik `lite_pending_<uid>.json` GÜNLÜĞÜNE (`LocalNotesStore.journalFor`, yerel-not deposu DEĞİL) eski sıklıkla
  (2 sn / 20 sn) yazılır; her `updateNote` girdiyi siler; açılışta `liteJournalRecoveryProvider` artığı yazar
  (çöpteki/olmayan nota dokunmaz). Web'de günlük yok → `journalReady=false` → seyreltme HİÇ yapılmaz.
- **Anında kalanlar:** başkasının notu (`ownerId`), benim paylaştığım not/klasör (`noteSharedByMe`; paylaşım
  bilgisi henüz yüklenmediyse "paylaşılıyor" sayılır), yalnız-cihaz not.
- **Ek deposu:** `attachmentSyncModeFor(cloudAttachments:)` — Pro (YALNIZ Play: `EntitlementGate.active`) → Storage;
  hak yoksa Google → Drive, misafir → yalnız cihaz. Storage'daki eski ekler okunur kalır/silinmez; Drive'a
  yüklenmiş eskiler Pro'da da okunur (`driveStoreProvider` Google+bağlıyken kurulur). Drive bağlı değilse mevcut
  şerit + otomatik izin sorusu + ilk giriş levhası devreye girer. Paylaşılan notun YENİ ekleri Lite'ta da
  Storage'a gider (ortak çalışan Drive'a erişemez) — sabah bakılacak (T11 "Lite'ta Storage kapalı" ile gerilim).
