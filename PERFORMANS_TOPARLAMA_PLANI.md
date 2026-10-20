# PERFORMANS VE TOPARLAMA PLANI — Faz 5–9

Kaynak: 2026-10-20 inceleme (kod DEĞİŞTİRİLMEDİ). Konu: CPU/RAM performansı,
doğrulanmış hatalar, kod tabanının derlenip toparlanması. Fazlar **ayrı
oturumlarda, sırayla** yapılır. Faz 1–4 `YOL_HARITASI.md`'de (hepsi bitti);
numaralar çakışmasın diye bu plan **Faz 5**'ten başlar.

İnceleme sırasında ölçülenler (bulut, Flutter 3.47.7, 4 çekirdek):
`flutter analyze` temiz · `flutter test -j 4` **1338/1338**, 2 dk 41 sn ·
ek lint kurallarıyla analiz (depoya dokunmadan kopyada) 410 bilgi düzeyi bulgu ·
Riverpod 3.3.2'nin duraklatma davranışı küçük bir deneyle doğrulandı (**Ek B**).

## Bu dosya nasıl kullanılır (her faz oturumu için)

Kullanıcı "Faz N'i yap" dediğinde (N = 5…9):

1. Bu dosyayı ve HAFIZA.md'yi oku. Yalnız **Faz N** maddeleri yapılır; bir
   sonraki faza kendiliğinden geçilmez.
2. Satır numaraları 2026-10-20 hâlidir, kayabilir: önce `grep` ile yeri bul,
   kök nedeni koddan DOĞRULA (madde artık geçersizse `GEÇERSİZ: neden` yaz).
3. **KARAR GEREKİR** etiketli maddede önce kullanıcıya kısa öneri sun, onay al.
4. Her madde: düzeltme + mümkünse test (testin kırmızıdan yeşile döndüğünü
   gör). Faz sonunda `flutter analyze` temiz ve `flutter test -j 4` tamamen
   yeşil olmadan "bitti" denmez.
5. Faz bitince: maddeleri `[x]` yap, altına 1-2 satır **Yapıldı:** (ne, hangi
   dosya); yapılamayanı `ERTELENDİ: neden`; **Durum** tablosunu güncelle;
   kalıcı karar/kök neden/tuzak → HAFIZA.md (tarihli); cihazda bakılacaklar →
   KALANLAR.md; commit + push.
6. "Senin yapacakların" maddeleri kullanıcının cihaz/konsol işidir; oturum
   yalnız hatırlatır.
7. `dart format` YALNIZ değiştirdiğin dosyaya (CLAUDE.md). Davranışı değişen
   her yerde HAFIZA'daki ilgili tuzağı oku (ör. ağır belge F3.13, merge
   yazımı, `sameRenderedNote`/`_sameVisual`).

**Flutter (bulut):** CLAUDE.md'deki gibi 3.47.7'yi scratchpad'e indir. Kök
kullanıcıyla `git` "dubious ownership" verirse ortam değişkeniyle geç:
`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*'`.

## Durum

| Faz | Konu | Durum | Tarih | Not |
|---|---|---|---|---|
| 5 | Doğrulanmış hatalar + bellek sızıntıları | Bekliyor | | En yüksek getiri, düşük risk — önce bu |
| 6 | CPU: kayıt yolu, arka plan işleri, sorgular | Bekliyor | | F6.8 KARAR GEREKİR |
| 7 | RAM ayak izi | Bekliyor | | F7.3 KARAR GEREKİR; önce ölç |
| 8 | Toparlama: kod hijyeni, tekrarlar, dokümanlar | Bekliyor | | Her an yapılabilir, davranış değiştirmez |
| 9 | Ölçüm, editör bölmesi, web (isteğe bağlı) | Bekliyor | | F9.3/F9.4 KARAR GEREKİR |

## Özet — en önemli bulgular

| # | Bulgu | Tür | Önem | Madde |
|---|---|---|---|---|
| 1 | Editörde açılan HER notun Firestore dinleyicisi oturum boyu açık kalıyor; kapandıktan sonra gelen her anlık görüntü yine ayrıştırılıp bellekte BİRİKİYOR, not yeniden açılınca hepsi topluca oynatılıyor | RAM + CPU + pil | **YÜKSEK** | F5.1 |
| 2 | Çoklu fotoğraf içe aktarmada 52 px'lik küçük resimler ve PPTX slayt görselleri TAM çözünürlükte çözülüyor (12 MP ≈ 48 MB/görsel) — düşük RAM'li telefonda çökme riski | RAM | **YÜKSEK** | F5.2 |
| 3 | Başka cihazdan (web) kaldırılan/silinen notun hatırlatıcısı, telefon uygulaması o sırada kapalıysa yine ÇALIYOR | Hata | ORTA | F5.3 |
| 4 | Notu "yalnız bu cihaz"a alınca sürüm geçmişi (not METNİ) bulutta kalıyor; Drive'daki ekler indirilmeden bırakılıyor | Hata (gizlilik/veri) | ORTA | F5.4 |
| 5 | Her otomatik kayıtta (0,5–3 sn) ek listesinin ve ağır kısmın tamamı JSON + SHA-1'den geçiyor (çizimli PDF notunda yazarken takılma) | CPU | ORTA | F6.1 |
| 6 | "Ek içeriğinde ara" açıkken PDF metni ANA iş parçacığında ayrıştırılıyor; indeks SharedPreferences'ta (açılışta tamamı belleğe yükleniyor) | CPU + RAM | ORTA | F6.3 |
| 7 | Ayar senkronu uygulama arka plandayken de 20 sn'de bir uyanıp her seferinde yazım yapıyor | Pil/CPU | DÜŞÜK-ORTA | F6.4 |
| 8 | Bana paylaşılan HER not için oturum boyu tam not dinleyicisi (rozet ve yükleme kuyruğu için) | RAM + ağ | ORTA | F6.8 |
| 9 | Büyük AI isteklerinde (PDF/ses) JSON gövdesi ana iş parçacığında kuruluyor (~27 MB dize, ~3 kat bellek sıçraması) | CPU + RAM | ORTA | F6.6 |
| 10 | 3 tarihli test dosyası geri geldi; 265 elle kurulan SnackBar; 4 kopya PDF sayfa çizimi; 33 boş `catch` | Toparlama | DÜŞÜK | Faz 8 |

---

## FAZ 5 — Doğrulanmış hatalar ve bellek sızıntıları

- [ ] **F5.1 Tek nota/klasöre bağlı akış sağlayıcıları kalıcı (YÜKSEK).**
  Riverpod 3.3.2'de `StreamProvider.family`/`Provider.family` varsayılan
  olarak KALICIDIR (`isAutoDispose = false`). Son dinleyici gidince sağlayıcı
  yok edilmez, **duraklatılır**: akış aboneliğine `pause()` çağrılır. Bizim
  akışlarımız (`NotesRepository._withLocal`, `_hydratedDoc`, `notes_repository.dart:223,388`)
  `onPause` vermeyen `StreamController`'lar; içerideki Firestore ve yerel
  depo abonelikleri çalışmaya devam eder, `merge` (= `Note.fromMap`) her
  olayda koşar ve olay duraklatılmış denetleyicide BİRİKİR. **Ek B**'deki
  deney: kapanıştan sonra 1000 olay → 1000 ayrıştırma + yeniden açılışta 1000
  olay topluca oynatıldı; `autoDispose` ile 0/0.
  Etkilenen sağlayıcılar:
  `noteStreamProvider` (`notes_repository.dart:152`), `ownedNoteStreamProvider`
  (`:174`), `ownedPendingWritesProvider` (`:183`), `pendingWritesProvider`
  (`:192`, `includeMetadataChanges`), `noteShareProvider`
  (`note_shares_repository.dart:107`), `sharedFolderNotesProvider`
  (`notes_providers.dart:869`), `folderNotesProvider` + `_folderNotesBox`
  (`:830`, `:856`), `folderUnreadProvider` (`folder_activity.dart:77`).
  Senaryo: editör `ref.listenManual` ile dinliyor (`note_editor_screen.dart:1117`),
  kapanışta `_sub.close()` (`:1450`). 30 not açıp kapatan kullanıcıda 30 not
  belgesi + 30 metadata dinleyicisi açık kalır; YEREL (yalnız bu cihaz) bir
  notta yazarken HER kayıt `LocalNotesStore.changes` üzerinden açılmış her
  bulut notunu yeniden ayrıştırıp kuyruğa ekler — bellek oturum boyu büyür.
  Yap: hepsini `.autoDispose.family` yap (`_folderNotesBox` de, yoksa kutu
  kalıcı kalır). DİKKAT — `ref.read` ile okunan yerler: `shared_activity_service.dart:115`
  `ownedNoteStreamProvider`'ı `_ref.read` ile okuyor; autoDispose'da dinleyen
  yoksa okuma "yükleniyor" döner ve not bildirimi sessizce atlanır. Değeri
  `sharedNoteUnreadProvider`'ın zaten izlediği akıştan al (ya da
  `ref.listen` ile tut). `upload_queue.dart:262` ve `shared_note_activity.dart:121`
  `ref.watch` ediyor (canlı kalır, sorun yok). Editör önbellekteki hafif notla
  açıldığı için (`_cachedNote`) yeniden açılışta yeni dinleyicinin ilk
  anlık görüntüsü görünür bir gecikme yaratmamalı — testte doğrula.
  Bitti ölçütü: sağlayıcı testi — editörü kapatınca `noteStreamProvider(id)`
  yok edilir (`onDispose` sayacı ya da `container.exists`);
  `grep -rn "Provider.family" lib | grep -v autoDispose` yalnız bilinçli
  olanları gösterir (`providerApiKeyProvider`). HAFIZA'ya tuzak yazıldı
  (Riverpod / performans).

- [ ] **F5.2 Sınırsız görsel çözme (YÜKSEK, çökme riski).**
  `cacheWidth`/`ResizeImage` olmadan çözülen görseller (12 MP fotoğraf ≈
  4000×3000×4 B ≈ 48 MB bitmap):
  - `image_prepare_screen.dart:197-198`: çoklu seçimde 52 px genişliğindeki
    küçük resim şeridi `FileImage` ile TAM çözünürlük — ekranda ~6 küçük resim
    = ~300 MB. `:164` ana önizleme ve `:101` kırpma ekranına giden
    `MemoryImage` de tam boy.
  - `viewers/slide_canvas.dart:59` (slayt zemini) ve `:184` (şekil görseli):
    PPTX'teki fotoğraflar tam boy; birkaç slayt aynı anda ayaktayken yüzlerce MB.
  - `scan_review_screen.dart:362` (tarama sayfaları sayfa görünümünde),
    `viewers/text_recognize_screen.dart:244`, `editor/drawing_screen.dart:205`,
    `folders/presentation/folder_chat_screen.dart:145`.
  Yap: görüntülenen genişlik × `devicePixelRatio` kadar çöz; var olan
  `decodeWidthBucket` (`image_viewer.dart:487`) gibi kovalı genişlik kullan
  (önbellek anahtarı her pikselde değişmesin). Metin tanıma ekranında
  seçim katmanının koordinatları görselin piksel boyuna bağlıysa onları
  ÖLÇÜDEN değil orandan hesapla (doğrula).
  Bitti ölçütü: widget testleri — küçük resim şeridi ve slayt görseli
  `ResizeImage` (ya da `cacheWidth`) ile kuruluyor.

- [ ] **F5.3 Yetim hatırlatıcılar (hata).**
  `ReminderService._scheduled` (`reminder_service.dart:162`) yalnız bellekte;
  açılışta boş başlar ve `_syncReminders` (`:271`) yalnız BU süreçte
  planladıklarını iptal eder. Uygulama kapalıyken hatırlatıcı başka cihazdan
  (web) kaldırılırsa ya da not silinir/arşivlenirse, AlarmManager'daki eski
  bildirim (flutter_local_notifications yeniden başlatmada da korur) iptal
  edilmez ve çalar. Hesap değiştirmede de öbür hesabın hatırlatıcıları kalır.
  Yap: ilk eşitlemede `_plugin.pendingNotificationRequests()` oku, `payload`'u
  `note:` ile başlayıp `wanted` içinde olmayanları iptal et (brifing ve
  paylaşım bildirimleri `note:` önekli planlanmış bildirim değil — doğrula).
  Saf işlev `orphanReminderIds(pending, wanted)` + test.
  Not: kimlik `noteId.hashCode` (`:269`) — Dart sürümleri arasında kararlılığı
  garanti değil; mutabakat bu riski de kapatır.

- [ ] **F5.4 "Yalnız bu cihaz"a alma eksik taşıyor (hata, gizlilik).**
  `NotesRepository.setLocalOnly` (`notes_repository.dart:1254`):
  (a) Ana ve ağır belgeyi siliyor (`:1294-1295`) ama `versions` alt
  koleksiyonunu SİLMİYOR — sürüm geçmişi notun METNİNİ taşır (F4.2); kullanıcı
  "bulutta kalmasın" dediği notun eski metinleri Firestore'da kalıyor.
  `hardDelete` (`:1034`) aynı işi doğru yapıyor — ortak yardımcıya al
  (`presence` de).
  (b) Ek indirme koşulu `!hasFile && a.storagePath.isNotEmpty` (`:1268`):
  YALNIZ Drive'da duran ek (storagePath boş, `driveId` dolu) indirilmeden
  taşınır → bu cihazda dosyası olmayan, hiç inmeyecek bir ek (yerel notlar
  indirme kuyruğunda atlanıyor) ve Drive'da kalan kopya. Koşula `a.isInDrive`
  ekle (`readBytes` Drive'ı zaten biliyor, `attachment_repository.dart:950`),
  taşıma sonrası Drive kopyasını sil (`driveFileDeleter`) ve `driveId`'yi temizle.
  Bitti ölçütü: `fake_cloud_firestore` testi — yerele alınan notun
  `versions` belgeleri yok; Drive eki için sahte okuyucuyla bayt yazıldı.

- [ ] **F5.5 Hesap değişince bellekte kalan önceki hesap verisi.**
  `semanticIndexProvider` (`semantic_search.dart:13`, uid'e bağlı değil),
  `_searchBodyCache` (`notes_providers.dart:1044`, her notun katlanmış TAM
  metni — transkriptler dahil), `LocalNotesStore._instances`
  (`local_notes_store.dart:39`) çıkışta temizlenmiyor. RAM + paylaşılan
  cihazda gizlilik. Yap: uid değişiminde temizle (sağlayıcıyı
  `currentUidProvider`'a bağla; global haritalar için çıkış kancası).
  `_searchBodyCache`'i not yayınında canlı kimliklerle buda (silinen notlar
  kalıyor).

- [ ] **F5.6 Ağır belge gelirken yerel ek değişikliği kaybolabilir (düşük olasılık).**
  `note_editor_screen.dart:1201`: ağır belge İLK geldiğinde (`hydrating`)
  ekler `incoming.attachments` ile OLDUĞU GİBİ değiştirilir. Açılıştan sonraki
  ilk ~yüzlerce ms içinde eklenen/taşınan ve henüz kaydedilmemiş (debounce)
  ek değişikliği silinir. Yap: hydrating'de yerelde bekleyen ek değişikliği
  varsa (`_debouncer.hasPending` ya da ek listesi `previous`'tan farklıysa)
  ağır alanları ek kimliğiyle yerel listeye işle. Test: hafif not → ek ekle →
  ağır belge gelir → ek duruyor.

**Faz 5 — senin yapacakların:** APK'dan sonra (a) 20-30 not aç-kapat, sonra
yerel bir notta 2 dk yaz — uygulama ısınıyor/yavaşlıyor mu; (b) galeriden 10
fotoğraf seç — çökme yok; (c) büyük fotoğraflı bir PPTX aç; (d) web'de bir
hatırlatıcıyı kaldır, telefonda uygulama KAPALIYKEN zamanı geçsin — bildirim
gelmemeli.

---

## FAZ 6 — CPU: kayıt yolu, arka plan işleri, sorgular

- [ ] **F6.1 Her kayıtta bütün eklerin JSON + SHA-1'i.**
  `updateNote` (`notes_repository.dart:584`) editör kaydında (0,5 sn
  debounce, en geç 3 sn) her seferinde: `note.toMap()` → `heavyBytesOf`
  (bölünmemiş notta bütün çizim noktalarını gezer) → `attachmentsDigest`
  (`:79`, ek listesinin tamamı `jsonEncode` + SHA-1) → bölünmüş notta ağır
  kısmın TAMAMI (sınır ~1 MiB) ikinci kez `jsonEncode` + SHA-1 (`:611-613`) →
  `_checkSize` içinde `estimateFirestoreBytes` gövdenin tamamını
  `utf8.encode` ile kopyalar (`firestore_size.dart`) → `_contentKey`
  (`:650`) bütün metni birleştirir. Çizimli/balonlu PDF notunda metin
  yazarken her kayıtta UI iş parçacığında yüzlerce KB serileştirme.
  Yap: `Attachment` değişmez — ek ÖRNEĞİ başına özet ve boyut tahmini
  `Expando` ile önbelleklensin; liste özeti = (kimlik, ek özeti) dizisinin
  özeti; ağır özet de aynı yoldan. `estimateValueBytes` dizeler için
  ayırmasız UTF-8 uzunluğu saysın (kod birimi döngüsü). Davranış aynı
  kalmalı: `notes_repository_data_test`, `note_heavy_test`,
  `note_size_test` yeşil. Ölçüm: 300 çizgi × 200 nokta notla `updateNote`
  süresi Stopwatch ile önce/sonra (test çıktısına yaz, eşik koyma).

- [ ] **F6.2 Depoda oturum boyu büyüyen haritalar.**
  `_recentWrites` (`:648`) not başına son 12 kaydın TAM içerik dizesini,
  `_versionBase` (`:667`) açılan her notun TAM `Note` nesnesini (ağır alanlar
  dahil) uid değişene dek tutuyor. Yap: `_recentWrites`'ta içerik yerine
  SHA-1 özet; `_versionBase`'te yalnız sürümün yazacağı metin yükü
  (`versionPayload`); editör kapanınca o notun girdileri bırakılsın (F4.2
  "açıldığı hâl ilk değişiklikte" anlamı korunarak — testle).

- [ ] **F6.3 Ek metni indeksi (`attachment_text_index.dart`).**
  (a) `extractPdfText` (`:184`) Syncfusion ayrıştırmasını ANA izolede yapıyor —
  büyük PDF'te saniyeler süren donma; `Isolate.run`'a taşı (`pdf_edit.dart:725`
  kalıbı). (b) Önbellek SharedPreferences'ta tek JSON (`:128`): her 8 ekte bir
  bütün harita yeniden yazılıyor (ilk taramada karesel) ve açılışta
  SharedPreferences'ın TAMAMI belleğe yüklendiği için (`main.dart`
  `getInstance`) her açılışta MB'larca metin okunuyor. Uid'e özgü dosyaya taşı
  (`AiCache` kalıbı), tur sonunda bir kez yaz, silinen ek kimliklerini buda;
  eski anahtarı bir kez taşıyıp sil. (c) `build` her not yayınında `_byNote`
  ile tüm metinleri yeniden birleştiriyor ve `_readable` her taranmamış ek
  için senkron `existsSync` yapıyor; `filteredNotesProvider` ek metnini her
  hesapta yeniden `foldForSearch`'ten geçiriyor (`notes_providers.dart:963`).
  Not→metin haritasını yalnız indeks değişince kur ve KATLANMIŞ sakla.

- [ ] **F6.4 Ayar senkronunun 20 sn döngüsü.**
  `prefs_sync.dart:176` `Timer.periodic(20 sn)` uygulama arkadayken de çalışır
  (Dart zamanlayıcıları süreç yaşadıkça işler); her turda eşitlenen bütün
  tercihleri okur, anlık görüntüyü `jsonDecode` eder ve DEĞİŞMESE BİLE
  `setString` ile geri yazar (`:219`, platform kanalı). Yap: anlık görüntü
  yalnız değişince yazılsın; zamanlayıcı `paused`'da dursun, `resumed`'da
  bir tur + yeniden başlasın (mevcut `didChangeAppLifecycleState`).
  Test: `planPrefsSync` aynı girdide boş plan → yazım yok.

- [ ] **F6.5 Yalnız-bu-cihaz deposu.**
  `LocalNotesStore.flush` (`local_notes_store.dart:227`) yerel bir notta
  yazarken 600 ms'de bir BÜTÜN yerel notları (çizimler dahil) UI izolesinde
  `jsonEncode` ediyor. `Isolate.run` ile kodla (ya da not başına dosya).
  `note(id)` (`:113`) her çağrıda yeniden ayrıştırıyor — `_parsed`
  önbelleğini kullan (editör akışı her yerel değişiklikte çağırıyor).

- [ ] **F6.6 Büyük AI isteğinin gövdesi ana izolede.**
  `json_http.dart:94` `plain.body = jsonEncode(data)`: base64 `compute`'a
  taşınmıştı (`gemini_service.dart:326`) ama 15 MB'lık bir PDF'in ~20 MB base64
  dizesi yine ANA izolede JSON'a ve ardından UTF-8 baytlarına çevriliyor —
  yüzlerce ms donma, ham + base64 + JSON + bayt ≈ 3-4 kat bellek. Yap: gövde
  büyükse (`>256 KB`) `Isolate.run(() => utf8.encode(jsonEncode(data)))` →
  `bodyBytes`; yanıt `bodyBytes` > 1 MB ise çözme de izolede.

- [ ] **F6.7 Gereksiz geniş/tekrarlı Firestore dinleyicileri.**
  (a) `watchTrash` (`notes_repository.dart:347`) KOLEKSİYONUN TAMAMINI dinleyip
  her anlık görüntüde bütün silinmiş belgeleri yeniden ayrıştırıyor; yorumdaki
  "null-olmayan filtre yok" (`:345`) bayat — `purgeOldTrash` zaten eşitsizlik
  sorgusu kullanıyor (`:1112`). `where('deletedAt', isNotEqualTo: null)` ya da
  `isGreaterThan: Timestamp(0, 0)` + `docChanges` ile artımlı ayrıştırma;
  kural uyumunu emülatör testinde doğrula (`rules-test`).
  (b) `watchFolderNotes` (`:333`) her anlık görüntüde klasörün BÜTÜN notlarını
  ayrıştırıyor — `watchNotes`'taki artımlı `docChanges` kalıbı.
  (c) KENDİ paylaştığım klasörlerin rozeti (`folder_activity.dart:89`,
  `watchedSharedFoldersProvider` `:126`) `sharedFolderNotesProvider(ownerId: ben)`
  ile İKİNCİ bir dinleyici açıyor; bu notlar `notesStreamProvider`'da zaten
  var → sahibi bensem `folderNotesProvider`'dan türet.

- [ ] **F6.8 Paylaşılan notlarda not başına dinleyici — KARAR GEREKİR.**
  `sharedNoteUnreadProvider` (`shared_note_activity.dart:112`, paylaşım
  bildirim servisi dinliyor) ve `foreignEditableNotesProvider`
  (`upload_queue.dart:256`, yükleme kuyruğu dinliyor) bana paylaşılan HER not
  için oturum boyu TAM not dinleyicisi (bölünmüşse ağır belge de) tutuyor;
  rozet yalnız `updatedAt/updatedBy` ister, kuyruk yalnız BU cihazda bekleyen
  dosyası olan notları. Seçenekler: (a) olduğu gibi kalsın (az paylaşım
  varsa maliyet küçük); (b) Cloud Function (`functions/push.js` zaten not
  değişimini dinliyor) `noteShares` aynasına `lastUpdatedAt/lastUpdatedBy`
  yazsın, rozet yalnız `sharedNotesWithMeProvider`'dan; kuyruk yalnız yerel
  bekleyen eki olan notları dinlesin. Öneri: (b), paylaşılan not sayısı ~20'yi
  geçiyorsa. Kural + emülatör testi gerekir.

- [ ] **F6.9 Olmayan dosya için tekrarlanan senkron `existsSync`.**
  `localFileExists` (`core/utils/local_file.dart:24`) yalnız VAR olanı
  önbellekliyor; buluttan inmemiş ekler (yeni cihaz, "yalnız metin" senkron
  kipi) için kart/editör her çizimde ve `pendingUploadsProvider` her not
  yayınında senkron sistem çağrısı yapıyor. Yap: negatif sonuç kısa süreli
  (ör. 2 sn) ya da `localFilesRevisionProvider` artışına kadar önbelleklensin;
  dosya yazan yollar (indirme, kopyalama) kaydı düşürsün. Bayat negatif
  önbellek "görsel görünmüyor" demektir — testle.

**Faz 6 — senin yapacakların:** çizimli bir PDF notunda 1 dk yazı yaz
(takılma azaldı mı); "Ek içeriğinde ara" açıkken büyük PDF ekle (donma yok mu).

---

## FAZ 7 — RAM ayak izi

Bu fazda önce **ölç** (F9.1 senaryoları, DevTools Memory → "Dart heap" ve
"Raster/Image"), sonra düzelt; sonucu Yapıldı notuna yaz.

- [ ] **F7.1 Kart küçük resimleri bellekte bayt olarak.**
  `CardThumbs` (`note_card_media.dart:912`) en çok 64 küçük resmi
  `Uint8List` olarak Dart yığınında tutuyor; PDF kapakları PNG (`:1014`) —
  sayfa içeriğine göre yüzlerce KB. Yap: bayt bütçesiyle sınırla (ör. 6 MB)
  ya da baytı tutma — diskteki dosyayı `ResizeImage(FileImage)` ile göster
  (çözülmüş görsel Flutter `ImageCache`'inde, o zaten arka planda
  boşaltılıyor). PDF kapağını JPEG kodla (izolede, `image` paketi).

- [ ] **F7.2 Çizim noktaları kutulu `List<double>`.**
  `InkStroke.points` (`domain/attachment.dart:71`, `fromMap` `:86`): her
  koordinat ayrı nesne (~16-24 B) — `Float32List` 4 B. Çizimli notlarda 4-6 kat
  RAM ve çizimde daha yavaş gezinme. Yap: `fromMap`'te `Float32List`,
  `toMap`'te `List<double>`; çizim SÜRERKEN büyüyen çizgi büyüyebilir liste
  kalmalı (sabit uzunluk). Yan etki: float32 yuvarlaması kayıtlı değeri ilk
  kayıtta bir kez değiştirir (özet değişir → ağır kısım bir kez yeniden
  yazılır) — kabul edilebilir, HAFIZA'ya yaz. Eşitlik/`listEquals` testleri.

- [ ] **F7.3 Liste akışında satır içi ağır alanlar — KARAR GEREKİR.**
  F3.13 yalnız ağır kısmı 96 KB'ı (`kHeavySplitBytes`) aşan notu bölüyor;
  altındaki her notun çizim/balon/PDF işaretleri ana ekran akışında
  ayrıştırılıp oturum boyu bellekte. Seçenekler: (a) eşiği düşür (ör. 16 KB) —
  bölünmüş biçimi v2+ istemciler zaten okuyor, veri sürümü artmaz; daha çok
  not iki belgeli yazılır; (b) liste akışında ağır alanları tembel ayrıştır —
  RİSKLİ: bölünmemiş notta ağır alanlar ANA belgede, listeden gelen notla
  `updateNote` yapan bir yol çizimi silebilir (HAFIZA "hafif not" tuzağı).
  Öneri: önce ölç, gerekiyorsa (a).

- [ ] **F7.4 SharedPreferences diyeti.**
  Açılışta `SharedPreferences.getInstance()` (`main.dart`, `runApp`'ten önce)
  bütün anahtarları belleğe alır. Büyük değerleri dosyaya taşı
  (`attachment_text_v1` F6.3'te; `user_templates_v1`, arama geçmişi, etkinlik
  haritalarının boyuna bak). Hata ayıklama derlemesinde açılışta toplam
  tercih boyunu günlüğe yaz.

- [ ] **F7.5 Oturum boyu önbelleklerin budanması.**
  F5.5'in uid dışı kısmı: `_searchBodyCache` silinen notları tutuyor;
  `SemanticIndex._cache` (`semantic_search.dart:63`) silinen notların
  vektörlerini tutuyor; `_folderNotesBox`/`_filteredNotesBox` (F5.1 sonrası
  kontrol). Not yayınında canlı kimliklerle buda.

- [ ] **F7.6 Görsel önbellek bütçesi (isteğe bağlı).**
  `PaintingBinding.instance.imageCache` varsayılanı 100 MB / 1000 görsel.
  Düşük RAM'li cihazda (ör. `ActivityManager.isLowRamDevice` ya da toplam RAM
  ≤ 4 GB — platform kanalı) 50 MB'a çek. Önce ölç.

**Faz 7 — senin yapacakların:** F9.1 ölçümünü Faz 7'den önce ve sonra yap.

---

## FAZ 8 — Toparlama (sadeleştirme, kod hijyeni, dokümanlar)

Davranış değiştirmez; her an, her fazın arasında yapılabilir. Toplu
biçimlendirme YOK (`dart format` yalnız dokunulan dosyaya).

- [ ] **F8.1 Tarihli test dosyaları geri geldi.** `test/fixes_2026_10_20_test.dart`,
  `test/ui_compact_2026_10_20_test.dart`, `test/voice_bubble_2026_10_20_test.dart`
  → özellik adına (F3.17'de 11 dosya böyle düzeltilmişti). HAFIZA "Test
  tuzakları"na kural: test dosyasına tarih adı verilmez.

- [ ] **F8.2 Lint setini genişlet.** `analysis_options.yaml`'a:
  `unawaited_futures` (38 yer — kasıtlıları `unawaited(...)` ile işaretle),
  `cancel_subscriptions`, `unnecessary_lambdas` (8), `unnecessary_breaks` (5),
  `avoid_redundant_argument_values` (46). `discarded_futures` (276) ve
  `avoid_slow_async_io` (17) gürültülü — EKLEME. Ölçüm komutu: kopyada
  `flutter analyze` (bkz. Ek A).

- [ ] **F8.3 Tek bildirim yardımcısı.** 265 `SnackBar(` + 137 `showSnackBar(`
  elle kuruluyor; ortak `timedSnackBar` yalnız 7 yerde
  (`core/widgets/undo_snackbar.dart`). `showAppMessage(context, metin,
  {eylem, geriAl})` → en yoğun dosyalardan başla (`settings_account` 20,
  `quick_add_actions` 17, editör 16, dashboard 15, `drive_ui` 14).

- [ ] **F8.4 PDF sayfa çiziminin 4 kopyası.** `note_card_media.dart:995`
  (`_renderPdf`), `viewers/pdf_page_image.dart:146`,
  `data/note_quick_export.dart:124`, `data/pdf/pdf_page_ocr.dart:244` →
  tek yardımcı (sayfa, hedef genişlik, zemin → `ui.Image`/bayt; `dispose`
  sırası tek yerde).

- [ ] **F8.5 Boş `catch` blokları.** 33 `catch (_) {}` (en çok
  `reminder_service.dart` 5, `youtube_viewer` 3, `share_intake` 3,
  `pdf_page_ocr` 3, `device_storage` 3). Veri katmanındakiler en azından
  `ErrorLog.record` yazsın; arayüzdekiler gerekçeli tek satır yorumla kalsın.

- [ ] **F8.6 pubspec temizliği.** Bayat yorumlar: `package_info_plus`
  ("`1.0.0+1`" — artık `1.1.0+1` ve CI `1.1.N`), Windows sürümleme
  şablon yorumu, varlık yorumlarında kalkmış `pdf` paketi anlatımı (F3.10).
  `syncfusion_flutter_core` kodda hiç içe aktarılmıyor — sürüm kilidi
  olarak tutuluyorsa yorumu bunu söylesin. `flutter pub outdated`: 144 paket
  kısıt dışında yeni sürümde — FlutterFire'ı BİRLİKTE yükselt (HAFIZA), ayrı
  oturum, APK işiyle doğrula.

- [ ] **F8.7 Dokümanları sadeleştir.** `KALANLAR.md` 52 KB, 20+ tur "CİHAZDA
  GÖRÜLMEDİ" — tek "cihaz doğrulama turu" listesine indir (yinelenenleri
  birleştir, sonradan geri alınan maddeleri — ör. F3.6 yıldız/çerçeve — at).
  `YOL_HARITASI.md` başına "tamamlandı, devamı PERFORMANS_TOPARLAMA_PLANI.md"
  notu. README mimari ağacını koddan doğrula.

- [ ] **F8.8 Yorum hijyeni (politika, toplu düzenleme DEĞİL).** `lib/`
  117.616 satırın 20.207'si yorum (%17); 775 tarihli yorum, 565 "kullanıcı
  isteği/bulgusu", 204 "KÖK NEDEN". F3.17 kararı geçerli: toplu temizlik yok;
  Faz 5–7'de DOKUNULAN her dosyada hikâye yorumları "neden böyle olmak
  zorunda" özüne (≤3 satır) indirilir, tarihçe git/HAFIZA'da kalır.

---

## FAZ 9 — Ölçüm, büyük yapısal işler, web (isteğe bağlı)

- [ ] **F9.1 Cihaz ölçüm protokolü (senin yapacakların + oturum hazırlığı).**
  Faz 5 ve 7 öncesi/sonrası aynı senaryolar, DevTools (profil derlemesi)
  Memory sekmesi: (1) soğuk açılış → ana ekran ilk kare süresi; (2) 30 not
  aç-kapat → Dart heap; (3) yerel notta 2 dk yazı → heap eğimi;
  (4) galeriden 10 fotoğraf → tepe RSS; (5) 30 slaytlık fotoğraflı PPTX.
  F2.6 kare ölçümü: Actions → Run workflow → "Kare ölçümü".

- [ ] **F9.2 Hata ayıklama teşhis sayaçları.** Yalnız debug/profil: açık not
  akışı sayısı (F5.1 doğrulaması), `CardThumbs` bayt toplamı, `ImageCache`
  doluluğu — Ayarlar → Hakkında'da gizli satır. Üretimde derlenmez.

- [ ] **F9.3 Editörün bölünmesi (F3.17'nin ertelenen kısmı) — KARAR GEREKİR.**
  `note_editor_screen.dart` 9.072 satır (+ `note_editor_parts.dart` 323),
  33 `setState`, `build` `:7495`'ten başlayıp ~1.580 satır. Bulma, AI, ekler,
  kalem, dikte ayrı denetleyicilere (`ChangeNotifier` + dar builder).
  Yüksek risk; her alt parça ayrı commit, editör testleri yeşil kalmalı.
  Öneri: ancak Faz 5–7 bittikten ve cihaz ölçümleri editörü hâlâ darboğaz
  gösterirse.

- [ ] **F9.4 Web'de WebAssembly — KARAR GEREKİR.** `flutter build web --wasm`
  (skwasm: çok iş parçacıklı çizim, daha iyi CPU). Eklenti uyumluluğu
  (pdfrx, webview, Firebase, `web` paketi) ayrı dalda denenmeli; CI web
  işinde bayrak. Getiri tarayıcıda belirgin olabilir, risk derleme kırılması.

---

## Ek A — İnceleme kapsamı ve sayılar (2026-10-20)

**İncelenen:** veri katmanı (`notes_repository`, `local_notes_store`,
`upload_queue`, `attachment_repository`, paylaşım/klasör/gelen kutusu
akışları), sağlayıcı yaşam döngüleri (bütün `StreamProvider`/`.family`),
editör kayıt ve birleştirme yolu, ana ekran/kart çizimi, görsel çözme
noktaları (35 `Image.*`/`*Image(` kullanımı), zamanlayıcılar
(`Timer.periodic` 9 yer), izole kullanımı, AI istek yolu, hatırlatıcılar,
ayar senkronu, CI derleme bayrakları.

**Doğru olanlar (koru):** artımlı ayrıştırmalı `watchNotes`; `StableBox`
ile örnek kimliği korunan türetilmiş listeler; kart önbelleği
(`_cachedCard`); debounce + `maxWait`'li kayıt; değişmeyen ek listesinin
yazılmaması; PDF düzenleme/dışa aktarma/tarama/OCR/base64'ün izolede
olması; kart görsellerinde `cacheWidth`; arka plana geçince ve bellek
sıkışınca önbellek boşaltma; `FrameLoop`; pdfrx katmanlarının sayfa başına
aynı örnekle kurulması; `planTextWrap`/span önbelleği; `AiCache` budaması;
yükleme kuyruğu ve hatırlatıcılarda geciktirme.

**Sayılar:** `lib/` 317 Dart dosyası, 117.616 satır (20.207 yorum);
165 üst düzey sağlayıcı; 164 test dosyası, 1338 test. En büyük dosyalar:
`note_editor_screen` 9.072, `items_editor` 2.610, `dashboard_screen` 2.432,
`note_images` 2.186, `text_wrap` 2.120, `gemini_service` 1.832,
`rich_text` 1.514, `voice_capture_sheet` 1.385. 13 dosya `part of`
(toplam 8.712 satır). `assets/google_fonts` 5,2 MB.

**Ek lint analizi (depoya dokunmadan):** projeyi scratchpad'e kopyala,
`analysis_options.yaml`'a aday kuralları ekle, `flutter pub get` +
`flutter analyze --no-fatal-infos`. 2026-10-20 sonucu: 276
`discarded_futures`, 46 `avoid_redundant_argument_values`, 38
`unawaited_futures`, 17 `avoid_slow_async_io`, 8 `unnecessary_lambdas`,
5 `unnecessary_breaks`, 2 `close_sinks` (`_withLocal`/`_hydratedDoc`
denetleyicileri — `onCancel` aboneliği bırakıyor, zararsız), 1
`no_adjacent_strings_in_list` (`note_quick_export.dart:59`, kasıtlı tek dize).

## Ek B — Riverpod duraklatma deneyi (F5.1'in kanıtı)

Scratchpad'de `riverpod: 3.3.2` ile (`dart pub get --offline`):
`_withLocal` gibi `onPause` vermeyen bir denetleyici, uzun ömürlü bir
yayın kaynağını dinliyor; aynı akış `StreamProvider.family` ve
`StreamProvider.autoDispose.family` ile sarılıyor. Dinleyici 1 olay alıp
kapatılıyor, kaynağa 1000 olay basılıyor, sonra yeniden dinleniyor.

```
family (keepAlive): source listeners=true, parses after close=1000
family (keepAlive): events replayed on reopen=1000
autoDispose: source listeners=false, parses after close=0
autoDispose: events replayed on reopen=0
```

Riverpod kaynağı: `riverpod-3.3.2/lib/src/core/element.dart` `onCancel` →
`_cancelSubscription?.pause?.call()`; `StreamProvider` kurucusu
`isAutoDispose = false`.
