# OTOMASYON — gözetimsiz iş zinciri

**Kullanıcı izni (2026-11-09):** işleri otomasyonla başlat, istediğin modelde alt ajan aç,
limite göre çalış; test telefonu USB'de (şifresiz, ekranı bozuk: yalnız gerekince aç); işi
bitir, main'e gönder; token israf etme ama bitmiş iş ver.

Plan: `OTURTMA_PLANI.md`. Bu dosya yalnız YÜRÜTME düzenidir. Her tur bu dosyayı baştan okur.

## Nasıl çalışır

- Zamanlanmış görev `not-oturtma-zinciri` her saat :55'te oturum başlatır; limit dolunca
  oturum ölür, sonraki tetik **kaldığı yerden** sürer. Durum: aşağıdaki Kuyruk.
- Zamanlanmış oturum YENİ OTURUM AÇAMAZ. Başka model gereken paket
  `Agent` aracıyla ALT AJANA verilir: `model: "fable" | "opus" | "sonnet"`,
  `isolation: "worktree"`, istem = aşağıdaki "İşçi kuralları" + paketin satırı. `Agent`
  reddedilirse ya da o model yoksa paket BU oturumda yapılır; Kuyruk'a gerçek model yazılır.
- **Yürütücü ince kalır (kullanıcı kararı 2026-11-12: "alt ajanlar daha çok işi yapabilir"):**
  CI izleme, kırmızı CI düzeltme, DEVIR, plan `[x]`, Kuyruk satırı güncellemesi ve sürüm notu
  taslağı ALT AJANIN işidir; yürütücü yalnız raporu, `git log`/diff özetini ve `gh run`
  sonucunu kontrol eder, birleştirir. Paketleri büyük tut (alt ajan başına daha çok madde;
  her alt ajan sıfırdan başlar). Alt ajan beklerken yoklama yok, bildirimi bekle.
- Aynı anda TEK yürütücü. Kilit: `.git/oto.lock` (içinde ISO zaman).

## Bir turun adımları

0. **Kilit.** `.git/oto.lock` varsa ve son değişimi 60 dakikadan yeniyse: hiçbir şey
   yapmadan "başka yürütücü çalışıyor" de ve BİTİR. Değilse kilidi şimdi yaz. Aşağıdaki
   her adımın başında kilidi tazele. Tur nasıl biterse bitsin kilidi sil.
   Kilit yalnız adım başında tek `date >` ile tazelenir; arka plan döngüsüyle ASLA (oturum
   ölünce döngü yaşar, kilit sonsuza dek taze kalır). Eşik tek: 60 dk (zamanlanmış görevle aynı).
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
   aşağıda. **Ölçümü yürütücü KENDİ yapmaz:** derlemeler bitince `Agent` `model: "sonnet"`
   alt ajana (iki APK yolu, telefon kuralları, `ab_klavye.py` A sonra B ikişer koşu, ikinci
   koşuların tablosu); kararı yürütücü verir. **Hız hissi / açılış / yükleme / akıcılık
   paketlerinde (P39 vb.) eşik %20 DEĞİL: hiçbir evre kötüleşmez, hedef evre ölçülebilir
   iyileşir.** Kötüleşirse paket çöpe gitmez: maddeler ayrı commit; kötüleştiren `git revert`
   + maddeye "iyileşme kanıtlanamadı", iyiler yeniden ölçülüp birleşir.
   Bir evrede UI ms ya da LAYOUT ms %20'den fazla kötüyse birleştirme YOK:
   satır `takıldı: ölçüm` + sayılar, sıradaki pakete geç. Telefon yoksa/ısınmışsa satır
   `cihaz bekliyor`, birleştirme `[apk]`'sız, ilk APK noktası ertelenir.
7. **Birleştir.** Alt ajan dalda yapmış olmalı: Kuyruk satırı `bitti` + tek satır sonuç, plan
   maddesi `[x]` + tarih + sonuç, `docs/regresyon_listesi.md` satırı, HAFIZA (kök neden varsa).
   Yürütücü kontrol eder, sonra `git checkout main && git merge --no-ff oto/<no>` (başlık
   `Birleştir: <paket adı>`), push. **Durum için ayrı commit/push atma** — her main push'u
   CI'ı baştan koşturur ve süren APK'yı iptal eder.
   **Temizlik (kullanıcı kararı 2026-11-12):** birleştirince o paketin çalışma kopyası
   (`git worktree remove --force <ağaç>`), uzak dalı (`git push origin --delete oto/<no>-*`)
   ve yerel dalı silinir; A/B taban ağacı (`../not_ab`) ölçüm bitince silinir. 34 kopya
   (~onlarca GB) birikmişti. Silinemeyen klasörü tutan Gradle sürecini durdur.
8. **APK noktası** (Kuyruk'ta APK = `evet`): birleştirme başlığına `[apk]`; aynı commit'te
   `assets/guide/release_notes_tr.md` + `_en.md`'ye günün bölümü (kullanıcı diliyle, o
   APK'ya giren bütün paketler). Push'tan sonra APK işi BİTENE dek main'e başka push yok
   (`gh run watch`). main kırmızıysa düzelt ya da `git revert -m 1`.
9. **Regresyon turu** (protokol madde 8): her APK noktasından önce `docs/regresyon_listesi.md`
   baştan koşulur.
10. **Limit freni (%90).** Paket başında, alt ajan dönünce, birleştirmeden önce
    `mcp__ccd_session_mgmt__get_usage` (ToolSearch ile yükle). "5-hour limit" `percentUsed` ≥ 90:
    yeni paket/alt ajan YOK; çalışana "commit + push yap ve dur" de; satır `sürüyor` kalsın;
    kilidi sil; `resetsAt`'ı özetine yaz, bitir (tur başında ≥ 90 ise hiçbir şey yapmadan bitir).
    ≥ 80: yeni paket başlatma, elindekini bitir. Araç `unavailable` ise frensiz devam (özetine yaz).
    **Devam.** Limit elverdikçe 3. adıma dön. Dur ve bitir: art arda 3 `takıldı`; main iki
    kez üst üste kırmızı; Kuyruk boş. Bitirirken kilidi sil, 5 satır özet yaz.

11. **Takılma önleme.** Her arka plan bekleme süre sınırlı: `timeout 2700 gh run watch <id>
    --exit-status` (45 dk; yalnız tek koşu, döngü yok); dolunca `gh run view <id> --json
    status,conclusion`. Alt ajandan 90 dk bildirim gelmezse `SendMessage` ile "commit + push +
    dur"; yine dönmezse `TaskStop`, satır `sürüyor` kalır (DEVIR.md devralana yeter). Tur
    bitince (başarılı/takıldı/limit): kendi arka plan görevlerini `TaskStop`, telefon ekranını
    kapat (`KEYCODE_SLEEP`), kilidi sil — kilidi silmeden özet yazma.

## İşçi kuralları (alt ajana aynen verilir)

- Depo: Flutter not uygulaması, `C:\Users\sena\Desktop\not`. Önce `CLAUDE.md`, sonra
  `OTURTMA_PLANI.md`'de (hız paketleri: `HIZ_PLANI.md`; görünüş: `DENEYIM_PLANI.md`) ve `KUYRUK_AYRINTI.md`'de paketin maddeleri (protokol (a)–(e): önce kanıtı üret → düzelt →
  aynı kanıt yeşil). `HAFIZA.md`'yi BAŞTAN SONA OKUMA (109 KB): konunu `Grep` ile ara.
- Dal: `oto/<no>-<kısa-ad>` (yeni çalışma ağacında önce `flutter pub get`; Flutter yolu
  `C:/src/flutter/bin/flutter.bat`). Küçük adımlarla commit + **her commit'ten sonra push**
  (limit oturumu her an kesebilir; yarım iş dalda kalsın). main'e push YOK.
- **Devir notu:** dalın kökünde `DEVIR.md`, HER push'tan önce güncel (en çok 25 satır):
  yapılanlar (madde + commit) · şu anki adım · kök neden/kanıt (dosya:satır) · işe
  yaramayanlar · sıradaki adım · test/ölçüm komutu. Devralan işçi ÖNCE bunu
  okur, baştan keşfetmez. Yürütücü birleştirmeden önce `DEVIR.md`'yi daldan SİLER
  (main'e girmez).
- Doğrulama: değişenin testi `--reporter failures-only`; push'tan önce tam
  `flutter analyze` (CI info düzeyini de hata sayar). Tam test takımını yerelde koşma.
  `dart format lib` yok.
- **Hız hissi işi:** kötüleşme yok; her değişiklik ölçülebilir iyileşir (önce/sonra DEVIR'e);
  kanıtsız değişiklik yapılmaz. Her madde AYRI commit (geri alınabilsin).
- KARAR çıkarsa plandaki **"En güvenli"** seçenek + maddeye "sabah bakılacak". Kullanıcıya
  soru sorma. Madde kapsamı dışına çıkma, yeni özellik ekleme.
- **Dokunma:** `config/app` bayrakları (`inkV2Write`, `minClient`), veri silen/taşıyan göç,
  erişimi GEVŞETEN kural, imza anahtarı, kişisel dosyalar, telefondaki varsayılan kimlikli
  uygulama (`flutter run/drive` varsayılan kimlikle ASLA — veri gider; ölçüm uygulaması
  `dev.kaimau.notlar.olcum`).
- Kanıt üretilemiyorsa düzeltme yazma: maddeye "üretilemedi: <ne denendi>" yaz, bitir.
- Arka planda başlattığın her komut (`flutter`, `gh run watch`, `adb`, betik) `timeout` ile; raporu yazmadan önce hepsini bitir/öldür.
- Rapor ≤ 15 satır: ne değişti (dosyalar), hangi test/ölçüm kırmızıdan yeşile döndü,
  doğrulanamayan ne kaldı, dal adı ve son commit.

## Telefon kuralları (Mi Note 10 Lite, USB)

- `adb devices` boşsa cihaz işi atlanır (`cihaz bekliyor`).
- Ekran yalnız ölçüm/tur sırasında: `adb shell input keyevent KEYCODE_WAKEUP` → yukarı
  kaydır (`adb shell input swipe 540 1800 540 600`); iş bitince `KEYCODE_SLEEP`.
  Derleme beklerken ekran KAPALI.
- Ölçümden önce `adb shell dumpsys battery | grep temperature` < 370 (37 °C); değilse bekle.
- Telefonda misafir hesap: Google/Drive/Gmail akışları "denenmedi".
- Kalem/tablet yok: kalem ölçümü telefonda parmakla (`ab_kalem.py`); tablet isteyen ölçüt "tablette doğrulanmadı".
- Koordinatla basmadan önce ekran yönüne ve klavyeye bak (HAFIZA "Cihaz turu tuzakları").

## Kuyruk

Durum: `bekliyor` · `sürüyor` · `bitti` · `takıldı: <neden>` · `cihaz bekliyor`.

Biten paketler: P01–P19, P23–P37, P40, P42, P47 (38; ayrıntı sürüm geçmişinde: `-S '| P01 |'`).

| No | Paket | Model | Plan maddeleri | Cihaz | APK | Durum / sonuç |
|---|---|---|---|---|---|---|
| P39 | Hız hissi (açılış, yeni not, yükleme) | fable | DENEYIM F78.1–F78.5 | cihaz | evet | sürüyor — dal oto/P39-hiz-hissi CI yeşil, main birleşti; kalan: cihaz A/B (DEVIR.md) + birleştirme; ayrıntı: KUYRUK_AYRINTI.md §P39 |
| P43 | Hız: tek komutla tam ölçüm + karar + altın taban + cihazsız bekçiler (P44 katıldı) | opus | HIZ_PLANI F81–F82 + F68.4 | cihaz |  | bekliyor — önce F82, sonra F81; + F68.4; sabit ek düzeltmesi P49'da; ayrıntı: KUYRUK_AYRINTI.md §P43 |
| P45 | Hız: her [apk]'da ölçüm + geçmiş | sonnet | HIZ_PLANI F83.1–F83.3 | cihaz |  | bekliyor — HIZ_PLANI F83; ayrıntı: KUYRUK_AYRINTI.md §P45 |
| P46 | Hız: ölçümün bulduğu yavaşlıkları düzelt | fable (limit %55 üstü → opus) | HIZ_PLANI F84 + F60.S2/F60.5/F68.3 | A/B | evet | bekliyor — `pinned_media_pane.dart`'a DOKUNMAZ (P49'un); sabit ekte bulgu P49 satırına yazılır; ayrıntı: KUYRUK_AYRINTI.md §P46 |
| P48 | Web yazı seçimi + takvim senkronu + web ek | opus | kullanıcı 2026-11-12 | cihaz (b) | evet | bekliyor — önce webde üret, kök neden kanıtlanmadan düzeltme yok; sabit ek çubuğu P49'un; ayrıntı: KUYRUK_AYRINTI.md §P48 |
| P49 | Sabit ek baştan: tasarım, tuşlar, özellikler | fable (limit %55 üstü → opus) | kullanıcı 2026-11-12 | A/B | evet | bekliyor — BAŞTAN TASARIM; kesin istekler (a)–(g) + KORU ayrıntıda; önce `istek_tara.py`; ayrıntı: KUYRUK_AYRINTI.md §P49 |
| P50 | Düzenleme modu baştan + hızlı menü | fable (limit %55 üstü → opus) | kullanıcı 2026-11-12 |  | evet | bekliyor — P49'DAN SONRA; `pinned_media_pane.dart`'a dokunmaz; kasma listesi §3–§4; ayrıntı: KUYRUK_AYRINTI.md §P50 |
| P38 | Hareket ve dokunsal dil | opus | DENEYIM F77.1–F77.4 | A/B | evet | bekliyor — P47 çöp sürükleme haptiği/`_previewCardDrop` korunur, yalnız `AppHaptics`e sarılır; ayrıntı: KUYRUK_AYRINTI.md §P38 |
| P20 | Editör çekirdeği | fable | Faz 64 | A/B | evet | bekliyor — P49 ve P50 BİTTİKTEN sonra; onların editör bloklarını AYNEN taşır; ayrıntı: KUYRUK_AYRINTI.md §P20 |
| P41 | Belirteç göçü | sonnet | DENEYIM F72.6 |  |  | bekliyor — P22'den önce, açık dal yokken (mekanik; editör hariç); kapanış toparlaması P53'te; ayrıntı: KUYRUK_AYRINTI.md §P41 |
| P22 | SON PAKET: açıkta kalan maddeler | opus | kalan `[ ]` maddeler | gerekirse | gerekirse | bekliyor — kalan `[ ]` maddeler + taşınanlar listesi ayrıntıda; ayrıntı: KUYRUK_AYRINTI.md §P22 |
| P53 | BÜYÜK TOPARLAMA: tek plan, tek kontrol listesi | opus | kullanıcı 2026-11-12 + F69.4/5, F58.1/4 |  |  | bekliyor — EN SON (P22'den sonra); protokol ayrıntıda; ayrıntı: KUYRUK_AYRINTI.md §P53 |

**SIRA (kullanıcı kararı 2026-11-12):** HIZ önce: P39 → P43 → P45 → P46. FABLE sonra: P36 → P39 → P49 → P50 → P20; sonra Opus/Sonnet: P37 → P38 → P40 → P48 → P42 → P41 → P22 → P53 (EN SON). Fable paketi yalnız 5 saatlik limit %55 altındayken başlar; üstündeyse sıradaki Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince EN BAŞTA alınır. P20 yalnız P33 bitmişse. P41 yalnız Kuyruk'ta `sürüyor`/`bulutta:` satırı yokken.

Paket protokolleri (P22, P53, P33–P42 = `DENEYIM_PLANI.md` kuralları: K-D kararları verildi, kapsam çiti Ek D, `istek_tara.py`, "Atlananlar") ve satırların tam metni: **`KUYRUK_AYRINTI.md`**; alt ajana paketin ayrıntı bölümünü de ver.
