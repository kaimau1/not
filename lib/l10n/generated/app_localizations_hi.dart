// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'नोट्स';

  @override
  String get loginTagline => 'आपके नोट्स, हर डिवाइस पर';

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String loginError(String error) {
    return 'साइन इन विफल: $error';
  }

  @override
  String get searchHint => 'नोट्स में खोजें...';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterText => 'टेक्स्ट';

  @override
  String get filterChecklist => 'सूची';

  @override
  String get filterOrdered => 'क्रमांकित';

  @override
  String get filterPinned => 'पिन किए गए';

  @override
  String get filterStarred => 'तारांकित';

  @override
  String get star => 'तारांकित करें';

  @override
  String get unstar => 'तारा हटाएँ';

  @override
  String editedAt(String date) {
    return 'संपादित: $date';
  }

  @override
  String get sectionPinned => 'पिन किए गए';

  @override
  String get sectionOthers => 'अन्य';

  @override
  String get emptyNotes => 'अभी कोई नोट नहीं';

  @override
  String get emptyNotesHint => 'अपना पहला नोट बनाने के लिए + दबाएँ';

  @override
  String get emptySearch => 'कोई परिणाम नहीं मिला';

  @override
  String get newTextNote => 'टेक्स्ट नोट';

  @override
  String get newChecklist => 'सूची';

  @override
  String get newOrderedList => 'क्रमांकित सूची';

  @override
  String get noteDeleted => 'नोट हटाया गया';

  @override
  String notesDeletedCount(int count) {
    return '$count नोट हटाए गए';
  }

  @override
  String selectedCount(int count) {
    return '$count चुने गए';
  }

  @override
  String get deleteSelected => 'चुने हुए हटाएँ';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get redo => 'फिर से करें';

  @override
  String get titleHint => 'शीर्षक';

  @override
  String get bodyHint => 'नोट...';

  @override
  String get newItemHint => 'नया आइटम';

  @override
  String moreItemsCount(int count) {
    return '+$count और आइटम';
  }

  @override
  String get addAttachment => 'जोड़ें';

  @override
  String get addAttachmentMore => 'अन्य अटैचमेंट प्रकार…';

  @override
  String get addImage => 'चित्र जोड़ें';

  @override
  String get addPdf => 'PDF जोड़ें';

  @override
  String get addSlide => 'स्लाइड जोड़ें';

  @override
  String get pasteImage => 'क्लिपबोर्ड से चित्र चिपकाएँ';

  @override
  String get clipboardEmpty => 'क्लिपबोर्ड में कोई चित्र नहीं है';

  @override
  String get noNoteSelected => 'बाईं ओर से कोई नोट चुनें';

  @override
  String attachmentFailed(String error) {
    return 'अनुलग्नक नहीं जोड़ा जा सका: $error';
  }

  @override
  String get attachmentCopying => 'कॉपी हो रहा है...';

  @override
  String get attachmentUploading => 'अपलोड हो रहा है...';

  @override
  String get attachmentUploadFailed =>
      'अपलोड नहीं हो सका — दोबारा कोशिश करने के लिए टैप करें';

  @override
  String get attachmentNotSynced =>
      'यह फ़ाइल अभी इस डिवाइस पर सिंक नहीं हुई है';

  @override
  String attachmentTooLarge(int limit) {
    return 'फ़ाइल बहुत बड़ी है (अधिकतम $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'स्टोरेज भर गया है ($limit)। जगह खाली करने के लिए पुराने अटैचमेंट हटाएँ।';
  }

  @override
  String get storageUsage => 'स्टोरेज';

  @override
  String storageUsageValue(String used, String limit) {
    return '$limit में से $used इस्तेमाल';
  }

  @override
  String get removeAttachment => 'अनुलग्नक हटाएँ';

  @override
  String get pin => 'पिन करें';

  @override
  String get unpin => 'पिन हटाएँ';

  @override
  String get delete => 'हटाएँ';

  @override
  String get color => 'रंग';

  @override
  String get aiTitle => 'AI';

  @override
  String get aiSummarize => 'नोट का सारांश बनाएँ';

  @override
  String get aiAnalyze => 'विश्लेषण करें';

  @override
  String get aiSectionNote => 'यह नोट';

  @override
  String get aiSectionAttachments => 'अनुलग्नक';

  @override
  String get summarize => 'सारांश बनाएँ';

  @override
  String get summaryDetailTitle => 'सारांश का प्रकार';

  @override
  String get summaryShort => 'संक्षिप्त सारांश';

  @override
  String get summaryShortInfo => 'कुछ वाक्यों का अवलोकन और मुख्य बिंदु';

  @override
  String get summaryDetailed => 'विस्तृत सारांश';

  @override
  String get summaryDetailedInfo =>
      'इतना पूरा कि मूल दस्तावेज़ खोलने की ज़रूरत न पड़े';

  @override
  String get listen => 'सुनें';

  @override
  String get ask => 'प्रश्न पूछें';

  @override
  String get extractText => 'टेक्स्ट निकालें';

  @override
  String get transcribe => 'प्रतिलेखन करें';

  @override
  String get listenToNote => 'ज़ोर से पढ़ें';

  @override
  String get aiNoApiKey => 'पहले सेटिंग में अपनी Gemini API कुंजी दर्ज करें';

  @override
  String aiError(String error) {
    return 'AI अनुरोध विफल: $error';
  }

  @override
  String get aiSummaryTitle => 'AI सारांश';

  @override
  String get aiThinking => 'सोच रहा हूँ...';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get settingsSearchHint => 'सेटिंग खोजें — “briefing”, “microphone”';

  @override
  String settingsSearchEmpty(String query) {
    return '«$query» से मेल खाने वाली कोई सेटिंग नहीं है';
  }

  @override
  String get settings => 'सेटिंग';

  @override
  String get settingsAppearance => 'रूप';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'हल्का';

  @override
  String get themeDark => 'गहरा';

  @override
  String get settingsAi => 'AI';

  @override
  String get geminiApiKey => 'Gemini API कुंजी';

  @override
  String get geminiApiKeyHint => 'AIza... से शुरू होने वाली कुंजी चिपकाएँ';

  @override
  String get geminiApiKeyInfo =>
      'कुंजी वैकल्पिक है: इसके बिना AI अनुरोध ऐप की अंतर्निहित सेवा से जाते हैं (एक मुफ़्त दैनिक सीमा, Premium के साथ अधिक)। अपनी कुंजी के साथ असीमित उपयोग के लिए aistudio.google.com से मुफ़्त कुंजी लें; कुंजी केवल इसी डिवाइस पर, सुरक्षित संग्रह में रखी जाती है।';

  @override
  String aiBuiltInPremium(int count) {
    return 'अंतर्निहित AI: Premium — आज $count अंक शेष';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'अंतर्निहित AI: आज $count मुफ़्त अंक शेष';
  }

  @override
  String get aiBuiltInByok => 'अपनी कुंजी के साथ — असीमित';

  @override
  String get aiReport => 'इस उत्तर की शिकायत करें';

  @override
  String get aiReportThanks => 'शिकायत मिल गई, धन्यवाद';

  @override
  String get privacyPolicyTitle => 'गोपनीयता नीति';

  @override
  String get lockNote => 'लॉक करें';

  @override
  String get unlockNote => 'अनलॉक करें';

  @override
  String get lockedNote => 'लॉक किया हुआ नोट';

  @override
  String get unlockAuthReason =>
      'लॉक किया हुआ नोट खोलने के लिए अपनी पहचान सत्यापित करें';

  @override
  String get exportBackup => 'बैकअप निर्यात करें (JSON)';

  @override
  String get expandListItems => 'सूची की पंक्तियाँ पूरी दिखाएँ';

  @override
  String get expandListItemsInfo =>
      'लंबे आइटम कई पंक्तियों में लिपटते हैं और पूरे दिखते रहते हैं। बंद होने पर पंक्ति एक ही लाइन में रहती है और छूने पर खुलती है।';

  @override
  String get quickCaptureRowSetting => 'त्वरित नोट पट्टी';

  @override
  String get quickCaptureRowInfo =>
      'होम स्क्रीन के ऊपर एक-पंक्ति \"नया नोट...\" फ़ील्ड दिखाता है। बंद होने पर + बटन का उपयोग करें।';

  @override
  String get emptyTrash => 'कचरा खाली करें';

  @override
  String emptyTrashConfirm(int count) {
    return '$count नोट हमेशा के लिए हटा दिए जाएँगे। इसे पूर्ववत नहीं किया जा सकता। क्या आप निश्चित हैं?';
  }

  @override
  String get trashEmptied => 'कचरा खाली कर दिया गया';

  @override
  String get validateAndSave => 'जाँचें और सहेजें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get aiDiagnostics => 'AI निदान';

  @override
  String get aiDiagnosticsEmpty => 'कोई त्रुटि दर्ज नहीं';

  @override
  String aiDiagnosticsCount(int count) {
    return 'पिछली $count त्रुटि प्रविष्टियाँ';
  }

  @override
  String get apiKeyValid => 'API कुंजी सत्यापित और सहेजी गई';

  @override
  String get apiKeyInvalid => 'API कुंजी मान्य नहीं है';

  @override
  String get apiKeySavedBadge => 'सहेजी गई';

  @override
  String get removeApiKey => 'कुंजी हटाएँ';

  @override
  String get refresh => 'ताज़ा करें';

  @override
  String get account => 'खाता';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get signOutConfirm => 'क्या आप वाकई साइन आउट करना चाहते हैं?';

  @override
  String get signOutAnonymousWarning =>
      'आप स्थानीय खाते में हैं: साइन आउट करने पर यह खाता और सभी नोट्स हमेशा के लिए दुर्गम हो जाएँगे — बैकअप के बिना वापस नहीं आ सकते। पहले Google खाता जोड़ें। फिर भी साइन आउट करें?';

  @override
  String get deleteAccount => 'मेरा खाता और डेटा हटाएँ';

  @override
  String get deleteAccountWarning =>
      'इसे पूर्ववत नहीं किया जा सकता: आपके सभी नोट, अनुलग्नक और आपका खाता हमेशा के लिए हटा दिए जाएँगे। क्या आप जारी रखना चाहते हैं?';

  @override
  String get deleteAccountConfirm => 'हमेशा के लिए हटाएँ';

  @override
  String get licensesTitle => 'ओपन-सोर्स लाइसेंस';

  @override
  String get generating => 'बनाया जा रहा है...';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get close => 'बंद करें';

  @override
  String get ok => 'ठीक है';

  @override
  String get syncPending => 'सिंक होने की प्रतीक्षा में';

  @override
  String get synced => 'सिंक हो गया';

  @override
  String genericError(String error) {
    return 'कुछ गड़बड़ हो गई: $error';
  }

  @override
  String get addTag => 'टैग';

  @override
  String get tagHint => 'जैसे काम, घर, स्कूल';

  @override
  String get addReminder => 'याद दिलाएँ';

  @override
  String get share => 'साझा करें';

  @override
  String get archive => 'संग्रहित करें';

  @override
  String get unarchive => 'संग्रह से निकालें';

  @override
  String get archiveTitle => 'संग्रह';

  @override
  String get archiveEmpty => 'संग्रह में कोई नोट नहीं';

  @override
  String get trashTitle => 'कचरा';

  @override
  String get trashEmpty => 'कचरा खाली है';

  @override
  String get trashInfo =>
      'हटाए गए नोट यहीं रहते हैं; आप उन्हें वापस ला सकते हैं या हमेशा के लिए हटा सकते हैं।';

  @override
  String get restore => 'वापस लाएँ';

  @override
  String get deleteForever => 'हमेशा के लिए हटाएँ';

  @override
  String get deleteForeverConfirm =>
      'यह नोट हमेशा के लिए हटा दिया जाएगा। क्या आप निश्चित हैं?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'सहायक "${title}" नोट को कूड़ेदान में डालना चाहता है। क्या आप सहमत हैं?';
  }

  @override
  String get recordAudio => 'आवाज़ रिकॉर्डिंग';

  @override
  String get recording => 'रिकॉर्ड हो रहा है...';

  @override
  String get stopAndSave => 'समाप्त करें और जोड़ें';

  @override
  String get micPermissionDenied => 'माइक्रोफ़ोन की अनुमति अस्वीकार कर दी गई';

  @override
  String get speechRecognitionFailed =>
      'वाक् पहचान काम नहीं कर पाई। जाँचें कि माइक्रोफ़ोन की अनुमति दी गई है और Google ऐप अद्यतन है।';

  @override
  String get addDrawing => 'चित्रकारी जोड़ें';

  @override
  String get drawingTitle => 'चित्रकारी';

  @override
  String get addToNote => 'नोट में जोड़ें';

  @override
  String get chatTitle => 'नोट असिस्टेंट';

  @override
  String get chatHint =>
      'अपने नोट्स के बारे में पूछें: «पिछले हफ़्ते लिखी वह रेसिपी क्या थी?», «मेरी खरीदारी सूची में क्या छूट रहा है?»';

  @override
  String get chatInputHint => 'प्रश्न लिखें...';

  @override
  String get fontSize => 'टेक्स्ट का आकार';

  @override
  String get fontSizePreview => 'आपके नोट ऐसे दिखेंगे';

  @override
  String get darkSchedule => 'गहरी थीम का समय';

  @override
  String get darkScheduleInfo =>
      'आपके तय किए घंटों के बीच गहरी थीम पर चला जाता है';

  @override
  String get aiTranslate => 'अनुवाद करें';

  @override
  String get voiceCommand => 'आवाज़ कमांड';

  @override
  String get semanticSearchToggle => 'AI से अर्थ-आधारित खोज';

  @override
  String get semanticSearchHint => 'अर्थ से खोजें: «गाड़ी का खर्च»...';

  @override
  String get briefingTitle => 'दिन की झलक';

  @override
  String get briefingLoading => 'आपकी झलक तैयार हो रही है...';

  @override
  String get briefingEmpty => 'आज के लिए कुछ नहीं';

  @override
  String get briefingSetting => 'दैनिक झलक की सूचना';

  @override
  String get briefingSettingInfo =>
      'हर सुबह आपके चुने हुए समय पर दिन के सारांश की सूचना पाएँ';

  @override
  String get autoTagSetting => 'अपने आप टैग करें';

  @override
  String get autoTagSettingInfo =>
      'जब कोई नोट बिना टैग के बंद होता है, AI एक उपयुक्त टैग जोड़ देता है';

  @override
  String get suggestTags => 'टैग सुझाएँ';

  @override
  String get aiFixNote => 'नोट सुधारें';

  @override
  String get fixLevelTitle => 'कितना सुधारना है?';

  @override
  String get fixSimple => 'हल्का';

  @override
  String get fixSimpleInfo => 'केवल वर्तनी और टाइपिंग की गलतियाँ';

  @override
  String get fixBalanced => 'संतुलित';

  @override
  String get fixBalancedInfo => 'वाक्य रचना भी, ताकि लेखन साफ़ हो';

  @override
  String get fixDetailed => 'गहन';

  @override
  String get fixDetailedInfo =>
      'पूरे टेक्स्ट को शुरू से आखिर तक फिर से लिखता है';

  @override
  String get existingTagsLabel => 'पिछले टैग';

  @override
  String get aiSkipCheckedSetting => 'AI के संपादन से चिह्नित आइटम बाहर रखें';

  @override
  String get aiSkipCheckedInfo =>
      'जब AI किसी सूची को सुधारता या अनुवाद करता है, पूरे हो चुके (चिह्नित) आइटम जस के तस रहते हैं; केवल बिना चिह्न वाले आइटम बदले जाते हैं।';

  @override
  String get noteUpdatedUndo => 'नोट अद्यतन हुआ';

  @override
  String get aiImprove => 'नोट बेहतर बनाएँ';

  @override
  String get improveFormal => 'और औपचारिक बनाएँ';

  @override
  String get improveShorten => 'छोटा करें';

  @override
  String get improveBullets => 'बुलेट सूची में बदलें';

  @override
  String get improveNumbered => 'क्रमांकित सूची में बदलें';

  @override
  String get replaceNote => 'नोट बदलें';

  @override
  String get openAsNewNote => 'नए नोट के रूप में';

  @override
  String get pdfChatHint =>
      'इस PDF के बारे में पूछें: «इसका सारांश दो», «क्या इसमें दंड की शर्त है?», «अंतिम तारीख क्या है?»';

  @override
  String get pdfChatInputHint => 'PDF के बारे में प्रश्न लिखें...';

  @override
  String get voiceCaptureHint =>
      'बोलिए: «दूध और ब्रेड खरीदनी है» या «कल 9 बजे मीटिंग है, याद दिलाना» — आपके बोलने के बाद AI आपका नोट बना देता है।';

  @override
  String get voiceFinish => 'समाप्त करें';

  @override
  String get voiceProcessing => 'आपकी बात पर काम हो रहा है...';

  @override
  String get voiceNothingHeard => 'रिकॉर्डिंग में कोई बोली नहीं मिली';

  @override
  String get voiceNoteSaved => 'आपका आवाज़ नोट सहेज लिया गया';

  @override
  String get openNote => 'नोट खोलें';

  @override
  String get remindersTitle => 'अनुस्मारक';

  @override
  String get remindersEmpty => 'कोई अनुस्मारक नहीं';

  @override
  String get remindersEmptyHint =>
      'किसी नोट में अनुस्मारक जोड़ें, या + बटन से अनुस्मारक वाला नया नोट बनाएँ';

  @override
  String get remindersUpcoming => 'आगामी';

  @override
  String get remindersPast => 'बीते हुए';

  @override
  String get reminderInPast =>
      'चुना गया समय बीत चुका है — भविष्य का समय चुनें।';

  @override
  String get newReminder => 'नया अनुस्मारक';

  @override
  String get remindersUntitled => 'बिना शीर्षक का नोट';

  @override
  String get remindersEdit => 'समय बदलें';

  @override
  String get remindersRemove => 'अनुस्मारक हटाएँ';

  @override
  String get aiModelChat => 'सारांश, शीर्षक, टैग और बातचीत';

  @override
  String get aiModelDocument => 'दस्तावेज़ चैट और PDF सारांश';

  @override
  String get aiModelTranslate => 'अनुवाद';

  @override
  String get aiModelVoice => 'वॉइस नोट सहायक';

  @override
  String get aiModelAuto => 'स्वचालित (अनुशंसित)';

  @override
  String get aiModelsInfo =>
      'आप हर काम के लिए अलग मॉडल चुन सकते हैं: छोटे टेक्स्ट के लिए तेज़ मॉडल ठीक है, लंबे दस्तावेज़ों के लिए सक्षम मॉडल चाहिए। यदि चुना हुआ मॉडल अपनी सीमा पर पहुँच जाए या हटा दिया जाए, तो अगला अपने आप आज़माया जाता है।';

  @override
  String get clearNote => 'खाली करें';

  @override
  String get clearNoteConfirm =>
      'नोट की सामग्री (टेक्स्ट और सूची के आइटम) हटा दी जाएगी। क्या आप निश्चित हैं?';

  @override
  String get themePaper => 'कागज़';

  @override
  String get calculatorTitle => 'कैलकुलेटर';

  @override
  String get calcExpressionHint => 'जैसे 12.5×3+40';

  @override
  String get calcInvalid => 'अमान्य अभिव्यक्ति';

  @override
  String get liveDictation => 'बोलकर लिखवाएँ';

  @override
  String get dictationListening =>
      'सुन रहा हूँ... बोलते ही टेक्स्ट आता जाता है';

  @override
  String get dictationNoKeyInfo =>
      'इस डिवाइस पर सीधा श्रुतलेख उपलब्ध नहीं है; रुकने पर रिकॉर्डिंग एक साथ प्रतिलेखित की जाएगी।';

  @override
  String get dictationHoldHint =>
      'माइक्रोफ़ोन दबाए रखें और बोलें; छोड़ने पर टेक्स्ट लिखा जाता है';

  @override
  String itemsSelected(int count) {
    return '$count आइटम चुने गए';
  }

  @override
  String get noteChatTitle => 'इस नोट से बात करें';

  @override
  String get noteChatHint => 'इस नोट के बारे में कुछ पूछें';

  @override
  String get noteChatIntro =>
      'नोट की सामग्री और उसके अनुलग्नक (PDF/चित्र) पढ़े जाते हैं, और आपके प्रश्न का उत्तर उन्हीं से दिया जाता है।';

  @override
  String get dictationProcessing => 'प्रतिलेखन हो रहा है...';

  @override
  String get aiDailyManualInfo =>
      'मुफ़्त योजना में यह अपने आप नहीं बनता, इसलिए आपकी दैनिक सीमा खर्च नहीं होती। नीचे दिए बटन से आप इसे दिन में एक बार बना सकते हैं।';

  @override
  String get aiGenerate => 'बनाएँ';

  @override
  String get aiGeneratedTodayInfo =>
      'यह आज बनाया गया था। मुफ़्त योजना में यह दिन में एक बार नया होता है; आप इसे कल फिर बना सकते हैं।';

  @override
  String get voiceAssistantTitle => 'आवाज़ नोट सहायक';

  @override
  String get voiceListening => 'सुन रहा हूँ...';

  @override
  String get voiceHoldHint =>
      'दबाए रखें और बोलें; छोड़ने पर आपका नोट बन जाता है';

  @override
  String get voiceTapHint => 'छूकर बोलें; समाप्त करने के लिए फिर छुएँ';

  @override
  String get voiceTooShort => 'वह रिकॉर्डिंग बहुत छोटी थी, फिर कोशिश करें';

  @override
  String get voiceModeSetting => 'यह कैसे काम करता है';

  @override
  String get voiceModeHold => 'बोलने के लिए दबाए रखें';

  @override
  String get voiceModeTap => 'शुरू करने के लिए छुएँ / रोकने के लिए छुएँ';

  @override
  String get voiceModeInfo =>
      'बोलने के लिए दबाए रखें: जब तक आप बटन दबाए रखते हैं यह सुनता है और छोड़ने पर नोट बना देता है। शुरू करने के लिए छुएँ: एक बार छूने पर रिकॉर्डिंग शुरू होती है, दूसरी बार छूने पर बंद।';

  @override
  String get voiceHeardLive => 'बोली पहचानी गई';

  @override
  String get voiceCaptureReady => 'बोली तैयार है';

  @override
  String get voiceCaptureEditHint => 'संपादित करने के लिए टेक्स्ट पर टैप करें';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · स्वचालित विराम चिह्न';
  }

  @override
  String get voiceCaptureAddToNote => 'नोट में जोड़ें';

  @override
  String get voiceCaptureCreateNote => 'नया नोट बनाएं';

  @override
  String get voiceCaptureAiNote => 'AI नोट';

  @override
  String get voiceCapturePlainNote => 'सादा नोट';

  @override
  String get voiceCloseTitle => 'आपका डिक्टेशन अब भी यहाँ है';

  @override
  String get voiceCloseKeepTalking => 'बोलना जारी रखें';

  @override
  String get voiceCaptureRestart => 'फिर से रिकॉर्ड करें';

  @override
  String get voiceChipSummarizeAdd => 'सारांश के रूप में जोड़ें';

  @override
  String get voiceChipSummarizeSave => 'सारांश के रूप में सहेजें';

  @override
  String get voiceChipToItems => 'आइटम में विभाजित करें';

  @override
  String get voiceChipAsList => 'चेकलिस्ट बनाएं';

  @override
  String get voiceChipFix => 'साफ करें';

  @override
  String get voiceChipCompose => 'असिस्टेंट को लिखने दें';

  @override
  String get editorToolList => 'सूची';

  @override
  String get permissionsTitle => 'अनुमतियाँ';

  @override
  String get permMic => 'माइक्रोफ़ोन';

  @override
  String get permMicInfo => 'आवाज़ नोट और श्रुतलेख के लिए ज़रूरी';

  @override
  String get permNotifications => 'सूचनाएँ';

  @override
  String get permNotificationsInfo => 'अनुस्मारक और दैनिक झलक के लिए ज़रूरी';

  @override
  String get permBattery => 'बैटरी अनुकूलन';

  @override
  String get permBatteryInfo =>
      'अनुस्मारक समय पर आएँ इसके लिए ऐप को बैटरी प्रतिबंधों से छूट दें';

  @override
  String get showTagChips => 'टैग चिप दिखाएँ';

  @override
  String get showFolderChips => 'फ़ोल्डर चिप दिखाएँ';

  @override
  String videoTooBigForAi(int mb) {
    return 'वीडियो AI को भेजने के लिए बहुत बड़ा है ($mb MB)। छोटा वीडियो रिकॉर्ड करें।';
  }

  @override
  String get permCamera => 'कैमरा';

  @override
  String get permCameraInfo => 'वीडियो नोट और फ़ोटो लेने के लिए ज़रूरी';

  @override
  String get permOnboardTitle => 'शुरू करने से पहले';

  @override
  String get permOnboardInfo =>
      'नोट्स ये अनुमतियाँ तभी माँगता है जब आप संबंधित सुविधा इस्तेमाल करते हैं। आप उन्हें अभी नीचे दे सकते हैं, या बाद में सेटिंग > अनुमतियाँ में बदल सकते हैं।';

  @override
  String get permOnboardGrantAll => 'अनुमतियाँ दें';

  @override
  String get permOnboardSkip => 'अभी नहीं';

  @override
  String get newVideoNote => 'वीडियो नोट';

  @override
  String get videoLocalOnly =>
      'यह वीडियो केवल इसी डिवाइस पर रखा गया है (क्लाउड पर अपलोड नहीं होता)';

  @override
  String get videoToNote => 'वीडियो से नोट बनाएँ';

  @override
  String get videoToNoteRunning => 'वीडियो देखा जा रहा है…';

  @override
  String get permGranted => 'दी गई';

  @override
  String get permGrant => 'दें';

  @override
  String get permOpenSettings => 'सेटिंग खोलें';

  @override
  String get newHandwriting => 'हस्तलेख';

  @override
  String get newVoiceCapture => 'आवाज़ नोट';

  @override
  String get suggestTitle => 'शीर्षक सुझाएँ';

  @override
  String get noteMetaMenu => 'टैग · शीर्षक · अनुस्मारक';

  @override
  String get folder => 'फ़ोल्डर';

  @override
  String get noFolder => 'कोई फ़ोल्डर नहीं';

  @override
  String get newFolder => 'नया फ़ोल्डर';

  @override
  String get editFolder => 'फ़ोल्डर संपादित करें';

  @override
  String get deleteFolder => 'फ़ोल्डर हटाएँ';

  @override
  String deleteFolderConfirm(String name) {
    return 'फ़ोल्डर «$name» हटा दिया जाएगा। उसके अंदर के नोट नहीं हटते — बस उनका कोई फ़ोल्डर नहीं रहेगा।';
  }

  @override
  String get folderNameHint => 'फ़ोल्डर का नाम';

  @override
  String get folderIcon => 'आइकन';

  @override
  String get editFilters => 'फ़िल्टर संपादित करें';

  @override
  String get editFiltersInfo =>
      'चुनें कि होम स्क्रीन पर कौन से फ़िल्टर दिखें। फ़िल्टर छिपाने से पृष्ठ साफ़ रहता है।';

  @override
  String get select => 'चुनें';

  @override
  String get noteArchived => 'नोट संग्रहित';

  @override
  String deleteChecked(int count) {
    return 'चिह्नित हटाएँ ($count)';
  }

  @override
  String get removeItem => 'आइटम हटाएँ';

  @override
  String get copyWholeNote => 'पूरा नोट कॉपी करें';

  @override
  String get allCopied => 'पूरा नोट क्लिपबोर्ड पर कॉपी हो गया';

  @override
  String get speechPlay => 'ज़ोर से पढ़ें';

  @override
  String get speechPause => 'रोकें';

  @override
  String get speechResume => 'जारी रखें';

  @override
  String get speechStop => 'बंद करें';

  @override
  String get speechRate => 'पढ़ने की गति';

  @override
  String get speechSystemDefault => 'सिस्टम का डिफ़ॉल्ट';

  @override
  String get speechNoVoices => 'इस डिवाइस पर कोई आवाज़ स्थापित नहीं है';

  @override
  String speechVoiceLanguage(String language) {
    return '$language आवाज़';
  }

  @override
  String get speechVoiceAutoInfo =>
      'बाकी भाषाएँ अपने आप पुरुष आवाज़ में पढ़ी जाती हैं';

  @override
  String get listening => 'सुन रहा हूँ...';

  @override
  String get listenPlay => 'सुनें';

  @override
  String get listenReadingPdf => 'दस्तावेज़ पढ़ा जा रहा है...';

  @override
  String get listenConvertWithAi => 'AI से बदलें';

  @override
  String get listenMakePodcast => 'पूरा पॉडकास्ट';

  @override
  String get listenMakePodcastSummary => 'सारांश पॉडकास्ट';

  @override
  String get listenOriginalText => 'मूल टेक्स्ट';

  @override
  String get listenPodcastReady => 'पॉडकास्ट का वाचन तैयार है';

  @override
  String get listenPodcastCached => 'पहले बनाया गया — कोई टोकन खर्च नहीं';

  @override
  String get listenRegenerate => 'फिर से बनाएँ';

  @override
  String get listenNoText =>
      'इस दस्तावेज़ से कोई पढ़ने योग्य टेक्स्ट नहीं निकला। स्कैन किए गए PDF में टेक्स्ट परत नहीं होती, और प्रस्तुति में केवल चित्र हो सकते हैं।';

  @override
  String get readDocument => 'दस्तावेज़ पढ़ें (Word, PDF, स्लाइड)';

  @override
  String get readDocUnsupported => 'इस प्रकार की फ़ाइल पढ़ी नहीं जा सकती।';

  @override
  String get exportPdf => 'PDF के रूप में निर्यात करें';

  @override
  String get pdfTitleField => 'शीर्षक';

  @override
  String get pdfContentField => 'सामग्री';

  @override
  String get pdfMarkupHint =>
      'पंक्ति की शुरुआत के चिह्न स्वरूपण बन जाते हैं: [x] और [ ] चेकबॉक्स के लिए, 1. क्रमांकित सूची के लिए, - बुलेट के लिए।';

  @override
  String get pdfIncludeDate => 'तारीख शामिल करें';

  @override
  String get exportIncludeImages => 'चित्र शामिल करें';

  @override
  String get exportWord => 'Word (.docx) के रूप में साझा करें';

  @override
  String get pdfPreview => 'पूर्वावलोकन';

  @override
  String get largeAttachmentTitle => 'बड़ी फ़ाइल';

  @override
  String largeAttachmentBody(String size) {
    return 'यह फ़ाइल $size MB की है। PDF संपीड़ित नहीं किए जा सकते; यह जैसी है वैसी ही अपलोड होगी और आपके संग्रहण में गिनी जाएगी। जारी रखें?';
  }

  @override
  String get speechRateForeign => 'विदेशी भाषा की गति';

  @override
  String notesArchivedCount(int count) {
    return '$count नोट संग्रहित किए गए';
  }

  @override
  String get backgroundColor => 'पृष्ठभूमि का रंग';

  @override
  String get backgroundColorInfo => 'नोट की पृष्ठभूमि का रंग';

  @override
  String get frameColor => 'फ़्रेम';

  @override
  String get frameColorInfo =>
      'आपके चुने रंग में नोट के चारों ओर फ़्रेम बनाता है';

  @override
  String get sortBy => 'क्रमबद्ध करें';

  @override
  String get reorderNotes => 'नोट्स का क्रम बदलें';

  @override
  String get reorderModeActive => 'क्रम बदलने के लिए कार्ड खींचें';

  @override
  String get reorderDone => 'हो गया';

  @override
  String get sortManual => 'मैन्युअल (खींचा हुआ क्रम)';

  @override
  String get sortUpdated => 'हाल ही में अद्यतन';

  @override
  String get sortCreated => 'बनाने की तारीख';

  @override
  String get sortTitle => 'शीर्षक से (अ–ह)';

  @override
  String get foldersSection => 'फ़ोल्डर';

  @override
  String get tagsSection => 'टैग';

  @override
  String get expandFilters => 'फ़िल्टर फैलाएँ';

  @override
  String get collapseFilters => 'फ़िल्टर समेटें';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम की भाषा';

  @override
  String get settingsSpeech => 'ज़ोर से पढ़ना';

  @override
  String get aiAdvanced => 'उन्नत: मॉडल और API कुंजी';

  @override
  String get aiAdvancedInfo =>
      'मॉडल का चुनाव और आपकी अपनी Gemini कुंजी। ज़्यादातर लोगों को इसकी ज़रूरत नहीं होती।';

  @override
  String get openBriefing => 'झलक खोलें';

  @override
  String get syncTitle => 'सिंक';

  @override
  String get syncLimitTitle => 'स्वचालित अपलोड की सीमा';

  @override
  String get syncLimitInfo =>
      'इससे बड़े अनुलग्नक डिवाइस पर ही रहते हैं और अपलोड नहीं होते। नोट का टेक्स्ट हमेशा सिंक होता है।';

  @override
  String get syncLimitUnlimited => 'कोई सीमा नहीं';

  @override
  String get backupTitle => 'बैकअप';

  @override
  String get importBackup => 'बैकअप से पुनर्स्थापित करें (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count नोट पुनर्स्थापित हुए';
  }

  @override
  String get importBackupInvalid => 'अमान्य बैकअप फ़ाइल';

  @override
  String get aiHubTitle => 'AI';

  @override
  String get aiSummarizeInfo => 'एक संक्षिप्त सारांश बनाता है';

  @override
  String get aiAnalyzeInfo => 'मुख्य बिंदु और करने के काम सूचीबद्ध करता है';

  @override
  String get aiImproveInfo => 'शैली बदलता है: औपचारिक, छोटा या सूची';

  @override
  String get aiTranslateInfo => 'नोट को चुनी हुई भाषा में अनुवाद करता है';

  @override
  String get aiFixNoteInfo => 'वर्तनी और विराम चिह्न ठीक करता है';

  @override
  String get moveToFolder => 'फ़ोल्डर में ले जाएँ';

  @override
  String get voiceAssistantBadge => 'सहायक';

  @override
  String get assistantGenericError =>
      'कुछ गड़बड़ हो गई — क्या आप फिर कोशिश करेंगे?';

  @override
  String get quickAddTooltip => 'नया नोट — प्रकार चुनें';

  @override
  String get autoTitleSetting => 'बंद करते समय शीर्षक सुझाएँ';

  @override
  String get autoTitleSettingInfo =>
      'जब आप संपादक से बाहर निकलते हैं, बिना शीर्षक वाले नोट को उसकी सामग्री से बना छोटा शीर्षक मिल जाता है।';

  @override
  String get hubChatInfo => 'आपके नोट्स से दिए गए उत्तर';

  @override
  String get hubBriefingInfo => 'एक नज़र में आपका दिन: अनुस्मारक और हाल के नोट';

  @override
  String get hubReadInfo => 'कोई PDF या Word दस्तावेज़ सुनें';

  @override
  String get annotate => 'टिप्पणी करें';

  @override
  String get annotateDone => 'टिप्पणी समाप्त करें';

  @override
  String get newPdfNote => 'PDF जोड़ें, नोट लिखें';

  @override
  String get imageNotePreparing => 'इमेज को दस्तावेज़ में लगाया जा रहा है…';

  @override
  String get newImageNote => 'इमेज जोड़ें, नोट लें';

  @override
  String get pdfPageNoteHint => 'इस पेज का नोट…';

  @override
  String pdfPage(int page) {
    return 'पेज ${page}';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'पेज ${page} / ${total}';
  }

  @override
  String get pdfPreviousPage => 'पिछला पेज';

  @override
  String get pdfNextPage => 'अगला पेज';

  @override
  String get pdfFullScreen => 'पूरी स्क्रीन में खोलें';

  @override
  String get pdfNoDocument => 'इस नोट में अभी कोई PDF नहीं है';

  @override
  String get pdfChooseDocument => 'PDF चुनें';

  @override
  String get newSlidesNote => 'स्लाइड जोड़ें, नोट लिखें';

  @override
  String get slidesNoDocument => 'इस नोट में अभी कोई प्रेज़ेंटेशन नहीं है';

  @override
  String get slidesChooseDocument => 'प्रेज़ेंटेशन चुनें';

  @override
  String get pdfEditPages => 'पेज संपादित करें';

  @override
  String get pdfDeletePages => 'चुने हुए पेज हटाएँ';

  @override
  String get pdfAddBlankPage => 'खाली पेज जोड़ें';

  @override
  String get pdfRotatePages => 'घुमाएँ';

  @override
  String get pdfBurnInk => 'हस्तलेख को दस्तावेज़ में पक्का करें';

  @override
  String get pdfApplyChanges => 'बदलाव लागू करें';

  @override
  String get pdfCannotDeleteAllPages => 'आप सारे पेज नहीं हटा सकते';

  @override
  String get pdfPagesHint =>
      'पेज चुनने के लिए उस पर टैप करें। पेज-नोट अपने पेज के साथ चलते हैं; हटाए गए पेज का नोट छिप जाता है, पर आपके डेटा में बना रहता है।';

  @override
  String pdfEditFailed(String error) {
    return 'PDF संपादित नहीं हो सका: ${error}';
  }

  @override
  String get pdfInkBurned => 'हस्तलेख दस्तावेज़ में पक्का कर दिया गया';

  @override
  String get pdfAllPageNotes => 'सभी पेज-नोट';

  @override
  String get pdfNoPageNotes =>
      'अभी कोई पेज-नोट नहीं है। किसी पेज पर जाएँ और नीचे दिए बॉक्स में लिखें।';

  @override
  String get crop => 'काटें';

  @override
  String get cropApply => 'कटाई लागू करें';

  @override
  String get cropReset => 'चयन रीसेट करें';

  @override
  String get cropHint =>
      'क्षेत्र चुनने के लिए कोने खींचें। कटाई को पूर्ववत नहीं किया जा सकता।';

  @override
  String get cropFailed => 'चित्र काटा नहीं जा सका।';

  @override
  String get penBallpoint => 'बॉलपॉइंट पेन';

  @override
  String get penMarker => 'मार्कर';

  @override
  String get penHighlighter => 'हाइलाइटर';

  @override
  String get eraser => 'रबर';

  @override
  String get inkArrow => 'तीर';

  @override
  String get clearInk => 'टिप्पणियाँ मिटाएँ';

  @override
  String get inkTwoFingerHint =>
      'एक उँगली बनाती है · दो उँगलियाँ खिसकाती और ज़ूम करती हैं';

  @override
  String get slideOpenFailed => 'प्रस्तुति नहीं खोली जा सकी';

  @override
  String get newPhotoNote => 'फ़ोटो नोट';

  @override
  String get newScanNote => 'दस्तावेज़ स्कैन करें';

  @override
  String get scanDocument => 'दस्तावेज़ स्कैन करें';

  @override
  String get scanDocumentSubtitle =>
      'किनारे पहचानता है, पृष्ठ सीधा करता है और जोड़ देता है';

  @override
  String get scanUnsupported =>
      'इस डिवाइस पर दस्तावेज़ स्कैन करना समर्थित नहीं है';

  @override
  String scanFailed(String error) {
    return 'दस्तावेज़ स्कैन नहीं किया जा सका: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return 'नोट में $count पृष्ठ जोड़े गए';
  }

  @override
  String get scanTextTitle => 'टेक्स्ट भी पहचानें?';

  @override
  String get scanTextBody =>
      'पृष्ठों का टेक्स्ट पहचाना जाकर नोट में लिखा जाता है। चित्र जैसा है वैसा ही रहता है। हर पृष्ठ में कुछ सेकंड लगते हैं।';

  @override
  String get scanImageOnly => 'केवल चित्र';

  @override
  String get scanRecognizeText => 'टेक्स्ट पहचानें';

  @override
  String get scanRecognizing => 'टेक्स्ट पहचाना जा रहा है…';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get qrScanTitle => 'QR कोड स्कैन करें';

  @override
  String get qrScanSubtitle => 'कैमरे से या किसी फ़ोटो से पढ़ें';

  @override
  String get qrScanHint => 'कोड को फ़्रेम के भीतर रखें';

  @override
  String get qrFromPhoto => 'फ़ोटो से पढ़ें';

  @override
  String get qrNotFound => 'इस चित्र में कोई कोड नहीं मिला';

  @override
  String get qrLinkFound => 'यह कोड एक लिंक है';

  @override
  String get qrOpenLink => 'लिंक पर जाएँ';

  @override
  String get qrSaveToNote => 'नोट में सहेजें';

  @override
  String get openLink => 'लिंक खोलें';

  @override
  String get linkOpenFailed => 'लिंक नहीं खोला जा सका';

  @override
  String qrScanFailed(String error) {
    return 'कोड नहीं पढ़ा जा सका: $error';
  }

  @override
  String get qrTorch => 'टॉर्च';

  @override
  String attachmentsCount(int count) {
    return 'अनुलग्नक ($count)';
  }

  @override
  String get hideAttachments => 'छिपाएँ';

  @override
  String get showAttachments => 'दिखाएँ';

  @override
  String get videoBack10 => '10 सेकंड पीछे';

  @override
  String get videoForward10 => '10 सेकंड आगे';

  @override
  String get selectAllItems => 'सभी चुनें';

  @override
  String get showAllChips => 'सभी दिखाएँ';

  @override
  String get hideAllChips => 'सभी छिपाएँ';

  @override
  String get chipPickInfo => 'होम स्क्रीन पर कौन से फ़ोल्डर और टैग चिप दिखें?';

  @override
  String get hiddenFolder => 'छिपा फ़ोल्डर';

  @override
  String get hiddenFolderInfo =>
      'छिपा फ़ोल्डर और उसमें रखे नोट होम स्क्रीन पर नहीं दिखते। उन्हें दिखाने के लिए ⋮ मेनू से «छिपे फ़ोल्डर» चुनें और अपनी पहचान सत्यापित करें।';

  @override
  String get hiddenFoldersMenu => 'छिपे फ़ोल्डर';

  @override
  String get hiddenFolderAuthReason =>
      'छिपे फ़ोल्डर दिखाने के लिए अपनी पहचान सत्यापित करें';

  @override
  String get hiddenFoldersShown => 'छिपे फ़ोल्डर दिख रहे हैं';

  @override
  String get hiddenFoldersHiddenAgain => 'छिपे फ़ोल्डर फिर से छिप गए';

  @override
  String get makeFolderHidden => 'छिपाएँ';

  @override
  String get makeFolderVisible => 'दिखाएँ';

  @override
  String gridColumnsCount(int count) {
    return '$count स्तंभ';
  }

  @override
  String get addImageOnPageSubtitle =>
      'पृष्ठ पर बैठता है, टेक्स्ट उसके चारों ओर बहता है';

  @override
  String get addImageAsFile => 'चित्र को फ़ाइल के रूप में जोड़ें';

  @override
  String get addImageAsFileSubtitle =>
      'पृष्ठ से बाहर, अनुलग्नक पट्टी में रहता है';

  @override
  String get moveImageToAttachments => 'अनुलग्नकों में ले जाएँ';

  @override
  String get moveImageToPage => 'पृष्ठ पर रखें';

  @override
  String get attachmentCopied => 'अनुलग्नक कॉपी हो गया';

  @override
  String get pasteAttachment => 'कॉपी किया अनुलग्नक चिपकाएँ';

  @override
  String get fullscreen => 'पूरी स्क्रीन';

  @override
  String get more => 'और';

  @override
  String get undone => 'पूर्ववत हो गया';

  @override
  String get filterOthers => 'अन्य';

  @override
  String get chatSuggestion1 => 'मेरी शॉपिंग लिस्ट में क्या कमी है?';

  @override
  String get chatSuggestion2 => 'इस सप्ताह के कार्य नोट्स का सारांश दें';

  @override
  String get chatSuggestion3 => 'क्या मेरे पास कल के लिए कोई रिमाइंडर है?';

  @override
  String get aiPointsToday => 'आज के पॉइंट्स';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'आधी रात को नवीनीकृत होगा';

  @override
  String get aiChatWithNotes => 'नोट असिस्टेंट';

  @override
  String get aiChatInputHint => 'अपने नोट्स के बारे में कुछ पूछें...';

  @override
  String get aiChatLooking => 'आपके नोट्स देखे जा रहे हैं...';

  @override
  String get aiChatFullScreen => 'पूर्ण स्क्रीन';

  @override
  String get aiOnYourNotes => 'आपके नोट्स पर';

  @override
  String get aiTaskDuplicates => 'डुप्लिकेट साफ़ करें';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count डुप्लिकेट नोट हैं';
  }

  @override
  String get duplicatesTitle => 'डुप्लिकेट नोट';

  @override
  String get duplicatesHint =>
      'हर समूह का सबसे पुराना नोट रखा जाता है, बाकी कूड़ेदान में चले जाते हैं।';

  @override
  String get duplicatesKeepBadge => 'रखा जाएगा';

  @override
  String get duplicatesDeleteAll => 'डुप्लिकेट को कूड़ेदान में भेजें';

  @override
  String duplicatesDone(int count) {
    return '$count डुप्लिकेट कूड़ेदान में भेजे गए';
  }

  @override
  String get aiRecentActions => 'हाल की कार्रवाइयाँ';

  @override
  String get aiHistoryClear => 'साफ़ करें';

  @override
  String get aiHistoryQuestion => 'प्रश्न';

  @override
  String get aiHistoryNoteAction => 'नोट कार्रवाई';

  @override
  String get aiHistoryVoiceNote => 'वॉइस नोट';

  @override
  String get aiRecentOps => 'हाल ही में';

  @override
  String get aiTaskWeekSummary => 'सप्ताह का सारांश';

  @override
  String get aiTaskWeekSummaryInfo => 'पिछले 7 दिनों का एक सारांश';

  @override
  String get aiTaskTagUntagged => 'अनटैग किए गए को टैग करें';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count नोट्स टैग की प्रतीक्षा में';
  }

  @override
  String get aiTaskSuggestTitles => 'शीर्षक सुझाएं';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count नोट्स का कोई शीर्षक नहीं है';
  }

  @override
  String get sectionPinnedShort => 'पिन किया गया';

  @override
  String get sectionToday => 'आज';

  @override
  String get sectionThisWeek => 'इस सप्ताह';

  @override
  String get sectionEarlier => 'पहले';

  @override
  String sectionNoteCount(int count) {
    return '$count नोट्स';
  }

  @override
  String get emptySearchSemanticHint => 'अर्थ (Meaning) टैब आज़माएं';

  @override
  String get quickCaptureHint => 'नया नोट...';

  @override
  String get quickCaptureSave => 'सहेजें';

  @override
  String get quickAddWrite => 'लिखें';

  @override
  String get quickAddCapture => 'कैप्चर — सामग्री से एक नोट बनाता है';

  @override
  String get viewToggle => 'दृश्य';

  @override
  String get searchModeText => 'टेक्स्ट';

  @override
  String get searchModeMeaning => 'अर्थ';

  @override
  String get filterReminded => 'रिमाइंडर के साथ';

  @override
  String get filterLocked => 'लॉक किया गया';

  @override
  String get sortColor => 'रंग';

  @override
  String get sortActive => 'सबसे अधिक काम की गई';

  @override
  String get voicePreview => 'आवाज़ आज़माएँ';

  @override
  String get voicePreviewCached =>
      'नमूना एक बार बनता है, फिर संग्रहण से चलता है';

  @override
  String get reorderHint => 'कार्ड को दबाकर रखें और जहाँ चाहें खींचें';

  @override
  String get filterSheetTitle => 'फ़िल्टर';

  @override
  String get filterReset => 'रीसेट';

  @override
  String get filterSectionStatus => 'स्थिति';

  @override
  String get filterSectionFolder => 'FOLDER';

  @override
  String get filterSectionTag => 'TAG';

  @override
  String get filterSectionSort => 'SORT';

  @override
  String get filterFavoriteHint =>
      'किसी विकल्प को होम स्क्रीन पर रखने के लिए तारे पर टैप करें';

  @override
  String get filterSheetSortHint =>
      'Mga grupo ng petsa (NGAYON, NGAYONG LINGGO…) ay ipinapakita lamang kapag nag-aayos ayon sa huling inedit.';

  @override
  String get formatTitle => 'स्वरूपण';

  @override
  String get formatBold => 'मोटा';

  @override
  String get formatItalic => 'तिरछा';

  @override
  String get formatUnderline => 'रेखांकित';

  @override
  String get formatTextColor => 'टेक्स्ट का रंग';

  @override
  String get formatHighlight => 'हाइलाइट';

  @override
  String get formatInfo =>
      'स्वरूपण टेक्स्ट के भीतर चिह्नों के रूप में चलता है (जैसे **मोटा**); निर्यात और ज़ोर से पढ़ने में ये चिह्न छिपे रहते हैं।';

  @override
  String get formatMenu => 'स्वरूपण…';

  @override
  String get noteFont => 'फ़ॉन्ट';

  @override
  String get noteFontDefault => 'डिफ़ॉल्ट';

  @override
  String get noteFontSerif => 'किताबी (सेरिफ़)';

  @override
  String get noteFontMono => 'टाइपराइटर';

  @override
  String get noteTextSize => 'टेक्स्ट का आकार';

  @override
  String get formatClear => 'स्वरूपण हटाएँ';

  @override
  String get noteTextOpacity => 'अपारदर्शिता';

  @override
  String get assistantVoiceSetting => 'सहायक उत्तर बोलकर सुनाए';

  @override
  String get assistantVoiceSettingInfo =>
      'आवाज़ सहायक अपना उत्तर ज़ोर से पढ़ता है (केवल फ़ोन पर)।';

  @override
  String get assistantMute => 'आवाज़ बंद करें';

  @override
  String get assistantUnmute => 'आवाज़ चालू करें';

  @override
  String get assistantMakeNote => 'फिर भी नोट बना दें';

  @override
  String get assistantNoteCreated => 'नोट बन गया';

  @override
  String get noteNotFound => 'नोट नहीं मिला। शायद इसे हटा दिया गया है।';

  @override
  String get back => 'वापस';

  @override
  String get addTextBlock => 'टेक्स्ट जोड़ें';

  @override
  String get attachNoteContent => 'नोट की सामग्री';

  @override
  String get noteBackgroundImage => 'पृष्ठभूमि चित्र';

  @override
  String get chooseBackgroundImage => 'चित्र चुनें';

  @override
  String get changeBackgroundImage => 'चित्र बदलें';

  @override
  String get removeBackgroundImage => 'पृष्ठभूमि हटाएँ';

  @override
  String get dashboardBackground => 'होम स्क्रीन की पृष्ठभूमि';

  @override
  String get dashboardBackgroundInfo =>
      'नोट ग्रिड के पीछे दिखने वाला चित्र (केवल इस डिवाइस पर)।';

  @override
  String get aiProvider => 'AI प्रदाता';

  @override
  String get aiProviderInfo =>
      'वह प्रदाता चुनें जिसकी आपकी कुंजी है। हर प्रदाता की कुंजी अलग रखी जाती है, इसलिए वापस लौटने पर उसे दोबारा टाइप नहीं करना पड़ता।';

  @override
  String get apiKeyFieldLabel => 'API कुंजी';

  @override
  String get getApiKey => 'कुंजी कहाँ से मिलेगी?';

  @override
  String get recommendedModel => 'अनुशंसित';

  @override
  String get freeTierBadge => 'मुफ़्त श्रेणी उपलब्ध है';

  @override
  String get continueWithoutAccount => 'बिना खाते के जारी रखें';

  @override
  String get localAccountInfo =>
      'आपके नोट केवल इसी डिवाइस पर रहते हैं: उन्हें कहीं और नहीं खोला जा सकता, ऐप हटाने पर वे चले जाते हैं, और अंतर्निहित AI बंद रहता है। आप कभी भी Google खाता जोड़ सकते हैं — आपके नोट साथ चले आएँगे।';

  @override
  String get localAccountBadge => 'स्थानीय खाता';

  @override
  String get linkGoogleAccount => 'Google खाता जोड़ें';

  @override
  String get accountLinked =>
      'आपका Google खाता जुड़ गया। अब आपके नोट का बैकअप हो रहा है।';

  @override
  String scanReviewPage(int current, int total) {
    return 'पेज ${current} / ${total}';
  }

  @override
  String get scanRotatePage => 'पेज घुमाएँ';

  @override
  String get scanDeletePage => 'पेज हटाएँ';

  @override
  String get scanLastPage => 'आख़िरी पेज नहीं हटाया जा सकता';

  @override
  String get scanDiscardTitle => 'स्कैन किए पेज छोड़ दें?';

  @override
  String get scanDiscardConfirm => 'छोड़ें';

  @override
  String get scanAdjustCorners => 'कोने ठीक करें';

  @override
  String get scanFilterOriginal => 'मूल';

  @override
  String get scanFilterAuto => 'बेहतर बनाएँ';

  @override
  String get scanFilterGray => 'श्वेत-श्याम रंगत';

  @override
  String get scanFilterBw => 'काला-सफ़ेद';

  @override
  String get scanApplyAll => 'सब पर लागू करें';

  @override
  String get scanPageFailed => 'पेज दिखाया नहीं जा सका';

  @override
  String get scanCropHint =>
      'टेढ़े पेज को "कोने ठीक करें" से सुधारें';

  @override
  String get scanAddAsPdf => 'PDF के रूप में जोड़ें';

  @override
  String get scanAddAsImages => 'छवियों के रूप में जोड़ें';

  @override
  String get scanBuildingPdf => 'PDF तैयार हो रही है…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'पाठ पहचाना जा रहा है… ${done}/${total}';
  }

  @override
  String get scanAutoDetect => 'किनारे अपने आप पहचानें';

  @override
  String get scanReset => 'रीसेट करें';

  @override
  String get scanDetecting => 'किनारे खोजे जा रहे हैं…';

  @override
  String get scanAutoFound =>
      'किनारे अपने आप मिल गए; ज़रूरत हो तो हैंडल से ठीक करें';

  @override
  String get scanDragHint => 'कोनों को काग़ज़ के किनारों तक खींचें';

  @override
  String get scanApplyCorners => 'सीधा करके लागू करें';

  @override
  String get scanWorking => 'सीधा किया जा रहा है…';

  @override
  String get scanPdfAdded => 'स्कैन नोट में PDF अनुलग्नक के रूप में जुड़ गया';

  @override
  String get premiumTitle => 'प्रीमियम';

  @override
  String premiumStatusActive(String date) {
    return 'प्रीमियम चालू — ${date} तक';
  }

  @override
  String get premiumStatusFree => 'आप मुफ़्त संस्करण इस्तेमाल कर रहे हैं';

  @override
  String get premiumPerksTitle => 'प्रीमियम से क्या बदलता है?';

  @override
  String get premiumPerkAi => 'रोज़ के AI अंक';

  @override
  String get premiumPerkAttach => 'अनुलग्नक का आकार';

  @override
  String get premiumPerkStorage => 'क्लाउड संग्रहण';

  @override
  String get premiumPerkAuto => 'अपने आप बनने वाली रोज़ की सामग्री';

  @override
  String get premiumPerkAutoBody =>
      'रोज़ाना का ब्रीफ़िंग और सुझाव हर दिन अपने आप तैयार होते हैं; मुफ़्त संस्करण में ये केवल माँगने पर चलते हैं।';

  @override
  String get premiumHowTitle => 'इसे कैसे लें?';

  @override
  String get premiumHowBody =>
      'प्रीमियम जल्द ही Play Store पर उपलब्ध होगा। फ़िलहाल हम शुरुआती पहुँच में हैं।';

  @override
  String get premiumByokHint =>
      'अगर आप अपनी Gemini API कुंजी डालते हैं, तो AI सुविधाएँ बिना कोटा के चलती हैं — प्रीमियम से अलग (सेटिंग → AI)।';

  @override
  String get premiumDiscoverTitle => 'वे सुविधाएँ जो शायद आपसे छूट गईं';

  @override
  String get discoverScanBody =>
      'स्कैन किए पेज सीधे और साफ़ किए जाते हैं और एक टैप में खोजे जा सकने वाली PDF बन जाते हैं — पाठ की परत डिवाइस पर ही, मुफ़्त बनती है।';

  @override
  String get discoverSemanticBody =>
      'खोज बॉक्स का "स्मार्ट" टैब शब्दों से नहीं, अर्थ से खोजता है: "उड़ान का समय" लिखिए और आपका यात्रा नोट सामने आ जाएगा।';

  @override
  String get discoverAssistantBody =>
      'होम स्क्रीन का माइक आपकी बात को अपने आप नोट, सूची और अनुस्मारक में बदल देता है — बस कहिए "कल सुबह 9 बजे दंत चिकित्सक"।';

  @override
  String get discoverLockBody =>
      'आप नोट को फ़िंगरप्रिंट/चेहरे से लॉक कर सकते हैं: उसकी सामग्री खोज, विजेट या AI में कभी नहीं जाती।';

  @override
  String get discoverHiddenBody =>
      'छिपे फ़ोल्डर के नोट होम स्क्रीन या खोज में कभी नहीं दिखते; फ़ोल्डर दिखाने के लिए प्रमाणीकरण चाहिए।';

  @override
  String get discoverExportBody =>
      'हर नोट को छवियों सहित PDF या Word में निर्यात किया जा सकता है (साझा मेन्यू में)।';

  @override
  String get guestSignInUnavailable =>
      'Google के बिना साइन-इन अभी बंद है: Firebase कंसोल में अनाम साइन-इन चालू नहीं है. Google से साइन इन करें या व्यवस्थापक के चालू करने के बाद फिर कोशिश करें.';

  @override
  String get googleSignInUnavailable =>
      'Google से साइन-इन अभी बंद है: Firebase कंसोल में Google प्रदाता चालू नहीं है.';

  @override
  String get signInNetworkError =>
      'इंटरनेट से कनेक्ट नहीं हो सका. अपना कनेक्शन जाँचकर फिर कोशिश करें.';

  @override
  String get signInCanceled => 'साइन-इन रद्द किया गया.';

  @override
  String get cardRichPreview => 'कार्ड पर फ़ॉर्मैट किया गया टेक्स्ट';

  @override
  String get cardRichPreviewInfo =>
      'आपके नोट्स के रंग, हाइलाइट, बोल्ड और अंडरलाइन होम स्क्रीन के कार्ड पर भी दिखते हैं. बंद होने पर कार्ड सादा टेक्स्ट दिखाते हैं.';

  @override
  String get fontSizeSmall => 'छोटा';

  @override
  String get fontSizeMedium => 'मध्यम';

  @override
  String get fontSizeLarge => 'बड़ा';

  @override
  String get fontSizeXLarge => 'बहुत बड़ा';

  @override
  String get appFontSetting => 'फ़ॉन्ट';

  @override
  String get appFontInfo =>
      'पूरे ऐप में इस्तेमाल होने वाला फ़ॉन्ट. नोट का अपना फ़ॉन्ट इस पर हावी रहता है. सभी फ़ॉन्ट ऐप के साथ आते हैं — इंटरनेट की ज़रूरत नहीं.';

  @override
  String get fontGroupSans => 'सैन्स';

  @override
  String get fontGroupSerif => 'सेरिफ़';

  @override
  String get fontGroupMono => 'मोनोस्पेस';

  @override
  String get fontGroupHand => 'हस्तलेख';

  @override
  String get appFontDefaultSuffix => 'डिफ़ॉल्ट';

  @override
  String get pdfSelectOcrRunning => 'पाठ पहचाना जा रहा है…';

  @override
  String get pdfSelectOcrNone => 'इस पेज पर कोई पाठ नहीं मिला';

  @override
  String pdfSelectCopied(int n) {
    return '${n} अक्षर कॉपी हुए';
  }

  @override
  String get bubbleAdd => 'नोट बुलबुला रखें';

  @override
  String get bubbleAddDone => 'बुलबुले जोड़ना पूरा';

  @override
  String get bubbleCollapse => 'बुलबुला समेटें';

  @override
  String get bubbleHint => 'अपना नोट यहाँ लिखें…';

  @override
  String get bubbleTapToPlace => 'पेज पर उस जगह टैप करें जहाँ बुलबुला चाहिए';

  @override
  String get aiModelPodcast => 'पॉडकास्ट वाचन';

  @override
  String get listenAiVoice => 'AI आवाज़ से सुनें';

  @override
  String get listenAiVoiceInfo =>
      'डिवाइस की आवाज़ के बजाय Gemini पढ़ता है: ज़्यादा स्वाभाविक, पर हर अनुच्छेद पर एक मॉडल कॉल लगती है।';

  @override
  String listenAiVoiceFailed(String error) {
    return 'AI वाचन विफल (${error})। डिवाइस की आवाज़ से पढ़ा जा रहा है।';
  }

  @override
  String get ttsSectionTitle => 'वाचन';

  @override
  String get ttsEngineDevice => 'डिवाइस की आवाज़';

  @override
  String get ttsEngineAi => 'AI';

  @override
  String get ttsEngineDeviceInfo =>
      'डिवाइस की अंतर्निर्मित आवाज़ पढ़ती है: मुफ़्त, ऑफ़लाइन और बिना लंबाई की सीमा के।';

  @override
  String get ttsEngineAiInfo =>
      'Gemini का वाक् मॉडल पढ़ता है: काफ़ी ज़्यादा स्वाभाविक, पर हर अनुच्छेद एक मॉडल कॉल है और आपकी अपनी Gemini कुंजी चाहिए।';

  @override
  String get ttsEngineAiUnavailable =>
      'AI आवाज़ के लिए आपकी अपनी Gemini कुंजी चाहिए। तब तक पढ़ना डिवाइस की आवाज़ से होगा।';

  @override
  String get ttsModel => 'वाक् मॉडल';

  @override
  String get ttsVoice => 'AI आवाज़';

  @override
  String get shareAsNote => 'नोट के रूप में साझा करें';

  @override
  String get shareAsNoteInfo =>
      'नोट को अनुलग्नकों, पेज-नोट, चित्रों और बुलबुलों समेत भेजता है; सामने वाला उसे Not ऐप में बिलकुल वैसा ही खोलता है।';

  @override
  String get shareAsNotePreparing => 'नोट पैकेज तैयार हो रहा है…';

  @override
  String get shareAsText => 'सादे टेक्स्ट के रूप में';

  @override
  String get shareAsTextInfo =>
      'नोट का टेक्स्ट और पेज नोट्स किसी भी ऐप को भेजता है।';

  @override
  String get shareAsTextEmpty =>
      'इस नोट में साझा करने लायक कोई टेक्स्ट नहीं है।';

  @override
  String get sharePdfWithBubbles => 'बबल वाली PDF के रूप में';

  @override
  String get sharePdfWithBubblesInfo =>
      'बबल, हाइलाइट और ड्रॉइंग PDF के अंदर छाप दिए जाते हैं; कोई भी खोल सकता है और Not में यह संपादन योग्य खुलता है।';

  @override
  String get sharePdfWithBubblesNone =>
      'इस नोट में बबल या ड्रॉइंग वाली कोई PDF नहीं है।';

  @override
  String get sharePdfWithBubblesPreparing => 'बबल वाली PDF तैयार हो रही है…';

  @override
  String get sharePdfWithBubblesSuffix => ' (बबल सहित)';

  @override
  String get bubbleStar => 'तारांकित करें';

  @override
  String get bubbleEdit => 'बुलबुला संपादित करें';

  @override
  String get bubbleStarredOnly => 'केवल तारांकित';

  @override
  String get bubbleSearchHint => 'बुलबुलों में खोजें…';

  @override
  String get bubblesOverviewTitle => 'बुलबुले';

  @override
  String get bubblesEmpty =>
      'अभी कोई बुलबुला नहीं है। दस्तावेज़ में पाठ चुनकर उसे हाइलाइट करें, या पेज पर एक बुलबुला रखें।';

  @override
  String get bubblesNoMatch => 'आपकी खोज से कोई बुलबुला मेल नहीं खाता।';

  @override
  String get bubbleNoText => '(खाली बुलबुला)';

  @override
  String get pdfHighlight => 'हाइलाइट करें';

  @override
  String get pdfHighlightWithNote => 'हाइलाइट + नोट';

  @override
  String get pageNotesShow => 'पेज-नोट दिखाएँ';

  @override
  String get pageNotesHide => 'पेज-नोट छिपाएँ';

  @override
  String get bubbleSave => 'सहेजें';

  @override
  String get bubbleTitleHint => 'शीर्षक';

  @override
  String get bubbleUrgent => 'अत्यावश्यक (चमकता है)';

  @override
  String get captureModeQuestion => 'नोट किस रूप में खुले?';

  @override
  String get captureModeBubbles => 'बुलबुले';

  @override
  String get captureModeBubblesInfo =>
      'सामग्री दस्तावेज़ पेज बन जाती है: बुलबुले, हाइलाइट और कलम।';

  @override
  String get captureModeClassic => 'पारंपरिक';

  @override
  String get captureModeClassicInfo =>
      'सादा पाठ नोट; सामग्री अनुलग्नक के रूप में जुड़ती है।';

  @override
  String get captureModeNew => 'नया';

  @override
  String get imagePrepareTitle => 'छवियाँ ठीक करें';

  @override
  String get imagePrepareDone => 'आगे बढ़ें';

  @override
  String get imageRotateLeft => 'बाएँ घुमाएँ';

  @override
  String get imageRotateRight => 'दाएँ घुमाएँ';

  @override
  String get videoFrameFailed =>
      'वीडियो से फ़्रेम नहीं लिया जा सका; पारंपरिक नोट खोला जा रहा है।';

  @override
  String get bubbleArrowHide => 'तीर छिपाएँ';

  @override
  String get bubbleArrowShow => 'तीर दिखाएँ';

  @override
  String get speechPitch => 'आवाज़ की ऊँचाई';

  @override
  String get speechVoicePickerTitle => 'आवाज़ का चुनाव';

  @override
  String get formatRemove => 'हटाएं';

  @override
  String get exportTitle => 'निर्यात करें';

  @override
  String get exportNotesOption => 'नोट का टेक्स्ट (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'नोट का टेक्स्ट और चित्र; बबल शामिल नहीं हैं।';

  @override
  String get captureNoteTitle => 'नोट का शीर्षक (वैकल्पिक)';

  @override
  String get captureNoteTitleHint => 'नए दस्तावेज़ को भी यही नाम मिलेगा';

  @override
  String get imageOcrTitle => 'चित्र में टेक्स्ट पहचानें';

  @override
  String get imageOcrNone => 'इस चित्र में कोई टेक्स्ट नहीं मिला।';

  @override
  String imageOcrHint(int count) {
    return '$count पंक्तियाँ पहचानी गईं · चुनने के लिए टैप करें';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count पंक्तियाँ चुनी गईं';
  }

  @override
  String get imageOcrShort => 'टेक्स्ट पहचानें';

  @override
  String get imageOcrWorking => 'टेक्स्ट पहचाना जा रहा है…';

  @override
  String get imageOcrSelectHint => 'टैप: शब्द · दबाकर खींचें: अक्षर दर अक्षर';

  @override
  String get imageOcrInsert => 'नोट में जोड़ें';

  @override
  String get imageOcrZoomIn => 'ज़ूम इन';

  @override
  String get imageOcrZoomOut => 'ज़ूम आउट';

  @override
  String get selectImages => 'चित्र चुनें';

  @override
  String get exportImages => 'चित्र';

  @override
  String get exportImagesInfo =>
      'बाएँ या दाएँ संरेखित सँकरे चित्रों के बगल से टेक्स्ट बहता है; केंद्रित चित्र पूरी चौड़ाई लेते हैं।';

  @override
  String get exportAlignLeft => 'बाएँ';

  @override
  String get exportAlignCenter => 'मध्य';

  @override
  String get exportAlignRight => 'दाएँ';

  @override
  String get exportImageWidth => 'चौड़ाई';

  @override
  String get exportImageLine => 'स्थान';

  @override
  String get aiModelSearch => 'मॉडल खोजें';

  @override
  String get aiModelOthers => 'अन्य मॉडल';

  @override
  String get aiModelNoMatch => 'कोई मेल खाता मॉडल नहीं।';

  @override
  String get aiModelAutoInfo => 'ऐप क्रम से सबसे उपयुक्त मॉडल आज़माता है।';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count अक्षर चुने गए';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count चित्र चुने गए';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count अनुलग्नक';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count पंक्तियाँ';
  }

  @override
  String get aiModelShowAll => 'सभी दिखाएँ';

  @override
  String get aiModelShowAllInfo =>
      'ऐप जिन मॉडलों का उपयोग नहीं करता, वे भी दिखते हैं।';

  @override
  String get rotateFailed => 'छवि घुमाई नहीं जा सकी।';

  @override
  String get dashboardBackgroundPick => 'पृष्ठभूमि छवि चुनें';

  @override
  String get dashboardBackgroundChange => 'पृष्ठभूमि छवि बदलें';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'ऑडियो तैयार हो रहा है: ${done}/${total} हिस्से';
  }

  @override
  String get podcastExportAudio => 'ऑडियो फ़ाइल के रूप में निर्यात करें';

  @override
  String get podcastExportAudioCost =>
      'पूरी स्क्रिप्ट AI आवाज़ से दोबारा बनाई जाती है और एक ही WAV फ़ाइल में सहेजी जाती है। इसमें आपका Gemini कोटा लगता है और लंबे पाठ पर कुछ मिनट लग सकते हैं।';

  @override
  String get podcastShareText => 'स्क्रिप्ट साझा करें';

  @override
  String get podcastSaveAsNote => 'नए नोट के रूप में सहेजें';

  @override
  String get podcastSavedAsNote => 'पॉडकास्ट स्क्रिप्ट नोट के रूप में सहेज दी गई।';

  @override
  String get listenPreparingVoice => 'ऑडियो तैयार हो रहा है…';

  @override
  String get appearancePreviewTitle => 'नमूना पाठ';

  @override
  String get appearancePreviewNoteTitle => 'नमूना नोट शीर्षक';

  @override
  String get appearancePreviewBody =>
      'आपके नोट ऐसे दिखेंगे। पाठ में **मोटा**, ~रेखांकित~ और ==2:हाइलाइट किया== ऐसा दिखता है।';

  @override
  String get appearancePreviewItem => 'सूची की एक पंक्ति ऐसी दिखती है';

  @override
  String get convertToText => 'पाठ में बदलें';

  @override
  String get convertToList => 'सूची में बदलें';

  @override
  String get convertedToText => 'सूची सादे पाठ में बदल दी गई।';

  @override
  String get convertedToList => 'पाठ सूची में बदल दिया गया।';

  @override
  String get convertToListEmpty => 'सूची में बदलने के लिए कोई पंक्ति नहीं है।';

  @override
  String get listTwoColumns => 'दो स्तंभ';

  @override
  String get listOneColumn => 'एक स्तंभ';

  @override
  String get sortItems => 'पंक्तियाँ क्रम में लगाएँ';

  @override
  String get sortStarredFirst => 'पहले तारांकित';

  @override
  String get sortUncheckedFirst => 'पूरी हुई सबसे बाद में';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'छवियों को अनुलग्नकों में ले जाएँ';

  @override
  String imagesToAttachmentsDone(int count) {
    return '${count} छवियाँ अनुलग्नकों में ले जाई गईं।';
  }

  @override
  String get imageOcrShowRecognized => 'पहचाना गया पाठ हाइलाइट करें';

  @override
  String get imageOcrHideRecognized => 'हाइलाइट छिपाएँ';

  @override
  String get bubblePlainMode => 'खुला पाठ बॉक्स';

  @override
  String get bubblePlainModeOn => 'खुला पाठ बॉक्स चालू है';

  @override
  String get bubblePlainTapToPlace => 'जहाँ पाठ चाहिए वहाँ टैप करें';

  @override
  String get bubblePlainHint => 'लिखने के लिए टैप करें';

  @override
  String get noteSearchTitle => 'नोट में खोजें';

  @override
  String get noteSearchHint => 'इस नोट में खोजें…';

  @override
  String get noteSearchEmptyHint =>
      'नोट का पाठ, पंक्तियाँ और पेज-नोट तुरंत खोजता है। छवि और PDF अनुलग्नकों के भीतर देखने के लिए नीचे स्कैन शुरू करें।';

  @override
  String get noteSearchNoHit => 'कोई मेल नहीं मिला।';

  @override
  String get noteSearchScanAttachments => 'अनुलग्नक स्कैन करें';

  @override
  String get noteSearchAskAi => 'AI से पूछें';

  @override
  String get noteTitleLabel => 'शीर्षक';

  @override
  String get noteBodyLabel => 'नोट का पाठ';

  @override
  String get itemLabel => 'पंक्ति';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '${count} अनुलग्नक स्कैन किए जा सकते हैं (छवि/PDF)।';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return '${count} अनुलग्नकों के भीतर भी खोजा जा रहा है।';
  }

  @override
  String pageLabel(int page) {
    return 'पेज ${page}';
  }

  @override
  String get archiveNotebook => 'संग्रह कॉपी';

  @override
  String get archiveNotebookInfo =>
      'अपने पेजों वाली एक कॉपी, जिसमें ज़रूरी दस्तावेज़ों और छवियों की नक़लें रखी जाती हैं।';

  @override
  String get archivePageImages => 'छवियाँ';

  @override
  String get archivePageVideos => 'वीडियो';

  @override
  String get archivePageDocuments => 'दस्तावेज़';

  @override
  String get archivePageTexts => 'पाठ';

  @override
  String get archiveNewPage => 'नया पेज';

  @override
  String get archivePageName => 'पेज का नाम (जैसे बिल)';

  @override
  String get archivePageEmpty => 'यह पेज खाली है।';

  @override
  String get archiveSearchHint => 'कॉपी में खोजें…';

  @override
  String get archiveAddText => 'पाठ जोड़ें';

  @override
  String get archiveAddFile => 'फ़ाइल जोड़ें';

  @override
  String get archiveCopyHere => 'संग्रह कॉपी में नक़ल करें';

  @override
  String get archiveNoNotebook =>
      'अभी कोई संग्रह कॉपी नहीं है। पहले एक बनाएँ।';

  @override
  String get archiveNothingToCopy => 'इस नोट में नक़ल करने योग्य कोई अनुलग्नक नहीं है।';

  @override
  String archiveDeleteEntry(String name) {
    return 'क्या "${name}" को कॉपी से हटाना है? यह नक़ल हमेशा के लिए चली जाएगी।';
  }

  @override
  String archiveCopied(int count) {
    return '${count} फ़ाइलें संग्रह कॉपी में नक़ल हो गईं।';
  }

  @override
  String get archiveCaptureTitle => 'छवि से लें';

  @override
  String get archiveCapturePage => 'पेज';

  @override
  String get archiveCapturePageInfo =>
      'AI का सुझाया प्रकार। खाली छोड़ने पर यह "पाठ" पेज में जाएगा।';

  @override
  String get archiveCaptureText => 'पहचाना गया पाठ';

  @override
  String get attachmentTagInsert => 'पाठ में डालें';

  @override
  String get attachmentTagInserted => 'अनुलग्नक का चिह्न डाल दिया गया।';

  @override
  String get attachmentTagPreview => 'अनुलग्नक देखें';

  @override
  String get attachmentTagEdit => 'अनुलग्नक संपादित करें';

  @override
  String archiveCardSummary(int files, int texts) {
    return '${files} फ़ाइलें · ${texts} पाठ';
  }

  @override
  String get archiveEntryTitle => 'शीर्षक';

  @override
  String get archiveLinkedFile => 'जुड़ी हुई फ़ाइल';

  @override
  String get archiveNoLink => 'कोई जुड़ी फ़ाइल नहीं';

  @override
  String get attachmentTagEmbed => 'चुने हुए पाठ में अनुलग्नक जोड़ें';

  @override
  String get attachmentTagNoAttachment =>
      'पहले नोट में एक फ़ाइल जोड़ें, फिर आप उसे पाठ में लगा सकेंगे।';

  @override
  String get bubbleModeBubble => 'बुलबुला';

  @override
  String get attachmentTagEmbedInfo =>
      'आपके चुने पाठ से जुड़ता है, और कुछ न चुना हो तो कर्सर की जगह पर';

  @override
  String get attachmentTagPickText =>
      'अब वह पाठ चुनें जिससे जोड़ना है, फिर "यहाँ जोड़ें" पर टैप करें।';

  @override
  String get attachmentTagLinkHere => 'यहाँ जोड़ें';

  @override
  String attachmentTagPendingBanner(String name) {
    return '${name} जोड़ा जाएगा — पाठ चुनें';
  }

  @override
  String get docNameNotesSuffix => 'नोट';

  @override
  String get docNamePhoto => 'फ़ोटो के नोट';

  @override
  String get docNameScan => 'स्कैन के नोट';

  @override
  String get docNameImage => 'छवि के नोट';

  @override
  String get docNameVideo => 'वीडियो के नोट';

  @override
  String get folderManage => 'फ़ोल्डर प्रबंधित करें';

  @override
  String get folderEmpty => 'यह फ़ोल्डर खाली है';

  @override
  String get folderEmptyHint =>
      'नीचे + से नोट जोड़ें, या किसी नोट को संपादित करते समय यहाँ ले आएँ।';

  @override
  String get brainstormTitle => 'AI के साथ विचार-मंथन';

  @override
  String get brainstormRowInfo =>
      'पहले AI एक रूपरेखा बनाता है, फिर आप दोनों मिलकर उसे बढ़ाते हैं';

  @override
  String get brainstormIntro =>
      'ऊपर के किसी शीर्षक पर टैप करें या बस लिखना शुरू करें — चलिए साथ में सोचते हैं।';

  @override
  String get brainstormOutlineTitle => 'रूपरेखा';

  @override
  String get brainstormInputHint => 'कोई विचार लिखें या सवाल पूछें…';

  @override
  String get brainstormAddIdea => 'नोट में जोड़ें';

  @override
  String get brainstormAdded => 'नोट में जोड़ दिया गया';

  @override
  String get folderShared => 'यह फ़ोल्डर किसी मित्र के साथ साझा है';

  @override
  String get friendsTitle => 'संपर्क';

  @override
  String get friendsAdd => 'मित्र जोड़ें';

  @override
  String get friendsEmpty =>
      'अभी कोई नहीं है। ईमेल से मित्र जोड़ें ताकि उनके साथ फ़ोल्डर साझा कर सकें।';

  @override
  String get friendsRequestsTitle => 'अनुरोध';

  @override
  String get friendsListTitle => 'मेरे मित्र';

  @override
  String get friendsAddEmailHint => 'friend@email.com';

  @override
  String get friendsSendRequest => 'अनुरोध भेजें';

  @override
  String get friendsRequestSent => 'अनुरोध भेज दिया गया';

  @override
  String get friendsNotFound =>
      'इस ईमेल से कोई उपयोगकर्ता पंजीकृत नहीं है। उन्हें कम से कम एक बार Google खाते से ऐप खोलना होगा।';

  @override
  String get friendsSelf => 'आप ख़ुद को मित्र नहीं बना सकते';

  @override
  String get friendsAlready => 'आप पहले से मित्र हैं';

  @override
  String get friendsDecline => 'अस्वीकार करें';

  @override
  String get friendsAccept => 'स्वीकार करें';

  @override
  String get friendsRemove => 'हटाएँ';

  @override
  String get friendsRemoveConfirmTitle => 'मित्र हटाएँ';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'क्या ${name} को मित्रों से हटाना है? आपने जो फ़ोल्डर साझा किए थे, वे अब नहीं दिखेंगे।';
  }

  @override
  String get friendsNeedsAccount =>
      'संपर्क और फ़ोल्डर साझा करने के लिए जुड़ा हुआ Google खाता ज़रूरी है।';

  @override
  String get friendsSearchHint => 'नाम या ईमेल से खोजें';

  @override
  String get friendsSearchTab => 'खोज';

  @override
  String get friendsSearchEmailTab => 'ईमेल से';

  @override
  String get friendsSearchEmpty => 'कोई परिणाम नहीं';

  @override
  String get friendsSearchTooShort => 'खोजने के लिए कम से कम 2 अक्षर लिखें';

  @override
  String get friendsSearchAdd => 'जोड़ें';

  @override
  String get folderShare => 'साझा करें';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count} लोगों के साथ साझा',
      one: '1 व्यक्ति के साथ साझा',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '"${name}" साझा करें';
  }

  @override
  String get folderShareInfo =>
      'आपके चुने मित्र को निमंत्रण जाता है; स्वीकार करते ही उन्हें फ़ोल्डर दिखने लगता है। अनुमति (पढ़ना / लिखना / दोनों) आप तय करते हैं।';

  @override
  String get friendsRowInfo => 'मित्र जोड़ें, उनके साथ फ़ोल्डर साझा करें';

  @override
  String get accountRecoverConflictTitle =>
      'इस डिवाइस पर बिना सहेजे नोट हैं';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'यह Google खाता पहले से किसी दूसरे सत्र से जुड़ा है; उस पर जाने से इस डिवाइस के ${count} नोट छिप जाएँगे (वे मिटते नहीं, बस यहाँ से पहुँच में नहीं रहेंगे)। फिर भी जारी रखें?';
  }

  @override
  String get accountRecoverConflictProceed => 'फिर भी बदलें';
  @override
  String get folderRoleRead => 'पढ़ना';

  @override
  String get folderRoleWrite => 'लिखना';

  @override
  String get folderRoleBoth => 'पढ़ना + लिखना';

  @override
  String get folderInvitePending => 'निमंत्रण भेजा गया, उत्तर की प्रतीक्षा है';

  @override
  String get folderWriteOnlyTitle => 'आपके पास केवल लिखने की अनुमति है';

  @override
  String get folderWriteOnlyHint => 'आप इस फ़ोल्डर में नए नोट डाल सकते हैं, पर भीतर के नोट नहीं देख सकते।';

  @override
  String get folderChatTitle => 'बातचीत';

  @override
  String get folderChatHint => 'संदेश लिखें…';

  @override
  String get folderChatSend => 'भेजें';

  @override
  String get folderChatEmptyTitle => 'अभी कोई संदेश नहीं';

  @override
  String get folderChatEmptyHint => 'जिनके साथ यह फ़ोल्डर साझा किया है, उनसे यहाँ बात करें।';

  @override
  String get folderInviteTitle => 'फ़ोल्डर का निमंत्रण';

  @override
  String folderInviteBody(Object name) {
    return '"${name}" फ़ोल्डर आपके साथ साझा किया गया है।';
  }

  @override
  String get folderInviteAccepted => 'फ़ोल्डर जोड़ दिया गया';

  @override
  String get folderInviteDeclined => 'निमंत्रण अस्वीकार किया गया';

  @override
  String friendRequestBanner(Object name) {
    return '${name} ने आपको मित्रता का अनुरोध भेजा है';
  }

  @override
  String get friendRequestAccepted => 'मित्र जोड़ लिया गया';

  @override
  String get sendNoteAction => 'मित्र को भेजें';

  @override
  String get sendNoteTitle => 'नोट किसी मित्र को भेजें';

  @override
  String get sendNoteInfo => 'नोट की एक नक़ल उस व्यक्ति के "आए हुए नोट" बॉक्स में पहुँचती है। अनुलग्नक (छवियाँ, दस्तावेज़, ऑडियो) नहीं भेजे जाते।';

  @override
  String sendNoteSent(Object name) {
    return 'नोट ${name} को भेज दिया गया';
  }

  @override
  String get inboxTitle => 'आए हुए नोट';

  @override
  String get inboxEmpty => 'कोई आया हुआ नोट नहीं';

  @override
  String get inboxEmptyHint => 'आपके मित्र जो नोट भेजते हैं, वे यहाँ जमा होते हैं।';

  @override
  String inboxFrom(Object name) {
    return 'भेजने वाला: ${name}';
  }

  @override
  String get inboxAccept => 'मेरे नोट में जोड़ें';

  @override
  String get inboxAccepted => 'नोट आपके नोट में जुड़ गया';

  @override
  String get folderShelfExpand => 'फ़ोल्डर फैलाएँ';

  @override
  String get folderShelfCollapse => 'फ़ोल्डर समेटें';

  @override
  String get accountSheetLocalInfo => 'आपके नोट केवल इसी डिवाइस पर हैं। बैकअप लेने और मित्र जोड़ने के लिए Google खाता जोड़ें।';

  @override
  String get accountSettings => 'खाता सेटिंग';
}
