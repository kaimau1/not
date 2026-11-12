# DEVİR — P37 Levhalar (oto/P37-levhalar, 2026-11-12)

Durum: F76.1–F76.4 yapıldı, dalda; main'e birleştirilmedi (yürütücü yapar, `[apk]`).

- F76.1 not ⋮ menüsü: başlıklı menüde tutamak yok (K-D7), ⚙ açılır menü (Menüyü düzenle ·
  Ekranı düzenle · Ayarlar, K-D10), Sil `DestructiveRow`. 412×915: 774 → 670 dp; 360×640'ta
  Sil'e 50 dp kaydırma. Bekçi `test/note_menu_sheet_height_test.dart`.
- `SheetHeader` (ortak): 56 dp, solda 16, başlık `AppText.sheetTitle` 18 pt — kapsam dışı
  levhalarda da (Ekle, tema, takvim editörleri, kalem tepsisi) başlık 2 pt büyüdü, satır +8 dp.
- F76.2 AI + Paylaş: `SheetTile.rich` (yeni `badge` parametresi, `AppIcons.glyph`), çerçevesiz
  kutular, `SectionLabel`, tutamak yok.
- F76.3 döküm `docs/deneyim/levhalar.md` (84 çağrı + sabah bakılacaklar).
- F76.4 `dialogTheme` (başlık 18, gövde 14) + `core/widgets/confirm_dialog.dart`.
- Bütçe `test/design_tokens/budget.json` düştü (radius 333, fontSize 211, iconSize 499,
  alpha 240, fontWeight 140) — başka dal birleşirken çakışabilir, yürütücü sayıyı ayarlar.

Doğrulanmadı: cihazda görünüm (tur yalnız Roboto); CI tam takım (`app_theme` değişti → ALL).
Sabah bakılacak: `SectionLabel` iç dolgusu 20/8 (menüyü uzatır), kapsam dışı levhalarda
tutamak + ✕, 34 el yazısı başlık, 5 `error`'suz yıkıcı onay (liste döküm dosyasında).
