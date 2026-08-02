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
  String get attachmentUploading => 'Uploading...';

  @override
  String get attachmentNotSynced =>
      'This file hasn\'t synced to this device yet';

  @override
  String attachmentTooLarge(int limit) {
    return 'File is too large ($limit MB max)';
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
  String get chatTitle => 'Chat with your notes';

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
  String get aiModelDocument => 'Podcasts and document chat';

  @override
  String get aiModelTranslate => 'Translation';

  @override
  String get aiModelVoice => 'Voice notes';

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
  String get aiProviderInfo => 'Choose the provider your own key belongs to. Each provider’s key is stored separately, so switching back does not require typing it again.';

  @override
  String get apiKeyFieldLabel => 'API key';

  @override
  String get getApiKey => 'Where do I get a key?';

  @override
  String get recommendedModel => 'Recommended';

  @override
  String get freeTierBadge => 'Has a free tier';
}
