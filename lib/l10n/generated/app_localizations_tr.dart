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
  String get titleHint => 'Başlık';

  @override
  String get bodyHint => 'Not...';

  @override
  String get newItemHint => 'Yeni öğe';

  @override
  String checkedItemsCount(int count) {
    return 'İşaretlenenler ($count)';
  }

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
  String get attachmentUploading => 'Yükleniyor...';

  @override
  String get attachmentNotSynced => 'Dosya bu cihaza henüz senkronlanmadı';

  @override
  String attachmentTooLarge(int limit) {
    return 'Dosya çok büyük (en fazla $limit MB)';
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
  String get aiSuggestions => 'Öneriler';

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
    return 'Dahili AI: Premium — bugün kalan hak $count';
  }

  @override
  String aiBuiltInRemaining(int count) {
    return 'Dahili AI: bugün kalan ücretsiz hak $count';
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
  String get apiKeyValid => 'API anahtarı doğrulandı ve kaydedildi';

  @override
  String get apiKeyInvalid => 'API anahtarı geçersiz';

  @override
  String get apiKeySavedBadge => 'Kayıtlı';

  @override
  String get removeApiKey => 'Anahtarı sil';

  @override
  String get settingsGmail => 'Gmail';

  @override
  String get connectGmail => 'Gmail\'i Bağla';

  @override
  String get gmailConnected => 'Gmail bağlı';

  @override
  String get gmailChangeAccount => 'Hesap değiştir';

  @override
  String get gmailInfo =>
      'Yapay zeka, gelen kutundaki son e-postaları tarayıp önemli olanları kısaca özetler. E-posta içeriği hiçbir yere kaydedilmez.';

  @override
  String get disconnectGmail => 'Bağlantıyı kes';

  @override
  String get importantEmails => 'Önemli E-postalar';

  @override
  String get refresh => 'Yenile';

  @override
  String get account => 'Hesap';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get signOutConfirm => 'Çıkış yapmak istediğine emin misin?';

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
  String get mailEmpty => 'Önemli e-posta bulunamadı';

  @override
  String get mailScanning => 'E-postalar taranıyor...';

  @override
  String mailWhyImportant(String reason) {
    return 'Neden önemli: $reason';
  }

  @override
  String get suggestionsTitle => 'Öneriler';

  @override
  String get suggestionsEmpty => 'Öneri üretebilmek için birkaç not ekle';

  @override
  String get suggestionsIntro => 'Notlarına göre öneriler';

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
  String get chatTitle => 'Notlarla Sohbet';

  @override
  String get chatHint =>
      'Notların hakkında soru sor: \"geçen hafta yazdığım tarif neydi?\", \"alışveriş listemde ne eksik?\"';

  @override
  String get chatInputHint => 'Bir soru yaz...';

  @override
  String get weeklySummary => 'Haftalık Özet';

  @override
  String get weeklySummaryEmpty => 'Son 7 günde not eklenmemiş';

  @override
  String get weeklySummaryIntro => 'Son 7 günün özeti';

  @override
  String get fontSize => 'Yazı boyutu';

  @override
  String get darkSchedule => 'Koyu tema zamanlaması';

  @override
  String get darkScheduleInfo =>
      'Belirlediğin saatler arasında koyu temaya geçilir';

  @override
  String get convertToNote => 'Nota çevir';

  @override
  String get convertToReminderNote => 'Hatırlatıcılı not';

  @override
  String get noteCreatedFromEmail => 'E-postadan not oluşturuldu';

  @override
  String mailDueDate(String date) {
    return 'Son tarih: $date';
  }

  @override
  String get translatorTitle => 'Çevirmen';

  @override
  String get aiTranslate => 'Çevir';

  @override
  String get swapLanguages => 'Dilleri değiştir';

  @override
  String get liveMode => 'Canlı';

  @override
  String get pushToTalkMode => 'Bas-Konuş';

  @override
  String get liveTranslateInfo =>
      'Gemini 3.5 Live Translate ile kesintisiz çeviri: başlatın ve konuşun; hangi dilde konuşulduğu otomatik algılanır, karşı dile hem sesli hem yazılı çevrilir.';

  @override
  String get startLive => 'Canlı çeviriyi başlat';

  @override
  String get stopLive => 'Durdur';

  @override
  String get connecting => 'Bağlanıyor...';

  @override
  String get heardLabel => 'Duyulan';

  @override
  String get translationLabel => 'Çeviri';

  @override
  String liveTranslateError(String error) {
    return 'Canlı çeviri hatası: $error';
  }

  @override
  String get pushToTalk => 'Konuşmak için dokun';

  @override
  String get pushToTalkHint =>
      'Mikrofona dokunup konuş; hangi dilde konuştuğun otomatik algılanır ve karşı dile çevrilir. Karşındaki de aynı düğmeyle kendi dilinde yanıt verebilir.';

  @override
  String get autoSpeak => 'Çeviriyi sesli oku';

  @override
  String get speakTranslation => 'Sesli oku';

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
  String get voiceNoteTitle => 'Sesli Not';

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
  String get aiModelDocument => 'Podcast ve belge sohbeti';

  @override
  String get aiModelTranslate => 'Çeviri';

  @override
  String get aiModelVoice => 'Sesli not';

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
  String get aiScanEmails => 'E-postaları tara';

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
  String get permissionsTitle => 'İzinler';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo => 'Sesli not, dikte ve canlı çeviri için gerekli';

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
  String get voiceCaptureActive => 'Ses kaydediliyor, konuşman nota yazılıyor…';

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
  String get speechVoice => 'Ses tipi';

  @override
  String get speechVoiceSubtitle => 'Sesli okumada kullanilacak ses';

  @override
  String get speechRate => 'Okuma hizi';

  @override
  String get speechSystemDefault => 'Sistem varsayilani';

  @override
  String get speechNoVoices => 'Bu cihazda yuklu ses bulunamadi';

  @override
  String get aiSummarySpeak => 'Ozeti sesli oku';

  @override
  String get speechVoiceTurkish => 'Türkçe ses';

  @override
  String get speechVoiceEnglish => 'İngilizce ses';

  @override
  String get speechVoiceAutoInfo =>
      'Diğer diller otomatik olarak erkek sesiyle okunur';

  @override
  String get nothingHeard => 'Konuşma algılanmadı';

  @override
  String get listening => 'Dinleniyor...';

  @override
  String get translateDownloadingModel => 'Dil modeli indiriliyor (bir kez)...';

  @override
  String get translateQuality => 'Gemini ile çevir (daha iyi kalite)';

  @override
  String get translateQualityInfo =>
      'Kapalıyken çeviri cihazda yapılır: bedava, çevrimdışı ve kota harcamaz. Açıkken Gemini kullanılır — deyim ve uzun cümlede daha iyi, ama kota harcar. ML Kit\'in desteklemediği dillerde (ör. Azerbaycanca) bu ayar ne olursa olsun Gemini kullanılır.';

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
  String get settingsSpeech => 'Sesli okuma';

  @override
  String get settingsTranslate => 'Çeviri';

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
  String get hubTranslateInfo => 'Metin ve konuşma çevirisi';

  @override
  String get hubSuggestionsInfo => 'Notlarından çıkarılmış somut öneriler';

  @override
  String get hubMailInfo => 'Gelen kutundaki önemli e-postalar';

  @override
  String get hubBriefingInfo => 'Güne bakış: notlar ve e-postalar';

  @override
  String get hubReadInfo => 'PDF/Word belgesini sesli dinle';

  @override
  String get annotate => 'Üzerine yaz';

  @override
  String get annotateDone => 'Yazmayı bitir';

  @override
  String get pen => 'Kalem';

  @override
  String get eraser => 'Silgi';

  @override
  String get clearInk => 'Çizimleri temizle';

  @override
  String get inkTwoFingerHint =>
      'Tek parmak çizer · iki parmakla kaydır ve yakınlaştır';

  @override
  String get slideOpenFailed => 'Sunum açılamadı';
}
