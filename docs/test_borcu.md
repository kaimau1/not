# Test borcu (F58.3 kova O) — otomatikleşebilen cihaz adımları

Bu fazda test YAZILMAZ; her satır `docs/cihaz_turu.md` adımının elle yapılan kısmı için bir
widget/akış testi önerisi. "Var" = ilgili dosya `test/` altında bulundu (içeriği doğrulanmadı,
yalnız ad eşleşmesi); "yok" = ad taraması boş. Test yazılınca satır ve turdaki adım silinir.

| Tur adımı | Elle yapılan | Karşılık | Öneri |
|---|---|---|---|
| Telefon 1 | tam yedek → geri yükle, takvim dahil | `backup_service_test`, `calendar_move_backup_test` var | sayım eşitliği: not/görev/etkinlik/rutin, ikinci yükleme çoğaltmaz (pageInk dahil, P11b) |
| Telefon 3 | not paketi açık/kapa | `note_package_open_test`, `note_package_test`, `items_package_unpack_test` var | Enter/Yeni madde pakette kalır (D7) — kapsamı doğrula |
| Telefon 6/7 | uygulama/not kilidi, kilitli bildirim | `app_lock_test`, `note_lock_test`, `security_guard_test` var | 1 dk sonra dönüşte kilit: sahte saat |
| Telefon 8 | geri zinciri | `back_closes_test`, `shared_notes_back_test`, `items_selection_back_*` var | kalem kipi/kapsül/ayar kartı geri sırası (A3) — yok |
| Telefon 11–13 | satır hatırlatıcı, kanallar, şerit | `reminder_*_test` var | şerit kendiliğinden belirir (A9), rozet sayısı (A10) — yok |
| Telefon 14 | yazım düzelt | `spell_engine_test` var | Backspace geri alma, ek değişimi öğrenilmez — kapsamı doğrula |
| Telefon 17/18 | aramadan kelimeye kayma, basılı tut halkası | yok | `?item=` kayması, halka dolum süresi |
| Telefon 19–20 | Tümü çipi, misafir etiketi | `folder_strip_chips_test`, `editor_guest_sync_badge_test` var | otomatik tamam; turdan çıkarılabilir |
| Telefon 21–23 | PDF sütunu, silgi, tepsi | `pdf_page_column_test`, `pen_single_tool_test`, `pen_policy_test`, `perf_budget_test` var | cihazda yalnız bellek/fırlatma ve gerçek çizim kalır |
| Telefon 26 | zemin görseli ek sayısı | yok | `note_card` arşiv rozeti + `share_target_sheet` meta için zemin görselli not testi (cihaz_turu bölüm D) |
| Telefon 29 | tema okunurluk | `theme_contrast_test` var | Lavanta/Zeytin/Saman/Krem/Şeftali/Nane çiftlerinin kapsandığını doğrula |
| Telefon 35–36 | takvim, rutin, güne not | `calendar_screen_test`, `routine_test`, `note_calendar_links_test` var | iki parmak yakınlaşma, sürükle-taşı — kısmen |
| Telefon 37 | Google Takvim senkronu | `google_calendar_test` var | uçak kipi kuyruğu "1 değişiklik bekliyor" — yok |
| Telefon 39 | paylaşım/ortak klasör | `shared_folder_home_test`, `shared_hub_count_test`, `share_target_test` var | yetkiler `rules-test` (26/26) ile kapsanıyor |
| Web 8 | Ctrl+tekerlek / Alt+ok | yok | kısayol işleyicisi birim testi (tarayıcı sayfa yakınlaşması elle kalır) |
| Web 12 | AI kapalıyken hata yağmuru yok | yok | widget testi: AI kapalı + kaydırma, hata sayacı 0 |
