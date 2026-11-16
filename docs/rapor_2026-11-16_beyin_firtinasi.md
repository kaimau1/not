# Beyin fırtınası raporu — 16 Kasım 2026

Zamanlanmış görevin istediği yedi başlık: hızlı ekle, performans/APK boyutu, akıllı liste,
Google Play'e çıkış, yapay zekâ, Firebase maliyeti, "satar mı?". **Uygulamada hiçbir kod
değişmedi; bu dosya yalnız öneri ve plandır.**

**Nasıl okunmalı**

- **[KOD]** = bu oturumda koddan/depodaki belgeden okundu (dosya:satır verilir).
- **[ÇIKARIM]** = koda bakarak vardığım sonuç; cihazda ya da testle doğrulanmadı.
- **[DIŞ]** = internetten bakılan kural/fiyat (16 Kasım 2026). Fiyatlar ve kurallar değişir;
  para harcamadan önce resmî sayfadan teyit et. Vergi/hukuk kısımları bilgi amaçlıdır,
  mali müşavir/avukat görüşü yerine geçmez.
- Hiçbir şey cihazda ölçülmedi. "Hızlanır" dediğim her şey **tahmindir**; HIZ SÖZLEŞMESİ
  gereği ölçülmeden doğru sayılmaz.
- Dondurma kuralı (K-O1) yürürlükte: aşağıdaki "yeni özellik" fikirleri sen açıkça
  istemedikçe zincir tarafından yapılmaz. Hata düzeltmesi sayılanları ayrıca işaretledim.

---

## 0. Önce özet — sabah okunacak 12 satır

1. **Klavye açıkken menü/panel kasması için en somut bulgu:** S48/S52'de düzelttiğimiz
   hatanın aynısı **10 levhada daha duruyor** (AI levhası, notta ara, hesap makinesi, ses
   yakalama, arkadaşlar, klasör sohbeti…). Bunlar her klavye karesinde baştan kuruluyor.
   Düzeltmesi bilinen kalıp; en yüksek getirili iş bu (§2.1).
2. **Akıllı listede olası hata buldum:** 1100 maddelik market sözlüğü akıllı listenin
   ayrıştırıcısına hiç girmiyor (`grocery: true` verilmemiş). Sesle "et domates ekmek"
   dediğinde ayrılmama/yazım düzeltmeme ihtimali yüksek. Testler yalnız virgüllü girdiyi
   deniyor (§3.1).
3. **"Hızlı ekle" cihazda hiç ölçülmedi** ve hız sözleşmesinin istediği bütçe
   senaryosu/ölçüm evresi yok (§1.3).
4. **Play'e bugünkü hâliyle çıkamayız; engel 6 tane ve hepsi çözülebilir:** GitHub'dan APK
   güncelleyici, Gmail izni (yıllık ücretli güvenlik denetimi ister), arka plan konum izni,
   sunucusuz AI kotası, App Check zorlanmıyor, gizlilik metni tutarsız (§4.2).
5. **Play hesabı:** kişisel hesap 25 $ tek sefer; ama yeni kişisel hesapta yayından önce
   **12 test kullanıcısı, kesintisiz 14 gün kapalı test** şartı var (§4.3).
6. **Vergi:** Türkiye'de gerçek kişiler için mobil uygulama kazanç istisnası var (GVK mük.
   20/B): bankada özel hesap, %15 kesinti, 2026 sınırı 5,3 milyon TL. Şirket kurmadan
   başlanabilir; mali müşavirle teyit et (§4.4).
7. **Firebase maliyeti korkulacak kalem değil:** kaba hesapla 1.000 aktif kullanıcı başına
   ayda **~5–15 $** (Firestore + depolama). 10.000 kullanıcıda ~50–150 $ (§6.1).
8. **Asıl maliyet ve risk yapay zekâda:** bugün ücretsiz AI Studio kotasıyla çalışıyoruz
   (proje geneli günde ~500 istek). Bu, onlarca kullanıcıda tükenir; ayrıca kota istemcide
   sayıldığı için değiştirilmiş bir istemci faturayı şişirebilir (§5.2).
9. **Önerim:** Play'de AI **olsun**, ama ücretsiz katmanda küçük ve ucuz (yalnız hafif
   model, günde ~10 puan), pahalı işler (video→not, podcast, PDF sohbet, seslendirme)
   aboneliğe; "kendi anahtarını gir" seçeneği sınırsız-ücretsiz yol olarak kalsın (§5.3).
10. **APK:** 60 MB'ın en büyük sökülebilir parçası ONNX çalışma zamanı (28,6 MB açık hâli).
    Play sürümünde çıkarılırsa ya da isteğe bağlı modüle alınırsa ~10 MB iner; yazı tipleri
    ~3 MB daha (§2.6).
11. **Neden satamayabiliriz:** ad jenerik ("Notlar" aranınca bulunmaz), özellik çok ama tek
    cümlelik vaat yok, tanınmayan geliştiriciye not emanet etme güveni, iOS yok (§7).
12. **Nasıl başarırız:** tek bir niş vaat ("Türkçe konuşarak not, liste, hatırlatıcı"),
    önce yalnız Türkiye, 3 ekranlık ilk kullanım, ölçüm (hangi özellik kullanılıyor), sonra
    genişleme (§7.3).

**Senden beklenen kararlar** raporun sonunda tek listede (§9).

---

## 1. Hızlı ekle

### 1.1 Bugün ne yapıyor [KOD]

"Hızlı ekle" yeni not açmıyor; **var olan bir nota metin/madde ekliyor** (`QuickDrop`).

- **Girişler:** ana ekranda mikrofonun solundaki ⚡ (`dashboard_widgets.dart:1581`), geniş
  ekranda ray (`app_frame.dart:874`), "+" menüsünde varsayılan gizli karo
  (`add_catalog.dart:82`). **Başka giriş yok:** başlatıcı kısayolu, ana ekran aracı,
  paylaşım hedefi, hızlı ayar karosu, `notlar://` bağlantısı yok.
- **Akış** (`quick_drop_sheet.dart`): levha açılır → hedef notlar bir kez hesaplanır (son
  kullanılan 6 hedef, sabitler, en son güncellenenler; kilitli/arşivli/sayfalı/başlıksız
  notlar dışarıda) → tek giriş çubuğu → hedef çipleri (ilk 12) → "Ekle".
- **Hedefi bulma** (`quick_drop.dart:176-300`): "ad: içerik", sonda hâl eki/komut
  ("…dosyalara ekle"), kök eşleştirme; berabere kalırsa sorar. Çözemezse yalnız
  **başlıkları** Gemini'ye yollar (en çok 40 başlık, 5 sn zaman aşımı).
- **Kaydetme:** yazı notunda sona ekler; listede tekrarları atlar, işaretliyse işareti
  kaldırır, miktarı günceller; yeni madde **sona** gider. Geri al var.
- Tarih/saat/hatırlatıcı/etiket ayrıştırması **yok**.

### 1.2 Bulduğum sorunlar

| # | Sorun | Tür | Kaynak |
|---|---|---|---|
| H1 | "süt bitti" deyince liste bitiyor ("bitti" bitirme sözcüğü) | hata | `KONTROL_LISTEM.md:19` |
| H2 | Geri al, `items`/`body` alanının **tamamını** eski hâline yazıyor; arada başka cihaz/ortak kişi düzenlediyse onun değişikliği silinebilir | hata riski [ÇIKARIM] | `quick_drop_sheet.dart:435-450` |
| H3 | Belge "1,6 sn geri sayım" diyor, kod 2 sn | belge tutarsızlığı | `editor.md:200` ↔ `quick_drop_sheet.dart:230` |
| H4 | Hedef adayları açılıştaki anlık görüntü; levha açıkken oluşan/yeniden adlanan not çıkmaz | küçük [ÇIKARIM] | `quick_drop_sheet.dart:236` |
| H5 | Market listesine eklenen madde reyon sırasına değil sona gidiyor | eksik | `quick_drop.dart:390` |
| H6 | Yalnız 12 hedef çipi, arama yok; 13. nota ulaşmanın yolu adını yazmak | kullanılabilirlik | `quick_drop_sheet.dart:615` |
| H7 | Başlıkta üç anahtar (AI'a sor / klavye aç / dinlemeye başla) her açılışta göz önünde | kalabalık | `quick_drop_sheet.dart:468-500` |
| H8 | Cihazda bakılmadı, ölçülmedi; AI yedeği cihazda denenmedi | doğrulama borcu | `KONTROL_LISTEM.md:22-26,65`, `PLAN.md:51` |

### 1.3 Akıcılık önerileri

1. **Bütçe senaryosu + ölçüm evresi ekle.** Hız sözleşmesi "dokunulan yüzeyin senaryosu
   `perf_budget_test`'te olmalı" diyor; hızlı ekle için yok. Önce bunu yaz: "⚡'ye bas →
   levha açık → klavye 6 kare → 3 harf yaz → Ekle" kurulum/yerleşim sayısı.
2. **Levha boyu her klavye karesinde değişiyor** [ÇIKARIM]. `SheetInsetPadding` alt payı
   her karede yeniliyor; çocuk `const` olduğu için ağaç baştan kurulmuyor ama yerleşim
   yenileniyor. Hızlı liste ekranında işe yarayan kalıbı (`KeyboardInsetScope` +
   `KeyboardSnap`: tek adımda otur) buraya da taşı; S49'da bu 438→341 kurulum, 168→99
   yerleşim kazandırmıştı.
3. **Klavye ve mikrofonu aynı anda açma.** Varsayılanlar hem "klavyeyi aç" hem "dinlemeye
   başla" (`quick_entry_memory.dart:159-167`). İkisi de platform kanalı çağrısı; motor
   belgemizde yazdığı gibi her kanal çağrısı kareyi bekletir (`akicilik.md:27-29`). Sırayla:
   levha animasyonu bitsin → **ya** klavye **ya** mikrofon. "Dinle" açıksa klavyeyi ilk
   dokunuşa bırak. (Bugün ikisinin aynı karede açılıp açılmadığını doğrulamadım.)
4. **Aday hesabını ilk kareden sonraya al** (not sayısı arttıkça `initState`'teki sıralama
   açılış karesini uzatır). Önce son 6 hedefi göster, kalanını bir kare sonra doldur.
5. **AI yedeğinde bekleme görünür olsun:** 5 sn'ye kadar sessiz bekleyiş "dondu" hissi
   verir; 300 ms'den sonra ince bir ilerleme çizgisi + "Vazgeç, ben seçeyim".

### 1.4 Geliştirme fikirleri (öncelik sırasıyla)

**A. Ulaşılabilirlik — hızlı eklemenin asıl değeri uygulamayı açmadan eklemek**

1. **Başlatıcı kısayolu** (simgeye uzun bas → "Hızlı ekle"). `app_shortcuts.xml`'de dört
   kısayol var, bu yok. En ucuz kazanç.
2. **Ana ekran aracı (1×1 ⚡ ve 4×1 "nota ekle…")**. Beş araç zaten var; altyapı hazır.
3. **Hızlı ayar karosu** (bildirim perdesinden ⚡).
4. **Paylaşım hedefi "Nota ekle":** başka uygulamadan paylaşılan metin bugün yeni not
   oluyor; ikinci seçenek olarak hedef seçtiren hızlı ekle levhası.
5. **Metin seçim menüsü ("Notlar'a ekle")**: Android `PROCESS_TEXT`.
6. `notlar://ekle?metin=…` bağlantısı (otomasyon uygulamaları, Gemini/AppFunctions).

**B. Akış**

7. **Hedef yokken "Yeni not olarak kaydet"** çipi. Bugün uygun not yoksa levha çıkmaz
   sokak.
8. **Çiplerin başına arama** ("@" ya da küçük büyüteç): 12 sınırı kalkar.
9. **Canlı önizleme satırı:** "→ Market listesi · süt, ekmek (2 madde)". Kullanıcı Ekle'ye
   basmadan neyin nereye gideceğini görür; yanlış hedef hatasını baştan keser.
10. **Reyona yerleştir** (H5): hedef market listesiyse yeni maddeyi akıllı listenin
    sıralamasıyla (`smartRank`) doğru reyonun sonuna koy.
11. **Tarih/hatırlatıcı:** "yarın 9'da dişçi" → hatırlatıcılı madde. Sesli komutta bu
    ayrıştırıcı zaten var; yeniden yazma, onu çağır.
12. **"bitti" çakışması (H1):** bitirme sözcüğünü yalnız **tek başına** söylendiğinde
    (öncesinde duraklama, cümlede başka sözcük yok) kabul et; ya da "tamam"/"kaydet" ekle.
13. **Geri al yalnız eklenenleri çıkarsın (H2):** eklenen maddelerin kimliklerini tut,
    geri alırken yalnız onları sil — ortak notta güvenli.
14. **Üç anahtarı ⚙ arkasına al (H7);** ilk açılışta bir kez sor, sonra hatırla.
15. **Hedef hafızası cihazlar arası** (bugün yalnız cihazda): `prefs_sync` ile taşınır.
16. **Çoklu hedef tek cümlede:** "süt markete, fatura yapılacaklara" — ayırıcı
    (`quickDropSeparate`) zaten var; her parçaya ayrı hedef çözümü.

**C. Güven**

17. AI yedeği başlık gönderiyor; levhada küçük bir "başlıklar yapay zekâya gider"
    açıklaması (Play gizlilik beyanı için de gerekir) ve çevrimdışıyken AI adımını atla.

---

## 2. Hız, akıcılık, pil, RAM, CPU, APK boyutu

### 2.1 Klavye açıkken menü/panel kasması — en somut bulgu [KOD]

S48 (şablon levhası 14124→396 kurulum) ve S52 (dört levha) kök nedeni şuydu: levha kendi
`build`'inde `MediaQuery.viewInsetsOf(context)` okuyor → klavye her kare kıpırdadığında
**bütün levha** baştan kuruluyor. Aynı kalıp şu 10 yerde hâlâ duruyor:

| Dosya | Ek yük |
|---|---|
| `ai_sheet.dart:575` | AI levhası |
| `note_search_sheet.dart:257` | **aynı build'de arama da yeniden hesaplanıyor** (`_textHits` + `_attachmentHits`) |
| `calculator_sheet.dart:106` | |
| `voice_capture_sheet.dart:795` | 18 `setState`'li büyük durum |
| `settings_ai.dart:528` | |
| `settings_appearance.dart:119` | dil listesi her build'de süzülüyor |
| `friends_screen.dart:610` | |
| `folder_chat_screen.dart:327` | |
| `note_link_ui.dart:69` | |
| `ai_result_sheet.dart:100` | |

Senin "klavye açıkken sürekli bir yerde, menüde, panelde kasma" tarifinle birebir örtüşen
tek kanıtlı kalıp bu. **Öneri:**

1. Onunu da `SheetInsetPadding` / `KeyboardInsetScope` kalıbına geçir (bilinen, denenmiş
   düzeltme; `test/levha_klavye_test.dart` bugün yalnız 4 levhayı koruyor → hepsini kapsa).
2. **Bekçi testi yaz:** `lib/` altında `viewInsetsOf(` çağrısı yalnız izinli yardımcı
   dosyalarda geçebilsin (izin listesi). Böylece yeni levha yazılırken hata geri gelemez.
   Bu, "her yeni levhada aynı hatayı yeniden bulma" döngüsünü kapatır.
3. Bunlar hata düzeltmesidir; dondurmaya takılmaz. Ölçüm kapısı geçerli (klavyeye dokunur).

### 2.2 Klavye 120 Hz, panel 60 Hz — açık sorun

`docs/perf/kullanici_video_2026-11-15.md`: senin telefonunda (Xiaomi, 120/144 Hz, Android
16) klavye karelerinin %14'ü 17,5 ms üstünde, en kötü 87–95 ms; hareket aralıklarının
~%40'ı 16–17 ms, yani uygulama 60 Hz'e düşüyor. Kip "k" (yerel `KlavyeOngoru.kt` tahmini)
cihazda doğrulanmadı; kapanışların %83'ünde zikzak görüldü.

**Önerilerim:**

1. **Takip etmekten vazgeç, tek adımda otur.** Klavyeyi kare kare izleyen her tasarım iki
   ayrı saatin (klavye penceresi ↔ Flutter) eşlenmesine bağlı; bunu dört kipte denedik,
   hâlâ açık. Sağlam yol: panel klavyenin **son** konumuna tek adımda yerleşsin (kısa bir
   solma ile), klavye onun üstüne/altına kendi hızında gelsin. Eşlenecek animasyon
   kalmayınca kasacak şey de kalmaz. `KeyboardSnap` bunu hızlı listede yapıyor; alt panel
   ve tüm levhalar için varsayılan olsun. (Görsel olarak "klavyeyle birlikte kayan panel"
   kadar şık değil, ama hiç takılmayan panel, bazen takılan şık panelden iyidir.)
2. **Sorunun Xiaomi'ye özgü olup olmadığını ayır.** HyperOS/MIUI bazı uygulamaları klavye
   açıkken 60 Hz'e sabitler [ÇIKARIM, yaygın bilinen davranış; bu cihazda doğrulanmadı].
   Aynı ölçümü bir Samsung ya da Pixel'de yapmadan daha fazla mühendislik harcamak
   kumardır. Komut: klavye açıkken `adb shell dumpsys display | grep -i refresh`.
3. **İkinci, ucuz bir test telefonu** (ikinci el orta sınıf Samsung). Tek telefon 52 °C'ye
   çıkıp ölçümleri geçersiz kılmıştı; ayrıca Play kullanıcılarının çoğu senin telefonundan
   yavaş cihaz kullanacak.

### 2.3 Menülerde kasma

- **Platform kanalı çağrıları kareyi bekletiyor** (`akicilik.md:27-29`). Yazarken çalışan
  bir tane buldum [KOD]: `WidgetService` her not/takvim/tema olayında 2 sn gecikmeyle 3
  kaydet + 2 güncelle çağrısı yapıyor (`widget_service.dart:41-66`). Otomatik kayıt da 2 sn
  → **yazarken ya da menü açarken araç güncellemesi araya girebilir** [ÇIKARIM]. Öneri:
  ana ekran araçlarını uygulama **arka plana giderken** (`paused`) güncelle; ön plandayken
  hiç çağırma. Kullanıcı aracı zaten uygulamadan çıkınca görür.
- **Açılış animasyonlarında `Opacity`:** `pop_in.dart:51`, `scale_settle.dart:103`,
  `customize_board.dart:215` alt ağacı tween'li `Opacity` ile solduruyor (9 kullanım).
  `FadeTransition` aynı işi alt ağacı yeniden kurmadan yapar. Ses kartında PopIn'in ağır
  kareye denk gelip yarım açılma yarattığını zaten gördük (rapor 2026-11-15).
- **`ActionMenu`** her bölümü `LayoutBuilder` + `Wrap` ile kuruyor. Sık açılan iki menü
  ("+" ve not ⋮) ilk kareden sonra boşta bir kez kurulup saklanabilir (ön ısıtma) —
  **ölçmeden yapma**; önce menü evresinin (altın taban: en kötü kare 40,9 ms) hangi
  parçasının pahalı olduğuna bak.
- **Levha + klavye iki animasyon üst üste:** son `[apk]`'da "+/⋮ levhası önce kurulur,
  klavye sonra iner" yapıldı; aynı sıralamayı bütün `showAppSheet` çağrılarına ortak
  yardımcıda ver (90 çağrı var), tek tek değil.

### 2.4 Not sayısı arttıkça yavaşlama (CPU) [KOD + ÇIKARIM]

- `akicilik.md:78`: 414 notta her Firestore olayı ~1,2 MB ve **21–27 ms Dart işi**. 120 Hz
  ekranda kare bütçesi 8,3 ms; yani yazarken her otomatik kayıt 2–3 kare düşürebilir.
- `notesStreamProvider` 26 yerde **bütün olarak** izleniyor; her kayıtta hepsi yeniden
  hesaplanıyor (`upload_queue.dart:204` tüm notları dolaşıyor, `due_state.dart:68`,
  `semantic_search.dart:49,90,144`, `notes_providers.dart` altı yerde…). Editördeki
  `select` (`note_editor_screen.dart:3616`) her olayda `backlinksTo` ile tüm notları
  tarıyor.
- **Öneriler:**
  1. **Kendi yazdığın kaydın yankısını ayır:** olay yalnız açık notun kendi kaydıysa
     (bekleyen yazma, tek belge değişti) türetilmiş sağlayıcıları tetikleme.
  2. Türetilmişleri **artımlı dizine** çevir (geri bağlantı dizini, bekleyen yükleme
     kümesi): değişen not girer/çıkar, tümü yeniden taranmaz.
  3. Editör açıkken liste türetmelerini 300–500 ms **birleştir** (liste zaten görünmüyor).
  4. Kalıcı çözüm PLAN (B)'deki **"kart dizini + gövde ayrı belge"** (F22.4). Play'de 2.000
     notlu kullanıcı çıkacak; o gün gelmeden yapılmalı. Veri göçü olduğu için yedek
     şartlı.
- **1.000 ve 3.000 notlu sentetik hesapla** ölç. Bugünkü bütün ölçümler ~400 notla.

### 2.5 Pil ve RAM

**Pil** [KOD]: ön plan servisi yok, WorkManager yok, wakelock yok — temel sağlam. Kalanlar:

- GitHub güncelleme yoklaması 30 dk'da bir (`app_update.dart:131`) → Play sürümünde tümden
  kalkmalı (zaten politika gereği, §4.2).
- `presence` 25 sn'de bir, `prefs_sync` 20 sn'de bir (ön planda). Presence yalnız
  **paylaşılan** not açıkken çalışmalı (bugün öyle mi, doğrulamadım); tek kişilik notta
  boşa yazma ve boşa radyo uyanması.
- Coğrafi çit (konum hatırlatıcı) süresiz ve 60 sn duyarlılıkta (`PlaceReminders.kt:133`):
  pil açısından makul, ama Play'de izin beyanı ister (§4.2).
- Kesin alarm yalnız 2 yerde; iyi.

**RAM:** hiç ölçülmemiş. Öneri: `adb shell dumpsys meminfo dev.kaimau.notlar` ile beş
durumda (boşta ana ekran, editör, PDF, kalem, YouTube) bir tablo çıkar, `docs/perf/`'e
taban olarak yaz. Şüpheliler: WebView (YouTube), pdfium sayfa önbelleği, 50 MB resim
önbelleği (`image_cache_budget.dart:13`), ONNX oturumu (kullanımdan sonra bırakılıyor mu?).

**Yazı tipi** [ÇIKARIM, doğrulanmadı]: yalnız Regular/Medium paketli; kodda 91 yerde
kalın (`w600+`) kullanılıyor ve `GoogleFonts.config.allowRuntimeFetching` hiç
ayarlanmamış (varsayılan açık). Yani kalın ağırlıklar **çalışma anında internetten
iniyor** olabilir: veri harcar, gelince yeniden yerleşim yapar, çevrimdışında sahte
kalın çizilir. Kontrol et; doğruysa ya kalınları pakete koy ya da **değişken yazı tipi**
(tek dosya tüm ağırlıklar) kullan ve çalışma anı indirmeyi kapat.

### 2.6 APK boyutu (bugün ~60 MB, arm64)

| Kalem | Boyut | Öneri | Tahmini kazanç |
|---|---|---|---|
| `libonnxruntime.so` (Antalia seslendirme) | 28,6 MB açık, ~11 MB sıkışık (`build.gradle.kts:108-114`) | Play sürümünde çıkar (sistem sesi + Gemini sesi kalır) **ya da** isteğe bağlı modül (Play Feature Delivery) | ~10–11 MB |
| Yazı tipleri (19 aile, 36 dosya) | 5,2 MB + 1 MB | 4–5 çekirdek aile pakette, kalanı seçilince insin; değişken yazı tipi | ~3–4 MB |
| Paketleme | `useLegacyPackaging = true` | Play için AAB + sıkıştırılmamış yerel kütüphane (Google'ın önerdiği; indirme Play'de zaten sıkışır, **kurulu boyut** küçülür) | kurulu boyutta ~25 MB |
| Dart kodu | `--obfuscate` yok | `--obfuscate` ekle (semboller zaten ayrılıyor); küçük boyut kazancı + tersine mühendisliği zorlaştırır | ~1–2 MB |
| Dil/yoğunluk kaynakları | tek APK | AAB'de Play cihaza göre böler | ~1–2 MB |

Gerçekçi hedef: Play indirme boyutu **~40–45 MB**. Önce `flutter build appbundle
--analyze-size` çıktısına bak; CI zaten dosya dosya boyut raporu basıyor
(`build.yml:432-441`), onu AAB için de çalıştır. Zaten iyi olanlar: arm64-only, R8 +
kaynak küçültme açık, ML Kit ve barkod Play Hizmetleri'nden (pakete girmiyor).

### 2.7 Ölçüm altyapısı için öneri

- **Uygulama içi kare sayacı** (yalnız profil/beta derlemesinde): `FrameTiming` ile ekran
  başına p50/p90/p99 ve "16 ms üstü kare %"sini topla, Ayarlar → Hakkında'da gizli bir
  "Hız günlüğü" sayfasında göster. Kablo, bilgisayar, soğuk telefon şartı gerekmeden
  **senin günlük kullanımından** gerçek veri gelir; "bugün şurada kastı" dediğinde bakacak
  sayı olur.
- Play'e çıkınca **Android Vitals** (yavaş kare, donma, ANR, pil) bedava gelir ve mağaza
  sıralamasını etkiler; kötü Vitals görünürlüğü düşürür.

### 2.8 Önerilen sıra

1. 10 levha + bekçi testi (§2.1) — düşük risk, kanıtlı kalıp.
2. Araç güncellemesini arka plana al (§2.3) — birkaç satır.
3. Hızlı ekle bütçe senaryosu + tek adımda oturma (§1.3).
4. Samsung/Pixel'de klavye ölçümü → 120/60 Hz sorununun kaynağını ayır (§2.2).
5. Yankı ayırma + artımlı dizinler (§2.4).
6. Play derlemesinde ONNX/yazı tipi/paketleme (§2.6).

---

## 3. Akıllı liste

### 3.1 Bugün ne yapıyor ve bulduğum hata [KOD]

Tek bir liste ekranı (`QuickListScreen`, `args.smart`); yazdıklarından türü kendi bulur:
**genel / alışveriş / bavul**. Yapay zekâ yok, her şey cihazdaki sözlükten: ~1100 maddelik
market sözlüğü (reyon sırası) + bavul sözlüğü (belge, giysi, bakım, sağlık, teknoloji).
Tür ya sözden ("bavul listesi", "market") ya da maddelerin çoğunluğundan çıkar. Sonuç
sıradan bir işaretli liste notudur; **tür ve reyon bilgisi nota kaydedilmez**, alt başlık
yoktur.

**Olası hata (oturumda koddan doğruladım, davranışı cihazda denemedim):**
`smartListArgs` (`note_template_sheet.dart:83-95`) `grocery: true` vermiyor.
`buildQuickLexicon(grocery: widget.args.grocery …)` (`quick_list_screen.dart:260-266`)
market sözlüğünü yalnız `grocery` doğruyken ekliyor (`quick_entry_memory.dart:193-206`).
Yani akıllı listenin **ayrıştırıcısında** 1100 maddelik sözlük yok; yalnız şablonun öneri
çipleri var. Hemen altındaki yorum ("Market önce eklendi…") tersini varsayıyor. Sıralama
ayrı sözlükten okunduğu için çalışıyor, o yüzden hata göze batmıyor.

- **Beklenen belirti:** boşlukla/sesle söylenen "et domates ekmek" tek madde kalabilir ya
  da çiplerde olmayan sözcüklerde yazım düzeltme çalışmaz.
- **Neden yakalanmadı:** `test/smart_list_test.dart:124,134` yalnız virgüllü girdi deniyor.
- **Öneri:** önce boşluklu girdiyle kırmızı test, sonra tek satırlık düzeltme. Hata
  düzeltmesi; dondurmaya takılmaz.

### 3.2 Diğer eksikler [KOD]

| # | Sorun | Yer |
|---|---|---|
| A1 | Sık kullanılanlar hafızası tek anahtar (`smart`): market ve bavul maddeleri karışıyor | `quick_list_screen.dart:238,443` |
| A2 | "Geçen seferden kalanlar" başlığa ("Liste") göre eşleşiyor; tür değişince yenilenmiyor | `:245-248` |
| A3 | Sıralama yalnız oluştururken; sonradan editörden/hızlı ekle ile gelen madde sıralanmıyor | tasarım |
| A4 | Tür ve grup kaydedilmediği için not açıldığında "akıllı" hiçbir şey kalmıyor | `:447-455` |
| A5 | Hafıza yalnız bu cihazda | `editor.md:193` |
| A6 | Çip başına `has()` her yenilemede tüm satırları tarıyor (küçük) | [ÇIKARIM] |
| A7 | Cihazda hiç bakılmadı | `KONTROL_LISTEM.md:24-26` |

### 3.3 Geliştirme planı — üç kademe

**Kademe 1 — oturtma (hata + küçük iş, 1 oturum)**

1. §3.1 hatası + boşluklu/sesli girdi testleri.
2. Hafıza anahtarını türe böl (`smart:market`, `smart:bavul`); kalanları türe göre eşle.
3. Çip `has()` için küme (Set) kullan.
4. Boş ekranda örnek ipucu: "süt, ekmek… ya da 'bavul listesi' de". "Akıllı liste" adı ne
   yaptığını söylemiyor; ilk açılışta tek cümle göster.

**Kademe 2 — liste notta da akıllı kalsın (veri modeline tek alan, 2–3 oturum)**

5. Nota `listKind` yaz (market/bavul/genel). Tek küçük alan; HAFIZA kural 5 gereği üç
   eşitlik işlevine de eklenir.
6. **Reyon başlıkları kaydedilmeden, çizilirken hesaplansın:** "Reyona göre grupla"
   görünümü; başlık nota yazılmaz (S6 kararıyla çelişmez), sözlükten türetilir. Editörde
   görünür yeni kip olduğu için `kasma-kontrol` + ölçüm kapısı şart.
7. Sonradan eklenen madde (editör, hızlı ekle H5, sesli komut) türü biliyorsa doğru reyona
   düşsün.
8. **"Alışverişi bitir":** işaretlileri kaldır/işareti sıfırla, sıklık hafızasını güncelle,
   kalanları "geçen seferden" olarak sakla.
9. **Miktar/birim:** "2 kg domates", "3 süt" ayrıştır; aynı madde tekrar gelirse miktarı
   topla (hızlı eklede bu mantık var: `planDropIntoList`).

**Kademe 3 — öğrenen liste (yeni özellik; karar senin)**

10. **Düzeltmeden öğren:** maddeyi başka reyona sürüklediğinde "kalem → kırtasiye" eşlemesi
    kişisel sözlüğe yazılsın, `prefs_sync` ile cihazlar arası gitsin.
11. **Bilinmeyen maddeyi AI ile bir kez sınıflandır, sonsuza dek hatırla:** sözlükte
    olmayan 5 maddeyi tek istekte hafif modele sor, sonucu cihazda sakla. Madde başına bir
    kez; maliyeti yok denecek kadar az. Çevrimdışıysa "diğer"e düşer.
12. **Yeni türler** (sözlük + öneri seti): yapılacaklar, tarif malzemesi, eczane, okul/
    kırtasiye, kamp, bebek çantası, taşınma, misafir hazırlığı. Tür bulunamazsa AI'a
    yalnız başlığı sor.
13. **Mağaza kipi:** büyük yazı, ekran açık kalır, tek elle, işaretlenen alta iner, reyon
    sırası o markete göre (marketini bir kez gezerek sırayı öğret).
14. **Ortak liste:** paylaşım zaten var; üstüne "Ayşe sütü aldı" anlık bildirimi (FCM ve
    Functions hazır).
15. **Tariften listeye:** tarif bağlantısı/fotoğrafı → malzeme listesi (AI; ücretli katman
    adayı).
16. **Sesli asistandan:** "listeye süt ekle" — AppFunctions servisi zaten var, Gemini'den
    çağrılabilir hâle getirmek küçük iş.
17. **Liste aracı:** ana ekranda market listesi, dokununca işaretle.
18. **Kendi şablonun:** "Bu listeyi şablon yap" (haftalık market, spor çantası).

**Bilinçli olarak önermediklerim:** fiyat takibi/market karşılaştırma (veri kaynağı ve
bakım yükü ağır), barkodla ürün veritabanı (lisanslı veri gerekir).

---

## 4. Google Play'e çıkış — sıfırdan yol haritası

> Depoda yürürlükteki karar **"Play'e çıkmıyoruz"** (`PLAN.md` (B)). Bu bölüm o kararı
> değiştirmez; karar verirsen izlenecek yolu anlatır.

### 4.1 Hazır olanlar [KOD]

- Paket adı `dev.kaimau.notlar`, imza anahtarı, R8/küçültme açık.
- **Genel (kişisel köprüsüz) AAB derlemesi CI'da hazır:** Actions → Derleme → Run workflow
  → `play` (F18.29); hiç çalıştırılmadı.
- Mağaza metni taslağı tr + en (`STORE_LISTING.md`), 512 px simge, veri güvenliği tablosu
  taslağı.
- Uygulama içinde **hesap ve veri silme** (`account_service.dart:95`).
- Crashlytics (kapatma anahtarıyla), reklam yok, analitik SDK yok.
- `premiumUntil` yalnız sunucudan yazılabiliyor; Premium ekranı var (satın alma yok).
- Güvenlik denetiminde açık yüksek bulgu yok (`docs/guvenlik_denetimi.md`).

### 4.2 Engeller — çıkmadan önce mutlaka

| # | Engel | Neden | Öneri |
|---|---|---|---|
| E1 | **GitHub'dan güncelleme denetimi** genel derlemede de çalışıyor: 30 dk'da bir yokluyor, kapatılamayan "Yeni sürüm var" bandı gösteriyor, GitHub sürüm sayfasına yolluyor (`app_update.dart:131,328-333,470`) | Play dışından güncelleme/kurulum yönlendirmesi Play politikasına aykırı; ret ya da kaldırılma sebebi [ÇIKARIM, yüksek güven] | Play derlemesinde `AppUpdateRunner` tümden derleme dışı; yerine Play'in uygulama içi güncelleme API'si |
| E2 | **`gmail.readonly`** izni canlı (`gmail_api.dart:17`) | Google'ın "kısıtlı" izin sınıfı: doğrulama + **her yıl ücretli bağımsız güvenlik denetimi (CASA)** ister [DIŞ] | Gmail'i Play sürümünden çıkar (kişisel derlemede kalsın). Getirisi maliyetini karşılamaz |
| E3 | **Arka plan konumu** (`ACCESS_BACKGROUND_LOCATION`, konum hatırlatıcı) | Play ayrı beyan + tanıtım videosu + uygulama içi açık bilgilendirme ister; en sık ret nedenlerinden | İlk sürümde konum hatırlatıcıyı çıkar; talep olursa sonra beyanla ekle |
| E4 | **AI kotası istemcide sayılıyor;** App Check **zorlanmıyor** | Değiştirilmiş istemci kotayı atlayıp faturayı şişirebilir (§5.2) | App Check'i zorla + Firebase AI Logic kullanıcı başı hız sınırı + sunucu sayacı (F18.28) |
| E5 | **Gizlilik metni tutarsız:** `PRIVACY_POLICY.md` yalnız Drive'dan söz ediyor; `web/gizlilik.html` Gmail/Takvim/Görevler'i de anlatıyor | Play ve OAuth incelemesi metinle uygulamayı karşılaştırır | Tek kaynak; herkese açık adres; AI'a giden veriyi açıkça yaz |
| E6 | **Web'den hesap silme adresi yok** [ÇIKARIM] | Play, uygulamayı kurmadan da silme talebi yapılabilecek bir web adresi ister | Basit bir form sayfası (Cloudflare Pages'te zaten web var) |
| E7 | **OAuth onay ekranı "Testing"te** | Yalnız test kullanıcıları Google'la girebiliyor | Yayına al; Takvim/Görevler "hassas" sınıf → Google doğrulaması (ücretsiz, haftalar sürebilir, tanıtım videosu + doğrulanmış alan adı ister) [DIŞ] |
| E8 | **Hedef API düzeyi** | 31 Ağustos 2026'dan beri yeni uygulamalar **Android 16 (API 36)** hedeflemeli [DIŞ] | Flutter 3.47.9'un `targetSdk` varsayılanını kontrol et; düşükse elle 36 |
| E9 | **16 KB bellek sayfası uyumu** [DIŞ, resmî sayfadan teyit edemedim] | Yerel kütüphaneler (onnxruntime, pdfium) uyumlu olmalı | AAB'yi Play Console'a yükleyince ön denetim uyarır; Android Studio APK Analyzer de gösterir |
| E10 | **Satın alma yok** | Para kazanılacaksa Play Billing zorunlu (dijital içerik) | F18.27: RevenueCat ya da `in_app_purchase` + doğrulama Function'ı |
| E11 | **AI içerik politikası** | Üretken AI içeren uygulamada kullanıcı uygunsuz çıktıyı **uygulama içinden bildirebilmeli** [DIŞ, genel politika bilgim] | AI yanıt baloncuğuna "Bildir" + "AI yanıtı hatalı olabilir" notu |
| E12 | Yedekler şifresiz (G-11) | Engel değil, güven konusu | Parolalı yedek seçeneği |

**Play sürümünde kalacak izinler ve beyanları:** bildirim, kesin alarm (hatırlatıcı
uygulaması olarak beyan edilir; izin reddedilirse yaklaşık alarma düşen yol hazır olmalı),
mikrofon, kamera, biyometri. Eklentilerin sessizce eklediği izinler olabilir: gerçek AAB'nin
birleşmiş manifestine bak.

### 4.3 Adım adım — hesaptan yayına

**Adım 0 — Kararlar (1 gün; §9'daki liste)**

**Adım 1 — Hesap ve yasal zemin (1–2 hafta, çoğu bekleme)**

1. **Hesap türünü seç** [DIŞ]:
   - **Kişisel:** 25 $ tek seferlik, kimlik doğrulaması (kimlik/pasaport + adres belgesi).
     Mağazada **adın ve ülken** görünür; uygulama para kazanıyorsa **açık adresin de**
     herkese görünür. **Yeni kişisel hesapta yayından önce en az 12 kişiyle kesintisiz 14
     gün kapalı test şartı var.**
   - **Kuruluş:** şirket + D-U-N-S numarası (almak 30 güne kadar sürebilir) gerekir; 12
     kişi şartı **yok**, mağazada şirket adı/adresi görünür.
   - **Önerim:** kişisel hesapla başla. 12 kişilik test zaten yapman gereken beta; ev
     adresinin görünmesi rahatsız ederse sanal ofis/iş adresi ya da ileride şahıs şirketi.
2. play.google.com/console → hesap aç → 25 $ öde → kimlik doğrula (birkaç gün).
3. **Ödeme profili (satıcı hesabı):** Play Console → Ödemeler → banka hesabı + vergi
   bilgisi. Ücretsiz uygulama yayınlamak için gerekmez; uygulama içi satış için gerekir.
4. **Vergi** (§4.4) — mali müşavirle bir görüşme.
5. **Marka/ad:** "Notlar" jenerik; mağazada bulunmaz, tescil edilemez. Ayırt edici bir ad
   seç, TÜRKPATENT ve Play'de ara. Paket adı (`dev.kaimau.notlar`) değişmek zorunda değil,
   kullanıcı görmez.
6. **Alan adı + iki sayfa:** gizlilik politikası ve hesap silme. OAuth doğrulaması da
   sahipliği doğrulanmış alan adı ister.

**Adım 2 — Kod: Play derlemesi (2–4 hafta; ayrı faz olarak planlanmalı)**

Sırayla: E1 güncelleyiciyi kapat → E2 Gmail'i çıkar → E3 konumu çıkar → E4 App Check +
sunucu kotası → E11 AI bildir düğmesi → E8/E9 hedef API + 16 KB → lisans sayfası (§4.5) →
E10 Billing → ilk kullanım akışı (3 ekran + AI onayı) → Antalia modelini kendi
sunucundan indir (§4.5) → APK boyutu (§2.6). Hepsi **derleme bayrağıyla** (`NOTLAR_KISISEL`
tersine): senin kişisel APK'n hiçbir şey kaybetmez.

**Adım 3 — Play Console girdisi (2–3 gün)**

1. Uygulama oluştur; varsayılan dil Türkçe; "Uygulama", "Ücretsiz" (**ücretsizden ücretliye
   sonradan dönülemez**, ama uygulama içi satış her zaman eklenir).
2. **Mağaza girdisi:** ad (≤30), kısa açıklama (≤80), uzun açıklama (≤4000) —
   `STORE_LISTING.md` hazır; simge 512 (hazır); **öne çıkan görsel 1024×500 (eksik)**; en
   az 2, tercihen 6–8 telefon ekran görüntüsü + tablet görüntüleri (**eksik**).
3. **Uygulama içeriği beyanları:** gizlilik politikası adresi · reklam yok · uygulama
   erişimi (inceleme ekibine bir **test hesabı** ver) · içerik derecelendirme anketi ·
   hedef kitle (13+ seç; çocuk kitlesi ağır kurallar getirir) · **veri güvenliği formu**
   (taslak `STORE_LISTING.md`'de; AI'a giden not içeriği, ses, görsel "toplanan/paylaşılan
   veri"dir) · hesap silme adresi · kesin alarm beyanı · finans/sağlık/haber "hayır".
4. **Play Uygulama İmzalama:** mevcut anahtar **yükleme anahtarı** olur; Google asıl imza
   anahtarını saklar. Anahtarı kaybetme riski böylece büyük ölçüde kalkar.

**Adım 4 — Test (en az 14 gün)**

1. **Dahili test** (100 kişiye kadar, inceleme yok): AAB'yi yükle, kendin kur.
2. **Kapalı test:** 12+ kişi, 14 gün kesintisiz. Kişi düşerse süre baştan başlayabilir →
   **15–20 kişi** al (aile, arkadaş, Türkçe geliştirici/teknoloji toplulukları).
   Testçilerin gerçekten kullanması gerekir; Google başvuruda "ne geri bildirim aldın, ne
   değiştirdin" diye sorar. Bu iki hafta aynı zamanda ilk gerçek kullanıcı araştırman.
3. Bu sırada: OAuth doğrulaması, Billing ürünleri + lisans testçileriyle gerçek satın
   alma, Android Vitals'e bakış.

**Adım 5 — Yayın**

1. Üretim erişimi başvurusu (sorulara somut yanıt; onay birkaç gün).
2. **Yalnız Türkiye** ile başla (§7.3): destek dili tek, vergi tek, GDPR yükü ertelenir.
3. **Kademeli dağıtım** %10 → %50 → %100; çökme oranına bak.
4. Uygulama içi değerlendirme isteği (ilk hafta değil; 5. kullanım gününden sonra).

**Gerçekçi takvim:** karar gününden yayına **8–10 hafta** (kod 2–4, test 2+, incelemeler
ve beklemeler 2–3). 14 günlük test ve OAuth doğrulaması sıkıştırılamaz; ikisini erkenden
başlat.

**Başlangıç maliyeti (kaba):** Play 25 $ · alan adı ~10–15 $/yıl · Firebase Blaze (zaten
açık olmalı: Functions ve Storage kullanıyoruz) · mali müşavir görüşmesi · isteğe bağlı
marka tescili. Gmail çıkarılırsa güvenlik denetimi ücreti yok.

### 4.4 Türkiye'de vergi [DIŞ — ikincil kaynaklar; mali müşavirle teyit et]

- **GVK mükerrer 20/B:** mobil uygulama geliştiriciliği kazancı için **gerçek kişilere**
  istisna. Vergi dairesinden istisna belgesi alınır, Türkiye'de bir bankada **bu işe özel
  hesap** açılır, tüm hasılat oraya gelir, banka **%15 kesinti** yapar ve bu nihai vergi
  olur; yıllık beyanname verilmez.
- **2026 sınırı 5.300.000 TL.** Aşılırsa istisna kalkar, kazancın tamamı beyan edilir.
- Şirketler (limited/anonim) yararlanamaz. Yani başlangıç için **şirket kurmamak** daha
  avantajlı olabilir.
- KDV ve SGK (Bağ-Kur) tarafını, başka işte çalışıyorsan etkisini müşavire sor.
- Google'ın payı: yıllık ilk 1 milyon $ gelirde %15 (bilgim; Play Console'dan teyit et).

### 4.5 Lisans ve telif — sorun var mı?

**Büyük bir telif engeli görmedim; kapatılması gereken küçük açıklar var.**

| Konu | Durum [KOD] | Yapılacak |
|---|---|---|
| Yazı tipleri (PT Sans + 19 Google ailesi) | OFL/Apache; lisans metinleri pakette **yok**, lisans sayfasına kayıtlı değil | OFL, metnin yazı tipiyle birlikte dağıtılmasını ister → `LicenseRegistry`'ye ekle (yarım günlük iş) |
| Antalia-2 Mini (seslendirme) | Apache-2.0, bildirimi uygulamada kayıtlı. Model ~50 MB, çalışma anında **üçüncü kişinin** HuggingFace deposundan iniyor (`fr0stb1rd/antalia-mini-web-onnx`) | Telif sorunu yok. **Tedarik riski var:** depo silinir/değişirse özellik bozulur ya da başka dosya iner → dosyaları kendi sunucuna koy + özet (hash) doğrula |
| Syncfusion PDF | Community lisansı | Ücretsiz ama **koşullu** (yıllık gelir/çalışan/geliştirici sayısı eşikleri; güncel şart sayfasından teyit et) ve lisansın **alınmış** olması gerekir. Hesabın yoksa aç, onayı sakla |
| Uygulama simgesi | Kaynak: senin verdiğin görsel (`tool/gen_icon.py:3-7`) | Görselin haklarının sende olduğundan emin ol (internetten alınmış ya da bir AI aracının ticari kullanım şartlarına tabi olabilir) |
| YouTube oynatıcı | Resmî gömme (iframe) + kendi kontrol çubuğumuz, **otomatik resim-içinde-resim**, zorla otomatik oynatma, kaynak adresi (`origin`) elle veriliyor (`youtube.dart:120-231`). Reklam engelleme/indirme yok | Gri alan [ÇIKARIM]: YouTube şartları arka planda/ekran dışı oynatmayı ve oynatıcıyı değiştirmeyi kısıtlar. Play sürümünde otomatik PiP'i kapat, standart kontrolleri kullan |
| Marka adları | Logo kullanılmıyor; giriş düğmesi genel simge | Mağaza metninde "Google Keep içe aktarma", "Gemini" yalnız tanımlayıcı olarak; simge/ekran görüntüsünde logo yok |
| Kopya kod | Üçüncü taraf lisans başlığı bulunmadı | — |
| Depo lisansı | `LICENSE` yok, depo özel | Kapalı kaynak için sorun değil |
| Sözlükler | Market/bavul elle yazılmış; telaffuz sözlüğü CMU (BSD-2) | BSD bildirimi lisans sayfasında olsun |
| Paket lisansları | `showLicensePage` var (`settings_account.dart:657`) | Flutter paketleri otomatik listeleniyor; yeterli |

**KVKK/GDPR (hukukçuya danış):** kullanıcı notları kişisel veri; AI kullanımı veriyi yurt
dışına aktarıyor. Gerekenler: aydınlatma metni, AI için ilk kullanımda **açık rıza**
ekranı, veri silme (var), VERBİS yükümlülüğünün doğup doğmadığının kontrolü. AB'de
yayınlarsan GDPR tam uygulanır — bir neden daha "önce yalnız Türkiye".

---

## 5. Yapay zekâ — Play'de olmalı mı, nasıl?

### 5.1 Bugün [KOD]

- **Dahili yol:** Firebase AI Logic → Gemini Developer API (`firebase_ai_client.dart:77`);
  model sırası `gemini-3.1-flash-lite` → `3.5-flash` → `2.5-flash`. Zincir **AI Studio
  ücretsiz kotasına** göre ayarlı (`ai_ses.md`).
- **Kendi anahtarın:** Gemini, OpenAI, Anthropic, OpenRouter; anahtar cihazın güvenli
  deposunda.
- **Kota:** ücretsiz 30 puan/gün, premium 300 (`constants.dart:135-140`); istemcide
  sayılıyor, `aiQuota/{uid}` kuralla korunuyor. Misafir dahili AI kullanamıyor.
- **~25 özellik:** özet, analiz, PDF sohbet, tüm notlarla sohbet, OCR, görsel soru, video→
  not, döküm, çeviri, podcast, seslendirme, brifing, başlık/etiket, yeniden yaz, beyin
  fırtınası, çalışma kartları, araçlı sesli asistan, e-posta→not…
- **Cihazda (bedava):** ML Kit OCR, barkod, belge tarama, cihaz konuşma tanıma, Antalia.
- Kilitli notlar AI'a gitmiyor — iyi, bunu mağazada söyle.

### 5.2 Play'e bugünkü hâliyle çıkarsa ne olur

1. **Ücretsiz kota proje genelidir.** Hafif model günde ~500 istek (bizim belgemiz). 50
   aktif kullanıcı bunu öğlene kadar bitirir; herkes "AI çalışmıyor" görür.
2. **Ücretsiz katmanda gönderilen içerik Google tarafından ürün geliştirmede
   kullanılabilir;** ücretli katmanda kullanılmaz [DIŞ]. Kullanıcı notlarını ücretsiz
   katmandan geçirmek gizlilik vaadimizle çelişir. Ayrıca bildiğim kadarıyla AB/İngiltere/
   İsviçre kullanıcılarına hizmette ücretli katman şart (şartlardan teyit et).
   → **Play'de ücretli katmana geçmek zorunlu.**
3. **Kota atlanabilir** [ÇIKARIM]: sayaç istemcide; App Check zorlanmadığı için uygulamayı
   taklit eden biri doğrudan Firebase AI Logic'i çağırabilir. Fatura bizde.

### 5.3 Önerim: Play'de olsun — "ucuz çekirdek + ücretli ağır işler + kendi anahtarın"

**Olsun, çünkü** mağaza adımız ve farkımız bu; AI'sız sürüm Keep'in kötü kopyası olur.
**Ama** maliyeti önce sınırla:

| Katman | İçerik | Model | Maliyet mantığı |
|---|---|---|---|
| **Cihazda (sınırsız, bedava)** | OCR, belge tarama, dikte, sistem sesiyle okuma, akıllı liste sözlüğü, hatırlatıcı ayrıştırma | yok | sıfır |
| **Ücretsiz bulut (günde ~10 puan)** | özet, başlık/etiket, yeniden yaz, kısa soru, sesli komut | yalnız hafif model | çağrı başı kuruşun altında |
| **Premium (abonelik)** | video→not, uzun ses dökümü, PDF sohbet, tüm notlarla sohbet, podcast, AI seslendirme, anlamsal arama, tariften liste | güçlü model | gelirle karşılanır |
| **Kendi anahtarın** | her şey, sınırsız | kullanıcının seçtiği | bize sıfır; güçlü kullanıcı için ayırt edici |

**Kaba maliyet** [ÇIKARIM; fiyatlar sık değişiyor, resmî sayfadan hesapla]: hafif modelde
tipik bir özet (~2.000 girdi + 500 çıktı belirteci) kuruşlar düzeyinde; kullanıcıların
%10'u günde 5 istek atsa 1.000 aktif kullanıcıda ayda ~15.000 istek ≈ **5–20 $**. Pahalı
olan ses/video/PDF: tek bir uzun video dökümü yüzlerce kısa özete bedel → bu yüzden
ücretli katmanda.

**Zorunlu korumalar (E4):**

1. App Check'i önce izle, sonra **zorla** (Play Integrity kurulu, yalnız zorlama kapalı).
2. Firebase AI Logic'in **kullanıcı başı hız sınırını** konsoldan düşür.
3. Günlük puanı **sunucuda** say (F18.28).
4. Google Cloud'da **bütçe uyarısı + sert tavan**, ve `config/app`'te **acil kapatma
   bayrağı** ("dahili AI geçici olarak kapalı; kendi anahtarınla sürdür").
5. Embedding (arama) şu an yalnız kendi anahtarla; öyle kalsın ya da premium olsun.

**Kullanıcıya dönük gerekenler:** ilk AI kullanımında onay ekranı (ne gider, kime gider,
kilitli notlar gitmez) · her yanıtta "Bildir" · "AI yanılabilir" notu · Ayarlar'da "AI'ı
tümden kapat".

### 5.4 Neler yapılabilir — fikirler

**Sadeleştirme (yeni özellikten önce):** 25 özellik çok; mağazada 4 kahraman özellik
anlatılır, gerisi menüde kaybolur. Kullanım ölçümü gelince az kullanılanı gizle.

**Kahraman adayları:**

1. **Konuş, gerisini o yapsın:** tek cümle → doğru türde not/madde/hatırlatıcı/takvim.
   Parçalar var (sesli komut, hızlı ekle, akıllı liste); tek giriş noktasında birleşmeli.
2. **Toplantı/ders kaydı → özet + yapılacaklar + hatırlatıcılar** (premium'un bayrağı).
3. **Fotoğraftan yapılı not:** tahta, fiş, kartvizit, el yazısı → başlık + maddeler.
4. **Notlarına sor** (kaynak gösteren sohbet) — var; öne çıkar.

**Ucuz ve akıllı:**

5. **Cihaz içi üretken model (Gemini Nano, ML Kit GenAI):** destekleyen telefonlarda özet/
   yeniden yazma/yazım denetimi cihazda, **sıfır maliyet, sıfır veri çıkışı**. Destek
   listesi dar ama büyüyor; "varsa cihazda, yoksa bulutta" katmanı uzun vadede hem maliyet
   hem gizlilik cevabı. Araştırmaya değer.
6. **Önbellek:** not değişmediyse aynı özeti yeniden üretme (içerik özetiyle anahtarla).
7. **Toplu, sessiz işler:** yeni notlara başlık/etiket önerisini tek istekte topla.

**Elde tutma:**

8. **Haftalık geri bakış** (var: haftalık özet) → pazar akşamı bildirimi.
9. **Akıllı gelen kutusu:** hızlı yakalanan dağınık notları klasör/etiket öner, tek
   dokunuşla onayla.
10. **Hatırlatıcı önerisi:** notta "cuma teslim" → "Hatırlatayım mı?" (cihazda, AI'sız).

---

## 6. Senkron ve Firebase maliyeti

### 6.1 Kaba hesap [KOD + ÇIKARIM + DIŞ]

**Veri modeli:** not başına bir Firestore belgesi; ağır içerik alt belgede. Ana dinleyici
**tüm notları sınırsız** dinliyor (`notes_repository.dart:298`). Otomatik kayıt 2 sn
(en geç 10 sn). Çevrimdışı önbellek 100 MB. Ekler: Firebase Storage (ücretsiz kullanıcıda
50 MB tavan, **istemcide sayılıyor**), Drive ya da yalnız cihaz.

**Ücretsiz günlük kota:** 50.000 okuma, 20.000 yazma, 1 GiB. **Liste fiyatı:** 100.000
okuma ~0,03–0,06 $, 100.000 yazma ~0,09–0,18 $ (bölgeye göre; `europe-west1` satırını
resmî sayfadan teyit edemedim — hesaplayıcıdan bak).

**Varsayım:** 1.000 aylık aktif, ~400 günlük aktif, kullanıcı başı 300 not, günde 3 soğuk
açılış (30 dk'dan eski oturumda dinleyici tüm notları yeniden okur [ÇIKARIM]), günde ~150
yazma.

| Kalem | 1.000 aktif | 10.000 aktif | 100.000 aktif |
|---|---|---|---|
| Okuma (~11 M/ay) | 3–7 $ | 35–70 $ | 350–700 $ |
| Yazma (~1,8 M/ay) | 2–3 $ | 16–32 $ | 160–320 $ |
| Firestore saklama | ~0 | ~2 $ | ~20 $ |
| Ek depolama (herkes 50 MB doldurursa; gerçekte çok altı) | ≤1,5 $ | ≤13 $ | ≤130 $ |
| İndirme trafiği, Functions, FCM | 1–3 $ | 10–30 $ | 100–300 $ |
| **Toplam (AI hariç)** | **~5–15 $** | **~50–150 $** | **~0,5–1,5 bin $** |

**Sonuç:** senkron maliyeti seni batırmaz. %2 kullanıcı ayda 50 TL ödese 10.000 aktifte
200 abone bunu fazlasıyla karşılar. **Batırabilecek üç şey:** (1) AI (§5), (2) kötüye
kullanım (depolama tavanı istemcide; biri 2 GB'ı doldurup tekrar tekrar indirtebilir),
(3) bir hata yüzünden sonsuz yazma döngüsü (takvimde "ping-pong" önlemi boşuna yazılmamış).

### 6.2 Ne yapmalı — Firebase'de kalarak

1. **Bütçe uyarısı + tavan** (ilk gün; 5 dakika). Firebase kendiliğinden durmaz.
2. **Depolama tavanını sunucuda uygula** (`storage.rules` + sayaç; F18.28).
3. **Ücretsiz kullanıcıda ekler varsayılan olarak kullanıcının kendi Drive'ına**
   (`drive.appdata` — altyapı hazır). Depolama ve trafik maliyeti **sıfıra** iner. Drive
   bağlamayan için küçük bir Firebase kotası (ör. 50 MB) kalır.
4. **Soğuk açılışta tüm notları yeniden okumayı kes:** yerel depo zaten var
   (`local_notes_store`); dinleyiciyi "son eşitlemeden beri değişenler"le sınırla
   (`updatedAt > sonEşitleme`). Okuma kalemini kabaca **onda birine** indirir, açılışı da
   hızlandırır (§2.4 ile aynı iş). Silinen notlar için mezar taşı gerekir; veri göçü
   sayılır, yedek şartlı.
5. **Yazmayı seyrelt:** yazarken 2 sn yerine 5–10 sn (yerelde anında kayıt sürer; yalnız
   buluta gidiş seyrekleşir), arka plana giderken kesin gönder. Yazma kalemini yarılar.
6. **Presence** yalnız paylaşılan notta; `prefs_sync` yalnız değişince.
7. **Sürüm geçmişi (30 sürüm)** ücretsizde 5'e insin; premium'da 30.
8. **Etkin olmayan hesap:** 12 ay girilmeyen ücretsiz hesabın ekleri (uyarı e-postasından
   sonra) soğuk depoya/silinmeye.

### 6.3 Başka çözümler

| Seçenek | Artı | Eksi | Görüşüm |
|---|---|---|---|
| **Firebase'de kal + 6.2** | sıfır göç, güvenlik kuralları ve testleri hazır, çevrimdışı hazır | kullandıkça öde; kilitlenme | **Önerim.** 100.000 aktife kadar yeter |
| **Ücretsiz = yalnız cihaz + kendi Drive'ına yedek; senkron = premium** | ücretsiz kullanıcı maliyeti ~0; premium'a güçlü neden | "bulutla eşitlenen" vaadi ücretsizde zayıflar; paylaşım ücretsizde çalışmaz; iki yol = iki kat hata | Maliyet gerçekten sorun olursa B planı |
| **Ücretsiz = Firestore'da yalnız metin, 2 cihaz sınırı** | basit, anlaşılır sınır | cihaz sayımı sunucuda gerek | Makul orta yol |
| **Supabase (Postgres + gerçek zamanlı)** | sabit aylık ücret, SQL, kendi sunucuna taşınabilir | kuralların/testlerin/çevrimdışı katmanın tümü yeniden yazılır; aylar sürer | Şimdi değil |
| **Kendi sunucun (PocketBase/Postgres, VPS)** | en ucuz birim maliyet | yedek, güvenlik, kesinti, 7/24 nöbet tek kişide | Önermem |
| **Cloudflare (D1/Durable Objects + R2)** | R2'de indirme trafiği ücretsiz; web zaten orada | senkronu sıfırdan yazmak | Yalnız **ekler için R2** ileride mantıklı |
| **Uçtan uca şifreli/CRDT senkron** | güçlü gizlilik vaadi | AI, arama, paylaşım, web hepsi zorlaşır | Ayrı ürün kararı |

**Özet:** altyapıyı değiştirme; **kullanımı ucuzlat** (6.2 madde 1–5) ve **geliri maliyete
bağla** (eşitleme/depoyu premium'un parçası yap).

---

## 7. Genel düşüncem — neden satarız, neden satamayız, nasıl başarırız

### 7.1 Neden satarız

1. **Türkçe önce.** Türkçe sesli komut ("her pazartesi 9'da toplantı"), Türkçe ek/kök
   eşleştirme, Türkçe market sözlüğü, cihazda Türkçe ses. Büyük rakipler Türkçeyi çeviri
   kalitesinde destekliyor; bu gerçek bir boşluk.
2. **Tek uygulamada not + liste + hatırlatıcı + takvim + kalem + PDF.** Türkiye'de insanlar
   bunun için 3–4 uygulama kullanıyor.
3. **Reklam yok + kendi anahtarını getir.** Teknik kullanıcı için güçlü, dürüst bir teklif.
4. **Hız disiplini.** Bütçe testleri, cihaz ölçümü, altın taban — tek kişilik projelerde
   neredeyse hiç görülmez. Android Vitals'te karşılığını alır.
5. **Web sürümü** var; "bilgisayarda da açılıyor" küçük ekipler için nadir.
6. **Güvenlik temeli sağlam:** kural testleri, denetim, hesap silme, kilitli notlar AI'a
   gitmiyor.

### 7.2 Neden satamayabiliriz (dürüst liste)

1. **Ad:** "Notlar" aranınca Samsung Notes, Google Keep, yüzlerce "not defteri" çıkar.
   Jenerik ad = sıfır kelime-arama görünürlüğü, sıfır ağızdan ağıza ("hangi notlar?").
   **En ucuz ve en önemli düzeltme.**
2. **Tek cümlelik vaat yok.** "Her şeyi yapan not uygulaması" kimseyi ikna etmez. Kullanıcı
   30 saniyede "bu benim için" demeli.
3. **Özellik genişliği yük.** 552 dosya, 205 bin satır, ~25 AI özelliği, kalem, PDF,
   takvim, sohbet, paylaşım… Tek kişi (+ AI) için destek ve hata yüzeyi çok geniş. Play'de
   bin farklı cihaz, bin farklı hata gelecek. `KONTROL_LISTEM.md`'de onlarca "yazıldı,
   cihazda doğrulanmadı" maddesi var — Play'e bu borçla çıkılmaz.
4. **Güven.** İnsanlar özel notlarını tanımadıkları tek kişilik bir geliştiriciye emanet
   etmekte isteksiz. Yedekler şifresiz (G-11), uçtan uca şifreleme yok.
5. **Rakipler bedava ve önceden kurulu.** Keep, Samsung Notes, OneNote, Notion. "Daha iyi"
   yetmez; "onların yapamadığı bir şey" gerekir.
6. **iOS yok.** Karışık cihazlı aile/ekip paylaşım özelliğini kullanamaz (web kısmen
   kurtarır).
7. **İlk kullanım.** Uygulama senin alışkanlıklarına göre şekillendi; yeni gelen ilk
   ekranda ne yapacağını bilmeyebilir. Bunu hiç test etmedik.
8. **60 MB**, yalnız arm64. Düşük depolamalı telefonlarda ilk silinen uygulama olur.
9. **Ölçüm yok.** Hangi özellik kullanılıyor, kim nerede bırakıyor — bilmiyoruz.
10. **Abonelik yorgunluğu.** Türkiye'de not uygulamasına aylık ödeme oranı düşük; %1–3
    dönüşüm iyimser sayılır [genel sektör gözlemi].

### 7.3 Nasıl başarırız

1. **Bir niş, bir vaat seç.** Önerim: **"Konuş, not olsun — Türkçe."** Sesle not, sesle
   alışveriş listesi, sesle hatırlatıcı. Elimizdeki en ayırt edici, en zor kopyalanan
   parça bu; hızlı ekle + akıllı liste + sesli komut zaten bu yöne gidiyor. Yedek nişler:
   öğrenci (PDF + kalem + çalışma kartları) ya da aile (ortak market listesi).
2. **Play sürümünü küçült.** Kahraman özellikler + sağlam çekirdek; Gmail, konum, harita
   köprüsü, YouTube PiP, sohbet gibi kenar özellikler ilk sürümde kapalı. Az özellik = az
   hata, az izin, küçük APK, kolay anlatım. Senin kişisel APK'nda hepsi kalır.
3. **Ad + simge + ilk 3 ekran görüntüsü.** Mağaza dönüşümünün neredeyse tamamı bunlar.
4. **İlk 60 saniye:** giriş → "bir şey söyle" → not oluştu → "bak, listeye çevirdim".
   Değer hesap açmadan görülmeli (misafir kipi var; iyi).
5. **Önce yalnız Türkiye, küçük başla.** 12–20 kişilik kapalı test → 100–200 kişilik açık
   beta → yayın. Her aşamada "en çok ne kullanıldı, nerede takıldılar".
6. **Ölç.** Rızayla, kişisel veri içermeyen birkaç olay: ilk not, ilk sesli not, ilk
   liste, 1./7./30. gün geri dönüş. Bunlar olmadan her karar tahmin.
7. **Fiyat fikri** (rakiplere bakıp sen ayarla): ücretsiz çekirdek · **Premium aylık/
   yıllık** (AI ağır işler + geniş depo + sürüm geçmişi) · AI içermeyen özellikler için
   **tek seferlik "ömür boyu"** seçeneği. AI'ı asla ömür boyu satma: maliyeti her ay
   yeniden doğar.
8. **Dağıtım** (reklam bütçesi olmadan): Türkçe teknoloji forumları ve toplulukları, kısa
   "konuşarak market listesi" videoları, Türkçe mağaza metni/anahtar sözcükler, kullanıcı
   yorumlarına hızlı ve kişisel yanıt.
9. **Güveni görünür kıl:** açık gizlilik sayfası, "notların reklam için kullanılmaz",
   parolalı yedek, kolay dışa aktarma (Markdown/zip — "istediğin an çık" güven verir).
10. **Beklentiyi doğru koy.** İlk yıl hedefi gelir değil **elde tutma** olsun: 30. günde
    hâlâ kullananların oranı. O sayı iyiyse gelir arkadan gelir; kötüyse reklam da
    kurtarmaz.

**Kısa hüküm:** ürün teknik olarak çoğu rakipten derin; eksik olan ürünleştirme (ad, vaat,
ilk kullanım, sadelik, ölçüm). Play'e "her şey" olarak değil "Türkçe konuşan not defteri"
olarak çıkarsa şansı gerçek; bugünkü genişliğiyle çıkarsa kalabalıkta kaybolur ve destek
yükü seni yorar.

---

## 8. Önerilen yol haritası (karar verirsen)

| Evre | Süre | İçerik |
|---|---|---|
| **0. Kararlar** | 1 gün | §9 |
| **1. Oturtma** (Play'den bağımsız, zaten gerekli) | 2–3 hafta | 10 levha + bekçi (§2.1) · akıllı liste hatası (§3.1) · hızlı ekle ölçüm + H1/H2 (§1) · araç güncellemesi arka plana (§2.3) · `KONTROL_LISTEM` cihaz turu |
| **2. Hesap ve yasal** (evre 1 ile paralel) | 1–2 hafta | Play hesabı, ad, alan adı, gizlilik + silme sayfası, mali müşavir, OAuth doğrulama başvurusu |
| **3. Play derlemesi** | 2–4 hafta | E1–E11, lisans sayfası, Billing, ilk kullanım akışı, APK küçültme, AI katmanları + korumalar, bütçe uyarıları |
| **4. Kapalı test** | 2–3 hafta | 15–20 kişi, 14 gün; geri bildirimle düzeltme; mağaza görselleri |
| **5. Yayın (TR)** | 1 hafta | kademeli dağıtım, Vitals ve çökme takibi |
| **6. Büyüme** | sürekli | ölçüme göre: akıllı liste kademe 2–3, cihaz içi AI, okuma maliyeti düşürme (§6.2-4), ikinci dil/ülke |

---

## 9. Senden beklenen kararlar (sabah bakılacak)

1. **Play'e çıkıyor muyuz?** ("çıkmıyoruz" kararı değişirse evre 2–5 başlar.)
2. **Hesap türü:** kişisel (12 kişilik test, adın görünür) mi, kuruluş mu?
3. **Uygulamanın adı.** (Aday üretmemi istersen ayrı tur.)
4. **Niş/vaat:** "Türkçe konuşarak not" mu, öğrenci mi, aile listesi mi?
5. **Play sürümünden çıkacaklar:** Gmail (önerim: çıkar), konum hatırlatıcı (çıkar),
   Antalia sesi (çıkar ya da isteğe bağlı indir), YouTube otomatik PiP (kapat),
   Takvim/Görevler (ilk sürümde kalsın mı — Google doğrulaması bekletir).
6. **AI:** ücretli katmana geçiş onayı; ücretsiz günlük puan (önerim ~10); hangi özellikler
   premium.
7. **Fiyat ve model:** abonelik + ömür boyu birlikte mi; Billing'i RevenueCat ile mi?
8. **Hızlı ekle ve akıllı listede hangi yeni özellikler** dondurmadan çıkarılsın? (Önerim:
   §1.4 madde 1, 7, 9, 10, 12, 13 ve §3.3 kademe 1 tamamı + kademe 2 madde 5–8.)
9. **Hata düzeltmeleri zincire girsin mi?** (§2.1 on levha + bekçi, §3.1 sözlük hatası,
   H1, H2, H3 — dondurmaya takılmaz, ama ölçüm kapısı gerektirenler var.)
10. **İkinci test telefonu** alınacak mı? (§2.2)

---

## Ek — bu rapor nasıl hazırlandı

- Kod üç ayrı salt-okuma incelemesiyle tarandı (hızlı ekle/akıllı liste; performans/APK;
  Play/lisans/AI/Firebase). Bulguların çoğunu **ben tek tek doğrulamadım**; şunları
  oturumda koddan kendim kontrol ettim: akıllı listede `grocery` bayrağının verilmediği,
  OAuth izin listesi, `allowRuntimeFetching`'in hiç ayarlanmadığı, AI puan sabitleri,
  `useLegacyPackaging` ve ONNX boyut notu.
- Hiçbir test koşulmadı, hiçbir şey cihazda ölçülmedi, hiçbir kod değişmedi.
- Dış kaynaklar (16 Kasım 2026):
  - Play kapalı test şartı: https://support.google.com/googleplay/android-developer/answer/14151465
  - Play hedef API düzeyi: https://support.google.com/googleplay/android-developer/answer/11926878
  - Firestore fiyatları: https://cloud.google.com/firestore/pricing
  - Gemini API fiyatları: https://ai.google.dev/gemini-api/docs/pricing (sayfa okunamadı;
    rakam vermedim, aralıklar ikincil kaynaklardan ve tutarsız — resmî sayfadan hesapla)
  - Kısıtlı izin doğrulaması: https://developers.google.com/identity/protocols/oauth2/production-readiness/restricted-scope-verification
  - GVK mük. 20/B 2026 sınırı (ikincil kaynaklar): https://www.alomaliye.com/2026/02/21/sosyal-icerik-ureticilerine-yapilan-odemelerden-gelir-vergisi-ve-kdv-uygulamasi/
