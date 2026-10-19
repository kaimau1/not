# YOL HARİTASI — dış göz incelemesinden çıkan fazlı iş planı

Kaynak: 2026-10-19 kapsamlı inceleme (kod değiştirilmeden yapıldı; rapor
özeti en altta, **Ek A**). Fazlar **ayrı oturumlarda, sırayla** yapılır.

## Bu dosya nasıl kullanılır (her faz oturumu için)

Kullanıcı "Faz N'i yap" dediğinde:

1. Bu dosyayı ve HAFIZA.md'nin son girdilerini oku. Yalnız **Faz N** maddeleri
   yapılır; kapsam dışına çıkılmaz. Bir sonraki faza kendiliğinden geçilmez.
2. Satır numaraları 2026-10-19 hâlidir, kayabilir — önce `grep` ile yeri bul,
   kök nedeni koddan doğrula, sonra düzelt.
3. **KARAR GEREKİR** etiketli maddede önce kullanıcıya kısa öneri sun, onay al.
4. Her madde: düzeltme + mümkünse test. Faz sonunda `flutter analyze` temiz,
   `flutter test` tamamen yeşil olmadan "bitti" denmez.
5. Kullanıcı "bitti / kaydet" dediğinde (ya da faz tamamlanınca):
   - maddeleri `[x]` yap, altına 1-2 satır **Yapıldı:** notu (ne, hangi dosya);
     yapılamayanı `ERTELENDİ: neden` ile işaretle,
   - aşağıdaki **Durum** tablosunu güncelle,
   - kalıcı karar / kök neden / tuzakları HAFIZA.md'ye (tarihli) yaz,
   - cihazda doğrulanması gerekenleri KALANLAR.md'ye ekle,
   - commit + push.
6. "Senin yapacakların" maddeleri kullanıcının konsol/cihaz işidir — oturum
   bunları yapamaz, yalnız hatırlatır.

**Flutter:** Windows'ta `C:\src\flutter\bin\flutter.bat` (PATH'te değil).
Bulut oturumunda SDK YOK: CI ile aynı sürümü indir —
`curl -o f.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.44.6-stable.tar.xz`
(1,5 GB) → scratchpad'e aç → `PATH` başına `.../flutter/bin`. **3.47+ KULLANMA**:
`pdfrx 1.3.5` orada derlenmiyor (bkz. F3.15). 2026-10-19 ölçümü: 3.44.6 ile
analiz temiz, 1327/1327 test, ~195 sn. `pub get` `pubspec.lock`'u değiştirirse
commit'e katma.

**Dağıtım:** `firestore.rules`, `storage.rules` ve `functions/` yalnız **main'e
push**ta CI'ın `deploy` işiyle yayınlanır. APK yalnız main'de, başlığında
`[apk]` geçen commit'le derlenir.

## Durum

| Faz | Konu | Durum | Tarih | Not |
|---|---|---|---|---|
| 1 | Güvenlik, gizlilik, veri bütünlüğü, hatalar | Bitti | 2026-10-19 | F1.5(d) ertelendi; cihaz doğrulaması KALANLAR'da; APK derlenmedi |
| 2 | Akıcılık / performans | Bekliyor | — | |
| 3 | Sadeleştirme ve birleştirme | Bekliyor | — | çoğu madde KARAR GEREKİR |
| 4 | Eksik özellikler, test altyapısı, Play | Bekliyor | — | |

---

## FAZ 1 — Güvenlik, gizlilik, veri bütünlüğü, hatalar

- [x] **F1.1 Kullanıcı dizini taranabiliyor (YÜKSEK).**
  Web'e giren herkes ilk açılışta otomatik anonim hesap alıyor
  (`login_screen.dart:48`), `searchUsers` yalnız `request.auth` var mı diye
  bakıyor (`functions/index.js:40-44`) ve her Google kullanıcısı onayı
  sorulmadan `userSearch`'e ad+e-postayla yazılıyor
  (`friends_repository.dart:107-118`, her açılış/öne gelişte). "ab", "ac"…
  sorgularıyla 15'er 15'er tüm e-postalar toplanabilir.
  Yap: (a) anonim token'ı reddet
  (`request.auth.token.firebase.sign_in_provider === 'anonymous'`);
  (b) uid başına hız sınırı (ör. dakikada 10, sayaç belgesi Admin SDK'yla);
  (c) **KARAR GEREKİR** — eşleşme: yalnız TAM e-posta mı, yoksa ad için en az
  3 harfli önek mi; (d) **KARAR GEREKİR** — Ayarlar'da "Adımla/e-postamla
  bulunabilirim" anahtarı (öneri: varsayılan kapalı; kapalıyken `userSearch`
  belgesi silinir, tam e-postayla `userDirectory` araması yine çalışır).
  Bitti ölçütü: anonim çağrı `permission-denied`/`unauthenticated` döner,
  anahtar kapalıyken belge yok.
  **Yapıldı (2026-10-19):** `functions/index.js` anonim red + `rateLimits/{uid}` (dk/10) + `search_match.js` (e-posta TAM, ad ≥3 harf kelime öneki — kullanıcı kararı); Ayarlar → Kişiler "Adımla bulunabilirim" (`discoverableProvider`, varsayılan AÇIK — kullanıcı kararı), kapalıyken `userSearch/{uid}` silinir.

- [x] **F1.2 Hesap silme eksik siliyor (Play + KVKK).**
  `account_service.dart:43-49` listesi şunları atlıyor: `userSearch/{uid}`
  (silinen kullanıcı aranabilir kalıyor!), `noteShares` (`ownerId == uid`),
  sahip olunan `folderShares/{id}/messages` alt koleksiyonu ve Storage
  `folderChats/{folderId}/` görselleri (folderShares silinmeden ÖNCE), Drive
  `appDataFolder` dosyaları (bağlıysa), `aiQuota/{uid}` (kural silmeye kapalı —
  kişisel içerik yok; bırakılabilir, HAFIZA'ya not düş).
  Bitti ölçütü: silinen koleksiyon listesi tek sabitte, testte doğrulanıyor.
  **Yapıldı:** `account_service.dart` tek sabit listeler + `test/account_deletion_test.dart` (koddaki/kurallardaki her koleksiyon listede); folderShares+messages+`folderChats/` Storage, noteShares, userSearch, Drive appDataFolder (`DriveStore.deleteAllAppData`). `aiQuota`/`rateLimits` bilerek kalır (HAFIZA).

- [x] **F1.3 Gizlilik politikası ve Play izinleri.**
  `PRIVACY_POLICY.md`: kaldırılmış Gmail anlatılıyor (`:35`), "konum
  toplanmaz" deniyor (`:46`) ama konum hatırlatıcısı + arka plan konum izni
  var; "başka kullanıcılarla paylaşılmaz" deniyor ama ad/e-posta aranabilir,
  klasör/ortak not/gelen kutusu var; AI bölümü yalnız Gemini diyor ama BYOK'ta
  OpenAI/Anthropic/OpenRouter'a da gidiyor; Drive ve misafir hesap kısmen var.
  Yeniden yaz (uygulama içi `/privacy` aynı dosyayı gösteriyor), tarihi güncelle.
  Manifest: `USE_EXACT_ALARM` kaldır (Play yalnız alarm/takvim uygulamasına
  izin veriyor; `SCHEDULE_EXACT_ALARM` kalsın — izin yoksa hatırlatıcının
  inexact'e düştüğünü doğrula), `AndroidManifest.xml:10`.
  **Yapıldı:** `PRIVACY_POLICY.md` yeniden yazıldı (19 Ekim 2026); `USE_EXACT_ALARM` kaldırıldı, inexact yedeği `reminder_service.dart`ta doğrulandı.

- [x] **F1.4 Klasör "yalnız yazma" rolü fazla yetkili + `updatedBy` sahte olabilir.**
  `firestore.rules:206-213`: 'write' rolündeki kişi notları OKUYAMAZ ama
  klasördeki HERKESİN notunu güncelleyebilir (üstüne yazma, `deletedAt` ile
  çöpe atma). Yap: notlara `createdBy` (oluşturmada `== request.auth.uid`
  zorunlu); 'write' rolünde güncelleme yalnız `resource.data.createdBy ==
  request.auth.uid` iken; 'both' değişmez. Paylaşılan yollarda (klasör + ortak
  not) `request.resource.data.updatedBy == request.auth.uid`. ÖNCE istemcinin
  bütün yazım yollarının `updatedBy`'ı gerçekten yazdığını doğrula
  (`notes_repository.dart:409,463,487,528,866,884` + başka yazan var mı) —
  yoksa meşru yazımlar reddedilir. Eski notlarda `createdBy` yok → 'write'
  rolü onları güncelleyemez (kabul edilebilir, HAFIZA'ya yaz).
  **Yapıldı:** `createdBy` (createNote/duplicate), kural: 'write' yalnız kendi notunu; klasör + ortak notta `updatedBy == auth.uid`, `createdBy` değişmez. Eksik `updatedBy` iki yola eklendi (`reorderNotes`, `patchAttachment`).

- [x] **F1.5 Eski istemci yeni veriyi bozuyor (YÜKSEK).**
  Bilinmeyen ek türü sessizce `image` oluyor (`attachment.dart:30-33`),
  `fromMap` tanımadığı alanları atıyor (`:1015`), diziler bütün yazıldığı için
  eski sürüm (özellikle elle derlenen Windows) bir notu kaydedince transkript
  eki `kind: image` + metinsiz geri yazılabiliyor.
  Yap: (a) `Attachment`, `NoteItem` (ve `Note` üst alanları) tanımadıkları
  anahtarları saklayıp `toMap`'te AYNEN geri yazsın; bilinmeyen tür kimliği
  korunsun, arayüzde "Bu ek için uygulamayı güncelle" kutusu, dokunulmaz;
  (b) notlara `schema` sürüm alanı; (c) **en düşük sürüm kapısı**: Firestore
  `config/app {minBuild}` (kural: herkes okur, kimse yazamaz) — `package_info`
  build numarası küçükse "Güncelle" ekranı (GitHub Releases bağlantısı),
  notlar salt okunur; (d) isteğe bağlı: "Yeni sürüm var" kartı (GitHub Releases
  `latest`). Test: bilinmeyen alan/tür içeren harita → `fromMap` → `toMap`
  birebir aynı.
  **Yapıldı:** (a) `extras` + `knownKeys` (`Attachment`, `NoteItem`, `Note`), `AttachmentKind.unknown` + `rawKind`, "uygulamayı güncelle" penceresi; (b) `schema: 1`; (c) **plandan sapma**: `config/app.minClient` ↔ `kClientDataVersion` (`core/app_update.dart`) — derleme numarası Windows/web'de hep 1; şerit + editör salt okunur; kural `config/` herkes okur, kimse yazamaz. (d) ERTELENDİ: isteğe bağlıydı. Test: `forward_compat_test.dart`.

- [x] **F1.6 1 MiB belge sınırına karşı koruma yok.**
  Çizim noktaları, balonlar, transkriptler (`Attachment.maxTextChars` tek ek
  için 120 bin, toplam için sınır yok — `attachment.dart:683`) ve sayfa
  notları tek belgede; sunucu reddi yutuluyor (`notes_repository.dart:493`).
  Yap: yazımdan önce `toMap` boyut tahmini; ~900 KB üstünde kullanıcıya
  uyarı (en büyük kalemi söyleyerek); yazım reddi yutulmasın, kullanıcıya ve
  F1.9 günlüğüne düşsün. (Kalıcı çözüm F3.13.)
  **Yapıldı:** `core/utils/firestore_size.dart` + `NotesRepository._checkSize` (≥900 KB, en büyük kalem adıyla) + `writeIssues` → `NoteWriteIssueListener`; ret yutulmuyor (günlük + Crashlytics + bildirim). Test: `note_size_test.dart`.

- [x] **F1.7 Doğrudan hatalar (Flutter 3.47 analizinin yakaladıkları).**
  `try` içinde `await`siz dönen Future → hata `catch`'e düşmüyor:
  `note_speech.dart:55-59` (bozuk PPTX okumayı düşürüyor — niyetin tersi),
  `drive_store.dart:506`, `scan/scan_deskew.dart:81`, `folder_sheets.dart:166`.
  `notes_repository.dart:493`: `onError` `String?` döndürüyor → yazım
  reddinde ikinci, yakalanmamış hata. Bitti ölçütü: 3.47.7 ile
  `flutter analyze` bu 6 uyarıyı vermez (yalnız analiz; 3.47'de test koşmaz).
  **Yapıldı:** 4 dosyada `return await`; `notes_repository` `onError` blok gövde. 3.47.7 ile `flutter analyze` temiz (bir beşinci yer daha çıktı: `note_speech.dart` PDF dalı — düzeltildi).

- [x] **F1.8 Türkçe aramada ı/I ve aksan.**
  `notes_providers.dart:1138` `_matches` (ve sorgu `:943`) `toLowerCase`
  kullanıyor: `'ILIK SU'` içinde `'ılık'` BULUNMUYOR (denendi). Ortak
  `foldForSearch()` (core/utils): ı/I/İ→i, ş→s, ğ→g, ü→u, ö→o, ç→c, â/î/û;
  iki tarafa da uygula. Eşleme 1:1 karakter kalsın (vurgulama indeksleri
  bozulmasın). Diğer aramalar: `grep -rn "toLowerCase().contains"` (not içi
  bul, not arama levhası, klasör/etiket, kılavuz, ayar araması). Test:
  ılık/ILIK, alışveriş/alisveris, İstanbul/istanbul.
  **Yapıldı:** `core/utils/search_fold.dart` `foldForSearch` (editördeki eski kopyanın yerine), 12 arama noktası. Test: `search_fold_test.dart` (+ `in_note_find_test` beklentisi güncellendi).

- [x] **F1.9 Hata günlüğü (harici SDK yok).**
  Hiç hata raporlama yok (`FlutterError.onError`/`PlatformDispatcher.onError`
  yok), yazım hataları yutuluyor. Yap: iki işleyici + yutulan yazım
  hataları → cihazda halka tampon (son ~200 kayıt, dosyada);
  Ayarlar → Hakkında → "Hata günlüğünü paylaş". **KARAR GEREKİR**: ileride
  Crashlytics (gizlilik politikası "analitik yok" diyor).
  **Yapıldı:** `core/error_log.dart` + `core/crash_reporting.dart`; Ayarlar → Hakkında "Hata günlüğünü paylaş" + "Çökme raporlarını gönder". **KARAR (kullanıcı): Crashlytics ŞİMDİ** — `firebase_crashlytics` 5.2.6, yalnız Android; sonra (kullanıcı isteği) Crashlytics Gradle eklentisi 3.0.8 + google-services 4.5.0 + `android/app/google-services.json`; ayrı BoM eklenmedi (HAFIZA). Gizlilik politikası buna göre.

- [x] **F1.10 Eskimiş dokümanlar.**
  README: Gmail özelliği ve `gmail/` klasörü (`:12,60-63,99-100`), mimari
  ağacında folders/friends/inbox/web/Drive yok. CLAUDE.md: test sayısı 1191 →
  güncel sayı; bulut oturumunda Flutter kurulumu notu; graphify "commit'te
  otomatik" diyor ama depoda öyle kanca yok, grafik 2026-07-30'dan (commit
  `ebba874e`) beri bayat → ya `graphify update .` ya da iddiayı düzelt.
  YAPILACAKLAR.md: artık olmayan `Desktop\notlar-keystore\` ve CI'dan
  kaldırılmış Windows artefaktını anlatıyor → güncelle ya da sil.
  **Yapıldı:** README, YAPILACAKLAR, CLAUDE.md (test sayısı, bulut Flutter, graphify iddiası: kanca yok, grafik bayat — `graphify` bulut ortamında yok, güncellenemedi).

**Faz 1 — senin yapacakların (konsol/cihaz):**
- [x] F1.1/F1.4 kural ve fonksiyon değişiklikleri main'e girince CI deploy
  işinin yeşil olduğuna bak. (2026-10-19, koşu #467: kurallar + searchUsers
  yayınlandı.)
- [ ] **AI faturası (G2):** App Check zorlamasını aç (Play yayınından sonra);
  o zamana kadar Google Cloud konsolunda Firebase AI Logic API kotalarında
  kullanıcı başı dakika sınırını düşür. (Sunucuda kota: F4.10.)
- [ ] Play Console: arka plan konum beyanı (+ açık bilgilendirme videosu),
  gizlilik politikasını herkese açık adrese koy.
- [ ] ~~Windows sürümünü yeniden derle~~ (Windows 2026-10-19'da kaldırıldı);
  telefonları güncelle, sonra konsolda `config/app` belgesine `minClient: 1` yaz (ileride yeni veri
  biçimi gelince `kClientDataVersion` ile birlikte artırılır — bkz. F1.5).
- [ ] Firebase konsolu → **Crashlytics**'i etkinleştir; ilk `[apk]`
  derlemesinden sonra açılışta çökme yok mu bak (KALANLAR).

---

## FAZ 2 — Akıcılık / performans

- [ ] **F2.1 Türetilmiş sağlayıcılar değer eşitliği bilmiyor.**
  `allTagsProvider` (`notes_providers.dart:650`), `archivedNotesProvider`
  (`:866`), `folderNotesProvider` (`:888`), `filteredNotesProvider` (`:939`),
  `folderNoteCountsProvider` (`folder_order.dart:106`) her not yayınında YENİ
  koleksiyon döndürüyor; `Note`'ta `==` yok. Her otomatik kayıtta (0,5–3 sn)
  izleyenleri yeniden kuruluyor — geniş ekranda (tablet/web) yazarken
  liste paneli, çip satırı, klasör rafı sürekli kuruluyor.
  Yap: içerik aynıysa ÖNCEKİ örneği döndür (`listEquals` — artımlı önbellek
  değişmeyen `Note` örneklerini koruduğu için kimlik karşılaştırması yeter;
  `Notifier.updateShouldNotify` ya da `select`). Kart hücresinde not örneği
  değişmediyse widget örneğini yeniden kullan.
  Bitti ölçütü: testte, ilgisiz bir notun yazımı çip satırını/klasör rafını
  yeniden kurmuyor (yeniden kurulum sayacı).

- [ ] **F2.2 `Timer` ile animasyon → `Ticker`.**
  `pdf_viewer_screen.dart:197` ve `items_editor.dart:489` (16 ms kenar
  kaydırma), `bubble_layer.dart:3197` (30 ms yerleşim bekleme döngüsü).
  Vsync'e bağlı değil; 120 Hz'de en fazla 60 adım + titreme.
  `AnimationController`/`Ticker` ya da kare-sonrası geri çağrı zinciri.

- [ ] **F2.3 Toplu işlemler tek `WriteBatch`.**
  `dashboard_screen.dart:310-460` (sil, klasöre taşı, arşivle, sabitle,
  yıldızla, renk) not başına ayrı yazım → N akış yayını, N yeniden kurulum,
  atomik olmayan geri alma. `NotesRepository.batchUpdate(ids, fields)`;
  yerel (senkronu kapalı) notlar ayrı yoldan.

- [ ] **F2.4 Arka plan servisleri ana ekranın `build`'inden çıkar.**
  `dashboard_screen.dart:900-912` dokuz servisi `ref.watch` ile ayakta
  tutuyor; `premiumProvider` her yayınında BÜTÜN ana ekran kuruluyor.
  Oturum açıkken kökte duran bir `AppServices` bileşenine (ya da `ref.listen`
  ile) taşı; giriş ekranında (uid yokken) başlamasınlar.

- [ ] **F2.5 Kopya not tespiti ana iş parçacığında O(n²).**
  `duplicateNotesProvider` (`notes_providers.dart:309`) AI merkezi açıkken her
  not yayınında yeniden hesaplanıyor. `Isolate.run` + geciktirme, ya da sayı
  yalnız ekran açılışında/kutuya dokununca.

- [ ] **F2.6 Ölçüm altyapısı.**
  "Kasma" bulgusu 10+ turda geldi, ölçüm yok. `integration_test` +
  `traceAction`: (a) 300 notlu ana ekranda fırlatma kaydırma, (b) editörde
  200 karakter yazma; kare build/raster p90 raporu; bütçe ör. p90 < 8 ms.
  CI'da Android emülatörlü AYRI iş, yalnız `workflow_dispatch` (dakika kotası).

- [ ] **F2.7 Editörün ilk bölünmesi (P1 başlangıcı).**
  `_NoteEditorScreenState` (`note_editor_screen.dart:438`, ~8.400 satır,
  `build` ~1.580 satır 7262–8840, 41 `setState`): küçük durumlar (meşgul,
  AI görevi, bulma indeksi, kalem kipi, sabitleme vurgusu, başlık üretimi)
  `ValueNotifier` + dar `ValueListenableBuilder`'a; `build` içindeki
  denetleyici yan etkileri (zengin metin teması, ek adları, çip renkleri,
  video damgaları — ~7333-7375) not değişince çalışan tek bir yere; her
  build'de planlanan `_pulseAttachBadge` kare-sonrası çağrısı yalnız sayı
  değişince. Tam bölme F3.17.

---

## FAZ 3 — Sadeleştirme ve birleştirme (çoğu KARAR GEREKİR)

Her maddede önce kısa öneri + kullanıcı onayı. Veri modeli değişen maddeler
F1.5'in en düşük sürüm kapısı yerindeyken yapılır.

- [ ] **F3.1 Tek mikrofon** — ana ekrandaki iki benzer düğme
  (`dashboard_screen.dart:1658,1670`) + "+ → Sesli not" → tek düğme; levhada
  "Yazdır ↔ AI düzenlesin" anahtarı, son seçim hatırlanır; basılı tut = öbür kip.
- [ ] **F3.2 "+" menüsü 4 kapı** (`quick_add_fab.dart:364-472`, 19 giriş):
  Metin/Liste · **Kamera** (foto/video/tarama/QR sekmeli tek ekran) ·
  **Dosya ekle** (tek seçici, tür dosyadan; "metne dök" seçim sonrası
  seçenek) · Şablon.
- [ ] **F3.3 Tek sohbet motoru** — Sohbet ekranı, merkez sohbet kartı, Belge
  sohbeti, Beyin fırtınası, AI levhası sohbeti → kapsam çipi (Tüm notlar /
  Bu not / Bu belge / Klasör) + kip (Soru-cevap / Beyin fırtınası).
- [ ] **F3.4 Tek belge görüntüleyici** — tam ekran PDF + PDF bölmesi + defter
  PDF sayfası (slayt eşleri) tek bileşen, farklı kaplar.
- [ ] **F3.5 Defter** — `archive_note_screen.dart` (4.455 satır, ikinci editör)
  → normal notun "Sayfalı görünüm" kipi; ad "Defter" ("Arşivle" ile çakışmasın).
- [ ] **F3.6 Kavram çiftleri** — Sabitle + Yıldızla → tek kavram; Zemin +
  Çerçeve rengi → tek renk (+ isteğe bağlı vurgu). Veri göçü gerekir.
- [ ] **F3.7 Paylaşım iki kavram** — klasör paylaşımı + ortak not + arkadaşa
  gönder → "Birlikte düzenle" (not/klasör) ve "Kopya gönder".
- [ ] **F3.8 Balonlu/Klasik sorusu** (`capture_mode_sheet.dart:55`) — Ayarlar'da
  varsayılan kip; levha yalnız ilk sefer.
- [ ] **F3.9 Tek seslendirme servisi** — `speech_output`, `ai_speech`,
  `note_speech`, `listen_screen`, `speak_button` → motor: cihaz / AI.
- [ ] **F3.10 Bağımlılıklar** — `flutter_staggered_grid_view` hiç kullanılmıyor
  (`pubspec.yaml:57`) → sil; `http` + `dio` → tek istemci; `pdf` →
  `syncfusion_flutter_pdf` (üretim de onunla), `pdfrx` görüntülemede kalır.
- [ ] **F3.11 Ayarlar** — `settings_screen.dart` (4.395 satır) bölümlere ayrı
  dosyalar; `settings_providers.dart`'taki ~20 kopya açık/kapalı tercih sınıfı
  → tek `BoolPref` ailesi (anahtar adları AYNI kalsın, tercih kaybolmasın).
- [ ] **F3.12 Ölü kod** — `keyboardOverlapOf` (`bubble_layer.dart:3388`),
  `folderFavoriteToken` (`notes_providers.dart:134`) sil;
  `balancedNoteColumns`, `textSimilarity`, `extractDocSync` yalnız testlerde
  yaşıyor → testleri canlı karşılığına taşı, sil.
- [ ] **F3.13 Ağır alanları not belgesinden ayır (P3)** — mürekkep, balonlar,
  transkript metni, sayfa notları → `notes/{id}/heavy` alt koleksiyonu ya da
  Storage; ana ekran yalnız hafif belgeyi dinlesin. Göç + geriye uyum planı
  şart (F1.5 kapısı). Açılış, bellek, önbellek ve 1 MiB riskini birlikte çözer.
- [ ] **F3.14 Diller** — tr/en 1564 metin, diğer 14 dil 1041: **523 metin
  (%33) eksik**, İngilizce görünüyor; hiçbiri anadilde okunmadı.
  **KARAR GEREKİR**: `translate.yml` ile tamamla + anadil kontrolü, ya da dil
  sayısını düşür.
- [ ] **F3.15 Flutter yükseltme kilidi** — 3.47.7'de `pdfrx 1.3.5` derlenmiyor
  (`pdf_file_cache.dart:351`, null güvenliği). pdfrx 2.x'e geç (API değişir:
  görüntüleyici, metin seçimi, sayfa görüntüsü), sonra Flutter 3.47+; CI
  `FLUTTER_VERSION` ve CLAUDE.md'deki uyarıyı güncelle.
- [ ] **F3.16 Modüller** — "Kişiselleştir → modüller" altyapısı var: yeni
  kullanıcıda ileri modüller (defter, podcast, QR, YouTube, sohbet,
  arkadaşlar) varsayılan kapalı; çekirdek: not, liste, ses, görsel/belge, ara.
- [ ] **F3.17 Kod tabanı bakımı** — editörü tam böl (F2.7'nin devamı: biçim,
  bulma, AI, ekler, kalem ayrı denetleyiciler); dev dosyalar
  (`dashboard_screen` 3.577, `bubble_layer` 3.398, `note_images` 3.135);
  koddaki tarihli hikâye yorumları (455 "kullanıcı isteği/bulgusu", 208
  "KÖK NEDEN") → yalnız "neden böyle olmak zorunda" kalsın, geçmiş git/HAFIZA'da;
  tarihle adlandırılmış 11 test dosyası (`requests_2026_10_17_d_test.dart`…)
  → özellik adına; HAFIZA.md (648 KB, okunamaz boyut) → ≤30 KB "geçerli
  kararlar ve tuzaklar" + `HAFIZA_ARSIV.md`.

---

## FAZ 4 — Eksik özellikler, test altyapısı, Play

- [ ] **F4.1 Ortak notta eşzamanlı düzenleme** — editör tüm gövdeyi yazıyor,
  son yazan kazanıyor (iki kişi aynı anda yazınca paragraf kaybı). En az
  "başka biri düzenliyor" göstergesi; sonra alan/paragraf bazlı birleştirme.
- [ ] **F4.2 Not sürüm geçmişi** — AI "notu değiştir", ortak not, otomatik
  kayıt varken "dünkü hâline dön" güvencesi (seyrek anlık görüntü).
- [ ] **F4.3 Misafir hesap hatırlatması** — ilk açılışta sessiz anonim oturum
  (`login_screen.dart:48`); uygulama silinince notlar erişilemez. N nottan
  sonra kalıcı "Google hesabını bağla" kartı.
- [ ] **F4.4 Drive'daki ekler web'de görünmüyor** (2026-10-19: Windows kaldırıldı, bilgisayardaki TEK yol artık web — öncelik yükseldi; Drive kipindeki kullanıcı ekleri bilgisayarda göremiyor) — web'de `NoDriveAuth`
  (`drive_store.dart:293`), `readBytes` null dönüyor
  (`attachment_repository.dart:950`). Web'de Drive okuması ya da Storage'a da
  yansıtma. (Kod okumasından; tarayıcıda doğrula.)
- [ ] **F4.5 Ayar senkronu** — tercihler yalnız cihazda (SharedPreferences);
  Android ve web ayrı ayrı ayarlanıyor. Seçili tercihler kullanıcı
  belgesine.
- [ ] **F4.6 FCM push** — paylaşım bildirimleri yalnız uygulama açıkken
  (KALANLAR'da ayrıntı).
- [ ] **F4.7 Erişilebilirlik** — tüm kodda 9 `Semantics`; tuval/balon/mürekkep
  ekran okuyucuya kapalı. Sistem yazı ölçeği YOK SAYILIYOR (`fixedTypography`,
  varsayılan 1.0) — ilk açılışta sistem ölçeğinden başla, sonra uygulama
  ayarı geçerli olsun.
- [ ] **F4.8 Kilit şifreleme değil** — içerik Firestore'da ve önbellekte düz
  metin; ekran kilidi olmayan cihazda doğrulamasız açılıyor
  (`note_guard.dart:12`). Kullanıcıya açıkça söyle; **KARAR GEREKİR**:
  isteğe bağlı gerçek şifreleme.
- [ ] **F4.9 Test altyapısı** — Firestore/Storage kuralları için emülatör
  testleri (28 KB kural, hiç testi yok); veri katmanı testleri
  (`fake_cloud_firestore` ya da emülatör); KALANLAR'daki 142 "cihazda görülmedi" maddesi için bir
  doğrulama turu.
- [ ] **F4.10 Play'e çıkış (biliniyor)** — Play Billing; AI kotası ve depolama
  tavanı SUNUCUDA (Cloud Function — G2'nin kod tarafı); App Check zorlaması.

---

## Ek A — İnceleme raporu özeti (2026-10-19)

**Kapsam:** `lib/` 297 Dart dosyası (~116 bin satır; ~89 bini kod, ~20 bini
yorum; üretilmiş çeviri dosyaları hariç), 153 test dosyası, kurallar, Cloud
Function, CI, manifest, dokümanlar. `flutter analyze` (3.44.6) temiz;
`flutter test` 1327/1327, 195 sn. Kod değiştirilmedi.

**Doğru olanlar (koru):** artımlı ayrıştırmalı çevrimdışı öncelikli senkron;
`maxWait`'li kayıt (not kaybı yok); değişmeyen ek listesinin yazılmaması;
tembel deterministik sütunlu ızgara, `RepaintBoundary`, ekran boyutunda görsel
çözme, arka planda/bellek baskısında önbellek boşaltma; servislerde
geciktirme; kurallarda istemciye kapalı `premiumUntil`, sunucu saatli AI kota
penceresi, sahip–yol eşleşmesi; çok sağlayıcılı AI soyutlaması ve içerik bazlı
puan; CI analiz/test kapısı, push öncesi test kancası, APK mimari denetimi ve
boyut raporu; uygulama içi kılavuz, RTL, gömülü yazı tipleri; yönlendiricide
dış adres / geri tuşu / çift kabuk kenar durumları.

**Fazla olanlar:** "+" menüsünde 19 giriş; 3 ses kapısı; 6 AI sohbet yüzeyi;
7 ek türü × 4 görünüm kipi + her içerikte Balonlu/Klasik sorusu; ikinci bir
editör olan defter; sabitle+yıldız, zemin+çerçeve; 3 paylaşım modeli; 4
depolama yolu (Storage, Drive, yalnız cihaz, video yalnız cihaz); %33'ü eksik
14 dil; 4.395 satırlık ayarlar + kopya tercih sınıfları; kullanılmayan
bağımlılık, 2 HTTP istemcisi, 3 PDF kütüphanesi; az miktarda ölü kod;
648 KB HAFIZA ve koda gömülü değişiklik günlüğü.

**Birleştirme haritası:** F3.1–F3.11 maddeleri.

**Sayılar:** en büyük dosyalar — `note_editor_screen.dart` 9.116,
`archive_note_screen.dart` 4.455, `settings_screen.dart` 4.395,
`dashboard_screen.dart` 3.577, `bubble_layer.dart` 3.398, `note_images.dart`
3.135 satır. KALANLAR: 142 açık madde, 20 tur "CİHAZDA GÖRÜLMEDİ".
Flutter 3.47.7: analizde 6 uyarı (F1.7), testler pdfrx yüzünden derlenmiyor
(F3.15).
