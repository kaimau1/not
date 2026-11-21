# DEVIR — P86 kasma T2 · T9 · T8 (dal oto/P86-kasma-t2-t9)

- **T2 (K-22a / K-23 / K-26 — Not akışı yankısı ve türetilmiş sağlayıcılar):**
  - `test/note_stream_echo_test.dart` ile editör açıkken (1280×800 bölünmüş görünüm, 30 not) tek otomatik kayıt yankısında yeniden hesaplanan/bildirim yayan sağlayıcılar, liste taramaları ve widget kurulumları ölçüldü.
  - `NoteListSlices` (`Expando` önbellekli tek geçişlik liste dilimleyici) + `noteBacklinksProvider` (`Provider.autoDispose.family`, `StableBox`) + `.select` / `StableBox` (`filteredNotesProvider`, `allNotesCountProvider`, `folderNoteCountsProvider`, `dueItemsProvider`/`dueNextProvider`, `calendarReminderNotesProvider`/`calendarTimedNotesProvider`, `pendingUploadsProvider`, `GuestBackupCard`) uygulandı.
  - **Önce → Sonra (`test/note_stream_echo_test.dart`):**
    - Yeniden hesaplanan türetilmiş sağlayıcı (`didDisposeProvider`): **20 (10 sağlayıcı) → 0**
    - Bildirim yayan türetilmiş sağlayıcı (`didUpdateProvider`, ham akışlar hariç): **4 → 0**
    - Yankılanan 30 notluk liste taraması: **11 geçiş (330 okuma) → 2 geçiş (60 okuma)**
    - Yankı penceresi widget kurulumu: **242 → 22** (`HomeCalendarStrip` 1→0, `_DayCell` 10→0, `BacklinksChip` 1→0, `GuestBackupCard` 1→0).
- **Sıradaki:** T9 (K-37 `PopIn` / `RevealUp`) ve T8 (K-28 / K-29).
