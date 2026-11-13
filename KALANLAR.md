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

> **2026-11-11 (F58.3):** Yapilacak cihaz adimlari artik docs/cihaz_turu.md icinde (telefon 40, tablet 27, web 20; yap -> beklenen). Otomatiklesebilenler docs/test_borcu.md. Asagidaki liste ARSIV olarak kalir; yeni dogrulama oraya yazilir.
143 maddelik eski liste `KALANLAR_ARSIV.md` sonunda (olduğu gibi). Hepsi
testlerle korunuyor; burada alan başına 1–2 adım. F18.8 akış testleri
(yaz → paylaş, iki sayfalı kopya, işaretlileri sil, tam yedek) ve birim
testleri otomatik doğrulananları kapsıyor. Sorun görünce madde numarasıyla
bildir. Yapılamayanı "denenmedi" diye yaz, silme.

**ÖNCELİKLİ TUR (2026-11-09) — önce bunlar, sırayla.** Liste 2026-11-02'den beri
büyüdü (~110 madde); "~10 dk" artık geçerli değil. Aşağıdaki 24 madde günlük
kullanımı ve veri güvenliğini kapsıyor; gerisi bunlardan sonra.
- Veri: #9/#100 (tam yedek → boş hesaba geri yükle), #47 (uzun notta Gboard + dikte, kapat-aç), D7 (not paketi kapat-aç), "Açık kalan gözlem" (boşalan madde).
- Günlük: #16 (web→telefon ≤ 20 sn), A7 + A9 + F2 (satır hatırlatıcısı, şerit), #6 (bildirimde "Tamam"), A11 + D3 + D6 (hızlı satır, alt çubuk 1,1 sn), D1 + D2 + C3 (yazım düzelt), F1 (aramadan kelimeye), #37 + A3 (geri zinciri), G2 + #109 (basılı tut halkası, klasör düğmesi), #7/#77 (ses).
- Kalem: A5 + D10 + G1 + H1 + H2 (şekil tanıma, çokgen, çizgi ucu), A6, C5, G3 + D9, #20.
- Takvim: #88, F3 + F6 + #102; #101/#103/#104 yalnız F19.B10 yapıldıysa.
- Gmail C1 + B9 · görünüm #51, #60 · web #29, #84 · H3 (son yazı boyutu).

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

**Tablet / S Pen (varsa)** — 2026-11-07 MatePad 11'de adb ile denendi (tepsi, silgi, ek+Drive, dikey/yatay); gerçek kalem enjekte edilemedi:
20. [ ] GERÇEK M-Pencil ile: yazı basınçla kalınlaşıyor; avuç ekrandayken iz kalmıyor (ilk kalem dokunuşu "yalnız kalem"i açar); yan düğme silgi; kalem havadayken uç önizlemesi; parmak metne/kaydırmaya gider.

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

**2026-11-08 — kalem, satır hatırlatıcısı, bildirim (dal `claude/a-kalem-bildirim-44cf8b`; yazıldı, cihazda doğrulanmadı)** — numaralar "A" önekli (paralel oturumla çakışmasın).
A1. [ ] Kalem kapsülü: yeni kalem görselleri (tükenmez, keçeli, fosforlu, silgi, gönye, kement) açık/koyu temada güzel mi; beyaz/siyah mürekkepte uç görünüyor mu.
A2. [ ] Kapsül ⋯ → "Bu kalemi sabitle" (2-3 farklı kalem/renk/kalınlık) → kapsülün üstünde sabit kalem şeridi; dokununca o kalem seçiliyor; basılı tutunca kalkıyor; uygulamayı kapat-aç → duruyor. Tablette (ray) aynı.
A3. [ ] "Sayfaya yaz (kalem)": ayar kartı açıkken geri → kart kapanır; kapsül açıkken geri → hapa iner; sonra geri → kalem kipi kapanır, NOT AÇIK; bir geri daha → ana ekran. × kalemi kapatıyor; ✓ (hızlı el yazısı notunda) notu kapatıp ana ekrana dönüyor.
A4. [ ] Uygulama simgesine basılı tut → "Kalemle yaz" → boş not kalem kipinde açılıyor.
A5. [ ] Kalemle kabaca daire, dikdörtgen, üçgen, düz çizgi, ok (tek çizgi ya da gövde + "^") çiz → sağ altta küçük düğme → dokununca düzgün şekil; geri al eski çizimi getiriyor. Yazı yazarken (harfler) düğme çıkmıyor mu / rahatsız ediyor mu? Ayarlar (kalem ⚙) → "Şekli tanı…" kapatınca çıkmıyor.
A6. [ ] Tik (✓) ve çarpı (✗) çiz → ilk seferde düğme → dokun → "Otomatik düzeltme açılsın mı?" → Aç → temiz tik/çarpı; sonrakilerde düğme doğrudan düzeltir; "Hayır" denince bir daha çıkmıyor; kalem ayarlarından açılıp kapanıyor. PDF/slayt üstünde de.
A7. [ ] Liste notunda maddeye basılı tut → "Hatırlat" → gün + saat → satırın sonunda ⏰ çip (saat yazılı); saate dokun → seçici → yeni saat; basılı tut → görev levhası (düzey, kişi, Gmail). Zamanında bildirim geliyor; dokununca NOT açılıyor. Görevler ekranında da görünüyor.
A8. [ ] Hatırlatıcı levhasında Bildirim: Az (sessiz, yalnız perdede), Orta (ses, açılır pencere yok), Sık (sesli + üstte açılır — eskisi), Acil (kişisel APK'da kilit ekranında tam ekran/alarm sesi; izin yoksa en yüksek öncelik). Ayarlar → Bildirimler'de dört ayrı kanal görünüyor.
A9. [ ] Ana ekran üstünde zamanı gelen hatırlatıcı/görev şeridi (+N); dokun → not açılıyor ve şerit maddesi gidiyor; ✕ hepsini kapatıyor; yeni hatırlatıcı zamanı gelince (uygulama açıkken) şerit kendiliğinden beliriyor.
A10. [ ] Uygulama simgesi rozeti: zamanı gelmiş açılmamış hatırlatıcı + bugünün tamamlanmamış görevleri sayısı (MIUI'de sayı, Pixel'de nokta); perdede tek sessiz "N hatırlatıcı/görev bekliyor" özeti — rahatsız ediyorsa söyle (kanal kapatılabilir). Huawei tablette rozet yok (GMS'siz başlatıcı; sabah bakılacak).
A11. [ ] Not yazarken (klavye açık) üst çubukta hızlı satır: kalın, madde imi, ☑, başlık (sırayla), fotoğraf, dosya, kalem (basılı tut = kalem ayarları), hatırlatıcı; yana kayıyor; klavye kapanınca tarih/etiket geri geliyor; klavye açılıp kapanırken titreme yok.
A12. [ ] Not kapanışı (yazdıktan sonra geri, karta küçülme): kasma azaldı mı? 4 not türünde (kısa, uzun, listeli, görselli) — `tool/perf/` ile ölçülürse kapanış karesi < 33 ms hedefi.
**Oturum B (2026-11-08) — yazıldı, cihazda doğrulanmadı:**
- B1. [ ] Ana ekran arama çubuğu: sağdaki ⋮/profil düğmesinin kenarına/boşluğuna basınca arama BAŞLAMIYOR; yalnız büyüteç ve metin alanından başlıyor.
- B2. [ ] Ayarlar → Görünüm → Yazı tipi: alçak levha, her kart kendi yazı tipiyle "Aa"; dokununca üstteki ekran anında değişiyor; Vazgeç açılıştaki tipe dönüyor.
- B3. [ ] PDF sayfa düzenleyicide sayfa seçiliyken geri tuşu önce seçimi kapatıyor. (Ana ekranda seçim modu + geri: kodda PopScope zaten var; kullanıcı "illa ×" dedi — telefonda yeniden dene, hâlâ çıkıyorsa kök neden başka.)
- B4. [ ] Zemin görseli olan, eki olmayan notta alt çubukta ataç rozeti artık çıkmıyor (kök neden varsayımı: zemin görseli ek sayılıyordu; kullanıcının notunda başka bir neden olabilir).
- B5. [ ] Dikte: uzun notta konuşurken yazılan satır ekranın içinde kalıyor (panel/klavye altında kalmıyor).
- B6. [ ] Yazarken alt çubuk iniyor, durunca ~0,65 sn sonra hemen geliyor; ilk seferde ipucu; Ayarlar → Kartlar'dan kapanıyor; kasma yok.
- B7. [ ] Takvim (web): yıl/ay görünümünde tekerlek yukarı = yakınlaş (imlecin ayı/haftası), aşağı = uzaklaş; Ctrl+tekerlek haftada gün açıyor.
- B8. [ ] Gmail: kart satırları tema renginde, etiket çipleri; iletide tarih çipi → etkinlik levhası, kişi çipi → "Nota ekle", ilgili not çipi.
- B9. [ ] Gmail iletisinde metin seç → menüde "Nota ekle" → seçici (üstte yeni not, altında küçük kartlar) → not açılıyor, metin + kaynak satırı ekli.
- B10. [ ] Takvim: gün levhası / etkinlik / Google etkinliği → "Mevcut notu bağla"; ajandada bağlı-not simgesine dokun → not açılıyor.
- B11. [ ] Rutinler → ✓ (nottan rutin) → seçilen notun maddeleri adım olmuş rutin düzenleyicide.

### C1–C8 (2026-11-08 oturum C — yazıldı, cihazda doğrulanmadı)
- C1 Gmail: seçili yazı → altta "Nota ekle" düğmesi; bağlantılar tıklanır; e-postadaki görseller altta; sağ üst harf → hesap seç / "Başka hesap ekle" (Android hesap seçicisi), yeni hesapta "Bağlan" çıkar.
- C2 Hızlı satır: en sağda ⋮; ⚙ ile düzenleme modu → İtalik/Altı çizili/Vurgula/Sesle yaz eklenebiliyor mu.
- C3 Yazım düzelt (✓abc): "herşey " → "Her şey "; Enter'da satır sonu nokta; Gboard/Samsung önerisiyle "kalmel" → "kalem".
- C4 Not paketi: metinde yazı seç → 📦 → etiket; dokun → önizleme (yaz, kalemle çiz, çöz). Listede maddeleri seç → 📦 → çerçeveli özet; dokun aç, dışarı dokun kapan.
- C5 Kalemle tik/kare çiz → işaretçiye KALEMLE bas → düzelir, seçili kalır; taşı + sağ alt tutamaktan boyutla.
- C6 Sabit PDF: kalem kipinde üstüne yaz, parmakla kaydır; kalem kapalıyken bölme çubuğundaki ✏.
- ~~C7 Balon el yazısı~~ kaldırıldı (2026-11-08 ikinci tur).
- C8 Kalem küçük paneli: silgi ⇄ son kalem tek dokunuş; liste maddelerinde ↑/↓ (fiziksel klavye).

### D1–D10 (2026-11-08 oturum D — yazıldı, cihazda doğrulanmadı)
- D1 Yazım düzelt açık: "yaoçoılıyor " → "yapılıyor "; "eksiknyapılıyor " → "eksik yapılıyor "; otomatik düzeltmeyi geri al (sil + eskisini yaz) → bir daha düzeltmiyor mu; kendi düzelttiğin kelime iki kez sonra kendiliğinden düzeliyor mu. Yazım düğmesine basılı tut → levha (öğrenme, sil).
- D2 Başlıkta "bakım togg" → "Bakım Togg".
- D3 Hızlı satır: kalem yalnız simge; 📷 ve 📅 düğmeleri; tablette (yüzen klavye / fiziksel klavye) alan odaktayken hızlı satır görünüyor mu.
- D4 Web ve tablette madde tutamağı hep görünür, sürükleyerek sıralama; Esc: levha/diyalog kapanır, sayfada geri gider.
- D5 Satır hatırlatıcı çipi yazıyla aynı hizada; dokun → menü → Sil (geri al çalışıyor mu).
- D6 Yazarken alt çubuk 1,1 sn sonra geliyor; yeni maddeye geçince / klavye kapanınca hemen.
- D7 Not paketi açıkken "Yeni madde" / Enter → paket bozulmuyor, yeni madde pakette; boş son maddede Enter paketten çıkarıyor; uygulamayı kapatıp açınca paket duruyor.
- D8 Kalem kipinde küçük hap: daha geniş, silgi ile hap açma karışmıyor.
- D9 Sabit (üstte) PDF: tam ekran yapmadan kalemle yazılıyor mu.
- D10 Kare/dikdörtgen/üçgen/çember: kabaca çiz → işaretçi doğru şekli öneriyor mu; kareye yakın → tam kare, belirgin uzun → dikdörtgen, eğik/yamuk → serbest dörtgen. Şekil aracında Üçgen ve Tablo.

### F1–F7 (2026-11-09 oturum F — yazıldı, cihazda doğrulanmadı)
- F1 Ana ekranda ara → karta dokun → not, arama çubuğu açık ve kelimeye kaydırılmış geliyor mu (klavye açılmadan); uzun liste notunda da.
- F2 Zamanı gelenler şeridinde satır görevine dokun → not o maddeye kayıyor mu.
- F3 Takvim gün levhasında çöp → "Geri al" levhanın ÜSTÜNDE görünüyor ve çalışıyor mu.
- F4 İpucu şeridi ekranın herhangi bir yerine dokununca kalkıyor mu.
- F5 Ayarlar → Depolama: yedek durumu satırı; tam yedek kaydedince tarih/sayı güncelleniyor mu.
- F6 Takvim şeridi daha ince (36 dp), altındaki boşluk kalktı mı; gece yarısından sonra uygulamaya dönünce "bugün" doğru mu.
- F7 Klavye önerisinden kelimenin EKİNİ değiştirmek ("kalemi" → "kalemde") öğrenilmiyor mu.

### G1–G4 (2026-11-09 oturum F, 2. tur — yazıldı, cihazda doğrulanmadı)
- G1 Kalemle çizip uçta bekle → üstte dolan halka (şekil simgesi), dolunca şekle oturuyor; parmakla çizgiye basılı tut → silgi halkası → silgi düğmesi.
- G2 Ana ekranda karta basılı tut → parmağın üstünde dolan halka, dolunca kart elde; yana çekişte etiketin altındaki çubuk doluyor, dolunca bırakınca geçiyor.
- G3 Sabit görsel/PDF: çubukta "T" → dokunduğun yere yazı kutusu, klavye açık. Yüzen görselde araç çubuğunda "T", ek şeridi/sağ tık menüsünde "Üstüne yazı ekle" → tam ekran yazı kipinde açılıyor; PDF tam ekranda "T".
- G4 Dar telefonda (≤ 360 dp) sabit PDF çubuğu taşmıyor mu (sürükleme tutamağı küçülüyor).

### H1–H3 (2026-11-09 oturum G — yazıldı, cihazda doğrulanmadı)
- H1 Kalemle kabaca beşgen / altıgen / yedigen çiz → işaretçi düzgün çokgen öneriyor mu; daire hâlâ daire mi (sekizgen bilerek daire sayılır).
- H2 Kalemle düz çizgi çiz, uçta bekle → çizgiye oturunca kalemi KALDIRMADAN gezdir → uç kalemi izliyor, başlangıç yerinde.
- H3 Bir notta Biçim → yazı boyutunu büyüt (seçim yokken) ve yazı tipini değiştir → yeni metin/liste notu aynı boyut ve tiple açılıyor mu; varsayılana döndürünce yeni notlar da varsayılan.

### Tablet turu sonucu (2026-11-09, kullanıcı) — GEÇTİ
Tam yedek geri yükleme + ikinci yükleme çoğaltmıyor; #47 Gboard; A2, A4, B5–B7, B13, C17, D18–D20, E, F, #6 bildirim. Yazım düzeltme (C3/D1/D2) kapatıldı ("zamanla anlaşılacak").

### I1–I10 (2026-11-09 oturum H — yazıldı, cihazda doğrulanmadı)
- I1 Not paketinde × (hapın sağı / açık paketin ilk maddesi) paketi çözüyor mu. **Kasma:** paketli notta tam olarak ne zaman kasıyor (açarken, yazarken, kapatırken)? Kod ölçümünde üretilemedi. **Kök (F60.2, 2026-11-10):** açık paketin `TapRegion` grubu yalnız paket satırlarıydı → Biçim/alt çubuk/hızlı satıra dokunmak paketi KAPATIYORDU (S10 testiyle üretildi); paketle/çözde `_rowCache.clear()` görünen bütün satırları (30 maddede 19–20) sıfırdan kuruyordu. İkisi de düzeltildi; cihazda 30 maddeli paketli notta aç → yaz → kalın yap → kapat akışı denenmedi.
- I2 Kalem görülen cihazda sağda küçük yuvarlak düğme: dokun → "Kalem dokunur": kalemle metne imleç konuyor, kaydırıyor; tekrar → "Kalem yazar". Sürükle → yeri kalıyor (uygulamayı kapat-aç).
- I3 "Kalem yazar"da sabit PDF'e kalemle yazılıyor, parmak kaydırıyor; gömülü PDF'e yazınca çizgi PDF'te (sayfaya değil).
- I4 Tablette not açıkken klavye açılınca soldaki ev/klasör/mikrofon/+ yukarı çıkmıyor (ekran görüntüsündeki karmaşa).
- I5 Fiziksel klavyede Esc: tam ekran → not kapanır. Tablette not açıkken listeden başka nota geç → geri → doğrudan liste (önceki not değil).
- I6 Şekil: 20° eğik kare/üçgen düz oturuyor; X tek çizgide ve iki çizgide; seçili şeklin üstündeki yuvarlak tutamakla döndür; eski bir şekle kalemle ÇİFT dokun → seçilir, taşı/boyutla/döndür.
- I7 Süzgeç/arama açıkken ya da "Son güncellenen" sırasında karta basılı tut → dolum halkası çıkıyor.
- I8 Aramadan nota girince sayfa açıldıktan SONRA kelimeye kayarak gidiyor.
- I9 Yeni sürüm çıkınca bildirimde/Ayarlar → Hakkında'da "Güncelle" → indirme çubuğu → (ilk seferde izin ekranı) → sistemin güncelle penceresi.
- I10 Tablet/web: sabit ekin çubuğunda sol baştaki yerleşim düğmesi → solda → sağda → üstte; aradaki ayraçla genişlik; web'de PDF ekle (olmazsa ekrandaki hata metnini yaz — Storage/Drive).
- Açık hata (yeniden üretilemedi): PDF bölmesinde sayfa "Not al" → sabitten gömülüye geçince "📖 s.11" satırı silinemiyor — tam adım/ekran görüntüsü gerekli.

### J1–J9 (2026-11-09 oturum J — yazıldı, cihazda doğrulanmadı)
- J0 **ÖNCE SEN (konsol):** Google Cloud Console → notlar-kaimau → API'ler ve Hizmetler → Kimlik bilgileri → "Kimlik bilgisi oluştur" → OAuth istemci kimliği → tür **Masaüstü uygulaması** → kimlik + sırrı GitHub → Settings → Secrets → Actions'a `GOOGLE_DESKTOP_CLIENT_ID` / `GOOGLE_DESKTOP_CLIENT_SECRET` olarak ekle (yerel derleme için `env.json`). Eklenmezse tablet eski Firebase akışında kalır (hata sürer).
- J1 Tablet (GMS'siz): Ayarlar → Google ile giriş → tarayıcıda onay → "Tamam — Not uygulamasına dönebilirsin" → uygulamaya dön, girişli; notlar telefonla senkron. Drive "Bağla" ve Gmail aynı şekilde; 1 saat sonra yeniden "Bağla" İSTEMEMELİ.
- J2 Tablet: Drive ve Gmail'e art arda bas → "headful operation" hatası yok (ikincisi birinciyi bekler).
- J3 Fiziksel klavyeyle yaz → kaleme geç → bir süre bekle → parmakla metne dokun: sanal klavye AÇILMAMALI; başka maddeye geçince de.
- J4 Hızlı satır (klavye açıkken üstte): kalem · yazım · paket · ekle · kalın · renk; telefonda kaydırmadan sığıyor mu. Renk: dokun → kırmızı; basılı tut → renk seç → o renk uygulanır ve bundan sonra dokununca o gelir. ⚙ ile eski düğmeler (madde imi, başlık, fotoğraf…) eklenebiliyor.
- J5 Kalem kipini her açışta altta "Yalnız kalemle yaz: AÇIK/KAPALI" + "Ayarla" → kalem ayarları açılıyor. Kalem kipi açılınca yüzen kalem "kalem yazar"a geçiyor; yüzen kalemi "yazar"a alınca kalem kipi açılıyor.
- J6 Kalem kapsülünde renk/kalınlık kartı açıkken sayfaya/metne dokun → kart kapanıyor.
- J7 Ana ekranda sol altta klasör düğmesi yok (klasörler: listede aşağı çek).
- J8 Tablette not açıkken liste ile not arasındaki tutamağı parmakla sürükle → genişledikçe 2, sonra 3 sütun.
- J9 Nottan Telegram'a kopyala → Telegram'dan nota yapıştır → maddeler "☐ " olmadan, ☑ olanlar işaretli geliyor; tekrar kopyalayınca "☐ ☐" yok. Otomatik düzeltme harflerin çoğunu değiştiren öneri UYGULAMIYOR; yanlış düzeltmenin üstüne başka kelime yazınca bir dahaki sefere o kelime geliyor.

### K1–K4 (2026-11-12 P39 hız hissi — yazıldı, cihazda doğrulanmadı)
- K1 **Açılış (F78.1, K-D8):** uygulamayı tamamen kapat → aç: beyaz ekran yerine zemin renginde simgeli açılış, sonra ana ekran. Ölçüm: `adb shell screenrecord` + `tool/perf/video.py` ile beyaz kare sayısı (önce/sonra). Beyaz kare kalıyorsa F78.1 commit'i geri alınır. Güncelleme sonrası açılış ve "Notlar Ölçüm" kimliği de denenir; açılış ekranında 3 sn'den uzun takılma olmamalı.
- K2 **Yeni not süresi (F78.2):** `cd tool/perf && python -u prof_new.py taban` → ortanca ≤ 450 ms mi; sayı DENEYIM_PLANI F78.2'ye yazılır.
- K3 **Sabit/gömülü PDF (F78.3b):** PDF'li notu aç: belge açılırken açık gri kutu + halka yerine belgenin küçük resmi (hafif karartılmış), sonra belge. Bölme boyu oynamıyor. A/B: `python -u prof_oc.py pdf <x> <y>` (sabit PDF'li not) — AÇILIŞ kareleri tabandan kötü olmamalı.
- K4 **A/B kapısı:** `tool/perf/ab_liste.py` ve `ab_klavye.py` — UI ms / LAYOUT ms +%20'yi aşmamalı.

### L1–L3 (2026-11-13 bulut — F79.6 çevrimdışı hâller; yazıldı, cihazda doğrulanmadı)
- L1 Uçak kipini aç → ana ekranda "Gelen" süzgecini seç (Gelen'i daha önce hiç açmamış taze kurulumda): "burada not yok" DEĞİL, "Bağlantı yok" + Tekrar dene. Uçak kipini kapat → Tekrar dene → liste gelir.
- L2 Uçak kipi → notta ✨ AI levhası: üstte "Bağlantı yok" kartı, araçlar soluk ve dokunulmuyor. Uçak kipini kapat → kart kalkar, araçlar açılır (levhayı kapatıp açmadan).
- L3 Uçak kipinde nota fotoğraf ekle → ana ekrandaki şerit "1 ek bekliyor — bağlantı gelince yüklenecek" (bulut-üstü-çizili simge, kırmızı değil). Bağlantı gelince "yükleniyor", sonra şerit kaybolur.
- L4 Notta birkaç maddeye noktalı, kesikli ve dalgalı "Alt çizgi" ver → bir maddeye dokun, klavye açılsın: takılma yok; çizgiler eskisi gibi görünüyor (noktalar yuvarlak, dalga aynı genlikte). Düz çizgide hâlâ takılıyorsa P55'e not et.
- L5 **Alt çubuk (P57):** Ayarlar → Kişiselleştir → "Not ekranı · alt çubuk": "Geri al" ve "Hatırlatıcı"yı aç, "Ara"yı tutamaçtan en üste sürükle → nota gir: çubukta Ara en solda, geri al ve hatırlatıcı var, çalışıyorlar. 360 dp'lik dar ekranda çok düğme açınca çubuk taşmıyor (önce küçülür, sonra kayar). "Alt çubuğu varsayılana döndür" → eski düzen.
- L6 **Klasörde çöpe sürükle (P58):** bir klasör seç → notu basılı tut, sürükle: altta çöp belirir, üstüne bırak → not silinir, "Geri al" çıkar. Sürüklerken diğer kartlar yer değiştirmez. Oynatmadan bırakınca not seçilir. Başkasının paylaştığı klasörde sürükleme yok.

## 3. Açık kararlar / bilinen sınırlar → `KALAN_ISLER_PLANI.md` (F18.2–F18.5, F18.11, F18.13, F18.27, "Bilinen sınırlar")

- [ ] Web'de tarayıcının geri tuşu tam ekranda önce tam ekrandan çıkmıyor (go_router popstate PopScope'a uğramıyor); Esc/☰/Android geri çıkarıyor (2026-11-02)
- [ ] Web debug konsolunda "+" düğmesinin ipucunda `RenderFollowerLayer` uyarısı (yalnız debug assert) — kaynağı araştırılmadı (2026-11-02)

## 4. Sonra yapılacak → `KALAN_ISLER_PLANI.md` (F18.17–F18.20, F18.22)

- [ ] **Akıcılık Faz 20–27** → `AKICILIK_PLANI.md` (telefonda ölçülmüş kök nedenler; önerilen sıra 20 → 27, KARAR maddeleri F22.2–F22.4, F24.2, F25.1, F26.2) (2026-11-03)
- [ ] **Faz 21 kabulü sağlanmadı** (2 tur sonra kaydırma %3,4–4,2 / 33–50 ms, arama 139 ms): kalan engel raster+kart kurulumu birlikte (Faz 23.4/26) ve arama için KARAR (önbellek payı ya da vurgu katmanı) — `AKICILIK_PLANI.md` Faz 21 notu (2026-11-03)

## Yarım kalan
- [ ] Not içi hatırlatıcı/görev çipi şimdilik yalnız LİSTE maddelerinde; düz metin satırında çip yok (satır kimliği yok, pencereli gövdeye satır içi çip pahalı) — tasarım TAKVIM_PLANI §10 (2026-11-08)
- [x] Ana ekran şeridinden satır görevine dokununca o satıra kaydırılıyor (`?item=`, 2026-11-09)
- [ ] Kalem şekil önerisi yalnız `InkController` çizimlerinde (sayfa üstü, PDF/slayt, görsel, ayrı çizim); madde jest katmanı (`InkGestureLayer`) kendi ✓ jestini kullanıyor (2026-11-08)
- [ ] Görev levhasında kişi alanı serbest metin; rehberden seçme ve Gmail iletisini uygulama içinde açma yok (2026-11-08)
- [ ] Tablette elle kontrol (v801 kurulu): kalemle yazarken avuç, kalemle tek tık kutucuk/metne gidiyor mu, yeni kalem kapsülü, not üst çubuğunda ⌨ düğmesi — klavye algılama doğrulandı, gerisi kullanım sınırı yüzünden yarım (2026-11-07)
- [x] `tablet-kalem-klavye` dalı main'de (2026-11-09'da doğrulandı)
