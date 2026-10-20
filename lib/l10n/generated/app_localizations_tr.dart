// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'Notlar';

  @override
  String get loginTagline => 'Notların her cihazda seninle';

  @override
  String get signInWithGoogle => 'Google ile giriş yap';

  @override
  String loginError(String error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String get searchHint => 'Notlarda ara...';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterText => 'Metin';

  @override
  String get filterChecklist => 'Liste';

  @override
  String get filterOrdered => 'Sıralı';

  @override
  String get filterPinned => 'Sabitlenmiş';

  @override
  String get star => 'Yıldızla';

  @override
  String get unstar => 'Yıldızı kaldır';

  @override
  String get sectionOthers => 'Diğerleri';

  @override
  String get emptyNotes => 'Henüz not yok';

  @override
  String get emptyNotesHint => 'İlk notunu eklemek için + düğmesine dokun';

  @override
  String get emptySearch => 'Sonuç bulunamadı';

  @override
  String get newTextNote => 'Metin notu';

  @override
  String get newChecklist => 'Liste';

  @override
  String get newOrderedList => 'Sıralı liste';

  @override
  String get noteDeleted => 'Not silindi';

  @override
  String notesDeletedCount(int count) {
    return '$count not silindi';
  }

  @override
  String selectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get deleteSelected => 'Seçilenleri sil';

  @override
  String get undo => 'Geri Al';

  @override
  String get redo => 'Yinele';

  @override
  String get titleHint => 'Başlık';

  @override
  String get bodyHint => 'Not...';

  @override
  String get newItemHint => 'Yeni öğe';

  @override
  String moreItemsCount(int count) {
    return '+$count öğe daha';
  }

  @override
  String get addAttachment => 'Ekle';

  @override
  String get addImage => 'Görsel ekle';

  @override
  String get addPdf => 'PDF ekle';

  @override
  String get addSlide => 'Slayt ekle';

  @override
  String get noNoteSelected => 'Soldan bir not seç';

  @override
  String attachmentFailed(String error) {
    return 'Ek eklenemedi: $error';
  }

  @override
  String get attachmentCopying => 'Kopyalanıyor...';

  @override
  String get attachmentUploading => 'Yükleniyor...';

  @override
  String get attachmentUploadFailed =>
      'Yüklenemedi — yeniden denemek için dokun';

  @override
  String get attachmentNotSynced => 'Dosya bu cihaza henüz senkronlanmadı';

  @override
  String attachmentTooLarge(int limit) {
    return 'Dosya çok büyük (en fazla $limit MB)';
  }

  @override
  String storageFull(String limit) {
    return 'Depolama doldu ($limit). Yer açmak için eski ekleri sil.';
  }

  @override
  String get storageUsage => 'Depolama';

  @override
  String storageUsageValue(String used, String limit) {
    return '$used / $limit kullanıldı';
  }

  @override
  String get removeAttachment => 'Eki kaldır';

  @override
  String get pin => 'Sabitle';

  @override
  String get unpin => 'Sabitlemeyi kaldır';

  @override
  String get delete => 'Sil';

  @override
  String get color => 'Renk';

  @override
  String get aiTitle => 'Yapay Zeka';

  @override
  String get aiSummarize => 'Notu özetle';

  @override
  String get aiAnalyze => 'Analiz et';

  @override
  String get aiSectionNote => 'Bu not';

  @override
  String get aiSectionAttachments => 'Ekler';

  @override
  String get summarize => 'Özetle';

  @override
  String get summaryDetailTitle => 'Özet türü';

  @override
  String get summaryShort => 'Kısa özet';

  @override
  String get summaryShortInfo => 'Birkaç cümlelik genel bakış ve ana maddeler';

  @override
  String get summaryDetailed => 'Detaylı özet';

  @override
  String get summaryDetailedInfo =>
      'Kaynağa bakmayı gereksiz kılan kapsamlı özet';

  @override
  String get listen => 'Sesli dinle';

  @override
  String get ask => 'Soru sor';

  @override
  String get extractText => 'Metni çıkar';

  @override
  String get transcribe => 'Yazıya dök';

  @override
  String get listenToNote => 'Sesli oku';

  @override
  String get aiNoApiKey => 'Önce Ayarlar\'dan Gemini API anahtarını gir';

  @override
  String aiError(String error) {
    return 'Yapay zeka isteği başarısız: $error';
  }

  @override
  String get aiSummaryTitle => 'AI Özeti';

  @override
  String get aiThinking => 'Düşünüyor...';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get settingsSearchHint => 'Ayar ara — “brifing”, “mikrofon”';

  @override
  String settingsSearchEmpty(String query) {
    return '«$query» için ayar yok';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get settingsAppearance => 'Görünüm';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get settingsAi => 'Yapay Zeka';

  @override
  String get geminiApiKeyInfo =>
      'Anahtar girmek isteğe bağlıdır: girmezsen AI istekleri uygulamanın dahili altyapısından yapılır (günlük ücretsiz hak, Premium ile daha yüksek günlük hak). Kendi anahtarınla sınırsız kullanım için aistudio.google.com adresinden ücretsiz anahtar alabilirsin; anahtar yalnızca bu cihazda güvenli depoda saklanır.';

  @override
  String aiBuiltInPremium(int count) {
    return 'Dahili AI: Premium — bugün kalan puan $count';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Dahili AI: bugün kalan ücretsiz puan $count';
  }

  @override
  String get aiBuiltInByok => 'Kendi anahtarın kullanılıyor — sınırsız';

  @override
  String get aiReport => 'Yanıtı bildir';

  @override
  String get aiReportThanks => 'Bildirimin alındı, teşekkürler';

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get lockNote => 'Kilitle';

  @override
  String get unlockNote => 'Kilidi kaldır';

  @override
  String get lockedNote => 'Kilitli not';

  @override
  String get unlockAuthReason => 'Kilitli notu açmak için kimliğini doğrula';

  @override
  String get exportBackup => 'Yedeği dışa aktar (JSON)';

  @override
  String get expandListItems => 'Liste satırlarını tam göster';

  @override
  String get expandListItemsInfo =>
      'Uzun liste/işaret öğeleri birkaç satıra sarılıp tamamen görünür. Kapalıyken satır tek satırda kalır, dokununca açılır.';

  @override
  String get quickCaptureRowSetting => 'Hızlı not satırı';

  @override
  String get quickCaptureRowInfo =>
      'Ana ekranın üstünde tek satırlık \"Yeni not...\" alanı görünür. Kapalıyken yeni not \"+\" düğmesinden açılır.';

  @override
  String get emptyTrash => 'Çöpü boşalt';

  @override
  String emptyTrashConfirm(int count) {
    return '$count not kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misin?';
  }

  @override
  String get trashEmptied => 'Çöp kutusu boşaltıldı';

  @override
  String get validateAndSave => 'Doğrula ve Kaydet';

  @override
  String get clear => 'Temizle';

  @override
  String get aiDiagnostics => 'AI tanılama';

  @override
  String get aiDiagnosticsEmpty => 'Kayıtlı hata yok';

  @override
  String aiDiagnosticsCount(int count) {
    return 'Son $count hata kaydı';
  }

  @override
  String get apiKeyValid => 'API anahtarı doğrulandı ve kaydedildi';

  @override
  String get apiKeyInvalid => 'API anahtarı geçersiz';

  @override
  String get apiKeySavedBadge => 'Kayıtlı';

  @override
  String get removeApiKey => 'Anahtarı sil';

  @override
  String get refresh => 'Yenile';

  @override
  String get account => 'Hesap';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get signOutConfirm => 'Çıkış yapmak istediğine emin misin?';

  @override
  String get signOutAnonymousWarning =>
      'Yerel hesaptasın: çıkış yaparsan bu hesaba ve TÜM notlarına bir daha ERİŞİLEMEZ — yedeğin yoksa geri getirilemezler. Notlarını korumak için önce Google hesabı bağla. Yine de çıkış yapılsın mı?';

  @override
  String get deleteAccount => 'Hesabımı ve verilerimi sil';

  @override
  String get deleteAccountWarning =>
      'Bu işlem geri alınamaz: tüm notların, eklerin ve hesabın kalıcı olarak silinir. Devam etmek istediğine emin misin?';

  @override
  String get deleteAccountConfirm => 'Kalıcı olarak sil';

  @override
  String get licensesTitle => 'Açık kaynak lisansları';

  @override
  String get generating => 'Üretiliyor...';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'İptal';

  @override
  String get close => 'Kapat';

  @override
  String get ok => 'Tamam';

  @override
  String get syncPending => 'Senkron bekleniyor';

  @override
  String get synced => 'Senkronize';

  @override
  String genericError(String error) {
    return 'Bir şeyler ters gitti: $error';
  }

  @override
  String get addTag => 'Etiket';

  @override
  String get tagHint => 'ör. iş, ev, okul';

  @override
  String get addReminder => 'Hatırlat';

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
  String get share => 'Paylaş';

  @override
  String get archive => 'Arşivle';

  @override
  String get unarchive => 'Arşivden çıkar';

  @override
  String get archiveTitle => 'Arşiv';

  @override
  String get archiveEmpty => 'Arşivde not yok';

  @override
  String get trashTitle => 'Çöp Kutusu';

  @override
  String get trashEmpty => 'Çöp kutusu boş';

  @override
  String get trashInfo =>
      'Silinen notlar burada durur; geri alabilir veya kalıcı olarak silebilirsin.';

  @override
  String get restore => 'Geri al';

  @override
  String get deleteForever => 'Kalıcı olarak sil';

  @override
  String get deleteForeverConfirm =>
      'Bu not kalıcı olarak silinecek. Emin misin?';

  @override
  String assistantDeleteConfirm(String title) {
    return 'Asistan \"$title\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?';
  }

  @override
  String get recordAudio => 'Ses kaydı';

  @override
  String get recording => 'Kaydediliyor...';

  @override
  String get stopAndSave => 'Bitir ve ekle';

  @override
  String get micPermissionDenied => 'Mikrofon izni verilmedi';

  @override
  String get addDrawing => 'Çizim ekle';

  @override
  String get drawingTitle => 'Çizim';

  @override
  String get addToNote => 'Nota ekle';

  @override
  String get chatTitle => 'Not Asistanı';

  @override
  String get chatHint =>
      'Notların hakkında soru sor: \"geçen hafta yazdığım tarif neydi?\", \"alışveriş listemde ne eksik?\"';

  @override
  String get chatInputHint => 'Bir soru yaz...';

  @override
  String get fontSize => 'Yazı boyutu';

  @override
  String get fontSizePreview => 'Notların bu boyutta görünecek';

  @override
  String get darkSchedule => 'Koyu tema zamanlaması';

  @override
  String get darkScheduleInfo =>
      'Belirlediğin saatler arasında koyu temaya geçilir';

  @override
  String get aiTranslate => 'Çevir';

  @override
  String get voiceCommand => 'Sesli komut';

  @override
  String get semanticSearchToggle => 'AI ile anlamsal arama';

  @override
  String get semanticSearchHint => 'Anlamıyla ara: \"araba masrafları\"...';

  @override
  String get briefingTitle => 'Günlük Brifing';

  @override
  String get briefingLoading => 'Brifing hazırlanıyor...';

  @override
  String get briefingEmpty => 'Bugün için içerik yok';

  @override
  String get briefingSetting => 'Günlük brifing bildirimi';

  @override
  String get briefingSettingInfo =>
      'Her sabah seçtiğin saatte günün özeti için bildirim al';

  @override
  String get autoTagSetting => 'Otomatik etiketle';

  @override
  String get autoTagSettingInfo =>
      'Not kapanırken etiketi yoksa yapay zeka uygun etiketi kendisi ekler';

  @override
  String get suggestTags => 'Etiket öner';

  @override
  String get aiFixNote => 'Notu düzelt';

  @override
  String get fixLevelTitle => 'Ne kadar düzeltilsin?';

  @override
  String get fixSimple => 'Basit';

  @override
  String get fixSimpleInfo => 'Yalnız imla ve yazım hataları';

  @override
  String get fixBalanced => 'Dengeli';

  @override
  String get fixBalancedInfo => 'Cümle yapısı da düzeltilir, daha düzgün yazı';

  @override
  String get fixDetailed => 'Detaylı';

  @override
  String get fixDetailedInfo => 'Yazıyı baştan aşağı yeniden düzenler';

  @override
  String get existingTagsLabel => 'Önceki etiketler';

  @override
  String get aiSkipCheckedSetting => 'İşaretlileri AI düzenlemesi dışında tut';

  @override
  String get aiSkipCheckedInfo =>
      'Checklist notunu AI ile düzeltir/çevirirken tamamlanmış (işaretli) maddeler değiştirilmeden korunur; yalnız işaretsiz maddeler düzenlenir.';

  @override
  String get noteUpdatedUndo => 'Not güncellendi';

  @override
  String get aiImprove => 'Notu geliştir';

  @override
  String get improveFormal => 'Daha resmî yap';

  @override
  String get improveShorten => 'Kısalt';

  @override
  String get improveBullets => 'Madde listesine çevir';

  @override
  String get improveNumbered => 'Sıralı (numaralı) listeye çevir';

  @override
  String get replaceNote => 'Notu değiştir';

  @override
  String get openAsNewNote => 'Yeni not olarak';

  @override
  String get pdfChatHint =>
      'Bu PDF hakkında soru sor: \"özetle\", \"cezai şart var mı?\", \"son teslim tarihi ne?\"';

  @override
  String get pdfChatInputHint => 'PDF hakkında bir soru yaz...';

  @override
  String get voiceFinish => 'Bitir';

  @override
  String get voiceProcessing => 'Söyledikleriniz uygulanıyor...';

  @override
  String get voiceNothingHeard => 'Kayıtta konuşma algılanamadı';

  @override
  String get voiceNoteSaved => 'Sesli notun kaydedildi';

  @override
  String get openNote => 'Notu aç';

  @override
  String get remindersTitle => 'Hatırlatıcılar';

  @override
  String get remindersEmpty => 'Hatırlatıcı yok';

  @override
  String get remindersEmptyHint =>
      'Bir nota hatırlatıcı ekle veya + düğmesiyle yeni bir hatırlatıcılı not oluştur';

  @override
  String get remindersUpcoming => 'Yaklaşan';

  @override
  String get remindersPast => 'Geçmiş';

  @override
  String get reminderInPast =>
      'Seçilen zaman geçmişte — gelecekte bir zaman seç.';

  @override
  String get newReminder => 'Yeni hatırlatıcı';

  @override
  String get remindersUntitled => 'Adsız not';

  @override
  String get remindersEdit => 'Zamanı değiştir';

  @override
  String get remindersRemove => 'Hatırlatıcıyı kaldır';

  @override
  String get aiModelChat => 'Özet, başlık, etiket ve sohbet';

  @override
  String get aiModelDocument => 'Belge sohbeti ve PDF özeti';

  @override
  String get aiModelTranslate => 'Çeviri';

  @override
  String get aiModelVoice => 'Sesli not asistanı';

  @override
  String get aiModelAuto => 'Otomatik (önerilen)';

  @override
  String get aiModelsInfo =>
      'Her iş için ayrı model seçebilirsin: kısa metin işleri hızlı modelle yeter, uzun belge işi yetenekli model ister. Seçtiğin model kota doldurur veya kaldırılırsa sıradaki otomatik denenir.';

  @override
  String get clearNote => 'Temizle';

  @override
  String get clearNoteConfirm =>
      'Notun içeriği (metin ve liste öğeleri) silinecek. Emin misin?';

  @override
  String get themePaper => 'Kağıt';

  @override
  String get calculatorTitle => 'Hesap Makinesi';

  @override
  String get calcExpressionHint => 'ör. 12,5×3+40';

  @override
  String get calcInvalid => 'Geçersiz ifade';

  @override
  String get liveDictation => 'Sesli yazdır';

  @override
  String get voiceCaptureAi => 'Sesli yakala (yapay zekâ)';

  @override
  String get dictationListening => 'Dinleniyor... konuştukça metin yazılır';

  @override
  String get dictationHoldHint =>
      'Mikrofonu basılı tutup konuşun, bırakınca yazılır';

  @override
  String itemsSelected(int count) {
    return '$count madde seçildi';
  }

  @override
  String get noteChatHint => 'Bu not hakkında bir şey sor';

  @override
  String get noteChatIntro =>
      'Notun içeriği ve ekleri (PDF/görsel) okunur, sorunu ona göre yanıtlar.';

  @override
  String get dictationProcessing => 'Yazıya dökülüyor...';

  @override
  String get aiDailyManualInfo =>
      'Ücretsiz planda bu içerik günlük hakkını boşa harcamamak için otomatik oluşturulmaz. Günde bir kez, aşağıdaki düğmeyle oluşturabilirsin.';

  @override
  String get aiGenerate => 'Oluştur';

  @override
  String get aiGeneratedTodayInfo =>
      'Bu içerik bugün oluşturuldu. Ücretsiz planda günde bir kez yenilenir; yarın tekrar oluşturabilirsin.';

  @override
  String get voiceAssistantTitle => 'Sesli Not Asistanı';

  @override
  String get voiceListening => 'Dinliyorum...';

  @override
  String get voiceTapHint => 'Dokun ve konuş; bitirmek için tekrar dokun';

  @override
  String get voiceModeSetting => 'Kullanım şekli';

  @override
  String get voiceModeHold => 'Basılı tut';

  @override
  String get voiceModeTap => 'Bas-başlat / bas-bitir';

  @override
  String get voiceModeInfo =>
      'Basılı tut: düğmeye bastığın sürece dinler, bırakınca notu oluşturur. Bas-başlat: bir dokunuşla kayıt başlar, ikinci dokunuşla biter.';

  @override
  String get voiceCaptureReady => 'Konuşma hazır';

  @override
  String get voiceCaptureEditHint => 'Düzeltmek için metne dokun';

  @override
  String voiceCapturePunctuation(String language) {
    return '$language · noktalama otomatik';
  }

  @override
  String get voiceCaptureAddToNote => 'Nota ekle';

  @override
  String get voiceCaptureCreateNote => 'Yeni not oluştur';

  @override
  String get voiceCaptureAiNote => 'AI not';

  @override
  String get voiceCapturePlainNote => 'Düz not';

  @override
  String get voiceCloseTitle => 'Konuştukların duruyor';

  @override
  String get voiceCloseKeepTalking => 'Konuşmaya devam et';

  @override
  String get voiceCaptureRestart => 'Baştan dinle';

  @override
  String get voiceChipSummarizeAdd => 'Özetleyerek ekle';

  @override
  String get voiceChipSummarizeSave => 'Özetleyerek kaydet';

  @override
  String get voiceChipToItems => 'Maddelere böl';

  @override
  String get voiceChipAsList => 'Liste notu yap';

  @override
  String get voiceChipFix => 'Düzelt';

  @override
  String get editorToolList => 'Liste';

  @override
  String get permissionsTitle => 'İzinler';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo => 'Sesli not ve dikte için gerekli';

  @override
  String get permNotifications => 'Bildirimler';

  @override
  String get permNotificationsInfo =>
      'Hatırlatıcılar ve günlük brifing için gerekli';

  @override
  String get permBattery => 'Pil optimizasyonu';

  @override
  String get permBatteryInfo =>
      'Hatırlatıcıların gecikmeden gelmesi için uygulamayı pil kısıtlamasından muaf tut';

  @override
  String videoTooBigForAi(int mb) {
    return 'Video AI\'ya göndermek için çok büyük ($mb MB). Daha kısa çek.';
  }

  @override
  String get permCamera => 'Kamera';

  @override
  String get permCameraInfo => 'Görüntülü not ve fotoğraf çekimi için gerekli';

  @override
  String get permOnboardTitle => 'Başlamadan önce';

  @override
  String get permOnboardInfo =>
      'Notlar bu izinleri yalnızca sen ilgili özelliği kullanınca ister. Şimdi vermek istersen aşağıdan açabilirsin; sonra Ayarlar > İzinler\'den de değiştirebilirsin.';

  @override
  String get permOnboardGrantAll => 'İzinleri ver';

  @override
  String get permOnboardSkip => 'Şimdi değil';

  @override
  String get newVideoNote => 'Video çek';

  @override
  String get videoLocalOnly =>
      'Bu video yalnızca bu cihazda saklanır (buluta yüklenmez)';

  @override
  String get videoToNote => 'Videodan not çıkar';

  @override
  String get videoToNoteRunning => 'Video inceleniyor…';

  @override
  String get permGranted => 'İzin verildi';

  @override
  String get permGrant => 'İzin ver';

  @override
  String get permOpenSettings => 'Ayarları aç';

  @override
  String get newHandwriting => 'El yazısı';

  @override
  String get newVoiceCapture => 'Sesli not';

  @override
  String get suggestTitle => 'Başlık öner';

  @override
  String get noteMetaMenu => 'Etiket · Başlık · Alarm';

  @override
  String get folder => 'Klasör';

  @override
  String get noFolder => 'Klasörsüz';

  @override
  String get newFolder => 'Yeni klasör';

  @override
  String get editFolder => 'Klasörü düzenle';

  @override
  String get deleteFolder => 'Klasörü sil';

  @override
  String deleteFolderConfirm(String name) {
    return '\"$name\" klasörü silinecek. İçindeki notlar silinmez, klasörsüz kalır.';
  }

  @override
  String get folderNameHint => 'Klasör adı';

  @override
  String get folderIcon => 'Simge';

  @override
  String get select => 'Seç';

  @override
  String get noteArchived => 'Not arşivlendi';

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
    return 'İşaretlileri sil ($count)';
  }

  @override
  String get removeItem => 'Öğeyi sil';

  @override
  String get copyWholeNote => 'Tüm notu kopyala';

  @override
  String get allCopied => 'Tüm not panoya kopyalandı';

  @override
  String get speechPlay => 'Sesli oku';

  @override
  String get speechPause => 'Duraklat';

  @override
  String get speechResume => 'Devam et';

  @override
  String get speechStop => 'Durdur';

  @override
  String get speechRate => 'Okuma hizi';

  @override
  String get speechNoVoices => 'Bu cihazda yuklu ses bulunamadi';

  @override
  String get speechVoiceAutoInfo =>
      'Diğer diller otomatik olarak erkek sesiyle okunur';

  @override
  String get listening => 'Dinleniyor...';

  @override
  String get listenPlay => 'Sesli dinle';

  @override
  String get listenReadingPdf => 'Belge okunuyor...';

  @override
  String get listenConvertWithAi => 'Yapay zekâ ile dönüştür';

  @override
  String get listenMakePodcast => 'Tam podcast';

  @override
  String get listenMakePodcastSummary => 'Özet podcast';

  @override
  String get listenOriginalText => 'Özgün metin';

  @override
  String get listenPodcastReady => 'Podcast anlatımı hazır';

  @override
  String get listenPodcastCached => 'Daha önce üretilmişti — token harcanmadı';

  @override
  String get listenRegenerate => 'Yeniden üret';

  @override
  String get listenNoText =>
      'Bu belgeden okunabilir metin çıkmadı. Taranmış bir PDF ise metin katmanı yoktur, sunumsa yalnızca görsel içeriyor olabilir.';

  @override
  String get readDocument => 'Belge oku (Word, PDF, sunum)';

  @override
  String get readDocUnsupported => 'Bu dosya türü okunamıyor.';

  @override
  String get exportPdf => 'PDF olarak dışa aktar';

  @override
  String get pdfTitleField => 'Başlık';

  @override
  String get pdfContentField => 'İçerik';

  @override
  String get pdfMarkupHint =>
      'Satır başındaki işaretler biçime dönüşür: [x] ve [ ] onay kutusu, 1. numaralı liste, - madde imi.';

  @override
  String get pdfIncludeDate => 'Tarihi ekle';

  @override
  String get exportIncludeImages => 'Görselleri ekle';

  @override
  String get exportWord => 'Word olarak paylaş (.docx)';

  @override
  String get pdfPreview => 'Önizle';

  @override
  String get largeAttachmentTitle => 'Büyük dosya';

  @override
  String largeAttachmentBody(String size) {
    return 'Bu dosya $size MB. PDF\'ler sıkıştırılamıyor; olduğu gibi buluta yüklenecek ve depolama alanından düşecek. Devam edilsin mi?';
  }

  @override
  String get speechRateForeign => 'Yabancı dil hızı';

  @override
  String notesArchivedCount(int count) {
    return '$count not arşivlendi';
  }

  @override
  String get backgroundColor => 'Renk';

  @override
  String get backgroundColorInfo => 'Notun rengi; istersen kenarına da vurgu';

  @override
  String get frameColor => 'Çerçeve';

  @override
  String get sortBy => 'Sıralama';

  @override
  String get reorderNotes => 'Notları sırala';

  @override
  String get reorderModeActive => 'Kartları sürükleyerek sırala';

  @override
  String get reorderDone => 'Bitti';

  @override
  String get sortManual => 'Elle (sürükleme sırası)';

  @override
  String get sortUpdated => 'Son güncellenen';

  @override
  String get sortCreated => 'Oluşturulma tarihi';

  @override
  String get sortTitle => 'Başlığa göre (A-Z)';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get languageSystem => 'Sistem dili';

  @override
  String get settingsSpeech => 'Sesli okuma';

  @override
  String get aiAdvanced => 'Gelişmiş: model ve API anahtarı';

  @override
  String get aiAdvancedInfo =>
      'Model seçimi ve kendi Gemini anahtarın. Çoğu kullanıcı için gerekli değildir.';

  @override
  String get openBriefing => 'Brifingi aç';

  @override
  String get syncTitle => 'Senkronizasyon';

  @override
  String get syncLimitTitle => 'Otomatik yükleme sınırı';

  @override
  String get syncLimitInfo =>
      'Bu boyuttan büyük ekler cihazda kalır, buluta yüklenmez. Not metni her zaman senkronlanır.';

  @override
  String get syncLimitUnlimited => 'Sınırsız';

  @override
  String get importBackup => 'Yedekten geri yükle (JSON)';

  @override
  String importBackupDone(int count) {
    return '$count not geri yüklendi';
  }

  @override
  String get importBackupInvalid => 'Geçersiz yedek dosyası';

  @override
  String get aiHubTitle => 'Yapay Zeka';

  @override
  String get aiSummarizeInfo => 'Kısa bir özet çıkarır';

  @override
  String get aiAnalyzeInfo => 'Ana noktaları ve yapılacakları listeler';

  @override
  String get aiImproveInfo => 'Üslubu değiştirir: resmî, kısa ya da liste';

  @override
  String get aiTranslateInfo => 'Notu seçtiğin dile çevirir';

  @override
  String get aiFixNoteInfo => 'Yazım ve noktalamayı düzeltir';

  @override
  String get moveToFolder => 'Klasöre taşı';

  @override
  String get assistantGenericError => 'Bir sorun oluştu, tekrar dener misin?';

  @override
  String get quickAddTooltip => 'Yeni not — tip seç';

  @override
  String get autoTitleSetting => 'Kapatırken başlık öner';

  @override
  String get autoTitleSettingInfo =>
      'Editörden çıkarken başlıksız kalan nota içeriğinden otomatik kısa bir başlık yazılır.';

  @override
  String get hubBriefingInfo => 'Güne bakış: hatırlatıcılar ve son notlar';

  @override
  String get hubReadInfo => 'PDF/Word belgesini sesli dinle';

  @override
  String get annotate => 'Üzerine yaz';

  @override
  String get annotateDone => 'Yazmayı bitir';

  @override
  String get newPdfNote => 'PDF\'ten not';

  @override
  String get imageNotePreparing => 'Görseller belgeye diziliyor…';

  @override
  String get newImageNote => 'Görselden not';

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
  String get newSlidesNote => 'Sunumdan not';

  @override
  String get slidesNoDocument => 'Bu notta henüz sunum yok';

  @override
  String get slidesChooseDocument => 'Sunum seç';

  @override
  String get pdfEditPages => 'Sayfaları düzenle';

  @override
  String get pdfDeletePages => 'Seçili sayfaları sil';

  @override
  String get pdfAddBlankPage => 'Boş sayfa ekle';

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
  String get crop => 'Kırp';

  @override
  String get cropApply => 'Kırpmayı uygula';

  @override
  String get cropReset => 'Seçimi sıfırla';

  @override
  String get cropHint =>
      'Köşeleri sürükleyerek alanı seç. Kırpma geri alınamaz.';

  @override
  String get cropFailed => 'Görsel kırpılamadı.';

  @override
  String get penBallpoint => 'Tükenmez kalem';

  @override
  String get penMarker => 'Keçeli kalem';

  @override
  String get penHighlighter => 'Fosforlu kalem';

  @override
  String get eraser => 'Silgi';

  @override
  String get inkArrow => 'Ok';

  @override
  String get clearInk => 'Çizimleri temizle';

  @override
  String get inkTwoFingerHint =>
      'Tek parmak çizer · iki parmakla kaydır ve yakınlaştır';

  @override
  String get slideOpenFailed => 'Sunum açılamadı';

  @override
  String get newPhotoNote => 'Fotoğraf çek';

  @override
  String get newScanNote => 'Belge tara';

  @override
  String get scanDocument => 'Belge tara';

  @override
  String get scanDocumentSubtitle =>
      'Kenarları bulur, düzleştirir ve nota ekler';

  @override
  String get scanUnsupported => 'Belge tarama bu cihazda desteklenmiyor';

  @override
  String scanFailed(String error) {
    return 'Belge taranamadı: $error';
  }

  @override
  String scanPagesAdded(int count) {
    return '$count sayfa nota eklendi';
  }

  @override
  String get scanTextTitle => 'Yazılar da tanınsın mı?';

  @override
  String get scanTextBody =>
      'Sayfalardaki yazı tanınıp notun içine yazılır. Görüntü aynen kalır. Sayfa başına birkaç saniye sürer.';

  @override
  String get scanImageOnly => 'Sadece görüntü';

  @override
  String get scanRecognizeText => 'Yazıları da tanı';

  @override
  String get scanRecognizing => 'Yazılar tanınıyor…';

  @override
  String get takePhoto => 'Fotoğraf çek';

  @override
  String get qrScanTitle => 'QR kod tara';

  @override
  String get qrScanSubtitle => 'Kameradan ya da fotoğraftan oku';

  @override
  String get qrScanHint => 'Kodu çerçevenin içine getir';

  @override
  String get qrFromPhoto => 'Fotoğraftan oku';

  @override
  String get qrNotFound => 'Bu görselde kod bulunamadı';

  @override
  String get qrLinkFound => 'Bu kod bir bağlantı';

  @override
  String get qrOpenLink => 'Linke git';

  @override
  String get qrSaveToNote => 'Nota kaydet';

  @override
  String get openLink => 'Bağlantıyı aç';

  @override
  String get linkOpenFailed => 'Bağlantı açılamadı';

  @override
  String qrScanFailed(String error) {
    return 'Kod okunamadı: $error';
  }

  @override
  String get qrTorch => 'Işık';

  @override
  String get hideAttachments => 'Gizle';

  @override
  String get showAttachments => 'Göster';

  @override
  String get selectAllItems => 'Tümünü seç';

  @override
  String get hiddenFolder => 'Gizli klasör';

  @override
  String get hiddenFolderInfo =>
      'Gizli klasör ve içindeki notlar ana ekranda görünmez. Göstermek için ⋮ menüsünden \"Gizli klasörler\" seçilir ve kimlik doğrulanır.';

  @override
  String get hiddenFoldersMenu => 'Gizli klasörler';

  @override
  String get hiddenFolderAuthReason =>
      'Gizli klasörleri göstermek için kimliğini doğrula';

  @override
  String get hiddenFoldersShown => 'Gizli klasörler gösteriliyor';

  @override
  String get hiddenFoldersHiddenAgain => 'Gizli klasörler yeniden saklandı';

  @override
  String get makeFolderHidden => 'Gizle';

  @override
  String get makeFolderVisible => 'Gizlemeyi kaldır';

  @override
  String gridColumnsCount(int count) {
    return '$count sütun';
  }

  @override
  String get addImageOnPageSubtitle => 'Sayfaya yerleşir, yazı etrafından akar';

  @override
  String get addImageAsFile => 'Görseli ek olarak yükle';

  @override
  String get addImageAsFileSubtitle =>
      'Sayfaya girmez, alttaki ek şeridinde durur';

  @override
  String get moveImageToAttachments => 'Ek olarak taşı';

  @override
  String get attachmentCopied => 'Ek kopyalandı';

  @override
  String get pasteAttachment => 'Kopyalanan eki yapıştır';

  @override
  String get fullscreen => 'Tam ekran';

  @override
  String get more => 'Diğer';

  @override
  String get undone => 'Geri alındı';

  @override
  String get filterOthers => 'Diğerleri';

  @override
  String get chatSuggestion1 => 'Alışveriş listemde ne eksik?';

  @override
  String get chatSuggestion2 => 'Bu haftaki iş notlarımı özetle';

  @override
  String get chatSuggestion3 => 'Yarın için hatırlatıcım var mı?';

  @override
  String get aiPointsToday => 'Bugünkü puan';

  @override
  String aiPointsOf(int used, int total) {
    return '$used / $total';
  }

  @override
  String get aiPointsRenew => 'gece yarısı yenilenir';

  @override
  String get aiChatWithNotes => 'Not Asistanı';

  @override
  String get aiChatInputHint => 'Notlarına bir şey sor…';

  @override
  String get aiChatLooking => 'notlarına bakıyor…';

  @override
  String get aiChatFullScreen => 'Tam ekran';

  @override
  String get aiOnYourNotes => 'NOTLARIN ÜZERİNDE';

  @override
  String get aiTaskDuplicates => 'Kopyaları temizle';

  @override
  String aiTaskDuplicatesInfo(int count) {
    return '$count kopya not var';
  }

  @override
  String get duplicatesTitle => 'Kopya notlar';

  @override
  String get duplicatesHint =>
      'Her kümede en eski not korunur, kalanlar çöp kutusuna taşınır.';

  @override
  String get duplicatesKeepBadge => 'korunur';

  @override
  String get duplicatesDeleteAll => 'Kopyaları çöpe taşı';

  @override
  String duplicatesDone(int count) {
    return '$count kopya çöp kutusuna taşındı';
  }

  @override
  String get aiRecentActions => 'SON İŞLEMLER';

  @override
  String get aiHistoryClear => 'Temizle';

  @override
  String get aiHistoryQuestion => 'Soru';

  @override
  String get aiHistoryNoteAction => 'Not işlemi';

  @override
  String get aiHistoryVoiceNote => 'Sesli not';

  @override
  String get aiTaskWeekSummary => 'Haftayı özetle';

  @override
  String get aiTaskWeekSummaryInfo => 'Son 7 günün notlarından tek özet';

  @override
  String get aiTaskTagUntagged => 'Etiketsizleri etiketle';

  @override
  String aiTaskTagUntaggedInfo(int count) {
    return '$count not etiket bekliyor';
  }

  @override
  String get aiTaskSuggestTitles => 'Başlık öner';

  @override
  String aiTaskSuggestTitlesInfo(int count) {
    return '$count başlıksız not var';
  }

  @override
  String get sectionPinnedShort => 'SABİT';

  @override
  String get sectionToday => 'BUGÜN';

  @override
  String get sectionThisWeek => 'BU HAFTA';

  @override
  String get sectionEarlier => 'DAHA ÖNCE';

  @override
  String sectionNoteCount(int count) {
    return '$count not';
  }

  @override
  String get emptySearchSemanticHint => 'Anlam sekmesini dene';

  @override
  String get quickCaptureHint => 'Yeni not…';

  @override
  String get quickCaptureSave => 'Kaydet';

  @override
  String get viewToggle => 'Görünüm';

  @override
  String get searchModeMeaning => 'Anlam';

  @override
  String get filterReminded => 'Alarmlı';

  @override
  String get filterLocked => 'Kilitli';

  @override
  String get sortColor => 'Renk';

  @override
  String get sortActive => 'En çok çalışılan';

  @override
  String get voicePreview => 'Sesi dene';

  @override
  String get voicePreviewCached =>
      'Örnek bir kez üretilir, sonra kayıttan çalınır';

  @override
  String get reorderHint => 'Kartı basılı tutup istediğin yere sürükle';

  @override
  String get filterSheetTitle => 'Süz';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterSectionStatus => 'DURUM';

  @override
  String get filterSectionFolder => 'KLASÖR';

  @override
  String get filterSectionTag => 'ETİKET';

  @override
  String get filterSectionSort => 'SIRALAMA';

  @override
  String get filterFavoriteHint =>
      'Ana ekranda kısayol olarak görünmesi için bir seçeneğin yıldızına dokun';

  @override
  String get filterSheetSortHint =>
      'Tarih grupları (BUGÜN, BU HAFTA…) yalnız “Son düzenlenen” sıralamasında gösterilir.';

  @override
  String get formatTitle => 'Biçim';

  @override
  String get formatBold => 'Kalın';

  @override
  String get formatItalic => 'İtalik';

  @override
  String get formatUnderline => 'Altı çizili';

  @override
  String get formatTextColor => 'Yazı rengi';

  @override
  String get formatHighlight => 'Renkli vurgu';

  @override
  String get formatInfo =>
      'Biçim, metnin içinde işaretle taşınır (**kalın** gibi); dışa aktarmada ve okumada işaretler görünmez.';

  @override
  String get formatMenu => 'Biçim…';

  @override
  String get noteFont => 'Yazı tipi';

  @override
  String get noteFontDefault => 'Varsayılan';

  @override
  String get noteFontSerif => 'Kitap (serif)';

  @override
  String get noteFontMono => 'Daktilo';

  @override
  String get noteTextSize => 'Yazı boyutu';

  @override
  String get formatClear => 'Biçimi temizle';

  @override
  String get formatHeading => 'Başlık';

  @override
  String get formatHeading1 => 'Büyük başlık';

  @override
  String get formatHeading2 => 'Alt başlık';

  @override
  String get formatNormalText => 'Normal metin';

  @override
  String get noteTextOpacity => 'Şeffaflık';

  @override
  String get assistantVoiceSetting => 'Asistan sesli yanıtlasın';

  @override
  String get assistantVoiceSettingInfo =>
      'Sesli asistan yanıtını yüksek sesle okur (yalnız telefonda).';

  @override
  String get assistantMute => 'Sesi kapat';

  @override
  String get assistantUnmute => 'Sesi aç';

  @override
  String get assistantMakeNote => 'Yine de nota dönüştür';

  @override
  String get assistantNoteCreated => 'Not oluşturuldu';

  @override
  String get noteNotFound => 'Not bulunamadı. Silinmiş olabilir.';

  @override
  String get back => 'Geri';

  @override
  String get addTextBlock => 'Metin ekle';

  @override
  String get attachNoteContent => 'Not içeriği';

  @override
  String get noteBackgroundImage => 'Zemin görseli';

  @override
  String get chooseBackgroundImage => 'Görsel seç';

  @override
  String get changeBackgroundImage => 'Görseli değiştir';

  @override
  String get removeBackgroundImage => 'Zemini kaldır';

  @override
  String get dashboardBackground => 'Ana ekran zemini';

  @override
  String get dashboardBackgroundInfo =>
      'Not ızgarasının arkasında duran görsel (yalnız bu cihazda).';

  @override
  String get aiProvider => 'Yapay zeka sağlayıcısı';

  @override
  String get aiProviderInfo =>
      'Kendi anahtarınla çalışan sağlayıcıyı seç. Her sağlayıcının anahtarı ayrı saklanır; aralarında geçiş yapınca yeniden girmen gerekmez.';

  @override
  String get apiKeyFieldLabel => 'API anahtarı';

  @override
  String get getApiKey => 'Anahtarı nereden alırım?';

  @override
  String get recommendedModel => 'Önerilen';

  @override
  String get freeTierBadge => 'Ücretsiz kademe var';

  @override
  String get continueWithoutAccount => 'Hesapsız devam et';

  @override
  String get localAccountInfo =>
      'Notların yalnız bu cihazda kalır: başka cihazdan açılamaz, uygulamayı silersen geri getirilemez ve dahili yapay zeka kapalı olur. İstediğin an Google hesabı bağlayabilirsin — notların olduğu gibi kalır.';

  @override
  String get localAccountBadge => 'Yerel hesap';

  @override
  String get linkGoogleAccount => 'Google hesabı bağla';

  @override
  String get accountLinked =>
      'Google hesabın bağlandı. Notların artık yedekleniyor.';

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
      'Hesapsız giriş şu an kapalı: Firebase konsolunda Authentication → Sign-in method → Anonymous açık değil. Google ile giriş yapabilir ya da yönetici bu yöntemi açtıktan sonra yeniden deneyebilirsin.';

  @override
  String get googleSignInUnavailable =>
      'Google ile giriş şu an kapalı: Firebase konsolunda Google oturum açma yöntemi etkin değil.';

  @override
  String get signInNetworkError =>
      'İnternete ulaşılamadı. Bağlantını kontrol edip yeniden dene.';

  @override
  String get signInCanceled => 'Giriş iptal edildi.';

  @override
  String get cardRichPreview => 'Kartlarda biçimli metin';

  @override
  String get cardRichPreviewInfo =>
      'Notların rengi, vurgusu, kalın ve altı çizili yazıları ana ekrandaki kartlarda da görünür. Kapalıyken kartlar düz metin gösterir.';

  @override
  String get fontSizeSmall => 'Küçük';

  @override
  String get fontSizeMedium => 'Orta';

  @override
  String get fontSizeLarge => 'Büyük';

  @override
  String get fontSizeXLarge => 'Çok büyük';

  @override
  String get appFontSetting => 'Yazı tipi';

  @override
  String get appFontInfo =>
      'Uygulamanın her yerinde kullanılan yazı tipi. Notun kendi yazı tipi seçimi bunun üstüne biner. Tüm yazı tipleri uygulamayla birlikte geliyor — internet gerekmez.';

  @override
  String get fontGroupSans => 'Sade';

  @override
  String get fontGroupSerif => 'Kitap';

  @override
  String get fontGroupMono => 'Daktilo';

  @override
  String get fontGroupHand => 'El yazısı';

  @override
  String get appFontDefaultSuffix => 'varsayılan';

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
      'Yapay zekâ sesi kendi Gemini anahtarını ister. Anahtar eklenene kadar okuma cihaz sesiyle yapılır.';

  @override
  String get ttsModel => 'Seslendirme modeli';

  @override
  String get ttsVoice => 'Yapay zekâ sesi';

  @override
  String get shareAsNotePreparing => 'Not paketi hazırlanıyor…';

  @override
  String get shareAsTextEmpty => 'Bu notta paylaşılacak yazı yok.';

  @override
  String get sharePdfWithBubbles => 'Balonlu PDF olarak';

  @override
  String get sharePdfWithBubblesInfo =>
      'Balonlar, vurgular ve çizimler PDF\'in içine basılır; herkes açabilir, Notlar\'da ise düzenlenebilir açılır.';

  @override
  String get sharePdfWithBubblesNone =>
      'Bu notta balon ya da çizim taşıyan PDF yok.';

  @override
  String get sharePdfWithBubblesPreparing => 'Balonlu PDF hazırlanıyor…';

  @override
  String get sharePdfWithBubblesSuffix => ' (balonlu)';

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
  String get formatRemove => 'Kaldır';

  @override
  String get exportTitle => 'Dışa aktar';

  @override
  String get exportNotesOption => 'Not metni (PDF / Word)';

  @override
  String get exportNotesOptionInfo =>
      'Notun yazısı ve görselleri; balonlar dahil değil.';

  @override
  String get captureNoteTitle => 'Not başlığı (isteğe bağlı)';

  @override
  String get captureNoteTitleHint => 'Oluşacak belgeye de bu ad verilir';

  @override
  String get imageOcrTitle => 'Görseldeki metni tanı';

  @override
  String get imageOcrNone => 'Bu görselde metin bulunamadı.';

  @override
  String get imageOcrShort => 'Metni tanı';

  @override
  String get imageOcrWorking => 'Metin tanınıyor…';

  @override
  String get imageOcrSelectHint =>
      'Dokun: kelime · Basılı tut ve sürükle: harf harf';

  @override
  String get imageOcrInsert => 'Nota ekle';

  @override
  String get imageOcrZoomIn => 'Yakınlaştır';

  @override
  String get imageOcrZoomOut => 'Uzaklaştır';

  @override
  String get selectImages => 'Görselleri seç';

  @override
  String get exportImages => 'Görseller';

  @override
  String get exportImagesInfo =>
      'Sola ya da sağa yaslı dar görsellerin yanından metin akar; ortalanan görsel tam genişlik olur.';

  @override
  String get exportAlignLeft => 'Sol';

  @override
  String get exportAlignCenter => 'Orta';

  @override
  String get exportAlignRight => 'Sağ';

  @override
  String get exportImageWidth => 'Genişlik';

  @override
  String get exportImageLine => 'Konum';

  @override
  String get aiModelSearch => 'Model ara';

  @override
  String get aiModelOthers => 'DİĞER MODELLER';

  @override
  String get aiModelNoMatch => 'Eşleşen model yok.';

  @override
  String get aiModelAutoInfo => 'Uygulama sırayla en uygun modeli dener.';

  @override
  String imageOcrCharsSelected(int count) {
    return '$count karakter seçildi';
  }

  @override
  String imagesSelectedCount(int count) {
    return '$count görsel seçildi';
  }

  @override
  String attachmentsCopiedCount(int count) {
    return '$count ek';
  }

  @override
  String exportImageLineOf(int count) {
    return '/ $count satır';
  }

  @override
  String get aiModelShowAll => 'Tümünü göster';

  @override
  String get aiModelShowAllInfo =>
      'Uygulamanın kullanmadığı modeller de listelenir.';

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
  String get archiveNotebook => 'Defter';

  @override
  String get archiveNewPage => 'Yeni sayfa';

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
  String get archiveDeletePage => 'Sayfayı sil';

  @override
  String get archivePrevPage => 'Önceki sayfa';

  @override
  String get archiveNextPage => 'Sonraki sayfa';

  @override
  String get archiveCopyHere => 'Arşiv defterine kopyala';

  @override
  String get archiveNoNotebook =>
      'Henüz arşiv defteri yok. Önce bir tane oluştur.';

  @override
  String get archiveNothingToCopy => 'Bu notta kopyalanacak ek yok.';

  @override
  String archiveCopied(int count) {
    return '$count dosya arşiv defterine kopyalandı.';
  }

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
  String get attachmentTagEmbed => 'Ek göm';

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
  String get friendsSearchHint => 'Ad (en az 3 harf) ya da tam e-posta';

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
  String get folderShare => 'Birlikte düzenle';

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
  String get collaborators => 'Ortak çalışanlar';

  @override
  String get collaboratorsInfo =>
      'Eklediğin kişiler bu notu kendi ana ekranlarında görür ve seninle aynı anda düzenler.';

  @override
  String get collaboratorsOwner => 'Sahibi';

  @override
  String get collaboratorsFriendsTitle => 'ARKADAŞLARIN';

  @override
  String get collaboratorsLeave => 'Paylaşımdan ayrıl';

  @override
  String get collaboratorsLeaveConfirm =>
      'Bu not artık ana ekranında görünmeyecek. Ayrılmak istiyor musun?';

  @override
  String get collaboratorsSaved => 'Paylaşım güncellendi';

  @override
  String collaboratorsCount(int count) {
    return '$count kişiyle paylaşıldı';
  }

  @override
  String get collaboratorsOnlyOwner =>
      'Ortak çalışanları yalnız notun sahibi değiştirebilir.';

  @override
  String get sharedWithMe => 'Benimle paylaşılanlar';

  @override
  String get sharedWithMeEmpty =>
      'Henüz seninle paylaşılan bir not yok. Biri seni bir notuna eklediğinde burada görünür.';

  @override
  String sharedByName(Object name) {
    return '$name paylaştı';
  }

  @override
  String get navNotes => 'Notlar';

  @override
  String get railExpand => 'Menüyü genişlet';

  @override
  String get railCollapse => 'Menüyü daralt';

  @override
  String get newNoteShort => 'Yeni not';

  @override
  String get newChecklistShort => 'Yeni liste';

  @override
  String get listPaneHide => 'Not listesini gizle';

  @override
  String get listPaneShow => 'Not listesini göster';

  @override
  String get keyboardShortcuts => 'Klavye kısayolları';

  @override
  String get shortcutSearch => 'Notlarda ara';

  @override
  String get shortcutToggleList => 'Not listesini gizle / göster';

  @override
  String get shortcutSections => 'Bölümler arasında geç';

  @override
  String get shortcutHelp => 'Kısayolları göster';

  @override
  String get noNoteSelectedHint => 'ya da yeni bir not başlat';

  @override
  String get loginFeatureSyncTitle => 'Her cihazda aynı notlar';

  @override
  String get loginFeatureSyncBody =>
      'Telefon, tablet, bilgisayar ve web arasında anında senkron.';

  @override
  String get loginFeatureAiTitle => 'Yapay zekâ yanında';

  @override
  String get loginFeatureAiBody =>
      'Özetle, sor, sesle yaz; belgelerinle konuş.';

  @override
  String get loginFeatureShareTitle => 'Birlikte yaz';

  @override
  String get loginFeatureShareBody =>
      'Notları ve klasörleri arkadaşlarınla canlı paylaş.';

  @override
  String get loginFeatureInkTitle => 'Kalem ve PDF';

  @override
  String get loginFeatureInkBody =>
      'El yazısıyla not al, PDF ve slaytların üstüne yaz.';

  @override
  String get foldersTitle => 'Klasörler';

  @override
  String get foldersEmpty =>
      'Henüz klasör yok. Bir klasör oluşturup notlarını düzenle.';

  @override
  String get folderColor => 'Renk';

  @override
  String get folderColorAuto => 'Otomatik';

  @override
  String get foldersMine => 'Klasörlerim';

  @override
  String get foldersSharedSection => 'Benimle paylaşılan klasörler';

  @override
  String trashDaysShort(int count) {
    return '$count gün';
  }

  @override
  String get trashTodayShort => 'Bugün';

  @override
  String get trashSoonSection => 'Yakında kalıcı silinecek';

  @override
  String get trashRestSection => 'Diğer silinenler';

  @override
  String get aiHubTagline => 'Notlarına sor, özetlet, düzenlet.';

  @override
  String get aiToolsSection => 'Araçlar';

  @override
  String get folderOrderTitle => 'Klasör sırası';

  @override
  String get folderReorder => 'Klasörleri sırala';

  @override
  String get folderOrderManual => 'Elle';

  @override
  String get folderOrderName => 'Ada göre';

  @override
  String get folderOrderNewest => 'En yeni önce';

  @override
  String get folderOrderNoteCount => 'Not sayısına göre';

  @override
  String get folderOrderHint =>
      'Tutamaktan sürükleyerek sıralayın. Bu sıra klasör şeridinde ve yana kaydırırken de kullanılır.';

  @override
  String get swipeModeTitle => 'Ana ekranda yana kaydırınca';

  @override
  String get swipeModeFolders => 'Klasörler arasında geç';

  @override
  String get swipeModeFilters => 'Süzgeçler ve etiketler arasında geç';

  @override
  String get swipeModeBoth => 'Klasörler, süzgeçler ve etiketler';

  @override
  String get swipeModeOff => 'Kapalı';

  @override
  String get shareIncludeTitle => 'Başlık';

  @override
  String get shareIncludeChecked => 'Tamamlananlar';

  @override
  String get shareIncludeTags => 'Etiketler';

  @override
  String get shareTextAction => 'Metni paylaş';

  @override
  String get findPrevious => 'Önceki eşleşme';

  @override
  String get findNext => 'Sonraki eşleşme';

  @override
  String get findShowAll => 'Tüm eşleşmeler';

  @override
  String findMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eşleşme',
      zero: 'Eşleşme yok',
    );
    return '$_temp0';
  }

  @override
  String get findDeepSearch => 'Eklerde ve YZ ile ara';

  @override
  String get notesSettingsTitle => 'Notlar ve klasörler';

  @override
  String get noteViewSetting => 'Ana ekran görünümü';

  @override
  String get noteViewGrid => 'Izgara';

  @override
  String get noteViewList => 'Liste';

  @override
  String get gridColumnsSetting => 'Sütun sayısı';

  @override
  String get gridColumnsInfo =>
      'Ana ekranda iki parmakla yakınlaştırarak da değiştirebilirsin.';

  @override
  String get gridColumnsAuto => 'Otomatik';

  @override
  String get folderShelfSetting => 'Klasörler ana ekranda';

  @override
  String get folderShelfStrip => 'Tek satır';

  @override
  String get folderShelfTiles => 'Karolar';

  @override
  String get deviceStorageTitle => 'Bu cihazda';

  @override
  String get deviceStorageAttachments => 'Ekler';

  @override
  String get deviceStorageDatabase => 'Notların yerel kopyası';

  @override
  String get deviceStorageCache => 'Önbellek ve geçici dosyalar';

  @override
  String get deviceStorageAi => 'Yapay zekâ önbelleği';

  @override
  String get deviceStorageTotal => 'Toplam (uygulamanın kendisi hariç)';

  @override
  String get deviceStorageInfo =>
      'Önbelleği temizlemek notları ve ekleri silmez; görseller gerektikçe yeniden iner. Eski geçici dosyalar zaten her açılışta temizlenir.';

  @override
  String get deviceStorageClear => 'Önbelleği temizle';

  @override
  String deviceStorageCleared(String size) {
    return '$size boşaltıldı';
  }

  @override
  String get deviceStorageUnavailable => 'Bu cihazda ölçülemedi.';

  @override
  String get localOnlyTurnOn => 'Senkronu kapat';

  @override
  String get localOnlyTurnOff => 'Senkronu aç';

  @override
  String get localOnlyBadge => 'Yalnız bu cihazda';

  @override
  String get localOnlyConfirmTitle => 'Bu not yalnız bu cihazda kalsın mı?';

  @override
  String get localOnlyConfirmBody =>
      'Not ve ekleri buluttan silinir ve diğer cihazlarında görünmez. Uygulamayı silersen ya da telefonu değiştirirsen bu not da gider. Senkronu istediğin zaman yeniden açabilirsin.';

  @override
  String get localOnlyConfirm => 'Senkronu kapat';

  @override
  String get localOnlyOnDone => 'Not artık yalnız bu cihazda';

  @override
  String get localOnlyOffDone => 'Not yeniden senkronlanıyor';

  @override
  String get localOnlySharedBlocked =>
      'Paylaşılan bir notun senkronu kapatılamaz';

  @override
  String get localOnlyDownloadFailed =>
      'Bazı ekler bu cihaza indirilemedi. Bağlantını kontrol edip yeniden dene; not değişmedi.';

  @override
  String get templatesTitle => 'Şablonlar';

  @override
  String get templatesSubtitle =>
      'Hazır düzenle başla; her şey sonradan değiştirilebilir.';

  @override
  String get fromTemplate => 'Şablondan';

  @override
  String get tplShoppingName => 'Alışveriş listesi';

  @override
  String get tplShoppingItems => 'Ekmek, Süt, Yumurta, Meyve, Sebze';

  @override
  String get tplShoppingDesc => 'Alınanları işaretle, alta insin';

  @override
  String get tplTodoDesc => 'Bugünün tarihiyle boş liste';

  @override
  String get tplTravelName => 'Seyahat çantası';

  @override
  String get tplTravelItems =>
      'Kimlik / pasaport, Telefon şarj aleti, İlaçlar, Diş fırçası, Kıyafetler, Kulaklık';

  @override
  String get tplTravelDesc => 'Hazır kontrol listesi';

  @override
  String get tplMeetingDesc => 'Katılımcılar, gündem, kararlar';

  @override
  String get tplJournalDesc => 'Bugün nasıldı, minnettarlık, yarın';

  @override
  String get tplRecipeName => 'Tarif';

  @override
  String get tplRecipeMeta => 'Porsiyon: · Süre:';

  @override
  String get tplRecipeIngredients => 'Malzemeler';

  @override
  String get tplRecipeSteps => 'Yapılışı';

  @override
  String get tplRecipeNotes => 'Notlar';

  @override
  String get tplRecipeDesc => 'Malzemeler ve adımlar';

  @override
  String get tplWeeklyName => 'Haftalık plan';

  @override
  String get tplWeeklyDesc => 'Bu haftanın günleri başlık başlık';

  @override
  String get tplExpenseDesc => 'Tarih, açıklama, tutar';

  @override
  String get tplReadingDesc => 'Kaynak, özet, alıntılar';

  @override
  String get settingsThemeHeader => 'Tema';

  @override
  String get settingsCardsHeader => 'Kartlar ve listeler';

  @override
  String get shareTargetTitle => 'Notlar\'a ekle';

  @override
  String get shareTargetNew => 'Yeni not';

  @override
  String get shareTargetExisting => 'Var olan nota';

  @override
  String get shareTargetCreate => 'Not oluştur';

  @override
  String get shareTargetSearch => 'Notlarda ara';

  @override
  String get shareTargetNoNotes => 'Eklenebilecek not yok';

  @override
  String get shareTargetNoMatch => 'Eşleşen not yok';

  @override
  String shareTargetMore(int count) {
    return '+$count dosya';
  }

  @override
  String get sharePreviewExpand => 'Önizlemeyi büyüt';

  @override
  String get sharePreviewCollapse => 'Önizlemeyi küçült';

  @override
  String get templatesSearch => 'Şablon ara';

  @override
  String get templatesAll => 'Tümü';

  @override
  String get templatesLists => 'Listeler';

  @override
  String get templatesPlanning => 'Planlama';

  @override
  String get templatesWriting => 'Yazı';

  @override
  String get templatesMine => 'Şablonlarım';

  @override
  String get templatesRecent => 'Son kullanılanlar';

  @override
  String get templatesNoMatch => 'Eşleşen şablon yok';

  @override
  String get templatesMineEmpty =>
      'Henüz kendi şablonun yok. Bir notun menüsünden “Şablon olarak kaydet” dersen burada durur.';

  @override
  String get templatesMineInfo => 'Kendi şablonun';

  @override
  String get templateRename => 'Yeniden adlandır';

  @override
  String get templateDelete => 'Şablonu sil';

  @override
  String get templateNameTitle => 'Şablon adı';

  @override
  String get templateNameHint => 'Ör. Haftalık market';

  @override
  String get templateSave => 'Kaydet';

  @override
  String templateSaved(String name) {
    return '“$name” şablonlarına eklendi';
  }

  @override
  String get saveAsTemplate => 'Şablon olarak kaydet';

  @override
  String get templateCreate => 'Oluştur';

  @override
  String templateCreateWithCount(int count) {
    return 'Oluştur · $count madde';
  }

  @override
  String get templateListChecks => 'Onay kutulu';

  @override
  String get templateListNumbers => 'Numaralı';

  @override
  String get templateItems => 'Maddeler';

  @override
  String get templateAddItem => 'Madde ekle';

  @override
  String get templateSuggestionsInfo =>
      'Öneriye dokununca listeye girer, yine dokununca çıkar.';

  @override
  String get tplShopProduce => 'Meyve ve sebze';

  @override
  String get tplShopProduceItems =>
      'Domates, Salatalık, Soğan, Patates, Limon, Muz, Elma, Maydanoz';

  @override
  String get tplShopBreakfast => 'Kahvaltılık';

  @override
  String get tplShopBreakfastItems =>
      'Peynir, Zeytin, Tereyağı, Bal, Reçel, Yoğurt';

  @override
  String get tplShopPantry => 'Temel gıda';

  @override
  String get tplShopPantryItems =>
      'Pirinç, Makarna, Un, Şeker, Zeytinyağı, Mercimek, Çay, Kahve';

  @override
  String get tplShopCleaning => 'Temizlik';

  @override
  String get tplShopCleaningItems =>
      'Bulaşık deterjanı, Çamaşır deterjanı, Tuvalet kâğıdı, Kâğıt havlu, Çöp poşeti';

  @override
  String get tplShopPersonal => 'Kişisel bakım';

  @override
  String get tplShopPersonalItems => 'Şampuan, Diş macunu, Sabun, Deodorant';

  @override
  String get tplTravelDocs => 'Belgeler';

  @override
  String get tplTravelDocsItems =>
      'Bilet, Otel rezervasyonu, Ehliyet, Seyahat sigortası, Nakit / kart';

  @override
  String get tplTravelClothes => 'Giyim';

  @override
  String get tplTravelClothesItems =>
      'Tişört, Pantolon, İç çamaşırı, Çorap, Pijama, Ceket, Ayakkabı';

  @override
  String get tplTravelCare => 'Bakım';

  @override
  String get tplTravelCareItems =>
      'Diş macunu, Şampuan, Güneş kremi, Tıraş takımı, Deodorant';

  @override
  String get tplTravelTech => 'Elektronik';

  @override
  String get tplTravelTechItems =>
      'Powerbank, Priz adaptörü, Kulaklık, Kablolar';

  @override
  String get tplHabitsName => 'Alışkanlık takibi';

  @override
  String get tplHabitsDesc => 'Her gün işaretle, zinciri kırma';

  @override
  String get tplHabitsItems =>
      '8 bardak su, 30 dakika yürüyüş, 20 sayfa kitap, Erken yat, Ekransız bir saat';

  @override
  String get tplCleaningName => 'Ev temizliği';

  @override
  String get tplCleaningDesc => 'Haftalık temizlik kontrol listesi';

  @override
  String get tplCleaningItems =>
      'Toz al, Süpür, Paspas yap, Banyoyu temizle, Mutfak tezgâhı, Çamaşır, Çöpleri çıkar, Çarşafları değiştir';

  @override
  String get tplMovingName => 'Taşınma listesi';

  @override
  String get tplMovingDesc => 'Taşınmadan önce ve sonra yapılacaklar';

  @override
  String get tplMovingItems =>
      'Nakliyeci ayarla, Koli ve bant al, Adres değişikliği bildir, Elektrik / su / doğalgaz aboneliği, İnterneti taşı, Anahtar teslimi';

  @override
  String get tplGiftsName => 'Hediye listesi';

  @override
  String get tplGiftsDesc => 'Kime ne alınacak, fikirler';

  @override
  String get tplGiftsItems => 'Anne, Baba, Kardeş, Arkadaş';

  @override
  String get tplWatchlistName => 'İzlenecekler';

  @override
  String get tplWatchlistDesc => 'Film, dizi ve kitap listesi';

  @override
  String get tplWorkoutName => 'Antrenman';

  @override
  String get tplWorkoutDesc => 'Isınmadan esnemeye egzersiz listesi';

  @override
  String get tplWorkoutItems =>
      'Isınma 5 dk, Squat 3×12, Şınav 3×10, Mekik 3×15, Plank 3×45 sn, Esneme 5 dk';

  @override
  String get tplGoalsName => 'Hedefler';

  @override
  String get tplGoalsDesc => 'Yıl, ay ve hafta hedefleri';

  @override
  String get tplGoalsYear => 'Bu yıl';

  @override
  String get tplGoalsMonth => 'Bu ay';

  @override
  String get tplGoalsWeek => 'Bu hafta';

  @override
  String get tplGoalsWhy => 'Neden önemli?';

  @override
  String get templateNew => 'Yeni şablon';

  @override
  String get templateEdit => 'Şablonu düzenle';

  @override
  String get templateDuplicate => 'Çoğalt';

  @override
  String get templateSaveAsMine => 'Şablonlarıma kaydet';

  @override
  String get templateUntitled => 'Adsız şablon';

  @override
  String get templateTypeText => 'Yazı';

  @override
  String get templateTitleHelp =>
      'Şablondan açılan notun başlığı (boş bırakılabilir)';

  @override
  String get templateBody => 'Yazı';

  @override
  String get templateHeadingHelp =>
      '“# ” ile başlayan satır başlık, “## ” ile başlayan alt başlık olur.';

  @override
  String get templateDiscardTitle => 'Değişiklikler kaydedilmesin mi?';

  @override
  String get templateDiscard => 'Vazgeç';

  @override
  String templateDeleted(String name) {
    return '“$name” silindi';
  }

  @override
  String get addVideoFromGallery => 'Galeriden video';

  @override
  String get addYouTubeVideo => 'YouTube videosu';

  @override
  String get addYouTubeVideoSubtitle => 'Notta oynar, küçük pencerede izlenir';

  @override
  String get youTubeLinkHelp =>
      'YouTube video bağlantısını yapıştır (youtube.com veya youtu.be).';

  @override
  String get youTubeInvalidLink => 'Bu bir YouTube video bağlantısı değil';

  @override
  String get youTubeOpenInBrowserInfo =>
      'Bu cihazda video uygulama içinde oynatılamıyor; tarayıcıda açılabilir.';

  @override
  String get youTubeOpenExternal => 'YouTube\'da aç';

  @override
  String get pictureInPicture => 'Resim içinde resim';

  @override
  String get pinMediaRelease => 'Bırak: üste sabitle (altta not)';

  @override
  String get unpinMedia => 'Sayfaya geri koy';

  @override
  String get unpinMediaRelease => 'Bırak: sayfaya geri koy';

  @override
  String get pinnedMediaResize => 'Bölme yüksekliği — sürükleyerek değiştir';

  @override
  String pageOf(int current, int total) {
    return 'Sayfa $current / $total';
  }

  @override
  String pageAdded(int page) {
    return '$page. sayfa eklendi';
  }

  @override
  String get deletePageConfirm =>
      'Bu sayfanın yazısı silinsin mi? Görselleri komşu sayfaya taşınır. Geri al ile geri getirebilirsin.';

  @override
  String get embedNewPdf => 'PDF';

  @override
  String get embedNewImage => 'Görsel';

  @override
  String get embedNewVideo => 'Video';

  @override
  String get embedNewYouTube => 'YouTube';

  @override
  String get embedPickTitle => 'Ne gömülsün?';

  @override
  String embedPickTitleFor(String label) {
    return '“$label” yazısına göm';
  }

  @override
  String get embedPickInfo => 'Gömülen ek yazıya dokununca yerinde açılır.';

  @override
  String get embedSectionNew => 'Yeni ekle';

  @override
  String get embedSectionExisting => 'Bu nottaki ekler';

  @override
  String get embedReplace => 'Değiştir';

  @override
  String get embedRemove => 'Gömmeyi kaldır';

  @override
  String get embedRemoved => 'Gömme kaldırıldı';

  @override
  String get guideTitle => 'Kullanım kılavuzu';

  @override
  String get guideMenuInfo => 'Bütün özellikler, adım adım';

  @override
  String get guideSearchHint => 'Kılavuzda ara — “sayfa”, “YouTube”';

  @override
  String get guideContents => 'İçindekiler';

  @override
  String get guideOpenScreen => 'Ekranı aç';

  @override
  String guideNoResults(String query) {
    return '«$query» için sonuç yok';
  }

  @override
  String get copyVideoLink => 'Bağlantıyı kopyala';

  @override
  String get videoLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get attachSectionVisual => 'Görsel ve çizim';

  @override
  String get menuSectionOrganize => 'Düzenle';

  @override
  String get menuSectionCopy => 'Kopyala ve dışa aktar';

  @override
  String get menuSectionTools => 'Araçlar';

  @override
  String get menuSectionProtect => 'Koruma ve depolama';

  @override
  String get menuSectionContent => 'İçerik';

  @override
  String get menuSectionPeople => 'Hesap ve kişiler';

  @override
  String get menuSectionHome => 'Ana ekran';

  @override
  String get menuSectionApp => 'Uygulama';

  @override
  String cardMoreFiles(int count) {
    return '+$count dosya daha';
  }

  @override
  String cardAudioCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ses kaydı',
      one: 'Ses kaydı',
    );
    return '$_temp0';
  }

  @override
  String get cardBubbleDocument => 'BALONLU PDF';

  @override
  String get cardBubbleSlides => 'BALONLU SUNUM';

  @override
  String get cardKindPdf => 'PDF';

  @override
  String get cardKindSlides => 'SUNUM';

  @override
  String cardBubbleCount(int count) {
    return '$count balon';
  }

  @override
  String get quickAddYouTube => 'YouTube videosu';

  @override
  String get docViewToBubbles => 'Balonlu görünüme geç';

  @override
  String get docViewToClassic => 'Klasik görünüme geç';

  @override
  String get docViewSwitchedBubbles =>
      'Balonlu görünüm: belge üstte, sayfa notu altta. Klasik yerleşim saklandı.';

  @override
  String get docViewSwitchedClassic =>
      'Klasik görünüm: belge sayfada bir ek. Balonlar ve sayfa notları saklandı.';

  @override
  String get docViewTextKept => 'Notun yazısı klasik görünümde duruyor.';

  @override
  String get captureModeChangeLater =>
      'Sonradan nottaki Balonlu / Klasik çipiyle değiştirebilirsin.';

  @override
  String get attachmentSyncTitle => 'Ek senkronu';

  @override
  String get driveSectionTitle => 'Ekler Google Drive\'ında';

  @override
  String get driveConnectTitle => 'Ekleri Google Drive\'ında sakla';

  @override
  String get driveConnectInfo =>
      'Görseller, PDF\'ler, sunumlar ve ses kayıtları kendi Drive kotanda, uygulamaya özel gizli klasörde saklanır ve öbür cihazlarına iner. Videolar cihazda kalır.';

  @override
  String get driveConnect => 'Bağla';

  @override
  String get driveDisconnect => 'Bağlantıyı kes';

  @override
  String get driveConnected => 'Google Drive bağlandı — ekler yedekleniyor.';

  @override
  String get driveConnectedInfo =>
      'Bağlı · ekler Drive\'ının uygulama klasöründe';

  @override
  String driveUsage(String used, String limit) {
    return 'Drive: $used / $limit kullanıldı';
  }

  @override
  String driveConnectFailed(String error) {
    return 'Google Drive bağlanamadı. $error';
  }

  @override
  String get driveApiDisabled =>
      'Google Cloud projesinde Drive API kapalı: konsolda \"Google Drive API\"yi etkinleştirip yeniden dene.';

  @override
  String get driveDisconnected =>
      'Drive bağlantısı kesildi. Yeni ekler bağlanana dek cihazda bekler.';

  @override
  String get textOnlyTitle => 'Yalnız metin senkronu';

  @override
  String get textOnlyInfo =>
      'Misafir hesapta yalnız yazılar senkronlanır; ekler bu cihazda kalır. Google hesabı bağlarsan ekler Google Drive\'ında saklanır.';

  @override
  String get storageModeInfo => 'Web\'de ekler uygulama bulutuna yüklenir.';

  @override
  String driveWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek Google Drive bağlantısını bekliyor — dokun, bağla',
      one: '1 ek Google Drive bağlantısını bekliyor — dokun, bağla',
    );
    return '$_temp0';
  }

  @override
  String get driveDownloading => 'Ek Google Drive\'dan indiriliyor…';

  @override
  String get driveNeededForFile =>
      'Bu ek Google Drive\'ında. Görmek için Ayarlar → Senkron\'dan Drive\'ı bağla.';

  @override
  String get bubbleDone => 'Bitti';

  @override
  String get bubbleEditShort => 'Düzenle';

  @override
  String get bubblePlainModeShort => 'Metin';

  @override
  String get pageBarMore => 'Sayfa ve not seçenekleri';

  @override
  String get viewModeTitle => 'Görünüm';

  @override
  String get viewModePinned => 'Sabit';

  @override
  String get viewModeFloating => 'Yüzen';

  @override
  String get viewModeBubbles => 'Balonlu';

  @override
  String get viewModePinnedHint =>
      'Üste sabitle — ek tepede durur, not altında kayar';

  @override
  String get viewModeFloatingHint => 'Sayfada yüzer — yazı etrafından akar';

  @override
  String get viewModeBubblesHint =>
      'Balonlu görünüm — sayfanın üstüne balon, vurgu ve kalem';

  @override
  String get viewModeSwitchedFloating => 'Ek sayfaya döndü';

  @override
  String get videoNoteAtTime => 'Bu ana not al';

  @override
  String get videoNoteAtTimeShort => 'Not al';

  @override
  String get videoTimeUnknown => 'Videonun anı okunamadı — önce videoyu oynat.';

  @override
  String get videoSpeed => 'Oynatma hızı';

  @override
  String get videoLoop => 'Tekrarla';

  @override
  String get bubbleSmaller => 'Balonu küçült';

  @override
  String get bubbleLarger => 'Balonu büyüt';

  @override
  String get bubbleAllSmaller => 'Tüm balonları küçült';

  @override
  String get bubbleAllLarger => 'Tüm balonları büyüt';

  @override
  String get bubblesShow => 'Balonları göster';

  @override
  String get bubblesHide => 'Balonları gizle';

  @override
  String get shareIncludeVideoLinks => 'Video bağlantıları';

  @override
  String get shareQuickPdf => 'PDF';

  @override
  String get shareAsImage => 'Görsel';

  @override
  String shareAttachmentFiles(int count) {
    return 'Ekler ($count)';
  }

  @override
  String get shareToFriendShort => 'Kopya gönder';

  @override
  String get shareCollaborateShort => 'Birlikte düzenle';

  @override
  String get shareAsNoteShort => 'Not paketi';

  @override
  String get shareMoreSection => 'DAHA FAZLA';

  @override
  String get shareQuickPreparing => 'Hazırlanıyor…';

  @override
  String get shareAttachmentFilesNone =>
      'Bu cihazda paylaşılacak ek dosyası yok.';

  @override
  String get attachmentRemoved => 'Ek kaldırıldı';

  @override
  String get pinnedEmbedOnPage => 'Sayfaya göm (yüzen)';

  @override
  String get customizeHideItem => 'Gizle';

  @override
  String get customizeShowItem => 'Göster';

  @override
  String get customizeModeTitle => 'Düzenleme modu';

  @override
  String get customizeModeHint => 'Gizlemek/göstermek için öğelere dokunun';

  @override
  String customizeHiddenCount(int count) {
    return '$count öğe gizli · dokunarak değiştirin';
  }

  @override
  String get customizeSave => 'Kaydet';

  @override
  String get customizeSaved => 'Düzen kaydedildi';

  @override
  String videoBackSeconds(int seconds) {
    return '$seconds sn geri';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return '$seconds sn ileri';
  }

  @override
  String get personalizeTitle => 'Kişiselleştir';

  @override
  String get personalizeInfo => 'Hangi alan ve düğmeler görünsün, eklentiler';

  @override
  String get personalizeOpen => 'Kişiselleştirmeyi aç';

  @override
  String get customizeStartTitle => 'Ekranda düzenle';

  @override
  String get customizeStartInfo =>
      'Düzenleme modunu açın; ekranlardaki düğme ve alanlara dokunarak gizleyin ya da gösterin. Bitince üstteki şeritten Kaydet\'e basın.';

  @override
  String get customizeStart => 'Düzenleme modunu başlat';

  @override
  String get customizeActive => 'Düzenleme modu açık';

  @override
  String get customizeModeShort => 'Ekranlarda dokunarak gizle/göster';

  @override
  String get personalizeModules => 'EKLENTİLER';

  @override
  String get personalizeModulesInfo =>
      'Bir eklentiyi kapatınca ona ait düğmeler her yerden kalkar.';

  @override
  String get moduleAi => 'Yapay zekâ';

  @override
  String get moduleAiInfo =>
      'Ana ekran ve not ekranındaki yapay zekâ düğmeleri';

  @override
  String get moduleVoice => 'Ses';

  @override
  String get moduleVoiceInfo => 'Sesli not, sesli yazdırma, ses kaydı';

  @override
  String get moduleVideo => 'Video';

  @override
  String get moduleVideoInfo => 'Video çekme, galeriden video, YouTube';

  @override
  String get moduleDocuments => 'Belgeler';

  @override
  String get moduleDocumentsInfo => 'PDF ve sunum ekleme';

  @override
  String get moduleScan => 'Tarama';

  @override
  String get moduleScanInfo => 'Belge tarama ve QR kod';

  @override
  String get moduleDrawing => 'Çizim';

  @override
  String get moduleDrawingInfo => 'El yazısı ve çizim';

  @override
  String get moduleTemplates => 'Şablonlar';

  @override
  String get moduleTemplatesInfo =>
      'Şablondan not, alışveriş listesi, arşiv defteri';

  @override
  String get moduleTags => 'Not çipleri';

  @override
  String get moduleTagsInfo =>
      'Başlığın altındaki etiket, klasör ve hatırlatıcı çipleri';

  @override
  String get moduleCollaboration => 'Ortak çalışma';

  @override
  String get moduleCollaborationInfo => 'Not ekranındaki kişi ekle düğmesi';

  @override
  String get moduleMixed => 'kısmen açık';

  @override
  String get personalizeEditorBar => 'NOT EKRANI · ALT ÇUBUK';

  @override
  String get personalizeEditorTop => 'NOT EKRANI · ÜST ÇUBUK VE ALANLAR';

  @override
  String get personalizeQuickAdd => 'YENİ NOT MENÜSÜ (+)';

  @override
  String get personalizeAttachSheet => 'EKLE LEVHASI (NOTUN İÇİNDE +)';

  @override
  String get personalizeVideo => 'VİDEO';

  @override
  String get personalizeHome => 'ANA EKRAN';

  @override
  String get personalizeHomeItemsInfo =>
      'Seçili olanlar ana ekranda görünür; düzenleme modunda ana ekrandaki öğelere dokunarak da gizleyebilirsiniz.';

  @override
  String get personalizeBubbles => 'BALONLAR';

  @override
  String get personalizeChipsInfo =>
      'Seçili olanlar görünür; dokunarak açıp kapatın.';

  @override
  String get personalizeReset => 'Varsayılana dön';

  @override
  String get personalizeResetConfirm =>
      'Bütün görünürlük ve sarma ayarları varsayılana dönsün mü?';

  @override
  String get personalizeResetDone => 'Varsayılana dönüldü';

  @override
  String get uiItemAttachments => 'Ekler';

  @override
  String get uiItemDate => 'Düzenleme tarihi';

  @override
  String get uiItemSync => 'Senkron simgesi';

  @override
  String get uiItemVideoTime => 'Süre yazısı';

  @override
  String get videoSeekBack => 'Geri sarma';

  @override
  String get videoSeekForward => 'İleri sarma';

  @override
  String get bubbleSizeSetting => 'Balon boyu';

  @override
  String get noteMenuCustomize => 'Ekranı düzenle';

  @override
  String secondsShort(int seconds) {
    return '$seconds sn';
  }

  @override
  String personalizeHiddenSummary(int count) {
    return '$count gizli';
  }

  @override
  String get uiItemVideoBadge => 'VİDEO';

  @override
  String get listPartRemoved => 'Liste kaldırıldı';

  @override
  String get textPartRemoved => 'Metin kaldırıldı';

  @override
  String get notePartsMenu => 'Bölümler';

  @override
  String get removeListPart => 'Listeyi kaldır';

  @override
  String get removeTextPart => 'Metni kaldır';

  @override
  String get transcriptTitle => 'Transkript';

  @override
  String get transcriptAction => 'Metne dök';

  @override
  String get transcriptFileSuffix => 'transkript';

  @override
  String get transcriptWorkingAudio => 'Ses metne dökülüyor…';

  @override
  String get transcriptWorkingVideo => 'Video metne dökülüyor…';

  @override
  String get transcriptWorkingImage => 'Görseldeki yazı okunuyor…';

  @override
  String get transcriptLongHint =>
      'Uzun kayıtlarda birkaç dakika sürebilir; bu ekranı açık tut.';

  @override
  String get transcriptSaved => 'Nota metin eki olarak kaydedildi';

  @override
  String get transcriptInsertSelection => 'Seçimi nota ekle';

  @override
  String get transcriptInsertAll => 'Tümünü nota ekle';

  @override
  String get transcriptInserted => 'Nota eklendi';

  @override
  String get transcriptNewNote => 'Yeni not';

  @override
  String get transcriptRetryAi => 'AI ile yeniden dök';

  @override
  String get transcriptReadWithAi => 'AI ile oku (el yazısı)';

  @override
  String get transcriptShowTimes => 'Zaman damgaları';

  @override
  String get transcriptDelete => 'Transkripti sil';

  @override
  String get transcriptDeleteConfirm =>
      'Transkript silinsin mi? Kaynak dosya notta kalır.';

  @override
  String get transcriptEmpty => 'Metin bulunamadı.';

  @override
  String transcriptTooLarge(int mb) {
    return 'Kayıt $mb MB; dahili yapay zekâ en çok 15 MB alabiliyor. Ayarlar\'dan kendi Gemini anahtarını girersen büyük kayıtlar da dökülür.';
  }

  @override
  String transcriptUnsupported(String format) {
    return 'Bu kayıt biçimi ($format) metne dökülemiyor.';
  }

  @override
  String get transcriptEdit => 'Düzenle';

  @override
  String get transcriptSave => 'Kaydet';

  @override
  String transcriptWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sözcük',
      one: '1 sözcük',
    );
    return '$_temp0';
  }

  @override
  String transcriptNoteTitle(String name) {
    return 'Transkript: $name';
  }

  @override
  String get transcriptOnDevice =>
      'Cihazda okundu · internet ve AI puanı harcanmadı';

  @override
  String get addAudioFile => 'Ses dosyası ekle';

  @override
  String get transcribeFile => 'Dosyayı metne dök';

  @override
  String get transcribeFileSubtitle =>
      'Ses, video ya da görsel seç; metni nota yazılır';

  @override
  String cardTranscriptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transkript',
      one: 'Transkript',
    );
    return '$_temp0';
  }

  @override
  String get transcriptPickTitle => 'Metne dökülecek dosya';

  @override
  String get transcriptUnsupportedFile =>
      'Bu dosya türü metne dökülemiyor (ses, video ya da görsel seç).';

  @override
  String get pickPdfTitle => 'PDF seç';

  @override
  String get pickSlidesTitle => 'Sunum seç';

  @override
  String get pickImagesTitle => 'Görsel seç';

  @override
  String get pickDocumentTitle => 'Belge seç';

  @override
  String get fileAppPickerTitle => 'Dosyaları Dosya Okuyucu ile seç';

  @override
  String get fileAppPickerInfo =>
      'Dosya eklerken doğrudan Dosya Okuyucu açılır ve yalnız istenen türün dosyaları (en yenisi üstte) listelenir. Kapalıyken uygulama seçimi sorulur.';

  @override
  String get viewModeAttached => 'Ek';

  @override
  String get viewModeAttachedHint => 'Ek olarak — alttaki ek şeridinde durur';

  @override
  String get textToBubblesPreparing => 'Metin belgeye diziliyor…';

  @override
  String get attachmentActions => 'Ek işlemleri';

  @override
  String get attachmentOpen => 'Aç';

  @override
  String get attachmentViewTitle => 'Nerede dursun?';

  @override
  String get attachmentUploadQueued => 'Yüklenmeyi bekliyor';

  @override
  String get attachmentWaitingOwner =>
      'Ekleyenin cihazından yüklenmesi bekleniyor';

  @override
  String attachmentsUploadingCount(int count) {
    return '$count ek yükleniyor';
  }

  @override
  String get sharedNoteNew => 'Yeni';

  @override
  String sharedNoteUpdatedBy(String name) {
    return '$name güncelledi';
  }

  @override
  String get sharedMarkAllRead => 'Tümünü okundu say';

  @override
  String get attachmentSaveAs => 'Farklı kaydet';

  @override
  String attachmentSavedAs(String name) {
    return '$name kaydedildi';
  }

  @override
  String get attachmentSaveAsFailed => 'Dosya kaydedilemedi';

  @override
  String get sharedHubTitle => 'Gelen ve paylaşılanlar';

  @override
  String get sharedHubInbox => 'Gelen';

  @override
  String get voiceAutoStop => 'Sessizlikte bitir';

  @override
  String get voiceAutoStopInfo =>
      'Konuşman bitince birkaç saniyelik sessizlikten sonra dinleme kendiliğinden biter.';

  @override
  String get voiceSmartCommands => 'Akıllı komutlar';

  @override
  String get voiceSmartCommandsInfo =>
      'Konuşurken şunları diyebilirsin: “son kelimeyi sil”, “son iki kelimeyi sil”, “son cümleyi sil”, “X yerine Y yaz”, “son kelime Y olacak”, “yeni satır”, “yeni madde”, “nokta koy”, “virgül koy”, “soru işareti”, “başlık X olsun”, “geri al”, “hepsini sil”, “dinlemeyi bitir”. Yazmaya kaldığın yerden, en sondan devam eder.';

  @override
  String get voiceAutoStopSoon => 'Sessizlik — birazdan biter';

  @override
  String get voiceCmdDeleted => 'Silindi';

  @override
  String get voiceCmdReplaced => 'Değiştirildi';

  @override
  String get voiceCmdNewLine => 'Yeni satır';

  @override
  String get voiceCmdUndone => 'Geri alındı';

  @override
  String get voiceCmdCleared => 'Temizlendi';

  @override
  String get fullscreenExit => 'Tam ekrandan çık';

  @override
  String get voiceCaptureContinue => 'Devam et';

  @override
  String get voiceCmdPunctuation => 'Noktalama eklendi';

  @override
  String get voiceCmdTitle => 'Başlık ayarlandı';

  @override
  String get voiceSilenceLabel => 'Bekleme süresi';

  @override
  String get voiceSilenceShort => 'Kısa';

  @override
  String get voiceSilenceNormal => 'Normal';

  @override
  String get voiceSilenceLong => 'Uzun';

  @override
  String get voiceOffline => 'İnternetsiz tanıma';

  @override
  String get voiceOfflineInfo =>
      'Telefonda dil paketi indirilmişse sesin internete gitmeden yazıya döker. Paket yoksa kendiliğinden çevrimiçi tanımaya döner.';

  @override
  String get discoverable => 'Adımla bulunabilirim';

  @override
  String get discoverableInfo =>
      'Açıkken başkaları seni adının ilk 3 harfiyle ya da tam e-postanla \"Kişi ara\"da bulabilir. Kapalıyken yalnız e-postanı bilen biri istek gönderebilir.';

  @override
  String get friendsSearchNeedsGoogle =>
      'Kişi aramak için Google hesabıyla giriş yap.';

  @override
  String get friendsSearchRateLimited =>
      'Çok fazla arama yaptın, bir dakika sonra tekrar dene.';

  @override
  String get updateRequiredBody =>
      'Bu sürüm eski: notlar salt okunur açılıyor. Verilerin bozulmasın diye uygulamayı güncelle.';

  @override
  String get updateAction => 'Güncelle';

  @override
  String get attachmentUnsupportedTitle => 'Bu ek için uygulamayı güncelle';

  @override
  String get attachmentUnsupportedBody =>
      'Bu ek uygulamanın daha yeni bir sürümünde eklendi. Bu sürüm onu gösteremiyor; ek korunuyor, silinmiyor.';

  @override
  String noteTooLarge(String size, String part) {
    return 'Not çok büyüdü ($size / 1024 KB) — en büyük kısım: $part. Bir kısmını ayrı bir nota taşı, yoksa kaydedilemeyebilir.';
  }

  @override
  String get noteSizeBody => 'metin';

  @override
  String get noteSizeItems => 'maddeler';

  @override
  String get noteSizePageNotes => 'sayfa notları';

  @override
  String noteSaveRejected(String reason) {
    return 'Not sunucuya kaydedilemedi: $reason';
  }

  @override
  String get errorLogShare => 'Hata günlüğünü paylaş';

  @override
  String get errorLogInfo =>
      'Son hatalar yalnız bu cihazda tutulur; sen paylaşmadıkça hiçbir yere gitmez.';

  @override
  String get errorLogEmpty => 'Kayıtlı hata yok.';

  @override
  String get crashReports => 'Çökme raporlarını gönder';

  @override
  String get crashReportsInfo =>
      'Uygulama çökünce not içeriği olmadan teknik bir rapor Firebase Crashlytics\'e gider (yalnız Android).';

  @override
  String get noteTooLargeShort => 'not 1 MiB sınırını aştı';

  @override
  String get crashTestTitle => 'Test çökmesi gönderilsin mi?';

  @override
  String get crashTestBody =>
      'Crashlytics kurulumunu doğrulamak için uygulama hemen kapanır. Yeniden açtığında rapor Firebase konsoluna gider (birkaç dakika sürebilir).';

  @override
  String get crashTestAction => 'Çökert';

  @override
  String get captureModeSetting => 'İçerikten not açılışı';

  @override
  String get captureModeSettingInfo =>
      'Fotoğraf, tarama, PDF, sunum ve görselden not alırken. İlk seçimin varsayılan olur.';

  @override
  String get captureModeAsk => 'Her seferinde sor';

  @override
  String get voiceMicDictate => 'Doğrudan yazdır';

  @override
  String get voiceMicTooltipAi =>
      'Sesli not (AI düzenlesin) — basılı tut: doğrudan yazdır';

  @override
  String get voiceMicTooltipDictate =>
      'Sesle yazdır — basılı tut: AI düzenlesin';

  @override
  String get quickAddCamera => 'Kamera';

  @override
  String get quickAddFile => 'Dosya ekle';

  @override
  String get quickAddFromDevice => 'Cihazdan dosya seç';

  @override
  String get quickAddTemplates => 'Şablon';

  @override
  String get quickAddFileWhat => 'Bu dosyayla ne yapalım?';

  @override
  String get quickAddFileAsNote => 'Notuna ekle';

  @override
  String get quickAddFileUnsupported => 'Bu dosya türü desteklenmiyor';

  @override
  String get chatScopeAll => 'Tüm notlar';

  @override
  String get chatScopeNote => 'Bu not';

  @override
  String get chatScopeDoc => 'Bu belge';

  @override
  String get chatModeQa => 'Soru-cevap';

  @override
  String get chatModeBrainstorm => 'Beyin fırtınası';

  @override
  String get aiChatRowTitle => 'Sohbet';

  @override
  String get aiChatRowInfo =>
      'Bu notla, belgesiyle ya da tüm notlarla; soru-cevap ya da beyin fırtınası';

  @override
  String get shareFolderTogether => 'Klasörü birlikte düzenle';

  @override
  String get shareTogetherSection => 'BİRLİKTE DÜZENLE';

  @override
  String get shareTogetherInfo =>
      'Aynı notu/klasörü siz ikiniz görür ve değiştirirsiniz';

  @override
  String get shareCopySection => 'KOPYA GÖNDER';

  @override
  String get shareCopyInfo =>
      'Arkadaşının gelen kutusuna bağımsız bir kopya gider';

  @override
  String get noteColorAccent => 'Kenarı vurgula';

  @override
  String get notebookViewOn => 'Defter görünümü';

  @override
  String get notebookViewOff => 'Defter görünümünü kapat';

  @override
  String inkSemantics(int count) {
    return 'Elle çizim, $count çizgi';
  }

  @override
  String bubbleSemantics(String text) {
    return 'Not balonu: $text';
  }

  @override
  String get bubbleSemanticsEmpty => 'Boş not balonu';
}
