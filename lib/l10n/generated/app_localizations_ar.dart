// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'ملاحظات';

  @override
  String get loginTagline => 'ملاحظاتك على كل أجهزتك';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بحساب Google';

  @override
  String loginError(String error) {
    return 'تعذّر تسجيل الدخول: $error';
  }

  @override
  String get searchHint => 'بحث...';

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
  String get star => 'تمييز بنجمة';

  @override
  String get unstar => 'إزالة النجمة';

  @override
  String get sectionOthers => 'أخرى';

  @override
  String get emptyNotes => 'لا توجد ملاحظات هنا بعد';

  @override
  String get emptyFilter => 'لا توجد ملاحظات تطابق هذا الفلتر';

  @override
  String get clearFilter => 'مسح الفلتر';

  @override
  String get emptyFolderTitle => 'لا توجد ملاحظات هنا بعد';

  @override
  String get newNoteAction => 'إضافة ملاحظة';

  @override
  String get emptySearch => 'لا شيء هنا يطابق بحثك';

  @override
  String get newTextNote => 'ملاحظة نصية';

  @override
  String get newChecklist => 'قائمة';

  @override
  String get newOrderedList => 'قائمة مرقّمة';

  @override
  String get noteDeleted => 'تم حذف الملاحظة';

  @override
  String get dragTrashHint => 'أفلِت هنا للحذف';

  @override
  String get dragTrashReady => 'أفلِت للحذف';

  @override
  String notesDeletedCount(int count) {
    return 'تم حذف $count ملاحظات';
  }

  @override
  String selectedCount(int count) {
    return 'تم تحديد $count';
  }

  @override
  String get deleteSelected => 'حذف المحدد';

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
  String get addImage => 'إضافة صورة';

  @override
  String attachmentFailed(String error) {
    return 'تعذّرت إضافة المرفق: $error';
  }

  @override
  String get attachmentCopying => 'جارٍ النسخ...';

  @override
  String get attachmentUploading => 'جارٍ الرفع...';

  @override
  String get attachmentUploadFailed => 'فشل الرفع — اضغط لإعادة المحاولة';

  @override
  String get attachmentNotSynced => 'لم تتم مزامنة هذا الملف مع هذا الجهاز بعد';

  @override
  String get attachmentDeviceOnly =>
      'ملف كبير: محفوظ على هذا الجهاز فقط، ولا يُنسخ احتياطيًا إلى السحابة';

  @override
  String get attachmentOtherDevice =>
      'هذا الملف الكبير موجود فقط على الجهاز الذي أُضيف منه؛ ولا يُنزَّل هنا';

  @override
  String get attachmentDeviceFull =>
      'لا توجد مساحة كافية على الجهاز لنسخ الملف. حرّر بعض المساحة وحاول مجددًا.';

  @override
  String get webDriveTapToOpen => 'في Google Drive · اضغط للفتح';

  @override
  String get noteFullscreen => 'ملء الشاشة';

  @override
  String get noteFullscreenExit => 'الخروج من ملء الشاشة';

  @override
  String get penModeDone => 'إغلاق القلم';

  @override
  String get pageInkOnCard => 'يحتوي على كتابة يدوية';

  @override
  String attachmentTooLarge(int limit) {
    return 'الملف كبير جدًا (الحد الأقصى $limit ميغابايت)';
  }

  @override
  String storageFull(String limit) {
    return 'مساحة التخزين ممتلئة ($limit). احذف المرفقات القديمة لتحرير مساحة.';
  }

  @override
  String get storageUsage => 'التخزين';

  @override
  String storageUsageValue(String used, String limit) {
    return 'مستخدم $used من $limit';
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
  String get summarize => 'تلخيص';

  @override
  String get listen => 'استماع';

  @override
  String get ask => 'اطرح سؤالًا';

  @override
  String get extractText => 'استخراج النص';

  @override
  String get transcribe => 'تفريغ صوتي';

  @override
  String get listenToNote => 'استماع';

  @override
  String aiError(String error) {
    return 'فشل طلب الذكاء الاصطناعي: $error';
  }

  @override
  String get aiThinking => 'جارٍ التفكير...';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ';

  @override
  String get settingsSearchHint => 'ابحث في الإعدادات — «قفل»، «ميكروفون»';

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
  String get themeSage => 'مريمية';

  @override
  String get themePorcelain => 'خزف';

  @override
  String get themeClay => 'طين';

  @override
  String get themeDark => 'داكن';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get lockNote => 'قفل';

  @override
  String get unlockNote => 'فتح القفل';

  @override
  String get lockedNote => 'ملاحظة مقفلة';

  @override
  String get unlockAuthReason => 'تحقّق من هويتك لفتح الملاحظة المقفلة';

  @override
  String get exportBackup => 'نسخة احتياطية كاملة';

  @override
  String get expandListItems => 'إظهار صفوف القائمة كاملة';

  @override
  String get expandListItemsInfo =>
      'تلتف العناصر الطويلة وتظهر كاملة؛ وعند الإيقاف سطر واحد.';

  @override
  String get quickCaptureRowSetting => 'شريط الملاحظة السريعة';

  @override
  String get quickCaptureRowInfo =>
      'حقل «ملاحظة جديدة…» بسطر واحد أعلى الشاشة الرئيسية.';

  @override
  String get emptyTrash => 'إفراغ السلة';

  @override
  String emptyTrashConfirm(int count) {
    return 'سيتم حذف $count ملاحظات نهائيًا. لا يمكن التراجع عن ذلك. هل أنت متأكد؟';
  }

  @override
  String get trashEmptied => 'تم إفراغ السلة';

  @override
  String get validateAndSave => 'تحقّق واحفظ';

  @override
  String get clear => 'مسح';

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
  String get switchAccount => 'تبديل الحساب';

  @override
  String get switchAccountConfirm =>
      'سيتم تسجيل خروجك من هذا الحساب وسيُفتح منتقي حسابات Google. تبقى ملاحظاتك في هذا الحساب وستجدها عند عودتك.';

  @override
  String get switchAccountGuestWarning =>
      'أنت تستخدم حساب ضيف: إن بدّلت الحساب ستفقد الوصول إلى الملاحظات على هذا الجهاز. اربط حساب Google أو أنشئ نسخة احتياطية كاملة أولًا.';

  @override
  String get penTrayShow => 'إظهار درج القلم';

  @override
  String get addDrawingSubtitle => 'ارسم على لوحة منفصلة تُضمَّن كصورة';

  @override
  String get addGroupWrite => 'كتابة';

  @override
  String get addGroupPen => 'القلم';

  @override
  String get addGroupFiles => 'ملفات وروابط';

  @override
  String get addGroupSound => 'الصوت';

  @override
  String get addGroupTemplate => 'القوالب';

  @override
  String get addSeparateDrawing => 'رسم منفصل (صورة)';

  @override
  String get addHandwriting => 'الكتابة على الصفحة (قلم)';

  @override
  String get addHandwritingSubtitle =>
      'وضع القلم: اكتب مباشرة على صفحة الملاحظة';

  @override
  String webDriveBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count مرفقات موجودة في Google Drive الخاص بك — امنح الإذن لرؤيتها',
      one: 'مرفق واحد موجود في Google Drive الخاص بك — امنح الإذن لرؤيته',
    );
    return '$_temp0';
  }

  @override
  String get webDriveShow => 'عرض';

  @override
  String webAttachmentsOnPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count مرفقات لم تغادر الهاتف الذي أُضيفت منه بعد. على الهاتف: الإعدادات ← المزامنة ← ربط Drive.',
      one: 'مرفق واحد لم يغادر الهاتف الذي أُضيف منه بعد. على الهاتف: الإعدادات ← المزامنة ← ربط Drive.',
    );
    return '$_temp0';
  }

  @override
  String get fullscreenPullHint => 'اسحب لملء الشاشة';

  @override
  String get fullscreenPullRelease => 'أفلِت: ملء الشاشة';

  @override
  String get signOutConfirm => 'هل تريد تسجيل الخروج فعلًا؟';

  @override
  String get signOutAnonymousWarning =>
      'أنت على حساب محلي: تسجيل الخروج يجعل هذا الحساب وكل ملاحظاته غير قابلة للوصول نهائيًا — وبدون نسخة احتياطية لا يمكن استعادتها. اربط حساب Google أولًا للاحتفاظ بملاحظاتك. هل تريد تسجيل الخروج على أي حال؟';

  @override
  String get deleteAccount => 'حذف حسابي وبياناتي';

  @override
  String get deleteAccountWarning =>
      'لا يمكن التراجع عن هذا: سيتم حذف كل ملاحظاتك ومرفقاتك وحسابك نهائيًا. هل تريد المتابعة؟';

  @override
  String get deleteAccountConfirm => 'حذف نهائي';

  @override
  String get deleteAccountPageInfo =>
      'يُحذف حسابك وكل بياناتك نهائيًا: الملاحظات والمجلدات والمرفقات (السحابة و Drive إن كان مربوطًا) وجهات الاتصال والملاحظات الواردة والمجلدات التي شاركتها وسجل حسابك. تبقى نسخ الملاحظات التي أرسلتها للآخرين لديهم. لا يمكن التراجع عن ذلك؛ أنشئ نسخة احتياطية من الإعدادات أولًا إن شئت.';

  @override
  String get licensesTitle => 'تراخيص المصادر المفتوحة';

  @override
  String get generating => 'جارٍ الإنشاء...';

  @override
  String get retry => 'حاول مجددًا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get close => 'إغلاق';

  @override
  String get ok => 'حسنًا';

  @override
  String get syncPending => 'بانتظار المزامنة';

  @override
  String get synced => 'تمت المزامنة';

  @override
  String get liteSyncHeld =>
      'تُرسل التغييرات إلى السحابة كل بضع دقائق — اضغط للمزامنة الآن';

  @override
  String get liteSyncSending => 'جارٍ إرسال التغييرات إلى السحابة';

  @override
  String genericError(String error) {
    return 'حدث خطأ ما: $error';
  }

  @override
  String get addTag => 'وسم';

  @override
  String get tagHint => 'مثلًا: عمل، منزل، مدرسة';

  @override
  String get addReminder => 'ذكّرني';

  @override
  String get placeReminder => 'تذكير بالموقع';

  @override
  String get placeReminderHint =>
      'استلم هذه الملاحظة كإشعار عند وصولك إلى مكان أو مغادرته. يراقب النظام الموقع؛ ويعمل حتى عندما يكون التطبيق مغلقًا.';

  @override
  String get placeCurrent => 'موقعي الحالي';

  @override
  String get placeSearchHint => 'ابحث عن عنوان أو مكان';

  @override
  String get placeSearchNone => 'لا توجد نتائج';

  @override
  String get placeArrive => 'عند الوصول';

  @override
  String get placeLeave => 'عند المغادرة';

  @override
  String get placeRadius => 'نصف القطر';

  @override
  String get placeSave => 'ضبط التذكير';

  @override
  String get placeRemove => 'إزالة تذكير الموقع';

  @override
  String get placeSet => 'تم ضبط تذكير الموقع';

  @override
  String get placeRemoved => 'تمت إزالة تذكير الموقع';

  @override
  String get placeNeedPermission =>
      'لم يُمنح إذن الموقع. يمكنك السماح به من الإعدادات.';

  @override
  String get placeNeedBackground =>
      'ليعمل أثناء إغلاق التطبيق، اضبط إذن الموقع على \"السماح طوال الوقت\".';

  @override
  String get placeBackgroundTitle => 'مطلوب إذن \"طوال الوقت\"';

  @override
  String get placeOpenSettings => 'سماح';

  @override
  String get placeLocationOff => 'موقع الجهاز متوقف. شغّله وحاول مجددًا.';

  @override
  String get placeFailed => 'تعذّر ضبط تذكير الموقع.';

  @override
  String get placeNoLocation => 'تعذّر تحديد موقعك. تأكد من تشغيل الموقع.';

  @override
  String placeArrivedBody(String place) {
    return 'وصلت إلى $place';
  }

  @override
  String placeLeftBody(String place) {
    return 'غادرت $place';
  }

  @override
  String get share => 'مشاركة';

  @override
  String get archive => 'أرشفة';

  @override
  String get unarchive => 'إلغاء الأرشفة';

  @override
  String get archiveTitle => 'الأرشيف';

  @override
  String get archiveEmpty => 'لا توجد ملاحظات مؤرشفة هنا';

  @override
  String get trashTitle => 'سلة المحذوفات';

  @override
  String get trashEmpty => 'لا توجد ملاحظات محذوفة هنا';

  @override
  String get trashInfo =>
      'تبقى الملاحظات المحذوفة هنا؛ يمكنك استعادتها أو حذفها نهائيًا.';

  @override
  String get restore => 'استعادة';

  @override
  String get deleteForever => 'حذف نهائي';

  @override
  String get deleteForeverConfirm =>
      'سيتم حذف هذه الملاحظة نهائيًا. هل أنت متأكد؟';

  @override
  String get recordAudio => 'تسجيل صوتي';

  @override
  String get recording => 'جارٍ التسجيل...';

  @override
  String get stopAndSave => 'إنهاء وإضافة';

  @override
  String get micPermissionDenied => 'تم رفض إذن الميكروفون';

  @override
  String get addDrawing => 'إضافة رسم';

  @override
  String get addToNote => 'إضافة إلى الملاحظة';

  @override
  String get fontSize => 'حجم النص';

  @override
  String get fontSizePreview => 'ستبدو ملاحظاتك هكذا';

  @override
  String get darkSchedule => 'جدولة المظهر الداكن';

  @override
  String get darkScheduleInfo =>
      'يتحوّل إلى المظهر الداكن بين الساعات التي تحددها';

  @override
  String get voiceCommand => 'أمر صوتي';

  @override
  String get suggestTags => 'اقتراح وسوم';

  @override
  String get existingTagsLabel => 'الوسوم السابقة';

  @override
  String get voiceFinish => 'إنهاء';

  @override
  String get voiceProcessing => 'جارٍ تطبيق ما قلته...';

  @override
  String get voiceNothingHeard => 'لم يُكتشف كلام في التسجيل';

  @override
  String get voiceNoteSaved => 'تم حفظ ملاحظتك الصوتية';

  @override
  String get openNote => 'فتح الملاحظة';

  @override
  String get remindersTitle => 'التذكيرات';

  @override
  String get remindersEmpty => 'لا توجد تذكيرات هنا';

  @override
  String get remindersEmptyHint =>
      'أضف تذكيرًا إلى ملاحظة، أو اكتب ملاحظة جديدة بتذكير عبر +.';

  @override
  String get remindersUpcoming => 'القادمة';

  @override
  String get remindersPast => 'السابقة';

  @override
  String get reminderInPast => 'الوقت المحدد في الماضي — اختر وقتًا مستقبليًا.';

  @override
  String get newReminder => 'تذكير جديد';

  @override
  String get remindersUntitled => 'ملاحظة بلا عنوان';

  @override
  String get remindersEdit => 'تغيير الوقت';

  @override
  String get remindersRemove => 'إزالة التذكير';

  @override
  String get clearNote => 'مسح المحتوى';

  @override
  String get clearNoteConfirm =>
      'سيتم حذف محتوى الملاحظة (النص وعناصر القائمة). هل أنت متأكد؟';

  @override
  String get calculatorTitle => 'الآلة الحاسبة';

  @override
  String get calcExpressionHint => 'مثلًا 12.5×3+40';

  @override
  String get calcInvalid => 'تعبير غير صالح';

  @override
  String get liveDictation => 'إملاء';

  @override
  String get dictationHoldHint =>
      'اضغط مطولًا على الميكروفون وتحدّث؛ يُكتب النص عند الإفلات';

  @override
  String itemsSelected(int count) {
    return 'تم تحديد $count عناصر';
  }

  @override
  String get dictationProcessing => 'جارٍ التفريغ...';

  @override
  String get voiceListening => 'جارٍ الاستماع...';

  @override
  String get voiceTapHint => 'اضغط وتحدّث؛ اضغط مجددًا للإنهاء';

  @override
  String get voiceModeSetting => 'طريقة الاستخدام';

  @override
  String get voiceModeHold => 'اضغط مطولًا للتحدث';

  @override
  String get voiceModeTap => 'اضغط للبدء';

  @override
  String get voiceModeInfo =>
      'الضغط المطوّل: يتوقف عند الإفلات. الضغطة: تتوقف بضغطة ثانية.';

  @override
  String get voiceCaptureReady => 'الكلام جاهز';

  @override
  String get voiceCaptureEditHint => 'اضغط على النص لتعديله';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · ترقيم تلقائي';
  }

  @override
  String get voiceCaptureAddToNote => 'إضافة إلى الملاحظة';

  @override
  String get voiceCaptureCreateNote => 'إنشاء ملاحظة جديدة';

  @override
  String get voiceCaptureAiNote => 'ملاحظة بالذكاء الاصطناعي';

  @override
  String get voiceCapturePlainNote => 'ملاحظة عادية';

  @override
  String get voiceCloseTitle => 'إملاؤك ما زال هنا';

  @override
  String get voiceCloseKeepTalking => 'واصل التحدث';

  @override
  String get voiceCaptureRestart => 'سجّل من جديد';

  @override
  String get voiceChipSummarizeAdd => 'إضافة كملخص';

  @override
  String get voiceChipSummarizeSave => 'حفظ كملخص';

  @override
  String get voiceChipToItems => 'تقسيم إلى عناصر';

  @override
  String get voiceChipAsList => 'تحويل إلى قائمة مهام';

  @override
  String get voiceChipFix => 'تنظيف';

  @override
  String get permissionsTitle => 'الأذونات';

  @override
  String get permMic => 'الميكروفون';

  @override
  String get permMicInfo =>
      'مطلوب للملاحظات الصوتية بالذكاء الاصطناعي والإملاء والتسجيل الصوتي';

  @override
  String get permNotifications => 'الإشعارات';

  @override
  String get permNotificationsInfo => 'مطلوبة للتذكيرات والملخص اليومي';

  @override
  String get permExactAlarm => 'المنبّهات والتذكيرات';

  @override
  String get permExactAlarmInfo =>
      'عند الإيقاف قد تتأخر التذكيرات بضع دقائق. اسمح بها لتطبيق الملاحظات';

  @override
  String get permBattery => 'تحسين البطارية';

  @override
  String get permBatteryInfo =>
      'استثنِ التطبيق من قيود البطارية كي لا تتأخر التذكيرات';

  @override
  String get permAutoStart => 'التشغيل التلقائي (Xiaomi)';

  @override
  String get permAutoStartInfo =>
      'استعادة التذكيرات بعد إعادة التشغيل: فعّل «التشغيل التلقائي»';

  @override
  String get autoStartHint =>
      'Xiaomi: اسمح بـ«التشغيل التلقائي» للتطبيق لتعمل التذكيرات بعد إعادة التشغيل';

  @override
  String get autoStartHintAction => 'فتح';

  @override
  String get exactAlarmHint =>
      'إذن المنبّه متوقف: قد تتأخر التذكيرات بضع دقائق';

  @override
  String get exactAlarmHintAction => 'سماح';

  @override
  String get permCamera => 'الكاميرا';

  @override
  String get permCameraInfo => 'مطلوبة لملاحظات الفيديو والتقاط الصور';

  @override
  String get newVideoNote => 'تسجيل فيديو';

  @override
  String get videoLocalOnly =>
      'هذا الفيديو محفوظ على هذا الجهاز فقط (لا يُرفع إلى السحابة)';

  @override
  String get videoToNote => 'إنشاء ملاحظة من الفيديو';

  @override
  String get permGranted => 'ممنوح';

  @override
  String get permGrant => 'منح';

  @override
  String get permOpenSettings => 'فتح الإعدادات';

  @override
  String get newVoiceCapture => 'ملاحظة صوتية بالذكاء الاصطناعي';

  @override
  String get suggestTitle => 'اقتراح عنوان';

  @override
  String get noteMetaMenu => 'وسم · تذكير · مجلد';

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
    return 'سيتم حذف المجلد \"$name\". لن تُحذف الملاحظات بداخله — ستصبح بلا مجلد فقط.';
  }

  @override
  String get folderNameHint => 'اسم المجلد';

  @override
  String get folderIcon => 'الأيقونة';

  @override
  String get select => 'تحديد';

  @override
  String get noteArchived => 'تمت أرشفة الملاحظة';

  @override
  String pendingUploads(int count) {
    return 'جارٍ رفع $count مرفقات';
  }

  @override
  String pendingUploadsFailed(int count) {
    return 'فشل $count مرفقات، ستُعاد المحاولة';
  }

  @override
  String pendingUploadsOffline(int count) {
    return '$count مرفقات بالانتظار — ستُرفع عند اتصالك بالإنترنت';
  }

  @override
  String get pendingUploadsInfo =>
      'المرفقات آمنة على هذا الجهاز. تُرفع تلقائيًا عند اتصالك بالإنترنت؛ وحتى ذلك الحين لا تظهر على أجهزتك الأخرى.';

  @override
  String checkedHeader(int count) {
    return 'المُنجزة ($count)';
  }

  @override
  String deleteChecked(int count) {
    return 'حذف المُنجزة ($count)';
  }

  @override
  String get removeItem => 'حذف العنصر';

  @override
  String get copyWholeNote => 'نسخ الملاحظة كاملة';

  @override
  String get allCopied => 'تم نسخ الملاحظة كاملة إلى الحافظة';

  @override
  String get speechRate => 'سرعة القراءة';

  @override
  String get speechNoVoices => 'لا توجد أصوات مثبتة على هذا الجهاز';

  @override
  String get speechVoiceAutoInfo => 'تُقرأ اللغات الأخرى بصوت ذكوري تلقائيًا';

  @override
  String get listening => 'جارٍ الاستماع...';

  @override
  String get exportPdf => 'تصدير كملف PDF';

  @override
  String get pdfTitleField => 'العنوان';

  @override
  String get pdfContentField => 'المحتوى';

  @override
  String get pdfMarkupHint =>
      'العلامات في بداية السطر تصبح تنسيقًا: [x] و[ ] لمربعات الاختيار، و1. لقائمة مرقّمة، و- لنقطة.';

  @override
  String get pdfIncludeDate => 'تضمين التاريخ';

  @override
  String get exportIncludeImages => 'تضمين الصور';

  @override
  String get exportWord => 'مشاركة كملف Word (.docx)';

  @override
  String get pdfPreview => 'معاينة';

  @override
  String get largeAttachmentTitle => 'ملف كبير';

  @override
  String largeAttachmentBody(String size) {
    return 'حجم هذا الملف $size ميغابايت. لا يمكن ضغط ملفات PDF؛ سيُرفع كما هو ويُحتسب من مساحة التخزين. هل تريد المتابعة؟';
  }

  @override
  String get speechRateForeign => 'سرعة اللغة الأجنبية';

  @override
  String notesArchivedCount(int count) {
    return 'تمت أرشفة $count ملاحظات';
  }

  @override
  String get backgroundColor => 'لون الخلفية';

  @override
  String get backgroundColorInfo =>
      'خلفية الملاحظة — تظهر داخل الملاحظة وعلى الشاشة الرئيسية';

  @override
  String get frameColor => 'الإطار';

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
  String get sortUpdated => 'المحدّثة مؤخرًا';

  @override
  String get sortCreated => 'تاريخ الإنشاء';

  @override
  String get sortTitle => 'حسب العنوان (أ–ي)';

  @override
  String get settingsLanguage => 'اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get syncTitle => 'المزامنة';

  @override
  String get syncLimitTitle => 'حد الرفع التلقائي';

  @override
  String get syncLimitInfo =>
      'تبقى المرفقات الأكبر على الجهاز؛ ويُزامَن نص الملاحظة دائمًا.';

  @override
  String get syncLimitUnlimited => 'بلا حد';

  @override
  String get importBackup => 'الاستعادة من نسخة احتياطية';

  @override
  String get importBackupInvalid => 'ملف نسخة احتياطية غير صالح';

  @override
  String get moveToFolder => 'نقل إلى مجلد';

  @override
  String get assistantGenericError => 'حدث خطأ ما — هل يمكنك المحاولة مجددًا؟';

  @override
  String get quickAddTooltip => 'ملاحظة جديدة — اختر النوع';

  @override
  String get annotate => 'تعليق توضيحي';

  @override
  String get annotateDone => 'إنهاء التعليق';

  @override
  String get newPdfNote => 'ملاحظة من PDF';

  @override
  String get imageNotePreparing => 'جارٍ ترتيب الصور في مستند…';

  @override
  String get newImageNote => 'ملاحظة من صور';

  @override
  String get pdfPageNoteHint => 'ملاحظة لهذه الصفحة…';

  @override
  String pdfPage(int page) {
    return 'الصفحة $page';
  }

  @override
  String pdfPageOf(int page, int total) {
    return 'الصفحة $page / $total';
  }

  @override
  String get pdfPreviousPage => 'الصفحة السابقة';

  @override
  String get pdfNextPage => 'الصفحة التالية';

  @override
  String get pdfFullScreen => 'فتح بملء الشاشة';

  @override
  String get pdfNoDocument => 'لا يوجد ملف PDF في هذه الملاحظة بعد';

  @override
  String get pdfChooseDocument => 'اختيار PDF';

  @override
  String get newSlidesNote => 'ملاحظة من شرائح';

  @override
  String get slidesNoDocument => 'لا يوجد عرض تقديمي في هذه الملاحظة بعد';

  @override
  String get slidesChooseDocument => 'اختيار عرض تقديمي';

  @override
  String get pdfEditPages => 'تعديل الصفحات';

  @override
  String get pdfDeletePages => 'حذف الصفحات المحددة';

  @override
  String get pdfAddBlankPage => 'إضافة صفحة فارغة';

  @override
  String get pdfRotatePages => 'تدوير';

  @override
  String get pdfBurnInk => 'دمج الكتابة اليدوية في المستند';

  @override
  String get pdfApplyChanges => 'تطبيق التغييرات';

  @override
  String get pdfCannotDeleteAllPages => 'لا يمكنك حذف كل الصفحات';

  @override
  String get pdfPagesHint =>
      'اضغط على صفحة لتحديدها. تنتقل ملاحظات الصفحة معها؛ وملاحظة الصفحة المحذوفة تُخفى لكنها تبقى في بياناتك.';

  @override
  String pdfEditFailed(String error) {
    return 'تعذّر تعديل ملف PDF: $error';
  }

  @override
  String get pdfInkBurned => 'تم دمج الكتابة اليدوية في المستند';

  @override
  String get pdfAllPageNotes => 'كل ملاحظات الصفحات';

  @override
  String get pdfNoPageNotes =>
      'لا توجد ملاحظات صفحات بعد. انتقل إلى صفحة واكتب في الحقل أدناه.';

  @override
  String get crop => 'قص';

  @override
  String get cropApply => 'تطبيق القص';

  @override
  String get cropReset => 'إعادة تعيين التحديد';

  @override
  String get cropHint => 'اسحب الزوايا لاختيار منطقة. لا يمكن التراجع عن القص.';

  @override
  String get cropFailed => 'تعذّر قص الصورة.';

  @override
  String get penBallpoint => 'قلم حبر جاف';

  @override
  String get penFountain => 'قلم حبر سائل';

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
  String get inkCleared => 'تم مسح التعليقات';

  @override
  String get inkEraserTooltip => 'ممحاة (اضغط مطولًا: مسح الكل)';

  @override
  String get inkTwoFingerHint => 'إصبع واحد يرسم · إصبعان للتحريك والتكبير';

  @override
  String get slideOpenFailed => 'تعذّر فتح العرض التقديمي';

  @override
  String get newPhotoNote => 'التقاط صورة';

  @override
  String get newScanNote => 'مسح مستند ضوئيًا';

  @override
  String get scanDocument => 'مسح مستند';

  @override
  String get scanDocumentSubtitle => 'يكتشف الحواف ويسوّي الصفحة ويضيفها';

  @override
  String get scanUnsupported =>
      'المسح الضوئي للمستندات غير مدعوم على هذا الجهاز';

  @override
  String scanFailed(String error) {
    return 'تعذّر مسح المستند: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return 'تمت إضافة $count صفحة إلى الملاحظة';
  }

  @override
  String get scanTextTitle => 'التعرّف على النص أيضًا؟';

  @override
  String get scanTextBody =>
      'يُتعرَّف على النص في الصفحات ويُكتب في الملاحظة. تبقى الصورة كما هي. يستغرق بضع ثوانٍ لكل صفحة.';

  @override
  String get scanImageOnly => 'الصورة فقط';

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
  String get qrScanHint => 'ضع الرمز داخل الإطار';

  @override
  String get qrFromPhoto => 'القراءة من صورة';

  @override
  String get qrNotFound => 'لم يُعثر على رمز في هذه الصورة';

  @override
  String get qrLinkFound => 'هذا الرمز رابط';

  @override
  String get qrOpenLink => 'الانتقال إلى الرابط';

  @override
  String get qrSaveToNote => 'حفظ في ملاحظة';

  @override
  String get openLink => 'فتح الرابط';

  @override
  String get linkOpenFailed => 'تعذّر فتح الرابط';

  @override
  String qrScanFailed(String error) {
    return 'تعذّرت قراءة الرمز: $error';
  }

  @override
  String get qrTorch => 'مصباح';

  @override
  String get hideAttachments => 'إخفاء';

  @override
  String get showAttachments => 'إظهار';

  @override
  String get selectAllItems => 'تحديد الكل';

  @override
  String get checkSelectedItems => 'إنجاز المحدد';

  @override
  String get itemUncheck => 'إلغاء الإنجاز';

  @override
  String get uncheckSelectedItems => 'إلغاء إنجاز المحدد';

  @override
  String get hiddenFolder => 'مجلد مخفي';

  @override
  String get hiddenFolderInfo =>
      'المجلد المخفي وملاحظاته لا تظهر على الشاشة الرئيسية. لإظهارها اختر \"المجلدات المخفية\" من قائمة ⋮ وتحقّق من هويتك.';

  @override
  String get hiddenFoldersMenu => 'المجلدات المخفية';

  @override
  String get hiddenFolderAuthReason => 'تحقّق من هويتك لإظهار المجلدات المخفية';

  @override
  String get hiddenFoldersShown => 'المجلدات المخفية ظاهرة الآن';

  @override
  String get hiddenFoldersHiddenAgain => 'أُخفيت المجلدات المخفية مجددًا';

  @override
  String get makeFolderHidden => 'إخفاء';

  @override
  String get makeFolderVisible => 'إظهار';

  @override
  String gridColumnsCount(int count) {
    return '$count أعمدة';
  }

  @override
  String get addImageOnPageSubtitle => 'تستقر على الصفحة ويلتف النص حولها';

  @override
  String get addImageAsFile => 'إضافة الصورة كملف';

  @override
  String get addImageAsFileSubtitle => 'تبقى خارج الصفحة، في شريط المرفقات';

  @override
  String get attachmentCopied => 'تم نسخ المرفق';

  @override
  String get pasteAttachment => 'لصق المرفق المنسوخ';

  @override
  String get fullscreen => 'ملء الشاشة';

  @override
  String get more => 'المزيد';

  @override
  String get undone => 'تم التراجع';

  @override
  String get filterOthers => 'بلا مجلد أو وسم';

  @override
  String get aiHistoryVoiceNote => 'ملاحظة صوتية بالذكاء الاصطناعي';

  @override
  String get sectionPinnedShort => 'مثبّتة';

  @override
  String get sectionUrgent => 'عاجل';

  @override
  String get urgentMark => 'تمييز كعاجل';

  @override
  String get urgentUnmark => 'إزالة علامة العاجل';

  @override
  String get urgentInfo => 'يظهر أولًا في الرئيسية مع !';

  @override
  String get sectionToday => 'اليوم';

  @override
  String get sectionThisWeek => 'هذا الأسبوع';

  @override
  String get sectionEarlier => 'سابقًا';

  @override
  String sectionNoteCount(int count) {
    return '$count ملاحظات';
  }

  @override
  String get quickCaptureHint => 'ملاحظة جديدة…';

  @override
  String get quickCaptureSave => 'حفظ';

  @override
  String get viewToggle => 'العرض';

  @override
  String get viewGrid => 'شبكة';

  @override
  String get viewList => 'قائمة';

  @override
  String get filterReminded => 'مع تذكير';

  @override
  String get filterLocked => 'مقفلة';

  @override
  String get sortColor => 'اللون';

  @override
  String get sortActive => 'الأكثر عملًا عليها';

  @override
  String get voicePreview => 'جرّب الصوت';

  @override
  String get reorderHint =>
      'اضغط مطولًا على بطاقة ثم اسحبها إلى المكان الذي تريده';

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
  String get filterSheetSortHint =>
      'مجموعات التاريخ (اليوم، هذا الأسبوع…) تظهر فقط عند الترتيب حسب «المحدّثة مؤخرًا».';

  @override
  String get formatTitle => 'التنسيق';

  @override
  String get formatBold => 'غامق';

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
      'ينتقل التنسيق داخل النص كعلامات (مثل **غامق**)؛ وتبقى العلامات مخفية في التصدير والقراءة الصوتية.';

  @override
  String get formatMenu => 'تنسيق…';

  @override
  String get noteFontDefault => 'افتراضي';

  @override
  String get noteFontSerif => 'كتابي (serif)';

  @override
  String get noteFontMono => 'آلة كاتبة';

  @override
  String get noteTextSize => 'حجم النص';

  @override
  String get formatClear => 'مسح التنسيق';

  @override
  String get formatHeading => 'عنوان';

  @override
  String get noteTextOpacity => 'العتامة';

  @override
  String get assistantMute => 'كتم';

  @override
  String get assistantUnmute => 'إلغاء الكتم';

  @override
  String get assistantMakeNote => 'حوّلها إلى ملاحظة على أي حال';

  @override
  String get assistantNoteCreated => 'تم إنشاء الملاحظة';

  @override
  String get noteNotFound => 'لم يُعثر على الملاحظة. ربما حُذفت.';

  @override
  String get back => 'رجوع';

  @override
  String get addTextBlock => 'إضافة نص';

  @override
  String get noteBackgroundImage => 'صورة الخلفية';

  @override
  String get changeBackgroundImage => 'تغيير الصورة';

  @override
  String get removeBackgroundImage => 'إزالة الخلفية';

  @override
  String get dashboardBackground => 'خلفية الشاشة الرئيسية';

  @override
  String get dashboardBackgroundInfo =>
      'صورة تظهر خلف شبكة الملاحظات (هذا الجهاز فقط).';

  @override
  String get apiKeyFieldLabel => 'مفتاح API';

  @override
  String get getApiKey => 'من أين أحصل على مفتاح؟';

  @override
  String get continueWithoutAccount => 'المتابعة بدون حساب';

  @override
  String get localAccountInfo =>
      'تبقى ملاحظاتك على هذا الجهاز فقط: لا يمكن فتحها من مكان آخر وتضيع إن أزلت التطبيق. يتطلب الذكاء الاصطناعي المدمج وجهات الاتصال والمشاركة حساب Google؛ ويمكنك استخدام الذكاء الاصطناعي بمفتاح API خاص بك. يمكنك ربط حساب Google في أي وقت — تنتقل ملاحظاتك معك.';

  @override
  String get localAccountBadge => 'حساب محلي';

  @override
  String get profileGuestName => 'ضيف';

  @override
  String get profileGuestSignIn => 'تسجيل الدخول';

  @override
  String get linkGoogleAccount => 'ربط حساب Google';

  @override
  String get accountLinked =>
      'تم ربط حساب Google. ملاحظاتك محفوظة احتياطيًا الآن.';

  @override
  String scanReviewPage(int current, int total) {
    return 'الصفحة $current / $total';
  }

  @override
  String get scanRotatePage => 'تدوير الصفحة';

  @override
  String get scanDeletePage => 'حذف الصفحة';

  @override
  String get scanLastPage => 'لا يمكن حذف الصفحة الأخيرة';

  @override
  String get scanDiscardTitle => 'تجاهل الصفحات الممسوحة؟';

  @override
  String get scanDiscardConfirm => 'تجاهل';

  @override
  String get scanAdjustCorners => 'ضبط الزوايا';

  @override
  String get scanFilterOriginal => 'الأصل';

  @override
  String get scanFilterAuto => 'تحسين';

  @override
  String get scanFilterGray => 'تدرّج رمادي';

  @override
  String get scanFilterBw => 'أبيض وأسود';

  @override
  String get scanApplyAll => 'تطبيق على الكل';

  @override
  String get scanPageFailed => 'تعذّر عرض الصفحة';

  @override
  String get scanCropHint => 'صحّح الصفحة المائلة بـ\"ضبط الزوايا\"';

  @override
  String get scanAddAsPdf => 'إضافة كملف PDF';

  @override
  String get scanAddAsImages => 'إضافة كصور';

  @override
  String get scanBuildingPdf => 'جارٍ تجهيز PDF…';

  @override
  String scanOcrProgress(int done, int total) {
    return 'جارٍ التعرّف على النص… $done/$total';
  }

  @override
  String get scanAutoDetect => 'اكتشاف الحواف تلقائيًا';

  @override
  String get scanReset => 'إعادة تعيين';

  @override
  String get scanDetecting => 'جارٍ البحث عن الحواف…';

  @override
  String get scanAutoFound =>
      'عُثر على الحواف تلقائيًا؛ اضبطها بالمقابض إن لزم';

  @override
  String get scanDragHint => 'اسحب الزوايا إلى حواف الورقة';

  @override
  String get scanApplyCorners => 'تقويم وتطبيق';

  @override
  String get scanWorking => 'جارٍ التقويم…';

  @override
  String get scanPdfAdded => 'أُضيف المسح إلى الملاحظة كمرفق PDF';

  @override
  String get premiumTitle => 'بريميوم';

  @override
  String get premiumStatusFree => 'أنت تستخدم النسخة المجانية';

  @override
  String get guestSignInUnavailable =>
      'تسجيل الدخول بدون Google متوقف حاليًا: لم يُفعَّل تسجيل الدخول المجهول في وحدة تحكم Firebase (Authentication ← Sign-in method). سجّل الدخول بحساب Google، أو حاول مجددًا بعد أن يفعّله المسؤول.';

  @override
  String get googleSignInUnavailable =>
      'تسجيل الدخول بحساب Google متوقف حاليًا: لم يُفعَّل موفّر Google في وحدة تحكم Firebase.';

  @override
  String get signInNetworkError =>
      'تعذّر الوصول إلى الإنترنت. تحقق من اتصالك وحاول مجددًا.';

  @override
  String get signInCanceled => 'أُلغي تسجيل الدخول.';

  @override
  String get cardRichPreview => 'نص منسّق على البطاقات';

  @override
  String get cardRichPreviewInfo =>
      'تعرض البطاقات اللون والتظليل والغامق والتسطير.';

  @override
  String get cardHideSensitive => 'إخفاء المحتوى الحساس على البطاقات';

  @override
  String get cardHideSensitiveInfo =>
      'تُخفى ملاحظات كلمات المرور وأرقام البطاقات/IBAN على البطاقات.';

  @override
  String get sensitiveHiddenOnCard => 'محتوى حساس — مخفي على البطاقة';

  @override
  String get paletteMore => 'ألوان أخرى';

  @override
  String get paletteCustom => 'لون مخصص';

  @override
  String get paletteUse => 'استخدام';

  @override
  String get paletteHue => 'درجة اللون';

  @override
  String get paletteSaturation => 'التشبّع';

  @override
  String get paletteLightness => 'السطوع';

  @override
  String get itemMoveToPage => 'نقل إلى صفحة أخرى';

  @override
  String itemMovedToPage(int page) {
    return 'نُقل العنصر إلى الصفحة $page';
  }

  @override
  String get archiveInsights => 'ماذا في أرشيفي؟';

  @override
  String archiveInsightsStats(int count, int files, int stale) {
    return '$count ملاحظات · $files مرفقات · $stale لم تُلمس منذ عام';
  }

  @override
  String get archiveByFolder => 'حسب المجلد';

  @override
  String get archiveNoFolder => 'بلا مجلد';

  @override
  String get archiveStale => 'لم تُلمس منذ عام';

  @override
  String get lineSpacing => 'تباعد الأسطر';

  @override
  String get lineSpacingNormal => 'عادي';

  @override
  String get lineSpacingWide => 'واسع';

  @override
  String get lineSpacingWider => 'أوسع';

  @override
  String get trashReminderTitle => 'قد يكون في السلة ما يستحق الاحتفاظ به';

  @override
  String trashReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستُحذف $count ملاحظات نهائيًا غدًا',
      one: 'ستُحذف ملاحظة نهائيًا غدًا',
    );
    return '$_temp0 — يبدو أنها ما زالت تحتوي على مهمة أو معلومة مهمة. ألقِ نظرة.';
  }

  @override
  String get groupByFolder => 'التجميع حسب المجلد';

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
  String get appFontInfo => 'خط التطبيق؛ بعضها يُنزَّل عند اختياره.';

  @override
  String get fontNeedsDownload => 'يُنزَّل مرة واحدة عند اختياره';

  @override
  String get followSystemTextScale => 'اتباع حجم نص النظام';

  @override
  String get followSystemTextScaleInfo =>
      'يُطبَّق حجم نص الهاتف على التطبيق أيضًا.';

  @override
  String get pdfSelectOcrRunning => 'جارٍ التعرّف على النص…';

  @override
  String get pdfSelectOcrNone => 'لم يُعثر على نص في هذه الصفحة';

  @override
  String pdfSelectCopied(int n) {
    return 'تم نسخ $n حرفًا';
  }

  @override
  String get bubbleAdd => 'إضافة فقاعة ملاحظة';

  @override
  String get bubbleAddDone => 'إنهاء إضافة الفقاعات';

  @override
  String get bubbleCollapse => 'طي الفقاعة';

  @override
  String get bubbleHint => 'اكتب ملاحظتك هنا…';

  @override
  String get bubbleTapToPlace => 'اضغط على الصفحة حيث تريد الفقاعة';

  @override
  String get ttsSectionTitle => 'القراءة الصوتية';

  @override
  String get ttsEngineDevice => 'صوت الجهاز';

  @override
  String get ttsEngineDeviceInfo =>
      'يقرأ صوت الجهاز المدمج: مجاني، دون إنترنت، وبلا حد للطول.';

  @override
  String get shareAsNotePreparing => 'جارٍ تجهيز حزمة الملاحظة…';

  @override
  String get shareAsTextEmpty => 'لا يوجد نص في هذه الملاحظة لمشاركته.';

  @override
  String get sharePdfWithBubbles => 'كملف PDF مع الفقاعات';

  @override
  String get sharePdfWithBubblesInfo =>
      'تُطبع الفقاعات والتظليل والرسومات في ملف PDF؛ يمكن لأي أحد فتحه، وفي التطبيق يُفتح قابلًا للتعديل.';

  @override
  String get sharePdfWithBubblesNone =>
      'لا يوجد في هذه الملاحظة ملف PDF يحمل فقاعات أو رسومات.';

  @override
  String get sharePdfWithBubblesPreparing => 'جارٍ تجهيز PDF مع الفقاعات…';

  @override
  String get sharePdfWithBubblesSuffix => ' (مع الفقاعات)';

  @override
  String get bubbleStar => 'تمييز بنجمة';

  @override
  String get bubbleEdit => 'تعديل الفقاعة';

  @override
  String get bubbleStarredOnly => 'المميزة بنجمة فقط';

  @override
  String get bubbleSearchHint => 'البحث في الفقاعات…';

  @override
  String get bubblesListAll => 'كل الفقاعات';

  @override
  String get bubblesOverviewTitle => 'الفقاعات';

  @override
  String get bubblesEmpty =>
      'لا توجد فقاعات بعد. حدّد نصًا في المستند وظلّله، أو ضع فقاعة على الصفحة.';

  @override
  String get bubblesNoMatch => 'لا توجد فقاعة تطابق بحثك.';

  @override
  String get bubbleNoText => '(فقاعة فارغة)';

  @override
  String get pdfHighlight => 'تظليل';

  @override
  String get pdfHighlightWithNote => 'تظليل + ملاحظة';

  @override
  String get pageNotesShow => 'إظهار ملاحظة الصفحة';

  @override
  String get pageNotesHide => 'إخفاء ملاحظة الصفحة';

  @override
  String get bubbleSave => 'حفظ';

  @override
  String get bubbleTitleHint => 'العنوان';

  @override
  String get bubbleUrgent => 'عاجل (يومض)';

  @override
  String get captureModeQuestion => 'كيف تُفتح الملاحظة؟';

  @override
  String get captureModeBubbles => 'فقاعات';

  @override
  String get captureModeBubblesInfo =>
      'يصبح المحتوى صفحة مستند: فقاعات وتظليل وقلم.';

  @override
  String get captureModeClassic => 'كلاسيكي';

  @override
  String get captureModeClassicInfo =>
      'ملاحظة نصية عادية؛ ويصبح المستند مرفقًا.';

  @override
  String get captureModeNew => 'جديد';

  @override
  String get imagePrepareTitle => 'ضبط الصور';

  @override
  String get imagePrepareDone => 'متابعة';

  @override
  String get imageRotateLeft => 'تدوير لليسار';

  @override
  String get imageRotateRight => 'تدوير لليمين';

  @override
  String get videoFrameFailed =>
      'تعذّر التقاط إطار من الفيديو؛ سيُفتح كملاحظة كلاسيكية.';

  @override
  String get bubbleArrowHide => 'إخفاء السهم';

  @override
  String get bubbleArrowShow => 'إظهار السهم';

  @override
  String get speechPitch => 'طبقة الصوت';

  @override
  String get speechVoicePickerTitle => 'اختيار الصوت';

  @override
  String get formatRemove => 'إزالة';

  @override
  String get exportNotesOption => 'PDF / Word مخصص…';

  @override
  String get exportNotesOptionInfo =>
      'نص الملاحظة وصورها كملف PDF أو Word بتخطيط قابل للضبط؛ دون الفقاعات';

  @override
  String get captureNoteTitle => 'عنوان الملاحظة (اختياري)';

  @override
  String get captureNoteTitleHint => 'يحمل المستند الجديد هذا الاسم أيضًا';

  @override
  String get imageOcrTitle => 'التعرّف على النص في الصورة';

  @override
  String get imageOcrNone => 'لم يُعثر على نص في هذه الصورة.';

  @override
  String get imageOcrShort => 'التعرّف على النص';

  @override
  String get imageOcrWorking => 'جارٍ التعرّف على النص…';

  @override
  String get imageOcrSelectHint => 'ضغطة: كلمة · اضغط واسحب: حرفًا بحرف';

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
      'يجري النص بجانب الصور الضيقة المحاذاة يمينًا أو يسارًا؛ والصور الوسطية تأخذ العرض كاملًا.';

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
  String imageOcrCharsSelected(int count) {
    return 'تم تحديد $count حرفًا';
  }

  @override
  String imagesSelectedCount(int count) {
    return 'تم تحديد $count صور';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count مرفقات';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count أسطر';
  }

  @override
  String get rotateFailed => 'تعذّر تدوير الصورة.';

  @override
  String get dashboardBackgroundChange => 'تغيير صورة الخلفية';

  @override
  String get appearancePreviewTitle => 'نص نموذجي';

  @override
  String get appearancePreviewNoteTitle => 'عنوان ملاحظة نموذجي';

  @override
  String get appearancePreviewBody =>
      'ستبدو ملاحظاتك هكذا. يظهر النص **الغامق** و~المسطّر~ و==2:المظلّل== هكذا.';

  @override
  String get appearancePreviewItem => 'هكذا يبدو عنصر قائمة المهام';

  @override
  String get convertToText => 'تحويل إلى نص';

  @override
  String get convertToList => 'تحويل إلى قائمة';

  @override
  String get convertedToText => 'حُوّلت القائمة إلى نص عادي.';

  @override
  String get convertedToList => 'حُوّل النص إلى قائمة.';

  @override
  String get convertToListEmpty => 'لا توجد أسطر لتحويلها إلى قائمة.';

  @override
  String get listTwoColumns => 'عمودان';

  @override
  String get listOneColumn => 'عمود واحد';

  @override
  String get sortItems => 'ترتيب العناصر';

  @override
  String get sortStarredFirst => 'المميزة بنجمة أولًا';

  @override
  String get sortUncheckedFirst => 'المُنجزة أخيرًا';

  @override
  String get sortAlphabetical => 'أ ← ي';

  @override
  String get sortAlphabeticalDesc => 'ي ← أ';

  @override
  String get imagesToAttachments => 'نقل الصور إلى المرفقات';

  @override
  String imagesToAttachmentsDone(int count) {
    return 'نُقلت $count صور إلى المرفقات.';
  }

  @override
  String get imageOcrShowRecognized => 'تظليل النص المُتعرَّف عليه';

  @override
  String get imageOcrHideRecognized => 'إخفاء التظليل';

  @override
  String get bubblePlainMode => 'مربع نص مفتوح';

  @override
  String get bubblePlainTapToPlace => 'اضغط حيث يجب أن يكون النص';

  @override
  String get bubblePlainHint => 'اضغط للكتابة';

  @override
  String get noteSearchTitle => 'البحث في الملاحظة';

  @override
  String get noteSearchHint => 'ابحث في هذه الملاحظة…';

  @override
  String get noteSearchEmptyHint =>
      'يبحث فورًا في نص الملاحظة وعناصرها وملاحظات صفحاتها. ابدأ الفحص أدناه للبحث داخل مرفقات الصور وPDF.';

  @override
  String get noteSearchNoHit => 'لم يُعثر على تطابقات.';

  @override
  String get noteSearchScanAttachments => 'فحص المرفقات';

  @override
  String get noteTitleLabel => 'العنوان';

  @override
  String get noteBodyLabel => 'نص الملاحظة';

  @override
  String get itemLabel => 'عنصر';

  @override
  String noteSearchAttachmentsInfo(int count) {
    return 'يمكن فحص $count مرفقات (صورة/PDF).';
  }

  @override
  String noteSearchAttachmentsReady(int count) {
    return 'يُبحث داخل $count مرفقات أيضًا.';
  }

  @override
  String pageLabel(int page) {
    return 'الصفحة $page';
  }

  @override
  String get archiveNotebook => 'دفتر';

  @override
  String get archiveNewPage => 'صفحة جديدة';

  @override
  String get archiveTemplateJournal => 'يوميات';

  @override
  String get archiveTemplateMeeting => 'اجتماع';

  @override
  String get archiveTemplateExpense => 'مصروفات';

  @override
  String get archiveTemplateTodo => 'مهام';

  @override
  String get archiveTemplateReading => 'ملاحظات القراءة';

  @override
  String get tplJournalHow => 'كيف كان اليوم؟';

  @override
  String get tplJournalGrateful => 'ممتن لـ';

  @override
  String get tplJournalTomorrow => 'للغد';

  @override
  String get tplMeetingAttendees => 'الحضور';

  @override
  String get tplMeetingAgenda => 'جدول الأعمال';

  @override
  String get tplMeetingDecisions => 'القرارات';

  @override
  String get tplMeetingActions => 'مَن، ماذا، متى';

  @override
  String get tplExpenseColumns => 'التاريخ · الوصف · المبلغ';

  @override
  String get tplExpenseTotal => 'الإجمالي:';

  @override
  String get tplReadingSource => 'المصدر';

  @override
  String get tplReadingSummary => 'الملخص';

  @override
  String get tplReadingQuotes => 'اقتباسات';

  @override
  String get tplReadingThoughts => 'أفكاري';

  @override
  String get archiveDeletePage => 'حذف الصفحة';

  @override
  String get archivePrevPage => 'الصفحة السابقة';

  @override
  String get archiveNextPage => 'الصفحة التالية';

  @override
  String get archiveCopyHere => 'جمع في الدفتر';

  @override
  String get archiveNoNotebook => 'لا يوجد دفتر بعد. أنشئ واحدًا أولًا.';

  @override
  String get archiveNothingToCopy => 'لا توجد مرفقات في هذه الملاحظة لنسخها.';

  @override
  String archiveCopied(int count) {
    return 'جُمعت $count ملفات في الدفتر.';
  }

  @override
  String get attachmentTagInserted => 'أُدرج وسم المرفق.';

  @override
  String get attachmentTagPreview => 'معاينة المرفق';

  @override
  String get attachmentTagEdit => 'تعديل المرفق';

  @override
  String archiveCardSummary(int files, int texts) {
    return '$files ملفات · $texts نصوص';
  }

  @override
  String get archivePaper => 'الورق';

  @override
  String get archivePaperLined => 'مسطّر';

  @override
  String get archivePaperGrid => 'مربعات';

  @override
  String get archivePaperDots => 'منقّط';

  @override
  String get archivePaperPlain => 'سادة';

  @override
  String get archivePaperLegal => 'دفتر قانوني';

  @override
  String get archivePaperEngineering => 'هندسي';

  @override
  String get archivePaperIsometric => 'متساوي القياس';

  @override
  String get attachmentTagEmbed => 'تضمين في النص';

  @override
  String get bubbleModeBubble => 'فقاعة';

  @override
  String get attachmentTagEmbedInfo =>
      'يُربط بالنص المحدد، أو عند المؤشر إن لم يُحدَّد شيء';

  @override
  String get attachmentTagLinkHere => 'اربط هنا';

  @override
  String attachmentTagPendingBanner(String name) {
    return 'سيُربط $name — حدّد النص';
  }

  @override
  String get docNameNotesSuffix => 'ملاحظات';

  @override
  String get docNamePhoto => 'ملاحظات صور';

  @override
  String get docNameScan => 'ملاحظات مسح';

  @override
  String get docNameImage => 'ملاحظات صورية';

  @override
  String get docNameVideo => 'ملاحظات فيديو';

  @override
  String get folderEmpty => 'لا توجد ملاحظات هنا بعد';

  @override
  String folderNoteCount(int count) {
    return '$count ملاحظات';
  }

  @override
  String get folderCardEmpty => 'فارغ';

  @override
  String get folderEmptyHint =>
      'أضف ملاحظة عبر + بالأسفل، أو انقل ملاحظة إلى هنا أثناء تعديلها.';

  @override
  String get folderShared => 'هذا المجلد مُشارك مع صديق';

  @override
  String get friendsTitle => 'جهات الاتصال';

  @override
  String get friendsAdd => 'إضافة صديق';

  @override
  String get friendsEmpty =>
      'أضف صديقًا عبر البريد الإلكتروني لتشارك المجلدات معه.';

  @override
  String get friendsRequestsTitle => 'الطلبات';

  @override
  String get friendsListTitle => 'أصدقائي';

  @override
  String get friendsSendRequest => 'إرسال طلب';

  @override
  String get friendsRequestSent => 'تم إرسال الطلب';

  @override
  String get friendsNotFound =>
      'لا يوجد مستخدم مسجّل بهذا البريد. يجب أن يكون قد فتح التطبيق بحساب Google مرة واحدة على الأقل.';

  @override
  String get friendsSelf => 'لا يمكنك إضافة نفسك كصديق';

  @override
  String get friendsAlready => 'أنتما صديقان بالفعل';

  @override
  String get friendsDecline => 'رفض';

  @override
  String get friendsAccept => 'قبول';

  @override
  String get friendsRemove => 'إزالة';

  @override
  String get friendsRemoveConfirmTitle => 'إزالة صديق';

  @override
  String friendsRemoveConfirmBody(Object name) {
    return 'إزالة $name من أصدقائك؟ لن تعود المجلدات التي شاركتها معه ظاهرة.';
  }

  @override
  String get friendsSearchHint => 'الاسم (3 أحرف أو أكثر) أو البريد كاملًا';

  @override
  String get friendsSearchEmpty => 'لا توجد نتائج';

  @override
  String get friendsSearchTooShort =>
      'اكتب 3 أحرف على الأقل أو بريدًا كاملًا للبحث';

  @override
  String get friendsSearchAdd => 'إضافة';

  @override
  String get folderShare => 'تعديل مشترك';

  @override
  String folderShareCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'مُشارك مع $count أشخاص',
      one: 'مُشارك مع شخص واحد',
    );
    return '$_temp0';
  }

  @override
  String folderShareTitle(Object name) {
    return 'مشاركة \"$name\"';
  }

  @override
  String get folderShareInfo =>
      'تذهب دعوة إلى الصديق الذي تختاره؛ ويرى المجلد بعد قبولها. أنت تحدد صلاحيته (قراءة / كتابة / كلاهما).';

  @override
  String get friendsRowInfo => 'أضف أصدقاء وشارك المجلدات معهم';

  @override
  String get accountRecoverConflictTitle => 'على هذا الجهاز ملاحظات غير محفوظة';

  @override
  String accountRecoverConflictBody(Object count) {
    return 'حساب Google هذا مرتبط بجلسة أخرى بالفعل؛ التبديل إليه سيخفي $count ملاحظات على هذا الجهاز (لا تُحذف، لكن لا يمكن الوصول إليها من هنا). هل تريد المتابعة؟';
  }

  @override
  String get accountRecoverConflictProceed => 'التبديل على أي حال';

  @override
  String get folderRoleRead => 'قراءة';

  @override
  String get folderRoleWrite => 'كتابة';

  @override
  String get folderRoleBoth => 'قراءة + كتابة';

  @override
  String get folderInvitePending => 'أُرسلت الدعوة، بانتظار الرد';

  @override
  String get folderWriteOnlyTitle => 'لديك صلاحية الكتابة فقط';

  @override
  String get folderWriteOnlyHint =>
      'يمكنك إضافة ملاحظات جديدة إلى هذا المجلد لكن لا يمكنك رؤية الملاحظات بداخله.';

  @override
  String get folderChatTitle => 'الدردشة';

  @override
  String get folderChatHint => 'اكتب رسالة…';

  @override
  String get folderChatSend => 'إرسال';

  @override
  String get folderChatEmptyTitle => 'لا توجد رسائل هنا بعد';

  @override
  String get folderChatEmptyHint => 'تحدّث هنا مع من شاركت معهم هذا المجلد.';

  @override
  String get folderInviteTitle => 'دعوة مجلد';

  @override
  String folderInviteBody(Object name) {
    return 'تمت مشاركة المجلد \"$name\" معك.';
  }

  @override
  String get folderInviteAccepted => 'تمت إضافة المجلد';

  @override
  String get folderInviteDeclined => 'رُفضت الدعوة';

  @override
  String friendRequestBanner(Object name) {
    return 'أرسل لك $name طلب صداقة';
  }

  @override
  String get friendRequestAccepted => 'تمت إضافة الصديق';

  @override
  String get sendNoteTitle => 'إرسال الملاحظة إلى صديق';

  @override
  String get sendNoteInfo =>
      'تصل نسخة من الملاحظة إلى صندوق \"الملاحظات الواردة\" لدى الشخص. لا تُرسل المرفقات (الصور والمستندات والصوت).';

  @override
  String sendNoteSent(Object name) {
    return 'أُرسلت الملاحظة إلى $name';
  }

  @override
  String get inboxTitle => 'الملاحظات الواردة';

  @override
  String get inboxEmpty => 'لا توجد ملاحظات واردة هنا';

  @override
  String get inboxEmptyHint => 'تتجمع هنا الملاحظات التي يرسلها لك أصدقاؤك.';

  @override
  String inboxFrom(Object name) {
    return 'أرسلها $name';
  }

  @override
  String get inboxAccept => 'إضافة إلى ملاحظاتي';

  @override
  String get inboxAccepted => 'أُضيفت الملاحظة إلى ملاحظاتك';

  @override
  String get folderShelfCollapse => 'طي المجلدات';

  @override
  String get accountSheetLocalInfo =>
      'ملاحظاتك على هذا الجهاز فقط. اربط حساب Google لنسخها احتياطيًا وإضافة أصدقاء.';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get videoFramesExtracting => 'جارٍ التقاط إطارات من الفيديو…';

  @override
  String get areaSelect => 'تحديد منطقة';

  @override
  String get areaSelectOff => 'إيقاف تحديد المنطقة';

  @override
  String get areaSelectHint =>
      'اسحب مربعًا حول ما تريد نسخه أو سؤال الذكاء الاصطناعي عنه.';

  @override
  String get areaCopyImage => 'نسخ كصورة';

  @override
  String get areaCopied => 'نُسخت المنطقة المحددة إلى الحافظة.';

  @override
  String get areaAskTitle => 'المنطقة المحددة';

  @override
  String get areaCaptureFailed => 'تعذّر التقاط المنطقة المحددة.';

  @override
  String get areaTooSmall => 'المنطقة المحددة صغيرة جدًا.';

  @override
  String get bubbleTextFill => 'خلفية النص';

  @override
  String get bubbleTextFillNone => 'بلا خلفية';

  @override
  String get bubbleTextAlignLeft => 'محاذاة لليسار';

  @override
  String get bubbleTextAlignCenter => 'توسيط';

  @override
  String get bubbleTextAlignRight => 'محاذاة لليمين';

  @override
  String get dashboardBackgroundPattern => 'النقش';

  @override
  String get dashboardBackgroundColor => 'لون الخلفية';

  @override
  String get dashboardBackgroundReset => 'إعادة إلى الافتراضي';

  @override
  String get patternNone => 'سادة';

  @override
  String get patternDots => 'نقاط';

  @override
  String get patternGrid => 'مربعات';

  @override
  String get patternLines => 'خطوط';

  @override
  String get patternDiagonal => 'قطري';

  @override
  String get patternGraph => 'ورق رسم بياني';

  @override
  String get sharedNotifications => 'إشعارات المجلدات المشتركة';

  @override
  String get sharedNotificationsInfo =>
      'استلم إشعارًا عند إضافة ملاحظة مشتركة أو تغييرها أو مراسلتها.';

  @override
  String get copyAsText => 'نسخ النص';

  @override
  String get searchAttachments => 'البحث داخل المرفقات';

  @override
  String get searchAttachmentsInfo => 'يبحث أيضًا في نص PDF والنص داخل الصور.';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get selectNone => 'مسح التحديد';

  @override
  String get duplicateNote => 'تكرار الملاحظة';

  @override
  String get noteDuplicated => 'تم تكرار الملاحظة';

  @override
  String notesDuplicatedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تم تكرار $count ملاحظات',
      one: 'تم تكرار ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get noteStatsTitle => 'إحصاءات الملاحظة';

  @override
  String noteStatsWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كلمات',
      one: 'كلمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String noteStatsChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أحرف',
      one: 'حرف واحد',
    );
    return '$_temp0';
  }

  @override
  String noteStatsItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عناصر',
      one: 'عنصر واحد',
    );
    return '$_temp0';
  }

  @override
  String noteStatsAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرفقات',
      one: 'مرفق واحد',
    );
    return '$_temp0';
  }

  @override
  String noteStatsReadTime(int count) {
    return '~$count دقيقة قراءة';
  }

  @override
  String get scrollToTop => 'العودة للأعلى';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتائج',
      one: 'نتيجة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String trashDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يُحذف نهائيًا خلال $count أيام',
      one: 'يُحذف نهائيًا خلال يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get trashLastDay => 'سيُحذف نهائيًا اليوم';

  @override
  String get noteRestored => 'تمت استعادة الملاحظة';

  @override
  String get restoreAll => 'استعادة الكل';

  @override
  String notesRestoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت استعادة $count ملاحظات',
      one: 'تمت استعادة ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get reminderRemoved => 'تمت إزالة التذكير';

  @override
  String get reminderOverdue => 'متأخر';

  @override
  String get reminderQuickTonight => 'الليلة 6:00 م';

  @override
  String get reminderQuickTomorrow => 'غدًا 9:00 ص';

  @override
  String get reminderQuickNextWeek => 'الأسبوع القادم';

  @override
  String get reminderSnooze => 'تأجيل ساعة';

  @override
  String get reminderSnoozed => 'تم تأجيل التذكير';

  @override
  String reminderCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكيرات',
      one: 'تذكير واحد',
    );
    return '$_temp0';
  }

  @override
  String get relativeJustNow => 'الآن';

  @override
  String relativeInMinutes(int count) {
    return 'خلال $count د';
  }

  @override
  String relativeInHours(int count) {
    return 'خلال $count س';
  }

  @override
  String relativeInDays(int count) {
    return 'خلال $count أيام';
  }

  @override
  String relativeAgoMinutes(int count) {
    return 'قبل $count د';
  }

  @override
  String relativeAgoHours(int count) {
    return 'قبل $count س';
  }

  @override
  String relativeAgoDays(int count) {
    return 'قبل $count أيام';
  }

  @override
  String get inboxDeclined => 'حُذفت الملاحظة الواردة';

  @override
  String inboxCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظات واردة',
      one: 'ملاحظة واردة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get appVersionCopied => 'نُسخت معلومات الإصدار';

  @override
  String notesMovedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'نُقلت $count ملاحظات',
      one: 'نُقلت ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get mediaPlay => 'تشغيل';

  @override
  String get mediaPause => 'إيقاف مؤقت';

  @override
  String get decrease => 'تقليل';

  @override
  String get increase => 'زيادة';

  @override
  String get tagManageTitle => 'إدارة الوسم';

  @override
  String get tagRename => 'إعادة تسمية الوسم';

  @override
  String get tagRenameHint => 'اسم الوسم الجديد';

  @override
  String get tagDelete => 'حذف الوسم';

  @override
  String tagDeleteConfirm(String tag) {
    return 'إزالة الوسم \"$tag\" من كل الملاحظات؟ تبقى الملاحظات.';
  }

  @override
  String get tagRenamed => 'تمت إعادة تسمية الوسم';

  @override
  String get tagDeleted => 'تمت إزالة الوسم';

  @override
  String get tagLongPressHint => 'اضغط مطولًا على وسم لإعادة تسميته أو حذفه.';

  @override
  String get recentSearches => 'عمليات البحث الأخيرة';

  @override
  String get clearRecentSearches => 'مسح السجل';

  @override
  String get imagesEqualizeSize => 'توحيد الأحجام';

  @override
  String get imagesFitRow => 'ملاءمة للصف';

  @override
  String imagesFitColumns(int count) {
    return '$count أعمدة';
  }

  @override
  String get imagesFitSingleRow => 'في صف واحد';

  @override
  String get reminderDone => 'تم';

  @override
  String get dateToday => 'اليوم';

  @override
  String get dateTomorrow => 'غدًا';

  @override
  String get noteDuplicatedNoAttachments => 'تم التكرار — لم تُنقل المرفقات';

  @override
  String get pdfGoToPage => 'الانتقال إلى صفحة';

  @override
  String get pdfThumbnails => 'تصفح الصفحات';

  @override
  String get pdfBookmarks => 'الإشارات المرجعية';

  @override
  String get pdfBookmarkAdd => 'إضافة إشارة مرجعية';

  @override
  String get pdfBookmarkRemove => 'إزالة الإشارة المرجعية';

  @override
  String get pdfNoBookmarks =>
      'لا توجد إشارات مرجعية بعد. اضغط زر الإشارة في شريط الصفحة.';

  @override
  String get pdfRotateView => 'تدوير العرض';

  @override
  String get pdfCopyPageText => 'نسخ نص الصفحة';

  @override
  String get pdfCapturePage => 'التقاط الصفحة (ذكاء اصطناعي / نسخ)';

  @override
  String get pdfSlideshow => 'تقدّم تلقائي';

  @override
  String get pdfSlideshowStop => 'إيقاف التقدّم التلقائي';

  @override
  String get pdfFirstPage => 'الصفحة الأولى';

  @override
  String get pdfLastPage => 'الصفحة الأخيرة';

  @override
  String get collaborators => 'المتعاونون';

  @override
  String get collaboratorsInfo =>
      'يرى الأشخاص الذين تضيفهم هذه الملاحظة على شاشتهم الرئيسية ويعدّلونها معك مباشرة.';

  @override
  String get collaboratorsOwner => 'المالك';

  @override
  String get collaboratorsFriendsTitle => 'أصدقاؤك';

  @override
  String get collaboratorsLeave => 'مغادرة الملاحظة المشتركة';

  @override
  String get collaboratorsLeaveConfirm =>
      'لن تظهر هذه الملاحظة على شاشتك الرئيسية بعد الآن. مغادرة؟';

  @override
  String get collaboratorsSaved => 'تم تحديث المشاركة';

  @override
  String get collaboratorsOnlyOwner =>
      'يمكن لمالك الملاحظة فقط تغيير المتعاونين.';

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
  String get shortcutSections => 'التبديل بين الأقسام';

  @override
  String get shortcutHelp => 'إظهار الاختصارات';

  @override
  String get shortcutFullscreen => 'تبديل ملء الشاشة للملاحظة';

  @override
  String get shortcutEscape => 'مغادرة ملء الشاشة ثم إغلاق الملاحظة';

  @override
  String get showNoteList => 'إظهار قائمة الملاحظات';

  @override
  String get shortcutSwitchFolder => 'تبديل المجلدات';

  @override
  String get shortcutMouseWheel => 'العجلة';

  @override
  String get shortcutGridColumns => 'عدد الأعمدة';

  @override
  String get shortcutSelectAll => 'أثناء التحديد: تحديد الكل';

  @override
  String get shortcutDeleteSelected => 'نقل المحدد إلى السلة';

  @override
  String get sharedFolderNoFileDrop =>
      'لا يمكن إفلات الملفات على مجلد مشترك. افتح ملاحظة وأفلِت الملف فيها.';

  @override
  String get shortcutAdjacentNote => 'الملاحظة السابقة / التالية في القائمة';

  @override
  String get shortcutCloseNote => 'إغلاق الملاحظة';

  @override
  String get softKeyboardShow =>
      'إظهار لوحة المفاتيح على الشاشة (لوحة مفاتيح فعلية متصلة)';

  @override
  String get softKeyboardHide => 'إخفاء لوحة المفاتيح على الشاشة';

  @override
  String get goHome => 'العودة للرئيسية';

  @override
  String get loginFeatureSyncTitle => 'الملاحظات نفسها على كل جهاز';

  @override
  String get loginFeatureSyncBody =>
      'مزامنة فورية بين الهاتف والجهاز اللوحي والكمبيوتر والويب.';

  @override
  String get loginFeatureAiTitle => 'تنظيم ذكي';

  @override
  String get loginFeatureAiBody =>
      'إملاء صوتي سريع، تدقيق إملائي دون إنترنت، أقسام بقالة ذكية ووسوم.';

  @override
  String get loginFeatureShareTitle => 'اكتبوا معًا';

  @override
  String get loginFeatureShareBody =>
      'شارك الملاحظات والمجلدات مباشرة مع أصدقائك.';

  @override
  String get loginFeatureInkTitle => 'القلم وPDF';

  @override
  String get loginFeatureInkBody =>
      'دوّن ملاحظات بخط اليد، واكتب على ملفات PDF والشرائح.';

  @override
  String get foldersTitle => 'المجلدات';

  @override
  String get foldersEmpty => 'لا توجد مجلدات بعد. أنشئ واحدًا لتنظيم ملاحظاتك.';

  @override
  String get foldersEmptyTitle => 'لا توجد مجلدات هنا بعد';

  @override
  String get foldersEmptyHint => 'أنشئ واحدًا لتنظيم ملاحظاتك.';

  @override
  String get folderColor => 'اللون';

  @override
  String get folderColorAuto => 'تلقائي';

  @override
  String get foldersMine => 'مجلداتي';

  @override
  String get foldersSharedSection => 'المجلدات المشتركة';

  @override
  String trashDaysShort(int count) {
    return '$count ي';
  }

  @override
  String get trashTodayShort => 'اليوم';

  @override
  String get trashSoonSection => 'ستُحذف نهائيًا قريبًا';

  @override
  String get trashRestSection => 'ملاحظات محذوفة أخرى';

  @override
  String get folderOrderTitle => 'ترتيب المجلدات';

  @override
  String get folderReorder => 'إعادة ترتيب المجلدات';

  @override
  String get folderOrderManual => 'مخصص';

  @override
  String get folderOrderName => 'حسب الاسم';

  @override
  String get folderOrderNewest => 'الأحدث أولًا';

  @override
  String get folderOrderNoteCount => 'حسب عدد الملاحظات';

  @override
  String get folderOrderHint =>
      'اسحب المقابض لإعادة الترتيب (السحب يحوّل إلى \"يدوي\"). يُستخدم هذا الترتيب أيضًا في شريط المجلدات وعند السحب الجانبي.';

  @override
  String get swipeModeTitle => 'السحب يمينًا/يسارًا في الشاشة الرئيسية';

  @override
  String get swipeModeFolders => 'التبديل بين المجلدات';

  @override
  String get swipeModeFilters => 'التبديل بين الفلاتر والوسوم';

  @override
  String get swipeModeBoth => 'المجلدات والفلاتر والوسوم';

  @override
  String get swipeModeOff => 'إيقاف';

  @override
  String get shareIncludeTitle => 'العنوان';

  @override
  String get shareIncludeChecked => 'العناصر المنجزة';

  @override
  String get shareIncludeTags => 'الوسوم';

  @override
  String get shareTextAction => 'مشاركة النص';

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
      other: '$count تطابقات',
      one: 'تطابق واحد',
      zero: 'لا تطابقات',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'البحث في المرفقات والذكاء الاصطناعي';

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
      'يمكنك أيضًا القرص على الشاشة الرئيسية لتغييرها.';

  @override
  String get gridColumnsAuto => 'تلقائي';

  @override
  String get folderShelfSetting => 'المجلدات على الشاشة الرئيسية';

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
  String get deviceStorageCache => 'الذاكرة المؤقتة والملفات المؤقتة';

  @override
  String get deviceStorageAi => 'ذاكرة الذكاء الاصطناعي المؤقتة';

  @override
  String get deviceStorageTotal => 'الإجمالي (دون التطبيق نفسه)';

  @override
  String get deviceStorageInfo =>
      'مسح الذاكرة المؤقتة لا يحذف الملاحظات أو المرفقات.';

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
      'تُزال الملاحظة ومرفقاتها من السحابة ولن تظهر على أجهزتك الأخرى. إن أزلت التطبيق أو غيّرت الهاتف تذهب هذه الملاحظة أيضًا. يمكنك إعادة تشغيل المزامنة في أي وقت.';

  @override
  String get localOnlyConfirm => 'إيقاف المزامنة';

  @override
  String get localOnlyOnDone => 'الملاحظة الآن على هذا الجهاز فقط';

  @override
  String get localOnlyOffDone => 'تُزامَن الملاحظة مجددًا';

  @override
  String get localOnlySharedBlocked => 'لا يمكن إيقاف المزامنة لملاحظة مشتركة';

  @override
  String get localOnlyDownloadFailed =>
      'تعذّر تنزيل بعض المرفقات إلى هذا الجهاز. تحقق من اتصالك وحاول مجددًا؛ لم تتغير الملاحظة.';

  @override
  String get templatesTitle => 'القوالب';

  @override
  String get templatesSubtitle =>
      'ابدأ بتخطيط جاهز؛ يمكنك تغيير كل شيء لاحقًا.';

  @override
  String get fromTemplate => 'قوالب جاهزة';

  @override
  String get tplShoppingName => 'قائمة التسوق';

  @override
  String get tplShoppingItems => 'خبز، حليب، بيض، فاكهة، خضار';

  @override
  String get tplShoppingDesc => 'أشِّر على ما اشتريته؛ وينتقل للأسفل';

  @override
  String get tplTodoDesc => 'قائمة فارغة بتاريخ اليوم';

  @override
  String get tplTravelName => 'قائمة الأمتعة';

  @override
  String get tplTravelItems =>
      'الهوية / جواز السفر، شاحن الهاتف، الأدوية، فرشاة الأسنان، الملابس، سماعات الرأس';

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
  String get tplRecipeSteps => 'الخطوات';

  @override
  String get tplRecipeNotes => 'ملاحظات';

  @override
  String get tplRecipeDesc => 'المكونات والخطوات';

  @override
  String get tplWeeklyName => 'الخطة الأسبوعية';

  @override
  String get tplWeeklyDesc => 'أيام هذا الأسبوع كعناوين';

  @override
  String get tplExpenseDesc => 'التاريخ، الوصف، المبلغ';

  @override
  String get tplReadingDesc => 'المصدر، الملخص، الاقتباسات';

  @override
  String get settingsThemeHeader => 'المظهر';

  @override
  String get settingsGroupPrivacyNotify => 'الخصوصية والإشعارات';

  @override
  String get settingsGroupText => 'النص';

  @override
  String get settingsGroupDictation => 'الكتابة بالصوت';

  @override
  String get settingsGroupGestures => 'الإيماءات';

  @override
  String get settingsGroupSortView => 'الترتيب والتخطيط';

  @override
  String get settingsGroupShared => 'الملاحظات المشتركة';

  @override
  String get settingsGroupAttachments => 'المرفقات';

  @override
  String get settingsGroupBackup => 'النسخ الاحتياطي';

  @override
  String get settingsGroupSession => 'الجلسة';

  @override
  String get settingsSecurityTitle => 'الأمان';

  @override
  String get settingsSecuritySummary => 'قفل الملاحظة، قفل التطبيق';

  @override
  String get settingsGroupAbout => 'حول';

  @override
  String get settingsGroupVersion => 'الإصدار';

  @override
  String get settingsCardsHeader => 'البطاقات والقوائم';

  @override
  String get shareTargetTitle => 'إضافة إلى الملاحظات';

  @override
  String get shareTargetNew => 'ملاحظة جديدة';

  @override
  String get shareTargetExisting => 'ملاحظة موجودة';

  @override
  String get shareTargetCreate => 'إنشاء ملاحظة';

  @override
  String get shareTargetSearch => 'البحث في الملاحظات';

  @override
  String get shareTargetNoNotes => 'لا توجد ملاحظات للإضافة إليها';

  @override
  String get shareTargetNoMatch => 'لا توجد ملاحظات مطابقة';

  @override
  String shareTargetMore(int count) {
    return '+$count ملفات';
  }

  @override
  String get sharePreviewExpand => 'توسيع المعاينة';

  @override
  String get sharePreviewCollapse => 'طي المعاينة';

  @override
  String get templatesSearch => 'البحث في القوالب';

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
      'ليس لديك قوالب بعد. اختر «حفظ كقالب» من قائمة الملاحظة وسيظهر هنا.';

  @override
  String get templatesMineInfo => 'قالبك';

  @override
  String get templateRename => 'إعادة تسمية';

  @override
  String get templateDelete => 'حذف القالب';

  @override
  String get templateNameTitle => 'اسم القالب';

  @override
  String get templateNameHint => 'مثلًا: مشتريات الأسبوع';

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
  String get templateListChecks => 'مربعات اختيار';

  @override
  String get templateListNumbers => 'مرقّمة';

  @override
  String get templateAddItem => 'إضافة عنصر';

  @override
  String get tplShopProduce => 'فواكه وخضار';

  @override
  String get tplShopProduceItems =>
      'طماطم، خيار، بصل، بطاطس، ليمون، موز، تفاح، بقدونس';

  @override
  String get tplShopBreakfast => 'الفطور';

  @override
  String get tplShopBreakfastItems => 'جبن، زيتون، زبدة، عسل، مربى، زبادي';

  @override
  String get tplShopPantry => 'المؤن';

  @override
  String get tplShopPantryItems =>
      'أرز، معكرونة، دقيق، سكر، زيت زيتون، عدس، شاي، قهوة';

  @override
  String get tplShopCleaning => 'التنظيف';

  @override
  String get tplShopCleaningItems =>
      'سائل الصحون، مسحوق الغسيل، ورق التواليت، مناديل ورقية، أكياس القمامة';

  @override
  String get tplShopPersonal => 'العناية الشخصية';

  @override
  String get tplShopPersonalItems => 'شامبو، معجون أسنان، صابون، مزيل عرق';

  @override
  String get tplTravelDocs => 'المستندات';

  @override
  String get tplTravelDocsItems =>
      'التذاكر، حجز الفندق، رخصة القيادة، تأمين السفر، نقود / بطاقات';

  @override
  String get tplTravelClothes => 'الملابس';

  @override
  String get tplTravelClothesItems =>
      'قمصان، بناطيل، ملابس داخلية، جوارب، بيجامة، سترة، أحذية';

  @override
  String get tplTravelCare => 'أدوات النظافة';

  @override
  String get tplTravelCareItems =>
      'معجون أسنان، شامبو، واقي شمس، أدوات حلاقة، مزيل عرق';

  @override
  String get tplTravelTech => 'الإلكترونيات';

  @override
  String get tplTravelTechItems => 'بطارية متنقلة، محوّل قابس، سماعات، كابلات';

  @override
  String get tplHabitsName => 'متتبع العادات';

  @override
  String get tplHabitsDesc => 'أشِّر كل يوم ولا تقطع السلسلة';

  @override
  String get tplHabitsItems =>
      '8 أكواب ماء، مشي 30 دقيقة، قراءة 20 صفحة، النوم مبكرًا، ساعة بلا شاشات';

  @override
  String get tplCleaningName => 'تنظيف المنزل';

  @override
  String get tplCleaningDesc => 'قائمة تنظيف أسبوعية';

  @override
  String get tplCleaningItems =>
      'إزالة الغبار، الكنس بالمكنسة، مسح الأرضية، تنظيف الحمام، أسطح المطبخ، الغسيل، إخراج القمامة، تغيير الشراشف';

  @override
  String get tplMovingName => 'قائمة الانتقال';

  @override
  String get tplMovingDesc => 'أمور قبل الانتقال وبعده';

  @override
  String get tplMovingItems =>
      'حجز شركة نقل، شراء صناديق وشريط لاصق، تحديث العنوان، حسابات الكهرباء / الماء / الغاز، نقل الإنترنت، تسليم المفاتيح';

  @override
  String get tplGiftsName => 'قائمة الهدايا';

  @override
  String get tplGiftsDesc => 'من يحصل على ماذا، أفكار';

  @override
  String get tplGiftsItems => 'أمي، أبي، أخي/أختي، صديق';

  @override
  String get tplWatchlistName => 'قائمة المشاهدة';

  @override
  String get tplWatchlistDesc => 'أفلام ومسلسلات وكتب للاحقًا';

  @override
  String get tplWorkoutName => 'التمرين';

  @override
  String get tplWorkoutDesc => 'قائمة تمارين من الإحماء إلى الإطالة';

  @override
  String get tplWorkoutItems =>
      'إحماء 5 دقائق، قرفصاء 3×12، ضغط 3×10، بطن 3×15، بلانك 3×45 ث، إطالة 5 دقائق';

  @override
  String get tplGoalsName => 'الأهداف';

  @override
  String get tplGoalsDesc => 'أهداف السنة والشهر والأسبوع';

  @override
  String get tplGoalsYear => 'هذا العام';

  @override
  String get tplGoalsMonth => 'هذا الشهر';

  @override
  String get tplGoalsWeek => 'هذا الأسبوع';

  @override
  String get tplGoalsWhy => 'لماذا يهم؟';

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
    return 'حُذف «$name»';
  }

  @override
  String get addVideoFromGallery => 'فيديو من المعرض';

  @override
  String get addYouTubeVideo => 'فيديو YouTube';

  @override
  String get addYouTubeVideoSubtitle =>
      'يُشغَّل في الملاحظة، شاهده في نافذة صغيرة';

  @override
  String get youTubeLinkHelp =>
      'الصق رابط فيديو YouTube ‏(youtube.com أو youtu.be).';

  @override
  String get youTubeInvalidLink => 'هذا ليس رابط فيديو YouTube';

  @override
  String get youTubeOpenInBrowserInfo =>
      'لا يمكن تشغيل الفيديو داخل التطبيق على هذا الجهاز؛ يمكن فتحه في المتصفح.';

  @override
  String get youTubeOpenExternal => 'فتح في YouTube';

  @override
  String get pictureInPicture => 'صورة داخل صورة';

  @override
  String get pinMediaRelease => 'أفلِت: تثبيت في الأعلى (الملاحظة بالأسفل)';

  @override
  String get unpinMediaRelease => 'أفلِت: عائم';

  @override
  String get pinnedMediaResize => 'ارتفاع اللوحة — اسحب للتغيير';

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
      'حذف نص هذه الصفحة؟ تنتقل صورها إلى الصفحة المجاورة. يمكنك استرجاعه بالتراجع.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'صورة';

  @override
  String get embedNewVideo => 'فيديو';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'ماذا تريد أن تضمّن؟';

  @override
  String get embedPickInfo => 'اضغط على النص لفتح العنصر المضمّن في مكانه.';

  @override
  String get embedSectionNew => 'إضافة جديد';

  @override
  String get embedSectionExisting => 'المرفقات في هذه الملاحظة';

  @override
  String get embedSectionLink => 'رابط';

  @override
  String get embedLinkHint => 'عنوان ويب (مثل example.com)';

  @override
  String get embedLinkApply => 'ربط';

  @override
  String get embedReplace => 'استبدال';

  @override
  String get embedRemove => 'إزالة التضمين';

  @override
  String get embedRemoved => 'أُزيل التضمين';

  @override
  String get guideTitle => 'دليل الاستخدام';

  @override
  String get guideMenuInfo => 'كل ميزة خطوة بخطوة';

  @override
  String get guideSearchHint => 'ابحث في الدليل — «صفحة»، «YouTube»';

  @override
  String get guideOpenScreen => 'أرني';

  @override
  String guideNoResults(String query) {
    return 'لا نتائج لـ «$query»';
  }

  @override
  String get copyVideoLink => 'نسخ الرابط';

  @override
  String get videoLinkCopied => 'تم نسخ الرابط';

  @override
  String get menuSectionOrganize => 'تنظيم';

  @override
  String get menuSectionCopy => 'نسخ';

  @override
  String get menuSectionTools => 'أدوات';

  @override
  String get menuSectionProtect => 'الحماية والتخزين';

  @override
  String get menuSectionApp => 'التطبيق';

  @override
  String cardMoreFiles(int count) {
    return '+$count ملفات أخرى';
  }

  @override
  String cardAudioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تسجيلات صوتية',
      one: 'تسجيل صوتي',
    );
    return '$_temp0';
  }

  @override
  String get cardBubbleDocument => 'PDF مع فقاعات';

  @override
  String get cardBubbleSlides => 'شرائح مع فقاعات';

  @override
  String get cardKindPdf => 'PDF';

  @override
  String get cardKindSlides => 'شرائح';

  @override
  String cardBubbleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فقاعات',
      one: 'فقاعة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get quickAddYouTube => 'فيديو YouTube';

  @override
  String get docViewToBubbles => 'التبديل إلى عرض الفقاعات';

  @override
  String get docViewToClassic => 'التبديل إلى العرض الكلاسيكي';

  @override
  String get docViewSwitchedBubbles =>
      'عرض الفقاعات: المستند في الأعلى وملاحظات الصفحات بالأسفل. يُحتفظ بتخطيطك الكلاسيكي.';

  @override
  String get docViewSwitchedClassic =>
      'العرض الكلاسيكي: المستند مرفق على الصفحة. يُحتفظ بالفقاعات وملاحظات الصفحات.';

  @override
  String get docViewTextKept => 'يبقى نص الملاحظة في العرض الكلاسيكي.';

  @override
  String get captureModeChangeLater =>
      'يمكنك التبديل لاحقًا بشريحة فقاعات / كلاسيكي في الملاحظة.';

  @override
  String get attachmentSyncTitle => 'مزامنة المرفقات';

  @override
  String get driveSectionTitle => 'المرفقات في Google Drive الخاص بك';

  @override
  String get driveConnectTitle => 'احفظ المرفقات في Google Drive الخاص بك';

  @override
  String get driveConnectInfo =>
      'تُحفظ الصور وملفات PDF والشرائح والتسجيلات الصوتية في مساحتك على Drive، في مجلد «Notlar»، وتُنزَّل على أجهزتك الأخرى. تبقى الفيديوهات على الجهاز.';

  @override
  String get driveConnect => 'ربط';

  @override
  String get driveDisconnect => 'قطع الاتصال';

  @override
  String get driveConnected =>
      'تم ربط Google Drive — يجري نسخ المرفقات احتياطيًا.';

  @override
  String get driveConnectedInfo => 'متصل · المرفقات في مجلد «Notlar» على Drive';

  @override
  String driveUsage(String used, String limit) {
    return 'Drive: مستخدم $used من $limit';
  }

  @override
  String driveConnectFailed(String error) {
    return 'تعذّر ربط Google Drive. $error';
  }

  @override
  String get driveApiDisabled =>
      'واجهة Drive API معطلة في مشروع Google Cloud: فعّل \"Google Drive API\" من وحدة التحكم وحاول مجددًا.';

  @override
  String get driveDisconnected =>
      'قُطع اتصال Drive. تنتظر المرفقات الجديدة على الجهاز حتى تعيد الربط.';

  @override
  String get textOnlyTitle => 'مزامنة النص فقط';

  @override
  String get textOnlyInfo =>
      'حسابات الضيوف تزامن النص فقط؛ وتبقى المرفقات على هذا الجهاز. اربط حساب Google لحفظ المرفقات في Google Drive الخاص بك.';

  @override
  String get storageModeInfo => 'على الويب، تُرفع المرفقات إلى سحابة التطبيق.';

  @override
  String driveWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرفقات بانتظار Google Drive — اضغط للربط',
      one: 'مرفق واحد بانتظار Google Drive — اضغط للربط',
    );
    return '$_temp0';
  }

  @override
  String get driveDownloading => 'جارٍ تنزيل المرفق من Google Drive…';

  @override
  String get driveNeededForFile =>
      'هذا المرفق في Google Drive الخاص بك. اربط Drive من الإعدادات ← المزامنة لرؤيته.';

  @override
  String get bubbleDone => 'تم';

  @override
  String get bubbleEditShort => 'تعديل';

  @override
  String get bubblePlainModeShort => 'نص';

  @override
  String get pageBarMore => 'خيارات الصفحة والملاحظة';

  @override
  String viewModeChanged(String from, String to) {
    return '$from ← $to';
  }

  @override
  String get videoRotate => 'تدوير الصورة';

  @override
  String get viewModeTitle => 'العرض';

  @override
  String get viewModeEmbed => 'تضمين في النص';

  @override
  String get viewModeEmbedHint =>
      'ضمّن هذا المرفق في كلمة من الملاحظة — الضغط على الكلمة يفتحه';

  @override
  String get viewModePinned => 'مثبّت';

  @override
  String get viewModeFloating => 'عائم';

  @override
  String get viewModeBubbles => 'فقاعات';

  @override
  String get viewModePinnedHint =>
      'تثبيت في الأعلى — يبقى فوق والملاحظة تتمرر تحته';

  @override
  String get viewModeFloatingHint => 'عائم على الصفحة — يلتف النص حوله';

  @override
  String get viewModeBubblesHint =>
      'عرض الفقاعات — فقاعات وتظليل وقلم على الصفحة';

  @override
  String get videoNoteAtTime => 'ملاحظة في هذه اللحظة';

  @override
  String get videoNoteAtTimeShort => 'ملاحظة';

  @override
  String get videoTimeUnknown =>
      'تعذّرت قراءة وقت الفيديو — شغّل الفيديو أولًا.';

  @override
  String get videoSpeed => 'سرعة التشغيل';

  @override
  String get videoLoop => 'تكرار';

  @override
  String get bubbleSmaller => 'فقاعة أصغر';

  @override
  String get bubbleLarger => 'فقاعة أكبر';

  @override
  String get bubbleAllSmaller => 'تصغير كل الفقاعات';

  @override
  String get bubbleAllLarger => 'تكبير كل الفقاعات';

  @override
  String get bubblesShow => 'إظهار الفقاعات';

  @override
  String get bubblesHide => 'إخفاء الفقاعات';

  @override
  String get shareIncludeVideoLinks => 'روابط الفيديو';

  @override
  String get shareQuickPdf => 'PDF';

  @override
  String get shareAsImage => 'صورة';

  @override
  String shareAttachmentFiles(int count) {
    return 'الملفات ($count)';
  }

  @override
  String get shareToFriendShort => 'إرسال إلى صديق';

  @override
  String get shareCollaborateShort => 'تعديل مشترك';

  @override
  String get shareAsNoteShort => 'حزمة ملاحظة';

  @override
  String get shareQuickPreparing => 'جارٍ التجهيز…';

  @override
  String get shareAttachmentFilesNone =>
      'لا توجد ملفات مرفقات على هذا الجهاز لمشاركتها.';

  @override
  String get attachmentRemoved => 'أُزيل المرفق';

  @override
  String get customizeHideItem => 'إخفاء';

  @override
  String get customizeShowItem => 'إظهار';

  @override
  String get customizeModeTitle => 'وضع التعديل';

  @override
  String get customizeModeTitleShort => 'تعديل';

  @override
  String customizeHiddenCount(int count) {
    return '$count مخفية · اضغط للتغيير';
  }

  @override
  String get customizeDone => 'تم';

  @override
  String videoBackSeconds(int seconds) {
    return 'رجوع $seconds ث';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return 'تقديم $seconds ث';
  }

  @override
  String get personalizeTitle => 'التخصيص';

  @override
  String get personalizeInfo => 'اختر المناطق والأزرار الظاهرة والإضافات';

  @override
  String get customizeStartTitle => 'التعديل على الشاشة';

  @override
  String get customizeStartInfo =>
      'اضغط على الأزرار والمناطق لإخفائها أو إظهارها؛ واضغط «تم» عند الانتهاء.';

  @override
  String get customizeStart => 'بدء وضع التعديل';

  @override
  String get customizeActive => 'وضع التعديل مفعّل';

  @override
  String get customizeHint => 'ضغطة: إخفاء/إظهار · إعادة ترتيب: حرّكه';

  @override
  String get customizeShown => 'ظاهر';

  @override
  String get customizeSurfaceBottomBar => 'الشريط السفلي';

  @override
  String get customizeSurfaceTopBar => 'الشريط العلوي';

  @override
  String get customizeSurfaceQuickRow => 'الصف السريع';

  @override
  String get customizeSurfaceAddPanel => 'لوحة \"+\"';

  @override
  String get customizeSurfacePinned => 'المرفق المثبّت';

  @override
  String get customizeSurfacePen => 'الأقلام';

  @override
  String get personalizeModules => 'الإضافات';

  @override
  String get moduleAi => 'الذكاء الاصطناعي';

  @override
  String get moduleAiInfo =>
      'أزرار الذكاء الاصطناعي في الشاشة الرئيسية وشاشة الملاحظة';

  @override
  String get moduleVoice => 'الصوت';

  @override
  String get moduleVoiceInfo =>
      'ملاحظات صوتية بالذكاء الاصطناعي، إملاء، تسجيل صوتي';

  @override
  String get moduleVideo => 'الفيديو';

  @override
  String get moduleVideoInfo => 'تسجيل، فيديوهات المعرض، YouTube';

  @override
  String get moduleDocuments => 'المستندات';

  @override
  String get moduleScan => 'المسح الضوئي';

  @override
  String get moduleScanInfo => 'مسح المستندات ورموز QR';

  @override
  String get moduleDrawing => 'الرسم';

  @override
  String get moduleDrawingInfo => 'الكتابة اليدوية والرسم';

  @override
  String get moduleTemplates => 'القوالب';

  @override
  String get moduleTemplatesInfo => 'ملاحظات من القوالب، قائمة التسوق، الدفتر';

  @override
  String get moduleTags => 'شرائح الملاحظة';

  @override
  String get moduleTagsInfo => 'شرائح الوسم والمجلد والتذكير تحت العنوان';

  @override
  String get moduleCollaboration => 'التعاون';

  @override
  String get moduleCollaborationInfo => 'زر إضافة شخص في شاشة الملاحظة';

  @override
  String get moduleMixed => 'مفعّل جزئيًا';

  @override
  String get personalizeBarLeft => 'الكبسولة اليسرى · الأدوات';

  @override
  String get personalizeBarRight => 'الكبسولة اليمنى · الذكاء الاصطناعي والصوت';

  @override
  String get personalizeBarReset => 'إعادة تعيين الشريط السفلي';

  @override
  String get personalizeBarTop => 'الشريط العلوي · ترتيب الأزرار';

  @override
  String get personalizeBarMoveRight => 'نقل إلى الكبسولة اليمنى';

  @override
  String get personalizeBarMoveLeft => 'نقل إلى الكبسولة اليسرى';

  @override
  String get reorderHandle => 'إعادة الترتيب';

  @override
  String get personalizeVideo => 'الفيديو';

  @override
  String get personalizeHome => 'الشاشة الرئيسية';

  @override
  String get personalizeBubbles => 'الفقاعات';

  @override
  String get personalizeReset => 'إعادة إلى الافتراضي';

  @override
  String get personalizeResetConfirm =>
      'إعادة كل إعدادات الظهور والتنقل إلى الافتراضي؟';

  @override
  String get personalizeResetDone => 'استُعيدت الإعدادات الافتراضية';

  @override
  String get uiItemAttachments => 'المرفقات';

  @override
  String get uiItemDate => 'تعديل التاريخ';

  @override
  String get uiItemSync => 'أيقونة المزامنة';

  @override
  String get uiItemVideoTime => 'تسمية الوقت';

  @override
  String get videoSeekBack => 'إرجاع';

  @override
  String get videoSeekForward => 'تقديم سريع';

  @override
  String get bubbleSizeSetting => 'حجم الفقاعة';

  @override
  String get noteMenuCustomize => 'تخصيص الشاشة';

  @override
  String secondsShort(int seconds) {
    return '$seconds ث';
  }

  @override
  String get uiItemVideoBadge => 'فيديو';

  @override
  String get listPartRemoved => 'أُزيلت القائمة';

  @override
  String get textPartRemoved => 'أُزيل النص';

  @override
  String get notePartsMenu => 'الأقسام';

  @override
  String get removeListPart => 'إزالة القائمة';

  @override
  String get removeTextPart => 'إزالة النص';

  @override
  String get transcriptTitle => 'النص المفرّغ';

  @override
  String get transcriptAction => 'تفريغ';

  @override
  String get transcriptFileSuffix => 'نص مفرّغ';

  @override
  String get transcriptWorkingAudio => 'جارٍ تفريغ الصوت…';

  @override
  String get transcriptWorkingVideo => 'جارٍ تفريغ الفيديو…';

  @override
  String get transcriptWorkingImage => 'جارٍ قراءة النص في الصورة…';

  @override
  String get transcriptLongHint =>
      'قد تستغرق التسجيلات الطويلة بضع دقائق؛ أبقِ هذه الشاشة مفتوحة.';

  @override
  String get transcriptSaved => 'حُفظ في الملاحظة كمرفق نصي';

  @override
  String get transcriptInsertSelection => 'إضافة المحدد إلى الملاحظة';

  @override
  String get transcriptInsertAll => 'إضافة الكل إلى الملاحظة';

  @override
  String get transcriptInserted => 'أُضيف إلى الملاحظة';

  @override
  String get transcriptNewNote => 'ملاحظة جديدة';

  @override
  String get transcriptShowTimes => 'الطوابع الزمنية';

  @override
  String get transcriptDelete => 'حذف النص المفرّغ';

  @override
  String get transcriptDeleteConfirm =>
      'حذف النص المفرّغ؟ يبقى الملف المصدر في الملاحظة.';

  @override
  String get transcriptEmpty => 'لم يُعثر على نص.';

  @override
  String transcriptUnsupported(String format) {
    return 'لا يمكن تفريغ صيغة التسجيل هذه ($format).';
  }

  @override
  String get transcriptEdit => 'تعديل';

  @override
  String get transcriptSave => 'حفظ';

  @override
  String transcriptWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count كلمات',
      one: 'كلمة واحدة',
    );
    return '$_temp0';
  }

  @override
  String transcriptNoteTitle(String name) {
    return 'نص مفرّغ: $name';
  }

  @override
  String get transcriptOnDevice =>
      'قراءة على الجهاز · دون إنترنت أو نقاط ذكاء اصطناعي';

  @override
  String get addAudioFile => 'إضافة ملف صوتي';

  @override
  String get transcribeFile => 'تفريغ ملف';

  @override
  String get transcribeFileSubtitle =>
      'اختر صوتًا أو فيديو أو صورة؛ ويُضاف نصه إلى الملاحظة';

  @override
  String cardTranscriptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نصوص مفرّغة',
      one: 'نص مفرّغ',
    );
    return '$_temp0';
  }

  @override
  String get transcriptPickTitle => 'ملف للتفريغ';

  @override
  String get transcriptUnsupportedFile =>
      'لا يمكن تفريغ هذا النوع من الملفات (اختر صوتًا أو فيديو أو صورة).';

  @override
  String get pickPdfTitle => 'اختيار PDF';

  @override
  String get pickSlidesTitle => 'اختيار عرض تقديمي';

  @override
  String get pickImagesTitle => 'اختيار صور';

  @override
  String get fileAppPickerTitle => 'اختيار الملفات بقارئ الملفات';

  @override
  String get fileAppPickerInfo =>
      'إضافة ملف تفتح قارئ الملفات مباشرة؛ وعند الإيقاف تختار تطبيقًا.';

  @override
  String get viewModeAttached => 'مُرفق';

  @override
  String get viewModeAttachedHint => 'كمرفق — يبقى في الشريط بالأسفل';

  @override
  String get textToBubblesPreparing => 'جارٍ تنسيق النص كمستند…';

  @override
  String get attachmentActions => 'إجراءات المرفق';

  @override
  String get attachmentUploadQueued => 'بانتظار الرفع';

  @override
  String get attachmentWaitingOwner => 'بانتظار أن يرفعه من أضافه';

  @override
  String attachmentsUploadingCount(int count) {
    return 'جارٍ رفع $count مرفقات';
  }

  @override
  String get sharedNoteNew => 'جديد';

  @override
  String sharedNoteUpdatedBy(String name) {
    return 'حدّثها $name';
  }

  @override
  String get sharedMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get attachmentSaveAs => 'حفظ باسم';

  @override
  String attachmentSavedAs(String name) {
    return 'حُفظ $name';
  }

  @override
  String get attachmentSaveAsFailed => 'تعذّر حفظ الملف';

  @override
  String get sharedHubTitle => 'الوارد والمشترك';

  @override
  String get voiceAutoStop => 'التوقف عند الصمت';

  @override
  String get voiceAutoStopInfo => 'يتوقف الاستماع بعد صمت قصير عند انتهائك.';

  @override
  String get voiceSmartCommands => 'أوامر ذكية';

  @override
  String get voiceSmartCommandsInfo =>
      'يفهم أوامر مثل «احذف الكلمة الأخيرة» و«استبدل X بـ Y» و«سطر جديد» و«تراجع»؛ القائمة الكاملة في دليل الاستخدام.';

  @override
  String get voiceAutoStopSoon => 'صمت — سيتوقف قريبًا';

  @override
  String get dictationPause => 'إيقاف مؤقت';

  @override
  String get dictationResume => 'استئناف';

  @override
  String get dictationPaused => 'متوقف مؤقتًا';

  @override
  String get dictationUndoChunk => 'التراجع عن آخر عبارة';

  @override
  String dictationLocaleTooltip(String lang) {
    return 'لغة الكلام: $lang';
  }

  @override
  String get voiceCmdDeleted => 'حُذف';

  @override
  String get voiceCmdReplaced => 'استُبدل';

  @override
  String get voiceCmdNewLine => 'سطر جديد';

  @override
  String get voiceCmdUndone => 'تم التراجع';

  @override
  String get voiceCmdCleared => 'تم المسح';

  @override
  String get fullscreenExit => 'الخروج من ملء الشاشة';

  @override
  String get voiceCaptureContinue => 'واصل التحدث';

  @override
  String get voiceCmdPunctuation => 'أُضيفت علامة ترقيم';

  @override
  String get voiceCmdTitle => 'تم ضبط العنوان';

  @override
  String get voiceSilenceLabel => 'مدة الانتظار';

  @override
  String get voiceSilenceShort => 'قصيرة';

  @override
  String get voiceSilenceNormal => 'عادية';

  @override
  String get voiceSilenceLong => 'طويلة';

  @override
  String get voiceOffline => 'التعرّف دون إنترنت';

  @override
  String get voiceOfflineInfo => 'مع حزمة اللغة يُفرَّغ الكلام دون إنترنت.';

  @override
  String get discoverable => 'السماح للآخرين بإيجادي بالاسم';

  @override
  String get discoverableInfo =>
      'عند التفعيل يمكن للآخرين إيجادك في «البحث عن أشخاص» بأول 3 أحرف من اسمك أو بريدك الكامل. وعند الإيقاف لا يمكن إرسال طلب إلا لمن يعرف بريدك.';

  @override
  String get friendsSearchNeedsGoogle =>
      'سجّل الدخول بحساب Google للبحث عن أشخاص.';

  @override
  String get friendsSearchRateLimited =>
      'عمليات بحث كثيرة. حاول مجددًا بعد دقيقة.';

  @override
  String get updateRequiredBody =>
      'هذا الإصدار قديم: تُفتح الملاحظات للقراءة فقط. حدّث التطبيق لتبقى بياناتك سليمة.';

  @override
  String get updateAction => 'تحديث';

  @override
  String get attachmentUnsupportedTitle => 'حدّث التطبيق لفتح هذا المرفق';

  @override
  String get attachmentUnsupportedBody =>
      'أُضيف هذا المرفق من إصدار أحدث من التطبيق. لا يمكن لهذا الإصدار عرضه؛ ويُحتفظ به كما هو.';

  @override
  String noteTooLarge(String size, String part) {
    return 'هذه الملاحظة تكبر كثيرًا ($size / 1024 كيلوبايت) — أكبر جزء: $part. انقل بعضها إلى ملاحظة منفصلة وإلا قد يفشل الحفظ.';
  }

  @override
  String get noteSizeBody => 'النص';

  @override
  String get noteSizeItems => 'عناصر القائمة';

  @override
  String get noteSizePageNotes => 'ملاحظات الصفحات';

  @override
  String noteSaveRejected(String reason) {
    return 'تعذّر حفظ الملاحظة على الخادم: $reason';
  }

  @override
  String get errorLogShare => 'مشاركة سجل الأخطاء';

  @override
  String get errorLogInfo =>
      'تُحفظ الأخطاء الأخيرة على هذا الجهاز فقط؛ ولا تذهب إلى أي مكان ما لم تشاركها.';

  @override
  String get feedbackSend => 'إرسال ملاحظات';

  @override
  String get feedbackInfo =>
      'اقتراح أو مشكلة: يُفتح تطبيق البريد؛ ويُضاف إصدار التطبيق ونوع الجهاز، لا ملاحظاتك.';

  @override
  String get feedbackNoMailApp =>
      'تعذّر فتح تطبيق بريد؛ نُسخ العنوان إلى الحافظة.';

  @override
  String get feedbackBodyPrompt => 'رسالتك:';

  @override
  String get errorLogEmpty => 'لم تُسجَّل أخطاء.';

  @override
  String get crashReports => 'إرسال تقارير الأعطال';

  @override
  String get crashReportsInfo =>
      'عند تعطل التطبيق يُرسل تقرير تقني دون محتوى ملاحظاتك إلى Firebase Crashlytics (أندرويد فقط).';

  @override
  String get noteTooLargeShort => 'الملاحظة تتجاوز حد 1 ميبيبايت';

  @override
  String get crashTestTitle => 'إرسال عطل تجريبي؟';

  @override
  String get crashTestBody =>
      'للتحقق من إعداد Crashlytics يُغلق التطبيق فورًا. عند إعادة فتحه يُرسل التقرير إلى وحدة تحكم Firebase (قد يستغرق بضع دقائق).';

  @override
  String get crashTestAction => 'تعطيل';

  @override
  String get captureModeSetting => 'ملاحظات من المحتوى';

  @override
  String get captureModeSettingInfo =>
      'عند أخذ ملاحظات من الصور والمسح وPDF؛ ويبقى اختيارك الأول.';

  @override
  String get captureModeAsk => 'اسأل كل مرة';

  @override
  String get voiceMicTooltipDictate =>
      'إملاء — ضغط مطوّل: ملاحظة صوتية بالذكاء الاصطناعي';

  @override
  String get quickAddCamera => 'الكاميرا';

  @override
  String get quickAddFile => 'إضافة ملف';

  @override
  String get quickAddFromDevice => 'اختيار ملف';

  @override
  String get quickAddFileWhat => 'ماذا نفعل بهذا الملف؟';

  @override
  String get quickAddFileUnsupported => 'هذا النوع من الملفات غير مدعوم';

  @override
  String get shareFolderTogether => 'تعديل المجلد معًا';

  @override
  String get shareTogetherInfo => 'كلاكما يرى الملاحظة أو المجلد نفسه ويغيّره';

  @override
  String get shareCopyInfo => 'تذهب نسخة مستقلة إلى صندوق الوارد لدى صديقك';

  @override
  String get notebookViewOn => 'عرض الدفتر';

  @override
  String get notebookViewOff => 'إيقاف عرض الدفتر';

  @override
  String inkSemantics(int count) {
    return 'كتابة يدوية، $count خطوط';
  }

  @override
  String get guestReminderTitle => 'ملاحظاتك ليست محفوظة احتياطيًا';

  @override
  String get guestReminderBody =>
      'أنت تستخدم التطبيق دون حساب: ملاحظاتك على هذا الجهاز فقط، والذكاء الاصطناعي المدمج والمشاركة متوقفان. إن مُسحت بيانات التطبيق أو المتصفح أو غيّرت الجهاز فلا يمكن استعادتها. اربط حساب Google — تبقى ملاحظاتك كما هي.';

  @override
  String get guestReminderLater => 'لاحقًا';

  @override
  String get driveWebConnectTitle => 'هذا المرفق في Google Drive الخاص بك';

  @override
  String get driveWebConnectBody =>
      'تُحفظ مرفقاتك في مجلد «Notlar» على Google Drive. اربط Google Drive لتنزيل المرفقات وتخزينها دون اتصال ورفعها من المتصفح.';

  @override
  String get driveWebConnectButton => 'ربط Drive';

  @override
  String get lockPatternSemantics => 'نمط القفل: صِل النقاط بإصبعك';

  @override
  String get lockDrawPattern => 'ارسم نمطك';

  @override
  String get lockDrawAgain => 'ارسم النمط مجددًا للتأكيد';

  @override
  String get lockEnterPassword => 'أدخل كلمة المرور';

  @override
  String get lockPassword => 'كلمة المرور';

  @override
  String get lockPasswordAgain => 'كلمة المرور (مرة أخرى)';

  @override
  String get lockWrong => 'خطأ، حاول مجددًا';

  @override
  String lockTooManyAttempts(int count) {
    return 'محاولات خاطئة كثيرة. انتظر $count ث.';
  }

  @override
  String get lockUseFingerprint => 'فتح ببصمة الإصبع';

  @override
  String get lockForgot => 'نسيت';

  @override
  String get lockForgotFailed =>
      'تعذّر التحقق بحساب Google. حسابات الضيوف لا يمكنها إعادة تعيين كلمة المرور.';

  @override
  String get lockNewPassword => 'كلمة مرور قفل جديدة';

  @override
  String get lockNewPattern => 'نمط قفل جديد';

  @override
  String lockPasswordTooShort(int count) {
    return 'يجب أن تكون كلمة المرور $count أحرف على الأقل';
  }

  @override
  String lockPatternTooShort(int count) {
    return 'يجب أن يصل النمط $count نقاط على الأقل';
  }

  @override
  String get lockMismatch => 'غير متطابق، حاول مجددًا';

  @override
  String get lockChangeAuthReason => 'تحقّق لتغيير إعداد القفل';

  @override
  String get lockMethodTitle => 'قفل الملاحظة';

  @override
  String get lockMethodInfo => 'كيف تُفتح الملاحظات المقفلة؟';

  @override
  String get lockMethodDevice => 'بصمة الإصبع';

  @override
  String get lockMethodPassword => 'كلمة مرور';

  @override
  String get lockMethodPattern => 'نمط';

  @override
  String get lockAlsoFingerprint => 'السماح ببصمة الإصبع أيضًا';

  @override
  String get lockChangePassword => 'تغيير كلمة المرور';

  @override
  String get lockChangePattern => 'تغيير النمط';

  @override
  String get lockWebDeviceInfo =>
      'لا توجد بصمة إصبع في المتصفحات: اختر كلمة مرور أو نمطًا لحماية الملاحظات المقفلة على الويب أيضًا.';

  @override
  String get lockNotEncryption =>
      'تُشفَّر نصوص الملاحظات المقفلة وعناصر القوائم وملاحظات الصفحات على الجهاز بخوارزمية AES-256-GCM قبل المزامنة. قفل البصمة يحفظ المفتاح في المخزن الآمن لهذا الجهاز؛ وقفل كلمة المرور أو النمط يشتقه من سرّك — إن نسيته فلا يمكن فك تشفير المحتوى المقفل سابقًا.';

  @override
  String get versionHistory => 'سجل الإصدارات';

  @override
  String get versionHistoryInfo =>
      'يُحفظ نص الملاحظة عند فتحها، وكل نصف ساعة أثناء التعديلات الطويلة، وقبل أن يغيّرها الذكاء الاصطناعي. لا تُحفظ إصدارات للمرفقات.';

  @override
  String get versionHistoryEmpty =>
      'لا توجد إصدارات بعد. تتجمع هنا أثناء تعديل الملاحظة.';

  @override
  String get versionRestore => 'استعادة هذا الإصدار';

  @override
  String get versionRestored => 'استُعيدت الملاحظة إلى الإصدار السابق';

  @override
  String get versionReasonAi => 'قبل تغيير الذكاء الاصطناعي';

  @override
  String get versionReasonRestore => 'قبل الاستعادة';

  @override
  String get versionReasonOpen => 'عند الفتح';

  @override
  String get versionReasonAuto => 'تلقائي';

  @override
  String get mergeConflictKept =>
      'عدّل شخص آخر الموضع نفسه — احتُفظ بالنسختين، احذف الزائدة.';

  @override
  String presenceEditing(String name) {
    return '$name يعدّل الآن';
  }

  @override
  String get presenceSomeone => 'شخص ما';

  @override
  String get frameColorInfo =>
      'يُرسم حول البطاقة في الشاشة الرئيسية فقط، لا داخل الملاحظة';

  @override
  String get filterStarred => 'المميزة بنجمة';

  @override
  String get fileUseBubbles => 'فقاعات: يصبح المستند هو الملاحظة';

  @override
  String get fileUseClassic => 'كلاسيكي: يصبح المستند مرفقًا';

  @override
  String get fileUseClassicImageInfo =>
      'تُفتح ملاحظة عادية؛ تستقر الصور على الصفحة ويلتف النص حولها.';

  @override
  String get fileUseVideo => 'دوّن ملاحظات على الفيديو';

  @override
  String get fileUseVideoInfo =>
      'يُشغَّل الفيديو في الأعلى وتكتب ملاحظاتك بالأسفل.';

  @override
  String get fileUseAudio => 'إضافة كمرفق صوتي';

  @override
  String get fileUseAudioInfo =>
      'يبقى التسجيل قابلًا للتشغيل في الملاحظة؛ فرّغه لاحقًا إن شئت.';

  @override
  String get fileUseTranscribeInfo => 'يُفرَّغ الكلام ويُكتب في نص الملاحظة.';

  @override
  String get fileUseTranscribeImageInfo =>
      'يُقرأ النص في الصورة ويُكتب في نص الملاحظة.';

  @override
  String get fileUseDefault => 'افتراضي';

  @override
  String fileUseMore(int count) {
    return '+$count ملفات أخرى';
  }

  @override
  String get attachAnyFileInfo =>
      'أي ملف: صورة، PDF، شرائح، صوت، فيديو — يُكتشف النوع ويُسأل عند الحاجة';

  @override
  String get listeningModeAi => 'ذكاء اصطناعي';

  @override
  String get listeningModeDictation => 'كتابة مباشرة';

  @override
  String get dictationPanelHint => 'يظهر النص عند المؤشر أثناء حديثك';

  @override
  String get voiceStartShort => 'ابدأ';

  @override
  String get archivePaperDashed => 'خطوط متقطعة';

  @override
  String get itemDividerRemove => 'إزالة الخط';

  @override
  String get fileUseAttachInfo => 'يُضاف إلى الملاحظة كمرفق قابل للتشغيل';

  @override
  String get allNotesChip => 'الكل';

  @override
  String get untitledNote => 'ملاحظة بلا عنوان';

  @override
  String get trashAnalysis => 'تحليل السلة';

  @override
  String get trashAnalyze => 'تحليل ذكي';

  @override
  String get trashSuggestRestore => 'فكّر في استعادتها';

  @override
  String get trashSuggestDelete => 'حذفها آمن';

  @override
  String get trashSuggestNone => 'لا اقتراحات';

  @override
  String trashRestoreAllSuggested(int count) {
    return 'استعادة الكل ($count)';
  }

  @override
  String trashDeleteAllSuggested(int count) {
    return 'حذف الكل ($count)';
  }

  @override
  String trashStatNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظات',
      one: 'ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String trashStatAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرفقات',
      one: 'مرفق واحد',
    );
    return '$_temp0';
  }

  @override
  String trashStatSoon(int count) {
    return '$count تُحذف خلال 3 أيام';
  }

  @override
  String trashStatLocked(int count) {
    return '$count مقفلة (لم تُفحص)';
  }

  @override
  String get trashReasonEmpty => 'فارغة — لا شيء لتخسره';

  @override
  String get trashReasonDuplicate => 'توجد ملاحظة مطابقة بالفعل';

  @override
  String trashReasonDuplicateOf(String title) {
    return 'مطابقة لـ: $title';
  }

  @override
  String get trashReasonDuplicateInTrash => 'توجد نسخة أحدث في السلة أيضًا';

  @override
  String trashReasonOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مهام مفتوحة',
      one: 'مهمة مفتوحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonReminder => 'لها تذكير قادم';

  @override
  String get trashReasonSensitive =>
      'تحتوي على معلومات مثل كلمات مرور أو IBAN أو أرقام هواتف';

  @override
  String trashReasonAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'لها $count مرفقات',
      one: 'لها مرفق واحد',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonSubstantial => 'نص طويل ذو محتوى';

  @override
  String get cardElementsHeader => 'المعروض على البطاقات';

  @override
  String get cardShowProgress => 'عدّاد التقدّم (مثل 3/10)';

  @override
  String get cardShowProgressInfo => 'يعرض العناصر المنجزة بشريط وعدد.';

  @override
  String get cardShowChecked => 'العناصر المنجزة';

  @override
  String get cardShowCheckedInfo =>
      'عند الإيقاف تُطوى العناصر المنجزة إلى ملخص: ✓ 3 منجزة.';

  @override
  String cardItemsDone(int count) {
    return '✓ $count منجزة';
  }

  @override
  String cardItemsAllDone(int count) {
    return '✓ الكل منجز ($count)';
  }

  @override
  String get emptyNotesFirstAction => 'اكتب ملاحظتك الأولى';

  @override
  String get emptyNotesHint => 'تظهر هنا الملاحظات التي تكتبها كبطاقات.';

  @override
  String get emptyFolderHint =>
      'تتجمع هنا الملاحظات التي تضيفها إلى هذا المجلد.';

  @override
  String get emptyFilterHint => 'امسح الفلتر لترى كل ملاحظاتك مجددًا.';

  @override
  String get emptySearchHint => 'جرّب كلمة أخرى.';

  @override
  String get archiveEmptyHint =>
      'الملاحظات التي تؤرشفها تغادر الشاشة الرئيسية وتُحفظ هنا.';

  @override
  String get trashEmptyHint =>
      'تبقى الملاحظات المحذوفة هنا 30 يومًا؛ ويمكنك استعادتها حتى ذلك الحين.';

  @override
  String get cardShowMoreCount => 'سطر «+N عناصر أخرى»';

  @override
  String get cardShowStatusIcons => 'أيقونات الحالة';

  @override
  String get cardShowStatusIconsInfo =>
      'مثبّتة، مميزة بنجمة، تذكير، مشتركة، هذا الجهاز فقط…';

  @override
  String get cardShowTag => 'الوسم';

  @override
  String get cardShowDate => 'التاريخ والوقت';

  @override
  String get cardShowMedia => 'الصور والفيديوهات';

  @override
  String get cardShowFolder => 'اسم المجلد';

  @override
  String get cardShowFolderInfo =>
      'مجلد الملاحظة في نتائج البحث وفي عرض «الكل».';

  @override
  String get cardShowPaper => 'نقش ورق الدفتر';

  @override
  String get formatFontPanel => 'الخط والحجم';

  @override
  String get inkShapes => 'الأشكال';

  @override
  String get inkShapeLine => 'خط مستقيم';

  @override
  String get inkShapeRectangle => 'مستطيل';

  @override
  String get inkShapeEllipse => 'دائرة / بيضاوي';

  @override
  String get inkPenOnlyOn => 'القلم فقط (الإصبع يمرّر) — إيقاف';

  @override
  String get inkPenOnlyOff => 'الإصبع يرسم أيضًا — التبديل إلى القلم فقط';

  @override
  String get inkPenOnlyHint =>
      'اكتب بالقلم · اسحب بإصبع، وقرّب بإصبعين للتكبير';

  @override
  String get inkSettings => 'إعدادات القلم';

  @override
  String get inkWidth => 'السُّمك';

  @override
  String get inkOpacity => 'العتامة';

  @override
  String get inkRecentColors => 'الألوان الأخيرة';

  @override
  String get inkPenOnlyTitle => 'الرسم بالقلم فقط';

  @override
  String get inkFingerToolTitle => 'الإصبع';

  @override
  String get inkFingerToolInfo =>
      'تلقائي: يمرّر الإصبع بعد رصد قلم، وإلا يرسم. يمرّر: القلم وحده يكتب والإصبع يمرّر. يرسم: الإصبع يكتب بأداة القلم أيضًا. يمحو: الإصبع يمحو، وإصبعان للتكبير.';

  @override
  String get inkFingerScroll => 'يمرّر';

  @override
  String get inkFingerDraw => 'يرسم';

  @override
  String get inkFingerErase => 'يمحو';

  @override
  String get inkFingerEraseOn => 'الإصبع يمحو — التبديل إلى القلم فقط';

  @override
  String get inkPressureTitle => 'حساسية الضغط';

  @override
  String get inkPressureInfo =>
      'الضغط الخفيف يكتب رفيعًا والضغط القوي يكتب سميكًا.';

  @override
  String get inkStylusTipsTitle => 'اختصارات القلم';

  @override
  String get inkStylusTips =>
      'اضغط مطولًا على زر القلم الجانبي أو المس بطرف الممحاة للمحو.';

  @override
  String get inkZoomReset => 'ملاءمة للشاشة';

  @override
  String get cardShowFiles => 'مرفقات الملفات';

  @override
  String get cardShowFilesInfo =>
      'إظهار مرفقات PDF والشرائح والصوت والنص على البطاقات';

  @override
  String get cardShowMediaShort => 'الصور على البطاقات';

  @override
  String get cardShowFilesShort => 'المرفقات على البطاقات';

  @override
  String get homeShowShared => 'الملاحظات المشتركة في الرئيسية';

  @override
  String get homeShowSharedInfo =>
      'تظهر الملاحظات المشتركة أيضًا في قسم خاص بها في الرئيسية.';

  @override
  String get homeShowSharedShort => 'إظهار الملاحظات المشتركة';

  @override
  String get homeSharedAtBottom => 'المشتركة أسفل ملاحظاتي';

  @override
  String get homeSharedAtBottomInfo =>
      'عند التفعيل تكون الملاحظات المشتركة أسفل ملاحظاتك.';

  @override
  String get homeSharedAtBottomShort => 'المشتركة في الأسفل';

  @override
  String get homeSharedSection => 'المشتركة';

  @override
  String get copyAttachment => 'نسخ المرفق';

  @override
  String get attachmentCopiedPasteHint =>
      'نُسخ المرفق — الصقه في ملاحظة أخرى من قائمة +';

  @override
  String get dividerSettings => 'إعدادات الخط';

  @override
  String get dividerPreviewText => 'عنصر نموذجي';

  @override
  String get dividerKind => 'النمط';

  @override
  String get dividerColor => 'اللون';

  @override
  String get dividerWeight => 'السُّمك';

  @override
  String get dividerApplyAll => 'تطبيق على الكل';

  @override
  String get dividerKindSolid => 'متصل';

  @override
  String get dividerKindDashed => 'متقطع';

  @override
  String get dividerKindDotted => 'منقّط';

  @override
  String get dividerKindDouble => 'مزدوج';

  @override
  String get dividerKindWavy => 'متموج';

  @override
  String get itemMenuUnstar => 'إزالة النجمة';

  @override
  String get itemMenuMove => 'نقل';

  @override
  String get itemMenuDelete => 'حذف';

  @override
  String get itemMenuLine => 'خط أسفله';

  @override
  String get formatStyleText => 'نص';

  @override
  String get formatStyleH1 => 'عنوان';

  @override
  String get formatStyleH2 => 'عنوان فرعي';

  @override
  String get formatSizeDown => 'أصغر';

  @override
  String get formatSizeUp => 'أكبر';

  @override
  String get imageCaptionHint => 'وصف الصورة';

  @override
  String get imageCaptionAdd => 'إضافة وصف';

  @override
  String get imageCaptionEdit => 'تعديل الوصف';

  @override
  String get voiceRecordResume => 'استئناف التسجيل';

  @override
  String get voiceRecordDiscard => 'تجاهل التسجيل';

  @override
  String get checkboxToggle => 'مربع اختيار';

  @override
  String get noteAppearance => 'المظهر';

  @override
  String get noteThemeNone => 'سادة';

  @override
  String get noteThemePalm => 'نخيل';

  @override
  String get noteThemeLagoon => 'بحيرة';

  @override
  String get noteThemeNight => 'ليل';

  @override
  String get noteThemeSunset => 'غروب';

  @override
  String get noteThemeSakura => 'ساكورا';

  @override
  String get noteThemeWaves => 'بحر';

  @override
  String get noteThemeMeadow => 'مرج';

  @override
  String get noteThemePaper => 'ورق';

  @override
  String get pinToHomeScreen => 'إضافة إلى الشاشة الرئيسية للهاتف';

  @override
  String get pinToHomeSent =>
      'أكّد على شاشتك الرئيسية — ستُفتح الملاحظة من اختصارها';

  @override
  String get pinToHomeUnsupported => 'شاشتك الرئيسية لا تدعم هذا الاختصار';

  @override
  String get inkColor => 'لون القلم';

  @override
  String get cardMediaHide => 'إخفاء معاينة الصورة';

  @override
  String get cardMediaShow => 'إظهار معاينة الصورة';

  @override
  String get youTubeEmbedInNote => 'تضمين في الملاحظة';

  @override
  String get goToLink => 'الانتقال إلى الرابط';

  @override
  String get noteFlatColors => 'ألوان سادة';

  @override
  String get youTubeEmbedded => 'ضُمّن الفيديو في الملاحظة';

  @override
  String get inkLasso => 'لاسو (تحديد ونقل)';

  @override
  String get inkLassoHint =>
      'ارسم حول الخطوط: اسحب لنقلها، واختر لونًا لتلوينها.';

  @override
  String get inkDeleteSelection => 'حذف التحديد';

  @override
  String get inkClearSelection => 'إلغاء التحديد';

  @override
  String get inkShapeSnapTitle => 'اضغط مطولًا للتحويل إلى شكل';

  @override
  String get inkShapeSnapInfo =>
      'أبقِ القلم ثابتًا في نهاية الخط لتحصل على خط أو دائرة أو مربع.';

  @override
  String get inkQuickSwapTitle => 'زر سريع قلم ↔ ممحاة';

  @override
  String get inkQuickSwapInfo =>
      'بعد كل خط يظهر زر للتبديل بين القلم والممحاة.';

  @override
  String get inkQuickSwapToEraser => 'التبديل إلى الممحاة';

  @override
  String get inkQuickSwapToPen => 'العودة إلى القلم';

  @override
  String get inkPartialEraserTitle => 'ممحاة جزئية';

  @override
  String get inkPartialEraserInfo =>
      'تمحو الممحاة ما تلمسه فقط؛ وعند الإيقاف تمحو الخط كله.';

  @override
  String get inkAutoStylusTitle => 'اكتشاف القلم تلقائيًا';

  @override
  String get inkAutoStylusInfo =>
      'يتفعّل وضع الكتابة عندما يلمس القلم الملاحظة.';

  @override
  String get inkStylusDetected => 'رُصد القلم — وضع الكتابة مفعّل';

  @override
  String get copyAndCheckSelectedItems => 'نسخ وإنجاز';

  @override
  String get copiedAndChecked => 'نُسخ وأُنجز';

  @override
  String get formatScopeCaret => 'المؤشر';

  @override
  String get formatScopeWord => 'كلمة';

  @override
  String get formatScopeLine => 'سطر';

  @override
  String get formatScopeAll => 'الكل';

  @override
  String get formatScopeSelection => 'التحديد';

  @override
  String get formatScopeHint =>
      'على ماذا يُطبَّق التنسيق: المؤشر أو الكلمة أو السطر أو الكل';

  @override
  String get formatStyleMenu => 'نمط الفقرة';

  @override
  String get colorNameCoral => 'مرجاني';

  @override
  String get colorNamePeach => 'خوخي';

  @override
  String get colorNameHoney => 'عسلي';

  @override
  String get colorNameSage => 'مريمية';

  @override
  String get colorNameStorm => 'عاصف';

  @override
  String get colorNameLavender => 'خزامى';

  @override
  String get colorNameClay => 'طيني';

  @override
  String get colorNameChalk => 'طباشيري';

  @override
  String get colorNameRed => 'أحمر';

  @override
  String get colorNameYellow => 'أصفر';

  @override
  String get colorNameGreen => 'أخضر';

  @override
  String get colorNameBlue => 'أزرق';

  @override
  String get colorNamePurple => 'بنفسجي';

  @override
  String get colorNameNone => 'بلا لون';

  @override
  String get colorNameOrange => 'برتقالي';

  @override
  String get colorNamePink => 'وردي';

  @override
  String get colorNameGray => 'رمادي';

  @override
  String get colorNameCyan => 'سماوي';

  @override
  String get colorNameWhite => 'أبيض';

  @override
  String get colorNameBlack => 'أسود';

  @override
  String get colorToneLight => 'فاتح';

  @override
  String get colorToneVivid => 'زاهٍ';

  @override
  String get colorToneDark => 'داكن';

  @override
  String colorShade(String color, String tone) {
    return '$color، $tone';
  }

  @override
  String get itemEmptyLabel => 'عنصر فارغ';

  @override
  String bubbleSemantic(int page, String text) {
    return 'فقاعة، الصفحة $page: $text';
  }

  @override
  String bubbleSemanticEmpty(int page) {
    return 'فقاعة فارغة، الصفحة $page';
  }

  @override
  String mediaBoxSemantic(String kind, String name) {
    return '$kind: $name';
  }

  @override
  String get formatSizeLabel => 'الحجم';

  @override
  String formatSizeValue(int percent) {
    return 'الحجم $percent%';
  }

  @override
  String get customColor => 'لون مخصص…';

  @override
  String get embedLasso => 'التحديد بالإحاطة';

  @override
  String embedLassoHint(String name) {
    return 'سيُربط $name — أحط بالنص أو اضغط على كلمة · مرّر بإصبعين';
  }

  @override
  String get embedSelectMode => 'الربط بالتحديد';

  @override
  String get embedLassoMissed => 'لا يوجد نص داخل الدائرة — ارسم حول النص';

  @override
  String get gestureItemDeleted => 'حُذف العنصر';

  @override
  String get itemGesturesSetting => 'إيماءات العناصر';

  @override
  String get itemGesturesSettingInfo =>
      'ارسم على عنصر: يُشطب أو يُنجز؛ والخربشة تحذفه.';

  @override
  String get pdfEditWorking => 'جارٍ معالجة PDF…';

  @override
  String get noteMenu => 'قائمة الملاحظة';

  @override
  String get moreActions => 'إجراءات أخرى';

  @override
  String get errorOffline =>
      'لا يوجد اتصال بالإنترنت أو هو ضعيف. حاول مجددًا عند الاتصال.';

  @override
  String get errorTimeout => 'استغرق ذلك وقتًا طويلًا. حاول مجددًا بعد قليل.';

  @override
  String get errorQuota => 'بلغت حد الاستخدام. حاول مجددًا بعد قليل.';

  @override
  String get errorPermission => 'غير مسموح. تحقق من حسابك أو أذونات التطبيق.';

  @override
  String get errorTooLarge => 'الملف كبير جدًا.';

  @override
  String get errorUnsupported => 'هذا غير مدعوم هنا.';

  @override
  String get errorUnknown => 'حدث أمر غير متوقع. التفاصيل في سجل الأخطاء.';

  @override
  String get errorStateTitle => 'تعذّر التحميل';

  @override
  String get errorStateOfflineTitle => 'أنت غير متصل';

  @override
  String get copyErrorDetail => 'نسخ التفاصيل';

  @override
  String get accountRequiredTitle => 'مطلوب حساب Google';

  @override
  String get accountRequiredBody =>
      'تعمل جهات الاتصال والتعاون وإرسال النسخ عبر بريدك الإلكتروني؛ وبدون حساب لا يمكن لأحد إيجادك. اربط حساب Google — تبقى ملاحظاتك كما هي.';

  @override
  String get accountRequiredBadge => 'يتطلب حساب Google';

  @override
  String get deletingAccount => 'جارٍ حذف حسابك وبياناتك…';

  @override
  String get sharedHubShort => 'الوارد';

  @override
  String get itemEmptyHint => 'اكتب عنصرًا';

  @override
  String get allFolders => 'كل المجلدات';

  @override
  String get guestReminderConnect => 'ربط';

  @override
  String get filterSectionType => 'النوع';

  @override
  String get reorderNotesManually => 'ترتيب يدوي';

  @override
  String get shareIncludeBubbles => 'الفقاعات';

  @override
  String sharedFolderBar(String role) {
    return 'مجلد مشترك · $role';
  }

  @override
  String get shareSendSection => 'إرسال للخارج';

  @override
  String get shareInAppSection => 'مع الأشخاص';

  @override
  String get shareTextHint => 'يرسل نص الملاحظة إلى تطبيق (واتساب، البريد…)';

  @override
  String get shareCopyHint => 'ينسخ نص الملاحظة إلى الحافظة';

  @override
  String get shareQuickPdfHint => 'يرسل الملاحظة كملف PDF بضغطة واحدة';

  @override
  String get shareAsImageHint => 'يرسل الملاحظة كصور، صفحة بصفحة';

  @override
  String get shareAttachmentFilesHint =>
      'يرسل صور الملاحظة وملفات PDF والصوت والفيديو نفسها';

  @override
  String get shareAsNoteInfo =>
      'ملف واحد بالمرفقات والصفحات والرسومات والفقاعات؛ يُفتح كما هو في التطبيق';

  @override
  String get bubbleCopy => 'نسخ';

  @override
  String get bubblesCopyAll => 'نسخ الكل';

  @override
  String get bubblesToNote => 'إضافة إلى الملاحظة';

  @override
  String get bubblesToNoteDone => 'أُضيفت الفقاعات إلى نهاية الملاحظة';

  @override
  String get bubbleMark => 'تعليم';

  @override
  String get bubbleFormat => 'تنسيق';

  @override
  String get sharedHubTagInbox => 'الوارد';

  @override
  String get sharedHubTagShared => 'مشتركة';

  @override
  String get sharedHubEmpty => 'لا شيء مستلم أو مشترك هنا بعد';

  @override
  String get sharedHubEmptyHint =>
      'تظهر هنا معًا النسخ التي يرسلها أصدقاؤك والملاحظات المشتركة التي يضيفونك إليها.';

  @override
  String get settingsModulesTitle => 'الإضافات والملاحظة السريعة';

  @override
  String settingsModulesSummary(int on, int total) {
    return '$on/$total إضافات مفعّلة';
  }

  @override
  String get settingsSoundTitle => 'الاستماع والإملاء';

  @override
  String cardElementsSummary(int on, int total) {
    return '$on/$total مفعّلة · شاهد نموذجًا';
  }

  @override
  String get cardElementsSampleTitle => 'تسوق نهاية الأسبوع';

  @override
  String cardElementsSampleItem(int n) {
    return 'عنصر $n';
  }

  @override
  String get cardElementsSampleTag => 'منزل';

  @override
  String get tipListGestures => 'نصيحة: اشطب عنصرًا بإصبعك ← يصبح منجزًا.';

  @override
  String get tipMediaPin =>
      'نصيحة: اضغط مطولًا على صورة واسحبها للأعلى ← تُثبَّت فوق الملاحظة.';

  @override
  String get tipGridSwipeFolders =>
      'نصيحة: اسحب الشاشة جانبيًا ← تنقّل بين المجلدات.';

  @override
  String get tipGridSwipeFilters =>
      'نصيحة: اسحب الشاشة جانبيًا ← تنقّل بين الفلاتر.';

  @override
  String get tipsResetTitle => 'إظهار النصائح مجددًا';

  @override
  String get tipsResetInfo =>
      'تظهر النصائح الصغيرة لمرة واحدة (الإيماءات، البحث بالمعنى) مجددًا.';

  @override
  String get tipsResetDone => 'ستظهر النصائح مجددًا';

  @override
  String get tipsEnabledTitle => 'إظهار نصائح مفيدة';

  @override
  String get tipsEnabledInfo =>
      'إظهار تلميحات قصيرة وهادئة عند استخدام ميزة لأول مرة.';

  @override
  String get tipFormatScope =>
      'نصيحة: بدّل النطاق بين المؤشر والكلمة والسطر والكل؛ واضغط على النسبة لإعادة الحجم إلى 100%.';

  @override
  String get tipTableGestures =>
      'نصيحة: اسحب حد العمود لتغيير حجمه، أو اضغط Tab للانتقال إلى الخلية التالية.';

  @override
  String get tipItemHoldSelect =>
      'نصيحة: اضغط مطولًا على عنصر للتحديد المتعدد؛ واستخدم النطاق والعكس والتنسيق الجماعي من الشريط السفلي.';

  @override
  String get tipVoiceCommands =>
      'نصيحة: قل «سطر جديد» أو «عنصر جديد» أو «نقطة» أو «احذف الكلمة الأخيرة» أثناء الإملاء.';

  @override
  String get tipFolderGestures =>
      'نصيحة: اضغط مطولًا على مجلد لخيارات سريعة، أو اسحب ملاحظة إلى مجلد لنقلها.';

  @override
  String get tipPinnedSplitResize =>
      'نصيحة: اسحب مقبض التقسيم لتغيير الحجم، أو بدّل الجانبين من الشريط المثبّت.';

  @override
  String get tipPinnedSmartActions =>
      'نصيحة: افتح الإجراءات الذكية من الشريط المثبّت لتلخيص الصفحات أو استخراج النص أو سؤال الذكاء الاصطناعي.';

  @override
  String get tipCrossAppDosyalarim =>
      'نصيحة: افتح ملفات PDF والملفات المرفقة في Dosyalarım؛ ومجمع الذكاء الاصطناعي المشترك يعمل في التطبيقين.';

  @override
  String get swipeModeInfo =>
      'ماذا يفعل السحب الجانبي في عرض الشبكة؛ وفي عرض القائمة سحب الصف يثبّت أو يؤرشف.';

  @override
  String get backupInfo =>
      'كل الملاحظات بمرفقاتها ومجلداتها في ملف واحد؛ والاستيراد مرتين لا يكرّرها.';

  @override
  String get backupInProgress => 'جارٍ تجهيز النسخة الاحتياطية';

  @override
  String get restoreInProgress => 'جارٍ الاستعادة';

  @override
  String get backupShareSubject => 'نسخة احتياطية للملاحظات';

  @override
  String get backupCancelled => 'أُلغي';

  @override
  String backupProgressCount(int done, int total) {
    return '$done / $total ملاحظات';
  }

  @override
  String restoreBackupResult(int restored, int skipped) {
    return 'استُعيدت $restored ملاحظات، وتُخطّيت $skipped (موجودة بالفعل)';
  }

  @override
  String get accountRecoverBringNotes => 'أحضر ملاحظاتي';

  @override
  String accountRecoverBringDone(int count) {
    return 'تم تبديل الحساب ونُقلت $count ملاحظات';
  }

  @override
  String get accountRecoverBringFailed =>
      'تم تبديل الحساب لكن تعذّر نقل الملاحظات؛ ملاحظات الضيف لم تُمس';

  @override
  String get appLockTitle => 'قفل التطبيق';

  @override
  String get appLockInfo =>
      'يطلب التحقق عند الفتح والعودة من الخلفية بطريقة قفل الملاحظات. ليس تشفيرًا؛ على هذا الجهاز فقط.';

  @override
  String get appLockWebNeedsSecret =>
      'لا يوجد قفل جهاز على الويب: اختر كلمة مرور أو نمطًا أعلاه أولًا.';

  @override
  String get appLockReason => 'افتح الملاحظات';

  @override
  String get appLockLockedTitle => 'الملاحظات مقفلة';

  @override
  String get appLockUnlock => 'فتح القفل';

  @override
  String get appLockDelayTitle => 'القفل:';

  @override
  String get appLockDelayNow => 'فورًا';

  @override
  String appLockDelayMinutes(int minutes) {
    return 'بعد $minutes د';
  }

  @override
  String get appLockHideRecents => 'إخفاء المحتوى في التطبيقات الأخيرة';

  @override
  String get repeatTitle => 'التكرار';

  @override
  String get repeatNone => 'بلا تكرار';

  @override
  String get repeatDaily => 'كل يوم';

  @override
  String get repeatWeekdays => 'كل أيام العمل';

  @override
  String get repeatWeekly => 'كل أسبوع';

  @override
  String repeatWeeklyOn(String days) {
    return 'أسبوعيًا: $days';
  }

  @override
  String get repeatMonthly => 'كل شهر';

  @override
  String get repeatYearly => 'كل سنة';

  @override
  String get importOther => 'استيراد من تطبيقات أخرى';

  @override
  String get importOtherInfo =>
      'Google Keep ‏(Takeout zip)، Markdown/txt (ملف أو zip)، Evernote ‏(.enex)';

  @override
  String get importInProgress => 'جارٍ الاستيراد';

  @override
  String get importOtherNone => 'لا توجد ملاحظات للاستيراد في هذا الملف';

  @override
  String importOtherResult(int imported, int skipped, int failed) {
    return 'استُوردت $imported ملاحظات، وتُخطّيت $skipped (موجودة بالفعل)، و$failed غير مقروءة';
  }

  @override
  String get noteLinkAction => 'ربط بملاحظة';

  @override
  String get noteLinkOpen => 'فتح الملاحظة';

  @override
  String get noteLinkPickTitle => 'الربط بأي ملاحظة؟';

  @override
  String get noteLinkInserted => 'رُبطت بالملاحظة';

  @override
  String get noteLinkMissing => 'لم يُعثر على الملاحظة المرتبطة (ربما حُذفت)';

  @override
  String get backlinksTitle => 'ملاحظات تشير إلى هنا';

  @override
  String backlinksCount(int count) {
    return '$count روابط عكسية';
  }

  @override
  String get relatedNotesTitle => 'ملاحظات ذات صلة';

  @override
  String get relatedNotesNone => 'لم يُعثر على ملاحظات ذات صلة';

  @override
  String get relatedNotesLink => 'ربط';

  @override
  String get studyCardsTitle => 'بطاقات اليوم';

  @override
  String get studyCardsEmpty => 'لا توجد بطاقات مستحقة هنا اليوم';

  @override
  String get studyCardsDone => 'انتهيت من اليوم!';

  @override
  String get studyCardsEmptyInfo =>
      'استخدم «إنشاء بطاقات» من قائمة ⋮ في الملاحظة ليحوّلها الذكاء الاصطناعي إلى بطاقات سؤال وجواب.';

  @override
  String studyCardsLeft(int count) {
    return 'تبقّى $count بطاقات';
  }

  @override
  String get studyCardsReveal => 'إظهار الإجابة';

  @override
  String get studyGradeAgain => 'مجددًا';

  @override
  String get studyGradeHard => 'صعب';

  @override
  String get studyGradeGood => 'جيد';

  @override
  String get studyGradeEasy => 'سهل';

  @override
  String updateAvailable(String name) {
    return 'يتوفر إصدار جديد: $name';
  }

  @override
  String get pdfNoteFromSelection => 'دوّن ملاحظة';

  @override
  String get pdfNoteAtPage => 'ملاحظة لهذه الصفحة';

  @override
  String get tipPdfReadNote =>
      'نصيحة: اضغط مطولًا على النص وحدّده ← «دوّن ملاحظة»: تدخل الصفحة والسطر في ملاحظتك، واضغط للعودة.';

  @override
  String showMoreChecked(int n) {
    return 'إظهار المنجزة ($n مخفية)';
  }

  @override
  String get hideMoreChecked => 'طي المنجزة';

  @override
  String get gmailGoogleOnly => 'سجّل الدخول بحساب Google لاستخدام Gmail.';

  @override
  String get tipHomeMicHold =>
      'نصيحة: اضغط مطولًا على الميكروفون لملاحظة صوتية بالذكاء الاصطناعي.';

  @override
  String get itemGesturesFingerAll => 'إيماءات الحذف والتصحيح بالإصبع أيضًا';

  @override
  String get itemGesturesFingerAllInfo =>
      'عند الإيقاف يكتفي الإصبع بالإنجاز؛ والخربشة والدائرة تحتاجان القلم.';

  @override
  String get itemAddHeader => 'عنوان فرعي';

  @override
  String get itemHeaderHint => 'اكتب عنوانًا فرعيًا';

  @override
  String get itemMenuToHeader => 'جعله عنوانًا';

  @override
  String get itemMenuToItem => 'جعله عنصرًا';

  @override
  String get pinnedMediaFit => 'ملاءمة';

  @override
  String get tagRemove => 'إزالة الوسم';

  @override
  String get itemAlignStart => 'محاذاة لليسار';

  @override
  String get itemAlignCenter => 'توسيط';

  @override
  String get itemAlignEnd => 'محاذاة لليمين';

  @override
  String get themeLavender => 'خزامى';

  @override
  String get themeOlive => 'زيتوني';

  @override
  String get tplShopMeat => 'لحوم ودواجن وأسماك';

  @override
  String get tplShopMeatItems =>
      'لحم مفروم، صدر دجاج، أفخاذ دجاج، مكعبات لحم بقري، سمك، نقانق، ديك رومي مدخن، كفتة';

  @override
  String get tplShopDrinks => 'مشروبات';

  @override
  String get tplShopDrinksItems =>
      'ماء، مياه غازية، عصير، لبن، صودا، شاي مثلج، حليب';

  @override
  String get tplShopSnacks => 'وجبات خفيفة';

  @override
  String get tplShopSnacksItems =>
      'بسكويت، شوكولاتة، رقائق بطاطس، مكسرات، مقرمشات، ويفر، فواكه مجففة';

  @override
  String get tplShopFrozen => 'مجمدات';

  @override
  String get tplShopFrozenItems =>
      'آيس كريم، بازلاء، بطاطس مقلية، زلابية، بيتزا، معجنات';

  @override
  String get tplShopBaby => 'الرضيع';

  @override
  String get tplShopBabyItems =>
      'حفاضات، مناديل مبللة، حليب أطفال، شامبو أطفال، كريم الحفاض';

  @override
  String get tplShopPet => 'الحيوانات الأليفة';

  @override
  String get tplShopPetItems =>
      'طعام قطط، طعام كلاب، رمل القطط، مكافآت، أسطوانة إزالة الوبر';

  @override
  String get tplTravelHealth => 'الصحة';

  @override
  String get tplTravelHealthItems =>
      'مسكنات، لاصقات جروح، دواء المعدة، الوصفات الطبية، طارد البعوض، كمامة';

  @override
  String get tplTravelBeforeGo => 'قبل المغادرة';

  @override
  String get tplTravelBeforeGoItems =>
      'تفقّد الموقد، أغلق النوافذ، أخرج القمامة، اسقِ النباتات، افصل الأجهزة، خذ المفاتيح';

  @override
  String get tplCleanKitchen => 'المطبخ';

  @override
  String get tplCleanKitchenItems =>
      'الصحون، سطح العمل، الموقد، الفرن، الثلاجة، الحوض، الميكروويف';

  @override
  String get tplCleanBath => 'الحمام';

  @override
  String get tplCleanBathItems =>
      'المرحاض، المغسلة، الدُّش، المرآة، فواصل البلاط، تغيير المناشف';

  @override
  String get tplCleanRooms => 'الغرف';

  @override
  String get tplCleanRoomsItems =>
      'إزالة الغبار، الكنس بالمكنسة، المسح، ترتيب الأسرّة، تنظيف النوافذ، نفض السجاد';

  @override
  String get tplCleanMonthly => 'شهريًا';

  @override
  String get tplCleanMonthlyItems =>
      'الستائر، فلتر المكيف، داخل الخزائن، صيانة الغسالة، فلتر الشفاط';

  @override
  String get tplMoveBefore => 'قبل الانتقال';

  @override
  String get tplMoveBeforeItems =>
      'احجز شركة نقل، اشترِ صناديق وشريطًا لاصقًا، تخلّص من الزوائد، ضع ملصقات على الصناديق، أبلغ شركات الخدمات، غيّر العنوان';

  @override
  String get tplMoveDay => 'يوم الانتقال';

  @override
  String get tplMoveDayItems =>
      'صوّر العدادات، سلّم المفاتيح، احتفظ بالأشياء الثمينة معك، جولة أخيرة، حقيبة الليلة الأولى';

  @override
  String get tplMoveAfter => 'بعد الانتقال';

  @override
  String get tplMoveAfterItems =>
      'إعداد الإنترنت، تسجيل العنوان، تغيير الأقفال، تحديث العنوان في البنك، التعرّف على الجيران';

  @override
  String get tplHabitHealth => 'الصحة';

  @override
  String get tplHabitHealthItems =>
      '8 أكواب ماء، مشي 30 دقيقة، النوم مبكرًا، يوم بلا سكر، تناول الفيتامينات، الإطالة';

  @override
  String get tplHabitMind => 'الذهن';

  @override
  String get tplHabitMindItems =>
      'قراءة 20 صفحة، تأمل، تدوين اليوميات، ساعة بلا شاشات، تعلّم كلمة جديدة';

  @override
  String get tplHabitHome => 'المنزل';

  @override
  String get tplHabitHomeItems =>
      'إنهاء غسل الصحون، ترتيب 10 دقائق، سقي النباتات، التخطيط للغد';

  @override
  String get tplWorkoutUpper => 'الجزء العلوي';

  @override
  String get tplWorkoutUpperItems =>
      'ضغط 3×10، عقلة 3×6، ضغط الكتف 3×10، تمرين البايسبس 3×12، غطس الترايسبس 3×10، بلانك 3×45 ث';

  @override
  String get tplWorkoutLower => 'الجزء السفلي';

  @override
  String get tplWorkoutLowerItems =>
      'قرفصاء 3×12، طعنات 3×10، جسر الألوية 3×15، رفع السمانة 3×20، الجلوس على الحائط 3×40 ث';

  @override
  String get tplWorkoutCardio => 'الكارديو';

  @override
  String get tplWorkoutCardioItems =>
      'جري 20 دقيقة، نط الحبل 5 دقائق، دراجة 30 دقيقة، قفز مع فتح الأطراف 3×30، بيربي 3×10';

  @override
  String get tplGiftPeople => 'الأشخاص';

  @override
  String get tplGiftPeopleItems =>
      'أمي، أبي، أخي/أختي، شريك الحياة، صديق، معلم، زميل، طفل';

  @override
  String get tplGiftIdeas => 'أفكار';

  @override
  String get tplGiftIdeasItems =>
      'كتاب، زهور، عطر، ساعة، هدية تجربة، صنع يدوي، كوب، بطاقة هدية';

  @override
  String get tplTodoHome => 'المنزل';

  @override
  String get tplTodoHomeItems =>
      'دفع الفواتير، الغسيل، البقالة، الإصلاحات، حجز موعد';

  @override
  String get tplTodoErrands => 'المشاوير';

  @override
  String get tplTodoErrandsItems =>
      'الذهاب إلى البنك، إرسال طرد، الصيدلية، التنظيف الجاف، مكتب البريد';

  @override
  String get templateFavorite => 'إضافة إلى المفضلة';

  @override
  String get templateUnfavorite => 'إزالة من المفضلة';

  @override
  String get templatesFavorites => 'المفضلة';

  @override
  String get templateFavoritesFull => 'حتى 4 مفضلات — أزِل واحدة أولًا';

  @override
  String get calendarTitle => 'التقويم';

  @override
  String get calendarToday => 'اليوم';

  @override
  String get calendarViewAgenda => 'جدول الأعمال';

  @override
  String get calendarViewMonth => 'الشهر';

  @override
  String get calendarNewEvent => 'حدث جديد';

  @override
  String get calendarEmpty => 'لا توجد أحداث هنا بعد';

  @override
  String get calendarEmptyHint =>
      'أضف حدثًا؛ والملاحظات ذات التذكيرات تظهر هنا أيضًا.';

  @override
  String get calendarNothingThisDay => 'لا شيء مخطط لهذا اليوم';

  @override
  String get calendarReminderTag => 'تذكير';

  @override
  String get calendarShowMonth => 'إظهار الشهر';

  @override
  String get calendarHideMonth => 'إخفاء الشهر';

  @override
  String get calendarPrevMonth => 'الشهر السابق';

  @override
  String get calendarNextMonth => 'الشهر التالي';

  @override
  String get calendarMoreDays => 'أبعد من ذلك';

  @override
  String get eventEditTitle => 'تعديل الحدث';

  @override
  String get eventTitleHint => 'أضف عنوانًا';

  @override
  String get eventUntitled => '(بلا عنوان)';

  @override
  String get eventAllDay => 'طوال اليوم';

  @override
  String get eventStarts => 'يبدأ';

  @override
  String get eventEnds => 'ينتهي';

  @override
  String get eventReminder => 'تذكير';

  @override
  String get eventReminderNone => 'بلا تذكير';

  @override
  String get eventReminderAtStart => 'عند وقت البدء';

  @override
  String get eventReminderAllDayMorning => 'في اليوم الساعة 09:00';

  @override
  String eventReminderMinutes(int count) {
    return 'قبل $count دقائق';
  }

  @override
  String eventReminderHours(int count) {
    return 'قبل $count ساعات';
  }

  @override
  String eventReminderDays(int count) {
    return 'قبل $count أيام';
  }

  @override
  String get eventLocation => 'الموقع';

  @override
  String get eventDescription => 'الوصف';

  @override
  String get eventSave => 'حفظ';

  @override
  String get eventDelete => 'حذف الحدث';

  @override
  String get eventDeleted => 'حُذف الحدث';

  @override
  String get eventDeleteRepeatingTitle => 'حدث متكرر';

  @override
  String get eventDeleteThis => 'هذا الحدث فقط';

  @override
  String get eventDeleteAll => 'كل التكرارات';

  @override
  String get eventNotificationAllDay => 'اليوم · طوال اليوم';

  @override
  String get tasksTitle => 'المهام';

  @override
  String get tasksDefaultList => 'مهامي';

  @override
  String get tasksNewTask => 'مهمة جديدة';

  @override
  String get tasksNewList => 'قائمة جديدة';

  @override
  String get tasksListNameHint => 'اسم القائمة';

  @override
  String get tasksRenameList => 'إعادة تسمية القائمة';

  @override
  String get tasksDeleteList => 'حذف القائمة';

  @override
  String get tasksDeleteListConfirm => 'حذف القائمة ومهامها؟';

  @override
  String get tasksEmpty => 'لا توجد مهام هنا';

  @override
  String get tasksEmptyHint =>
      'أضف أشياء للقيام بها؛ وتظهر المهام ذات تاريخ الاستحقاق في التقويم أيضًا.';

  @override
  String tasksCompleted(int count) {
    return 'المكتملة ($count)';
  }

  @override
  String get tasksClearCompleted => 'حذف المكتملة';

  @override
  String get taskEditTitle => 'تعديل المهمة';

  @override
  String get taskTitleHint => 'ما الذي يجب فعله؟';

  @override
  String get taskNotesHint => 'أضف تفاصيل';

  @override
  String get taskDue => 'تاريخ الاستحقاق';

  @override
  String get taskNoDue => 'بلا تاريخ';

  @override
  String get taskTime => 'الوقت';

  @override
  String get taskNoTime => 'بلا وقت';

  @override
  String get taskReminderAtDue => 'ذكّرني عند الاستحقاق';

  @override
  String get taskList => 'القائمة';

  @override
  String get taskStar => 'تمييز بنجمة';

  @override
  String get taskDelete => 'حذف المهمة';

  @override
  String get taskDeleted => 'حُذفت المهمة';

  @override
  String get taskAddSubtask => 'إضافة مهمة فرعية';

  @override
  String get taskOverdue => 'متأخرة';

  @override
  String get calendarViewYear => 'السنة';

  @override
  String get calendarViewWeek => 'الأسبوع';

  @override
  String get calendarPinchHint =>
      'اقرص بإصبعين للتنقل بين السنة والشهر والأسبوع';

  @override
  String get calendarPrevious => 'السابق';

  @override
  String get calendarNext => 'التالي';

  @override
  String get themeWhite => 'أبيض';

  @override
  String get themeStraw => 'قش';

  @override
  String get calendarSwipe => 'السحب لتغيير الأسبوع/اليوم في التقويم';

  @override
  String get calendarSwipeInfo =>
      'عند الإيقاف تغيّر أزرار الأسهم فقط الشهر أو الأسبوع.';

  @override
  String calendarMoved(String day) {
    return 'نُقل إلى $day';
  }

  @override
  String get gcalTitle => 'تقويم Google';

  @override
  String get gcalInfo =>
      'تظهر هنا أحداث تقويم Google (للقراءة فقط). يمكنك ربط الملاحظات بها؛ ولا يُكتب شيء في Google.';

  @override
  String get gcalConnect => 'ربط تقويم Google';

  @override
  String get gcalConnectFailed => 'تعذّر ربط تقويم Google';

  @override
  String get gcalCalendars => 'التقاويم المعروضة';

  @override
  String get gcalRefresh => 'تحديث';

  @override
  String get gcalDisconnect => 'قطع الاتصال';

  @override
  String get gcalError =>
      'تقويم Google غير متاح الآن؛ تُعرض الأحداث المخزنة مؤقتًا.';

  @override
  String get gcalReadOnly =>
      'حدث من تقويم Google · عدّل المتكررة في تقويم Google';

  @override
  String get gcalOpenInGoogle => 'فتح في تقويم Google';

  @override
  String get calendarMeetingNote => 'ملاحظة اجتماع';

  @override
  String get calendarLinkedNotes => 'الملاحظات المرتبطة';

  @override
  String get calendarUnlinkNote => 'إلغاء الربط';

  @override
  String gcalSyncedAt(String time) {
    return 'آخر مزامنة $time';
  }

  @override
  String get calendarLinked => 'رُبط بالتقويم';

  @override
  String get calendarLinkNote => 'ربط بالتقويم';

  @override
  String get calendarLinkToDay => 'ربط بيوم';

  @override
  String get calendarLinkNewEvent => 'إنشاء حدث وربطه';

  @override
  String get calendarLinkToEvent => 'ربط بحدث';

  @override
  String get calendarHolidays => 'العطل الرسمية (تركيا)';

  @override
  String get calendarHolidayEstimated => 'تقديري';

  @override
  String get calendarDayNote => 'ملاحظة لهذا اليوم';

  @override
  String calendarDayWrittenNotes(int count) {
    return 'ملاحظات كُتبت ذلك اليوم ($count)';
  }

  @override
  String calendarMoreCount(int count) {
    return '+$count أخرى';
  }

  @override
  String get calendarWeekSummaryTitle => 'هذا الأسبوع';

  @override
  String calendarWeekSummaryPlans(int count) {
    return '$count خطط';
  }

  @override
  String calendarWeekSummaryNotes(int count) {
    return '$count ملاحظات';
  }

  @override
  String get itemMenuTask => 'جعله مهمة';

  @override
  String get gtasksTitle => 'مهام Google';

  @override
  String get gtasksConnected => 'تم ربط مهام Google ومزامنتها';

  @override
  String get gtasksFailed => 'تعذّرت المزامنة مع مهام Google';

  @override
  String get gtasksSyncNow => 'مزامنة الآن';

  @override
  String get gtasksSynced => 'تمت مزامنة المهام';

  @override
  String get eventSaveLocal => 'كل الأجهزة';

  @override
  String get gcalWriteDenied => 'لم يُمنح إذن الكتابة في تقويم Google';

  @override
  String get gcalDeleteConfirm =>
      'حذف هذا الحدث من تقويم Google؟ لا يمكن التراجع عن ذلك.';

  @override
  String get gcalEdit => 'تعديل';

  @override
  String gcalPending(int count) {
    return '$count تغييرات بانتظار الإرسال إلى Google';
  }

  @override
  String get ocrToEvent => 'إضافة إلى التقويم كحدث';

  @override
  String get calendarSuggestAction => 'إضافة إلى التقويم';

  @override
  String calendarSuggest(String when) {
    return 'ملاحظتك تذكر $when';
  }

  @override
  String get calendarIcsExport => 'تصدير التقويم (.ics)';

  @override
  String get calendarIcsImport => 'استيراد ملف تقويم (.ics)';

  @override
  String calendarIcsImported(int count, int skipped) {
    return 'أُضيفت $count أحداث، و$skipped كانت موجودة';
  }

  @override
  String get routinesTitle => 'الروتين';

  @override
  String get routineNew => 'روتين جديد';

  @override
  String get routineEdit => 'تعديل الروتين';

  @override
  String get routinesEmpty => 'لا يوجد روتين هنا بعد';

  @override
  String get routinesEmptyHint =>
      'أنشئ خطة متكررة مثل روتين الصباح: أنجز خطواتها وتابع سلسلتك.';

  @override
  String get routineDoneToday => 'أُنجز اليوم';

  @override
  String get routineStartToday => 'إنجاز اليوم';

  @override
  String get routineDone => 'تم';

  @override
  String get routineTitleHint => 'اسم الروتين';

  @override
  String get routineTime => 'الوقت';

  @override
  String get routineRemind => 'ذكّرني عند الموعد';

  @override
  String get routineSteps => 'الخطوات';

  @override
  String get routineStepHint => 'خطوة';

  @override
  String get routineAddStep => 'إضافة خطوة';

  @override
  String get routineDeleted => 'حُذف الروتين';

  @override
  String routineStreak(int count) {
    return '🔥 $count أيام';
  }

  @override
  String routineStepCount(int count) {
    return '$count خطوات';
  }

  @override
  String routineProgress(int done, int total) {
    return '$done/$total خطوات';
  }

  @override
  String get menuSearchHint => 'ابحث بالاسم أو الوظيفة (مثل: جمع، مشاركة)';

  @override
  String get menuSearchEmpty => 'لا يوجد إجراء مطابق';

  @override
  String get menuEdit => 'تعديل القائمة';

  @override
  String get menuSectionOther => 'أخرى';

  @override
  String get menuQuickRow => 'وضعه في الصف السريع';

  @override
  String get menuReset => 'الافتراضي';

  @override
  String get themeCream => 'كريمي';

  @override
  String get themePeach => 'خوخي';

  @override
  String get themeMint => 'نعناعي';

  @override
  String get themeOcean => 'محيط';

  @override
  String get themeRose => 'وردي';

  @override
  String get themeTangerine => 'يوسفي';

  @override
  String get themeEmerald => 'زمردي';

  @override
  String get themeAmethyst => 'جمشت';

  @override
  String get themePickerTitle => 'المظهر';

  @override
  String get reminderQuickInHour => 'بعد ساعة';

  @override
  String get reminderSheetTitle => 'تذكير';

  @override
  String get reminderSheetRemove => 'إزالة';

  @override
  String get reminderSheetSave => 'حفظ';

  @override
  String get homeFolderStripHide => 'إخفاء صف المجلدات';

  @override
  String get homeViewMenu => 'العرض والتصفية';

  @override
  String googleApiDisabled(String api) {
    return '$api معطّلة في مشروع Google Cloud لهذا التطبيق. فعّلها من وحدة التحكم واربط مجددًا.';
  }

  @override
  String get googleApiEnable => 'تفعيل';

  @override
  String googleScopeMissing(String api) {
    return 'لم يُمنح إذن $api. حدّد مربع الإذن عند الربط.';
  }

  @override
  String get friendsEmptyTitle => 'لا توجد جهات اتصال هنا بعد';

  @override
  String get friendsFilterHint => 'البحث في جهات الاتصال';

  @override
  String get friendsNoName => 'بلا اسم';

  @override
  String get friendsSharedFolders => 'المجلدات المشتركة';

  @override
  String get friendsNoSharedFolders => 'لم تشارك مجلدًا مع هذا الشخص بعد.';

  @override
  String friendsSince(String date) {
    return 'في جهات اتصالك منذ $date';
  }

  @override
  String get friendsCopyEmail => 'نسخ البريد الإلكتروني';

  @override
  String get friendsEmailCopied => 'نُسخ البريد الإلكتروني';

  @override
  String get friendsWantsToConnect => 'يريد إضافتك كجهة اتصال';

  @override
  String get friendsSendToEmail => 'إرسال طلب إلى هذا العنوان';

  @override
  String get friendsSent => 'أُرسل';

  @override
  String get friendsAlreadyShort => 'في جهات الاتصال';

  @override
  String get settingsGroupAccount => 'الحساب';

  @override
  String get settingsGroupApp => 'التطبيق';

  @override
  String get settingsUpdatesTitle => 'التحديثات والإصدار';

  @override
  String get settingsGroupData => 'البيانات والخصوصية';

  @override
  String get settingsGroupOther => 'أخرى';

  @override
  String friendsCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جهات اتصال',
      one: 'جهة اتصال واحدة',
      zero: 'لا جهات اتصال بعد',
    );
    return '$_temp0';
  }

  @override
  String friendsRequestsSummary(int count) {
    return '$count معلّقة';
  }

  @override
  String get inkFixApply => 'تهذيب الشكل';

  @override
  String get inkShapeSuggestTitle => 'التعرّف على الأشكال';

  @override
  String get inkShapeSuggestInfo =>
      'ارسم دائرة أو مربعًا أو خطًا أو سهمًا تقريبيًا ليظهر زر التهذيب.';

  @override
  String get inkMarkFixTitle => 'تهذيب علامات ✓ و✗';

  @override
  String get inkMarkFixInfo => 'يظهر زر تهذيب لعلامات ✓ و✗ المرسومة باليد.';

  @override
  String get inkMarkFixAskTitle => 'تفعيل تهذيب علامات الصح والخطأ؟';

  @override
  String get inkMarkFixAskBody =>
      'يمكن تهذيب علامات الصح والخطأ المرسومة باليد. تؤكد كل واحدة بالزر الصغير بجانبها؛ ويمكنك إيقاف ذلك من إعدادات القلم.';

  @override
  String get inkMarkFixAskYes => 'تفعيل';

  @override
  String get inkMarkFixAskNo => 'لا';

  @override
  String get inkPinPen => 'تثبيت هذا القلم';

  @override
  String get inkPinnedPen => 'قلم مثبّت · اضغط مطولًا للإزالة';

  @override
  String get reminderLevelTitle => 'الإشعار';

  @override
  String get reminderLevelLow => 'منخفض';

  @override
  String get reminderLevelNormal => 'عادي';

  @override
  String get reminderLevelHigh => 'مرتفع';

  @override
  String get reminderLevelUrgent => 'عاجل';

  @override
  String get reminderLevelLowInfo => 'صامت؛ في لوحة الإشعارات فقط';

  @override
  String get reminderLevelNormalInfo => 'صوت عادي، دون نافذة منبثقة';

  @override
  String get reminderLevelHighInfo => 'صوت ونافذة منبثقة أعلى الشاشة';

  @override
  String get reminderLevelUrgentInfo => 'ملء الشاشة، أعلى أولوية (مثل المنبّه)';

  @override
  String get itemMenuRemind => 'تذكير';

  @override
  String get taskContactHint => 'شخص (إلى / من)';

  @override
  String get taskGmailHint => 'رابط Gmail';

  @override
  String dueBadgeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تذكيرات/مهام بالانتظار',
      one: 'تذكير/مهمة واحدة بالانتظار',
    );
    return '$_temp0';
  }

  @override
  String get dueBadgeBody => 'المستحق الآن ومهام اليوم — على الشاشة الرئيسية';

  @override
  String get dueBadgeChannel => 'بالانتظار (شارة الأيقونة)';

  @override
  String get quickRowAttach => 'إضافة';

  @override
  String get quickRowColor => 'لون النص (اضغط مطولًا: اختر المفضل)';

  @override
  String get penModePenOnlyOn => 'وضع القلم · القلم فقط: مفعّل (الإصبع يمرّر)';

  @override
  String get penModePenOnlyOff =>
      'وضع القلم · القلم فقط: متوقف (الإصبع يرسم أيضًا)';

  @override
  String get penModeSettings => 'الإعدادات';

  @override
  String get quickRowBold => 'غامق';

  @override
  String get quickRowBullet => 'نقطة';

  @override
  String get quickRowHeading => 'عنوان (يتنقل)';

  @override
  String get quickRowPhoto => 'إضافة صورة';

  @override
  String get quickRowFile => 'إرفاق ملف';

  @override
  String get quickRowPen => 'الكتابة بالقلم · ضغط مطوّل: إعدادات القلم';

  @override
  String get editorBarEraser => 'ممحاة · يفتح وضع القلم بالممحاة';

  @override
  String get quickRowReminder => 'تذكير';

  @override
  String get hideBarWhileTyping => 'إخفاء الشريط السفلي أثناء الكتابة';

  @override
  String get hideBarWhileTypingInfo =>
      'ينزلق الشريط السفلي بعيدًا أثناء الكتابة ويعود عند التوقف.';

  @override
  String get typingBarHideDelay => 'مهلة الإخفاء';

  @override
  String get typingBarHideDelayInfo => 'بعد كم من بدء الكتابة يختفي الشريط';

  @override
  String get typingBarShowDelay => 'مهلة الظهور';

  @override
  String get typingBarShowDelayInfo =>
      'بعد كم من التوقف عن الكتابة يعود الشريط';

  @override
  String secondsValue(String value) {
    return '$value ث';
  }

  @override
  String get tipHideBarTyping =>
      'يختفي الشريط السفلي أثناء الكتابة ويعود عند التوقف. يمكنك إيقاف ذلك من الإعدادات.';

  @override
  String get addToNoteTitle => 'إضافة إلى الملاحظة';

  @override
  String get addToNewNote => 'ملاحظة جديدة';

  @override
  String get addToNoteEmpty => 'لا توجد ملاحظات أخرى بعد';

  @override
  String get calendarLinkExistingNote => 'ربط ملاحظة موجودة';

  @override
  String get routineFromNote => 'إنشاء روتين من ملاحظة';

  @override
  String get quickRowSubheading => 'عنوان فرعي';

  @override
  String get quickRowItalic => 'مائل';

  @override
  String get quickRowUnderline => 'تسطير';

  @override
  String get quickRowHighlight => 'تظليل';

  @override
  String get quickRowSpellOn =>
      'تصحيح الإملاء: مفعّل (تُصحَّح كل كلمة تلقائيًا)';

  @override
  String get quickRowSpellOff => 'تصحيح الإملاء: متوقف';

  @override
  String get quickRowPackage => 'حزم';

  @override
  String get notePackageHint => 'نص طويل — احزمه للترتيب';

  @override
  String get quickRowDictation => 'إملاء';

  @override
  String get notePackageSelectFirst => 'حدّد نصًا لحزمه (أو اضغط فقرة طويلة)';

  @override
  String notePackageCount(int count) {
    return '$count عناصر';
  }

  @override
  String get notePackageUnpack => 'فك الحزم (إعادته إلى الملاحظة)';

  @override
  String get pinnedPenWrite => 'اكتب عليه بالقلم';

  @override
  String get pinnedShrinkToFit => 'تصغير عند التضييق';

  @override
  String get quickRowCamera => 'التقاط صورة';

  @override
  String get quickRowScan => 'مسح مستند';

  @override
  String get quickRowDate => 'إدراج التاريخ والوقت';

  @override
  String get spellAutoTitle => 'تصحيح تلقائي';

  @override
  String get spellLearnTitle => 'تصحيح يتعلّم';

  @override
  String get spellCheckDoneTitle => 'تدقيق العناصر المنجزة أيضًا';

  @override
  String get spellCheckDoneSubtitle =>
      'عند الإيقاف لا يوضع خط تحت العناصر المنجزة';

  @override
  String get spellManualHint => 'اكتب الكلمة الصحيحة';

  @override
  String get spellManualFix => 'تصحيح يدوي';

  @override
  String get spellLearnSubtitle =>
      'يتعلّم الكلمات التي تصححها بنفسك أو تختارها من اقتراحات لوحة المفاتيح. يُزامَن قاموسك الشخصي مع حسابك.';

  @override
  String spellLearnedCount(int count) {
    return '$count تصحيحات متعلَّمة';
  }

  @override
  String get spellForget => 'نسيان ما تم تعلمه';

  @override
  String get spellForgotten => 'أُزيلت التصحيحات المتعلَّمة';

  @override
  String get spellModeTitle => 'التدقيق الإملائي';

  @override
  String get spellModeInfo =>
      'إظهار فقط: يوضع خط تحت الأخطاء. تلقائي: يصحح عند التأكد.';

  @override
  String get spellModeOff => 'متوقف';

  @override
  String get spellModeShow => 'إظهار فقط';

  @override
  String get spellModeAuto => 'تلقائي';

  @override
  String get spellAddToDictionary => 'إضافة إلى القاموس';

  @override
  String spellAlwaysFix(String word) {
    return 'صحّح دائمًا: $word';
  }

  @override
  String get spellKeepInNote => 'تجاهل في هذه الملاحظة';

  @override
  String get spellReviewAction => 'تدقيق الإملاء';

  @override
  String get spellReviewNoteOption => 'تدقيق هذه الملاحظة';

  @override
  String get spellReviewClean => 'لم يُعثر على أخطاء إملائية';

  @override
  String get spellReviewCleanHint => 'كل كلمات هذه الملاحظة تبدو سليمة.';

  @override
  String spellReviewFixAll(int count) {
    return 'تصحيح الكل ($count)';
  }

  @override
  String spellReviewApply(int count) {
    return 'تطبيق ($count)';
  }

  @override
  String get spellReviewSkip => 'تخطٍّ';

  @override
  String get spellReviewHintBadge => 'تلميح سياقي';

  @override
  String spellReviewFixed(int count) {
    return 'طُبّقت $count تصحيحات إملائية';
  }

  @override
  String get lineTaskRetime => 'تغيير الوقت';

  @override
  String get lineTaskDone => 'تم';

  @override
  String get lineTaskUndone => 'تعليم كغير منجز';

  @override
  String get lineTaskDetails => 'التفاصيل (المستوى، التكرار، جهة الاتصال)';

  @override
  String get lineTaskDelete => 'حذف التذكير';

  @override
  String get inkShapeTriangle => 'مثلث';

  @override
  String get inkShapeTable => 'جدول';

  @override
  String get homeFolderStripShort => 'صف المجلدات';

  @override
  String get homeCalendarStripShort => 'شريط التقويم';

  @override
  String get homeCalendarStrip => 'شريط التقويم في الأعلى';

  @override
  String get homeCalendarStripInfo =>
      'تقويم بالأحداث والمهام والعطل أعلى الشاشة الرئيسية.';

  @override
  String get homeCalendarStripExpand => 'توسيع شريط التقويم';

  @override
  String get homeCalendarStripCollapse => 'طي شريط التقويم';

  @override
  String get folderMenuEdit => 'إعادة ترتيب · حذف';

  @override
  String get themeClassic => 'كلاسيكي';

  @override
  String get themeNewsprint => 'ورق الجرائد';

  @override
  String get themeNotebook => 'دفتر';

  @override
  String get themeGraphite => 'جرافيت';

  @override
  String get themeLedger => 'دفتر حسابات';

  @override
  String get themeGroupCalm => 'هادئ';

  @override
  String get themeGroupPaper => 'ورق';

  @override
  String get themeGroupVivid => 'زاهٍ';

  @override
  String get spellLearnedTitle => 'الكتابات المتعلَّمة';

  @override
  String get spellLearnedInfo =>
      'كلمات كتبتها ثم صححتها بنفسك أو اخترتها من اقتراحات لوحة المفاتيح. يمكنك إضافة كلماتك: خطأ ← صحيح (تُطبَّق فورًا).';

  @override
  String get spellLearnedSettingInfo =>
      'عرض التصحيحات المتعلَّمة وإضافتها وحذفها';

  @override
  String get spellLearnedWrong => 'خطأ';

  @override
  String get spellLearnedRight => 'صحيح';

  @override
  String get spellLearnedAdd => 'إضافة';

  @override
  String get spellLearnedEmpty => 'لا توجد تصحيحات متعلَّمة بعد.';

  @override
  String spellLearnedSeen(int count) {
    return '$count مرات';
  }

  @override
  String get spellLearnedKept => 'كلمات تُركت كما هي (تراجعت عن التصحيح)';

  @override
  String get spellRulesOnlyTitle => 'القواعد فقط';

  @override
  String get spellRulesOnlySubtitle =>
      'تُصحَّح فقط الأخطاء المعروفة والتصحيحات التي علّمتها؛ دون تخمين.';

  @override
  String get spellRejectedTitle =>
      'تصحيحات لن تُجرى مجددًا (تراجعت عنها أو غيّرتها)';

  @override
  String get inkEraserOffer => 'اختيار الممحاة';

  @override
  String get inkPenOffer => 'العودة إلى القلم';

  @override
  String get tipPenShapeHold =>
      'أبقِ القلم ثابتًا في نهاية الخط: تتحول الخطوط والمربعات والدوائر إلى أشكال نظيفة.';

  @override
  String get tipPenEraserHold =>
      'للمحو اضغط مطولًا على خط ← اضغط زر الممحاة. إصبعان = تمرير/تكبير.';

  @override
  String backupStatusCloud(int count) {
    return 'السحابة: $count ملاحظات في حساب Google، والتغييرات تُزامَن تلقائيًا';
  }

  @override
  String get backupStatusGuest =>
      'لا نسخة سحابية: الملاحظات على هذا الجهاز فقط. اربط حساب Google أو أنشئ نسخة احتياطية كاملة.';

  @override
  String backupStatusLast(String date, int count) {
    return 'آخر نسخة كاملة: $date · $count ملاحظات';
  }

  @override
  String get backupStatusNever =>
      'لم تُنشأ نسخة احتياطية كاملة على هذا الجهاز بعد';

  @override
  String get attachmentAddText => 'اكتب عليه';

  @override
  String get stylusTogglesOn => 'القلم يكتب';

  @override
  String get stylusTogglesOff => 'القلم ينقر (لا يكتب)';

  @override
  String updateBanner(String version) {
    return 'يتوفر إصدار جديد: v$version — اضغط للتنزيل والتثبيت';
  }

  @override
  String updateBannerReady(String version) {
    return 'نُزّل v$version — اضغط للتثبيت الآن';
  }

  @override
  String updateBannerDownloading(String version, int percent) {
    return 'جارٍ تنزيل v$version… $percent%';
  }

  @override
  String updateReadyToInstall(String version) {
    return 'نُزّل v$version؛ وسيُثبَّت عند فتح التطبيق في المرة القادمة';
  }

  @override
  String get updateInstallNow => 'التثبيت الآن';

  @override
  String get updateDownloadFailed =>
      'تعذّر تنزيل الإصدار الجديد — تحقق من الاتصال واضغط مجددًا';

  @override
  String get updateInstallFailed => 'لم يكتمل التثبيت — حاول مجددًا';

  @override
  String get autoUpdateTitle => 'التحديث تلقائيًا';

  @override
  String get autoUpdateInfo =>
      'تُنزَّل الإصدارات الجديدة في الخلفية وتُثبَّت عند فتح التطبيق في المرة القادمة';

  @override
  String get updateInstall => 'تحديث';

  @override
  String get updateNeedsPermission =>
      'اسمح لهذا التطبيق بتثبيت تطبيقات غير معروفة، ثم اضغط «تحديث» مجددًا';

  @override
  String get updateTapToCheck => 'اضغط للتحقق من التحديثات';

  @override
  String get updateReopenOn => 'يُعاد فتحه تلقائيًا بعد التحديث';

  @override
  String get updateReopenOff => 'إعادة الفتح بعد التحديث: سماح';

  @override
  String get updateChecking => 'جارٍ التحقق من التحديثات…';

  @override
  String get updateUpToDate => 'لديك أحدث إصدار';

  @override
  String get releaseNotesTitle => 'ملاحظات الإصدار';

  @override
  String get settingsWritingTitle => 'القلم والكتابة والشاشة';

  @override
  String get settingsWritingSummary => 'القلم · تصحيح الإملاء · أشرطة الرئيسية';

  @override
  String get settingsPenSection => 'القلم';

  @override
  String get settingsSpellSection => 'تصحيح الإملاء';

  @override
  String get settingsScreenSection => 'الشاشة الرئيسية وشاشة الملاحظة';

  @override
  String get settingsShowAllNotes => 'ملاحظات المجلدات في الرئيسية أيضًا';

  @override
  String get settingsShowAllNotesInfo =>
      'تظهر ملاحظات المجلدات في الرئيسية أيضًا (عدا الأرشيف والمخفية).';

  @override
  String get settingsAttachmentsExpanded => 'شريط المرفقات مفتوح في الملاحظات';

  @override
  String get settingsListPaneCollapsed =>
      'إخفاء قائمة الملاحظات في الشاشات العريضة (تركيز)';

  @override
  String get settingsListPaneCollapsedInfo =>
      'على الجهاز اللوحي والويب تبدأ القائمة مغلقة أثناء فتح ملاحظة.';

  @override
  String get pinnedSideToggle => 'الموضع: أعلى / يسار / يمين';

  @override
  String get pinnedSideTitle => 'موضع اللوحة';

  @override
  String get pinnedSideTop => 'أعلى';

  @override
  String get pinnedSideLeft => 'يسار';

  @override
  String get pinnedSideRight => 'يمين';

  @override
  String releaseNotesToastTitle(String version) {
    return 'الجديد · v$version';
  }

  @override
  String releaseNotesToastMore(int count) {
    return '+$count أخرى';
  }

  @override
  String get releaseNotesToastAll => 'عرض الكل';

  @override
  String get updateInstalling =>
      'نُزّل — جارٍ التثبيت؛ سيُغلق التطبيق ويُعاد فتحه';

  @override
  String get updateAborted => 'أُلغي التثبيت — اضغط للمحاولة مجددًا';

  @override
  String get updateOpenedBrowser => 'فُتحت صفحة التنزيل في المتصفح';

  @override
  String cardHiddenYoutube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فيديوهات YouTube',
      one: 'فيديو YouTube',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenVideo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فيديوهات',
      one: 'فيديو',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenImage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صور',
      one: 'صورة',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenDoc(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مستندات',
      one: 'PDF',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تسجيلات صوتية',
      one: 'تسجيل صوتي',
    );
    return '$_temp0';
  }

  @override
  String get quickAddKeepOne => 'يجب أن يبقى خيار واحد ظاهرًا على الأقل';

  @override
  String get attachmentUploadNow => 'حاول الآن';

  @override
  String uploadPendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مرفقات بانتظار الرفع',
      one: 'مرفق واحد بانتظار الرفع',
    );
    return '$_temp0';
  }

  @override
  String get uploadPendingBody => 'يُرفع عند فتحك للتطبيق.';

  @override
  String get uploadPendingChannel => 'رفع المرفقات المعلّق';

  @override
  String placementHintShort(String view) {
    return 'أُضيف كـ$view · اضغط المفتاح للتغيير';
  }

  @override
  String get listPaneRight => 'قائمة الملاحظات على اليمين';

  @override
  String get listPaneRightInfo =>
      'في العرض المقسّم (جهاز لوحي، نافذة عريضة) تكون القائمة يمين الملاحظة';

  @override
  String get listPaneMoveRight => 'نقل القائمة إلى اليمين';

  @override
  String get noteOpenSide => 'فتح جنبًا إلى جنب';

  @override
  String get micBusySideNote => 'الميكروفون مستخدم في الملاحظة الأخرى';

  @override
  String get noteCloseSide => 'إغلاق الملاحظة الجانبية';

  @override
  String get listPaneMoveLeft => 'نقل القائمة إلى اليسار';

  @override
  String get quickRowEditTitle => 'القائمة السريعة (أعلى، أثناء الكتابة)';

  @override
  String get quickRowEditInfo =>
      'اضغط للإضافة إلى القائمة أو الإزالة منها. تُطبَّق التغييرات فورًا دون حفظ.';

  @override
  String get quickRowEditShown => 'في القائمة';

  @override
  String get quickRowEditAvailable => 'متاح';

  @override
  String get quickRowEditEmpty => 'القائمة فارغة — أضف أزرارًا أدناه';

  @override
  String get quickRowEditReset => 'إعادة إلى الافتراضي';

  @override
  String get quickRowShortPen => 'القلم';

  @override
  String get quickRowShortSpell => 'التدقيق الإملائي';

  @override
  String get quickRowShortColor => 'لون النص';

  @override
  String get quickRowShortHeading => 'عنوان';

  @override
  String get quickEntryHint => 'اكتب أو قل: موز تفاح، 2 حليب…';

  @override
  String get quickEntryListening => 'جارٍ الاستماع…';

  @override
  String get quickEntryMic => 'إضافة بالصوت';

  @override
  String get quickEntryMicStop => 'إيقاف الاستماع';

  @override
  String get quickListEmpty =>
      'اكتب في الأعلى أو تحدّث أو اضغط أدناه؛ تُبنى قائمتك هنا.';

  @override
  String get smartListHint =>
      'اكتب أو قل حليب، خبز…؛ وللأمتعة قل «قائمة الأمتعة».';

  @override
  String get quickListDone => 'تم';

  @override
  String get quickListAisleSort => 'ترتيب حسب القسم';

  @override
  String get quickListOpenInNote => 'فتح كملاحظة';

  @override
  String get quickListDiscard => 'تجاهل';

  @override
  String get quickListFrequent => 'المعتاد لديك';

  @override
  String get quickListLeftovers => 'من المرة السابقة';

  @override
  String get quickListAddAll => 'إضافة الكل';

  @override
  String quickListSaved(String title) {
    return 'حُفظت «$title»';
  }

  @override
  String get quickListOpen => 'فتح';

  @override
  String get quickListRemove => 'إزالة';

  @override
  String quickListCorrected(String typed) {
    return 'كتبت «$typed»؛ اضغط للتراجع';
  }

  @override
  String quickListRestored(String typed) {
    return 'أُبقيت كـ«$typed»؛ ولن تُصحَّح مجددًا';
  }

  @override
  String get quickDropTitle => 'إضافة سريعة';

  @override
  String get quickDropInfo => 'اكتب أو تحدّث؛ ويذهب إلى الملاحظة التي تختارها';

  @override
  String get quickDropHint => 'حليب، خبز… أو «أضف الحليب إلى قائمة التسوق»';

  @override
  String get quickDropTarget => 'الإضافة إلى أي ملاحظة؟';

  @override
  String get quickDropNoNotesNew =>
      'لا توجد قائمة أو ملاحظة نصية للإضافة إليها بعد: ما تكتبه يُحفظ كملاحظة جديدة.';

  @override
  String get quickDropSavingNew => 'جارٍ الحفظ كملاحظة جديدة…';

  @override
  String get quickDropSavedNew => 'حُفظت كملاحظة جديدة';

  @override
  String get quickDropAdd => 'إضافة';

  @override
  String quickDropAdded(int count, String title) {
    return 'أُضيفت $count عناصر إلى «$title»';
  }

  @override
  String quickDropAddedText(String title) {
    return 'أُضيف إلى «$title»';
  }

  @override
  String quickDropNothingNew(String title) {
    return 'كل شيء موجود بالفعل في «$title»';
  }

  @override
  String get quickDropKeyboard => 'لوحة المفاتيح عند الفتح';

  @override
  String get quickDropMicAuto => 'الاستماع عند الفتح';

  @override
  String get noteExpiry => 'الأرشفة في…';

  @override
  String get noteExpiryDay => 'يوم واحد';

  @override
  String get noteExpiry3Days => '3 أيام';

  @override
  String get noteExpiryWeek => 'أسبوع';

  @override
  String get noteExpiryMonth => 'شهر';

  @override
  String get noteExpiryPick => 'اختيار التاريخ والوقت';

  @override
  String get noteExpiryRemove => 'إزالة المؤقت';

  @override
  String noteExpiryChip(String date) {
    return 'تُؤرشف $date';
  }

  @override
  String noteExpiryLeftDays(int n) {
    return '$nي';
  }

  @override
  String noteExpiryLeftHours(int n) {
    return '$nس';
  }

  @override
  String noteExpiryLeftMinutes(int n) {
    return '$nد';
  }

  @override
  String get smartList => 'قائمة ذكية';

  @override
  String get smartListInfo =>
      'اكتب أو تحدّث؛ يحدد التسوق أو الأمتعة ويجمّع العناصر';

  @override
  String get smartListGeneric => 'قائمة';

  @override
  String get smartListPacking => 'قائمة الأمتعة';

  @override
  String get smartListPharmacy => 'قائمة الصيدلية';

  @override
  String get smartListStationery => 'قائمة القرطاسية';

  @override
  String get smartListHardware => 'قائمة العُدد';

  @override
  String get smartListCamping => 'قائمة التخييم';

  @override
  String get smartListBaby => 'حقيبة الرضيع';

  @override
  String get smartListSport => 'حقيبة الرياضة';

  @override
  String get sortByGroup => 'حسب القسم / المجموعة';

  @override
  String get finishShopping => 'إنهاء التسوق';

  @override
  String finishShoppingDone(int count) {
    return 'أُزيلت $count عناصر منجزة';
  }

  @override
  String get scanAny => 'مسح';

  @override
  String get scanAnyInfo => 'مستند أو رمز QR — تُلتقط رموز QR تلقائيًا';

  @override
  String get scanAnyHint =>
      'تُلتقط رموز QR تلقائيًا. للمستند اضغط «مسح مستند».';

  @override
  String get scanQrFound => 'عُثر على رمز QR';

  @override
  String get scanUseQr => 'استخدام رمز QR';

  @override
  String get listToNumbered => 'جعلها مرقّمة';

  @override
  String get listToChecklist => 'جعلها قائمة مهام';

  @override
  String get quickDropWhich => 'في أي ملاحظة يذهب هذا؟';

  @override
  String get quickDropAsking => 'جارٍ تحديد الملاحظة…';

  @override
  String quickDropAddingTo(String title) {
    return 'جارٍ الإضافة إلى «$title»…';
  }

  @override
  String get quickDropWait => 'انتظر';

  @override
  String get quickDropAiToggle => 'اسأل الذكاء الاصطناعي عند الشك';

  @override
  String get aiOffTitle => 'الذكاء الاصطناعي متوقف';

  @override
  String get aiConsentTitle => 'استخدام الذكاء الاصطناعي';

  @override
  String get aiConsentWhat =>
      'ما يُرسل: فقط النص أو الملاحظة أو المرفق (صورة، صوت، PDF) الذي تختاره لتلك المهمة.';

  @override
  String get aiConsentWhere =>
      'إلى أين: إلى خدمة Gemini من Google (عبر Firebase)؛ وإن أدخلت مفتاحك فإلى المزوّد الذي اخترته.';

  @override
  String get aiConsentMistakes =>
      'قد يخطئ الذكاء الاصطناعي؛ تحقّق من المعلومات المهمة بنفسك.';

  @override
  String get aiConsentTurnOff =>
      'يمكنك إيقاف الذكاء الاصطناعي تمامًا في أي وقت من الإعدادات ← الذكاء الاصطناعي.';

  @override
  String get aiConsentAccept => 'أوافق';

  @override
  String get aiConsentDecline => 'ليس الآن';

  @override
  String get aiPausedTitle => 'الذكاء الاصطناعي غير متاح مؤقتًا';

  @override
  String get homePullGestureTitle => 'السحب للأسفل أعلى القائمة';

  @override
  String get homeSwipeRightGestureTitle => 'السحب يمينًا في «الكل»';

  @override
  String get homeGestureInfo => 'اختر ملاحظة أو مجلدًا لتفتحه الإيماءة مباشرة';

  @override
  String get homeGestureFolders => 'المجلدات';

  @override
  String get homeGestureNote => 'ملاحظة';

  @override
  String get homeGestureFolder => 'مجلد';

  @override
  String get homeGestureNone => 'لا شيء';

  @override
  String get homeGestureMissing =>
      'لم يُعثر على هدف الإيماءة؛ اختره مجددًا من الإعدادات ← الملاحظات';

  @override
  String get calendarExpiryTag => 'تُؤرشف';

  @override
  String get calendarExpiryRemoved => 'أُزيل وقت الأرشفة';

  @override
  String get inkFingerAuto => 'تلقائي';

  @override
  String get inkFingerAutoNowScroll =>
      'تلقائي: رُصد قلم على هذا الجهاز، لذا يمرّر الإصبع.';

  @override
  String get inkFingerAutoNowDraw =>
      'تلقائي: لم يُرصد قلم بعد، لذا يرسم الإصبع؛ ويتحول إلى التمرير أول ما يلمس القلم.';

  @override
  String get barMoreLeftGroup => 'المجموعة اليسرى';

  @override
  String get barMoreRightGroup => 'المجموعة اليمنى (ملوّنة)';

  @override
  String get barMoreToRight => 'نقل إلى المجموعة اليمنى';

  @override
  String get barMoreToLeft => 'نقل إلى المجموعة اليسرى';

  @override
  String get layoutScopeAll => 'تطبيق على الكل';

  @override
  String get layoutScopeNote => 'هذه الملاحظة فقط';

  @override
  String get layoutScopeInfoAll => 'تُطبَّق التغييرات على كل الملاحظات.';

  @override
  String get layoutScopeInfoNote =>
      'لهذه الملاحظة تخطيطها الخاص؛ وتُطبَّق التغييرات هنا فقط.';

  @override
  String get layoutScopeReset => 'إعادة تعيين تخطيط هذه الملاحظة';

  @override
  String quickRowEditNotHere(String names) {
    return 'غير معروض في هذه الملاحظة: $names';
  }

  @override
  String get barMoreEdit => 'تعديل الشريط السفلي';

  @override
  String get barMoreEditHint =>
      'الأزرار المثبّتة (📌) تبقى على الشريط (يتسع الهاتف لأول 3)؛ والباقي في هذه القائمة. اضغط مطولًا واسحب لإعادة الترتيب.';

  @override
  String get barMoreToBar => 'نقل إلى الشريط';

  @override
  String get barMoreToMenu => 'نقل إلى القائمة';

  @override
  String menuEditInlineHint(int count) {
    return 'اضغط مطولًا واسحب لإعادة الترتيب · ⊖ إخفاء · ☆ الصف السريع (حتى $count)';
  }

  @override
  String get menuHiddenGroup => 'مخفية';

  @override
  String get quickDropSettings => 'إعدادات الإضافة السريعة';

  @override
  String quickDropPreviewText(String title, String text) {
    return '← $title · $text';
  }

  @override
  String quickDropPreviewItems(String title, String items, int count) {
    return '← $title · $items ($count جديدة)';
  }

  @override
  String get quickDropPickMyself => 'سأختار بنفسي';

  @override
  String get quickDropFindNote => 'البحث عن ملاحظة';

  @override
  String quickDropPreviewReminder(String when, String text) {
    return '⏰ $when · $text';
  }

  @override
  String get quickDropSavedReminder => 'حُفظت كملاحظة مع تذكير';

  @override
  String quickDropPreviewCalendar(String day, String text) {
    return '📅 $day · $text';
  }

  @override
  String quickDropSavedCalendar(String day) {
    return 'أُضيفت الملاحظة إلى التقويم · $day';
  }

  @override
  String quickDropPreviewMulti(String summary, int count) {
    return '← $summary ($count ملاحظات)';
  }

  @override
  String quickDropAddedMulti(int count) {
    return 'أُضيف إلى $count ملاحظات';
  }

  @override
  String get aiNeedsProTitle => 'الذكاء الاصطناعي جزء من Pro';

  @override
  String get proTitle => 'النسخة الكاملة';

  @override
  String get proSettingsSubtitle =>
      'Lite مقابل النسخة الكاملة، أرصدة القرارات، المشتريات';

  @override
  String get proStatusFree => 'خطتك: Lite (مجانية · بلا إعلانات)';

  @override
  String get proStatusLifetime => 'خطتك: النسخة الكاملة (مدى الحياة)';

  @override
  String get proTiersTitle => 'الخطط';

  @override
  String get proTierFree => 'Lite';

  @override
  String get proTierLifetime => 'النسخة الكاملة';

  @override
  String get proRowBasics =>
      'ملاحظات، قوائم، قلم، PDF، تذكيرات، تقويم؛ تدقيق إملائي وإملاء وOCR وباركود على الجهاز، ووضع المتجر';

  @override
  String get proRowUnlimited => 'ملاحظات ومجلدات ومرفقات وأجهزة بلا حدود';

  @override
  String get proRowSync => 'المزامنة السحابية';

  @override
  String get proSyncPeriodic => 'دورية (5 د)';

  @override
  String get proSyncInstant => 'فورية';

  @override
  String get proRowAttachments => 'تُخزَّن المرفقات في';

  @override
  String get proAttachDrive => 'Drive الخاص بك';

  @override
  String get proAttachCloud => 'Drive + مشترك';

  @override
  String get proRowHistory => 'سجل 30 إصدارًا، نسخة احتياطية محمية بكلمة مرور';

  @override
  String get proRowLooks => 'كل المظاهر، 19 خطًا، أنماط الورق';

  @override
  String get proRowAi => 'قرارات ذكية (الأقسام، التوجيه، الوسوم)';

  @override
  String get proDecisionsIncluded => '750 استدعاء';

  @override
  String get proRowOwnKey => 'مفتاح Gemini الخاص بك';

  @override
  String get proLockedBadge => 'في النسخة الكاملة';

  @override
  String get proBuyTitle => 'شراء';

  @override
  String get proPlanLifetime => 'النسخة الكاملة · مرة واحدة (مدى الحياة)';

  @override
  String get proPlanDecisionPack => 'حزمة +1,000 قرار ذكي';

  @override
  String proPriceOnce(String price) {
    return '$price · تدفع مرة واحدة، بلا اشتراك';
  }

  @override
  String get proBuy => 'شراء';

  @override
  String get proOwned => 'مملوك';

  @override
  String get proRestore => 'استعادة المشتريات';

  @override
  String get proTerms =>
      'بلا اشتراكات وبلا إعلانات. النسخة الكاملة شراء لمرة واحدة مدى الحياة يشمل 750 قرارًا ذكيًا. عند نفاد الأرصدة يستمر التطبيق وكل الميزات على الجهاز بلا حدود؛ ويمكنك اختياريًا إضافة حزمة +1,000 قرار أو استخدام مفتاح Gemini الخاص بك.';

  @override
  String get proLoading => 'جارٍ جلب الأسعار من Google Play…';

  @override
  String get proUnavailable => 'تعذّر الوصول إلى Google Play.';

  @override
  String get proElsewhere =>
      'تتم المشتريات على هاتفك: في تطبيق أندرويد، الإعدادات ← النسخة الكاملة. وما تشتريه يُفتح هنا أيضًا على هذا الحساب.';

  @override
  String get proGuest =>
      'سجّل الدخول بحساب Google للشراء: حساب الضيف موجود على هذا الجهاز فقط، فقد يضيع الشراء معه.';

  @override
  String get proNoticePending => 'الدفع معلّق؛ تُفتح خطتك تلقائيًا بعد تأكيده.';

  @override
  String get proNoticeCanceled => 'أُلغي الشراء.';

  @override
  String get proNoticeFailed => 'تعذّر إتمام الشراء. حاول مجددًا بعد قليل.';

  @override
  String get proNoticeVerifyFailed =>
      'تعذّر التحقق من الشراء؛ يعيد التطبيق المحاولة عند فتحه التالي. يردّ Google Play المبالغ غير المتحقق منها.';

  @override
  String get proNoticeOtherAccount =>
      'هذا الشراء يخص حسابًا آخر. سجّل الدخول بذلك الحساب لاستخدامه.';

  @override
  String get proNoticeDone => 'شكرًا! فُتحت خطتك.';

  @override
  String get proNoticeRestored => 'استُعيدت مشترياتك.';

  @override
  String get proNoticeNothing =>
      'لا توجد مشتريات للاستعادة في حساب Google Play هذا.';

  @override
  String get proIncluded => 'مشمول';

  @override
  String get proNotIncluded => 'غير مشمول';

  @override
  String get decisionsSectionTitle => 'القرارات الذكية';

  @override
  String get decisionsSectionSubtitle =>
      'أقسام البقالة غير المعروفة، هدف الإضافة السريعة، واقتراحات الوسوم';

  @override
  String get decisionsQuotaByok =>
      'مفتاح Gemini الخاص مفعّل · قرارات ذكية بلا حدود';

  @override
  String decisionsQuotaSummary(int calls, String tokens) {
    return 'القرارات الذكية المتبقية: $calls · ميزانية $tokens رمز';
  }

  @override
  String get decisionsQuotaFreeHint =>
      'القواعد الذكية على الجهاز مجانية · 750 قرارًا مشمولة في النسخة الكاملة';

  @override
  String get decisionsTurnOffTitle => 'إيقاف القرارات الذكية';

  @override
  String get decisionsTurnOffBody =>
      'عند الإيقاف تستمر كل القواميس على الجهاز والتدقيق الإملائي وقواعد التسوق مجانًا.';

  @override
  String get decisionsByokTitle => 'مفتاح Gemini API الخاص (متقدم)';

  @override
  String get decisionsByokInfo =>
      'عند نفاد القرارات تابع بمفتاح Gemini الخاص بك؛ ويبقى على هذا الجهاز.';

  @override
  String get calendarDayLinkRemoved => 'أُزيلت الملاحظة من هذا اليوم';

  @override
  String get calendarLinkTime => 'الوقت';

  @override
  String get calendarLinkAllDay => 'طوال اليوم';

  @override
  String get driveOnboardTitle => 'احتفظ بالمرفقات على كل جهاز';

  @override
  String get driveOnboardBody =>
      'تُنسخ مرفقات الصور وPDF والصوت احتياطيًا إلى مجلد \"Notlar\" في Google Drive، فترى المرفقات نفسها على الهاتف والجهاز اللوحي والويب.';

  @override
  String get driveOnboardConnect => 'ربط Drive';

  @override
  String get driveOnboardLater => 'لاحقًا';

  @override
  String get exportMarkdownZip => 'تصدير Markdown (.zip)';

  @override
  String get exportMarkdownZipInfo =>
      'يصدّر الملاحظات كملفات .md قابلة للنقل منظمة حسب المجلد';

  @override
  String get exportMarkdownZipEmpty => 'لا توجد ملاحظات للتصدير';

  @override
  String exportMarkdownZipDone(int count) {
    return 'صُدّرت $count ملاحظات بصيغة Markdown (.zip)';
  }

  @override
  String get storeMode => 'وضع المتجر';

  @override
  String get storeModeHideChecked => 'إخفاء المنجزة';

  @override
  String get storeModeShowChecked => 'إظهار المنجزة';

  @override
  String storeModeRemaining(int remaining, int total) {
    return 'تبقّى $remaining من $total';
  }

  @override
  String get storeModeAllDone => 'انتهى الكل!';

  @override
  String get storeModeAddHint => 'أضف عنصرًا بسرعة…';

  @override
  String get backupPasswordTitle => 'كلمة مرور النسخة الاحتياطية (اختياري)';

  @override
  String get backupPasswordInfo =>
      'تعيين كلمة مرور يحمي النسخة بتشفير قوي. ولا يمكن استعادة كلمة المرور المنسية.';

  @override
  String get backupPasswordHint => 'كلمة المرور';

  @override
  String get backupPasswordConfirmHint => 'تأكيد كلمة المرور';

  @override
  String get backupPasswordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get backupWithoutPassword => 'نسخ احتياطي دون كلمة مرور';

  @override
  String get backupWithPassword => 'تشفير ونسخ احتياطي';

  @override
  String get backupPasswordProLocked =>
      'النسخة المحمية بكلمة مرور متاحة في خطتي مدى الحياة وPro. النسخ دون كلمة مرور مجاني؛ واستعادة نسخة مشفرة مجانية دائمًا.';

  @override
  String get backupSeeTiers => 'عرض الخطط';

  @override
  String get backupEnterPasswordTitle => 'نسخة احتياطية مشفرة';

  @override
  String get backupEnterPasswordBody =>
      'هذه النسخة محمية بكلمة مرور. أدخل كلمة المرور للاستعادة.';

  @override
  String get backupWrongPassword => 'كلمة مرور خاطئة أو تعذّر فك تشفير النسخة';

  @override
  String get calendarAddActionTitle => 'ماذا يضيف + في التقويم';

  @override
  String get calendarAddActionInfo =>
      'يُضاف إلى اليوم المحدد (أو اليوم)؛ ويمكنك تغييره في النافذة.';

  @override
  String get calendarAddNote => 'ملاحظة';

  @override
  String get calendarAddEvent => 'حدث';

  @override
  String get calendarAddTask => 'مهمة';

  @override
  String get calendarFullPage => 'تقويم بصفحة كاملة';

  @override
  String get calendarNewDayNoteTitle => 'ملاحظة جديدة';

  @override
  String get calendarNewDayNoteOpen => 'كتابة ملاحظة';

  @override
  String calendarSlotAddTitle(String time) {
    return 'إضافة في $time';
  }

  @override
  String get eraserOn => 'الممحاة مفعّلة';

  @override
  String get calendarRelToday => 'اليوم';

  @override
  String get calendarRelTomorrow => 'غدًا';

  @override
  String get calendarRelYesterday => 'أمس';

  @override
  String calendarRelInDays(int count) {
    return 'خلال $count أيام';
  }

  @override
  String calendarRelDaysAgo(int count) {
    return 'قبل $count أيام';
  }

  @override
  String calendarWeekNumber(int count) {
    return 'الأسبوع $count';
  }

  @override
  String calendarDayEvents(int count) {
    return '$count أحداث';
  }

  @override
  String calendarDayTasks(int count) {
    return '$count مهام';
  }

  @override
  String calendarDayReminders(int count) {
    return '$count تذكيرات';
  }

  @override
  String calendarDayNotesCount(int count) {
    return '$count ملاحظات';
  }

  @override
  String get calendarDayFree => 'يوم فارغ';

  @override
  String get webWorkspaceSection => 'مساحة العمل';

  @override
  String get webOrganizeSection => 'التنظيم';

  @override
  String get webViewGrid => 'عرض الشبكة';

  @override
  String get webViewList => 'عرض القائمة';

  @override
  String get webColumnsMenu => 'كثافة الأعمدة';

  @override
  String get webColumnsAuto => 'تلقائي';

  @override
  String webColumnsCount(int count) {
    return '$count أعمدة';
  }

  @override
  String webNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ملاحظات',
      one: 'ملاحظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get webDriveStatusConnected => 'Drive متصل';

  @override
  String webDriveStatusSyncing(int count) {
    return '$count قيد المزامنة';
  }

  @override
  String webDriveStatusAttention(int count) {
    return '$count معلّقة';
  }

  @override
  String get webSyncCloudReady => 'المزامنة السحابية نشطة';

  @override
  String get webCacheTitle => 'ذاكرة مرفقات المتصفح المؤقتة';

  @override
  String webCacheInfo(int count, String size) {
    return '$count ملفات · $size (جاهزة دون اتصال)';
  }

  @override
  String get webCacheEmpty => 'لا توجد مرفقات مخزنة مؤقتًا بعد';

  @override
  String get webCacheClear => 'مسح';

  @override
  String get webCacheCleared => 'مُسحت ذاكرة مرفقات المتصفح المؤقتة';

  @override
  String get quickRowMoreEdit => 'تعديل القائمة السريعة';

  @override
  String get quickRowDay => 'إدراج تاريخ اليوم';

  @override
  String get tableInsert => 'جدول';

  @override
  String get tableInsertInfo => '3 صفوف · عمودان، يمكن تغييرها لاحقًا';

  @override
  String get tableName => 'جدول';

  @override
  String get tableAddRow => 'إضافة صف';

  @override
  String get tableAddRowBelow => 'إضافة صف أسفله';

  @override
  String get tableDeleteRow => 'حذف الصف';

  @override
  String get tableColumnCount => 'الأعمدة';

  @override
  String get tableHeaderRow => 'الصف الأول عنوان';

  @override
  String get tableEqualWidths => 'أعمدة متساوية العرض';

  @override
  String get tableDelete => 'حذف الجدول';

  @override
  String get tableOptions => 'إعدادات الجدول';

  @override
  String get tableColumnsWillDrop => 'سيُحذف النص في العمود الأخير. متابعة؟';

  @override
  String get tableMoveHint => 'اضغط مطولًا للنقل، واسحب الزاوية لتغيير الحجم';

  @override
  String get tableRowCount => 'الصفوف';

  @override
  String get tableRowsWillDrop => 'سيُحذف النص في الصفوف الأخيرة. متابعة؟';

  @override
  String get tableEditSection => 'تعديل';

  @override
  String get tableShareImage => 'صورة';

  @override
  String get tableSharePdf => 'PDF';

  @override
  String get tableShareWord => 'Word';

  @override
  String get tableShareFailed => 'تعذّرت مشاركة الجدول';

  @override
  String get tableAddRowAbove => 'إضافة صف أعلاه';

  @override
  String get tableInsertColumn => 'إضافة عمود يمينًا';

  @override
  String get tableDeleteColumn => 'حذف العمود';

  @override
  String get tableColumnsOneWillDrop => 'سيُحذف النص في العمود المحدد. متابعة؟';

  @override
  String get tableSortAsc => 'ترتيب أ←ي';

  @override
  String get tableSortDesc => 'ترتيب ي←أ';

  @override
  String get tableStripedRows => 'صفوف مخططة';

  @override
  String get tableDataSection => 'البيانات';

  @override
  String get tableCopyMarkdown => 'نسخ Markdown';

  @override
  String get tableCopyCsv => 'نسخ CSV';

  @override
  String get tablePasteData => 'لصق CSV / TSV';

  @override
  String get tablePasteWillReplace =>
      'سيُستبدل محتوى الجدول الحالي بالبيانات الملصقة. متابعة؟';

  @override
  String get tablePasteInvalid => 'لا توجد بيانات جدول صالحة في الحافظة';

  @override
  String get tablePasted => 'لُصقت بيانات الجدول';

  @override
  String get tableSorted => 'رُتّب الجدول';

  @override
  String folderHeaderPinnedCount(int count) {
    return '$count مثبّتة';
  }

  @override
  String get folderNewNote => 'ملاحظة جديدة';

  @override
  String get folderFilterSort => 'التصفية والترتيب';

  @override
  String get folderLivePreview => 'معاينة';

  @override
  String get pinnedSmartActions => 'إجراءات ذكية';

  @override
  String get pinnedSmartOcr => 'استخراج النص';

  @override
  String get pinnedSmartSummarize => 'تلخيص وإضافة';

  @override
  String get pinnedSmartTasks => 'تحويل إلى مهام';

  @override
  String get pinnedSmartAreaAsk => 'تحديد منطقة والسؤال';

  @override
  String get dashboardBackgroundGallery => 'خلفيات مختارة';

  @override
  String get dashboardBackgroundFromDevice => 'من المعرض';

  @override
  String get dashboardBackgroundOpacity => 'الظهور';

  @override
  String get wallpaperAuroraBloom => 'تفتّح الشفق';

  @override
  String get wallpaperCitrusSun => 'شمس الحمضيات';

  @override
  String get wallpaperCoralLagoon => 'بحيرة مرجانية';

  @override
  String get wallpaperBotanicalGarden => 'حديقة نباتية';

  @override
  String get wallpaperLavenderDream => 'حلم الخزامى';

  @override
  String get wallpaperTerracottaStudio => 'استوديو الطين المحروق';

  @override
  String get wallpaperPastelConfetti => 'قصاصات باستيل';

  @override
  String get wallpaperGoldenMeadow => 'مرج ذهبي';

  @override
  String get wallpaperMidnightAurora => 'شفق منتصف الليل';

  @override
  String get wallpaperVelvetCosmos => 'كون مخملي';

  @override
  String get noteThemeAurora => 'شفق';

  @override
  String get noteThemeCitrus => 'حمضيات';

  @override
  String get noteThemeBotanical => 'نباتي';

  @override
  String get noteThemeTerracotta => 'طين محروق';

  @override
  String get noteThemeConfetti => 'قصاصات ملونة';

  @override
  String get noteThemeCobalt => 'كوبالت';

  @override
  String get themeActiveLabel => 'المظهر النشط';

  @override
  String get themeGroupAll => 'الكل';

  @override
  String get itemRangeSelect => 'تحديد نطاق';

  @override
  String get itemInvertSelection => 'عكس التحديد';

  @override
  String get itemMoveUp => 'نقل للأعلى';

  @override
  String get itemMoveDown => 'نقل للأسفل';

  @override
  String get itemDivider => 'فاصل';

  @override
  String get selectionToolbarMore => 'إجراءات أخرى';

  @override
  String get selectionMenuEdit => 'تعديل';

  @override
  String get selectionMenuEditDone => 'تم';

  @override
  String get selectionMenuEditHint =>
      'اضغط للإضافة إلى الصف الرئيسي أو الإزالة منه';

  @override
  String get itemsBatchFormat => 'تنسيق جماعي';

  @override
  String itemsDeletedUndo(int count) {
    return 'حُذفت $count عناصر';
  }

  @override
  String itemsFormattedCount(int count) {
    return 'نُسّقت $count عناصر';
  }

  @override
  String get ecosystemDosyalarimTitle => 'أدِر كل ملف بـ Dosyalarım';

  @override
  String get ecosystemDosyalarimSubtitle =>
      'وقّع ملفات PDF، وعدّل ملفات Word وExcel، وشارك بسهولة مع ملاحظاتك.';

  @override
  String get ecosystemGetApp => 'اكتشف Dosyalarım';

  @override
  String get ecosystemDismiss => 'تجاهل';

  @override
  String shopBudgetCart(String amount) {
    return 'السلة: $amount';
  }

  @override
  String shopBudgetEstimated(String amount) {
    return 'تقدير: $amount';
  }

  @override
  String shopBudgetLimit(String amount) {
    return 'الميزانية: $amount';
  }

  @override
  String get shopBudgetSet => 'تحديد الميزانية';

  @override
  String get shopBudgetHint => 'مثلًا 1500';

  @override
  String get shopAllStores => 'الكل';

  @override
  String shopPriceTitle(String item) {
    return 'السعر والقسم · $item';
  }

  @override
  String get shopUnitPriceLabel => 'السعر';

  @override
  String get shopStoreLabel => 'المتجر';

  @override
  String get shopAisleLabel => 'القسم';

  @override
  String get shopPriceCompareHeader => 'سجل أسعار المتجر';

  @override
  String get shopClearPrice => 'مسح السعر';

  @override
  String get shopRecipesTitle => 'حزم الوجبات والوصفات';

  @override
  String get shopRecipesSearchHint => 'ابحث عن وصفات…';

  @override
  String shopServingsCount(int count) {
    return '$count حصص';
  }

  @override
  String get shopAddToList => 'إضافة إلى القائمة';

  @override
  String get shopNewCustomRecipe => 'حفظ وصفة مخصصة';

  @override
  String get shopRecipeNameHint => 'اسم الوصفة';

  @override
  String get shopIngredientsHint =>
      'المكونات (مفصولة بفواصل: 500 غ لحم، 2 طماطم)';

  @override
  String get shopCustomBadge => 'مخصص';

  @override
  String shopAisleOrderTitle(String store) {
    return 'ترتيب الأقسام · $store';
  }

  @override
  String get shopResetOrder => 'إعادة الافتراضي';

  @override
  String get shopReceiptTitle => 'تحديث الأسعار من الإيصال';

  @override
  String get shopReceiptCamera => 'التقاط صورة الإيصال';

  @override
  String get shopReceiptGallery => 'اختيار الإيصال من المعرض';

  @override
  String shopReceiptMatched(int count) {
    return 'طوبقت $count عناصر';
  }

  @override
  String get shopReceiptNoMatches =>
      'لم يُعثر على عناصر قائمة مطابقة في الإيصال.';

  @override
  String get shopReceiptApply => 'تطبيق الأسعار';

  @override
  String get shopDueHeader => 'على وشك النفاد';

  @override
  String shopDueEveryDays(int days) {
    return '$daysي';
  }

  @override
  String get shopStatusUnavailable => 'نفد من المخزون';

  @override
  String get shopStatusUnavailableBadge => 'غير متوفر';

  @override
  String get shopBarcodeTitle => 'مسح الباركود';

  @override
  String shopBarcodeUnknownPrompt(String ean) {
    return 'باركود جديد ($ean)';
  }

  @override
  String get shopBarcodeNameHint => 'اسم المنتج (مثل: قهوة 100 غ)';

  @override
  String get shopKeepScreenOn => 'إبقاء الشاشة مضاءة';

  @override
  String get shopAtStoreButton => 'أنا في المتجر';

  @override
  String shopAtStoreMessage(String name) {
    return '🛒 $name في المتجر الآن — أضف ما ينقص!';
  }

  @override
  String get shopAtStoreSent => 'أُبلغ المتعاونون';

  @override
  String get shopScanReceiptTooltip => 'مسح الإيصال (OCR)';

  @override
  String get shopRecipesTooltip => 'حزم الوصفات';

  @override
  String get shopAisleOrderTooltip => 'تخصيص ترتيب الأقسام';

  @override
  String shopTakenBy(String name) {
    return 'أخذه $name';
  }

  @override
  String shopEstimatedPrefix(String amount) {
    return '~$amount';
  }

  @override
  String shopActualPrice(String amount) {
    return '$amount';
  }

  @override
  String shopOpenStoreModeCount(int remaining) {
    return 'وضع المتجر ($remaining)';
  }

  @override
  String get shopOpenStoreMode => 'وضع المتجر';

  @override
  String get shopDictationTooltip => 'إضافة بالصوت';

  @override
  String get spellManualLearn => 'تعلّم هذا التصحيح';

  @override
  String get spellManualLearnHint =>
      'يُقترح ويُصحَّح تلقائيًا في المرة القادمة.';

  @override
  String get spellNoSuggestions => 'لا توجد اقتراحات';

  @override
  String get spellHintBadge => 'تلميح';

  @override
  String get spellErrorBadge => 'إملاء';

  @override
  String get wallpaperSakuraBreeze => 'نسيم الساكورا';

  @override
  String get wallpaperOceanMist => 'ضباب المحيط';

  @override
  String get wallpaperAutumnMaple => 'أوراق الخريف';

  @override
  String get wallpaperSageLinen => 'كتان مريمية';

  @override
  String get wallpaperPeachHorizon => 'أفق خوخي';

  @override
  String get wallpaperNordicPaper => 'ورق شمالي';

  @override
  String get wallpaperStarryPine => 'صنوبر مرصّع بالنجوم';

  @override
  String get wallpaperObsidianGold => 'سبج وذهب';

  @override
  String get uiProfileSectionTitle => 'أنماط واجهة جاهزة';

  @override
  String get uiProfileSimple => 'بسيط';

  @override
  String get uiProfileSimpleDesc => 'تخطيط نظيف للملاحظات السريعة والتسوق';

  @override
  String get uiProfileStandard => 'قياسي';

  @override
  String get uiProfileStandardDesc => 'كل الأدوات بتوازن';

  @override
  String get uiProfileTabletPen => 'جهاز لوحي وقلم';

  @override
  String get uiProfileTabletPenDesc =>
      'عرض مقسّم، وأدوات القلم وPDF في المقدمة';

  @override
  String uiProfileApplied(String name) {
    return 'طُبّق نمط $name';
  }

  @override
  String get lockNeedSecretOnce =>
      'أدخل كلمة مرور القفل أو النمط مرة واحدة لتفعيل الفتح بالبصمة على هذا الجهاز.';

  @override
  String get lockForgotConfirmTitle => 'إعادة تعيين قفل الملاحظات؟';

  @override
  String get lockForgotConfirmBody =>
      'لا يمكن فك تشفير الملاحظات المقفلة بسرّك الحالي مجددًا دون ذلك السر. هل تريد إعادة تعيين القفل على أي حال؟';

  @override
  String get lockForgotConfirmAction => 'إعادة تعيين';

  @override
  String get starterShoppingTitle => '🛒 قائمة بقالة نموذجية';

  @override
  String get starterWelcomeTitle => '⚡ بداية سريعة';
}
