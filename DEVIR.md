# DEVİR — P33 (DENEYIM Faz 72: tasarım zemini) · dal `oto/P33-tasarim-zemini`

## Yapılanlar
- F72.1 `lib/app/theme/app_tokens.dart`: `AppSpace/AppRadius/AppIconSize/AppAlpha/AppWeight`, `AppMotion.quick/long`.
- F72.2 aynı dosyada `AppText.of(ThemeData)` (8 rol, tema başına `Expando` önbellek; ham temada null yok).
- F72.3 `test/design_tokens_guard_test.dart` + `test/design_tokens/budget.json` (token_sayim.py ile aynı desen; bütçe yalnız düşer; bozma denemesi testi).
- F72.4 `lib/core/widgets/sheet_tile.dart` (`SheetTile.tile/.rich`, `DestructiveRow`, `SheetTileGrid`), `lib/core/widgets/delayed_spinner.dart`.
- F72.5 (kısmi) `sectionLabelStyle`/`SectionLabel` → `AppText.section` (w700 → w600). Tek görünür fark.

## Bilerek YAPILMAYAN (sabah bakılacak)
- `SheetHeader` ölçüsü (56 dp, 16 dp sol, başlık 18 w600), `EmptyState` (32 simge/72 daire) ve K-D7 tutamak kaldırma:
  hepsi her levhada görünür fark + K-D7 ~15 çağıran dosyaya (P37/P20 alanı) dokunur → "bu faz bölüm adı dışında
  ekranı değiştirmez" kuralıyla çelişiyor. P37 (F76.1/F76.3) ve P40 (F79.5) kendi turunda yapsın.
- `SectionLabel` içine "üst 20, alt 8" dolgu: çağıranlar kendi dolgusunu veriyor; içeri eklemek çift dolgu = görünür fark.

## Test
`flutter test test/design_components_test.dart test/design_tokens_guard_test.dart --reporter failures-only`
Tur: `TOUR_OUT=build/tour-sonra TOUR_COMPARE=build/tour-once flutter test tool/tour/screen_tour_test.dart` (FLUTTER_ROOT=C:/src/flutter)
