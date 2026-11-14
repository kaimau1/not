# DEVIR — P63 Görsel tasarım B (plan + iskelet)

Dal: `oto/P63-tasarim-B`. Fable YALNIZ plan + iskelet yazar; uygulama Opus/Sonnet paketleriyle.

## Yapılanlar
- Kanıt toplandı (kod + `istek_tara.py`, 21 dosya). Görsel tur bu 5 yüzeyi ÇEKMİYOR
  (`tool/tour/screen_tour_test.dart:656-676`) → koşulmadı; her pakete "tura ekle" maddesi yazıldı.
- `docs/plan_tasarim_B.md` §0 ortak kurallar, §1 düzenleme modu, §2 şablonlar.

## Şu anki adım
- Plan §3 kalem seti, §4 sesle yazma, §5 madde çizgileri, §7 paketler; sonra iskelet.

## Sıradaki
- İskelet dosyaları (plan §6): customize_board, template_preview_card, pen_stroke_preview,
  voice_level_wave, divider_kind_picker + küçük testleri.

## Notlar
- P62 ajanına dosya sınırı ve beklenen ortak belirteçler mesajla bildirildi.
- Bütçe senaryo numaraları: P63 = S40–S44 (P62 = S30–S39, S28 boş).
- Test komutu: `"C:/src/flutter/bin/flutter.bat" test test/<ad>_test.dart --reporter failures-only`
