# DEVIR — oto/silgi-yazi (K-S1, kullanıcı kararı 2026-11-15 "silgi olsun")

Yapılanlar:
- `UiItem.barEraser` (`lib/core/personalize.dart`, barLeftDefault'ta Kalem'den sonra, varsayılan görünür) + ayar listesinde simge/ad.
- `note_editor_screen.dart` alt çubuk: metin/liste notu, !readOnly, !_penMode, mürekkep varken silgi segmenti; `eraserGate` yalnız `committedRev` dinler (dar); `_openEraser` = setEraser(true) + _openPen.
- Çeviri `editorBarEraser` TR+EN; sürüm notu 16 Kasım; kalem.md, regresyon_listesi, OTOMASYON K-S1 notu.

Test: `flutter test test/editor_bar_customize_test.dart --reporter failures-only` (4 yeni: yok/var+dokun/düzen modu/gizli).
Bütçe: `flutter test test/perf_budget_test.dart` tam yeşil (S17, S8, S47 değişmedi); jank/keyboard guard + design_tokens yeşil.
Cihaz: yok (telefon yok) — "yazıldı, cihazda doğrulanmadı".
Sıradaki: CI yeşil → yürütücü birleştirir.
