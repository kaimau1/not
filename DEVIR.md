# DEVIR — oto/acil-sabit (Acil not)
- Yorum: "Acil" = NOT bayrağı (sabit/yıldız gibi), `Note.urgent` / alan `urgent`. attachment/PageBubble.urgent'e dokunulmadı.
- Yapılan: note.dart alan + `homeSections` (acil→sabit→diğer); dashboard_slivers 3 bölüm yolu + home_snapshot; kart ünlemi (note_card, iki yer, `card-urgent`); + levhası 'urgent' (add_catalog, attach_sheet, note_editor_attachments); editör tarih yanı ünlem (NoteSlice, dokununca kalkar); kart sağ tık menüsü; backup; repo.setUrgent; TR/EN çeviri.
- toMap koşullu (`if (urgent)`): S16 bayt bütçesi; kapatma setUrgent(false) ile açık yazım (`_setUrgent`).
- İşe yaramayan: ⋮ menüsüne (hızlı satır ya da Düzenle bölümü) koymak — note_menu_sheet_height_test (732/790 > 722) ve S37 (502 > 487) kırmızı. Vazgeçildi, sabah bakılacak.
- Test: `flutter test test/urgent_note_test.dart test/perf_budget_test.dart test/note_menu_sheet_height_test.dart test/add_catalog_test.dart --reporter failures-only` (yerelde yeşil).
- Sıradaki: CI yeşil → yürütücü birleştirir. Telefonda bakılmadı (KONTROL_LISTEM).
