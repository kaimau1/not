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
   yürütücü verir. **Hız hissi / açılış / yükleme / akıcılık paketlerinde (P39 ve benzeri;
   kullanıcı kararı 2026-11-12) eşik %20 DEĞİL: hiçbir evre kötüleşmez, hedef evre ölçülebilir
   iyileşir.** Kötüleşme çıkarsa paket çöpe gitmez: maddeler ayrı commit'tir (DEVIR'de madde →
   commit), şüpheli commit'i çıkarıp yeniden ölç, kötüleştireni `git revert` et + maddeye
   "iyileşme kanıtlanamadı", iyi maddeleri yeniden ölçüp birleştir.
   Bir evrede UI ms ya da LAYOUT ms %20'den fazla kötüyse birleştirme YOK:
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
- **Hız hissi işi (kullanıcı kararı 2026-11-12):** kötüleşme kabul edilmez, her değişiklik
  ölçülebilir iyileşme getirir (önce/sonra kanıtı DEVIR'e); kanıtlanamayan değişiklik yapılmaz.
  Her madde AYRI, bağımsız commit (kötüleşen tek başına geri alınabilsin). Sık ara commit + push.
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

Biten paketler (38): P01, P02, P03, P04, P05, P06, P07, P08, P11b, P09, P10, P11, P12, P13, P14, P23, P24, P25, P26, P27, P28, P15, P16, P17, P29, P30, P31, P32, P18, P19, P33, P34, P35, P36, P37, P47, P40, P42 — ayrıntı git geçmişinde (`git log -S '| P01 |' -- OTOMASYON.md`).

| No | Paket | Model | Plan maddeleri | Cihaz | APK | Durum / sonuç |
|---|---|---|---|---|---|---|
| P39 | Hız hissi (açılış, yeni not, yükleme hâlleri) | fable | DENEYIM F78.1–F78.5 | cihaz | evet | sürüyor — dal oto/P39-hiz-hissi yazıldı (CI yeşil), main birleşti; kalan: cihaz A/B (APK'lar hazır, DEVIR.md) + birleştirme |
| P43 | Hız: tek komutla tam ölçüm + otomatik karar + altın taban + cihazsız bekçiler (P44 katıldı, tek ajan) | opus | HIZ_PLANI F81.1–F81.5 + F82.1–F82.3 | cihaz | | bekliyor — önce F82 (cihazsız bekçiler S18–S25, kasma kalıpları, uzun oturum), sonra F81 (cihazda ölçüm + altın taban); senaryolara "sabit görsel/PDF + klavye aç/kapa" evresi de girer (kullanıcı 2026-11-12; düzeltmesi P49'da — sabit ek dosyasına tek paket dokunsun); OTURTMA F68.4 kaydırma kabulü ölçümü (`ab_liste.py`) de burada (P22'den alındı) |
| P45 | Hız: her [apk]'da ölçüm + geçmiş + CI kare ölçümü kararı | sonnet | HIZ_PLANI F83.1–F83.3 | cihaz | | bekliyor |
| P46 | Hız: ölçümün bulduğu yavaşlıkları düzelt | fable (limit %55 üstü → opus) | HIZ_PLANI F84.1–F84.3 + OTURTMA F60.S2, F60.5, F68.3 (P22'den alındı: klavye birikim kasması, yazma ana bloğu, liste akışı K-O13) | A/B | evet | bekliyor — `pinned_media_pane.dart`'a DOKUNMAZ: sabit ek + klavye kasması P49'da (aynı dosya iki kez değişmesin); ölçüm sabit ekte yavaşlık bulursa bulguyu P49 satırına yaz |
| P48 | Web yazı seçimi + takvim senkronu (tek ajan) | opus | kullanıcı 2026-11-12: (a) "webte yazı seçerken sorunlar var, yazı tipiyle alakalı olabilir"; (b) "telefonda eklediğim takvim etkinlikleri tablette görülmüyor, tablette eklediklerim telefonda görülüyor; webde de aynı" | cihaz (b) | evet | bekliyor — (a) önce webde üret (seçim nereden başlıyor, vurgu hizası, yazı tipi/`height`/`StrutStyle`); P47'nin jest kapatması tahmindi, kök neden değil. (b) `calendar_repository.dart` `users/{uid}/events` okuma/yazma iki yönde aynı görünüyor (P47'de bakıldı); kanıt: telefonda ekle → Firestore'da belge var mı, `uid` aynı mı, bekleyen yazma mı, Google Takvim kaynaklı mı. Kök neden kanıtlanmadan düzeltme yok. (c) OTURTMA F65.6 web'de ek görünmüyor / paylaşılan notta ek (P22'den alındı; web + senkron, aynı ajan) — ekin görünüşüne değil yükleme/okuma yoluna dokunur, sabit ek çubuğu P49'un |
| P49 | Sabit ek baştan: tasarım, tuşlar, özellikler | fable (limit %55 üstü → opus) | kullanıcı 2026-11-12: "sabit ek tasarımı, tuşları, özellikleri fable baştan yazdır" | A/B | evet | bekliyor — BAŞTAN TASARIM (yama değil): önce mevcut sabit ek çubuğu/bölmesinin bütün düğmelerini ve özelliklerini (görsel, PDF, video, ses, balon, kalem, yerleşim üst/sol/sağ, sığdır, tam ekran) dök, DENEYIM §2 diliyle yeni düzen öner ve uygula. Kesin istekler: (a) ⋮ ile "sayfalara göz at" menüleri TEK ⋮ menüde; kart düğmesi bizim stilde, yer açılır; (b) yüzen kalem düğmesi ↔ paneldeki kalem TAM senkron (yüzenden açınca paneldeki kayboluyor, panelden açınca yüzen bilmiyor); (c) paneldeki kalem açılınca silgili hızlı kalem menüsü; (d) "kalem yazar, parmak dokunur" gibi ipuçları alt kalem panelini KAPATMASIN, sürekli çıkmasın. (e) SABİT EK + KLAVYE KASMASI (kullanıcı 2026-11-12: "sabit ek varken klavye açılırken hem sabit ek paneli hem klavye kasıyor"; P46'dan alındı, senaryo P43'te): yeni tasarım kasma listesi §6–§7'ye uysun, A/B'de bu evre ölçülsün. (f) P22'den alınanlar (hepsi sabit ek): OTURTMA F65.1 bölme çubuğu sadeleşmesi (K-O6 — bu paketle açıldı), F65.2/F67.5 yatayda yandan sabitleme varsayılanı (K-O7), F65.3 birden çok sabit ek (K-O8); K-O7/K-O8 için en güvenli seçenek + "sabah bakılacak". (g) P42 kalanı: sabit PDF çubuğu 1,3× yazıda ve 360/393 dp'de taşıyor. KORU: P47 ("T" kalktı, balon gizle/göster balon menüsünde, `kPinnedSideMinWidth` 560), P39 F78.3(b) bölmenin içindeki yükleme hâli. `pinned_media_pane.dart`, `ViewerPen`, P15. Önce `istek_tara.py` |
| P50 | Düzenleme modu baştan: her şey düzenlenebilsin + hızlı menü | fable (limit %55 üstü → opus) | kullanıcı 2026-11-12: "düzenleme modunu fable yaptır her şey düzenlenebilsin"; "hızlı menü ve hızlı menüyü düzenle üzerine çalışılmalı, şu an normal düzenleme modunu açıyor" | | evet | bekliyor — (a) düzenleme modu (Ekranı/Menüyü düzenle, `customizable.dart`, `UiItem`): ekranda görünen HER düğme/alan gizle/göster/sırala (eksik `Customizable` sarmalarını dök, tamamla); (b) "Hızlı menüyü düzenle" genel düzenleme modunu değil hızlı menünün kendi düzen kipini açsın (P28 "+" paneli düzen kipiyle birleşik dil). Kasma listesi §3–§4: düzen kipi kök `setState` değil, ağaç şekli değişmesin. P49'DAN SONRA: sabit ek çubuğunun `Customizable` sarmalarını P49 yapar, P50 `pinned_media_pane.dart`'a dokunmaz; editör `note_editor_screen.dart` yapısı P20'nin (P50 yalnız sarmalar) |
| P38 | Hareket ve dokunsal dil | opus | DENEYIM F77.1–F77.4 | A/B | evet | bekliyor — P47 çöp sürüklemesindeki `HapticFeedback` ve sıra donması (`_previewCardDrop`) korunur, yalnız `AppHaptics`e sarılır |
| P20 | Editör çekirdeği (başlama şartı tutuyorsa) | fable | Faz 64 | A/B | evet | bekliyor — P49 (sabit ek) ve P50 (düzenleme modu) BİTTİKTEN sonra; onların editördeki bloklarını AYNEN taşır |
| P41 | Belirteç göçü | sonnet | DENEYIM F72.6 | | | bekliyor — P22'den önce, açık dal yokken (mekanik; editör klasörü hariç). Kapanış toparlaması P53'e taşındı (2026-11-12) |
| P22 | SON PAKET: açıkta kalan her maddeyi değerlendir ve uygun biçimde yap | opus | Kalan açık `[ ]` maddeler (2026-11-12 ayıklandı): kalem/mürekkep F61.7, F61.8, F62.4, F62.6, F63.6, F63.7 · tablet F67.6, F67.8 · F66.5 (yalnız rapor) · F68.5 (park) · cihaz turu F69.1–F69.3 · P40'ın "sabah bakılacak"ları (Gelen süzgeci hata hâli, AI levhası çevrimdışı, bekleyen ek şeridi). BAŞKA PAKETE TAŞINDI, burada YAPILMAZ: F58.1/F58.4 → P53, F60.5/F60.S2/F68.3 → P46, F68.4 → P43, F65.1/F65.2/F65.3/F67.5 → P49, F65.6 → P48; F60.7, F66.1–3 zaten kapandı (Ek D) + "cihazda doğrulanmadı" / "tablette doğrulanmadı" işaretli maddeler + açık K-O kararları | gerekirse | gerekirse | bekliyor — protokol aşağıda |
| P53 | BÜYÜK TOPARLAMA: tek plan, tek kontrol listesi | opus | kullanıcı 2026-11-12: "bitmişleri sil, eski planları tamamen toparla, tek plana indir, kafa karışıklığı olmasın; benim kontrol etmem gerekenleri madde madde, anlayacağım şekilde bir dosyaya yaz; diğerlerini grupla, kaldır; HAFIZA, CLAUDE.md dahil toparla, main'e gönder" + F69.4, F69.5 (eski P21) + OTURTMA F58.1, F58.4 | | | bekliyor — EN SON (P22'den sonra). Protokol aşağıda (P53 protokolü) |

**P22 protokolü (kullanıcı isteği 2026-11-10):** P01–P21 bitince `OTURTMA_PLANI.md`'yi baştan tara; `[ ]` kalan HER maddeyi otomatik değerlendir, soru sorma. Her madde için sırayla: (1) kanıtla — kod/test/ölçümle hâlâ geçerli mi, başka işle kapanmış mı; (2) kapanmışsa `[x]` + tek satır kanıt, gereksizse `[~]` + neden; (3) geçerliyse kendi modeli neyse ona uygun işle: kısa maddeleri kendin yap, Fable gerektirenleri (güvenlik/performans/editör/kalem) `Agent` ile `model: "fable"` alt ajana ver, mekanik olanları `sonnet` alt ajana; (4) KARAR çıkarsa plandaki "En güvenli" seçenek + maddeye "sabah bakılacak"; (5) telefon/tablet/hesap gerektirenler yapılamaz → "yazıldı, cihazda doğrulanmadı" + `KALANLAR.md` §2'ye adım. Kullanıcı işi olanları (konsol, hesap, telefon) yapma, yalnız `KALANLAR.md`'ye topla. Küçük commit'ler, CI yeşilse `[apk]`; sonunda plan Durum tablosu + HAFIZA güncelle ve geriye kalanın dürüst listesini yaz.

**P53 protokolü (kullanıcı isteği 2026-11-12):** bütün P'ler (P22 dahil) bitince, EN SON. Kod yazmaz, yalnız belge toparlar; veri/kanıt kaybetmez (silinen her şey git geçmişinde ve arşivde kalır). Sırayla:
1. **Tek plan — `PLAN.md`:** bütün plan dosyalarını (`OTURTMA_PLANI`, `DENEYIM_PLANI`, `HIZ_PLANI`, `KALAN_ISLER_PLANI`, `YOL_HARITASI`, `PERFORMANS_TOPARLAMA_PLANI`, `KULLANICI_DENEYIMI_PLANI`, `AKICILIK_PLANI`, `TEMA_PLANI`, `TUTARLILIK_PLANI`, `TAKVIM_PLANI`, `YORUM_ANALIZI_PLANI`, `KALEM_PLANI`, `KALANLAR.md`) madde madde tara. `[x]` bitmişler PLAN'a GİRMEZ. Açık kalan her madde PLAN.md'de tek satır, üç gruptan birinde: **(A) Senin yapacakların** (aşağıdaki listeye işaret), **(B) Bekletilenler / park** (neden + hangi kararla), **(C) Açık kod işi** (varsa; model + kısa kapsam). Her satırın sonunda eski kimliği (ör. `F65.6`) dursun ki geçmişe bakılabilsin.
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
