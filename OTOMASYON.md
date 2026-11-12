# OTOMASYON — gözetimsiz iş zinciri

**Kullanıcı izni (2026-11-09):** "Otomasyon olarak işleri başlat. Yeni oturum açma izni
veriyorum, istediğin modelde. Kullanım limitine göre çalış. Bilgisayar açık; test telefonu
USB hata ayıklamada bağlı, şifresi yok, kaydırarak açılıyor, ekranı bozuk — ekranı yalnız
gerekince aç. İşi bitir, main'e gönder. Token israf etme ama işi savsaklama; bitmiş iş
istiyorum."

Plan: `OTURTMA_PLANI.md`. Bu dosya yalnız YÜRÜTME düzenidir. Her tur bu dosyayı baştan okur.

## Nasıl çalışır

- Zamanlanmış görev `not-oturtma-zinciri` her saat :55'te bu depoda bir oturum başlatır.
  5 saatlik limit dolunca oturum ölür; limit yenilenince sonraki tetik
  **kaldığı yerden** sürer. Durum bu dosyanın sonundaki Kuyruk tablosundadır.
- Zamanlanmış oturum YENİ OTURUM AÇAMAZ (ölçüldü 2026-11-05). Başka model gereken paket
  `Agent` aracıyla ALT AJANA verilir: `model: "fable" | "opus" | "sonnet"`,
  `isolation: "worktree"`, istem = aşağıdaki "İşçi kuralları" + paketin satırı. `Agent`
  reddedilirse ya da o model yoksa paket BU oturumda yapılır; Kuyruk'a gerçek model yazılır.
- Oturumun kendisi ince kalır: kod işini alt ajan yapar; yürütücü doğrular, birleştirir,
  ölçer. (Yürütücünün bağlamı şişerse kalan paketler pahalılaşır.)
- Aynı anda TEK yürütücü. Kilit: `.git/oto.lock` (içinde ISO zaman; `.git` içinde olduğu
  için commit'lenmez).

## Bir turun adımları

0. **Kilit.** `.git/oto.lock` varsa ve son değişimi 40 dakikadan yeniyse: hiçbir şey
   yapmadan "başka yürütücü çalışıyor" de ve BİTİR. Değilse kilidi şimdi yaz. Aşağıdaki
   her adımın başında kilidi tazele. Tur nasıl biterse bitsin kilidi sil.
   **Kilidi arka plan döngüsüyle TAZELEME** (`while …; do date > .git/oto.lock; sleep …; done`
   YASAK): oturum limitte ölünce döngü yaşar, kilit sonsuza dek taze kalır. 2026-11-11 23:51'de
   açılan döngü 2026-11-12 09:47'ye dek kilidi tuttu; 02:02–09:02 arası 8 devam turu "başka
   yürütücü çalışıyor" deyip boşa kapandı. Tazeleme yalnız adım başındaki tek `date >` satırıdır;
   40 dakikadan uzun süren adımda (alt ajan bekleme) bildirim geldiğinde tazele.
1. **Depo.** `git status` temiz olmalı (değilse: `git stash -u` + Kuyruk notuna yaz),
   `git checkout main && git pull --ff-only`.
2. **main sağlığı.** `gh run list -b main -L 3` (yoksa GitHub MCP `actions_list`). Son
   BİTEN koşu kırmızıysa bu turun işi onu düzeltmektir (yalnız kırmızı işin kaydının
   kuyruğunu oku). `[apk]` koşusu SÜRÜYORSA bitene dek main'e push YOK (iptal eder) —
   bu sırada dalda çalışılır.
3. **Paketi seç.** Durumu `bulutta:` ile başlayan satır başka (bulut) oturumundur: ATLA,
   dalına dokunma; yalnız Cihaz = `A/B` ve "cihaz bekliyor" olunca ölçümü sen yaparsın.
   Kuyruk'ta ilk `sürüyor` (yarım kalmış: dalı `oto/<no>` uzakta varsa
   oradan sür) yoksa ilk `bekliyor`. Satırı `sürüyor` yap (yalnız yerelde; ayrıca push yok).
4. **Yaptır.** Alt ajanı başlat (yukarıdaki gibi). Bitince raporunu OKU ama güvenme:
   `git log oto/<no>`, diff özeti ve test çıktısına kendin bak.
5. **Doğrula.** Dal push'lu olmalı. CI: `gh run list -b oto/<no> -L 1` → sürüyorsa
   `gh run watch <id> --exit-status` (arka planda; yoklama döngüsü kurma). Kırmızıysa
   alt ajana YALNIZ kırmızı işin kayıt kuyruğuyla geri ver (en çok 2 tur; sonra `takıldı`).
6. **Cihaz kapısı** (Kuyruk'ta Cihaz = `A/B`): CLAUDE.md ÖLÇÜM KAPISI. Taban = son `[apk]`
   commit'i (`git worktree add ../not_ab <commit>` → profil derlemesi). Telefon kuralları
   aşağıda. **Ölçümü yürütücü KENDİ yapmaz (kullanıcı kararı 2026-11-10):** derlemeler
   bitince `Agent` ile `model: "sonnet"` alt ajana verilir (istem: iki APK yolu, telefon
   kuralları, `ab_klavye.py` A sonra B ikişer koşu, ikinci koşuların tablosu); kararı
   yürütücü verir. Bir evrede UI ms ya da LAYOUT ms %20'den fazla kötüyse birleştirme YOK:
   satır `takıldı: ölçüm` + sayılar, sıradaki pakete geç. Telefon yoksa/ısınmışsa satır
   `cihaz bekliyor` olur, birleştirme `[apk]`'sız yapılır ve ilk APK noktası ertelenir.
7. **Birleştir.** Dalda: Kuyruk satırını `bitti` + tek satır sonuç yap, `OTURTMA_PLANI.md`
   maddesini `[x]` + tarih + sonuç, `docs/regresyon_listesi.md` satırı, HAFIZA (kök neden
   varsa, tek satır). Sonra `git checkout main && git merge --no-ff oto/<no>` (başlık
   `Birleştir: <paket adı>`), push. **Durum için ayrı commit/push atma** — her main push'u
   CI'ı baştan koşturur ve süren APK'yı iptal eder.
8. **APK noktası** (Kuyruk'ta APK = `evet`): birleştirme başlığına `[apk]`; aynı commit'te
   `assets/guide/release_notes_tr.md` + `_en.md`'ye günün bölümü (kullanıcı diliyle, o
   APK'ya giren bütün paketler). Push'tan sonra APK işi BİTENE dek main'e başka push yok
   (`gh run watch`). main kırmızıysa düzelt ya da `git revert -m 1`.
9. **Regresyon turu** (protokol madde 8): her APK noktasından önce `docs/regresyon_listesi.md`
   baştan koşulur.
10. **Limit freni (%90, kullanıcı kararı 2026-11-09).** Her paketin BAŞINDA, alt ajan
    döndüğünde ve her birleştirmeden önce `mcp__ccd_session_mgmt__get_usage` çağır
    (ToolSearch ile yükle). "5-hour limit" `percentUsed` ≥ 90 ise: yeni paket/alt ajan
    BAŞLATMA; çalışan alt ajana "commit + push yap ve dur" de; yarım iş dalda kalsın,
    Kuyruk satırı `sürüyor` kalsın; kilidi sil; `resetsAt` saatini özetine yaz ve bitir.
    ≥ 80 ise yeni paket başlatma, yalnız elindekini bitir. Araç `unavailable` dönerse
    frensiz devam et (bunu özetine yaz). Tur başında ≥ 90 ise hiçbir şey yapmadan bitir.
    **Devam.** Limit elverdikçe 3. adıma dön. Dur ve bitir: art arda 3 `takıldı`; main iki
    kez üst üste kırmızı; Kuyruk boş. Bitirirken kilidi sil, 5 satır özet yaz.

## İşçi kuralları (alt ajana aynen verilir)

- Depo: Flutter not uygulaması, `C:\Users\sena\Desktop\not`. Önce `CLAUDE.md`, sonra
  `OTURTMA_PLANI.md`'de paketin maddeleri (protokol (a)–(e): önce kanıtı üret → düzelt →
  aynı kanıt yeşil). `HAFIZA.md`'yi BAŞTAN SONA OKUMA (109 KB): konunu `Grep` ile ara.
- Dal: `oto/<no>-<kısa-ad>` (yeni çalışma ağacında önce `flutter pub get`; Flutter yolu
  `C:/src/flutter/bin/flutter.bat`). Küçük adımlarla commit + **her commit'ten sonra push**
  (limit oturumu her an kesebilir; yarım iş dalda kalsın). main'e push YOK.
- **Devir notu (kullanıcı kararı 2026-11-09):** dalın kökünde `DEVIR.md` tut ve HER
  push'tan önce güncelle (en çok 25 satır): yapılanlar (madde + commit) · şu an üstünde
  çalışılan adım ve nerede kaldığı · bulunan kök neden/kanıt (dosya:satır) · denenip
  işe yaramayanlar · sıradaki adım · açık test/ölçüm komutu. Devralan işçi ÖNCE bunu
  okur, baştan keşfetmez. Yürütücü birleştirmeden önce `DEVIR.md`'yi daldan SİLER
  (main'e girmez).
- Doğrulama: değişenin testi `--reporter failures-only`; push'tan önce tam
  `flutter analyze` (CI info düzeyini de hata sayar). Tam test takımını yerelde koşma.
  `dart format lib` yok.
- KARAR çıkarsa plandaki **"En güvenli"** seçenek + maddeye "sabah bakılacak". Kullanıcıya
  soru sorma. Madde kapsamı dışına çıkma, yeni özellik ekleme.
- **Dokunma:** `config/app` bayrakları (`inkV2Write`, `minClient`), veri silen/taşıyan göç,
  erişimi GEVŞETEN kural, imza anahtarı, kişisel dosyalar, telefondaki varsayılan kimlikli
  uygulama (`flutter run/drive` varsayılan kimlikle ASLA — veri gider; ölçüm uygulaması
  `dev.kaimau.notlar.olcum`).
- Kanıt üretilemiyorsa düzeltme yazma: maddeye "üretilemedi: <ne denendi>" yaz, bitir.
- Rapor ≤ 15 satır: ne değişti (dosyalar), hangi test/ölçüm kırmızıdan yeşile döndü,
  doğrulanamayan ne kaldı, dal adı ve son commit.

## Telefon kuralları (Mi Note 10 Lite, USB)

- `adb devices` boşsa cihaz işi atlanır (`cihaz bekliyor`).
- Ekran yalnız ölçüm/tur sırasında: `adb shell input keyevent KEYCODE_WAKEUP` → yukarı
  kaydır (`adb shell input swipe 540 1800 540 600`); iş bitince `KEYCODE_SLEEP`.
  Derleme beklerken ekran KAPALI.
- Ölçümden önce `adb shell dumpsys battery | grep temperature` < 370 (37 °C); değilse bekle.
- Uygulama telefonda misafir hesapta: Google/Drive/Gmail akışları denenemez → "denenmedi".
- Kalem ve tablet yok: kalem ölçümü telefon düzeninde, kalem kipi açık, parmakla
  (`ab_kalem.py`). Tablet isteyen kabul ölçütü "tablette doğrulanmadı" diye işaretlenir.
- Koordinatla basmadan önce ekran yönüne ve klavyeye bak (HAFIZA "Cihaz turu tuzakları").

## Kuyruk

Durum: `bekliyor` · `sürüyor` · `bitti` · `takıldı: <neden>` · `cihaz bekliyor`.
Sıra önceliktir: önce kullanıcının bildirdiği hatalar, sonra kalem/performans, sonra gerisi.

| No | Paket | Model | Plan maddeleri | Cihaz | APK | Durum / sonuç |
|---|---|---|---|---|---|---|
| P01 | Ortak test düzeneği + eke çizgi saf değişiklik | fable | F59.1, F60.1 | A/B | | bitti (2026-11-10): eke 10 çizgide kök kurulum/kayıt 10 → 1; klavye/yazma A/B'de regresyon yok; PDF çizimi cihazda ölçülmedi (P11 aracı) |
| P02 | Klavye/alt panel birikim kasması | fable | F60.S2 | A/B | evet | bitti (2026-11-10): ÜRETİLEMEDİ — cihazsız bekçi (`editor_leak_test`) ve cihazda taze ↔ 32 gir-çık ölçümünde birikim yok (klavye aç 299 → 293 ms); F60.S2 açık kaldı, kullanıcıdan senaryo gerek. Tek düzeltme: `PageTurn` animasyon sızıntısı. APK: P01+P02 |
| P03 | HAFIZA'yı böl (≤ 30 KB), ölü kod | sonnet | F58.2, F58.5 | | | bitti (2026-11-10): HAFIZA 109 → 5 KB (`docs/hafiza/` 10 konu dosyası, `HAFIZA_ARSIV_3.md` bayt bayt eski hâl, boyut bekçisi); ölü `pickReminderWhen` + `CardSeeThrough` silindi. Balonlu yalnız-yazma yolları yapılmadı (sabah bakılacak); yeni 30 kural satırı gözden geçirilmeli |
| P04 | "Tümü" çipi + klasör çipleri, paket kapanması, misafir etiketi | opus | F60.S3, F60.2, F60.4 | | evet | bitti (2026-11-10): Tümü dokun = bütün notlar, uzun bas = Klasörler, tek vurgu; açık paket çubuklara dokununca kapanmıyor, paketle/çöz satır önbelleğini silmiyor (S10 bekçisi); misafirde "Yalnız bu cihazda". Klavye A/B'de regresyon yok (ölçüm Sonnet alt ajanında). Kullanıcıya görünen düzeltme olduğu için `[apk]` |
| P05 | Gömülüde silgi + `PenPolicy` + tek araç durumu | fable | F60.S4, F63.1, F63.2 | | | bitti (2026-11-10): araç durumu tek yerde (`InkToolMemory`): tepsideki silgi/renk sabit ve gömülü PDF'te de geçerli (önce silgi seçiliyken çiziyordu), geri al son dokunulan yüzeyde; kalem kuralı tek tablo `PenPolicy` (4 yerel kopya kalktı, davranış aynı). Cihazda doğrulanmadı (kalem A/B aracı P11). Kalan: kement renk/sil yalnız sayfada; görüntüleyici/çizim ekranı tabloya bağlanmadı (F63.4). SÜRÜM NOTU BORCU (sonraki `[apk]`'ya): silgi eklenmiş PDF'te de siler · tepsideki renk/kalınlık PDF'e yazarken de geçerli · geri al en son yazılan yerdeki çizgiyi alır |
| P06 | Sabit PDF sürekli dikey kaydırma | opus | F65.8 | A/B | evet | bitti (2026-11-10): sabit PDF tembel dikey sayfa sütunu (`PdfPageColumn`; 300 sayfada en çok 5 sayfa canlı), yana kaydırma ve çubuktaki `‹ n/N ›` kalktı, sağ altta sayfa hapı; sayfa kaydı yalnız kaydırma durunca. Klavye A/B (taban 39fc2567, 3'er koşu): kapa %101, aç %99, yazma/kapanış gürültü içinde — regresyon yok. **PDF kaydırmanın KENDİSİ cihazda denenmedi** (ölçüm verisinde PDF'li not yok; 300 sayfa fırlatma + bellek kabulü açık → cihaz turu). APK: P05+P06 |
| P07 | Pencere sınıfı + telefon yatay + tur boyutları | opus | F67.1, F66.7, F67.2 | A/B | | bitti (2026-11-11): `WindowClass` tek yerde (kısa kenar < 600 = telefon), yatay telefonda bölünme yok, döndürmede liste konumu korunur; tur 5 gerçek boyut. A/B (taban 514082b9) regresyon yok (en kötü klavye aç LAYOUT +%10). F66.7 kısmen: kısa yükseklik ince ayarları sabah bakılacak; cihazda uygulama portreye kilitli kaldı, yatay denenemedi |
| P08 | Büyük dosyalar yerelde | opus | F65.9 (K-O15 en güvenli: kopyala) | | evet | bitti (2026-11-11): sınırı aşan PDF akışla uygulama deposuna kopyalanır, `localOnly`, kuyruk/kota atlar, "yalnız bu cihazda"; K-O15 en güvenli (sabah bakılacak). Cihazda 1 GB denenmedi; Gmail/paylaşım/hızlı ekle yolları ve buluta-yedekle anahtarı yapılmadı |
| P11b | Yedek/paket sayfa el yazısını (pageInk) taşımıyor | opus | P11 bulgusu | | evet | bitti (2026-11-11): kök `note_package.dart:59` encode/decode + `note_share.dart:196` içe alma pageInk düşürüyordu; eski paketler açılıyor; gidiş-dönüş ve geri yükleme testleri kırmızı→yeşil |
| P09 | Yazım düzeltici v2 | opus | Faz 70 | | | bitti (2026-11-11): kök: bulanık eşleşme hep aynı adayı veriyor, öğrenme yalnız son kelimenin silinmesini izliyordu; yeni `spell_engine.dart`, hafıza v2 + göç, ısrar testleri kırmızı→yeşil. A/B ters sırayla (B,A,B) regresyon yok (yazma −%9). Sabah bakılacak: öneri eklenmedi, `spell_memory.json.v1` yedeği silinmiyor, gerçek v1 göçü cihazda denenmedi |
| P10 | Güncelleme ekranı takılması | opus | F60.S1 | cihaz | evet | bitti (2026-11-10): kullanıcı çözüldüğünü bildirdi (güncelleme yolu 514082b9'da yeniden yazıldı: `ApkGuncelleme.kt`, `GuncellemeSonrasiAc.kt`, `app_update.dart`). Atla; widget testi ve cihaz doğrulaması ayrıca istenmiyor |
| P11 | Bütçe testleri (kalan) + kalem A/B aracı | fable | F59.2–F59.6 | | | bitti (2026-11-11): bütçe testleri S1–S16 (bugünkü ölçüme oturtuldu, bozma denemesinde kırmızı), `ab_kalem.py` + `make_dataset.py --ink`. Cihazda koşmadı. Bulgular: S8 ilk klavye açılışında ItemsEditor her inset karesinde kuruluyor; `encodeNoteJson` pageInk yazmıyor (yedek el yazısını taşımıyor → P11b) |
| P12 | Güvenlik denetimi + CI kapıları | fable | Faz 71 | | | bitti (2026-11-11): 9 bulgu düzeltildi (YÜKSEK G-01 userDirectory ele geçirme; kilitli not bildirimi; action SHA sabit); rules-test 14→26; CI `guvenlik` işi (gitleaks + osv). Açık: yedek şifresiz G-11 (karar), CSP, konsol işleri `docs/guvenlik_denetimi.md` |
| P13 | Mürekkep deposu v2 (yazma bayrağı KAPALI kalır) | fable | F61.0–F61.6 | ölçüm | | bitti (2026-11-11): okuma tarafı v2 (paket kodlayıcı ≤4,5 KB/1000 nokta, bant planlayıcı, çift okuma, kalem kalkınca sadeleştirme); yazma YOK, bayraklar aynı. Kalem A/B (B,A,B): UI +%11,5, raster −%4 — gürültü içinde. Sabah bakılacak: K-O2 en güvenli, F61.0 b/c cihaz ölçümü, ink kuralları paylaşılan not için bayrak öncesi, F61.6 yazma yolu |
| P14 | Mürekkep çizimi v2 | fable | F62.0–F62.3, F62.5 | A/B | evet | bitti (2026-11-11): çizilen çizgi ayrı katman, tek ortak çizim yolu (`ink_stroke_paint.dart`), basınçlı çizgi saveLayer yok, S15 2001→1 çağrı; dolma kalem. Kalem A/B (B,A,B): çizim UI −%30, raster +%3,6 (gürültü), görsel aynı. Açık: F62.0 dolu sayfa (1500/4000) ölçümü, F62.3 ona bağlı (sabah bakılacak); basınçlı çizgi parmakla sınanamadı |
| P23 | Klavye açılırken alt panel titremesi — kökten | fable | F60.S5 | A/B | evet | bitti (2026-11-11, bulut): KeyboardInsetScope — S17 ilk kare 320 → 45, hareket 87–96 → 54; cihaz A/B YAPILDI 2026-11-12 (P29 satırında): regresyon yok |
| P24 | Madde uzun bas → devam edince madde seçimi | opus | F60.S6 | A/B | evet | bitti (2026-11-11, bulut): basılı tutmaya devam (1,1 sn) → madde seçimi; cihaz A/B 2026-11-12 regresyon yok (P29 satırı) |
| P25 | Yazarken alt panel gizleme ayarları (0,1 sn kaydırıcı) | fable | F60.S7 (P23'ten sonra) | A/B | evet | bitti (2026-11-11, bulut): Ayarlar → Kartlar anahtar + 2 gecikme kaydırıcısı; cihaz A/B 2026-11-12 regresyon yok (P29 satırı) |
| P26 | Kartta gizlenen eke yazılı özet (YouTube/görsel) | sonnet | F60.S8 | | evet | bitti (2026-11-11, bulut): kartta gizli eke tek satır özet |
| P27 | Ana ekranda sürüklerken çöp kutusu | opus | F60.S9 | A/B | evet | bitti (2026-11-11, bulut): sürüklerken çöp hedefi (600 ms dolum); cihaz A/B 2026-11-12 regresyon yok (P29 satırı) |
| P28 | Not ekle menüsü düzen kipi (gizle/göster/sırala) | opus | F60.S10 | | evet | bitti (2026-11-11, bulut): + panelinde düzen kipi |
| P15 | Kalem akışları (kalan) | fable | F63.3–F63.5 (K-O5 en güvenli) | | | bitti (2026-11-11): sabit görsele kalem (çizgi görselin dikdörtgeninde, yakınlaştırmayla), tam ekran PDF/görsel/slaytta yüzen kalem düğmesi (`ViewerPen`, `PenPolicy.viewer` = sabit belge), telefonda parmakla kalem kipinde iki parmak ipucu; K-O5 en güvenli (dokunma, sabah bakılacak). Cihazda doğrulanmadı; PDF/slayt tam ekran widget testi yok. SÜRÜM NOTU BORCU (sonraki `[apk]`): bu üç madde |
| P16 | Doğrulama borcu → cihaz turu belgesi | sonnet | F58.3, F60.6 | | | bitti (2026-11-11): `docs/cihaz_turu.md` (telefon 40, tablet/kalem 27, web 20 adım) + `docs/test_borcu.md`; F58.3 [x]. F60.6 açık: zemin görseli ek sayılıyor (`note_card.dart:1755`, `share_target_sheet.dart:516`) → P22 |
| P17 | Ekler (kalan) | opus | F65.4 (K-O9 bildirim), F65.5, F65.7, F60.3 | | | bitti (2026-11-12): bekleyen ek yüklemesi için 15 dk sonra sessiz bildirim + "Şimdi dene" (K-O9 en güvenli, sabah bakılacak); PDF ilk sayfası küçük önizleme olarak yüklenir (web/diğer cihaz kartında görünür); yeni ek ipucu tek satır 4 sn; "📖 s.N" satırı PDF yokken bağlantı sayılmıyor (dokununca düzenlenir). Cihazda doğrulanmadı; pdfium ilk sayfa işleme gerçek PDF ile denenmedi; F65.7 tür başı varsayılan yerleşim yapılmadı (K-O8, sabah bakılacak). SÜRÜM NOTU BORCU: bu dört madde |
| P29 | Madde uzun bas — iki aşama (halka dolumu, tüm yazı → madde seç) | opus | F60.S11 | A/B | evet | bitti (2026-11-12): halka (yalnız boyama), 650 ms titreşim + tüm yazı, 1250 ms titreşim + madde seç; test 10/10 · cihaz A/B 2026-11-12 (taban fa47d832, aday P23–P32, 2. koşular): klavye aç UI −%22 LAYOUT −%39, kapa −%19/−%37, yazma +%10/+%9, liste +%9/+%11 — regresyon yok |
| P30 | Çöp kutusu: kalan simge hatası + kara delik efekti | opus | F60.S12 | A/B | evet | bitti (2026-11-12): kök — önizlemede hücre yeniden kurulunca onDragEnd gelmiyordu → onDragCompleted/onDraggableCanceled; beklemesiz bırak, yakınlıkla küçül/kızar, 350 ms kara delik; test 4/4 · cihaz A/B 2026-11-12 (taban fa47d832, aday P23–P32, 2. koşular): klavye aç UI −%22 LAYOUT −%39, kapa −%19/−%37, yazma +%10/+%9, liste +%9/+%11 — regresyon yok. Sürükleme efektinin kendisi cihazda gözle denenmedi |
| P31 | Kaydırarak klasör/takvim geçişi ayarı | sonnet | F60.S13 | | evet | bitti (2026-11-12): takvim kaydırma anahtarı (Ayarlar → Notlar); ana ekran klasör kaydırması zaten "Ana ekranda yana kaydırınca → Kapalı" ile kapanıyor, yeni anahtar eklenmedi |
| P32 | Panoda işaretli madde işareti kalkmasın | sonnet | F60.S14 | | evet | bitti (2026-11-12): ana ekran kartında işaretli maddenin kutusuna dokunmak işareti kaldırmıyor, notu açıyor (`note_card.dart` toggleCardItem); işaret kaldırma editörde (sabah bakılacak: kartta geri alma istenirse uzun bas). Test `card_checked_item_test` |
| P18 | Telefon/tablet (kalan) | opus | F67.3, F67.4, F67.9 (+ F66.4 dalda yapıldı). F66.6 → P40, F67.7 → P42 (DENEYIM Ek D.2): bu pakette YAPILMAZ — dal `oto/P18-telefon-tablet` bu hâliyle doğrulanıp birleştirilir | A/B | evet | bitti (2026-11-12): F67.4 kısa pencere+klavye (alt çubuk gizli, üst 40 dp, yazı alanı 73 → 197 dp), F67.3 dar liste bölmesi, F67.9 liste sağa (en olası anlam, sabah bakılacak), F66.4 tur; "+" başlığa taşınmadı. Tablette doğrulanmadı · cihaz A/B 2026-11-12 (taban 6d9f537b, aday P18+P19, 2. koşular): klavye aç UI −%12 LAYOUT −%14, kapa −%5/+%2, yazma −%9/+%13, not kapanış −%23/−%18 — regresyon yok |
| P19 | Liste yükü | fable | F68.1, F68.2 | A/B | | bitti (2026-11-12): F68.1 açık notun kartı yazarken bekler (S12 1/13 → 0/0), F68.2 kısmen (S12b 1/13 → 0/0; gövde bölme üretilemedi, sabah bakılacak) · cihaz A/B 2026-11-12 (taban 6d9f537b, aday P18+P19, 2. koşular): klavye aç UI −%12 LAYOUT −%14, kapa −%5/+%2, yazma −%9/+%13, not kapanış −%23/−%18 — regresyon yok |
| P33 | Tasarım zemini: belirteç, mandal testi, ortak bileşen (görünüm değişmez) | opus | DENEYIM F72.1–F72.5 | | | bitti (2026-11-12): belirteçler (`AppSpace/AppRadius/AppIconSize/AppAlpha/AppWeight`, `AppMotion.quick/long`), `AppText.of` 8 rol, mandal testi `design_tokens_guard_test` (bozma denemesinde kırmızı), `SheetTile`/`DestructiveRow`/`SheetTileGrid`/`DelayedSpinner`, `SectionLabel` = `AppText.section` (w700 → w600; boyut zaten 14). Tur 274 PNG %0 fark. F72.5 kısmen: SheetHeader/EmptyState ölçüleri ve K-D7 tutamak görünür değişiklik → P37 F76.1/F76.3 ve P40 F79.5 (sabah bakılacak). Cihazda yazı ağırlığı görülmedi |
| P34 | Renk rolleri + sakin tipografi | opus | DENEYIM F73.1–F73.4 | | evet | bitti (2026-11-12): renk rolleri (zamanı gelen şeridi sıcak, AI tertiary, paylaş/ayarlar daireleri nötr; sözleşme `app_palette.dart` başında, bekçi `color_roles_test`), yazı boyu 33 yer (< 12 → 12), ağırlık 83 yer → `AppWeight.strong` (mandal fontWeight 225 → 142), tema seçici Sakin/Kâğıt/Canlı. Tur 79 PNG değişti, kabul PNG'lerine bakıldı. Sabah bakılacak: editör `_addToolButton` rengi → P36; "Koyu" Sakin'in sonunda; Görünüm'de "Tema" + "Sakin" iki başlık üst üste. Cihazda görülmedi |
| P35 | Ana ekran cilası (yerleşim değişmez) | opus | DENEYIM F74.1–F74.6 | A/B | evet | bitti (2026-11-12): ev düğmesi primaryContainer, takvim şeridi üç harf gün, zamanı gelen şeridi ✕ 48 dp, kartta işaretliler tek satır özet (yeni `card_show_checked`, varsayılan kapalı — sabah bakılacak: P32 isteğiyle birlikte gözden geçir), soluk kart ⋮, nötr mikrofon, "İlk notunu yaz". Cihaz A/B (taban 8b5c24db, 2. koşular): klavye aç +%5/+%5, yazma +%3/+%4, liste kaydırma +%5,5/+%7 (B daha sıcak) — regresyon yok. Sabah bakılacak: kart yükseklik tahmini özeti saymıyor |
| P36 | Not ekranı alt çubuğu (kalem, dokunma alanı, renkli notta ton) | fable | DENEYIM F75.1–F75.3 | A/B | evet | bitti (2026-11-12): Kalem sol kapsülde, Paylaş ⋮ menüsünde, her segment 48 dp (`MinTapTarget.minWidth`), renkli notta çubuk notun tonunda; 360 dp + ekli metin notunda Kalem çubuktan düşer (en güvenli, sabah bakılacak). Cihaz A/B (taban 32a20103, aday P36+P37+P40 3595df5c, 2. koşular): klavye kapa −%8/−%2, aç −%4/+%6, yazma −%4/−%10, not kapanış gürültülü (A2 sapkın) — regresyon yok; son klavye kapa LAYOUT 9,9 → 13,4 ms (B1 7,4, gürültü). Yazmada en uzun kare 29 → 42 ms, sayısı eşit — sabah bakılacak. Tur sahnesi `n4-paylas` ⋮ üzerinden açılmalı. APK: P36+P37+P40 |
| P37 | Levhalar: ortak başlık, ortak karo | opus | DENEYIM F76.1–F76.4 | | evet | bitti (2026-11-12, bulut): not menüsü 775 → 670 dp (tutamak yok, ⚙ açılır menü: Menüyü/Ekranı düzenle · Ayarlar, Sil `DestructiveRow`), küçük telefonda Sil 96 → 50 dp kaydırma; AI/Paylaş `SheetTile.rich`; `SheetHeader` 56 dp/18 pt; onaylar `showConfirmDialog` (yıkıcı = error); 84 levha dökümü `docs/deneyim/levhalar.md`. Cihazda bakılmadı; sabah bakılacak: kapsam dışı levhalarda tutamak+✕, 34 levha kendi 16 pt başlığı, error tonsuz 5 onay |
| P38 | Hareket ve dokunsal dil | opus | DENEYIM F77.1–F77.4 | A/B | evet | bekliyor |
| P39 | Hız hissi (açılış, yeni not, yükleme hâlleri) | fable | DENEYIM F78.1–F78.5 | cihaz | evet | bekliyor |
| P40 | İkincil ekranlar + boş/çevrimdışı hâller | opus | DENEYIM F79.1–F79.6 (OTURTMA F66.6 dahil) | | evet | bitti (2026-11-12, bulut): `EmptyState` §2.3 ölçüsü + "Burada … yok" kalıbı (terminology bekçisi), `ErrorState` "Bağlantı yok"/"Yüklenemedi" (Gelen hatada artık boş görünmüyor), boş klasör 72 dp + ızgaradaki Yeni klasör karosu kalktı, Çöp/Arşiv Ara+⋮ ve etiketli Geri al·Sil, Ayarlar nötr 40 dp kutular + misafir kartı, ajanda 56/64 dp; tur `TOUR_EMPTY`/`TOUR_OFFLINE` 6+6. Sabah bakılacak: ana ekran Gelen süzgeci hatada boş hâl (P19 alanı), AI levhası çevrimdışı düğmeler, bekleyen ek şeridi çevrimdışı "yükleniyor" |
| P41 | Belirteç göçü (mekanik; editör klasörü hariç; açık dal yokken) | sonnet | DENEYIM F72.6 | | | bekliyor |
| P42 | Koyu tema, küçük ekran, web cilası, önce/sonra dosyası | sonnet + opus | DENEYIM F80.1–F80.5 (OTURTMA F67.7 dahil) | | evet | bitti (2026-11-12, bulut; kullanıcı isteğiyle birleştirildi): koyu temada kart/PDF perdesi/Sil ayrışması (`docs/deneyim/koyu.md`, bekçiler `theme_contrast_test`, `dark_theme_polish_test`), tura `TOUR_FONT=1.3`, takvim şeridi büyük yazıda küçülür, web odak halkası `KeyboardFocusRing` + kısayollar `kAppShortcuts`, `tap_targets_test` (27 gerekçeli istisna); F80.5 kısmi (cihaz turu web 21–23, tablet 28). Sabah bakılacak: `docs/deneyim/once-sonra.md` yazılmadı, sabit PDF çubuğu 1,3× + 360/393 dp taşıyor (`pinned_media_pane.dart`), şerit çipleri 32 dp. Cihazda bakılmadı |
| P20 | Editör çekirdeği (başlama şartı tutuyorsa) | fable | Faz 64 | A/B | evet | bekliyor |
| P21 | Kapanış: konsol listesi, plan/HAFIZA toparlama | sonnet | F69.4, F69.5 | | | bekliyor |
| P22 | SON PAKET: açıkta kalan her maddeyi değerlendir ve uygun biçimde yap | opus | P01–P21'de adı geçmeyen açık `[ ]` maddeler (F58.1, F58.4, F60.5, F60.7, F61.7, F61.8, F62.4, F62.6, F63.6, F63.7, F65.1–3, F65.6, F66.1–3, F66.5, F67.5, F67.6, F67.8, F68.3–5, F69.1–3) + F60.S2 + "cihazda doğrulanmadı" / "tablette doğrulanmadı" işaretli maddeler + açık K-O kararları | gerekirse | gerekirse | bekliyor — protokol aşağıda |

**P22 protokolü (kullanıcı isteği 2026-11-10):** P01–P21 bitince `OTURTMA_PLANI.md`'yi baştan tara; `[ ]` kalan HER maddeyi otomatik değerlendir, soru sorma. Her madde için sırayla: (1) kanıtla — kod/test/ölçümle hâlâ geçerli mi, başka işle kapanmış mı; (2) kapanmışsa `[x]` + tek satır kanıt, gereksizse `[~]` + neden; (3) geçerliyse kendi modeli neyse ona uygun işle: kısa maddeleri kendin yap, Fable gerektirenleri (güvenlik/performans/editör/kalem) `Agent` ile `model: "fable"` alt ajana ver, mekanik olanları `sonnet` alt ajana; (4) KARAR çıkarsa plandaki "En güvenli" seçenek + maddeye "sabah bakılacak"; (5) telefon/tablet/hesap gerektirenler yapılamaz → "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım. Kullanıcı işi olanları (konsol, hesap, telefon) yapma, yalnız `KALANLAR.md`'ye topla. Küçük commit'ler, CI yeşilse `[apk]`; sonunda plan Durum tablosu + HAFIZA güncelle ve geriye kalanın dürüst listesini yaz.

**P33–P42 = `DENEYIM_PLANI.md` (kullanıcı isteği 2026-11-12: "görünen ve hissedilen her
şeyi mükemmelleştir; tasarım Fable'da" + "diğer fazlarla zıt olmasın, aynı yerde tekrar
tekrar çalışmayalım").** Bu paketlerin maddeleri, protokolü ve "Önce oku" listeleri O
dosyadadır (işçiye `OTURTMA_PLANI.md` yerine onu okut). Kurallar: (1) oradaki **K-D
kararları VERİLMİŞTİR** — "en güvenli"ye düşme; her K-D tek başına geri alınabilir tek
commit. (2) **Önce eski isteğe bak:** görünüş/yer değiştirmeden önce `python
tool/design/istek_tara.py <dosya>`; çelişen iş YAPILMAZ (plan §4'teki 16 fikir dahil).
(3) **Kapsam çiti = plan Ek D:** her paket yalnız orada adına yazılı dosyalara dokunur.
(4) **Sıra (kullanıcı kararı 2026-11-12: "Fable işleri limit ilk açıldığında ilk yapılsın"):**
FABLE ÖNCE — P36 → P39 → P20, sonra Opus/Sonnet: P37 → P38 → P40 → P41 → P42 → P21 → P22.
Fable paketi yalnız 5 saatlik limit taze/düşükken (%55 altı) başlar; %55 üstündeyse sıradaki
Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince (resetsAt sonrası
ilk tur) EN BAŞTA alınır. P20 başlama şartı tutmuyorsa atla; tek şart P33 bitmiş olsun. P41 yalnız Kuyruk'ta `sürüyor`
/ `bulutta:` satırı yokken. (5) Her paket işe başlamadan ekran turunu `build/tour-once/`'ye
alır, bitince `TOUR_COMPARE` ile karşılaştırır; yürütücü kabulde adı geçen PNG'lere kendi
bakar. (6) **P22 ATLAR** (bu planla kapandı ya da taşındı): K-O5, K-O10, K-O11, K-O14,
F60.7, F63.5, F66.1, F66.2, F66.3, F66.4, F66.6, F67.7. **K-O6 / F65.1 kullanıcıda AÇIK**
(gözetimsiz yapılmaz). (7) HAFIZA/CLAUDE/KALANLAR toparlaması yalnız P21'de (tek kapanış).

Atlananlar (kullanıcı kararı bekliyor, gözetimsiz yapılmaz): K-O1, K-O3 (v2 yazımını açma),
K-O4, K-O6, K-O7, K-O8, K-O10, K-O11, K-O12, K-O14, F63.6, F65.6 (kullanıcıdan hata metni),
F69.1–F69.3 (elle cihaz turu).
