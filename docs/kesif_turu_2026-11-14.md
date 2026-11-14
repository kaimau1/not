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
