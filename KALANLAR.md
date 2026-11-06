# KALANLAR — canlı kalan iş

Biten madde silinir; karar/neden bilgisi HAFIZA.md'ye yazılır. 2026-10-20
(F8.7): 20+ turun "CİHAZDA GÖRÜLMEDİ" listeleri TEK cihaz doğrulama turuna
indirildi, sonradan geri alınan/eskiyen maddeler atıldı. Eski hâli
`KALANLAR_ARSIV.md` (dondurulmuş).

> **2026-11-01:** Açık işlerin TEK planı artık `KALAN_ISLER_PLANI.md`
> (Faz 18 bulut · Faz 19 senin). Eski §1 (konsol/hesap) → F19.B/F19.D,
> §3 (açık kararlar/sınırlar) → F18.2–F18.5, F18.11, F18.13, F18.27 ve
> "Bilinen sınırlar", §4 (sonra yapılacak) → F18.17–F18.20, F18.22 —
> burada tekrar tutulmaz. Bu dosyada yalnız **§2 cihaz doğrulama listesi**
> kalır (F19.C1'in ayrıntısı); F18.31 onu ~10 dakikalık duman testine indirir.

## 1. Senin yapacakların → `KALAN_ISLER_PLANI.md` Faz 19 (B, D)

## 2. Duman testi (~10 dk telefon + web) — F18.31, 2026-11-02
143 maddelik eski liste `KALANLAR_ARSIV.md` sonunda (olduğu gibi). Hepsi
testlerle korunuyor; burada alan başına 1–2 adım. F18.8 akış testleri
(yaz → paylaş, iki sayfalı kopya, işaretlileri sil, tam yedek) ve birim
testleri otomatik doğrulananları kapsıyor. Sorun görünce madde numarasıyla
bildir. Yapılamayanı "denenmedi" diye yaz, silme.

**Cihaz turu sonucu (2026-11-05, v1.1.701–704, Mi Note 10 Lite, yerel hesap):** geçenler silindi, kalanlar kısaltıldı. Bulunan ve düzeltilen hatalar HAFIZA "Cihaz turu kök nedenleri". Denenmedi, nedenleri: Google hesabı/AI gerekir (#7, #8, #31, #79, Gelen ve Kişiler); ikinci hesap (#81, #82, #83); ses (#7, #47 dikte); şifre girişi otomasyonda yapılmadı (#10, #11 kilit); web (#16–19, #27, #29, #30, #33, #57, #74, #76, #84, #85); tablet/kalem (#20, #22–24, #28, #86); Vulkan ya da temiz Android 12 cihazı (#59, #60 beyaz açılış); kişisel köprü APK'sı (#14).
**Açık ölçüm:** yazma ana bloğu `taban.py`'de 148 → 229 ms, >16 ms 42 → 51 blok (v1.1.671 → v1.1.701, tek koşu, `adb` tuşu; CI bütçesi temiz; profil ile nedenine bakılmalı).

**Ek senkronu (2026-11-06, v1.2.2, Mi Note 10 Lite, Google hesabı) — GEÇTİ:** görsel eklendi →
izin bir kez kendiliğinden soruldu → Drive'daki "Notlar" klasörüne yüklendi (`driveId`) + önizleme
(25 KB, izinsiz açılıyor); dosyası telefonda olmayan kayıt (başka cihaz benzetimi) Drive'dan indi,
kartta çizildi. Yeni metin notunda klavye açık; not "+" → Hatırlat aynı "Ne zaman" levhası; Ayarlar →
İzinler'de Xiaomi "Otomatik başlatma" satırı MIUI ekranını açıyor; ilk hatırlatıcı kaydedilince ipucu + "Aç" çıkıyor (v1.2.5). Gmail bağlan + Nota kaydet, sürüm geçmişi, tam yedek kaydet/geri yükle de geçti.

**Telefon (v1.1.N, Google hesabı; ~7 dk)**
1. [ ] (2026-11-06, yazıldı, cihazda doğrulanmadı) Klasör düğmesine basılı tut → ortada halka; parmağı hafif bir yöne kaydır → klasör vurgulanır, bırak → geçer; ortada bırak → vazgeç. Takvim → + : levha akıcı açılıyor, klavye sonra geliyor; ay başlığı görünür. Google Takvim bağla: API kapalıysa "Etkinleştir" çıkıyor (F19.B10).
2. [ ] ⋮ yerine başlık "+" levhası → Araçlar → İlgili notlar → Bağla (F18.17). Biçim, `[[` bağlantısı ve "1 bağlantı" çipi telefonda geçti.
4. [ ] Görsel: üstüne kalemle çiz + açık metin → Paylaş → Ekler / PDF: çizim ve yazı görselde (F18.13). Çıkan dosyaya telefonda bakılmadı; test `image_annotations_export`.
5. [ ] PDF balonlu notta basılı tut → balon → Paylaş: "Sayfa N — …" satırı. Toplu Kopyala balon satırını veriyor (görsel balonda geçti).
6. [ ] Hatırlatıcı bildiriminde "Tamam" yarına kaydırıyor (bildirim MIUI'de eylemleri göstermedi). Çalma, Hatırlatıcılar ekranı ve sonraki güne ilerleme geçti. Yeniden başlatma: MIUI otomatik başlatma izni açıkken dene.
7. [ ] Sesli: ana ekran mikrofonu = dikte; basılı tut = AI sesli not
   ("her pazartesi 9'da toplantı" → tekrarlı hatırlatıcı).
8. [ ] Yapay zekâ: Tüm notlar sohbetine eski bir nottaki bilgiyi sor →
   cevap + kaynak not çipi (F18.18). Bir notta ⋮ → Kart üret → kaydet →
   Yapay zekâ → Bugünün kartları → Cevabı göster → İyi (F18.19).
9. [ ] Tam yedek — telefonda geçti (2026-11-06, v1.2.4): "Tam yedek al" → sistemin Kaydet penceresi → İndirilenler (görsel içinde); geri yükle → "0 not geri yüklendi, 2 atlandı (zaten var)". Kalan: boş hesaba/yeni cihaza geri yükleyince görsel/çizim/balon/sayfa/klasör geliyor mu; Keep Takeout zip (F18.15). Not: Dosya Okuyucu seçicisi yeni kaydedilen `.notyedek`i listelemedi ("Diğer" → sistem seçicisi buluyor) — dosya-okuyucu deposunun dizinleme işi.
10. [ ] Ayarlar → Hesap → Uygulama kilidi aç → uygulamayı arka plana al,
   1 dk sonra dön → kilit; widget'tan / bildirimden açınca da kilit;
   "Son uygulamalarda gizle" → son uygulamalar boş (F18.6).
11. [ ] Not kilidi (şifre). Sürüm geçmişi "Bu sürüme dön" + Geri al telefonda geçti (2026-11-06).
12. [ ] Not paketi gönder-aç; PDF → var olan not. Dosyalar'dan PDF paylaş → yeni PDF notu + Drive'a yükleme telefonda geçti (2026-11-06). Metin paylaşımı (iki hedef) geçti.
13. [ ] TalkBack'te kart tek seferde okunuyor (F19.C2). Yazı ölçeği 1,3 + "Sistem yazı boyutunu izle" taşmadı.
14. [ ] Kişisel köprü: Harita "not al" (uygulama kapalı), Kanallarım "Not al" (F19.C4).
15. [ ] Yeni sürüm çıkınca açılışta bir kez "Yeni sürüm var" + Ayarlar →
   Hakkında satırı (F18.21).

**Web (Chrome, ~3 dk)**
16. [ ] Soğuk açılış tek logo; giriş; not yaz → telefonda ≤ 20 sn.
17. [ ] + → Dosya → büyük PDF → balon → Balonlu PDF indir (web'de ağır iş:
   donma süresi kabul edilebilir mi — F18.9).
18. [ ] Pencereyi daralt/genişlet → liste yerinde; Drive'daki ek "bağlan" ile
   iniyor.
19. [ ] Ayarlar → Uygulama kilidi web'de yalnız şifre/desenle açılıyor.

**Açık kalan gözlem**
- [ ] **Veri kaybı — kanıt bekliyor (2026-11-01):** liste notunda bir maddenin
  metni boşaldı ("Boş madde"); 3 denemede yeniden üretilemedi. Tekrar
  görülürse tam adımları yaz; tahminle yama yapılmadı.

**Tablet / S Pen (varsa)**
20. [ ] Kalem sayfaya yazar, parmak metne gider; kalemler ALTTAKİ çekmecede
   (çizince iner, dokununca çıkar), tam ekran.

**2026-11-02 kullanıcı listesi (bu sürümde yapıldı, cihazda bak)**
22. [ ] Tablette Google ile giriş: seçici açılmazsa tarayıcı penceresiyle
   girmeli (yerel giriş anında düşerse yedek yol).
23. [ ] Tablette ray dar (64 dp, etiketsiz), "Gelen" rayda yok. Not açınca
   ray kalkar, solda tek sütun liste, sağda not; sol kenardaki tutamak /
   kenardan çekme ray çekmecesini açar, geri tuşu kapatır.
24. [ ] Katlanabilir: kapalıyken telefon düzeni; açınca liste + not yan yana,
   ayraç menteşeye oturur; açıp kapatırken liste yerinde.
25. [ ] Liste notunda görsel maddenin ortasına denk gelince: görselin
   üstündeki satırlar tam genişlik, yalnız hizadaki satırlar sağa kayar.
26. [ ] Kalem kipindeyken + → Çizim ekle → ayrı tuval → Nota ekle → görsel
   olarak nota gömülür; "Sayfaya el yazısı" kalem kipini açar.
27. [ ] Web'de Drive ekli not (2026-11-06 sonrası): telefondan eklenen GÖRSEL kartta
   izinsiz hemen görünür (küçük önizleme); not içinde üstte "N ek Google
   Drive'ında · Göster" → tek izinle (Drive dosyaları + eski gizli klasör) hepsi
   tam boy iner; sayfayı yenile → yeniden izin istemez (~55 dk). Web'den eklenen
   ek telefonda açılıyor. (Telefon tarafı geçti; web'de Google oturumu olmadığı
   için denenmedi — tahmin: drive.file erişimi Cloud projesi düzeyinde.)
28. [ ] Tablette not açıkken liste/not ayracını sola zorla → "Tam ekran için
   çek" → biraz daha → "Bırak: tam ekran" → bırak: tam ekran. Sol kenardan
   sağa çek → tam ekrandan çıkar.
29. [ ] Geniş ekranda (web ≥ 640 px): not yokken liste tam genişlik; not aç →
   solda tek sütun; tam ekran → sol üstte ☰ → liste geri gelir; geri ok →
   tam genişlik ana sayfa, kaldığın kart görünür. Ctrl+Shift+F ve Esc
   klavyeyle (tarayıcı otomasyonunda Ctrl'li kısayollar Flutter'a ulaşmadı —
   Ctrl+/ dahil; elle denenmeli).
30. [ ] Kalem tepsisi (2026-11-02 yeniden): web'de fareyle kalem kipinde imleç
   artı, çizgi tam tıklanan noktada; tepsi tek satır, alçak; seçili kaleme
   yeniden dokun → renk paneli üstte kart; sayfaya yaz → panel kapanır, tepsi
   iner (yalnız tutamak + renk noktası); telefonda "⋯" → yinele/ayarlar.

**2026-11-04 gece görevi (Faz 28 — yazıldı, cihazda doğrulanmadı)**
31. [ ] (F28.1) Telefonda geçti (2026-11-06): bağlan + izin, gelen kutusu, "Nota kaydet"
   (sonda Gmail bağlantısı). Kalan: aramada `from:…`; ekli (PDF/görsel) e-posta;
   "AI özetiyle not" ve "Görev listesi çıkar"; web'de yenileyince yeniden bağlan
   istemiyor (≤ 55 dk).
32. [ ] (F28.4) Aynı PDF'i sabit ve balonlu modda aç → zemin, sayfa arası boşluk,
   gölge aynı.
33. [ ] (F28.3/F28.5) Web'de ⋮ → Ayarlar/Arşiv/Çöp açılıyor; tablette ray tepesindeki
   ev simgesi her ekrandan ana sayfaya; Alt+Home.

**2026-11-04 gece görevi (AKICILIK Faz 20–27 bulut kısmı — yazıldı, cihazda ölçülmedi)**
Ölçüm "Notlar Ölçüm" profil derlemesinde ya da release'te `tool/perf` ile
(AKICILIK_PLANI Ek A); sayıları AKICILIK_PLANI Ek B'ye satır olarak yaz.
37. [ ] (F22.7) Geri tuşu: paylaşılanlar → not → geri → geri → uygulama
   kapanmıyor; ana ekranda geri → çıkar.
39. [ ] (F26.2) Görselli 20+ notla ana ekran → uygulamayı arka plana al,
   başka uygulama aç, 1 dk sonra dön → kart görselleri boş kutu/tek tek
   belirme OLMADAN yerinde (videoyla: F26.1).
40. [ ] (F25.1, önce ölç) `preloadNoteFonts` gerçek süresi (profil zaman
   çizelgesi) ve beklemeyi kaldırınca ilk 2 sn'deki yeniden yerleşim → karar
   AKICILIK_PLANI F25.1.
42. [ ] (F23.4) 4 not türünde aç/kapa (`scen.open_close`): geçiş raster
   < 12 ms/kare (bugün 18–26); içerik solması gözle aynı.
44. [ ] (F25.2, ölç) Soğuk açılışta Firestore yerel önbelleğinin ilk not
   listesi yayını (ms, profil zaman çizelgesi) → anında içerik gerekli mi;
   bayat özet / kilitli not kararı.
46. [ ] (F26.3/F26.4) "Son güncellenen" sıralamasında bir notu aç, yaz,
   kapat → not kapanırken tepedeki yerine iner, sonra zıplamaz; geniş
   ekranda yazarken soldaki listede kart yerinde. Segment (süzgeç/klasör)
   kaydırması videoda flaşsız (F26.1).

**2026-11-04 (yazıldı, telefonda kısmen denendi)**
47. [ ] (F24.2) 6 KB+ notta GERÇEK klavyeyle yaz (Gboard, otomatik düzeltme, dikte): metin doğru yerde; uzak paragrafa dokun → imleç orada; uzun bas → seçim; Tümünü seç + Kopyala tüm notu alır; kapat-aç → metin aynı. adb ile denendi, Gboard önerisi ve dikte DENENMEDİ.
48. [ ] (F25.2) Telefon SOĞUKKEN soğuk açılış ×3: içerik ilk ~1 sn'de, sabit notlar yerinde, liste gelince zıplama yok; özet gösterilirken karta dokunmak bir şey yapmaz (<1 sn).

**2026-11-04 — yeni tema (TEMA_PLANI Faz 29–35, yazıldı, cihazda doğrulanmadı)**
50. [ ] (F31.2, K4) Ana ekranı 200+ notla hızlı kaydır (`tool/perf/`): raster p90 ≤ 9 ms (önce 8,6). Kart gölgesi şimdilik bulanıksız 1 dp; bütçe tutuyorsa `AppTokens.cardShadow`'a yumuşak gölge (0 3 10 /%5) denenip AYNI ölçüm tekrarlanacak.
51. [ ] Koyu temada BEYAZ özel renk: yazı okunur. Sarı YAZI açık notta koyu sarı-kahve, koyu notta açık; renk seçerken odak ve kaydırma yerinde. Siyah renkte not ve kart geçti.
52. [ ] (F33) Defter: mavi sayfada çizgiler mavi-gri, adaçayında yeşil-gri; kenar çizgisi mercan (kırmızı hata rengi değil); kartta da aynı. Noktalı desende noktalar görünür.
53. [ ] (F35) Ana ekran widget'ı Adaçayı renklerinde (gece: koyu Adaçayı); uygulama açılışında beyaz parlama yok (açılış zemini `#EAF0EB`). Web: açılış ekranı ve tarayıcı çubuğu rengi yeni zemin.

**2026-11-04 — tutarlılık (TUTARLILIK_PLANI Faz 36, yazıldı, cihazda doğrulanmadı)**
56. [ ] (F36.4) Üste sabit görsel/PDF/video ⋮ → Paylaş; yazıya gömülü eke dokun → önizlemede Paylaş simgesi; ikisi de dosyayı (YouTube'da bağlantıyı) paylaşır.
57. [ ] (F36.5) Web'de (dahili AI kapalı) liste notunda parmakla kaydırırken hata yağmuru YOK; maddenin üstüne bilerek daire çiz → bir kez "Daire jesti yazımı yapay zekâyla düzeltir…", ikinci dairede sessiz; karala → "Madde silindi · Geri al" geri getirir.
59. [ ] (F27.3) Vulkan'lı bir cihaz (Adreno > 650 ya da Mali) varsa: `tool/perf/taban.py` kaydırma + geçiş; hedefler iki arka uçta da sağlansın. Test telefonu GLES, ölçülemedi.
60. [ ] (F30.6) Beyaz açılış: Mi Note 10 Lite'ta (MIUI 13, v1.1.671) ~0,6 sn beyaz SÜRÜYOR, kaynaklar APK'da doğru; temiz Android 12+ cihazda dene, orada da beyazsa ilk Flutter karesine bak. Ayrıca koyu notta durum çubuğu simgeleri açık, açık notta koyu; çizilmiş temalı açık notta da koyu.
61. [ ] (F31.4, F33.6, F34.4) Seçili kartı sürükle: hafif eğik + büyük gölge; kart ⋮'ten renk değiştir ve editörde renk değiştir: 200 ms solma; sayfalı notta yana çek: sayfa kayar, altta "2 / 5" hapı söner.
60. [ ] (F24.3) 120 maddeli listede gerçek klavyeyle: maddeye dokun → imleç dokunulan harfte, klavye önerisi seç, uzun bas → sözcük seçilir, sesle yazdır, TalkBack'te madde okunuyor ve çift dokunuşla açılıyor. Otomatik denendi: dokun, yaz, Enter.
61. [ ] (F25.1) Farklı yazı tipli (kaydedilmiş) not açılınca ilk seferde metin kısa süre başka yazı tipiyle görünüp oturuyor mu; rahatsız ediyorsa söyle (sabah bakılacak).

**2026-11-05 — not her yerde aynı (TUTARLILIK_PLANI Faz 37, yazıldı, cihazda ayrıntılı doğrulanmadı)**
63. [ ] (F37.2) 1 saat sonrasına ve yarına hatırlatıcı kur: kartta ve liste satırında "bugün/yarın HH:mm"; 3 gün sonrası yalnız simge; dar kartta (zoom ile çok sütun) taşma yok.
65. [ ] (F37.4) Renkli, siyah özel renkli ve renksiz liste notunu Paylaş → PDF ve Görsel: sayfa notun renginde (renksiz beyaz), kutucuk notun tonunda, yazı okunur, çok sayfalıda her sayfa boyalı. Koyu sayfa baskıda rahatsız ediyorsa söyle (sabah bakılacak).

**2026-11-05 — not ekranı (TUTARLILIK_PLANI Faz 38, yazıldı, cihazda elle doğrulanmadı)**
69. [ ] (F38.7) Klavye açılırken alt çubuk: telefonda ölçümde birikim çıkmadı (15 tur). Kendi notlarında hâlâ "her açılışta artıyor" görüyorsan hangi notta (ekli mi, uzun mu) söyle: sabah bakılacak. Görselli notta ilk açılış 33 ms, sonrakiler 66–149 ms farkı açık.
70. [ ] (F39.2, F39.3) Gerçek parmakla: ana ekranda iki parmak aç/kapa ızgarayı ölçekler, köşede sütun simgesi, bırakınca oturur; yana çek: ızgara parmağı izler, kenarda sonraki klasörün adı, kısa çekişte geri döner, seçili çip ortalanır. Dikey kaydırmayla yarışmıyor mu bak.
72. [ ] (F40.5) v1.1.704 üstü: sabit videoda telefonda ⋮ → Görüntüyü döndür (çubuğa sığmıyor), geniş çubukta düğme; tam ekranda da. Arka plana çıkınca durma ve kendi başlamama geçti.
73. [ ] (F40.6/F40.7) Aynı görsel sabit ↔ balonlu: çubuk rengi ve açıklama aynı; açıklama sabitte görselin altında, dokununca düzenleniyor. Sunum balonluda zemin artık siyah değil.
75. [ ] (F41.4) Başka uygulamadan görsel paylaş → not "Yeni ek nerede dursun?" ipucuyla açılır. Panel, Ayrı çizim (parmak; "Yalnız kalem" kapalıyken), vazgeçince boş not kalmaması, not içi dosya levhası geçti.
76. [ ] (F41.4 web) Not açıkken dosyayı sayfaya bırak ya da görsel yapıştır → o nota girer; not kapalıyken yeni not; Word'den metin+resim yapıştır → yalnız metin yazılır.
74. [ ] (F40.8) Web: görsele sağ tık menüsü, üstüne gelince ⋮, masaüstünden dosyayı sayfaya sürükle-bırak → "dosya" levhası. Android tablette sürükle-bırak yok (bilerek).

**2026-11-05 — yapay zekâ ve ses (TUTARLILIK_PLANI Faz 42, yazıldı, cihazda elle doğrulanmadı)**
77. [ ] (F42.1) Ana ekran mikrofonuna basılı tut → AI sesli not. Rozetsiz mikrofon ve bir kezlik ipucu geçti.
78. [ ] (F42.2) Puan bitince kota kartı ve yenilenme saati; web'de dahili kapalıysa kart, "Tekrar dene". Misafir kilidi ve AI levhası kartı geçti.
79. [ ] (F42.4) Notta dikte bitir (uzun cümle) → bildirimde "AI ile düzelt" → aralık düzeliyor, Geri al çalışıyor; bu arada metni değiştirdiysen dokunmuyor. Anahtarsız misafirde öneri çıkmıyor.
80. [ ] (F42.6) Parmakla karala/daire → hiçbir şey olmaz; Ayarlar → Görünüm'den açınca çalışır; kalemli cihazda otomatik algılama kapalıyken. Parmakla üstünü çizme v1.1.704'te geçti.

**2026-11-05 — paylaşım ve Gelen (TUTARLILIK_PLANI Faz 43, yazıldı, cihazda doğrulanmadı: ikinci hesap ister, gerçek kişiye davet gönderilmedi)**
81. [ ] (F43.2) İkinci hesapla klasör paylaş, çipine dokun: ayrı sayfa açılmıyor, ana ekran süzülüyor, çip vurgulu, Süz düğmesinde ad ve ×, arama çalışıyor, geri tuşu kaldırıyor, yana kaydırmada durak. Üç yetkiyi dene: Okuma (kilit, düğme yok, not salt okunur), Okuma + yazma (yeni not sahibin klasöründe), Yazma (notlar yok, tek seferlik pencere). Sohbet şeritten açılıyor. Sahip paylaşımı kaldırınca süzgeç kapanıyor.
82. [ ] (F43.3) Ortak not: kart, liste satırı ve editörde aynı simge ve renk; editörde sayı (sahipte ve alıcıda). Renkli notta simge notun koyu tonunda.
83. [ ] (F43.4, F43.5) Levhada Ekler ile ek menüsünde Paylaş aynı dosyayı gönderiyor (işaretli görsel PNG basılı). Misafirde: not "+" levhasında Ortak çalışanlar, avatar levhasında ve rayda Kişiler kilitli; dokununca aynı giriş levhası.

**2026-11-05 gece — kullanıcı listesi (10 madde; yazıldı, cihazda doğrulanmadı)**
87. [ ] Ara başlık: maddede imleç varken "Ara başlık" → başlık o maddenin ALTINDA; başlığa basılı tut → menüde sola/ortaya/sağa, kartta da hizalı.
88. [ ] Biçim → Kapsam "Kelime" → imleci bir kelimeye koy → A+ iki kez: yalnız o kelime büyüyor, satır ya da komşu kelime değil (gövdede ve maddede).
89. [ ] Etiketli notta başlığın altında boş bant yok; kartta ve üst çubukta etiket temanın renginde dolu hap (Adaçayı, Lavanta, Zeytin).
90. [ ] Ayarlar → Görünüm: Lavanta ve Zeytin; telefonda tema kartları iki sıra, adlar okunuyor.
91. [ ] Şablonlar: yıldızla 4 favori (5.si uyarı), "+" menüsünde Şablon bölümü favorilerle diziliyor; kartlar küçük; alışverişte "İki sütun" → not iki sütunlu açılıyor; öneri çipleri grup içinde A→Z.
92. [ ] Sabit PDF/görselde balon yaz → geri: önce klavye, sonra kart kapanır, not açık kalır; üçüncü geri not. Kart alttan süzülerek açılıyor.
93. [ ] Uzun PDF'i (sabit bölme ve tam ekran) hızlı kaydır: takılma azaldı mı; basılı tutunca metin seçimi hâlâ ilk denemede geliyor (metin artık gecikmeli yükleniyor).
94. [ ] Ara başlıklı listede klavye aç/kapa kasması: widget testinde yeniden üretilemedi (satır kuruluşu ve kare süresi başlıklı/başlıksız aynı, odakta satır boyu değişmiyor). Hâlâ kasıyorsa hangi notta (madde sayısı, başlık odakta mı) söyle — sabah bakılacak.

**2026-11-05 — web ve geniş ekran (TUTARLILIK_PLANI Faz 44, yazıldı, tarayıcı ve tablette elle doğrulanmadı; tur aracı ve testlerle görüldü)**
84. [ ] (F44.5 web) Ctrl+tekerlek sütun değiştiriyor, tarayıcı sayfası YAKINLAŞMIYOR; dokunmatik yüzeyde kıstırma sütun, iki parmak yatay kaydırma klasör geçiyor, atalet ikinci klasöre atlamıyor. Alt+←/→ klasör geçiyor, tarayıcı geri gitmiyor; arama kutusundayken geçmiyor. Fareyle kartın üstüne gelince ⋮; seçimde Ctrl+A ve Delete. Maddede sağ tık menüsü.
85. [ ] (F44.1, F44.2) Rayda kalem, mikrofon ve "+" (panel sağa açılıyor, Esc kapatıyor); Ayarlar'dayken "+" → Metin notu notu açıyor; rayda "Notlar" açık notu kapatıp ana sayfaya dönüyor. Dar pencerede Ayarlar ve notta 🏠 çubukta, şerit yok.
86. [ ] (F44.7, F44.8) Tablet dikey: nota girince liste çekiliyor, ☰ geri getiriyor, başka karta dokununca yine çekiliyor, kart açılış geçişi garip durmuyor. Tarayıcıyı daraltıp genişlet: açık not, seçim ve liste konumu yerinde.
87. [ ] (TAKVIM F47.3) İki parmakla: yılda bir ayın üstünde aç → o ay; ayda bir haftanın üstünde aç → o hafta; kapat → ay → yıl. Geçiş parmak noktasından büyüyor, kasma yok; tek parmakla yatay kaydırma dönem değiştiriyor, haftada dikey kaydırma çalışıyor. Web'de Ctrl+tekerlek aynı.
88. [ ] (TAKVIM F47) Ana ekran ⋮ → Takvim: ajanda, başlıktan ay ızgarası, güne dokunma. Yeni etkinlik (10 dk önce hatırlatma) → bildirim zamanında geliyor, dokununca takvim açılıyor; tüm gün etkinliği (o gün 09:00); tekrarlı etkinlikte "yalnız bu" silme. Hatırlatıcılı not ajandada. Web/tablette ay solda. Takvim → ✓ Görevler: görev, alt görev, yeni liste; tarihli görev ajandada; tekrarlı görev tikleyince sonraki güne geçiyor; "zamanı gelince hatırlat" bildirimi.

**2026-11-06 — tema, ana ekran, takvim (yazıldı, cihazda doğrulanmadı)**
95. [ ] Sabit görseli yüzene al → alttaki "Geri al" → görsel yine sabit (yüzen → sabit, ek → yüzen için de).
96. [ ] Ayarlar → Görünüm: Beyaz ve Saman; telefonda tema kartları 3 × 3, adlar okunuyor; Saman'da kart kremi masadan açık.
97. [ ] Ana ekran ⋮ → Zemin → "Takvim zemini": ayın takvimi zeminde (bugün vurgulu, etkinlik adları), kartlarda başlık net, gövde soluk; kaydırma kasıyor mu (Opacity katmanı)?
98. [ ] Ana ekranda Tümü görünümünde sola kaydır → kenarda "Takvim" → takvim açılıyor; klasördeyken sola kaydırma klasör geziyor; Ayarlar → Notlar'dan kapatılınca sola kaydırma eskisi gibi.
99. [ ] (TAKVIM F47.5) Ay görünümünde etkinlik/görev/hatırlatıcı şeridine basılı tut → başka güne sürükle → taşındı + "Geri al"; tekrarlı etkinlik sürüklenmiyor.
100. [ ] (TAKVIM F46.5) Tam yedek al → yeni hesapta geri yükle: etkinlikler, görevler, listeler ve güne bağlı notlar geliyor; ikinci yükleme çoğaltmıyor.
101. [ ] (TAKVIM Faz 48, önce F19.B10) Takvim → ☁ → Google Takvim'i bağla: takvimler renkleriyle, birini kapatınca etkinlikleri kayboluyor; Google etkinliği ayda çerçeveli şerit, ajandada ☁; dokununca salt okunur levha → "Google Takvim'de aç" Google'da açıyor, "Toplantı notu" not açıp bağlıyor (levhada "Bağlı notlar"). Uygulamayı kapat-aç: etkinlikler ağsız da önbellekten geliyor. Web'de 55 dk sonra yeniden bağlan istemesi beklenir.
102. [ ] (TAKVIM Faz 49) Ay görünümünde güne dokun → "Bu güne not" → "6 Kasım Cuma" başlıklı not açılıyor, ikinci kez aynı not; levhada güne bağlı notlar ve "O gün yazılan notlar". Not ⋮ → Takvime bağla → güne / etkinliğe / yeni etkinlik; notta başlığın altında "📅 6 Kas · …" hapı → takvim o günde açılıyor. Etkinlik levhasında "Toplantı notu".
103. [ ] (TAKVIM Faz 50, önce F19.B10) Liste notunda maddeye basılı tut → "Görev yap" → görev; görevi tikle → madde işaretli, maddeyi kaldır → görev açık. Görevler → ☁ → bağla: yerel görevler Google Görevler'de, Google'dakiler burada (listeleriyle); Google'da tamamla → 15 dk içinde ya da "Şimdi eşle" ile burada tamam; burada sil → Google'dan da silinir.
104. [ ] (TAKVIM Faz 51, önce F19.B10) Yeni etkinlik → "Google Takvim" seçili → kaydet → ilk kez yazma izni soruluyor → etkinlik hemen görünüyor, Google Takvim'de de var (tekrar/hatırlatmasıyla). Uçak kipinde kaydet → levhada "1 değişiklik bekliyor" → bağlantı gelince gidiyor. Google etkinliğinde Düzenle/Sil; tekrarlı oluşta yalnız "Google Takvim'de aç".
105. [ ] (TAKVIM Faz 52) Brifingi yenile: bugünün etkinlik/görevleri ve gecikmiş görev anılıyor. Asistana "yarın 15:00 dişçi ekle", "cumaya kadar raporu bitir görevi", "yarın neler var?" → takvimde/görevlerde görünüyor, cevap doğru. Notun sonuna "yarın 15:00 toplantı" yazıp çık → "Takvime ekle" bildirimi. Afiş fotoğrafında metin tanı → takvim simgesi → etkinlik taslağı. Gmail iletisinde "Görev yap". Takvim ⋮ → .ics dışa aktar, Google Takvim'e içe aktar; Google'dan alınan .ics'i buraya içe aktar, ikinci kez çoğaltmıyor.
106. [ ] (TAKVIM Faz 53) Takvim → 🧘 Rutinler → "Sabah" (3 adım, 07:30, hatırlat) → ajandada her gün; 07:30'da bildirim; gün levhasında adımları tikle → tamam, kartta 🔥 seri ve şerit dolu. Ana ekran "Bugün" widget'ında etkinlik/görev/rutin satırları.
107. [ ] Not ⋮, kart ⋮, not "+", ana ekran ⋮, çoklu seçim ⋮ → sağ üstte ⚙ → bir işlemi gizle, birini yıldızla hızlı satıra al, sürükleyerek sırala → kaydet → menü öyle; "Varsayılan" geri getiriyor.
108. [ ] Ana ekran Tümü'de SAĞA kaydır → takvim (sola kaydırma klasör geziyor).
109. [ ] Sol alttaki klasör düğmesi: dokun → Klasörler; basılı tut → üstte ad şeridi, sağa/sola hafif kaydır → titreşimle kayıyor, bırak → o klasör açılıyor.
110. [ ] Ayarlar → Görünüm: Krem, Şeftali, Nane (telefonda 3'lü sıralar); okunurluk.
111. [ ] Notta "+" → "Takvime ekle" → gün, saat → etkinlik levhası not bağlı açılıyor.

## 3. Açık kararlar / bilinen sınırlar → `KALAN_ISLER_PLANI.md` (F18.2–F18.5, F18.11, F18.13, F18.27, "Bilinen sınırlar")

- [ ] Web'de tarayıcının geri tuşu tam ekranda önce tam ekrandan çıkmıyor (go_router popstate PopScope'a uğramıyor); Esc/☰/Android geri çıkarıyor (2026-11-02)
- [ ] Web debug konsolunda "+" düğmesinin ipucunda `RenderFollowerLayer` uyarısı (yalnız debug assert) — kaynağı araştırılmadı (2026-11-02)

## 4. Sonra yapılacak → `KALAN_ISLER_PLANI.md` (F18.17–F18.20, F18.22)

- [ ] **Akıcılık Faz 20–27** → `AKICILIK_PLANI.md` (telefonda ölçülmüş kök nedenler; önerilen sıra 20 → 27, KARAR maddeleri F22.2–F22.4, F24.2, F25.1, F26.2) (2026-11-03)
- [ ] **Faz 21 kabulü sağlanmadı** (2 tur sonra kaydırma %3,4–4,2 / 33–50 ms, arama 139 ms): kalan engel raster+kart kurulumu birlikte (Faz 23.4/26) ve arama için KARAR (önbellek payı ya da vurgu katmanı) — `AKICILIK_PLANI.md` Faz 21 notu (2026-11-03)
