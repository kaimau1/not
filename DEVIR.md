# DEVIR — P04 (oto/P04-cipler-paket)

Sıra: F60.S3 → F60.2 → F60.4. Yürütücü birleştirmeden önce bu dosyayı siler.

## Yapılanlar
- F60.S3 [x] (a4a1f732) — `AllNotesChip` (folder_tile.dart): dokun = bütün notlar, uzun bas =
  `/folders`, tek vurgu. Bekçi `test/folder_strip_chips_test.dart`.
- F60.2 [x] — `kNotePackageTapGroup` (note_package.dart); note_editor_screen.dart'ta hızlı
  satır, biçim paneli, alt çubuk (TypingBarHide), kalem tepsisi `TapRegion(groupId:)`;
  items_editor.dart `togglePackage`'dan `_rowCache.clear()` kalktı. Bekçi
  `test/note_package_open_test.dart` (S10, bütçe budgets.json S10). Cihazda denenmedi.

## Şu an
- F60.4 (misafir notunda üst çubuk "Senkronize") başlanmadı.

## Notlar
- Windows'ta `test/folder_strip_fixed_test.dart` 2. test CRLF yüzünden düşer (`'\n}\n'`
  arıyor); CI'da (LF) geçer — bu dalın işi değil.
- F60.2 editöre dokunuyor: `[apk]` öncesi ölçüm kapısı (ab_klavye.py) koşulmadı.

## Açık komut
- `C:/src/flutter/bin/flutter.bat test test/note_package_open_test.dart test/folder_strip_chips_test.dart --reporter failures-only`
