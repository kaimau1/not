// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Notes';

  @override
  String get loginTagline => 'Your notes, on every device';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String loginError(String error) {
    return 'Sign-in failed: $error';
  }

  @override
  String get searchHint => 'Search notes...';

  @override
  String get filterAll => 'All';

  @override
  String get filterText => 'Text';

  @override
  String get filterChecklist => 'List';

  @override
  String get filterOrdered => 'Numbered';

  @override
  String get filterPinned => 'Pinned';

  @override
  String get filterStarred => 'Starred';

  @override
  String get star => 'Star';

  @override
  String get unstar => 'Remove star';

  @override
  String editedAt(String date) {
    return 'Edited: $date';
  }

  @override
  String get sectionPinned => 'Pinned';

  @override
  String get sectionOthers => 'Others';

  @override
  String get emptyNotes => 'No notes yet';

  @override
  String get emptyNotesHint => 'Tap + to add your first note';

  @override
  String get emptySearch => 'No results found';

  @override
  String get newTextNote => 'Text note';

  @override
  String get newChecklist => 'List';

  @override
  String get newOrderedList => 'Numbered list';

  @override
  String get noteDeleted => 'Note deleted';

  @override
  String notesDeletedCount(int count) {
    return '$count notes deleted';
  }

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

  @override
  String get titleHint => 'Title';

  @override
  String get bodyHint => 'Note...';

  @override
  String get newItemHint => 'New item';

  @override
  String moreItemsCount(int count) {
    return '+$count more items';
  }

  @override
  String get addAttachment => 'Add';

  @override
  String get addAttachmentMore => 'More attachment types…';

  @override
  String get addImage => 'Add image';

  @override
  String get addPdf => 'Add PDF';

  @override
  String get addSlide => 'Add slides';

  @override
  String get pasteImage => 'Paste image from clipboard';

  @override
  String get clipboardEmpty => 'No image on the clipboard';

  @override
  String get noNoteSelected => 'Pick a note from the left';

  @override
  String attachmentFailed(String error) {
    return 'Couldn\'t add the attachment: $error';
  }

  @override
  String get attachmentCopying => 'Copying...';

  @override
  String get attachmentUploading => 'Uploading...';

  @override
  String get attachmentUploadFailed => 'Upload failed — tap to retry';

  @override
  String get attachmentNotSynced =>
      'This file hasn\'t synced to this device yet';

  @override
  String attachmentTooLarge(int limit) {
    return 'File is too large ($limit MB max)';
  }

  @override
  String storageFull(String limit) {
    return 'Storage is full ($limit). Delete old attachments to free up space.';
  }

  @override
  String get storageUsage => 'Storage';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used of $limit used';
  }

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get delete => 'Delete';

  @override
  String get color => 'Colour';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => 'Summarise note';

  @override
  String get aiAnalyze => 'Analyse';

  @override
  String get aiSectionNote => 'This note';

  @override
  String get aiSectionAttachments => 'Attachments';

  @override
  String get summarize => 'Summarise';

  @override
  String get summaryDetailTitle => 'Summary type';

  @override
  String get summaryShort => 'Short summary';

  @override
  String get summaryShortInfo =>
      'A few sentences of overview plus the key points';

  @override
  String get summaryDetailed => 'Detailed summary';

  @override
  String get summaryDetailedInfo =>
      'Thorough enough that you needn\'t open the original';

  @override
  String get listen => 'Listen';

  @override
  String get ask => 'Ask a question';

  @override
  String get extractText => 'Extract text';

  @override
  String get transcribe => 'Transcribe';

  @override
  String get listenToNote => 'Read aloud';

  @override
  String get aiNoApiKey => 'Enter your Gemini API key in Settings first';

  @override
  String aiError(String error) {
    return 'AI request failed: $error';
  }

  @override
  String get aiSummaryTitle => 'AI summary';

  @override
  String get aiThinking => 'Thinking...';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get settingsSearchHint => 'Search settings — “briefing”, “microphone”';

  @override
  String settingsSearchEmpty(String query) {
    return 'No setting matches «$query»';
  }

  @override
  String get settings => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Gemini API key';

  @override
  String get geminiApiKeyHint => 'Paste the key starting with AIza...';

  @override
  String get geminiApiKeyInfo =>
      'A key is optional: without one, AI requests go through the app\'s built-in service (a free daily allowance, higher with Premium). For unlimited use with your own key, get a free one at aistudio.google.com; the key is stored only on this device, in secure storage.';

  @override
  String aiBuiltInPremium(int count) {
    return 'Built-in AI: Premium — $count points left today';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Built-in AI: $count free points left today';
  }

  @override
  String get aiBuiltInByok => 'Using your own key — unlimited';

  @override
  String get aiReport => 'Report this answer';

  @override
  String get aiReportThanks => 'Report received, thank you';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get lockNote => 'Lock';

  @override
  String get unlockNote => 'Unlock';

  @override
  String get lockedNote => 'Locked note';

  @override
  String get unlockAuthReason => 'Verify your identity to open the locked note';

  @override
  String get exportBackup => 'Export backup (JSON)';

  @override
  String get expandListItems => 'Show list rows in full';

  @override
  String get expandListItemsInfo =>
      'Long list items wrap over several lines and stay fully visible. When off, a row stays on one line and expands when tapped.';

  @override
  String get quickCaptureRowSetting => 'Quick note bar';

  @override
  String get quickCaptureRowInfo =>
      'Shows a one-line \"New note...\" field at the top of the home screen. When off, use the + button.';

  @override
  String get emptyTrash => 'Empty bin';

  @override
  String emptyTrashConfirm(int count) {
    return '$count notes will be permanently deleted. This can\'t be undone. Are you sure?';
  }

  @override
  String get trashEmptied => 'Bin emptied';

  @override
  String get validateAndSave => 'Verify and save';

  @override
  String get clear => 'Clear';

  @override
  String get aiDiagnostics => 'AI diagnostics';

  @override
  String get aiDiagnosticsEmpty => 'No errors recorded';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Last $count error records';
  }

  @override
  String get apiKeyValid => 'API key verified and saved';

  @override
  String get apiKeyInvalid => 'API key is not valid';

  @override
  String get apiKeySavedBadge => 'Saved';

  @override
  String get removeApiKey => 'Delete key';

  @override
  String get refresh => 'Refresh';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get signOutAnonymousWarning =>
      'You are on a local account: signing out makes this account and ALL its notes permanently inaccessible — without a backup they cannot be recovered. Link a Google account first to keep your notes. Sign out anyway?';

  @override
  String get deleteAccount => 'Delete my account and data';

  @override
  String get deleteAccountWarning =>
      'This can\'t be undone: all your notes, attachments and your account will be permanently deleted. Are you sure you want to continue?';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get licensesTitle => 'Open-source licences';

  @override
  String get generating => 'Generating...';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get syncPending => 'Waiting to sync';

  @override
  String get synced => 'Synced';

  @override
  String genericError(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get addTag => 'Tag';

  @override
  String get tagHint => 'e.g. work, home, school';

  @override
  String get addReminder => 'Remind me';

  @override
  String get share => 'Share';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get archiveTitle => 'Archive';

  @override
  String get archiveEmpty => 'No notes in the archive';

  @override
  String get trashTitle => 'Bin';

  @override
  String get trashEmpty => 'The bin is empty';

  @override
  String get trashInfo =>
      'Deleted notes stay here; you can restore them or delete them for good.';

  @override
  String get restore => 'Restore';

  @override
  String get deleteForever => 'Delete permanently';

  @override
  String get deleteForeverConfirm =>
      'This note will be permanently deleted. Are you sure?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'The assistant wants to move the note \"$title\" to the trash. Do you approve?';
  }

  @override
  String get recordAudio => 'Voice recording';

  @override
  String get recording => 'Recording...';

  @override
  String get stopAndSave => 'Finish and add';

  @override
  String get micPermissionDenied => 'Microphone permission was denied';

  @override
  String get speechRecognitionFailed =>
      'Speech recognition didn\'t work. Check that microphone permission is granted and the Google app is up to date.';

  @override
  String get addDrawing => 'Add drawing';

  @override
  String get drawingTitle => 'Drawing';

  @override
  String get addToNote => 'Add to note';

  @override
  String get chatTitle => 'Note Assistant';

  @override
  String get chatHint =>
      'Ask about your notes: \"what was that recipe I wrote last week?\", \"what\'s missing from my shopping list?\"';

  @override
  String get chatInputHint => 'Type a question...';

  @override
  String get fontSize => 'Text size';

  @override
  String get fontSizePreview => 'Your notes will look like this';

  @override
  String get darkSchedule => 'Dark theme schedule';

  @override
  String get darkScheduleInfo =>
      'Switches to the dark theme between the hours you set';

  @override
  String get aiTranslate => 'Translate';

  @override
  String get voiceCommand => 'Voice command';

  @override
  String get semanticSearchToggle => 'Semantic search with AI';

  @override
  String get semanticSearchHint => 'Search by meaning: \"car expenses\"...';

  @override
  String get briefingTitle => 'Daily briefing';

  @override
  String get briefingLoading => 'Preparing your briefing...';

  @override
  String get briefingEmpty => 'Nothing for today';

  @override
  String get briefingSetting => 'Daily briefing notification';

  @override
  String get briefingSettingInfo =>
      'Get a notification with the day\'s summary each morning at the time you choose';

  @override
  String get autoTagSetting => 'Tag automatically';

  @override
  String get autoTagSettingInfo =>
      'When a note is closed without tags, AI adds a fitting one';

  @override
  String get suggestTags => 'Suggest tags';

  @override
  String get aiFixNote => 'Fix up the note';

  @override
  String get fixLevelTitle => 'How much should be fixed?';

  @override
  String get fixSimple => 'Light';

  @override
  String get fixSimpleInfo => 'Spelling and typos only';

  @override
  String get fixBalanced => 'Balanced';

  @override
  String get fixBalancedInfo => 'Sentence structure too, for cleaner writing';

  @override
  String get fixDetailed => 'Thorough';

  @override
  String get fixDetailedInfo => 'Rewrites the whole text from top to bottom';

  @override
  String get existingTagsLabel => 'Previous tags';

  @override
  String get aiSkipCheckedSetting => 'Leave ticked items out of AI edits';

  @override
  String get aiSkipCheckedInfo =>
      'When AI fixes or translates a checklist, completed (ticked) items are kept exactly as they are; only unticked items are edited.';

  @override
  String get noteUpdatedUndo => 'Note updated';

  @override
  String get aiImprove => 'Improve the note';

  @override
  String get improveFormal => 'Make it more formal';

  @override
  String get improveShorten => 'Shorten';

  @override
  String get improveBullets => 'Turn into a bullet list';

  @override
  String get improveNumbered => 'Turn into a numbered list';

  @override
  String get replaceNote => 'Replace the note';

  @override
  String get openAsNewNote => 'As a new note';

  @override
  String get pdfChatHint =>
      'Ask about this PDF: \"summarise it\", \"is there a penalty clause?\", \"what\'s the deadline?\"';

  @override
  String get pdfChatInputHint => 'Type a question about the PDF...';

  @override
  String get voiceCaptureHint =>
      'Speak: \"buy milk and bread\" or \"meeting tomorrow at 9, remind me\" — AI builds your note when you\'re done.';

  @override
  String get voiceFinish => 'Finish';

  @override
  String get voiceProcessing => 'Applying what you said...';

  @override
  String get voiceNothingHeard => 'No speech detected in the recording';

  @override
  String get voiceNoteSaved => 'Your voice note has been saved';

  @override
  String get openNote => 'Open note';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersEmpty => 'No reminders';

  @override
  String get remindersEmptyHint =>
      'Add a reminder to a note, or create a new note with a reminder using the + button';

  @override
  String get remindersUpcoming => 'Upcoming';

  @override
  String get remindersPast => 'Past';

  @override
  String get reminderInPast =>
      'The selected time is in the past — pick a future time.';

  @override
  String get newReminder => 'New reminder';

  @override
  String get remindersUntitled => 'Untitled note';

  @override
  String get remindersEdit => 'Change the time';

  @override
  String get remindersRemove => 'Remove reminder';

  @override
  String get aiModelChat => 'Summaries, titles, tags and chat';

  @override
  String get aiModelDocument => 'Document chat and PDF summary';

  @override
  String get aiModelTranslate => 'Translation';

  @override
  String get aiModelVoice => 'Voice note assistant';

  @override
  String get aiModelAuto => 'Automatic (recommended)';

  @override
  String get aiModelsInfo =>
      'You can pick a separate model per job: short text work is fine on a fast model, long documents want a capable one. If your chosen model hits its quota or is withdrawn, the next one is tried automatically.';

  @override
  String get clearNote => 'Clear';

  @override
  String get clearNoteConfirm =>
      'The note\'s contents (text and list items) will be deleted. Are you sure?';

  @override
  String get themePaper => 'Paper';

  @override
  String get calculatorTitle => 'Calculator';

  @override
  String get calcExpressionHint => 'e.g. 12.5×3+40';

  @override
  String get calcInvalid => 'Invalid expression';

  @override
  String get liveDictation => 'Dictate';

  @override
  String get voiceCaptureAi => 'Voice capture (AI)';

  @override
  String get dictationListening => 'Listening... text appears as you speak';

  @override
  String get dictationNoKeyInfo =>
      'Live dictation isn\'t available on this device; the recording will be transcribed in one go when you stop.';

  @override
  String get dictationHoldHint =>
      'Hold the microphone and speak; text is written when you let go';

  @override
  String itemsSelected(int count) {
    return '$count items selected';
  }

  @override
  String get noteChatTitle => 'Chat with this note';

  @override
  String get noteChatHint => 'Ask something about this note';

  @override
  String get noteChatIntro =>
      'The note\'s contents and attachments (PDF/image) are read, and your question is answered from them.';

  @override
  String get dictationProcessing => 'Transcribing...';

  @override
  String get aiDailyManualInfo =>
      'On the free plan this isn\'t generated automatically, so it doesn\'t eat your daily allowance. You can generate it once a day with the button below.';

  @override
  String get aiGenerate => 'Generate';

  @override
  String get aiGeneratedTodayInfo =>
      'This was generated today. On the free plan it refreshes once a day; you can generate it again tomorrow.';

  @override
  String get voiceAssistantTitle => 'Voice note assistant';

  @override
  String get voiceListening => 'Listening...';

  @override
  String get voiceHoldHint =>
      'Hold and speak; your note is created when you let go';

  @override
  String get voiceTapHint => 'Tap and speak; tap again to finish';

  @override
  String get voiceTooShort => 'That recording was too short, try again';

  @override
  String get voiceModeSetting => 'How it works';

  @override
  String get voiceModeHold => 'Hold to talk';

  @override
  String get voiceModeTap => 'Tap to start / tap to stop';

  @override
  String get voiceModeInfo =>
      'Hold to talk: it listens while you hold the button and creates the note when you let go. Tap to start: one tap begins recording, a second tap ends it.';

  @override
  String get voiceHeardLive => 'Speech detected';

  @override
  String get voiceCaptureReady => 'Speech ready';

  @override
  String get voiceCaptureEditHint => 'Tap the text to edit';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · automatic punctuation';
  }

  @override
  String get voiceCaptureAddToNote => 'Add to note';

  @override
  String get voiceCaptureCreateNote => 'Create new note';

  @override
  String get voiceCaptureAiNote => 'AI note';

  @override
  String get voiceCapturePlainNote => 'Plain note';

  @override
  String get voiceCloseTitle => 'Your dictation is still here';

  @override
  String get voiceCloseKeepTalking => 'Keep talking';

  @override
  String get voiceCaptureRestart => 'Record again';

  @override
  String get voiceChipSummarizeAdd => 'Add as summary';

  @override
  String get voiceChipSummarizeSave => 'Save as summary';

  @override
  String get voiceChipToItems => 'Split into items';

  @override
  String get voiceChipAsList => 'Make a checklist';

  @override
  String get voiceChipFix => 'Clean up';

  @override
  String get voiceChipCompose => 'Let the assistant write it';

  @override
  String get editorToolList => 'List';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permMic => 'Microphone';

  @override
  String get permMicInfo => 'Needed for voice notes and dictation';

  @override
  String get permNotifications => 'Notifications';

  @override
  String get permNotificationsInfo =>
      'Needed for reminders and the daily briefing';

  @override
  String get permBattery => 'Battery optimisation';

  @override
  String get permBatteryInfo =>
      'Exempt the app from battery restrictions so reminders arrive on time';

  @override
  String get showTagChips => 'Show tag chips';

  @override
  String get showFolderChips => 'Show folder chips';

  @override
  String videoTooBigForAi(int mb) {
    return 'The video is too large to send to AI ($mb MB). Record a shorter one.';
  }

  @override
  String get permCamera => 'Camera';

  @override
  String get permCameraInfo => 'Needed for video notes and taking photos';

  @override
  String get permOnboardTitle => 'Before you start';

  @override
  String get permOnboardInfo =>
      'Notes only asks for these permissions when you use the matching feature. You can grant them now below, or change them later under Settings > Permissions.';

  @override
  String get permOnboardGrantAll => 'Grant permissions';

  @override
  String get permOnboardSkip => 'Not now';

  @override
  String get newVideoNote => 'Video note';

  @override
  String get videoLocalOnly =>
      'This video is stored only on this device (not uploaded to the cloud)';

  @override
  String get videoToNote => 'Make a note from the video';

  @override
  String get videoToNoteRunning => 'Reviewing the video…';

  @override
  String get permGranted => 'Granted';

  @override
  String get permGrant => 'Grant';

  @override
  String get permOpenSettings => 'Open settings';

  @override
  String get newHandwriting => 'Handwriting';

  @override
  String get newVoiceCapture => 'Voice note';

  @override
  String get suggestTitle => 'Suggest a title';

  @override
  String get noteMetaMenu => 'Tag · Title · Reminder';

  @override
  String get folder => 'Folder';

  @override
  String get noFolder => 'No folder';

  @override
  String get newFolder => 'New folder';

  @override
  String get editFolder => 'Edit folder';

  @override
  String get deleteFolder => 'Delete folder';

  @override
  String deleteFolderConfirm(String name) {
    return 'The folder \"$name\" will be deleted. The notes inside aren\'t deleted — they\'ll just have no folder.';
  }

  @override
  String get folderNameHint => 'Folder name';

  @override
  String get folderIcon => 'Icon';

  @override
  String get editFilters => 'Edit filters';

  @override
  String get editFiltersInfo =>
      'Choose which filters appear on the home screen. Hiding filters keeps the page tidy.';

  @override
  String get select => 'Select';

  @override
  String get noteArchived => 'Note archived';

  @override
  String deleteChecked(int count) {
    return 'Delete ticked ($count)';
  }

  @override
  String get removeItem => 'Delete item';

  @override
  String get copyWholeNote => 'Copy the whole note';

  @override
  String get allCopied => 'The whole note was copied to the clipboard';

  @override
  String get speechPlay => 'Read aloud';

  @override
  String get speechPause => 'Pause';

  @override
  String get speechResume => 'Resume';

  @override
  String get speechStop => 'Stop';

  @override
  String get speechRate => 'Reading speed';

  @override
  String get speechSystemDefault => 'System default';

  @override
  String get speechNoVoices => 'No voices are installed on this device';

  @override
  String speechVoiceLanguage(String language) {
    return '$language voice';
  }

  @override
  String get speechVoiceAutoInfo =>
      'Other languages are read with a male voice automatically';

  @override
  String get listening => 'Listening...';

  @override
  String get listenPlay => 'Listen';

  @override
  String get listenReadingPdf => 'Reading the document...';

  @override
  String get listenConvertWithAi => 'Convert with AI';

  @override
  String get listenMakePodcast => 'Full podcast';

  @override
  String get listenMakePodcastSummary => 'Summary podcast';

  @override
  String get listenOriginalText => 'Original text';

  @override
  String get listenPodcastReady => 'Podcast narration is ready';

  @override
  String get listenPodcastCached => 'Generated earlier — no tokens spent';

  @override
  String get listenRegenerate => 'Generate again';

  @override
  String get listenNoText =>
      'No readable text came out of this document. A scanned PDF has no text layer, and a presentation may contain images only.';

  @override
  String get readDocument => 'Read a document (Word, PDF, slides)';

  @override
  String get readDocUnsupported => 'This file type can\'t be read.';

  @override
  String get exportPdf => 'Export as PDF';

  @override
  String get pdfTitleField => 'Title';

  @override
  String get pdfContentField => 'Content';

  @override
  String get pdfMarkupHint =>
      'Marks at the start of a line become formatting: [x] and [ ] for tick boxes, 1. for a numbered list, - for a bullet.';

  @override
  String get pdfIncludeDate => 'Include the date';

  @override
  String get exportIncludeImages => 'Include images';

  @override
  String get exportWord => 'Share as Word (.docx)';

  @override
  String get pdfPreview => 'Preview';

  @override
  String get largeAttachmentTitle => 'Large file';

  @override
  String largeAttachmentBody(String size) {
    return 'This file is $size MB. PDFs can\'t be compressed; it will be uploaded as-is and count against your storage. Continue?';
  }

  @override
  String get speechRateForeign => 'Foreign-language speed';

  @override
  String notesArchivedCount(int count) {
    return '$count notes archived';
  }

  @override
  String get backgroundColor => 'Background colour';

  @override
  String get backgroundColorInfo => 'The note\'s background colour';

  @override
  String get frameColor => 'Frame';

  @override
  String get frameColorInfo =>
      'Draws a frame around the note in the colour you pick';

  @override
  String get sortBy => 'Sort';

  @override
  String get reorderNotes => 'Reorder notes';

  @override
  String get reorderModeActive => 'Drag the cards to reorder';

  @override
  String get reorderDone => 'Done';

  @override
  String get sortManual => 'Manual (drag order)';

  @override
  String get sortUpdated => 'Recently updated';

  @override
  String get sortCreated => 'Date created';

  @override
  String get sortTitle => 'By title (A–Z)';

  @override
  String get foldersSection => 'Folders';

  @override
  String get tagsSection => 'Tags';

  @override
  String get expandFilters => 'Expand filters';

  @override
  String get collapseFilters => 'Collapse filters';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System language';

  @override
  String get settingsSpeech => 'Read aloud';

  @override
  String get aiAdvanced => 'Advanced: model and API key';

  @override
  String get aiAdvancedInfo =>
      'Model choice and your own Gemini key. Most people don\'t need this.';

  @override
  String get openBriefing => 'Open the briefing';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncLimitTitle => 'Automatic upload limit';

  @override
  String get syncLimitInfo =>
      'Attachments larger than this stay on the device and aren\'t uploaded. Note text always syncs.';

  @override
  String get syncLimitUnlimited => 'No limit';

  @override
  String get backupTitle => 'Backup';

  @override
  String get importBackup => 'Restore from backup (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count notes restored';
  }

  @override
  String get importBackupInvalid => 'Invalid backup file';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => 'Produces a short summary';

  @override
  String get aiAnalyzeInfo => 'Lists the key points and to-dos';

  @override
  String get aiImproveInfo => 'Changes the tone: formal, shorter or a list';

  @override
  String get aiTranslateInfo => 'Translates the note into a language you pick';

  @override
  String get aiFixNoteInfo => 'Fixes spelling and punctuation';

  @override
  String get moveToFolder => 'Move to folder';

  @override
  String get voiceAssistantBadge => 'Assistant';

  @override
  String get assistantGenericError =>
      'Something went wrong — could you try again?';

  @override
  String get quickAddTooltip => 'New note — pick a type';

  @override
  String get autoTitleSetting => 'Suggest a title on close';

  @override
  String get autoTitleSettingInfo =>
      'When you leave the editor, a note left without a title gets a short one written from its contents.';

  @override
  String get hubChatInfo => 'Questions answered from your notes';

  @override
  String get hubBriefingInfo =>
      'Your day at a glance: reminders and recent notes';

  @override
  String get hubReadInfo => 'Listen to a PDF or Word document';

  @override
  String get annotate => 'Annotate';

  @override
  String get annotateDone => 'Finish annotating';

  @override
  String get newPdfNote => 'Add PDF, take notes';

  @override
  String get imageNotePreparing => 'Arranging images into a document…';

  @override
  String get newImageNote => 'Add image, take notes';

  @override
  String get pdfPageNoteHint => 'Note for this page…';

  @override
  String pdfPage(int page) {
    return 'Page $page';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Page $page / $total';
  }

  @override
  String get pdfPreviousPage => 'Previous page';

  @override
  String get pdfNextPage => 'Next page';

  @override
  String get pdfFullScreen => 'Open full screen';

  @override
  String get pdfNoDocument => 'This note has no PDF yet';

  @override
  String get pdfChooseDocument => 'Choose PDF';

  @override
  String get newSlidesNote => 'Add slides, take notes';

  @override
  String get slidesNoDocument => 'This note has no presentation yet';

  @override
  String get slidesChooseDocument => 'Choose presentation';

  @override
  String get pdfEditPages => 'Edit pages';

  @override
  String get pdfDeletePages => 'Delete selected pages';

  @override
  String get pdfAddBlankPage => 'Add blank page';

  @override
  String get pdfRotatePages => 'Rotate';

  @override
  String get pdfBurnInk => 'Burn handwriting into the document';

  @override
  String get pdfApplyChanges => 'Apply changes';

  @override
  String get pdfCannotDeleteAllPages => 'You can\'t delete every page';

  @override
  String get pdfPagesHint =>
      'Tap a page to select it. Page notes travel with their page; a deleted page\'s note is hidden but kept in your data.';

  @override
  String pdfEditFailed(String error) {
    return 'Couldn\'t edit the PDF: $error';
  }

  @override
  String get pdfInkBurned => 'Handwriting burned into the document';

  @override
  String get pdfAllPageNotes => 'All page notes';

  @override
  String get pdfNoPageNotes =>
      'No page notes yet. Turn to a page and write in the field below.';

  @override
  String get crop => 'Crop';

  @override
  String get cropApply => 'Apply crop';

  @override
  String get cropReset => 'Reset selection';

  @override
  String get cropHint =>
      'Drag the corners to choose an area. Cropping can\'t be undone.';

  @override
  String get cropFailed => 'Couldn\'t crop the image.';

  @override
  String get penBallpoint => 'Ballpoint pen';

  @override
  String get penMarker => 'Marker';

  @override
  String get penHighlighter => 'Highlighter';

  @override
  String get eraser => 'Eraser';

  @override
  String get inkArrow => 'Arrow';

  @override
  String get clearInk => 'Clear annotations';

  @override
  String get inkTwoFingerHint => 'One finger draws · two fingers pan and zoom';

  @override
  String get slideOpenFailed => 'The presentation couldn\'t be opened';

  @override
  String get newPhotoNote => 'Photo note';

  @override
  String get newScanNote => 'Scan a document';

  @override
  String get scanDocument => 'Scan document';

  @override
  String get scanDocumentSubtitle =>
      'Finds the edges, flattens the page and adds it';

  @override
  String get scanUnsupported =>
      'Document scanning is not supported on this device';

  @override
  String scanFailed(String error) {
    return 'Could not scan the document: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count page(s) added to the note';
  }

  @override
  String get scanTextTitle => 'Recognise the text too?';

  @override
  String get scanTextBody =>
      'The text on the pages is recognised and written into the note. The image stays as it is. Takes a few seconds per page.';

  @override
  String get scanImageOnly => 'Image only';

  @override
  String get scanRecognizeText => 'Recognise text';

  @override
  String get scanRecognizing => 'Recognising text…';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get qrScanTitle => 'Scan a QR code';

  @override
  String get qrScanSubtitle => 'Read it with the camera or from a photo';

  @override
  String get qrScanHint => 'Line the code up inside the frame';

  @override
  String get qrFromPhoto => 'Read from a photo';

  @override
  String get qrNotFound => 'No code found in this image';

  @override
  String get qrLinkFound => 'This code is a link';

  @override
  String get qrOpenLink => 'Go to the link';

  @override
  String get qrSaveToNote => 'Save to a note';

  @override
  String get openLink => 'Open link';

  @override
  String get linkOpenFailed => 'The link couldn\'t be opened';

  @override
  String qrScanFailed(String error) {
    return 'Couldn\'t read the code: $error';
  }

  @override
  String get qrTorch => 'Torch';

  @override
  String attachmentsCount(int count) {
    return 'Attachments ($count)';
  }

  @override
  String get hideAttachments => 'Hide';

  @override
  String get showAttachments => 'Show';

  @override
  String get videoBack10 => 'Back 10s';

  @override
  String get videoForward10 => 'Forward 10s';

  @override
  String get selectAllItems => 'Select all';

  @override
  String get showAllChips => 'Show all';

  @override
  String get hideAllChips => 'Hide all';

  @override
  String get chipPickInfo =>
      'Which folder and tag chips should appear on the home screen?';

  @override
  String get hiddenFolder => 'Hidden folder';

  @override
  String get hiddenFolderInfo =>
      'A hidden folder and the notes in it don\'t appear on the home screen. To show them, pick \"Hidden folders\" from the ⋮ menu and verify your identity.';

  @override
  String get hiddenFoldersMenu => 'Hidden folders';

  @override
  String get hiddenFolderAuthReason =>
      'Verify your identity to show hidden folders';

  @override
  String get hiddenFoldersShown => 'Hidden folders are showing';

  @override
  String get hiddenFoldersHiddenAgain => 'Hidden folders are tucked away again';

  @override
  String get makeFolderHidden => 'Hide';

  @override
  String get makeFolderVisible => 'Unhide';

  @override
  String gridColumnsCount(int count) {
    return '$count columns';
  }

  @override
  String get addImageOnPageSubtitle => 'Sits on the page, text flows around it';

  @override
  String get addImageAsFile => 'Add image as a file';

  @override
  String get addImageAsFileSubtitle =>
      'Stays out of the page, in the attachment strip';

  @override
  String get moveImageToAttachments => 'Move to attachments';

  @override
  String get moveImageToPage => 'Place on page';

  @override
  String get attachmentCopied => 'Attachment copied';

  @override
  String get pasteAttachment => 'Paste copied attachment';

  @override
  String get fullscreen => 'Full screen';

  @override
  String get more => 'More';

  @override
  String get undone => 'Undone';

  @override
  String get filterOthers => 'Others';

  @override
  String get chatSuggestion1 => 'What is missing from my shopping list?';

  @override
  String get chatSuggestion2 => 'Summarise this week\'s work notes';

  @override
  String get chatSuggestion3 => 'Do I have a reminder for tomorrow?';

  @override
  String get aiPointsToday => 'Today\'s points';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'renews at midnight';

  @override
  String get aiChatWithNotes => 'Note Assistant';

  @override
  String get aiChatInputHint => 'Ask something about your notes…';

  @override
  String get aiChatLooking => 'looking through your notes…';

  @override
  String get aiChatFullScreen => 'Full screen';

  @override
  String get aiOnYourNotes => 'ON YOUR NOTES';

  @override
  String get aiTaskDuplicates => 'Clean up duplicates';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count duplicate notes';
  }

  @override
  String get duplicatesTitle => 'Duplicate notes';

  @override
  String get duplicatesHint =>
      'The oldest note in each group is kept, the rest go to the trash.';

  @override
  String get duplicatesKeepBadge => 'kept';

  @override
  String get duplicatesDeleteAll => 'Move duplicates to trash';

  @override
  String duplicatesDone(int count) {
    return '$count duplicates moved to trash';
  }

  @override
  String get aiRecentActions => 'RECENT ACTIONS';

  @override
  String get aiHistoryClear => 'Clear';

  @override
  String get aiHistoryQuestion => 'Question';

  @override
  String get aiHistoryNoteAction => 'Note action';

  @override
  String get aiHistoryVoiceNote => 'Voice note';

  @override
  String get aiRecentOps => 'RECENT';

  @override
  String get aiTaskWeekSummary => 'Summarise the week';

  @override
  String get aiTaskWeekSummaryInfo => 'One summary from the last 7 days';

  @override
  String get aiTaskTagUntagged => 'Tag the untagged';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count notes waiting for tags';
  }

  @override
  String get aiTaskSuggestTitles => 'Suggest titles';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count notes have no title';
  }

  @override
  String get sectionPinnedShort => 'PINNED';

  @override
  String get sectionToday => 'TODAY';

  @override
  String get sectionThisWeek => 'THIS WEEK';

  @override
  String get sectionEarlier => 'EARLIER';

  @override
  String sectionNoteCount(int count) {
    return '$count notes';
  }

  @override
  String get emptySearchSemanticHint => 'Try the Meaning tab';

  @override
  String get quickCaptureHint => 'New note…';

  @override
  String get quickCaptureSave => 'Save';

  @override
  String get quickAddWrite => 'WRITE';

  @override
  String get quickAddCapture => 'CAPTURE — CREATES A NOTE FROM CONTENT';

  @override
  String get viewToggle => 'View';

  @override
  String get searchModeText => 'Text';

  @override
  String get searchModeMeaning => 'Meaning';

  @override
  String get filterReminded => 'With reminder';

  @override
  String get filterLocked => 'Locked';

  @override
  String get sortColor => 'Colour';

  @override
  String get sortActive => 'Most worked on';

  @override
  String get voicePreview => 'Try the voice';

  @override
  String get voicePreviewCached =>
      'The sample is generated once, then played from storage';

  @override
  String get reorderHint =>
      'Press and hold a card, then drag it where you want';

  @override
  String get filterSheetTitle => 'Filter';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterSectionStatus => 'STATUS';

  @override
  String get filterSectionFolder => 'FOLDER';

  @override
  String get filterSectionTag => 'TAG';

  @override
  String get filterSectionSort => 'SORT';

  @override
  String get filterFavoriteHint =>
      'Tap a star to keep that option on the home screen';

  @override
  String get filterSheetSortHint =>
      'Date groups (TODAY, THIS WEEK…) are only shown when sorting by last edited.';

  @override
  String get formatTitle => 'Format';

  @override
  String get formatBold => 'Bold';

  @override
  String get formatItalic => 'Italic';

  @override
  String get formatUnderline => 'Underline';

  @override
  String get formatTextColor => 'Text colour';

  @override
  String get formatHighlight => 'Highlight';

  @override
  String get formatInfo =>
      'Formatting travels inside the text as markers (like **bold**); markers stay hidden in exports and read-aloud.';

  @override
  String get formatMenu => 'Format…';

  @override
  String get noteFont => 'Font';

  @override
  String get noteFontDefault => 'Default';

  @override
  String get noteFontSerif => 'Book (serif)';

  @override
  String get noteFontMono => 'Typewriter';

  @override
  String get noteTextSize => 'Text size';

  @override
  String get formatClear => 'Clear formatting';

  @override
  String get noteTextOpacity => 'Opacity';

  @override
  String get assistantVoiceSetting => 'Assistant speaks replies';

  @override
  String get assistantVoiceSettingInfo =>
      'The voice assistant reads its reply out loud (phone only).';

  @override
  String get assistantMute => 'Mute';

  @override
  String get assistantUnmute => 'Unmute';

  @override
  String get assistantMakeNote => 'Turn into a note anyway';

  @override
  String get assistantNoteCreated => 'Note created';

  @override
  String get noteNotFound => 'Note not found. It may have been deleted.';

  @override
  String get back => 'Back';

  @override
  String get addTextBlock => 'Add text';

  @override
  String get attachNoteContent => 'Note content';

  @override
  String get noteBackgroundImage => 'Background image';

  @override
  String get chooseBackgroundImage => 'Choose image';

  @override
  String get changeBackgroundImage => 'Change image';

  @override
  String get removeBackgroundImage => 'Remove background';

  @override
  String get dashboardBackground => 'Home screen background';

  @override
  String get dashboardBackgroundInfo =>
      'Image shown behind the note grid (this device only).';

  @override
  String get aiProvider => 'AI provider';

  @override
  String get aiProviderInfo =>
      'Choose the provider your own key belongs to. Each provider’s key is stored separately, so switching back does not require typing it again.';

  @override
  String get apiKeyFieldLabel => 'API key';

  @override
  String get getApiKey => 'Where do I get a key?';

  @override
  String get recommendedModel => 'Recommended';

  @override
  String get freeTierBadge => 'Has a free tier';

  @override
  String get continueWithoutAccount => 'Continue without an account';

  @override
  String get localAccountInfo =>
      'Your notes stay on this device only: they cannot be opened elsewhere, they are gone if you uninstall the app, and built-in AI is off. You can link a Google account at any time — your notes carry over.';

  @override
  String get localAccountBadge => 'Local account';

  @override
  String get linkGoogleAccount => 'Link a Google account';

  @override
  String get accountLinked =>
      'Your Google account is linked. Your notes are backed up now.';

  @override
  String scanReviewPage(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String get scanRotatePage => 'Rotate page';

  @override
  String get scanDeletePage => 'Delete page';

  @override
  String get scanLastPage => 'The last page cannot be deleted';

  @override
  String get scanDiscardTitle => 'Discard scanned pages?';

  @override
  String get scanDiscardConfirm => 'Discard';

  @override
  String get scanAdjustCorners => 'Adjust corners';

  @override
  String get scanFilterOriginal => 'Original';

  @override
  String get scanFilterAuto => 'Enhance';

  @override
  String get scanFilterGray => 'Grayscale';

  @override
  String get scanFilterBw => 'Black & white';

  @override
  String get scanApplyAll => 'Apply to all';

  @override
  String get scanPageFailed => 'Could not display the page';

  @override
  String get scanCropHint => 'Fix a skewed page with \"Adjust corners\"';

  @override
  String get scanAddAsPdf => 'Add as PDF';

  @override
  String get scanAddAsImages => 'Add as images';

  @override
  String get scanBuildingPdf => 'Preparing PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Recognizing text… $done/$total';
  }

  @override
  String get scanAutoDetect => 'Auto-detect edges';

  @override
  String get scanReset => 'Reset';

  @override
  String get scanDetecting => 'Looking for edges…';

  @override
  String get scanAutoFound =>
      'Edges found automatically; fine-tune with the handles if needed';

  @override
  String get scanDragHint => 'Drag the corners to the edges of the paper';

  @override
  String get scanApplyCorners => 'Straighten & apply';

  @override
  String get scanWorking => 'Straightening…';

  @override
  String get scanPdfAdded => 'Scan added to the note as a PDF attachment';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium active — until $date';
  }

  @override
  String get premiumStatusFree => 'You are using the free version';

  @override
  String get premiumPerksTitle => 'What changes with Premium?';

  @override
  String get premiumPerkAi => 'Daily AI points';

  @override
  String get premiumPerkAttach => 'Attachment size';

  @override
  String get premiumPerkStorage => 'Cloud storage';

  @override
  String get premiumPerkAuto => 'Automatic daily content';

  @override
  String get premiumPerkAutoBody =>
      'The daily briefing and suggestions are prepared automatically every day; on free they only run on demand.';

  @override
  String get premiumHowTitle => 'How to get it?';

  @override
  String get premiumHowBody =>
      'Premium will soon be available through the Play Store. We are currently in early access.';

  @override
  String get premiumByokHint =>
      'If you enter your own Gemini API key, AI features run without quota — independent of Premium (Settings → AI).';

  @override
  String get premiumDiscoverTitle => 'Features you may have missed';

  @override
  String get discoverScanBody =>
      'Scanned pages are straightened and enhanced, then turned into a SEARCHABLE PDF with one tap — the text layer is produced on device, for free.';

  @override
  String get discoverSemanticBody =>
      'The \"Smart\" tab in the search box searches by MEANING, not words: type \"flight times\" and your travel note shows up.';

  @override
  String get discoverAssistantBody =>
      'The microphone on the home screen turns your speech into notes, lists and reminders by itself — just say \"dentist tomorrow at 9\".';

  @override
  String get discoverLockBody =>
      'You can lock a note with fingerprint/face: its content never leaks into search, widgets or AI.';

  @override
  String get discoverHiddenBody =>
      'Notes in a hidden folder never appear on the home screen or in search; revealing the folder requires authentication.';

  @override
  String get discoverExportBody =>
      'Every note can be exported as PDF or Word, images included (in the share menu).';

  @override
  String get guestSignInUnavailable =>
      'Signing in without Google is currently off: Anonymous sign-in is not enabled in the Firebase console (Authentication → Sign-in method). Sign in with Google, or try again once an admin enables it.';

  @override
  String get googleSignInUnavailable =>
      'Google sign-in is currently off: the Google provider is not enabled in the Firebase console.';

  @override
  String get signInNetworkError =>
      'Couldn\'t reach the internet. Check your connection and try again.';

  @override
  String get signInCanceled => 'Sign-in canceled.';

  @override
  String get cardRichPreview => 'Formatted text on cards';

  @override
  String get cardRichPreviewInfo =>
      'Colors, highlights, bold and underline from your notes also show on the home screen cards. When off, cards show plain text.';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeMedium => 'Medium';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeXLarge => 'Extra large';

  @override
  String get appFontSetting => 'Font';

  @override
  String get appFontInfo =>
      'The font used everywhere in the app. A note\'s own font choice overrides it. All fonts ship with the app — no internet needed.';

  @override
  String get fontGroupSans => 'Sans';

  @override
  String get fontGroupSerif => 'Serif';

  @override
  String get fontGroupMono => 'Monospace';

  @override
  String get fontGroupHand => 'Handwriting';

  @override
  String get appFontDefaultSuffix => 'default';

  @override
  String get pdfSelectOcrRunning => 'Recognising text…';

  @override
  String get pdfSelectOcrNone => 'No text found on this page';

  @override
  String pdfSelectCopied(int n) {
    return '$n characters copied';
  }

  @override
  String get bubbleAdd => 'Drop a note bubble';

  @override
  String get bubbleAddDone => 'Done adding bubbles';

  @override
  String get bubbleCollapse => 'Collapse bubble';

  @override
  String get bubbleHint => 'Write your note here…';

  @override
  String get bubbleTapToPlace => 'Tap the page where you want the bubble';

  @override
  String get aiModelPodcast => 'Podcast narration';

  @override
  String get listenAiVoice => 'Listen with AI voice';

  @override
  String get listenAiVoiceInfo =>
      'Gemini narrates instead of the device voice: more natural, but each paragraph costs a model call.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'AI narration failed ($error). Reading with the device voice.';
  }

  @override
  String get ttsSectionTitle => 'Narration';

  @override
  String get ttsEngineDevice => 'Device voice';

  @override
  String get ttsEngineAi => 'AI';

  @override
  String get ttsEngineDeviceInfo =>
      'The built-in device voice reads: free, offline and unlimited in length.';

  @override
  String get ttsEngineAiInfo =>
      'Gemini\'s speech model reads: noticeably more natural, but each paragraph is a model call and it needs your own Gemini key.';

  @override
  String get ttsEngineAiUnavailable =>
      'The AI voice needs your own Gemini key. Until you add one, reading uses the device voice.';

  @override
  String get ttsModel => 'Speech model';

  @override
  String get ttsVoice => 'AI voice';

  @override
  String get shareAsNote => 'Share as note';

  @override
  String get shareAsNoteInfo =>
      'Sends the note with its attachments, page notes, drawings and bubbles; the other side opens it exactly the same in the Not app.';

  @override
  String get shareAsNotePreparing => 'Preparing note package…';

  @override
  String get shareAsText => 'As plain text';

  @override
  String get shareAsTextInfo =>
      'Sends the note\'s text and page notes to any app.';

  @override
  String get shareAsTextEmpty => 'This note has no text to share.';

  @override
  String get sharePdfWithBubbles => 'As PDF with bubbles';

  @override
  String get sharePdfWithBubblesInfo =>
      'Bubbles, highlights and drawings are stamped into the PDF; anyone can open it, and in Not it opens editable.';

  @override
  String get sharePdfWithBubblesNone =>
      'This note has no PDF carrying bubbles or drawings.';

  @override
  String get sharePdfWithBubblesPreparing => 'Preparing PDF with bubbles…';

  @override
  String get sharePdfWithBubblesSuffix => ' (with bubbles)';

  @override
  String get bubbleStar => 'Star';

  @override
  String get bubbleEdit => 'Edit bubble';

  @override
  String get bubbleStarredOnly => 'Starred only';

  @override
  String get bubbleSearchHint => 'Search bubbles…';

  @override
  String get bubblesOverviewTitle => 'Bubbles';

  @override
  String get bubblesEmpty =>
      'No bubbles yet. Select text in the document and highlight it, or drop a bubble on the page.';

  @override
  String get bubblesNoMatch => 'No bubble matches your search.';

  @override
  String get bubbleNoText => '(empty bubble)';

  @override
  String get pdfHighlight => 'Highlight';

  @override
  String get pdfHighlightWithNote => 'Highlight + note';

  @override
  String get pageNotesShow => 'Show page note';

  @override
  String get pageNotesHide => 'Hide page note';

  @override
  String get bubbleSave => 'Save';

  @override
  String get bubbleTitleHint => 'Title';

  @override
  String get bubbleUrgent => 'Urgent (blinks)';

  @override
  String get captureModeQuestion => 'How should the note open?';

  @override
  String get captureModeBubbles => 'Bubbles';

  @override
  String get captureModeBubblesInfo =>
      'Content becomes a document page: bubbles, highlights and pen.';

  @override
  String get captureModeClassic => 'Classic';

  @override
  String get captureModeClassicInfo =>
      'Plain text note; content goes in as an attachment.';

  @override
  String get captureModeNew => 'NEW';

  @override
  String get imagePrepareTitle => 'Adjust images';

  @override
  String get imagePrepareDone => 'Continue';

  @override
  String get imageRotateLeft => 'Rotate left';

  @override
  String get imageRotateRight => 'Rotate right';

  @override
  String get videoFrameFailed =>
      'Couldn\'t grab a frame from the video; opening a classic note.';

  @override
  String get bubbleArrowHide => 'Hide arrow';

  @override
  String get bubbleArrowShow => 'Show arrow';

  @override
  String get speechPitch => 'Voice pitch';

  @override
  String get speechVoicePickerTitle => 'Voice selection';

  @override
  String get formatRemove => 'Remove';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportNotesOption => 'Note text (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'The note’s text and images; bubbles not included.';

  @override
  String get captureNoteTitle => 'Note title (optional)';

  @override
  String get captureNoteTitleHint => 'The new document gets this name too';

  @override
  String get imageOcrTitle => 'Recognize text in image';

  @override
  String get imageOcrNone => 'No text found in this image.';

  @override
  String imageOcrHint(int count) {
    return '$count lines found · tap to select';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count lines selected';
  }

  @override
  String get imageOcrShort => 'Recognize text';

  @override
  String get imageOcrWorking => 'Recognizing text…';

  @override
  String get imageOcrSelectHint =>
      'Tap: word · Hold and drag: letter by letter';

  @override
  String get imageOcrInsert => 'Add to note';

  @override
  String get imageOcrZoomIn => 'Zoom in';

  @override
  String get imageOcrZoomOut => 'Zoom out';

  @override
  String get selectImages => 'Select images';

  @override
  String get exportImages => 'Images';

  @override
  String get exportImagesInfo =>
      'Text flows beside narrow images aligned left or right; centred images take the full width.';

  @override
  String get exportAlignLeft => 'Left';

  @override
  String get exportAlignCenter => 'Centre';

  @override
  String get exportAlignRight => 'Right';

  @override
  String get exportImageWidth => 'Width';

  @override
  String get exportImageLine => 'Position';

  @override
  String get aiModelSearch => 'Search models';

  @override
  String get aiModelOthers => 'OTHER MODELS';

  @override
  String get aiModelNoMatch => 'No matching model.';

  @override
  String get aiModelAutoInfo =>
      'The app tries the most suitable models in order.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count characters selected';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count images selected';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count attachments';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count lines';
  }

  @override
  String get aiModelShowAll => 'Show all';

  @override
  String get aiModelShowAllInfo => 'Also lists models the app does not use.';

  @override
  String get rotateFailed => 'Couldn\'t rotate the image.';

  @override
  String get dashboardBackgroundPick => 'Choose background image';

  @override
  String get dashboardBackgroundChange => 'Change background image';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Preparing audio: $done/$total parts';
  }

  @override
  String get podcastExportAudio => 'Export as audio file';

  @override
  String get podcastExportAudioCost =>
      'The whole script is re-synthesised with the AI voice and saved as a single WAV file. This uses your Gemini quota and can take a few minutes for long texts.';

  @override
  String get podcastShareText => 'Share the script';

  @override
  String get podcastSaveAsNote => 'Save as a new note';

  @override
  String get podcastSavedAsNote => 'The podcast script was saved as a note.';

  @override
  String get listenPreparingVoice => 'Preparing audio…';

  @override
  String get appearancePreviewTitle => 'Sample text';

  @override
  String get appearancePreviewNoteTitle => 'Sample note title';

  @override
  String get appearancePreviewBody =>
      'Your notes will look like this. Inline **bold**, ~underlined~ and ==2:highlighted== text appears like so.';

  @override
  String get appearancePreviewItem => 'A checklist item looks like this';

  @override
  String get convertToText => 'Convert to text';

  @override
  String get convertToList => 'Convert to list';

  @override
  String get convertedToText => 'The list was converted to plain text.';

  @override
  String get convertedToList => 'The text was converted to a list.';

  @override
  String get convertToListEmpty => 'There are no lines to convert into a list.';

  @override
  String get listTwoColumns => 'Two columns';

  @override
  String get listOneColumn => 'Single column';

  @override
  String get sortItems => 'Sort items';

  @override
  String get sortStarredFirst => 'Starred first';

  @override
  String get sortUncheckedFirst => 'Completed last';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Move images to attachments';

  @override
  String imagesToAttachmentsDone(int count) {
    return '$count images moved to attachments.';
  }

  @override
  String get imageOcrShowRecognized => 'Highlight recognised text';

  @override
  String get imageOcrHideRecognized => 'Hide the highlight';

  @override
  String get bubblePlainMode => 'Open text box';

  @override
  String get bubblePlainModeOn => 'Open text box is on';

  @override
  String get bubblePlainTapToPlace => 'Tap where the text should go';

  @override
  String get bubblePlainHint => 'Tap to write';

  @override
  String get noteSearchTitle => 'Search in note';

  @override
  String get noteSearchHint => 'Search this note…';

  @override
  String get noteSearchEmptyHint =>
      'Searches the note text, items and page notes instantly. Start the scan below to look inside image and PDF attachments.';

  @override
  String get noteSearchNoHit => 'No matches found.';

  @override
  String get noteSearchScanAttachments => 'Scan attachments';

  @override
  String get noteSearchAskAi => 'Ask the AI';

  @override
  String get noteTitleLabel => 'Title';

  @override
  String get noteBodyLabel => 'Note text';

  @override
  String get itemLabel => 'Item';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '$count attachments can be scanned (image/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'Searching inside $count attachments too.';
  }

  @override
  String pageLabel(int page) {
    return 'Page $page';
  }

  @override
  String get archiveNotebook => 'Archive notebook';

  @override
  String get archiveNotebookInfo =>
      'A notebook with its own pages that keeps copies of important documents and images.';

  @override
  String get archivePageImages => 'Images';

  @override
  String get archivePageVideos => 'Videos';

  @override
  String get archivePageDocuments => 'Documents';

  @override
  String get archivePageTexts => 'Texts';

  @override
  String get archiveNewPage => 'New page';

  @override
  String get archiveGeneralPage => 'General';

  @override
  String get archiveRenamePage => 'Rename page';

  @override
  String get archiveDeletePage => 'Delete page';

  @override
  String archiveDeletePageInfo(String name) {
    return 'Delete the page \"$name\"? Its entries are not deleted; they move to the General page.';
  }

  @override
  String get archivePrevPage => 'Previous page';

  @override
  String get archiveNextPage => 'Next page';

  @override
  String get archiveAddEntry => 'Add to page';

  @override
  String get archiveMoveEntry => 'Move to another page';

  @override
  String archiveEntryCount(int count) {
    return '$count entries';
  }

  @override
  String get archivePageName => 'Page name (e.g. Invoices)';

  @override
  String get archivePageEmpty => 'Empty page';

  @override
  String get archiveSearchHint => 'Search the notebook…';

  @override
  String get archiveAddText => 'Add text';

  @override
  String get archiveAddFile => 'Add file';

  @override
  String get archiveCopyHere => 'Copy to an archive notebook';

  @override
  String get archiveNoNotebook => 'No archive notebook yet. Create one first.';

  @override
  String get archiveNothingToCopy => 'This note has no attachments to copy.';

  @override
  String archiveDeleteEntry(String name) {
    return 'Delete \"$name\" from the notebook? This copy is gone for good.';
  }

  @override
  String archiveCopied(int count) {
    return '$count files copied to the archive notebook.';
  }

  @override
  String get archiveCaptureTitle => 'Capture from image';

  @override
  String get archiveCapturePage => 'Page';

  @override
  String get archiveCapturePageInfo =>
      'The page the AI suggested. Left empty, it goes to the General page.';

  @override
  String get archiveCaptureText => 'Recognised text';

  @override
  String get attachmentTagInsert => 'Insert into the text';

  @override
  String get attachmentTagInserted => 'The attachment tag was inserted.';

  @override
  String get attachmentTagPreview => 'Preview attachment';

  @override
  String get attachmentTagEdit => 'Edit attachment';

  @override
  String archiveCardSummary(int files, int texts) {
    return '$files files · $texts texts';
  }

  @override
  String get archivePlaceOnPage => 'Place on page';

  @override
  String get archivePaper => 'Paper';

  @override
  String get archivePaperLined => 'Lined';

  @override
  String get archivePaperGrid => 'Grid';

  @override
  String get archivePaperDots => 'Dotted';

  @override
  String get archivePaperPlain => 'Plain';

  @override
  String get archiveWriteHint => 'Write on this page…';

  @override
  String get archivePageTitleHint => 'Page name';

  @override
  String archiveAutoPageName(int number) {
    return 'Page $number';
  }

  @override
  String get archiveNewPageHint =>
      'Start writing or add something — the page opens by itself.';

  @override
  String get archiveNewPageLabel => 'New page';

  @override
  String get archiveAttachmentsHeading => 'Files on this page';

  @override
  String get archiveNotesHeading => 'Notes';

  @override
  String get archiveOpenPage => 'Go to page';

  @override
  String get archiveEntryTitle => 'Title';

  @override
  String get archiveLinkedFile => 'Linked file';

  @override
  String get archiveNoLink => 'No linked file';

  @override
  String get attachmentTagEmbed => 'Embed attachment in selection';

  @override
  String get attachmentTagNoAttachment =>
      'Add a file to the note first, then you can embed it in the text.';

  @override
  String get bubbleModeBubble => 'Bubble';

  @override
  String get attachmentTagEmbedInfo =>
      'Links to your selected text, or at the cursor if nothing is selected';

  @override
  String get attachmentTagPickText =>
      'Now select the text to link, then tap \"Link here\".';

  @override
  String get attachmentTagLinkHere => 'Link here';

  @override
  String attachmentTagPendingBanner(String name) {
    return '$name will be linked — select the text';
  }

  @override
  String get docNameNotesSuffix => 'notes';

  @override
  String get docNamePhoto => 'Photo notes';

  @override
  String get docNameScan => 'Scan notes';

  @override
  String get docNameImage => 'Image notes';

  @override
  String get docNameVideo => 'Video notes';

  @override
  String get folderManage => 'Manage folder';

  @override
  String get folderEmpty => 'This folder is empty';

  @override
  String folderNoteCount(int count) {
    return '$count notes';
  }

  @override
  String get folderEmptyHint =>
      'Add a note with + below, or move a note here while editing it.';

  @override
  String get brainstormTitle => 'Brainstorm with AI';

  @override
  String get brainstormRowInfo =>
      'AI drafts an outline first, then you build on it together';

  @override
  String get brainstormIntro =>
      'Tap one of the headings above or just type — let\'s start thinking together.';

  @override
  String get brainstormOutlineTitle => 'OUTLINE';

  @override
  String get brainstormInputHint => 'Write an idea or ask a question…';

  @override
  String get brainstormAddIdea => 'Add to note';

  @override
  String get brainstormAdded => 'Added to note';

  @override
  String get folderShared => 'This folder is shared with a friend';

  @override
  String get friendsTitle => 'Contacts';

  @override
  String get friendsAdd => 'Add friend';

  @override
  String get friendsEmpty =>
      'No one yet. Add a friend by email to share folders with them.';

  @override
  String get friendsRequestsTitle => 'REQUESTS';

  @override
  String get friendsListTitle => 'MY FRIENDS';

  @override
  String get friendsAddEmailHint => 'friend@email.com';

  @override
  String get friendsSendRequest => 'Send request';

  @override
  String get friendsRequestSent => 'Request sent';

  @override
  String get friendsNotFound =>
      'No user is registered with this email. They need to have opened the app with a Google account at least once.';

  @override
  String get friendsSelf => 'You can\'t add yourself as a friend';

  @override
  String get friendsAlready => 'You\'re already friends';

  @override
  String get friendsDecline => 'Decline';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsRemove => 'Remove';

  @override
  String get friendsRemoveConfirmTitle => 'Remove friend';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'Remove $name from your friends? Folders you shared with them will no longer be visible.';
  }

  @override
  String get friendsNeedsAccount =>
      'Contacts and folder sharing require a linked Google account.';

  @override
  String get friendsSearchHint => 'Search by name or email';

  @override
  String get friendsSearchTab => 'Search';

  @override
  String get friendsSearchEmailTab => 'By email';

  @override
  String get friendsSearchEmpty => 'No results';

  @override
  String get friendsSearchTooShort => 'Type at least 2 characters to search';

  @override
  String get friendsSearchAdd => 'Add';

  @override
  String get folderShare => 'Share';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared with $count people',
      one: 'Shared with 1 person',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'Share \"$name\"';
  }

  @override
  String get folderShareInfo =>
      'An invite goes to the friend you pick; they see the folder once they accept. You choose their permission (read / write / both).';

  @override
  String get friendsRowInfo => 'Add friends, share folders with them';

  @override
  String get accountRecoverConflictTitle => 'This device has unsaved notes';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'This Google account is already linked to another session; switching to it will hide the $count note(s) on this device (they aren\'t deleted, just no longer reachable from here). Continue anyway?';
  }

  @override
  String get accountRecoverConflictProceed => 'Switch anyway';

  @override
  String get folderRoleRead => 'Read';

  @override
  String get folderRoleWrite => 'Write';

  @override
  String get folderRoleBoth => 'Read + write';

  @override
  String get folderInvitePending => 'Invite sent, waiting for an answer';

  @override
  String get folderWriteOnlyTitle => 'You only have write access';

  @override
  String get folderWriteOnlyHint =>
      'You can add new notes to this folder but cannot see the notes inside it.';

  @override
  String get folderChatTitle => 'Chat';

  @override
  String get folderChatHint => 'Write a message…';

  @override
  String get folderChatSend => 'Send';

  @override
  String get folderChatEmptyTitle => 'No messages yet';

  @override
  String get folderChatEmptyHint =>
      'Talk here with the people you shared this folder with.';

  @override
  String get folderInviteTitle => 'Folder invite';

  @override
  String folderInviteBody(Object name) {
    return 'The folder \"$name\" was shared with you.';
  }

  @override
  String get folderInviteAccepted => 'Folder added';

  @override
  String get folderInviteDeclined => 'Invite declined';

  @override
  String friendRequestBanner(Object name) {
    return '$name sent you a friend request';
  }

  @override
  String get friendRequestAccepted => 'Friend added';

  @override
  String get sendNoteAction => 'Send to a friend';

  @override
  String get sendNoteTitle => 'Send the note to a friend';

  @override
  String get sendNoteInfo =>
      'A copy of the note lands in the person\'s \"Incoming notes\" box. Attachments (images, documents, audio) are not sent.';

  @override
  String sendNoteSent(Object name) {
    return 'Note sent to $name';
  }

  @override
  String get inboxTitle => 'Incoming notes';

  @override
  String get inboxEmpty => 'No incoming notes';

  @override
  String get inboxEmptyHint => 'Notes your friends send you collect here.';

  @override
  String inboxFrom(Object name) {
    return 'Sent by $name';
  }

  @override
  String get inboxAccept => 'Add to my notes';

  @override
  String get inboxAccepted => 'Note added to your notes';

  @override
  String get folderShelfExpand => 'Expand folders';

  @override
  String get folderShelfCollapse => 'Collapse folders';

  @override
  String get accountSheetLocalInfo =>
      'Your notes are only on this device. Link a Google account to back them up and add friends.';

  @override
  String get accountSettings => 'Account settings';

  @override
  String get videoFramesExtracting => 'Grabbing frames from the video…';

  @override
  String get areaSelect => 'Select area';

  @override
  String get areaSelectOff => 'Turn off area select';

  @override
  String get areaSelectHint =>
      'Drag a box around what you want to copy or ask the AI about.';

  @override
  String get areaCopyImage => 'Copy as image';

  @override
  String get areaCopied => 'Selected area copied to the clipboard.';

  @override
  String get areaAskAi => 'Ask the AI';

  @override
  String get areaAskTitle => 'Selected area';

  @override
  String get areaAskHint =>
      'Add a question if you like (leave it empty to transcribe and explain).';

  @override
  String get areaAskRun => 'Ask';

  @override
  String get areaCaptureFailed => 'Couldn\'t capture the selected area.';

  @override
  String get areaTooSmall => 'The selected area is too small.';

  @override
  String get areaAddToNote => 'Add to note';

  @override
  String get bubbleTextFill => 'Text background';

  @override
  String get bubbleTextFillNone => 'No background';

  @override
  String get bubbleTextAlignLeft => 'Align left';

  @override
  String get bubbleTextAlignCenter => 'Align center';

  @override
  String get bubbleTextAlignRight => 'Align right';

  @override
  String get dashboardBackgroundPattern => 'Pattern';

  @override
  String get dashboardBackgroundColor => 'Background color';

  @override
  String get dashboardBackgroundImageSection => 'Background image';

  @override
  String get dashboardBackgroundReset => 'Reset to default';

  @override
  String get patternNone => 'Plain';

  @override
  String get patternDots => 'Dots';

  @override
  String get patternGrid => 'Grid';

  @override
  String get patternLines => 'Lines';

  @override
  String get patternDiagonal => 'Diagonal';

  @override
  String get patternGraph => 'Graph paper';

  @override
  String get archivePagesOverview => 'Pages';

  @override
  String get archiveSemanticHint => 'Search the notebook by meaning…';

  @override
  String get semanticUnavailable =>
      'Semantic search is unavailable right now; showing text search.';

  @override
  String get sharedNotifications => 'Shared folder notifications';

  @override
  String get sharedNotificationsInfo =>
      'Get a phone notification when someone adds or edits a note or writes in the chat. The home screen counter keeps working when this is off.';

  @override
  String get copyAsText => 'Copy text';

  @override
  String get searchAttachments => 'Search inside attachments';

  @override
  String get searchAttachmentsInfo =>
      'Also scans PDF text and text in images (OCR). Turning this on indexes the files stored on this device once; later searches use the cache.';
}
