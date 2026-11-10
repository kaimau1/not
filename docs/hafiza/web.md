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

