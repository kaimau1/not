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
