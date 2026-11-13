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
   alt ajana ("iki APK, `ab_hepsi.py <A> <B> --altin`, tabloyu ve son satırı getir"); karar
   `KARAR:` satırıdır (F81.2 kuralı + altın taban %15). **Hız hissi / açılış / yükleme / akıcılık
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
   **Yarım iş devri (kullanıcı kararı 2026-11-12):** paket yarıda kalırsa (limit/durdurma) Kuyruk
   satırı HEMEN `sürüyor — dal <ad> (<commit>): bitti <x>, kalan <y>; DEVIR.md'den sür` olur ve main'e
   push edilir ("bekliyor" kalırsa sonraki tur sıfırdan başlar). Önce `git log origin/<dal>..HEAD`
   boş olmalı. Ölçüm ham sayıları DEVIR'e/plana yazılır, sohbette kalmaz. Tur başında uzaktaki
   `oto/*` dallarına bak; satırı olmayan dalı DEVIR'iyle satıra bağla.
8. **APK noktası** (Kuyruk'ta APK = `evet`): birleştirmeden ÖNCE `ab_hepsi.py <A> <B> --altin` ZORUNLU (paket A/B istemese bile; F83.1) — telefon yoksa `[apk]` ertelenir, birleştirme `[apk]`'sız; birleştirme başlığına `[apk]`; aynı commit'te
   `assets/guide/release_notes_tr.md` + `_en.md`'ye günün bölümü (kullanıcı diliyle, o
   APK'ya giren bütün paketler).
   **APK izlenmez (kullanıcı kararı 2026-11-12):** dal CI'ı yeşilse main APK'sı da yeşil olur;
   birleştir, push, özeti ver, sıradaki pakete geç. Yalnız sonraki main push'undan ÖNCE tek bakış:
   `gh run list -b main -L 1` — APK işi sürüyorsa push'u bekletip dalda çalışmaya devam et
   (yeni push süren APK'yı iptal eder). main kırmızıysa 2. adım (main sağlığı) yakalar.
9. **Regresyon turu** (protokol madde 8): her APK noktasından önce `docs/regresyon_listesi.md`
   baştan koşulur.
10. **Limit freni (%90).** Paket başında, alt ajan dönünce, birleştirmeden önce
    `mcp__ccd_session_mgmt__get_usage` (ToolSearch ile yükle). "5-hour limit" `percentUsed` ≥ 90:
    yeni paket/alt ajan YOK; çalışana "commit + push yap ve dur" de; satır `sürüyor` kalsın;
    kilidi sil; `resetsAt`'ı özetine yaz, bitir (tur başında ≥ 90 ise hiçbir şey yapmadan bitir).
    ≥ 80: yeni paket başlatma, elindekini bitir. Araç `unavailable` ise frensiz devam (özetine yaz).
    **Devam.** Limit elverdikçe 3. adıma dön.
    **Limiti boş bırakma (kullanıcı kararı 2026-11-13: "gece boyu ufacık işler yapıp durmuş"):**
    aynı anda EN ÇOK 2 paket alt ajanı (dosyaları çakışmayan iki paket; cihaz/A-B ölçümü tek
    seferde bir tane). Biri bitince hemen sıradakini başlat. Limit < %80 ve Kuyruk'ta iş varken
    tur BİTMEZ (yalnız kilit/limit/3 takıldı ile biter). Cihaz kabul ölçümü (A=A, altın taban)
    en çok 2 tur; yine kırmızıysa satıra `kullanıcı kararı` yaz, aracı/işi birleştir, sıradakine
    geç — saatlerce ölçüm döngüsü yok.
    **Uzun alt ajanı DİRİLTME (2026-11-13: limit açılınca iki Fable ajanı SendMessage ile
    sürdürüldü, 1 dakikada 0 → %43):** sürdürülen ajan bütün eski konuşmasını önbelleksiz yeniden
    gönderir. Limit yenilenince ya da 5 dk'dan uzun aradan sonra eski ajana mesaj atma; aynı
    paket için YENİ alt ajan aç, istem "dalın DEVIR.md'sinden sür" olsun. **Haftalık Fable kotası
    SONUNA KADAR kullanılır (kullanıcı 2026-11-13):** haftalık Fable sınırı yok; Fable satırları
    Fable'la yapılır, haftalık kota bitince Opus. Dur ve bitir: art arda 3 `takıldı`; main iki
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

Biten paketler: P01–P19, P23–P37, P39, P40, P42, P47 (39; P39 cihaz A/B 2026-11-12: soğuk açılış −5…−11 %, beyaz kare −11…−20 %, liste −46 % kare, klavye gürültü sınırında; ayrıntı sürüm geçmişinde: `-S '| P01 |'`).

| No | Paket | Model | Plan maddeleri | Cihaz | APK | Durum / sonuç |
|---|---|---|---|---|---|---|
| P54b | .md başlık düzeltmesi | opus | P54 devamı | | evet | bitti — main'e birleştirildi 2026-11-13 |
| P43 | Hız: tek komutla tam ölçüm + karar + altın taban + cihazsız bekçiler (P44 katıldı) | opus | HIZ_PLANI F81–F82 + F68.4 | cihaz |  | araç main'e birleştirildi 2026-11-13 (kabul: kullanıcı 2026-11-13 `yaz` LAYOUT'a gürültü payı verdi (ab_hepsi ALTIN_PAY %25) → kapandı) — F82 main'de; F81 araç+altın taban bitti, KABUL KALDI (2. tur: A/B %20 eşikle A=A 2/2 GEÇTİ; altına karşı `yaz` LAYOUT +%16 yanlış alarm — sabah bakılacak); F68.4 ölçüldü (%2,3–3,3) → P46; ayrıntı: KUYRUK_AYRINTI.md §P43 |
| P55 | KASMA KÖKTEN: not aç/kapa, klavye aç/kapa, alt panel titremesi, alt çizgili madde + P46'nın cihaz maddeleri (F84.1–3, F60.S2, F60.5, F68.3) | opus | kullanıcı 2026-11-13 | A/B | evet | cihaz bekliyor — dal `oto/P55-kasma` (52227793) BİTTİ, CI yeşil: alt panel titremesi kök nedeni (Android<35 IME animasyonunda gezinme çubuğu boyu eksik) `keyboard_snap.dart` içinde düzeldi, cihaz kaydında 63/85 → 0/85 kare; F84.1/2 düzelmedi, F68.3 sabah bakılacak; A/B 1. tur 2026-11-13: KARAR KALDI yalnız altın tabana karşı `yaz` LAYOUT +%33 (A 373, B 415 ms; A↔B 13 evrede gürültü içinde; ham: Desktop/ab_P55_P56_P38.log) → KALAN: 2. tur; yine yalnız altın `yaz` ise kullanıcı kararı yaz, [apk] birleştir; DEVIR.md dalda |
| P56 | Not sürükle-sırala: iki sütun arasında zıplama | opus | kullanıcı 2026-11-13 | A/B | evet | cihaz bekliyor — dal `oto/P56-surukle-zipla` (62f53171) BİTTİ, CI yeşil: `reorder_hover_gate.dart` 100 ms bekleme + 300 ms kilit, kanıt testi 60 → ≤1 takas; KALAN: cihaz A/B → geçerse [apk] birleştir; DEVIR.md dalda |
| P57 | Alt çubuk: her düğme eklenip çıkarılabilir, sıralanabilir (Ayarlar) | opus | kullanıcı 2026-11-13 |  | evet | bitti — bulut 2026-11-13, main'e [apk]: `UiPrefs.barOrder/aiOrder` + 8 eklenebilir düğme (geri al, yinele, hatırlatıcı, fotoğraf, kamera, tara, renk, paylaş); Ayarlar → Kişiselleştir → alt çubuk sürükle-sırala + anahtar; varsayılan görünüş aynı; cihazda doğrulanmadı (KALANLAR L5); kalan: düğmeyi iki kapsül arasında taşıma yok — P50'ye; ayrıntı: KUYRUK_AYRINTI.md §P57 |
| P58 | Klasörde/süzgeçte de basılı tut → çöpe sürükle | opus | kullanıcı 2026-11-13 |  | evet | bitti — bulut 2026-11-13, main'e [apk]: elle sıra kapalı görünümlerde (klasör, süzgeç, arama, etiket) sürükleme yalnız çöp hedefine (`inSection` false → sıra önizlemesi yok, sıra yazılmaz); oynamadan bırakma eskisi gibi seçer; başkasının paylaşılan klasöründe kapalı; kanıt `drag_trash_target_test` (önce kırmızı); cihazda doğrulanmadı (KALANLAR L6) |
| P45 | Hız: her [apk]'da ölçüm + geçmiş | sonnet | HIZ_PLANI F83.1–F83.3 | cihaz |  | cihaz bekliyor — dal `oto/P45-olcum-gecmis`: F83.1 (OTOMASYON 8. adım) + F83.2 (`tool/perf/gecmis.py`, `docs/perf/README.md`) yazıldı; F83.3 kararı sabah bakılacak (CI perf işi olduğu gibi, yalnız bayrakta); ayrıntı: KUYRUK_AYRINTI.md §P45 |
| P46 | Hız: ölçümün bulduğu yavaşlıkları düzelt | opus | HIZ_PLANI F84 + F60.S2/F60.5/F68.3 | A/B | evet | bitti — main'e birleştirildi [apk] 2026-11-13 KULLANICI KARARIYLA (cihaz A/B sonucu bu oturumda görülmedi; `Desktop/ab_P46.log` bakılacak, kötüleşme varsa madde başı commit `git revert`); S9/S18/S21/S22/S23/S25 bütçeleri düştü; cihaz maddeleri → P55 |
| P48 | Web yazı seçimi + takvim senkronu + web ek | opus | kullanıcı 2026-11-12 | cihaz (b) | evet | bitti — main'e birleştirildi [apk] 2026-11-13: web fare/klavye seçimi genişletilmiyor; yeni etkinlik varsayılanı Firestore "Tüm cihazlar" (K2 sapması kullanıcıca onaylandı 2026-11-13: etkinlik her yerde); (c) web ek üretilemedi; cihazda doğrulanmadı; ayrıntı: KUYRUK_AYRINTI.md §P48 |
| P49 | Sabit ek baştan: tasarım, tuşlar, özellikler | opus (kullanıcı 2026-11-13: tasarım bitti, kalanı Opus sürdürür) | kullanıcı 2026-11-12 | A/B | evet | bitti — bulut 2026-11-13, main'e [apk]: (a) tek ⋮ levhası (görünüm anahtarı, balonlar, PDF işleri, ek işleri, Kaldır); (b) ✏ hep görünür, yüzen kalemle senkron (`onPenOff`); (c) bölme kalemi açıkken çubukta silgi/geri al/yinele/ayar; (d) ipuçları kalem tepsisinin üstünde (`SnackBarObstacle`), oturumda durum başına bir kez; (e) klavye kasması S17 düştü; (f) F65.1 K-O6 dar çubuk + F65.2 K-O7 (kullanıcı kararı: geniş yatay pencerede seçilmemişse ek solda), F65.3 K-O8 en güvenli = tek sabit ek, sabah bakılacak; (g) 360/393 dp × 1,3 yazı taşmaz (bekçi `pinned_bar_redesign_test`); cihaz A/B YAPILMADI (bulut, telefon yok) — cihaz bekliyor, KALANLAR L7–L9 |
| P50 | Düzenleme modu baştan + hızlı menü | fable (limit %55 üstü → opus) | kullanıcı 2026-11-12 |  | evet | sürüyor — dal `oto/P50-duzenleme` (489cfe09) BİTTİ, CI yeşil: düzenleme modu anında uygular (Geri al/Bitti), alt çubukta kapsüller arası taşıma, üst çubuk sarmaları gizlenebilir; editöre dokundu → KALAN: cihaz A/B, sonra [apk] birleştir; ana ekran sarmaları (P56 çiti) ve üst çubuk sırası (P20) yapılmadı; DEVIR.md dalda |
| P38 | Hareket ve dokunsal dil | opus | DENEYIM F77.1–F77.4 | A/B | evet | cihaz bekliyor — dal `oto/P38-hareket` (42ec637e) BİTTİ (kısmen), CI yeşil: `AppHaptics` + 53 çağrı göçü, eksik haptikler, `toggle_pop`; P55/P56 çitindeki dosyalarda 35 çağrı + editör pop'u kaldı (DEVIR.md); KALAN: cihaz A/B → [apk] birleştir, sonra kalan göç |
| P20 | Editör çekirdeği | fable | Faz 64 | A/B | evet | bekliyor — P49 ve P50 BİTTİKTEN sonra; onların editör bloklarını AYNEN taşır; ayrıntı: KUYRUK_AYRINTI.md §P20 |
| P41 | Belirteç göçü | sonnet | DENEYIM F72.6 |  |  | bekliyor — P22'den önce, açık dal yokken (mekanik; editör hariç); kapanış toparlaması P53'te; ayrıntı: KUYRUK_AYRINTI.md §P41 |
| P22 | SON PAKET: açıkta kalan maddeler | opus | kalan `[ ]` maddeler | gerekirse | gerekirse | bekliyor — kalan `[ ]` maddeler + taşınanlar listesi ayrıntıda; ayrıntı: KUYRUK_AYRINTI.md §P22 |
| P53 | BÜYÜK TOPARLAMA: tek plan, tek kontrol listesi | opus | kullanıcı 2026-11-12 + F69.4/5, F58.1/4 |  |  | bekliyor — EN SON (P22'den sonra); protokol ayrıntıda; ayrıntı: KUYRUK_AYRINTI.md §P53 |

**SIRA (kullanıcı 2026-11-13): P55 + P56 EN ÖNDE** (kasma/titreme/akıcı açılmama kökten çözülecek). **SIRA (kullanıcı kararı 2026-11-12):** HIZ önce: P39 → P43 → P45 → P46. FABLE sonra: P36 → P39 → P49 → P50 → P20; sonra Opus/Sonnet: P37 → P38 → P40 → P48 → P42 → P41 → P22 → P53 (EN SON). Fable paketi yalnız 5 saatlik limit %55 altındayken başlar; üstündeyse sıradaki Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince EN BAŞTA alınır. P20 yalnız P33 bitmişse. P41 yalnız Kuyruk'ta `sürüyor`/`bulutta:` satırı yokken.

Paket protokolleri (P22, P53, P33–P42 = `DENEYIM_PLANI.md` kuralları: K-D kararları verildi, kapsam çiti Ek D, `istek_tara.py`, "Atlananlar") ve satırların tam metni: **`KUYRUK_AYRINTI.md`**; alt ajana paketin ayrıntı bölümünü de ver.
