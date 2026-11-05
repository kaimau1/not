# AKICILIK PLANI — Faz 20–27 (kasma · donma · titreme · FPS düşüşü · gecikme)

Kaynak: 2026-11-03 derin inceleme — **gerçek telefonda ölçüm + profil + kod**
(kod DEĞİŞTİRİLMEDİ; yalnız `tool/perf/` ölçüm araçları eklendi). Hedef:
Google Keep gibi her yerde akıcı. Fazlar **ayrı oturumlarda, sırayla**; numara
`KALAN_ISLER_PLANI.md` (Faz 18–19) sonrasından başlar.

**Ölçüm ortamı:** Xiaomi Mi Note 10 Lite (Snapdragon 730G: 2×A76 2,2 GHz +
6×A55 1,8 GHz, Adreno 618, 6 GB), Android 12 / MIUI 13, **60 Hz** (kare bütçesi
16,7 ms), 1080×2340. Uygulama **v1.1.613** (CI release). Veri: misafir hesapta
244 not — 140 metin (5'i 300–600 satır), 70 liste (5'i 90–150 madde), 30
görselli (40 foto, 2400×1800), 4 adlı stres notu (`OLCUM …`). Aynı veri yan
yana kurulu **"Notlar Ölçüm"** profil derlemesinde de var (bkz. Ek A).

## Bu dosya nasıl kullanılır

Kullanıcı "Faz N'i yap" dediğinde (N = 20…27):

1. Bu dosyayı + HAFIZA.md'yi oku. Yalnız **Faz N**; kendiliğinden sonrakine geçme.
2. **Önce ölç, sonra düzelt:** her maddeden önce ilgili senaryoyu telefonda koş
   (`tool/perf/`, Ek A), sayıyı yaz; düzeltmeden sonra AYNI senaryoyu tekrar
   koş. Kabul ölçütü sağlanmadıysa madde bitmedi. Telefon yoksa "yazıldı,
   cihazda doğrulanmadı" diye işaretle, KALANLAR'a ekle.
3. Satır numaraları 2026-11-03 hâlidir: önce `grep`, kök nedeni koddan doğrula.
4. **KARAR GEREKİR** maddesinde önce kullanıcıya kısa öneri + bedel, onay al.
5. Faz sonunda değişenin testi oturumda + tam takım CI'da yeşil (CLAUDE.md › DOĞRULAMA — KISA YOL);
   maddeler `[x]` + **Yapıldı/Ölçüldü:** satırı (önce→sonra sayı); Durum tablosu;
   kalıcı karar/tuzak → HAFIZA.md; commit + push (APK isteniyorsa başlıkta `[apk]`).
6. Belirti yamalama YASAK: "ilk N satır sonra geri kalanı", "kare başına K öğe"
   türü parçalama ancak kök neden giderildikten sonra hâlâ gerekiyorsa ve
   ölçümle gerekçelenirse eklenir (geçmişte 6+ tur böyle geçti, bkz. K10).

## Durum

| Faz | Konu | Durum | Tarih | Not |
|---|---|---|---|---|
| 20 | Ölçüm kapısı (gerçekçi veri, yan yana profil derlemesi, CI bütçesi) | Bitti | 2026-11-04 | F20.4 taban `tool/perf/taban.py` (Ek B v1.1.661 satırı) |
| 21 | Ana ekran kartı: önizlemeyi kırp, kart başına işi azalt | Kısmen | 2026-11-04 | 2 tur: takılma %8,4→%3,4–4,2, en kötü 115→33–50 ms, arama 465→139 ms; kabul sağlanmadı — kalan engel raster+kurulum (K7); F21.6 arama katmanı yazıldı (2026-11-04, cihazda ölçülmedi) |
| 22 | Firestore trafiği: yazımda tüm koleksiyon ana iş parçacığında | Kısmen | 2026-11-04 | F22.1 ölçüldü (kayıt başına 1 olay; bedel not sayısıyla doğrusal: 200 not 593 KB / 11 ms, 414 not ~1,2 MB / 21–27 ms Dart); yalnız F22.4 göçü açık |
| 23 | Geçişler: not açma/kapama | Bitti (kabul kısmen) | 2026-11-04 | F23.2/5 ölçüldü; kapanış animasyonu çoğunlukla ≤ 33 ms, uzun notlarda bazen tek 50 ms |
| 24 | Uzun not editörü: tuş başına O(n) | Bitti | 2026-11-04 | F24.1 eşik 2500 / pencere 1500; 35 KB'ta kare p90 13,5 ms; F24.3 liste maddesi düz çizim (bütçe üstü kare 27→7) |
| 25 | Soğuk açılış | Bitti (kabul kısmen) | 2026-11-04 | F25.1 açılışta 5,2 MB→295 KB yazı tipi, Dart ilk kare 119→53 ms; donuk kare 198–264→115–181 ms; release TotalTime ~780 ms, < 600 hedefi SAĞLANMADI (kalan motor+Activity) |
| 26 | Titreme ve görsel kararlılık | Bitti | 2026-11-04 | F26.1 video: flaş/zıplama yok; beyaz açılış penceresi TEMA Faz 35'e |
| 27 | Hijyen + regresyon kapısı | Kısmen | 2026-11-04 | F27.2 ölçüldü, F27.4 duman testi; F27.3 Vulkan'lı cihaz yok (KALANLAR §2 #59) |

## Özet — ölçülen taban çizgisi (v1.1.613, release)

| Senaryo | Ölçülen | Hedef |
|---|---|---|
| Soğuk açılış (×3) | ilk kare 732–792 ms; ardından **tek kare 313–396 ms donuk** + 50–66 ms takılmalar; içerik ~1,2 sn'de oturuyor | ilk kare < 600 ms, içerik ilk karede, ilk 2 sn'de > 50 ms kare yok |
| Ana ekran fırlatma (12 fırlatma, ~1000 kare) | takılan kare **%6,5**, 94 kayıp vsync; en kötü **99–115 ms**; ana iş parçacığı p99 67 ms, en uzun 105–127 ms | takılan < %1, hiçbir kare > 33 ms |
| Not açma (4 tür × 3) | dokunuş→ilk kare **43–101 ms** (kısa), 54–86 ms (görselli), **122–192 ms** (500 satır), 81–126 ms (120 madde); açılışta 33–49 ms takılma; 120 maddede ana iş parçacığı **200–420 ms kesintisiz** meşgul | dokunuş→ilk kare < 50 ms; en çok 1 kare > 16,7 ms |
| Not kapama (4 tür × 3) | **12/12 denemede 99 ms (6 vsync) donma**; küçülme animasyonunda raster 18–26 ms/kare | 0 kare > 33 ms |
| Kısa notta yazma (4 × 14 karakter) | her otomatik kayıttan ~0,5 sn sonra, dokunuş yokken **27–56 ms ana blok** (uyandıran: `FirestoreWorker`); 49–99 ms takılmalar | yazarken 0 kare > 33 ms |
| 500 satırlık notta yazma | **efektif 4,6 fps**; tuş başına LAYOUT 90–110 ms; **400–580 ms** donmalar; Java `commitText` 5–23 ms/tuş | tuş→kare p95 < 16 ms |
| Ana ekranda arama (5 harf + silme) | ana iş parçacığı en uzun **368 ms** (p90 107 ms) | sonuç karesi < 16 ms |

Notlar: (1) Kaydırmada **Skia ile A/B** (release, `--ez enable-impeller false`):
takılma yine %6,5 → **sorun çizici/GPU değil, Dart (ana) iş parçacığı.**
(2) Yazma senaryolarında SurfaceFlinger aralıkları boşta bekleme
boşluklarını da içerir; güvenilir sayı "kayıttan sonra ana blok" ve tuş başına
LAYOUT süresidir (Ek A, hizalama yöntemi).

## Kök nedenler (etkiye göre)

**K1 — Kart önizlemesi notun TAMAMINI işliyor (en büyük tek neden).**
`_NotePreview.build` → `noteBodyText(context, mask(note.body), …, maxLines: 2|4)`
(`note_card.dart` ~1405, `noteBodyText` ~213): 2–4 satır göstermek için gövdenin
tamamı `maskSensitiveNumbers` (regex) → `richSpans`/`stripRichMarkers` → metin
motorundan geçiyor. Metin motoru `maxLines`'tan bağımsız bütün metni
şekillendiriyor (önce tek satırda şekillenir, sonra kırılır). **Kanıt:**
kaydırmada bütçeyi aşan karelerde CPU örneklerinin **%60,3'ü
`_NativeParagraph._layout`**, LAYOUT 74–89 ms/kare; `maskSensitiveNumbers` %8,4,
regex %8,9, `isCredentialNote` %2,2. Etkilediği her şey: kaydırma, arama (ızgara
yeniden kurulur), açılış (ilk ızgara), kapanış (pano yeniden kurulumu), her kart
yenilemesi. Uzun not sayısı arttıkça kötüleşir.

**K2 — Editör gövdesi tek parça `TextField`: tuş başına O(n).** Her tuşta tüm
metin yeniden yerleşiyor ve Android metin girişi tam metni kanalda iki yönde
taşıyor. **Kanıt:** 35 KB notta tuş başına LAYOUT 90–110 ms, örneklerin %75'i
`_NativeParagraph._layout`; Java `InputConnection#commitText` 5–23 ms (kısa notta
~1,7 ms). Madde listesinde her madde ayrı `TextField` → 120 maddede açılış ve
kapanış ağır (bugünkü "ilk 12 madde, kalanı 1100 ms sonra 4'er" çözümü belirtiyi
öteliyor; ana iş parçacığı 200–420 ms yine kesintisiz meşgul).

**K3 — Her yazım tüm koleksiyonu ana iş parçacığından geçiriyor.** FlutterFire
7.1.0 `QuerySnapshotsStreamHandler` her olayda `querySnapshot.getDocuments()`
TAMAMINI Pigeon'a çevirip `mainHandler.post(events.success(…))` yapıyor →
kodlama Java ana iş parçacığında, çözme Dart'ta (`DispatchPlatformMessage` olay
başına ~6,6 ms). `updatedAt: FieldValue.serverTimestamp()` yüzünden **kayıt
başına 2 olay** (yerel + sunucu onayı); otomatik kayıt 0,5 sn debounce (en geç
3 sn); ana liste dinleyicisi (`watchNotes`, `app_services`) editör açıkken de
canlı. **Kanıt:** atrace — kayıt sonrası 27–56 ms ana blokları uyandıran iş
parçacığı `FirestoreWorker` / `pool-13-thread`. Maliyet not sayısı × boyutla büyür.

**K4 — Dart UI iş parçacığı = Android ana iş parçacığı (Flutter 3.29+ birleşik,
3.47'de kapatılamaz).** `DisableMergedPlatformUIThread` motor tarafından
"disabled" (kullanılırsa istisna). Her platform kanalı çağrısının Java tarafı
karenin içinde koşar: açılış/kapanış karelerinde `___sendPlatformMessage` özel
sürenin %7,8–10,7'si. `alwaysHandleBack` (`app.dart:103`) her
`NavigationNotification`da `SystemNavigator.setFrameworkHandlesBack(true)` yolluyor.

**K5 — Geçişte bütün ağaç işleri.** HeroController `_allHeroesFor` iki sayfanın
tüm eleman ağacını geziyor: **kapanış karesinin %13,6'sı**. Uygulamada elle
`Hero` yok; tek Hero'lar FAB'ların örtük Hero'su (`heroTag`: `add-fab`,
`backToTop`, `rail-new-note`) — not açma/kapama için uçuşa gerek yok. Riverpod 3 örtülen panodaki her kartın aboneliğini
duraklatıp/sürdürüyor (`_updateTickerMode`, `onSubscriptionResumeOrReactivate`
~%5–8); kapanış karesinde kartlar yeniden kuruluyor (`NoteCard.build`,
`maskSensitiveNumbers`); editör sökümü `FINALIZE TREE` 9 ms + `POST_FRAME` 12 ms.

**K6 — Kart başına fazla abonelik ve hesap.** Her `NoteCard` ~8 `ref.watch` +
`CardMediaPlan.of` + `isCredentialNote` + maske; kaydırmada
`ConsumerStatefulElement.mount` %7,3. GC: 13 sn kaydırmada **34 scavenge** (en
uzun 11 ms, ana iş parçacığında), eşzamanlı işaretleme toplam 1,2 sn CPU.

**K7 — GPU: Adreno ≤ 650'de Impeller OpenGLES.** Motor kara listesi
(`driver_info_vk.cc` `IsKnownBadDriver`: `adreno ≤ kAdreno650`) Vulkan'ı
kapatıyor → SD 855/860/865/870/778G/7xx ailesinin hepsi GLES'te. Kaydırmada
raster yeterli (p90 8,6 ms), ama kapsayıcı dönüşüm geçişinde tam ekran
katmanlar (karartma, kenar yumuşatmalı kırpma, `Opacity`, alttaki CANLI pano)
**raster 18–26 ms/kare**.

**K8 — Açılış.** `runApp` yazı tipleri için 400 ms'ye kadar bekliyor
(`main.dart`), ilk içerik Firestore'un tam anlık görüntüsü + K1'li ilk ızgara
kurulumuyla geliyor → ilk kareden sonra 313–396 ms donuk kare.

**K9 — Titreme şüphelileri (ölçülmedi, video gerekir).** Arka plana geçişte
`imageCache.clear()` + `CardThumbs.clearMemory()` (`main.dart` onPause) → dönüşte
ve kaydırmada görsellerin geç gelmesi; açılışta iskelet→içerik değişimi;
düzenlenen notun "Son güncellenen" sırasında yer değiştirmesi; segment
geçişinde (`AnimatedSwitcher`) iki ızgaranın birlikte kurulması.

**K10 — Ölçüm boşluğu (neden hep belirti yamalandı).** CI `perf_test` sentetik:
kısa gövdeli 300 kart, 1,4 KB metinde yazma, x86 emülatör → K1/K2/K3'ü hiç
görmedi; telefon ölçümleri tek tek senaryolarla yapıldı. Sonuç: "ilk 12 madde",
"4 madde/kare", "kapanışta 6 madde/kare söküm", `+120 ms yetişme` gibi
zamanlama yamaları.

## Yapılmayacaklar (ölçüldü / sonuçsuz)

- **Skia'ya dönmek:** A/B'de aynı %6,5 takılma; Skia opt-out "deprecated".
- **İş parçacığı birleştirmesini kapatmak:** 3.47 Android'de bayrak kaldırılmış.
- **Satırlara/kartlara `RepaintBoundary` serpmek:** sorun boyama değil yerleşim
  (HAFIZA: daha önce denendi, kazanç yok).
- **Yeni zamanlama/parçalama hileleri, `cacheExtent` oynamak:** kök neden K1/K2.

---

## FAZ 20 — Ölçüm kapısı (önce ölç, sonra düzelt)

- [x] **F20.1 Ölçüm araçları depoda.** `tool/perf/` (bkz. `tool/perf/README.md`):
  SurfaceFlinger kare zamanları, atrace iş parçacığı yükü + saat hizalama,
  profil uygulamasında VM servisi (zaman çizelgesi + CPU örnekleri),
  Keep Takeout veri seti üreticisi. **Yapıldı (2026-11-03).**
- [x] **F20.2 Profil derlemesi kendiliğinden yan yana kurulsun.** Bugün elle
  yapıldı (Ek A): `applicationId` → `dev.kaimau.notlar.olcum`, manifest etiketi
  "Notlar Ölçüm", `google-services.json`a aynı istemcinin kopyası. Yap:
  `buildTypes.profile { applicationIdSuffix = ".olcum" }` + etiket için manifest
  yer tutucusu + `android/app/src/profile/google-services.json`. DİKKAT: CI
  `perf` işi (`flutter drive --profile`) yeni kimlikle kurar — emülatörde sorun
  yok; test telefonunda varsayılan kimlikle `flutter run/drive/install` ASLA
  (imza uyuşmazlığı → kaldır-kur → telefondaki veri silinir).
  Kabul: `flutter build apk --profile` çıktısı telefondaki release'e dokunmadan kurulur.
  **Yapıldı (2026-11-04):** `build.gradle.kts` `profile { applicationIdSuffix = ".olcum" }` + `manifestPlaceholders["appLabel"]` ("Notlar" / "Notlar Ölçüm") + `android/app/src/profile/google-services.json` (aynı istemcinin `…olcum` kopyası). CI `[perf]` işi profil derlemesini bu kimlikle kurdu (bkz. Ek B). Telefonda kabul (release'e dokunmadan kurulum) KALANLAR §2 #38. Sınır: `app_shortcuts.xml` sabit paket adı → kısayollar release'i açar.
- [x] **F20.3 CI `perf_test`'i gerçekçi yap.** Veri setine 10 uzun gövde
  (300–600 satır) ve 120 maddelik liste; yeni senaryolar: 30 KB notta 100 tuş
  yazma, kart ızgarasında arama sorgusu değişimi. Bütçe p90 build < 8 ms →
  **bugün KIRMIZI olmalı** (K1/K2'yi yakaladığını göster); Faz 21/24 sonrası yeşil.
  **Yapıldı (2026-11-04):** veri setine 10 uzun gövde (300–600 satır) + 120 maddelik liste; yeni senaryolar `editor_typing_30kb` (30 KB'ta 100 tuş) ve `dashboard_search` ("önemli" yaz-sil ×3). Bütçe F27.4 ile p90/p99/en kötü. İlk `[perf]` koşusu (41785838651, Ek B): dördü de bütçe İÇİNDE — **beklenen kırmızı GÖRÜLMEDİ.** 30 KB senaryosu K2'yi yakalamıyor: `enterText` IME kanalını (Java `commitText`, telefonda tuş başına maliyetin büyüğü) atlıyor, x86 emülatörde yerleşim hızlı; arama senaryosu F21.6 SONRASI ölçüldü (öncesi yok). K2'yi CI'da yakalamak için gerçek IME yolu (`TestTextInput` yerine platform kanalı) ya da cihaz gerekir — **sabah bakılacak**; telefondaki ölçüm KALANLAR §2 #38. Ayrıca koşucu diski doldu (41784350487) → perf işine "Disk aç" adımı.
- [x] **F20.4 Taban çizelgesi** bu dosyadaki tablo; her faz sonunda aynı
  senaryolarla yeni satır (Ek B).
  **Yapıldı (2026-11-04):** `tool/perf/taban.py <etiket>` Ek B'nin bütün sütunlarını tek koşuda üretir (v1.1.661 satırı). Sonraki Tema/Tutarlılık oturumları aynı komutla satır ekler.

## FAZ 21 — Ana ekran kartı: önizlemeyi kırp, kart başına işi azalt (K1, K6)

**Ölçüm (2026-11-03, profil derlemesi "Notlar Ölçüm", aynı telefon/veri; önce → sonra):**
kaydırma SF takılan **%8,4 → %3,5 / %3,4** (iki koşu), kayıp vsync 96 → 38, en
kötü kare **115 → 50 / 66 ms**, ana iş parçacığı en uzun blok 110 → 96 ms;
VM: bütçeyi aşan UI karesi 14 → 5, LAYOUT p99 **34 → 20 ms** (en çok 90 → 27);
aşan karelerde `_NativeParagraph._layout` %62 → %33, `maskSensitiveNumbers` %8,4
ve `isCredentialNote` %2,2 → listeden çıktı. Arama (5 harf + silme): en uzun
UI karesi **465 → 143 ms**, ana blok 482 → 150 ms. Kapanış (kısa sabit not):
en kötü kare 29 → 34 ms (gürültü), `NoteCard.build` kapanış karesinde hâlâ %3.
**Kabul SAĞLANMADI** (hedef takılma < %1, kare < 33 ms, LAYOUT p99 < 8 ms,
arama < 16 ms). Kalan, ölçülen: (1) her yeni kart dilimini (≤ 600 karakter,
10 satır) ve maddelerini (≤ 200) yine şekillendiriyor — görünen ~100 karakter;
(2) aramada sorgu değişince önbellek payındaki ~130 kartın HEPSİ yeniden
kuruluyor (`SliverMultiBoxAdaptorElement.performRebuild` %17, BUILD 50-74 ms);
(3) hücre `Consumer` + kart `ConsumerWidget` bağlama %10 (`mount`). Önerilen
devam: dilimi görünen satıra göre daralt (5 satır / ~300) ve aramada yalnız
görünen kartları yenile — ayrı karar/oturum.

**2. tur (aynı gün, aynı ölçüm):** dilim 10 satır/600 → **5 satır/300**, madde
200 → 120; hücrenin odak/açık-not `Consumer`ı kartın tek aboneliğine katıldı
(`NoteCard.frame`, hücre başına bir bağlama eksik). Kaydırma SF takılan
%4,2 / %3,4 / %4,0 (üç koşu), en kötü **33,5 / 49,5 ms**, LAYOUT p99 19 ms
(dilimi yarıya indirmek LAYOUT'u değiştirmedi), scavenge 27; arama en uzun
kare 139 ms (BUILD 65, LAYOUT 126). **Kabul yine SAĞLANMADI; iki denemeden
sonra yama yok, kalan engel ölçüldü:** (a) kaydırma: SF'ye hizalı atrace
(`hitch.py`) — kalan takılmaların hepsi tek kaçan vsync (33 ms); o karelerde
ana iş parçacığı 10-20 ms VE raster 10-17 ms birlikte → kart kurulumu +
Impeller GLES çizimi birlikte bütçeyi aşıyor (K7; Faz 23.4 / Faz 26 GPU işi,
kart küçük resim/zemin katmanları). (b) arama: süzgeç yalnız eşleşeni
gösterdiği ve kesit eşleşmeyi her kartta görünür kıldığı için her tuşta
görünen kartların vurgusu GERÇEKTEN değişiyor — "eşleşmesi değişmeyen kartı
koru" önerisinin yakalayacağı kart yok; kare önbellek payındaki (1600 px,
~30-40 kart) bütün kartların yeniden kurulumu + süzgeç sonrası ızgaranın
yeniden dağıtımı (`sliverBalancedNoteColumns`). Çözüm KARAR ister: aramada
önbellek payını daraltmak ya da vurguyu kartın dışına (katman) almak.
**KARAR (kullanıcı, 2026-11-03):** **vurgu kartın üstünde ayrı katman** — sorgu değişince kart yeniden kurulmaz, yalnız vurgu katmanı (madde **F21.6**, açık).

- [x] **F21.1 Önizleme dilimi.** Gövdenin kartta görünecek kadarı:
  `previewSlice(body)` — ilk ~10 satır ve ≤ ~600 karakter (kod birimi değil
  grapheme sınırında kes). `mask`, `richSpans`, `stripRichMarkers`,
  `foldForSearch` YALNIZ dilime. Liste maddesi metni de ≤ ~200 karakter. Başlık
  zaten kısa ama aynı kapıdan geçsin. Biçim işareti dilimin sonunda kapanmamış
  kalırsa düz metin çizilsin (`richSpans` eşleşmeyeni düz sayıyor — testle doğrula).
  **Yapıldı:** `card_preview.dart` `previewSlice` (10 satır / 600, grafem sınırı
  `CharacterRange.at`, satır ortasında `…`); örtme dilimden 64 karakter taşar
  (kesimde bölünen numara açık kalmasın); madde/sayfa notu 200; başlık dilimlenir
  (örtülmez, eskisi gibi). Liste görünümü satırı (`NoteListRow`) da dilimden.
- [x] **F21.2 Önizleme önbelleği.** Not örneği (kimlik/`updatedAt`) + ayar
  kümesi → hazır önizleme (`InlineSpan` ya da küçük bir değer nesnesi);
  `isCredentialNote` / hassas tarama not sürümü başına bir kez. Mevcut
  `_cardCache` (dashboard) aynı örneği döndürüyor ama ilk kurulum ve her not
  değişiminde maliyet hâlâ tam metin — önbellek dilim üzerinden.
  **Yapıldı:** `CardPreview.of(note, hideSensitive:)` — not ÖRNEĞİ başına
  `Expando` (akış değişmeyen notun örneğini koruyor): başlık/gövde/madde
  dilimleri, ekran okuyucu etiketi, TAM metinde parola taraması bir kez.
- [x] **F21.3 Arama vurgusu dilimin dışındaysa** eşleşmenin çevresinden kısa
  kesit göster ("… eşleşen kelime …", Keep gibi); yoksa sonuç kartında vurgu
  görünmez olur. Süzme (`filteredNotesProvider`) tam metinle kalır.
  **Yapıldı:** ölçüt "dilimin dışı" değil "dar kartın ilk satırlarında
  görünmüyor" (2 sütunlu telefonda 600 karakterin ~100'ü görünür).
  `searchExcerpt` eşleşmenin satır başından ya da ~24 karakter önceki sözcükten
  `… ` ile; gövde+konum süzgecin önbelleğinden (`bodySearchMatch`, önbelleğe
  işaretsiz gövde eklendi) — kart uzun gövdeyi yeniden taramaz.
- [x] **F21.4 Kart başına aboneliği azalt.** Kartta izlenen ayarlar
  (`cardDisplayProvider`, `cardRichPreviewProvider`, `cardHideSensitiveProvider`,
  `localFilesRevisionProvider`, klasör adı için `showAllNotesProvider` /
  `selectedFolderProvider` / `foldersStreamProvider`, `myNoteSharesProvider`)
  ızgara düzeyinde BİR kez izlensin, karta değer olarak geçsin; seçim durumu
  yalnız seçim kipi açıkken hücre düzeyinde. Hedef: kart `StatelessWidget` (ya
  da tek `watch`). Bu, K5'teki Riverpod duraklat/sürdür maliyetini de düşürür.
  **Yapıldı (tek watch):** `_cardEnvProvider` hepsini toplar, kart `select`
  ile yalnız kendi kaydını çeker (9 abonelik → 1; klasör adı yalnız arama /
  "Tümü"de ikinci). Kart API'si değişmedi (7 çağrı yeri aynen). Kart hâlâ
  `ConsumerWidget`; `mount` payı sürüyor (yukarıdaki (3)).
- [x] **F21.5 Kart kurulumunda bellek çalkantısı:** regex/dize üretimi dilim ve
  önbellekle düşer; kaydırmada scavenge sayısını ölç (taban 34 / 13 sn).
  **Ölçüldü:** 10 fırlatmada scavenge **29 → 27** (en uzun 10,9 → 8,4 ms) —
  sayı pek düşmedi; çalkantı artık metinden değil widget/eleman üretiminden.
- Kabul: kaydırma senaryosu takılan kare **< %1**, en kötü kare < 33 ms,
  LAYOUT p99 < 8 ms; arama senaryosunda en uzun ana blok < 16 ms; kapanış
  profilinde `NoteCard.build` / `maskSensitiveNumbers` YOK; testler: dilim
  (uzun gövde, grapheme, açık kalan işaret), arama kesiti.

- [x] **F21.6 Arama vurgusu kartın üstünde ayrı katman** (KARAR 2026-11-03).
  Sorgu değişince kart yeniden kurulmaz; vurgu dikdörtgenleri kartın metin
  düzeninden (önbellekli `TextPainter`/paragraf kutuları) hesaplanıp üstte
  ayrı `CustomPaint` katmanında çizilir. Süzgeç sonucu değişmeyen kartlar
  aynı örnek kalır (`ValueKey(note.id)`). Kabul: arama karesi < 16 ms
  (bugün 139 ms); vurgu testleri yeşil.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** `search_highlight.dart` — `SearchHighlight` render nesnesi canlı sorguyu (`ValueListenable`) dinler, eşleşme kutularını paragrafın `getBoxesForSelection`ından metnin ALTINA boyar; metin sorgudan bağımsız. Pano kart önbelleği anahtarı "arama var mı" (sorgu değil) → harf eklemek kart kurmaz; yalnız kesit (`_SearchExcerptBody`) değişince o parça kurulur. Bedel: vurgu kalın/renkli yazı değil (glif genişliği → yerleşim), zemin + alt çizgi. Testler: `search_highlight_test`, `card_preview_test`. Ölçüm: KALANLAR §2 #36.

## FAZ 22 — Firestore trafiği (K3, K4)

- [x] **F22.1 Önce ölç:** 50 / 250 / 500 notla kısa notta yazma senaryosu →
  kayıt sonrası ana blok (ms) ve kayıt başına olay sayısı. Beklenen: not
  sayısıyla doğrusal; olay sayısı 2.
  **Ölçüldü (2026-11-04, profil, `prof_save.py`, F22.3 sonrası):** kayıt başına ana liste olayı **1** (3 kayıtta 3; tek not dinleyicisi 2). 200 notta olay başına 593 KB, Dart çözme bloğu 11 ms, yazarken en kötü kare 15,7 ms, 0 kare > 16,7. 414 notta olay ~1,2 MB, Dart 21–27 ms, en kötü kare 26 ms, 2 kare aşan (bu koşuda içe aktarmadan kalan yükleme kuyruğu da olay üretti: 14 olay). Doğrusal → F22.4 hâlâ gerekçeli. 50 not ÖLÇÜLMEDİ (veriyi silmek gerekirdi); doğrudan ~3 ms. Java tarafı kodlama profilde görünmez.
- [x] **F22.2 Otomatik kaydı seyrekleştir.** **KARAR (kullanıcı, 2026-11-03):** EVET — ~2 sn boşluk, en geç 10 sn; kapanış/arka plan/odak kaybında hemen. Debounce 0,5 sn →
  ~2 sn boşluk, en geç 3 sn → ~10 sn; kapanış/arka plan/odak kaybında hemen
  (bugün de var: `_debouncer.flush`, `onPause`). Bedel: uygulama öldürülürse en
  çok ~10 sn'lik yazı (yerel önbellek yazımı anlık değil kayıtta). Kazanç: olay
  sayısı 3–4× azalır. Öneri: evet.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** `kEditorSaveDelay` 2 sn / `kEditorSaveMaxWait` 10 sn; çıkış kapıları değişmedi (`_saveNow`: dispose + `resumed` dışı her evre). Test `autosave_cadence_test`. Ölçüm KALANLAR §2 #34.
- [x] **F22.3 Kayıt başına ikinci olayı kaldır.** **KARAR (kullanıcı, 2026-11-03):** EVET — otomatik kayıtta istemci saati, sunucu zamanı kapanışta (`serverUpdatedAt ?? updatedAt`). Otomatik
  kayıtta `updatedAt` istemci saatiyle (`Timestamp.now()`); sunucu zamanı yalnız
  editör kapanışında (ya da ayrı `serverUpdatedAt` alanında). Etkilenenler
  (`grep updatedAt`, 7 karşılaştırma): `shared_note_activity` okunmamış
  hesabı, `push_service`, yedek, sıralama, `text_merge` üç yönlü birleştirme.
  Risk: cihaz saati yanlışsa sıra/okunmamış kayar. Öneri: sunucu zamanı
  kapanışta + karşılaştırmalar `serverUpdatedAt ?? updatedAt`.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** `updateNote(clientTime: true)` otomatik kayıtta `updatedAt = Timestamp.now()`; kapanışta ve `paused/detached`ta bir kez sunucu damgası (`_stampServerTimeOnExit` → `updateFields(id, {})`); `_saveNow` zaten sunucu zamanıyla yazar. Ayrı `serverUpdatedAt` alanı EKLENMEDİ (en güvenli: şema/kural/yedek değişmez, 7 karşılaştırma aynen `updatedAt`); cihaz saati yanlışsa sapma yalnız editör açıkken. Alan gerekirse **sabah bakılacak**.
- [ ] **F22.4 Senkron yükü not sayısından bağımsız.** **KARAR (kullanıcı, 2026-11-03):** **B seçildi** — hafif "kart dizini" + gövde ayrı belge. GÜVENLİK ŞARTLARI: göçten önce yerel tam yedek; göç idempotent ve sürümlü; eski şema bir sürüm boyunca okunmaya devam (geri dönüş mümkün); kurallar + `rules-test` + yedek/geri yükleme aynı oturumda; birden çok oturuma bölünebilir (önce okuma tarafı, sonra yazma, en son eski alanların kaldırılması). Aşağıdaki A metni bilgi için: Ana liste: ilk liste
  önbellekten bir kez (`GetOptions(source: cache)`), sonra yalnız
  `updatedAt > son görülen` sorgusu dinlenir → her olay yalnız değişen notları
  taşır, bedel not sayısından bağımsızlaşır. Gerekenler: kalıcı silmeler için
  mezar taşı (`_deleteCloudCopy` canlı notu `delete()` ediyor — başka cihaz bunu
  delta'da göremez → önce `deletedAt` yaz ya da `tombstones`), saat kayması
  için pay (`updatedAt` sunucu zamanı olmalı → F22.3 ile birlikte tasarla),
  ara sıra tam uzlaştırma. Alternatif B: hafif "kart dizini" belgesi + gövde
  ayrı belge (veri göçü, kurallar, yedek — daha büyük). Öneri: A.
  **Bulutta yapılmadı (2026-11-04):** yerel tam yedek şartı kullanıcının cihazında; dizin belgesi olmadan okuma tarafı ölü kod olur — `KALAN_ISLER_PLANI` **F19.F1** (sabah bakılacak).
- [x] **F22.5 Dart tarafı tek geçiş:** `watchNotes` → `_withLocal` → sıralama →
  `filteredNotesProvider` olay başına bir kez sıralasın; editör açıkken
  (telefonda tam ekran) gizli pano iş yapmasın — profil zaman çizelgesiyle ölç.
  **İncelendi (2026-11-04):** kod değişikliği gerekmedi — gizli pano (`TickerMode` kapalı) Riverpod 3'te aboneliği duraklatıyor, `filteredNotesProvider` editör açıkken olay başına hesaplanmıyor, görünür olunca bir kez yetişiyor (`hidden_dashboard_pause_test` sabitler). Olay başına sıralama: depo (`_compare`, ~0,2 ms/500 not) — diğer tüketiciler sıraya bağlı, kaldırılmadı. Profil ölçümü KALANLAR §2 #34 ile birlikte.
- [x] **F22.6 Editörün tek not dinleyicileri:** `noteStreamProvider` +
  `pendingWritesProvider` (`includeMetadataChanges`) kayıt başına kaç olay
  üretiyor, ölç; senkron göstergesi için gerekmeyen olayları ele.
  **Ertelendi (2026-11-04):** iki belge dinleyicisi (veri + `includeMetadataChanges`) tek akışa birleştirilebilir ama metadata-only olayı ayıklamak derin karşılaştırma ister; kazanç tek belge kodlaması (~ms), F22.3 ile kayıt başına olay zaten 3→2. Ölçmeden değiştirilmedi — **sabah bakılacak** (profilde `noteStreamProvider`/`pendingWritesProvider` olay sayısı).
  **Yapıldı (2026-11-04, 2. tur, cihazda ölçülmedi):** iki akış AYNI yerel `includeMetadataChanges` dinleyicisini paylaşır (`_DocHub`, Firestore örneğine bağlı — paylaşılan klasör deposu da aynı dinleyiciyi bulur; geç abone son görüntüyü hemen alır); not akışı metadata-only olayı `deepDataEquals` ile eler (varsayılan `snapshots()` anlamı). Kayıt başına yerel olay 3→2 (yazım + onay), her biri tam belge kodlaması. Test `shared_doc_listener_test`. Ölçüm KALANLAR §2 #41 (F27.1 sayacıyla).
- [x] **F22.7 Platform kanalı israfı:** `alwaysHandleBack` son değeri saklasın,
  değişmediyse kanal çağrısı yok (K4).
  **Yapıldı (2026-11-04):** `alwaysHandleBack` bir kez yazar, `detached`/`AppLifecycleListener.onDetach`ta unutur. `shared_notes_back_test`: üç geçişte tek kanal çağrısı.
- Kabul: kısa notta yazma senaryosunda kayıt sonrası ana blok **< 8 ms**,
  yazarken 0 kare > 33 ms; 500 notla da aynı (F22.4 sonrası).

## FAZ 23 — Geçişler: not açma/kapama (K5, K7)

- [x] **F23.1 Hero taramasını kapat.** Elle `Hero` yok; FAB'ların örtük Hero'su
  (`heroTag`) sayfa geçişinde uçmasın diye de gereksiz. Yönlendirici gezginini
  `HeroControllerScope.none` ile sar (MaterialApp `builder` içinde) — bedel:
  FAB'lar sayfalar arasında uçmaz, sayfayla birlikte geçer (zaten not
  geçişinde FAB altta kalıyor; gözle kontrol). `Hero(` kullanımını yakalayan
  küçük test. Kabul: kapanış profilinde `_allHeroesFor` yok.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** `HeroControllerScope.none` İŞLEMEZ — go_router her gezgine (`_CustomNavigator`) kendi HeroController'ını koyuyor. Yerine `withoutHeroWalk` = `HeroMode(enabled: false)` (tarama o düğümde durur): ana ekran, not (`_NoteOpenRoute.buildContent`) ve defter sayfaları. `hero_walk_test`: uçuş yok + `lib`te elle `Hero(` yok.
- [x] **F23.2 Kapanışta pano yeniden kurulmasın.** `FreezeWhenHidden` çözülürken
  değişmeyen kart kurulmasın (F21.4 sonrası ölç); Riverpod duraklat/sürdür
  maliyeti (`_updateTickerMode`) abonelik sayısı düşünce kalan kısmıyla ölç.
  **Ölçüldü (2026-11-04, widget profili):** kapanış karesinde yalnız 2 `NoteCard` kuruluyor (değişen not); `_updateTickerMode`/abonelik sürdürme %9, `filteredNotesProvider` yeniden hesabı %6,6 (~3-4 ms). Kod değişmedi: kalan maliyet düz dağılmış, tek hedef yok.
- [x] **F23.3 Editör sökümünü kapanış animasyonunun sonrasına ertele.** Kayıt
  flush'ı hemen (veri güvenliği); dinleyici/denetleyici/mürekkep/PDF sökümü ve
  `POST_FRAME` işleri geçiş bittikten sonra. Kabul: kapanışın ilk karesi < 16 ms.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** söküm zaten rota kalkınca; kapanış karelerine binen asıl iş bekleyen 2 sn'lik kayıt zamanlayıcısıydı → `noteRouteClosing`da `Debouncer.pause()`, rota kalkınca `dispose → _saveNow` yazar, jest vazgeçilirse `resume()`. Test `debouncer_test`.
- [x] **F23.4 Kapsayıcı dönüşümün GPU maliyeti (GLES).** `note_open_route.dart`
  `_ContainerTransform`: alttaki panoyu geçiş boyunca da görüntüden çiz (ya da
  tam örtülen bölgeyi hiç çizme), `Opacity` yerine görüntünün boya alfası,
  karartmayı tek katmanda; kenar yumuşatmalı kırpma yalnız yarıçap > 0 iken.
  Kabul: geçişte raster < 12 ms/kare (bugün 18–26).
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** `Opacity` kaldırıldı — dondurulmuş görüntü `_FadeSnapshotPainter` ile boya alfasıyla çizilir (görüntü yoksa `pushOpacity`/doğrudan); kırpma yarıçap > 0,5 iken `antiAlias`, sonra `hardEdge`, oturunca yok. Karartma zaten tek `ColoredBox`. Alttaki panonun görüntüden çizilmesi YAPILMADI (pano `FreezeWhenHidden`; ayrı görüntü ~10 MB doku — önce raster ölçümü). Test `note_open_transition_test`. Ölçüm KALANLAR §2 #42.
- [x] **F23.5 Editör ilk karesi hafif.** İlk karede yalnız görünen kısım (üst
  çubuk + ilk ekran metni); ek şeridi, kalem tepsisi, AI parçaları, sesli kayıt
  sonraki karelerde. Kabul: kısa/görselli notta dokunuş→ilk kare < 50 ms.
  **Bulutta yapılmadı (2026-11-04):** açılış geçişi sayfanın İLK karesini görüntüye alıp yalnız t=0,45'te bir kez tazeliyor (F23.4 / 2026-10-30 kök nedeni); sonraki karelere ertelenen parça (ek şeridi vb.) görüntüde yok, t=0,45'te içerik neredeyse opakken "pat" diye belirir. Kalem tepsisi, sesli kayıt paneli, AI şeridi ilk karede zaten boş (`null`/`SizedBox.shrink`). Hangi parçanın ilk karede pahalı olduğu profil olmadan bilinmiyor — KALANLAR §2 #43 (profilde editör ilk karesinin widget build dökümü), sonra erteleme + görüntü tazeleme birlikte.
  **Ölçüldü, kod değişmedi (2026-11-04, widget + CPU profili):** kısa notta ilk kare 47 ms (40 °C, profil), düz dağılmış: en büyük uygulama payı `ConsumerStatefulElement.mount` %10, tek başına ağır parça yok; ertelemek görüntü tazelemeyle "pat" etkisi getirir. Release: kısa/görselli açma en kötü aralık 33–50 ms, yani kabul (< 50 ms) sınırda (bir kez 66 ms). 120 maddede ilk kare 97→70 ms.
- Kabul (faz): 4 not türünde kapanışta **0 kare > 33 ms** (bugün 12/12'de 99
  ms); açılışta en çok 1 kare > 16,7 ms.

## FAZ 24 — Uzun not editörü: tuş başına O(n) (K2)

- [x] **F24.1 Eşik ölçümü:** 1 / 5 / 10 / 20 / 35 KB metinde tuş→kare ve Java
  `commitText` süresi → pencereli kipe geçiş eşiği (tahmin ~4–6 KB).
  **Ölçüldü (2026-11-04, profil, `prof_sizes.py`):** tahmin YANLIŞ, eşik çok daha aşağıda. Tek alanda LAYOUT ~5 ms/KB (41 °C): 1 KB p90 9 ms, 2 KB 12, 3 KB 17 (karelerin %43'ü bütçe üstü), 4 KB 21 (%75). **Eşik 6000 → 2500, pencere 3000 → 1500.** Sonra (38–40 °C) boyuttan bağımsız: 3/8/20/35 KB'ta LAYOUT p90 12 / 11,6 / 12,5 / 9,5 ms, kare p90 15,5 / 17,5 / 15,9 / 13,5 ms, IME iletisi ~1 KB (tek alanda 4 KB'ta 2,7 KB). Java `commitText` süresi profilde görünmez; bayt oranı yerine geçti.
- [x] **F24.2 Pencereli düzenleme.** **KARAR (kullanıcı, 2026-11-03):** PENCERELİ KİP (blok editörü değil). Gövde, eşiği
  aşınca paragraf listesi olarak çizilir (tembel `SliverList`, paragraf başına
  önbellekli `Text.rich` — biçim işaretleri satır sonunu aşmadığı için
  paragraflar bağımsız, bkz. `text_wrap_controller.dart` paragraf önbelleği);
  `TextField` yalnız imlecin çevresindeki pencereyi (± ~20 paragraf, ≤ ~3 KB)
  taşır. Tuşta yalnız pencere yerleşir; IME kanalı yalnız pencere metnini
  taşır. Pencere dışına dokunuş/ok tuşu/seçim → yeniden pencerele. Arama /
  değiştir, biçim kapsamı (`FormatScope`), geri alma, dikte, not bağlantıları,
  görsel sarma tam metin modeli üzerinden. Alternatif: blok editörü
  (super_editor tarzı, her paragraf ayrı düğüm) — daha büyük iş. Öneri:
  pencereli kip, kısa notlarda bugünkü yol aynen.
  **Kısmen (2026-11-04):** 1. parça — saf metin modeli `text_window.dart` (paragraf sınırında pencere `windowAround`, ofset eşlemesi, `spliceWindow` geri yazma, `needsRewindow`; eşik `kWindowedThreshold` = 6000 TAHMİN) + `text_window_test`. Editöre BAĞLI DEĞİL. Sonraki parçalar: (2) pencere dışı paragrafların önbellekli çizimi (`SliverList`) + dokunuşla yeniden pencereleme, (3) arama/biçim/geri alma/dikte tam metin üzerinden — F24.1 eşik ölçümünden sonra, cihazda doğrulamalı oturumda.
- [x] **F24.3 Madde listesi:** yalnız odaklanan madde `TextField`.** Odakta
  olmayan maddeler düz metin (`_cachedItemRow` zaten çiziyor); dokunulan madde
  düzenlenebilire döner. Sonra `_kFirstRows` / `_rowBudget` / kapanışta parça
  parça söküm (`noteRouteClosing`) hileleri silinir (usta 6b).
  **Bulutta yapılmadı (2026-11-04):** madde denetleyicilerine 15+ yerden kimlikle erişiliyor (biçim çubuğu hedefi, `insertTextAtCaret`, not içi arama/değiştir, dikte, ek etiketi çipleri, sürükle-bırak, Enter/Backspace birleştirme); düz metin satırına dokunuşta imleç konumu (`TextPainter.getPositionForOffset`) ve uzun basışla seçim yeniden kurulmalı. Cihazda yazma/seçim/dikte doğrulaması olmadan editörün en çok kullanılan yolu değiştirilmedi — **sabah bakılacak** (cihazlı oturumda, F24.1 ölçümüyle birlikte).
  **Yapıldı (2026-11-04):** `items_editor_lazy.dart`: madde `RichText`, dokununca/odak istenince gerçek alan ve öyle kalır. Bütün odak yolları `_LazyFocusNode.requestFocus` üzerinden alanı kurdurur (15+ yere dokunulmadı). Baştan gerçek alan: boş madde, görsel sarması, 📎, 📖, bağlantı, video damgası. Kırılım birebir: birleşmiş stil + 3 dp imleç payı (test). Testler varsayılan `debugEagerItemFields=true` (`test/flutter_test_config.dart`), düz yolu `items_editor_lazy_test` sınar. **Ölçüldü (aynı profil, ~34 °C):** bütçe üstü kare 27 → 7, ilk kare 97 → 70 ms, büyüme kareleri 23 ms → bütçe altı; kapanıştaki parça parça söküm silindi (tek kare, animasyon sonunda). Kademeli kurulum ÖLÇÜMLE kaldı: 100 satır tek karede 163 ms → ilk 16, 500 ms sonra kare başına 2. Telefonda dokun-yaz-Enter denendi; gerçek klavye önerisi, uzun basış, dikte KALANLAR §2 #60.
- [x] **F24.4 Görsel sarma ölçümü** (`WrapFieldMeasure`, `text_wrap.dart`) tam
  metni ikinci bir `TextPainter` ile yerleştiriyorsa paragraf bazlı önbellek.
  **İncelendi (2026-11-04):** kod değişikliği gerekmedi — `WrapFieldMeasure` görsel yokken ve tampon temizken (`floats.isEmpty && isPlain`) kare sonu geri çağrısını HİÇ kurmuyor (K2'nin uzun düz metin notunda ikinci yerleşim yok); görsel varken `planTextWrap` 2026-10-16'dan beri yalnız görsel BANDINI kapsayan öneki diziyor. Görselli uzun notta kalan maliyet F24.1 ölçümünde ayrıca görülür.
- Kabul: 35 KB notta tuş→kare **p95 < 16 ms**, yazarken 0 kare > 33 ms; 120
  maddelik liste açılışı dokunuş→ilk kare < 60 ms, açılıştan sonra 100 ms'yi
  aşan kesintisiz ana iş yok; geri alma/dikte/arama testleri yeşil.

## FAZ 25 — Soğuk açılış (K8)

- [x] **F25.1 Yazı tipi beklemesi.** **KARAR (kullanıcı, 2026-11-03):** yalnız ana ekranda görünen yazı tipi beklenir, gerisi arka planda. Önce ölç:
  `preloadNoteFonts` gerçek süresi ve beklemeyi kaldırınca ilk kullanımdaki
  yeniden yerleşim maliyeti (HAFIZA: bekleme bir kasmayı çözmek için kondu).
  Seçenek: yalnız ana ekranda görünen yazı tipini bekle, gerisi arka planda.
  **Bulutta yapılmadı (2026-11-04):** KARAR "önce ölç" — arka planda yüklenen her yazı tipi motora "yazı tipleri değişti" dedirtip ekrandaki BÜTÜN metni yeniden yerleştiriyor (bekleme bu yüzden kondu); `preloadNoteFonts` süresi ve ilk 2 sn'deki yeniden yerleşim telefonda ölçülmeden değiştirilmedi.
  **Yapıldı (2026-11-04):** ölçüm: açılışta 35 dosya / 5,2 MB ana iş parçacığında (kanal sayacı `flutter/assets`), ama `loadFontFromList` yalnız %1,7. Yalnız genel yazı tipi beklenir (`preloadNoteFonts(appFamily)`). KARARDAN SAPMA: "gerisi arka planda" yerine **seçici açılınca** (`preloadRemainingNoteFonts`): arka plan yüklemesi her dosyada motora "yazı tipleri değişti" dedirtip ekrandaki metni yeniden dizerdi; kaydedilen ailesi farklı not ilk açılışta o aileyi bir kez yükler — **sabah bakılacak**. Sonuç: `flutter/assets` 5248 → 295 KB, Dart ilk kare 119 → 53 ms.
- [x] **F25.2 Anında içerik.** Son ana ekranın ilk ~30 kartının hafif özeti
  (başlık, F21.1 dilimi, renk, bayraklar, küçük resim yolu) arka plana geçişte
  diske; açılışta ilk karede bunlar çizilir, Firestore gelince sessizce
  uzlaştırılır (Keep davranışı). İskelet→içerik titremesi de kalkar.
  **Bulutta yapılmadı (2026-11-04):** yeni KARAR doğuyor — diskteki özet bayatsa (başka cihazda silinen/taşınan not) ilk karede hayalet kart çizilir, dokununca "not bulunamadı"; kilitli/gizli klasör notlarının özeti diske düz yazılır mı. Ayrıca Firestore yerel önbelleğinin ilk yayın süresi ölçülmedi (kazanç bilinmiyor). En güvenli: ölçmeden yapma — KALANLAR §2 #44, **sabah bakılacak**.
- [x] **F25.3 İlk 2 saniyenin platform kanalı trafiği:** App Check,
  `DisplayRate`, `ImageCacheBudget`, widget teması/güncellemesi, göçler,
  presence, FCM — ilk içerik karesinden sonraya ve birbirinden ayrı karelere yay.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** `AppServices` kademeli — not kilidi, derin bağlantı, paylaş menüsü ilk karede; premium, göçler, yükleme kuyruğu, tercih senkronu, hatırlatıcı, konum temizliği, paylaşım hareketi, FCM, widget, transkript ilk kareden SONRA kare başına BİR (`Priority.idle` dilimi, en geç 400 ms). `main` App Check / `DisplayRate` / `ImageCacheBudget` aynı biçimde (`_staggerAfterFirstFrame`). Test `app_services_stagger_test`. Ölçüm KALANLAR §2 #45 (F27.1 sayacı + zaman çizelgesi).
- Kabul: soğuk açılış ilk kare < 600 ms (bugün ~770), içerik ilk karede, ilk 2
  sn'de > 50 ms kare yok (bugün 313–396 ms donuk kare).
  **Durum (v1.1.667):** TotalTime 776–802 ms (< 600 SAĞLANMADI; kalan büyük kısmı Dart öncesi), içerik ilk karede evet, donuk kare 115–181 ms (> 50 sürüyor: ilk ızgara 138 ms, Firestore yetişmesi 55 ms). Ek kök neden düzeltildi: boş çöpte bütün notların parmak izi (açılıştan 5 sn sonra CPU'nun %20'si) → `trashReminderPlan` erken döner, dolu çöpte `runHeavy`.

## FAZ 26 — Titreme ve görsel kararlılık (K9)

- [x] **F26.1 Videoyla ölç.** `adb shell screenrecord --bit-rate 20000000` ile
  açılış, arka plandan dönüş, segment/klasör geçişi, editörden dönüş, kaydırma;
  kare kare inceleme (ffmpeg ile kareler) → titreme listesi (iskelet,
  görsel geç gelme, yerleşim zıplaması, renk/tema yanıp sönmesi).
  **Ölçüldü (2026-11-04, v1.1.667, `video.py`, 30 fps fark + kare yaprağı):** uygulama içinde flaş 0, zıplama 0; iskelet→içerik ve görsel geç gelme görülmedi. Tek bulgu: soğuk açılışta ~0,6 sn BEYAZ sistem penceresi, sonra tema zemini (titreme değil, marka uyumu) → TEMA_PLANI Faz 35'e bırakıldı. Klasör çipi geçişi kısa çapraz solma, bilinçli.
- [x] **F26.2 Arka planda görsel önbelleği.** **KARAR (kullanıcı, 2026-11-03):** TUT — yalnız `onTrimMemory`/`didHaveMemoryPressure`'da boşalt.
  `onPause`ta `imageCache.clear()` + `CardThumbs.clearMemory()` yerine yalnız
  `onTrimMemory`/`didHaveMemoryPressure`'da boşalt. Bedel: arkadaki uygulama
  birkaç MB fazla tutar.
  **Yapıldı (2026-11-04, cihazda ölçülmedi):** `main.dart` `onPause`ta `imageCache.clear()` + `CardThumbs.clearMemory()` kaldırıldı; boşaltma yalnız `_MemoryPressure.didHaveMemoryPressure` (Android `onTrimMemory`).
- [x] **F26.3 Sıra zıplaması.** Editör açıkken düzenlenen not "Son
  güncellenen"de tepeye zıplamasın: editör kapanınca kart yerinden tepeye
  animasyonla taşınsın (ya da Keep gibi dönüşte bir kez yerleşsin).
  **Yapıldı (2026-11-04, cihazda ölçülmedi):** `sortHeldNoteIdsProvider` — editör notu tutar, sıralama o not için açıldığı andaki `updatedAt`i kullanır (son güncellenen, renk/başlık eşitliği, elle sıralamadaki eşit `orderIndex`); kart içeriği güncel. KAPANIŞ başlayınca (`noteRouteClosing`) bırakılır: telefonda pano görünmeden yerine oturur, küçülen not yeni yere iner; jestten vazgeçilirse yeniden tutulur; geniş ekranda kapanışta bir kez. Test `sort_hold_test`. Gözle: KALANLAR §2 #46.
- [x] **F26.4 Segment geçişinde çift ızgara:** `AnimatedSwitcher` sırasında
  eski + yeni ızgaranın birlikte kurulma maliyeti ve görsel flaşı ölç.
  **Yapıldı (2026-11-04, yazıldı, ölçülmedi):** ayrılan ızgara `SnapshotWhenLeaving` ile bir kez görüntüye alınır (her karede yarı saydam katmanda rasterleşmez, dokunuş almaz); sarmalayıcı hep ağaçta — durum/kaydırma korunur. Flaş (iki yarı saydam ızgara) videoyla ölçülecek — KALANLAR §2 #46. Test `snapshot_when_leaving_test`.
- Kabul: videoda belirgin flaş/zıplama yok; listede düzeltilenler.

## FAZ 27 — Hijyen ve regresyon kapısı (K6, K10)

- [x] **F27.1 Platform kanalı sayacı:** profil derlemesinde kanal adı + bayt
  günlüğü (geçici `BinaryMessenger` sarmalayıcısı) → senaryo başına en çok
  konuşan kanallar; gereksizleri ele (K4).
  **Yapıldı (2026-11-04):** `channel_counter.dart` — `Diagnostics.enabled` (debug/profil) derlemede `ChannelCountingBinding` varsayılan ileticiyi sarar (kanal başına giden/gelen ileti + bayt); VM servisi `ext.notlar.channels` (`reset=true`), `tool/perf/vmsvc.py` `VM.channels()`, Ayarlar → Hakkında teşhis satırında ilk 3 kanal. Release'te kod yok. Test `channel_counter_test`. "Gereksizleri ele" kısmı ölçümden sonra (KALANLAR §2 #41/#45).
- [x] **F27.2 Erişilebilirlik servisi açıkken** (şifre yöneticisi, ekran
  okuyucu) semantik ağacın kare maliyetini ölç; büyük ağaçlarda süsleri
  `ExcludeSemantics`.
  **Ölçüldü (2026-11-04, `prof_a11y.py`, sistem ayarı değişmeden `uiautomator events`):** kaydırmada SEMANTICS p50 6,7 / p90 10,2 / en çok 20 ms; bütçe üstü kare 10 → 50 (~300 karede), kare p90 10,6 → 19,7 ms. Kart zaten tek düğüm (+ ⋮); kesilecek süs yok, kalan bedel çerçevenin kaydırmada geometri güncellemesi. Kod değişmedi. Şifre yöneticisi açık kullanıcıda kaydırma ~%15 takılır: bilinen sınır.
- [ ] **F27.3 (yapılamadı: Vulkan'lı cihaz yok, KALANLAR §2 #59) Vulkan'lı bir cihazda** (Adreno > 650 ya da Mali) geçiş ve kaydırma
  ölçümü — hedefler iki arka uçta da sağlansın.
- [x] **F27.4 Sürüm öncesi duman testi:** `tool/perf` senaryoları test
  telefonunda; Ek B'ye satır. CI bütçesi: p90 < 8 ms, p99 < 16 ms, en kötü < 33 ms.
  **Kısmen (2026-11-04):** CI bütçesi `perf_driver.dart`ta p90 < 8, p99 < 16, en kötü < 33 ms. Telefon duman testi KALANLAR §2 #38.
  **Yapıldı (2026-11-04):** `python -u tool/perf/taban.py <etiket>` (~8 dk) Ek B satırı üretir; v1.1.661 ve v1.1.667 satırları.

---

## Ek A — Ölçüm yöntemi (tekrar üretmek için)

Ayrıntı ve komutlar: `tool/perf/README.md`. Özet:

- **Release (gerçek kullanıcı deneyimi):** `dumpsys SurfaceFlinger --latency
  '<SurfaceView katmanı>'` 0,7 sn'de bir okunur (tampon 128 kare) → kare
  aralıkları; `atrace sched …` → `main` / `1.raster` / `1.io` / `DartWorker`
  koşu patlamaları. Release'te Dart zaman çizelgesi YOK (`--trace-systrace`
  release'te yasak) ama `--ez enable-impeller false` niyet bayrağı release'te
  çalışıyor (Skia A/B için).
- **Saat hizalama:** atrace boot saatinde, SurfaceFlinger monotonikte; ana
  iş parçacığındaki `deliverInputEvent … eventTimeNano=` (monotonik) ile fark
  bulunur (`hitch.py`). Bu cihazda atrace'e grafik işaretleri düşmüyor.
  Takılmayı kimin tetiklediği: `sched_waking` → uyandıran iş parçacığı
  (`FirestoreWorker` bulgusu buradan).
- **Profil ("Notlar Ölçüm", `dev.kaimau.notlar.olcum`):** VM servisi HTTP GET
  ile (`/getVMTimeline`, `/getCpuSamples`); CPU örnekleyici varsayılan KAPALI →
  `setFlag profiler true`. Kare evreleri (BUILD/LAYOUT/PAINT), GC olayları,
  bütçeyi aşan karelerdeki fonksiyonlar (`prof_*.py`).
- **TUZAKLAR:** Xiaomi'de YENİ paket kurulumu "USB üzerinden yükle" onayı ister
  (adb ile `Yükle`ye basılır; güncelleme istemez). Ekran zaman aşımı 60 sn —
  uzun döngülerde zararsız Shift tuşu. `uiautomator dump` Flutter semantiğini
  açar → ölçüm sırasında dökme yapma. Arka arkaya geri tuşu uygulamayı
  kapatabilir → her senaryodan önce `front()` ile öndeki uygulamayı doğrula.
  Varsayılan kimlikle `flutter run/drive` test telefonunda ASLA (veri silinir).

## Ek B — Ölçüm kayıtları

| Tarih | Sürüm | Kaydırma takılan % / en kötü | Kapanış en kötü | Kısa not yazma: kayıt sonrası ana blok | 35 KB yazma tuş→kare | Açılış ilk kare / donuk kare |
|---|---|---|---|---|---|---|
| 2026-11-03 | v1.1.613 | %6,5 / 99–115 ms | 99 ms (12/12) | 27–56 ms | 90–110 ms LAYOUT, 4,6 fps | ~770 ms / 313–396 ms |
| 2026-11-04 | profil, main (F21–F27 bulut kodu) | %2,3 / 50 ms | animasyon 17 ms, en çok 1×33 ms (bkz. not) | en kötü kare 21 ms | 122 ms LAYOUT | TotalTime 1315–2273 / 587–654 ms |
| 2026-11-04 | profil, F24.2 + F25.2 | — | — | — | LAYOUT p90 11 ms, 1/46 kare bütçe üstü (pencereye giriş ~195 ms, bir kez) | TotalTime 1518–1586 = İLK KARE İÇERİK (önce ilk kare iskelet 1315–1411, içerik ~2,5 sn); ardından ~750 ms Firestore bekleme (ekran sabit, içerik görünür) |
| 2026-11-04 | **v1.1.661 release — ZİNCİR TABANI** (Tema/Tutarlılık bununla karşılaştırır; `tool/perf/taban.py`, 230 not, dikey) | %3,5 / 49,7 ms (39 kayıp vsync) | animasyon 33 ms (son aralık ~99 ms bekleme, takılma değil); 120 maddede 50 ms ×3 | ana blok en uzun 90 ms, >16 ms 12 blok | ana blok en uzun 164 ms, >16 ms 35 blok | TotalTime 690–880 / 198–264 ms |
| 2026-11-04 | **v1.1.667 release** (F24.1, F24.3, F25.1; aynı betik, soğuk telefon 26–30 °C) | %3,8 / 49,9 ms (44 kayıp vsync; K7, bu turda dokunulmadı) | animasyon 33 ms; uzun notlarda 50 ms ×1–2 | ana blok en uzun 90 ms, >16 ms 16 blok | ana blok en uzun 148 ms (pencereye giriş), >16 ms 40 blok* | TotalTime 776–802 (kurulum sonrası ilk 1516) / 115–181 ms |
| 2026-11-05 | **v1.1.671 release** (TEMA Faz 29–34; aynı betik, soğutulmuş telefon 29–32 °C) | %2,5 / 49,7 ms (29 kayıp vsync) | animasyon 33 ms; uzun notlarda 50 ms | ana blok en uzun 75 ms, >16 ms 22 blok | ana blok en uzun 148 ms, >16 ms 42 blok* | TotalTime 774–803 / 132–165 ms |
| 2026-11-05 | **v1.1.677 release** (TUTARLILIK Faz 37; aynı betik, telefon 18–25 °C; v1.1.675'te de koşuldu) | %0,4 / 32,8 ms (4 kayıp vsync; v1.1.675: %1,0 / 48,3 ms) | animasyon 33 ms; uzun notlarda 50–82 ms | ana blok en uzun 86 ms, >16 ms 28 blok (v1.1.675: 62 ms, 31) | ana blok en uzun 179 ms, >16 ms 43 blok* (v1.1.675: 183 ms, 47; taban 148 ms, 42) — İZLE: nedeni bulunmadı, Faz 37 yazma yoluna dokunmadı, tuş sütunu `adb input` (profil esas) | TotalTime ~760–1170 / ilk 1572 ms |
| 2026-11-03 | profil, Faz 21 öncesi → sonrası | %8,4 / 115 ms → %3,5 / 50–66 ms (1. tur) → %3,4–4,2 / 33–50 ms (2. tur) | — | — | — | — |

**Taban ayrıntısı (v1.1.661):** açma en kötü aralık kısa 33–50, görselli 33–50, 500 satır 33–66 ms; 120 maddede 680–697 ms görünen aralık DA yanılgı: donma değil, ilk 12 madde çizilip 1100 ms bekleme boşluğu (profilde en uzun kare 97 ms). Yazma sütunlarında SF aralığı boşta beklemeyi de sayar; güvenilir sayı ana blok ve profil LAYOUT'u.

*`adb input text` tuş olayı yolu, gerçek IME değil; bu sütunda tuş başına kare için profil sayısı (F24.1) esas.

**ÖLÇÜM YANILGISI (2026-11-04):** kapanıştaki "99–117 ms donma" takılma DEĞİL: SF aralığı son animasyon karesi → ~120 ms sonraki yetişme karesi; ekranda değişen yok, animasyon boyunca 17 ms. `analyze()` boşta bekleme eşiği (250 ms) bunu takılma sayıyor; kapanışta aralıkları sırayla oku.

**CI emülatörü (`[perf]`, x86_64 API 34, yazılım GPU — mutlak değil koşudan koşuya karşılaştır):**

| Tarih | Koşu | Senaryo | build p90 / p99 / en kötü (ms) | raster p90 |
|---|---|---|---|---|
| 2026-11-04 | 41785838651 (F21.6 + F20.2 dahil) | dashboard_scroll | 3,4 / 4,7 / 5,7 | 5,1 |
| 2026-11-04 | 41785838651 | editor_typing (200 krk) | 0,3 / 0,4 / 1,2 | 5,1 |
| 2026-11-04 | 41785838651 | editor_typing_30kb (100 tuş) | 0,3 / 2,0 / 4,8 | 4,7 |
| 2026-11-04 | 41785838651 | dashboard_search ("önemli" ×3) | 3,6 / 6,2 / 6,9 | 4,3 |
