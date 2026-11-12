# DEVIR — P34 (Faz 73: renk rolleri + sakin tipografi), dal `oto/P34-renk-tipografi` (taban `oto/P33-tasarim-zemini`)
- **Yapılanlar:** F73.1 K-D1 renk rolleri (zamanı gelen şeridi secondary, Yeni klasör primaryContainer, paylaş daireleri nötr, ayar alan simgeleri + Kılavuz/Kişiselleştir kısayolları nötr, AiIcon tertiary, sözleşme `app_palette.dart` başında) · F73.3 punto (12-altı 10 yer, yarım punto 23 yer) · F73.2 K-D2 krom ağırlığı w700/w800 → `AppWeight.strong` (83 yer) · F73.4 K-D9 tema seçici Sakin/Kâğıt/Canlı. Commit başlıkları "K-D1/K-D2/K-D9 F73.x".
- **Bekçiler:** `test/color_roles_test.dart` (yeni; eski `due_banner.dart` ile KIRMIZI → düzeltmeyle YEŞİL), `test/theme_picker_groups_test.dart` (yeni), `design_tokens/budget.json` alpha 243→242, fontWeight 225→142 (yalnız düştü). `folder_strip_chips_test` seçili çip ağırlığı `AppWeight.strong`.
- **YAPILMAYAN / sabah bakılacak:** F73.1-2 `_addToolButton` rozeti (`editor/note_editor_toolbar.dart`) — Ek D.1 "P34 `editor/`'e girmez", P36 yapsın. "Koyu" seçeneği plan listesinde yoktu → Sakin'in sonunda. Tema bölümünde "Tema" başlığının hemen altında "Sakin" etiketi (iki etiket üst üste) — P37/P42 bakabilir.
- **Dışarıda bırakılanlar (bilerek):** takvim ay/hafta/yıl ızgarası (Ek D.1 kimsede değil, Y12), klasör çipi üst sayısı (Y2), `home_calendar_strip`/`note_card` (P35), `ai_hub_screen` puntosu (Y15), `action_menu_sheet` (P37), kullanıcı içeriği kalını (balon/sunum/görsel notu, rich_text).
- **Tur:** `build/tour-once` (taban) ↔ `build/tour`; %0,5 üstü 79 PNG (çoğu ağırlık/punto). Kabul: `build/tour/telefon-ana.png`, `telefon-ayarlar.png`, `telefon-n4-paylas.png`, `telefon-ayarlar-gorunum.png`.
- **Doğrulanmadı:** koyu tur yalnız telefon ana/ayarlar/n4 (`build/tour-koyu`, okunur); cihaz yok (renk/yazı işi — ölçüm kapısı gerektirmez, editör/çubuk/liste düzenine dokunulmadı).
- **Sıradaki:** CI'ı izle; yeşilse P34 birleştirmesi `[apk]` + sürüm notu (aşağıda).
- **Açık test komutu:** `flutter test test/color_roles_test.dart test/theme_picker_groups_test.dart test/design_tokens_guard_test.dart test/theme_contrast_test.dart test/folder_strip_chips_test.dart --reporter failures-only`

## Sürüm notu maddeleri
- Ekran daha sakin: arayüzdeki başlık ve etiketler biraz daha ince, çok küçük yazılar okunur boya getirildi.
- Renkler artık anlam taşıyor: yeşil/temanın ana rengi eylem, sıcak renk zaman ve hatırlatma, üçüncü renk yalnız yapay zekâ (✨). "Zamanı gelenler" şeridi sıcak renge döndü.
- Paylaş ekranındaki Kopyala/PDF/Görsel daireleri ve Ayarlar'daki simge kutuları sade, nötr renkte.
- Tema seçici üç grupta: Sakin, Kâğıt ve Canlı.
