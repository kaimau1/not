# PLAN — TEK PLAN (2026-11-17 akşam; P22/P53 + 15/16/17 Kasım raporları + kasma envanteri + P61 keşif turu + OTOMASYON kuyruğu + KONTROL kararları)

**Bu dosya tek plandır.** Ayrıntı kaynakları (yalnız okuma, iş buradan seçilir):
`docs/rapor_2026-11-16_beyin_firtinasi.md` (16K), `docs/rapor_2026-11-17_senkron_lite_pro_yazim.md`
(17K), `docs/perf/kasma_envanteri.md` (K-xx), `docs/rapor_2026-11-15.md` (15K), keşif turu
`docs/kesif_turu_2026-11-14.md` (KT-xx; dal `oto/P61-kesif-turu`, bu planla main'e alındı).
OTOMASYON.md Kuyruğu'ndaki açık satırlar (P61, K32, K34) buraya taşındı; Kuyruk yalnız yürütme durumu tutar. Bitmiş (`[x]`) maddeler burada tutulmaz (git'te).
Kullanıcının kendi listesi: `KONTROL_LISTEM.md`. Eski planlar `docs/arsiv/planlar/`.

## 0. 17 Kasım oturumunda BİTENLER (main'e `[apk]` ile girdi; cihazda doğrulanmadı)

- KP1 levhalar (K-01…K-12): 11 levha klavye karesinde baştan kurulmuyor; S53 bütçesi (arama
  1152→294, not seçici 4758→630, AI sonuç 1512→294 kurulum); `viewInsetsOf` bekçisi.
- KP2 (K-38 ilk ikisi): "Geri al" çubuğu ve `CountdownBar` adımlı boyama (`SteppedCountdown`).
- KP3 kısmi: ana ekran aracı ön planda güncellenmez, arka plana geçerken bir kez (K-24);
  ayar eşitlemesi değişmeyen turu atlar (K-25); nabız arka planda durur (K-53: yalnız paylaşılan
  notta başladığı doğrulandı).
- Hatalar: akıllı liste market sözlüğü (17K §5.1), hızlı ekle H9 ("rapor yaz"), H10 (güncel nota
  ekle + seçici geri al).
- Senkron S2/S3 + korkuluklar: aralıksız yazımda bulut kaydı en geç 20 sn (10 idi; sessizlik 2 sn
  kaldı), `config/app` uzaktan kayıt freni `saveDelaySec`/`saveMaxWaitSec`, sürüm budama sorgusu
  her 5 sürümde bir, boşta yazma bekçisi testi (`test/idle_write_guard_test.dart`).

## 1. SIRADAKİ İŞLER (öncelik sırasıyla)

### 1.0 KARAR (kullanıcı, 2026-11-17 akşam) — sormadan uygula
- **Cihaz:** test telefonu yerine **tablet** bağlanacak. Cihazlı işler (T1, T2, T4, T8, T9, T13,
  T16) tablette koşar; tablet + web + kalem kontrolleri (KONTROL "Tablette bak", "Bilgisayarda bak",
  K32 yan yana, K34 parmak aracı, dolma kalem, 1 GB PDF) aynı turda biter. Ölçüm tabanı tablette
  yeniden alınır (telefon tabanıyla karşılaştırılmaz).
- **S1 "yalnız değişeni dinle": doğrudan yapılır** (1.4/1 ilk büyük faz). Şartlar kalkmadı: önce
  yerel tam yedek, geri alınabilir uzaktan bayrak (varsayılan kapalı → iki cihaz testinden sonra açık),
  `rules-test` yeşil, iki cihaz (tablet + web) eşitleme testleri.
- **Dondurma (K-O1) KALKTI.** 1.4'teki büyük fazlar sırayla açılır; oturum = bir faz, `[apk]` başına
  en çok 5 görünür değişiklik ve hız kapıları sürer. HE-4 ve AL-2 bu fazların içinde (1.1/7 kapandı).
- **Keşif turu zevk kararları yürütücüde:** KT-2 masaüstünde levha ortada en çok 560 dp; KT-10 Not
  kilidi ayrı "Güvenlik" bölümü; KT-8 masaüstü geri alma duraklamada adım (yazım grubu ~1 sn
  sessizlik); KT-1 toast'lar kuyrukta tek tek, arama çubuğunu örtmeyecek yerde. (1.1/12 kapandı)
- **Model: tek uygulama + Lite/Pro katmanı.** Lite senkronu açık + aralıklı; Lite ekleri kullanıcının
  kendi Drive'ına (S4); T11 depolama tavanı bu modele göre (Lite'ta Storage kapalı). (1.1/1, /3)
- **Play'e ÇIKILIYOR — hazırlık başlasın** (eski "çıkmıyoruz" kalktı). 1.4/5 Lite/Pro + Play yolu
  açılır; Play'e özgü kalan kararlar (ad, hesap türü, niş, AI katmanı, fiyat, Lite cihaz sınırı)
  o fazın BAŞINDA sorulur (cihaz sınırı kapandı: yok). Park'taki Billing/OAuth yayını/gizlilik/konum beyanı/mağaza işleri bu
  faza girer. Kişisel APK (`NOTLAR_KISISEL=1`) yolu Play sürümü çıkana dek sürer.
- **Yazım denetimi v3 varsayılanı "Yalnız göster"** (altı çizili, dokununca öneri; kendiliğinden
  düzeltme yok); Y-0 ölçüm seti faz başında. (1.1/6)
- **KONTROL küçük kararları yürütücüde:** 33 yeni el yazısı kayıt biçimi tablette ölçülür, sonra
  karar (şimdilik kapalı); 35 tek sabit ek kalır; 36 ilk hatırlatıcıda alarm izni kapalıysa ipucu
  EKLENİR; 37 alt arama kısayolu yok; 38 bulutta emülatör ölçümü yok; 39 en büyük yazıda sabit ek
  çubuğu taşarsa etiketler kısalır. (1.1/13 kapandı)

**Sıra (önerim, yürütücü bunu izler):** (1) telefonsuz T3, T5, T7, T10, T12, T14, T15 + KONTROL 36/39
→ (2) tablet bağlanınca T13 → T16 + T1 (tablet tabanı) → T2/T4/T8/T9 → (3) S1 → S4 → (4) Play
hazırlığı (1.5 PL1–PL12) + Pro AI sadeleştirme (1.6 AI-S) + Lite/Pro → (5) yazım v3, hızlı ekle, akıllı liste, güven/büyüme.

### 1.1 Senden karar bekleyenler (karar gelmeden başlamaz)
1. ~~Model~~ → KARAR 1.0: tek uygulama + katman.
2. ~~Lite cihaz sınırı~~ → KARAR 1.5: sınırsız; içerik sınırı yok.
3. ~~Lite ekleri~~ → KARAR 1.0: kullanıcının Drive'ı.
4. ~~S1 ayrı faz mı~~ → KARAR 1.0: doğrudan yapılır.
5. Yıllık fiyat aralığı (maliyet hesabı netleşsin). (17K §2.3)
6. ~~Yazım~~ → KARAR 1.0: Yalnız göster.
7. ~~HE-4 / AL-2 dondurmadan çıksın mı~~ → KARAR 1.0: dondurma kalktı.
8. Play'e ÇIKILIYOR (KARAR 1.0); **ad, hesap türü, niş, AI katmanı, fiyat** — Play fazı başında (16K §9)
9. İkinci test cihazı (60/120 Hz ayrımı için) — şimdilik tablet (16K §2.2, K-21)
10. ~~Dondurma~~ → KARAR 1.0: kalktı.
11. ~~Test telefonu~~ → KARAR 1.0: tablet.
12. ~~Keşif turu zevk kararları~~ → KARAR 1.0 (yürütücü): masaüstü levha genişliği/yeri (KT-2), Not kilidi ayrı "Güvenlik"
    bölümü (KT-10), masaüstü Ctrl+Z adımı kelime mi duraklama mı (KT-8), ipucu toast'ı masaüstünde
    yeri/sıklığı (KT-1).
13. ~~KONTROL kararları~~ → KARAR 1.0 (yürütücü): 33 yeni el yazısı kayıt biçimi (YAZMA kapalı), 35 birden çok sabit ek
    (sekme/yan yana/tek), 36 ilk hatırlatıcıda alarm izni ipucu, 37 ana ekranda alt arama kısayolu,
    38 bulutta emülatör hız ölçümü (CI kotası), 39 sabit ek çubuğu en büyük yazıda.

### 1.2 Senin konsolda yapacakların (5–15 dk, kod yok)
- **Google Cloud bütçe uyarısı 5 / 20 / 50 $** (e-posta + telefon) — maliyet korkuluğu 1, en acil.
- **App Check zorlaması** (Play Integrity kurulu) — korkuluk 3 (KONTROL 31).
- Acil fren gerekirse: Firestore konsolunda `config/app` belgesine `saveDelaySec: 30`,
  `saveMaxWaitSec: 120` sayıları (yeni açılan editörlerde bulut kaydını seyreltir; silince
  varsayılana döner). `minClient`/`inkV2Write`'a dokunma.

### 1.3 Kod işi — zincire hazır (karar gerektirmez)
| No | İş | Kaynak | Cihaz |
|---|---|---|---|
| T1 | Cihaz ölçüm turu: panel kip k/c, 60 Hz ayrımı, RAM tabanı, ısınma, ab_hepsi kör evreleri, 1000/3000 not; 17 Kasım `[apk]`'sının A/B'si (ÖLÇÜM KAPISI bu kez yapılamadı) | K-20, K-21, K-59…K-63 | evet |
| T2 | Not akışı yankısı: sağlayıcı sayacı senaryosu + en pahalı 3 türetilmişi dilime çevir (veri göçü yok) | K-22a, K-23 | A/B |
| T3 | **[x] 2026-11-17 (P65)** Merriweather-Medium pakete, çalışma anı indirme kapalı, bekçi `font_runtime_fetch_test`; uçak kipinde görünüş cihazda bakılmadı. Yazı tipi çalışma anı indirmesi: doğrula, `allowRuntimeFetching=false` + kalın dosyaları pakete, bekçi | K-54 | hayır |
| T4 | Hızlı ekle kalanı: H1 ("süt bitti" sessizlik süresiyle), H3 (süre tutarsızlığı), H11 ("Yeni not olarak kaydet" çipi), hızlı ekle bütçe senaryosu | 17K §4.1, K-64…K-69 | A/B |
| T5 | **[x] 2026-11-17 (P65)** sık eklenenler türe bölündü (`smart:market`/`smart:bavul`), "Geçen seferden" türe göre, boş liste ipucu, S49 açılış bütçesi. Akıllı liste AL-1: sık kullanılanları türe böl, ipucu satırı, açılış ilk karesi bütçesi | 17K §5.2, K-41 | hayır |
| T6 | Klavye açıkken sayfa iskeleti: 17 ekranı ölç, kötülere T2 kalıbı | K-13…K-19 | gerekirse |
| T7 | **[~] 2026-11-17 (P65)** sürüm geçmişi, hesap makinesi, paylaşım levhası araması; **2026-11-18 (P72): kılavuz araması — sonucu değişmeyen tuşta kart kurulumu 9 → 0**; kalan liste `docs/hafiza/akicilik.md` 2026-11-17 T7. Tembel liste + build'de hesap + onChanged setState (ekran başına) | K-47, K-48, K-57, K-58 | hayır |
| T8 | Editörde kalanlar (ölçüm kapılı) | K-27…K-36 | A/B |
| T9 | Kısa geçişlerdeki `TweenAnimationBuilder`'lar ve beliriş animasyonları (`PopIn`, `RevealUp`…): önce ölç, kurulum > 5 ise düzelt (bu oturumda bilerek dokunulmadı: `child` zaten yeniden kurulmuyor) | K-37, K-38 kalanı | A/B |
| T10 | **[x] 2026-11-17 (P64)** denetleyici levhanın State'inde, bekçi `caption_sheet_dispose_test`. Görsel açıklama levhası: kapanış animasyonunda atılmış denetleyici kullanılıyor (debug uyarısı; S53 yazılırken görüldü) | `attachment_actions.dart` `showCaptionSheet` | hayır |
| T11 | Senkron korkuluk 6: depolama tavanı sunucuda (ya da Lite'ta Storage kapalı) — 1.1/3 kararına bağlı | 17K §1.4 | hayır |

| T12 | **[~] 2026-11-17 (P64)** KT-2/3/5/9/10/12 yapıldı, KT-6/7 zaten vardı; **KT-1 [x] 2026-11-18 (P72): zaten P62 PA5'te (2026-11-15) yapılmış — tek bildirim şeridi `AppNoticeController` (ipucu yalnız şerit boşken, duyuru sıra bekler), ipucu üst kromun ALTINDA; kanıt `test/app_notice_test.dart` 3 test + `notice_paths_guard_test` (ham SnackBar 0); kod değişmedi. Yenilikler 12 sn → 6 sn önerisi KARAR'da yok, yapılmadı (sabah bakılacak)**; kalan KT-4 (A/B), KT-8 (ölçüm kapısı), klasör adı 2 satır (sabah bakılacak: kart boyu sabit). Keşif turu "kendimiz yaparız" 8 maddesi: KT-7 hesap levhası 2 satır, KT-5 "Sabitten çıkar", KT-3 dar ekranda gün adı + FAB boşluğu, KT-4 hızlı ekle levhası yazı 1.3, KT-9 ortak boş durum, KT-12 arama ipucu kısalt, KT-6 çevrimdışı AI şeridi, KT-1 toast kuyruğu | KT, P61 (3) | hayır (KT-1/KT-4 A/B) |
| T13 | Ölçüm aracı onarımı: `sablon` evresi atlanıyor, `bicim/kalem/duzen` hiç koşmadı, `acilis` 2 kare; altın taban yeni veriyle (`--altin-yaz`) — T1'in ön koşulu | 15K §4 | evet |
| T14 | **[x] 2026-11-17 (P65)** budamada canlı küme = aktif + çöp; bekçi `semantic_trash_cache_test`. Çöp kutusunda anlamca arama ↔ önbellek temizliği döngüsü | 15K §4 | hayır |
| T15 | **[x] 2026-11-17 (P65)** `showNoteTemplateSheet` + TemplateComposer liste dalı silindi. Şablon önizlemesinin ölü liste dalını (TemplateComposer liste dalı + `showNoteTemplateSheet`) testleriyle birlikte sil | (C) son madde | hayır |
| T16 | P61 canlı tur — TABLETTE (adb/uiautomator, KT-13…) + web + kalem kontrolleri; bulguların düzeltilmesi; KT-1/2/8/10 KARAR 1.0'a göre | P61 (2)(3) | evet (tablet) |

**Bilerek yapılmayanlar:** kuralda yazma hız sınırı (17K §1.4-4) — reddedilen yazım
çevrimdışı kuyrukta YEREL değişikliği geri alır, veri kaybı riski; S1 kararıyla birlikte
`rules-test` ile yeniden düşünülür. Hatırlatıcı eşitlemesine imza katmanı (K-24 ikinci yarı) —
not başına imza zaten var, kanal çağrısı yok; risk > kazanç. Geri bağlantı dizini (K-26) — seçici
ucuz, ölçülmeden dokunulmadı.

### 1.4 Büyük fazlar (karara bağlı, sırasıyla önerim)
1. **[~] 2026-11-17 (P67) kod + bayrak (`config/app.syncDeltaListen`, KAPALI); açmadan önce: minClient damgalı sürüme + iki cihaz testi (`docs/hafiza/veri.md` S1, KONTROL "Tablette bak").** **S1 yalnız değişeni dinle** (17K §1.3) → sonra S4 Lite ekleri Drive'a.
2. **Yazım denetimi v3** Y-0 → Y-1 → Y-2 → Y-3 → Y-4 → Y-5 → Y-6 (17K §3.3).
3. **Hızlı ekle** HE-2 önizleme satırı → HE-3 uygulamayı açmadan ekle → HE-4 tek giriş → HE-5 (17K §4.2).
4. **Akıllı liste** AL-2 → AL-6 (17K §5.2).
5. **Lite/Pro + Play yolu** (karar 1.1/1, 1.1/8 sonrası): engeller E1–E12, evreler 2–6 (16K §4, §8).
6. Güven/büyüme: parolalı yedek + uçtan uca şifreli kilitli not, ilk 60 saniye, rızalı kullanım
   ölçümü, kolay dışa aktarma, uygulama içi hız günlüğü (17K §6).

### 1.5 Beyin fırtınasından (16K) açık kalanlar — Play yolu ayrıntısı
**KARAR (kullanıcı, 2026-11-17 akşam):** Play hesabı **kişisel** (25 $; yayından önce 12 test kullanıcısı,
kesintisiz 14 gün kapalı test). Play derlemesinde **kapalı**: Gmail, konum hatırlatıcı, Antalia sesi (ONNX);
Takvim/Görevler **kalır** → OAuth "hassas" doğrulamasına başvurulur. AI katmanı (kullanıcı, 2026-11-17 gece — üç katman önerisinin yerine):
**Ücretsiz = yapay zekâ YOK** (bulut AI yok, kendi anahtar alanı da yok; cihazda çalışan OCR, belge
tarama, dikte, sistem sesi, akıllı liste sözlüğü AI sayılmaz, kalır) · **Pro abonelik = dahili AI**
(§1.6'daki 8 ana yetenek; günlük kota yalnız burada, sunucuda sayılır) · **Ömür boyu (tek sefer) = dahili AI
yok, kendi Gemini anahtarını girebilir** (sınırsız, maliyet bize sıfır). Abonelik yalnız AI'ın aylık
maliyeti için; AI ömür boyu satılmaz. 
**Katman farkları (kullanıcı, 2026-11-17 gece):**

| | Ücretsiz | Ömür boyu (tek sefer) | Pro (aylık/yıllık) |
|---|---|---|---|
| Bütün not/liste/kalem/PDF/hatırlatıcı/takvim, cihazda OCR·dikte·sesle okuma | ✓ | ✓ | ✓ |
| Not/klasör/ek sayısı | sınırsız | sınırsız | sınırsız |
| Cihaz sayısı | sınırsız | sınırsız | sınırsız |
| Eşitleme | aralıklı | anında | anında |
| Ekler | kendi Drive'ı | kendi Drive'ı (yürütücü: tek sefer ödemeye süren depo maliyeti bağlanmaz) | bizim bulut (Storage) |
| Sürüm geçmişi + parolalı tam yedek | ✗ | ✓ | ✓ |
| Ek temalar / yazı tipleri / kart görünümleri | ✗ (temel set) | ✓ | ✓ |
| Dahili AI (§1.6) | ✗ | ✗ | ✓ |
| Kendi Gemini anahtarı | ✗ | ✓ | ✓ |

Pro = ömür boyunun hepsi + dahili AI + bulut ekleri. Temel tema/yazı tipi setinin hangi parçaları ücretsizde
kalacağı PL6'da belirlenir (bugünkü varsayılan görünüm ücretsizde kalır; kimsenin elinden özellik alınmaz).

**Ek kararlar (kullanıcı, 2026-11-17 gece):** Play sürümü **yeni paket adıyla** (ad seçilince) ve **tamamen ayrı altyapıyla**
(kullanıcı, 2026-11-17 gece): **yeni Google hesabı, yeni Firebase/Google Cloud projesi, yeni web sitesi**
(alan adı + barındırma), yeni OAuth onay ekranı ve doğrulaması, yeni Gemini/AI Logic faturalaması, yeni
App Check. Kişisel APK `dev.kaimau.notlar` eski proje `notlar-kaimau` + eski web'de AYNEN sürer; iki
dünya arasında veri paylaşımı YOK (kişisel notlarını Play'e taşımak istersen dışa aktar → içe aktar). **Pro biterse** buluttaki ekler silinmez, okunur kalır; yeni ekler kendi
Drive'ına; tek dokunuşla eskileri Drive'a taşıma; silme yok. **Satın alma yalnız Android'de** (Play Billing),
hak hesaba bağlı (sunucuda doğrulanır, `entitlements/{uid}`), web'de "telefondan al" yazısı. **Pro'da 7 gün
ücretsiz deneme.** Kişisel hesabın (geliştirici) hakkı sunucudan Pro.
**Yürütücü varsayılanları (değiştirmek istersen söyle):** paylaşılan notlar her katmanda anında (ortak
düzenleme bozulmasın); ücretsiz eşitleme aralığı 5 dk + uygulama arka plana geçerken bir kez; ömür boyudan
Pro'ya geçen kişiye ömür boyu hakları kalır; Pro günlük AI kotası kotanın %80'inde uyarı.
**Hâlâ açık:** fiyatlar (aylık / yıllık / ömür boyu, TL), ad + niş, Pro'nun ücretli Gemini erişimi
(AI Studio ücretsiz kotası ticari kullanımda yetmez → Firebase AI Logic/Vertex ödemeli, Blaze bütçe tavanı).
**Niş/vaat ve uygulama adı kullanıcı yazacak (bekliyor).** Kişisel APK'da her şey kalır.

| No | İş | Kaynak | Cihaz |
|---|---|---|---|
| PL1 | **[~] 2026-11-18 (P73)** Dart kapıları (P66) + konum izin/alıcıları Play manifestinden silindi, Gmail pakette yok; **ONNX kaldı**: `.so` dışlaması açılışta çökertir (eklenti motoru attach'te yükler) → ayrı paket gerekir, sabah bakılacak (`docs/play_hazirlik.md`). Play derleme bayrağı (`NOTLAR_PLAY`): GitHub güncelleyicisi kapalı (E1), Gmail/konum/ONNX derlemeden çıkar (E2, E3, §2.6), YouTube otomatik PiP kapalı (§4.5) | 16K §4.2 | hayır |
| PL2 | **[~] 2026-11-18 (P70)** istemci: tek kapı `AiAdmission`, `aiKillSwitch`, yerel hız sınırı 30/dk; App Check zorlaması, Function kotası, bütçe tavanı açık — `docs/play_hazirlik.md`. AI korumaları (yalnız Pro dahili AI'ı): App Check zorlaması, kullanıcı başı hız sınırı, Pro günlük kotası sunucuda (F18.28), `config/app` acil kapatma bayrağı, bütçe tavanı (E4); ücretsiz katmanda AI girişleri gizli, kendi anahtar alanı yalnız ömür boyu + Pro'da | 16K §5.3 | hayır |
| PL3 | **[x] 2026-11-18 (P70)** rıza (yalnız Play; kişisel APK sormuyor — sabah bakılacak), "AI yanılabilir" + Bildir, AI'ı tümden kapat. AI kullanıcı yüzü: ilk kullanımda rıza ekranı, yanıtta "Bildir" + "AI yanılabilir", Ayarlar'da "AI'ı tümden kapat" (E11, KVKK) | 16K §5.3, §4.5 | hayır |
| PL4 | **[x] 2026-11-18 (P69)** gizlilik tek kaynak (`PRIVACY_POLICY.md` → web), `/delete-account`, KVKK TASLAĞI (hukuki onay sabah bakılacak). Gizlilik metni tek kaynak + herkese açık adres; web'den hesap silme sayfası (E5, E6); KVKK aydınlatma metni | 16K §4.2, §4.5 | hayır |
| PL5 | **[x] 2026-11-17 (P66)** API 36 tamam, 16 KB uyumlu görünüyor (ilk AAB'de doğrula), Play'de sıkıştırılmamış .so; komut `docs/play_hazirlik.md`. Hedef API 36 kontrolü (E8), 16 KB sayfa uyumu (E9), AAB + sıkıştırılmamış yerel kütüphane + `--obfuscate` (§2.6) | 16K §4.2, §2.6 | hayır |
| PL6 | Satın alma: Play Billing (RevenueCat ya da `in_app_purchase` + doğrulama Function'ı) — Pro aylık/yıllık abonelik + ömür boyu tek sefer; katman kapısı: ücretsiz / Pro (dahili AI) / ömür boyu (kendi anahtar) (E10, F18.27) | 16K §4.2 | hayır |
| PL7 | **[x] 2026-11-18 (P69)** 20 yazı tipi OFL + CMU BSD LicenseRegistry'de; Antalia SHA-256 doğrulaması (kendi sunucu kalanı). Lisans açıkları: yazı tipi OFL metinleri `LicenseRegistry`'ye, CMU BSD bildirimi, Antalia dosyaları kendi sunucumuza + özet doğrulama (kişisel APK için) | 16K §4.5 | hayır |
| PL8 | Ürünleştirme: ilk 60 saniye akışı, rızalı kullanım ölçümü (ilk not/sesli not/liste, 1./7./30. gün), mağaza görselleri — niş/ad gelince | 16K §7.3 | hayır |
| PL9 | Kapalı test (12+ kişi, 14 gün) → açık beta → TR yayın, kademeli dağıtım, Vitals takibi | 16K §8 evre 4–5 | — |
| PL10 | Yazı tipleri: 4–5 çekirdek aile pakette, kalanı seçilince insin (T3 ile birlikte) | 16K §2.6 | hayır |
| PL11 | RAM tabanı: beş durumda `dumpsys meminfo` (ana ekran, editör, PDF, kalem, YouTube) → `docs/perf/` | 16K §2.5 | evet (tablet) |
| PL13 | **[x] 2026-11-18 (P73)** kod tarafı: bayrak çeşidi (flavor değil; kişisel APK yolu/kimliği aynı), Play paket adı env'den (yoksa durur), `src/release/google-services.json` + `DefaultFirebaseOptions.play` (`env_play.json`), `AppLinks`, CI `play` işi + Play kural yayını PLAY_* Secrets yoksa atlanır. Sabah bakılacak: paket adı, 2. Firebase projesi, yükleme anahtarı, Secrets, kısayol `targetPackage`. Ayrı Play altyapısı (kod tarafı): tek kod tabanı, derleme çeşidi `kisisel`/`play`; çeşide göre Firebase yapılandırması (`google-services.json`, `firebase_options` çifti), web sitesi adresi, gizlilik/silme sayfası adresi, `env` ayrı; CI'da iki imza + iki kural yayını (`firebase deploy --project`); `rules-test` iki proje için aynı kurallar; sırlar GitHub Secrets'ta ayrı adlarla | ek kararlar | hayır |
| PL14 | **[x] 2026-11-18 (P71)** altyapı: `entitlements/{uid}` kuralı + rules-test, `EntitlementService` (yalnız Play'de etkin), deneme tetikleyicisi TASLAĞI, PL6 sözleşmesi; Pro özellik listesi sabah bakılacak. Hak (entitlement) altyapısı: `entitlements/{uid}` sunucuda doğrulanmış satın almadan, kurallar + `rules-test`, web/Android aynı kapı, 7 gün deneme, Pro bitince ekler okunur + "Drive'a taşı" | ek kararlar | hayır |
| PL15 | **[~] 2026-11-18 (P69)** "Geri bildirim gönder" (mailto); Crashlytics yeni Firebase projesine bağlı. Çökme takibi (Crashlytics, KONTROL 28) + destek e-postası + uygulama içi "Geri bildirim gönder" | 16K §8 | hayır |
| PL12 | **[x] 2026-11-17 (P66)** `frame_timing_log.dart`, profil/`NOTLAR_HIZ_GUNLUGU` derlemesinde Ayarlar'da; cihazda bakılmadı. Uygulama içi hız günlüğü (profil/beta derlemesinde `FrameTiming`, Ayarlar → Hakkında) | 16K §2.7 | hayır |

**Senin işlerin (Play):** yeni Google hesabı → yeni Firebase projesi (Blaze + bütçe tavanı) → Play geliştirici hesabı (kişisel, 25 $) → alan adı + yeni web sitesi; ayrıca mali müşavir (GVK 20/B istisnası), Syncfusion
Community lisansını al, uygulama simgesinin haklarını teyit et, alan adı, 12 test kullanıcısı bul.

**Faz içinde açılacak fikirler (1.4 fazlarına bağlandı):** hızlı ekle ulaşılabilirlik — başlatıcı
kısayolu, 1×1/4×1 ana ekran aracı, hızlı ayar karosu, paylaşımda "Nota ekle", metin seçim menüsü,
`notlar://ekle` (16K §1.4 A) → 1.4/3; akıllı liste kademe 2 (`listKind`, reyon görünümü, "Alışverişi
bitir", miktar) ve kademe 3 (düzeltmeden öğren, AI ile sınıflandır, yeni türler, mağaza kipi, liste
aracı) (16K §3.3) → 1.4/4; cihaz içi Gemini Nano katmanı, özet önbelleği, haftalık geri bakış
bildirimi, akıllı gelen kutusu, hatırlatıcı önerisi (16K §5.4) → 1.4/6; "Konuş, gerisini o yapsın"
tek giriş = HE-4.

### 1.6 Pro AI sadeleştirme + iyileştirme (faz AI-S) — KARAR (kullanıcı, 2026-11-17 gece)
"Yalnız işe yarayanlar kalsın, onlar da iyileşsin." Bugün ~30 AI yeteneği var (`gemini_service.dart`).
**Kalan 8 ana yetenek** (her biri tek yerden açılır; ✨ levhası 3 bölüm: Yaz · Sor · Dönüştür):

| # | Yetenek | Birleşenler (bugünkü işlevler) | İyileştirme |
|---|---|---|---|
| A1 | **Notlarına sor** (kaynaklı sohbet: tüm notlar / bu not / bu belge) | `assistantChat`, `chatAboutNote`, `askAboutNoteText` (notta ara), `outlineNote` + `brainstormAboutNote` → sohbet öneri çipi | Dahili kipte de anlamca getirme (bugün kelime örtüşmesi), her yanıtta kaynak çipi, "Bildir" |
| A2 | **Kayıttan not** (ses/toplantı/ders → özet + yapılacaklar + hatırlatıcı önerisi) | `transcribeAudio`, `transcribeMedia` + özet | Tek akış: döküm → özet → maddeler → "hatırlatayım mı?"; uzun kayıt parçalı |
| A3 | **Konuş, gerisini o yapsın** (tek cümle → doğru türde not/madde/hatırlatıcı/takvim) | `assistantVoiceNote`, hızlı ekle AI yedeği `pickDropTarget` | HE-4 tek giriş ile aynı iş; önce cihazda ayrıştır, AI yalnız gerekince |
| A4 | **Belgeye sor** (PDF/slayt/belge) | `summarizePdf`, `summarizeDocumentText`, `chatWithPdf` | Özet = ilk önerilen soru; sayfa numaralı kaynak |
| A5 | **Fotoğraftan yapılı not** (tahta, fiş, kartvizit, el yazısı) | `extractTextFromImage`, `askAboutImage` | Önce cihazda OCR (ücretsiz), AI yalnız yapılandırmaya (başlık + maddeler) |
| A6 | **Yazıyı iyileştir** (düzelt · yeniden yaz · kısalt/uzat · resmî/samimi · çevir) | `rewriteText`, düzeltme seviyeleri, `translateText` | Tek menü, önce/sonra önizleme + geri al; yazım v3 ile çakışmasın |
| A7 | **Özet** (kısa/ayrıntılı tek düğme, uzunluk anahtarı) | `summarizeNote` | Not değişmediyse önbellekten (içerik özetiyle anahtar) |
| A8 | **Sessiz düzen** (başlık, etiket, kopya not önerisi; tek istekte toplu) | `generateTitle`, `suggestTags`, hub "etiketle / başlık öner / kopyalar" | Toplu tek istek; kopya bulma cihazda (AI'sız) |
| + | **Çalışma kartları** | `generateStudyCards` | kalır (kullanıcı) |
| + | **Günün/haftanın özeti** | `composeBriefing` + haftalık özet | tek ekran, tek bildirim (pazar akşamı haftalık) |

**Play'den kalkanlar (kişisel APK'da kalabilir):** podcast + Gemini seslendirme (`podcastScript`, `speech`;
sistem sesiyle okuma ücretsiz kalır), video → not (`noteFromVideo`, `videoNoteExcerpt`), e-postadan not
(`fromEmail`, Gmail zaten kapalı). **Tümden kalkanlar:** "Notu analiz et" (`analyzeNote`, belirsiz → A1'e
devreder), çöp kutusu AI derin analizi (`analyzeTrash`; cihazdaki kurallar kalır), arşiv içgörüsü
(`summarizeArchive`), ayar aramada AI (`matchSettings` → yerel arama), ölü kod `tidyCapture`.

**Durum 2026-11-18 (P72):** AI-S2 [x] ✨ levhası 3 bölüm — Yaz (sesli not, Düzelt, Geliştir, Çevir) · Sor (Sohbet, PDF'e sor) · Dönüştür (Özet, PDF/slayt özet+dinle, metin tanı, döküm); `PlayBuild` kapısı gerekmedi (levhada Play'den kalkan yetenek yok); bütçe S54 (gövde 0, levha kökü 1). AI-S2 ekleri (sohbet öneri çipleri, Play'de tek seçenekli ses seçicisi) AÇIK — AI-S3'le.
**Durum 2026-11-18 (P68):** AI-S0 [x] (set `tool/ai_altin/`, taban koşusu GEMINI_API_KEY bekliyor), AI-S1 [x] (5 yetenek kalktı, Play'den kalkanlar `PlayBuild` kapısında). AI-S2'ye ek: Sohbet öneri çipleri (Ana hat / Fikir ver / Eksikleri bul), Play'de tek seçenekli ses seçicisini gizle.

**Sıra:** AI-S0 Türkçe altın örnek seti (her yetenek için 10–20 girdi + beklenen çıktı ölçütü, kalite
puanı; değişiklikten önce/sonra) → AI-S1 kaldır/birleştir (Play bayrağıyla, kişisel APK'yı bozmadan) →
AI-S2 ✨ levhası 3 bölüm (kasma-kontrol + bütçe senaryosu) → AI-S3…S10 yetenek başına iyileştirme, her
biri altın setle ölçülerek. PL2 korumaları ve PL3 rıza/"Bildir" ile birlikte Play fazında.

### 1.7 Kullanıcı istekleri (2026-11-18, sohbette açıkça istendi — zincire hazır)
| No | İstek | Not | Cihaz |
|---|---|---|---|
| U1 | [~] Kaydırma jestleri ayarlanabilir: üstten çekme (bugün klasörler) ve soldan sağa çekme (bugün takvim) Ayarlar'dan seçilsin — klasörler / takvim / belirli bir not / belirli bir klasör / hiçbiri | varsayılan bugünkü davranış. **Durum 2026-11-18 (P74, dal oto/P74-jest-takvim-web):** yazıldı — Ayarlar → Notlar iki satır (`home_pull_gesture`, `home_swipe_right_gesture`, eşitlenen ayar); eski "sağa kaydırınca takvim" kapalıysa "hiçbiri"; "hiçbiri" = sağa çekiş klasör gezisine döner (sabah bakılacak: tümden kapatma isteniyorsa); cihazda A/B yok | A/B (ana ekran) |
| U2 | Editör üst paneli düzenlenmeli (geri · yazım · B · renk · ⋮ · geri al/yinele · ara · ⋮ kalabalık; telefonda sadeleştir, sık kullanılan öne) | `istek_tara.py` önce | A/B (editör) |
| U3 | **Bug:** defter kipinde sayfa geçişi jestleriyle (kaydırma/seçim) karışıyor | kök neden + test | A/B |
| U4 | [x] Zamana/güne bağlı notlar, hatırlatıcılar vb. ana ekran takvim şeridinde ve tam takvimde görünsün | **2026-11-18 (P74):** hatırlatıcılar ve tarihli maddeler (görev) zaten vardı; eksik olan ZAMANLI NOT (`expiresAt`) eklendi — arşivlenme gününde "Arşivlenir" satırı, sürükleme/silme `expiresAt`'e dokunur (yeni Firestore alanı yok) | hayır |
| U5 | **Bug:** alttaki bildirimin geri sayım çubuğu takılarak ilerliyor; kesintisiz akmalı (tek AnimationController/doğrusal, kare kaçırmadan) | P72 KT-1 toast kuyruğundan sonra | A/B |
| U6 | Telefonda alt paneldeki 5 düğme → 4; en sağdaki "⋮" (ya da benzeri) küçük açılır pencerede kalanları gösterir | tablette 5 kalabilir | A/B (alt çubuk) |
| U7 | Metin seçim menüsü (Kes/Kopyala/Yapıştır/Biçim…/Ek göm/⋮) düzenlensin: **Tümünü seç** yok → eklensin; en çok kullanılanlar önde (seçim sırasında) | | hayır |
| U8 | [~] Gemini Decisions API'yi geniş kullan (çıktı ücretsiz, çok hızlı): başlık önerisini doğrulat (kendi algoritmamız ya da AI başlığı "doğru mu?" → hayırsa yeni başlık), hızlı eklede yazım düzeltmesini doğrulat, şablon/hızlı ekle içi kararlar, uygulama içi evet/hayır soruları; beyin fırtınası + ek öneriler | `docs/plan_decisions_api.md` · **2026-11-18 (P76, dal oto/P76-decisions):** DA-E1 servis + bayrak, DA-1 hızlı ekle hedefi, DA-2 etiket öner çipinde sessiz düzen, DA-13 başlık doğrulama, DA-14 hızlı ekle yazım doğrulama, DA-E0 altın set + canlı ölçüm; bayraklar (`aiDecisionsFeatures`/`aiDecisionsShadow`) VARSAYILAN KAPALI → kullanıcıya görünür değişiklik yok; açma kararı gölge ölçümünden sonra (sabah bakılacak) | hayır |

## 2. Önceki açık işler (P22 listesi, aynen)

### (A) Kullanıcının yapacakları → `KONTROL_LISTEM.md`

- Cihaz turu: telefon / tablet / web (KONTROL 1–23) — F69.1, F63.7, F67.8, F19.C1, F19.C2, F19.C4–C6, YORUM F55.5, KALANLAR §2 (C–L, P22, P45)
- Yeni cihaza geçiş + tam yedek geri yükleme (KONTROL 1) — F69.2, F19.A4, YORUM F54.4
- Liste maddesi "Boş madde"ye dönüyor, kanıt bekliyor (KONTROL 2) — KALANLAR veri kaybı 2026-11-01, cihaz turu A4
- Hatırlatıcı güvenilirliği cihazda (KONTROL 4) — F69.3, YORUM F56.2
- Konsol: AI bütçe/kota (24) F19.A1 · sunucu yedeği (25) F19.A5 · Calendar/Tasks API (26) F19.B10 · masaüstü OAuth (27) KALANLAR J0 · Crashlytics (28) F19.B4, YOL_HARITASI · Drive API + Functions (29) F19.B2, F19.B3 · minClient (30) F19.B1, F61.7 · App Check (31) F19.A2, F19.D2
- Test misafir hesabını sil — F19.C7
- PPTX portu için depo izni — F19.B8, F18.20
- Hız ölçüm tabanı yenilensin mi (KONTROL 40) — HIZ F81.2, F81.4 (P43/P55/P59/P20 sabah bakılacakları)
- Kararlar (KONTROL 32–39) — K-O12/F67.6, K-O3/F61.7, K-O4/F62.6, F63.6, K-O8/F65.3, F69.3 ipucu, F66.5, HIZ F83.3

### (B) Bekletilenler / park

- Mürekkep v2 YAZMA + tembel göç + kurallar — K-O2/K-O3 kapısı (F61.0 (b)(c) cihaz ölçümü yok) — F61.0, F61.4, F61.6, F61.7, F61.8
- Kalem raster karoları + görüntüye fırınlama — F62.0 cihaz ölçümü kapısı — F62.0, F62.3, F62.4
- Kalem gecikmesi ölçümü (240 fps) — cihaz — F62.6 (ölçüm), YORUM F54.1
- Açılış süresi kalanı (motor + Activity) — kod işi yok — F68.5
- Vulkan'lı cihazda ölçüm — cihaz yok — AKICILIK F27.3, F19.F4
- Kart dizini + gövde ayrı belge (senkron yükü) — KARAR B, veri göçü güvenlik şartlı — AKICILIK F22.4, YORUM F54.3
- ~~Play'e çıkış~~ → 1.4/5'e taşındı (KARAR 1.0: çıkılıyor) — F18.27, F18.28, F19.D1–D7, YOL_HARITASI F4.10
- Taşınan düğme ipucu, uygulama içi sürüm notu — tek kullanıcı, ertelendi — YORUM F57.1, F57.2
- Önce/sonra görsel karşılaştırma dosyası — DENEYIM F80.5
- Kare ölçümü CI işi (emülatör, sonuçsuz kaldı) — F19.B6, KULLANICI_DENEYIMI F17.1, HIZ F83.3
- Bilinen sınırlar: web geri tuşu tam ekran, debug `RenderFollowerLayer` uyarısı, düz metinde görev çipi yok, madde jest katmanında şekil önerisi yok, görev kişi alanı serbest metin — KALANLAR §3, Yarım kalan

### (C) Açık kod işi

- [x] **İki not yan yana (tablet yatay)** — opus — K-O12 kararı VERİLDİ (2026-11-12) — F67.6 — 2026-11-14 kod bitti (K32, dal oto/K32-yan-yana); tablette doğrulama KONTROL_LISTEM 32
- [x] **Parmağa ayrı araç** — YAZILDI 2026-11-14 (K34, dal `oto/K34-parmak-araci`): Kaydırır/Çizer/Siler, Siler = geçici silgi yolu, avuç/iki parmak geri alma, 22 dp yarıçap süzgeci; tablette doğrulanmadı → KONTROL 41 — F63.6, YORUM F55.1
- ~~**Kalem ucu tahmini**~~ — kullanıcı kararıyla çıkarıldı (2026-11-14: "yalnız parmak aracı olsun") — F62.6
- **Dolma kalem** — YAZILDI (`InkPen.fountain`, F62.5; `test/ink_paint_v2_test.dart`), cihazda denenmedi — YORUM F55.4
- **Büyük PDF (500 MB–1 GB)** — KOD YAZILDI (P08, 2026-11-11: akışla kopya, `localOnly`, rozet; `test/large_local_pdf_test.dart`); yalnız tablette 1 GB doğrulaması kaldı → KONTROL 20 — F65.9
- **Web'de ek görünmüyor / paylaşılan notta ek** — kullanıcıdan hata metni gerek — F65.6
- **Editör bölge çıkarma + `_mutate` kök setState** — P20 kısmi (bölge çıkarılmadı; M6 `_sameVisual` silinmedi, daraldı; M7 kural CLAUDE.md'ye yazılsın mı; Seç kipi/tablette satır 23 kalıyor; ekran okuyucu taşı eylemleri yalnız tutamaçlı kipte) — sabah bakılacak — F64.3, F64.4
- **Kasma kökten artığı** — P55 [apk] ile bitti (2026-11-14); yalnız plan arşivindeki `[ ]` işaretleri bayat, cihazda his kontrolü KONTROL 3 — HIZ F84.1, F84.2, F68.3
- **Kaydırma kabulü** — P43/P46 ölçtü (%2,3–3,3); resmî kabul yazılmadı — F68.4, AKICILIK Faz 21
- **Pano gövdesini böl (ölçüm kapılı)** — boşa kurulum düzeltildi (kısmen), kalanı ölçüm kapılı — F68.2
- **Takvim haftalık ızgarada sürükle, görev elle sırala** — ay görünümünde sürükleme VAR (`_MonthCell` DragTarget), `WeekPage`'de yok — TAKVIM (ayrı faz)
- **Uçtan uca akış testleri** — widget düzeyinde YAPILDI (F18.8: `user_flows_test`, `media_bubbles_share_test`, `backup_service_test`); açık kalan: `integration_test/` emülatör akışları + web ağır işler (F17.3) — F17.2, F17.3
- **PPTX düzenleme portu** — depo izni sonrası — F18.20
- **Şablon önizlemesinin liste dalını kaldır** — liste şablonları `QuickListScreen`e taşındı (2026-11-15); `TemplateComposer` liste dalı + `showNoteTemplateSheet` üretimde çağrılmıyor, `note_templates_test` / `template_sheet_layout_test` / bütçe S48 / ekran turu ona bağlı → birlikte taşınıp silinecek; ayrıca hızlı liste + hızlı ekle cihazda A/B ölçülmedi (KONTROL "Telefonda bak") — `docs/hafiza/editor.md` sonu
