# DEVIR — P86 kasma T2 · T9 · T8 (dal oto/P86-kasma-t2-t9)

- **T2 (K-22a / K-23 / K-26 — Not akışı yankısı ve türetilmiş sağlayıcılar, `5a1d4001`):**
  - `test/note_stream_echo_test.dart` (1280×800 bölünmüş görünüm, 30 not, açık editör otomatik kayıt yankısı).
  - `NoteListSlices` (`Expando` tek geçişlik liste dilimleyici) + `noteBacklinksProvider` (`Provider.autoDispose.family`, `StableBox`) + `.select` / `StableBox` (`filteredNotesProvider`, `allNotesCountProvider`, `folderNoteCountsProvider`, `dueItemsProvider`/`dueNextProvider`, `calendarReminderNotesProvider`/`calendarTimedNotesProvider`, `pendingUploadsProvider`, `GuestBackupCard`).
  - **Önce → Sonra:** yeniden hesaplanan türetilmiş (`didDisposeProvider`) **20 (10 sağlayıcı) → 0** · bildirim yayan türetilmiş (`didUpdateProvider`) **4 → 0** · liste taraması **11 geçiş (330 okuma) → 2 geçiş (60 okuma)** · yankı penceresi widget kurulumu **242 → 22** (`HomeCalendarStrip` 1→0, `_DayCell` 10→0, `BacklinksChip` 1→0, `GuestBackupCard` 1→0).
- **T9 (K-37 — `PopIn` ve `RevealUp` / `ScaleSettle`, `ca0b24fd`):**
  - `PopIn` ve `RevealUp`, `TweenAnimationBuilder` + `Opacity` yerine `SingleTickerProviderStateMixin` + `AnimationController` + `FadeTransition` (`RenderAnimatedOpacity`) + `Transform` olarak güncellendi; `motionOf(context)` ve `PopIn.animate` korundu.
  - **Önce → Sonra (`test/pop_in_reveal_up_test.dart`):** çocuk kurulumu **1 → 1** · `Opacity` (`RenderOpacity`) **1 → 0** (`FadeTransition` / `RenderAnimatedOpacity` **1**) · `PopIn` 15 ara kare kurulumu **60 (4/kare) → 30 (2/kare)** (`Opacity` 15→0) · `RevealUp` 17 ara kare kurulumu **51 (3/kare) → 34 (2/kare)** (`Opacity` 17→0).
- **T8 — K-28 (`findLinks` / `_scanPlainness` / `_paragraphSpan`):**
  - `findLinks` aday token süzgeci (`.` sonrası ASCII harf, `www.` ya da `://` içeren boşluksuz dilim) + tek girişlik önbellek; `findAttachmentTags` erken `📎 ` kontrolü; `_paragraphSpan` düz paragraf kısayolu ve `copyLooksFrom` değişmezlik kontrolü.
  - **Önce → Sonra (`test/text_wrap_link_scan_test.dart`, 200 cümle ~11.600 karakterlik tek paragraf açılış + 5 tuş):** düz paragrafta `_linkPattern` çağrısı **6 (69.615 kr) → 0 (0 kr)** · bağlantılı+biçimli paragrafta **12 (139.830 kr) → 6 (156 kr, %99,9 düşüş)**.
- **Sıradaki:** T8 — K-29 (`ItemsEditor._growBudget`).
