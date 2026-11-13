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
- Web turu: Playwright + semantik ağaç (`KULLANICI_DENEYIMI_PLANI.md` Ek A);
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
