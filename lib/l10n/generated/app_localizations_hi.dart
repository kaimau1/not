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
  String get attachmentUploading => 'अपलोड हो रहा है...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

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
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
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
  String get aiModelDocument => 'पॉडकास्ट और दस्तावेज़ से बातचीत';

  @override
  String get aiModelTranslate => 'अनुवाद';

  @override
  String get aiModelVoice => 'आवाज़ नोट';

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
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get pdfPageNoteHint => 'Bu sayfanın notu…';

  @override
  String pdfPage(int page) {
    return 'Sayfa $page';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'Sayfa $page / $total';
  }

  @override
  String get pdfPreviousPage => 'Önceki sayfa';

  @override
  String get pdfNextPage => 'Sonraki sayfa';

  @override
  String get pdfFullScreen => 'Tam ekran aç';

  @override
  String get pdfNoDocument => 'Bu notta henüz PDF yok';

  @override
  String get pdfChooseDocument => 'PDF seç';

  @override
  String get newSlidesNote => 'Sunum ekle not al';

  @override
  String get slidesNoDocument => 'Bu notta henüz sunum yok';

  @override
  String get slidesChooseDocument => 'Sunum seç';

  @override
  String get pdfEditPages => 'Sayfaları düzenle';

  @override
  String get pdfDeletePages => 'Seçili sayfaları sil';

  @override
  String get pdfRotatePages => 'Döndür';

  @override
  String get pdfBurnInk => 'El yazısını belgeye göm';

  @override
  String get pdfApplyChanges => 'Değişiklikleri uygula';

  @override
  String get pdfCannotDeleteAllPages => 'Tüm sayfalar silinemez';

  @override
  String get pdfPagesHint =>
      'Sayfaya dokunup seçin. Sayfa notları sayfalarıyla birlikte taşınır; silinen sayfanın notu listede görünmez ama kaydınızda kalır.';

  @override
  String pdfEditFailed(String error) {
    return 'PDF düzenlenemedi: $error';
  }

  @override
  String get pdfInkBurned => 'El yazısı belgeye gömüldü';

  @override
  String get pdfAllPageNotes => 'Tüm sayfa notları';

  @override
  String get pdfNoPageNotes =>
      'Henüz sayfa notu yok. Sayfayı çevirip alttaki alana yazın.';

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
  String get attachNoteContent => 'Not içeriği';

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
    return 'Sayfa $current / $total';
  }

  @override
  String get scanRotatePage => 'Sayfayı döndür';

  @override
  String get scanDeletePage => 'Sayfayı sil';

  @override
  String get scanLastPage => 'Son sayfa silinemez';

  @override
  String get scanDiscardTitle => 'Taranan sayfalar atılsın mı?';

  @override
  String get scanDiscardConfirm => 'At';

  @override
  String get scanAdjustCorners => 'Köşeleri ayarla';

  @override
  String get scanFilterOriginal => 'Özgün';

  @override
  String get scanFilterAuto => 'Netleştir';

  @override
  String get scanFilterGray => 'Gri';

  @override
  String get scanFilterBw => 'Siyah-beyaz';

  @override
  String get scanApplyAll => 'Hepsine uygula';

  @override
  String get scanPageFailed => 'Sayfa görüntülenemedi';

  @override
  String get scanCropHint =>
      'Yamuk sayfayı \"Köşeleri ayarla\" ile düzeltebilirsin';

  @override
  String get scanAddAsPdf => 'PDF olarak ekle';

  @override
  String get scanAddAsImages => 'Görsel olarak ekle';

  @override
  String get scanBuildingPdf => 'PDF hazırlanıyor…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'Metin tanınıyor… $done/$total';
  }

  @override
  String get scanAutoDetect => 'Kenarları otomatik bul';

  @override
  String get scanReset => 'Sıfırla';

  @override
  String get scanDetecting => 'Kenarlar aranıyor…';

  @override
  String get scanAutoFound =>
      'Kenarlar otomatik bulundu; gerekirse tutamaçlardan ince ayar yap';

  @override
  String get scanDragHint => 'Köşeleri kâğıdın kenarlarına sürükle';

  @override
  String get scanApplyCorners => 'Düzelt ve uygula';

  @override
  String get scanWorking => 'Düzeltiliyor…';

  @override
  String get scanPdfAdded => 'Tarama, PDF eki olarak nota eklendi';

  @override
  String get premiumTitle => 'Premium';

  @override
  String premiumStatusActive(String date) {
    return 'Premium etkin — $date tarihine kadar';
  }

  @override
  String get premiumStatusFree => 'Ücretsiz sürümü kullanıyorsun';

  @override
  String get premiumPerksTitle => 'Premium ile ne değişir?';

  @override
  String get premiumPerkAi => 'Günlük yapay zeka puanı';

  @override
  String get premiumPerkAttach => 'Ek dosya boyutu';

  @override
  String get premiumPerkStorage => 'Bulut depolama alanı';

  @override
  String get premiumPerkAuto => 'Otomatik günlük içerik';

  @override
  String get premiumPerkAutoBody =>
      'Günlük brifing ve öneriler her gün kendiliğinden hazırlanır; ücretsizde yalnız düğmeyle üretilir.';

  @override
  String get premiumHowTitle => 'Nasıl edinilir?';

  @override
  String get premiumHowBody =>
      'Premium yakında Play Store üzerinden satın alınabilecek. Şu an erken erişim dönemindeyiz.';

  @override
  String get premiumByokHint =>
      'Kendi Gemini API anahtarını girersen yapay zeka özellikleri kotasız çalışır — Premium\'dan bağımsız (Ayarlar → Yapay Zeka).';

  @override
  String get premiumDiscoverTitle => 'Gözden kaçan özellikler';

  @override
  String get discoverScanBody =>
      'Kamerayla taranan sayfalar kenar bulma ve netleştirmeyle düzelir, tek dokunuşla ARANABİLİR PDF olur — metin katmanı cihazda, ücretsiz üretilir.';

  @override
  String get discoverSemanticBody =>
      'Arama kutusundaki \"Akıllı\" sekmesi kelime değil ANLAM arar: \"uçak saatleri\" yazınca seyahat notun çıkar.';

  @override
  String get discoverAssistantBody =>
      'Ana ekrandaki mikrofon konuşmanı nota, listeye ve hatırlatıcıya kendisi çevirir — \"yarın 9\'da diş randevusu\" demen yeter.';

  @override
  String get discoverLockBody =>
      'Bir notu parmak izi/yüz kilidiyle kilitleyebilirsin: içeriği aramaya, widget\'a ve AI\'a hiç sızmaz.';

  @override
  String get discoverHiddenBody =>
      'Gizli klasördeki notlar ana ekranda ve aramada hiç görünmez; klasörü göstermek kimlik doğrulaması ister.';

  @override
  String get discoverExportBody =>
      'Her not görselleriyle birlikte PDF ya da Word olarak dışa aktarılabilir (paylaş menüsünde).';

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
  String get pdfSelectOcrRunning => 'Metin tanınıyor…';

  @override
  String get pdfSelectOcrNone => 'Bu sayfada metin bulunamadı';

  @override
  String pdfSelectCopied(int n) {
    return '$n karakter kopyalandı';
  }

  @override
  String get bubbleAdd => 'Not balonu bırak';

  @override
  String get bubbleAddDone => 'Balon bırakmayı bitir';

  @override
  String get bubbleCollapse => 'Balonu küçült';

  @override
  String get bubbleHint => 'Buraya notunu yaz…';

  @override
  String get bubbleTapToPlace => 'Sayfada balonu bırakmak istediğin yere dokun';

  @override
  String get aiModelPodcast => 'Podcast anlatısı';

  @override
  String get listenAiVoice => 'Yapay zekâ sesiyle dinle';

  @override
  String get listenAiVoiceInfo =>
      'Cihaz sesi yerine Gemini seslendirir: daha doğal, her paragraf bir model çağrısı harcar.';

  @override
  String listenAiVoiceFailed(String error) {
    return 'Yapay zekâ seslendirmesi başarısız oldu ($error). Cihaz sesiyle okunuyor.';
  }

  @override
  String get ttsSectionTitle => 'Seslendirme';

  @override
  String get ttsEngineDevice => 'Cihaz sesi';

  @override
  String get ttsEngineAi => 'Yapay zekâ';

  @override
  String get ttsEngineDeviceInfo =>
      'Cihazın yerleşik sesi okur: bedava, çevrimdışı ve sınırsız uzunlukta.';

  @override
  String get ttsEngineAiInfo =>
      'Gemini\'nin seslendirme modeli okur: belirgin daha doğal ama her paragraf bir model çağrısıdır ve kendi Gemini anahtarını ister.';

  @override
  String get ttsModel => 'Seslendirme modeli';

  @override
  String get ttsVoice => 'Yapay zekâ sesi';

  @override
  String get shareAsNote => 'Not olarak paylaş';

  @override
  String get shareAsNoteInfo =>
      'Notu ekleri, sayfa notları, çizimleri ve balonlarıyla gönderir; karşı taraf Not uygulamasında aynı şekilde açar.';

  @override
  String get shareAsNotePreparing => 'Not paketi hazırlanıyor…';

  @override
  String get shareAsText => 'सादे टेक्स्ट के रूप में';

  @override
  String get shareAsTextInfo => 'नोट का टेक्स्ट और पेज नोट्स किसी भी ऐप को भेजता है।';

  @override
  String get shareAsTextEmpty => 'इस नोट में साझा करने लायक कोई टेक्स्ट नहीं है।';

  @override
  String get sharePdfWithBubbles => 'बबल वाली PDF के रूप में';

  @override
  String get sharePdfWithBubblesInfo =>
      'बबल, हाइलाइट और ड्रॉइंग PDF के अंदर छाप दिए जाते हैं; कोई भी खोल सकता है और Not में यह संपादन योग्य खुलता है।';

  @override
  String get sharePdfWithBubblesNone => 'इस नोट में बबल या ड्रॉइंग वाली कोई PDF नहीं है।';

  @override
  String get sharePdfWithBubblesPreparing => 'बबल वाली PDF तैयार हो रही है…';

  @override
  String get sharePdfWithBubblesSuffix => ' (बबल सहित)';

  @override
  String get bubbleStar => 'Yıldızla';

  @override
  String get bubbleEdit => 'Balonu düzenle';

  @override
  String get bubbleStarredOnly => 'Yalnız yıldızlılar';

  @override
  String get bubbleSearchHint => 'Balonlarda ara…';

  @override
  String get bubblesOverviewTitle => 'Balonlar';

  @override
  String get bubblesEmpty =>
      'Henüz balon yok. Belgede bir metni seçip vurgula ya da sayfaya balon bırak.';

  @override
  String get bubblesNoMatch => 'Aramaya uyan balon yok.';

  @override
  String get bubbleNoText => '(boş balon)';

  @override
  String get pdfHighlight => 'Vurgula';

  @override
  String get pdfHighlightWithNote => 'Vurgula + not';

  @override
  String get pageNotesShow => 'Sayfa notunu göster';

  @override
  String get pageNotesHide => 'Sayfa notunu gizle';

  @override
  String get bubbleSave => 'Kaydet';

  @override
  String get bubbleTitleHint => 'Başlık';

  @override
  String get bubbleUrgent => 'Acil (yanıp söner)';
}
