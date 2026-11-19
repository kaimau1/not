# Hafıza — Web

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Web
- `--wasm` (skwasm, JS yedeği); COOP/COEP yok. Wasm'da `int` 64, JS'de 53 bit.
- Geri tuşu `HomeFirstRouteInformationProvider`. Açılış `notlar-ready`
  olayında (`signalWebReady`). Açılış katmanı GERÇEK simgeyi
  (`icons/Icon-192.png`) gösterir — simge değişince `index.html`i de
  güncelle. `web/_headers`: simge + `google_fonts` 1 hafta önbellek
  (`/assets/fonts/` HAYIR: MaterialIcons her derlemede değişir).
- Drive ekleri `WebDriveAuth`/`WebDriveGate` (`blob:` buluta yazılmaz). Jeton
  SEKMEDE (`sessionStorage`, uid'e bağlı, ~55 dk — yenilemede yeniden izin
  sormaz); notta `WebAttachmentsBanner`: "N ek Drive'da · Göster" (tek
  dokunuş hepsini indirir) ya da "telefondan çıkmamış" uyarısı (Android'de
  Drive bağlı değilse ekler cihazda bekler — web'in yapabileceği yok). Web
  Drive'a yazmaz; yerel not/video yok.
- Web Drive (2026-11-03): bağlanma/indirme hatası artık SNACKBAR + ErrorLog
  (`web-drive-connect`/`web-drive-fetch`; eskiden sessizdi → "gelmiyor"un
  kökü görülemedi). Yeni jetonla düşen ekler yeniden denenir. Kök neden hâlâ
  doğrulanmadı: sıradaki turda kullanıcıdan ekrandaki hata metnini iste.
- **Bulut tarayıcısı TUZAĞI (2026-11-02):** sandbox Chromium'unda yolu `%2F`
  içeren HER Firebase Storage isteği 400 (ön istek dahil; curl'de aynısı
  403/200). Yükleme (`?name=`) geçer, okuma/silme geçmez → web turunda ek
  gösterme, PDF açma ve "Hesabımı sil" ölçülemez/bitmez. Canlı site etkilenmez.
- Web turu: Playwright + semantik ağaç (`docs/arsiv/planlar/KULLANICI_DENEYIMI_PLANI.md` Ek A);
  misafir hesabı tur sonunda sil. App Check web'de anahtarla.

## Kısa kurallar (sıkıştırmada tek satıra inenler)
- Web YouTube iframe `enablejsapi=1`; sekme gizlenince/rota örtülünce
  `pauseVideo`.

## 2026-11-07 — Tablet turu (HUAWEI MatePad 11, GMS'siz, M-Pencil) — kök nedenler
- **Ayarlar/uygulama gri ekran:** web'de JS `1.0`'ı Firestore'a TAMSAYI yazıyor; ayar senkronu `setInt` → `getDouble('font_scale')` çöküyordu (senkron gelir gelmez bütün uygulama). `writeLocalPref` `kDoublePrefKeys`'te double yazar, `FontScaleNotifier` num okur. Yeni ondalık senkron tercih eklenirse `kDoublePrefKeys`'e ekle.


## 2026-11-12 — P48 web yazı seçimi
- `trackSelectionPointerKind()` uygulama ömürlü TEK `pointerRouter.addGlobalRoute` kurar (tekrar çağrı eklemez); `editor_leak_test` tabanı bundan sonra alınır — yoksa globalRoutes 1→2 kırmızı (P48 ilk CI).
- KÖK NEDEN ("webte yazı seçerken sorun, yazı tipi olabilir" — yazı tipi DEĞİL): `sentence_select.dart` cümle genişletici seçimin kaynağına bakmıyordu; fareyle çift tıklama bütün cümleyi, shift+ok ya da kelime içi fare sürüklemesi bütün kelimeyi seçiyordu. Genişletme artık yalnız dokunmatik (son `PointerDownEvent` türü fare/izleme dörtgeni değilse ve shift basılı değilse). Webde üretme: `build web --release --wasm` + `python -m http.server` + misafir kip; karşılaştırma için arama alanı (genişleticisiz) doğru seçer.

## 2026-11-14 — P59 web seçim görünümü (KÖK NEDEN bulundu)
- Belirti: seçili kısım mavi kutuda, beyaz, TARAYICI yazı tipiyle; solunda gri şerit (Flutter'ın kendi seçimi). KÖK: Flutter'ın gizli DOM metin alanının YEREL seçimi. Motor onu yalnız `flutter-view input::selection { background-color: transparent }` ile gizler (!important ve renk yok) → sayfaya genel `::selection {… !important}` kuralı (Dark Reader vb. eklenti) gelince görünür. Yazı tipi farkı DOM alanının yazı tipi Flutter ailesini (gömülü, CSS'te yok) bulamamasından. Çözüm `web/index.html`: `flt-text-editing-host`/`flt-semantics` input/textarea `::selection` saydam zemin + renk, `!important` (bekçi `web_selection_css_test`).
- Üretme (oturumsuz): ayrı giriş dosyası (P59 örneği silindi, kalıp burada) (`pumpEditor` sağlayıcılarıyla gerçek `NoteEditorScreen`, Firebase yok) → `build web --wasm -t … -o build/web_repro` + `http.server` + Playwright `channel=chrome`; tarayıcıda eklenti yoksa belirti çıkmaz — `::selection{background:#3b7bd9!important;color:#fff!important}` enjekte et. P48'in "yazı tipi değil" sonucu cümle genişleticisi içindi; bu ikinci, ayrı neden.
- TUZAK: semantik açıkken (`ensureSemantics`) DOM alanı fare olaylarını alır, fareyle sürükleme yerel metin sürükle-bırakı yapıp metni karıştırabilir (yalnız düzenekte görüldü; uygulama semantiği kendiliğinden açmıyor).

## 2026-11-18 — P74 PW-A (KW-1/KW-2) KÖK NEDENLER
- KW-1 (ana ekran + ray anlamsal ağaçta yok): sayfa rotası `ModalRoute` her zaman `ModalBarrier` → `BlockSemantics` taşır; engel, aynı anlamsal sınır içinde ONDAN ÖNCE çizilen kardeşleri siler. Uygulamada Navigator kök değil: `AppFrame`'de ray (Row'da önce), `SplitShell`'de soldaki liste iç Navigator'dan önce çiziliyor → ikisi de ağaçtan düşüyordu. Çözüm: iki yerde Navigator çocuğu `Semantics(container: true)` (`app_frame.dart`, `split_shell.dart`). Bekçi `test/web_semantics_home_test.dart` (`ensureSemantics` + `find.bySemanticsLabel`). Navigator'ın yanına yeni kardeş koyarken sınırı unutma.
- KW-2 (Tab ana ekranda ilerlemiyor): geniş ekranda iç Navigator'daki '/' rotası `SizedBox.shrink`; rota odağı alıyor, kapsamında odaklanacak öğe yok → Tab yerinde sayıyor (web'de `leaveFlutterView` gibi tarayıcıya). Çözüm: not açık değilken iç Navigator `ExcludeFocus`. Ağaç şekli sabit (bayrak değişir).

## 2026-11-19 — P77 web bulguları (PW-B/C/D/F)
- Bildirim şeridi (`app_notice.dart`): pencere ≥ 600 (`AppNoticeHost.wideBreakpoint` = `kRailBreakpoint`) iken dip bildirimi alt-SON köşede — ray ve bölünmüş görünümün listesi baş tarafta, son köşe hep içerik. Şerit boşken de yalnız `MediaQuery.sizeOf` okur (çıkan kart köşe değiştirmesin).
- `TipOnce.show`: ipucu yalnız çağıran sayfa `ModalRoute.isCurrentOf` iken; ertelenen ipucu başka sayfa öndeyse düşer (sayılmaz). `lastPointerIsMouse()` (`sentence_select.dart`) fareyle anlamsız ipuçları için.
- Web açılış katmanı (`web/index.html`) işletim sistemi koyu kipini DEĞİL uygulamanın kaydını izler: localStorage `flutter.theme_mode` (shared_preferences web, JSON dize). Tema anahtarı/adları değişirse betik + `web_splash_theme_test` birlikte.
- KW-10: `initialFontScale(web, windowWidth)` — yalnız İLK açılışta, web ≥ 1200 → en az Büyük (1,15).
- KW-17 KÖK NEDEN: `appBarTheme.titleTextStyle` punto taşımıyor (tema kurulurken textTheme ölçüsüz) → üst çubuk başlıkları her yerde 14 px. Karar bekliyor (keşif belgesi "P77 durumu").
- Gizlilik ekranı `privacyBlocks()` ile çizilir (başlık/madde/paragraf, satır sonları birleşir); web sayfaları yine `tool/gizlilik_sayfalari.dart`.
- Ekran turunda misafir afişi yok (sahte oturum misafir değil) — afiş değişikliği turda görünmez.
