# Test borcu (F58.3 kova O) — otomatikleşebilen cihaz adımları

Bu fazda test YAZILMAZ; her satır `docs/cihaz_turu.md` adımının elle yapılan kısmı için bir
widget/akış testi önerisi. "Var" = ilgili dosya `test/` altında bulundu (içeriği doğrulanmadı,
yalnız ad eşleşmesi); "yok" = ad taraması boş. Test yazılınca satır ve turdaki adım silinir.

| Tur adımı | Elle yapılan | Karşılık | Öneri / Durum |
|---|---|---|---|
| Telefon 1 | tam yedek → geri yükle, takvim dahil | `backup_service_test`, `calendar_move_backup_test`, `test_borcu_closure_test` | ✅ Kapandı (`pageInk`, klasör, olay/görev/liste/gün bağları, `Routine` + `RoutineLog` ve idempotent 2. yükleme kapsanıyor) |
| Telefon 3 | not paketi açık/kapa | `note_package_open_test`, `note_package_test`, `items_package_unpack_test`, `test_borcu_closure_test` | ✅ Kapandı (açık pakette Enter/yeni madde `package` kimliğini korur, paket bölünmez) |
| Telefon 6/7 | uygulama/not kilidi, kilitli bildirim | `app_lock_test`, `note_lock_test`, `security_guard_test`, `test_borcu_closure_test` | ✅ Kapandı (1 dk yeniden kilit eşiği + `AppLockSecureScope` ref-sayacı doğrulandı) |
| Telefon 8 | geri zinciri | `back_closes_test`, `shared_notes_back_test`, `items_selection_back_*`, `test_borcu_closure_test` | ✅ Kapandı (`penMode -> capsule -> settingsCard` 3 katmanlı `BackCloses` LIFO kapanışı doğrulandı) |
| Telefon 11–13 | satır hatırlatıcı, kanallar, şerit | `reminder_*_test`, `due_items_test`, `test_borcu_closure_test` | ✅ Kapandı (`DueBanner` otomatik belirir, `+N` gösterir, kilitli notu gizler) |
| Telefon 14 | yazım düzelt | `spell_engine_test`, `test_borcu_closure_test` | ✅ Kapandı (`AutoSpell` tek Backspace ile düzeltmeyi geri alıp çifti reddeder; `kalemi -> kalemde` ek değişimi öğrenilmez) |
| Telefon 17/18 | aramadan kelimeye kayma, basılı tut halkası | `hold_progress_ring_test`, `test_borcu_closure_test` | ✅ Kapandı (`?item=` rota sorgusu `revealItemId` aktarır; `HoldRingArea` 0.25 sessiz payı doğrulandı) |
| Telefon 19–20 | Tümü çipi, misafir etiketi | `folder_strip_chips_test`, `editor_guest_sync_badge_test` | ✅ Otomatik tamam; widget testleriyle kapandı |
| Telefon 21–23 | PDF sütunu, silgi, tepsi | `pdf_page_column_test`, `pen_single_tool_test`, `pen_policy_test`, `perf_budget_test` | cihazda yalnız bellek/fırlatma ve gerçek çizim kalır |
| Telefon 26 | zemin görseli ek sayısı | `share_target_test`, `test_borcu_closure_test` | ✅ Kapandı (`attachmentsWithoutBackground`, `NoteCard` arşiv rozeti ve `canReceiveShare` filtresi doğrulandı) |
| Telefon 29 | tema okunurluk | `theme_contrast_test`, `test_borcu_closure_test` | ✅ Kapandı (`Lavanta/Zeytin/Saman/Krem/Şeftali/Nane` dahil tüm `ThemeFamily.values` açık/koyu WCAG kontrastları doğrulandı) |
| Telefon 35–36 | takvim, rutin, güne not | `calendar_screen_test`, `routine_test`, `note_calendar_links_test`, `calendar_move_backup_test`, `test_borcu_closure_test` | ✅ Kapandı (iki parmak yakınlaşma + `MonthPage` uzun basış sürükle-taşı + `movedToDay` doğrulandı) |
| Telefon 37 | Google Takvim senkronu | `google_calendar_test`, `test_borcu_closure_test` | ✅ Kapandı (çevrimdışı `saveToGoogle` -> `pending == 1` ve iyileşmede sıfırlama doğrulandı) |
| Telefon 39 | paylaşım/ortak klasör | `shared_folder_home_test`, `shared_hub_count_test`, `share_target_test` var | yetkiler `rules-test` ile kapsanıyor |
| Web 8 | Ctrl+tekerlek / Alt+ok | `home_gestures_test`, `test_borcu_closure_test` | ✅ Kapandı (`AppShortcuts` `Alt+Ok` klasör geçişi + `PinchColumns` `Ctrl+tekerlek` doğrulandı) |
| Web 12 | AI kapalıyken hata yağmuru yok | `test_borcu_closure_test` | ✅ Kapandı (`aiTurnedOffProvider` kapısı + not listesi kaydırmada `ErrorLog.entries` boş) |
