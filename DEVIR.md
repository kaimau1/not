# DEVIR — oto/kalem-tepsisi (kullanıcı isteği 2026-11-15, kalem kapsülü)
- Yapıldı: kapsülde geri al (showUndo, yalnız tam ekranda), × / ✓ → tek pen-close (klavye), silgi kendi düğmesi (mürekkebe bağlı soluk), basılı tut / ⋯ → tümünü temizle + Geri al bildirimi; TR/EN çeviri; S42 kalem resmi 77→66; iconSize 406→404.
- Dosyalar: pen_tray.dart, note_editor_screen.dart (_penCloseButton, showUndo), .arb + generated, testler (pen_tray_controls, editor_pen_tablet, pen_single_tool).
- Test: flutter test test/pen_tray_controls_test.dart test/editor_pen_tablet_test.dart test/pen_single_tool_test.dart; perf S42 --plain-name S42.
- Sıradaki: CI yeşil → yürütücü birleştirir (cihaz A/B kalem evresi), DEVIR silinir.
# DEVIR — oto/olcum-evreleri (ab_hepsi P63 evreleri)
Yapılanlar (tool/perf/ab_hepsi.py, perf.py; lib/ dokunulmadı):
- sablon: panel reverse kaydırma, Şablon grubu üstte → H*0,2'den aşağı uzun çekiş ×2 (pencerede de).
- kalem: düşen evreden sonra list_top (bicim listeyi dipte bırakıyordu).
- bicim: ensure_cizgi — "OLCUM cizgi" yoksa notyedek üret/it/"Yedekten geri yükle" (birleştirir).
- acilis: am start'a --ez endless-trace-buffer true + "açılış tanı:" satırı (kare < 5).
- perf.open_import(button=...) genelleştirildi.
Durum: cihazda DENENMEDİ (telefon soğumada). Sözdizimi + ad denetimi + main_ink çıktısı yerelde tamam.
Cihazda ilk koşu: "hazırlık:" satırı, "evre atlandı" satırı kalmamalı, acilis kare > 2.
