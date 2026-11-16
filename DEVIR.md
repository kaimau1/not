# DEVIR — oto/yeni-not-odak (kullanıcı isteği 2026-11-16: yeni not → ana ekranda odak + yanıp sönme)
- Yapıldı: NotesRepository.lastCreatedId (createNote/newNoteId/duplicateNote) → editör dispose (boş değilse)
  Timer(AppMotion.long) → focusedNoteProvider.focusBrief (1,2 sn, 2 nabız). _openNew odağı kaldırıldı.
- _FocusHalo: reduce motion = sabit vurgu; görünürse kaydırma yok, değilse ortala. Tembel listede kurulmamış
  kart: dashboard _revealFocused (sıra oranıyla jumpTo, ≤6 kare).
- Test: flutter test test/new_note_focus_test.dart (3 senaryo yeşil); perf_budget, editor_leak, second_note, optimistic yeşil.
- Kalan: CI yeşil; cihazda bakılmadı (KONTROL_LISTEM "Telefonda bak").
