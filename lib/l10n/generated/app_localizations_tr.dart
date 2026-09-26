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
  String get filterStarred => 'Yıldızlı';

  @override
  String get star => 'Yıldızla';

  @override
  String get unstar => 'Yıldızı kaldır';

  @override
  String editedAt(String date) {
    return 'Düzenlendi: $date';
  }

  @override
  String get sectionPinned => 'Sabitlenmiş';

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
  String get addAttachmentMore => 'Diğer ek türleri…';

  @override
  String get addImage => 'Görsel ekle';

  @override
  String get addPdf => 'PDF ekle';

  @override
  String get addSlide => 'Slayt ekle';

  @override
  String get pasteImage => 'Panodan görsel yapıştır';

  @override
  String get clipboardEmpty => 'Panoda görsel yok';

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
  String get geminiApiKey => 'Gemini API Anahtarı';

  @override
  String get geminiApiKeyHint => 'AIza... ile başlayan anahtarı yapıştır';

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
  String placeActive(String place, String trigger) {
    return '$place · $trigger';
  }

  @override
  String get placeSection => 'Konum';

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
  String get speechRecognitionFailed =>
      'Konuşma tanıma çalışmadı. Mikrofon izninin verildiğinden ve Google uygulamasının güncel olduğundan emin ol.';

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
  String get voiceCaptureHint =>
      'Konuş: \"süt ve ekmek al\" ya da \"yarın 9\'da toplantı, hatırlat\" — bitince notunu yapay zeka oluşturur.';

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
  String get dictationNoKeyInfo =>
      'Bu cihazda anlık yazdırma yok; kayıt bitince tek seferde yazıya dökülecek.';

  @override
  String get dictationHoldHint =>
      'Mikrofonu basılı tutup konuşun, bırakınca yazılır';

  @override
  String itemsSelected(int count) {
    return '$count madde seçildi';
  }

  @override
  String get noteChatTitle => 'Bu notla sohbet et';

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
  String get voiceHoldHint =>
      'Basılı tutarak konuş; bırakınca notun oluşturulur';

  @override
  String get voiceTapHint => 'Dokun ve konuş; bitirmek için tekrar dokun';

  @override
  String get voiceTooShort => 'Kayıt çok kısaydı, tekrar dene';

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
  String get voiceHeardLive => 'Algılanan konuşma';

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
  String get voiceChipCompose => 'Asistan oluştursun';

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
  String get showTagChips => 'Etiket çiplerini göster';

  @override
  String get showFolderChips => 'Klasör çiplerini göster';

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
  String get newVideoNote => 'Görüntülü not';

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
  String get editFilters => 'Filtreleri düzenle';

  @override
  String get editFiltersInfo =>
      'Ana ekranda görünmesini istediğin filtreleri seç. Kapalı filtreler sayfayı sade tutar.';

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
  String get speechSystemDefault => 'Sistem varsayilani';

  @override
  String get speechNoVoices => 'Bu cihazda yuklu ses bulunamadi';

  @override
  String speechVoiceLanguage(String language) {
    return '$language sesi';
  }

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
  String get backgroundColor => 'Zemin rengi';

  @override
  String get backgroundColorInfo => 'Notun arka plan rengi';

  @override
  String get frameColor => 'Çerçeve';

  @override
  String get frameColorInfo =>
      'Notun çevresine seçtiğin renkte bir çerçeve çizilir';

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
  String get foldersSection => 'Klasörler';

  @override
  String get tagsSection => 'Etiketler';

  @override
  String get expandFilters => 'Filtreleri genişlet';

  @override
  String get collapseFilters => 'Filtreleri daralt';

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
  String get backupTitle => 'Yedek';

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
  String get voiceAssistantBadge => 'Asistan';

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
  String get hubChatInfo => 'Notlarına dayanarak soru-cevap';

  @override
  String get hubBriefingInfo => 'Güne bakış: hatırlatıcılar ve son notlar';

  @override
  String get hubReadInfo => 'PDF/Word belgesini sesli dinle';

  @override
  String get annotate => 'Üzerine yaz';

  @override
  String get annotateDone => 'Yazmayı bitir';

  @override
  String get newPdfNote => 'PDF ekle not al';

  @override
  String get imageNotePreparing => 'Görseller belgeye diziliyor…';

  @override
  String get newImageNote => 'Görsel ekle not al';

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
  String get newPhotoNote => 'Foto çek not al';

  @override
  String get newScanNote => 'Belge tara not al';

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
  String attachmentsCount(int count) {
    return 'Ekler ($count)';
  }

  @override
  String get hideAttachments => 'Gizle';

  @override
  String get showAttachments => 'Göster';

  @override
  String get videoBack10 => '10 sn geri';

  @override
  String get videoForward10 => '10 sn ileri';

  @override
  String get selectAllItems => 'Tümünü seç';

  @override
  String get showAllChips => 'Tümünü göster';

  @override
  String get hideAllChips => 'Tümünü gizle';

  @override
  String get chipPickInfo =>
      'Hangi klasör ve etiketlerin çipi ana ekranda görünsün?';

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
  String get moveImageToPage => 'Sayfaya koy';

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
  String get aiRecentOps => 'SON İŞLEMLER';

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
  String get quickAddWrite => 'YAZ';

  @override
  String get quickAddCapture => 'YAKALA — İÇERİKTEN NOT OLUŞTURUR';

  @override
  String get viewToggle => 'Görünüm';

  @override
  String get searchModeText => 'Metin';

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
      'Yapay zekâ sesi kendi Gemini anahtarını ister. Anahtar eklenene kadar okuma cihaz sesiyle yapılır.';

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
  String get shareAsText => 'Düz metin olarak';

  @override
  String get shareAsTextInfo =>
      'Notun yazısını ve sayfa notlarını herhangi bir uygulamaya gönderir.';

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
  String imageOcrHint(int count) {
    return '$count satır tanındı · dokunarak seç';
  }

  @override
  String imageOcrSelected(int count) {
    return '$count satır seçildi';
  }

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
  String get shareAsFileSection => 'Dosya olarak';

  @override
  String get shareInAppSection => 'Uygulama içinde';

  @override
  String get shareSendFriendInfo =>
      'Notun bir kopyasını arkadaşının gelen kutusuna bırakır.';

  @override
  String get shareCollaborateInfo =>
      'Arkadaşlarınla aynı notu birlikte düzenle; değişiklikler anında görünür.';

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
}
