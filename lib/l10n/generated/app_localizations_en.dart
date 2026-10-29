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
  String get star => 'Star';

  @override
  String get unstar => 'Remove star';

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
  String get addImage => 'Add image';

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
  String get placeReminder => 'Location reminder';

  @override
  String get placeReminderHint =>
      'Get this note as a notification when you arrive at or leave a place. The system watches the location; it works even when the app is closed.';

  @override
  String get placeCurrent => 'My current location';

  @override
  String get placeSearchHint => 'Search an address or place';

  @override
  String get placeSearchNone => 'No results';

  @override
  String get placeArrive => 'On arrival';

  @override
  String get placeLeave => 'On leaving';

  @override
  String get placeRadius => 'Radius';

  @override
  String get placeSave => 'Set reminder';

  @override
  String get placeRemove => 'Remove location reminder';

  @override
  String get placeSet => 'Location reminder set';

  @override
  String get placeRemoved => 'Location reminder removed';

  @override
  String get placeNeedPermission =>
      'Location permission was not granted. You can allow it in settings.';

  @override
  String get placeNeedBackground =>
      'To work while the app is closed, set location permission to \"Allow all the time\".';

  @override
  String get placeBackgroundTitle => '\"All the time\" permission needed';

  @override
  String get placeOpenSettings => 'Allow';

  @override
  String get placeLocationOff =>
      'Device location is off. Turn it on and try again.';

  @override
  String get placeFailed => 'Could not set the location reminder.';

  @override
  String get placeNoLocation =>
      'Could not get your location. Make sure location is on.';

  @override
  String placeArrivedBody(String place) {
    return 'You arrived at $place';
  }

  @override
  String placeLeftBody(String place) {
    return 'You left $place';
  }

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
  String get dictationHoldHint =>
      'Hold the microphone and speak; text is written when you let go';

  @override
  String itemsSelected(int count) {
    return '$count items selected';
  }

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
  String get voiceTapHint => 'Tap and speak; tap again to finish';

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
  String get newVideoNote => 'Record a video';

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
  String get select => 'Select';

  @override
  String get noteArchived => 'Note archived';

  @override
  String pendingUploads(int count) {
    return '$count attachments uploading';
  }

  @override
  String pendingUploadsFailed(int count) {
    return '$count attachments failed, will retry';
  }

  @override
  String get pendingUploadsInfo =>
      'Attachments are safe on this device. They upload automatically when you are online; until then they do not appear on your other devices.';

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
  String get speechNoVoices => 'No voices are installed on this device';

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
  String get backgroundColorInfo =>
      'The note background — shown inside the note and on the home screen';

  @override
  String get frameColor => 'Frame';

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
  String get hubBriefingInfo =>
      'Your day at a glance: reminders and recent notes';

  @override
  String get hubReadInfo => 'Listen to a PDF or Word document';

  @override
  String get annotate => 'Annotate';

  @override
  String get annotateDone => 'Finish annotating';

  @override
  String get newPdfNote => 'Note from PDF';

  @override
  String get imageNotePreparing => 'Arranging images into a document…';

  @override
  String get newImageNote => 'Note from images';

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
  String get newSlidesNote => 'Note from slides';

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
  String get newPhotoNote => 'Take a photo';

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
  String get hideAttachments => 'Hide';

  @override
  String get showAttachments => 'Show';

  @override
  String get selectAllItems => 'Select all';

  @override
  String get checkSelectedItems => 'Check selected';

  @override
  String get uncheckSelectedItems => 'Uncheck selected';

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
  String get viewToggle => 'View';

  @override
  String get viewGrid => 'Grid';

  @override
  String get viewList => 'List';

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
  String get formatHeading => 'Heading';

  @override
  String get formatHeading1 => 'Heading';

  @override
  String get formatHeading2 => 'Subheading';

  @override
  String get formatNormalText => 'Normal text';

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
  String get cardHideSensitive => 'Hide sensitive content on cards';

  @override
  String get cardHideSensitiveInfo =>
      'Notes that mention a password don\'t show their content on the card; IBAN and card numbers show only their last four digits. Inside the note everything stays as is.';

  @override
  String get sensitiveHiddenOnCard => 'Sensitive content — hidden on card';

  @override
  String get paletteMore => 'More colors';

  @override
  String get paletteCustom => 'Custom color';

  @override
  String get paletteUse => 'Use';

  @override
  String get paletteHue => 'Hue';

  @override
  String get paletteSaturation => 'Saturation';

  @override
  String get paletteLightness => 'Lightness';

  @override
  String get itemMoveToPage => 'Move to another page';

  @override
  String itemMovedToPage(int page) {
    return 'Item moved to page $page';
  }

  @override
  String get screenAiSearchHint => 'Search by meaning…';

  @override
  String get archiveInsights => 'What\'s in my archive?';

  @override
  String archiveInsightsStats(int count, int files, int stale) {
    return '$count notes · $files attachments · $stale untouched for a year';
  }

  @override
  String get archiveByFolder => 'By folder';

  @override
  String get archiveNoFolder => 'No folder';

  @override
  String get archiveStale => 'Untouched for a year';

  @override
  String get archiveInsightsAi => 'Summarize with AI';

  @override
  String get archiveAiStale => 'AI: looks outdated';

  @override
  String get lineSpacing => 'Line spacing';

  @override
  String get lineSpacingNormal => 'Normal';

  @override
  String get lineSpacingWide => 'Wide';

  @override
  String get lineSpacingWider => 'Wider';

  @override
  String get trashReminderTitle =>
      'Something in the trash may be worth keeping';

  @override
  String trashReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes will be deleted for good tomorrow',
      one: 'A note will be deleted for good tomorrow',
    );
    return '$_temp0 — it looks like it still holds a task or important info. Take a look.';
  }

  @override
  String get groupByFolder => 'Group by folder';

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
  String get ttsEngineLocal => 'Turkish voice';

  @override
  String get ttsEngineLocalInfo =>
      'Antalia: a Turkish speech model that runs on the phone. Free, offline and quota-free; the model is downloaded once (~50 MB). It reads Turkish only — text in other languages is read with the device voice. The voice is synthetic and does not belong to a real person.';

  @override
  String get ttsLocalUnsupported =>
      'The Turkish voice only works in the Android app. Here the device voice reads.';

  @override
  String get ttsLocalMissing =>
      'Until the model is downloaded, the device voice reads.';

  @override
  String get ttsLocalDownload => 'Download model (~50 MB)';

  @override
  String ttsLocalDownloading(String done) {
    return 'Downloading… $done';
  }

  @override
  String get ttsLocalReady => 'Model installed — works offline';

  @override
  String get ttsLocalDelete => 'Delete model';

  @override
  String ttsLocalFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get listenLocalVoice => 'Listen with Turkish voice (Antalia)';

  @override
  String get shareAsNotePreparing => 'Preparing note package…';

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
  String get archiveNotebook => 'Notebook';

  @override
  String get archiveNewPage => 'New page';

  @override
  String get archiveTemplateJournal => 'Journal';

  @override
  String get archiveTemplateMeeting => 'Meeting';

  @override
  String get archiveTemplateExpense => 'Expenses';

  @override
  String get archiveTemplateTodo => 'To-do';

  @override
  String get archiveTemplateReading => 'Reading notes';

  @override
  String get tplJournalHow => 'How was today?';

  @override
  String get tplJournalGrateful => 'Grateful for';

  @override
  String get tplJournalTomorrow => 'For tomorrow';

  @override
  String get tplMeetingAttendees => 'Attendees';

  @override
  String get tplMeetingAgenda => 'Agenda';

  @override
  String get tplMeetingDecisions => 'Decisions';

  @override
  String get tplMeetingActions => 'Who, what, when';

  @override
  String get tplExpenseColumns => 'Date · Description · Amount';

  @override
  String get tplExpenseTotal => 'Total:';

  @override
  String get tplReadingSource => 'Source';

  @override
  String get tplReadingSummary => 'Summary';

  @override
  String get tplReadingQuotes => 'Quotes';

  @override
  String get tplReadingThoughts => 'My thoughts';

  @override
  String get archiveDeletePage => 'Delete page';

  @override
  String get archivePrevPage => 'Previous page';

  @override
  String get archiveNextPage => 'Next page';

  @override
  String get archiveCopyHere => 'Copy to an archive notebook';

  @override
  String get archiveNoNotebook => 'No archive notebook yet. Create one first.';

  @override
  String get archiveNothingToCopy => 'This note has no attachments to copy.';

  @override
  String archiveCopied(int count) {
    return '$count files copied to the archive notebook.';
  }

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
  String get archivePaperLegal => 'Legal pad';

  @override
  String get archivePaperEngineering => 'Engineering';

  @override
  String get archivePaperIsometric => 'Isometric';

  @override
  String get attachmentTagEmbed => 'Embed';

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
  String get friendsSearchHint => 'Name (3+ letters) or full email';

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
  String get folderShare => 'Edit together';

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

  @override
  String get selectAll => 'Select all';

  @override
  String get selectNone => 'Clear selection';

  @override
  String get duplicateNote => 'Duplicate note';

  @override
  String get noteDuplicated => 'Note duplicated';

  @override
  String notesDuplicatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes duplicated',
      one: '1 note duplicated',
    );
    return '$_temp0';
  }

  @override
  String get noteStatsTitle => 'Note statistics';

  @override
  String noteStatsWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String noteStatsChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String noteStatsItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String noteStatsAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String noteStatsReadTime(int count) {
    return '~$count min read';
  }

  @override
  String get scrollToTop => 'Back to top';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deleted permanently in $count days',
      one: 'Deleted permanently in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get trashLastDay => 'Will be deleted permanently today';

  @override
  String get noteRestored => 'Note restored';

  @override
  String get restoreAll => 'Restore all';

  @override
  String notesRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes restored',
      one: '1 note restored',
    );
    return '$_temp0';
  }

  @override
  String get reminderRemoved => 'Reminder removed';

  @override
  String get reminderOverdue => 'Overdue';

  @override
  String get reminderQuickTonight => 'Tonight 6:00 PM';

  @override
  String get reminderQuickTomorrow => 'Tomorrow 9:00 AM';

  @override
  String get reminderQuickNextWeek => 'Next week';

  @override
  String get reminderQuickCustom => 'Pick a date…';

  @override
  String get reminderQuickTitle => 'When should we remind you?';

  @override
  String get reminderSnooze => 'Snooze 1 hour';

  @override
  String get reminderSnoozed => 'Reminder snoozed';

  @override
  String reminderCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reminders',
      one: '1 reminder',
    );
    return '$_temp0';
  }

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeInMinutes(int count) {
    return 'in $count min';
  }

  @override
  String relativeInHours(int count) {
    return 'in $count h';
  }

  @override
  String relativeInDays(int count) {
    return 'in $count days';
  }

  @override
  String relativeAgoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String relativeAgoHours(int count) {
    return '$count h ago';
  }

  @override
  String relativeAgoDays(int count) {
    return '$count days ago';
  }

  @override
  String get inboxDeclined => 'Incoming note deleted';

  @override
  String inboxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incoming notes',
      one: '1 incoming note',
    );
    return '$_temp0';
  }

  @override
  String get appVersion => 'App version';

  @override
  String get appVersionCopied => 'Version info copied';

  @override
  String notesMovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes moved',
      one: '1 note moved',
    );
    return '$_temp0';
  }

  @override
  String get mediaPlay => 'Play';

  @override
  String get mediaPause => 'Pause';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String get tagManageTitle => 'Manage tag';

  @override
  String get tagRename => 'Rename tag';

  @override
  String get tagRenameHint => 'New tag name';

  @override
  String get tagDelete => 'Delete tag';

  @override
  String tagDeleteConfirm(String tag) {
    return 'Remove the tag \"$tag\" from all notes? The notes are kept.';
  }

  @override
  String get tagRenamed => 'Tag renamed';

  @override
  String get tagDeleted => 'Tag removed';

  @override
  String get tagLongPressHint => 'Long-press a tag to rename or delete it.';

  @override
  String get recentSearches => 'Recent searches';

  @override
  String get clearRecentSearches => 'Clear history';

  @override
  String get imagesEqualizeSize => 'Match sizes';

  @override
  String get imagesFitRow => 'Fit to row';

  @override
  String imagesFitColumns(int count) {
    return '$count columns';
  }

  @override
  String get imagesFitSingleRow => 'Fit in one row';

  @override
  String get briefingNotificationTitle => 'Good morning! ☀️';

  @override
  String get briefingNotificationBody =>
      'Today\'s briefing is ready — tap for a summary of your reminders, notes and important emails.';

  @override
  String get reminderDone => 'Done';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get noteDuplicatedNoAttachments =>
      'Duplicated — attachments were not copied';

  @override
  String get pdfGoToPage => 'Go to page';

  @override
  String get pdfThumbnails => 'Browse pages';

  @override
  String get pdfBookmarks => 'Bookmarks';

  @override
  String get pdfBookmarkAdd => 'Add bookmark';

  @override
  String get pdfBookmarkRemove => 'Remove bookmark';

  @override
  String get pdfNoBookmarks =>
      'No bookmarks yet. Tap the bookmark button on the page bar.';

  @override
  String get pdfRotateView => 'Rotate view';

  @override
  String get pdfCopyPageText => 'Copy page text';

  @override
  String get pdfCapturePage => 'Capture page (AI / copy)';

  @override
  String get pdfSlideshow => 'Auto advance';

  @override
  String get pdfSlideshowStop => 'Stop auto advance';

  @override
  String get pdfFirstPage => 'First page';

  @override
  String get pdfLastPage => 'Last page';

  @override
  String get collaborators => 'Collaborators';

  @override
  String get collaboratorsInfo =>
      'People you add see this note on their home screen and edit it with you in real time.';

  @override
  String get collaboratorsOwner => 'Owner';

  @override
  String get collaboratorsFriendsTitle => 'YOUR FRIENDS';

  @override
  String get collaboratorsLeave => 'Leave shared note';

  @override
  String get collaboratorsLeaveConfirm =>
      'This note will no longer appear on your home screen. Leave?';

  @override
  String get collaboratorsSaved => 'Sharing updated';

  @override
  String collaboratorsCount(int count) {
    return 'Shared with $count people';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'Only the note\'s owner can change collaborators.';

  @override
  String get sharedWithMe => 'Shared with me';

  @override
  String get sharedWithMeEmpty =>
      'No notes have been shared with you yet. They appear here when someone adds you to a note.';

  @override
  String sharedByName(Object name) {
    return 'Shared by $name';
  }

  @override
  String get navNotes => 'Notes';

  @override
  String get railExpand => 'Expand menu';

  @override
  String get railCollapse => 'Collapse menu';

  @override
  String get newNoteShort => 'New note';

  @override
  String get newChecklistShort => 'New list';

  @override
  String get listPaneHide => 'Hide note list';

  @override
  String get listPaneShow => 'Show note list';

  @override
  String get keyboardShortcuts => 'Keyboard shortcuts';

  @override
  String get shortcutSearch => 'Search notes';

  @override
  String get shortcutToggleList => 'Hide / show note list';

  @override
  String get shortcutSections => 'Switch between sections';

  @override
  String get shortcutHelp => 'Show shortcuts';

  @override
  String get noNoteSelectedHint => 'or start a new note';

  @override
  String get loginFeatureSyncTitle => 'Same notes on every device';

  @override
  String get loginFeatureSyncBody =>
      'Instant sync across phone, tablet, computer and web.';

  @override
  String get loginFeatureAiTitle => 'AI at your side';

  @override
  String get loginFeatureAiBody =>
      'Summarize, ask, dictate; chat with your documents.';

  @override
  String get loginFeatureShareTitle => 'Write together';

  @override
  String get loginFeatureShareBody =>
      'Share notes and folders live with friends.';

  @override
  String get loginFeatureInkTitle => 'Pen and PDF';

  @override
  String get loginFeatureInkBody =>
      'Take handwritten notes, write on PDFs and slides.';

  @override
  String get foldersTitle => 'Folders';

  @override
  String get foldersEmpty =>
      'No folders yet. Create one to organize your notes.';

  @override
  String get folderColor => 'Color';

  @override
  String get folderColorAuto => 'Automatic';

  @override
  String get foldersMine => 'My folders';

  @override
  String get foldersSharedSection => 'Folders shared with me';

  @override
  String trashDaysShort(int count) {
    return '$count d';
  }

  @override
  String get trashTodayShort => 'Today';

  @override
  String get trashSoonSection => 'Deleted permanently soon';

  @override
  String get trashRestSection => 'Other deleted notes';

  @override
  String get aiHubTagline => 'Ask, summarize and tidy up your notes.';

  @override
  String get aiToolsSection => 'Tools';

  @override
  String get folderOrderTitle => 'Folder order';

  @override
  String get folderReorder => 'Reorder folders';

  @override
  String get folderOrderManual => 'Custom';

  @override
  String get folderOrderName => 'By name';

  @override
  String get folderOrderNewest => 'Newest first';

  @override
  String get folderOrderNoteCount => 'By note count';

  @override
  String get folderOrderHint =>
      'Drag the handles to reorder (dragging switches to \"Manual\"). This order is also used in the folder strip and when swiping.';

  @override
  String get swipeModeTitle => 'Swiping left/right on the home screen';

  @override
  String get swipeModeFolders => 'Switch between folders';

  @override
  String get swipeModeFilters => 'Switch between filters and tags';

  @override
  String get swipeModeBoth => 'Folders, filters and tags';

  @override
  String get swipeModeOff => 'Off';

  @override
  String get shareIncludeTitle => 'Title';

  @override
  String get shareIncludeChecked => 'Completed items';

  @override
  String get shareIncludeTags => 'Tags';

  @override
  String get shareTextAction => 'Share text';

  @override
  String get findPrevious => 'Previous match';

  @override
  String get findNext => 'Next match';

  @override
  String get findShowAll => 'All matches';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matches',
      one: '1 match',
      zero: 'No matches',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Search attachments & AI';

  @override
  String get notesSettingsTitle => 'Notes & folders';

  @override
  String get noteViewSetting => 'Home screen layout';

  @override
  String get noteViewGrid => 'Grid';

  @override
  String get noteViewList => 'List';

  @override
  String get gridColumnsSetting => 'Columns';

  @override
  String get gridColumnsInfo =>
      'You can also pinch on the home screen to change it.';

  @override
  String get gridColumnsAuto => 'Auto';

  @override
  String get folderShelfSetting => 'Folders on the home screen';

  @override
  String get folderShelfStrip => 'Single row';

  @override
  String get folderShelfTiles => 'Tiles';

  @override
  String get deviceStorageTitle => 'On this device';

  @override
  String get deviceStorageAttachments => 'Attachments';

  @override
  String get deviceStorageDatabase => 'Local copy of notes';

  @override
  String get deviceStorageCache => 'Cache and temporary files';

  @override
  String get deviceStorageAi => 'AI cache';

  @override
  String get deviceStorageTotal => 'Total (excluding the app itself)';

  @override
  String get deviceStorageInfo =>
      'Clearing the cache does not delete notes or attachments; images download again when needed. Old temporary files are also cleaned up on every launch.';

  @override
  String get deviceStorageClear => 'Clear cache';

  @override
  String deviceStorageCleared(String size) {
    return '$size freed';
  }

  @override
  String get deviceStorageUnavailable =>
      'Could not be measured on this device.';

  @override
  String get localOnlyTurnOn => 'Stop syncing';

  @override
  String get localOnlyTurnOff => 'Sync this note';

  @override
  String get localOnlyBadge => 'Only on this device';

  @override
  String get localOnlyConfirmTitle => 'Keep this note only on this device?';

  @override
  String get localOnlyConfirmBody =>
      'The note and its attachments are removed from the cloud and won\'t appear on your other devices. If you uninstall the app or change phones, this note goes too. You can turn sync back on at any time.';

  @override
  String get localOnlyConfirm => 'Stop syncing';

  @override
  String get localOnlyOnDone => 'The note is now only on this device';

  @override
  String get localOnlyOffDone => 'The note is syncing again';

  @override
  String get localOnlySharedBlocked =>
      'Sync can\'t be turned off for a shared note';

  @override
  String get localOnlyDownloadFailed =>
      'Some attachments couldn\'t be downloaded to this device. Check your connection and try again; the note was not changed.';

  @override
  String get templatesTitle => 'Templates';

  @override
  String get templatesSubtitle =>
      'Start with a ready layout; you can change everything later.';

  @override
  String get fromTemplate => 'From template';

  @override
  String get tplShoppingName => 'Shopping list';

  @override
  String get tplShoppingItems => 'Bread, Milk, Eggs, Fruit, Vegetables';

  @override
  String get tplShoppingDesc => 'Tick off what you bought; it moves down';

  @override
  String get tplTodoDesc => 'An empty list with today\'s date';

  @override
  String get tplTravelName => 'Packing list';

  @override
  String get tplTravelItems =>
      'ID / passport, Phone charger, Medicines, Toothbrush, Clothes, Headphones';

  @override
  String get tplTravelDesc => 'A ready checklist';

  @override
  String get tplMeetingDesc => 'Attendees, agenda, decisions';

  @override
  String get tplJournalDesc => 'How was today, gratitude, tomorrow';

  @override
  String get tplRecipeName => 'Recipe';

  @override
  String get tplRecipeMeta => 'Servings: · Time:';

  @override
  String get tplRecipeIngredients => 'Ingredients';

  @override
  String get tplRecipeSteps => 'Steps';

  @override
  String get tplRecipeNotes => 'Notes';

  @override
  String get tplRecipeDesc => 'Ingredients and steps';

  @override
  String get tplWeeklyName => 'Weekly plan';

  @override
  String get tplWeeklyDesc => 'This week\'s days as headings';

  @override
  String get tplExpenseDesc => 'Date, description, amount';

  @override
  String get tplReadingDesc => 'Source, summary, quotes';

  @override
  String get settingsThemeHeader => 'Theme';

  @override
  String get settingsCardsHeader => 'Cards and lists';

  @override
  String get shareTargetTitle => 'Add to Notes';

  @override
  String get shareTargetNew => 'New note';

  @override
  String get shareTargetExisting => 'Existing note';

  @override
  String get shareTargetCreate => 'Create note';

  @override
  String get shareTargetSearch => 'Search notes';

  @override
  String get shareTargetNoNotes => 'No notes to add to';

  @override
  String get shareTargetNoMatch => 'No matching notes';

  @override
  String shareTargetMore(int count) {
    return '+$count files';
  }

  @override
  String get sharePreviewExpand => 'Expand preview';

  @override
  String get sharePreviewCollapse => 'Collapse preview';

  @override
  String get templatesSearch => 'Search templates';

  @override
  String get templatesAll => 'All';

  @override
  String get templatesLists => 'Lists';

  @override
  String get templatesPlanning => 'Planning';

  @override
  String get templatesWriting => 'Writing';

  @override
  String get templatesMine => 'My templates';

  @override
  String get templatesRecent => 'Recently used';

  @override
  String get templatesNoMatch => 'No matching templates';

  @override
  String get templatesMineEmpty =>
      'You have no templates yet. Choose “Save as template” from a note\'s menu and it will appear here.';

  @override
  String get templatesMineInfo => 'Your template';

  @override
  String get templateRename => 'Rename';

  @override
  String get templateDelete => 'Delete template';

  @override
  String get templateNameTitle => 'Template name';

  @override
  String get templateNameHint => 'e.g. Weekly groceries';

  @override
  String get templateSave => 'Save';

  @override
  String templateSaved(String name) {
    return '“$name” added to your templates';
  }

  @override
  String get saveAsTemplate => 'Save as template';

  @override
  String get templateCreate => 'Create';

  @override
  String templateCreateWithCount(int count) {
    return 'Create · $count items';
  }

  @override
  String get templateListChecks => 'Checkboxes';

  @override
  String get templateListNumbers => 'Numbered';

  @override
  String get templateItems => 'Items';

  @override
  String get templateAddItem => 'Add item';

  @override
  String get templateSuggestionsInfo =>
      'Tap a suggestion to add it to the list; tap again to remove it.';

  @override
  String get tplShopProduce => 'Fruit and vegetables';

  @override
  String get tplShopProduceItems =>
      'Tomatoes, Cucumbers, Onions, Potatoes, Lemons, Bananas, Apples, Parsley';

  @override
  String get tplShopBreakfast => 'Breakfast';

  @override
  String get tplShopBreakfastItems =>
      'Cheese, Olives, Butter, Honey, Jam, Yogurt';

  @override
  String get tplShopPantry => 'Pantry';

  @override
  String get tplShopPantryItems =>
      'Rice, Pasta, Flour, Sugar, Olive oil, Lentils, Tea, Coffee';

  @override
  String get tplShopCleaning => 'Cleaning';

  @override
  String get tplShopCleaningItems =>
      'Dish soap, Laundry detergent, Toilet paper, Paper towels, Trash bags';

  @override
  String get tplShopPersonal => 'Personal care';

  @override
  String get tplShopPersonalItems => 'Shampoo, Toothpaste, Soap, Deodorant';

  @override
  String get tplTravelDocs => 'Documents';

  @override
  String get tplTravelDocsItems =>
      'Tickets, Hotel booking, Driver\'s license, Travel insurance, Cash / cards';

  @override
  String get tplTravelClothes => 'Clothes';

  @override
  String get tplTravelClothesItems =>
      'T-shirts, Trousers, Underwear, Socks, Pyjamas, Jacket, Shoes';

  @override
  String get tplTravelCare => 'Toiletries';

  @override
  String get tplTravelCareItems =>
      'Toothpaste, Shampoo, Sunscreen, Shaving kit, Deodorant';

  @override
  String get tplTravelTech => 'Electronics';

  @override
  String get tplTravelTechItems =>
      'Power bank, Plug adapter, Headphones, Cables';

  @override
  String get tplHabitsName => 'Habit tracker';

  @override
  String get tplHabitsDesc => 'Tick every day, don\'t break the chain';

  @override
  String get tplHabitsItems =>
      '8 glasses of water, 30-minute walk, Read 20 pages, Go to bed early, One screen-free hour';

  @override
  String get tplCleaningName => 'House cleaning';

  @override
  String get tplCleaningDesc => 'Weekly cleaning checklist';

  @override
  String get tplCleaningItems =>
      'Dust, Vacuum, Mop, Clean the bathroom, Kitchen counters, Laundry, Take out the trash, Change the sheets';

  @override
  String get tplMovingName => 'Moving checklist';

  @override
  String get tplMovingDesc => 'Things to do before and after the move';

  @override
  String get tplMovingItems =>
      'Book movers, Buy boxes and tape, Update your address, Electricity / water / gas accounts, Transfer internet, Hand over keys';

  @override
  String get tplGiftsName => 'Gift list';

  @override
  String get tplGiftsDesc => 'Who gets what, ideas';

  @override
  String get tplGiftsItems => 'Mom, Dad, Sibling, Friend';

  @override
  String get tplWatchlistName => 'Watchlist';

  @override
  String get tplWatchlistDesc => 'Films, series and books to get to';

  @override
  String get tplWorkoutName => 'Workout';

  @override
  String get tplWorkoutDesc => 'Exercise list from warm-up to stretching';

  @override
  String get tplWorkoutItems =>
      'Warm-up 5 min, Squats 3×12, Push-ups 3×10, Crunches 3×15, Plank 3×45 s, Stretching 5 min';

  @override
  String get tplGoalsName => 'Goals';

  @override
  String get tplGoalsDesc => 'Goals for the year, month and week';

  @override
  String get tplGoalsYear => 'This year';

  @override
  String get tplGoalsMonth => 'This month';

  @override
  String get tplGoalsWeek => 'This week';

  @override
  String get tplGoalsWhy => 'Why does it matter?';

  @override
  String get templateNew => 'New template';

  @override
  String get templateEdit => 'Edit template';

  @override
  String get templateDuplicate => 'Duplicate';

  @override
  String get templateSaveAsMine => 'Save to my templates';

  @override
  String get templateUntitled => 'Untitled template';

  @override
  String get templateTypeText => 'Text';

  @override
  String get templateTitleHelp =>
      'Title of notes created from this template (optional)';

  @override
  String get templateBody => 'Text';

  @override
  String get templateHeadingHelp =>
      'Lines starting with “# ” become headings, “## ” subheadings.';

  @override
  String get templateDiscardTitle => 'Discard changes?';

  @override
  String get templateDiscard => 'Discard';

  @override
  String templateDeleted(String name) {
    return '“$name” deleted';
  }

  @override
  String get addVideoFromGallery => 'Video from gallery';

  @override
  String get addYouTubeVideo => 'YouTube video';

  @override
  String get addYouTubeVideoSubtitle =>
      'Plays in the note, watch in a small window';

  @override
  String get youTubeLinkHelp =>
      'Paste a YouTube video link (youtube.com or youtu.be).';

  @override
  String get youTubeInvalidLink => 'This is not a YouTube video link';

  @override
  String get youTubeOpenInBrowserInfo =>
      'Video can\'t be played in the app on this device; it can be opened in the browser.';

  @override
  String get youTubeOpenExternal => 'Open in YouTube';

  @override
  String get pictureInPicture => 'Picture-in-picture';

  @override
  String get pinMediaRelease => 'Release: pin to top (note below)';

  @override
  String get unpinMedia => 'Put back on page';

  @override
  String get unpinMediaRelease => 'Release: put back on page';

  @override
  String get pinnedMediaResize => 'Pane height — drag to change';

  @override
  String pageOf(int current, int total) {
    return 'Page $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'Page $page added';
  }

  @override
  String get deletePageConfirm =>
      'Delete this page\'s text? Its images move to the neighbouring page. You can bring it back with Undo.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Image';

  @override
  String get embedNewVideo => 'Video';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'What to embed?';

  @override
  String embedPickTitleFor(String label) {
    return 'Embed into “$label”';
  }

  @override
  String get embedPickInfo =>
      'Tap the text to open the embedded item in place.';

  @override
  String get embedSectionNew => 'Add new';

  @override
  String get embedSectionExisting => 'Attachments in this note';

  @override
  String get embedReplace => 'Replace';

  @override
  String get embedRemove => 'Remove embed';

  @override
  String get embedRemoved => 'Embed removed';

  @override
  String get guideTitle => 'User guide';

  @override
  String get guideMenuInfo => 'Every feature, step by step';

  @override
  String get guideSearchHint => 'Search the guide — “page”, “YouTube”';

  @override
  String get guideContents => 'Contents';

  @override
  String get guideOpenScreen => 'Open screen';

  @override
  String guideNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get copyVideoLink => 'Copy link';

  @override
  String get videoLinkCopied => 'Link copied';

  @override
  String get menuSectionOrganize => 'Organize';

  @override
  String get menuSectionCopy => 'Copy and export';

  @override
  String get menuSectionTools => 'Tools';

  @override
  String get menuSectionProtect => 'Protection and storage';

  @override
  String get menuSectionContent => 'Content';

  @override
  String get menuSectionPeople => 'Account and people';

  @override
  String get menuSectionHome => 'Home screen';

  @override
  String get menuSectionApp => 'App';

  @override
  String cardMoreFiles(int count) {
    return '+$count more files';
  }

  @override
  String cardAudioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voice recordings',
      one: 'Voice recording',
    );
    return '$_temp0';
  }

  @override
  String get cardBubbleDocument => 'PDF WITH BUBBLES';

  @override
  String get cardBubbleSlides => 'SLIDES WITH BUBBLES';

  @override
  String get cardKindPdf => 'PDF';

  @override
  String get cardKindSlides => 'SLIDES';

  @override
  String cardBubbleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bubbles',
      one: '1 bubble',
    );
    return '$_temp0';
  }

  @override
  String get quickAddYouTube => 'YouTube video';

  @override
  String get docViewToBubbles => 'Switch to bubbles view';

  @override
  String get docViewToClassic => 'Switch to classic view';

  @override
  String get docViewSwitchedBubbles =>
      'Bubbles view: document on top, page notes below. Your classic layout is kept.';

  @override
  String get docViewSwitchedClassic =>
      'Classic view: the document is an attachment on the page. Bubbles and page notes are kept.';

  @override
  String get docViewTextKept => 'The note\'s text stays in classic view.';

  @override
  String get captureModeChangeLater =>
      'You can switch later with the Bubbles / Classic chip in the note.';

  @override
  String get attachmentSyncTitle => 'Attachment sync';

  @override
  String get driveSectionTitle => 'Attachments in your Google Drive';

  @override
  String get driveConnectTitle => 'Keep attachments in your Google Drive';

  @override
  String get driveConnectInfo =>
      'Images, PDFs, slides and voice recordings are kept in your own Drive storage, in a hidden app folder, and download to your other devices. Videos stay on the device.';

  @override
  String get driveConnect => 'Connect';

  @override
  String get driveDisconnect => 'Disconnect';

  @override
  String get driveConnected =>
      'Google Drive connected — attachments are being backed up.';

  @override
  String get driveConnectedInfo =>
      'Connected · attachments live in your Drive\'s app folder';

  @override
  String driveUsage(String used, String limit) {
    return 'Drive: $used of $limit used';
  }

  @override
  String driveConnectFailed(String error) {
    return 'Couldn\'t connect Google Drive. $error';
  }

  @override
  String get driveApiDisabled =>
      'The Drive API is disabled in the Google Cloud project: enable \"Google Drive API\" in the console and try again.';

  @override
  String get driveDisconnected =>
      'Drive disconnected. New attachments wait on the device until you reconnect.';

  @override
  String get textOnlyTitle => 'Text-only sync';

  @override
  String get textOnlyInfo =>
      'Guest accounts sync text only; attachments stay on this device. Link a Google account to keep attachments in your Google Drive.';

  @override
  String get storageModeInfo =>
      'On the web, attachments are uploaded to the app\'s cloud.';

  @override
  String driveWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments are waiting for Google Drive — tap to connect',
      one: '1 attachment is waiting for Google Drive — tap to connect',
    );
    return '$_temp0';
  }

  @override
  String get driveDownloading =>
      'Downloading the attachment from Google Drive…';

  @override
  String get driveNeededForFile =>
      'This attachment is in your Google Drive. Connect Drive in Settings → Sync to see it.';

  @override
  String get bubbleDone => 'Done';

  @override
  String get bubbleEditShort => 'Edit';

  @override
  String get bubblePlainModeShort => 'Text';

  @override
  String get pageBarMore => 'Page and note options';

  @override
  String get viewModeTitle => 'View';

  @override
  String get viewModePinned => 'Pinned';

  @override
  String get viewModeFloating => 'Floating';

  @override
  String get viewModeBubbles => 'Bubbles';

  @override
  String get viewModePinnedHint =>
      'Pin to top — stays above, the note scrolls below';

  @override
  String get viewModeFloatingHint => 'Float on the page — text wraps around it';

  @override
  String get viewModeBubblesHint =>
      'Bubbles view — bubbles, highlights and pen on the page';

  @override
  String get viewModeSwitchedFloating => 'Back on the page';

  @override
  String get videoNoteAtTime => 'Note at this moment';

  @override
  String get videoNoteAtTimeShort => 'Note';

  @override
  String get videoTimeUnknown =>
      'Couldn\'t read the video time — play the video first.';

  @override
  String get videoSpeed => 'Playback speed';

  @override
  String get videoLoop => 'Loop';

  @override
  String get bubbleSmaller => 'Smaller bubble';

  @override
  String get bubbleLarger => 'Larger bubble';

  @override
  String get bubbleAllSmaller => 'Make all bubbles smaller';

  @override
  String get bubbleAllLarger => 'Make all bubbles larger';

  @override
  String get bubblesShow => 'Show bubbles';

  @override
  String get bubblesHide => 'Hide bubbles';

  @override
  String get shareIncludeVideoLinks => 'Video links';

  @override
  String get shareQuickPdf => 'PDF';

  @override
  String get shareAsImage => 'Image';

  @override
  String shareAttachmentFiles(int count) {
    return 'Files ($count)';
  }

  @override
  String get shareToFriendShort => 'Send a copy';

  @override
  String get shareCollaborateShort => 'Edit together';

  @override
  String get shareAsNoteShort => 'Note package';

  @override
  String get shareMoreSection => 'MORE';

  @override
  String get shareQuickPreparing => 'Preparing…';

  @override
  String get shareAttachmentFilesNone =>
      'No attachment files on this device to share.';

  @override
  String get attachmentRemoved => 'Attachment removed';

  @override
  String get pinnedEmbedOnPage => 'Embed on page (floating)';

  @override
  String get customizeHideItem => 'Hide';

  @override
  String get customizeShowItem => 'Show';

  @override
  String get customizeModeTitle => 'Edit mode';

  @override
  String get customizeModeHint => 'Tap items to hide or show them';

  @override
  String customizeHiddenCount(int count) {
    return '$count hidden · tap to change';
  }

  @override
  String get customizeSave => 'Save';

  @override
  String get customizeSaved => 'Layout saved';

  @override
  String videoBackSeconds(int seconds) {
    return 'Back $seconds s';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return 'Forward $seconds s';
  }

  @override
  String get personalizeTitle => 'Personalize';

  @override
  String get personalizeInfo => 'Choose visible areas and buttons, plug-ins';

  @override
  String get personalizeOpen => 'Open personalization';

  @override
  String get customizeStartTitle => 'Edit on screen';

  @override
  String get customizeStartInfo =>
      'Turn on edit mode, then tap buttons and areas on any screen to hide or show them. When you\'re done, tap Save in the strip at the top.';

  @override
  String get customizeStart => 'Start edit mode';

  @override
  String get customizeActive => 'Edit mode is on';

  @override
  String get customizeModeShort => 'Hide or show by tapping on screens';

  @override
  String get personalizeModules => 'PLUG-INS';

  @override
  String get personalizeModulesInfo =>
      'Turning a plug-in off removes its buttons everywhere.';

  @override
  String get moduleAi => 'AI';

  @override
  String get moduleAiInfo => 'AI buttons on the home and note screens';

  @override
  String get moduleVoice => 'Voice';

  @override
  String get moduleVoiceInfo => 'Voice notes, dictation, audio recording';

  @override
  String get moduleVideo => 'Video';

  @override
  String get moduleVideoInfo => 'Recording, gallery videos, YouTube';

  @override
  String get moduleDocuments => 'Documents';

  @override
  String get moduleScan => 'Scanning';

  @override
  String get moduleScanInfo => 'Document scanning and QR codes';

  @override
  String get moduleDrawing => 'Drawing';

  @override
  String get moduleDrawingInfo => 'Handwriting and drawing';

  @override
  String get moduleTemplates => 'Templates';

  @override
  String get moduleTemplatesInfo =>
      'Notes from templates, shopping list, archive notebook';

  @override
  String get moduleTags => 'Note chips';

  @override
  String get moduleTagsInfo => 'Tag, folder and reminder chips under the title';

  @override
  String get moduleCollaboration => 'Collaboration';

  @override
  String get moduleCollaborationInfo =>
      'The add-person button in the note screen';

  @override
  String get moduleMixed => 'partly on';

  @override
  String get personalizeEditorBar => 'NOTE SCREEN · BOTTOM BAR';

  @override
  String get personalizeEditorTop => 'NOTE SCREEN · TOP BAR AND AREAS';

  @override
  String get personalizeQuickAdd => 'NEW NOTE MENU (+)';

  @override
  String get personalizeAttachSheet => 'ADD SHEET (+ INSIDE A NOTE)';

  @override
  String get personalizeVideo => 'VIDEO';

  @override
  String get personalizeHome => 'HOME SCREEN';

  @override
  String get personalizeHomeItemsInfo =>
      'Selected items appear on the home screen; in edit mode you can also tap them on the home screen to hide.';

  @override
  String get personalizeBubbles => 'BUBBLES';

  @override
  String get personalizeChipsInfo =>
      'Selected items are visible; tap to toggle.';

  @override
  String get personalizeReset => 'Reset to default';

  @override
  String get personalizeResetConfirm =>
      'Reset all visibility and seek settings to default?';

  @override
  String get personalizeResetDone => 'Defaults restored';

  @override
  String get uiItemAttachments => 'Attachments';

  @override
  String get uiItemDate => 'Edit date';

  @override
  String get uiItemSync => 'Sync icon';

  @override
  String get uiItemVideoTime => 'Time label';

  @override
  String get videoSeekBack => 'Rewind';

  @override
  String get videoSeekForward => 'Fast-forward';

  @override
  String get bubbleSizeSetting => 'Bubble size';

  @override
  String get noteMenuCustomize => 'Customize screen';

  @override
  String secondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String personalizeHiddenSummary(int count) {
    return '$count hidden';
  }

  @override
  String get uiItemVideoBadge => 'VIDEO';

  @override
  String get listPartRemoved => 'List removed';

  @override
  String get textPartRemoved => 'Text removed';

  @override
  String get notePartsMenu => 'Sections';

  @override
  String get removeListPart => 'Remove list';

  @override
  String get removeTextPart => 'Remove text';

  @override
  String get transcriptTitle => 'Transcript';

  @override
  String get transcriptAction => 'Transcribe';

  @override
  String get transcriptFileSuffix => 'transcript';

  @override
  String get transcriptWorkingAudio => 'Transcribing audio…';

  @override
  String get transcriptWorkingVideo => 'Transcribing video…';

  @override
  String get transcriptWorkingImage => 'Reading the text in the image…';

  @override
  String get transcriptLongHint =>
      'Long recordings can take a few minutes; keep this screen open.';

  @override
  String get transcriptSaved => 'Saved to the note as a text attachment';

  @override
  String get transcriptInsertSelection => 'Add selection to note';

  @override
  String get transcriptInsertAll => 'Add all to note';

  @override
  String get transcriptInserted => 'Added to note';

  @override
  String get transcriptNewNote => 'New note';

  @override
  String get transcriptRetryAi => 'Re-transcribe with AI';

  @override
  String get transcriptReadWithAi => 'Read with AI (handwriting)';

  @override
  String get transcriptShowTimes => 'Timestamps';

  @override
  String get transcriptDelete => 'Delete transcript';

  @override
  String get transcriptDeleteConfirm =>
      'Delete the transcript? The source file stays in the note.';

  @override
  String get transcriptEmpty => 'No text found.';

  @override
  String transcriptTooLarge(int mb) {
    return 'The recording is $mb MB; the built-in AI accepts up to 15 MB. Add your own Gemini key in Settings to transcribe larger recordings.';
  }

  @override
  String transcriptUnsupported(String format) {
    return 'This recording format ($format) can\'t be transcribed.';
  }

  @override
  String get transcriptEdit => 'Edit';

  @override
  String get transcriptSave => 'Save';

  @override
  String transcriptWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String transcriptNoteTitle(String name) {
    return 'Transcript: $name';
  }

  @override
  String get transcriptOnDevice =>
      'Read on device · no internet or AI points used';

  @override
  String get addAudioFile => 'Add audio file';

  @override
  String get transcribeFile => 'Transcribe a file';

  @override
  String get transcribeFileSubtitle =>
      'Pick audio, video or an image; its text goes into the note';

  @override
  String cardTranscriptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transcripts',
      one: 'Transcript',
    );
    return '$_temp0';
  }

  @override
  String get transcriptPickTitle => 'File to transcribe';

  @override
  String get transcriptUnsupportedFile =>
      'This file type can\'t be transcribed (pick audio, video or an image).';

  @override
  String get pickPdfTitle => 'Choose a PDF';

  @override
  String get pickSlidesTitle => 'Choose a presentation';

  @override
  String get pickImagesTitle => 'Choose images';

  @override
  String get pickDocumentTitle => 'Choose a document';

  @override
  String get fileAppPickerTitle => 'Pick files with Dosya Okuyucu';

  @override
  String get fileAppPickerInfo =>
      'Adding a file opens Dosya Okuyucu directly, listing only files of the requested type (newest first). When off, you\'re asked which app to use.';

  @override
  String get viewModeAttached => 'Attached';

  @override
  String get viewModeAttachedHint =>
      'As attachment — stays in the strip at the bottom';

  @override
  String get textToBubblesPreparing => 'Laying out the text as a document…';

  @override
  String get attachmentActions => 'Attachment actions';

  @override
  String get attachmentOpen => 'Open';

  @override
  String get attachmentViewTitle => 'Where should it go?';

  @override
  String get attachmentUploadQueued => 'Waiting to upload';

  @override
  String get attachmentWaitingOwner =>
      'Waiting for the person who added it to upload it';

  @override
  String attachmentsUploadingCount(int count) {
    return 'Uploading $count attachments';
  }

  @override
  String get sharedNoteNew => 'New';

  @override
  String sharedNoteUpdatedBy(String name) {
    return 'Updated by $name';
  }

  @override
  String get sharedMarkAllRead => 'Mark all as read';

  @override
  String get attachmentSaveAs => 'Save as';

  @override
  String attachmentSavedAs(String name) {
    return '$name saved';
  }

  @override
  String get attachmentSaveAsFailed => 'Couldn\'t save the file';

  @override
  String get sharedHubTitle => 'Received & shared';

  @override
  String get sharedHubInbox => 'Received';

  @override
  String get voiceAutoStop => 'Stop on silence';

  @override
  String get voiceAutoStopInfo =>
      'When you finish speaking, listening stops by itself after a few seconds of silence.';

  @override
  String get voiceSmartCommands => 'Smart commands';

  @override
  String get voiceSmartCommandsInfo =>
      'While speaking you can say: “delete last word”, “delete last sentence”, “replace X with Y”, “change the last word to Y”, “new line”, “new item”, “question mark”, “full stop”, “insert comma”, “set the title to X”, “undo”, “clear all”, “stop listening”. Writing then continues from the end.';

  @override
  String get voiceAutoStopSoon => 'Silence — stopping soon';

  @override
  String get voiceCmdDeleted => 'Deleted';

  @override
  String get voiceCmdReplaced => 'Replaced';

  @override
  String get voiceCmdNewLine => 'New line';

  @override
  String get voiceCmdUndone => 'Undone';

  @override
  String get voiceCmdCleared => 'Cleared';

  @override
  String get fullscreenExit => 'Exit full screen';

  @override
  String get voiceCaptureContinue => 'Keep talking';

  @override
  String get voiceCmdPunctuation => 'Punctuation added';

  @override
  String get voiceCmdTitle => 'Title set';

  @override
  String get voiceSilenceLabel => 'Wait time';

  @override
  String get voiceSilenceShort => 'Short';

  @override
  String get voiceSilenceNormal => 'Normal';

  @override
  String get voiceSilenceLong => 'Long';

  @override
  String get voiceOffline => 'Offline recognition';

  @override
  String get voiceOfflineInfo =>
      'If the language pack is downloaded on your phone, speech is transcribed without going online. Without it, online recognition is used automatically.';

  @override
  String get discoverable => 'Let people find me by name';

  @override
  String get discoverableInfo =>
      'When on, others can find you in \"Find people\" by the first 3 letters of your name or your full email. When off, only someone who knows your email can send a request.';

  @override
  String get friendsSearchNeedsGoogle =>
      'Sign in with a Google account to search for people.';

  @override
  String get friendsSearchRateLimited =>
      'Too many searches. Try again in a minute.';

  @override
  String get updateRequiredBody =>
      'This version is outdated: notes open read-only. Update the app so your data stays intact.';

  @override
  String get updateAction => 'Update';

  @override
  String get attachmentUnsupportedTitle =>
      'Update the app to open this attachment';

  @override
  String get attachmentUnsupportedBody =>
      'This attachment was added in a newer version of the app. This version can\'t show it; it is kept as is.';

  @override
  String noteTooLarge(String size, String part) {
    return 'This note is getting too large ($size / 1024 KB) — largest part: $part. Move some of it to a separate note or it may fail to save.';
  }

  @override
  String get noteSizeBody => 'text';

  @override
  String get noteSizeItems => 'list items';

  @override
  String get noteSizePageNotes => 'page notes';

  @override
  String noteSaveRejected(String reason) {
    return 'The note could not be saved to the server: $reason';
  }

  @override
  String get errorLogShare => 'Share error log';

  @override
  String get errorLogInfo =>
      'Recent errors are kept only on this device; they go nowhere unless you share them.';

  @override
  String get errorLogEmpty => 'No errors recorded.';

  @override
  String get crashReports => 'Send crash reports';

  @override
  String get crashReportsInfo =>
      'When the app crashes, a technical report without your note content is sent to Firebase Crashlytics (Android only).';

  @override
  String get noteTooLargeShort => 'the note exceeds the 1 MiB limit';

  @override
  String get crashTestTitle => 'Send a test crash?';

  @override
  String get crashTestBody =>
      'To verify the Crashlytics setup the app closes immediately. When you reopen it, the report is sent to the Firebase console (may take a few minutes).';

  @override
  String get crashTestAction => 'Crash';

  @override
  String get captureModeSetting => 'Notes from content';

  @override
  String get captureModeSettingInfo =>
      'When taking a note from a photo, scan, PDF, slides or image. Your first choice becomes the default.';

  @override
  String get captureModeAsk => 'Ask every time';

  @override
  String get voiceMicTooltipDictate =>
      'Type as I speak — long-press: AI tidies';

  @override
  String get quickAddCamera => 'Camera';

  @override
  String get quickAddFile => 'Add file';

  @override
  String get quickAddFromDevice => 'Choose a file';

  @override
  String get quickAddFileWhat => 'What should we do with this file?';

  @override
  String get quickAddFileUnsupported => 'This file type is not supported';

  @override
  String get chatScopeAll => 'All notes';

  @override
  String get chatScopeNote => 'This note';

  @override
  String get chatScopeDoc => 'This document';

  @override
  String get chatModeQa => 'Q&A';

  @override
  String get chatModeBrainstorm => 'Brainstorm';

  @override
  String get aiChatRowTitle => 'Chat';

  @override
  String get aiChatRowInfo =>
      'With this note, its document or all notes; Q&A or brainstorm';

  @override
  String get shareFolderTogether => 'Edit folder together';

  @override
  String get shareTogetherSection => 'EDIT TOGETHER';

  @override
  String get shareTogetherInfo =>
      'You both see and change the same note or folder';

  @override
  String get shareCopySection => 'SEND A COPY';

  @override
  String get shareCopyInfo =>
      'An independent copy goes to your friend\'s inbox';

  @override
  String get notebookViewOn => 'Notebook view';

  @override
  String get notebookViewOff => 'Turn off notebook view';

  @override
  String inkSemantics(int count) {
    return 'Handwriting, $count strokes';
  }

  @override
  String bubbleSemantics(String text) {
    return 'Note bubble: $text';
  }

  @override
  String get bubbleSemanticsEmpty => 'Empty note bubble';

  @override
  String get guestReminderTitle => 'Your notes are not backed up';

  @override
  String get guestReminderBody =>
      'You are using the app without an account: your notes live only on this device. If the app is removed or you change phones they cannot be recovered. Link your Google account — your notes stay as they are.';

  @override
  String get guestReminderLater => 'Later';

  @override
  String get driveWebConnectTitle => 'This attachment is in your Google Drive';

  @override
  String get driveWebConnectBody =>
      'Files added on your phone are stored in Drive. To view them in the browser, allow access to Drive with your Google account (valid for this session).';

  @override
  String get driveWebConnectButton => 'Connect Drive';

  @override
  String get lockPatternSemantics =>
      'Lock pattern: connect the dots with your finger';

  @override
  String get lockDrawPattern => 'Draw your pattern';

  @override
  String get lockDrawAgain => 'Draw the pattern again to confirm';

  @override
  String get lockEnterPassword => 'Enter your password';

  @override
  String get lockPassword => 'Password';

  @override
  String get lockPasswordAgain => 'Password (again)';

  @override
  String get lockWrong => 'Wrong, try again';

  @override
  String lockTooManyAttempts(int count) {
    return 'Too many wrong attempts. Wait $count s.';
  }

  @override
  String get lockUseFingerprint => 'Unlock with fingerprint';

  @override
  String get lockForgot => 'Forgot';

  @override
  String get lockForgotFailed =>
      'Could not verify with your Google account. Guest accounts cannot reset the password.';

  @override
  String get lockNewPassword => 'New lock password';

  @override
  String get lockNewPattern => 'New lock pattern';

  @override
  String lockPasswordTooShort(int count) {
    return 'Password must be at least $count characters';
  }

  @override
  String lockPatternTooShort(int count) {
    return 'Pattern must connect at least $count dots';
  }

  @override
  String get lockMismatch => 'Did not match, try again';

  @override
  String get lockChangeAuthReason => 'Verify to change the lock setting';

  @override
  String get lockMethodTitle => 'Note lock';

  @override
  String get lockMethodInfo => 'How should locked notes open?';

  @override
  String get lockMethodDevice => 'Fingerprint';

  @override
  String get lockMethodPassword => 'Password';

  @override
  String get lockMethodPattern => 'Pattern';

  @override
  String get lockAlsoFingerprint => 'Also allow fingerprint';

  @override
  String get lockChangePassword => 'Change password';

  @override
  String get lockChangePattern => 'Change pattern';

  @override
  String get lockWebDeviceInfo =>
      'Browsers have no fingerprint: choose a password or pattern to protect locked notes on the web too.';

  @override
  String get lockNotEncryption =>
      'The lock is not encryption: the note content is stored as plain text on the server and in the device cache. The lock only stops this app from showing the note.';

  @override
  String get versionHistory => 'Version history';

  @override
  String get versionHistoryInfo =>
      'The note text is saved when opened, every half hour during long edits and before AI changes it. Attachments are not versioned.';

  @override
  String get versionHistoryEmpty =>
      'No versions yet. They collect here as you edit the note.';

  @override
  String get versionRestore => 'Restore this version';

  @override
  String get versionRestored => 'Note restored to the earlier version';

  @override
  String get versionReasonAi => 'Before AI change';

  @override
  String get versionReasonRestore => 'Before restoring';

  @override
  String get versionReasonOpen => 'As opened';

  @override
  String get versionReasonAuto => 'Automatic';

  @override
  String get mergeConflictKept =>
      'Someone else edited the same spot — both versions were kept, delete the extra one.';

  @override
  String presenceEditing(String name) {
    return '$name is editing now';
  }

  @override
  String get presenceSomeone => 'Someone';

  @override
  String get frameColorInfo =>
      'Drawn only around the card on the home screen, not inside the note';

  @override
  String get filterStarred => 'Starred';

  @override
  String get fileUseBubbles => 'Annotate as a document';

  @override
  String get fileUseClassic => 'Add to a note';

  @override
  String get fileUseClassicImageInfo =>
      'A plain note opens; images sit on the page and text flows around them.';

  @override
  String get fileUseVideo => 'Take notes on the video';

  @override
  String get fileUseVideoInfo =>
      'The video plays on top, you write your notes below.';

  @override
  String get fileUseAudio => 'Add as an audio attachment';

  @override
  String get fileUseAudioInfo =>
      'The recording stays playable in the note; transcribe it later if you like.';

  @override
  String get fileUseTranscribeInfo =>
      'Speech is transcribed and written into the note body.';

  @override
  String get fileUseTranscribeImageInfo =>
      'Text in the image is read and written into the note body.';

  @override
  String get fileUseDefault => 'Default';

  @override
  String fileUseMore(int count) {
    return '+$count more files';
  }

  @override
  String get quickAddSectionMore => 'More';

  @override
  String get attachAnyFileInfo =>
      'Any file: image, PDF, slides, audio, video — the type is detected, you\'re asked what to do when it matters';

  @override
  String get listeningModeAi => 'AI';

  @override
  String get listeningModeDictation => 'Live typing';

  @override
  String get dictationPanelHint => 'Text appears at the cursor as you speak';

  @override
  String get voiceStartShort => 'Start';

  @override
  String get aiVoiceRowTitle => 'Voice note';

  @override
  String get aiVoiceRowInfoEditor =>
      'Speak; AI tidies it up and adds it to this note';

  @override
  String get aiVoiceRowInfoHub =>
      'Speak; AI builds the note — title, items and reminders';

  @override
  String get archivePaperDashed => 'Dashed lines';

  @override
  String get itemDividerSolid => 'Line below';

  @override
  String get itemDividerDashed => 'Dashed line below';

  @override
  String get itemDividerDotted => 'Dotted line below';

  @override
  String get itemDividerRemove => 'Remove line';

  @override
  String get attachSectionFiles => 'Files and links';

  @override
  String get attachSectionCapture => 'Camera and recording';

  @override
  String get fileUseAttachInfo => 'Added to the note as a playable attachment';

  @override
  String get allNotesChip => 'All';

  @override
  String get archiveAiSearch => 'AI search (by meaning)';

  @override
  String get archiveAiSearchHint => 'Search the archive by meaning…';

  @override
  String get untitledNote => 'Untitled note';

  @override
  String get trashAnalysis => 'Trash analysis';

  @override
  String get trashAnalyze => 'Smart analysis';

  @override
  String get trashAiRun => 'Deep analysis with AI';

  @override
  String get trashAiRunning => 'Analyzing…';

  @override
  String get trashAiInfo =>
      'On-device rules are ready. AI analysis sends a short digest of the notes to the model; locked notes are never sent.';

  @override
  String get trashAiNothing =>
      'Nothing to analyze (locked notes are never sent)';

  @override
  String get trashSuggestRestore => 'Consider restoring';

  @override
  String get trashSuggestDelete => 'Safe to delete';

  @override
  String get trashSuggestNone => 'No suggestions';

  @override
  String trashRestoreAllSuggested(int count) {
    return 'Restore all ($count)';
  }

  @override
  String trashDeleteAllSuggested(int count) {
    return 'Delete all ($count)';
  }

  @override
  String trashStatNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String trashStatAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count attachments',
      one: '1 attachment',
    );
    return '$_temp0';
  }

  @override
  String trashStatSoon(int count) {
    return '$count going within 3 days';
  }

  @override
  String trashStatLocked(int count) {
    return '$count locked (not inspected)';
  }

  @override
  String get trashReasonEmpty => 'Empty — nothing to lose';

  @override
  String get trashReasonDuplicate => 'An identical note already exists';

  @override
  String trashReasonDuplicateOf(String title) {
    return 'Identical to: $title';
  }

  @override
  String get trashReasonDuplicateInTrash => 'A newer copy is also in the trash';

  @override
  String trashReasonOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open tasks',
      one: '1 open task',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonReminder => 'Has an upcoming reminder';

  @override
  String get trashReasonSensitive =>
      'Contains info like passwords, IBAN, phone numbers';

  @override
  String trashReasonAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Has $count attachments',
      one: 'Has 1 attachment',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonSubstantial => 'Long, substantial text';

  @override
  String get trashReasonAi => 'AI suggestion';

  @override
  String get cardElementsHeader => 'Shown on cards';

  @override
  String get cardShowProgress => 'Progress counter (e.g. 3/10)';

  @override
  String get cardShowProgressInfo =>
      'Shows how many to-do items are checked, with a bar and a count.';

  @override
  String get cardShowMoreCount => '“+N more items” line';

  @override
  String get cardShowStatusIcons => 'Status icons';

  @override
  String get cardShowStatusIconsInfo =>
      'Pinned, starred, reminder, shared, this device only…';

  @override
  String get cardShowTag => 'Tag';

  @override
  String get cardShowDate => 'Date and time';

  @override
  String get cardShowMedia => 'Images and videos';

  @override
  String get cardShowFolder => 'Folder name';

  @override
  String get cardShowFolderInfo =>
      'The note\'s folder in search results and in the All view.';

  @override
  String get cardShowPaper => 'Notebook paper pattern';

  @override
  String get settingsAiSearch => 'Search with AI';

  @override
  String get settingsAiSearchHint =>
      'Describe what you want — “text is too small”';

  @override
  String get settingsAiSearchGo => 'Find';

  @override
  String get settingsAiSearchEmpty =>
      'No matching setting found. Try other words.';

  @override
  String get settingsAiSearchFound => 'Settings found by AI';

  @override
  String get formatFontPanel => 'Font and size';

  @override
  String get formatColorsPanel => 'Colors';

  @override
  String get formatPageColor => 'Page color';

  @override
  String get inkShapes => 'Shapes';

  @override
  String get inkShapeLine => 'Straight line';

  @override
  String get inkShapeRectangle => 'Rectangle';

  @override
  String get inkShapeEllipse => 'Circle / ellipse';

  @override
  String get inkPenOnlyOn => 'Pen only (finger scrolls) — turn off';

  @override
  String get inkPenOnlyOff => 'Finger also draws — switch to pen only';

  @override
  String get inkPenOnlyHint =>
      'Write with the pen · drag with a finger, pinch to zoom';

  @override
  String get inkSettings => 'Pen settings';

  @override
  String get inkWidth => 'Thickness';

  @override
  String get inkOpacity => 'Opacity';

  @override
  String get inkRecentColors => 'Recent colors';

  @override
  String get inkPenOnlyTitle => 'Draw with pen only';

  @override
  String get inkPenOnlyInfo =>
      'Fingers don\'t draw; one finger scrolls, two fingers zoom. Your palm leaves no marks. Turns on automatically the first time a pen touches the screen.';

  @override
  String get inkPressureTitle => 'Pressure sensitivity';

  @override
  String get inkPressureInfo =>
      'Light pressure writes thin, firm pressure writes thick.';

  @override
  String get inkStylusTipsTitle => 'Pen shortcuts';

  @override
  String get inkStylusTips =>
      'Hold the pen\'s side button or touch with the eraser end to erase. Undo / redo are in the top row.';

  @override
  String get inkZoomReset => 'Fit to screen';

  @override
  String get inkZoomHint => 'Pinch with two fingers to zoom and pan';

  @override
  String get cardShowFiles => 'File attachments';

  @override
  String get cardShowFilesInfo =>
      'Show PDF, slide, audio and text attachments on cards';

  @override
  String get cardShowMediaShort => 'Images on cards';

  @override
  String get cardShowFilesShort => 'Attachments on cards';

  @override
  String get homeShowShared => 'Shared notes on home screen';

  @override
  String get homeShowSharedInfo =>
      'Also show notes shared with me in a separate section at the top of the home screen';

  @override
  String get homeShowSharedShort => 'Shared';

  @override
  String get homeSharedSection => 'SHARED WITH ME';

  @override
  String get copyAttachment => 'Copy attachment';

  @override
  String get attachmentCopiedPasteHint =>
      'Attachment copied — paste it into another note from the + menu';

  @override
  String get dividerSettings => 'Line settings';

  @override
  String get dividerPreviewText => 'Sample item';

  @override
  String get dividerKind => 'Style';

  @override
  String get dividerColor => 'Color';

  @override
  String get dividerWeight => 'Thickness';

  @override
  String get dividerApplyAll => 'Apply to all';

  @override
  String get dividerKindSolid => 'Solid';

  @override
  String get dividerKindDashed => 'Dashed';

  @override
  String get dividerKindDotted => 'Dotted';

  @override
  String get dividerKindDouble => 'Double';

  @override
  String get dividerKindWavy => 'Wavy';

  @override
  String get itemMenuUnstar => 'Unstar';

  @override
  String get itemMenuMove => 'Move';

  @override
  String get itemMenuDelete => 'Delete';

  @override
  String get itemMenuLine => 'Line below';

  @override
  String get formatStyleText => 'Text';

  @override
  String get formatStyleH1 => 'Title';

  @override
  String get formatStyleH2 => 'Subtitle';

  @override
  String get formatSizeDown => 'Smaller';

  @override
  String get formatSizeUp => 'Larger';

  @override
  String get imageCaptionHint => 'Image caption';

  @override
  String get imageCaptionAdd => 'Add caption';

  @override
  String get imageCaptionEdit => 'Edit caption';

  @override
  String get voiceRecordResume => 'Resume recording';

  @override
  String get voiceRecordDiscard => 'Discard recording';

  @override
  String get checkboxToggle => 'Checkbox';

  @override
  String get noteAppearance => 'Appearance';

  @override
  String get noteThemeNone => 'Plain';

  @override
  String get noteThemePalm => 'Palm';

  @override
  String get noteThemeLagoon => 'Lagoon';

  @override
  String get noteThemeNight => 'Night';

  @override
  String get noteThemeSunset => 'Sunset';

  @override
  String get noteThemeSakura => 'Sakura';

  @override
  String get noteThemeWaves => 'Sea';

  @override
  String get noteThemeMeadow => 'Meadow';

  @override
  String get noteThemePaper => 'Paper';

  @override
  String get pinToHomeScreen => 'Add to home screen';

  @override
  String get pinToHomeSent =>
      'Confirm on your home screen — the note will open from its shortcut';

  @override
  String get pinToHomeUnsupported =>
      'Your home screen doesn\'t support this shortcut';

  @override
  String get inkColor => 'Pen color';

  @override
  String get formatApplyAll => 'Apply to all';

  @override
  String get formatApplyItem => 'Apply to item';

  @override
  String get cardMediaHide => 'Hide image preview';

  @override
  String get cardMediaShow => 'Show image preview';

  @override
  String get youTubeEmbedInNote => 'Embed in note';

  @override
  String get goToLink => 'Go to link';

  @override
  String get noteFlatColors => 'Plain colors';

  @override
  String get youTubeEmbedded => 'Video embedded in the note';
}
