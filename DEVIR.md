# DEVIR — P04 (oto/P04-cipler-paket)

Sıra: F60.S3 → F60.2 → F60.4. Yürütücü birleştirmeden önce bu dosyayı siler.

## Yapılanlar
- F60.S3 [x] — `AllNotesChip` (lib/features/folders/presentation/folder_tile.dart): dokun =
  `resetFilters` + `showAllNotes` true (+ not açıksa `goHome`), uzun bas = `/folders`; vurgu
  klasör/Gelen/paylaşılan içindeyken söner. Bekçi `test/folder_strip_chips_test.dart`
  (kırmızı → yeşil). Kılavuz satırı (guide_tr/en 22), HAFIZA arayuz.md, regresyon listesi.

## Şu an
- F60.2 başlanmadı.

## Notlar
- Windows'ta `test/folder_strip_fixed_test.dart` 2. test CRLF yüzünden düşer (`'\n}\n'`
  arıyor); CI'da (LF) geçer — bu dalın işi değil.

## Açık komut
- `C:/src/flutter/bin/flutter.bat test test/folder_strip_chips_test.dart --reporter failures-only`
