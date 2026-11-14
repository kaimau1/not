# OTURTMA PLANI — Faz 58–69 (sağlamlık · akıcılık · kalem · ekler · telefon/tablet)

**Tarih:** 2026-11-09 · **Taban commit:** `099eb689` (v1.2.36) · **Yazan:** Fable 5 incelemesi
(planlar + HAFIZA + kod okuması + ekran turu `build/tour/*.png`, 117 görüntü).

**Kullanıcı isteği (2026-11-09):** "Uzun süredir yoğun güncelliyoruz ama hâlâ performans
sorunları yaşıyoruz, eksikler var, tam oturmuyor. Detaylı plan çıkar, şimdiki planları da
kat; ben alt modellere (Opus) yaptıracağım. Basite kaçma, hata düzeltmekten yoruldum."

Bu dosya açık kalan HER işin tek sırasıdır. Eski plan dosyaları silinmedi; açık maddeleri
§2 envanterinde buradaki faza bağlandı. Çelişki olursa **bu dosya geçerlidir**.

> Satır numaraları `099eb689` içindir ve kayar. Bir yeri bulamazsan ADIYLA ara
> (`Grep`), satıra güvenme.

---

## Bu dosya nasıl kullanılır (protokol)

1. Kullanıcı **"Faz N'i yap"** ya da **"F61.3'ü yap"** der. Yalnız o faz/madde yapılır;
   kendiliğinden sonrakine geçilmez.
2. Her fazın başındaki **"Önce oku"** listesi dışında dosya okumak zorunda değilsin;
   `HAFIZA.md`'nin yalnız ilgili bölümünü oku (F58.2'den sonra konu dosyası).
3. Sıra her maddede aynı: **(a) kanıtı yeniden üret** (test ya da ölçüm, kırmızı görülür)
   → **(b) düzelt** → **(c) aynı test/ölçüm yeşil** → **(d) madde `[x]` + tek satır
   sonuç** → **(e) commit**. (a) üretilemiyorsa düzeltme YAZMA; maddeye "üretilemedi:
   <ne denendi>" yaz ve dur.
4. **KARAR** maddelerinde önce kullanıcıya sor. Zamanlanmış/gözetimsiz oturumda maddede
   yazan **"En güvenli"** seçenek uygulanır ve maddeye "sabah bakılacak" yazılır.
5. Doğrulama CLAUDE.md'deki gibi: değişenin testi + `dart analyze <dosyalar>` → push → CI
   yeşil → main'e birleştir. Editör/klavye/çubuk/liste/geçişe dokunan iş `[apk]`'dan önce
   cihazda A/B (`tool/perf/ab_klavye.py`; kalem için F59.5'ten sonra `ab_kalem.py`).
6. **Bu plan sürerken yeni özellik eklenmez** (K-O1). Kullanıcı yeni istek verirse
   `ISTEK_KUTUSU.md`'ye tek satır yazılır, plan bitince ele alınır. İstisna: kullanıcı
   "şimdi yap" derse yapılır.
7. Faz bitince: Durum tablosu, HAFIZA (kök neden/tuzak varsa), sürüm notu (kullanıcıya
   görünen değişiklik varsa), commit/push.
8. **Faz/paket sonu regresyon turu** (kullanıcı 2026-11-09: "fazların sonunda önceki
   tespit edilen sorunları deneyerek en az ölçümle bulalım"). `docs/regresyon_listesi.md`:
   düzeltilen HER sorun tek satır — belirti · 1 dakikalık denetim (test adı ya da
   adb/ölçüm komutu) · beklenen. Her faz/paket bitiminde liste baştan koşulur: otomatik
   olanlar test, cihaz isteyenler EN AZ ölçümle (tek `ab_klavye.py` koşusu + 30 gir-çık
   evresi; kalem işi varsa `ab_kalem.py`). Kırmızı çıkan şey fazı kapatmaz. Dosya yoksa
   ilk düzeltmeyi yapan oluşturur.

**Hangi fazı hangi model yapsın**

Kullanıcı kararı (2026-11-09): güvenlik, performans, editör ve kalem **Fable**'da.

| Model | İşler |
|---|---|
| **Fable** (en güçlü; küçük commit, adım kırmızıysa sonrakine geçme) | Faz 59 (performans denetimi + bütçe testleri), F60.1, F60.S2 (klavye birikim kasması), Faz 61–63 (kalem; F60.S4 dahil), Faz 64 (editör), Faz 68 (liste yükü), Faz 71 (güvenlik) |
| **Opus** | F60.2, F60.3, F60.5, F60.S1, F60.S3, Faz 65 (ekler; F65.8, F65.9), Faz 66 (telefon; F66.7), Faz 67 (tablet; F67.9), Faz 70 (yazım düzeltici v2) |
| **Sonnet** (mekanik, kuralı açık işler) | F58.2 (HAFIZA'yı cümle değiştirmeden bölme), F58.3, F58.5, F60.4, F60.6, F66.4, F67.2, `docs/cihaz_turu.md`, `docs/regresyon_listesi.md` bakımı, sürüm notları, F69.4–F69.5 |

Gözetimsiz yürütmenin sırası ve kuralları: `OTOMASYON.md`.

---

## Durum

| Faz | Konu | Durum | Tarih | Not |
|---|---|---|---|---|
| 58 | Fren ve zemin (süreç, hafıza, doğrulama borcu) | Bekliyor | | kod yok |
| 59 | Otomatik akıcılık kapısı (cihazsız bütçe testleri) | Bitti (`ab_kalem.py` cihazda koşturulmadı) | 2026-11-11 | 16 senaryo CI'da; bütçe = bugünkü ölçüm |
| 60 | Bilinen hatalar + kullanıcı sorun kutusu | Bekliyor | | F60.1 en yüksek getiri |
| 61 | Mürekkep deposu v2 (1 MiB tavanı, kayıt maliyeti) | Bekliyor | | veri biçimi; yedek şartı |
| 62 | Mürekkep çizimi v2 (gecikme, dolu sayfada kasma) | Bekliyor | | |
| 63 | Kalem akışları (her yüzeyde tek kural) | Sürüyor | 2026-11-11 | F63.1–F63.5 yapıldı (P05, P15; K-O5 açık); F63.6 karar, F63.7 cihaz turu bekliyor |
| 64 | Editör çekirdeği (dar dinleme) | Sürüyor (P20 adım 1–10 bitti, 2026-11-14) | S3/S4 satır 23→1, S1 kök 1→0, S9 tuval 2→0, S14 tuval 1→0 | cihaz A/B bekliyor; F64.3/F64.4 kısmi (M2, M6) |
| 65 | Ekler: yerleşim, çubuklar, yükleme güvenilirliği | Bekliyor | | KALEM_PLANI K6–K7 burada |
| 66 | Telefon: ana ekran ve not ekranı yoğunluğu | Bekliyor | | |
| 67 | Tablet ve geniş ekran | Bekliyor | | |
| 68 | Liste ve senkron yükü | Sürüyor (F68.1 bitti, F68.2 kısmen — 2026-11-12) | | AKICILIK F22.4 burada |
| 69 | Doğrulama turu ve kapanış | Bekliyor | | |
| 70 | Yazım düzeltici v2 (baştan) | Bekliyor | | Opus |
| 71 | Güvenlik denetimi ve altyapısı | Bitti (cihazda/yayında doğrulanmadı; KARAR: yedek şifresi) | 2026-11-11 | rapor `docs/guvenlik_denetimi.md`; 9 bulgu düzeltildi, açık kritik/yüksek yok |

**Önerilen sıra:** 58 → 59 → 60 → 61 → 62 → 63 → 65 → 66 → 67 → 68 → 64 → 69.
Faz 64 bilerek sonda: en riskli iş, getirisi Faz 59 ölçümüyle kanıtlanmadan başlanmaz.
Faz 60.1 tek başına hemen yapılabilir (kalemle eke yazarken kasmanın kökü).

---

## 0. Değerlendirme

### Doğru yapılanlar (koru)

- **Ürün konumu sağlam:** Android + web senkronu, ücretsiz, AI, el yazısı ve PDF aynı notta.
  Rakiplerde üçü birlikte yok (YORUM_ANALIZI §3).
- **Ölç-sonra-düzelt kültürü var:** `tool/perf/` (22 betik), A/B kapısı, kök neden notları.
  AKICILIK Faz 21/24 gerçek kazanç getirdi (uzun notta LAYOUT p90 122 → 12 ms).
- **Veri güvenliği düşünülmüş:** ileri uyum (`extras`), tam yedek, sürüm geçmişi, kural
  testleri, yazım reddi yutulmuyor.
- **Test tabanı geniş:** 340 test dosyası / 46 bin satır; bekçi testleri (sözlük, simge,
  terim, kontrast) tutarlılığı koruyor.
- **Görsel dil oturmuş:** "masa ve kâğıt" teması, kart = açık not kuralı, tek simge sözlüğü.

### Yanlış gidenler (bu planın gerekçesi)

1. **Hız doğrulamayı geçti.** 3 günde 10 oturum (A–J), oturum başına 10–18 görünür
   değişiklik. `KALANLAR.md` §2'de ~110 madde "yazıldı, cihazda doğrulanmadı". Her yeni
   özellik eskisinin üstüne doğrulanmadan biniyor; hata bulunduğunda hangi oturumdan
   geldiği belli değil. "Hata düzeltmekten yoruldum" bunun sonucu.
2. **Akıcılık kırılgan bir sözleşmeye bağlı.** Editör tek `State` (~126 alan, 14 `part`
   dosyası, 5159 satırlık ana dosyada binlerce satırlık `build`). "Yeniden kurma" kararı elle tutulan üç karşılaştırma
   (`_sameVisual`, `sameRenderedNote`, `sameItemsVisually`) + elle anahtarlanan satır
   önbelleğiyle veriliyor. CLAUDE.md'deki 7 maddelik "kasma kontrol listesi" bu
   sözleşmenin kendisi: unutulan bir alan ya bayat ekran ya da tam kurulum demek. Kodda
   **257 "KÖK NEDEN" yorumu** var; aynı sınıf hata tekrar tekrar düzeltilmiş.
3. **Regresyon kapısı elle ve cihazda.** CI'daki kare ölçümü sentetik (x86 emülatör, kısa
   not). Gerçek kapı telefonda A/B; her oturumda koşulmuyor. 2026-11-08'de eklenen
   "yazarken çubuk gizlenir" yazmayı ×3,3 yavaşlattı ve iki gün sonra fark edildi.
4. **Kalem yolu ölçeklenmiyor (bu incelemenin en önemli bulgusu, §1 B1–B4).** Mürekkep
   Firestore'a `double` dizisi olarak, notun TÜM mürekkebi tek belgede yazılıyor; her
   kayıt hepsini ana iş parçacığında yeniden kodluyor; her kalem hareketi sayfanın TÜM
   çizgilerini yeniden boyuyor. Sayfa doldukça yavaşlar ve yaklaşık bir-iki ekran yoğun
   el yazısında 1 MiB belge sınırına dayanır.
5. **Kapsam çok geniş.** Not, liste, kalem, PDF, video, sunum, Gmail, takvim, görev, rutin,
   kişiler, AI sohbet, kart, OCR, yazım öğrenme, 20+ tema, 1100 satırlık ayar sağlayıcı
   dosyası. Her biri
   editöre/ana ekrana yüzey ekliyor. Çekirdek akışlar (aşağıda) kusursuz olmadan yeni
   yüzey açmak "tam oturmuyor" hissini büyütüyor.
6. **Araç çubuğu kalabalığı.** Sabit ekli notta telefonda 3 çubuk / ~21 düğme, tablette
   ~25; çoğu yalnız simge (tur: `telefon-e-pdf-sabit.png`, `tablet-yatay-e-pdf-sabit.png`).
7. **Hafıza dosyası kendi kuralını çiğniyor.** `HAFIZA.md` 109 KB (hedef ≤ 30 KB, ~57 bin
   token). Her oturum bunu okuyarak başlıyor; alt modeller kuralı gürültüde kaçırır.

### Çekirdek akışlar (öncelik bunlarda; yeni iş bunlara hizmet etmiyorsa bekler)

1. Hızlı not / liste yaz, sonra bul. 2. Kalemle yaz (sayfaya ve PDF/görsele).
3. Ek ekle, oku, üstüne not al. 4. Telefon ↔ tablet ↔ web senkronu (ekler dahil).
5. Hatırlatıcı zamanında çalar. 6. Hiçbir koşulda veri kaybolmaz.

---

## 1. Kanıtlı bulgular

Hepsi koddan doğrulandı; "hesap" yazanlar ölçülmedi, ilgili fazın 0. maddesi ölçer.

| # | Bulgu | Kanıt | Etki | Faz |
|---|---|---|---|---|
| **B1** | Mürekkep `double` dizisi olarak saklanıyor: nokta başına 16 bayt (x,y), kalemde basınçla 24 bayt | `attachment.dart` `InkStroke.toMap` (`'d'`, `'q'`); `firestore_size.dart` sayı = 8 bayt | Nokta eleme 0,002 sayfa genişliği (`ink_layer.dart` `pointerMove`, ~1,5 dp). Harf başına 40–80 nokta. **Hesap:** bir ekran yoğun el yazısı ≈ 30–40 bin nokta ≈ 0,7–1 MB | 61 |
| **B2** | Notun TÜM mürekkebi (sayfa + bütün ekler) tek belgede: `notes/{id}/heavy/data`; sınır 1 MiB, 900 KB'ta uyarı | `note_heavy.dart`; `notes_repository.dart` `docWarnBytes` | B1 ile birlikte: 1–2 ekran el yazısında kayıt reddi. Kalem kullanıcısı için veri kaybı riski | 61 |
| **B3** | Her kayıt bütün mürekkebi birkaç kez gezer ve platform kanalından kodlar: `note.toMap()` → `heavyBytesOf` → `splitAttachmentMaps` → `sameFirestoreValue` ×2 → `copyFirestoreValue` → `batch.set(heavy)`; ardından ağır belge dinleyicisi aynı veriyi geri yollar, `Note.fromMap` + `InkController.replace` (`_sameStrokes`) yeniden gezer | `notes_repository.dart` `updateNote` (680–766), `_hydratedDoc` (401); `ink_layer.dart` `replace` (862) | Flutter 3.47'de Dart UI = Android ana iş parçacığı (AKICILIK K4): yazarken her 2–10 sn'de mürekkep boyuyla doğrusal takılma | 61 |
| **B4** | Her kalem hareketi sayfanın TÜM çizgilerini yeniden boyar: `ListenableBuilder(controller)` her `notifyListeners`'ta yeni `InkPainter` kurar (kurucuda sayfa süzgeci = liste tahsisi), `paint` hepsini çizer; basınçlı çizgi nokta başına ayrı `drawLine`, saydam basınçlı çizgi çizgi başına `saveLayer` | `ink_layer.dart` `InkPageLayer.build` (1742), `InkPainter` (2580–2689) | Sayfa doldukça kalem gecikmesi büyür. Impeller'da resim önbelleği yok (doğrula: F62.0) | 62 |
| **B5** | Sabit/gömülü eke her çizgi **editörün tamamını kurar ve anında tam kayıt atar**: bölme `onChanged: _updateAttachment` → `_mutate(immediate: true)`; yeni `attachments` listesi → `_sameVisual` içindeki `identical(a.attachments, b.attachments)` false → `setState` | `note_editor_media_view.dart:1066`, `note_editor_screen.dart:2166`, `:3954`, `note_editor_embed.dart:263`; `note_editor_attachments.dart` `_updateAttachment` (1070); `note_editor_screen.dart` `_sameVisual` (1762) | PDF'e kalemle yazarken saniyede 3–5 kez tam editör kurulumu + B3 | 60.1 |
| **B6** | Yeniden kurma kararı "yasak liste": yeni görünür alan üç karşılaştırmaya + satır önbelleği anahtarına elle eklenmeli | `sameItemsVisually` (263), `sameRenderedNote` (320), `_sameVisual` (1762), `items_editor.dart` `_cachedItemRow` (1949), `_syncRowCache` (1982) | Tekrarlayan "editör baştan kuruluyor" ve "değişiklik çıkıp girince görünüyor" hataları | 59, 64 |
| **B7** | Paket aç/kapa üye satırlarını sıfırdan kurar/söker (kapalı: `SizedBox.shrink` / hap; açık: `TapRegion` → `DecoratedBox` → satır); paketle/çöz `_rowCache.clear()` ile TÜM satırları yeniden kurar (anahtar zaten `item.package` içeriyor, temizlik gereksiz); açık paketin `TapRegion` grubunda yalnız paket satırları var | `items_editor.dart` `_packagedRow` (1774–1824), `togglePackage` (1710–1743), `_cachedItemRow` (1949) | **Hipotez (testle doğrula):** paket içindeyken araç çubuğuna dokunmak `onTapOutside` ile paketi kapatır, odaklı alan sökülür (klavye oynar, satırlar yeniden kurulur). "Paketli notta kasma" (KALANLAR I1) için ilk şüpheli | 60.2 |
| **B8** | Bölünmüş görünümde (tablet yatay) liste görünürken her otomatik kayıt panoyu yeniden kurar | `dashboard_screen.dart` `build` 1119–2181 (53 `ref.watch`, tek gövde); HAFIZA 2026-11-10 "200 notluk ızgarayı yeniden hesaplama, 31–47 ms" | Tablette yazarken/çizerken düzenli takılma | 68.1 |
| **B9** | Telefonda ana ekranın tepesi SABİT yığın: arama + takvim şeridi + zamanı gelen + davet + süzgeç + bekleyen yükleme + klasör şeridi; hiçbiri kaydırınca çekilmiyor | `dashboard_screen.dart` 1636–1678 (hepsi `Column` içinde, ızgara `Expanded`); tur `telefon-ana.png`: ilk nota kadar ~210 dp (ekranın %23'ü) | İçeriğe ayrılan alan az | 66.1 |
| **B10** | Telefonda klavye kapalıyken kalem düğmesi yok (alt çubuk: Biçim · Ekle · Ara · Paylaş · Seç ‖ AI · Ses · Mikrofon) | tur `telefon-n1.png`; KALEM_PLANI K5 | Telefonda elle yazma keşfedilemiyor | 63.5 |
| **B11** | Kesme noktaları dağınık: 600 (5 yer), 520 (5), 340 (6), 400, 430, 640, 760, 840, 900, 920, 960… adlı sabit yalnız 3 tane | `split_shell.dart` 23/31/50; `grep "(width\|shortestSide) *(>=\|<)"` | Aynı pencere bir yerde "tablet", başka yerde "telefon" sayılıyor | 67.1 |
| **B12** | Ekran turu gerçek cihaz boyutlarını çekmiyor: tur 412×915, 800×1280, 1280×800, 1440×900; gerçek tablet (MatePad 11) **1024×640 dp** yatay / 640×1024 dikey | `tool/tour/screen_tour_test.dart:311`; HAFIZA "MatePad 11 = … yatay 1024×640 dp" | Tablette görülen taşma/sıkışma turda görünmüyor | 67.2 |
| **B13** | Yükleme kuyruğu yalnız uygulama açıkken çalışır (süreç içi `Timer` + bağlantı olayı) | `upload_queue.dart` (`_scheduleRetry`, `Connectivity`) | Ek ekleyip uygulamayı kapatan kullanıcıda ek başka cihaza gitmez | 65.4 |
| **B14** | `HAFIZA.md` 109 KB, hedefinin 3,6 katı | `wc -c HAFIZA.md` | Oturum başı ~57 bin token; kural kaçırma | 58.2 |
| **B15** | Bölünmüş görünümde liste bölmesi 320 dp'de telefon başlığının aynısını taşır; "+" ve mikrofon düğmeleri son kartın üstünde | tur `tablet-yatay-n1.png` (800 dp yükseklikte 2,5 kart görünüyor) | Tablet listesi verimsiz | 67.3 |

---

## 2. Açık iş envanteri (eski planlar → bu plan)

| Kaynak | Madde | Yeni yeri |
|---|---|---|
| KALEM_PLANI K2 | Sabit görsele kalemle yazma | F63.3 |
| KALEM_PLANI K3 | Tam ekran görüntüleyicide kalem düğmesi | F63.4 |
| KALEM_PLANI K4 | Tek kalem tepsisi, tek etkin yüzey | F63.2 |
| KALEM_PLANI K5 | Telefonda elle yazma | F63.5 |
| KALEM_PLANI K6 | Eklerin yerleşimi (tasarım) | F65.1–F65.3 |
| KALEM_PLANI K7 | Web'de ek görünmüyor / paylaşılan notta ek senkronu | F65.6 |
| YORUM F54.1 | Kalem gecikmesini ölç | F62.0, F62.6 |
| YORUM F54.3 | Göç öncesi otomatik yerel yedek | F61.6 |
| YORUM F54.4 | Yeni cihaza geçiş denemesi | F69.2 |
| YORUM F55.1 | Parmağa araç ata | F63.6 (KARAR) |
| YORUM F55.4 | Dolma kalem | F62.5 |
| YORUM F55.5 | Kalem kapsülü cihaz turu | F63.7 |
| YORUM F56.2 | Hatırlatıcı güvenilirliği | F69.3 |
| YORUM F57.1/2 | Taşınan düğme ipucu / sürüm notu | F57.2 yapıldı (sürüm notları sayfası); F57.1 park |
| AKICILIK F22.4 | Senkron yükü not sayısından bağımsız | F68.3 (yeniden ölç, KARAR) |
| AKICILIK Faz 21 | Kaydırma kabulü (%3,4–4,2; hedef < %1) | F68.4 |
| AKICILIK F27.3 | Vulkan'lı cihaz | park (cihaz yok) |
| KALAN_ISLER F18.20 | PPTX düzenleme portu | park |
| KALAN_ISLER F18.27/28, F19.D | Play Billing, sunucu kotası, mağaza | park ("Play'e çıkmıyoruz") |
| KALAN_ISLER F19.A/B | Konsol işleri (kullanıcı) | F69.4 listesi |
| KALAN_ISLER F19.C | Cihaz turları | F58.3, F69.1 |
| TAKVIM | Saat ızgarasında sürükleme, görev sürükle-sırala | park (K-O1 dondurma) |
| KALANLAR "Yarım kalan" | Düz metin satırında hatırlatıcı çipi; şekil önerisi madde katmanında; görev levhasında kişi | park (dondurma) |
| KALANLAR I1 | Paket kasması | F60.2 |
| KALANLAR "Açık hata" | "📖 s.11" satırı silinemiyor | F60.3 |
| KALANLAR "Açık ölçüm" | Yazma ana bloğu 148 → 229 ms | F60.5 |
| KALANLAR §3 | Web geri tuşu tam ekran; `RenderFollowerLayer` uyarısı | park (bilinçli) |
| HAFIZA açık soru | Misafir "Senkronize" yazısı | F60.4 |
| HAFIZA | MIUI beyaz açılış | F60.7 (KARAR) |
| HAFIZA | `CardSeeThrough` ölü kod vb. | F58.5 |
| TEMA F32.6 | ΔE 0,08 K5 paletinde tutmuyor | park (kullanıcı kararı bekliyor) |

---

## 3. Kararlar

Önerilen **kalın**. "En güvenli" = gözetimsiz oturumda uygulanacak olan.

> **2026-11-12 — KARAR VERİLDİ (kullanıcı tasarım kararlarını Fable'a bıraktı):** K-O5,
> K-O10, K-O11 ve K-O14 `DENEYIM_PLANI.md` §3'te karara bağlandı (K-D6, K-D4, K-D5, K-D8)
> ve oradaki fazlarda uygulanır; bu dosyada o kararlara bağlı maddeler (F60.7, F63.5,
> F66.1–F66.3) ile F66.4, F66.6, F67.7 oraya taşındı (DENEYIM Ek D.2) — burada YAPILMAZ.
> **K-O6 / F65.1 BİTTİ (2026-11-13, P49)** — çubuktaki düğmeler tek tek kullanıcı isteğiydi (DENEYIM §4 Y10); dar çubuk + tek ⋮ levhası.
> **Faz 72–80: `DENEYIM_PLANI.md`.**

- **K-O1 — Özellik dondurma:** **Bu plan bitene dek yeni özellik yok; istekler
  `ISTEK_KUTUSU.md`'ye** / dondurma yok. En güvenli: dondur.
- **K-O2 — Mürekkep v2 kapsamı (F61):** **sıkı kodlama + bantlı belgeler + artımlı kayıt**
  / yalnız sıkı kodlama (tek belge kalır; tavan ~6× uzar, kayıt yine hepsini yazar).
  En güvenli: F61.1–F61.3 (kodlayıcı, planlayıcı, okuma) yazılır, YAZMA bayrağı kapalı kalır.
- **K-O3 — Eski istemci:** v2 mürekkebi eski sürüm GÖREMEZ (silemez de). **Bütün cihazlar
  güncellenince `config/app.minClient` = 4** / çift yazım (v1 + v2 birlikte; 1 MiB tavanı
  kalkmaz). En güvenli: v2 yazımı yalnız kullanıcı "cihazlarım güncel" deyince açılır.
- **K-O4 — Uç tahmini (F62.6):** kalemin 1 kare ilerisini çizip sonra düzelten tahmin.
  **Cihazda A/B, kullanıcı hissine göre** / hiç. En güvenli: kapalı bayrakla yazılır.
- **K-O5 — Telefon alt çubuğu (F63.5):** **Paylaş ⋮ menüsüne iner, yerine Kalem gelir**
  / Ses dalgası ⋮'e iner / kalem yalnız hızlı satırda kalır. En güvenli: dokunma.
  *(2026-11-11, P15 gözetimsiz: "dokunma" uygulandı, karar AÇIK — sabah bakılacak.)*
- **K-O6 — Ek çubuğu sadeleşmesi (F65.1):** **telefonda bölme çubuğu en çok 5 düğme:
  ⛶ · tutamak · birincil iş (Not al / T) · ✏ · ⋮; görünüm anahtarı (Sabit · Yüzen · Ek),
  balon, bağlantı ⋮ levhasının başında** / bugünkü. En güvenli: dokunma.
- **K-O7 — KARAR (kullanıcı, 2026-11-13): tablette ve webde sabit ek YANDA olabilir** (geniş ekranda yan yerleşim seçilebilir/varsayılan yan; telefonda üstte). Eski metin:
  **Yatay geniş ekranda sabit ek:** **≥ 840 dp ve yatayken yeni sabit ek
  kendiliğinden YANDA açılır (kullanıcı değiştirirse hatırlanır)** / hep üstte. En güvenli:
  dokunma.
- **K-O8 — Birden çok sabit ek:** **bölme çubuğunda sekme** / yan yana / tek sabit ek.
  En güvenli: tek sabit ek (bugünkü).
- **K-O9 — Arka planda ek yükleme (F65.4):** **yeni bağımlılık yok: bekleyen ek varken
  uygulama arka plana geçerse 15 dk sonra "N ek yüklenmeyi bekliyor" bildirimi** /
  `workmanager` ile arka plan yüklemesi (Drive jetonu başsız yalıtımda sorunlu).
  En güvenli: bildirim.
- **K-O10 — Telefon ana ekran tepesi (F66.1):** **dar ekranda takvim şeridi kapalı başlar
  (tek ince satır)** / şeritler ızgarayla birlikte kayar (klasör kaydırma geçişini bozma
  riski, 2026-11-07 kök nedeni) / bugünkü. En güvenli: bugünkü.
- **K-O11 — Kartta işaretli maddeler (F66.3):** **işaretsiz madde varken işaretliler tek
  satır "✓ N tamamlandı"** / bugünkü. En güvenli: bugünkü.
- **K-O12 — İki not yan yana (F67.6):** **şimdilik yok (dondurma)** / tablet yatayda
  ikinci not bölmesi. En güvenli: yok.
- **K-O13 — Liste yükü (F68.3):** ölçüm sonucuna göre: **gerçek hesapta kayıt sonrası ana
  blok ≤ 12 ms ise hiçbir şey yapma** / > 12 ms ise "yakın/eski" iki sorgu bölmesi (göçsüz)
  / kart dizini göçü (AKICILIK F22.4-B). En güvenli: hiçbir şey yapma.
- **K-O14 — MIUI beyaz açılış (F60.7):** **`androidx.core:core-splashscreen` ile ilk Flutter
  karesine dek açılış ekranını tut (yerel bağımlılık)** / bırak. En güvenli: bırak.


**KARARLAR (kullanıcı, 2026-11-12) — P22 sormadan uygular. Genel ilke: uygulamayı yalnız
kullanıcı kullanıyor, Play'de yayında değil → HİÇBİR özellik "kapalı bayrakla" bekletilmez;
yazılan özellik varsayılan AÇIK gelir ve sürüm notuna girer (bayrak yalnız Ayarlar'da
kapatma seçeneği olarak kalabilir).**
- **K-O1:** İstek/yeni özellik dursun (`ISTEK_KUTUSU.md`), AMA düzeltme ve bug fix'ler yapılır.
- **K-O2:** Ölçümsüz açma YOK → v2 YAZMA kodlanır; F61.0 (b)(c) cihaz ölçümü yapılınca açılır
  (veri güvenliği kapısı; ölçüm sonrası varsayılan AÇIK).
- **K-O3:** Doğrudan v2'ye geçilir: yazma açılınca `config/app.minClient` = 4 (çift yazım yok).
- **K-O4:** Uç tahmini yazılır (bayrak yalnız A/B içindir; kullanıcı denedikten sonra açık).
- **K-O6:** Sadeleştir — telefonda bölme çubuğu en çok 5 düğme (⛶ · tutamak · birincil iş ·
  ✏ · ⋮); görünüm anahtarı, balon, bağlantı ⋮ levhasının başına. Düğmeler ⋮ içinde KALIR, silinmez.
- **K-O7:** Yatay ve ≥ 840 dp'de yeni sabit ek YANDA açılır; kullanıcı üste alabilir, hatırlanır.
- **K-O8:** Tek sabit ek (bugünkü).
- **K-O12:** Tablet yatayda iki not yan yana OLSUN (ikinci not bölmesi; F67.6 yapılır).
- **F63.6:** Parmağa ayrı araç YAZILIR ve release'e (`[apk]`) girer; kapalı bırakılmaz.
---

## FAZ 58 — Fren ve zemin (kod yok)

**Önce oku:** `CLAUDE.md`, `HAFIZA.md` (son kez tamamı), `KALANLAR.md`.

- [ ] **F58.1 Dondurma kuralı (K-O1).** `CLAUDE.md`'ye "Yol haritası" bölümünün başına bu
  dosyanın işaretçisi ve "OTURTMA sürerken yeni özellik yok; istekler `ISTEK_KUTUSU.md`"
  satırı. `ISTEK_KUTUSU.md` oluştur (başlık + boş liste). Kullanıcı onayı şart.
- [x] **F58.2 HAFIZA ≤ 30 KB.** *(2026-11-10: HAFIZA.md 5 KB; eski hâl HAFIZA_ARSIV_3.md bayt aynı; 10 konu dosyası docs/hafiza/ — anahtar sözcükle girdi başına dağıtıldı, satır kaybı 0; bekçi test/hafiza_size_test.dart; CLAUDE.md güncel. "Her oturumda geçerli kurallar" 30 madde elle yazıldı — sabah gözden geçir, dağılım isabeti de.)* (a) `HAFIZA.md`'nin bugünkü hâlini `HAFIZA_ARSIV_3.md`
  olarak AYNEN kopyala (dondurulmuş). (b) `docs/hafiza/` altında konu dosyaları; bölümler
  CÜMLE DEĞİŞTİRMEDEN taşınır: `ortam_ci.md` (Ortam, CI, Test tuzakları, Android),
  `veri.md` (Veri modeli, Yedek, Ek senkronu), `akicilik.md` (Riverpod/performans + kasma
  regresyonu), `editor.md` (Editör, klavye, metin + tarihli oturum notlarının editör
  maddeleri), `kalem.md` (kalem, şekil, avuç, sabit PDF), `ekler_pdf.md` (PDF, balon,
  görüntüleyici, ek modeli), `arayuz.md` (Arayüz kararları, tema, ana ekran), `web.md`,
  `takvim_gmail.md`, `ai_ses.md`. Tarihli "Oturum X" başlıkları parçalanıp konusuna gider.
  (c) Yeni `HAFIZA.md`: Ortam (10 satır) + **"Her oturumda geçerli kurallar"** (en çok 40
  madde, her biri tek satır; CLAUDE.md kasma listesiyle çakışanı yazma) + konu dizini
  tablosu ("şuna dokunacaksan şunu oku"). (d) Bekçi: `test/hafiza_size_test.dart`:
  `File('HAFIZA.md').lengthSync() <= 30 * 1024`. (e) CLAUDE.md "Hafıza" bölümünü güncelle.
  Kabul: `wc -c HAFIZA.md` ≤ 30720; `HAFIZA_ARSIV_3.md` eski dosyayla bayt bayt aynı.
- [x] **F58.3 Doğrulama borcunu çalıştırılabilir yap.** *(2026-11-11: `docs/cihaz_turu.md` telefon 40 / tablet 27 / web 20 adım, `docs/test_borcu.md` (O), KALANLAR §2 başına işaret; eski liste arşiv olarak kaldı, X listesi cihaz_turu bölüm E.)* `KALANLAR.md` §2'deki her maddeyi
  üç kovaya ayır: **(O) otomatikleşir** → karşılığında widget/akış testi var mı bak; yoksa
  test adını `docs/test_borcu.md`'ye yaz (bu fazda test YAZILMAZ); **(E) elle** (kalem,
  avuç, mikrofon, bildirim, ikinci hesap) → `docs/cihaz_turu.md`'ye risk sırasıyla, cihaz
  başına (telefon / tablet / web) en çok 40 adım, her adım "yap → beklenen" biçiminde;
  **(X) eskimiş** (özelliği kalkmış/yeniden yazılmış) → sil. `KALANLAR.md` §2 yerine
  `docs/cihaz_turu.md`'ye işaret kalır. Kural: tura yeni adım girerse doğrulanmış bir adım
  çıkar (40 tavanı).
- [ ] **F58.4 Oturum disiplini (CLAUDE.md'ye 4 satır).** Bir oturum = bir faz/konu; `[apk]`
  başına en çok 5 kullanıcıya görünür değişiklik; her `[apk]`'dan önce Faz 59 bütçe testleri
  yeşil; "yazıldı, cihazda doğrulanmadı" maddesi 40'ı geçerse yeni iş durur, tur yapılır.
- [x] **F58.5 Ölü kod süpürmesi.** *(2026-11-10: pickReminderWhen + CardSeeThrough (+ kendi testi) silindi, ayrı commitler, analyze temiz. text_window.dart KALDI: windowed_body.dart kullanıyor. Balonlu yalnız-yazma yolları: aranmadı/silinmedi — şüpheli, sabah bakılacak.)* Adayları `Grep` ile doğrula, başvuru yoksa sil:
  `CardSeeThrough` (HAFIZA: "hiçbir yerde açılmıyor"), `pickReminderWhen` ("artık
  kullanılmıyor"), `text_window.dart` ("bağlı değil" — `windowed_body.dart` kullanıyorsa
  kalır), balonlu görünümden kalan yalnız-yazma yolları (salt okunur ortak notun çizimi
  KALIR). Her silme ayrı commit; `dart analyze lib test` temiz.
- Kabul: HAFIZA ≤ 30 KB; `docs/cihaz_turu.md` ≤ 120 adım; CLAUDE.md güncel.

---

## FAZ 59 — Otomatik akıcılık kapısı (cihazsız, CI'da)

Amaç: CLAUDE.md'deki elle kontrol listesini **kırmızıya dönen teste** çevirmek. Sayılan şey
süre değil **sayı** (kurulum, çizim çağrısı, yazılan bayt): makineden bağımsız, titremez.

**Önce oku:** `test/note_screen_chrome_test.dart` (tam editörü kuran `_pump` ve
`debugOnRebuildDirtyWidget` kalıbı), `test/keyboard_jank_guard_test.dart`,
`test/items_editor_row_cache_test.dart`, `test/editor_pen_tablet_test.dart`.

- [x] **F59.1 Ortak düzenek.** *(2026-11-09: `pumpEditor`/`endEditor`/`BuildCounter`/
  `CountingNotesRepository` (`updateNoteCalls`, `bytesWritten`, `lastSaved`); kabuk testi ona
  taşındı, 8 test yeşil.)* `test/support/editor_harness.dart`: `note_screen_chrome_test`
  içindeki `_pump` ve sahte depo kurulumunu buraya TAŞI (kopyalama; eski test bunu
  kullansın). Ek olarak:

  ```dart
  /// Sahne boyunca widget türü başına yeniden kurulum sayar.
  class BuildCounter {
    final counts = <String, int>{};
    void start() {
      counts.clear();
      debugOnRebuildDirtyWidget = (e, _) {
        final name = e.widget.runtimeType.toString();
        counts[name] = (counts[name] ?? 0) + 1;
      };
    }
    void stop() => debugOnRebuildDirtyWidget = null;
    int of(String type) => counts[type] ?? 0;
  }
  ```

  Depo yazımlarını saymak için sahte depoya `int updateNoteCalls` ve `int bytesWritten`
  (`estimateValueBytes` ile) sayaçları.
- [x] **F59.2 Bütçe testi.** *(2026-11-09: dosyalar kuruldu, YALNIZ S6/S7 yazıldı — F60.1'in
  kanıtı. 2026-11-11 (P11): S1–S5, S8, S9, S11–S14 eklendi; S10 `note_package_open_test`'te.
  Bütçe = bugünkü ölçüm (`bugun`/`hedef`/`neden` alanları), sayılar Ek A'da. Bozma denemesi:
  `_sameVisual` başına `false &&` → S1, S2, S5, S6, S7 kırmızı (geri alındı). Bulgu: S8 30
  maddeli notta İLK klavye açılışında `ItemsEditor` her inset karesinde kuruluyor (Ek A).)* `test/perf_budget_test.dart` + `test/perf_budget/budgets.json`.
  Ek A'daki S1–S16 senaryolarının her biri bir `testWidgets`; ölçülen sayı
  `budgets.json`'daki değerle `lessThanOrEqualTo` karşılaştırılır. İlk koşuda bugünkü sayı
  ölçülüp dosyaya **"bugün"** olarak yazılır; Ek A'daki **"hedef"** sütunu ilgili faz
  bitince dosyaya işlenir. **Mandal kuralı:** bütçe yalnız DÜŞER. Yükseltmek için commit
  başlığında `[butce]` + `budgets.json`'da `"neden"` alanı (bekçi: `git diff` yerine
  dosyada her girdinin `"neden"`i boş olamaz kuralı yeter).
  Dikkat: test yüzeyi 800×600 = TABLET sayılır (HAFIZA); telefon senaryoları
  `tester.view.physicalSize = Size(400, 800)`, `devicePixelRatio = 1`.
- [x] **F59.3 Boyayıcı sayacı (S15).** *(2026-11-11: 2001 çağrı — O(N) doğrulandı.)* `flutter_test`'in `TestRecordingCanvas`'ı ile
  `InkPainter(...).paint(canvas, size)` çağır, `canvas.invocations.length` say: 2000
  çizgili sayfada etkin çizgiye 1 nokta eklenince yapılan çizim çağrısı. Bugün O(N)
  (beklenen ≥ 2000) → hedef ≤ 8 (Faz 62).
- [x] **F59.4 Kayıt sayacı (S16).** *(2026-11-11: 2 belge (not + `heavy/data`), 448 925 bayt
  — bir çizgi için bütün mürekkep yeniden yazılıyor.)* `fake_cloud_firestore` ile `NotesRepository.updateNote`:
  2000 çizgili nota 1 çizgi ekle, yazılan belge sayısı ve toplam bayt. Bugün ≈ bütün
  mürekkep → hedef: 1 bant belgesi, ≤ 64 KB (Faz 61).
- [x] **F59.5 Cihaz A/B'ye kalem senaryosu.** *(2026-11-11: araç yazıldı, **cihazda
  koşturulmadı** (işçi telefona dokunmaz). `python -u ab_kalem.py <etiket> <kart_x> <kart_y>
  <kalem_x> <kalem_y>`; dolu sayfa `ab_kalem.py hazirla 1500 …` ile cihazda üretilir, çünkü
  **yedek/not paketi sayfa el yazısını (`Note.pageInk`) TAŞIMIYOR** (`encodeNoteJson`'da alan
  yok — ayrı bulgu, sabah bakılacak: tam yedekten dönen notta sayfa çizimi kaybolur).
  `make_dataset.py --ink 1500` → `olcum_kalem.notyedek`: boş not + 1500 çizgili sabit PDF
  (uygulamanın `decodeNoteJson`'ıyla doğrulandı).)* `tool/perf/ab_kalem.py` (`ab_klavye.py`'nin
  iskeletinden): telefon düzeni, kalem kipi açık (parmak çizer), `input touchscreen swipe`
  ile 30 çizgi; iki veri hâli: boş sayfa ve 1500 çizgili sayfa (`make_dataset.py`'ye
  `--ink 1500` seçeneği: sentetik el yazısı benzeri çizgiler). Çıktı: evre başına UI ms,
  raster ms, > 16,7 ms kare sayısı; ayrıca kayıt anındaki en uzun ana blok. Kapı: bir
  evrede UI ya da raster %20 artarsa birleştirme yok (ÖLÇÜM KAPISI ile aynı kural).
- [x] **F59.6 CLAUDE.md kasma listesine tek satır** *(2026-11-11, madde 8)*: "Bu listeyi unutma diye değil:
  `test/perf_budget_test.dart` kırmızıysa birleştirme yok."
- Kabul: 16 senaryo CI'da koşuyor; bilerek bozulan bir örnek (ör. `_sameVisual`'dan bir
  alanı çıkar) testi kırmızıya çeviriyor (dene, geri al).

---

## FAZ 60 — Bilinen hatalar + kullanıcı sorun kutusu

**Önce oku:** her maddenin kendi dosyaları. Faz 59 düzeneği şart (F60.1, F60.2 onunla
doğrulanır).

- [x] **F60.1 Eke çizgi = saf değişiklik (B5).** *(2026-11-09: S6/S7 kök kurulum 10 → 1,
  `updateNote` 10 → 1 (`perf_budget_test`). **Cihaz A/B (2026-11-10, Mi Note 10 Lite, `ab_klavye.py`, taban 099eb689, 2. koşular):**
  yazma 1037 → 1025 ms (LAYOUT 308 → 310), klavye aç 301 → 290, kapa 173 → 189 ms —
  regresyon yok (not kapanışı iki sürümde de 27/67 kare arasında oynuyor: gürültü).
  **PDF'e çizimin kendisi cihazda ölçülmedi** (`ab_kalem.py` F59.5'te gelecek).
  Plandan sapma: `_sameVisual` ek karşılaştırması genel değil, YALNIZ mürekkep yolundan
  (`_mutate(inkOnly:)`) gevşer — yoksa geri al / tam ekrandan dönen mürekkep kökü kurmaz,
  bölme bayat kalırdı. Ek tuzak bulundu ve kapatıldı: bayat kutudan gelen sayfa çevirme
  eski çizgi listesini geri yazıyordu (`_withLiveInk`); gömülü belgeye `_docInkSeen`.
  Not paketi çizgi başına bildirmiyor (yalnız kapanışta `onSave`) — dokunulmadı. Önizleme
  levhası (`note_editor_embed.dart` `showEmbedPreview`) eski yolda kaldı.)*
  *Kanıt:* S6/S7 bugün çizgi başına 1 kök kurulum + 1 `updateNote`.
  *Düzeltme:* (1) `note_editor_attachments.dart`'a `_updateAttachmentInk(Attachment)`:
  `_updateAttachment` ile aynı dönüşüm ama `immediate` YOK (debounce'lu). (2) Mürekkep
  bildiren üç yer buna bağlanır: sabit bölme (`pinned_media_pane.dart` `_inkFor` →
  `widget.onChanged`; bölmeye ayrı `onInkChanged` parametresi ekle, yoksa `onChanged`'e
  düşsün), gömülü belge (`note_images.dart` `_docInkFor`), not paketi önizlemesi
  (`note_package.dart`). (3) `_sameVisual`'da `identical(a.attachments, b.attachments)`
  yerine `_sameAttachmentsVisually(a.attachments, b.attachments)`: özdeşse true; boy
  farklıysa false; eleman eleman `identical` ya da "mürekkep dışında aynı"
  (`sameFirestoreValue(x.copyWith(ink: const []).toMap(), y.copyWith(ink: const []).toMap())`).
  *Tuzak:* bölme kendi `InkController`'ından boyar; kök kurulmayınca `widget.media.ink`
  bayat kalır ama `_inkSeen` kimlik denetimi (`pinned_media_pane.dart` 336) bunu zaten
  yutar — testte "çiz → başka nedenle kök kurul → çizgi sayısı aynı" adımı olsun.
  Kart önizlemesi/dışa aktarma `_note`'tan okur (güncel).
  *Kabul:* S6/S7 kök kurulum 0 (ilk çizgide geri al düğmesi için 1 serbest), `updateNote`
  10 çizgide ≤ 1; `test/ink_editing_guard_test.dart` yeşil; cihazda `ab_kalem.py` PDF evresi.
- [x] **F60.2 Not paketi: kapanma ve ağaç şekli (B7).**
  *(2026-11-10: S10 `test/note_package_open_test.dart` kırmızı (Biçim'e dokununca paket
  kapanıyordu) → yeşil. (a) tek sabit `kNotePackageTapGroup` (`note_package.dart`); alt
  çubuk, hızlı satır, biçim paneli, kalem tepsisi koşulsuz `TapRegion` ile gruba girdi;
  dışarı (başka madde) dokunuş yine kapatır. (b) `togglePackage`'daki `_rowCache.clear()`
  kalktı: tek üyeyi çöz/paketle 19/20 → 3/2 satır kurulumu. (c) ölçüldü, değişiklik
  gerekmedi: aç'ta yeni `TextField` 0, var olan satırın yeniden kurulumu 0, kurulan 8 = 6
  üye + kaydırmayla görünür olan 2 satır. Bütçe `budgets.json` S10. **Cihazda 30 maddeli
  paketli notta aç → yaz → kalın yap → kapat akışı denenmedi; ölçüm kapısı (ab_klavye) koşulmadı.**)*
  *Önce test (S10):* 6 maddeli paket aç → bir maddeye odaklan → alt çubuktaki Biçim
  düğmesine `tester.tap` → beklenen: paket AÇIK, odak yerinde. Bugün kapanıyorsa hipotez
  doğrulandı.
  *Düzeltme:* (a) `TapRegion` grubuna editörün çubuklarını kat: grup kimliği paket başına
  değil TEK sabit olur (`const kNotePackageTapGroup = 'note-package'`; açık paket zaten
  tek, `_openPackage`); alt çubuk, hızlı satır, biçim paneli ve kalem tepsisi
  `TapRegion(groupId: kNotePackageTapGroup, child: …)` ile sarılır (sarmalayıcı HEP var —
  ağaç şekli koşula bağlı değişmez). (b) `togglePackage`'daki `_rowCache.clear()` kalkar:
  satır anahtarı `item.package`'ı içerdiği için değişen üyeler kendiliğinden yenilenir,
  diğer satırlar önbellekten döner. (c) Aç/kapa'da paket DIŞI satırların `Element`'i
  yeniden kurulmamalı (anahtarlar korunur); üyeler açılışta düz çizimle (F24.3
  `items_editor_lazy.dart`) gelir, gerçek alan yalnız dokunulan üyede kurulur.
  Ölç: aç'ta mount edilen `TextField` ≤ 1, paket dışı satır kurulumu 0; paketle/çöz'de
  kurulan satır = üye sayısı.
  *Kabul:* S10 yeşil; KALANLAR I1'e "kök: <bulunan>" yaz; cihazda 30 maddeli paketli notta
  aç → yaz → kalın yap → kapat akışı takılmasız.
  Cihaz A/B (2026-11-10, Mi Note 10 Lite, `ab_klavye.py`, taban 4bdd6eb4, 2. koşular): klavye kapa 190 → 194 ms, aç 285 → 293 ms (LAYOUT 73 → 78) — regresyon yok. `yaz`/`not-kapa` evreleri iki değerli (kare sayısı 68↔208 / 5↔66; A1 ve B2 yüksek, A2/A3/B1 düşük): sürümden bağımsız gürültü, B1 düşük kipte tabanla aynı (yaz %105). Ölçüm arama sonucundan açılan notla yapıldı (OLCUM notları 414 notun dibinde).
- [x] **F60.3 "📖 s.N" satırı silinemiyor (sabit → gömülü geçişte).** *(2026-11-11: KÖK `tag_tap.dart` `linkAtPoint`: PDF referansı, notta dönülecek PDF olmasa da (PDF "Ek" görünümünde alt şeritte → `_pdfForRefs` null; madde satırlarında hiç işleyici yok) bağlantı sayılıyordu → odaksız alanda dokunuş klavyeyi AÇMIYOR, hiçbir şey de yapmıyordu; satıra imleç konamıyordu. Kanıt `test/pdf_ref_keyboard_test.dart` kırmızı → yeşil: `pdfRefs` bayrağı (damga gibi), gövdede `_pdfForRefs != null` iken açık, madde satırında kapalı. `WrapTextController` düzeyinde geri silme sarma açık/kapalı ÇALIŞIYOR (aynı dosyada bekçi). Yüzen görünümde referans bilerek bağlantı (dokununca sayfaya döner; imleç satır sonuna konup silinir). Cihazda doğrulanmadı.)* Yeniden üretim:
  sabit PDF'te "Not al" → görünümü Yüzen/Ek'e çevir → gövdede `📖 s.11 …` satırını
  Backspace ile sil. İncele: `core/utils/pdf_ref.dart`, `WrapTextController.linkSpans`,
  `tag_tap.dart` (dokunuş çözümü), `_setAttachmentView`. Şüpheli: referans satırı sarma
  çapası (`stripWrapAnchors`) ya da gömülü kutu `InkExclusionZone`/yüzen kutu dokunuşu
  yutuyor. Widget testiyle üret; üretilemezse maddeye "üretilemedi" yaz, kullanıcıdan ekran
  kaydı iste.
- [x] **F60.4 Misafir notunda üst çubuk "Senkronize" diyor.**
  *(2026-11-10: kanıt `test/editor_guest_sync_badge_test.dart` kırmızı (anonim hesapta
  "Senkronize") → yeşil. Üst çubuk göstergesi `isAnonymousProvider` true iken yalnız-bu-cihaz
  dalına girer (`cloud_off` + "Yalnız bu cihazda"); hesaplı kullanıcıda bulut aynen.
  Düzenek `pumpEditor`'a `overrides` parametresi eklendi.)* Misafir/yalnız-bu-cihaz
  notunda bulut simgesi yerine "yalnız bu cihazda" simgesi + ipucu (ana ekranla aynı dil).
  `watchPendingWrites` zaten `isLocal` için false döner; gösterge bileşeninde misafir dalı.
- [x] **F60.5 Yazma ana bloğu 148 → 229 ms (v1.1.671 → v1.1.701).** *(2026-11-13 P55: eski iki sürüm yeniden derlenmedi; bugünkü profil derlemesinde `prof_type.py` 4 × yazma: 215 kare, en pahalı 5 kare 38,9 / 21,8 / 20,1 / 19,3 / < 16 ms — hepsi LAYOUT ağırlıklı (metin alanı dizimi + düzenlenen paragrafın bağlantı/işaret taraması). Düzeltme F84.2'de)* `tool/perf/prof_type.py`
  ile iki sürümü profil derlemesinde karşılaştır; fark F60.1/Faz 59 sonrası sürüyorsa en
  pahalı 5 çerçeveyi maddeye yaz. Düzeltme ayrı madde olarak açılır.
- [x] **F60.6 Kart ve liste: ek sayacı/rozet tutarlılığı taraması.** *(2026-11-14 P22: düzeltildi — arşiv defteri rozeti (`note_card.dart`) ve paylaşım hedefi "📎 N" (`share_target_sheet.dart`) `attachmentsWithoutBackground` sayar; bekçi `card_hidden_media_test` + `share_target_test` (önce kırmızı → yeşil). İstatistik sayımları (note_stats, trash_analysis, archive_insights) bilinçli ham sayım, dokunulmadı. Cihazda doğrulanmadı: KALANLAR telefon 26.)* *(2026-11-11: tarama yapıldı, bulgular `docs/cihaz_turu.md` bölüm D — `note_card.dart:1755` ve `share_target_sheet.dart:516` düzeltme adayı; kod değişmedi, düzeltme açık.)* `Note.attachments`'ı
  doğrudan sayan yerleri `Grep "attachments.length\|attachments.isNotEmpty"` ile bul;
  zemin görselini saymaması gerekenler `attachmentsWithoutBackground` kullansın (HAFIZA
  "hayalet ek sayacı" kuralı).
- [~] **F60.7 MIUI beyaz açılış — KARAR K-O14.** *(2026-11-14 P22: DENEYIM planıyla kapandı/taşındı (KUYRUK §P22 "P22 ATLAR", Ek D).)*
- **F60.S Kullanıcının bildirdiği sorunlar (2026-11-09 listesi).** Başka faza düşenler:
  sabit PDF kaydırma → F65.8 · büyük dosyalar → F65.9 · telefon yatay → F66.7 · "not
  menüsü sağa" → F67.9 · yazım düzeltici → Faz 70 · güvenlik → Faz 71 · performans
  denetimi → Faz 59 + F60.S2 · kalem akışı → Faz 61–63 · ek akışı → Faz 65.
- [x] **F60.S1 [Opus] Uygulama içi güncelleme ekranda takılı kalıyor.** *(2026-11-10: kullanıcı "çözüldü" dedi; güncelleme akışı 514082b9'da yeniden yazıldı. Aşağıdaki inceleme adımları yapılmayacak.)* Kullanıcının ekran
  görüntüsü notunda (bu oturumda görülmedi). İncele: `core/app_update.dart`
  `installAppUpdate` (indirme → `installApk` → FileProvider `cache-path`): ilerleme
  penceresi her yolda kapanıyor mu (`DialogRoute` + `removeRoute` kuralı), kurulum
  İPTAL / izin ekranından dönüş / ağ hatası / indirme yarıda kesilme sonrası durum
  sıfırlanıyor mu. Cihazda: adb ile bir önceki sürümü kur → Güncelle → `adb logcat` +
  `uiautomator dump`. Kabul: başarı, iptal, ağ hatası üç yolda da ekran kapanır ya da
  hata + "yeniden dene" gösterir; widget testi üç yolu sabitler.
- [x] **F60.S2 [Fable] Klavye açılırken alt panel kasıyor ve kullanımla ARTIYOR.** *(2026-11-13 P55: cihazda yine birikim YOK — taze ve 30 gir-çık sonrası `prof_kb2.py` klavye aç/kapa UI en uzun kare 17,3 → 12,5 ms, > 16 ms 1 → 0. Kullanıcının gördüğü "alt panel" kusurunun kökü başkaymış: Android < 35 motoru animasyon karelerinde IME boşluğundan gezinme çubuğunu düşüyor, çubuk öneri şeridinin altında kalıyordu (bkz. `docs/hafiza/akicilik.md` P55) — düzeltildi)*
  Kullanıcı: "en başta yok gibi; notlara gir-çık yaptıkça artıyor; önceki fazda
  çözmüştük". Bu **birikim (sızıntı) imzası**: kapanan editörden kalan genel dinleyiciler
  klavyenin her karesinde iş yapıyor. *Önce say:* `lib/features/notes` ve `lib/core`'da
  her `addListener` / `addObserver` / `addGlobalRoute` / `addPostFrameCallback` dışı
  kalıcı kayıt / `listenManual` / `OverlayEntry.insert` / `Timer.periodic` için aynı
  sınıfta karşılığı (`remove…`, `cancel`, `close`, `remove()`) var mı; eşleşmeyenlerin
  listesini maddeye yaz. Öncelikli şüpheliler: `FocusManager.instance.addListener`
  (`KeyboardSwitch` / `_fieldFocusedN`, `auto_spell.dart`), `GestureBinding…addGlobalRoute`
  (TipOnce), `InkToolMemory.autoStylusListenable`, `HardKeyboard`, `BackCloses` kaydı,
  `_DocHub` aboneleri, `openNoteIdsProvider` yığını, `NoteVideoHub`, kapanışta `dispose`'u
  istisnayla yarıda kesilen editör (bkz. `_mutate` içindeki eski kök neden notu).
  *Bekçi testi* `test/editor_leak_test.dart`: editörü 15 kez aç-kapa; sonra tek not açıp
  klavye turu (`note_screen_chrome_test` F38.7 kalıbı) → tür başına kurulum sayısı 1.
  açılıştaki turla AYNI; `FocusManager` üzerindeki dinleyici sayısı (debug sayaçlı ince
  sarmalayıcıyla) artmamış. *Cihazda:* aynı sürümde taze açılış ile 30 gir-çık SONRASI
  `ab_klavye.py` klavye evresi; fark > %20 ise `prof_kb2.py` ile en pahalı 5 çerçeve.
  Kabul: 30 gir-çık sonrası klavye aç/kapa UI ms taze açılışın ≤ %110'u; bekçi yeşil;
  regresyon listesine satır.
  **Durum (2026-11-10, P02) — cihazsız birikim ÜRETİLEMEDİ; cihazda da ÜRETİLEMEDİ;
  madde AÇIK (sabah bakılacak: kullanıcıdan hangi notta/ne kadar kullanımdan sonra).**
  *Cihaz (2026-11-10, Mi Note 10 Lite, P01 sonrası profil derlemesi, `ab_klavye.py`):* taze
  açılış → yazmadan 32 gir-çık (4 not: metin, görselli ×3; her birinde klavye aç/kapa) →
  aynı ölçüm. Klavye aç 298,5 → 292,7 ms (LAYOUT 79,5 → 71,6), kapa 178,6 → 167,3 ms,
  yazma 1018 → 1053 ms; PSS 465 → 456 MB, yerel yığın 128 → 131 MB. Birikim yok.
  DENENMEDİ: sabit PDF'li not, uzun liste, 32'den uzun oturum, kalemli tablet. *Sayım:* `lib/` genelinde genel (uygulama ömürlü)
  kayıtların hepsinin karşılığı var — `FocusManager` (yalnız `note_editor_screen`
  initState/dispose), `autoStylusListenable` (editör + `pinned_media_pane`),
  `noteRouteClosing`, `addObserver` (editör, `note_video_boxes`), `addGlobalRoute`
  (TipOnce), `listenManual` (`_sub.close`); `HardKeyboard` tek seferlik (`_hooked`).
  Eşleşmeyen `addListener`'ların hepsi sınıfın KENDİ denetleyicisine (dispose'la gider).
  *Bekçi* `test/editor_leak_test.dart` (2 sahne): (1) çıplak editör rota olarak 20
  aç-kapa, (2) gerçek kabuk (AppFrame + SplitShell + ana ekran + `NoteOpenPage`, karta
  dokunarak; liste / metin / sabit PDF / gömülü PDF / görsel / sayfalı not, kalemli
  cihaz) 28 aç-kapa + her açılışta odak, yazma, klavye turu. Ölçülen: atılmamış nesne
  (Flutter bellek olayları: State, ChangeNotifier, Ticker, Element, RenderObject…) tür
  başına 6. → 18. kapanış ARTMIYOR; genel dinleyiciler açılış öncesiyle aynı; klavye
  turunun tür başına kurulum sayıları 10. ve 28. açılışta BİREBİR aynı. Tek kırmızı:
  `PageTurn`'ün `CurvedAnimation`'ı atılmıyordu (5 → 15; zararsız — üst denetleyici
  atılınca dinleyicisi düşer; düzeltildi, `page_swipe.dart`). **Sonuç: "kapanan
  editörden kalan dinleyici" varsayımı widget katmanında doğrulanmadı; kasma düzeltmesi
  YAZILMADI.** Kalan şüpheliler (cihazsız görülemez): yazdıkça uzayan not/madde
  (`ab_klavye.py` başındaki TUZAK notu — aynı maddeye her koşuda ~56 karakter), sınırsız
  statik önbellekler (`note_card_media` `_cache`/`_sizes`, `TextPagination._cache`,
  `pdf_page_ocr` `_cache`) → yığın/GC, raster tarafı, Firestore yankıları. *Yan bulgu
  (birikim değil, kare başı sabit yük):* kabukta klavye hareketinin orta karesinde
  ~28–50 widget kuruluyor; SABİT PDF'li notta ~180 (`PinnedMediaPane` ve bar
  düğmeleri her karede) — cihazda fark çıkarsa ilk bakılacak yer.
- [x] **F60.S3 [Opus] "Tümü" çipi bütün notları göstermeli; klasör çipleri denetimi.**
  *(2026-11-10: kanıt `test/folder_strip_chips_test.dart` kırmızı (Tümü dokununca
  `/folders`) → yeşil. `AllNotesChip` dokun = `resetFilters` + `showAllNotes` true (+ not
  açıksa `goHome`), uzun bas = `/folders`; vurgu artık klasör/Gelen/paylaşılan içindeyken
  söner (eskiden Tümü açıkken kendi klasörde iki çip vurguluydu). Test ev, Tümü, Gelen,
  kendi, paylaşılan çipini sırayla dener. Süzgeç açıkken şerit gizli olduğundan süzgeç
  sıfırlama yalnız kodda (arayüzden o anda Tümü'ye erişilmez). Kılavuz satırı güncellendi.)*
  Bugün (2026-11-06 kararı) "Tümü" DOKUN → `/folders`, UZUN BAS → bütün notlar. Kullanıcı
  (2026-11-09): dokununca ana ekranda tüm notlar. Düzelt: dokun = bütün notlar
  (klasör/süzgeç sıfırlanır, `resetFilters` + `goHome`), uzun bas = `/folders`. Ayrıca
  şeritteki HER çip için widget testi (ev düğmesi, Tümü, Gelen, kendi klasörüm,
  paylaşılan klasör): dokun → `filteredNotesProvider` beklenen küme, seçili çip vurgulu.
  `folder_strip_fixed_test` ve HAFIZA'daki 2026-11-06 maddesi güncellenir.
- [x] **F60.S4 [Fable] Ek gömülüyken silgi seçili olduğu hâlde kalem yazıyor.** *(2026-11-10:
  F63.2 ile düzeldi — `test/pen_single_tool_test.dart` düzeltmeden önce kırmızıydı (silgi seçili,
  gömülü/sabit PDF'te çizgi 1 → 2), şimdi dokunulan çizgi siliniyor; paket önizlemesi aynı
  denetleyici sınıfı, birim testiyle. Cihazda doğrulanmadı.)* Kök:
  gömülü/sabit ekin kendi `InkController`'ı tepsideki araç değişimini görmüyor (KALEM K4).
  Önce kırmızı test: tepside silgi seç → gömülü PDF'e kalem dokunuşu → çizgi sayısı
  ARTMAZ, dokunulan çizgi silinir (sabit PDF, not paketi önizlemesi için de). Düzeltme
  F63.2 (tek araç durumu).
**Kullanıcı listesi 2026-11-11** ("şimdi yap" — K-O1 istisnası; kuyrukta P23–P28):

- [x] **F60.S5 [Fable] Klavye açılırken alt panel titriyor/kasıyor — kökten.** Kullanıcı:
  "klavye açılırken alt paneldeki titreme kasmayı kökünden çöz, tekrar yaşanmayacak
  şekilde". F60.S2'nin birikim varsayımı üretilemedi; bu madde açılış ANININ kendisi:
  klavye hareketinin her karesinde alt panelin (ve gövdenin) yeniden dizilmesi/konum
  sıçraması. Kanıt: kabukta klavye animasyonu boyunca kare başına kurulum/LAYOUT sayısı
  (`keyboard_jank_guard_test` kalıbı; F60.S2 yan bulgusu: orta karede 28–50 widget,
  sabit PDF'li notta ~180) + alt panelin konumunun karelerde ileri-geri gitmesi (titreme).
  Kök düzeltme CLAUDE.md kasma listesi 6–7 ile: boy tek adımda, hareket yalnız boyamada;
  `viewInsets` yalnız dar öğede okunur. Bekçi: klavye açılırken alt panel konumu tekdüze
  (geri sıçrama yok) ve kare başı kurulum ≤ bütçe; `perf_budget` senaryosu. Cihaz A/B.
  **2026-11-11 (P23, Fable):** kök editör Scaffold'ı MediaQuery'ye bağlıydı (her klavye karesinde kurulum + dizim), hızlı satır ilk klavye karesinde kuruluyordu, PinnedMediaPane evreyi setState'le alıyordu → `KeyboardInsetScope`; S17 ilk kare 320 → 45, hareket 87–96 → 54, dizilen 1 → 0. Bekçi `keyboard_jank_guard_test` (konum tekdüze) + S17. Cihazda A/B BEKLİYOR.
- [x] **F60.S6 [Opus] Madde uzun bas: önce yazı seçilir, basılı tutmaya devam → madde
  seçimi.** Kullanıcı: "maddenin herhangi bir yerine basılı tutunca tüm yazı seçilir; bu
  doğru. Basılı tutmaya devam ederse madde seç çalışsın." Uzun basış (≈500 ms) = bugünkü
  metin seçimi; parmak kalkmadan ≈ +600 ms daha (hafif titreşim) → o madde seçim kipine
  girer (bugünkü madde seç), metin seçimi kalkar. Kasma listesi 1–4 geçerli. Widget testi.
  **2026-11-11 (P24, Opus):** `_HoldToSelect` (ham Listener, yalnız parmak, 1100 ms, kTouchSlop) → titreşim + madde seçim kipi; test `items_editor_hold_select_test` 5/5. Cihazda doğrulanmadı.
- [x] **F60.S7 [Fable] Yazarken alt panel gizleme ayarlanabilir.** Kullanıcı: "yazarken alt
  panelin gizlenip gösterilmesi ayarlanabilir olsun, kapatılabilsin; ne zaman kapanacak,
  kaç sn sonra açılacak — 0,1 sn adımlı kaydırıcı." Ayarlar → (Görünüm/Editör): aç/kapa
  anahtarı + "Gizlenme gecikmesi" ve "Yeniden görünme gecikmesi" kaydırıcıları (0–5 sn,
  0,1 adım), cihaz tercihi. Gizleme/gösterme kural 6 gereği yalnız boyamada. F60.S5'ten
  SONRA (aynı kod).
  **2026-11-11 (P25, Fable):** Ayarlar → Kartlar `TypingBarSettings`: anahtar + gizlenme/yeniden görünme gecikmesi (0–5 sn, 0,1; varsayılan 0 / 1,1 sn = eski davranış), cihaz tercihi; test 9/9. Cihazda doğrulanmadı.
- [x] **F60.S8 [Sonnet] Kartta gizlenen ek içeriği yazıyla anılsın.** Kullanıcı: "YouTube
  videoları ya da görseller notta; kartta görsel gizlenince hiçbir şeyi yokmuş gibi
  oluyor. En azından ek içeriği yazsın — 'YouTube videosu var' gibi güzel bir dille."
  Kart önizlemesi görseli göstermiyorsa (gizli/sığmıyor) tek satır, ikonlu, sade özet:
  "▶ YouTube videosu · Başlık", "🖼 2 görsel", "📄 PDF · ad" (l10n tr/en). Kart ızgarası
  kasma listesi 2 (önbellek anahtarı) geçerli. Widget testi.
  **2026-11-11 (P26, Sonnet):** `CardHiddenMedia` + tek satır özet (YouTube/video/görsel/PDF/ses, çoğul l10n), zemin görseli sayılmaz, kilitli notta yok; test `card_hidden_media_test`. Cihazda bakılmadı.
- [x] **F60.S9 [Opus] Ana ekranda sürüklerken çöp kutusu.** Kullanıcı: "notu basılı tutup
  sürüklerken aşağıda çöp kutusu olsun; üzerine gelince kısa bir dolma, bırakınca çöp
  kutusuna atılsın — hafif animasyonla." Sürükleme başlayınca altta çöp hedefi kayarak
  çıkar; üstüne gelince ≈ 600 ms dairesel dolum (yalnız boyama), dolunca titreşim; bırakınca
  kart küçülüp hedefe süzülür → çöpe taşınır (geri al çubuğu mevcut silme yoluyla). Dolum
  bitmeden bırakılırsa hiçbir şey olmaz. Mevcut sürükle-bırak (klasöre/sıraya) bozulmaz.
  **2026-11-11 (P27, Opus):** `DragTrashTarget` (hep ağaçta, boyamada belirir; 600 ms dolum, titreşim; olağan silme yolu + geri al); test 2/2. Cihazda doğrulanmadı.
- [x] **F60.S10 [Opus] Not ekle menüsü düzenlenebilir.** Kullanıcı: "not ekle menüsünde her
  düğme düzen kipinde gizle/göster ve yer değiştir olmalı." Menüde "Düzenle" → her öğede
  göz (gizle/göster) + tutamaçla sıralama; cihaz/hesap tercihi; "Varsayılana dön". Gizli
  öğeler normal kipte görünmez; en az bir öğe kalır.
  **2026-11-11 (P28, Opus):** + panelinde "Menüyü düzenle": göz + grup içi sıralama, Bitti, Varsayılana dön, son görünür kilitli; sıra `MenuLayouts` `home.quickAdd`; test 4/4. Cihazda doğrulanmadı.

- [x] **F60.S11 [Opus] Madde uzun bas — iki aşama görünür olsun** (kullanıcı listesi
  2026-11-12; F60.S6'nın devamı). Kullanıcı: "Uzun basmada 2 etkileşim: 1. önce yuvarlak
  bir dolum olur, ufak titreme, yazının tümü seçilir; 2. ufak titreme ile madde seç başlar."
  Basılan yerde dairesel dolum halkası (yalnız boyama, kasma listesi 3–4/6); 1. aşama
  (≈500 ms) sonunda hafif titreşim + maddenin TÜM yazısı seçili; parmak kalkmadan devam →
  halka ikinci tur, 2. aşama sonunda hafif titreşim + madde seçim kipi. Bugünkü
  `_HoldToSelect` (F60.S6) üstüne kurulur; yeni yol açma. Widget testi (iki aşama, titreşim
  çağrıları, satır önbelleği `identical`). Cihaz A/B.
  **2026-11-12 (P29, Opus):** `_HoldToSelect` iki aşama: basılan yerde halka (yalnız boyama, 150 ms sonra görünür), 650 ms hafif titreşim + tüm yazı seçili, 1250 ms hafif titreşim + madde seç; test `items_editor_hold_select_test` 10/10. Cihazda doğrulanmadı.
- [x] **F60.S12 [Opus] Çöp kutusu: kalan simge hatası + anlaşılır, premium atma efekti**
  (kullanıcı listesi 2026-11-12; F60.S9'un devamı). Kullanıcı: "çöp kutusuna bir şey
  sürükleyince işareti ekranda kalıyor; sürüklenen şey çöp kutusuna gitmiyor gibi —
  aslında gidiyormuş ama üzerine gelip beklemek gerekiyor, ne zaman atılacağı anlaşılmıyor.
  Çöp kutusuna yaklaştıkça notun görseli küçülerek gitsin, sonra kara delik gibi çekilsin,
  çöp kutusu yavaşça kırmızıya dönsün — premium bir çöp kutusu efekti. Atmanın bir
  animasyonu olmalı." (a) KANIT önce: sürükleme bitince/iptalde çöp hedefi gizlenmiyor
  (widget testi kırmızı) → kök düzelt. (b) Bekleme kalkar: hedef bölgesine girip BIRAKMAK
  yeter (yanlış silmeye karşı geri al çubuğu zaten var); yaklaştıkça sürüklenen kart
  mesafeyle küçülür ve hedefe doğru çekilir, hedef renk geçişiyle kırmızılaşır. (c) Bırakınca
  kara delik animasyonu (küçül + dön + içeri çekil, ≈350 ms) → olağan silme yolu + geri al.
  Hepsi boyamada (Transform/Opacity), ızgara yeniden dizilmez. Cihaz A/B (ana ekran listesi).
  **2026-11-12 (P30, Opus):** kök: hücre önizlemede yeniden kurulunca Flutter kabul edilen bırakmada `onDragEnd` vermiyordu → `onDragCompleted`+`onDraggableCanceled` (dashboard_widgets); beklemesiz bırak, yakınlıkla küçül/kızar, 350 ms kara delik; test 4/4. Cihazda A/B yapılmadı.
- [x] **F60.S13 [Sonnet] Kaydırarak geçişler kapatılabilsin** (kullanıcı listesi
  2026-11-12). Kullanıcı: "Kaydırarak klasör geçişlerini kapatabilmeliyiz; takvim hafta
  da ayar olarak kapatılabilir olmalı." Ayarlar'da iki anahtar (cihaz tercihi, varsayılan
  AÇIK = bugünkü davranış): "Ana ekranda kaydırarak klasör değiştir", "Takvimde kaydırarak
  hafta/gün değiştir". Kapalıyken yatay kaydırma jesti hiç kurulmaz (dikey kaydırma ve
  düğmeler çalışır). Widget testi.
  **Yapıldı 2026-11-12 (P31):** takvim anahtarı `calendarSwipeProvider` (hafta/gün/ay sayfa kaydırma + ay ızgarası jesti); ana ekran klasör kaydırması zaten Ayarlar → Notlar → "Ana ekranda yana kaydırınca → Kapalı" (SwipeMode.off) ile kapanıyor, yeni anahtar eklenmedi.
- [x] **F60.S14 [Sonnet] Panoda işaretli maddeye basınca işaret kalkmamalı** (kullanıcı
  listesi 2026-11-12). Kullanıcı: "dashboard'da işaretli bir maddenin işaretine basınca
  işareti kaldırılıyor; bu doğru bir davranış değil." Önce "dashboard"un hangi yüzey
  olduğunu kanıtla (ana ekran kart önizlemesindeki onay kutuları / günlük brifing-pano /
  takvim görev listesi — kodda `toggle` yollarını ara). En güvenli: o yüzeyde işaretli
  madde tek dokunuşla geri alınmaz (dokunuş notu/maddeyi açar ya da yok sayılır); işareti
  kaldırmak editörde. Karar "sabah bakılacak". Widget testi.
  **Yapıldı 2026-11-12:** yüzey ana ekran kart önizlemesi (`note_card.dart` madde satırı +
  `toggleCardItem`; tek `toggle` yolu). İşaretli kutuya dokunuş artık notu açar, işareti
  kaldırmaz; boş kutu işaretlenir. `test/card_checked_item_test.dart`. Sabah bakılacak:
  kart önizlemesinde işaret geri alma isteniyorsa uzun basma gibi ayrı bir yol gerekir.
- Kabul: F60.1 ve F60.2 bütçe testleriyle kilitli; diğerleri ya düzeltildi ya da
  "üretilemedi + ne gerekli" notuyla kapandı.

---

## FAZ 61 — Mürekkep deposu v2 (B1, B2, B3)

**Hedef:** (1) hiçbir belge 1 MiB'e yaklaşmasın, (2) kayıt maliyeti toplam mürekkeple değil
DEĞİŞEN bantla orantılı olsun, (3) ana iş parçacığında `double` listesi kodlanmasın.

**Önce oku:** `domain/attachment.dart` (`InkStroke`, 55–150), `domain/note_heavy.dart`
(tamamı), `domain/note.dart` (`pageInk`, `attachmentsField`, `fromMap`'te `rawPageInk`),
`data/notes_repository.dart` (`updateNote`, `_hydratedDoc`, `hydrate`, `_deleteCloudCopy`,
`duplicateNote`), `data/note_package.dart` (`encodeNoteJson`/`decodeNoteJson`),
`firestore.rules` 268–300, `auth/data/account_service.dart` (silme listeleri),
`core/app_update.dart` (`kClientDataVersion`), Ek B.

**Güvenlik şartları (CLAUDE.md gece kuralı):** göçten önce yerel tam yedek; göç idempotent;
eski biçim okunmaya devam; `rules-test` yeşil; yedek/geri yükleme aynı oturumda sınanır.

- [ ] **F61.0 Ölç ve doğrula.** *(2026-11-11 P13: (a) yapıldı — `test/ink_pack_test.dart`, 1000 basınçlı nokta 24 000–24 200 bayt; (b) ve (c) cihazda ölçülmedi → kapı açık kaldı, K-O2 "En güvenli" uygulandı: kodlayıcı + planlayıcı + okuma yazıldı, YAZMA bayrağı kapalı — sabah bakılacak.)* (a) Birim testi: 1000 nokta + basınçlı tek çizginin
  `estimateValueBytes(toMap())` değeri (beklenen ≈ 24 000). (b) Tablette gerçek bir el
  yazısı notunda nokta sayısı: editör açılışında debug'da bir kez
  `debugPrint('ink: ${çizgi} çizgi, ${nokta} nokta, ${bayt} bayt')` (profil derlemesinde
  bak, sonra satırı sil). (c) `tool/perf/prof_save.py` ile 1500 çizgili notta kayıt sonrası
  ana blok (ms). Sonuçları maddeye yaz. **Kapı:** (b) bir ekran < 150 KB VE (c) < 8 ms
  çıkarsa K-O2'de "yalnız sıkı kodlama" seçeneğine in; değilse tam kapsam.
- [x] **F61.1 Sıkı kodlayıcı (saf Dart).** *(2026-11-11 P13: `ink_pack.dart` + `test/ink_pack_test.dart` yeşil; 1000 basınçlı nokta ≤ 4500 bayt.)* `lib/features/notes/domain/ink_pack.dart`:

  ```dart
  /// Çizgileri Ek B'deki ikili biçime yazar / okur. Okunan çizgide `points`
  /// ve `pressures` bugünkü gibi `Float32List`.
  Uint8List encodeInkPack(List<InkStroke> strokes, {List<double>? z});
  ({List<InkStroke> strokes, List<double> z}) decodeInkPack(Uint8List bytes);
  ```

  Test `test/ink_pack_test.dart`: gidiş-dönüş (boş, tek nokta, ok, şekil, basınçlı, saydam,
  y > 1 olan uzun sayfa, 5000 çizgi); nokta sapması ≤ 1/16384; bozuk/kısa girdi `FormatException`
  (çökme yok); bilinmeyen sürüm baytı → `FormatException`; boyut: 1000 basınçlı nokta
  ≤ 4500 bayt.
- [x] **F61.2 Çizgi sadeleştirme (kalkışta).** *(2026-11-11 P13: `simplifyStroke` + `InkController.pointerUp`; öneri sadeleşmiş çizgiden tanınır (sapma ≤ 0,3 dp, kimlik tutarlı kalsın diye) — sabah bakılacak; `ab_kalem.py` cihazda ölçülmedi.)* `InkController.pointerUp`'ta serbest çizgi
  bitince (ok/şekil/oturmuş düz çizgi HARİÇ) RDP: tolerans 0,0004 sayfa genişliği
  (~0,3 dp); basınç dizisi aynı indekslerle süzülür; ilk/son nokta korunur.
  `ink_recognize.dart`'taki `_simplify` `Offset` listesiyle çalışıyor — düz listede çalışan
  25 satırlık bir sürümü `ink_pack.dart`'a yaz (`simplifyStroke`), tanıma kodu değişmesin.
  Test: sadeleşmiş çizginin özgün çizgiye en büyük uzaklığı ≤ tolerans; nokta sayısı
  gerçekçi el yazısı örneğinde ≥ %40 azalır; i noktası (tek nokta) ve 2 noktalı çizgi
  dokunulmaz. Şekil tanıma sadeleştirmeden ÖNCE çalışır (bugünkü sıra korunur).
- [x] **F61.3 Planlayıcı (saf Dart).** *(2026-11-11 P13: `ink_plan.dart` + `test/ink_plan_test.dart` yeşil (6 durum + z tükenmesi); yoğun bant `~<bant>`, `b`, `c`… parçalarına bölünür.)* `lib/features/notes/domain/ink_plan.dart`:

  ```dart
  const kInkBandHeight = 1.0; // sayfa genişliği biriminde; uzun sayfa bantlara bölünür

  /// docId → bayt. docId = '<yüzey>~<sayfa>~<bant>' (yüzey: ek kimliği ya da '_page_ink').
  Map<String, Uint8List> planInkDocs({
    required String surface,
    required List<InkStroke> strokes,
    required InkOrder order, // çizgi örneği → z (Expando); bilinmeyene komşudan z verir
  });

  /// Bantlardan düz listeye: z'ye göre kararlı sıralı.
  List<InkStroke> mergeInkDocs(Iterable<Uint8List> packs, InkOrder order);
  ```

  Kurallar: bant = `floor(ilk noktanın y'si / kInkBandHeight)`; sayfası sabit oranlı
  yüzeyde (PDF/görsel, y ≤ 1) bant hep 0. z: yüklenen çizgi kayıttaki z'sini korur; yeni
  çizgi düz listedeki önceki ve sonraki komşunun z ortalamasını alır (sonda: önceki + 1).
  Bir bant paketi 256 KB'ı aşarsa (çok yoğun bant) ikiye bölünür: `…~<bant>` ve
  `…~<bant>b` (z'ye göre ilk yarı / ikinci yarı).
  Test `test/ink_plan_test.dart`: (1) `merge(plan(x)) == x` sıra dahil; (2) sona çizgi
  eklemek yalnız 1 belgeyi değiştirir; (3) ortadan silmek yalnız o bandı değiştirir;
  (4) taşıma (kement) eski ve yeni bandı değiştirir, başka bant değişmez; (5) yerinde
  değiştirme (şekle oturtma) çizim sırasını korur; (6) 20 000 çizgi → hiçbir belge > 256 KB.
- [ ] **F61.4 Kurallar ve silme listeleri.** *(2026-11-11 P13 — KISMEN: silme listeleri yapıldı (`_deleteCloudCopy` kalıcı silme + "yalnız bu cihaz" ortak yolu, `AccountService.deletedNoteSubcollections`; testler `notes_repository_data_test`, `account_deletion_test`). Kurallara DOKUNULMADI: paket sınırı "yalnız sıkılaştırma"; ortak not/klasör kullanıcısına `ink` erişimi açmak yeni erişim. Sahip `users/{uid}/{collection}/**` genel kuralıyla zaten erişir; v2 yazımı kapalıyken `ink` belgesi oluşmaz. Bayrak açılmadan ÖNCE kural + `rules-test` yazılmalı — sabah bakılacak.)* `firestore.rules` 275–300: `sub in ['heavy',
  'versions']` geçen okuma/oluşturma/güncelleme kurallarına `'ink'` ekle; **silme** de
  gerekir (boşalan bant belgesi silinir) — `heavy` için bugün silme kuralı sahibin genel
  kuralından geliyor; ortak notta 'write' rolü için `ink` belgesinde `delete` izni ekle
  (koşul `update` ile aynı). `rules-test`'e: sahip yazar/siler; 'write' rolü yazar/siler;
  'read' rolü yazamaz; yabancı okuyamaz. Silme listeleri: `notes_repository.dart`
  `_deleteCloudCopy`'ye `ink` alt koleksiyonu; `account_service.dart:63` listesine `ink`
  (`account_deletion_test` bilerek kırılır → güncelle). Kalıcı silme, "yalnız bu cihaz",
  hesap silme üçü de testle.
- [x] **F61.5 Okuma tarafı (iki biçim birden).** *(2026-11-11 P13: `_hydratedDoc` tek `ink` dinleyicisi + `InkDocCache` (bayt bayt aynı belge çözülmez, değişmeyen yüzeyin listesi aynı örnek), `mergeInkV2` (v2 kazanır, `inkV: 2` not `heavyRef` sayılır), `hydrate`/`hydrateNote` → `needsHydrate`; bozuk/bilinmeyen sürüm `ErrorLog`'a, atlanır. v1 notta `heavyLoaded` anlamı AYNEN. Test `test/ink_v2_read_test.dart`. Açık: bozuk bantlı yüzeyin "salt okunur" açılması yazılmadı (yazım kapalıyken üstüne yazan yok) — sabah bakılacak.)* `_hydratedDoc`: ana belgede `inkV == 2`
  ise `notes/{id}/ink` koleksiyonu dinlenir (tek dinleyici); gelen belgeler yüzey→sayfa→bant
  eşlenir, `mergeInkDocs` ile çizgiler kurulur ve ilgili ekin `ink`'ine / `pageInk`'e
  konur. **Yalnız değişen belge çözülür:** belge kimliği → (son görülen paket baytları,
  çözülmüş çizgiler) önbelleği; gelen paket BAYT BAYT aynıysa (tam karşılaştırma — uzunluk
  ya da ön ek yetmez: çizgi kıpırdayınca boy aynı kalır; ≤ 256 KB'ta < 1 ms) çözme yok.
  Kendi yazdığın paket böyle elenir.
  `hydrate()` (paylaş, kopya, yedek, toplu seçim) da `ink` koleksiyonunu okur. v1 dizisi
  ile v2 belgesi aynı yüzeyde birlikteyse v2 kazanır. `heavyLoaded` v2 notta `ink`
  koleksiyonunun İLK anlık görüntüsü de gelince true olur (yoksa eksik mürekkeple yazım
  riski).
  Test: v1 not olduğu gibi açılır; elle kurulmuş v2 not açılır; karışık (bir ek v1, sayfa
  v2) açılır; `hydrate` v2'yi doldurur.
- [ ] **F61.6 Yazma tarafı + tembel göç.** *(2026-11-11 P13 — YAZILMADI: K-O2 "En güvenli" = kodlayıcı + planlayıcı + okuma, YAZMA kapalı; F61.0 kapısı (b)(c) cihazda ölçülmediği için kapsam da kesin değil ("yalnız sıkı kodlama"ya inebilir). Bekçi: `ink_v2_read_test` "v2 YAZIMI KAPALI" (kayıt `ink`'e yazmaz, `inkV` koymaz). Not: v1 yazan istemci v2 notu düzenlerse mürekkebi v1'e yazar, okumada v2 kazanır → değişiklik görünmez; bayrak açılmadan önce `minClient` (K-O3) ŞART — sabah bakılacak.)* Bayrak: `config/app.inkV2Write` (bool, yoksa
  false) + debug'da yerel tercih `ink_v2_write`. Bayrak açıkken `updateNote`: mürekkep ana
  belgeye/`heavy`'ye YAZILMAZ; `planInkDocs` çıktısı son yazılanla (docId → bayt özdeşliği)
  karşılaştırılır, yalnız değişen belgeler `set`, boşalanlar `delete`, ana belge
  `inkV: 2` ile aynı `WriteBatch`'te. `heavy/data`'da yalnız `bubbles`/`pdfMarks` kalır.
  Ana belgede `_page_ink` işaret kaydı (`{id, kind: 'pageInk'}`) mürekkepsiz kalır
  (`hasPageInk` kart için gerekli): `Note.attachmentsField` çıktısındaki her ek
  haritasından `ink` anahtarı v2 yazımında sökülür. Kart el yazısı önizlemesi
  (`CardPageInk`) veriyi nereden alıyor koddan doğrula; hafif listede mürekkep yokken
  bugünkü davranış neyse o korunur. **Tembel göç:** v1 not düzenlenebilir açılmış ve ağır
  veri yüklüyse ilk mürekkep değişikliğinde (ya da kullanıcı notu kapatırken mürekkep
  varsa) v2'ye yazılır ve AYNI batch'te `heavy/data`'dan `ink` anahtarları kaldırılır.
  **Göçten önce (F54.3):** cihazda bir kez `BackupService` ile otomatik tam yedek
  (`appSupportPath/yedek_ink_v2_oncesi.notyedek`, tercih `ink_v2_backup_done`); yedek
  alınamazsa bayrak açık olsa da v2 yazımı YAPILMAZ ve `ErrorLog`'a yazılır.
  Not paketi / yedek JSON biçimi DEĞİŞMEZ (`encodeNoteJson` v1 dizisi yazar; hidratlanmış
  nottan). Yerel notlar (`LocalNotesStore`) v1 kalır.
  Test: bayrak kapalı = bugünkü yazım bayt bayt aynı; bayrak açık = S16 (1 çizgi → 1 belge,
  ≤ 64 KB); göç idempotent (iki kez çalıştır, sonuç aynı); göç yarıda kesilirse (batch
  hatası) not v1 olarak okunmaya devam eder; `duplicateNote`, "yalnız bu cihaz", paylaş,
  tam yedek → geri yükleme v2 notta mürekkebi korur.
- [ ] **F61.7 Sürüm ve eski istemci (K-O3).** *(2026-11-14 P22: açık, yapılamaz — kullanıcı kararı K-O3 (v2 yazımı) bekliyor; gözetimsiz açılmaz; kullanıcı listesine.)* `kClientDataVersion` 3 → 4. Sürüm notu ve
  `KALANLAR`'a kullanıcı adımı: "telefon, tablet, web güncel olunca Firebase konsolu →
  `config/app` → `inkV2Write: true`, `minClient: 4`". Bayrak açılmadan önce telefonda bir
  notta debug tercihiyle uçtan uca denenir.
- [ ] **F61.8 Ölçüm.** *(2026-11-14 P22: açık, yapılamaz — F61.6 (v2 yazma) yazılmadan ölçülecek şey yok; cihaz; kullanıcı listesine.)* F61.0'ın (c) ölçümü yeniden: 1500 çizgili notta kayıt sonrası ana
  blok **< 4 ms**; kayıt başına yazılan bayt ≤ 64 KB; `ab_kalem.py` dolu sayfa evresinde
  kayıt anında > 16,7 ms kare yok.
- Kabul: 20 000 çizgili sentetik not açılır, çizilir, kaydedilir; hiçbir belge > 256 KB;
  eski sürümle yazılmış her not açılır; yedek → boş hesaba geri yükleme mürekkebi getirir.

---

## FAZ 62 — Mürekkep çizimi v2 (B4, gecikme)

**Hedef:** kalem hareketinin maliyeti sayfadaki çizgi sayısından bağımsız olsun.

**Önce oku:** `viewers/ink_layer.dart` (`InkController` 50–950, `pointerDown/Move/Up`,
`InkPageLayer` 1649–1800, `_InkOverlayPainter`, `InkPainter` 2580–2689),
`editor/page_ink_layer.dart`, `viewers/ink_pen.dart` (`inkPaint`), `note_card_media.dart`
(`CardPageInk`).

- [ ] **F62.0 Ölç (kapı).** *(2026-11-11, P14: yapılmadı — cihaz işi, işçi telefona dokunmaz; F62.1–F62.2 sonrası `ab_kalem.py` boş/1500/4000 yürütücüde.)* `ab_kalem.py` boş / 1500 / 4000 çizgili sayfada: çizerken kare
  başına UI ms ve raster ms (p50/p90), > 16,7 ms kare oranı. Beklenen: çizgi sayısıyla
  doğrusal. Raster p90 dolu sayfada < 6 ms çıkarsa F62.3 yapılmaz. Sonuçları yaz.
- [x] **F62.1 Etkin çizgi ayrı katman.** *(2026-11-11, P14: S15 2001 → 1 çağrı; `committedRev` `notifyListeners`'ta kimlik karşılaştırmasıyla artar (her yolu ayrı ayrı işaretlemek yerine), `test/ink_paint_v2_test.dart`: çizerken bitmiş katman `debugNeedsPaint` false. Kement taşıma sürerken seçili çizgiler bitmiş katmanda kaldı (bugünkü maliyet). `TOUR_COMPARE` piksel denetimi koşulmadı — F62.2 pikselleri bilerek değiştiriyor.)* `InkController`'a `ValueNotifier<int>
  committedRev` (yalnız BİTMİŞ çizgi kümesi değişince artar: çizgi sonu, silgi, geri al,
  yerine koy, taşıma bitişi) ve `InkStroke? get activeStroke`. `InkPageLayer`:
  `ListenableBuilder` KALKAR; yerine `Stack[ RepaintBoundary(CustomPaint(painter:
  CommittedInkPainter(controller, page, repaint: controller.committedRev))),
  CustomPaint(painter: ActiveInkPainter(controller, page, repaint: controller)) ]`.
  `CommittedInkPainter` `_active` hariç çizgileri çizer; `ActiveInkPainter` yalnız etkin
  çizgiyi + bugünkü `_InkOverlayPainter` işlerini. Sayfa süzgeci (`s.page == page`)
  denetleyicide `committedRev` başına bir kez hesaplanıp önbelleklenir
  (`strokesOf(page)`). `Semantics` etiketi `committedRev`'e bağlı küçük bir
  `ValueListenableBuilder`'a iner.
  *Tuzak:* silgi ve kement sürerken bitmiş çizgiler değişir → o hareketlerde
  `committedRev` de artar (bugünkü maliyet; kabul). Taşıma/döndürme SÜRERKEN seçili
  çizgiler etkin katmanda çizilir, bitince bitmiş katmana döner.
  *Kabul:* S15 ≤ 8 çizim çağrısı; 16 InkController kuran dosyanın hepsi derlenir
  (`ink_editing_guard_test` yeşil); ekran turu `TOUR_COMPARE` ile mürekkepli ekranlarda
  piksel farkı %0.
- [x] **F62.2 Çizgi başına geometri önbelleği.** *(2026-11-11, P14: `viewers/ink_stroke_paint.dart` tek çizim yolu (katman, kart, PDF/görsel dışa aktarma `InkPainter` üstünden); 1500 saydam basınçlı çizgi = 1500 çağrı, `saveLayer` 0. Basınçlı dolgu şerit yerine parça başına kapsül birleşimi (keskin dönüşte delik olmasın). Seyrek çizgi (şekil, %2'den uzun parça) yumuşatılmaz — köşe keskin kalır. Altın görüntü gözle onayı yapılmadı: sabah bakılacak.)* `Expando<_StrokeGeom>` (anahtar: çizgi
  örneği): (boyut, `Path`, sınır kutusu). Düz kalınlıkta çizgi: tek `Path`, **orta nokta
  yumuşatmalı** (`quadraticBezierTo(p[i], mid(p[i], p[i+1]))`; 2–3 noktalıda düz).
  Basınçlı çizgi: değişken kalınlıkta **tek dolgu çokgeni** (her noktada normal ± yarı
  kalınlık, uçlarda yarım daire; `PathFillType.nonZero`) → nokta başına `drawLine` ve
  saydam çizgideki `saveLayer` KALKAR. Etkin çizgi büyürken önbellek kullanılmaz (her
  karede yeniden kurulur; tek çizgi ucuz). `CardPageInk`, PDF dışa aktarma
  (`image_annotations.dart`) ve yazdırma aynı yardımcıyı kullanır (tek çizim yolu).
  *Kabul:* 1500 basınçlı çizgide `TestRecordingCanvas` çağrı sayısı ≤ çizgi sayısı + 4;
  altın görüntü: eski/yeni çizim yan yana `build/tour`'da; fark gözle onaylanır (köşeler
  yumuşar — beklenen); i noktası ve basınç 0 çizgi görünür (taban kalınlık ×0,35 korunur).
- [ ] **F62.3 Bant karoları (uzun sayfa).** *(2026-11-11, P14: yapılmadı — F62.0 kapısı ölçülmeden (raster p90 dolu sayfada < 6 ms ise gereksiz) en güvenli seçenek beklemek; sabah bakılacak.)* `PageInkStack` (uniform sayfa) bitmiş katmanı
  tek `CustomPaint` yerine `kInkBandHeight` yüksekliğinde karo `RepaintBoundary`'lerine
  böler; karo, sınır kutusu kendisiyle kesişen çizgileri `clipRect` ile çizer. Bir çizgi
  eklenince yalnız kesiştiği karolar yeniden boyanır (`committedRev` yerine karo başına
  sürüm: denetleyici "kirli bant kümesi" verir). Ekran dışındaki karoyu derleyici zaten
  çizmez. PDF/görsel sayfasında sayfa = tek karo (değişmez).
  *Kabul:* 4000 çizgili 10 ekranlık notta çizerken raster p90, boş sayfadakinin ≤ 1,5 katı;
  kaydırırken karo sınırında kesik/eksik çizgi yok (uzun dikey çizgi iki karoda da görünür
  testi).
- [ ] **F62.4 (yalnız F62.3 yetmezse) Karoyu görüntüye fırınla.** *(2026-11-14 P22: açık, yapılamaz — koşullu: F62.0/F62.3 cihaz ölçümü yok; kullanıcı listesine.)* Karo 300 ms değişmezse
  `Picture.toImageSync` ile aygıt pikselinde görüntüye çevrilir, çizimde `drawImageRect`;
  değişince düşer. Bellek tavanı 8 karo. Zamanlayıcı YOK (test tuzağı): "değişmeden geçen
  kare sayısı ≥ 18" ile.
- [x] **F62.5 Dolma kalem (YORUM F55.4).** *(2026-11-11, P14: `InkPen.fountain` (sırada SONDA — ön ayarlar sıra tutuyor), tür saydamlık 0xFE'den tanınır (şeffaflık kaydırıcısı %10 adımlı, 254 üretmez), şeffaflığı sabit; tepside tükenmezin yanında. Dolma kalem çizgisi kalkışta RDP ile sadeleşmez (hız nokta aralığında). Paylaşılan PDF damgası (`pdf_edit.dart`) basınçlı çizgi gibi düz kalınlıkta kalır. Testler `test/ink_paint_v2_test.dart`. Cihazda denenmedi.)* Yeni `InkPen` türü: basınç eğrisi daha dik
  (×0,2–×1,8) + hızla incelme (ardışık nokta aralığı büyüdükçe kalınlık azalır; hız
  bilgisi noktalardan türetilir, şema değişmez). F62.2'nin çokgen yoluyla çizilir.
  Tepside 5. kalem. i/ö/ü noktası: tek noktalı çizgi taban yarıçapla çizilir.
- [ ] **F62.6 Gecikme ölçümü (YORUM F54.1) + uç tahmini (K-O4).** *(2026-11-14 P22: açık, yapılamaz — cihaz ölçümü (240 fps) + K-O4 kararı; kullanıcı listesine.)* Ölçüm: 240 fps ağır
  çekim ya da ekran kaydı + `getevent` zaman damgası; kalem ucu ile çizginin ucu arası
  mesafe / kalem hızı = gecikme (ms). Hedef ≤ 2 kare (33 ms). Fazlaysa: etkin katmanda son
  iki noktadan doğrusal 1 karelik tahmin parçası (yalnız boyanır, çizgiye EKLENMEZ, sonraki
  olayda düzelir); cihaz tercihi `ink_predict`. Kullanıcı A/B'de beğenmezse kapalı kalır.
  Ön tampon (androidx graphics-core) yalnız bunlardan sonra hâlâ > 3 kare ise ayrı KARAR.
- Kabul: `ab_kalem.py` dolu sayfa (1500) ile boş sayfa arasında UI ms ve raster ms farkı
  ≤ %20; bütçe S15 kilitli.

---

## FAZ 63 — Kalem akışları: her yüzeyde tek kural

`KALEM_PLANI.md`'nin "Kurallar 1–4"ü hedef davranıştır (değişmedi). Bugün kural dört ayrı
yerde yeniden yazılmış (editör `_syncPageInkKinds`, bölme `_inkFor`/`_explicitPen`/`_ownPen`,
gömülü `_docInkFor`, görüntüleyiciler) — B3/B4/B5 hataları buradan çıktı.

**Önce oku:** `KALEM_PLANI.md`, `editor/note_editor_flow.dart` (`_pageInkOf`,
`_syncPageInkKinds`), `editor/pinned_media_pane.dart` 280–345, `editor/note_images.dart`
385–420, `editor/stylus_toggle.dart`, `editor/pen_tray.dart`, `viewers/ink_layer.dart`
(`InkToolMemory`, `allowedKinds`, `penOnly`, `claims`).

- [x] **F63.1 `PenPolicy` (saf işlev, tek doğruluk tablosu).** *(2026-11-10: `viewers/pen_policy.dart`
  + `test/pen_policy_test.dart` (6 yüzey × 16 girdi, bugünkü davranış + "yerel kopya yok" bekçisi).
  Sayfa, sabit, gömülü, paket ve yüzen düğme görünürlüğü oradan okur; görüntüleyici/çizim ekranında
  yerel kural yoktu (`allowedKinds` atanmıyor) — tabloda satırları var, F63.4 bağlar. Davranış
  değişmedi; cihazda doğrulanmadı.)*
  `lib/features/notes/presentation/viewers/pen_policy.dart`:

  ```dart
  enum PenSurface { page, pinnedDoc, embeddedDoc, viewer, drawing, package }

  class PenPolicy {
    const PenPolicy({required this.allowedKinds, required this.fingerScrolls,
        required this.showFloatingToggle, required this.layerActive});
    /// null = hepsi çizer.
    final Set<PointerDeviceKind>? allowedKinds;
    final bool fingerScrolls;
    final bool showFloatingToggle;
    /// false = mürekkep katmanı hiç kurulmaz (basılı tut seçim parmakta kalsın).
    final bool layerActive;

    static PenPolicy resolve({required PenSurface surface, required bool penMode,
        required bool autoStylus, required bool stylusEver, required bool penOnly});
  }
  ```

  Test `test/pen_policy_test.dart`: KALEM_PLANI kurallarının doğruluk tablosu (kalem
  görülmüş/görülmemiş × kip açık/kapalı × yalnız kalem × yüzen düğme yazar/dokunur × 6
  yüzey). Sonra altı yüzey de `PenPolicy.resolve` çağırır; yerel kopyalar silinir.
  Davranış DEĞİŞMEZ (önce tablo bugünkü davranışla yazılır, sonra sapma varsa ayrı madde).
- [x] **F63.2 Tek araç durumu (KALEM K4).** *(2026-11-10: araç alanları `InkController`'da getter →
  `InkToolMemory` (kopya yok); `InkToolMemory.toolRev` bütün açık denetleyicileri uyarır; etkin yüzey
  `InkController.active` (döngüsel import olmasın diye orada), editör tepsisi `followActive` ile geri
  al/yineleyi ona yollar. Geçici araç (silgi/ok/şekil/kement) açık denetleyici kalmayınca kaleme
  döner. Kalan: kement seçiminin renk/sil işlemleri hâlâ tepsinin kendi (sayfa) denetleyicisinde.
  `test/pen_single_tool_test.dart` 9 yeşil. Cihazda doğrulanmadı.)* `InkToolMemory` araç/renk/kalınlık/silgi için
  `ValueListenable` verir; her `InkController` `pointerDown`'da aracı oradan okur (kendi
  kopyası yok). "Etkin yüzey" = son kalem dokunuşunu alan denetleyici
  (`InkToolMemory.activeController`); `PenTray` geri al/yinele/silgiyi ona yollar. Test:
  tepside renk değiştir → sabit PDF'e çizilen çizgi yeni renkte; geri al son dokunulan
  yüzeyde çalışır.
- [x] **F63.3 Sabit ve tam ekran GÖRSELE kalem (KALEM K2).** *(2026-11-11, P15: tam ekran görselde
  katman zaten vardı; SABİT görselde yoktu ve var olan çizim bölmenin TAMAMINA boyanıyordu (görsel
  `contain` ile ortalanınca kayık). Artık `pinned_media_pane._imageInkLayer`: görselin dikdörtgeninde,
  yakınlaştırmanın içinde, `InkClaim` + `InkPageLayer` (`PenPolicy.pinnedDoc`); parmak çizerken iki
  parmak `InkNavLayer`. Bölme çubuğuna görsel için ayrı kalem düğmesi EKLENMEDİ (K-O6 çubuk kararı
  açık) — editörün kalem kipi / yüzen düğme açar. Test `test/pinned_image_ink_test.dart` (kırmızı 3 →
  yeşil 4). Cihazda doğrulanmadı.)* `Attachment.ink`, sayfa 1,
  `uniform: false`; katman görselin `BoxFit.contain` dikdörtgenine oturur (ölçek/kaydırma
  dönüşümünün İÇİNDE, yakınlaşınca birlikte büyür). Dışa aktarma zaten çizimi basıyor
  (`image_annotations.dart`). Test: 2× yakınlaşmışken çizilen çizgi 1×'te aynı yerde.
- [x] **F63.4 Tam ekran görüntüleyicilerde yüzen kalem düğmesi (KALEM K3).** *(2026-11-11, P15:
  `viewers/viewer_pen.dart` (`ViewerPen` karışımı) üç görüntüleyicide: `StylusToggleOverlay` + kalemin
  ilk görülüşü; `PenPolicy.viewer` artık sabit belgeyle aynı kural (tablo testte değişti): "kalem
  yazar"ken kalem çizim düğmesine basmadan yazar (`InkClaim`), parmak gezinir; "dokunur" açık çizim
  kipini de kapatır. `stylusEver` ayrıca `InkController.pointerDown`'da (her katman). Kalem kipi kapalı
  yazarken kalem tepsisi yok (araç son seçilen) — tepsi için çizim düğmesi. Testler
  `test/viewer_stylus_toggle_test.dart` (kırmızı 3 → yeşil 4), `test/pen_policy_test.dart`. PDF/slayt
  görüntüleyicide widget testi yok (pdfrx); cihazda doğrulanmadı.)*
  `PdfViewerScreen`, `ImageViewerScreen`, `SlideViewerScreen`'e `StylusToggleOverlay`;
  `stylusEver` her mürekkep katmanında işaretlenir (bugün yalnız editör içeriğinde).
- [x] **F63.5 Telefonda elle yazma (KALEM K5, B10) — KARAR K-O5.** *(2026-11-11, P15, gözetimsiz:
  K-O5'te "En güvenli: dokunma" uygulandı — alt çubuk DEĞİŞMEDİ, klavye kapalıyken kalem hâlâ yalnız
  Ekle → "El yazısı"nda ve hızlı satırda (B10 AÇIK kalır); **sabah bakılacak**. Yapılan: kalem kipi
  parmakla açılınca (yalnız kalem kapalı) bir kez "Tek parmak çizer · iki parmak kaydırır" ipucu
  (`TipOnce.penTwoFinger`, `_penModeOpened`). Sayfa altı boşluğu için düzeltme YAZILMADI — üretilemedi:
  boşluk zaten son çizginin altında ekran boyunun %70'i (`page_ink_layer.dart` `viewport * 0.7`),
  400×800'de 560 dp ve çizgi indikçe uzuyor (test doğruluyor). Test `test/editor_pen_tablet_test.dart`
  (kırmızı 1 → yeşil). Cihazda doğrulanmadı.)* Klavye kapalıyken alt
  çubukta kalem; kalem kipinde iki parmakla kaydırma ipucu (`TipOnce`); sayfa sonunda
  yazdıkça uzayan boşluk (bugün kalem kipinde "sayfa altı boşluğu" var — telefonda yeterli
  mi tur görüntüsüyle bak). Cihaz: tablette telefon düzeni + `input touchscreen`.
- [ ] **F63.6 Parmağa araç (YORUM F55.1) — KARAR, tablette denenmeden yazılmaz.** *(2026-11-14 P22: karar 2026-11-12 VERİLDİ ("parmağa ayrı araç YAZILIR"); KUYRUK §P22 "atlananlar" listesi bununla çelişiyor (eski). P22'de yazılmadı — kalem işi, fable paketi gerekir → açık kod işi; sabah bakılacak.)*
- [ ] **F63.7 Kalem cihaz turu (YORUM F55.5).** *(2026-11-14 P22: açık, yapılamaz — kullanıcı tableti; docs/cihaz_turu.md B; kullanıcı listesine.)* `docs/cihaz_turu.md` kalem bölümü: avuç
  reddi (elle), kalem tıkı metne gider, kapsül ↔ hap, şekil/çokgen/çizgi ucu, sabit PDF,
  gömülü PDF, görsel, tam ekran, yüzen düğme, telefonda parmak. Kullanıcı yapar; sonuç
  maddelere işlenir.
- Kabul: `pen_policy_test` yeşil ve altı yüzeyde yerel kural kopyası yok
  (`Grep "allowedKinds ="` yalnız `PenPolicy` kullanan satırları verir).

---

## FAZ 64 — Editör çekirdeği: dar dinleme (B6)

**Başlama şartı:** Faz 59 bütçe tablosu dolu VE Faz 60–63 bitti. Tabloda kök kurulumu hâlâ
pahalı olan senaryo yoksa (S3, S4, S9, S14 ≤ hedef ve cihazda kök `build` < 4 ms) bu faz
**yapılmaz**; "gerek kalmadı" diye kapatılır.

**İlke:** Kök `setState` yalnız KİP değişiminde. Not içeriği değişince yalnız o içeriği
çizen bölge kurulur. Bölge bağımlılığını derleyici zorlar (ayrı widget, açık parametre).

**Önce oku:** `note_editor_screen.dart` (alanlar 470–1150, `_mutate`, `build` 2876–~4900),
`note_editor_parts.dart`, `note_editor_toolbar.dart`.

- [x] *(2026-11-14 P20 adım 1: tablo Ek A "F64.1 haritası".)* **F64.1 Kök kurulum haritası.** Faz 59 düzeneğiyle 25 kullanıcı eylemi için kök
  kurulum sayısı ve (profil derlemesinde) kök `build` süresi: işaretle, madde ekle/sil,
  sürükle-sırala, biçim uygula, renk, sabitle, yıldız, etiket ekle/sil, klasör, hatırlatıcı,
  ek ekle/sil/görünüm değiştir, kalem kipi aç/kapa, arama aç/kapa, sayfa değiştir, geri al.
  Tabloyu Ek A'ya ekle. En pahalı 5 eylem bu fazın kapsamıdır; gerisi dokunulmaz.
- [x] *(2026-11-14 P20 adım 3: `note_slice.dart` + `_noteN` (`LateSafeValue`) + `_undoN`; S1 kök 1→0.)* **F64.2 Mekanizma (davranış değişmez).** `_note` alanı `ValueNotifier<Note?> _noteN`
  üzerinden (`Note? get _note => _noteN.value`). Yeni dosya `editor/note_slice.dart`:

  ```dart
  /// [source]'tan [select] ile seçilen dilim değişince yalnız bu alt ağaç kurulur.
  class NoteSlice<T> extends StatefulWidget {
    const NoteSlice({super.key, required this.source, required this.select,
        required this.builder, this.equals});
    final ValueListenable<Note?> source;
    final T Function(Note note) select;
    final bool Function(T a, T b)? equals; // null → ==
    final Widget Function(BuildContext context, T value) builder;
    // State: source'u dinler; select sonucu değişmediyse setState YOK.
  }
  ```

  Test: dilim dışı alan değişince `builder` çağrılmaz; kaynak değişince abonelik taşınır.
- [ ] *(2026-11-14 P20: kısmi — bölge ÇIKARILMADI (plan M2); yıldız/iğne dilim, biçim kipi notifier ile kaynağında kesildi: S14 1→0, S9 2→0.)* **F64.3 Bölge çıkarma (eylem başına bir commit, F64.1 sırasıyla).** Her bölge kendi
  dosyasında `StatelessWidget`/`ConsumerWidget`; State'e erişimi yalnız açık parametreler ve
  geri çağrılar (uzantı tear-off TUZAĞI: geri çağrı sınıf yöntemi olmalı). Aday bölgeler:
  üst çubuk, çip şeridi, tuval (gövde + maddeler + yüzen ekler), sabit bölme, alt çubuk.
  Her çıkarmadan sonra: bütçe testi, `note_accent_consistency_test`,
  `note_everywhere_same_test`, `editor_open_at_test`, `editor_pen_tablet_test`, ekran turu
  `TOUR_COMPARE` (%0 fark), cihazda `ab_klavye.py`.
- [ ] *(2026-11-14 P20 M6: `_sameVisual` SİLİNMEDİ, daraldı (pinned/starred çıktı, 34→32 terim, bekçi mandallı) — sabah bakılacak.)* **F64.4 `_mutate` kök `setState`'i bırakır.** Bölgeler dilimle dinlediği için
  `_sameVisual` ve `sameRenderedNote` SİLİNİR (akış yankısı da `_noteN.value = …` yapar;
  dilimi değişmeyen bölge kurulmaz). `sameItemsVisually` `ItemsEditor` diliminin `equals`'ı
  olarak kalır. CLAUDE.md kasma listesinin 1. maddesi "yeni madde alanı → `sameItemsVisually`
  + satır önbelleği anahtarı"na iner.
- [x] *(2026-11-14 P20 adım 6: kural `docs/hafiza/editor.md` (M7: CLAUDE.md'ye değil — sabah bakılacak), bekçi `test/editor_core_guard_test.dart` (`_update(` ≤ 32).)* **F64.5 Kural.** CLAUDE.md'ye: "Editöre yeni görünür parça = yeni bölge widget'ı;
  `_NoteEditorScreenState`'e alan/`_update` eklenmez" + bekçi testi: `note_editor_*.dart`
  içindeki `_update(` sayısı bugünkünü (31) geçemez.
- Kabul: Ek A S3/S4/S9/S14 hedefte; `_sameVisual` yok; cihaz A/B'de hiçbir evre kötüleşmedi.

---

## FAZ 65 — Ekler: yerleşim, çubuklar, yükleme güvenilirliği

**Önce oku:** `editor/pinned_media_pane.dart`, `editor/pinned_side.dart`,
`editor/view_mode_switch.dart`, `editor/attachment_actions.dart` (`attachmentActionsFor`),
`editor/attachment_status.dart`, `data/upload_queue.dart`, `data/drive_store.dart`,
tur görüntüleri `*-e-*.png`.

- [x] **F65.1 Bölme çubuğu sadeleşmesi — KARAR K-O6** *(2026-11-13 P49: dar çubuk (< 600 dp) ⛶ · [oynatma] · tutamak · Not al · ✏ · ⋮; anahtar, balon, yer imi, PDF ve ek işleri TEK ⋮ levhasında; geniş çubukta anahtar/balon/yer imi çubukta da. Bekçi `pinned_bar_redesign_test` (360/393 dp × 1,3 taşmaz) — G4 kapandı. Önce/sonra tur görüntüsü çekilmedi (bulut); cihazda doğrulanmadı.)* **— (§0 "Yanlış gidenler" madde 6).** Bugün
  telefonda sabit PDF çubuğu: ⛶ · ✏ · • · Not al · T · balon+ · [Sabit|Yüzen|Ek] · bağlantı
  · ⋮ (10 denetim, hepsi simge). Öneri: ⛶ · tutamak · **birincil iş** (PDF: "Not al";
  görsel: "T"; video: "Not al") · ✏ · ⋮. ⋮ levhasının başında görünüm anahtarı (anahtar
  KALIR, eşanlamlı madde yok — TUTARLILIK K6 korunur), altında balon, bağlantı, yer imi,
  döndür, paylaş (`attachmentActionsFor` sırası). ≥ 600 dp'de bugünkü geniş çubuk kalabilir.
  Önce/sonra tur görüntüsü kullanıcıya gösterilir. `G4` (≤ 360 dp taşma) bununla kapanır.
- [x] **F65.2 Yatayda yandan sabitleme varsayılanı — KARAR K-O7.** *(2026-11-13 P49, K-O7 kullanıcı kararı "tablette/webde yanda": `PinnedSideMemory.preferred` — tercih yazılmamışsa ve pencere ≥ 840 dp + yataysa sol; seçim bir kez yapılınca hep o. Bekçi `pinned_side_layout_test`. Tablette doğrulanmadı.)* `PinnedSideMemory`
  hiç yazılmamışsa ve pencere ≥ 840 dp + yataysa `side = start`. 1024×640 dp'de (gerçek
  tablet) üstte sabit ek + 3 çubuk + klavye içerik bırakmıyor (F67.4 ile birlikte ölç).
- [ ] **F65.3 Birden çok sabit ek — KARAR K-O8.** *(2026-11-13 P49: en güvenli = tek sabit ek, dokunulmadı — sabah bakılacak.)*
- [x] **F65.4 Yükleme güvenilirliği (B13) — KARAR K-O9.** *(2026-11-11: K-O9 en güvenli = bildirim, sabah bakılacak. Kanıt `test/attachment_status_test.dart` kırmızı (bekleyen ekte düğme yok, `pendingUploadNotice` yok) → yeşil. `ReminderService` `AppLifecycleListener`: arka plana geçerken bekleyen ek varsa (Drive bağlantısı beklemiyorsa) 15 dk sonra sessiz tek bildirim (`upload` kanalı, yük `upload`), dönünce/kuyruk boşalınca iptal; bekleyen ek rozetinde "Şimdi dene" → `retryNow`. Cihazda doğrulanmadı.)* Öneri (bağımlılıksız): uygulama
  `paused` olurken kuyrukta bekleyen ek varsa `ReminderService` üzerinden 15 dk sonrasına
  sessiz tek bildirim ("N ek yüklenmeyi bekliyor — açınca yüklenir", yük `upload:` — `note:`
  ile BAŞLAMAZ); uygulama açılınca/kuyruk boşalınca iptal. Ayrıca not ekranında ekin durum
  rozeti (`attachmentStatusOf`) "bekliyor"ken dokununca "şimdi dene".
- [x] **F65.5 PDF ilk sayfa önizlemesi buluta.** *(2026-11-11: kanıt `test/pdf_cloud_thumb_test.dart` kırmızı (dosyasız PDF kartı önizleme çizmiyor, `wantsCloudThumb` yok) → yeşil. Drive yüklemesinde PDF'in ilk sayfası `pdfFirstPageThumb` (320 px JPEG, ≤ 40 KB) → `thumbs/{ekId}.jpg` → `thumbUrl`; kart `_PdfFirstPage` dosya yokken onu çizer. Storage kuralı ve boyut sınırı testi zaten var (`rules-test/rules.test.js` thumbs: 41 KB ve `application/pdf` reddi) — yeni kural testi gerekmedi. Gerçek PDF çizimi (pdfium) cihazda doğrulanmadı.)* Görseldeki `thumbs/{ekId}.jpg` (≤ 40 KB)
  yolu PDF için de: yüklemede `pdf_page_render.dart` ile ilk sayfa → JPEG → aynı yol →
  `thumbUrl`. Web ve diğer cihaz kartında/yer tutucusunda indirmeden görünür. Storage
  kuralı zaten `thumbs` için var; `rules-test`'e PDF önizleme boyut sınırı testi.
- [ ] **F65.6 Web'de ek görünmüyor / paylaşılan notta ek (KALEM K7).** Kod tek başına
  yetmiyor (HAFIZA "Web Drive": kök doğrulanmadı). Kullanıcıdan: web'de eki açmayı dene,
  çıkan SNACKBAR metnini yaz (`web-drive-connect` / `web-drive-fetch`). Sonra: Firestore
  REST ile o ekin `driveId` / `downloadUrl` / `thumbUrl` alanlarına bak (yöntem HAFIZA "Ek
  senkronu — TEK YOL" sonu). Paylaşılan notta yükleme yolu (`_isShared` → Storage,
  `_processForeign`) testle izlenir. Kök bulunmadan düzeltme yazılmaz.
- [x] **F65.7 Ek ekleme sonrası tek soru.** *(2026-11-11: kanıt `test/view_mode_switch_test.dart` "F65.7" kırmızı (ipucu uzun, kalkmayan bölümde kaldırılmış "Balonlu" anlatıyordu) → yeşil. İpucu tek satır "Yüzen olarak eklendi · değiştirmek için anahtara dokun", 4 sn sonra boşalır (yer ağaçta kalır), nabızlı anahtar aynı. **Sabah bakılacak:** tür bazlı varsayılan (PDF/video/sunum → Sabit) UYGULANMADI — bugün PDF/sunum alt şeride, video sayfaya iniyor; değiştirmek davranış değişikliği (madde "davranış aynı" diyor, çelişki) ve tek sabit ek kuralıyla (K-O8) çakışır → en güvenli: bugünkü varsayılan. Cihazda doğrulanmadı.)* "Nerede dursun?" ipucu (Sabit · Yüzen · Ek)
  bugün nabızlı anahtar + satır. Ek türüne göre varsayılan: PDF/video/sunum → Sabit,
  görsel → Yüzen, diğer dosya → Ek; ipucu yalnız varsayılan DEĞİŞTİRİLEBİLİR diye 4 sn
  görünür ("Sabitlendi · Değiştir"). KARAR gerekmez (davranış aynı, soru kısalır) —
  kullanıcı "her seferinde sorsun" derse bugünkü kalır.
- Kabul: telefonda sabit ekli notta toplam düğme ≤ 14 (bugün ~21); tur önce/sonra dosyada.

---

## FAZ 66 — Telefon: ana ekran ve not ekranı yoğunluğu

**Önce oku:** `dashboard_screen.dart` 1560–1700 (sabit başlık yığını), `home_calendar_strip`
(Grep `HomeCalendarStrip`), `note_card.dart` (madde önizlemesi), `card_preview.dart`,
tur `telefon-*.png`.

- [~] **F66.1 Ana ekran tepesi (B9) — KARAR K-O10.** *(2026-11-14 P22: DENEYIM planıyla kapandı/taşındı (KUYRUK §P22 "P22 ATLAR", Ek D).)* Öneri: en kısa kenar < 600 dp'de
  `homeCalendarStripOpenProvider` varsayılanı KAPALI (tek ince satır: bugünün tarihi +
  varsa etkinlik sayısı; dokununca açılır; kullanıcının seçimi hatırlanır). Zamanı gelen
  şeridi kalır (önemli). Hedef: ilk nota kadar ≤ 150 dp (bugün ~210).
  *Yapma:* şeritleri yükseklik animasyonuyla gizleme (CLAUDE.md kural 6).
- [~] **F66.2 Alt çubuk (K-O5, F63.5 ile aynı karar).** *(2026-11-14 P22: DENEYIM planıyla kapandı/taşındı (KUYRUK §P22 "P22 ATLAR", Ek D).)*
- [~] **F66.3 Kartta işaretli maddeler — KARAR K-O11.** *(2026-11-14 P22: DENEYIM planıyla kapandı/taşındı (KUYRUK §P22 "P22 ATLAR", Ek D).)* `card_preview.dart`: işaretsiz
  madde varsa önce onlar; işaretliler tek satır "✓ N tamamlandı". Hepsi işaretliyse
  bugünkü. Dilim sınırı (5 satır) değişmez; akıcılık bütçesi (F21) bağlayıcı.
- [~] **F66.4 Küçük telefon turu.** *(2026-11-14 P22: DENEYIM planıyla kapandı/taşındı (KUYRUK §P22 "P22 ATLAR", Ek D).)* Tur boyutlarına `telefon-kucuk 360×640` ve
  `telefon-uzun 393×851` (F67.2 ile birlikte). Taşan/kesilen her yer madde olarak yazılır
  ve düzeltilir (ad kesilmesi, çubuk taşması, levha boyu).
- [x] **F66.5 Tek elle erişim taraması.** *(2026-11-14 P22 rapor — RAPOR_F66_5 aşağıda; kod değişmedi.)* Sık işler (yeni not, ara, klasör değiştir, geri)
  alt yarıda mı: not ekranında "+" (üst sağ) yerine alt çubuktaki "+" yeterli mi — yalnız
  rapor; değişiklik KARAR.
  *RAPOR_F66_5 (2026-11-14, koddan):* (1) Yeni not: ana ekranda "+" (`QuickAddFab`) ve mikrofon SAĞ ALTTA — tek elle erişilir. (2) Not ekranında üst sağdaki "+" YENİ NOT DEĞİL, not bilgisi menüsü (`note-meta-chip`: klasör/etiket/başlık) — sık değil, üstte kalabilir; yeni not için ayrı düğme gerekmez. (3) Ara: ana ekranda arama kutusu üstte; alt yarıda kısayol yok (not içinde Ara alt çubukta, P57'de taşınabilir). (4) Klasör değiştir: üstteki çip şeridi + SAĞA kaydırma takvim (sola kaydırma yok, #108). (5) Geri: sistem jesti/tuşu. ÖNERİ (KARAR, uygulanmadı — sabah bakılacak): ana ekranda arama için alta kısayol (ör. "+" menüsüne "Ara") istenirse ayrı iş.
- [x] **F66.6 Boş / hata / çevrimdışı hâlleri.** *(2026-11-12 → DENEYIM F79.6, P40.)* Çevrimdışıyken not ekranı bulut simgesi,
  bekleyen ek, AI düğmeleri ne gösteriyor; uçak kipinde widget testiyle 6 ekran görüntüsü
  (tura `TOUR_OFFLINE=1`). Tutarsızlıklar madde olur.
- Kabul: `telefon-ana.png` önce/sonra; ilk not ≤ 150 dp'de başlıyor; 360×640'ta taşma yok.

---

## FAZ 67 — Tablet ve geniş ekran

**Önce oku:** `app/split_shell.dart`, `app/app_frame.dart`, `editor/pinned_side.dart`,
`editor/editor_quick_row.dart` (`KeyboardSwitch`), tur `tablet-*.png`, HAFIZA "Geniş ekran".

- [x] **F67.1 Pencere sınıfı tek yerde (B11).** `lib/app/window_class.dart`:
  **Yapıldı (2026-11-11, P07):** `lib/app/window_class.dart` (`WindowClass`, `compactDevice` = dokunmatik + en kısa kenar < 600; 5 adlı sabit taşındı, eski dosyalar yeniden dışa veriyor). Çevrilen: editor_quick_row, items_editor, pen_tray.useRail, dashboard arama, share_target, login, note_open_route, `splitActiveFor(Size)`. Kutu ölçen `ai_hub` 920 / `calendar_views` 900 / pen_tray dok 640 dokunulmadı. Bekçi + denklik testi `test/window_class_guard_test.dart` (bekçi yalnız shortestSide KARŞILAŞTIRMASI; note_themes ölçek hesabı serbest).

  ```dart
  enum WindowWidth { compact /* <600 */, medium /* 600–839 */, expanded /* 840–1199 */, large /* ≥1200 */ }
  enum WindowHeight { short /* <480 */, regular /* 480–899 */, tall /* ≥900 */ }

  class WindowClass {
    const WindowClass(this.width, this.height, this.touchFirst);
    final WindowWidth width; final WindowHeight height;
    /// Web'de false (fare/klavye öncelikli), Android'de true.
    final bool touchFirst;
    static WindowClass of(BuildContext context); // MediaQuery.sizeOf + kIsWeb
    static WindowClass fromSize(Size size, {required bool web}); // saf, testli
  }
  ```

  Mevcut adlı sabitler (`kSplitBreakpoint` 840, `kNoteSplitBreakpoint` 640,
  `kPortraitListBreakpoint` 960, `kPinnedSideMinWidth` 840, `kReadingWidth` 760) KALIR ve
  bu dosyaya taşınır. `shortestSide >= 600` ve çıplak `width >= 600/840/900` karşılaştırmaları
  (12 yer) `WindowClass`'a çevrilir; bileşen İÇİ sığdırma eşikleri (340, 400, 430, 520 —
  bir kutunun kendi genişliği) dokunulmaz. Bekçi `test/window_class_guard_test.dart`: `lib`
  içinde `shortestSide` yalnız `window_class.dart`'ta geçer.
  *Tuzak:* test yüzeyi 800×600 tablet sayılır; davranış değişmemeli — her çevirmede eski
  koşulla yeni koşulun aynı pencere kümesini verdiğini birim testiyle göster.
- [x] **F67.2 Tur gerçek cihaz boyutlarıyla (B12).** `tool/tour/screen_tour_test.dart`
  `_sizes`'a: `matepad-yatay 1024×640`, `matepad-dikey 640×1024`, `telefon-kucuk 360×640`,
  `telefon-uzun 393×851`. Klavyeli hâl: `TOUR_KEYBOARD=300` → `viewInsets.bottom`. Çıkan
  görüntülerde taşma/sıkışma madde olarak listelenir.
  **Yapıldı (2026-11-11, P07):** 5 boyut (+`telefon-yatay 851×393`), `TOUR_KEYBOARD`, `TOUR_SIZES` süzgeci. ana/n1/n4/e-pdf-sabit 5 boyutta + telefon-yatay klavyeli (220): taşma istisnası YOK. Göze çarpan: telefon-yatay+klavye'de yazı alanı ~70 dp (üst çubuk + hızlı satır) → F67.4 kapsamı; telefon-yatay ana ekranda takvim + zamanı gelen şeridi ~130 dp yiyor.
- [x] **F67.3 Bölünmüş görünümde liste bölmesi (B15).** *(2026-11-12, P18: `kNarrowListPane` < 420 dp → takvim/zamanı gelen şeridi Offstage, arama hapında AI+süz ⋮ levhasına, mikrofon gizli. Yapılmadı: "+" liste başlığına taşınmadı (sabah bakılacak). Tablette doğrulanmadı.)* Liste bölmesi < 420 dp iken:
  takvim şeridi ve zamanı gelen şeridi çizilmez (tam ekran listede durur), arama hapı
  kısalır (AI hapı ve süz ⋮'e iner), "+"/mikrofon yüzen düğmeleri yerine liste başlığında
  tek "+" (rayın çekmece olduğu durumda). Ağaç şekli sabit kalsın (`Offstage`/koşullu
  sliver, State korunur — HAFIZA "Tek liste örneği").
- [x] **F67.4 Yatay + klavye yükseklik bütçesi.** *(2026-11-12, P18: `ShortKeyboardBarHide` alt çubuğu kararlı klavye boşluğuyla tek adımda gizler (Offstage), sabit medya en küçük, pencere < 480 dp üst çubuk 40 dp; tur matepad-yatay+klavye300 yazı alanı 73 → 197 dp. ≥ 873 dp pencerede bağlanmıyor (S17 bütçesi). Tablette doğrulanmadı.)* 1024×640 dp, klavye 300 dp: görünür
  içerik ≥ 200 dp olmalı. Bugünkü kesintiler: üst çubuk 48 + hızlı satır + alt çubuk 50 +
  (sabit ek çubuğu 40). `WindowHeight.short` (klavye sonrası kalan < 480) iken: alt çubuk
  gizli (hızlı satır yeter), üst çubuk 40 dp, sabit bölme en küçük boyda. Boy değişimi TEK
  ADIMDA (kural 6), `KeyboardSwitch` kuralı (7) korunur. Tur `matepad-yatay` + klavye ile
  doğrula.
- [x] **F67.5 Yandan sabitleme varsayılanı (F65.2 ile aynı karar).** *(2026-11-13: F65.2 ile yapıldı.)*
- [ ] **F67.6 İki not yan yana — KARAR K-O12 (öneri: şimdilik yok).** *(2026-11-14 P22: karar 2026-11-12 VERİLDİ ("tablet yatayda iki not yan yana OLSUN"); P22'de yazılmadı — büyük tablet düzeni işi, ayrı paket gerekir → açık kod işi.)*
- [x] **F67.7 Klavye ve fare.** → DENEYIM F80.3 (P42, 2026-11-12: kısayol levhası tablodan, odak halkası, D22; sağ tık/üstüne gelme doğrulandı). Kısayol listesi levhası (Ctrl+/; `app.dart` `shortcuts`
  haritasından üretilir, elle liste tutulmaz); kart ve madde üzerinde sağ tık = uzun basış
  menüsü (var olanları doğrula, eksikleri ekle); fareyle üstüne gelince kart ve satır
  vurgusu (yalnız `touchFirst == false`); Tab sırası: arama → klasör şeridi → kartlar.
- [ ] **F67.8 Tablet cihaz turu.** *(2026-11-14 P22: açık, yapılamaz — kullanıcı tableti; docs/cihaz_turu.md B; kullanıcı listesine.)* `docs/cihaz_turu.md` tablet bölümü (yatay/dikey, klavye
  takılı/değil, kalem): bölünmüş görünüm, ayraç, tam ekran, yandan sabit, hızlı satır,
  fiziksel klavye uykusu (HAFIZA oturum J). Kullanıcı yapar.
- Kabul: tur yeni 4 boyutta taşmasız; bekçi yeşil; 1024×640 + klavyede içerik ≥ 200 dp.

---

## FAZ 68 — Liste ve senkron yükü

**Önce oku:** `notes_providers.dart` (`filteredNotesProvider`, `sortHeldNoteIdsProvider`,
`openNoteIdsProvider`), `dashboard_screen.dart` `build`, `dashboard_slivers.dart`,
`AKICILIK_PLANI.md` Faz 21–22, `tool/perf/prof_save.py`, `ab_liste.py`.

- [x] **F68.1 Açık notun kartı yazarken beklesin (B8).** *(2026-11-12, P19: `heldNotePreviewProvider` (kimlik → değişiklik öncesi örnek, editörün `_mutate`'inden; 3 sn tek seferlik `Timer`, kapanışta/anında kayıtta bırakılır) → `filteredNotesProvider` tutulan örneği verir. S12 kırmızı 1/13 → yazarken+kayıt 0/0, durunca pano 1 / kart 1. Eski "13 kart" ölçüm artığıydı: kayıt notu "Bugün" bölümüne taşıyıp ızgarayı yeniden diziyordu (düzenek artık hepsi bugün). Cihazda doğrulanmadı.)* Bölünmüş görünümde liste
  görünürken, editörü açık ve son 3 sn içinde değişmiş notun listeye giden örneği TUTULUR
  (sıralama tutmasının içerik karşılığı: `heldNotePreviewProvider`, not kimliği → tutulan
  örnek). Yazma 3 sn durunca ya da not kapanınca bırakılır (tek seferlik `Timer`; editörün
  `_noteTyping` sinyalinden). Tutulan örnek aynı olduğu için `filteredNotesProvider`
  `StableBox` ile önceki listeyi döner → pano kurulmaz.
  *Tuzak:* tutulan örnek YALNIZ listeye gider; depoya/editöre/hatırlatıcı servisine değil
  (HAFIZA `home_snapshot` tuzağıyla aynı sınıf).
  *Kabul:* S12 (yazarken `DashboardScreen` kurulumu 0; durunca ≤ 1 kart).
- [ ] **F68.2 Pano gövdesini böl (ölçüm kapılı).** *(2026-11-12, P19 — KISMEN, sabah bakılacak: cihazsız kanıtı üretilen tek boşa kurulum düzeltildi — açık nottan başka nota geçişte `DashboardPaneScope` çapa notu değişince bütün pano kuruluyordu (yeni bütçe S12b: pano 1 / hücre 13 → 0 / 0; çapa artık bildirim sebebi değil). Gövdeyi üçe bölme YAZILMADI — üretilemedi: S12/S12b'de girdisi değişmeyen pano kurulumu kalmadı; yatay bölünmüşte not aç/kapa sütun sayısını değiştiriyor (meşru yeniden dizim), kapı koşulu "tablette kapanış karesi > 33 ms" cihaz ölçümü ister. Cihazda `ab_klavye.py` tablet evresi > 33 ms verirse bölme ayrı iş.)* F68.1'den sonra tablette not kapanış
  karesi hâlâ > 33 ms ise: `dashboard_screen.dart` `build`'in üç parçası ayrı widget:
  başlık yığını, klasör şeridi, ızgara. Her biri kendi `ref.watch` kümesiyle. Izgara girdisi
  (sıralı kimlikler + sütun sayısı) değişmedikçe `sliverBalancedNoteColumns` ve
  `dateBuckets` yeniden hesaplanmaz (girdi kaydıyla not).
- [ ] **F68.3 Liste akışının maliyeti — KARAR K-O13 (AKICILIK F22.4).** *(2026-11-13 P55: YAPILAMADI — ölçüm kullanıcının GERÇEK hesabında ister; ölçüm uygulaması ayrı Firebase projesinde, varsayılan kimlikli uygulamaya dokunulmaz. K-O13 en güvenli seçenek uygulandı: hiçbir şey yapılmadı. Sabah bakılacak: kullanıcı kendi telefonunda `prof_save.py`'yi gerçek hesapla koşturmalı)* Önce KULLANICININ
  GERÇEK hesabında (ölçüm veri seti değil) `prof_save.py`: not sayısı, olay boyutu (KB),
  kayıt sonrası Dart bloğu (ms). ≤ 12 ms → kapat. > 12 ms → "yakın/eski" bölmesi tasarımı
  ayrı madde olarak yazılır (iki sorgu: `updatedAt ≥ T` ve `< T`; birleşimde 500 ms
  "kaybolan not" tamponu; `updatedAt`'siz belge denetimi; bileşik dizin). Kart dizini göçü
  (F22.4-B) yalnız o da yetmezse.
- [ ] **F68.4 Kaydırma kabulü (AKICILIK Faz 21 kalanı).** `ab_liste.py` ile bugünkü
  takılma oranı; hedef < %2 (eski hedef < %1 Adreno ≤ 650 + GLES'te gerçekçi değil —
  K7). Kalan engel kart raster'ıysa: kart içi `ClipRRect`/gölge/gradyan sayımı
  (`debugDumpLayerTree` ile kart başına katman), fazlasını `DecoratedBox`'a indir.
  **Ölçüm (2026-11-13, P43, `ab_hepsi.py` `liste` evresi = `ab_liste.py`'nin aynı 8 fırlatması, 9 geçerli koşu):** > 16 ms UI karesi 9c837495'te 5–12 / 305 (%1,6–3,9, ortanca %2,6–3,0), P39 (02ebd989) 10/305 (%3,3), en uzun 22–37 ms → **hedef < %2 TUTMADI.** Kart raster/katman düzeltmesi P46'da (F84 "ölçümün bulduğu yavaşlıklar").
- [~] **F68.5 Açılış (park).** *(2026-11-14 P22: park — kod işi yok, kalan süre motor + Activity.)* 780 ms'nin kalanı motor + Activity; kod işi yok.
- Kabul: tablette yazarken kayıt anında > 33 ms kare yok (`ab_klavye.py` tablet evresi).

---

## FAZ 69 — Doğrulama turu ve kapanış

- [ ] **F69.1 Cihaz turu.** *(2026-11-14 P22: açık, yapılamaz — kullanıcı; docs/cihaz_turu.md; kullanıcı listesine.)* `docs/cihaz_turu.md` telefon + tablet + web (kullanıcı; ~30 dk
  cihaz başına). Bulunan her sorun `F60.S` biçiminde maddeye, kök nedenli düzeltmeye.
- [ ] **F69.2 Yeni cihaza geçiş (YORUM F54.4).** *(2026-11-14 P22: açık, yapılamaz — kullanıcı; temiz kurulum + geri yükleme; kullanıcı listesine.)* Temiz kurulum → giriş → bütün notlar, el
  yazısı (v1 ve v2), ekler, klasörler, takvim geliyor mu; tam yedek → boş hesaba geri yükle.
- [x] **F69.3 Hatırlatıcı güvenilirliği (YORUM F56.2).** *(2026-11-14 P22: Ayarlar → İzinler'e "Alarmlar ve hatırlatıcılar" satırı — YALNIZ tam zamanlı alarm izni kapalıyken (`canScheduleExactNotifications`), dokununca sistem izin ekranı (`permissions_service.dart`, `settings_account.dart`). Pil muafiyeti okunamıyor (önceki karar), satır her zaman duruyor. "İlk hatırlatıcıda ipucu" YAZILMADI: ayar satırı + MIUI ipucu yeterli sayıldı — sabah bakılacak. Yazıldı, cihazda doğrulanmadı: KALANLAR P22.2.)* Pil iyileştirme açık / tam zamanlı
  alarm izni yokken Ayarlar → İzinler'de uyarı satırı + ilk hatırlatıcıda ipucu (MIUI
  otomatik başlatma satırı var; aynı yere). Telefonda: uygulama kapalı, 10 dk sonraya
  hatırlatıcı, ekran kapalı → çalıyor mu.
- [ ] **F69.4 Kullanıcı konsol işleri (tek liste).** KALAN_ISLER F19.A1, A2, A4, A5, B1–B4,
  B10 (Calendar API), KALANLAR J0 (masaüstü OAuth istemcisi), F61.7 bayrakları.
- [ ] **F69.5 Kapanış.** Bütçe tablosu Ek A'da "hedef" = `budgets.json`; eski planlarda
  buraya taşınan maddelere "→ OTURTMA F6x.y" notu; `KALANLAR.md` sadeleşir; HAFIZA konu
  dosyaları güncel; sürüm notu; dondurma (K-O1) kalkar, `ISTEK_KUTUSU.md` kullanıcıyla
  önceliklendirilir.

---

## Kullanıcı listesinden eklenen maddeler (2026-11-09)

Numaralar ait oldukları fazı gösterir; o fazın "Önce oku" listesi geçerlidir.

- [x] **F65.8 [Opus] Sabit PDF: klasik sürekli dikey kaydırma.** Kullanıcı: "sayfa sayfa
  değil; bütün sayfalar alt alta, yalnız kaydırıyoruz. Sağa-sola kaydırmayı kaldır. Alt
  paneldeki sayfa sayısı yazılarını kaldır; sayfanın sağ altında ufak yazsın, görsel
  dilimize uygun." Uygulama: sabit bölmede tek sayfalık `PdfPageBox` + dikey çekişle
  geçiş (`_onPageScroll`, KALEM K1) yerine sayfaları TEMBEL kuran dikey liste
  (`ListView.builder`; sayfa başına bugünkü sayfa kutusu — mürekkep, seçim, balon
  katmanları sayfa başına aynen, `pdfLayerParams` sayfa başına aynı örnek). Genişliğe
  oturur; yüksekliği bilinmeyen sayfa ilk sayfanın oranıyla yer tutar. Yana kaydırarak
  sayfa çevirme ve bölme çubuğundaki `‹ n/N ›` KALKAR (`PdfBoxBar` köprüsünden çıkar).
  Sayfa göstergesi: bölmenin sağ altında küçük hap ("12 / 240"; `AppTokens` kart rengi +
  ince çizgi, 11–12 pt), kaydırırken tam, 2 sn sonra soluk (yalnız boyama — `Opacity`
  katmanı yerine renk alfası). `Attachment.pdfPage` = görünür alanın ortasındaki sayfa
  (kaydırma DURUNCA yazılır, her karede değil); tam ekran `initialPage`, `📖 s.N` atlaması
  ve yer imi `jumpTo` ile. Kalem kuralı korunur (kalem yazar, parmak kaydırır:
  `dragDevices`). Görünür ±2 sayfa dışındaki sayfa görüntüleri bırakılır (F65.9 için şart).
  Yakınlaştırma ilk sürümde çift dokunuş 2,5× (o sayfa) + iki parmak; kaydırma kilidi
  kuralı aynı. KALEM_PLANI K1'deki "dipte çekince sonraki sayfa" bununla geçersiz olur
  (oraya not düş). Kabul: 300 sayfalık PDF'te fırlatma akıcı (> 33 ms kare < %2), bellek
  sabit; `ink_editing_guard_test` yeşil; tur görüntüsü önce/sonra.
  **2026-11-10:** `PdfPageColumn` (tembel dikey liste, 300 sayfada canlı sayfa ≤ 5), ‹ n/N › → sağ alt `PdfPagePill`, `pdfPage` kaydırma durunca; yana/dipte çekişle çevirme kalktı (bekçi `test/pdf_page_column_test.dart`). Cihazda doğrulanmadı — A/B yürütücüde (tur görüntüsü de).
  Cihaz A/B (2026-11-10, `ab_klavye.py`, taban 39fc2567, 3'er koşu, ölçüm Sonnet alt ajanında): klavye kapa ortanca 183 → 185 ms, aç 280 → 276 ms; yazma düşük kip 471–558 → 551–588 ms (gürültü bandında), yüksek kip 966 → 986 — regresyon yok. PDF kaydırma cihazda DENENMEDİ (ölçüm verisinde PDF'li not yok): 300 sayfa fırlatma/bellek kabulü cihaz turuna kaldı.
- [ ] **F65.9 [Opus] Büyük dosyalar yerelde açılsın (500 MB–1 GB PDF).** Kullanıcı:
  "tabletimde radyoloji PDF'lerim var, açamıyorum; illa Drive'a yüklemek istiyor ya da
  sınır var deyip hiç açmıyor. Yedek zorunlu olmasın, ek menüsünden seçilsin; ama açılmalı,
  üzerine not alayım." Hedef: **boyut sınırı AÇMAYI asla engellemez.**
  (1) Sınırı bul: `Grep "MB\|maxBytes\|tooLarge\|kMax\|sizeLimit"` → `attachment_repository.dart`,
  `upload_queue.dart`, `drive_store.dart`, dosya ekleme akışı (`showFileUseSheet`,
  `useFiles`). Eklemeyi reddeden her yer "yerelde tut" yoluna düşer.
  (2) Model: `Attachment.localOnly` (bool; yalnız true yazılır; `knownKeys` +
  `forward_compat_test`). Yükleme kuyruğu bu eki ATLAR; durum rozeti "yalnız bu cihazda"
  (`attachmentStatusOf`); ek menüsünde "Buluta yedekle" ⇄ "Yalnız bu cihazda tut"
  (`attachmentActionsFor` + `AttachmentAction`). > 100 MB ek varsayılan `localOnly` + bir
  kez bilgi; Drive/Storage sınırını aşan ekte "yedekle" pasif ve nedeni yazılı.
  (3) Dosya — **KARAR K-O15:** **uygulama deposuna AKIŞLA kopyala** (belleğe okumadan,
  ilerleme göstergeli; depolama 2×) / kalıcı URI izniyle yerinde aç (yer kazanır; dosya
  taşınırsa kopar; yerel kod ister). En güvenli: kopyala. Yer yoksa anlaşılır hata.
  (4) Açılış: PDF dosya YOLUNDAN açılır; baytları belleğe alan her yol (`readAsBytes`,
  `openData`) büyük dosyada dosya yoluna çevrilir. OCR, metin dizini
  (`attachment_text_<uid>.json`), önizleme ve kart küçük resmi büyük dosyada tembel ve
  sayfa bazlı (bütün belgeyi gezme yok).
  (5) Başka cihaz/web: "bu ek yalnız <cihaz adı>nda" yer tutucusu; indirme denenmez.
  (6) Tam yedek `localOnly` ekleri varsayılan DIŞARIDA bırakır (seçenekle dahil), geri
  yüklemede yer tutucu.
  Kabul (tablette, 1 GB PDF): eklenir, ilk sayfa ≤ 10 sn'de görünür, RAM artışı < 300 MB,
  kalemle yazılır + "Not al" çalışır, uygulamayı kapat-aç sonrası yerinde; yükleme kuyruğu
  denemez. 1 GB'lık sentetik PDF'i test için betikle üret (kişisel dosya açma).
  **2026-11-11 (P08, gözetimsiz):** K-O15 "en güvenli" uygulandı — **sabah bakılacak**. Kanıt: `preparePdf` `bytes.length > maxBytes`te `FileTooLargeException` atıyor, `_addPdfFile` önce `readAsBytes` (tüm dosya RAM'e). Düzeltme: tavanı aşan PDF `prepareLocalPdf` ile `copyFileStreamed` (akış, yüzde şeritte) → `Attachment.localOnly` (`skipsUpload` → kuyruk/yükleme atlar, kota sayılmaz); seçici önbellek kopyası silinir; yer yoksa `DeviceFullException`; `readBytes` localOnly'de `FileTooLargeException` (AI/paylaşım/kopya RAM'e almasın); durum `deviceOnly`/`otherDevice` (başka cihaz/web yer tutucu, indirme yok). Tam yedek zaten > 60 MB eki atlıyor (6 kendiliğinden). Bekçi `test/large_local_pdf_test.dart` + forward_compat + attachment_status. **Yapılmadı:** ek menüsünde "Buluta yedekle ⇄ Yalnız bu cihazda" geçişi, OCR/metin dizini tembelliği, tablette 1 GB kabul ölçümü (cihazda doğrulanmadı — KALANLAR §2).
- [x] **F66.7 [Opus] Telefon yatay: yerleşim bozuk.** Kullanıcı (ekran görüntülü): "yan
  çevirince ekran yerleşimi yapılamamış, tamamen bozuk." Kök (B11): genişlik eşikleri
  yatay telefonu (≈ 851×393 dp) tablet sayıyor — `splitActiveFor(width ≥ 640)` 393 dp
  yükseklikte bölünmüş görünüm açıyor. Düzelt: F67.1 `WindowClass` CİHAZ sınıfını EN KISA
  KENARLA verir (< 600 = telefon, yatayda da): bölünme yok, ray yok; `WindowHeight.short`
  iken üst çubuk 40 dp, alt çubuk yazarken gizli, sabit ek YANDA (yükseklik kısıtlı),
  ana ekran 3–4 sütun, başlık yığını tek satır arama + klasör şeridi (takvim şeridi ve
  zamanı gelen şeridi kapalı). Tur boyutu `telefon-yatay 851×393` (+ `TOUR_KEYBOARD=220`).
  Kabul: tur görüntülerinde taşma/üst üste binme yok; `wide_screen_*` testleri
  telefon-yatay için "bölünme yok" der; cihazda döndür → not aç → yaz → kapat.
  **Kısmen (2026-11-11, P07):** kök düzeldi — telefon cihazı yatayda bölünmüyor (`splitActiveFor` + not açılış hareketi aynı kural), kalem tepsisi yatay telefonda sütun değil alt dok; ray zaten yükseklik < 500'de yoktu. Döndürmede aynı örnek kaldığı için sütun değişince kaydırma ORANI yeniden uygulanıyor (`wide_screen_doors` F18.11 testi bu yüzden kırmızıya düştü → yeşil). YAPILMADI (sabah bakılacak): kısa yükseklikte üst çubuk 40 dp, yazarken alt çubuk gizleme, sabit ek yanda, takvim/zamanı gelen şeridi kapalı (F67.4 ve K-O10 ile birlikte; kural 6/7 gereği cihaz A/B ister). Cihazda döndür→aç→yaz→kapat doğrulanmadı.
- [x] **F67.9 [Opus] "Not menüsü sağa alınabilsin (tablette)".** *(2026-11-12, P18, en olası anlam — sabah bakılacak: `listPaneRightProvider` (`list_pane_right`), SplitShell Row `textDirection` ters, ayraçta uzun bas/sağ tık menüsü + Ayarlar → Görünüm; ray yerinde kaldı. Tablette doğrulanmadı.)* Anlam belirsiz. Gözetimsiz
  oturumda yalnız EN OLASI anlam yapılır: **not listesi bölmesi sağa alınabilsin**
  (`SplitShell`: cihaz tercihi `list_pane_side`; ayraçta uzun bas → "Listeyi sağa / sola
  al" + Ayarlar → Görünüm; ray da aynı tarafa; menteşe ve "çekerek tam ekran" yönü
  aynalanır). Diğer olası anlam (editörün alt çubuğu/araç menüsü sağ kenarda dikey şerit)
  kullanıcıya SORULUR — "sabah bakılacak".

---

## FAZ 70 — Yazım düzeltici v2 (baştan) [Opus]

Kullanıcı (2026-11-09): "Düzeltilmişi değiştiriyorum, ısrarla kendi düzelttiğine getiriyor
kelimeyi yine. Yazım düzelticiyi baştan yazdır." Bugünkü yapı sezgi üstüne sezgi:
`core/utils/spell_fix.dart` (kurallar), `spell_learn.dart` (967 satır: sözlük, öğrenme,
karışıklık, reddetme, unlearn), `auto_spell.dart` (508 satır: alan bağlama + karar).

**Önce oku:** bu üç dosya, `spell_learned_screen.dart`, testleri (`Grep "spell" test/`),
HAFIZA'da "Yazım" geçen maddeler (oturum C, D, E, F, J).

**İlkeler (v2'nin sözleşmesi):**
1. **Kullanıcının düzeltmesi kutsaldır.** Otomatik düzeltilmiş bir kelimeyi kullanıcı
   değiştirirse o (yazılan → düzeltilen) çifti ANINDA ve kalıcı olarak reddedilir (ilk
   seferde; "N kez sonra" yok) ve o kelime o notta bir daha otomatik düzeltilmez.
2. **Emin değilsen dokunma.** Otomatik DEĞİŞTİRME yalnız: açık kurallar (`herşey` → `her
   şey` gibi tablo), kullanıcının öğrettiği/onayladığı düzeltmeler, ve tek adaylı +
   yüksek güvenli durumlar. Gerisi değiştirmez (en fazla altı noktalı öneri — KARAR;
   en güvenli: öneri de yok).
3. **Her otomatik düzeltme tek Backspace ile geri alınır** (özgün yazı döner + çift
   reddedilir).
4. **Tek saf karar motoru.** `SpellEngine.decide(SpellInput) → SpellDecision` (yok /
   değiştir(yeni, neden) / öner). `auto_spell.dart` yalnız alan olayını motora taşır ve
   kararı uygular; içinde kural YOK. Motor tablo güdümlü testlerle sabitlenir.
5. Türkçe ek tuzağı (aday yazılanın ön eki/uzantısıysa dokunma), başlık kipi, yapıştırma
   ve dikteye dokunmama, Çince'de bulanık eşleşme yok — bugünkü kurallar motorun açık
   girdileri olarak korunur.

- [x] **F70.0 Israrı üret.** Bugünkü kodla kırmızı test: otomatik düzeltme A → B; kullanıcı
  B'yi C yapar; sonra A yeniden yazılır → beklenen: B'ye DÖNMEZ. Hangi yol geri
  getiriyor (öğrenilmiş düzeltme `suggest`, cihaz denetçisi `_nativeSplit`/ilk öneri,
  `replacedWord` öğrenmesi, bulanık eşleşme) maddeye yaz. — **[x] 2026-11-11:** kırmızı üretildi (`test/spell_engine_test.dart` "F70.0 ısrar"). Geri getiren yol: bulanık `SpellMemory.nearest` ("kalen" → "kalem") her seferinde aynı aday; öğrenme yalnız SON biten kelimeyi ve yalnız silmeyle izliyordu — bir kelime sonra düzeltme ya da tek adımda (klavye önerisi) değiştirme reddi tetiklemiyordu, `replacedWord` bilinen kelimede null.
- [x] **F70.1 Sözleşme testleri.** `test/spell_engine_test.dart`: KALANLAR'daki bütün
  örnekler (C3, D1, D2, F7, J9: "herşey ", "yaoçoılıyor ", "eksiknyapılıyor ", "kalemi"
  ↔ "kalemde", "bakım togg", ☐ yapıştırma) + ilke 1–3 senaryoları + "bilinen kelimeye
  dokunma" + "3 kez görülmeden bilinen sayma". Testler önce yazılır. — **[x] 2026-11-11:** `test/spell_engine_test.dart` (31 test: KALANLAR örnekleri, ilke 1–3, bilinen/3 kez, iki aday, kipler, göç, ayarlar ekranı) yeşil.
- [x] **F70.2 Motor.** `lib/core/utils/spell_engine.dart` (saf): girdiler (kelime, önceki
  kelime, kip, dil, kişisel sözlük görünümü, öğrenilmişler, reddedilenler, bu notta
  dokunulmazlar). Mesafe işlevi `spell_learn.dart`'tan taşınır (klavye ağırlıklı
  Damerau–Levenshtein — yeniden yazma). Güven eşiği tek yerde sabit. — **[x] 2026-11-11:** `spell_engine.dart` (`SpellEngine.decide`, mesafe taşındı, eşik `confidenceMargin` = 0,3). "Öner" kararı yok (KARAR en güvenli, sabah bakılacak); "önceki kelime" girdisi kullanılmadı.
- [x] **F70.3 Bağlama.** `auto_spell.dart` inceltilir: kelime bitişi algılama, kararı
  uygulama, Backspace-geri-al penceresi, "kullanıcı değiştirdi" algısı (düzeltmeden
  sonraki ilk düzenleme o kelimenin aralığına değerse). Editör kasma kuralları: kök
  `setState` yok, satır önbelleği etkilenmez. — **[x] 2026-11-11:** `auto_spell.dart` yalnız bağlama: son 30 biten kelime izlenir (`_track/_settle`), değişen otomatik düzeltme ilk seferde reddedilir + o notta `_noteKeep` (`beginNote`), Backspace geri al (`_Undo`). Kök `setState` yok. Değiştirilen düzeltmenin yerine yazılan kelime onaylı öğrenilir (öbür notlarda uygulanır — sabah bakılacak).
- [x] **F70.4 Hafıza göçü.** `spell_memory.json` v1 → v2: öğrenilmiş düzeltmeler ve
  reddedilenler taşınır; taşınamayan sezgisel kayıtlar (karışıklık ağırlıkları) atılır.
  Eski dosya `.v1` adıyla bir sürüm boyunca saklanır. — **[x] 2026-11-11:** `SpellMemory.decode` v1 → v2 (en güçlü doğru + sayı, "r" → `keep`, "c" atılır); dosya `spell_memory.json.v1` yedeklenir, web'de `spell_memory_v2` anahtarı. `.v1` yedeğini silen kod sonraki sürümde.
- [x] **F70.5 Ayarlar.** "Öğrenilen yazımlar" ekranı v2 verisini gösterir: düzeltmeler,
  reddedilenler (geri alınabilir), "otomatik düzelt" aç/kapa + "yalnız kurallar" kipi. — **[x] 2026-11-11:** Öğrenilen yazımlar: otomatik düzelt + "yalnız kurallar" anahtarları, düzeltmeler, reddedilen çiftler ve dokunulmaz kelimeler (çip silinince yeniden açılır).
- [x] **F70.6 Eski kodu sil.** Kullanılmayan sezgiler ve testleri kalkar; `dart analyze` temiz. — **[x] 2026-11-11:** harf karışıklıkları, `alignSubstitutions`, `_nativeSplit`, v1 `suggest` ve `spell_learn_test.dart` silindi; tam `flutter analyze` temiz.
- Kabul: F70.0 testi yeşil; sözleşme testlerinin tamamı yeşil; yazarken kök kurulum
  bütçesi (Ek A S1/S2) değişmedi; regresyon listesine "ısrar" satırı.

---

## FAZ 71 — Güvenlik denetimi ve altyapısı [Fable]

Savunma amaçlı, kendi uygulamamızın denetimi. Çıktı: `docs/guvenlik_denetimi.md` (bulgu ·
kanıt (dosya:satır) · önem · düzeltme · durum) + kalıcı CI kapıları. Kritik/yüksek
bulgular aynı fazda düzeltilir (kural + test); orta/düşük listelenir. Davranış değiştiren
düzeltme KARAR'dır; gözetimsiz oturumda yalnız rapor + kırmayan sıkılaştırma yapılır.

**Önce oku:** `firestore.rules`, `storage.rules`, `rules-test/`, `android/app/src/**/AndroidManifest.xml`,
`.github/workflows/*.yml`, `web/_headers`, `web/index.html`, `core/app_update.dart`,
`auth/data/*` (jeton deposu, `loopback_oauth.dart`), `MainActivity` ve `src/kisisel`.

- [x] **F71.1 Tehdit modeli (1 sayfa `docs/guvenlik.md`).** Varlıklar: notlar, ekler,
  Drive/Gmail/Takvim jetonları, Gemini anahtarı, imza anahtarı. Saldırganlar: başka
  hesap, paylaşım ortağı, cihazı eline geçiren, kötü niyetli dosya/bağlantı/paylaşım,
  tedarik zinciri (paket, CI action).
  → **Sonuç (2026-11-11):** `docs/guvenlik.md` (varlık, saldırgan, savunma, kalan risk tabloları).
- [x] **F71.2 Firestore / Storage kuralları.** Her `match` için kim-okur/kim-yazar matrisi
  ve `rules-test` karşılığı. Özellikle: `userDirectory/{email}` ve `userSearch` ile
  kullanıcı numaralandırma; `noteShares` / `folderShares` rol yükseltme ve kendi rolünü
  değiştirme; `inboxNotes` ve `friendRequests` spam (boyut/sıklık sınırı); `config/*`
  yazımı; alt koleksiyonlar (`heavy`, `versions`, `presence`, F61 `ink`); 'write' rolünün
  `createdBy` kuralı; alan doğrulaması (tür, boyut) eksikleri; Storage'da yol başına
  boyut ve içerik türü, `thumbs` tavanı (HAFIZA: kurallar OR'lanır tuzağı).
  → **Sonuç (2026-11-11):** matris + 12 yeni kural testi (`rules-test`, 26/26). 5 bulgu düzeltildi: e-posta dizini ele geçirme (YÜKSEK), arama dizini / arkadaşlık isteğinde sahte e-posta, üyenin klasörü yeniden adlandırması, tavanlar. Açık: gelen kutusu hız sınırı, presence/versions doğrulaması (G-13, G-16).
- [x] **F71.3 Sırlar ve CI.** Depo GEÇMİŞİNDE anahtar taraması (gitleaks; `env.json`,
  keystore, servis hesabı, jeton). APK'ya gömülen değerler (`GOOGLE_DESKTOP_CLIENT_SECRET`
  dart-define → düz metin; masaüstü istemci sırrı gizli sayılmaz, kapsam ve onay ekranı
  kısıtlarıyla belgelensin). İş akışları: `permissions:` en az yetki, `pull_request_target`
  yok, secret log'a basılmıyor, üçüncü taraf action'lar commit SHA'sına sabit, Release
  yazma yetkisi yalnız gereken işte.
  → **Sonuç (2026-11-11):** geçmişte sır yok (elle desen taraması; kalıcısı CI gitleaks). İş akışı: üst düzey `contents: read`, 4 üçüncü taraf action SHA'ya sabit. Masaüstü istemci sırrı belgelendi (G-10). Açık: sırların betiğe gömülme biçimi, sürümsüz `npx firebase-tools` (G-19, yalnız main adımları).
- [x] **F71.4 Android yüzeyi.** `exported` bileşenler; derin bağlantı `notlar://note/<id>`
  ve bildirim/widget/kısayol açılışı uygulama kilidi ile not kilidini ATLAYABİLİYOR mu;
  paylaşım alıcısı (dosya adıyla yol geçişi, boyut, tür); kişisel köprü izni
  (`signature|knownSigner`); FileProvider yol kapsamı; uygulama içi güncelleme (APK yalnız
  kendi Release adresinden mi; kurulumdan önce paket adı + imza
  `getPackageArchiveInfo` ile doğrulanıyor mu); `allowBackup` / `dataExtractionRules`;
  jeton deposu (şifreli, uid'e bağlı); `FLAG_SECURE`; `url_launcher` şema süzgeci.
  → **Sonuç (2026-11-11):** dışa açık bileşenler, FileProvider, `allowBackup`, köprü izni, güncelleme (imzayı Android zorlar), jeton deposu incelendi — kritik yok. Bağlantı açıcıya şema süzgeci eklendi. Cihazda denenmedi (derin bağlantı + uygulama kilidi, `FLAG_SECURE`).
- [x] **F71.5 Web yüzeyi.** `web/_headers` (CSP, `X-Frame-Options`, `Referrer-Policy`);
  `sessionStorage` jetonu; güvenilmeyen HTML basılan yerler (Gmail ileti gövdesi, YouTube
  iframe, bağlantı önizlemesi); App Check durumu; açık yönlendirme.
  → **Sonuç (2026-11-11):** `frame-ancestors` + `X-Frame-Options` eklendi (yayında doğrulanmadı). Tam CSP açık (G-12, deneme gerek). App Check zorlaması konsolda doğrulanmalı (kullanıcı işi).
- [x] **F71.6 Uygulama içi veri yolları.** Kilitli not / gizli klasör / parola notu şu
  yollardan sızıyor mu: arama, kart önizlemesi, `home_snapshot`, widget, bildirim metni,
  AppFunctions (`Ajan.kt`), AI bağlamı ("Tüm notlar" sohbeti, ilgili notlar, günlük
  brifing), paylaşım, yedek, `ErrorLog`/Crashlytics. İçe aktarma: zip slip, zip bombası,
  dosya sayısı/boyut tavanı (`.notyedek`, Keep Takeout, `.enex`), güvenilmeyen PDF/PPTX.
  Yedek dosyası şifresiz — uyarı ya da parola seçeneği KARAR.
  → **Sonuç (2026-11-11):** kilitli notun hatırlatıcı BİLDİRİMİ başlık + gövde sızdırıyordu → düzeltildi (G-26). Diğer yollar gizli. Yol geçişi tek noktada kesili; zip bombası açık (G-21). **Yedek şifresiz — KARAR, sabah bakılacak** (G-11). `ErrorLog` incelenmedi.
- [x] **F71.7 Bağımlılıklar.** `dart pub outdated`, `osv-scanner` (pubspec.lock,
  `functions/`, `rules-test/`), `npm audit`. Bilinen açıklı sürüm → yükseltme maddesi
  (FlutterFire paketleri BİRLİKTE yükseltilir kuralı).
  → **Sonuç (2026-11-11):** `npm audit` (rules-test: 29, yalnız test aracı), `pub outdated` 131 eski paket; osv eşlemesi yerelde yapılamadı → CI `guvenlik` işi. Yükseltme yapılmadı.
- [x] **F71.8 Kalıcı altyapı.** CI'da: gitleaks + osv-scanner (kırmızı = uyarı, engel
  değil) + kural testi kapsam özeti. `SECURITY.md`. Bekçi testleri: manifestlerde yeni
  `android:exported="true"` listesi sabit (yeni girdi testi kırar); `firestore.rules`'ta
  koşulsuz `allow … if true` deseni yok; F71.6'daki her sızıntı yolu için "kilitli not
  görünmez" testi.
  → **Sonuç (2026-11-11):** CI `guvenlik` işi (gitleaks + osv-scanner, uyarı düzeyi), `rules-test/kapsam.js` (33/43 koşul), `SECURITY.md`, `test/security_guard_test.dart` (13 bekçi).
- Kabul: rapor dosyada; kritik/yüksek bulgu 0 açık (ya da KARAR bekliyor diye işaretli);
  CI'da üç yeni kapı çalışıyor; `rules-test` yeşil.

---

## Yapılmayacaklar (alt modele not: bunlara girme)

- Durum yönetimi kitaplığı değiştirmek (Riverpod kalır), `ItemsEditor`'ı ya da metin
  sarma motorunu baştan yazmak, Skia'ya dönmek, satırlara/kartlara `RepaintBoundary`
  serpmek, `cacheExtent`/zamanlayıcı/"ilk N öğe" hileleri (AKICILIK "Yapılmayacaklar").
- Listede olmayan yeni paket eklemek. Bu planın izin verdiği tek yerel bağımlılık adayı
  K-O14 (`core-splashscreen`), o da KARAR'lı.
- `dart format lib`, tam test takımını yerelde koşmak, CI kırmızıyken birleştirmek.
- Bir maddenin kanıtını üretmeden "düzeldi" yazmak; ölçmeden "hızlandı" yazmak.
- Faz 61'de yedek almadan göç; `heavy/data`'yı v2 yazımı doğrulanmadan boşaltmak.

---

## Ek A — Bütçe senaryoları (F59.2)

"Bugün" sütunu F59.2'de ölçüldü (2026-11-11, `budgets.json` ile aynı). "Hedef" ilgili faz bitince `budgets.json`'a işlenir.

| # | Senaryo (telefon 400×800 aksi yazmıyorsa) | Sayılan | Bugün | Hedef | Faz |
|---|---|---|---|---|---|
| S1 | Kısa metin notu, gövdeye 20 karakter | kök `NoteEditorScreen` kurulumu | 1 (kayıt 1) | ≤ 1 (geri al düğmesi) | — |
| S2 | 30 maddeli liste, bir maddeye 20 karakter | `ItemsEditor` kurulumu / yeniden kurulan satır | 5 / 15 | 0 / 0 | — |
| S3 | 30 maddeli liste, bir kutucuğu işaretle | kök kurulum / kurulan satır | 1 / 13 | ≤ 1 / ≤ 2 | 64 |
| S4 | Maddede Enter (yeni madde) | kök kurulum / kurulan satır | 1 / 14 | ≤ 1 / ≤ 2 | 64 |
| S5 | Kalem kipi, sayfaya 10 çizgi | kök kurulum / `updateNote` | 0 / 1 | ≤ 1 / ≤ 1 | — |
| S6 | Sabit PDF'e 10 çizgi | kök kurulum / `updateNote` | 10 / 10 → **1 / 1** (F60.1, 2026-11-09) | ≤ 1 / ≤ 1 | 60.1 |
| S7 | Gömülü PDF'e 10 çizgi | aynı | 10 / 10 → **1 / 1** (F60.1, 2026-11-09) | ≤ 1 / ≤ 1 | 60.1 |
| S8 | Klavye aç/kapa ×3 (inset kareleri) | gövde kurulumu | kısa not 0; 30 maddede ilk açılış 15 + oturma 3, sonraki turlar 0 | 0 | — |
| S9 | Biçim panelini aç → kapat | tuval kurulumu / gövde boyunun değiştiği kare | 2 / 2 (2026-11-13, P46; önce 34) | 0 / 2 | 64 |
| S10 | Paketi aç → maddeye odaklan → Biçim'e dokun | paket açık mı / mount edilen `TextField` | F60.2 (`note_package_open_test`) | açık / ≤ üye sayısı | 60.2 |
| S11 | Kendi kaydının akış yankısı | kök kurulum | 0 | 0 | — |
| S12 | 1280×800 bölünmüş: açık nota 20 karakter + kayıt | `DashboardScreen` kurulumu / kurulan `NoteCard` | 1 / 13 → **0 / 0** yazarken+kayıt; durunca 1 / 1 (F68.1, 2026-11-12) | 0 / ≤ 1 | 68.1 |
| S12b | 1280×800 bölünmüş: açık nottan başka nota geç (içerik aynı) | `DashboardScreen` / hücre / `NoteCard` | 1 / 13 / 2 → **0 / 0 / 2** (F68.2, 2026-11-12) | 0 / 0 / ≤ 2 | 68.2 |
| S13 | Ana ekran, 300 not, 3 ekran kaydır | kurulan `NoteCard` | 24 (300 notun) | ≤ görünür + önbellek | — |
| S14 | Sabitle / yıldızla | tuval kurulumu | 1 (yıldız) | 0 | 64 |
| S15 | 2000 çizgi varken etkin çizgiye 1 nokta | çizim çağrısı (`TestRecordingCanvas`) | 2001 | ≤ 8 | 62.1 |
| S16 | 2000 çizgi varken 1 çizgi ekle + kaydet | yazılan belge / bayt | 2 / 448 925 bayt | 1 / ≤ 64 KB | 61.6 |
| S17 | Klavye aç/kapa ×3, 18 karelik hareket (`keyboard_jank_guard_test`): metin / sabit PDF / **sabit görsel** (P43, 2026-11-12) | kare başına kurulum / editör içi / dizilen sınır | sabit görsel: ilk 63 / geçiş 240 / hareket 59 (editör içi 12) / 2 sınır | editör içi ≤ 7, dizilen 0 | P49 |
| S18 | Telefon 412×915, 30 not: karttan not aç (`NoteOpenPage`), 40 kare | `NoteCard` / `DashboardScreen` / ilk kare / sonraki en ağır kare | 2 / 0 / 876 / 285 (2026-11-13, P46; önce 877 / 788) | ≤ 1 / 0 / — / editör ikinci kez kurulmaz | 84 |
| S19 | S18'in devamı: sistem geri ile ana ekrana dön | `NoteCard` / `DashboardScreen` / en ağır kare | 2 / 0 / 523 | ≤ 1 / 0 | 84 |
| S20 | 30 maddeli not: ⋮ levhası aç → kapat | editör gövdesi kurulumu | 0 | 0 | — |
| S21 | Telefon, 60 not (18 görünür): arama kutusuna 5 harf | harf başına `NoteCard` / pano | 56 / 6 (2026-11-13, P46; önce 114) | ≤ görünür | 84 |
| S22 | Takvim haftalık, 21 etkinlik: bir hafta ileri fırlat | `WeekPage` / toplam / tek kare | 1 / 509 / 508 (2026-11-13, P46; önce 3 / 979 / 978) | yalnız gelen sayfa | 84 |
| S23 | Ana ekran, `swipe_mode=filters`: yana fırlat → sonraki süzgeç → geri | `NoteCard` ileri / geri / pano / en ağır kare | 30 / 30 / 1 / 2361 (2026-11-13, P46; önce 2941) | görünür kadar | 84 |
| S24 | Soğuk açılış (30 not) | kurulum: ilk kare / kartlara dek / 2 sn | 930 / 4019 / 4031 | taban (mandal) | — |
| S25 | Görselli 50 not, dpr 2,625, 6 ekran kaydır | çözme boyu sınırsız küçük resim | 0 (2026-11-13, P46; önce 21) | 0 | 84 |
| S26 | 1280×800 bölünmüş, nottan listeye dön | DashboardScreen / NoteCard kurulumu | 1 / 14 (2026-11-14, P59) | ≤ 1 / ≤ 14 | — |

### F64.1 haritası (2026-11-14, P20 adım 1; `test/editor_rebuild_map_test.dart`, eylem + 3 sn)

Sütunlar: `NoteEditorScreen` (kök) / `NotePageCanvas` (tuval) / `ItemsEditor` / `_LazyItemField` (satır).

| Eylem | Kök / tuval / liste / satır | Kaynak (P20 planı) |
|---|---|---|
| İlk değişiklik (gövdeye 1 harf) | 1 / 1 / 0 / 0 | M3: `canUndo` false→true |
| İşaretle (30 madde, 8. kutucuk) | 1 / 1 / 1 / 23 | M1: satır anahtarında sıra no |
| Madde ekle (Enter) | 1 / 1 / 1 / 23 | M1 |
| Sabitle (üst çubuk iğnesi) | 1 / 1 / 0 / 0 | M4: `_sameVisual` pinned |
| Yıldız (⋮ hızlı satır) | 1 / 1 / 0 / 0 | M4: `_sameVisual` starred |
| Biçim paneli aç → kapat | 2 / 2 / 0 / 0 | M5: `_formatBarOpen` kök `setState` |
| Maddeye 20 harf (S2, bütçeden) | — / — / 5 / 15 | kapsam dışı (P22 listesine) |
| Arama aç (alt çubuk) | 1 / 1 / 0 / 0 | dokunulmaz (Faz 64 ilk 5 dışı) |
| Geri al (metin değişikliği) | 0 / 0 / 0 / 0 | **bulgu:** kök kurulmuyor → yinele düğmesi `onPressed: null` kalıyor (bayat); adım 3 `_undoN` çözer |
| Yinele | ölçülemedi: düğme etkinleşmedi (yukarıdaki bulgu) | adım 3 |
| Madde sil, sürükle-sırala, kalın, renk, etiket, klasör, hatırlatıcı, ek ekle/sil/görünüm, kalem kipi, sayfa değiştir | üretilmedi: levha/seçici/dosya düzeneği gerekir; M1–M5 öngörüsüne girdi değil | — |

## Ek B — Mürekkep paketi biçimi (F61.1)

Küçük uçlu (little-endian). `varuint` = LEB128; `zigzag` = `(n << 1) ^ (n >> 63)` sonra LEB128.
Koordinat birimi `kInkUnit = 1/16384` (sayfa genişliği oranı; 760 dp sayfada 0,046 dp).

```
Başlık : 0x49 0x4B ('IK') · sürüm u8 = 1 · çizgiSayısı varuint
Çizgi  : bayrak u8        bit0 = ok (arrow), bit1 = basınç var
         sayfa  varuint   (1 tabanlı)
         renk   u32       (ARGB)
         kalınlık f32     (sayfa genişliği oranı)
         z      f64       (çizim sırası)
         n      varuint   (nokta sayısı)
         x0 zigzag · y0 zigzag                (round(değer / kInkUnit))
         (n−1) × [dx zigzag · dy zigzag]      (bir önceki noktaya fark)
         bayrak bit1 ise: n × u8              (round(basınç × 255))
```

Belge: `notes/{noteId}/ink/{yüzey}~{sayfa}~{bant}` → `{ v: 1, b: Blob(paket), n: çizgiSayısı }`.
Okumada bilinmeyen `v` olan belge atlanır ve `ErrorLog`'a yazılır (çökme yok, üstüne
yazılmaz: o yüzey salt okunur açılır).

## Ek C — Cihaz ve pencere boyutları (dp)

| Ad | Boyut | Sınıf (F67.1) | Not |
|---|---|---|---|
| Mi Note 10 Lite (test telefonu) | 393×851 | compact / regular | Adreno 618, GLES |
| Küçük telefon | 360×640 | compact / regular | tur |
| MatePad 11 dikey | 640×1024 | medium / tall | bölünme sınırı tam 640 |
| MatePad 11 yatay | 1024×640 | expanded / regular (klavyeyle short) | GMS'siz, M-Pencil |
| Tur: tablet | 800×1280 / 1280×800 | medium / expanded | bugünkü tur |
| Tur: masaüstü | 1440×900 | large / tall | web |
