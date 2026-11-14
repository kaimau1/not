# DEVIR — P63 Görsel tasarım B (plan; iskelet ve uygulama YOK)

Dal: `oto/P63-tasarim-B`. Tek dosya: `docs/plan_tasarim_B.md`. Fable limitte kesildi (2026-11-14).

## Biten bölümler (tam: durum+kanıt, hedef, durumlar, kabul, kasma+bütçe)
- §0 ortak kurallar, §1 düzenleme modu (S40), §2 şablonlar (S41) — 39eaff22
- §3 kalem seti (S42) — d2b82c34
- §4 sesle yazmanın etkin menüsü (S43) — 65787bad

## YARIM / kalan (sıradaki ajan yazar, §1–§4 biçimiyle)
- §5 madde çizgileri: YALNIZ §5.1 kanıt yazıldı (dosya:satır doğrulandı). Eksik: §5.2 hedef,
  §5.3 durumlar, §5.4 kabul, §5.5 kasma + S44. "Taslak yön" maddeleri karar DEĞİL.
- §6 iskelet tanımı: yazılmadı; imzaların yeri ve doğrulanmış kod gerçekleri plan §6 notunda.
- §7 paketler: yalnız taslak tablo (PB0–PB7: dosya kümesi, model, bağımlılık, A/B, bütçe).
  Eksik: paket başına kanıt, önce üretilecek test/tur sahnesi, kabul, tuzaklar.
- Plan başına "Durum" satırı eklenmedi (plan tamamlanınca).

## Notlar
- Kanıtın tamamı planda (bölüm x.1); sohbette kalan yok. Hipotezler italik "hipotez" diye işaretli
  (§3: `_build` şeridinin Column'u, `ab_hepsi.py` kalem evresi).
- `istek_tara.py` koşulan dosyalar: pen_tray, ink_tools, ink_layer, listening_visuals,
  note_editor_voice, voice_capture_sheet, item_divider_style, format_bar, items_editor_actions/row,
  note_editor_parts. §5 hedefi yazılırken format_bar + items_editor_row yeniden süzülmeli.
- Tutarsızlıklar (plan §7 sonunda not edildi): §0 "§8" atfı = P62 planı §1; §1.2 "paket D2" = PB2.
- `test/listening_card_bubble_theme_test.dart:61` `ListeningWaveform` türüne bakıyor (§4 kabulünde).
- P62 dalı main'e girmeden PB1/PB3/PB5 başlamaz (`AppSurface`, `AppMotion.selection/emphasized`).

## Sıradaki
§5.2–5.5 → §6 → §7 ayrıntısı → Durum satırı → PB0 iskelet (Opus). Kod yazılmadı, main'e dokunulmadı.
