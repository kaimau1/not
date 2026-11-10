# DEVIR — P04 (oto/P04-cipler-paket)

Sıra: F60.S3 → F60.2 → F60.4 — ÜÇÜ DE BİTTİ. Yürütücü birleştirmeden önce bu dosyayı siler.

## Yapılanlar
- F60.S3 [x] (a4a1f732) — `AllNotesChip` (folder_tile.dart): dokun = bütün notlar, uzun bas =
  `/folders`, tek vurgu. Bekçi `test/folder_strip_chips_test.dart`.
- F60.2 [x] (f7f17852) — `kNotePackageTapGroup`; editör çubukları `TapRegion(groupId:)`;
  `togglePackage`'dan `_rowCache.clear()` kalktı. Bekçi `test/note_package_open_test.dart`
  (S10, budgets.json S10). Cihazda denenmedi.
- F60.4 [x] — üst çubuk senkron göstergesi misafirde "Yalnız bu cihazda"
  (note_editor_screen.dart, `isAnonymousProvider`). Bekçi
  `test/editor_guest_sync_badge_test.dart`; `pumpEditor`'a `overrides` parametresi.

## Notlar
- Windows'ta `test/folder_strip_fixed_test.dart` 2. test CRLF yüzünden düşer (`'\n}\n'`
  arıyor); CI'da (LF) geçer — bu dalın işi değil.
- F60.2 editöre dokunuyor: `[apk]` öncesi ölçüm kapısı (ab_klavye.py) koşulmadı.

## Açık komut
- `C:/src/flutter/bin/flutter.bat test test/note_package_open_test.dart test/folder_strip_chips_test.dart test/editor_guest_sync_badge_test.dart --reporter failures-only`
