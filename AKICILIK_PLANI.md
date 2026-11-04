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
| 20 | Ölçüm kapısı (gerçekçi veri, yan yana profil derlemesi, CI bütçesi) | Kısmen | 2026-11-04 | F20.1 araçlar, F20.3 gerçekçi CI verisi + 2 senaryo; F20.2/F20.4 telefon |
| 21 | Ana ekran kartı: önizlemeyi kırp, kart başına işi azalt | Kısmen | 2026-11-04 | 2 tur: takılma %8,4→%3,4–4,2, en kötü 115→33–50 ms, arama 465→139 ms; kabul sağlanmadı — kalan engel raster+kurulum (K7); F21.6 arama katmanı yazıldı (2026-11-04, cihazda ölçülmedi) |
| 22 | Firestore trafiği: yazımda tüm koleksiyon ana iş parçacığında | Kısmen | 2026-11-04 | F22.2/3/5/7 bulutta (cihazda ölçülmedi); F22.1 ölçüm, F22.4 göç, F22.6 açık |
| 23 | Geçişler: not açma/kapama | Kısmen | 2026-11-04 | F23.1 Hero taraması + F23.3 kayıt zamanlayıcısı (cihazda ölçülmedi); F23.2/4/5 ölçüm |
| 24 | Uzun not editörü: tuş başına O(n) | Açık | — | En büyük iş; mimari KARAR |
| 25 | Soğuk açılış | Açık | — | |
| 26 | Titreme ve görsel kararlılık | Açık | — | Önce videoyla ölç |
| 27 | Hijyen + regresyon kapısı | Kısmen | 2026-11-04 | F27.4 CI bütçesi (p90/p99/en kötü) |

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
- [ ] **F20.4 Taban çizelgesi** bu dosyadaki tablo; her faz sonunda aynı
  senaryolarla yeni satır (Ek B).

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

- [ ] **F22.1 Önce ölç:** 50 / 250 / 500 notla kısa notta yazma senaryosu →
  kayıt sonrası ana blok (ms) ve kayıt başına olay sayısı. Beklenen: not
  sayısıyla doğrusal; olay sayısı 2.
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
- [x] **F22.5 Dart tarafı tek geçiş:** `watchNotes` → `_withLocal` → sıralama →
  `filteredNotesProvider` olay başına bir kez sıralasın; editör açıkken
  (telefonda tam ekran) gizli pano iş yapmasın — profil zaman çizelgesiyle ölç.
  **İncelendi (2026-11-04):** kod değişikliği gerekmedi — gizli pano (`TickerMode` kapalı) Riverpod 3'te aboneliği duraklatıyor, `filteredNotesProvider` editör açıkken olay başına hesaplanmıyor, görünür olunca bir kez yetişiyor (`hidden_dashboard_pause_test` sabitler). Olay başına sıralama: depo (`_compare`, ~0,2 ms/500 not) — diğer tüketiciler sıraya bağlı, kaldırılmadı. Profil ölçümü KALANLAR §2 #34 ile birlikte.
- [ ] **F22.6 Editörün tek not dinleyicileri:** `noteStreamProvider` +
  `pendingWritesProvider` (`includeMetadataChanges`) kayıt başına kaç olay
  üretiyor, ölç; senkron göstergesi için gerekmeyen olayları ele.
  **Ertelendi (2026-11-04):** iki belge dinleyicisi (veri + `includeMetadataChanges`) tek akışa birleştirilebilir ama metadata-only olayı ayıklamak derin karşılaştırma ister; kazanç tek belge kodlaması (~ms), F22.3 ile kayıt başına olay zaten 3→2. Ölçmeden değiştirilmedi — **sabah bakılacak** (profilde `noteStreamProvider`/`pendingWritesProvider` olay sayısı).
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
- [ ] **F23.2 Kapanışta pano yeniden kurulmasın.** `FreezeWhenHidden` çözülürken
  değişmeyen kart kurulmasın (F21.4 sonrası ölç); Riverpod duraklat/sürdür
  maliyeti (`_updateTickerMode`) abonelik sayısı düşünce kalan kısmıyla ölç.
  **Açık (ölçüm):** kart önbelleği (F2.1) + F21.4 sonrası yetişmede değişmeyen kart aynı örnek; kalan maliyet ancak profilde görülür — KALANLAR §2 #35 ile ölç.
- [x] **F23.3 Editör sökümünü kapanış animasyonunun sonrasına ertele.** Kayıt
  flush'ı hemen (veri güvenliği); dinleyici/denetleyici/mürekkep/PDF sökümü ve
  `POST_FRAME` işleri geçiş bittikten sonra. Kabul: kapanışın ilk karesi < 16 ms.
  **Yapıldı (2026-11-04, yazıldı, cihazda ölçülmedi):** söküm zaten rota kalkınca; kapanış karelerine binen asıl iş bekleyen 2 sn'lik kayıt zamanlayıcısıydı → `noteRouteClosing`da `Debouncer.pause()`, rota kalkınca `dispose → _saveNow` yazar, jest vazgeçilirse `resume()`. Test `debouncer_test`.
- [ ] **F23.4 Kapsayıcı dönüşümün GPU maliyeti (GLES).** `note_open_route.dart`
  `_ContainerTransform`: alttaki panoyu geçiş boyunca da görüntüden çiz (ya da
  tam örtülen bölgeyi hiç çizme), `Opacity` yerine görüntünün boya alfası,
  karartmayı tek katmanda; kenar yumuşatmalı kırpma yalnız yarıçap > 0 iken.
  Kabul: geçişte raster < 12 ms/kare (bugün 18–26).
- [ ] **F23.5 Editör ilk karesi hafif.** İlk karede yalnız görünen kısım (üst
  çubuk + ilk ekran metni); ek şeridi, kalem tepsisi, AI parçaları, sesli kayıt
  sonraki karelerde. Kabul: kısa/görselli notta dokunuş→ilk kare < 50 ms.
- Kabul (faz): 4 not türünde kapanışta **0 kare > 33 ms** (bugün 12/12'de 99
  ms); açılışta en çok 1 kare > 16,7 ms.

## FAZ 24 — Uzun not editörü: tuş başına O(n) (K2)

- [ ] **F24.1 Eşik ölçümü:** 1 / 5 / 10 / 20 / 35 KB metinde tuş→kare ve Java
  `commitText` süresi → pencereli kipe geçiş eşiği (tahmin ~4–6 KB).
- [ ] **F24.2 Pencereli düzenleme.** **KARAR (kullanıcı, 2026-11-03):** PENCERELİ KİP (blok editörü değil). Gövde, eşiği
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
- [ ] **F24.3 Madde listesi: yalnız odaklanan madde `TextField`.** Odakta
  olmayan maddeler düz metin (`_cachedItemRow` zaten çiziyor); dokunulan madde
  düzenlenebilire döner. Sonra `_kFirstRows` / `_rowBudget` / kapanışta parça
  parça söküm (`noteRouteClosing`) hileleri silinir (usta 6b).
- [ ] **F24.4 Görsel sarma ölçümü** (`WrapFieldMeasure`, `text_wrap.dart`) tam
  metni ikinci bir `TextPainter` ile yerleştiriyorsa paragraf bazlı önbellek.
- Kabul: 35 KB notta tuş→kare **p95 < 16 ms**, yazarken 0 kare > 33 ms; 120
  maddelik liste açılışı dokunuş→ilk kare < 60 ms, açılıştan sonra 100 ms'yi
  aşan kesintisiz ana iş yok; geri alma/dikte/arama testleri yeşil.

## FAZ 25 — Soğuk açılış (K8)

- [ ] **F25.1 Yazı tipi beklemesi.** **KARAR (kullanıcı, 2026-11-03):** yalnız ana ekranda görünen yazı tipi beklenir, gerisi arka planda. Önce ölç:
  `preloadNoteFonts` gerçek süresi ve beklemeyi kaldırınca ilk kullanımdaki
  yeniden yerleşim maliyeti (HAFIZA: bekleme bir kasmayı çözmek için kondu).
  Seçenek: yalnız ana ekranda görünen yazı tipini bekle, gerisi arka planda.
  **Bulutta yapılmadı (2026-11-04):** KARAR "önce ölç" — arka planda yüklenen her yazı tipi motora "yazı tipleri değişti" dedirtip ekrandaki BÜTÜN metni yeniden yerleştiriyor (bekleme bu yüzden kondu); `preloadNoteFonts` süresi ve ilk 2 sn'deki yeniden yerleşim telefonda ölçülmeden değiştirilmedi.
- [ ] **F25.2 Anında içerik.** Son ana ekranın ilk ~30 kartının hafif özeti
  (başlık, F21.1 dilimi, renk, bayraklar, küçük resim yolu) arka plana geçişte
  diske; açılışta ilk karede bunlar çizilir, Firestore gelince sessizce
  uzlaştırılır (Keep davranışı). İskelet→içerik titremesi de kalkar.
- [ ] **F25.3 İlk 2 saniyenin platform kanalı trafiği:** App Check,
  `DisplayRate`, `ImageCacheBudget`, widget teması/güncellemesi, göçler,
  presence, FCM — ilk içerik karesinden sonraya ve birbirinden ayrı karelere yay.
- Kabul: soğuk açılış ilk kare < 600 ms (bugün ~770), içerik ilk karede, ilk 2
  sn'de > 50 ms kare yok (bugün 313–396 ms donuk kare).

## FAZ 26 — Titreme ve görsel kararlılık (K9)

- [ ] **F26.1 Videoyla ölç.** `adb shell screenrecord --bit-rate 20000000` ile
  açılış, arka plandan dönüş, segment/klasör geçişi, editörden dönüş, kaydırma;
  kare kare inceleme (ffmpeg ile kareler) → titreme listesi (iskelet,
  görsel geç gelme, yerleşim zıplaması, renk/tema yanıp sönmesi).
- [x] **F26.2 Arka planda görsel önbelleği.** **KARAR (kullanıcı, 2026-11-03):** TUT — yalnız `onTrimMemory`/`didHaveMemoryPressure`'da boşalt.
  `onPause`ta `imageCache.clear()` + `CardThumbs.clearMemory()` yerine yalnız
  `onTrimMemory`/`didHaveMemoryPressure`'da boşalt. Bedel: arkadaki uygulama
  birkaç MB fazla tutar.
  **Yapıldı (2026-11-04, cihazda ölçülmedi):** `main.dart` `onPause`ta `imageCache.clear()` + `CardThumbs.clearMemory()` kaldırıldı; boşaltma yalnız `_MemoryPressure.didHaveMemoryPressure` (Android `onTrimMemory`).
- [ ] **F26.3 Sıra zıplaması.** Editör açıkken düzenlenen not "Son
  güncellenen"de tepeye zıplamasın: editör kapanınca kart yerinden tepeye
  animasyonla taşınsın (ya da Keep gibi dönüşte bir kez yerleşsin).
- [ ] **F26.4 Segment geçişinde çift ızgara:** `AnimatedSwitcher` sırasında
  eski + yeni ızgaranın birlikte kurulma maliyeti ve görsel flaşı ölç.
- Kabul: videoda belirgin flaş/zıplama yok; listede düzeltilenler.

## FAZ 27 — Hijyen ve regresyon kapısı (K6, K10)

- [ ] **F27.1 Platform kanalı sayacı:** profil derlemesinde kanal adı + bayt
  günlüğü (geçici `BinaryMessenger` sarmalayıcısı) → senaryo başına en çok
  konuşan kanallar; gereksizleri ele (K4).
- [ ] **F27.2 Erişilebilirlik servisi açıkken** (şifre yöneticisi, ekran
  okuyucu) semantik ağacın kare maliyetini ölç; büyük ağaçlarda süsleri
  `ExcludeSemantics`.
- [ ] **F27.3 Vulkan'lı bir cihazda** (Adreno > 650 ya da Mali) geçiş ve kaydırma
  ölçümü — hedefler iki arka uçta da sağlansın.
- [ ] **F27.4 Sürüm öncesi duman testi:** `tool/perf` senaryoları test
  telefonunda; Ek B'ye satır. CI bütçesi: p90 < 8 ms, p99 < 16 ms, en kötü < 33 ms.
  **Kısmen (2026-11-04):** CI bütçesi `perf_driver.dart`ta p90 < 8, p99 < 16, en kötü < 33 ms. Telefon duman testi KALANLAR §2 #38.

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
| 2026-11-03 | profil, Faz 21 öncesi → sonrası | %8,4 / 115 ms → %3,5 / 50–66 ms (1. tur) → %3,4–4,2 / 33–50 ms (2. tur) | — | — | — | — |

**CI emülatörü (`[perf]`, x86_64 API 34, yazılım GPU — mutlak değil koşudan koşuya karşılaştır):**

| Tarih | Koşu | Senaryo | build p90 / p99 / en kötü (ms) | raster p90 |
|---|---|---|---|---|
| 2026-11-04 | 41785838651 (F21.6 + F20.2 dahil) | dashboard_scroll | 3,4 / 4,7 / 5,7 | 5,1 |
| 2026-11-04 | 41785838651 | editor_typing (200 krk) | 0,3 / 0,4 / 1,2 | 5,1 |
| 2026-11-04 | 41785838651 | editor_typing_30kb (100 tuş) | 0,3 / 2,0 / 4,8 | 4,7 |
| 2026-11-04 | 41785838651 | dashboard_search ("önemli" ×3) | 3,6 / 6,2 / 6,9 | 4,3 |
