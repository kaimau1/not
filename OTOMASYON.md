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
| P23 | Klavye açılırken alt panel titremesi — kökten | fable | F60.S5 | A/B | evet | bulutta: sürüyor (2026-11-11, bulut oturumu) |
| P24 | Madde uzun bas → devam edince madde seçimi | opus | F60.S6 | A/B | evet | bulutta: sürüyor (2026-11-11, bulut oturumu) |
| P25 | Yazarken alt panel gizleme ayarları (0,1 sn kaydırıcı) | fable | F60.S7 (P23'ten sonra) | A/B | evet | bulutta: sürüyor (2026-11-11, bulut oturumu) |
| P26 | Kartta gizlenen eke yazılı özet (YouTube/görsel) | sonnet | F60.S8 | | evet | bulutta: sürüyor (2026-11-11, bulut oturumu) |
| P27 | Ana ekranda sürüklerken çöp kutusu | opus | F60.S9 | A/B | evet | bulutta: sürüyor (2026-11-11, bulut oturumu) |
| P28 | Not ekle menüsü düzen kipi (gizle/göster/sırala) | opus | F60.S10 | | evet | bulutta: sürüyor (2026-11-11, bulut oturumu) |
| P15 | Kalem akışları (kalan) | fable | F63.3–F63.5 (K-O5 en güvenli) | | | bekliyor |
| P16 | Doğrulama borcu → cihaz turu belgesi | sonnet | F58.3, F60.6 | | | bitti (2026-11-11): `docs/cihaz_turu.md` (telefon 40, tablet/kalem 27, web 20 adım) + `docs/test_borcu.md`; F58.3 [x]. F60.6 açık: zemin görseli ek sayılıyor (`note_card.dart:1755`, `share_target_sheet.dart:516`) → P22 |
| P17 | Ekler (kalan) | opus | F65.4 (K-O9 bildirim), F65.5, F65.7, F60.3 | | | bekliyor |
| P18 | Telefon/tablet (kalan) | opus | F66.4, F66.6, F67.3, F67.4, F67.7, F67.9 | A/B | evet | bekliyor |
| P19 | Liste yükü | fable | F68.1, F68.2 | A/B | | bekliyor |
| P20 | Editör çekirdeği (başlama şartı tutuyorsa) | fable | Faz 64 | A/B | evet | bekliyor |
| P21 | Kapanış: konsol listesi, plan/HAFIZA toparlama | sonnet | F69.4, F69.5 | | | bekliyor |
| P22 | SON PAKET: açıkta kalan her maddeyi değerlendir ve uygun biçimde yap | opus | P01–P21'de adı geçmeyen açık `[ ]` maddeler (F58.1, F58.4, F60.5, F60.7, F61.7, F61.8, F62.4, F62.6, F63.6, F63.7, F65.1–3, F65.6, F66.1–3, F66.5, F67.5, F67.6, F67.8, F68.3–5, F69.1–3) + F60.S2 + "cihazda doğrulanmadı" / "tablette doğrulanmadı" işaretli maddeler + açık K-O kararları | gerekirse | gerekirse | bekliyor — protokol aşağıda |

**P22 protokolü (kullanıcı isteği 2026-11-10):** P01–P21 bitince `OTURTMA_PLANI.md`'yi baştan tara; `[ ]` kalan HER maddeyi otomatik değerlendir, soru sorma. Her madde için sırayla: (1) kanıtla — kod/test/ölçümle hâlâ geçerli mi, başka işle kapanmış mı; (2) kapanmışsa `[x]` + tek satır kanıt, gereksizse `[~]` + neden; (3) geçerliyse kendi modeli neyse ona uygun işle: kısa maddeleri kendin yap, Fable gerektirenleri (güvenlik/performans/editör/kalem) `Agent` ile `model: "fable"` alt ajana ver, mekanik olanları `sonnet` alt ajana; (4) KARAR çıkarsa plandaki "En güvenli" seçenek + maddeye "sabah bakılacak"; (5) telefon/tablet/hesap gerektirenler yapılamaz → "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım. Kullanıcı işi olanları (konsol, hesap, telefon) yapma, yalnız `KALANLAR.md`'ye topla. Küçük commit'ler, CI yeşilse `[apk]`; sonunda plan Durum tablosu + HAFIZA güncelle ve geriye kalanın dürüst listesini yaz.

Atlananlar (kullanıcı kararı bekliyor, gözetimsiz yapılmaz): K-O1, K-O3 (v2 yazımını açma),
K-O4, K-O6, K-O7, K-O8, K-O10, K-O11, K-O12, K-O14, F63.6, F65.6 (kullanıcıdan hata metni),
F69.1–F69.3 (elle cihaz turu).
