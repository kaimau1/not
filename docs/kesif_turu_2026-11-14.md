# Keşif turu — 2026-11-14 (P61)

Yalnız bulma + belgeleme; koda dokunulmadı. Ekran görüntüleri: `docs/kesif_turu/` (12 küçük PNG, ~0,8 MB).

## Yöntem ve kapsam
- **Ekran turu** (`tool/tour/screen_tour_test.dart`, var olan bayraklarla, kod değişikliği YOK): `TOUR_SIZES` ile telefon-kucuk 360, telefon-uzun 393, tablet-dikey 800, matepad-yatay 1024, masaüstü 1440; açık (153 görüntü), koyu (`TOUR_DARK=1`, 123), yazı 1.3 (`TOUR_FONT=1.3`, 52 telefon/tablet/masaüstü), boş hâller (`TOUR_EMPTY=1`) ve çevrimdışı (`TOUR_OFFLINE=1`). Hepsi yeşil (taşma istisnası yok); görüntüler elle incelendi (kontak sayfalarıyla, hepsi tek tek değil: telefon-kucuk tam, tablet/masaüstü ana-editör-ayar-gelen-çöp).
- **Web canlı tur**: `flutter build web` (env.json içeriği yazdırılmadı) → `build/web` → `localhost:8099` → Playwright (headless Chromium) 390x844, 1024x768, 1440x900, ayrıca yeniden boyutlama 320/700/1024. Web uygulaması giriş istemeden **anonim (Yerel hesap)** açılıyor; gerçek hesap kullanılmadı, hiçbir girişe dokunulmadı. Gezilen: ana, kenar çubuğu (not/klasör/yapay zekâ/takvim/arşiv/çöp/ayarlar), hızlı ekle, filtre-süz, hesap, ⋮, klavye kısayolları (Ctrl+/ çalışıyor), ayarlar alt sayfaları (Hesap, Görünüm, Eklentiler, Notlar ve klasörler, Kalem...), kılavuz, editör yazımı (uzun metin/emoji/HTML), arama, Ctrl+Z.
- **Konsol/ağ**: 3 görünümde de `error` düzeyinde konsol iletisi YOK, sayfa hatası YOK, HTTP >= 400 YOK. Yalnız WebGL "GPU stall" uyarıları (headless) ve Firestore `Listen` kanalında `ERR_ABORTED` (normal uzun-yoklama kesilmesi). Temiz.
- **Sınırlar (dürüst)**: headless Chromium'da Flutter kanvas ağacı yalnız toast görünürken boş çıktı; bu yüzden düğme listesi DOM'dan çıkarılamadı, tıklamalar koordinatla yapıldı → her ⋮/düğme TEK TEK denenmedi (kapsanan yerler yukarıda). Tab ile gezinme için görüntü alındı ama odak halkası kanıtlanabilir bulunamadı (KT-11 olası). Mikrofon izni headless'ta yok ("Mikrofon izni verilmedi" levhası beklenen). Gerçek Google girişi, Drive/Gmail denenmedi. AI ekranındaki siyah bloklar test yazı tipi (Ahem) — hata DEĞİL.

## Bulgular

Özet: 12 bulgu — yüksek 0, orta 6, düşük 6. Tür: görsel 5, UX 4, metin 2, erişilebilirlik 1 (olası); kesin bug yok (KT-8 olası).

### KT-1 — İki toast aynı anda, ipucu arama çubuğunu örtüyor
- Yüzey: web masaüstü (ve telefon). Ekran: ana, ilk açılış. Tür: UX/görsel. Önem: **orta**.
- Adımlar: temiz tarayıcı oturumunda uygulamayı aç.
- Beklenen: tek bildirim; gelen şey arama çubuğunu kapatmasın. Gerçek: üstte "Anlam açıkken kelimeyi değil anlamı arar..." ipucu (arama kutusunun tam üstünde, onu kısmen örtüyor) ve altta 12 sn kalan "Yenilikler · v1.2.0" toast'ı aynı anda; ikisi ilk ekranı kalabalıklaştırıyor, Yenilikler toast'ı alt çubuğu da örtüyor.
- Görüntü: `docs/kesif_turu/kt01-web-masaustu-ana.png`
- Öneri: toast'ları kuyruğa al (biri bitince öbürü), ipucu masaüstünde arama kutusunun altında ya da yalnız arama odaklanınca çıksın; Yenilikler 12 sn → 6 sn.
- Dosya: `lib/app/release_notes_toast.dart` (süre 12 sn, ipucu gecikmesi 2500 ms), `lib/features/notes/presentation/dashboard_widgets.dart:558` (`tipSemanticSearch`).
- istek_tara: `release_notes_toast.dart` çelişki yok.

### KT-2 — Masaüstünde "Görünüm ve süz" levhası tüm genişliğe yayılıyor
- Yüzey: web masaüstü 1440 (tablet yatay da muhtemel). Ekran: ana → süz düğmesi. Tür: görsel. Önem: **orta**.
- Gerçek: levha 1240 px; Izgara/Liste segmenti ve çipler uzun şeritler olarak yayılıyor, göz tarama mesafesi çok uzun; oysa hesap levhası aynı ekranda ~300 px'lik kart. Tutarsız levha genişliği.
- Görüntü: `kt02-web-masaustu-suz-levhasi.png`, karşılaştırma `kt07`.
- Öneri: geniş ekranda levha için `maxWidth` ~560-640 dp, ortada ya da imleç yanında; segment tam genişlik yerine içeriğe göre.
- Dosya: `lib/features/notes/presentation/filter_sheet.dart` (`showAppSheet`, satır 33), `showAppSheet` tanımı (`lib/core/widgets/` altında).
- istek_tara: `filter_sheet.dart` — "klasör satırı, takvim satırı gizleme... görünüm ve süz ekranına koy, daha kompakt olsun" (2026-11-10) var; daraltmak "kompakt" isteğiyle uyumlu, bölüm içeriğini kaldırmıyor. Çelişki yok.

### KT-3 — Dar pencerede (320 dp) takvim şeridi gün adları tek harfe düşüyor; FAB boş durum düğmesini örtüyor
- Yüzey: web 320 dp (telefon-kucuk 360'ta değil). Ekran: ana (boş). Tür: görsel/erişilebilirlik. Önem: orta.
- Gerçek: şeritte "C P P S Ç P C P" — Cmt/Paz/Pzt/Cum aynı harfe iniyor, ayırt edilemez; boş durumdaki "İlk notunu yaz" düğmesinin yarısı mikrofon+FAB'ın altında kalıyor.
- Görüntü: `kt03-web-320-serit-fab.png`
- Öneri: 340 dp altında gün adı yerine yalnız sayı (gün adı Semantics'te kalsın); boş durumun alt boşluğunu FAB yüksekliği kadar artır.
- Dosya: `lib/features/calendar/presentation/home_calendar_strip.dart:298` (`weekday.characters.first`), boş durum `lib/features/notes/presentation/dashboard_screen.dart`.
- istek_tara: `home_calendar_strip.dart:21` — kullanıcı "2 satır, 10 gün görünsün" demiş; gün sayısına/yüksekliğe dokunulmuyor, yalnız etiket. Çelişki yok.

### KT-4 — Yazı 1.3'te hızlı ekle levhasının başı kesiliyor
- Yüzey: telefon 360, yazı ölçeği 1.3. Ekran: ana → "+" hızlı ekle. Tür: görsel. Önem: orta.
- Gerçek: levhanın üstü ekranın üst kenarına yapışıyor, "Şablon" başlığı kenara değiyor, tutamaç yok; içerik kaydırılabilir ama ilk bakışta kesik görünüyor. (Dar etiketler "Alışveriş listesi" iki satır, ok.)
- Görüntü: `kt04-telefon-yazi130-hizli-ekle.png`
- Öneri: levha `maxHeight` = ekran - üst güvenli alan - 24 dp; üst kenarda yuvarlak köşe/boşluk bırak.
- Dosya: `lib/features/notes/presentation/quick_add_fab.dart` (levha yüksekliği).
- istek_tara: `quick_add_fab.dart` taranmadı çelişki yok (yalnız boyut sınırı).

### KT-5 — "Sabitlemeyi kaldır" kelime ortasından bölünüyor
- Yüzey: telefon 360. Ekran: sabitli not → Not menüsü. Tür: metin/görsel. Önem: düşük.
- Gerçek: "Sabitlemey / i kaldır" (üst sıra yuvarlak düğme etiketi `maxLines: 2`, sığmayınca kelime ortasından kırılıyor).
- Görüntü: `kt05-telefon-n4-menu.png`
- Öneri: etiketi "Sabitten çıkar" ya da "Çöz" gibi kısalt (l10n `unpin`); veya üst sıra 5 yerine 4 düğme + taşan sıra.
- Dosya: `lib/l10n/app_tr.arb:118` (`unpin`), `lib/core/widgets/action_menu_sheet.dart:421,519`.
- istek_tara: dosya yok sayılabilecek metin değişikliği; çelişki yok.

### KT-6 — Çevrimdışıyken yapay zekâ levhası uyarısız tüm eylemleri sunuyor
- Yüzey: telefon, çevrimdışı. Ekran: not → Yapay zekâ. Tür: UX. Önem: düşük.
- Gerçek: "Bugünkü puan 30/30", Notu düzelt/özetle/analiz/çevir/geliştir normal görünüyor; bağlantı yokluğu yalnız basınca anlaşılıyor (Çöp/Gelen "Bağlantı yok" gösteriyor, tutarsız).
- Görüntü: `kt06-telefon-cevrimdisi-ai.png`
- Öneri: levha tepesinde "Bağlantı yok — yapay zekâ çevrimiçi çalışır" şeridi, eylemler soluk.
- Dosya: `lib/features/ai/presentation/ai_sheet.dart`, `lib/features/ai/data/ai_gate.dart`.
- istek_tara: çelişki yok.

### KT-7 — Hesap levhasında metinler kesiliyor
- Yüzey: web telefon 390. Ekran: ana → profil simgesi. Tür: metin/görsel. Önem: düşük.
- Gerçek: "Notların yalnız bu cihazda. Google hesabı bağlarsan yedeklenir ve arkada…" ve Premium "Ücretsiz sürümü kullanı…" tek satıra sığmayıp "…" ile bitiyor; kullanıcı asıl bilgiyi (yedeklenir ve arkadaşlarla paylaşabilirsin) okuyamıyor.
- Görüntü: `kt07-web-telefon-hesap-levhasi.png`
- Öneri: `maxLines: 1` → 2 (ya da 3).
- Dosya: `lib/features/auth/presentation/account_sheet.dart:174-184` (`maxLines: 1` + ellipsis).
- istek_tara: çelişki yok.

### KT-8 — Masaüstü editörde "Geri alındı" çubuğu tüm genişlikte; Ctrl+Z tüm yazımı tek adımda siliyor
- Yüzey: web masaüstü. Ekran: yeni not → uzun yazım → Ctrl+B, Ctrl+Z. Tür: UX/bug-olası. Önem: orta (veri kaybı hissi).
- Gerçek: ~500 karakterlik yazım tek Ctrl+Z ile tamamen silindi (kullanıcı geri almak için Ctrl+Y/Yinele zorunda; yineleme düğmesi var, geri gelir) ve altta 1300 px'lik koyu bir çubuk. Geri alma adımı ayrıntısı belirsiz; yazım paketleri çok büyük olabilir.
- Görüntü: `kt08-web-masaustu-geri-alindi.png`
- Öneri: yazı geri alma adımını kelime/duraklama (örn. 1,5 sn) bazlı böl; snackbar'a `width: 360` + ortalı/`behavior: floating` ver.
- Dosya: editör geri alma yığını (`lib/features/notes/presentation/editor/` altında `undo` ara), snackbar sarmalayıcı.
- istek_tara: editör dosyaları, çelişki ancak somut dosya seçilince taranmalı — **doğrulanmadı** (headless'ta Ctrl+B etkisi de karışmış olabilir; cihazda yeniden dene).

### KT-9 — Boş durumlar tutarsız: Klasörler boş durumu sol-üst hizalı, Ana/Arşiv/Çöp ortalı
- Yüzey: web masaüstü, tablet. Ekran: Klasörler. Tür: görsel/UX. Önem: düşük.
- Gerçek: "Henüz klasör yok..." tek satır, sol üstte; başka boş ekranlar simge + başlık + açıklama + eylem düğmesi ile ortalı.
- Görüntü: `kt09-web-masaustu-klasorler-bos.png`, karşılaştırma `kt12-telefon-bos-hal.png`.
- Öneri: aynı `EmptyState` bileşeni (simge + "Yeni klasör" düğmesi).
- Dosya: `lib/features/folders/` klasör ekranı (Grep: `folderEmpty`/"Henüz klasör yok" l10n).
- istek_tara: çelişki yok (görünüş tutarlılığı TUTARLILIK planı ile uyumlu).

### KT-10 — Ayarlar > Hesap sayfası: "Not kilidi" Hesap başlığı altında, ayrı bölümde değil
- Yüzey: web masaüstü. Ekran: Ayarlar → Hesap. Tür: UX/görsel. Önem: düşük.
- Gerçek: Hesap detayında hesap bilgisi, çıkış, silme, gizlilik, sürüm ve sonra aniden "Not kilidi" (parmak izi/şifre/desen) ve "Uygulama kilidi"; başlık "Hesap" iken kilit güvenlik ayarı. Sol liste ile detay arasında ~150 px boş boşluk (detay 690 px ortalanmış).
- Görüntü: `kt10-web-masaustu-ayarlar-hesap.png`
- Öneri: "Güvenlik ve kilit" ayrı kategori; detay bölmesini listeye yasla.
- Dosya: `lib/features/settings/presentation/` (Grep: `noteLock`/`Not kilidi`).
- istek_tara: çelişki kontrolü gerekir (ayar yeri taşıma) — yapmadan önce çalıştır.

### KT-11 — Toast görünürken erişilebilirlik ağacında yalnız toast var (olası)
- Yüzey: web. Tür: erişilebilirlik. Önem: orta-olası (doğrulanmadı).
- Gerçek: semantik ağaç dökümünde toast açıkken yalnız tam ekran bir `group` (0,0,1440x900) + toast düğmesi görünüyor; uygulamanın geri kalanı yok. Ekran okuyucu için 12 sn boyunca arayüz gizli olabilir; headless'ta Flutter semantiği geç kurulduğu için kesin değil.
- Öneri: toast sarmalayıcısına `Positioned.fill` yerine yalnız kendi alanı; `Semantics(container: true)` olmasın; gerçek ekran okuyucuyla (NVDA/TalkBack) doğrula.
- Dosya: `lib/app/release_notes_toast.dart`.
- istek_tara: çelişki yok.

### KT-12 — Yazı 1.3'te arama kutusu ipucu ve bazı adlar kırpılıyor
- Yüzey: telefon 360, yazı 1.3. Ekran: ana, Klasörler. Tür: görsel. Önem: düşük.
- Gerçek: "Notlarda ar..." ve "Ortak i…", "Hepsi tamam ..." kırpılıyor; çipler yatay kaydırmada "Dua" gibi yarım kalıyor (1.0'da da yarım çip kaydırma ipucu, yeterli).
- Görüntü: `kt11-telefon-yazi130-ana.png`
- Öneri: arama ipucu "Ara..." (kısa), klasör kartı adı `maxLines: 2`.
- Dosya: `lib/l10n/app_tr.arb:14` (`searchHint`), `lib/features/folders/` klasör kartı.
- istek_tara: çelişki yok.

## Temiz çıkanlar (bulgu yok)
Koyu temada okunabilirlik (işaretli madde metni ölçülen kontrast ~8,7:1), ana/editör/menü/ayarlar tüm 9 boyutta taşma yok, Ctrl+/ kısayol levhası çalışıyor ve düzenli, konsol/ağ temiz, boş hâl metinleri doğru Türkçe, çevrimdışı şeritleri ("3 ek buluta yükleniyor") anlaşılır.

## Kendimiz karar verip yapabileceklerimiz
1. KT-7 `maxLines` 1→2 (hesap levhası).
2. KT-5 "Sabitlemeyi kaldır" kısalt / `Sabitten çıkar`.
3. KT-3 340 dp altı gün adını gizle, boş durum alt boşluğu.
4. KT-4 hızlı ekle levhası `maxHeight` + üst boşluk.
5. KT-9 Klasör boş durumunu ortak bileşene çevir.
6. KT-12 `searchHint` kısalt, klasör adı iki satır.
7. KT-6 çevrimdışı AI şeridi.
8. KT-1 toast kuyruğu (ikisi aynı anda çıkmasın).

## Kullanıcı zevkine kalanlar
1. KT-2 masaüstü levha genişliği/konumu (ortada mı imleç yanında mı).
2. KT-10 Not kilidi'nin ayrı "Güvenlik" kategorisine taşınması + detay bölmesi hizası.
3. KT-8 geri alma adımı ayrıntısı (kelime mi duraklama mı) ve snackbar biçimi.
4. KT-1 ipucu toast'ının masaüstünde yeri/sıklığı.
5. Masaüstü editörde metin sütununun solda mı ortada mı durması (1440'ta metin sola yaslı, sağda büyük boşluk; ayar ya da "okuma genişliği" isteği olabilir).
6. Takvim şeridi tipografisi (14 Kas etiketleri çok küçük, ~9 sp; okunurluk ile iki satır sözü arasında denge).


---

# Tablet canlı turu — 2026-11-18/19 (T16, KT-13…)

Cihaz: HUAWEI MatePad 11 (1600x2560 @ 400 dpi = 640x1024 dp dikey / 1024x640 dp yatay), fiziksel klavye ("HUAWEI MatePad Keyboard") takılı, GMS'siz, sistem karanlık. Uygulama: ölçüm kimliği `dev.kaimau.notlar.olcum` (profil, misafir veri; asıl uygulamaya yalnız açılış/gezinti denetimi yapıldı), dal `oto/T16-tablet-turu` = main dd55fb09 birleşimi. Yön `wm user-rotation lock 0|1` ile sabitlendi (iş bitince `free`).
Yöntem: `tool/perf/tur_gez.py` (uiautomator etiketleriyle gezinti + 0,3 ölçekli ekran görüntüsü; ana ekran semantiği boşken `ab_hepsi.home_locate`), her görüntü elle incelendi. Gezilen: ana, "+" paneli, Süz, Uygulama ⋮, Anlam, hesap, kart ⋮, takvim şeridi, Klasörler, Yapay zekâ, Takvim, Arşiv, Çöp, Ayarlar + 6 alt sayfa, liste notu editörü + not menüsü + ⌨, sabit PDF, Şablonlar, kalem kipi; **dikey, yatay (ana-detay/bölünmüş) ve koyu tema (Koyu)**. Görüntüler: `docs/kesif_tablet_2026-11-18/` (19 küçük PNG, ~0,55 MB). logcat (dikey tur boyunca) `FATAL/ANR/E-flutter` YOK.
**Yapılamayanlar (dürüst):** M-Pencil/kalem davranışı (adb kalem türü üretmez), 1 GB PDF, gerçek TalkBack, sesle yazma (mikrofon izni istenince REDDET verildi), K32 "Yanda aç" (aşağıdaki KT-13 engelledi), ayraç sürükleme, 120 Hz paneli, web (başka ajan).

Özet: 12 bulgu — **yüksek 1, orta 3, düşük 8**.

### KT-13 — Yatayda sabit liste notunun kartına (gövde) dokununca uygulama arka plana gidiyor
- Yüzey: tablet YATAY (2560x1600), ölçüm kimliği (release'te denenmedi). Ekran: ana → ilk kart "Kitap bilet" (sabit, liste notu). Önem: **yüksek** (çökme gibi, veri kaybı yok).
- Adımlar: `wm user-rotation lock 1`, uygulamayı aç, 8 sn bekle, kartın MERKEZİNE dokun (477,941). Gerçek: not açılmıyor, uygulama `moveTaskToBack` ile arka plana gidiyor (logcat: `ActivityTaskManager: moveTaskToBack: Task{… dev.kaimau.notlar.olcum …}`, çökme/FATAL yok; 3/3 tekrar). Aynı kartın ⋮ yakınına (514,965) dokunmak notu normal açıyor. Dikeyde aynı merkez dokunuşu normal açıyor.
- Olası kök: yatay bölünmüş kabukta not açılırken rota "geri alacak şey yok" diyor ve Flutter `SystemNavigator.pop()` çağırıyor (`lib/app/app.dart:120-165` `alwaysHandleBack` yorumu); not açma yolu `lib/app/router.dart:88-140` (`NoteRoutePush`) + `lib/app/split_shell.dart` (`_closing`/`_lastNoteId`). Doğrulanmadı.
- Öneri: 1024x640 dp widget testi (kart merkez/kenar/⋮ dokunuşları; `router` konumu + `SystemNavigator.pop` sayacı) ve karta özgü bir yol (ör. kartın içindeki onay kutusu/satır dokunuşu) araması; K32 "Yanda aç" turu bu düzeltmeye bağlı.
- Görüntü: `kt-yatay-01-ana.png` (kart yeri).

### KT-14 — Tablet ana ekran ve ray erişilebilirlik ağacında yoktu (d822538f); birleşik derlemede ilk dökümde dolu, durağanken yine boşalabiliyor
- Yüzey: tablet dikey+yatay. Önem: **orta** (TalkBack ile doğrulanmadı).
- Gerçek: uiautomator dökümünde ana ekran + ray 3,4 KB boş `View` zinciri (`ray`, arama, kartlar yok); levha/editör/ayarlar dolu; telefon düzeninde (`wm size 1080x2400`) dolu. main'de PW-A KW-1 (b2d9a878, Navigator `BlockSemantics` sınırı) bunu düzeltmiş: birleşik derlemede soğuk açılışta ana ekran 49 etiket ("Notlar | Sekme 1 / 7"), ama notlardan dönüşten/boşta bir süre sonra döküm yine boş çıkabiliyor (UiAutomation yalnız ~1 sn bağlanıyor; boşta Flutter tam ağacı göndermiyor olabilir → TalkBack sürekli bağlı olduğundan farklı). "Düzenleme modu" üst bandı da (Geri al · Bitti) dökümde yoktu (görüntüde var).
- Öneri: gerçek TalkBack ile tablet ana ekranı + düzenleme modu bandı; `web_semantics_home_test` benzeri 640x1024 ve 1024x640 dp semantik testi. Ölçüm aracı bu yüzden tablet ana ekranında piksel tablosuna (`GEO_1600`) ve ilk döküme dayanıyor (tool/perf/README).
- Görüntü: yok (döküm).

### KT-15 — Yatay bölünmüşte yüzen kalem düğmesi "Ara başlık" eylemini örtüyor
- Yüzey: tablet yatay, editör sağ bölmesi. Ekran: liste notu → "Yeni madde / T Ara başlık" satırı. Önem: **orta** (eylem yarı örtülü: "Ara ba…").
- Gerçek: sağ kenardaki yuvarlak kalem düğmesi (editörün yüzen "Kalemle yaz") satırın sağındaki "Ara başlık"ı kesiyor; dikeyde aynı düğme satırın altında kalıyor.
- Dosya: `lib/features/notes/presentation/editor/note_editor_screen.dart` (yüzen kalem düğmesi konumu; `quickRowPen`), "Yeni madde/Ara başlık" satırı.
- Öneri: düğmenin sağ boşluğunu (satır `padding.end`) düğme genişliği + 8 dp yap ya da düğmeyi satır yüksekliklerinin dışına al.
- Görüntü: `kt-yatay-03-bolunmus-editor.png`.

### KT-16 — "Kalem kipi · Yalnız kalemle yaz: açık [Ayarla]" bildirimi kalem tepsisini örtüyor
- Yüzey: tablet dikey (+ yatayda liste bölmesinin altı). Ekran: not → "Kalemle yaz". Önem: **orta** (tepsi ~4 sn tıklanamaz).
- Gerçek: alt-solda koyu bildirim kalem tepsisinin sol yarısını (renk/kalem seçici) örtüyor; yatayda liste bölmesinin altında kalıyor (örtmüyor).
- Dosya: `note_editor_screen.dart:2520` (`penModePenOnlyOn`), toast yeri; ilgili KT-1/P72 toast kuyruğu.
- Öneri: toast'ı kalem tepsisinin ÜSTÜNE (tepsi yüksekliği kadar `bottom` boşluğu) koy; kalem kipinde bu bilgi yerine tepsideki simge/ipucu.
- Görüntü: `kt-dikey-11-kalem-kipi-toast.png`, `kt-yatay-06-kalem-tepsisi.png`.

### KT-17 — Liste bölmesinde "+" ve "↑" düğmeleri kart içeriğini örtüyor
- Yüzey: tablet yatay, bölünmüş (not açık). Önem: düşük. Gerçek: sol bölmenin sağ altındaki yüzen "+" ve (kaydırınca) "↑" kartın tarih/etiket satırını örtüyor ("18 Kas" görünmüyor); dar liste bölmesinde (~330 dp) orantısız büyük.
- Öneri: bölünmüşte düğmeleri küçült (mini FAB) ya da listeye alt boşluk (`bottom: 88`).
- Görüntü: `kt-yatay-04-bolunmus-pdf.png`.

### KT-18 — Editörde ⌨ düğmesi odak yokken tek başına klavye açmıyor, durumu belirsiz
- Yüzey: tablet + fiziksel klavye. Önem: düşük. Gerçek: fiziksel klavye takılıyken alana dokunmak sanal klavyeyi açmaz (bilerek, `HardKeyboard`); ⌨ AÇ/KAPA anahtarı: alan odakta değilken basınca simge "gizle"ye döner ama klavye gelmez; ⌨ açıkken sonraki alan dokunuşları klavyeyi açar, BACK klavyeyi kapatır ama anahtar "açık" kalır (sonraki ⌨ dokunuşu KAPATIR → "iki kez bastım, açılmadı").
- Dosya: `note_editor_screen.dart:5480-5500` (`HardKeyboard.softWanted`/`toggleSoft`).
- Öneri: BACK klavyeyi kapatınca `softWanted=false`; odak yokken ⌨ önce odaklasın.
- Görüntü: yok.

### KT-19 — Ana ekranın tepesinde iki bant + şerit + çipler ilk notu ~%25 aşağı itiyor
- Yüzey: tablet dikey. Önem: düşük. Gerçek: "Yeni sürüm var" bandı (eski sürümde) + "Notların yedeklenmiyor" bandı + takvim şeridi + klasör çipleri; ilk kart y≈650 px'te (2560'ta). Misafir + eski sürümde her açılışta bu yığın var.
- Öneri: bantları tek satırda birleştir ya da güncelleme bandını yalnız Ayarlar'da göster.
- Görüntü: `kt-dikey-01-ana.png`.

### KT-20 — Dikey tablette alt levhalar tam genişlikte, içerik seyrek
- Yüzey: tablet dikey (640 dp). Önem: düşük. Gerçek: "Uygulama" levhası, kart ⋮ levhası, "Görünüm ve süz" 640 dp'ye yayılıyor (Izgara/Liste segmenti, 5 yuvarlak düğme arası ~100 dp); KT-2 kuralı (en çok 560 dp, ortada) yatayda çalışıyor (`kt-yatay-02`), dikey tabletlerde yalnız ≥ 600 dp penceresinde görsel olarak "dolu" değil.
- Öneri: levha `maxWidth` 560'ı ≥ 600 dp'de dikey tablete de uygula (yatayla aynı kural).
- Görüntü: `kt-dikey-03-suz-levhasi.png`, `kt-dikey-04-uygulama-menusu.png`.

### KT-21 — Ölçüm kimliğinde her açılışta widget ve FCM istisnaları (yutuluyor)
- Yüzey: profil/ölçüm kimliği, GMS'siz tablet. Önem: düşük (kullanıcıya görünmez). Gerçek: logcat `flutter: Widget güncellenemedi: PlatformException(-3, No Widget found with Name TodayWidgetProvider… Didn't find class "dev.kaimau.notlar.olcum.TodayWidgetProvider"` ve `NotlarWidgetProvider` (home_widget sınıf adını applicationId'den kuruyor; `.olcum` ekinde sınıf yok); `FCM başlatılamadı: MISSING_INSTANCEID_SERVICE` (GMS yok). İkisi try/catch'te.
- Öneri: home_widget çağrılarında tam nitelikli sınıf adı (`qualifiedAndroidName: 'dev.kaimau.notlar.TodayWidgetProvider'`); iki günlük satırını `debugPrint` altına al (release günlüğünü kirletmesin).

### KT-22 — "Tepeden aşağı çekince" jesti hızlı başa dönmede klasör menüsünü açıp sonraki dokunuşu yutuyor
- Yüzey: tablet dikey, U1 varsayılanı (Klasörler). Önem: düşük. Gerçek: listeyi başa almak için art arda aşağı kaydırınca (en üstte aşırı kaydırma) klasör hızlı menüsü ("Tümü/Klasörler/Gelen", "Yeni klasör", "Sırala - sil") açılıyor; menü açıkken ilk dokunuş menüyü kapatıp eylemi yutuyor (ölçüm turu 3 koşuyu bozdu; ölçüm uygulamasında jest "Hiçbiri" yapıldı).
- Öneri: jest eşiği (çekme ≥ ~96 dp ve hız < eşik) ya da menü açılmadan önce kısa titreşim/geri bildirim; Ayarlar'daki seçenek zaten var.
- Görüntü: yok (ölçüm sırasında görüldü).

### KT-23 — Takvim ay hücrelerinde olay yazısı çok küçük (dikey tablet, olası)
- Yüzey: tablet dikey, Takvim ay. Önem: düşük (olası; yalnız "Arife", "29 Ekim Bayramı" etiketleri incelendi). Gerçek: hücre ~60x120 dp ama olay çubuğu yazısı ~9–10 sp; hücrenin %90'ı boş. PW-E KW-9 (geniş ay hücresinde gün 13 / şerit 11 pt) bunu ele almış olabilir — birleşik derlemede dikey tabletle yeniden bak.
- Görüntü: `kt-dikey-06-takvim-ay.png`.

### KT-24 — ⚡ "Hızlı ekle" ilk dokunuşta mikrofon izni istiyor (açıklamasız)
- Yüzey: tablet, ray ⚡. Önem: düşük. Gerçek: "Hızlı ekle" düğmesine ilk dokunuşta sistem "mikrofona erişme izni verilsin mi?" penceresi (REDDET verildi); izin istemeden önce neden istendiği söylenmiyor; mikrofon yalnız kullanıcı mikrofona basınca istenmeli (görülen: tek dokunuş → hemen izin penceresi).
- Öneri: izni mikrofon düğmesine basılınca iste; ya da ilk kullanımda kısa açıklama levhası.

## Temiz çıkanlar (tablet turu)
Koyu tema (Koyu) ana/editör/ayarlar okunur, kontrast iyi (`kt-koyu-01/02`); yatay ayarlar ana-detay (sol liste + sağ detay) düzgün (`kt-yatay-05`); yatay "Uygulama"/kart levhası ortada ≤ 560 dp (KT-2 çalışıyor, `kt-yatay-02`); Güvenlik ayrı bölüm (KT-10 çalışıyor); Klasörler boş durumu ortak bileşen (KT-9); Şablonlar levhası düzgün (`kt-dikey-10`); Kalem ayarlarında "Parmak: Kaydır · Çiz · Sil" var (K34 ayarı görüldü); dikey↔yatay döndürmede (kilitle/serbest) çökme/taşma yok; logcat'te FATAL/ANR yok.

## Tablet geliştirme önerileri
1. **Yatay/bölünmüş ölçüm:** ölçüm (profil) APK'sının manifestindeki `screenOrientation=portrait` bir `--dart-define`/manifest anahtarına bağlansın; `ab_hepsi.py` zaten `--yon yatay` ister, yatay evre seçicileri (sol ray + liste + sağ editör) yazılmalı. Yatay taban ayrı `altin_taban_tablet.json` anahtarı (yön eki etikette var).
2. **KT-13 önce:** yatay kart dokunuşu düzelmeden K32 "Yanda aç", ayraç sürükleme ve bölünmüş ölçümler güvenilmez.
3. Bölünmüş görünümde alt kenar yüzenleri (liste "+" / "↑", editör kalem düğmesi, toast) için tek "güvenli alt boşluk" kuralı (KT-15/16/17).
4. Fiziksel klavye ipuçları: ⌨ durumunu açık göster, BACK ile senkronla (KT-18); klavye kısayolları levhası (Ctrl+/) tablette de bağlansın.
5. Dikey tablette ayarlar iki sütun kartlarla iyi; ana ekran bant yığını (KT-19) ve takvim ay hücresi ölçeği (KT-23) tablet-özel ayar.
6. Takvim ay görünümüne tablette gün ayrıntı paneli (yan) — yatayda boş hücreler yerine.
7. Huawei çoklu pencere (yan yana iki uygulama) ve M-Pencil kısayolları (hover imleci, çift dokunuş) denenmedi.

## Kümeleme (düzeltme paketleri; dosya çakışmasın diye)
- **TP-A (yatay kabuk/gezinti):** KT-13, KT-14 (doğrulama testi) → `lib/app/router.dart`, `lib/app/app.dart`, `lib/app/split_shell.dart`, `lib/app/app_frame.dart`, `test/` yeni yatay testler.
- **TP-B (editör yüzenleri + kalem toast'u):** KT-15, KT-16, KT-18 → `lib/features/notes/presentation/editor/note_editor_screen.dart` (+ `editor/` altı kalem tepsisi dosyaları), `lib/core/utils/hard_keyboard*.dart` (varsa).
- **TP-C (ana ekran/liste yüzenleri + bantlar + levhalar):** KT-17, KT-19, KT-20, KT-22 → `lib/features/notes/presentation/dashboard_screen.dart`, `dashboard_widgets.dart`, `quick_add_fab.dart`, `lib/core/widgets/` levha (`showAppSheet`), `lib/features/settings/presentation/notes_settings.dart` (jest).
- **TP-D (platform/olcum kimliği/izin):** KT-21, KT-24 → `lib/features/**/widget*` (home_widget çağrıları), `lib/features/notes/presentation/quick_drop_sheet.dart`, `voice_*`.
- **TP-E (takvim):** KT-23 → `lib/features/calendar/presentation/month_grid.dart`, `calendar_views.dart`.
- **TP-F (araç):** tablet yatay ölçüm anahtarı → `android/app/src/profile/AndroidManifest.xml`, `tool/perf/ab_hepsi.py`.
Paketler birbirinden dosya olarak ayrıdır (TP-A/B/C/D/E/F kesişmez; TP-B ve TP-C `editor/` ile `notes/presentation/` kökünü paylaşmaz).
