# KUYRUK_AYRINTI — Kuyruk satırlarının tam metni

OTOMASYON.md Kuyruk satırları kısa özettir; asıl kapsam, KORU çitleri ve kullanıcı istekleri burada, AYNEN. Alt ajana paketin satırı + bu dosyadaki `## P..` bölümü verilir.


## P43 — Hız: tek komutla tam ölçüm + otomatik karar + altın taban + cihazsız bekçiler (P44 katıldı, tek ajan)

Model: opus · Cihaz: cihaz · APK: -

**Plan maddeleri:** HIZ_PLANI F81.1–F81.5 + F82.1–F82.3

**Durum (2026-11-13):** F82 main'de; F81 aracı + ilk tam A/B + altın taban dalda (`oto/P43-hiz-olcum`); **F81 kabulü KALDI** (aynı APK A=A'da `yaz` LAYOUT yanlış alarm, altına karşı +%22–40 sıcaklık kayması — HIZ_PLANI F81 Durum, sabah bakılacak); 2. tur (sabah): eşik %20 + < 34 °C + 6 koşulu altın → A/B A=A 2/2 GEÇTİ, altına karşı `yaz` LAYOUT +%16 → hâlâ KALDI (HIZ_PLANI F81 Durum 2); F68.4 ölçüldü: liste > 16 ms %2,3–3,3, hedef %2 tutmadı → P46. Eski durum: önce F82 (cihazsız bekçiler S18–S25, kasma kalıpları, uzun oturum), sonra F81 (cihazda ölçüm + altın taban); senaryolara "sabit görsel/PDF + klavye aç/kapa" evresi de girer (kullanıcı 2026-11-12; düzeltmesi P49'da — sabit ek dosyasına tek paket dokunsun); OTURTMA F68.4 kaydırma kabulü ölçümü (`ab_liste.py`) de burada (P22'den alındı)

## P45 — Hız: her [apk]'da ölçüm + geçmiş + CI kare ölçümü kararı

Model: sonnet · Cihaz: cihaz · APK: -

**Plan maddeleri:** HIZ_PLANI F83.1–F83.3

**Durum:** bekliyor

## P46 — Hız: ölçümün bulduğu yavaşlıkları düzelt

Model: fable (limit %55 üstü → opus) · Cihaz: A/B · APK: evet

**Plan maddeleri:** HIZ_PLANI F84.1–F84.3 + OTURTMA F60.S2, F60.5, F68.3 (P22'den alındı: klavye birikim kasması, yazma ana bloğu, liste akışı K-O13)

**Durum:** bekliyor — `pinned_media_pane.dart`'a DOKUNMAZ: sabit ek + klavye kasması P49'da (aynı dosya iki kez değişmesin); ölçüm sabit ekte yavaşlık bulursa bulguyu P49 satırına yaz

**P43 cihaz ölçüm bulguları (2026-11-13, `ab_hepsi.py`, A=9c837495 B=P39 02ebd989, 3'er koşu, ortanca; gürültü ±%15):** P39'da `klasor` LAYOUT 82→108 ms (+%33, aynı APK tekrarında 87 — gerçek olabilir), `menu` LAYOUT 44→50, `sabit_kay` UI 877→967 ms (sabit ek → P49). En ağırlar: `sabit_kb` 2,3–2,5 sn UI/4 klavye geçişi (373 kare; sabit ek → P49), `liste` 1,24–1,37 sn/8 fırlatma, > 16 ms %2,3–3,3 (F68.4), `arama` en uzun kare 62–82 ms, `not_ac` en uzun 61–89 ms, ilk kare 378–413 ms.

**P43 cihazsız bekçi bulguları (2026-11-12, mandallı, düzeltilmedi — düzeltince ilgili mandalı düşür):**
1. S21 arama: harf başına 114 `NoteCard` kuruluyor (görünür 18 — 6 katı).
2. S25 `note_card_media.dart` `_image` `thumbUrl` dalında `memCacheWidth` yok → Drive küçük resmi tam boy çözülüyor (21 kart).
3. S22 takvim hafta fırlatma tek karede ~980 kurulum.
4. S23 süzgeç kaydırma en ağır kare 2941 kurulum.
5. Kasma listesi md. 6: editör kökünde gövdeyle aynı Column'da 3 `AnimatedSize` (ses hapı, biçim paneli, alt çubuk takası — `jank_patterns_guard_test` mandalı 4).
6. S18 not açma geçişinde ikinci kare 788 kurulum (editör iki karede kuruluyor).

## P48 — Web yazı seçimi + takvim senkronu (tek ajan)

Model: opus · Cihaz: cihaz (b) · APK: evet

**Plan maddeleri:** kullanıcı 2026-11-12: (a) "webte yazı seçerken sorunlar var, yazı tipiyle alakalı olabilir"; (b) "telefonda eklediğim takvim etkinlikleri tablette görülmüyor, tablette eklediklerim telefonda görülüyor; webde de aynı"

**Durum:** bitti — dal `oto/P48-web-takvim` CI yeşil (2026-11-13), cihazda doğrulanmadı (telefonda Google Takvim bağlı mı bakılacak). İlk CI kırmızısı: işaretçi takibi `addGlobalRoute` editör sızıntı bekçisinde (`editor_leak_test` globalRoutes 1→2) — uygulama ömürlü tek yol, test tabanı `trackSelectionPointerKind()` sonrası alınır. (a) KÖK NEDEN `lib/core/utils/sentence_select.dart` cümle genişletici: seçimin kaynağına bakmıyordu — webde fareyle kelimeye çift tıklama bütün cümleyi, shift+ok ile 3 harf bütün kelimeyi (token) seçiyordu (yerel `build web --wasm`, misafir kipte üretildi; düz arama alanında çift tıklama doğru). Genişletme artık fare/izleme dörtgeni ve shift basılıyken yapılmaz (`_mouseOrKeyboardSelection`); kanıt `test/sentence_select_test.dart` "fare ve klavye seçimi" kırmızı→yeşil + webde yeniden denendi. Yazı tipi değil. (b) KÖK NEDEN `event_editor.dart` `_toGoogle`: Google Takvim bağlantısı cihaza özgü (`gcal_cache_<uid>` SharedPreferences); bağlı telefonda yeni etkinlik varsayılan Google'a gidiyor, Google'ı bağlamamış tablet/web görmüyordu; "Bu cihaz" etiketi tersini söylüyordu. Varsayılan artık Firestore ("Tüm cihazlar"); kanıt `test/calendar_screen_test.dart` "Google bağlıyken de…" kırmızı→yeşil. **K2 sapması — sabah bakılacak.** Cihazda: telefonda Google Takvim bağlı mı. (c) üretilemedi: web oturumu kullanıcının hesabıyla açılamadı; Firestore REST (salt okuma) ana hesapta: video ekleri hiç yüklenmiyor (tasarım, `skipsUpload`), 3 PDF + 1 görsel yalnız Drive'da önizlemesiz (web Drive bağlanmadan yalnız "Drive'da" kutusu çizer), 1 PDF hiç yüklenmemiş (başka hesapta). Kullanıcının snackbar metni gerekli (F65.6).

## P49 — Sabit ek baştan: tasarım, tuşlar, özellikler

Model: fable (limit %55 üstü → opus) · Cihaz: A/B · APK: evet

**Plan maddeleri:** kullanıcı 2026-11-12: "sabit ek tasarımı, tuşları, özellikleri fable baştan yazdır"

**Durum:** bekliyor — BAŞTAN TASARIM (yama değil): önce mevcut sabit ek çubuğu/bölmesinin bütün düğmelerini ve özelliklerini (görsel, PDF, video, ses, balon, kalem, yerleşim üst/sol/sağ, sığdır, tam ekran) dök, DENEYIM §2 diliyle yeni düzen öner ve uygula. Kesin istekler: (a) ⋮ ile "sayfalara göz at" menüleri TEK ⋮ menüde; kart düğmesi bizim stilde, yer açılır; (b) yüzen kalem düğmesi ↔ paneldeki kalem TAM senkron (yüzenden açınca paneldeki kayboluyor, panelden açınca yüzen bilmiyor); (c) paneldeki kalem açılınca silgili hızlı kalem menüsü; (d) "kalem yazar, parmak dokunur" gibi ipuçları alt kalem panelini KAPATMASIN, sürekli çıkmasın. (e) SABİT EK + KLAVYE KASMASI (kullanıcı 2026-11-12: "sabit ek varken klavye açılırken hem sabit ek paneli hem klavye kasıyor"; P46'dan alındı, senaryo P43'te): yeni tasarım kasma listesi §6–§7'ye uysun, A/B'de bu evre ölçülsün. (f) P22'den alınanlar (hepsi sabit ek): OTURTMA F65.1 bölme çubuğu sadeleşmesi (K-O6 — bu paketle açıldı), F65.2/F67.5 yatayda yandan sabitleme varsayılanı (K-O7), F65.3 birden çok sabit ek (K-O8); K-O7/K-O8 için en güvenli seçenek + "sabah bakılacak". (g) P42 kalanı: sabit PDF çubuğu 1,3× yazıda ve 360/393 dp'de taşıyor. KORU: P47 ("T" kalktı, balon gizle/göster balon menüsünde, `kPinnedSideMinWidth` 560), P39 F78.3(b) bölmenin içindeki yükleme hâli. `pinned_media_pane.dart`, `ViewerPen`, P15. Önce `istek_tara.py`

**P43 bulgusu (2026-11-12):** S17 sabit görsel/PDF klavye hareket karelerinde sabit bölme diziliyor (görsel 2, PDF 3 sınır: `_RenderLayoutBuilder`, `RenderCustomMultiChildLayoutBox`), editör içi 12/11 (metin 7) — `budgets.json` S17 `sabit_*` mandalları; yeni tasarım bunları düşürsün.

## P50 — Düzenleme modu baştan: her şey düzenlenebilsin + hızlı menü

Model: fable (limit %55 üstü → opus) · Cihaz: - · APK: evet

**Plan maddeleri:** kullanıcı 2026-11-12: "düzenleme modunu fable yaptır her şey düzenlenebilsin"; "hızlı menü ve hızlı menüyü düzenle üzerine çalışılmalı, şu an normal düzenleme modunu açıyor"

**Durum:** bekliyor — (a) düzenleme modu (Ekranı/Menüyü düzenle, `customizable.dart`, `UiItem`): ekranda görünen HER düğme/alan gizle/göster/sırala (eksik `Customizable` sarmalarını dök, tamamla); (b) "Hızlı menüyü düzenle" genel düzenleme modunu değil hızlı menünün kendi düzen kipini açsın (P28 "+" paneli düzen kipiyle birleşik dil). Kasma listesi §3–§4: düzen kipi kök `setState` değil, ağaç şekli değişmesin. P49'DAN SONRA: sabit ek çubuğunun `Customizable` sarmalarını P49 yapar, P50 `pinned_media_pane.dart`'a dokunmaz; editör `note_editor_screen.dart` yapısı P20'nin (P50 yalnız sarmalar)

## P38 — Hareket ve dokunsal dil

Model: opus · Cihaz: A/B · APK: evet

**Plan maddeleri:** DENEYIM F77.1–F77.4

**Durum:** bekliyor — P47 çöp sürüklemesindeki `HapticFeedback` ve sıra donması (`_previewCardDrop`) korunur, yalnız `AppHaptics`e sarılır

## P20 — Editör çekirdeği (başlama şartı tutuyorsa)

Model: fable · Cihaz: A/B · APK: evet

**Plan maddeleri:** Faz 64

**Durum:** bekliyor — P49 (sabit ek) ve P50 (düzenleme modu) BİTTİKTEN sonra; onların editördeki bloklarını AYNEN taşır

## P41 — Belirteç göçü

Model: sonnet · Cihaz: - · APK: -

**Plan maddeleri:** DENEYIM F72.6

**Durum:** bekliyor — P22'den önce, açık dal yokken (mekanik; editör klasörü hariç). Kapanış toparlaması P53'e taşındı (2026-11-12)

## P22 — SON PAKET: açıkta kalan her maddeyi değerlendir ve uygun biçimde yap

Model: opus · Cihaz: gerekirse · APK: gerekirse

**Plan maddeleri:** Kalan açık `[ ]` maddeler (2026-11-12 ayıklandı): kalem/mürekkep F61.7, F61.8, F62.4, F62.6, F63.6, F63.7 · tablet F67.6, F67.8 · F66.5 (yalnız rapor) · F68.5 (park) · cihaz turu F69.1–F69.3 · P40'ın "sabah bakılacak"ları (Gelen süzgeci hata hâli, AI levhası çevrimdışı, bekleyen ek şeridi). BAŞKA PAKETE TAŞINDI, burada YAPILMAZ: F58.1/F58.4 → P53, F60.5/F60.S2/F68.3 → P46, F68.4 → P43, F65.1/F65.2/F65.3/F67.5 → P49, F65.6 → P48; F60.7, F66.1–3 zaten kapandı (Ek D) + "cihazda doğrulanmadı" / "tablette doğrulanmadı" işaretli maddeler + açık K-O kararları

**Durum:** bekliyor — protokol aşağıda

## P53 — BÜYÜK TOPARLAMA: tek plan, tek kontrol listesi

Model: opus · Cihaz: - · APK: -

**Plan maddeleri:** kullanıcı 2026-11-12: "bitmişleri sil, eski planları tamamen toparla, tek plana indir, kafa karışıklığı olmasın; benim kontrol etmem gerekenleri madde madde, anlayacağım şekilde bir dosyaya yaz; diğerlerini grupla, kaldır; HAFIZA, CLAUDE.md dahil toparla, main'e gönder" + F69.4, F69.5 (eski P21) + OTURTMA F58.1, F58.4

**Durum:** bekliyor — EN SON (P22'den sonra). Protokol aşağıda (P53 protokolü)

## Protokoller ve paket grubu kuralları (OTOMASYON.md'den taşındı, AYNEN)

**P22 protokolü (kullanıcı isteği 2026-11-10):** P01–P21 bitince `OTURTMA_PLANI.md`'yi baştan tara; `[ ]` kalan HER maddeyi otomatik değerlendir, soru sorma. Her madde için sırayla: (1) kanıtla — kod/test/ölçümle hâlâ geçerli mi, başka işle kapanmış mı; (2) kapanmışsa `[x]` + tek satır kanıt, gereksizse `[~]` + neden; (3) geçerliyse kendi modeli neyse ona uygun işle: kısa maddeleri kendin yap, Fable gerektirenleri (güvenlik/performans/editör/kalem) `Agent` ile `model: "fable"` alt ajana ver, mekanik olanları `sonnet` alt ajana; (4) KARAR çıkarsa plandaki "En güvenli" seçenek + maddeye "sabah bakılacak"; (5) telefon/tablet/hesap gerektirenler yapılamaz → "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım. Kullanıcı işi olanları (konsol, hesap, telefon) yapma, yalnız `KALANLAR.md`'ye topla. Küçük commit'ler, CI yeşilse `[apk]`; sonunda plan Durum tablosu + HAFIZA güncelle ve geriye kalanın dürüst listesini yaz.

**P53 protokolü (kullanıcı isteği 2026-11-12):** bütün P'ler (P22 dahil) bitince, EN SON. Kod yazmaz, yalnız belge toparlar; veri/kanıt kaybetmez (silinen her şey git geçmişinde ve arşivde kalır). Sırayla:
1. **Tek plan — `PLAN.md`:** bütün plan dosyalarını (`OTURTMA_PLANI`, `DENEYIM_PLANI`, `HIZ_PLANI`, `KALAN_ISLER_PLANI`, `KUYRUK_AYRINTI.md` (P53 bitince yalnız protokol/kural bölümleri `docs/hafiza/`'ya, açık satır ayrıntıları PLAN.md'ye girer; dosya sonra arşive), `YOL_HARITASI`, `PERFORMANS_TOPARLAMA_PLANI`, `KULLANICI_DENEYIMI_PLANI`, `AKICILIK_PLANI`, `TEMA_PLANI`, `TUTARLILIK_PLANI`, `TAKVIM_PLANI`, `YORUM_ANALIZI_PLANI`, `KALEM_PLANI`, `KALANLAR.md`) madde madde tara. `[x]` bitmişler PLAN'a GİRMEZ. Açık kalan her madde PLAN.md'de tek satır, üç gruptan birinde: **(A) Senin yapacakların** (aşağıdaki listeye işaret), **(B) Bekletilenler / park** (neden + hangi kararla), **(C) Açık kod işi** (varsa; model + kısa kapsam). Her satırın sonunda eski kimliği (ör. `F65.6`) dursun ki geçmişe bakılabilsin.
2. **Senin kontrol listen — `KONTROL_LISTEM.md`:** kullanıcının yapması/bakması gereken HER şey, madde madde, sade Türkçe, teknik terim ve dosya adı olmadan. Her madde: ne (bir cümle) · nerede (uygulamada hangi ekran / hangi konsol sayfası) · nasıl (2–4 adım) · doğruysa ne görmeli · yanlışsa ne yapmalı (ör. "ekran görüntüsü alıp bana gönder"). Gruplar: **Telefonda bak** · **Tablette bak** · **Bilgisayarda (web) bak** · **Konsol/hesap işleri** (Firebase, Google Cloud, GitHub). "Cihazda doğrulanmadı / tablette doğrulanmadı / sabah bakılacak" işaretli bütün maddeler ve açık KARAR'lar buraya (karar maddesinde: seçenekler, şu an uygulanan "en güvenli" seçenek, değiştirmek isterse ne demeli). Kutucuklu (`- [ ]`), en önemlisi üstte; 40 maddeyi geçerse benzerlerini birleştir.
3. **Eski planları kaldır:** yukarıdaki plan dosyalarını `docs/arsiv/planlar/`'a TAŞI (`git mv`, silme). Önce `test/`, `tool/`, `.github/` içinde bu dosya adlarını okuyanları bul (2026-11-12'de: `test/color_roles_test.dart`, `test/design_components_test.dart`, `test/design_tokens_guard_test.dart`, `test/perf_budget/budgets.json`, `tool/design/istek_tara.py`, `tool/design/token_sayim.py`) ve yollarını güncelle — test kırmızıya dönmesin. DENEYIM §2 tasarım sözleşmesi ve §4 "çelişen fikirler" listesi, HIZ hız sözleşmesi gibi KALICI KURALLAR arşive gitmesin: `docs/hafiza/` ilgili konu dosyasına (arayuz, akicilik) taşı.
4. **OTOMASYON.md:** Kuyruk'ta yalnız açık satırlar kalsın; bitmiş P satırları tek satırlık "Biten paketler: P01–P53 (ayrıntı git geçmişinde ve `docs/arsiv/`)" ile değişsin. Yürütme kuralları aynen kalır.
5. **CLAUDE.md:** "Yol haritası" bölümündeki 12 plan maddesi TEK satıra iner: "Açık iş: `PLAN.md`; kullanıcının kontrol listesi: `KONTROL_LISTEM.md`; eski planlar `docs/arsiv/planlar/` (yalnız geçmiş)". F58.1 (dondurma kuralı) ve F58.4 (oturum disiplini) burada eklenir. Kasma kontrol listesi ve ölçüm kapısı gibi geçerli kurallar AYNEN kalır; tarihi geçmiş açıklamaları kısalt.
6. **HAFIZA:** `HAFIZA.md` ve `docs/hafiza/*.md`'de bayatlamış kural (artık olmayan dosya/plan adı, değişmiş eşik) düzelt; tarihçe `HAFIZA_ARSIV_*` dondurulmuş kalır. `test/hafiza_size_test.dart` yeşil kalsın.
7. **F69.4 konsol listesi, F69.5:** KONTROL_LISTEM'in "Konsol/hesap" grubuna gir.
8. Dalda çalış, CI yeşil → main'e birleştir (kod değişmediyse `[apk]` YOK). Kullanıcıya son mesaj: KONTROL_LISTEM.md'nin yolu + kaç madde + ilk 3 madde.

**P33–P42 = `DENEYIM_PLANI.md` (kullanıcı isteği 2026-11-12: "görünen ve hissedilen her
şeyi mükemmelleştir; tasarım Fable'da" + "diğer fazlarla zıt olmasın, aynı yerde tekrar
tekrar çalışmayalım").** Bu paketlerin maddeleri, protokolü ve "Önce oku" listeleri O
dosyadadır (işçiye `OTURTMA_PLANI.md` yerine onu okut). Kurallar: (1) oradaki **K-D
kararları VERİLMİŞTİR** — "en güvenli"ye düşme; her K-D tek başına geri alınabilir tek
commit. (2) **Önce eski isteğe bak:** görünüş/yer değiştirmeden önce `python
tool/design/istek_tara.py <dosya>`; çelişen iş YAPILMAZ (plan §4'teki 16 fikir dahil).
(3) **Kapsam çiti = plan Ek D:** her paket yalnız orada adına yazılı dosyalara dokunur.
(4) **Sıra (kullanıcı kararı 2026-11-12: "Fable işleri limit ilk açıldığında ilk yapılsın"):**
FABLE ÖNCE — P36 → P39 → P49 → P50 → P20, sonra Opus/Sonnet: P37 → P38 → P40 → P48 → P42 → P41 → P22 → P53 (EN SON).
**HIZ (kullanıcı kararı 2026-11-12):** P39 → P43 (P44 katıldı) → P45 → P46 her şeyden önce (plan `HIZ_PLANI.md`; işçiye onu okut).
Fable paketi yalnız 5 saatlik limit taze/düşükken (%55 altı) başlar; %55 üstündeyse sıradaki
Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince (resetsAt sonrası
ilk tur) EN BAŞTA alınır. P20 başlama şartı tutmuyorsa atla; tek şart P33 bitmiş olsun. P41 yalnız Kuyruk'ta `sürüyor`
/ `bulutta:` satırı yokken. (5) Her paket işe başlamadan ekran turunu `build/tour-once/`'ye
alır, bitince `TOUR_COMPARE` ile karşılaştırır; yürütücü kabulde adı geçen PNG'lere kendi
bakar. (6) **P22 ATLAR** (bu planla kapandı ya da taşındı): K-O5, K-O10, K-O11, K-O14,
F60.7, F63.5, F66.1, F66.2, F66.3, F66.4, F66.6, F67.7. **K-O6 / F65.1: kullanıcı 2026-11-12 P49 ile açtı ("sabit ek tasarımı, tuşları, özellikleri baştan")**
(yalnız P49 yapar, P22 dokunmaz). (7) HAFIZA/CLAUDE/KALANLAR/plan toparlaması yalnız P53'te (tek kapanış; eski P21).

Atlananlar (kullanıcı kararı bekliyor, gözetimsiz yapılmaz): K-O1, K-O3 (v2 yazımını açma),
K-O4, K-O6, K-O7, K-O8, K-O10, K-O11, K-O12, K-O14, F63.6, F65.6 (kullanıcıdan hata metni),
F69.1–F69.3 (elle cihaz turu).
