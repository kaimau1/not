# DEVIR — oto/sureli-not (zamanlı not)
- Yapıldı: Note.expiresAt (+knownKeys/copyWith/fromMap/toMap yalnız doluyken), expiredNotes(); repo archiveExpired/setExpiry, setArchived(true) süreyi temizler; notesStreamProvider her yayında + dashboard resume denetimi; editör "+" menüsü 'expiry' + çip (expiry_sheet.dart: hazır süreler + pickLineTime + kaldır); kart kum saati + kalan süre (dar kartta yalnız simge); TR/EN .arb; test/sureli_not_test.dart.
- Kart ⋮ menüsüne eklemek note_menu_sheet_height_test + S37'yi kırdı → geri alındı.
- toMap'te koşulsuz null alan S16 bayt bütçesini 11 bayt aştı → yalnız doluyken yazılıyor, kaldırma açık null.
- CI 1. tur: editor_core_guard `_sameVisual` terim 33>32 → reminderAt+expiresAt tek kayıt terimi `(a.reminderAt, a.expiresAt) == (...)`. Yerelde bu bekçi CRLF yüzünden RangeError verir (autocrlf), CI'da LF.
- Test: flutter test test/sureli_not_test.dart test/perf_budget_test.dart test/note_menu_sheet_height_test.dart
- Kalan: CI yeşil; cihazda bakılmadı (KONTROL_LISTEM).
