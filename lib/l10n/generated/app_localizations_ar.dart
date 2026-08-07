// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'الملاحظات';

  @override
  String get loginTagline => 'ملاحظاتك على كل أجهزتك';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بحساب Google';

  @override
  String loginError(String error) {
    return 'تعذّر تسجيل الدخول: $error';
  }

  @override
  String get searchHint => 'ابحث في الملاحظات...';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterText => 'نص';

  @override
  String get filterChecklist => 'قائمة';

  @override
  String get filterOrdered => 'مرقّمة';

  @override
  String get filterPinned => 'مثبّتة';

  @override
  String get filterStarred => 'مميّزة بنجمة';

  @override
  String get star => 'إضافة نجمة';

  @override
  String get unstar => 'إزالة النجمة';

  @override
  String editedAt(String date) {
    return 'عُدّلت: $date';
  }

  @override
  String get sectionPinned => 'مثبّتة';

  @override
  String get sectionOthers => 'أخرى';

  @override
  String get emptyNotes => 'لا توجد ملاحظات بعد';

  @override
  String get emptyNotesHint => 'اضغط + لإنشاء أول ملاحظة';

  @override
  String get emptySearch => 'لا توجد نتائج';

  @override
  String get newTextNote => 'ملاحظة نصية';

  @override
  String get newChecklist => 'قائمة';

  @override
  String get newOrderedList => 'قائمة مرقّمة';

  @override
  String get noteDeleted => 'حُذفت الملاحظة';

  @override
  String notesDeletedCount(int count) {
    return 'حُذفت $count ملاحظة';
  }

  @override
  String selectedCount(int count) {
    return '$count محدّدة';
  }

  @override
  String get deleteSelected => 'حذف المحدّد';

  @override
  String get undo => 'تراجع';

  @override
  String get redo => 'إعادة';

  @override
  String get titleHint => 'العنوان';

  @override
  String get bodyHint => 'ملاحظة...';

  @override
  String get newItemHint => 'عنصر جديد';

  @override
  String moreItemsCount(int count) {
    return '+$count عناصر أخرى';
  }

  @override
  String get addAttachment => 'إضافة';

  @override
  String get addAttachmentMore => 'أنواع مرفقات أخرى…';

  @override
  String get addImage => 'إضافة صورة';

  @override
  String get addPdf => 'إضافة PDF';

  @override
  String get addSlide => 'إضافة شرائح';

  @override
  String get pasteImage => 'لصق صورة من الحافظة';

  @override
  String get clipboardEmpty => 'لا توجد صورة في الحافظة';

  @override
  String get noNoteSelected => 'اختر ملاحظة من الجانب';

  @override
  String attachmentFailed(String error) {
    return 'تعذّر إضافة المرفق: $error';
  }

  @override
  String get attachmentUploading => 'جارٍ الرفع...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced => 'لم تتم مزامنة هذا الملف مع هذا الجهاز بعد';

  @override
  String attachmentTooLarge(int limit) {
    return 'الملف كبير جدًا (بحد أقصى $limit ميجابايت)';
  }

  @override
  String storageFull(String limit) {
    return 'مساحة التخزين ممتلئة ($limit). احذف المرفقات القديمة لتحرير مساحة.';
  }

  @override
  String get storageUsage => 'التخزين';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used من $limit مستخدمة';
  }

  @override
  String get removeAttachment => 'إزالة المرفق';

  @override
  String get pin => 'تثبيت';

  @override
  String get unpin => 'إلغاء التثبيت';

  @override
  String get delete => 'حذف';

  @override
  String get color => 'اللون';

  @override
  String get aiTitle => 'الذكاء الاصطناعي';

  @override
  String get aiSummarize => 'تلخيص الملاحظة';

  @override
  String get aiAnalyze => 'تحليل';

  @override
  String get aiSectionNote => 'هذه الملاحظة';

  @override
  String get aiSectionAttachments => 'المرفقات';

  @override
  String get summarize => 'تلخيص';

  @override
  String get summaryDetailTitle => 'نوع الملخّص';

  @override
  String get summaryShort => 'ملخّص قصير';

  @override
  String get summaryShortInfo => 'بضع جمل عامة مع أهم النقاط';

  @override
  String get summaryDetailed => 'ملخّص مفصّل';

  @override
  String get summaryDetailedInfo => 'وافٍ بما يكفي لتستغني عن فتح الأصل';

  @override
  String get listen => 'استماع';

  @override
  String get ask => 'اطرح سؤالًا';

  @override
  String get extractText => 'استخراج النص';

  @override
  String get transcribe => 'تفريغ النص';

  @override
  String get listenToNote => 'قراءة بصوت عالٍ';

  @override
  String get aiNoApiKey => 'أدخل أولًا مفتاح Gemini API في الإعدادات';

  @override
  String aiError(String error) {
    return 'فشل طلب الذكاء الاصطناعي: $error';
  }

  @override
  String get aiSummaryTitle => 'ملخّص الذكاء الاصطناعي';

  @override
  String get aiThinking => 'جارٍ التفكير...';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String get settingsSearchHint => 'ابحث في الإعدادات — \"موجز\"، \"ميكروفون\"';

  @override
  String settingsSearchEmpty(String query) {
    return 'لا يوجد إعداد يطابق «$query»';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsAppearance => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get settingsAi => 'الذكاء الاصطناعي';

  @override
  String get geminiApiKey => 'مفتاح Gemini API';

  @override
  String get geminiApiKeyHint => 'الصق المفتاح الذي يبدأ بـ AIza...';

  @override
  String get geminiApiKeyInfo =>
      'المفتاح اختياري: بدونه تمر طلبات الذكاء الاصطناعي عبر الخدمة المدمجة في التطبيق (حصة يومية مجانية، وأكبر مع Premium). وللاستخدام بلا حدود بمفتاحك الخاص، احصل على مفتاح مجاني من aistudio.google.com؛ يُحفظ المفتاح على هذا الجهاز فقط، في مساحة تخزين آمنة.';

  @override
  String aiBuiltInPremium(int count) {
    return 'الذكاء الاصطناعي المدمج: Premium — بقي اليوم $count نقطة';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'الذكاء الاصطناعي المدمج: بقي اليوم $count نقطة مجانية';
  }

  @override
  String get aiBuiltInByok => 'باستخدام مفتاحك الخاص — بلا حدود';

  @override
  String get aiReport => 'الإبلاغ عن هذه الإجابة';

  @override
  String get aiReportThanks => 'وصلنا بلاغك، شكرًا لك';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get lockNote => 'قفل';

  @override
  String get unlockNote => 'إلغاء القفل';

  @override
  String get lockedNote => 'ملاحظة مقفلة';

  @override
  String get unlockAuthReason => 'أكّد هويتك لفتح الملاحظة المقفلة';

  @override
  String get exportBackup => 'تصدير نسخة احتياطية (JSON)';

  @override
  String get expandListItems => 'إظهار سطور القائمة كاملة';

  @override
  String get expandListItemsInfo =>
      'تلتف العناصر الطويلة على عدة سطور وتبقى ظاهرة بالكامل. وعند الإيقاف يبقى العنصر في سطر واحد ويتوسّع عند لمسه.';

  @override
  String get quickCaptureRowSetting => 'شريط الملاحظة السريعة';

  @override
  String get quickCaptureRowInfo =>
      'يعرض حقل \"ملاحظة جديدة...\" من سطر واحد أعلى الشاشة. عند الإيقاف استخدم زر +.';

  @override
  String get emptyTrash => 'إفراغ سلة المحذوفات';

  @override
  String emptyTrashConfirm(int count) {
    return 'ستُحذف $count ملاحظة نهائيًا، ولا يمكن التراجع عن ذلك. هل أنت متأكد؟';
  }

  @override
  String get trashEmptied => 'أُفرغت سلة المحذوفات';

  @override
  String get validateAndSave => 'تحقّق واحفظ';

  @override
  String get clear => 'مسح';

  @override
  String get aiDiagnostics => 'تشخيص الذكاء الاصطناعي';

  @override
  String get aiDiagnosticsEmpty => 'لم تُسجَّل أي أخطاء';

  @override
  String aiDiagnosticsCount(int count) {
    return 'آخر $count سجل أخطاء';
  }

  @override
  String get apiKeyValid => 'تم التحقق من مفتاح API وحفظه';

  @override
  String get apiKeyInvalid => 'مفتاح API غير صالح';

  @override
  String get apiKeySavedBadge => 'محفوظ';

  @override
  String get removeApiKey => 'حذف المفتاح';

  @override
  String get refresh => 'تحديث';

  @override
  String get account => 'الحساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل تريد بالفعل تسجيل الخروج؟';

  @override
  String get signOutAnonymousWarning =>
      'أنت على حساب محلي: تسجيل الخروج سيجعل هذا الحساب وكل الملاحظات غير قابلة للوصول نهائيًا — وبدون نسخة احتياطية لا يمكن استعادتها. اربط حساب Google أولًا. هل تريد الخروج رغم ذلك؟';

  @override
  String get deleteAccount => 'حذف حسابي وبياناتي';

  @override
  String get deleteAccountWarning =>
      'لا يمكن التراجع عن ذلك: ستُحذف كل ملاحظاتك ومرفقاتك وحسابك نهائيًا. هل تريد المتابعة؟';

  @override
  String get deleteAccountConfirm => 'حذف نهائي';

  @override
  String get licensesTitle => 'تراخيص المصادر المفتوحة';

  @override
  String get generating => 'جارٍ الإنشاء...';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get ok => 'حسنًا';

  @override
  String get syncPending => 'في انتظار المزامنة';

  @override
  String get synced => 'تمت المزامنة';

  @override
  String genericError(String error) {
    return 'حدث خطأ ما: $error';
  }

  @override
  String get addTag => 'وسم';

  @override
  String get tagHint => 'مثل: العمل، البيت، المدرسة';

  @override
  String get addReminder => 'ذكّرني';

  @override
  String get share => 'مشاركة';

  @override
  String get archive => 'أرشفة';

  @override
  String get unarchive => 'إخراج من الأرشيف';

  @override
  String get archiveTitle => 'الأرشيف';

  @override
  String get archiveEmpty => 'لا توجد ملاحظات في الأرشيف';

  @override
  String get trashTitle => 'سلة المحذوفات';

  @override
  String get trashEmpty => 'سلة المحذوفات فارغة';

  @override
  String get trashInfo =>
      'تبقى الملاحظات المحذوفة هنا؛ يمكنك استعادتها أو حذفها نهائيًا.';

  @override
  String get restore => 'استعادة';

  @override
  String get deleteForever => 'حذف نهائي';

  @override
  String get deleteForeverConfirm =>
      'ستُحذف هذه الملاحظة نهائيًا. هل أنت متأكد؟';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'تسجيل صوتي';

  @override
  String get recording => 'جارٍ التسجيل...';

  @override
  String get stopAndSave => 'إنهاء وإضافة';

  @override
  String get micPermissionDenied => 'تم رفض إذن الميكروفون';

  @override
  String get speechRecognitionFailed =>
      'لم ينجح التعرّف على الكلام. تأكّد من منح إذن الميكروفون ومن تحديث تطبيق Google.';

  @override
  String get addDrawing => 'إضافة رسم';

  @override
  String get drawingTitle => 'رسم';

  @override
  String get addToNote => 'إضافة إلى الملاحظة';

  @override
  String get chatTitle => 'مساعد الملاحظات';

  @override
  String get chatHint =>
      'اسأل عن ملاحظاتك: «ما تلك الوصفة التي كتبتها الأسبوع الماضي؟»، «ما الناقص من قائمة التسوّق؟»';

  @override
  String get chatInputHint => 'اكتب سؤالًا...';

  @override
  String get fontSize => 'حجم النص';

  @override
  String get fontSizePreview => 'هكذا ستبدو ملاحظاتك';

  @override
  String get darkSchedule => 'جدولة المظهر الداكن';

  @override
  String get darkScheduleInfo =>
      'ينتقل إلى المظهر الداكن بين الساعتين اللتين تحدّدهما';

  @override
  String get aiTranslate => 'ترجمة';

  @override
  String get voiceCommand => 'أمر صوتي';

  @override
  String get semanticSearchToggle => 'بحث بالمعنى بالذكاء الاصطناعي';

  @override
  String get semanticSearchHint => 'ابحث بالمعنى: «مصاريف السيارة»...';

  @override
  String get briefingTitle => 'موجز اليوم';

  @override
  String get briefingLoading => 'جارٍ تحضير موجزك...';

  @override
  String get briefingEmpty => 'لا شيء لهذا اليوم';

  @override
  String get briefingSetting => 'إشعار الموجز اليومي';

  @override
  String get briefingSettingInfo =>
      'احصل كل صباح على إشعار بملخّص اليوم في الوقت الذي تختاره';

  @override
  String get autoTagSetting => 'الوسم تلقائيًا';

  @override
  String get autoTagSettingInfo =>
      'عند إغلاق ملاحظة بلا وسوم، يضيف الذكاء الاصطناعي وسمًا مناسبًا';

  @override
  String get suggestTags => 'اقتراح وسوم';

  @override
  String get aiFixNote => 'تحسين الملاحظة';

  @override
  String get fixLevelTitle => 'إلى أي مدى نصحّح؟';

  @override
  String get fixSimple => 'خفيف';

  @override
  String get fixSimpleInfo => 'الإملاء والأخطاء المطبعية فقط';

  @override
  String get fixBalanced => 'متوازن';

  @override
  String get fixBalancedInfo => 'وبنية الجمل أيضًا، لكتابة أوضح';

  @override
  String get fixDetailed => 'شامل';

  @override
  String get fixDetailedInfo => 'يعيد كتابة النص كله من أوله إلى آخره';

  @override
  String get existingTagsLabel => 'الوسوم السابقة';

  @override
  String get aiSkipCheckedSetting =>
      'استثناء العناصر المؤشَّرة من تعديلات الذكاء الاصطناعي';

  @override
  String get aiSkipCheckedInfo =>
      'عندما يصحّح الذكاء الاصطناعي قائمة أو يترجمها، تبقى العناصر المنجزة (المؤشَّرة) كما هي تمامًا؛ ولا يُعدَّل إلا غير المؤشَّر منها.';

  @override
  String get noteUpdatedUndo => 'حُدِّثت الملاحظة';

  @override
  String get aiImprove => 'تحسين الملاحظة';

  @override
  String get improveFormal => 'بأسلوب أكثر رسمية';

  @override
  String get improveShorten => 'اختصار';

  @override
  String get improveBullets => 'تحويل إلى قائمة نقطية';

  @override
  String get improveNumbered => 'تحويل إلى قائمة مرقّمة';

  @override
  String get replaceNote => 'استبدال الملاحظة';

  @override
  String get openAsNewNote => 'كملاحظة جديدة';

  @override
  String get pdfChatHint =>
      'اسأل عن ملف PDF هذا: «لخّصه»، «هل فيه بند جزائي؟»، «ما الموعد النهائي؟»';

  @override
  String get pdfChatInputHint => 'اكتب سؤالًا عن ملف PDF...';

  @override
  String get voiceCaptureHint =>
      'تكلّم: «شراء حليب وخبز» أو «اجتماع غدًا الساعة 9، ذكّرني» — ينشئ الذكاء الاصطناعي ملاحظتك عندما تنتهي.';

  @override
  String get voiceFinish => 'إنهاء';

  @override
  String get voiceProcessing => 'جارٍ معالجة ما قلته...';

  @override
  String get voiceNothingHeard => 'لم يُعثر على كلام في التسجيل';

  @override
  String get voiceNoteSaved => 'حُفظت ملاحظتك الصوتية';

  @override
  String get openNote => 'فتح الملاحظة';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get remindersEmpty => 'لا توجد تذكيرات';

  @override
  String get remindersEmptyHint =>
      'أضف تذكيرًا إلى ملاحظة، أو أنشئ ملاحظة جديدة مع تذكير من زر +';

  @override
  String get remindersUpcoming => 'القادمة';

  @override
  String get remindersPast => 'الماضية';

  @override
  String get reminderInPast => 'الوقت المحدد قد مضى — اختر وقتًا في المستقبل.';

  @override
  String get newReminder => 'تذكير جديد';

  @override
  String get remindersUntitled => 'ملاحظة بلا عنوان';

  @override
  String get remindersEdit => 'تغيير الوقت';

  @override
  String get remindersRemove => 'إزالة التذكير';

  @override
  String get aiModelChat => 'الملخّصات والعناوين والوسوم والمحادثة';

  @override
  String get aiModelDocument => 'البودكاست ومحادثة المستندات';

  @override
  String get aiModelTranslate => 'الترجمة';

  @override
  String get aiModelVoice => 'الملاحظات الصوتية';

  @override
  String get aiModelAuto => 'تلقائي (موصى به)';

  @override
  String get aiModelsInfo =>
      'يمكنك اختيار نموذج مستقل لكل مهمة: النصوص القصيرة يكفيها نموذج سريع، أما المستندات الطويلة فتحتاج نموذجًا أقوى. وإذا استنفد النموذج المختار حصته أو تم سحبه، يُجرَّب التالي تلقائيًا.';

  @override
  String get clearNote => 'تفريغ';

  @override
  String get clearNoteConfirm =>
      'سيُحذف محتوى الملاحظة (النص وعناصر القائمة). هل أنت متأكد؟';

  @override
  String get themePaper => 'ورق';

  @override
  String get calculatorTitle => 'الآلة الحاسبة';

  @override
  String get calcExpressionHint => 'مثل 12.5×3+40';

  @override
  String get calcInvalid => 'تعبير غير صالح';

  @override
  String get liveDictation => 'إملاء';

  @override
  String get dictationListening => 'أستمع... يظهر النص أثناء حديثك';

  @override
  String get dictationNoKeyInfo =>
      'الإملاء المباشر غير متاح على هذا الجهاز؛ سيُفرَّغ التسجيل دفعة واحدة عند التوقّف.';

  @override
  String get dictationHoldHint =>
      'اضغط مطوّلًا على الميكروفون وتكلّم؛ يُكتب النص عند رفع إصبعك';

  @override
  String itemsSelected(int count) {
    return '$count عنصر محدّد';
  }

  @override
  String get noteChatTitle => 'محادثة مع هذه الملاحظة';

  @override
  String get noteChatHint => 'اسأل شيئًا عن هذه الملاحظة';

  @override
  String get noteChatIntro =>
      'يُقرأ محتوى الملاحظة ومرفقاتها (PDF/صورة)، ويُجاب على سؤالك انطلاقًا منها.';

  @override
  String get dictationProcessing => 'جارٍ التفريغ...';

  @override
  String get aiDailyManualInfo =>
      'في الخطة المجانية لا يُنشأ هذا تلقائيًا، فلا يستهلك حصتك اليومية. يمكنك إنشاؤه مرة واحدة يوميًا بالزر أدناه.';

  @override
  String get aiGenerate => 'إنشاء';

  @override
  String get aiGeneratedTodayInfo =>
      'أُنشئ هذا اليوم. في الخطة المجانية يتجدّد مرة واحدة يوميًا؛ ويمكنك إنشاؤه مجددًا غدًا.';

  @override
  String get voiceAssistantTitle => 'مساعد الملاحظات الصوتية';

  @override
  String get voiceListening => 'أستمع...';

  @override
  String get voiceHoldHint =>
      'اضغط مطوّلًا وتكلّم؛ تُنشأ ملاحظتك عند رفع إصبعك';

  @override
  String get voiceTapHint => 'المس وتكلّم؛ والمس مرة أخرى للإنهاء';

  @override
  String get voiceTooShort => 'كان ذلك التسجيل قصيرًا جدًا، حاول مرة أخرى';

  @override
  String get voiceModeSetting => 'طريقة العمل';

  @override
  String get voiceModeHold => 'اضغط مطوّلًا للتحدّث';

  @override
  String get voiceModeTap => 'المس للبدء / المس للإيقاف';

  @override
  String get voiceModeInfo =>
      'اضغط مطوّلًا للتحدّث: يستمع ما دمت ضاغطًا على الزر وينشئ الملاحظة عند رفع إصبعك. المس للبدء: لمسة أولى تبدأ التسجيل ولمسة ثانية تنهيه.';

  @override
  String get voiceHeardLive => 'تم رصد كلام';

  @override
  String get voiceCaptureReady => 'جاهز للتسجيل';

  @override
  String get voiceCaptureEditHint => 'انقر على النص للتعديل';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · ترقيم تلقائي';
  }

  @override
  String get voiceCaptureAddToNote => 'إضافة إلى الملاحظة';

  @override
  String get voiceCaptureCreateNote => 'إنشاء ملاحظة جديدة';

  @override
  String get voiceCaptureAiNote => 'ملاحظة ذكية';

  @override
  String get voiceCapturePlainNote => 'ملاحظة عادية';

  @override
  String get voiceCloseTitle => 'ما أمليته لا يزال موجودًا';

  @override
  String get voiceCloseKeepTalking => 'متابعة التحدث';

  @override
  String get voiceCaptureRestart => 'تسجيل مجددًا';

  @override
  String get voiceChipSummarizeAdd => 'إضافة كملخص';

  @override
  String get voiceChipSummarizeSave => 'حفظ كملخص';

  @override
  String get voiceChipToItems => 'تقسيم إلى عناصر';

  @override
  String get voiceChipAsList => 'تحويل إلى قائمة مهام';

  @override
  String get voiceChipFix => 'تنقيح النص';

  @override
  String get voiceChipCompose => 'دع المساعد يكتبها';

  @override
  String get editorToolList => 'قائمة';

  @override
  String get permissionsTitle => 'الأذونات';

  @override
  String get permMic => 'الميكروفون';

  @override
  String get permMicInfo => 'مطلوب للملاحظات الصوتية والإملاء';

  @override
  String get permNotifications => 'الإشعارات';

  @override
  String get permNotificationsInfo => 'مطلوبة للتذكيرات وموجز اليوم';

  @override
  String get permBattery => 'تحسين البطارية';

  @override
  String get permBatteryInfo =>
      'استثنِ التطبيق من قيود البطارية لتصل التذكيرات في وقتها';

  @override
  String get showTagChips => 'إظهار شرائح الوسوم';

  @override
  String get showFolderChips => 'إظهار شرائح المجلدات';

  @override
  String videoTooBigForAi(int mb) {
    return 'الفيديو أكبر من أن يُرسل إلى الذكاء الاصطناعي ($mb ميجابايت). سجّل مقطعًا أقصر.';
  }

  @override
  String get permCamera => 'الكاميرا';

  @override
  String get permCameraInfo => 'مطلوبة لملاحظات الفيديو والتقاط الصور';

  @override
  String get permOnboardTitle => 'قبل أن تبدأ';

  @override
  String get permOnboardInfo =>
      'لا يطلب تطبيق الملاحظات هذه الأذونات إلا عند استخدامك للميزة المقابلة. يمكنك منحها الآن أدناه، أو تغييرها لاحقًا من الإعدادات > الأذونات.';

  @override
  String get permOnboardGrantAll => 'منح الأذونات';

  @override
  String get permOnboardSkip => 'ليس الآن';

  @override
  String get newVideoNote => 'ملاحظة فيديو';

  @override
  String get videoLocalOnly =>
      'يُحفظ هذا الفيديو على هذا الجهاز فقط (ولا يُرفع إلى السحابة)';

  @override
  String get videoToNote => 'إنشاء ملاحظة من الفيديو';

  @override
  String get videoToNoteRunning => 'جارٍ مراجعة الفيديو…';

  @override
  String get permGranted => 'ممنوح';

  @override
  String get permGrant => 'منح';

  @override
  String get permOpenSettings => 'فتح الإعدادات';

  @override
  String get newHandwriting => 'خط اليد';

  @override
  String get newVoiceCapture => 'ملاحظة صوتية';

  @override
  String get suggestTitle => 'اقتراح عنوان';

  @override
  String get noteMetaMenu => 'وسم · عنوان · تذكير';

  @override
  String get folder => 'مجلد';

  @override
  String get noFolder => 'بلا مجلد';

  @override
  String get newFolder => 'مجلد جديد';

  @override
  String get editFolder => 'تعديل المجلد';

  @override
  String get deleteFolder => 'حذف المجلد';

  @override
  String deleteFolderConfirm(String name) {
    return 'سيُحذف المجلد «$name». أما الملاحظات التي بداخله فلن تُحذف — ستبقى بلا مجلد فحسب.';
  }

  @override
  String get folderNameHint => 'اسم المجلد';

  @override
  String get folderIcon => 'أيقونة';

  @override
  String get editFilters => 'تعديل عوامل التصفية';

  @override
  String get editFiltersInfo =>
      'اختر عوامل التصفية التي تظهر في الشاشة الرئيسية. إخفاء بعضها يبقي الصفحة مرتّبة.';

  @override
  String get select => 'تحديد';

  @override
  String get noteArchived => 'أُرشفت الملاحظة';

  @override
  String deleteChecked(int count) {
    return 'حذف المؤشَّر ($count)';
  }

  @override
  String get removeItem => 'حذف العنصر';

  @override
  String get copyWholeNote => 'نسخ الملاحظة كاملة';

  @override
  String get allCopied => 'نُسخت الملاحظة كاملة إلى الحافظة';

  @override
  String get speechPlay => 'قراءة بصوت عالٍ';

  @override
  String get speechPause => 'إيقاف مؤقت';

  @override
  String get speechResume => 'متابعة';

  @override
  String get speechStop => 'إيقاف';

  @override
  String get speechRate => 'سرعة القراءة';

  @override
  String get speechSystemDefault => 'الإعداد الافتراضي للنظام';

  @override
  String get speechNoVoices => 'لا توجد أصوات مثبّتة على هذا الجهاز';

  @override
  String speechVoiceLanguage(String language) {
    return 'صوت $language';
  }

  @override
  String get speechVoiceAutoInfo => 'تُقرأ اللغات الأخرى تلقائيًا بصوت رجالي';

  @override
  String get listening => 'أستمع...';

  @override
  String get listenPlay => 'استماع';

  @override
  String get listenReadingPdf => 'جارٍ قراءة المستند...';

  @override
  String get listenConvertWithAi => 'تحويل بالذكاء الاصطناعي';

  @override
  String get listenMakePodcast => 'بودكاست كامل';

  @override
  String get listenMakePodcastSummary => 'بودكاست ملخّص';

  @override
  String get listenOriginalText => 'النص الأصلي';

  @override
  String get listenPodcastReady => 'سرد البودكاست جاهز';

  @override
  String get listenPodcastCached => 'أُنشئ سابقًا — دون إنفاق أي رموز';

  @override
  String get listenRegenerate => 'إنشاء من جديد';

  @override
  String get listenNoText =>
      'لم يخرج من هذا المستند نص قابل للقراءة. ملف PDF الممسوح ضوئيًا لا يحتوي طبقة نصية، وقد لا يحتوي العرض التقديمي إلا على صور.';

  @override
  String get readDocument => 'قراءة مستند (Word أو PDF أو شرائح)';

  @override
  String get readDocUnsupported => 'لا يمكن قراءة هذا النوع من الملفات.';

  @override
  String get exportPdf => 'تصدير بصيغة PDF';

  @override
  String get pdfTitleField => 'العنوان';

  @override
  String get pdfContentField => 'المحتوى';

  @override
  String get pdfMarkupHint =>
      'تتحوّل العلامات في بداية السطر إلى تنسيق: [x] و[ ] لمربعات الاختيار، و1. لقائمة مرقّمة، و- لنقطة.';

  @override
  String get pdfIncludeDate => 'تضمين التاريخ';

  @override
  String get exportIncludeImages => 'تضمين الصور';

  @override
  String get exportWord => 'مشاركة بصيغة Word ‏(.docx)';

  @override
  String get pdfPreview => 'معاينة';

  @override
  String get largeAttachmentTitle => 'ملف كبير';

  @override
  String largeAttachmentBody(String size) {
    return 'حجم هذا الملف $size ميجابايت. ملفات PDF لا يمكن ضغطها؛ سيُرفع كما هو ويُحتسب ضمن مساحة تخزينك. هل تريد المتابعة؟';
  }

  @override
  String get speechRateForeign => 'سرعة اللغات الأجنبية';

  @override
  String notesArchivedCount(int count) {
    return 'أُرشفت $count ملاحظة';
  }

  @override
  String get backgroundColor => 'لون الخلفية';

  @override
  String get backgroundColorInfo => 'لون خلفية الملاحظة';

  @override
  String get frameColor => 'الإطار';

  @override
  String get frameColorInfo => 'يرسم إطارًا حول الملاحظة باللون الذي تختاره';

  @override
  String get sortBy => 'ترتيب';

  @override
  String get reorderNotes => 'إعادة ترتيب الملاحظات';

  @override
  String get reorderModeActive => 'اسحب البطاقات لإعادة ترتيبها';

  @override
  String get reorderDone => 'تم';

  @override
  String get sortManual => 'يدوي (ترتيب السحب)';

  @override
  String get sortUpdated => 'المحدَّثة حديثًا';

  @override
  String get sortCreated => 'تاريخ الإنشاء';

  @override
  String get sortTitle => 'حسب العنوان (أ–ي)';

  @override
  String get foldersSection => 'المجلدات';

  @override
  String get tagsSection => 'الوسوم';

  @override
  String get expandFilters => 'توسيع عوامل التصفية';

  @override
  String get collapseFilters => 'طيّ عوامل التصفية';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get settingsSpeech => 'القراءة بصوت عالٍ';

  @override
  String get aiAdvanced => 'متقدّم: النموذج ومفتاح API';

  @override
  String get aiAdvancedInfo =>
      'اختيار النموذج ومفتاح Gemini الخاص بك. معظم الناس لا يحتاجون إلى ذلك.';

  @override
  String get openBriefing => 'فتح الموجز';

  @override
  String get syncTitle => 'المزامنة';

  @override
  String get syncLimitTitle => 'حد الرفع التلقائي';

  @override
  String get syncLimitInfo =>
      'تبقى المرفقات الأكبر من هذا الحد على الجهاز ولا تُرفع. أما نص الملاحظات فيُزامَن دائمًا.';

  @override
  String get syncLimitUnlimited => 'بلا حد';

  @override
  String get backupTitle => 'النسخ الاحتياطي';

  @override
  String get importBackup => 'استعادة من نسخة احتياطية (JSON)';

  @override
  String importBackupDone(int count) {
    return 'استُعيدت $count ملاحظة';
  }

  @override
  String get importBackupInvalid => 'ملف النسخة الاحتياطية غير صالح';

  @override
  String get aiHubTitle => 'الذكاء الاصطناعي';

  @override
  String get aiSummarizeInfo => 'ينتج ملخّصًا قصيرًا';

  @override
  String get aiAnalyzeInfo => 'يعدّد النقاط الأساسية والمهام';

  @override
  String get aiImproveInfo => 'يغيّر الأسلوب: رسمي أو أقصر أو قائمة';

  @override
  String get aiTranslateInfo => 'يترجم الملاحظة إلى اللغة التي تختارها';

  @override
  String get aiFixNoteInfo => 'يصحح الإملاء وعلامات الترقيم';

  @override
  String get moveToFolder => 'نقل إلى مجلد';

  @override
  String get voiceAssistantBadge => 'المساعد';

  @override
  String get assistantGenericError => 'حدث خطأ ما — هل تحاول مرة أخرى؟';

  @override
  String get quickAddTooltip => 'ملاحظة جديدة — اختر نوعًا';

  @override
  String get autoTitleSetting => 'اقتراح عنوان عند الإغلاق';

  @override
  String get autoTitleSettingInfo =>
      'عند مغادرة المحرّر، تحصل الملاحظة التي تُركت بلا عنوان على عنوان قصير مكتوب من محتواها.';

  @override
  String get hubChatInfo => 'إجابات مأخوذة من ملاحظاتك';

  @override
  String get hubBriefingInfo => 'يومك في لمحة: التذكيرات والملاحظات الأخيرة';

  @override
  String get hubReadInfo => 'استمع إلى مستند PDF أو Word';

  @override
  String get annotate => 'تعليق توضيحي';

  @override
  String get annotateDone => 'إنهاء التعليق';

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
  String get crop => 'قصّ';

  @override
  String get cropApply => 'تطبيق القصّ';

  @override
  String get cropReset => 'إعادة ضبط التحديد';

  @override
  String get cropHint =>
      'اسحب الزوايا لاختيار منطقة. لا يمكن التراجع عن القصّ.';

  @override
  String get cropFailed => 'تعذّر قصّ الصورة.';

  @override
  String get penBallpoint => 'قلم حبر جاف';

  @override
  String get penMarker => 'قلم تحديد';

  @override
  String get penHighlighter => 'قلم تظليل';

  @override
  String get eraser => 'ممحاة';

  @override
  String get clearInk => 'مسح التعليقات';

  @override
  String get inkTwoFingerHint => 'إصبع واحد يرسم · وإصبعان يحرّكان ويكبّران';

  @override
  String get slideOpenFailed => 'تعذّر فتح العرض التقديمي';

  @override
  String get newPhotoNote => 'ملاحظة بصورة';

  @override
  String get newScanNote => 'مسح مستند ضوئيًا';

  @override
  String get scanDocument => 'مسح المستند ضوئيًا';

  @override
  String get scanDocumentSubtitle =>
      'يجد الحواف ويعدّل استواء الصفحة ثم يضيفها';

  @override
  String get scanUnsupported =>
      'المسح الضوئي للمستندات غير مدعوم على هذا الجهاز';

  @override
  String scanFailed(String error) {
    return 'تعذّر مسح المستند ضوئيًا: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return 'أُضيفت $count صفحة إلى الملاحظة';
  }

  @override
  String get scanTextTitle => 'هل نتعرّف على النص أيضًا؟';

  @override
  String get scanTextBody =>
      'يُتعرَّف على النص الموجود في الصفحات ويُكتب داخل الملاحظة. وتبقى الصورة كما هي. يستغرق ذلك بضع ثوانٍ لكل صفحة.';

  @override
  String get scanImageOnly => 'صورة فقط';

  @override
  String get scanRecognizeText => 'التعرّف على النص';

  @override
  String get scanRecognizing => 'جارٍ التعرّف على النص…';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get qrScanTitle => 'مسح رمز QR';

  @override
  String get qrScanSubtitle => 'اقرأه بالكاميرا أو من صورة';

  @override
  String get qrScanHint => 'حاذِ الرمز داخل الإطار';

  @override
  String get qrFromPhoto => 'القراءة من صورة';

  @override
  String get qrNotFound => 'لم يُعثر على رمز في هذه الصورة';

  @override
  String get qrLinkFound => 'هذا الرمز عبارة عن رابط';

  @override
  String get qrOpenLink => 'الانتقال إلى الرابط';

  @override
  String get qrSaveToNote => 'الحفظ في ملاحظة';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String get linkOpenFailed => 'تعذّر فتح الرابط';

  @override
  String qrScanFailed(String error) {
    return 'تعذّرت قراءة الرمز: $error';
  }

  @override
  String get qrTorch => 'الكشّاف';

  @override
  String attachmentsCount(int count) {
    return 'المرفقات ($count)';
  }

  @override
  String get hideAttachments => 'إخفاء';

  @override
  String get showAttachments => 'إظهار';

  @override
  String get videoBack10 => '10 ثوانٍ للخلف';

  @override
  String get videoForward10 => '10 ثوانٍ للأمام';

  @override
  String get selectAllItems => 'تحديد الكل';

  @override
  String get showAllChips => 'إظهار الكل';

  @override
  String get hideAllChips => 'إخفاء الكل';

  @override
  String get chipPickInfo =>
      'أي شرائح المجلدات والوسوم ينبغي أن تظهر في الشاشة الرئيسية؟';

  @override
  String get hiddenFolder => 'مجلد مخفي';

  @override
  String get hiddenFolderInfo =>
      'لا يظهر المجلد المخفي ولا الملاحظات التي بداخله في الشاشة الرئيسية. ولإظهارها، اختر «المجلدات المخفية» من قائمة ⋮ ثم أكّد هويتك.';

  @override
  String get hiddenFoldersMenu => 'المجلدات المخفية';

  @override
  String get hiddenFolderAuthReason => 'أكّد هويتك لإظهار المجلدات المخفية';

  @override
  String get hiddenFoldersShown => 'المجلدات المخفية ظاهرة الآن';

  @override
  String get hiddenFoldersHiddenAgain => 'أُخفيت المجلدات المخفية من جديد';

  @override
  String get makeFolderHidden => 'إخفاء';

  @override
  String get makeFolderVisible => 'إظهار';

  @override
  String gridColumnsCount(int count) {
    return '$count أعمدة';
  }

  @override
  String get addImageOnPageSubtitle => 'تستقر في الصفحة، ويلتف النص حولها';

  @override
  String get addImageAsFile => 'إضافة الصورة كملف';

  @override
  String get addImageAsFileSubtitle => 'تبقى خارج الصفحة، في شريط المرفقات';

  @override
  String get moveImageToAttachments => 'نقل إلى المرفقات';

  @override
  String get moveImageToPage => 'وضع في الصفحة';

  @override
  String get attachmentCopied => 'نُسخ المرفق';

  @override
  String get pasteAttachment => 'لصق المرفق المنسوخ';

  @override
  String get fullscreen => 'ملء الشاشة';

  @override
  String get more => 'المزيد';

  @override
  String get undone => 'تم التراجع';

  @override
  String get filterOthers => 'أخرى';

  @override
  String get chatSuggestion1 => 'ما المفقود من قائمة تسوقي؟';

  @override
  String get chatSuggestion2 => 'لخص ملاحظات العمل لهذا الأسبوع';

  @override
  String get chatSuggestion3 => 'هل لدي تذكير للغد؟';

  @override
  String get aiPointsToday => 'نقاط اليوم';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'تتجدد عند منتصف الليل';

  @override
  String get aiChatWithNotes => 'مساعد الملاحظات';

  @override
  String get aiChatInputHint => 'اسأل شيئاً عن ملاحظاتك…';

  @override
  String get aiChatLooking => 'أبحث في ملاحظاتك…';

  @override
  String get aiChatFullScreen => 'ملء الشاشة';

  @override
  String get aiOnYourNotes => 'في ملاحظاتك';

  @override
  String get aiTaskDuplicates => 'تنظيف التكرارات';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count ملاحظات مكررة';
  }

  @override
  String get duplicatesTitle => 'الملاحظات المكررة';

  @override
  String get duplicatesHint =>
      'يتم الاحتفاظ بأقدم ملاحظة في كل مجموعة، وتنتقل البقية إلى سلة المهملات.';

  @override
  String get duplicatesKeepBadge => 'محفوظة';

  @override
  String get duplicatesDeleteAll => 'نقل التكرارات إلى سلة المهملات';

  @override
  String duplicatesDone(int count) {
    return 'تم نقل $count من التكرارات إلى سلة المهملات';
  }

  @override
  String get aiRecentActions => 'الإجراءات الأخيرة';

  @override
  String get aiHistoryClear => 'مسح';

  @override
  String get aiHistoryQuestion => 'سؤال';

  @override
  String get aiHistoryNoteAction => 'إجراء على الملاحظة';

  @override
  String get aiHistoryVoiceNote => 'ملاحظة صوتية';

  @override
  String get aiRecentOps => 'الأحدث';

  @override
  String get aiTaskWeekSummary => 'لخص الأسبوع';

  @override
  String get aiTaskWeekSummaryInfo => 'ملخص واحد من آخر 7 أيام';

  @override
  String get aiTaskTagUntagged => 'أضف وسوماً للملاحظات غير المصنفة';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count ملاحظة تنتظر التصنيف';
  }

  @override
  String get aiTaskSuggestTitles => 'اقترح عناوين';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count ملاحظة بدون عنوان';
  }

  @override
  String get sectionPinnedShort => 'مثبتة';

  @override
  String get sectionToday => 'اليوم';

  @override
  String get sectionThisWeek => 'هذا الأسبوع';

  @override
  String get sectionEarlier => 'سابقاً';

  @override
  String sectionNoteCount(int count) {
    return '$count ملاحظة';
  }

  @override
  String get emptySearchSemanticHint => 'جرب تبويب المعنى';

  @override
  String get quickCaptureHint => 'ملاحظة جديدة…';

  @override
  String get quickCaptureSave => 'حفظ';

  @override
  String get quickAddWrite => 'كتابة';

  @override
  String get quickAddCapture => 'التقاط — إنشاء ملاحظة من المحتوى';

  @override
  String get viewToggle => 'عرض';

  @override
  String get searchModeText => 'نص';

  @override
  String get searchModeMeaning => 'المعنى';

  @override
  String get filterReminded => 'مع تذكير';

  @override
  String get filterLocked => 'مقفل';

  @override
  String get sortColor => 'اللون';

  @override
  String get filterSheetTitle => 'تصفية';

  @override
  String get filterReset => 'إعادة تعيين';

  @override
  String get filterSectionStatus => 'الحالة';

  @override
  String get filterSectionFolder => 'المجلد';

  @override
  String get filterSectionTag => 'الوسم';

  @override
  String get filterSectionSort => 'الترتيب';

  @override
  String get filterFavoriteHint =>
      'اضغط على النجمة لإبقاء الخيار في الشاشة الرئيسية';

  @override
  String get filterSheetSortHint =>
      'تظهر مجموعات التاريخ (اليوم، هذا الأسبوع...) فقط عند الترتيب حسب آخر تعديل.';

  @override
  String get formatTitle => 'التنسيق';

  @override
  String get formatBold => 'عريض';

  @override
  String get formatItalic => 'مائل';

  @override
  String get formatUnderline => 'تسطير';

  @override
  String get formatTextColor => 'لون النص';

  @override
  String get formatHighlight => 'تظليل';

  @override
  String get formatInfo =>
      'ينتقل التنسيق داخل النص على هيئة علامات (مثل **عريض**)؛ وتبقى هذه العلامات مخفية في الملفات المصدَّرة وفي القراءة الصوتية.';

  @override
  String get formatMenu => 'التنسيق…';

  @override
  String get noteFont => 'الخط';

  @override
  String get noteFontDefault => 'افتراضي';

  @override
  String get noteFontSerif => 'كتابي (بذيول)';

  @override
  String get noteFontMono => 'آلة كاتبة';

  @override
  String get noteTextSize => 'حجم النص';

  @override
  String get formatClear => 'مسح التنسيق';

  @override
  String get noteTextOpacity => 'العتامة';

  @override
  String get assistantVoiceSetting => 'المساعد ينطق الردود';

  @override
  String get assistantVoiceSettingInfo =>
      'يقرأ المساعد الصوتي ردّه بصوت عالٍ (على الهاتف فقط).';

  @override
  String get assistantMute => 'كتم الصوت';

  @override
  String get assistantUnmute => 'إلغاء الكتم';

  @override
  String get assistantMakeNote => 'اجعلها ملاحظة على أي حال';

  @override
  String get assistantNoteCreated => 'أُنشئت الملاحظة';

  @override
  String get noteNotFound => 'لم يُعثر على الملاحظة. ربما تكون قد حُذفت.';

  @override
  String get back => 'رجوع';

  @override
  String get addTextBlock => 'إضافة نص';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'صورة الخلفية';

  @override
  String get chooseBackgroundImage => 'اختيار صورة';

  @override
  String get changeBackgroundImage => 'تغيير الصورة';

  @override
  String get removeBackgroundImage => 'إزالة الخلفية';

  @override
  String get dashboardBackground => 'خلفية الشاشة الرئيسية';

  @override
  String get dashboardBackgroundInfo =>
      'صورة تظهر خلف شبكة الملاحظات (على هذا الجهاز فقط).';

  @override
  String get aiProvider => 'مزوّد الذكاء الاصطناعي';

  @override
  String get aiProviderInfo =>
      'اختر المزوّد الذي يتبع له مفتاحك. يُحفظ مفتاح كل مزوّد على حدة، فلا يتطلّب الرجوع إليه كتابته من جديد.';

  @override
  String get apiKeyFieldLabel => 'مفتاح API';

  @override
  String get getApiKey => 'من أين أحصل على مفتاح؟';

  @override
  String get recommendedModel => 'موصى به';

  @override
  String get freeTierBadge => 'له خطة مجانية';

  @override
  String get continueWithoutAccount => 'المتابعة بدون حساب';

  @override
  String get localAccountInfo =>
      'تبقى ملاحظاتك على هذا الجهاز فقط: لا يمكن فتحها في مكان آخر، وتضيع إذا أزلت التطبيق، والذكاء الاصطناعي المدمج معطّل. ويمكنك ربط حساب Google في أي وقت — وستنتقل ملاحظاتك معك.';

  @override
  String get localAccountBadge => 'حساب محلي';

  @override
  String get linkGoogleAccount => 'ربط حساب Google';

  @override
  String get accountLinked =>
      'تم ربط حساب Google. أصبحت ملاحظاتك الآن محفوظة احتياطيًا.';

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
      'تسجيل الدخول بدون Google متوقف حاليًا: تسجيل الدخول المجهول غير مُفعَّل في وحدة تحكم Firebase. سجّل الدخول بحساب Google أو أعد المحاولة بعد تفعيله من المشرف.';

  @override
  String get googleSignInUnavailable =>
      'تسجيل الدخول بحساب Google متوقف حاليًا: مزوّد Google غير مُفعَّل في وحدة تحكم Firebase.';

  @override
  String get signInNetworkError =>
      'تعذّر الوصول إلى الإنترنت. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get signInCanceled => 'تم إلغاء تسجيل الدخول.';

  @override
  String get cardRichPreview => 'نص منسّق على البطاقات';

  @override
  String get cardRichPreviewInfo =>
      'تظهر ألوان ملاحظاتك وتظليلها والخط العريض والتسطير على بطاقات الشاشة الرئيسية أيضًا. عند الإيقاف تعرض البطاقات نصًا عاديًا.';

  @override
  String get fontSizeSmall => 'صغير';

  @override
  String get fontSizeMedium => 'متوسط';

  @override
  String get fontSizeLarge => 'كبير';

  @override
  String get fontSizeXLarge => 'كبير جدًا';

  @override
  String get appFontSetting => 'الخط';

  @override
  String get appFontInfo =>
      'الخط المستخدم في كل أنحاء التطبيق. خط الملاحظة نفسها له الأولوية. جميع الخطوط مضمّنة في التطبيق — لا حاجة للإنترنت.';

  @override
  String get fontGroupSans => 'بلا زخارف';

  @override
  String get fontGroupSerif => 'بزخارف';

  @override
  String get fontGroupMono => 'ثابت العرض';

  @override
  String get fontGroupHand => 'خط اليد';

  @override
  String get appFontDefaultSuffix => 'افتراضي';

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
}
