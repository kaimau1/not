# DEVIR — P86 kasma T2 · T9 · T8 (dal oto/P86-kasma-t2-t9)

- **T2 (K-22a / K-23 / K-26 — Not akışı yankısı ve türetilmiş sağlayıcılar, `5a1d4001`):**
  - `test/note_stream_echo_test.dart` (1280×800 bölünmüş görünüm, 30 not, açık editör otomatik kayıt yankısı).
  - `NoteListSlices` (`Expando` tek geçişlik liste dilimleyici) + `noteBacklinksProvider` (`Provider.autoDispose.family`, `StableBox`) + `.select` / `StableBox` (`filteredNotesProvider`, `allNotesCountProvider`, `folderNoteCountsProvider`, `dueItemsProvider`/`dueNextProvider`, `calendarReminderNotesProvider`/`calendarTimedNotesProvider`, `pendingUploadsProvider`, `GuestBackupCard`).
  - **Önce → Sonra:** yeniden hesaplanan türetilmiş sağlayıcı (`didDisposeProvider`) **20 (10 sağlayıcı) → 0** · bildirim yayan türetilmiş (`didUpdateProvider`) **4 → 0** · liste taraması **11 geçiş (330 okuma) → 2 geçiş (60 okuma)** · yankı penceresi widget kurulumu **242 → 22** (`HomeCalendarStrip` 1→0, `_DayCell` 10→0, `BacklinksChip` 1→0, `GuestBackupCard` 1→0).
- **T9 (K-37 — `PopIn` ve `RevealUp` / `ScaleSettle`):**
  - `PopIn` ve `RevealUp`, `TweenAnimationBuilder` + `Opacity` yerine `SingleTickerProviderStateMixin` + `AnimationController` + `FadeTransition` (`RenderAnimatedOpacity`) + `Transform` (`PopIn`'de ölçek+öteleme tek matriste) olarak güncellendi; `motionOf(context)` ve `PopIn.animate` korundu.
  - **Önce → Sonra (`test/pop_in_reveal_up_test.dart`):** çocuk kurulumu **1 → 1** · `Opacity` (`RenderOpacity`) **1 → 0** (`FadeTransition` / `RenderAnimatedOpacity` **1**) · `PopIn` 15 ara kare widget kurulumu **60 (4/kare) → 30 (2/kare)** (`Opacity` 15→0) · `RevealUp` 17 ara kare widget kurulumu **51 (3/kare) → 34 (2/kare)** (`Opacity` 17→0).
- **Sıradaki:** T8 güvenli alt kümesi (K-28 `text_wrap_controller.dart` / `link_text.dart`, K-29 `ItemsEditor._growBudget`).
