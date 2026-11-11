# DEVİR — P11 Bütçe testleri (kalan) + kalem A/B aracı (F59.2–F59.6)

Dal: `oto/P11-butce-testleri` (main `b2e2332c`'den). Paket BİTTİ; kalan: CI yeşili + cihaz koşusu.

## Yapılanlar
- F59.2/F59.3/F59.4 (commit 1): `test/perf_budget_test.dart`'a S1–S5, S8, S9, S11–S16
  (S6/S7 vardı, S10 `note_package_open_test.dart`'ta). Bütçe = bugünkü ölçüm,
  `test/perf_budget/budgets.json` (`bugun` + `hedef` + `neden`).
  `editor_harness.dart`: `pumpEditor(noteStream:)` (yankı senaryoları).
- Bozma denemesi: `_sameVisual` başına `false &&` → S1, S2, S5, S6, S7 kırmızı; geri alındı.
- F59.5 (commit 2): `tool/perf/ab_kalem.py` + `make_dataset.py --ink N` + README.
  **Cihazda koşturulmadı** (py_compile + üretilen yedek `decodeNoteJson` ile doğrulandı).
- F59.6 (commit 2): CLAUDE.md kasma listesi madde 8. Plan maddeleri `[x]`, Ek A "Bugün",
  Durum tablosu, `docs/regresyon_listesi.md`, `docs/hafiza/akicilik.md`.

## Bulgular (düzeltme YOK — ilgili fazın işi)
- S8: 30 maddeli notta İLK klavye açılışında `ItemsEditor` her inset karesinde kuruluyor
  (5 kare → 5 kurulum + 2'şer satır alanı, oturmada 1); 2.–3. tur 0. Ataları temiz →
  kendi bağımlılığı/dinleyicisi (MediaQuery, _ScrollableScope…). Kök neden aranmadı.
- **Yedek/not paketi sayfa el yazısını taşımıyor:** `encodeNoteJson`
  (`lib/features/notes/data/note_package.dart`) `Note.pageInk` yazmıyor → tam yedekten ya da
  paylaşılan paketten dönen notta sayfa çizimi yok. Plan dışı; sabah bakılacak.
- Hedefin üstündekiler: S2 5/15, S3 satır 13, S4 satır 14, S9 tuval 2, S14 tuval 1,
  S12 Dashboard 1 / NoteCard 13, S15 2001 çağrı, S16 2 belge / 448 925 bayt.

## Cihaz koşusu (yürütücü yaptırır; profil uygulaması + `launch_profile()`, tool/perf içinden)
- Koordinat: `python -c "from perf import *; print(find('OLCUM kalem'))"`; not açıkken kalem düğmesi.
- Boş sayfa: `python -u ab_kalem.py <etiket> <kart_x> <kart_y> <kalem_x> <kalem_y>`
- Dolu sayfa: önce bir kez `python -u ab_kalem.py hazirla 1500 <kart_x> <kart_y> <kalem_x> <kalem_y>`
  (~15 dk), sonra aynı ölçüm komutu. A sonra B, ikişer koşu, ikinciyi al. Kapı: UI/raster +%20.
- Denenmemiş varsayım: kalem kipinde ilk geri tuşu kipi, ikincisi notu kapatır (`kalem-kapa`/`not-kapa`).

## Komutlar
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --reporter failures-only`
