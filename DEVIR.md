# DEVİR — P40 (DENEYIM Faz 79: ikincil ekranlar + boş/çevrimdışı hâller)

Dal: `oto/P40-ikincil-ekranlar` · taban `origin/main` b2a09b3c · 2026-11-12 · durum: F79.1–F79.6 bitti

## Yapılan (her biri ayrı commit)
- F79.5 `EmptyState` §2.3 + "Burada … yok" kalıbı (bekçi `terminology_test`); tur `TOUR_EMPTY=1` (6 sahne).
- F79.6 `ErrorState` kısa başlık + bulut; Gelen hatada boş demiyor; tur `TOUR_OFFLINE=1` (6 sahne).
- F79.3 Klasörler: boş kart 72 dp "Boş", ızgaradaki Yeni klasör karosu yok.
- F79.4 Çöp/Arşiv: Ara + ⋮; çöp kartında etiketli Geri al · Sil (error).
- F79.2 Ayarlar: nötr 40 dp kutu köşe m, rowTitle + meta, kısayollar aynı ton, misafir kartı.
- F79.1 Ajanda: 56/64 dp, rowTitle/meta, durum simgeleri 18, çöp 18 dp %60 hedef 48 (KALDI).
- Yeni testler: folders_screen, trash_archive_bar, settings_profile_card; calendar_screen'e ölçü testi.

## Sabah bakılacak
- Ana ekran "Gelen" süzgeci (`dashboard_slivers._hubSlivers`, P19 alanı) hata anında boş hâl gösteriyor.
- AI levhası çevrimdışıyken düğmeler etkin (P37 alanı); bekleyen ek şeridi bağlantı yokken "yükleniyor".
- Misafir profil kartı turda yok (oturumsuz) — cihazda bakılmalı.

## Not
- Taban tur `build/tour-once/` (git dışı). PDF sahnelerinde pdfium hatası tabanda da var.
- `test/design_tokens/budget.json` düşürüldü; P37 ile birleşirken sayıları yeniden say (yalnız düşer).
- `folders_screen.dart` biçimlendirildi (dosyada ~40 satır ilgisiz biçim farkı).
