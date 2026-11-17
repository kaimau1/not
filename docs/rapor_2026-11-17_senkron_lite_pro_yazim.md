# Rapor — 17 Kasım 2026: senkron maliyeti, Lite/Pro, yazım denetimi, hızlı ekle, akıllı liste

16 Kasım raporunun (`rapor_2026-11-16_beyin_firtinasi.md`) devamı. O rapordaki bulguları
tekrarlamıyorum; üstüne koyuyorum. Kasma tarafı ayrı dosyada: `docs/perf/kasma_envanteri.md`
(69 kayıt, 9 paket). **Kod değişmedi; bu dosya öneri ve plandır.**

**Etiketler:** `[KOD]` bu oturumda koddan okundu (dosya:satır) · `[ÇIKARIM]` koda bakarak vardığım
sonuç · `[DIŞ]` 17 Kasım 2026'da resmî sayfadan okundu · `[TAHMİN]` varsayıma dayalı hesap.
**Hiçbir şey çalıştırılmadı:** bu bilgisayarda Flutter SDK yok; test koşamadım. Koddan okuyarak
bulduğum hataların kırmızı testleri Ek 1'de hazır.

---

## 0. Özet

1. **Maliyet korkun bu fiyat modelinde haklı — ama çözümü var.** Bugünkü kodla aktif bir
   kullanıcının metin senkronu yılda kabaca 0,18–0,38 $ tutar. "Cüzi yıllık abonelik + ücretsiz
   kullanıcıya da senkron" modelinde bu, abonelik gelirinin taşıyamayacağı bir yük: başa baş için
   kullanıcıların %6–13'ünün abone olması gerekir, gerçekçi oran %1–3 (§1.2).
2. **İki teknik değişiklik bu maliyeti ~15 kat düşürür:** (a) açılışta bütün notları yeniden
   okumak yerine yalnız değişenleri dinlemek, (b) buluta yazmayı seyreltmek. Sonrası yılda
   0,01–0,02 $/kullanıcı; başa baş abone oranı %0,4–0,8'e iner. Bu iş lüks değil, modelin ön
   koşulu (§1.3).
3. **Lite kullanıcıya senkron verilebilir.** Önerim: Lite'ta metin senkronu açık; pahalı olanlar
   (bulut ek deposu, yapay zekâ, sürüm geçmişi, ortak düzenleme) Pro'da. Lite'ın ekleri
   kullanıcının kendi Google Drive'ına gider; bize maliyeti sıfır, altyapısı hazır (§2).
4. **Asıl batırıcı senkron değil, kontrolsüz kullanım:** hata yüzünden yazma döngüsü, taklit
   istemci, depolama indirme trafiği, yapay zekâ. Altı ucuz korkuluk öneriyorum; ilki (bütçe
   uyarısı) bugün 5 dakikada kurulur (§1.4).
5. **Lite ve Pro iki ayrı uygulama olmasın.** Tek uygulama, içinde iki katman. İki mağaza kaydı iki
   kat bakım, bölünmüş puan, yükseltmede veri taşıma demek (§2.1).
6. **Yazım:** bugünkü sistem "kelime bitince otomatik düzelt"; görsel denetim (altını çiz, dokununca
   öner) yok ve Türkçe ekleri tanımıyor. Yedi kademeli plan: önce ölçüm seti, sonra ek tanıma,
   Türkçe harf geri kazanımı, altı çizili denetim, notu toplu denetle (§3).
7. **Hızlı eklede iki yeni hata buldum** [KOD]: "rapor yaz" yazınca "yaz" siliniyor, nota "rapor"
   ekleniyor; ve ekleme, levha açılırken alınan eski not kopyasının üstüne yazıyor (başka cihazdaki
   değişikliği ezebilir) (§4.1).
8. **Akıllı listedeki sözlük hatasını yeniden doğruladım** [KOD]: 1100 maddelik market sözlüğü
   akıllı listenin ayrıştırıcısına girmiyor (§5.1).
9. **Kasma:** 11 levha klavyenin her karesinde baştan kuruluyor; "Geri al" çubuğu görünürken her
   karede dizilim yenileniyor; yazarken ana ekran aracı ve hatırlatıcı eşitlemesi araya giriyor.
   Tam liste ve paketler envanterde.

**Senden beklenen kararlar** §7'de.

---

## 1. Senkron maliyeti

### 1.1 Bugün ne okuyup ne yazıyoruz [KOD]

| Kalem | Nerede | Davranış |
|---|---|---|
| Not listesi | `notes_repository.dart:298` | Silinmemiş BÜTÜN notlar sınırsız dinlenir |
| Takvim | `calendar_repository.dart:106, 192, 273, 314, 341, 366, 393` | Yedi koleksiyon sınırsız dinlenir |
| Klasör, arkadaş, gelen, paylaşım, ayar, kota, yapılandırma | `folders_repository.dart:107`, `friends_repository.dart:165`, `inbox_repository.dart:138`, `note_shares_repository.dart:128–143`, `prefs_sync.dart:198`, `ai_gate.dart:23`, `app_update.dart:54` | Oturum boyu dinleyiciler |
| Otomatik kayıt | `kEditorSaveDelay` 2 sn, en geç 10 sn (`akicilik.md:55`) | Yazarken dakikada 6–30 yazma |
| Ayar eşitleme | `prefs_sync.dart:221` | 20 sn'de bir yoklama; değişiklik varsa yazma |
| Ortak düzenleme nabzı | `note_presence.dart:72` | 25 sn'de bir yazma (yalnız paylaşılan notta olmalı; doğrulanmadı, envanter K-53) |
| Çevrimdışı önbellek | `main.dart:135–136` | Açık, 100 MB |

**Faturayı belirleyen kural** [DIŞ, Firestore fiyat belgesi]: "Çevrimdışı kalıcılık açıksa ve
dinleyici 30 dakikadan uzun süre kopuk kaldıysa, yepyeni bir sorgu yapmışsın gibi okunan her belge
için ücretlenirsin." Yani uygulama yarım saatten uzun kapalı kaldıktan sonra her açılışta **bütün
notlar ve bütün takvim kayıtları yeniden okunmuş sayılır.** 300 notlu kullanıcı günde üç kez açarsa
günde ~1.350 okuma. Okuma kaleminin neredeyse tamamı bu.

Ücretsiz kota [DIŞ]: günde 50.000 okuma, 20.000 yazma, 1 GiB; ayda 10 GiB çıkış. Kota proje
genelidir, kullanıcı başına değil.

### 1.2 Kullanıcı başına hesap [TAHMİN]

Varsayım: 300 not + 150 diğer belge, günde 3 "soğuk" açılış, günde 10 dakika yazma. Birim fiyat
aralığı: 100.000 okuma 0,03–0,06 $, 100.000 yazma 0,09–0,18 $ (bölgeye göre; `europe-west1`
satırını resmî sayfadan bu oturumda da okuyamadım, hesaplayıcıdan teyit et).

| | Okuma / yıl | Yazma / yıl | Yıllık maliyet (aktif kullanıcı başı) |
|---|---|---|---|
| **Bugünkü kod** | ~480.000 | ~48.000 | **0,18–0,38 $** |
| Kademe 1: yazmayı seyrelt | ~480.000 | ~8.000 | 0,15–0,30 $ |
| **Kademe 2: + yalnız değişeni dinle** | ~15.000 | ~8.000 | **0,012–0,023 $** |

**Gelir tarafı.** Play abonelik payı %15 [DIŞ: "%10 + %5 faturalama ücreti", yıllık ilk 1 milyon $].
Türkiye'de KDV ve %15 kesinti (16 Kasım raporu §4.4) düşünce elde kalan kabaca fiyatın %60'ı
[TAHMİN; mali müşavirle teyit]. Örnek: yıllık fiyatın net karşılığı 3 $ ise:

| | Başa baş için gereken abone oranı |
|---|---|
| Bugünkü kod | %6 – %13 |
| Kademe 2 sonrası | %0,4 – %0,8 |

Not uygulamalarında gerçekçi abone oranı %1–3. **Sonuç: bugünkü kodla bu model zarar eder;
Kademe 2 ile rahat döner.** Kendi fiyatını koyup yeniden hesapla: `gereken oran = kullanıcı başı
yıllık maliyet ÷ abone başına net gelir`. (Kurulumların hepsi aktif değildir; aylık aktif
kullanıcıya bölersen oranlar yarıya yakın düşer. Ben temkinli tarafı yazdım.)

16 Kasım raporundaki "korkulacak kalem değil" cümlesi aylık 50 TL'lik abonelik varsayımıyla
yazılmıştı. Cüzi yıllık fiyatta o cümle geçerli değil; düzeltiyorum.

### 1.3 Maliyeti düşüren işler (Firebase'de kalarak)

**S1 — Yalnız değişeni dinle (okumayı ~30 kat düşürür; en büyük kazanç).**
Liste yerel önbellekten okunur (ücretsiz), sunucuya yalnız "son eşitlemeden beri değişenler"
sorgusu bağlanır.

- Her bulut yazımı `syncAt: serverTimestamp` alanı taşır. İmleç istemci saatine DEĞİL bu alana
  dayanır (cihaz saati yanlış olan telefon değişiklik kaçırmasın).
- `watchNotes()`: önce `get(Source.cache)` ile tüm liste, sonra `where('syncAt', '>', imleç)`
  dinleyicisi. Tek alan dizini otomatik; bileşik dizin gerekmez.
- Silme: çöp zaten yumuşak silme (`deletedAt`), delta sorgusuna girer. Kalıcı silinen (30 gün)
  belge için: imleç 30 günden eskiyse TAM yeniden okuma.
- Güvenlik ağı: haftada bir `count()` toplam sorgusuyla (1000 belge başına 1 okuma) yerel sayı
  sunucuyla karşılaştırılır; tutmuyorsa tam okuma. Önbellek dolup belge atarsa (100 MB sınırı)
  eksik not kalmasın diye.
- Aynı kalıp takvim, görev, klasör koleksiyonlarına; ya da onlar yalnız ilgili ekran açılınca
  dinlenir.
- **Risk yüksek:** senkron mantığına dokunur. Şartlar: yerel tam yedek, `rules-test` yeşil, iki
  cihazlı senaryo testleri (çevrimdışı düzenleme, saat farkı, 31 gün kapalı cihaz, silinen not),
  geri alınabilir bayrak. Ayrı faz olarak planlanmalı; "bu iş nasıl batar" listesi plan
  aşamasında yazılır.
- Yan kazanç: açılış hızlanır, not sayısıyla büyüyen kasma (envanter K-22) hafifler.

**S2 — Yazmayı seyrelt (yazmayı ~6 kat düşürür; küçük ve güvenli iş).**
Yerel kayıt anında sürer (önbellek); buluta gidiş 2 sn yerine 20–30 sn'de bir ve uygulama arka
plana giderken kesin. Kapanış, not değiştirme ve `paused` anında hemen yazılır. İki cihazda aynı
anda aynı notu düzenleyen için gecikme 30 sn'ye çıkar: Pro'da 2–5 sn kalabilir (anlık senkron
vaadi), Lite'ta 30 sn.

**S3 — Boşa yazmaları kes.** Ayar eşitlemesi yalnız değişince (envanter K-25); nabız yalnız
paylaşılan notta (K-53); sürüm geçmişi Lite'ta 3, Pro'da 30.

**S4 — Ekleri Firebase'den çıkar.** Firebase Depolama: 0,026 $/GB/ay saklama, **0,12 $/GB indirme**
[DIŞ, eski tip kova]. İndirme trafiği kontrolsüz kalemdir. Lite'ın ekleri kullanıcının kendi
Drive'ına (`drive.appdata`; altyapı `DriveStore` olarak hazır). Bu izin "hassas olmayan" sınıfta
[DIŞ] → ek doğrulama/denetim yükü yok; Drive API standart kullanımda ücretsiz [DIŞ]. Pro'nun
ekleri için ileride Cloudflare R2: 0,015 $/GB/ay, **indirme trafiği ücretsiz**, 10 GB bedava
[DIŞ] — Firebase'den ucuz ve trafik sürprizi yok; küçük bir aracı servis gerekir, şimdi şart değil.

**Sıra önerim:** korkuluklar (§1.4, hemen) → S2 + S3 (küçük) → S4'ün Lite kısmı (kural + varsayılan)
→ S1 (ayrı faz, en büyük kazanç).

### 1.4 Korkuluklar — "bir sabah büyük fatura" olmasın

| # | Önlem | Maliyeti | Neyi önler |
|---|---|---|---|
| 1 | Google Cloud bütçe uyarısı: 5 / 20 / 50 $ eşikleri, e-posta + telefon | 5 dk, bugün | Geç fark etmeyi. Firebase kendiliğinden durmaz; fiyat sayfasında harcama tavanı yok [DIŞ] |
| 2 | **Boşta yazma bekçisi (test):** uygulama bir not açıkken 2 dakika boşta beklerse bulut yazımı 0, dinleyici sayısı sabit | 1 küçük test | Hata yüzünden sonsuz yazma döngüsünü (takvimdeki "ping-pong" önlemi boşuna yazılmamış) — yayına çıkmadan yakalar |
| 3 | App Check'i zorla (Play Integrity kurulu, yalnız zorlama kapalı) | konsol + izleme | Taklit istemcinin faturayı şişirmesini |
| 4 | Kuralda hız sınırı: not güncellemesi, önceki `syncAt`'ten en az 1–2 sn sonra | kural + `rules-test` | Döngüye giren ya da değiştirilmiş istemciyi sunucuda keser |
| 5 | Uzaktan ayar: `config/app`'e `senkronKipi` (anlık / aralıklı / duraklat) ve `liteYazmaAraligi` | küçük kod; **`config/app` bayrağı eklemek senin kararın** (HAFIZA kural 17) | Kriz anında uygulama güncellemesi beklemeden frene basmayı |
| 6 | Depolama tavanını sunucuda uygula (bugün istemcide sayılıyor) | Functions sayacı ya da Lite'ta Storage'ı tümden kapat | 2 GB doldurup tekrar tekrar indirtmeyi |

Bilerek önermediğim: bütçe aşılınca faturalandırmayı otomatik kapatan işlev. Projeyi tümden
durdurur ve Google'ın kendi uyarısına göre kaynaklar geri getirilemeyecek biçimde silinebilir
[hatırladığım bilgi, teyit etmedim]. Frene uzaktan ayarla basmak (5) daha güvenli.

### 1.5 Altyapıyı değiştirmek gerekir mi?

| Seçenek | Rakam [DIŞ] | Görüşüm |
|---|---|---|
| Firebase'de kal + §1.3 | 100.000 aktif kullanıcıda metin senkronu ~100–200 $/ay [TAHMİN] | **Önerim.** Kurallar, testler, çevrimdışı katman hazır |
| Lite senkronu Cloudflare'de (Workers + D1) | 5 $/ay sabit; içinde ayda 25 milyar satır okuma ve 50 milyon satır yazma; sonrası 1 $/milyon yazma | Birim maliyet çok düşük. Ama ikinci bir senkron yolu = iki kat hata yüzeyi, yetkilendirme ve çevrimdışı kuyruk elle yazılır. **50.000 kullanıcıdan önce düşünme** |
| Lite senkronu tümüyle kullanıcının Drive'ında | 0 $ | Mümkün (izin hassas değil, kota bol) ama yeni bir senkron motoru; anlık değil, paylaşım yok. S1 sonrası kazancı yılda kullanıcı başı ~0,015 $; değmez. **C planı** |
| Supabase / kendi sunucu | sabit aylık | 16 Kasım raporundaki görüş aynı: şimdi değil |

---

## 2. Lite ve Pro

### 2.1 Tek uygulama, iki katman

"Lite" ve "Pro" iki ayrı uygulama olursa: iki mağaza kaydı, iki inceleme, bölünmüş puan ve yorum,
Lite'tan Pro'ya geçişte yeniden kurulum, iki paket adı için ayrı Firebase ayarı. Karşılığında tek
kazanç küçük APK'dır; o da isteğe bağlı indirme ile çözülür (16 Kasım §2.6). **Önerim: tek uygulama;
"Lite" ücretsiz katmanın adı, "Pro" aboneliğin adı.** `premiumUntil` alanı ve Premium ekranı zaten
var [KOD: `premium_screen.dart`, sunucudan yazılır].

### 2.2 Kimde ne olsun — ilke: "bize her kullanımda para yazan şey Pro'da"

| Özellik | Lite (ücretsiz, reklamsız) | Pro (yıllık) | Neden |
|---|---|---|---|
| Not, liste, hatırlatıcı, takvim, kalem, PDF | sınırsız | sınırsız | Cihazda çalışır; maliyeti yok |
| **Metin senkronu** | var; aralıklı (≈30 sn, açılış/kapanışta kesin) | anlık | S1 + S2 sonrası Lite maliyeti yılda ~0,01–0,02 $ |
| Cihaz sayısı | 2 | sınırsız + web | Anlaşılır sınır; sayım sunucuda gerekir. İstersen Lite'ta da sınırsız bırak: maliyet farkı küçük |
| Ekler (görsel, PDF, ses) | cihazda + kendi Drive'ına | Drive ya da bulut depo (ör. 10 GB) | Depolama ve indirme trafiği gerçek para |
| Sürüm geçmişi | son 3 | 30 gün | Her sürüm bir yazma + saklama |
| Paylaşım | not gönder (kopya), 1 ortak liste | ortak düzenleme, kimin yazdığı görünür, ortak klasör | Nabız ve çok dinleyici yazma üretir |
| Yapay zekâ | cihaz içi her şey + günde az puan (hafif model) ya da kendi anahtarın | ağır işler: video/ses dökümü, PDF sohbet, tüm notlarla sohbet | En büyük değişken maliyet (16 Kasım §5) |
| Yazım denetimi, akıllı liste, hızlı ekle | var | var + AI ile "notu düzelt" | Sözlük cihazda; AI kısmı ücretli |
| Yedek | elle tam yedek | parolalı + otomatik yedek | Güven özelliği; maliyeti düşük, değeri yüksek |
| Görünüm | çekirdek temalar | ek tema, yazı tipi, kâğıt | Maliyeti sıfır Pro nedeni |

**Dikkat edilecekler:**

- Lite'ta senkron "aralıklı" olunca iki cihazda aynı notu aynı anda düzenleyen kullanıcı çakışma
  görür. Üç yönlü birleştirme var (`text_merge.dart`); davranışı iki cihazlı testle sabitle.
- Senkronu ücretsiz verip sonra geri almak güven kırar. Lite'ın kapsamını ilk günden yaz; sınır
  koyacaksan (2 cihaz) baştan koy.
- "Ömür boyu" satacaksan yalnız AI içermeyen özellikler için (16 Kasım §7.3-7).

### 2.3 Fiyat

Rakamı sen koy; hesap §1.2'deki formülle. İki uyarı: (1) Play'de ücretsiz yayınlanan uygulama
sonradan ücretliye çevrilemez ama uygulama içi abonelik her zaman eklenir; (2) yıllık + aylık
birlikte sun: aylık fiyat yıllığı "ucuz" gösterir, yıllık asıl satılandır.

---

## 3. Yazım denetimi — geliştirilmiş plan (v3)

> "Okuduğun plan" olarak depoda Faz 70'i (yazım düzeltici v2, bitti) ve `editor.md:135` notunu
> buldum. Başka bir belgeyi kastettiysen söyle.

### 3.1 Bugün ne var [KOD]

- **Otomatik düzeltme**, kelime bitince (boşluk/noktalama) ve yalnız tek karakter yazılırken:
  `auto_spell.dart:259–365`. Yapıştırma ve dikte dokunulmaz. **Varsayılan kapalı** (`:61`).
- Karar sırası (`spell_engine.dart:111–145`): dokunulmazlar → öğretilen düzeltme → 45 satırlık kural
  tablosu (`spell_fix.dart:20–66`: "herşey" → "her şey") → bilinen kelimeyse dur → boşluk yerine
  basılan harfi ayır → tek adaylı yakın eşleşme → cihazın yazım denetçisi (`:508–538`).
- Backspace geri alır; reddedilen düzeltme bir daha gelmez; kişisel sözlük cihazda
  (`spell_memory.json`), cihazlar arası gitmez.

### 3.2 Eksikler

| # | Eksik | Etkisi |
|---|---|---|
| Y1 | **Görsel denetim yok.** Hatalı kelimenin altı çizilmiyor, dokununca öneri yok | Kullanıcı ya "körlemesine düzelt"i açar ya hiçbir şey görmez. "Yazım denetimi" denince beklenen bu |
| Y2 | **Türkçe ekleri tanımıyor.** "Bilinen kelime" = aynen 3 kez görülmüş yüzey biçimi (`spell_learn.dart:79`). "kalemlerimizden" hiç görülmediyse bilinmiyor sayılır | Yanlış düzeltme riski; bu yüzden eşik çok temkinli ve yakalama oranı düşük. Tek koruma "aday yazılanın kökü/uzantısıysa dokunma" (`spell_engine.dart:190`) |
| Y3 | **Türkçe harfsiz yazım** ("calisma", "guzel", "degil") yalnız rastlantıyla düzeliyor | Türkçe yazanların en sık hatası |
| Y4 | Kural tablosu 45 satır | "de/da", "ki", "mi" ayrımı, kesme işareti, şapka yok ya da kısmi |
| Y5 | Yapıştırılan ve dikte edilen metin hiç denetlenmiyor | Dikte çıktısı hatanın en yoğun olduğu yer |
| Y6 | Doğruluğu ölçen bir veri seti yok; testler tek tek örnek | "Geliştirdik" demenin ölçüsü yok; ısrar hatası böyle kaçmıştı |
| Y7 | Kişisel sözlük cihazda kalıyor | Yeni cihazda sıfırdan öğrenir |
| Y8 | Hız bütçesi yok; yakın eşleşme bütün sözlük kovalarını geziyor (`:185–203`) | Sözlük büyürse kelime sonunda takılma |

### 3.3 Plan — yedi kademe (her biri ayrı paket)

**Y-0 Ölçüm seti (önce bu; kod davranışı değişmez).**
`test/spell_corpus/` altında iki dosya: (a) 500 DOĞRU Türkçe kelime, çoğu ekli ("evlerimizdeki",
"gidiyorduk", "İstanbul'dan") — hiçbirine dokunulmamalı; (b) 300 yanlış → doğru çifti (komşu tuş,
eksik/fazla harf, harfsiz yazım, bitişik "de/ki/mi"). Test iki sayı üretir: **yanlış düzeltme
oranı** (hedef %0,5'in altı, mandal) ve **yakalama oranı** (yalnız artar). Bugünkü sayılar taban
olarak yazılır. Sonraki her kademe bu iki sayıyla kabul edilir.

**Y-1 Ek tanıma (Y2).** Küçük, saf bir Türkçe ek çözücü: kelimeyi kök + ek zinciri olarak dener
(çoğul, iyelik, hâl, bildirme, yaygın fiil ekleri; ünlü uyumu ve ünsüz yumuşaması denetimiyle).
Kök sözlükteyse ve ek zinciri kurallıysa kelime "bilinir". Kök sözlüğü: mevcut yerleşik liste +
notlardan gelen + açık lisanslı bir Türkçe kök listesi (lisansı kontrol edilip lisans sayfasına
yazılır). Hızlı ekledeki kaba kök bulucu (`quick_drop.dart:119` `quickStem`) bununla değiştirilir:
tek kök bulucu. Kabul: yanlış düzeltme oranı düşer, 500 doğru kelimenin tamamı "bilinir".

**Y-2 Türkçe harf geri kazanımı (Y3).** Harfsiz yazılan kelimenin Türkçe harfli TEK karşılığı
sözlükte varsa düzelt ("calisma" → "çalışma"); birden fazlaysa ("aci": acı/açı) dokunma, yalnız
öner. Ayrıştırıcıda `quickAscii` eşleştirmesi zaten var; yazım motoruna da girer.

**Y-3 Kural tablosunu büyüt (Y4).** 45 → ~300 satır yaygın yanlış (elle derlenir; telif yok).
Bağlama bağlı olanlar ("bende" → "ben de") **otomatik uygulanmaz**, yalnız Y-4'teki öneri olarak
çıkar: yanlış düzeltme güveni yok eder.

**Y-4 Altı çizili denetim (Y1) — üç kipli ayar:** Kapalı / Yalnız göster / Otomatik düzelt.

- Altı çizgi **boyama katmanında** çizilir (aramadaki `SearchHighlight` kalıbı). Metin
  parçalarına (span) KONMAZ: `buildTextSpan` her çizimde çalışır, tuş başına bütün metni yeniden
  biçimlendirir (envanterdeki kök nedenlerin aynısı).
- Hesap artımlı: yalnız değişen paragraf yeniden denetlenir; not açılışında tam tarama arka planda
  (`runHeavy`), sonuç paragraf özetine göre önbellekte.
- Kelimeye dokununca küçük menü: öneriler · "Sözlüğe ekle" · "Hep böyle düzelt" · "Bu notta
  dokunma". Bugünkü hafıza işlevleri (`learnFix`, `rejectPair`, `keep`) bu düğmelere bağlanır.
- Flutter'ın hazır yazım denetimi (`SpellCheckConfiguration`) kullanılmaz: her değişiklikte bütün
  metni platform kanalından geçirir; kanal çağrısı kareyi bekletir.
- Editöre görünür yeni katman → `kasma-kontrol` + bütçe senaryosu ("denetim açıkken 5 tuş": kök
  kurulum 0, satır kurulum 0) + cihaz A/B (`yaz` evresi) şart.

**Y-5 Toplu denetim (Y5).** "Notu denetle": bütün bulgular listede, tek tek ya da hepsi kabul;
değişiklik öncesi/sonrası görünür; tek "Geri al". Yapıştırma ve dikte sonrası küçük bir çip:
"3 olası yazım hatası · Gözden geçir". Pro'da ek: "Yapay zekâ ile düzelt" (cümle düzeyi, hafif
model, yalnız fark gösterilir; kilitli not gitmez).

**Y-6 Sözlük eşitleme ve hız (Y7, Y8).** Kişisel sözlük tek küçük belgeyle (`users/{uid}/meta/spell`)
yalnız uygulama arka plana giderken yazılır. Yakın eşleşme için ön dizin (ilk harf + uzunluk
kovası, yükte bir kez, arka planda). Bütçe: kelime sonu kararı 1 ms'nin altında.

**Varsayılan:** Y-0…Y-3 bitince "Yalnız göster" kipi varsayılan AÇIK olabilir (hiçbir şeyi
değiştirmez, risksiz). Otomatik düzeltme kullanıcı seçimi kalır.

**Yapma:** büyük hazır sözlük kütüphanesi ekleme (APK büyür, Türkçe eklerde zayıf); her tuşta
denetleme (yalnız kelime sonunda ve duraklamada).

---

## 4. Hızlı ekle — geliştirme planı

16 Kasım raporundaki H1–H8 ve fikir listesi geçerli. Aşağısı yeni bulgular ve sıralı plan.

### 4.1 Yeni bulgular [KOD — çalıştırılmadı, kırmızı testleri Ek 1'de]

| # | Sorun | Yer | Sonuç |
|---|---|---|---|
| **H9** | Sondaki genel fiiller komut sayılıp içerikten siliniyor. Komut listesi `ekle` dışında `koy`, `yaz`, `kaydet`, `not et`, `not al` içeriyor (`quick_drop.dart:34–37`). Hedef not bulunamasa bile içerik komutsuz dönüyor (`:276–278`) | `quick_drop.dart`, `quick_drop_sheet.dart:280, 302` | Yazarak "rapor yaz" → nota **"rapor"** eklenir. Sesle söylenince "kullanıcı bir not adlandırdı" sayılır, yapay zekâya ya da "Hangi nota?" sorusuna gider. Yapılacaklar listesi kullanan herkes bunu yaşar |
| **H10** | Ekleme, levha AÇILIRKEN alınan not kopyasından hesaplanıp alanın TAMAMINI yazıyor (`_candidates` `:236` → `_noteOf` `:398` → `quickDropFields(note, …)` `:417` → `updateFields` `:426`) | `quick_drop_sheet.dart` | Levha açıkken not başka cihazda, ortak kişide ya da editörde değiştiyse **o değişiklik ezilir.** 16 Kasım'daki H2 (geri al) ve H4 (bayat aday) aynı kökün yüzleri |
| H11 | Başlıksız notlar hedef olamıyor (`:62`); uygun not yoksa levha çıkmaz sokak | `quick_drop_sheet.dart:53–64` | Yeni kullanıcı ilk denemede "hiçbir şey olmadı" görür |

Şüphelenip çürüttüğüm: "saat 14:30 toplantı" gibi girdide saat iki noktasının "ad: içerik"
ayırıcısı sayılması. Kodu izledim (`quick_drop.dart:184–198`, `_bestTitles` `:342–376`): iki
noktadan önceki rakam başlıkla eşleşmediği için kural devreye girmiyor. Sorun değil; yine de Ek
1'de bekçi testi var.

**Düzeltme tarifleri:**

- **H9:** komut fiili yalnız bir hedef BULUNDUĞUNDA içerikten atılır. Hedef yoksa özgün metin
  aynen içerik olur; `command: true` yalnız `ekle` ailesi için döner (`koy/yaz/kaydet/not al` tek
  başına "kullanıcı not adlandırdı" kanıtı değildir).
- **H10:** uygulama anında notun GÜNCEL hâli okunur; liste notunda yeni madde atomik eklenir
  (Firestore dizi birleştirme ya da işlem), yazı notunda işlem içinde sona eklenir. Geri al yalnız
  eklenen madde kimliklerini çıkarır. Veri yazma yolu değiştiği için `rules-test` ve "levha
  açıkken not değişti" testi şart.
- **H11:** aday yoksa ve her zaman en başta: "Yeni not olarak kaydet" çipi; isteğe bağlı sabit bir
  "Gelen kutusu" notu.
- **H1 ("süt bitti" listeyi bitiriyor; 16 Kasım raporundan):** yalnız metne bakarak çözülmez —
  ses tanıma noktalama vermez, "süt ekmek bitti" ile "süt bitti" aynı görünür. Çözüm ses
  oturumundaki zaman bilgisinden gelir: yalın "bitti" yalnız kendinden önce ~0,7 sn sessizlik
  varsa bitiş sayılır; "liste bitti", "bu kadar", "not bitti" her zaman bitiş sayılır
  (`done_word.dart:7–16`, `voice_listen_session.dart`).

### 4.2 Sıralı plan

**HE-1 Sağlamlaştırma (hata; dondurmaya takılmaz).** H9, H10, H1, H3 (belge/kod süre
tutarsızlığı), H11'in "Yeni not olarak kaydet" kısmı. Kabul: Ek 1'deki testler yeşil; hızlı ekle
bütçe senaryosu yazılmış (envanter K-64).

**HE-2 Görünür güven.** Canlı önizleme satırı: "→ Market listesi · süt, ekmek (2 madde)".
Kullanıcı Ekle'ye basmadan neyin nereye gideceğini görür; yanlış hedef hatasının çoğunu baştan
keser. Üç anahtar (AI / klavye / dinle) ⚙ arkasına. Yapay zekâ beklerken 300 ms sonra ince ilerleme
+ "Ben seçeyim". Çiplerin başına arama (12 sınırı kalkar).

**HE-3 Uygulamayı açmadan ekle (asıl değer).** Sırayla, hepsi küçük: başlatıcı kısayolu → 1×1 ve
4×1 ana ekran aracı → hızlı ayar karosu → paylaşım hedefi "Nota ekle" → metin seçim menüsü →
`notlar://ekle?metin=…`. Hepsi aynı levhaya çıkar; ayrı ekran yazılmaz.

**HE-4 Tek giriş: "yaz ya da söyle, gerisini o anlasın".** Bugün üç ayrı kapı var: hızlı ekle,
sesli komut, akıllı liste. Tek satırda birleşir; sırayla dener: (1) hedefli ekleme ("… markete
ekle"), (2) tarih/saat varsa hatırlatıcılı madde ("yarın 9'da dişçi" — ayrıştırıcı sesli komutta
hazır, yeniden yazma), (3) birkaç market maddesi → son market listesi ya da yeni akıllı liste,
(4) hiçbiri → Gelen kutusu notu. Her adımda önizleme satırı kararı gösterir; kullanıcı tek
dokunuşla değiştirir. Bu, 16 Kasım raporundaki "Konuş, gerisini o yapsın" kahraman özelliğinin
iskeletidir. Yeni özellik: karar senin.

**HE-5 Akıllı hedef.** Hedef hafızası cihazlar arası; tek cümlede çok hedef ("süt markete, fatura
yapılacaklara" — ayırıcı hazır); bağlama göre sıralama (saat ve güne göre en çok kullanılan hedef
öne); market listesine eklenen madde doğru reyona (akıllı liste AL-2 ile ortak).

---

## 5. Akıllı liste — geliştirme planı

### 5.1 Doğrulanan hata [KOD]

`QuickListArgs.grocery` varsayılanı `false` (`quick_list_screen.dart:33`); `smartListArgs` bu
bayrağı vermiyor (`note_template_sheet.dart:84–95`); `buildQuickLexicon` hazır market sözlüğünü
yalnız `grocery` doğruyken ekliyor (`quick_entry_memory.dart:193–206`). Sonuç: akıllı listenin
**ayrıştırıcısında** yalnız şablonun öneri çipleri (31 alışveriş maddesi, `app_tr.arb:1935–1943`)
var, 1100 maddelik sözlük yok. Sıralama ve tür tanıma ayrı sözlükten (`_grocery`, `:276`) okuduğu
için doğru çalışıyor; hata göze batmıyor. Beklenen belirti: boşlukla ya da sesle söylenen ve
çiplerde olmayan art arda maddeler tek madde kalır — **"süt yumurta ekmek" üç madde yerine tek
madde olur** (üçü de sözlükte var, `quick_lexicon_data.dart:62, 68`; hiçbiri çiplerde yok); çiplerde
olmayan kelimelerde yakın eşleşme düzeltmesi çalışmaz. Düzeltme: `smartListArgs`'a `grocery: true`
(tek satır) + Ek 1'deki boşluklu girdi testi.

### 5.2 Plan

**AL-1 Oturtma (hata + küçük iş).** §5.1 düzeltmesi ve testi · sık kullanılanlar hafızasını türe
böl (`smart:market`, `smart:bavul`; bugün tek anahtarda karışıyor) · "geçen seferden kalanlar"
başlığa değil türe göre eşlensin · boş ekranda tek cümlelik ipucu ("süt, ekmek… ya da 'bavul
listesi' de") · bütçe senaryosuna açılışın ilk karesi (envanter K-41).

**AL-2 Liste notta da akıllı kalsın.** Nota tek küçük alan: `listKind` (market / bavul / genel).
HAFIZA kural 5: üç "aynı mı" karşılaştırmasına da eklenir. Bununla: sonradan eklenen madde
(editör, hızlı ekle, sesli komut) doğru reyona düşer · "Reyona göre grupla" görünümü (başlıklar
nota YAZILMAZ, çizilirken sözlükten türetilir; kullanıcının "alt başlık yok" kararıyla çelişmez) ·
"Alışverişi bitir": işaretlileri kaldır, sıklık hafızasını güncelle, kalanları sakla · miktar
toplama ("2 süt" + "1 süt" → "3 süt"; mantık hızlı eklede hazır, `planDropIntoList`).

**AL-3 Daha çok tür, daha derin sözlük.** Bavul sözlüğü ~100 madde, market 1100. Yeni türler
sözlük + öneri seti olarak: yapılacaklar, tarif malzemesi, eczane/ecza dolabı, kırtasiye/okul,
kamp, bebek çantası, spor çantası, taşınma, misafir hazırlığı, tamirat/hırdavat. Tür eklemek =
bir sözlük dizesi + bir satır; kod büyümez.

**AL-4 Öğrenen liste.** (a) Maddeyi başka gruba sürükleyince kişisel eşleme öğrenilir ve
cihazlar arası gider. (b) Sözlükte olmayan maddeler tek istekte hafif modele sorulur, sonuç
sonsuza dek cihazda saklanır (madde başına bir kez; çevrimdışıysa "diğer"). (c) **Tahmin:** "her
hafta süt alıyorsun, 9 gündür almadın" → öneri çipi; hesap tümüyle cihazda, sıklık hafızasından.
(d) "Evde var / bitti" durumu: kiler mantığı, bitenler bir dokunuşla listeye.

**AL-5 Mağazada kullanım.** Mağaza kipi: büyük yazı, ekran açık kalır, tek elle, işaretlenen alta
iner · reyon sırası markete göre öğretilir (marketi bir kez gez, işaretleme sıran o marketin
sırası olur) · ortak listede "Ayşe sütü aldı" bildirimi (FCM ve Functions hazır; Pro adayı) · ana
ekran aracı: market listesi, dokununca işaretle · konuma bağlı hatırlatma ("markete yaklaşınca
listeyi göster"; konum izni Play'de ayrı beyan ister).

**AL-6 Girdi zenginliği.** Tariften listeye (bağlantı ya da fotoğraf → malzemeler; AI, Pro adayı)
· fişten "aldıklarım" (cihaz içi OCR hazır) · "Bu listeyi şablon yap" (haftalık market, spor
çantası) · sesli asistandan "listeye süt ekle" (AppFunctions servisi hazır).

**Önermediklerim:** fiyat takibi / market karşılaştırma, barkodla ürün veritabanı (veri kaynağı ve
lisans yükü ağır).

---

## 6. Daha neler yapılabilir (kısa)

1. **Parolalı yedek ve uçtan uca şifreli kilitli notlar.** Bugün not kilidi şifreleme değil
   (`veri.md:56`). "Notlarını biz de okuyamayız" cümlesi, tanınmayan geliştirici için en güçlü
   güven kanıtı; yalnız kilitli notlarda uygulanırsa arama ve AI etkilenmez.
2. **İlk 60 saniye.** Yeni kullanıcı için üç ekranlık akış; değer hesap açmadan görülsün (misafir
   kipi var).
3. **Kullanım ölçümü** (rızayla, içerik yok): ilk not, ilk sesli not, ilk liste, 1/7/30. gün geri
   dönüş. Olmadan Lite/Pro sınırını nereye çekeceğini tahminle belirlersin.
4. **Kolay çıkış:** tek dokunuşla Markdown/zip dışa aktarma. "İstediğin an çık" diyebilen uygulamaya
   girilir.
5. **iOS.** Kod Flutter; teknik engel yok. Engel maliyet ve emek: Apple geliştirici hesabı (yıllık
   ücretli), Mac'te derleme, yerel köprülerin (klavye öngörüsü, araçlar, konuşma) iOS karşılıkları.
   Android'de elde tutma kanıtlanmadan başlama.
6. **Saat ve araç yüzeyleri:** Wear OS'ta sesle hızlı ekle; kilit ekranı aracı.
7. **Davet:** ortak liste daveti doğal büyüme kanalı; davet edilen Lite ile katılabilmeli.
8. **Uygulama içi hız günlüğü** (envanter K-62): "bugün şurada kastı" dediğinde bakılacak sayı.

---

## 7. Senden beklenen kararlar

1. **Model:** tek uygulama + Lite/Pro katmanı mı (önerim), iki ayrı uygulama mı?
2. **Lite senkronu:** metin senkronu Lite'ta açık, aralıklı (önerim) — onay? Cihaz sınırı 2 mi,
   sınırsız mı?
3. **Lite ekleri:** kendi Drive'ına (önerim) — onay?
4. **Senkron işleri zincire girsin mi?** Korkuluklar (§1.4: 1, 2, 3, 4) ve S2 + S3 küçük ve
   güvenli. **S1 (yalnız değişeni dinle) ayrı, planlı bir faz** — başlatayım mı?
5. **`config/app`'e uzaktan senkron ayarı** eklensin mi (§1.4-5)?
6. **Yıllık fiyat aralığı** (hesabı ona göre netleştireyim).
7. **Yazım:** Y-0 (ölçüm seti) hemen başlasın mı; Y-4'te varsayılan "Yalnız göster" olsun mu?
8. **Hızlı ekle:** HE-1 hata düzeltmeleri zincire girsin mi? HE-4 (tek giriş) dondurmadan çıksın mı?
9. **Akıllı liste:** AL-1 zincire girsin mi? AL-2'deki `listKind` alanına onay?
10. **Kasma paketleri:** envanter Ek A'daki dokuz satır `OTOMASYON.md` Kuyruk'a eklensin mi; hangi
    sırayla?

---

## Ek 1 — Kırmızı testler (işçi için; bu oturumda koşulamadı)

Aşağıdaki dosya `test/` altına konup koşulur. Beklenen: işaretli satırlar bugün KIRMIZI.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/quick_drop.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';

void main() {
  const titles = ['Yapılacaklar', 'Market listesi', 'Proje notları'];

  test('H9: hedef yokken sondaki fiil içerikte kalır', () {
    for (final s in ['rapor yaz', 'çöpü kapıya koy', 'dosyayı kaydet']) {
      final r = parseDropTarget(s, titles);
      expect(r.index, isNull, reason: s);
      expect(r.content, s, reason: 'bugün fiil siliniyor'); // KIRMIZI beklenir
      expect(r.command, isFalse, reason: s); // KIRMIZI beklenir
    }
    // "ekle" ailesi hedefle birlikte çalışmayı sürdürür.
    final ok = parseDropTarget('süt ekmek markete ekle', titles);
    expect(ok.index, 1);
    expect(ok.content, 'süt ekmek');
  });

  test('bekçi: saat iki noktası ad ayırıcı değildir (bugün YEŞİL beklenir)', () {
    final r = parseDropTarget('proje 14:30 toplantı', titles);
    expect(r.index, isNull);
    expect(r.content, contains('14:30'));
  });

  test('akıllı liste: boşluklu girdi market sözlüğüyle ayrılır', () {
    // Ekrandaki kurulumun aynısı: smartListArgs grocery vermiyor.
    QuickLexicon lex({required bool grocery}) {
      final l = buildQuickLexicon(locale: 'tr', grocery: grocery);
      for (final (text, group) in packingEntries('tr')) {
        l.add(text, group: group);
      }
      return l;
    }

    List<String> parse(bool grocery, String s) => [
      for (final i
          in buildQuickParser(lex(grocery: grocery), spell: SpellMemory())
              .parse(s, flush: true)
              .items)
        i.name,
    ];

    // Market sözlüğü varken üç madde; bugün ekranın kurduğu sözlükte (grocery
    // yok) tek madde. Düzeltmenin asıl testi ekran düzeyinde yazılır:
    // smartListArgs ile açılan QuickListScreen'e "süt yumurta ekmek" + Enter
    // → 3 satır (kalıp: test/smart_list_test.dart, test/quick_list_screen_test.dart).
    expect(parse(true, 'süt yumurta ekmek'), hasLength(3));
    expect(parse(false, 'süt yumurta ekmek'), hasLength(1)); // hatanın modeli
  });
}
```

H1 bu dosyada yok: metinle sınanamaz (§4.1). Testi, ses oturumunun zaman bilgisi sahtelenerek
`quick_entry_bar` düzeyinde yazılır.

H10 (bayat kopyanın üstüne yazma) widget düzeyinde sınanır: `QuickDropSheet` açıkken sahte depoda
hedef notun maddelerini değiştir, sonra Ekle'ye bas; yazılan alanlar depodaki GÜNCEL maddeleri
içermeli (`_LiveRepo` düzeneği, `perf_budget_test.dart`).

## Ek 2 — Bu rapor nasıl hazırlandı

- Okunan belgeler: 16 Kasım raporu, `HAFIZA.md`, `docs/hafiza/akicilik.md`, `veri.md`, `editor.md`
  (ilgili bölümler), `OTOMASYON.md`, `PLAN.md`, `KONTROL_LISTEM.md` (ilk 80 satır),
  `docs/perf/kullanici_video_2026-11-15.md`, `isci` ve `kasma-kontrol` skill'leri.
- Okunan kod: `notes_repository.dart` (dinleyiciler), `prefs_sync.dart`, `note_presence.dart`,
  `widget_service.dart`, `reminder_service.dart`, `spell_engine.dart`, `spell_fix.dart`,
  `spell_learn.dart`, `auto_spell.dart`, `quick_drop.dart`, `quick_drop_sheet.dart`,
  `smart_list.dart`, `quick_list_screen.dart`, `quick_entry_memory.dart`; ayrıca `lib/` genelinde
  kalıp taraması (envanter Ek C).
- Dış kaynaklar (17 Kasım 2026): Firestore fiyat belgesi (ücretsiz kota, 30 dakika kuralı; bölge
  fiyat tablosu okunamadı) · Firebase fiyat sayfası (Depolama, Functions, FCM, App Check) ·
  Cloudflare R2 / D1 / Durable Objects / Workers fiyat sayfaları · Google Drive API sınırları ve izin
  sınıfları · Google Play hizmet ücreti sayfası.
- Doğrulanmayanlar: bütün maliyet tabloları varsayıma dayalı hesap; Firestore'un kendi yazdığın
  kaydın yankısını okuma sayıp saymadığı belgede yazmıyor (hesaba katmadım); vergi oranları 16 Kasım
  raporundaki ikincil kaynaklardan.
