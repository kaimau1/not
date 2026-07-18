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
  String get quickAddHint => 'Not al...';

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
  String get newChecklist => 'Alışveriş listesi';

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
  String get pasteImage => 'Panodan görsel yapıştır';

  @override
  String get clipboardEmpty => 'Panoda görsel yok';

  @override
  String get attachmentUploading => 'Yükleniyor...';

  @override
  String get attachmentNotSynced => 'Dosya bu cihaza henüz senkronlanmadı';

  @override
  String get attachmentTooLarge => 'Dosya çok büyük (en fazla 25 MB)';

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
  String get colorDefault => 'Varsayılan';

  @override
  String get aiTitle => 'Yapay Zeka';

  @override
  String get aiSummarize => 'Notu özetle';

  @override
  String get aiAnalyze => 'Analiz et';

  @override
  String aiSummarizePdf(String name) {
    return 'PDF\'i özetle: $name';
  }

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
      'Anahtar girmek isteğe bağlıdır: girmezsen AI istekleri uygulamanın dahili altyapısından yapılır (günlük ücretsiz hak, Premium ile sınırsız). Kendi anahtarınla sınırsız kullanım için aistudio.google.com adresinden ücretsiz anahtar alabilirsin; anahtar yalnızca bu cihazda güvenli depoda saklanır.';

  @override
  String get aiBuiltInPremium => 'Dahili AI: Premium etkin — sınırsız kullanım';

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
  String get noteNotFound => 'Not bulunamadı';

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
  String get addDrawing => 'Çizim ekle';

  @override
  String get drawingTitle => 'Çizim';

  @override
  String get addToNote => 'Nota ekle';

  @override
  String aiExtractImageText(String name) {
    return 'Görseldeki metni çıkar: $name';
  }

  @override
  String aiTranscribeAudio(String name) {
    return 'Yazıya dök: $name';
  }

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
  String get autoTitleSetting => 'Otomatik başlık';

  @override
  String get autoTitleSettingInfo =>
      'Not kapanırken başlığı yoksa yapay zeka hızlı bir modelle kısa bir başlık üretir';

  @override
  String get suggestTags => 'Etiket öner';

  @override
  String get aiFixNote => 'Notu düzelt (yazım + düzen)';

  @override
  String get aiImprove => 'Notu geliştir';

  @override
  String get improveFix => 'Yazımı ve dilbilgisini düzelt';

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
  String aiAskPdf(String name) {
    return 'PDF\'e soru sor: $name';
  }

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
  String get voiceProcessing => 'Dinlediklerim nota dönüştürülüyor...';

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
  String get aiModelChat => 'Sohbet ve AI özellikleri';

  @override
  String get aiModelVoice => 'Sesli not';

  @override
  String get aiModelAuto => 'Otomatik (önerilen)';

  @override
  String get aiModelsInfo =>
      'Liste Google\'dan canlı çekilir. Seçtiğin model kota doldurur veya kaldırılırsa sıradaki otomatik denenir.';

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
      'Canlı döküm için Ayarlar\'dan Gemini API anahtarı girebilirsin; şimdilik kayıt bitince tek seferde yazıya dökülecek.';

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
  String get voiceHoldHint => 'Basılı tutarak konuş; bırakınca notun oluşturulur';

  @override
  String get voiceTapHint => 'Dokun ve konuş; bitirmek için tekrar dokun';

  @override
  String get voiceTapToFinish => 'Bitirmek için dokun';

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
}
