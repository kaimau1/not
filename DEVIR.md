# DEVİR — P40 (DENEYIM Faz 79: ikincil ekranlar + boş/çevrimdışı hâller)

Dal: `oto/P40-ikincil-ekranlar` · taban `origin/main` b2a09b3c · 2026-11-12

## Yapılan
- F79.5 boş hâller: `EmptyState` §2.3 ölçüsü (72 dp nötr daire, simge 32, `rowTitle` + `body`,
  dikeyde %38); başlıklar "Burada … yok", açıklama tek cümle (bekçi: `terminology_test` F79.5).
  Tur: `TOUR_EMPTY=1` → ana-bos, klasor-bos, arsiv-bos, cop-bos, gelen-bos, arama-bos.

## Sırada
- F79.6 çevrimdışı turu (`TOUR_OFFLINE=1`, 6 sahne) + bulgular; F79.1 ajanda; F79.2 ayarlar;
  F79.3 klasörler; F79.4 çöp/arşiv/Gelen.

## Not
- Taban tur `build/tour-once/` (git dışı). PDF sahnelerinde pdfium hatası tabanda da var.
- `test/design_tokens/budget.json` her committe düşürülür (yalnız düşer).
