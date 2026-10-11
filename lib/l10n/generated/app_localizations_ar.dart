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
  String get attachmentCopying => 'جارٍ النسخ...';

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
  String get placeReminder => 'Konum hatırlatıcısı';

  @override
  String get placeReminderHint =>
      'Bir yere varınca ya da oradan ayrılınca bu not bildirim olarak gelsin. Konumu sistem izler; uygulama açık olmasa da çalışır.';

  @override
  String get placeCurrent => 'Şu anki konumum';

  @override
  String get placeSearchHint => 'Adres ya da yer ara';

  @override
  String get placeSearchNone => 'Sonuç bulunamadı';

  @override
  String get placeArrive => 'Varınca';

  @override
  String get placeLeave => 'Ayrılınca';

  @override
  String get placeRadius => 'Yarıçap';

  @override
  String get placeSave => 'Hatırlatıcıyı kur';

  @override
  String get placeRemove => 'Konum hatırlatıcısını kaldır';

  @override
  String get placeSet => 'Konum hatırlatıcısı kuruldu';

  @override
  String get placeRemoved => 'Konum hatırlatıcısı kaldırıldı';

  @override
  String get placeNeedPermission =>
      'Konum izni verilmedi. Ayarlardan izin verebilirsin.';

  @override
  String get placeNeedBackground =>
      'Uygulama kapalıyken de çalışması için konum iznini \"Her zaman izin ver\" yapman gerekiyor.';

  @override
  String get placeBackgroundTitle => '\"Her zaman\" izni gerekli';

  @override
  String get placeOpenSettings => 'İzin ver';

  @override
  String get placeLocationOff =>
      'Cihazın konum hizmeti kapalı. Açıp yeniden dene.';

  @override
  String get placeFailed => 'Konum hatırlatıcısı kurulamadı.';

  @override
  String get placeNoLocation =>
      'Konum alınamadı. Konumun açık olduğundan emin ol.';

  @override
  String placeArrivedBody(String place) {
    return '$place konumuna vardın';
  }

  @override
  String placeLeftBody(String place) {
    return '$place konumundan ayrıldın';
  }

  @override
  String placeActive(String place, String trigger) {
    return '$place · $trigger';
  }

  @override
  String get placeSection => 'Konum';

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
  String get aiModelDocument => 'محادثة المستند وملخّص PDF';

  @override
  String get aiModelTranslate => 'الترجمة';

  @override
  String get aiModelVoice => 'مساعد الملاحظة الصوتية';

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
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

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
  String pendingUploads(int count) {
    return '$count ek buluta yükleniyor';
  }

  @override
  String pendingUploadsFailed(int count) {
    return '$count ek yüklenemedi, yeniden denenecek';
  }

  @override
  String get pendingUploadsInfo =>
      'Ekler bu cihazda güvende. Bağlantı olduğunda kendiliğinden yüklenir; o zamana kadar öbür cihazlarınızda görünmez.';

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
  String get imageNotePreparing => 'يجري تجميع الصور في مستند…';

  @override
  String get newImageNote => 'أضف صورة ودوّن الملاحظات';

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
  String get pdfAddBlankPage => 'إضافة صفحة فارغة';

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
  String get inkArrow => 'سهم';

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
  String get sortActive => 'الأكثر استخدامًا';

  @override
  String get voicePreview => 'جرّب الصوت';

  @override
  String get voicePreviewCached =>
      'يُنشأ المقطع مرة واحدة ثم يُشغَّل من التخزين';

  @override
  String get reorderHint =>
      'اضغط مطوّلاً على البطاقة ثم اسحبها إلى المكان الذي تريده';

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
  String get formatHeading => 'Başlık';

  @override
  String get formatHeading1 => 'Büyük başlık';

  @override
  String get formatHeading2 => 'Alt başlık';

  @override
  String get formatNormalText => 'Normal metin';

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
  String get ttsEngineAiUnavailable =>
      'يحتاج صوت الذكاء الاصطناعي إلى مفتاح Gemini الخاص بك. حتى ذلك الحين تتم القراءة بصوت الجهاز.';

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
  String get shareAsText => 'كنص عادي';

  @override
  String get shareAsTextInfo =>
      'يرسل نص الملاحظة وملاحظات الصفحات إلى أي تطبيق.';

  @override
  String get shareAsTextEmpty => 'لا يوجد نص في هذه الملاحظة لمشاركته.';

  @override
  String get sharePdfWithBubbles => 'كملف PDF مع الفقاعات';

  @override
  String get sharePdfWithBubblesInfo =>
      'تُطبع الفقاعات والتظليلات والرسومات داخل ملف PDF؛ يمكن لأي شخص فتحه، وفي تطبيق Not يُفتح قابلاً للتحرير.';

  @override
  String get sharePdfWithBubblesNone =>
      'لا يوجد في هذه الملاحظة ملف PDF يحمل فقاعات أو رسومات.';

  @override
  String get sharePdfWithBubblesPreparing => 'يجري تجهيز ملف PDF مع الفقاعات…';

  @override
  String get sharePdfWithBubblesSuffix => ' (مع الفقاعات)';

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

  @override
  String get captureModeQuestion => 'Notu nasıl açalım?';

  @override
  String get captureModeBubbles => 'Balonlu';

  @override
  String get captureModeBubblesInfo =>
      'İçerik belge sayfası olur: üzerine balon, vurgu ve kalem.';

  @override
  String get captureModeClassic => 'Klasik';

  @override
  String get captureModeClassicInfo =>
      'Düz metin notu; içerik ek olarak girer.';

  @override
  String get captureModeNew => 'YENİ';

  @override
  String get imagePrepareTitle => 'Görselleri düzelt';

  @override
  String get imagePrepareDone => 'Devam';

  @override
  String get imageRotateLeft => 'Sola döndür';

  @override
  String get imageRotateRight => 'Sağa döndür';

  @override
  String get videoFrameFailed =>
      'Videodan kare alınamadı; not klasik açılıyor.';

  @override
  String get bubbleArrowHide => 'Oku gizle';

  @override
  String get bubbleArrowShow => 'Oku göster';

  @override
  String get speechPitch => 'Ses tonu';

  @override
  String get speechVoicePickerTitle => 'Ses seçimi';

  @override
  String get formatRemove => 'إزالة';

  @override
  String get exportTitle => 'تصدير';

  @override
  String get exportNotesOption => 'نص الملاحظة (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'نص الملاحظة وصورها؛ الفقاعات غير مضمّنة.';

  @override
  String get captureNoteTitle => 'عنوان الملاحظة (اختياري)';

  @override
  String get captureNoteTitleHint => 'سيحمل المستند الجديد الاسم نفسه';

  @override
  String get imageOcrTitle => 'التعرّف على النص في الصورة';

  @override
  String get imageOcrNone => 'لم يُعثر على نص في هذه الصورة.';

  @override
  String imageOcrHint(int count) {
    return 'تم التعرّف على $count سطرًا · اضغط للتحديد';
  }

  @override
  String imageOcrSelected(int count) {
    return 'تم تحديد $count سطرًا';
  }

  @override
  String get imageOcrShort => 'التعرّف على النص';

  @override
  String get imageOcrWorking => 'جارٍ التعرّف على النص…';

  @override
  String get imageOcrSelectHint =>
      'انقر: كلمة · اضغط مطوّلاً واسحب: حرفًا حرفًا';

  @override
  String get imageOcrInsert => 'إضافة إلى الملاحظة';

  @override
  String get imageOcrZoomIn => 'تكبير';

  @override
  String get imageOcrZoomOut => 'تصغير';

  @override
  String get selectImages => 'تحديد الصور';

  @override
  String get exportImages => 'الصور';

  @override
  String get exportImagesInfo =>
      'يلتفّ النص حول الصور الضيّقة المحاذاة يمينًا أو يسارًا؛ أما المتوسّطة فتأخذ العرض كاملاً.';

  @override
  String get exportAlignLeft => 'يسار';

  @override
  String get exportAlignCenter => 'وسط';

  @override
  String get exportAlignRight => 'يمين';

  @override
  String get exportImageWidth => 'العرض';

  @override
  String get exportImageLine => 'الموضع';

  @override
  String get aiModelSearch => 'البحث عن نموذج';

  @override
  String get aiModelOthers => 'نماذج أخرى';

  @override
  String get aiModelNoMatch => 'لا يوجد نموذج مطابق.';

  @override
  String get aiModelAutoInfo => 'يجرّب التطبيق أنسب النماذج بالترتيب.';

  @override
  String imageOcrCharsSelected(int count) {
    return 'تم تحديد $count حرفًا';
  }

  @override
  String imagesSelectedCount(int count) {
    return 'تم تحديد $count صورة';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count مرفقات';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count سطرًا';
  }

  @override
  String get aiModelShowAll => 'إظهار الكل';

  @override
  String get aiModelShowAllInfo =>
      'يعرض أيضًا النماذج التي لا يستخدمها التطبيق.';

  @override
  String get rotateFailed => 'Görsel döndürülemedi.';

  @override
  String get dashboardBackgroundPick => 'Zemin görseli seç';

  @override
  String get dashboardBackgroundChange => 'Zemin görselini değiştir';

  @override
  String podcastRenderingAudio(int done, int total) {
    return 'Ses hazırlanıyor: $done/$total parça';
  }

  @override
  String get podcastExportAudio => 'Ses dosyası olarak dışa aktar';

  @override
  String get podcastExportAudioCost =>
      'Metnin tamamı yapay zekâ sesiyle yeniden seslendirilip tek bir WAV dosyası olarak hazırlanır. Bu işlem Gemini kotandan düşer ve uzun metinlerde birkaç dakika sürebilir.';

  @override
  String get podcastShareText => 'Metni paylaş';

  @override
  String get podcastSaveAsNote => 'Yeni not olarak kaydet';

  @override
  String get podcastSavedAsNote => 'Podcast metni not olarak kaydedildi.';

  @override
  String get listenPreparingVoice => 'Ses hazırlanıyor…';

  @override
  String get appearancePreviewTitle => 'Örnek metin';

  @override
  String get appearancePreviewNoteTitle => 'Örnek not başlığı';

  @override
  String get appearancePreviewBody =>
      'Notların bu yazı tipi ve boyutta görünecek. Satır içi **kalın**, ~altı çizili~ ve ==2:vurgulu== metinler de böyle durur.';

  @override
  String get appearancePreviewItem => 'Liste maddesi böyle görünür';

  @override
  String get convertToText => 'Metne dönüştür';

  @override
  String get convertToList => 'Listeye dönüştür';

  @override
  String get convertedToText => 'Liste düz metne dönüştürüldü.';

  @override
  String get convertedToList => 'Metin listeye dönüştürüldü.';

  @override
  String get convertToListEmpty => 'Listeye dönüştürülecek satır yok.';

  @override
  String get listTwoColumns => '2 sütun';

  @override
  String get listOneColumn => 'Tek sütun';

  @override
  String get sortItems => 'Maddeleri sırala';

  @override
  String get sortStarredFirst => 'Önce yıldızlılar';

  @override
  String get sortUncheckedFirst => 'Tamamlananlar sona';

  @override
  String get sortAlphabetical => 'A → Z';

  @override
  String get sortAlphabeticalDesc => 'Z → A';

  @override
  String get imagesToAttachments => 'Görselleri eke dönüştür';

  @override
  String imagesToAttachmentsDone(int count) {
    return '$count görsel eke dönüştürüldü.';
  }

  @override
  String get imageOcrShowRecognized => 'Tanınan metni vurgula';

  @override
  String get imageOcrHideRecognized => 'Vurguyu kaldır';

  @override
  String get bubblePlainMode => 'Açık metin alanı';

  @override
  String get bubblePlainModeOn => 'Açık metin alanı açık';

  @override
  String get bubblePlainTapToPlace => 'Metnin geleceği yere dokun';

  @override
  String get bubblePlainHint => 'Yazmak için dokun';

  @override
  String get noteSearchTitle => 'Notta ara';

  @override
  String get noteSearchHint => 'Bu notta ara…';

  @override
  String get noteSearchEmptyHint =>
      'Notun metninde, maddelerinde ve sayfa notlarında anında arar. Ek görsellerin ve PDF\'lerin içi için aşağıdaki taramayı başlat.';

  @override
  String get noteSearchNoHit => 'Eşleşme bulunamadı.';

  @override
  String get noteSearchScanAttachments => 'Ekleri tara';

  @override
  String get noteSearchAskAi => 'Yapay zekâya sor';

  @override
  String get noteTitleLabel => 'Başlık';

  @override
  String get noteBodyLabel => 'Not metni';

  @override
  String get itemLabel => 'Madde';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return '$count ek taranabilir (görsel/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return '$count ekin içi de aranıyor.';
  }

  @override
  String pageLabel(int page) {
    return 'Sayfa $page';
  }

  @override
  String get archiveNotebook => 'Arşiv defteri';

  @override
  String get archiveNotebookInfo =>
      'Önemli belgeleri ve görselleri kopyasıyla toplayan, kendi sayfaları olan defter.';

  @override
  String get archivePageImages => 'Görseller';

  @override
  String get archivePageVideos => 'Videolar';

  @override
  String get archivePageDocuments => 'Belgeler';

  @override
  String get archivePageTexts => 'Metinler';

  @override
  String get archiveNewPage => 'Yeni sayfa';

  @override
  String get archiveTemplateTitle => 'Sayfa şablonu';

  @override
  String get archiveTemplateBlank => 'Boş sayfa';

  @override
  String get archiveTemplateJournal => 'Günlük';

  @override
  String get archiveTemplateMeeting => 'Toplantı';

  @override
  String get archiveTemplateExpense => 'Harcamalar';

  @override
  String get archiveTemplateTodo => 'Yapılacaklar';

  @override
  String get archiveTemplateReading => 'Okuma notu';

  @override
  String get tplJournalHow => 'Bugün nasıldı?';

  @override
  String get tplJournalGrateful => 'Minnettar olduklarım';

  @override
  String get tplJournalTomorrow => 'Yarın için';

  @override
  String get tplMeetingAttendees => 'Katılımcılar';

  @override
  String get tplMeetingAgenda => 'Gündem';

  @override
  String get tplMeetingDecisions => 'Kararlar';

  @override
  String get tplMeetingActions => 'Kim, ne, ne zaman';

  @override
  String get tplExpenseColumns => 'Tarih · Açıklama · Tutar';

  @override
  String get tplExpenseTotal => 'Toplam:';

  @override
  String get tplReadingSource => 'Kaynak';

  @override
  String get tplReadingSummary => 'Özet';

  @override
  String get tplReadingQuotes => 'Alıntılar';

  @override
  String get tplReadingThoughts => 'Düşüncelerim';

  @override
  String get archiveGeneralPage => 'Genel';

  @override
  String get archiveRenamePage => 'Sayfayı yeniden adlandır';

  @override
  String get archiveDeletePage => 'Sayfayı sil';

  @override
  String archiveDeletePageInfo(String name) {
    return '\"$name\" sayfası silinsin mi? İçindeki girdiler silinmez, Genel sayfasına taşınır.';
  }

  @override
  String get archivePrevPage => 'Önceki sayfa';

  @override
  String get archiveNextPage => 'Sonraki sayfa';

  @override
  String get archiveAddEntry => 'Sayfaya ekle';

  @override
  String get archiveMoveEntry => 'Başka sayfaya taşı';

  @override
  String archiveEntryCount(int count) {
    return '$count girdi';
  }

  @override
  String get archivePageName => 'Sayfa adı (ör. Faturalar)';

  @override
  String get archivePageEmpty => 'Boş sayfa';

  @override
  String get archiveSearchHint => 'Defterde ara…';

  @override
  String get archiveAddText => 'Metin ekle';

  @override
  String get archiveAddFile => 'Dosya ekle';

  @override
  String get archiveCopyHere => 'Arşiv defterine kopyala';

  @override
  String get archiveNoNotebook =>
      'Henüz arşiv defteri yok. Önce bir tane oluştur.';

  @override
  String get archiveNothingToCopy => 'Bu notta kopyalanacak ek yok.';

  @override
  String archiveDeleteEntry(String name) {
    return '\"$name\" defterden silinsin mi? Bu kopya kalıcı olarak gider.';
  }

  @override
  String archiveCopied(int count) {
    return '$count dosya arşiv defterine kopyalandı.';
  }

  @override
  String get archiveCaptureTitle => 'Görselden yakala';

  @override
  String get archiveCapturePage => 'Sayfa';

  @override
  String get archiveCapturePageInfo =>
      'Yapay zekânın önerdiği sayfa. Boş bırakılırsa Genel sayfasına düşer.';

  @override
  String get archiveCaptureText => 'Tanınan metin';

  @override
  String get attachmentTagInsert => 'Metne ekle';

  @override
  String get attachmentTagInserted => 'Ek etiketi metne eklendi.';

  @override
  String get attachmentTagPreview => 'Eki önizle';

  @override
  String get attachmentTagEdit => 'Eki düzenle';

  @override
  String archiveCardSummary(int files, int texts) {
    return '$files dosya · $texts metin';
  }

  @override
  String get archivePlaceOnPage => 'Sayfaya yerleştir';

  @override
  String get archivePaper => 'Kâğıt';

  @override
  String get archivePaperLined => 'Çizgili';

  @override
  String get archivePaperGrid => 'Kareli';

  @override
  String get archivePaperDots => 'Noktalı';

  @override
  String get archivePaperPlain => 'Düz';

  @override
  String get archiveWriteHint => 'Bu sayfaya yaz…';

  @override
  String get archivePageTitleHint => 'Sayfa adı';

  @override
  String archiveAutoPageName(int number) {
    return 'Sayfa $number';
  }

  @override
  String get archiveNewPageHint =>
      'Yazmaya başla ya da bir şey ekle — sayfa kendiliğinden açılır.';

  @override
  String get archiveNewPageLabel => 'Yeni sayfa';

  @override
  String get archiveAttachmentsHeading => 'Bu sayfadaki dosyalar';

  @override
  String get archiveNotesHeading => 'Notlar';

  @override
  String get archiveOpenPage => 'Sayfaya git';

  @override
  String get archiveEntryTitle => 'Başlık';

  @override
  String get archiveLinkedFile => 'Bağlı dosya';

  @override
  String get archiveNoLink => 'Bağlı dosya yok';

  @override
  String get attachmentTagEmbed => 'Seçili yazıya ek göm';

  @override
  String get attachmentTagNoAttachment =>
      'Önce nota bir dosya ekle; sonra yazıya gömebilirsin.';

  @override
  String get bubbleModeBubble => 'Balon';

  @override
  String get attachmentTagEmbedInfo =>
      'Yazıyı seçtiysen o yazıya, seçmediysen imlecin yerine bağlanır';

  @override
  String get attachmentTagPickText =>
      'Şimdi bağlanacak yazıyı seç, sonra \"Buraya bağla\"ya dokun.';

  @override
  String get attachmentTagLinkHere => 'Buraya bağla';

  @override
  String attachmentTagPendingBanner(String name) {
    return '$name bağlanacak — yazıyı seç';
  }

  @override
  String get docNameNotesSuffix => 'notlar';

  @override
  String get docNamePhoto => 'Fotoğraf notları';

  @override
  String get docNameScan => 'Tarama notları';

  @override
  String get docNameImage => 'Görsel notları';

  @override
  String get docNameVideo => 'Görüntü notları';

  @override
  String get folderManage => 'Klasörü yönet';

  @override
  String get folderEmpty => 'Bu klasör boş';

  @override
  String folderNoteCount(int count) {
    return '$count not';
  }

  @override
  String get folderEmptyHint =>
      'Aşağıdaki + ile buraya not ekle ya da bir notu düzenlerken bu klasöre taşı.';

  @override
  String get brainstormTitle => 'AI ile beraber düşün';

  @override
  String get brainstormRowInfo =>
      'AI önce bir ana hat çıkarır, sonra birlikte geliştirirsiniz';

  @override
  String get brainstormIntro =>
      'Yukarıdaki başlıklardan birine dokun ya da doğrudan yaz — birlikte düşünmeye başlayalım.';

  @override
  String get brainstormOutlineTitle => 'ANA HAT';

  @override
  String get brainstormInputHint => 'Bir fikir yaz ya da soru sor…';

  @override
  String get brainstormAddIdea => 'Nota ekle';

  @override
  String get brainstormAdded => 'Nota eklendi';

  @override
  String get folderShared => 'Bu klasör bir arkadaşınla ortak';

  @override
  String get friendsTitle => 'Kişiler';

  @override
  String get friendsAdd => 'Arkadaş ekle';

  @override
  String get friendsEmpty =>
      'Henüz kimse yok. E-postayla bir arkadaş ekle, klasörlerini onunla paylaş.';

  @override
  String get friendsRequestsTitle => 'İSTEKLER';

  @override
  String get friendsListTitle => 'ARKADAŞLARIM';

  @override
  String get friendsAddEmailHint => 'arkadas@eposta.com';

  @override
  String get friendsSendRequest => 'İstek gönder';

  @override
  String get friendsRequestSent => 'İstek gönderildi';

  @override
  String get friendsNotFound =>
      'Bu e-postayla kayıtlı bir kullanıcı bulunamadı. Kişinin uygulamayı Google hesabıyla en az bir kez açmış olması gerekir.';

  @override
  String get friendsSelf => 'Kendini arkadaş ekleyemezsin';

  @override
  String get friendsAlready => 'Zaten arkadaşsınız';

  @override
  String get friendsDecline => 'Reddet';

  @override
  String get friendsAccept => 'Kabul et';

  @override
  String get friendsRemove => 'Kaldır';

  @override
  String get friendsRemoveConfirmTitle => 'Arkadaşlıktan çıkar';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return '$name arkadaş listenden kaldırılsın mı? Onunla paylaştığın klasörler artık görünmez.';
  }

  @override
  String get friendsNeedsAccount =>
      'Kişiler ve klasör paylaşımı Google hesabı bağlı kullanıcılarda çalışır.';

  @override
  String get friendsSearchHint => 'İsim veya e-posta ile ara';

  @override
  String get friendsSearchTab => 'Ara';

  @override
  String get friendsSearchEmailTab => 'E-posta ile';

  @override
  String get friendsSearchEmpty => 'Sonuç yok';

  @override
  String get friendsSearchTooShort => 'Aramak için en az 2 karakter yaz';

  @override
  String get friendsSearchAdd => 'Ekle';

  @override
  String get folderShare => 'Paylaş';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişiyle paylaşıldı',
      one: '1 kişiyle paylaşıldı',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return '\"$name\" klasörünü paylaş';
  }

  @override
  String get folderShareInfo =>
      'Seçtiğin arkadaşa davet gider; kabul edince klasörü görür. Yetkiyi (okuma / yazma / her ikisi) sen belirlersin.';

  @override
  String get friendsRowInfo => 'Arkadaş ekle, klasörlerini onlarla paylaş';

  @override
  String get accountRecoverConflictTitle =>
      'Bu cihazda kaydedilmemiş notlar var';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'Bu Google hesabı zaten başka bir oturuma bağlı; ona geçersen bu cihazdaki $count not artık görünmeyecek (silinmezler ama bu ekrandan erişilemezler). Yine de geçmek istiyor musun?';
  }

  @override
  String get accountRecoverConflictProceed => 'Yine de geç';

  @override
  String get folderRoleRead => 'Okuma';

  @override
  String get folderRoleWrite => 'Yazma';

  @override
  String get folderRoleBoth => 'Okuma + yazma';

  @override
  String get folderInvitePending => 'Davet gönderildi, yanıt bekleniyor';

  @override
  String get folderWriteOnlyTitle => 'Yalnız yazma yetkin var';

  @override
  String get folderWriteOnlyHint =>
      'Bu klasöre yeni not ekleyebilirsin ama içindeki notları göremezsin.';

  @override
  String get folderChatTitle => 'Sohbet';

  @override
  String get folderChatHint => 'Mesaj yaz…';

  @override
  String get folderChatSend => 'Gönder';

  @override
  String get folderChatEmptyTitle => 'Henüz mesaj yok';

  @override
  String get folderChatEmptyHint =>
      'Bu klasörü paylaştığın kişilerle burada yazışabilirsin.';

  @override
  String get folderInviteTitle => 'Klasör daveti';

  @override
  String folderInviteBody(Object name) {
    return '\"$name\" klasörü seninle paylaşıldı.';
  }

  @override
  String get folderInviteAccepted => 'Klasör eklendi';

  @override
  String get folderInviteDeclined => 'Davet reddedildi';

  @override
  String friendRequestBanner(Object name) {
    return '$name sana arkadaşlık isteği gönderdi';
  }

  @override
  String get friendRequestAccepted => 'Arkadaş eklendi';

  @override
  String get sendNoteAction => 'Arkadaşa gönder';

  @override
  String get sendNoteTitle => 'Notu arkadaşına gönder';

  @override
  String get sendNoteInfo =>
      'Notun bir kopyası seçtiğin kişinin \"Gelen notlar\" kutusuna düşer. Ekler (görsel, belge, ses) gönderilmez.';

  @override
  String sendNoteSent(Object name) {
    return 'Not $name kişisine gönderildi';
  }

  @override
  String get inboxTitle => 'Gelen notlar';

  @override
  String get inboxEmpty => 'Gelen not yok';

  @override
  String get inboxEmptyHint =>
      'Arkadaşlarının sana gönderdiği notlar burada birikir.';

  @override
  String inboxFrom(Object name) {
    return '$name gönderdi';
  }

  @override
  String get inboxAccept => 'Notlarıma ekle';

  @override
  String get inboxAccepted => 'Not notlarına eklendi';

  @override
  String get folderShelfExpand => 'Klasörleri büyüt';

  @override
  String get folderShelfCollapse => 'Klasörleri daralt';

  @override
  String get accountSheetLocalInfo =>
      'Notların yalnız bu cihazda. Google hesabı bağlarsan yedeklenir ve arkadaş ekleyebilirsin.';

  @override
  String get accountSettings => 'Hesap ayarları';

  @override
  String get videoFramesExtracting => 'Videodan kareler alınıyor…';

  @override
  String get areaSelect => 'Alan seç';

  @override
  String get areaSelectOff => 'Alan seçimini kapat';

  @override
  String get areaSelectHint =>
      'Kopyalamak ya da yapay zekâya sormak istediğin alanı parmağınla çiz.';

  @override
  String get areaCopyImage => 'Görsel olarak kopyala';

  @override
  String get areaCopied => 'Seçilen alan panoya kopyalandı.';

  @override
  String get areaAskAi => 'Yapay zekâya sor';

  @override
  String get areaAskTitle => 'Seçilen alan';

  @override
  String get areaAskHint =>
      'İstersen bir soru yaz (boş bırakırsan formülü/metni çıkarıp açıklar).';

  @override
  String get areaAskRun => 'Sor';

  @override
  String get areaCaptureFailed => 'Seçilen alanın görüntüsü alınamadı.';

  @override
  String get areaTooSmall => 'Seçilen alan çok küçük.';

  @override
  String get areaAddToNote => 'Nota ekle';

  @override
  String get bubbleTextFill => 'Yazı zemini';

  @override
  String get bubbleTextFillNone => 'Zeminsiz';

  @override
  String get bubbleTextAlignLeft => 'Sola hizala';

  @override
  String get bubbleTextAlignCenter => 'Ortala';

  @override
  String get bubbleTextAlignRight => 'Sağa hizala';

  @override
  String get dashboardBackgroundPattern => 'Desen';

  @override
  String get dashboardBackgroundColor => 'Zemin rengi';

  @override
  String get dashboardBackgroundImageSection => 'Zemin görseli';

  @override
  String get dashboardBackgroundReset => 'Varsayılana dön';

  @override
  String get patternNone => 'Düz';

  @override
  String get patternDots => 'Noktalı';

  @override
  String get patternGrid => 'Kareli';

  @override
  String get patternLines => 'Çizgili';

  @override
  String get patternDiagonal => 'Çapraz';

  @override
  String get patternGraph => 'Milimetrik';

  @override
  String get archivePagesOverview => 'Sayfalar';

  @override
  String get archiveSemanticHint => 'Defterde anlamıyla ara…';

  @override
  String get semanticUnavailable =>
      'Anlamsal arama şu an kullanılamıyor; metin araması gösteriliyor.';

  @override
  String get sharedNotifications => 'Paylaşılan klasör bildirimleri';

  @override
  String get sharedNotificationsInfo =>
      'Karşı taraf not eklediğinde/değiştirdiğinde ya da sohbete yazdığında telefona bildirim gelsin. Kapalıyken ana ekrandaki sayaç yine çalışır.';

  @override
  String get copyAsText => 'Metni kopyala';

  @override
  String get searchAttachments => 'Ek içeriğinde de ara';

  @override
  String get searchAttachmentsInfo =>
      'PDF\'lerin metnini ve görsellerdeki yazıyı (OCR) da tarar. Açıldığında cihazdaki ekler bir kez taranır; sonrası önbellekten gelir.';

  @override
  String get selectAll => 'Tümünü seç';

  @override
  String get selectNone => 'Seçimi kaldır';

  @override
  String get duplicateNote => 'Notu çoğalt';

  @override
  String get noteDuplicated => 'Not çoğaltıldı';

  @override
  String notesDuplicatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not çoğaltıldı',
      one: '1 not çoğaltıldı',
    );
    return '$_temp0';
  }

  @override
  String get noteStatsTitle => 'Not istatistikleri';

  @override
  String noteStatsWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kelime',
      one: '1 kelime',
    );
    return '$_temp0';
  }

  @override
  String noteStatsChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count karakter',
      one: '1 karakter',
    );
    return '$_temp0';
  }

  @override
  String noteStatsItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count madde',
      one: '1 madde',
    );
    return '$_temp0';
  }

  @override
  String noteStatsAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek',
      one: '1 ek',
    );
    return '$_temp0';
  }

  @override
  String noteStatsReadTime(int count) {
    return '~$count dk okuma';
  }

  @override
  String get scrollToTop => 'Başa dön';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sonuç',
      one: '1 sonuç',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'Aramayı temizle';

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün sonra kalıcı silinir',
      one: '1 gün sonra kalıcı silinir',
    );
    return '$_temp0';
  }

  @override
  String get trashLastDay => 'Bugün kalıcı silinecek';

  @override
  String get noteRestored => 'Not geri yüklendi';

  @override
  String get restoreAll => 'Hepsini geri yükle';

  @override
  String notesRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not geri yüklendi',
      one: '1 not geri yüklendi',
    );
    return '$_temp0';
  }

  @override
  String get emptyingTrash => 'Çöp boşaltılıyor…';

  @override
  String get reminderRemoved => 'Hatırlatıcı kaldırıldı';

  @override
  String get reminderOverdue => 'Gecikti';

  @override
  String get reminderQuickTonight => 'Bu akşam 18:00';

  @override
  String get reminderQuickTomorrow => 'Yarın 09:00';

  @override
  String get reminderQuickNextWeek => 'Gelecek hafta';

  @override
  String get reminderQuickCustom => 'Tarih seç…';

  @override
  String get reminderQuickTitle => 'Ne zaman hatırlatılsın?';

  @override
  String get reminderSnooze => '1 saat ertele';

  @override
  String get reminderSnoozed => 'Hatırlatıcı ertelendi';

  @override
  String reminderCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatıcı',
      one: '1 hatırlatıcı',
    );
    return '$_temp0';
  }

  @override
  String get relativeJustNow => 'az önce';

  @override
  String relativeInMinutes(int count) {
    return '$count dk sonra';
  }

  @override
  String relativeInHours(int count) {
    return '$count sa sonra';
  }

  @override
  String relativeInDays(int count) {
    return '$count gün sonra';
  }

  @override
  String relativeAgoMinutes(int count) {
    return '$count dk önce';
  }

  @override
  String relativeAgoHours(int count) {
    return '$count sa önce';
  }

  @override
  String relativeAgoDays(int count) {
    return '$count gün önce';
  }

  @override
  String get inboxDeclined => 'Gelen not silindi';

  @override
  String inboxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gelen not',
      one: '1 gelen not',
    );
    return '$_temp0';
  }

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get appVersionCopied => 'Sürüm bilgisi kopyalandı';

  @override
  String notesMovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not taşındı',
      one: '1 not taşındı',
    );
    return '$_temp0';
  }

  @override
  String get mediaPlay => 'Oynat';

  @override
  String get mediaPause => 'Duraklat';

  @override
  String get decrease => 'Azalt';

  @override
  String get increase => 'Artır';

  @override
  String get tagManageTitle => 'Etiketi yönet';

  @override
  String get tagRename => 'Etiketi yeniden adlandır';

  @override
  String get tagRenameHint => 'Yeni etiket adı';

  @override
  String get tagDelete => 'Etiketi sil';

  @override
  String tagDeleteConfirm(String tag) {
    return '\"$tag\" etiketi tüm notlardan kaldırılsın mı? Notlar silinmez.';
  }

  @override
  String get tagRenamed => 'Etiket yeniden adlandırıldı';

  @override
  String get tagDeleted => 'Etiket kaldırıldı';

  @override
  String get tagLongPressHint =>
      'Etikete uzun bas: yeniden adlandır ya da sil.';

  @override
  String get recentSearches => 'Son aramalar';

  @override
  String get clearRecentSearches => 'Geçmişi temizle';

  @override
  String get imagesEqualizeSize => 'Boyutları eşitle';

  @override
  String get imagesFitRow => 'Satıra sığdır';

  @override
  String imagesFitColumns(int count) {
    return '$count sütun';
  }

  @override
  String get imagesFitSingleRow => 'Tek satıra sığdır';

  @override
  String get briefingNotificationTitle => 'Günaydın! ☀️';

  @override
  String get briefingNotificationBody =>
      'Bugünün brifingi hazır — hatırlatıcıların, notların ve önemli e-postaların özeti için dokun.';

  @override
  String get reminderDone => 'Tamamlandı';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateTomorrow => 'Yarın';

  @override
  String get noteDuplicatedNoAttachments =>
      'Kopyalandı — ekler kopyaya taşınmadı';

  @override
  String get pdfGoToPage => 'Sayfaya git';

  @override
  String get pdfThumbnails => 'Sayfalara göz at';

  @override
  String get pdfBookmarks => 'Yer imleri';

  @override
  String get pdfBookmarkAdd => 'Yer imi koy';

  @override
  String get pdfBookmarkRemove => 'Yer imini kaldır';

  @override
  String get pdfNoBookmarks =>
      'Henüz yer imi yok. Sayfa çubuğundaki yer imi düğmesine dokunun.';

  @override
  String get pdfRotateView => 'Görünümü döndür';

  @override
  String get pdfCopyPageText => 'Sayfa metnini kopyala';

  @override
  String get pdfCapturePage => 'Sayfayı yakala (yapay zekâ / kopyala)';

  @override
  String get pdfSlideshow => 'Otomatik geçiş';

  @override
  String get pdfSlideshowStop => 'Otomatik geçişi durdur';

  @override
  String get pdfFirstPage => 'İlk sayfa';

  @override
  String get pdfLastPage => 'Son sayfa';

  @override
  String get pdfPlaceOnPage => 'PDF\'i sayfaya yerleştir';

  @override
  String get collaborators => 'المتعاونون';

  @override
  String get collaboratorsInfo =>
      'يرى الأشخاص الذين تضيفهم هذه الملاحظة على شاشتهم الرئيسية ويحررونها معك مباشرة.';

  @override
  String get collaboratorsOwner => 'المالك';

  @override
  String get collaboratorsFriendsTitle => 'أصدقاؤك';

  @override
  String get collaboratorsLeave => 'مغادرة الملاحظة المشتركة';

  @override
  String get collaboratorsLeaveConfirm =>
      'لن تظهر هذه الملاحظة على شاشتك الرئيسية بعد الآن. هل تريد المغادرة؟';

  @override
  String get collaboratorsSaved => 'تم تحديث المشاركة';

  @override
  String collaboratorsCount(int count) {
    return 'تمت المشاركة مع $count أشخاص';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'يمكن لمالك الملاحظة فقط تغيير المتعاونين.';

  @override
  String get sharedWithMe => 'تمت مشاركتها معي';

  @override
  String get sharedWithMeEmpty =>
      'لم تتم مشاركة أي ملاحظات معك بعد. ستظهر هنا عندما يضيفك أحد إلى ملاحظة.';

  @override
  String sharedByName(Object name) {
    return 'شاركها $name';
  }

  @override
  String get navNotes => 'الملاحظات';

  @override
  String get railExpand => 'توسيع القائمة';

  @override
  String get railCollapse => 'طي القائمة';

  @override
  String get newNoteShort => 'ملاحظة جديدة';

  @override
  String get newChecklistShort => 'قائمة جديدة';

  @override
  String get listPaneHide => 'إخفاء قائمة الملاحظات';

  @override
  String get listPaneShow => 'إظهار قائمة الملاحظات';

  @override
  String get keyboardShortcuts => 'اختصارات لوحة المفاتيح';

  @override
  String get shortcutSearch => 'البحث في الملاحظات';

  @override
  String get shortcutToggleList => 'إخفاء / إظهار قائمة الملاحظات';

  @override
  String get shortcutSections => 'التنقل بين الأقسام';

  @override
  String get shortcutHelp => 'عرض الاختصارات';

  @override
  String get noNoteSelectedHint => 'أو ابدأ ملاحظة جديدة';

  @override
  String get loginFeatureSyncTitle => 'الملاحظات نفسها على كل جهاز';

  @override
  String get loginFeatureSyncBody =>
      'مزامنة فورية بين الهاتف والجهاز اللوحي والكمبيوتر والويب.';

  @override
  String get loginFeatureAiTitle => 'الذكاء الاصطناعي بجانبك';

  @override
  String get loginFeatureAiBody => 'لخّص واسأل وأملِ؛ وتحدث مع مستنداتك.';

  @override
  String get loginFeatureShareTitle => 'اكتبوا معًا';

  @override
  String get loginFeatureShareBody =>
      'شارك الملاحظات والمجلدات مع أصدقائك مباشرة.';

  @override
  String get loginFeatureInkTitle => 'القلم وPDF';

  @override
  String get loginFeatureInkBody =>
      'دوّن بخط اليد واكتب على ملفات PDF والشرائح.';

  @override
  String get foldersTitle => 'المجلدات';

  @override
  String get foldersEmpty => 'لا توجد مجلدات بعد. أنشئ مجلدًا لتنظيم ملاحظاتك.';

  @override
  String get folderColor => 'اللون';

  @override
  String get folderColorAuto => 'تلقائي';

  @override
  String get foldersMine => 'مجلداتي';

  @override
  String get foldersSharedSection => 'مجلدات تمت مشاركتها معي';

  @override
  String trashDaysShort(int count) {
    return '$count يوم';
  }

  @override
  String get trashTodayShort => 'اليوم';

  @override
  String get trashSoonSection => 'سيتم حذفها نهائيًا قريبًا';

  @override
  String get trashRestSection => 'ملاحظات محذوفة أخرى';

  @override
  String get aiHubTagline => 'اسأل ولخّص ونظّم ملاحظاتك.';

  @override
  String get aiToolsSection => 'الأدوات';

  @override
  String get folderOrderTitle => 'ترتيب المجلدات';

  @override
  String get folderReorder => 'إعادة ترتيب المجلدات';

  @override
  String get folderOrderManual => 'مخصص';

  @override
  String get folderOrderName => 'حسب الاسم';

  @override
  String get folderOrderNewest => 'الأحدث أولاً';

  @override
  String get folderOrderNoteCount => 'حسب عدد الملاحظات';

  @override
  String get folderOrderHint =>
      'اسحب المقابض لإعادة الترتيب. يُستخدم الترتيب نفسه في شريط المجلدات وعند السحب.';

  @override
  String get swipeModeTitle => 'السحب في الشاشة الرئيسية';

  @override
  String get swipeModeFolders => 'التنقل بين المجلدات';

  @override
  String get swipeModeFilters => 'التنقل بين الفلاتر والوسوم';

  @override
  String get swipeModeBoth => 'المجلدات والفلاتر والوسوم';

  @override
  String get swipeModeOff => 'إيقاف';

  @override
  String get shareIncludeTitle => 'العنوان';

  @override
  String get shareIncludeChecked => 'العناصر المكتملة';

  @override
  String get shareIncludeTags => 'الوسوم';

  @override
  String get shareTextAction => 'مشاركة النص';

  @override
  String get shareAsFileSection => 'كملف';

  @override
  String get shareInAppSection => 'داخل التطبيق';

  @override
  String get shareSendFriendInfo => 'يضع نسخة من الملاحظة في صندوق وارد صديقك.';

  @override
  String get shareCollaborateInfo =>
      'حرّر الملاحظة نفسها مع أصدقائك؛ تظهر التغييرات فورًا.';

  @override
  String get findPrevious => 'التطابق السابق';

  @override
  String get findNext => 'التطابق التالي';

  @override
  String get findShowAll => 'كل التطابقات';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تطابق',
      zero: 'لا توجد تطابقات',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'البحث في المرفقات وبالذكاء الاصطناعي';

  @override
  String get notesSettingsTitle => 'الملاحظات والمجلدات';

  @override
  String get noteViewSetting => 'تخطيط الشاشة الرئيسية';

  @override
  String get noteViewGrid => 'شبكة';

  @override
  String get noteViewList => 'قائمة';

  @override
  String get gridColumnsSetting => 'الأعمدة';

  @override
  String get gridColumnsInfo =>
      'يمكنك تغييره أيضًا بالقرص على الشاشة الرئيسية.';

  @override
  String get gridColumnsAuto => 'تلقائي';

  @override
  String get folderShelfSetting => 'المجلدات في الشاشة الرئيسية';

  @override
  String get folderShelfStrip => 'صف واحد';

  @override
  String get folderShelfTiles => 'مربعات';

  @override
  String get deviceStorageTitle => 'على هذا الجهاز';

  @override
  String get deviceStorageAttachments => 'المرفقات';

  @override
  String get deviceStorageDatabase => 'نسخة محلية من الملاحظات';

  @override
  String get deviceStorageCache => 'ذاكرة التخزين المؤقت والملفات المؤقتة';

  @override
  String get deviceStorageAi => 'ذاكرة الذكاء الاصطناعي المؤقتة';

  @override
  String get deviceStorageTotal => 'الإجمالي (دون التطبيق نفسه)';

  @override
  String get deviceStorageInfo =>
      'مسح الذاكرة المؤقتة لا يحذف الملاحظات أو المرفقات؛ تُنزَّل الصور مجددًا عند الحاجة. تُنظَّف الملفات المؤقتة القديمة عند كل تشغيل.';

  @override
  String get deviceStorageClear => 'مسح الذاكرة المؤقتة';

  @override
  String deviceStorageCleared(String size) {
    return 'تم تحرير $size';
  }

  @override
  String get deviceStorageUnavailable => 'تعذّر القياس على هذا الجهاز.';

  @override
  String get localOnlyTurnOn => 'إيقاف المزامنة';

  @override
  String get localOnlyTurnOff => 'مزامنة هذه الملاحظة';

  @override
  String get localOnlyBadge => 'على هذا الجهاز فقط';

  @override
  String get localOnlyConfirmTitle =>
      'الاحتفاظ بهذه الملاحظة على هذا الجهاز فقط؟';

  @override
  String get localOnlyConfirmBody =>
      'ستُحذف الملاحظة ومرفقاتها من السحابة ولن تظهر على أجهزتك الأخرى. إذا حذفت التطبيق أو غيّرت هاتفك فستضيع هذه الملاحظة أيضًا. يمكنك إعادة تشغيل المزامنة في أي وقت.';

  @override
  String get localOnlyConfirm => 'إيقاف';

  @override
  String get localOnlyOnDone => 'الملاحظة الآن على هذا الجهاز فقط';

  @override
  String get localOnlyOffDone => 'تتم مزامنة الملاحظة مجددًا';

  @override
  String get localOnlySharedBlocked => 'لا يمكن إيقاف مزامنة ملاحظة مشتركة';

  @override
  String get localOnlyDownloadFailed =>
      'تعذّر تنزيل بعض المرفقات. تحقّق من الاتصال وحاول مجددًا؛ لم تتغير الملاحظة.';

  @override
  String get templatesTitle => 'القوالب';

  @override
  String get templatesSubtitle =>
      'ابدأ بتخطيط جاهز؛ يمكنك تغيير كل شيء لاحقًا.';

  @override
  String get fromTemplate => 'من قالب';

  @override
  String get tplShoppingName => 'قائمة التسوق';

  @override
  String get tplShoppingItems => 'خبز, حليب, بيض, فاكهة, خضار';

  @override
  String get tplShoppingDesc => 'ضع علامة على ما اشتريته؛ ينتقل للأسفل';

  @override
  String get tplTodoDesc => 'قائمة فارغة بتاريخ اليوم';

  @override
  String get tplTravelName => 'قائمة الأمتعة';

  @override
  String get tplTravelItems =>
      'الهوية / جواز السفر, الشاحن, الأدوية, فرشاة الأسنان, الملابس, السماعات';

  @override
  String get tplTravelDesc => 'قائمة تحقق جاهزة';

  @override
  String get tplMeetingDesc => 'الحضور، جدول الأعمال، القرارات';

  @override
  String get tplJournalDesc => 'كيف كان اليوم، الامتنان، الغد';

  @override
  String get tplRecipeName => 'وصفة';

  @override
  String get tplRecipeMeta => 'الحصص: · الوقت:';

  @override
  String get tplRecipeIngredients => 'المكونات';

  @override
  String get tplRecipeSteps => 'طريقة التحضير';

  @override
  String get tplRecipeNotes => 'ملاحظات';

  @override
  String get tplRecipeDesc => 'المكونات والخطوات';

  @override
  String get tplWeeklyName => 'خطة أسبوعية';

  @override
  String get tplWeeklyDesc => 'أيام هذا الأسبوع كعناوين';

  @override
  String get tplExpenseDesc => 'التاريخ، الوصف، المبلغ';

  @override
  String get tplReadingDesc => 'المصدر، الملخص، الاقتباسات';

  @override
  String get settingsThemeHeader => 'المظهر';

  @override
  String get settingsCardsHeader => 'البطاقات والقوائم';

  @override
  String get shareTargetTitle => 'أضِف إلى الملاحظات';

  @override
  String get shareTargetNew => 'ملاحظة جديدة';

  @override
  String get shareTargetExisting => 'ملاحظة موجودة';

  @override
  String get shareTargetCreate => 'إنشاء ملاحظة';

  @override
  String get shareTargetSearch => 'ابحث في الملاحظات';

  @override
  String get shareTargetNoNotes => 'لا توجد ملاحظات متاحة';

  @override
  String get shareTargetNoMatch => 'لا توجد ملاحظات مطابقة';

  @override
  String shareTargetMore(int count) {
    return '+$count ملفات';
  }

  @override
  String get sharePreviewExpand => 'تكبير المعاينة';

  @override
  String get sharePreviewCollapse => 'تصغير المعاينة';

  @override
  String get templatesSearch => 'ابحث في القوالب';

  @override
  String get templatesAll => 'الكل';

  @override
  String get templatesLists => 'قوائم';

  @override
  String get templatesPlanning => 'تخطيط';

  @override
  String get templatesWriting => 'كتابة';

  @override
  String get templatesMine => 'قوالبي';

  @override
  String get templatesRecent => 'المستخدمة مؤخرًا';

  @override
  String get templatesNoMatch => 'لا توجد قوالب مطابقة';

  @override
  String get templatesMineEmpty =>
      'ليست لديك قوالب خاصة بعد. اختر «حفظ كقالب» من قائمة أي ملاحظة وسيظهر هنا.';

  @override
  String get templatesMineInfo => 'قالبك';

  @override
  String get templateRename => 'إعادة التسمية';

  @override
  String get templateDelete => 'حذف القالب';

  @override
  String get templateNameTitle => 'اسم القالب';

  @override
  String get templateNameHint => 'مثل: تسوق الأسبوع';

  @override
  String get templateSave => 'حفظ';

  @override
  String templateSaved(String name) {
    return 'أُضيف «$name» إلى قوالبك';
  }

  @override
  String get saveAsTemplate => 'حفظ كقالب';

  @override
  String get templateCreate => 'إنشاء';

  @override
  String templateCreateWithCount(int count) {
    return 'إنشاء · $count عناصر';
  }

  @override
  String get templateListChecks => 'مربعات اختيار';

  @override
  String get templateListNumbers => 'مرقّمة';

  @override
  String get templateItems => 'العناصر';

  @override
  String get templateAddItem => 'إضافة عنصر';

  @override
  String get templateSuggestionsInfo =>
      'اضغط على اقتراح لإضافته إلى القائمة، واضغط مرة أخرى لإزالته.';

  @override
  String get tplShopProduce => 'خضار وفواكه';

  @override
  String get tplShopProduceItems =>
      'طماطم, خيار, بصل, بطاطس, ليمون, موز, تفاح, بقدونس';

  @override
  String get tplShopBreakfast => 'الفطور';

  @override
  String get tplShopBreakfastItems => 'جبن, زيتون, زبدة, عسل, مربى, زبادي';

  @override
  String get tplShopPantry => 'مؤن';

  @override
  String get tplShopPantryItems =>
      'أرز, معكرونة, دقيق, سكر, زيت زيتون, عدس, شاي, قهوة';

  @override
  String get tplShopCleaning => 'منظفات';

  @override
  String get tplShopCleaningItems =>
      'سائل الصحون, مسحوق الغسيل, ورق التواليت, مناديل المطبخ, أكياس القمامة';

  @override
  String get tplShopPersonal => 'العناية الشخصية';

  @override
  String get tplShopPersonalItems => 'شامبو, معجون أسنان, صابون, مزيل عرق';

  @override
  String get tplTravelDocs => 'المستندات';

  @override
  String get tplTravelDocsItems =>
      'التذاكر, حجز الفندق, رخصة القيادة, تأمين السفر, نقود / بطاقات';

  @override
  String get tplTravelClothes => 'الملابس';

  @override
  String get tplTravelClothesItems =>
      'قمصان, بناطيل, ملابس داخلية, جوارب, بيجامة, سترة, أحذية';

  @override
  String get tplTravelCare => 'أدوات العناية';

  @override
  String get tplTravelCareItems =>
      'معجون أسنان, شامبو, واقي شمس, أدوات الحلاقة, مزيل عرق';

  @override
  String get tplTravelTech => 'إلكترونيات';

  @override
  String get tplTravelTechItems => 'بطارية متنقلة, محوّل قابس, سماعات, كابلات';

  @override
  String get tplHabitsName => 'متابعة العادات';

  @override
  String get tplHabitsDesc => 'ضع علامة كل يوم ولا تقطع السلسلة';

  @override
  String get tplHabitsItems =>
      '8 أكواب ماء, مشي 30 دقيقة, قراءة 20 صفحة, النوم مبكرًا, ساعة بلا شاشات';

  @override
  String get tplCleaningName => 'تنظيف المنزل';

  @override
  String get tplCleaningDesc => 'قائمة تنظيف أسبوعية';

  @override
  String get tplCleaningItems =>
      'إزالة الغبار, الكنس بالمكنسة, مسح الأرضيات, تنظيف الحمّام, سطح المطبخ, الغسيل, إخراج القمامة, تغيير الشراشف';

  @override
  String get tplMovingName => 'قائمة الانتقال';

  @override
  String get tplMovingDesc => 'مهام قبل الانتقال وبعده';

  @override
  String get tplMovingItems =>
      'حجز شركة النقل, شراء صناديق وشريط لاصق, تحديث العنوان, الكهرباء / الماء / الغاز, نقل الإنترنت, تسليم المفاتيح';

  @override
  String get tplGiftsName => 'قائمة الهدايا';

  @override
  String get tplGiftsDesc => 'من يحصل على ماذا، أفكار';

  @override
  String get tplGiftsItems => 'أمي, أبي, أخي, صديق';

  @override
  String get tplWatchlistName => 'للمشاهدة';

  @override
  String get tplWatchlistDesc => 'أفلام ومسلسلات وكتب';

  @override
  String get tplWorkoutName => 'تمرين';

  @override
  String get tplWorkoutDesc => 'من الإحماء إلى التمدد';

  @override
  String get tplWorkoutItems =>
      'إحماء 5 دقائق, قرفصاء 3×12, ضغط 3×10, تمارين بطن 3×15, بلانك 3×45 ث, تمدد 5 دقائق';

  @override
  String get tplGoalsName => 'الأهداف';

  @override
  String get tplGoalsDesc => 'أهداف السنة والشهر والأسبوع';

  @override
  String get tplGoalsYear => 'هذه السنة';

  @override
  String get tplGoalsMonth => 'هذا الشهر';

  @override
  String get tplGoalsWeek => 'هذا الأسبوع';

  @override
  String get tplGoalsWhy => 'لماذا هذا مهم؟';

  @override
  String get templateNew => 'قالب جديد';

  @override
  String get templateEdit => 'تعديل القالب';

  @override
  String get templateDuplicate => 'تكرار';

  @override
  String get templateSaveAsMine => 'حفظ في قوالبي';

  @override
  String get templateUntitled => 'قالب بلا عنوان';

  @override
  String get templateTypeText => 'نص';

  @override
  String get templateTitleHelp =>
      'عنوان الملاحظات المنشأة من هذا القالب (اختياري)';

  @override
  String get templateBody => 'النص';

  @override
  String get templateHeadingHelp =>
      'الأسطر التي تبدأ بـ «# » تصبح عناوين، و«## » عناوين فرعية.';

  @override
  String get templateDiscardTitle => 'تجاهل التغييرات؟';

  @override
  String get templateDiscard => 'تجاهل';

  @override
  String templateDeleted(String name) {
    return 'تم حذف «$name»';
  }

  @override
  String get addVideoFromGallery => 'فيديو من المعرض';

  @override
  String get addYouTubeVideo => 'فيديو يوتيوب';

  @override
  String get addYouTubeVideoSubtitle =>
      'يُشغَّل داخل الملاحظة، شاهده في نافذة صغيرة';

  @override
  String get youTubeLinkHelp =>
      'الصق رابط فيديو يوتيوب (youtube.com أو youtu.be).';

  @override
  String get youTubeInvalidLink => 'هذا ليس رابط فيديو يوتيوب';

  @override
  String get youTubeOpenInBrowserInfo =>
      'لا يمكن تشغيل الفيديو داخل التطبيق على هذا الجهاز؛ يمكن فتحه في المتصفح.';

  @override
  String get youTubeOpenExternal => 'فتح في يوتيوب';

  @override
  String get pictureInPicture => 'صورة داخل صورة';

  @override
  String get pinMediaTop => 'تثبيت في الأعلى';

  @override
  String get pinMediaRelease => 'أفلِت: تثبيت في الأعلى (الملاحظة بالأسفل)';

  @override
  String get unpinMedia => 'إعادة إلى الصفحة';

  @override
  String get unpinMediaRelease => 'أفلِت: إعادة إلى الصفحة';

  @override
  String get pinnedMediaResize => 'ارتفاع اللوحة — اسحب لتغييره';

  @override
  String get addPageSubtitle => 'يضيف صفحة فارغة جديدة إلى الملاحظة';

  @override
  String pageOf(int current, int total) {
    return 'الصفحة $current / $total';
  }

  @override
  String pageAdded(int page) {
    return 'أُضيفت الصفحة $page';
  }

  @override
  String get deletePageConfirm =>
      'حذف نص هذه الصفحة؟ تنتقل صورها إلى الصفحة المجاورة. يمكنك استعادته بالتراجع.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'صورة';

  @override
  String get embedNewVideo => 'فيديو';

  @override
  String get embedNewYouTube => 'يوتيوب';

  @override
  String get embedPickTitle => 'ماذا تريد أن تضمّن؟';

  @override
  String embedPickTitleFor(String label) {
    return 'تضمين في «$label»';
  }

  @override
  String get embedPickInfo => 'اضغط على النص لفتح العنصر المضمّن في مكانه.';

  @override
  String get embedSectionNew => 'إضافة جديد';

  @override
  String get embedSectionExisting => 'مرفقات هذه الملاحظة';

  @override
  String get embedReplace => 'استبدال';

  @override
  String get embedRemove => 'إزالة التضمين';

  @override
  String get embedRemoved => 'أُزيل التضمين';

  @override
  String get guideTitle => 'دليل الاستخدام';

  @override
  String get guideMenuInfo => 'كل الميزات خطوة بخطوة';

  @override
  String get guideSearchHint => 'ابحث في الدليل — «صفحة»، «يوتيوب»';

  @override
  String get guideContents => 'المحتويات';

  @override
  String get guideOpenScreen => 'فتح الشاشة';

  @override
  String guideNoResults(String query) {
    return 'لا نتائج لـ «$query»';
  }

  @override
  String get copyVideoLink => 'نسخ الرابط';

  @override
  String get videoLinkCopied => 'تم نسخ الرابط';

  @override
  String get attachSectionVisual => 'الصور والرسم';

  @override
  String get menuSectionOrganize => 'تنظيم';

  @override
  String get menuSectionCopy => 'النسخ والتصدير';

  @override
  String get menuSectionTools => 'الأدوات';

  @override
  String get menuSectionProtect => 'الحماية والتخزين';

  @override
  String get menuSectionContent => 'المحتوى';

  @override
  String get menuSectionPeople => 'الحساب وجهات الاتصال';

  @override
  String get menuSectionHome => 'الشاشة الرئيسية';

  @override
  String get menuSectionApp => 'التطبيق';
}
