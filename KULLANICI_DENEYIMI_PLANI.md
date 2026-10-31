# KULLANICI DENEYİMİ PLANI — Faz 10–17

Kaynak: 2026-10-30 baştan sona inceleme (kod DEĞİŞTİRİLMEDİ). Amaç: her
özelliği tek tek gözden geçirmek, iyi ve kötü yanını yazmak, ne yapılacağını
fazlara bölmek. Faz 1–4 `YOL_HARITASI.md`'de, Faz 5–9
`PERFORMANS_TOPARLAMA_PLANI.md`'de (hepsi bitti); numaralar çakışmasın diye bu
plan **Faz 10**'dan başlar.

**Öncelik sırası (kullanıcı, 2026-10-30):**
**Ö1** kullanıcı deneyimi, görsel güzellik, rahat ve kasmayan akış, "bu ne?"
dedirten şey olmaması · **Ö2** performans ve doğru çalışma · **Ö3**
erişilebilirlik · **Ö4** anlaşılırlık · **Ö5** görsel bütünlük, tekrar
olmaması · **Ö6** tek ekranda ya da alanda çok ve etkili işlev.

Faz sırası bu önceliklerle aynı değil: **Faz 10 kırık ve yanıltıcı olanları**
kapatır (kısa sürer ve diğer bütün işlerin önünü açar), sonra Ö1 (Faz 11–13),
Ö4 (14), Ö3 (15), Ö5 (16), ölçüm ve cihaz turu (17). Ö6 ayrı bir faz değil,
Faz 11–13'ün içinde "birleştir, bağlama göre göster" maddeleri olarak duruyor:
yeni düğme eklemek yerine var olanları toplamak.

## İnceleme nasıl yapıldı

- **Web sürümü gerçekten kullanıldı** (notlar-web.pages.dev, v1.1.547 =
  `main` 9142cab): 412×915 (telefon) ve 1280×800 (geniş ekran), Playwright ile;
  Flutter'ın semantik ağacı açılıp her ekrandaki düğmelerin adı, rolü ve boyutu
  okundu. Geçici bir misafir hesap açıldı; iş bitince uygulamanın kendi
  "Hesabımı ve verilerimi sil" yoluyla silindi.
- **Kod okundu**: 361 dosya / ~135 bin satır; her alanın sunum katmanı ve
  kılavuz (`assets/guide/guide_tr.md`), HAFIZA, KALANLAR karşılaştırıldı.
- **Ölçüm (bulut, Flutter 3.47.7):** `flutter analyze` temiz ·
  `flutter test -j 4` **1730/1730**, 1 dk 52 sn · web soğuk açılış ilk kare
  ~2,6 sn, ~1,6 MB.
- Yalnız Android'de olanlar (kamera, tarama, QR, dikte, ses kaydı, widget,
  kalem, Antalia) bu oturumda **çalıştırılamadı** — tabloda **C** ile işaretli,
  değerlendirmeleri koddan.

**Kanıt etiketleri:** **W** = web sürümünde denendi/görüldü · **K** = koddan
doğrulandı (dosya:satır verilir) · **K✓** = küçük bir deneme testiyle doğrulandı
· **C** = cihazda doğrulanmalı.
**Değerlendirme:** 🟢 iyi (küçük cila) · 🟡 orta (belirgin sorun var) ·
🔴 kötü (kırık ya da yanıltıcı).

## Bu dosya nasıl kullanılır (her faz oturumu için)

Kullanıcı "Faz N'i yap" dediğinde (N = 10…17):

1. Bu dosyayı ve HAFIZA.md'yi oku. Yalnız **Faz N** maddeleri yapılır; bir
   sonraki faza kendiliğinden geçilmez.
2. Satır numaraları 2026-10-30 hâlidir, kayabilir: önce `grep` ile yeri bul,
   bulguyu koddan (gerekirse web'de) yeniden DOĞRULA. Bulgu artık geçersizse
   `GEÇERSİZ: neden` yaz.
3. **KARAR GEREKİR** etiketli maddede önce kullanıcıya kısa öneri sun, onay al.
   Kullanıcının daha önce verdiği bir kararı (HAFIZA'da "kullanıcı kararı")
   değiştiren her madde KARAR GEREKİR sayılır.
4. Her madde: değişiklik + mümkünse test (kırmızıdan yeşile). Arayüz
   maddelerinde "önce/sonra" ekran görüntüsü (web'de Playwright, bkz. **Ek A**)
   commit mesajında ya da faz notunda anlatılır. Faz sonunda `flutter analyze`
   temiz ve `flutter test -j 4` tamamen yeşil olmadan "bitti" denmez.
5. Faz bitince: maddeleri `[x]` yap, altına 1-2 satır **Yapıldı:** (ne, hangi
   dosya); yapılamayanı `ERTELENDİ: neden`; **Durum** tablosunu güncelle;
   kalıcı karar/kök neden/tuzak → HAFIZA.md (tarihli); cihazda bakılacaklar →
   KALANLAR.md; kılavuz etkileniyorsa `assets/guide/guide_tr.md` + `_en.md`;
   commit + push.
6. "Senin yapacakların" kullanıcının cihaz/konsol işidir; oturum yalnız
   hatırlatır.
7. `dart format` YALNIZ değiştirdiğin dosyaya. Kişiselleştirme kimlikleri
   (`UiItem.*`) kalıcı tercih anahtarıdır — düğme taşırken kimliği değiştirme.
   Metin değişikliği hem `app_tr.arb` hem `app_en.arb`'de, ardından
   `flutter gen-l10n` + `dart format lib/l10n/generated`.

**Flutter (bulut):** CLAUDE.md'deki gibi 3.47.7'yi scratchpad'e indir. Kök
kullanıcıyla `git` "dubious ownership" verirse:
`GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=safe.directory GIT_CONFIG_VALUE_0='*'`.

## Durum

| Faz | Konu | Öncelik | Durum | Tarih | Not |
|---|---|---|---|---|---|
| 10 | Kırık ve yanıltıcı olanlar | Ö2 · Ö4 | Bitti | 2026-10-31 | 7/7; 1750/1750 test; F10.7 kök neden koddan (web'de yeniden denenmedi); cihaz turu KALANLAR'da |
| 11 | Ana ekran ve "+" akışı | Ö1 · Ö6 | Bitti | 2026-10-31 | 9/9 (3 KARAR: önerilenler onaylandı); 1755/1755 test; web önce/sonra görüntüsü ALINMADI (canlı Firebase'de misafir hesap açmamak için) — cihaz/web turu KALANLAR'da |
| 12 | Not ekranı: çubuklar, ⋮, biçim, liste | Ö1 · Ö5 · Ö6 | Bitti | 2026-10-31 | 9/9 (F12.7 düğme gizleme yerine ipucu adı — 3 boş madde kararı korundu); 2 KARAR (palet üst çubukta; iki düğme + Diğer); ek istek: "Gelen" çipi Tümü'nün yanında; 1758/1758 test; web görüntüsü ALINMADI |
| 13 | Balonlu mod, medya, kalem, paylaşım akışı | Ö1 · Ö2 | Bekliyor | | Balon yazısı paylaşılamıyor |
| 14 | Anlaşılırlık: adlar, ayarlar, kılavuz, ipuçları | Ö4 | Bekliyor | | Kılavuz eskimiş |
| 15 | Erişilebilirlik | Ö3 | Bekliyor | | Yazı boyutu kararı |
| 16 | Görsel bütünlük ve tekrar temizliği | Ö5 | Bekliyor | | Simge ve levha dili |
| 17 | Ölçüm, uçtan uca test, cihaz turu | Ö2 | Bekliyor | | |

## Özet — en önemli bulgular

| # | Bulgu | Kanıt | Önem | Madde |
|---|---|---|---|---|
| 1 | **Web'de PDF eklenemiyor**: "+ → Dosya ekle → PDF → Belge gibi not al" → "Ek eklenemedi: Unsupported operation: RawReceivePort", not boş kalıyor. `Isolate.run` web'de yok; aynı yol sayfa sil/sırala/döndür ve Balonlu PDF dışa aktarmayı da kırıyor | W, K | **YÜKSEK** | F10.1 |
| 2 | **Çok sayfalı not eksik paylaşılıyor/kopyalanıyor**: `noteShareText` yalnız ETKİN sayfayı yazıyor; kılavuz "bütün sayfalar" diyor | K✓ | **YÜKSEK** | F10.2 |
| 3 | **Balonların yazısı hiçbir metin paylaşımına girmiyor**, balon kopyalanamıyor; tek yol balonları PDF'e basmak (web'de 1 yüzünden kırık) | K | **YÜKSEK** | F13.1 |
| 4 | Not ekranının ⋮ düğmesinin adı yanlış ("Etiket · Başlık · Alarm") — başlığın yanındaki "+" ile aynı; ekran okuyucu iki düğmeyi aynı adla okuyor | W, K | ORTA | F10.3 |
| 5 | ~80 yerde ham istisna metni kullanıcıya gösteriliyor (`aiError('$e')`, `genericError('$e')`) | W, K | ORTA | F10.4 |
| 6 | Misafir hesapta AI ekranları "30/30 puan" gösterip dokununca hata veriyor; Kişiler/Ortak çalışanlar/Kopya gönder görünür ama işlemez | W, K | ORTA | F10.5 |
| 7 | Kullanım kılavuzu en az 10 yerde uygulamayla çelişiyor (16 dil, alt çubukta asistan mikrofonu, + menüsü kapıları, "eski yıldızlılar sabitli", hızlı not satırı…) | W, K | ORTA | F14.5 |
| 8 | Aynı yere çok kapı: hesap/kişiler/gelen 4 giriş; "Kişiselleştir" Ayarlar'da iki kez; "Yeni hatırlatıcı" iki düğme; "Kopya gönder" başlığı altında "Kopya gönder" | W | ORTA | F11.1, F14.2 |
| 9 | Simge çakışmaları: Arşiv ↔ Gelen kutusu neredeyse aynı simge; Defter ve Not paketi arşiv kutusu simgesi | W, K | ORTA | F16.1 |
| 10 | Erişilebilirlik: sistem yazı boyutu ezilmiş (kullanıcı kararı), 239 özel jest / 26 semantik etiket, 48 dp altı hedefler, hareketi azalt yok sayılıyor | W, K | ORTA | Faz 15 |

Toplam **120 satır** (108 özellik + 12 genel konu) değerlendirildi: 🔴 11 · 🟡 42 · 🟢 67.

---

## Özellik envanteri ve değerlendirme

Her satır: ne iyi, ne kötü, ne yapılmalı, hangi fazda. Sorun sütunu boşsa
özellik iyi durumda, yalnız cihaz turunda bakılır.

### A. Açılış, giriş, hesap

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| A1 | Web açılış ekranı | 🟡 | Soğuk açılış ~2,6 sn, 1,6 MB (W) | HTML açılışı ("Notlar · hazırlanıyor…") ile Flutter'ın ilk ekranı ("Notes · Your notes…") üst üste biniyor; simgeler kaymış, iki dil aynı anda (W) | Tek açılış: HTML katmanı Flutter'ın ilk anlamlı karesine kadar kalsın, Flutter tarafı ayrıca logo çizmesin; dil tarayıcıya göre | 10 |
| A2 | Giriş ekranı | 🟢 | Sade, tek birincil düğme, "Hesapsız devam et" açık; geniş ekranda vitrin (W) | Misafir açıklaması "dahili yapay zekâ kapalı olur" diyor, misafir oturumunda AI "30/30" görünüyor (bkz. M1) | Metin ve davranış aynı şeyi söylesin | 10 |
| A3 | Misafir uyarı kartı (ana ekran) | 🟡 | Riski açıkça söylüyor, tek dokunuşla Google girişi (W) | 138 px, ekranın ~%15'i, her açılışta en üstte; ne zaman geri geldiği belirsiz (W) | "Sonra"dan sonra tek satırlık şerit / avatar rozeti; not sayısı arttıkça (ör. 5, 20) yeniden tam kart | 11 |
| A4 | Misafirde hesap gerektiren işler | 🔴 | Kod misafiri koruyor (`collaborators_sheet.dart:32`, `ai_gate.dart:154`) | Düğmeler görünür ve etkin; dokununca ya kısa bildirim ya işlemden SONRA hata. AI: puan 30/30 görünüyor, her araç hata dönüyor (W, K) | Misafirde bu girişler kilit rozetli; dokununca tek tip "Google hesabı gerekir" levhası (neden + Giriş yap); AI'da puan yerine "Google ile gir ya da kendi anahtarını ekle" kartı | 10 |
| A5 | Hesap girişleri | 🟡 | Hesap levhası düzenli: Kişiler, Gelen notlar, Premium, Hesap ayarları (W) | Aynı yere 4 kapı: üst çubuk hesap simgesi, üst çubuk Gelen, ⋮ → Hesap, ⋮ → Kişiler (W) | Üst çubukta TEK avatar (gelen sayısı rozetli) → hesap levhası; ⋮'ten Hesap/Kişiler kalksın | 11 |
| A6 | Hesap silme | 🟢 | İki adım, geri alınamaz uyarısı net; ağır belge/sürüm de siliniyor (W, K) | Web'de onaydan sonra ~6 sn bomboş ekran, gösterge yok (W) | "Siliniyor…" göstergesi; bitince giriş ekranı. Önce DOĞRULA | 10 |
| A7 | İzin tanıtımı | 🟡 | Bir kez çıkıyor, izinler Ayarlar → İzinler'den yönetilebiliyor (K `permissions_onboarding.dart`) | İlk açılışta, henüz hiçbir iş yapılmadan toplu izin levhası — izinler zaten kullanıldıkları yerde de isteniyor; yeni kullanıcının ilk gördüğü şey bir izin listesi (K) | **KARAR GEREKİR:** levha kalksın, izin yalnız bağlamında (ilk dikte, ilk fotoğraf…) + Ayarlar → İzinler | 11 |

### B. Ana ekran

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| B1 | Üst çubuk | 🟡 | Arama her yerden dokunulur, Süz kutunun içinde (W) | 6 öğe: arama + Anlam + Süz + hesap + gelen + ⋮; ipucu "Notlarda ara..." kesiliyor (geniş ekranda "Notlarda ar..."); misafirde hesap simgesi telefon (W) | A5 ile tek avatar; Anlam anahtarı yalnız arama odaklıyken; arama kutusu genişlesin | 11 |
| B2 | Not kartları ve ızgara | 🟢 | Temiz, dengeli sütunlar, kapak görseli, karttan madde işaretleme, saat (W) | Kart ⋮ 36 dp ve ADSIZ (`note_card.dart:895` InkWell, tooltip/semantik yok); kart semantik ağaçta iki kez okunuyor (W) | ⋮'e ad + 48 dp dokunma alanı; kartı `MergeSemantics` ile tek düğüm | 15 |
| B3 | Tarih grupları (BUGÜN / BU HAFTA) | 🟡 | Süz levhası dipnotla açıklıyor (W) | Varsayılan sıralama "Elle" → gruplar hiç görünmüyor ama kılavuz ana ekranı böyle anlatıyor; dipnot "Son düzenlenen", çip "Son güncellenen" (W) | **KARAR GEREKİR:** varsayılan sıralama; adlar tek | 11 |
| B4 | Süz levhası | 🟡 | Hepsi tek levhada, seçili olan dolu çip (W) | Üç farklı kontrol aynı çip görünümünde: tekli seçim (Izgara/Liste), aç-kapa (Kartta görseller/ekler, Paylaşılanlar), süzgeç; "DURUM" içinde TÜR (Metin/Liste/Sıralı) ile DURUM (Sabitlenmiş/Yıldızlı/Alarmlı/Kilitli) karışık; "Diğerleri" belirsiz; ✥ "Notları sırala" simgesi açıklamasız; başlıklar "Görünüm" ve "DURUM" farklı yazımda (W) | Görünüm = segmentli düğme + anahtarlar; "Tür" ve "Durum" ayrı satır; "Diğerleri" açık ad; ✥ → metinli "Elle sırala" | 11 |
| B5 | Klasör şeridi ve klasörler | 🟢 | "Tümü" sayaçlı, Yeni klasör tek dokunuş; kendi klasörüm süzgeçli ana ekran (W, K) | ⇕ "Klasörleri büyüt" simgesi anlamsız, 34×32 dp; klasör sırası ⋮'te, klasörler ekranı ayrı — 3 yer (W) | ⇕ yerine şeridin sonunda "Tüm klasörler"; sıra o görünümün içinde | 11 |
| B6 | Yatay kaydırma jestleri | 🟡 | Izgarada ekranı kaydırınca klasör/süzgeç, listede satır kaydırınca sabitle/arşivle; geri alınabilir (K `dashboard_widgets.dart:875`) | Kılavuz ayırmadan "Sağa kaydır: sabitle" diyor; ayar adı ("Ana ekranda yana kaydırınca") ızgara/liste farkını söylemiyor; hiçbiri görünür değil (K) | Kılavuz + ayar açıklaması; ilk kullanımda bir kez ipucu (F14.6) | 14 |
| B7 | Seçim kipi ve toplu işler | 🟢 | Uzun bas → seçim; "Tümünü seç" görünenlerle sınırlı; geri al (W, K) | Kopyala simgesi (content_copy) ⋮'deki "Notu çoğalt" ile karışıyor; simgelerin ne yaptığı yalnız uzun basınca (W) | Simge sözlüğü (F16.1) | 16 |
| B8 | Boş durumlar | 🟢 | "Henüz not yok — + düğmesine dokun" açık (W) | Hatırlatıcılar boşken iki aynı "Yeni hatırlatıcı" düğmesi (orta + yüzen) (W) | Boşken yalnız ortadaki | 11 |
| B9 | Ana ekran zemini | 🟢 | Renk + desen + görsel, anında (W) | 12 renk dairesi ADSIZ (W) | Renk adları | 15 |
| B10 | Paylaşılanlar bölümü (`home_show_shared`) | 🟢 | Kendi ızgarama karışmıyor (K) | — | Cihaz turunda bak | C |
| B11 | Geniş ekran (web/tablet) | 🟡 | Yan menü + liste + not üç bölme, klavye kısayolları görünür (W) | "Yeni not" üç yerde (yan menü, +, boş bölme); Arşiv/Çöp hem yan menüde hem ⋮'te; liste bölmesinin üst çubuğu sıkışık (W) | Geniş ekranda + ve ⋮ tekrarları gizlensin; arama tam genişlik | 11 |
| B12 | Hızlı not satırı | 🟡 | Not açmadan yazma (K) | Varsayılan KAPALI (`settings_providers.dart:519`) ama kılavuz "listenin başında" diyor (K) | Kılavuz düzelt (ya da KARAR: varsayılan) | 14 |

### C. Yeni not oluşturma

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| C1 | "+" paneli | 🟢 | Tek panel, birincil üç düğme başparmak bölgesinde, başlıklı gruplar (W) | "Defter" simgesi arşiv kutusu (`quick_add_fab.dart:377` inventory_2); "DOSYA EKLE" başlığının ilk düğmesi yine "Dosya ekle"; "Diğer" başlığı belirsiz (W) | Defter = kitap simgesi; gruplar "Şablon ve çizim · Kamera · Dosya ve bağlantı" | 11 |
| C2 | Dosyadan not (tek levha) | 🟢 | Özet + başlık + iki net seçenek (W) | Seçenek adları ("Belge gibi not al" / "Nota ek olarak ekle") başka yerlerdeki "Balonlu / Klasik" ile eşleşmiyor (W) | Tek ad çifti (F14.1) | 14 |
| C3 | Web'de PDF'ten not | 🔴 | — | "Ek eklenemedi: Unsupported operation: RawReceivePort", not "Bu notta henüz PDF yok" ile boş (W). Kök: `PdfEdit.readSharedPdfInBackground` ve `_bg` `Isolate.run` kullanıyor (`pdf_edit.dart:715,726`); web'de izole yok | Web'de `compute`/doğrudan çağrı, ortak yardımcı + test | 10 |
| C4 | Şablondan not, alışveriş listesi, defter | 🟢 | Önizlemeli, maddeler not oluşmadan seçilir (K) | — | Cihaz turunda bak | C |
| C5 | Ana ekran mikrofonu | 🟡 | Dokun = doğrudan yazdır, basılı tut = AI sesli not; ad bunu söylüyor (W) | Basılı tutma görsel olarak belli değil; kılavuz "son kullandığın kipi açar" diyor (K) | Düğmede küçük ✨ rozeti ya da bir kez ipucu; kılavuz | 14 |

### D. Not ekranı — genel

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| D1 | Üst çubuk | 🟡 | Geri al/yinele hep yan yana, tarih + senkron durumu (W) | ⋮'in adı "Etiket · Başlık · Alarm" (`note_editor_screen.dart:4278`, `l10n.noteMetaMenu`) — başlıktaki "+" ile aynı; aynı hata `dashboard_screen.dart:964`, `folder_screen.dart:282`; 412 px'te 8 öğe (W, K) | ⋮ = "Not menüsü"; ayrı anahtar | 10 |
| D2 | Başlık yanındaki "+" | 🟡 | Yeni sayfa, Hatırlat, Klasör, Etiket, Etiket öner tek yerde (W) | "+" alt çubuktaki "+ Ekle" ile aynı simge; ne açacağı belli değil (W) | Etiket/alarm simgeli küçük çip ya da kısa metin | 12 |
| D3 | ⋮ not menüsü | 🟡 | Başlıklı gruplar, Sil ayrı ve kırmızı (W) | Hızlı satırda Paylaş ve Notta ara alt çubukta zaten var (HAFIZA kuralı "çubukta duran iş menüde tekrar edilmez" çiğneniyor); Hesap makinesi en görünür yerde; "Temizle" ne temizlediğini söylemiyor (onayı var); "Kopyala ve dışa aktar" grubunda dışa aktarma yok; "Ekranı düzenle"/"Ayarlar" araçların arasında (W, K) | Hızlı satırdan Paylaş/Notta ara kalkar, Hesap makinesi Araçlar'a; yerine sık iş (öneri: Yıldızla · Klasöre taşı · Sürüm geçmişi · Sesli dinle); "İçeriği temizle"; grup "Kopyala"; ekran/ayar en altta küçük satır | 12 |
| D4 | Alt çubuk | 🟡 | Sık işler tek dokunuş, AI ve mikrofon ayrı kapsülde (W) | Aynı konumdaki düğme türe göre başka iş: metinde ☑ "Onay kutusu", listede ⬚ "Seç", belge notunda kalem (W) — kas hafızası bozuluyor | Ortak sıra sabit, türe özgü düğme hep sol grubun EN SONUNDA | 12 |
| D5 | Geri al / yinele | 🟢 | Tüm notu saklıyor, silinen ek geri gelir (K) | — | — | — |
| D6 | Notta ara | 🟢 | Yazarken vurgu, önceki/sonraki/tümü (W) | — | — | — |
| D7 | Görünüm levhası (tema/renk/çerçeve/zemin) | 🟢 | Görsel temalar anında, düz renkler aynı levhada (W) | "Düz renkler" satırının altında bir de "Zemin rengi" düğmesi; Biçim panelindeki "Sayfa rengi" aynı levhayı açıyor, palet simgesi üç yerde (W, K) | "Zemin rengi" → "Özel renk…"; Sayfa rengi tek yerden (KARAR GEREKİR: üst çubuk mu biçim paneli mi) | 12 |
| D8 | Boş not kendiliğinden silinir | 🟢 | Boş açılıp kapanan not iz bırakmıyor (W) | — | — | — |
| D9 | Sürüm geçmişi, kilit, istatistik, sesli oku | 🟢 | Menüden tek dokunuş (W, K) | — | Cihaz turunda bak | C |
| D10 | Not açılış geçişi (karttan büyüme) | 🟢 | Karttan genişleyip karta küçülüyor, görüntü bir kez alınıyor (K, 2026-10-30) | — | Cihazda kasma turu | C |

### E. Liste notları

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| E1 | Madde yazma | 🟢 | Enter yeni madde, işaretliler sona ve üstü çizili, "İşaretlileri sil (1)" (W) | Boş son madde ("Yeni öğe") ile altındaki "+ Yeni öğe" düğmesi aynı anda — iki "Yeni öğe" (W) | Boş son madde varken düğme gizli ya da düğme tek | 12 |
| E2 | Madde uzun basış menüsü | 🟢 | Yıldızla · Seç · Sil sade (W) | Menü maddelerin üstüne biniyor, hangi maddeye ait olduğu vurgulanmıyor (W) | Hedef maddeyi vurgula, menüyü maddenin altına | 12 |
| E3 | Madde jestleri (üstünü çiz, karala, daire) | 🟡 | Kipsiz, ayarla kapanır, saf sınıflandırıcı testli (K) | Görünmez; ilk kullanıcı bilmez (K). Fareyle sürükleme seçime dönüşüyor — beklenen (W) | İlk liste notunda bir kez ipucu (F14.6) | 14 |
| E4 | Çok işaretli madde akıcılığı | 🟢 | Katmansız soluk, önbellekli satır (K, 2026-10-30) | — | Cihaz turu | C |
| E5 | Madde kutucukları (erişilebilirlik) | 🟡 | — | Kutucuklar ADSIZ: ekran okuyucu "onay kutusu" der, madde metnini söylemez (W) | Kutucuğa madde metni etiketi | 15 |

### F. Biçim

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| F1 | Biçim paneli | 🟡 | Dört sıra, her iş tek dokunuş, kapsam (İmleç/Kelime/Satır/Tümü) güçlü (W) | Kapsam "Tümü" ile 4. sıradaki "Tümüne uygula" aynı fikri iki kontrolle anlatıyor; panel 182 px; 5 renk dairesinin hepsi "Yazı rengi" diye okunuyor; "%100" ne olduğunu söylemiyor (W) | "Tümüne uygula"yı kapsam "Tümü"ye kat; renk adları; "Boyut %100"; kapsam sırası yalnız seçim yokken | 12 |
| F2 | Satır içi biçim işaretleri | 🟢 | Metnin içinde, eski sürüm okuyabiliyor (K) | — | — | — |
| F3 | Yazı tipi / boyut / şeffaflık tepsisi | 🟢 | Gömülü yazı tipleri, ilk kullanım kasması giderildi (K) | — | — | — |
| F4 | Etkin biçim rozetleri | 🟢 | Panel kapalıyken B/I/U/renk görünür (K) | — | — | — |

### G. Görseller, video, YouTube, ekler

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| G1 | Yüzen görseller, metin akışı | 🟢 | Yapışma, hizalama çizgileri, açıklama (K) | — | Cihaz turu | C |
| G2 | Görünüm anahtarı (Sabit / Yüzen / Balonlu) | 🟡 | Aynı anahtar üç yerde, geçiş hiçbir şey silmiyor (K) | Adlar dağınık: "Belge gibi not al", "Balonlu", "Klasik", "Nota ek olarak", "Yüzen" (W, K) | Ad sözlüğü (F14.1) | 14 |
| G3 | Üste sabitleme (yukarı sürükle) | 🟡 | Medya üstte, not altta; bölme boyu hatırlanıyor (K) | Jest görünmez; "Bırak: üste sabitle (altta not)" bırakma hedefinin adı editörün KÖK düğümüne yapışmış, ekran okuyucu her açılışta bunu okuyor (W) | Etiket yalnız sürüklerken; panelde "Sabit" düğmesi zaten var — ipucu | 15 |
| G4 | Video / YouTube yerinde oynatma, damgalar, "⏱ Not al" | 🟢 | Zaman damgası dokununca sarıyor, hız, PiP (K) | — | Cihaz turu | C |
| G5 | Ek şeridi, eki kopyala / yapıştır | 🟢 | Uygulama içi pano + görselde sistem panosu; Ekle'de "Kopyalanan eki yapıştır" (K) | — | — | — |
| G6 | Yazıya gömme (çip) | 🟢 | Türe göre renkli çip, önizleme kartı, ters yönde "Buraya bağla" (K) | — | Cihaz turu | C |
| G7 | Görüntüleyiciler (görsel/PDF/sunum/video/YouTube/transkript) | 🟡 | Her biri işine özel araçlarla (K) | Ortak çubuk yok: paylaş yalnız transkriptte, görselde kırp/döndür/OCR, PDF'te yalnız balon listesi, videoda tam ekran/PiP/tekrarla (K) | Ortak çubuk: Geri · ad · Paylaş · Eki kopyala · ⋮ (türe özgüler ⋮'te ya da altta) | 13 |

### H. Balonlu mod (PDF, sunum, görsel belge)

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| H1 | Balon bırakma (basılı tut / Balon düğmesi) | 🟢 | İki yol, sivri uç noktayı gösteriyor, yazma kartı klavyeyi izliyor (K) | — | Cihaz turu | C |
| H2 | Balon yazma kartı | 🟡 | Her şey tek kartta (K) | Kartta 9 kontrol: sil, renk, yıldız, acil, kalın, italik, dolgu, küçült, büyüt (`bubble_dock.dart:461-609`); kılavuza göre en az renk/yıldız/acil/boyut/sil hep görünür — küçük ekranda yazı alanı daralıyor (K; cihazda bak) | Görünür: renk · sil · Bitti; biçim (B/I, dolgu, boyut) tek "Aa" altında. KARAR GEREKİR (balonlu mod kullanıcının özenle kurduğu yer) | 13 |
| H3 | Balon yazısını kopyalama / paylaşma | 🔴 | — | Balon metni kopyalanamıyor; 💬 listesi metin olarak dışa verilemiyor; "Metni paylaş"/"Kopyala" balonları HİÇ içermiyor (`note_share_text.dart` yalnız gövde + madde + sayfa notu) (K) | Paylaşım çipi "Balonlar" (sayfa no + metin); balon kartında Kopyala; 💬 listesinde "Tümünü kopyala / nota aktar" | 13 |
| H4 | Vurgu, metin seçimi, alan seçimi | 🟢 | Çift dokun → seç → vurgula/kopyala/AI'ya sor; alan PNG'ye (K) | — | Cihaz turu | C |
| H5 | Belge üstünde kalem | 🟡 | Tek parmak çizer, iki parmak kaydırır (K) | İki ayrı kalem arayüzü: çizim ekranında yeni `PenTray`, PDF/görsel üstünde eski `InkToolbar` (HAFIZA) | Tek `PenTray` | 13 |
| H6 | Balon göster/gizle, listele/ara | 🟢 | Silmeden gizler, listeden gidince yeniden görünür (K) | — | — | — |
| H7 | Sayfaları düzenle (sil/döndür/sırala) | 🔴 | Sayfa notları sayfalarıyla taşınıyor (K) | Web'de C3 ile aynı kökten kırık (`pdf_edit.dart:650-694` → `_bg` → `Isolate.run`) (K) | F10.1 ile birlikte | 10 |
| H8 | Balonlu PDF dışa aktarma | 🔴 | Balonlar ve çizim PDF'e basılıyor, geri okunabilir damga (K) | Web'de C3 ile aynı kökten kırık (K) | F10.1 ile birlikte | 10 |
| H9 | Sunum (PPTX) | 🟢 | Slayt bölmesi PDF ile aynı dil (K) | — | Cihaz turu | C |

### I. Kalem, çizim, el yazısı

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| I1 | Çizim ekranı ve kalem tepsisi | 🟢 | Tükenmez/keçeli/fosforlu, ikinci dokunuşta ayar, basınç (K) | — | Cihaz turu | C |
| I2 | S Note araçları (kement, şekil, kısmi silgi, havada önizleme) | 🟢 | Basılı tut → şekil, kement seç/taşı/boya (K, 2026-10-30) | — | Cihaz turu | C |
| I3 | Kalemi otomatik algıla | 🟡 | Kalem dokunuşu doğru kipi açıyor (K) | Metin notunda kalem dokunuşu el yazısı tuvalini AÇIYOR — beklemeyen kullanıcı için ani geçiş (K) | İlk seferde "Kalemle yazmak için tuval açıldı — Ayarlar'dan kapatılır" bildirimi | 14 |

### J. Tarama, OCR, QR

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| J1 | Belge tarama | 🟢 | Kenar bulma, düzleştirme, aranabilir PDF (K) | — | Cihaz turu | C |
| J2 | Görselde metin tanıma | 🟢 | Cihazda, satıra dokunarak seçim (K) | — | — | C |
| J3 | QR tara | 🟢 | Kamera ve galeri (K) | Web'de yok — panelde de gizli (W) | — | — |

### K. Ses ve dikte

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| K1 | Doğrudan yazdır (dikte) | 🟢 | Kota yok, bipler susturuluyor (K) | — | Cihaz turu | C |
| K2 | AI sesli not levhası | 🟡 | Akıllı komutlar, notu kendisi kuruyor (K) | Levhanın durumlarına dağılmış 5 çip (Liste yap, Düzelt, Özetle ekle, Özetle kaydet, Maddelere) + 6 eylem (Nota ekle, Not oluştur, AI notu, Düz not, Devam, Yeniden) — ilk kullanıcıya ağır (K; aynı anda kaçının göründüğüne cihazda bak) | Varsayılan tek birincil eylem ("Notu kur"), gerisi "Diğer" altında. KARAR GEREKİR | 12 |
| K3 | Ses kaydı (alt şeritte hap) | 🟢 | Kayıt sürerken yazılıyor, bitince satıra dalgalı hap (K) | — | Cihaz turu | C |
| K4 | Ses işlerinin adları | 🟡 | — | Benzer dört ad: "Sesle yazdır", "Sesli not", "Ses kaydı", "Sesli oku"; "Sesli not" iki yerde (AI levhası + AI ekranı) (W, K) | Sözlük: Dikte · AI sesli not · Ses kaydı · Sesli dinle (F14.1) | 14 |
| K5 | Sesli okuma ve Antalia Türkçe sesi | 🟢 | Tek kapı `SpeechService`, düşerse cihaza geçip sebebi söylüyor (K) | — | — | — |

### L. Transkript

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| L1 | Ses/video/görsel metne dökme | 🟢 | Damgalı, ek olarak saklanıyor, aramaya giriyor, yeniden AI puanı harcamıyor (K) | — | Cihaz turu | C |
| L2 | Transkript ekranı | 🟢 | Seç → nota ekle / yeni not, kopyala, .txt paylaş (K) | — | — | — |

### M. Yapay zekâ

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| M1 | Misafirde yapay zekâ | 🔴 | Sunucu tarafı doğru korunuyor (K) | Arayüz "Bugünkü puan 30/30" ve etkin düğmeler gösteriyor, dokununca hata (W, K `ai_gate.dart:154`) | A4 ile | 10 |
| M2 | Not ekranı AI levhası | 🟡 | Sesli not + Sohbet geniş satır, araçlar açıklamalı kart (W) | Kart boyları farklı (96/107 px), "Notu geliştir" tek başına; başlık "Yapay Zeka", metinler "yapay zekâ" (W) | Eşit yükseklik ya da tek sütun liste | 12 |
| M3 | Yapay Zekâ ekranı | 🟡 | Kahraman kart, Not Asistanı öneri çipleri, araçlar sayılı (W) | Başlık iki kez; sağ üst ayar düğmesinin adı "Yapay Zeka"; "0 başlıksız not var", "0 kopya not var" kartları iş yokken duruyor; öneri çipleri onay kutusu rolünde (W) | İşi olmayan araç gizli/soluk; düğme adları; çip rolü | 14 |
| M4 | Sohbet (kapsam + kip) | 🟢 | Tek ekran, Tüm notlar / Bu not / Bu belge, beyin fırtınası (K) | — | Cihaz turu | C |
| M5 | Hata metinleri | 🔴 | Hata günlüğü cihazda tutuluyor (K) | ~80 yerde ham istisna kullanıcıya: `aiError('$e')`, `genericError('$e')` (örn. `ai_chat_screen.dart:292`, `listen_screen.dart:203`, `friends_screen.dart:205`); web'de görülen "Unsupported operation: RawReceivePort" (W, K) | Tek `friendlyError(e)`: ağ yok / kota / izin / dosya büyük / bilinmeyen + "Ayrıntıyı kopyala"; ham metin yalnız günlükte | 10 |
| M6 | Günlük brifing, belge oku (podcast) | 🟢 | Önbellekli, sesli, nota kaydedilebilir (K) | — | — | — |
| M7 | Anlamsal arama | 🟡 | Süzgeçlerle tutarlı, gecikmeli sorgu (K) | Arama kutusunda "Anlam" anahtarı; kılavuz "Metin / Anlam sekmesi" diyor (W) | Kılavuz; anahtar yalnız odakta (B1) | 14 |
| M8 | Otomatik etiket/başlık, kopya temizleme, çöp analizi | 🟢 | Cihaz kuralları + isteğe bağlı AI, kilitli not gitmiyor (K) | — | — | — |

### N. Düzen: klasör, etiket, arşiv, çöp, kilit

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| N1 | Etiketler | 🟢 | Başlık "+" ile ekle, Süz'de yeniden adlandır/sil (K) | — | — | — |
| N2 | Arşiv | 🟢 | Sade, arama + ✨, "Arşivimde neler var?" (W, K) | — | — | — |
| N3 | Çöp kutusu + akıllı analiz | 🟢 | Gün sayacı, "yakında silinecek" bölümü, toplu geri yükle (K) | — | — | — |
| N4 | Gizli klasörler | 🟢 | Biyometrik açılış (K) | — | Cihaz turu | C |
| N5 | Not kilidi | 🟢 | Cihaz/şifre/desen, "şifreleme değil" açıkça yazıyor (W, K) | — | — | — |
| N6 | Kart hassas içerik gizleme | 🟢 | IBAN/kart no örtülü, parola notu içeriksiz (K) | — | — | — |

### O. Hatırlatıcılar

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| O1 | Saat hatırlatıcısı ve ekranı | 🟢 | Hızlı seçenekler (bu akşam/yarın/haftaya), erteleme, geçmiş (K) | Boşken iki "Yeni hatırlatıcı" (B8) (W) | B8 | 11 |
| O2 | Konum hatırlatıcısı | 🟢 | Var/ayrıl (K) | — | Cihaz turu | C |
| O3 | Günlük brifing bildirimi, çöp hatırlatması | 🟢 | Planlı bildirimlerle mutabakat (K) | — | — | — |

### P. Paylaşım ve kopyalama

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| P1 | Paylaş levhası | 🟡 | Metin önizlemesi, içerik çipleri hatırlanıyor, tek dokunuş düğmeler (W) | "KOPYA GÖNDER" başlığının altında yine "Kopya gönder"; misafirde görünür; web'de "Görsel" ve "Ekler" yok (kılavuz var diyor); "Not paketi" ne olduğu yazmıyor; "PDF" ile "Not metni (PDF / Word)" ayrımı belirsiz (W) | İki bölüm: **Gönder** (Metin · Kopyala · PDF · Görsel · Ekler) ve **Notlar kullanıcısına** (Kopya gönder · Birlikte düzenle · Not paketi); uzun basınca açıklama; "Ayarlı PDF/Word…" | 13 |
| P2 | Çok sayfalı notun paylaşımı/kopyası | 🔴 | — | `noteShareText` yalnız ETKİN sayfa (deneme testi: 2 sayfalı not → yalnız "Birinci sayfa"); kart ⋮ Kopyala, seçimde Kopyala, editör Kopyala aynı işlev (K✓ `note_share_text.dart:91`) | Sayfalar "Sayfa N" başlığıyla sırayla + test; PDF/Word/Görsel çıktısında da doğrula | 10 |
| P3 | Balonlu notun paylaşımı | 🔴 | Balonlu PDF var (K) | H3 | H3 | 13 |
| P4 | "Kopya" sözcüğünün anlamları | 🟡 | — | Kopyala (panoya), Notu çoğalt, Kopya gönder (arkadaşa), Eki kopyala (uygulama panosu), Deftere kopyala, "Arşiv defterine kopyala" (eski defter adı), Kopyala ve işaretle (W, K) | Sözlük: Kopyala = panoya · Çoğalt = yeni not · Gönder = arkadaşa · "Deftere topla" (F14.1) | 14 |
| P5 | Dışarıdan paylaşım (Paylaş → Notlar) | 🟢 | Yeni not / var olan not, kart ızgarasıyla seçim (K) | — | Cihaz turu | C |
| P6 | Ayarlı PDF/Word dışa aktarma | 🟢 | Başlık, görsel yeri/boyu (K) | — | Çok sayfalı not (P2) burada da kontrol | 10 |
| P7 | Not paketi | 🟢 | Ekler, sayfalar, çizim, balonlarla birebir (K) | Simgesi Defter ile aynı (F16.1) | — | 16 |

### Q. Birlikte çalışma

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| Q1 | Kişiler, kişi araması | 🟢 | Kötüye kullanıma karşı sınırlı arama (K) | Misafirde dokununca belirsiz (A4) | A4 | 10 |
| Q2 | Ortak not, "X düzenliyor", üç yönlü birleştirme | 🟢 | Eşzamanlı yazım korunuyor (K) | — | İki hesapla cihaz turu | C |
| Q3 | Klasör paylaşımı + klasör sohbeti | 🟢 | Okuma/yazma rolü, itme bildirimi (K) | — | Cihaz turu | C |
| Q4 | Gelen ve paylaşılanlar | 🟢 | Tek ekran, iki sekme, boş durum açıklamalı (W) | Simgesi Arşiv'e çok benziyor (F16.1) | — | 16 |

### R. Widget'lar ve kısayollar

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| R1 | Ana ekran widget'ları (5 tür) | 🟢 | Notlar, Hızlı not, Hızlı eylemler, Sesli not, Bugün (K) | — | Cihaz turu (açık/koyu) | C |
| R2 | Uygulama kısayolları, "Ana ekrana yerleştir", Gemini işlevleri | 🟢 | Not rengi + baş harfli simge; kilitli not ajana dönmüyor (K) | — | — | — |
| R3 | Klavye kısayolları (web/geniş) | 🟢 | Ctrl+N/K/\ ve liste ekranı (W) | — | — | — |

### S. Ayarlar, kişiselleştirme, kılavuz

| # | Özellik | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| S1 | Ayarlar ekranı | 🟡 | Arama + ✨ ile ayar bulma, alanlar kapalı açılır, açılan alan tepeye gelir (W, K) | "Kişiselleştir" iki kez (üstte bağlantı kartı + aşağıda alan, alanın özeti "Geri sarma 10 sn · İleri sarma 10 sn"); "Düzenleme modu" üçüncü giriş; "Sesli okuma" alanının özeti "Bas-başlat / bas-bitir" (dikte ayarı) ve içinde "Dil" var; "Notlar ve klasörler" özeti yalnız kaydırma ayarı; Görünüm'de 12+ "kartta göster" anahtarı alt alta (W, K) | Alan adı = içeriği; Dil kendi satırı ya da Görünüm'de; kart anahtarları önizlemeli "Kartta görünenler" alt levhası; Kişiselleştir tek giriş | 14 |
| S2 | Kişiselleştir ekranı | 🟢 | Eklentiler anahtarlı ve açıklamalı, ekranda düzenleme modu (W) | "Şablonlar — … arşiv defteri" eski ad; "siz" diliyle yazılmış ("açın, dokunun") — uygulamanın geri kalanı "sen" (W) | F14.1 | 14 |
| S3 | Kullanım kılavuzu | 🔴 | Aranabilir, bölümlü (W) | İçindekiler çipleri ile altındaki akordeon AYNI başlık listesi (W). İçerik eskimiş: "16 dil" (tr+en var), alt çubukta "asistan mikrofonu" (kalktı), "+ menüsünde Kamera · Dosya · Şablon kapıları" (tek panel), "Ses dosyası ekle / Görüntülü not / Galeriden video" (tek Dosya ekle), "eski yıldızlılar da sabitlidir" (yıldız geri geldi), "Hızlı not satırı listenin başında" (varsayılan kapalı), "misafirde yazılar senkronlanır" (giriş ekranı "yalnız bu cihazda" diyor), "Sağa kaydır: sabitle" (yalnız liste), "Kopyalamak menülerde ayrıca yok" (⋮'te Paylaş var), "Metin/Anlam sekmesi" (anahtar) (K) | Kılavuz koddan yeniden; içindekiler ya çip ya liste; her bölümde ilgili ekrana "Göster" bağlantısı | 14 |
| S4 | Premium, gizlilik, lisanslar, hata günlüğü | 🟢 | Hesap levhasından ve Ayarlar'dan (W) | — | — | — |
| S5 | Ayar senkronu | 🟢 | Cihaza özgü anahtar dışarıda, 20 sn yoklama yalnız ön planda (K) | — | — | — |

### U. Genel (bütün uygulama)

| # | Konu | Not | İyi | Sorun | Yapılmalı | Faz |
|---|---|---|---|---|---|---|
| U1 | Semantik etiketler | 🟡 | `IconButton`ların neredeyse hepsinde ipucu var (kaba sayım: 199'dan ~6'sı ipucusuz) (K) | 239 özel jest (GestureDetector/InkWell/Listener) karşısında 26 semantik işaret; balonlar, sayfadaki görseller/videolar, PDF sayfası, kart ⋮, renk daireleri, madde kutucukları adsız (W, K) | Faz 15 | 15 |
| U2 | Yazı boyutu ve kalın metin | 🔴 | İlk açılışta sistem ölçeğinin en yakın kademesi alınıyor (F4.7) (K) | `fixedTypography` (`app.dart:53`) sistem yazı ölçeğini EZİYOR ve "kalın metin"i kapatıyor — sonradan sistemden büyütmek etkisiz (2026-08-07 kullanıcı kararı) (K) | **KARAR GEREKİR:** "Sistem yazı boyutunu izle" seçeneği | 15 |
| U3 | Dokunma hedefleri | 🟡 | Ana düğmeler 40–56 dp (W) | 48 dp altı: kart ⋮ 36, Klasörleri büyüt 34×32, Süz 34×42, ayar ✨ 34×32, dinleme başlık düğmesi 34 (W, HAFIZA) | Görünüm aynı kalarak dokunma alanı ≥ 48 | 15 |
| U4 | Hareketi azalt | 🟡 | — | Sistem "animasyonları kaldır" yalnız 2 dosyada okunuyor; not açılış geçişi, `ExpandReveal`, `RevealUp`, `ScaleSettle`, `PopIn`, `PressScale` dikkate almıyor (K) | Ortak `motionOf(context)` yardımcısı | 15 |
| U5 | Gizli jestler ve keşfedilebilirlik | 🟡 | Jestler güçlü ve hızlı (K) | En az 10 görünmez jest (kart kaydırma, iki parmakla sütun, ekranı kaydırıp klasör, mikrofona basılı tut, PDF'e basılı tut → balon, çift dokun → vurgu, maddeye çiz, medyayı yukarı sürükle, daire çizerek bağla, sayfayı yana çek); ipucu sistemi yok (yalnız izin tanıtımı) (K) | Bağlamında bir kez çıkan küçük ipucu (`TipOnce`) + "İpuçlarını yeniden göster" | 14 |
| U6 | Adlandırma ve dil birliği | 🟡 | Metinlerin neredeyse tamamı l10n'da (K) | `app_tr.arb`: "Yapay Zeka" ×4 / "Yapay zeka" ×2 / "yapay zeka" ×4 / "Yapay zekâ" ×14 / "yapay zekâ" ×7; "öğe" ↔ "madde"; "sen" ↔ "siz" karışık (örn. `pdfPagesHint`, `customizeModeHint`); "Son güncellenen" ↔ "Son düzenlenen" (K) | Terim sözlüğü + toplu düzeltme + arb tarama testi | 14 |
| U7 | Levha ve başlık dili | 🟡 | Ortak `showAppSheet` (65 yerde) ve `ActionMenu` (K) | Levha başlıkları farklı: başlık + "Kapat" hapı (Süz), başlık + ✕ (Ekle), yalnız tutamak (⋮ menüleri), simgeli başlık (AI); bölüm başlıkları bazen BÜYÜK, bazen cümle düzeni (W) | Tek başlık bileşeni + tek bölüm başlığı stili | 16 |
| U8 | Simge sözlüğü | 🟡 | Material simgeleri tutarlı ağırlıkta (W) | Aynı simge farklı iş: arşiv kutusu (`inventory_2`) = Defter + Not paketi + Arşiv defterine kopyala; palet = Görünüm + Sayfa rengi + Zemin rengi; "+" = Ekle + başlık menüsü + yeni not. Farklı iş benzer simge: Arşiv (`archive`) ↔ Gelen kutusu (`move_to_inbox`) (W, K) | Tek simge = tek anlam | 16 |
| U9 | Renk tokenları ve temalar | 🟡 | Beş tema; kırık beyaz ılık ve sakin (W) | Tema dışında 151 `Color(0x…)` + 207 `Colors.white/black` (K) — koyu/kâğıt temada uyumsuzluk riski | Gözden geçir, token'a çevir; koyu tema ekran turu | 16 |
| U10 | Yükleniyor / boş / hata durumları | 🟡 | `EmptyState` 21 yerde (K) | 67 dönen gösterge, iskelet (skeleton) yalnız 5 yerde (K) | Liste ekranlarında iskelet, tek hata bileşeni (M5 ile) | 16 |
| U11 | Kod sağlığı ve performans tabanı | 🟢 | Analiz temiz, 1730/1730 test; Faz 5–9 kasma kök nedenlerini kapattı (K) | Kare ölçümü (F9.1) hiç yapılmadı; dev dosyalar (`note_editor_screen.dart` 4390, `note_editor_attachments.dart` 2352, `note_images.dart` 2301, `items_editor.dart` 2278 satır) değişiklik riskini artırıyor (K) | Faz 17 | 17 |
| U12 | Cihazda doğrulanmamış iş birikimi | 🟡 | KALANLAR tek liste (K) | ~80 madde "cihazda görülmedi" (KALANLAR §2) | Faz 17: on dakikalık duman testine indir | 17 |

---

## FAZ 10 — Kırık ve yanıltıcı olanlar

Kısa ve yüksek değerli. Bitince web'de PDF akışı, çok sayfalı paylaşım ve
misafir deneyimi doğru çalışır; kullanıcı ham hata metni görmez.

- [x] **F10.1 Web'de `Isolate.run` (YÜKSEK) — C3, H7, H8.**
  `pdf_edit.dart:715` (`readSharedPdfInBackground`) ve `:726` (`_bg`: sayfa
  sil/sırala/döndür, damgalama) `Isolate.run` kullanıyor; web'de
  `RawReceivePort` yok → "Ek eklenemedi: Unsupported operation". Tek yardımcı
  (`runHeavy(fn)`: web'de `compute`/doğrudan, diğerinde `Isolate.run`) ve
  `lib` içindeki bütün `Isolate.run`lar oradan (`local_notes_store.dart:276`
  yalnız Android ama yine de). Web'de iş ana iş parçacığında koşacağı için
  büyük PDF'te `_runBusy` göstergesi şart. Test: yardımcının web dalı için
  birim testi + `PdfEdit` sarmalayıcılarının çağrı testi. Cihaz: web'de PDF
  ekle → balon → sayfa sil → Balonlu PDF paylaş.
  **Yapıldı:** `core/utils/run_heavy.dart` (`runHeavy`: web'de bir kare
  bekleyip aynı iş parçacığı, diğerinde `Isolate.run`); `pdf_edit.dart` ve
  `local_notes_store.dart` oradan. PDF okuma `_runBusy` içine alındı, sayfa
  düzenleme "PDF işleniyor…" göstergesiyle. Ek bulgu: balonlu PDF paylaşımı
  web'de `getTemporaryDirectory` ile de kırılırdı → `XFile.fromData`
  (`note_share.dart`). Test: `run_heavy_test.dart`, `pdf_edit_test.dart`
  (sarmalayıcılar).
- [x] **F10.2 Çok sayfalı not paylaşımı (YÜKSEK) — P2, P6.**
  `noteShareText` (`note_share_text.dart:91`) `textPages`'i dolaşsın: etkin
  sayfa `body/items`ten, diğerleri listeden; "Sayfa N" başlığı (tek sayfada
  başlık yok). Aynı işlevi kullanan kart ⋮ Kopyala, seçim Kopyala, editör
  Kopyala kendiliğinden düzelir. PDF/Word/Görsel çıktısında sayfaların
  girdiğini doğrula (`note_pdf.dart`, `note_docx.dart`). Test:
  `note_share_text_test.dart`'a iki sayfalı not.
  **Yapıldı:** `noteShareText` bütün sayfaları yazar (tek sayfada başlık
  yok, boş sayfa atlanır). PDF/Word dışa aktarma da yalnız etkin sayfayı
  alıyordu → `exportContentOf` (`pdf_export_screen.dart`). Görsel çıktısı
  ekranın görüntüsü olduğundan etkin sayfadır (değişmedi). Test:
  `note_share_text_test.dart`, `export_pages_test.dart`.
- [x] **F10.3 ⋮ düğmelerinin adı — D1.** `note_editor_screen.dart:4278`,
  `dashboard_screen.dart:964`, `folder_screen.dart:282` `l10n.noteMetaMenu`
  yerine yeni anahtar ("Not menüsü" / "Diğer işlemler"); başlık "+"ı
  `noteMetaMenu`de kalır. Test: `find.byTooltip`.
  **Yapıldı:** editör ⋮ = `noteMenu` ("Not menüsü"), seçim çubuklarının ⋮'i
  = `moreActions` ("Diğer işlemler"). Editör için widget testi altyapısı
  yok; `menu_names_test.dart` adların ayrı olduğunu denetler.
- [x] **F10.4 Ham hata metni yok — M5.** `core/` altında `friendlyError(l10n, e)`:
  ağ yok, zaman aşımı, kota/oran, izin, dosya çok büyük, desteklenmeyen
  (web), bilinmeyen → kısa Türkçe metin; ham metin `ErrorLog`a ve bildirimde
  "Ayrıntıyı kopyala"ya. `aiError('$e')`/`genericError('$e')` çağrılarının
  hepsi (~80, `grep -rn "('\$e')\|(e.toString())"`). Test: eşleyici birim testi.
  **Yapıldı:** `core/friendly_error.dart` (`classifyError` + `friendlyError`;
  `UserFacingException` — `GeminiException` iletisi olduğu gibi kalır); 81
  çağrı yeri + sohbet denetleyicisi, ses kaydı, tarama, QR, geçmiş, giriş
  yedeği. Ham metin `ErrorLog`a; `showMessage` az önceki hatanın
  bildirimine kendiliğinden "Ayrıntıyı kopyala" ekler. Test:
  `friendly_error_test.dart`.
- [x] **F10.5 Misafir deneyimi — A2, A4, M1, Q1.** Misafirde (a) AI levhası ve
  AI ekranı puan yerine "Google ile gir ya da kendi anahtarını ekle" kartı,
  araçlar soluk; (b) Kişiler, Ortak çalışanlar, Kopya gönder, Birlikte düzenle
  kilit rozetli, dokununca ortak `showAccountRequiredSheet` (neden + Google
  ile giriş yap); (c) giriş ekranı ve misafir kartı metni bununla aynı şeyi
  söylesin. Kendi anahtarı olan misafirde AI açık kalır (`ai_gate.dart:149`).
  **Yapıldı:** `aiGuestLockedProvider` (misafir + anahtarsız); AI ekranı ve
  not içi AI levhası puan yerine `GuestAiCard` (Google ile giriş · Kendi
  anahtarımı ekle), araçlar `GuestAiDim` ile soluk (Kopyalar açık). Ortak
  `showAccountRequiredSheet` + `AccountLockBadge`
  (`auth/presentation/account_required.dart`): Kişiler, Ortak çalışanlar,
  Kopya gönder, Birlikte düzenle, klasör paylaşımı — girişler misafirde
  artık gizli değil, kilitli. `localAccountInfo` ve `guestReminderBody`
  aynı şeyi söyler. Test: `guest_ai_lock_test.dart`.
- [x] **F10.6 Web açılış ekranı — A1.** `web/index.html` açılışı Flutter'ın
  ilk anlamlı karesine kadar kalsın; Flutter'daki başlangıç ekranı web'de
  çizilmesin (ya da tam tersi — tek katman); dil `navigator.language`.
  **Yapıldı:** HTML katmanı `notlar-ready` olayında kalkar
  (`core/utils/web_ready.dart`; giriş düğmeleri ya da `AppFrame` çizilince);
  sessiz misafir girişi sürerken Flutter ara ekranı HTML'in altında kalır.
  Yedek: ilk kareden 6 sn sonra. Dil `navigator.language` (tr değilse
  İngilizce). `_autoSigningIn` artık ilk karede doğru.
- [x] **F10.7 Hesap silme sonrası boş ekran — A6.** Önce DOĞRULA (web'de ~6 sn
  boş ekran görüldü); silme sürerken gösterge, bitince giriş ekranı.
  **Yapıldı:** kök neden koddan: oturum düşünce router bekleme penceresini
  kaldırabiliyor, ardından körlemesine `navigator.pop()` giriş sayfasını
  atıyordu. Pencere `DialogRoute` olarak tutulur, yalnız açıksa
  `removeRoute`; içinde "Hesabın ve verilerin siliniyor…". Web'de yeniden
  denenmedi (KALANLAR).

**Senin yapacakların:** web'de (Chrome) PDF ekle → balon → paylaş; telefonda
iki sayfalı notu WhatsApp'a paylaş, iki sayfanın da gittiğine bak.

## FAZ 11 — Ana ekran ve "+" akışı

Ana ekran sadeleşir, aynı işin tek kapısı olur; boşalan yer aramaya ve
notlara kalır (Ö6).

- [x] **F11.1 Üst çubuk: tek avatar — A5, B1. KARAR GEREKİR.** Hesap simgesi +
  Gelen simgesi → tek avatar (misafirde kişi simgesi), okunmamış gelen/davet
  sayısı rozet; dokununca hesap levhası (Kişiler · Gelen ve paylaşılanlar ·
  Premium · Hesap ayarları). "Anlam" anahtarı arama odaklıyken görünür.
  `UiItem.homeAccount` kimliği korunur; Gelen için yeni kimlik gerekmez.
  **Yapıldı:** `AccountAvatarButton` (`auth/presentation/account_sheet.dart`)
  tek kapı: rozet = `accountPendingCountProvider` (arkadaşlık isteği +
  `sharedHubBadgeProvider`), 48 dp, misafirde kişi simgesi; levhada "Gelen ve
  paylaşılanlar" (`SharedHubScreen`). `SharedHubButton` silindi. Anlam
  anahtarı yalnız odak/sorgu varken (`TextFieldTapRegion` — dokununca odak
  düşmesin). Levha içeriğe göre boylanır (alçak pencerede taşıyordu).
- [x] **F11.2 Ana ⋮ menüsü.** Hesap ve Kişiler satırları avatar levhasına
  gider; "Klasör sırası" klasör görünümüne (F11.5). Kalan: hızlı satır
  (Yapay Zekâ · Hatırlatıcılar · Arşiv · Çöp · Ayarlar) + Ana ekran zemini ·
  Kişiselleştir · Kılavuz.
  **Yapıldı:** `dashboard_menu.dart`: Hesap/Kişiler ve Klasör sırası çıktı;
  "Hesap" yalnız avatar kişiselleştirmede gizliyse "Ana ekran" grubunda.
- [x] **F11.3 Misafir kartı — A3.** "Sonra"dan sonra tek satırlık şerit (ya da
  yalnız avatar rozeti); not sayısı 5 ve 20'yi geçince bir kez yeniden tam kart.
  **Yapıldı:** `guestReminderMode` (none/strip/full, `guest_backup_card.dart`):
  "Sonra" o anki not sayısını yazar (`guest_reminder_later_count`); sonra
  48 dp tek satır şerit (dokununca Google bağla); 5 ve 20 eşiği geçilince bir
  kez tam kart. Eski 7 günlük erteleme kaydı "0'da Sonra" sayılır.
- [x] **F11.4 Süz levhası — B3, B4. KARAR GEREKİR (varsayılan sıralama).**
  Görünüm: Izgara|Liste segmentli düğme + "Kartta görseller / ekler /
  Paylaşılanlar" anahtar satırları; "Tür" (Tümü/Metin/Liste/Sıralı) ve
  "Durum" (Sabitli/Yıldızlı/Alarmlı/Kilitli/…) ayrı satır; "Diğerleri" açık
  ad; ✥ → metinli "Elle sırala"; "Son güncellenen" / "Son düzenlenen" tek ad;
  bölüm başlıkları aynı stil. Öneri: varsayılan "Son güncellenen" (tarih
  grupları görünür), elle sıralayan kullanıcının kayıtlı seçimi korunur.
  **Yapıldı:** varsayılan `kDefaultNoteSort = updated` (KARAR onaylandı);
  `migrateDefaultNoteSort`: kayıt yokken sürüklenmiş not (`orderIndex > 0`)
  varsa "Elle" kalıcılaşır. Süz: Görünüm `SegmentedButton` + `_SwitchRow`
  anahtarlar; Tür ve Durum ayrı bölüm; "Klasörsüz ve etiketsiz"; ✥ → metinli
  "Elle sırala"; dipnot "Son güncellenen"; başlıklar tek yazım (Durum,
  Etiket, Sıralama). Test: `home_simplify_test.dart`.
- [x] **F11.5 Klasör şeridi — B5.** ⇕ yerine şeridin sonunda "Tüm klasörler"
  (metinli, 48 dp); orada klasör sırası ve klasör ekranı tek yüzey.
  **Yapıldı:** `dashboard_shelf.dart`: ⇕ yerine 48 dp "Tüm klasörler" →
  `/folders` (klasör sırası orada, AppBar'da). Şerit 48 dp (çipler yine 32).
  Karo görünümü Ayarlar'daki anahtarla kalır.
- [x] **F11.6 "+" paneli — C1.** Defter simgesi kitap (`menu_book`); grup adları
  "Şablon ve çizim · Kamera · Dosya ve bağlantı"; grup başlığı ile ilk düğme
  aynı adı taşımasın.
  **Yapıldı:** Defter simgesi `book_outlined` (+, kart rozeti, kart türü,
  defter seçici, "Deftere kopyala"; `menu_book` Kılavuz'da kullanıldığı için
  değil). Grup başlıkları "Kamera · Dosya ve bağlantı · Şablon ve çizim".
  Not paketi simgesi (`share_sheet`) F16.1'e kaldı.
- [x] **F11.7 Çift düğmeler — B8.** Hatırlatıcılar boşken yalnız ortadaki
  düğme; benzer boş durum + yüzen düğme çiftleri (arşiv, klasör) taranır.
  **Yapıldı:** Hatırlatıcılar boşken yüzen düğme yok (`_visibleReminders`).
  Tarandı: arşivde yüzen düğme yok; klasörün boş durumundaki "Metin notu"
  ile "+" paneli aynı iş değil (panel bütün seçenekler) — dokunulmadı.
- [x] **F11.8 Geniş ekran — B11.** Yan menü görünürken "+" ve ⋮'teki yan menü
  tekrarları gizli; arama kutusu liste bölmesinin tam genişliği; boş not
  bölmesinde tek "Yeni not" (+ menüsü açar).
  **Yapıldı:** `AppRailScope` (`app_frame.dart`): ray görünürken ⋮ hızlı
  satırındaki AI/Hatırlatıcılar/Arşiv/Çöp/Ayarlar gizli. Boş not bölmesi
  (`NoNoteSelected`) tek "Yeni not" → `quickAddOpenRequest` ile listenin "+"
  panelini açar. Arama kutusu: üst çubuktan Gelen düğmesi ve (odak dışında)
  Anlam anahtarı kalkınca genişledi; ayrıca genişlik kuralı eklenmedi.
- [x] **F11.9 İlk açılış izin levhası — A7. KARAR GEREKİR.** Öneri: levha
  kalkar; her izin ilk kullanıldığı yerde kısa açıklamayla istenir (dikte,
  fotoğraf, bildirim → ilk hatırlatıcı, konum → ilk konum hatırlatıcısı);
  toplu görünüm Ayarlar → İzinler'de kalır. Bağlamda isteyen yolların hepsinin
  var olduğunu önce DOĞRULA.
  **Yapıldı:** `PermissionsOnboarding` silindi. Doğrulama: mikrofon
  (`record`/dikte `hasPermission` ilk kullanımda sorar, retteyse
  `micPermissionDenied`), kamera/galeri (`image_picker`, `mobile_scanner`
  kendileri sorar), bildirim: `ReminderService` artık kurulumda değil ilk
  planlanacak bildirimde (`_askPermissionOnce`). **Konum hatırlatıcısı
  uygulamada YOK** — o kol GEÇERSİZ. Ayarlar → İzinler yerinde.

**Senin yapacakların:** telefonda ana ekranın yeni hâli — avatar, Süz, misafir
şeridi; tablet/web üç bölme.

## FAZ 12 — Not ekranı: çubuklar, ⋮, biçim, liste

Not ekranında her işin tek ve sabit yeri olur; kas hafızası bozulmaz.

- [x] **F12.1 ⋮ not menüsü — D3.** Hızlı satır şimdi Yıldızla · Paylaş ·
  Notta ara · Hesap makinesi: Paylaş ve Notta ara kalkar (alt çubukta var —
  HAFIZA kuralı), Hesap makinesi Araçlar'a iner; yerine sık iş (öneri:
  Yıldızla · Klasöre taşı · Sürüm geçmişi · Sesli dinle; Sabitle üst çubukta
  zaten var). "Temizle" → "İçeriği temizle"; "Kopyala
  ve dışa aktar" → "Kopyala"; "Ekranı düzenle" ve "Ayarlar" en altta ince satır.
  **Yapıldı:** `note_menu_sheet.dart`: hızlı satır Yıldızla · Klasöre taşı ·
  Sürüm geçmişi · Sesli dinle. Ara/Paylaş yalnız alt çubukta GÖRÜNMÜYORSA
  (dar ekranda `planEditorBar` düşürdü ya da gizlendi) Araçlar'da
  (`_barHasSearch/_barHasShare`); Hesap makinesi Araçlar'da. "İçeriği
  temizle", grup "Kopyala"; Ekranı düzenle · Ayarlar `ActionMenu.footer`
  (Sil'in altında ince satır).
- [x] **F12.2 Kart ⋮ ile not ⋮ aynı iskelet.** İki menü aynı not için farklı
  sıra ve grup adı kullanıyor (kart: Düzenle/Kopyala ve dışa aktar/Araçlar/
  Koruma; not: İçerik/Kopyala ve dışa aktar/Araçlar/Koruma). Ortak grup adları
  ve sıra; yalnız bağlama özgü maddeler farklı.
  **Yapıldı:** iki menü de Düzenle · Kopyala · Araçlar · Koruma (editörün
  "İçerik"i → "Düzenle"); kartta Klasöre taşı hızlı satıra çıktı (Yıldızla ·
  Klasöre taşı sırası ortak). Test: `menus_youtube_test.dart`.
- [x] **F12.3 Alt çubuk sabit sıra — D4.** Biçim · Ekle · Ara · Paylaş ortak
  sırada; türe özgü düğme (☑ / Seç / Kalem) her zaman sol grubun EN SONUNDA.
  `UiItem` kimlikleri değişmez.
  **Yapıldı:** kapsül sırası Biçim · Ekle · Ara · Paylaş · Ekler · (☑ | Seç);
  kalem (belge notu) kapsülün hemen sağında. Kimlikler aynı.
- [x] **F12.4 Başlık "+" — D2.** Etiket/alarm simgeli küçük çip; notta etiket
  ya da alarm varsa çip onları gösterir (tek alanda hem durum hem eylem, Ö6).
  **Yapıldı:** çıplak "+" yerine etiket + alarm simgeli çip
  (`note-meta-chip`): etiket varsa dolu simge + sayı, alarm kuruluysa dolu
  vurgulu alarm. İpucu "Etiket · Alarm · Klasör".
- [x] **F12.5 Biçim paneli — F1.** "Tümüne uygula" kapsam "Tümü"ye katılır
  (Tümü seçiliyken biçim zaten tamamına); renk dairelerine renk adı; "%100" →
  "Boyut %100" (ekran okuyucuda da); klavye açıkken panel yüksekliği ölçülür,
  kapsam sırası seçim varken gizlenir (seçim zaten kapsamdır).
  **Yapıldı:** `format_bar.dart`: "Tümüne uygula" (`_applyToAll`) kalktı —
  kapsam "Tümü" aynı iş; daire ipuçları "Yazı rengi: Kırmızı"…; boyut
  üstte küçük "Boyut", ekran okuyucu "Boyut %100"; elle seçim varken kapsam
  sırası gizli (`_manualSelection`, kapsamın kendi seçimi sayılmaz) — panel
  o kadar alçalır. Klavye açıkken panel yine `Flexible` + kaydırma içinde;
  ayrı yükseklik ölçümü EKLENMEDİ (cihazda bakılacak, KALANLAR). Test:
  `note_screen_bars_test`, `format_scope_switch_test`.
- [x] **F12.6 Görünüm levhası — D7. KARAR GEREKİR.** "Zemin rengi" → "Özel
  renk…"; Sayfa rengi tek yerden (öneri: üst çubuk palet; biçim panelinden
  kalksın).
  **Yapıldı (KARAR: üst çubuk palet):** biçim panelindeki "Sayfa rengi"
  (`onPageStyle`) kalktı; görünüm levhasındaki "Zemin rengi" → "Özel renk…"
  (`customColor`). Kart ⋮ "Zemin rengi" (yalnız renk) yerinde.
- [x] **F12.7 Liste — E1, E2.** Boş son madde varken "+ Yeni öğe" düğmesi
  gizli; madde menüsü açılınca hedef madde vurgulanır, menü maddenin altında.
  **Yapıldı (değiştirildi):** düğme GİZLENMEDİ — art arda en çok 3 boş
  madde açılabilmesi kullanıcı kararı (2026-09-26), gizlemek onu bozuyordu
  (2 test kırıldı). İki "Yeni öğe" tekrarı boş maddenin ipucu "Madde yaz"
  (`itemEmptyHint`) ile giderildi. Madde menüsü: satır kutusu bulunur
  (`itemMenuRowRect`), menü açıkken madde vurgulu, menü maddenin altında.
- [x] **F12.8 AI levhası — M2.** Araç kartları eşit yükseklik (ya da tek sütun
  liste); başlık "Yapay zekâ" (F14.1 sözlüğü).
  **Yapıldı:** `_AiTileGrid` iki sütunlu satırlar (IntrinsicHeight +
  stretch) — yan yana kutular eşit boy, tek kalan son kutu tam genişlik.
  Başlık "Yapay zekâ" (`aiTitle`, `aiHubTitle`, `settingsAi`).
- [x] **F12.9 AI sesli not levhası — K2. KARAR GEREKİR.** Tek birincil eylem
  ("Notu kur"), çipler ve öbür eylemler "Diğer" altında.
  **Yapıldı (KARAR: iki düğme kalsın, çipler Diğer'e):** AI not · Düz not
  yan yana (önceki kullanıcı kararı); Özetleyerek kaydet / Liste notu yap /
  Düzelt varsayılan kapalı "Diğer" çipinin altında (`_moreOpen`). Levhanın
  gözden geçirme evresine test yolu yok — cihazda bakılacak.

**Senin yapacakların:** metin, liste ve belge notunda alt çubuğun aynı
yerde durduğu; biçim paneli klavye açıkken.

## FAZ 13 — Balonlu mod, medya, kalem ve paylaşım akışı

"Balonlu moddan kopyalamaya, paylaşmaya" akışı uçtan uca tamamlanır.

- [ ] **F13.1 Balon yazısı dışarı çıkar (YÜKSEK) — H3, P3.** (a) Paylaşım
  çiplerine "Balonlar" (balonlu notta varsayılan açık): `noteShareText`
  sayfa sırasıyla "Sayfa N — balon metni" (başlıklı balonda başlık); (b)
  balon okuma kartında Kopyala; (c) 💬 balon listesinde "Tümünü kopyala" ve
  "Nota aktar" (sayfa notuna ya da yeni nota). Test: paylaşım metni testi.
- [ ] **F13.2 Balon yazma kartı — H2. KARAR GEREKİR.** Görünür: renk · sil ·
  Bitti; biçim (B/I, dolgu, boyut) tek "Aa" düğmesinin altında; yıldız/acil
  tek "işaret" düğmesinde. Kart yazı alanı en az 3 satır.
- [ ] **F13.3 Tek kalem arayüzü — H5.** PDF/görsel üstündeki `InkToolbar` →
  `PenTray` (çizim ekranıyla aynı; `InkToolMemory` ortak). Eski araç çubuğu
  silinir.
- [ ] **F13.4 Paylaş levhası — P1.** İki bölüm: **Gönder** (Metin · Kopyala ·
  PDF · Görsel · Ekler) ve **Notlar kullanıcısına** (Kopya gönder · Birlikte
  düzenle · Not paketi, misafirde kilitli — F10.5); düğmeye uzun basınca kısa
  açıklama; "Not metni (PDF / Word)" → "Ayarlı PDF / Word…". Web'de Görsel ve
  Ekler neden yoksa ya eklenir ya kılavuzdan çıkar.
- [ ] **F13.5 Görüntüleyicilerin ortak çubuğu — G7.** Görsel, PDF, sunum,
  video, YouTube, transkript: Geri · ad · Paylaş · Eki kopyala · ⋮; türe özgü
  araçlar (kırp/döndür/OCR, balon listesi, hız/PiP) çubuğun altında ya da ⋮'te.
- [ ] **F13.6 Üste sabitleme ipucu — G3.** Sürükleme başlayınca hedef şerit;
  "Bırak: üste sabitle" etiketi yalnız sürüklerken semantik ağaçta.

**Senin yapacakların:** telefonda PDF notu → balonlar → "Metni paylaş"
balonlarla → WhatsApp; balonu kopyala; PDF'e kalemle yaz (yeni tepsi).

## FAZ 14 — Anlaşılırlık: adlar, ayarlar, kılavuz, ipuçları

Her şey tek adla anılır; kılavuz uygulamayı doğru anlatır; gizli jestler
kendini bir kez tanıtır.

- [ ] **F14.1 Terim sözlüğü — U6, C2, G2, K4, P4.** `TERIMLER.md` (kısa
  tablo) + arb düzeltmesi: "Yapay zekâ" (başlıkta da), "madde" (öğe değil),
  hep "sen"; Balonlu ↔ Klasik (dosya levhasında da: "Balonlu: belge notun
  kendisi olur" / "Klasik: belge ek olur"); ses: Dikte · AI sesli not · Ses
  kaydı · Sesli dinle; kopya ailesi: Kopyala (panoya) · Çoğalt · Gönder ·
  Deftere topla; "arşiv defteri" adı her yerden kalkar. Test: `app_tr.arb`
  taraması (yasaklı yazımlar: "Yapay Zeka", "öğe", "-ın/-in" emir + "siz").
- [ ] **F14.2 Ayarlar alanları — S1.** Tek "Kişiselleştir" girişi (üstteki
  kart; alan adı "Video ve oynatma" ya da içeriğe göre); alan özetleri
  içerikten; "Dil" Görünüm'e ya da kendi satırına; "Kartta görünenler" önizlemeli
  alt levha (12 anahtar bir yerde, canlı kart örneği).
- [ ] **F14.3 Yapay Zekâ ekranı — M3.** Başlık bir kez; ayar düğmesinin adı;
  işi olmayan araç (0 başlıksız, 0 kopya) gizli ya da soluk "Şu an iş yok";
  öneri çipleri düğme rolünde.
- [ ] **F14.4 Mikrofon ve arama ipuçları — C5, M7, I3.** Ana ekran
  mikrofonunda basılı tutma rozeti; kalem otomatik algılama ilk seferde
  bildirim; "Anlam" anahtarının ne yaptığı ilk açılışta tek satır.
- [ ] **F14.5 Kılavuzu yeniden yaz — S3, B6, B12.** Her bölüm koddan
  doğrulanarak (tabloda listelenen 10+ çelişki); içindekiler tekrarı kalkar;
  her bölümde "Göster" (ilgili ekrana götürür) — mümkünse. `_en.md` da.
- [ ] **F14.6 Bir kez çıkan ipuçları — U5, E3, B6. KARAR GEREKİR (hangi
  jestler, ne sıklık).** `TipOnce(id)`: bağlamında, işi ilk kez mümkün
  olduğunda tek satırlık balon; gösterilenler cihazda; Ayarlar → "İpuçlarını
  yeniden göster". Öneri: liste notu (madde jestleri), ilk PDF notu (basılı
  tut → balon), ilk görsel (yukarı sürükle → sabitle), ilk ızgara (yana
  kaydır → klasör). En fazla oturumda bir ipucu.

**Senin yapacakların:** kılavuzu baştan sona oku, yanlış kalan yeri bildir.

## FAZ 15 — Erişilebilirlik

TalkBack ile uygulama baştan sona kullanılabilir; büyük yazıda bozulmaz.

- [ ] **F15.1 Sistem yazı boyutu — U2. KARAR GEREKİR.** 2026-08-07 kararı
  ("yazı boyutu tüm telefonlarda sabit") erişilebilirlikle çatışıyor. Öneri:
  Ayarlar → Görünüm → "Sistem yazı boyutunu izle" (varsayılan KAPALI —
  mevcut davranış korunur; açıkken `fixedTypography` sistem ölçeğiyle
  çarpar); kalın metin aynı seçenekte. Taşma testleri 1.3×/1.6× ölçekte.
- [ ] **F15.2 Adsız kontroller — B2, B9, E5, U1.** Kart ⋮; renk daireleri
  (biçim paneli, zemin, palet: renk adı); madde kutucukları (madde metni +
  durum); balonlar (sayfa no + ilk satır); sayfadaki görsel/video/PDF kutusu
  (tür + ad + açıklama); PDF sayfası (Sayfa N/M).
- [ ] **F15.3 Yanlış roller ve çift okuma — G3, M3, B2.** Seçim çipleri
  `checkbox` → tekli seçimde `inMutuallyExclusiveGroup`/radyo, eylem çipinde
  düğme; kart tek düğüm (`MergeSemantics`); kökteki "Bırak: üste sabitle"
  etiketi kalkar (F13.6 ile).
- [ ] **F15.4 Dokunma hedefleri ≥ 48 dp — U3.** Görünüm değişmeden dokunma
  alanı büyür (`materialTapTargetSize`, saydam dolgu): kart ⋮, Klasörleri
  büyüt, Süz, ayar ✨, `ListeningHeaderButton`.
- [ ] **F15.5 Hareketi azalt — U4.** `motionOf(context)`
  (`MediaQuery.disableAnimationsOf`): not açılış geçişi solmaya, `ExpandReveal`/
  `RevealUp`/`ScaleSettle`/`PopIn`/`PressScale` anında.
- [ ] **F15.6 Küçük yazı ve kontrast.** 12 sp altındaki sabit yazılar
  (`fontSize: 8.5…11.5`, ~80 yer) taranır: okunan metin en az 12, yalnız
  rozet/sayaçta küçük; ikincil metin kontrastı ≥ 4,5:1 (kırık beyaz ve kâğıt
  temada `onSurfaceVariant`).
- [ ] **F15.7 Erişilebilirlik testleri.** Ana ekran, not ekranı, biçim paneli,
  Süz, Paylaş, AI levhası için `androidTapTargetGuideline`,
  `labeledTapTargetGuideline`, `textContrastGuideline` widget testleri.

**Senin yapacakların:** TalkBack açıkken: not oluştur, listeyi işaretle, PDF'e
balon bırak, paylaş. Sistem yazı boyutunu en büyüğe al, ana ekran ve not ekranı.

## FAZ 16 — Görsel bütünlük ve tekrar temizliği

Tek tasarım dili: aynı simge aynı anlam, levhalar aynı iskelet, renkler
temadan.

- [ ] **F16.1 Simge sözlüğü — U8, B7, P7, Q4.** Tek simge = tek anlam:
  Arşiv (`archive`) ↔ Gelen (`inbox`/zarf — `move_to_inbox` arşive çok
  benziyor); Defter (`menu_book`), Not paketi (paket/zip simgesi), arşiv
  kutusu yalnız Arşiv; palet yalnız "görünüm"; Kopyala (`content_copy`) ↔
  Çoğalt (`library_add`) ayrımı her yerde. Sözlük `TERIMLER.md`'nin yanına.
- [ ] **F16.2 Levha iskeleti — U7.** `showAppSheet` için tek başlık bileşeni
  (başlık solda + ✕ sağda; menü levhalarında başlık = not adı) ve tek bölüm
  başlığı stili (cümle düzeni, `labelLarge`); Süz, Ekle, ⋮, Paylaş, AI,
  Görünüm aynı iskelette.
- [ ] **F16.3 Renk tokenları — U9.** Tema dışı `Color(0x…)` (151) ve
  `Colors.white/black` (207) taranır: arayüz rengi olanlar `ColorScheme`/
  `NoteColors`'a; kasıtlı olanlar (fotoğraf üstü koyu yuvarlak vb.) yorumlu
  kalır. Koyu, kâğıt ve kırık beyaz temada ekran turu.
- [ ] **F16.4 Yükleniyor ve hata durumları — U10.** Ana ekran, klasör, arşiv,
  çöp, paylaşılanlar ilk yüklemede iskelet; hata görünümü tek bileşen (F10.4
  metniyle).
- [ ] **F16.5 Kalan tekrar taraması.** Faz 11–15'ten sonra aynı işin iki
  yerde durduğu kalan yerler (ör. Hesap makinesi, "Notta ara", palet) — liste
  çıkar, gereksizleri kaldır.

**Senin yapacakların:** koyu temada her ana ekranın görüntüsü; simgeleri
"bu ne?" diye sorduğun yer kaldı mı.

## FAZ 17 — Ölçüm, uçtan uca test, cihaz turu

Yapılanların cihazda doğru ve akıcı olduğunu ölçerek bitirir.

- [ ] **F17.1 Kare ölçümü (F9.1) — U11.** Actions → Derleme → "Kare ölçümü";
  `perf-summary` p90 değerleri HAFIZA'ya taban. Ana ekran kaydırma, not açma,
  biçim paneli, PDF kaydırma, balon bırakma senaryoları `integration_test`te
  var mı bak, yoksa ekle.
- [ ] **F17.2 Uçtan uca akış testleri.** `integration_test/`: (1) + → Metin →
  yaz → paylaş metni; (2) + → Dosya → PDF → balon → paylaş (balonlarla); (3)
  iki sayfalı not → kopyala; (4) liste → işaretle → işaretlileri sil. Web'de
  Playwright betiği (Ek A) aynı akışları ekran görüntüsüyle.
- [ ] **F17.3 Web ağır işler.** F10.1'den sonra web'de büyük (20+ MB, 100+
  sayfa) PDF ile ekleme/damgalama süresi ve arayüz donması; gerekirse parça
  parça işleme ya da "web'de en çok N MB" uyarısı.
- [ ] **F17.4 KALANLAR sadeleştirme — U12.** ~80 "cihazda görülmedi"
  maddesini Faz 10–16 sonrası tek on dakikalık duman testine indir (her alan
  1-2 adım); eskiyenleri at.
- [ ] **F17.5 (İsteğe bağlı) Dev dosyalar.** Faz 12–13 `note_editor_screen.dart`
  ve `items_editor.dart`'a çok dokunduysa yeni konu dosyalarına bölme (F9.3
  deseni). Dokunmadıysa ERTELENDİ.

**Senin yapacakların:** F17.1 koşusu, duman testi turu.

---

## Ek A — Web'de ekran turu (sonraki oturumlar için)

Bulutta Chromium + Playwright hazır (`require('playwright')`). Yayındaki web
sürümü `main` ile aynıdır (Cloudflare Pages, her `main` push'unda); dalda
yapılan değişikliği görmek için yerelde `flutter build web --wasm` +
`python3 -m http.server`.

- Telefon görünümü 412×915, geniş 1280×800; `locale: 'tr-TR'`.
- Flutter semantik ağacı: sayfa yüklenince
  `document.querySelector('flt-semantics-placeholder').click()` → her
  `flt-semantics` öğesinin `aria-label`, `role` ve kutusu okunur; düğmeye
  etiketine göre dokunmak için kutunun ortasına `page.mouse.click`.
- Kalıcı profil (`launchPersistentContext`) misafir oturumunu betikler arası
  korur. İlk açılış otomatik misafir hesap açar (Firebase'de anonim kullanıcı):
  tur bitince Ayarlar → Hesap → "Hesabımı ve verilerimi sil".
- Dosya seçici: `page.waitForEvent('filechooser')` + `setFiles`; gerçek PDF
  için Chromium'un `page.pdf()`'i kullanılabilir.
- Android'e özgü yüzeyler (kamera, tarama, dikte, kalem, widget) web'de yok —
  onlar "Senin yapacakların"da.
