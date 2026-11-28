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
  String get searchHint => 'Ara...';

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
  String get emptyNotes => 'Burada henüz not yok';

  @override
  String get emptyFilter => 'Burada bu süzgece uyan not yok';

  @override
  String get clearFilter => 'Süzgeci kaldır';

  @override
  String get emptyFolderTitle => 'Burada henüz not yok';

  @override
  String get newNoteAction => 'Not ekle';

  @override
  String get emptySearch => 'Burada aramana uyan not yok';

  @override
  String get newTextNote => 'Metin notu';

  @override
  String get newChecklist => 'Liste';

  @override
  String get newOrderedList => 'Sıralı liste';

  @override
  String get noteDeleted => 'Not silindi';

  @override
  String get dragTrashHint => 'Çöpe atmak için buraya bırak';

  @override
  String get dragTrashReady => 'Bırak: çöpe at';

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
  String get undo => 'Geri al';

  @override
  String get redo => 'Geri getir';

  @override
  String get titleHint => 'Başlık';

  @override
  String get bodyHint => 'Not...';

  @override
  String get newItemHint => 'Yeni madde';

  @override
  String moreItemsCount(int count) {
    return '+$count madde daha';
  }

  @override
  String get addAttachment => 'Ekle';

  @override
  String get addImage => 'Görsel ekle';

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
  String get attachmentDeviceOnly =>
      'Büyük dosya: yalnız bu cihazda duruyor, buluta yedeklenmez';

  @override
  String get attachmentOtherDevice =>
      'Bu büyük dosya yalnız eklendiği cihazda; buraya indirilmez';

  @override
  String get attachmentDeviceFull =>
      'Cihazda yer kalmadı; dosya kopyalanamadı. Biraz yer açıp yeniden dene.';

  @override
  String get webDriveTapToOpen => 'Google Drive\'da · açmak için dokun';

  @override
  String get noteFullscreen => 'Tam ekran';

  @override
  String get noteFullscreenExit => 'Tam ekrandan çık';

  @override
  String get penModeDone => 'Kalemi kapat';

  @override
  String get pageInkOnCard => 'El yazısı var';

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
  String get unpin => 'Sabitten çıkar';

  @override
  String get delete => 'Sil';

  @override
  String get color => 'Renk';

  @override
  String get summarize => 'Özetle';

  @override
  String get listen => 'Sesli dinle';

  @override
  String get ask => 'Soru sor';

  @override
  String get extractText => 'Metni çıkar';

  @override
  String get transcribe => 'Yazıya dök';

  @override
  String get listenToNote => 'Sesli dinle';

  @override
  String aiError(String error) {
    return 'Yapay zekâ isteği başarısız: $error';
  }

  @override
  String get aiThinking => 'Düşünüyor...';

  @override
  String get copy => 'Kopyala';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get settingsSearchHint => 'Ayar ara — “kilit”, “mikrofon”';

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
  String get themeSage => 'Adaçayı';

  @override
  String get themePorcelain => 'Porselen';

  @override
  String get themeClay => 'Kil';

  @override
  String get themeDark => 'Koyu';

  @override
  String get privacyPolicyTitle => 'Gizlilik politikası';

  @override
  String get lockNote => 'Kilitle';

  @override
  String get unlockNote => 'Kilidi kaldır';

  @override
  String get lockedNote => 'Kilitli not';

  @override
  String get unlockAuthReason => 'Kilitli notu açmak için kimliğini doğrula';

  @override
  String get exportBackup => 'Tam yedek al';

  @override
  String get expandListItems => 'Liste satırlarını tam göster';

  @override
  String get expandListItemsInfo =>
      'Uzun maddeler sarılıp tamamen görünür; kapalıyken tek satır.';

  @override
  String get quickCaptureRowSetting => 'Hızlı not satırı';

  @override
  String get quickCaptureRowInfo =>
      'Ana ekranın üstünde tek satırlık “Yeni not…” alanı.';

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
  String get signOut => 'Oturumu kapat';

  @override
  String get switchAccount => 'Hesap değiştir';

  @override
  String get switchAccountConfirm =>
      'Bu hesaptan çıkılıp Google hesap seçici açılacak. Notların bu hesapta kalır, geri döndüğünde yine burada olur.';

  @override
  String get switchAccountGuestWarning =>
      'Misafir hesaptasın: hesap değiştirirsen bu cihazdaki notlara bir daha ulaşamazsın. Önce Google hesabına bağla ya da tam yedek al.';

  @override
  String get penTrayShow => 'Kalem tepsisini aç';

  @override
  String get addDrawingSubtitle =>
      'Ayrı tuvalde çiz, görsel olarak nota gömülsün';

  @override
  String get addGroupWrite => 'Yaz';

  @override
  String get addGroupPen => 'Kalem';

  @override
  String get addGroupFiles => 'Dosya ve bağlantı';

  @override
  String get addGroupSound => 'Ses';

  @override
  String get addGroupTemplate => 'Şablon';

  @override
  String get addSeparateDrawing => 'Ayrı çizim (görsel)';

  @override
  String get addHandwriting => 'Sayfaya yaz (kalem)';

  @override
  String get addHandwritingSubtitle =>
      'Kalem kipi: notun sayfasına doğrudan yaz';

  @override
  String webDriveBanner(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek Google Drive’ında — görmek için izin ver',
      one: '1 ek Google Drive’ında — görmek için izin ver',
    );
    return '$_temp0';
  }

  @override
  String get webDriveShow => 'Göster';

  @override
  String webAttachmentsOnPhone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ek henüz eklendiği telefondan buluta çıkmadı. Telefonda Ayarlar → Senkron → Drive’ı bağla.',
      one: '1 ek henüz eklendiği telefondan buluta çıkmadı. Telefonda Ayarlar → Senkron → Drive’ı bağla.',
    );
    return '$_temp0';
  }

  @override
  String get fullscreenPullHint => 'Tam ekran için çek';

  @override
  String get fullscreenPullRelease => 'Bırak: tam ekran';

  @override
  String get signOutConfirm => 'Çıkış yapmak istediğine emin misin?';

  @override
  String get signOutAnonymousWarning =>
      'Yerel hesaptasın: çıkış yaparsan bu hesaba ve tüm notlarına bir daha erişilemez — yedeğin yoksa geri getirilemezler. Notlarını korumak için önce Google hesabı bağla. Yine de çıkış yapılsın mı?';

  @override
  String get deleteAccount => 'Hesabımı ve verilerimi sil';

  @override
  String get deleteAccountWarning =>
      'Bu işlem geri alınamaz: tüm notların, eklerin ve hesabın kalıcı olarak silinir. Devam etmek istediğine emin misin?';

  @override
  String get deleteAccountConfirm => 'Kalıcı olarak sil';

  @override
  String get deleteAccountPageInfo =>
      'Hesabın ve bütün verilerin kalıcı olarak silinir: notlar, klasörler, ekler (bulut ve bağlıysa Drive), kişiler, gelen notlar, paylaştığın klasörler ve hesap kaydı. Başkasına gönderdiğin notların kopyaları onlarda kalır. Bu işlem geri alınamaz; istersen önce Ayarlar\'dan yedek al.';

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
  String get liteSyncHeld =>
      'Değişiklikler birkaç dakikada bir buluta gider — şimdi eşitlemek için dokun';

  @override
  String get liteSyncSending => 'Değişiklikler buluta gönderiliyor';

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
  String get archiveEmpty => 'Burada arşivlenmiş not yok';

  @override
  String get trashTitle => 'Çöp kutusu';

  @override
  String get trashEmpty => 'Burada silinmiş not yok';

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
  String get addToNote => 'Nota ekle';

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
  String get voiceCommand => 'Sesli komut';

  @override
  String get suggestTags => 'Etiket öner';

  @override
  String get existingTagsLabel => 'Önceki etiketler';

  @override
  String get voiceFinish => 'Bitir';

  @override
  String get voiceProcessing => 'Söylediklerin uygulanıyor...';

  @override
  String get voiceNothingHeard => 'Kayıtta konuşma algılanamadı';

  @override
  String get voiceNoteSaved => 'Sesli notun kaydedildi';

  @override
  String get openNote => 'Notu aç';

  @override
  String get remindersTitle => 'Hatırlatıcılar';

  @override
  String get remindersEmpty => 'Burada hatırlatıcı yok';

  @override
  String get remindersEmptyHint =>
      'Bir nota hatırlatıcı ekle ya da + ile hatırlatıcılı yeni bir not yaz.';

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
  String get clearNote => 'İçeriği temizle';

  @override
  String get clearNoteConfirm =>
      'Notun içeriği (metin ve liste maddeleri) silinecek. Emin misin?';

  @override
  String get calculatorTitle => 'Hesap makinesi';

  @override
  String get calcExpressionHint => 'ör. 12,5×3+40';

  @override
  String get calcInvalid => 'Geçersiz ifade';

  @override
  String get liveDictation => 'Dikte';

  @override
  String get dictationHoldHint =>
      'Mikrofonu basılı tutup konuş, bırakınca yazılır';

  @override
  String itemsSelected(int count) {
    return '$count madde seçildi';
  }

  @override
  String get dictationProcessing => 'Yazıya dökülüyor...';

  @override
  String get voiceListening => 'Dinliyorum...';

  @override
  String get voiceTapHint => 'Dokun ve konuş; bitirmek için tekrar dokun';

  @override
  String get voiceModeSetting => 'Kullanım şekli';

  @override
  String get voiceModeHold => 'Basılı tut';

  @override
  String get voiceModeTap => 'Dokun-başlat';

  @override
  String get voiceModeInfo =>
      'Basılı tut: bırakınca biter. Bas-başlat: ikinci dokunuşla biter.';

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
  String get permissionsTitle => 'İzinler';

  @override
  String get permMic => 'Mikrofon';

  @override
  String get permMicInfo => 'AI sesli not, dikte ve ses kaydı için gerekli';

  @override
  String get permNotifications => 'Bildirimler';

  @override
  String get permNotificationsInfo =>
      'Hatırlatıcılar ve günlük brifing için gerekli';

  @override
  String get permExactAlarm => 'Alarmlar ve hatırlatıcılar';

  @override
  String get permExactAlarmInfo =>
      'Kapalıyken hatırlatıcılar birkaç dakika geç çalabilir. Notlar için izni aç';

  @override
  String get permBattery => 'Pil optimizasyonu';

  @override
  String get permBatteryInfo =>
      'Hatırlatıcılar gecikmesin diye pil kısıtlamasından muaf tut';

  @override
  String get permAutoStart => 'Otomatik başlatma (Xiaomi)';

  @override
  String get permAutoStartInfo =>
      'Telefon yeniden başlayınca hatırlatıcılar kurulsun: “Otomatik başlatma”yı aç';

  @override
  String get autoStartHint =>
      'Xiaomi: telefon yeniden başlayınca da çalması için Notlar’a “Otomatik başlatma” izni ver';

  @override
  String get autoStartHintAction => 'Aç';

  @override
  String get exactAlarmHint =>
      'Alarm izni kapalı: hatırlatıcılar dakikasında değil, birkaç dakika geç çalabilir';

  @override
  String get exactAlarmHintAction => 'İzni aç';

  @override
  String get permCamera => 'Kamera';

  @override
  String get permCameraInfo => 'Görüntülü not ve fotoğraf çekimi için gerekli';

  @override
  String get newVideoNote => 'Video çek';

  @override
  String get videoLocalOnly =>
      'Bu video yalnızca bu cihazda saklanır (buluta yüklenmez)';

  @override
  String get videoToNote => 'Videodan not çıkar';

  @override
  String get permGranted => 'İzin verildi';

  @override
  String get permGrant => 'İzin ver';

  @override
  String get permOpenSettings => 'Ayarları aç';

  @override
  String get newVoiceCapture => 'AI sesli not';

  @override
  String get suggestTitle => 'Başlık öner';

  @override
  String get noteMetaMenu => 'Etiket · Alarm · Klasör';

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
  String pendingUploadsOffline(int count) {
    return '$count ek bekliyor — bağlantı gelince yüklenecek';
  }

  @override
  String get pendingUploadsInfo =>
      'Ekler bu cihazda güvende. Bağlantı olduğunda kendiliğinden yüklenir; o zamana kadar öbür cihazlarınızda görünmez.';

  @override
  String checkedHeader(int count) {
    return 'İşaretliler ($count)';
  }

  @override
  String deleteChecked(int count) {
    return 'İşaretlileri sil ($count)';
  }

  @override
  String get removeItem => 'Maddeyi sil';

  @override
  String get copyWholeNote => 'Tüm notu kopyala';

  @override
  String get allCopied => 'Tüm not panoya kopyalandı';

  @override
  String get speechRate => 'Okuma hızı';

  @override
  String get speechNoVoices => 'Bu cihazda yuklu ses bulunamadi';

  @override
  String get speechVoiceAutoInfo =>
      'Diğer diller otomatik olarak erkek sesiyle okunur';

  @override
  String get listening => 'Dinleniyor...';

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
  String get backgroundColorInfo =>
      'Notun arka plan rengi — notun içinde ve ana ekranda görünür';

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
  String get syncTitle => 'Senkronizasyon';

  @override
  String get syncLimitTitle => 'Otomatik yükleme sınırı';

  @override
  String get syncLimitInfo =>
      'Bundan büyük ekler cihazda kalır; not metni her zaman eşitlenir.';

  @override
  String get syncLimitUnlimited => 'Sınırsız';

  @override
  String get importBackup => 'Yedekten geri yükle';

  @override
  String get importBackupInvalid => 'Geçersiz yedek dosyası';

  @override
  String get moveToFolder => 'Klasöre taşı';

  @override
  String get assistantGenericError => 'Bir sorun oluştu, tekrar dener misin?';

  @override
  String get quickAddTooltip => 'Yeni not — tip seç';

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
      'Sayfaya dokunup seç. Sayfa notları sayfalarıyla birlikte taşınır; silinen sayfanın notu listede görünmez ama kaydında kalır.';

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
      'Henüz sayfa notu yok. Sayfayı çevirip alttaki alana yaz.';

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
  String get penFountain => 'Dolma kalem';

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
  String get inkCleared => 'Çizimler temizlendi';

  @override
  String get inkEraserTooltip => 'Silgi (basılı tut: tümünü temizle)';

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
  String get checkSelectedItems => 'Seçilenleri işaretle';

  @override
  String get itemUncheck => 'İşareti kaldır';

  @override
  String get uncheckSelectedItems => 'Seçilenlerin işaretini kaldır';

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
  String get filterOthers => 'Klasörsüz ve etiketsiz';

  @override
  String get aiHistoryVoiceNote => 'AI sesli not';

  @override
  String get sectionPinnedShort => 'Sabit';

  @override
  String get sectionUrgent => 'Acil';

  @override
  String get urgentMark => 'Acil işaretle';

  @override
  String get urgentUnmark => 'Acil işaretini kaldır';

  @override
  String get urgentInfo => 'Ana ekranda en üstte, ünlemle';

  @override
  String get sectionToday => 'Bugün';

  @override
  String get sectionThisWeek => 'Bu hafta';

  @override
  String get sectionEarlier => 'Daha önce';

  @override
  String sectionNoteCount(int count) {
    return '$count not';
  }

  @override
  String get quickCaptureHint => 'Yeni not…';

  @override
  String get quickCaptureSave => 'Kaydet';

  @override
  String get viewToggle => 'Görünüm';

  @override
  String get viewGrid => 'Izgara';

  @override
  String get viewList => 'Liste';

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
  String get reorderHint => 'Kartı basılı tutup istediğin yere sürükle';

  @override
  String get filterSheetTitle => 'Süz';

  @override
  String get filterReset => 'Sıfırla';

  @override
  String get filterSectionStatus => 'Durum';

  @override
  String get filterSectionFolder => 'Klasör';

  @override
  String get filterSectionTag => 'Etiket';

  @override
  String get filterSectionSort => 'Sıralama';

  @override
  String get filterSheetSortHint =>
      'Tarih grupları (Bugün, Bu hafta…) yalnız “Son güncellenen” sıralamasında gösterilir.';

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
  String get noteTextOpacity => 'Şeffaflık';

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
  String get noteBackgroundImage => 'Zemin görseli';

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
  String get apiKeyFieldLabel => 'API anahtarı';

  @override
  String get getApiKey => 'Anahtarı nereden alırım?';

  @override
  String get continueWithoutAccount => 'Hesapsız devam et';

  @override
  String get localAccountInfo =>
      'Notların yalnız bu cihazda kalır: başka cihazdan açılamaz, uygulamayı silersen geri getirilemez. Dahili yapay zekâ, kişiler ve paylaşım Google hesabı ister; yapay zekâyı kendi API anahtarınla kullanabilirsin. İstediğin an Google hesabı bağlayabilirsin — notların olduğu gibi kalır.';

  @override
  String get localAccountBadge => 'Yerel hesap';

  @override
  String get profileGuestName => 'Misafir';

  @override
  String get profileGuestSignIn => 'Giriş yap';

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
  String get premiumStatusFree => 'Ücretsiz sürümü kullanıyorsun';

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
      'Kartlarda renk, vurgu, kalın ve altı çizili yazı görünür.';

  @override
  String get cardHideSensitive => 'Kartlarda hassas içeriği gizle';

  @override
  String get cardHideSensitiveInfo =>
      'Parolalı notun içeriği ve kart/IBAN numaraları kartta gizlenir.';

  @override
  String get sensitiveHiddenOnCard => 'Hassas içerik — kartta gizlendi';

  @override
  String get paletteMore => 'Daha fazla renk';

  @override
  String get paletteCustom => 'Özel renk';

  @override
  String get paletteUse => 'Kullan';

  @override
  String get paletteHue => 'Ton';

  @override
  String get paletteSaturation => 'Doygunluk';

  @override
  String get paletteLightness => 'Açıklık';

  @override
  String get itemMoveToPage => 'Başka sayfaya taşı';

  @override
  String itemMovedToPage(int page) {
    return 'Madde $page. sayfaya taşındı';
  }

  @override
  String get archiveInsights => 'Arşivimde neler var?';

  @override
  String archiveInsightsStats(int count, int files, int stale) {
    return '$count not · $files ek · $stale not bir yıldır açılmadı';
  }

  @override
  String get archiveByFolder => 'Klasörlere göre';

  @override
  String get archiveNoFolder => 'Klasörsüz';

  @override
  String get archiveStale => 'Bir yıldır dokunulmamış';

  @override
  String get lineSpacing => 'Satır aralığı';

  @override
  String get lineSpacingNormal => 'Normal';

  @override
  String get lineSpacingWide => 'Geniş';

  @override
  String get lineSpacingWider => 'Çok geniş';

  @override
  String get trashReminderTitle => 'Çöpte geri yüklemen gereken not olabilir';

  @override
  String trashReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not yarın kalıcı silinecek',
      one: 'Bir not yarın kalıcı silinecek',
    );
    return '$_temp0 — içinde iş ya da önemli bilgi var gibi. Göz at.';
  }

  @override
  String get groupByFolder => 'Klasöre göre grupla';

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
      'Uygulamanın yazı tipi; bazıları seçilince internetten iner.';

  @override
  String get fontNeedsDownload => 'Seçilince bir kez indirilir';

  @override
  String get followSystemTextScale => 'Sistem yazı boyutunu izle';

  @override
  String get followSystemTextScaleInfo =>
      'Telefonun yazı boyutu da uygulamaya geçer.';

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
  String get ttsSectionTitle => 'Seslendirme';

  @override
  String get ttsEngineDevice => 'Cihaz sesi';

  @override
  String get ttsEngineDeviceInfo =>
      'Cihazın yerleşik sesi okur: bedava, çevrimdışı ve sınırsız uzunlukta.';

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
  String get bubblesListAll => 'Tüm balonlar';

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
  String get captureModeClassicInfo => 'Düz metin notu; belge ek olur.';

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
  String get exportNotesOption => 'Ayarlı PDF / Word…';

  @override
  String get exportNotesOptionInfo =>
      'Notun yazısı ve görselleri PDF ya da Word olarak, düzeni ayarlanır; balonlar dahil değil';

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
  String get rotateFailed => 'Görsel döndürülemedi.';

  @override
  String get dashboardBackgroundChange => 'Zemin görselini değiştir';

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
  String get archiveCopyHere => 'Deftere topla';

  @override
  String get archiveNoNotebook => 'Henüz defter yok. Önce bir tane oluştur.';

  @override
  String get archiveNothingToCopy => 'Bu notta kopyalanacak ek yok.';

  @override
  String archiveCopied(int count) {
    return '$count dosya deftere toplandı.';
  }

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
  String get archivePaperLegal => 'Bloknot';

  @override
  String get archivePaperEngineering => 'Milimetrik';

  @override
  String get archivePaperIsometric => 'İzometrik';

  @override
  String get attachmentTagEmbed => 'Yazıya göm';

  @override
  String get bubbleModeBubble => 'Balon';

  @override
  String get attachmentTagEmbedInfo =>
      'Yazıyı seçtiysen o yazıya, seçmediysen imlecin yerine bağlanır';

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
  String get folderEmpty => 'Burada henüz not yok';

  @override
  String folderNoteCount(int count) {
    return '$count not';
  }

  @override
  String get folderCardEmpty => 'Boş';

  @override
  String get folderEmptyHint =>
      'Aşağıdaki + ile buraya not ekle ya da bir notu düzenlerken bu klasöre taşı.';

  @override
  String get folderShared => 'Bu klasör bir arkadaşınla ortak';

  @override
  String get friendsTitle => 'Kişiler';

  @override
  String get friendsAdd => 'Arkadaş ekle';

  @override
  String get friendsEmpty =>
      'E-postayla bir arkadaş ekle, klasörlerini onunla paylaş.';

  @override
  String get friendsRequestsTitle => 'İstekler';

  @override
  String get friendsListTitle => 'Arkadaşlarım';

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
  String get friendsSearchHint => 'Ad (en az 3 harf) ya da tam e-posta';

  @override
  String get friendsSearchEmpty => 'Sonuç yok';

  @override
  String get friendsSearchTooShort =>
      'Aramak için en az 3 harf ya da tam bir e-posta yaz';

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
  String get folderChatEmptyTitle => 'Burada henüz mesaj yok';

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
  String get inboxEmpty => 'Burada gelen not yok';

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
  String get areaAskTitle => 'Seçilen alan';

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
      'Ortak notta ekleme, değişiklik ya da mesaj olunca bildirim gelir.';

  @override
  String get copyAsText => 'Metni kopyala';

  @override
  String get searchAttachments => 'Ek içeriğinde de ara';

  @override
  String get searchAttachmentsInfo =>
      'PDF metnini ve görsellerdeki yazıyı da arar.';

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
  String get reminderDone => 'Tamamlandı';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateTomorrow => 'Yarın';

  @override
  String get noteDuplicatedNoAttachments =>
      'Çoğaltıldı — ekler yeni nota taşınmadı';

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
      'Henüz yer imi yok. Sayfa çubuğundaki yer imi düğmesine dokun.';

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
  String get collaboratorsFriendsTitle => 'Arkadaşların';

  @override
  String get collaboratorsLeave => 'Paylaşımdan ayrıl';

  @override
  String get collaboratorsLeaveConfirm =>
      'Bu not artık ana ekranında görünmeyecek. Ayrılmak istiyor musun?';

  @override
  String get collaboratorsSaved => 'Paylaşım güncellendi';

  @override
  String get collaboratorsOnlyOwner =>
      'Ortak çalışanları yalnız notun sahibi değiştirebilir.';

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
  String get shortcutFullscreen => 'Notu tam ekran yap / çık';

  @override
  String get shortcutEscape => 'Tam ekrandan çık, sonra notu kapat';

  @override
  String get showNoteList => 'Not listesini göster';

  @override
  String get shortcutSwitchFolder => 'Klasörler arasında geç';

  @override
  String get shortcutMouseWheel => 'tekerlek';

  @override
  String get shortcutGridColumns => 'Sütun sayısı';

  @override
  String get shortcutSelectAll => 'Seçimdeyken hepsini seç';

  @override
  String get shortcutDeleteSelected => 'Seçilenleri çöp kutusuna at';

  @override
  String get sharedFolderNoFileDrop =>
      'Paylaşılan klasöre dosya bırakılamaz. Önce not aç, dosyayı onun içine bırak.';

  @override
  String get shortcutAdjacentNote => 'Listede önceki / sonraki not';

  @override
  String get shortcutCloseNote => 'Notu kapat';

  @override
  String get softKeyboardShow => 'Sanal klavyeyi aç (fiziksel klavye takılı)';

  @override
  String get softKeyboardHide => 'Sanal klavyeyi kapat';

  @override
  String get goHome => 'Ana sayfaya dön';

  @override
  String get loginFeatureSyncTitle => 'Her cihazda aynı notlar';

  @override
  String get loginFeatureSyncBody =>
      'Telefon, tablet, bilgisayar ve web arasında anında senkron.';

  @override
  String get loginFeatureAiTitle => 'Akıllı yardımcılar';

  @override
  String get loginFeatureAiBody =>
      'Sesle hızlı not al, yazım hatalarını düzelt, market reyonlarını ve etiketleri düzenle.';

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
  String get foldersEmptyTitle => 'Burada henüz klasör yok';

  @override
  String get foldersEmptyHint => 'Bir klasör oluşturup notlarını düzenle.';

  @override
  String get folderColor => 'Renk';

  @override
  String get folderColorAuto => 'Otomatik';

  @override
  String get foldersMine => 'Klasörlerim';

  @override
  String get foldersSharedSection => 'Paylaşılan klasörler';

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
      'Tutamaktan sürükleyerek sıralayın (sürüklemek sırayı \"Elle\"ye çevirir). Bu sıra klasör şeridinde ve yana kaydırırken de kullanılır.';

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
      'Önbelleği temizlemek notları ve ekleri silmez.';

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
  String get fromTemplate => 'Hazır şablonlar';

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
  String get settingsGroupPrivacyNotify => 'Gizlilik ve bildirim';

  @override
  String get settingsGroupText => 'Yazı';

  @override
  String get settingsGroupDictation => 'Sesle yazma';

  @override
  String get settingsGroupGestures => 'Hareketler';

  @override
  String get settingsGroupSortView => 'Sıralama ve görünüm';

  @override
  String get settingsGroupShared => 'Paylaşılan notlar';

  @override
  String get settingsGroupAttachments => 'Ekler';

  @override
  String get settingsGroupBackup => 'Yedek';

  @override
  String get settingsGroupSession => 'Oturum';

  @override
  String get settingsSecurityTitle => 'Güvenlik';

  @override
  String get settingsSecuritySummary => 'Not kilidi, uygulama kilidi';

  @override
  String get settingsGroupAbout => 'Hakkında';

  @override
  String get settingsGroupVersion => 'Sürüm';

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
  String get templateListChecks => 'Onay kutulu';

  @override
  String get templateListNumbers => 'Numaralı';

  @override
  String get templateAddItem => 'Madde ekle';

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
  String get unpinMediaRelease => 'Bırak: Yüzen';

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
  String get embedPickInfo => 'Gömülen ek yazıya dokununca yerinde açılır.';

  @override
  String get embedSectionNew => 'Yeni ekle';

  @override
  String get embedSectionExisting => 'Bu nottaki ekler';

  @override
  String get embedSectionLink => 'Bağlantı';

  @override
  String get embedLinkHint => 'Web adresi (örn. ornek.com)';

  @override
  String get embedLinkApply => 'Bağla';

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
  String get guideOpenScreen => 'Göster';

  @override
  String guideNoResults(String query) {
    return '«$query» için sonuç yok';
  }

  @override
  String get copyVideoLink => 'Bağlantıyı kopyala';

  @override
  String get videoLinkCopied => 'Bağlantı kopyalandı';

  @override
  String get menuSectionOrganize => 'Düzenle';

  @override
  String get menuSectionCopy => 'Kopyala';

  @override
  String get menuSectionTools => 'Araçlar';

  @override
  String get menuSectionProtect => 'Koruma ve depolama';

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
      'Görseller, PDF\'ler, sunumlar ve ses kayıtları kendi Drive kotanda, Drive\'ındaki “Notlar” klasöründe saklanır ve öbür cihazlarına iner. Videolar cihazda kalır.';

  @override
  String get driveConnect => 'Bağla';

  @override
  String get driveDisconnect => 'Bağlantıyı kes';

  @override
  String get driveConnected => 'Google Drive bağlandı — ekler yedekleniyor.';

  @override
  String get driveConnectedInfo =>
      'Bağlı · ekler Drive\'ındaki “Notlar” klasöründe';

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
  String viewModeChanged(String from, String to) {
    return '$from → $to';
  }

  @override
  String get videoRotate => 'Görüntüyü döndür';

  @override
  String get viewModeTitle => 'Görünüm';

  @override
  String get viewModeEmbed => 'Yazıya göm';

  @override
  String get viewModeEmbedHint =>
      'Bu eki nottaki bir yazıya göm — yazıya dokununca açılır';

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
  String get shareToFriendShort => 'Arkadaşa gönder';

  @override
  String get shareCollaborateShort => 'Birlikte düzenle';

  @override
  String get shareAsNoteShort => 'Not paketi';

  @override
  String get shareQuickPreparing => 'Hazırlanıyor…';

  @override
  String get shareAttachmentFilesNone =>
      'Bu cihazda paylaşılacak ek dosyası yok.';

  @override
  String get attachmentRemoved => 'Ek kaldırıldı';

  @override
  String get customizeHideItem => 'Gizle';

  @override
  String get customizeShowItem => 'Göster';

  @override
  String get customizeModeTitle => 'Düzenleme modu';

  @override
  String get customizeModeTitleShort => 'Düzen';

  @override
  String customizeHiddenCount(int count) {
    return '$count düğme gizli · dokunarak değiştir';
  }

  @override
  String get customizeDone => 'Bitti';

  @override
  String videoBackSeconds(int seconds) {
    return '$seconds sn geri';
  }

  @override
  String videoForwardSeconds(int seconds) {
    return '$seconds sn ileri';
  }

  @override
  String get personalizeTitle => 'Arayüz düzeni';

  @override
  String get personalizeInfo => 'Hangi alan ve düğmeler görünsün, eklentiler';

  @override
  String get customizeStartTitle => 'Ekranda düzenle';

  @override
  String get customizeStartInfo =>
      'Düğme ve alanlara dokunarak gizle ya da göster; bitince Bitti\'ye bas.';

  @override
  String get customizeStart => 'Düzenleme modunu başlat';

  @override
  String get customizeActive => 'Düzenleme modu açık';

  @override
  String get customizeHint => 'Dokun: gizle/göster · Sırala: yerini değiştir';

  @override
  String get customizeShown => 'Görünenler';

  @override
  String get customizeSurfaceBottomBar => 'Alt çubuk';

  @override
  String get customizeSurfaceTopBar => 'Üst çubuk';

  @override
  String get customizeSurfaceQuickRow => 'Hızlı satır';

  @override
  String get customizeSurfaceAddPanel => '\"+\" paneli';

  @override
  String get customizeSurfacePinned => 'Sabit ek';

  @override
  String get customizeSurfacePen => 'Kalemler';

  @override
  String get personalizeModules => 'Eklentiler';

  @override
  String get moduleAi => 'Yapay zekâ';

  @override
  String get moduleAiInfo =>
      'Ana ekran ve not ekranındaki yapay zekâ düğmeleri';

  @override
  String get moduleVoice => 'Ses';

  @override
  String get moduleVoiceInfo => 'AI sesli not, dikte, ses kaydı';

  @override
  String get moduleVideo => 'Video';

  @override
  String get moduleVideoInfo => 'Video çekme, galeriden video, YouTube';

  @override
  String get moduleDocuments => 'Belgeler';

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
  String get moduleTemplatesInfo => 'Şablondan not, alışveriş listesi, defter';

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
  String get personalizeBarLeft => 'Sol kapsül · araçlar';

  @override
  String get personalizeBarRight => 'Sağ kapsül · yapay zekâ ve ses';

  @override
  String get personalizeBarReset => 'Alt çubuğu varsayılana döndür';

  @override
  String get personalizeBarTop => 'Üst çubuk · düğmelerin sırası';

  @override
  String get personalizeBarMoveRight => 'Sağ kapsüle taşı';

  @override
  String get personalizeBarMoveLeft => 'Sol kapsüle taşı';

  @override
  String get reorderHandle => 'Sırala';

  @override
  String get personalizeVideo => 'Video';

  @override
  String get personalizeHome => 'Ana ekran';

  @override
  String get personalizeBubbles => 'Balonlar';

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
  String get transcriptShowTimes => 'Zaman damgaları';

  @override
  String get transcriptDelete => 'Transkripti sil';

  @override
  String get transcriptDeleteConfirm =>
      'Transkript silinsin mi? Kaynak dosya notta kalır.';

  @override
  String get transcriptEmpty => 'Metin bulunamadı.';

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
  String get fileAppPickerTitle => 'Dosyaları Dosya Okuyucu ile seç';

  @override
  String get fileAppPickerInfo =>
      'Dosya eklerken doğrudan Dosya Okuyucu açılır; kapalıyken uygulama sorulur.';

  @override
  String get viewModeAttached => 'Ek';

  @override
  String get viewModeAttachedHint => 'Ek olarak — alttaki ek şeridinde durur';

  @override
  String get textToBubblesPreparing => 'Metin belgeye diziliyor…';

  @override
  String get attachmentActions => 'Ek işlemleri';

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
  String get voiceAutoStop => 'Sessizlikte bitir';

  @override
  String get voiceAutoStopInfo =>
      'Konuşma bitince kısa bir sessizlikten sonra dinleme biter.';

  @override
  String get voiceSmartCommands => 'Akıllı komutlar';

  @override
  String get voiceSmartCommandsInfo =>
      '“son kelimeyi sil”, “X yerine Y yaz”, “yeni satır”, “geri al” gibi komutları anlar; tam liste Kullanım kılavuzunda.';

  @override
  String get voiceAutoStopSoon => 'Sessizlik — birazdan biter';

  @override
  String get dictationPause => 'Duraklat';

  @override
  String get dictationResume => 'Devam et';

  @override
  String get dictationPaused => 'Duraklatıldı';

  @override
  String get dictationUndoChunk => 'Son cümleyi geri al';

  @override
  String dictationLocaleTooltip(String lang) {
    return 'Konuşma dili: $lang';
  }

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
      'Dil paketi varsa ses internete gitmeden yazıya dökülür.';

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
  String get feedbackSend => 'Geri bildirim gönder';

  @override
  String get feedbackInfo =>
      'Öneri ya da sorun: e-posta uygulaman açılır; sürüm ve cihaz türü eklenir, notların eklenmez.';

  @override
  String get feedbackNoMailApp =>
      'E-posta uygulaması açılamadı; adres panoya kopyalandı.';

  @override
  String get feedbackBodyPrompt => 'Mesajın:';

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
      'Fotoğraf, tarama, PDF ve görselden not alırken; ilk seçimin kalır.';

  @override
  String get captureModeAsk => 'Her seferinde sor';

  @override
  String get voiceMicTooltipDictate => 'Dikte — basılı tut: AI sesli not';

  @override
  String get quickAddCamera => 'Kamera';

  @override
  String get quickAddFile => 'Dosya ekle';

  @override
  String get quickAddFromDevice => 'Cihazdan dosya seç';

  @override
  String get quickAddFileWhat => 'Bu dosyayla ne yapalım?';

  @override
  String get quickAddFileUnsupported => 'Bu dosya türü desteklenmiyor';

  @override
  String get shareFolderTogether => 'Klasörü birlikte düzenle';

  @override
  String get shareTogetherInfo =>
      'Aynı notu/klasörü ikiniz de görür ve değiştirirsiniz';

  @override
  String get shareCopyInfo =>
      'Arkadaşının gelen kutusuna bağımsız bir kopya gider';

  @override
  String get notebookViewOn => 'Defter görünümü';

  @override
  String get notebookViewOff => 'Defter görünümünü kapat';

  @override
  String inkSemantics(int count) {
    return 'Elle çizim, $count çizgi';
  }

  @override
  String get guestReminderTitle => 'Notların yedeklenmiyor';

  @override
  String get guestReminderBody =>
      'Hesapsız kullanıyorsun: notların yalnız bu cihazda, dahili yapay zekâ ve paylaşım kapalı. Uygulama veya tarayıcı verisi silinirse ya da cihaz değişirse notlar geri getirilemez. Google hesabını bağla — notların olduğu gibi kalır.';

  @override
  String get guestReminderLater => 'Sonra';

  @override
  String get driveWebConnectTitle => 'Bu ek Google Drive’ında';

  @override
  String get driveWebConnectBody =>
      'Eklerin Google Drive’ındaki “Notlar” klasöründe saklanıyor. Tarayıcıda indirip çevrimdışı önbelleğe almak ve yeni ek yüklemek için Google Drive’a bağlan.';

  @override
  String get driveWebConnectButton => 'Drive’a bağlan';

  @override
  String get lockPatternSemantics =>
      'Kilit deseni: noktaları parmakla birleştir';

  @override
  String get lockDrawPattern => 'Deseni çiz';

  @override
  String get lockDrawAgain => 'Onaylamak için deseni yeniden çiz';

  @override
  String get lockEnterPassword => 'Şifreni gir';

  @override
  String get lockPassword => 'Şifre';

  @override
  String get lockPasswordAgain => 'Şifre (tekrar)';

  @override
  String get lockWrong => 'Yanlış, yeniden dene';

  @override
  String lockTooManyAttempts(int count) {
    return 'Çok fazla yanlış deneme. $count sn bekle.';
  }

  @override
  String get lockUseFingerprint => 'Parmak iziyle aç';

  @override
  String get lockForgot => 'Unuttum';

  @override
  String get lockForgotFailed =>
      'Google hesabınla doğrulanamadı. Misafir hesapta şifre sıfırlanamaz.';

  @override
  String get lockNewPassword => 'Yeni kilit şifresi';

  @override
  String get lockNewPattern => 'Yeni kilit deseni';

  @override
  String lockPasswordTooShort(int count) {
    return 'Şifre en az $count karakter olmalı';
  }

  @override
  String lockPatternTooShort(int count) {
    return 'Desen en az $count noktayı birleştirmeli';
  }

  @override
  String get lockMismatch => 'Eşleşmedi, baştan dene';

  @override
  String get lockChangeAuthReason => 'Kilit ayarını değiştirmek için doğrula';

  @override
  String get lockMethodTitle => 'Not kilidi';

  @override
  String get lockMethodInfo => 'Kilitli notlar nasıl açılsın?';

  @override
  String get lockMethodDevice => 'Parmak izi';

  @override
  String get lockMethodPassword => 'Şifre';

  @override
  String get lockMethodPattern => 'Desen';

  @override
  String get lockAlsoFingerprint => 'Parmak iziyle de açılabilsin';

  @override
  String get lockChangePassword => 'Şifreyi değiştir';

  @override
  String get lockChangePattern => 'Deseni değiştir';

  @override
  String get lockWebDeviceInfo =>
      'Tarayıcıda parmak izi yok: kilitli notları web’de de korumak için şifre ya da desen seç.';

  @override
  String get lockNotEncryption =>
      'Kilitli notun gövdesi, maddeleri ve sayfa notları cihazda AES-256-GCM ile şifrelenip eşitlenir; parmak izi kilidinde anahtar yalnız bu cihazın güvenli deposundadır. Şifre veya desen kilidinde anahtar sırrından türetilir — unutursan eski kilitli içerik geri çözülemez.';

  @override
  String get versionHistory => 'Sürüm geçmişi';

  @override
  String get versionHistoryInfo =>
      'Notun metni açıldığında, uzun düzenlemede yarım saatte bir ve yapay zekâ değiştirmeden önce saklanır. Ekler sürümlenmez.';

  @override
  String get versionHistoryEmpty =>
      'Henüz sürüm yok. Notu düzenledikçe burada birikir.';

  @override
  String get versionRestore => 'Bu sürüme dön';

  @override
  String get versionRestored => 'Not eski sürümüne döndü';

  @override
  String get versionReasonAi => 'AI değiştirmeden önce';

  @override
  String get versionReasonRestore => 'Geri dönmeden önce';

  @override
  String get versionReasonOpen => 'Açıldığı hâli';

  @override
  String get versionReasonAuto => 'Otomatik';

  @override
  String get mergeConflictKept =>
      'Aynı yerde başka biri de yazdı — iki hâli de tutuldu, fazlasını silebilirsin.';

  @override
  String presenceEditing(String name) {
    return '$name şu an düzenliyor';
  }

  @override
  String get presenceSomeone => 'Biri';

  @override
  String get frameColorInfo =>
      'Yalnız ana ekrandaki kartın çevresine çizilir; notun içinde görünmez';

  @override
  String get filterStarred => 'Yıldızlı';

  @override
  String get fileUseBubbles => 'Balonlu: belge notun kendisi olur';

  @override
  String get fileUseClassic => 'Klasik: belge ek olur';

  @override
  String get fileUseClassicImageInfo =>
      'Düz not açılır; görseller sayfaya yerleşir, yazı etrafından akar.';

  @override
  String get fileUseVideo => 'Videoyla not al';

  @override
  String get fileUseVideoInfo => 'Video üstte oynar, notunu altına yazarsın.';

  @override
  String get fileUseAudio => 'Ses eki olarak ekle';

  @override
  String get fileUseAudioInfo =>
      'Kayıt notta çalınabilir ek olarak durur; istersen sonra metne dökersin.';

  @override
  String get fileUseTranscribeInfo =>
      'Konuşma yazıya dökülür ve metin notun gövdesine yazılır.';

  @override
  String get fileUseTranscribeImageInfo =>
      'Görseldeki yazı okunur ve notun gövdesine yazılır.';

  @override
  String get fileUseDefault => 'Varsayılan';

  @override
  String fileUseMore(int count) {
    return '+$count dosya daha';
  }

  @override
  String get attachAnyFileInfo =>
      'Her tür dosya: görsel, PDF, sunum, ses, video — tür kendiliğinden tanınır, gerekirse ne yapılacağı sorulur';

  @override
  String get listeningModeAi => 'Yapay zekâ';

  @override
  String get listeningModeDictation => 'Doğrudan yazım';

  @override
  String get dictationPanelHint => 'Konuştukça imlecin olduğu yere yazılır';

  @override
  String get voiceStartShort => 'Başla';

  @override
  String get archivePaperDashed => 'Kesikli çizgili';

  @override
  String get itemDividerRemove => 'Çizgiyi kaldır';

  @override
  String get fileUseAttachInfo => 'Nota ek olarak girer; oynatılabilir';

  @override
  String get allNotesChip => 'Tümü';

  @override
  String get untitledNote => 'Başlıksız not';

  @override
  String get trashAnalysis => 'Çöp analizi';

  @override
  String get trashAnalyze => 'Akıllı analiz';

  @override
  String get trashSuggestRestore => 'Geri yüklemeyi düşün';

  @override
  String get trashSuggestDelete => 'Güvenle silinebilir';

  @override
  String get trashSuggestNone => 'Öneri yok';

  @override
  String trashRestoreAllSuggested(int count) {
    return 'Tümünü geri yükle ($count)';
  }

  @override
  String trashDeleteAllSuggested(int count) {
    return 'Tümünü sil ($count)';
  }

  @override
  String trashStatNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not',
      one: '1 not',
    );
    return '$_temp0';
  }

  @override
  String trashStatAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek',
      one: '1 ek',
    );
    return '$_temp0';
  }

  @override
  String trashStatSoon(int count) {
    return '$count not 3 gün içinde gidiyor';
  }

  @override
  String trashStatLocked(int count) {
    return '$count kilitli (incelenmedi)';
  }

  @override
  String get trashReasonEmpty => 'Boş not — kaybedilecek bir şey yok';

  @override
  String get trashReasonDuplicate => 'Aynısı notlarında zaten var';

  @override
  String trashReasonDuplicateOf(String title) {
    return 'Aynısı notlarında var: $title';
  }

  @override
  String get trashReasonDuplicateInTrash => 'Çöpte daha yeni bir kopyası var';

  @override
  String trashReasonOpenTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yapılmamış madde var',
      one: '1 yapılmamış madde var',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonReminder => 'İleri tarihli hatırlatıcısı var';

  @override
  String get trashReasonSensitive => 'Şifre, IBAN, telefon gibi bilgi içeriyor';

  @override
  String trashReasonAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek taşıyor',
      one: '1 ek taşıyor',
    );
    return '$_temp0';
  }

  @override
  String get trashReasonSubstantial => 'Uzun, emek verilmiş metin';

  @override
  String get cardElementsHeader => 'Kartta görünenler';

  @override
  String get cardShowProgress => 'İlerleme sayacı (ör. 3/10)';

  @override
  String get cardShowProgressInfo =>
      'İşaretli madde sayısı çubuk ve sayıyla görünür.';

  @override
  String get cardShowChecked => 'Tamamlanan maddeler';

  @override
  String get cardShowCheckedInfo =>
      'Kapalıyken işaretliler tek satır özet olur: ✓ 3 tamamlandı.';

  @override
  String cardItemsDone(int count) {
    return '✓ $count tamamlandı';
  }

  @override
  String cardItemsAllDone(int count) {
    return '✓ Hepsi tamam ($count)';
  }

  @override
  String get emptyNotesFirstAction => 'İlk notunu yaz';

  @override
  String get emptyNotesHint => 'Yazdığın notlar burada kart olarak görünür.';

  @override
  String get emptyFolderHint => 'Bu klasöre eklediğin notlar burada toplanır.';

  @override
  String get emptyFilterHint =>
      'Süzgeci kaldırınca bütün notların yeniden görünür.';

  @override
  String get emptySearchHint => 'Başka bir sözcükle dene.';

  @override
  String get archiveEmptyHint =>
      'Arşivlediğin notlar ana ekrandan kalkar, burada saklanır.';

  @override
  String get trashEmptyHint =>
      'Sildiğin notlar 30 gün burada kalır; o sürede geri alabilirsin.';

  @override
  String get cardShowMoreCount => '“+N madde daha” satırı';

  @override
  String get cardShowStatusIcons => 'Durum simgeleri';

  @override
  String get cardShowStatusIconsInfo =>
      'Sabit, yıldız, hatırlatıcı, ortak not, yalnız bu cihaz…';

  @override
  String get cardShowTag => 'Etiket';

  @override
  String get cardShowDate => 'Tarih ve saat';

  @override
  String get cardShowMedia => 'Görseller ve videolar';

  @override
  String get cardShowFolder => 'Klasör adı';

  @override
  String get cardShowFolderInfo =>
      'Arama sonucunda ve Tümü görünümünde notun klasörü.';

  @override
  String get cardShowPaper => 'Defter kâğıdı deseni';

  @override
  String get formatFontPanel => 'Yazı tipi ve boyut';

  @override
  String get inkShapes => 'Şekiller';

  @override
  String get inkShapeLine => 'Düz çizgi';

  @override
  String get inkShapeRectangle => 'Dikdörtgen';

  @override
  String get inkShapeEllipse => 'Daire / elips';

  @override
  String get inkPenOnlyOn => 'Yalnız kalem yazıyor (parmak kaydırır) — kapat';

  @override
  String get inkPenOnlyOff => 'Parmakla da yazılıyor — yalnız kaleme geç';

  @override
  String get inkPenOnlyHint =>
      'Kalemle yaz · parmakla kaydır, iki parmakla yakınlaştır';

  @override
  String get inkSettings => 'Kalem ayarları';

  @override
  String get inkWidth => 'Kalınlık';

  @override
  String get inkOpacity => 'Şeffaflık';

  @override
  String get inkRecentColors => 'Son kullanılan renkler';

  @override
  String get inkPenOnlyTitle => 'Yalnız kalemle yaz';

  @override
  String get inkFingerToolTitle => 'Parmak';

  @override
  String get inkFingerToolInfo =>
      'Otomatik: kalem görüldüyse parmak kaydırır, görülmediyse çizer. Kaydırır: yalnız kalem yazar, parmak kaydırır. Çizer: parmak da kalemin aracıyla yazar. Siler: parmak siler, iki parmak yakınlaştırır.';

  @override
  String get inkFingerScroll => 'Kaydırır';

  @override
  String get inkFingerDraw => 'Çizer';

  @override
  String get inkFingerErase => 'Siler';

  @override
  String get inkFingerEraseOn => 'Parmak siliyor — yalnız kaleme geç';

  @override
  String get inkPressureTitle => 'Basınç algısı';

  @override
  String get inkPressureInfo =>
      'Kalemle hafif bastırınca ince, sert bastırınca kalın yazar.';

  @override
  String get inkStylusTipsTitle => 'Kalem kısayolları';

  @override
  String get inkStylusTips =>
      'Kalemin yan düğmesini basılı tut ya da silgi ucuyla dokun: siler.';

  @override
  String get inkZoomReset => 'Tam görünüme dön';

  @override
  String get cardShowFiles => 'Dosya ekleri';

  @override
  String get cardShowFilesInfo =>
      'PDF, sunum, ses ve metin ekleri kartta görünsün';

  @override
  String get cardShowMediaShort => 'Kartta görseller';

  @override
  String get cardShowFilesShort => 'Kartta ekler';

  @override
  String get homeShowShared => 'Paylaşılan notlar ana ekranda';

  @override
  String get homeShowSharedInfo =>
      'Ortak notlar ana ekranda ayrı bölümde de görünür.';

  @override
  String get homeShowSharedShort => 'Paylaşılan notları göster';

  @override
  String get homeSharedAtBottom => 'Paylaşılanlar notlarımın altında';

  @override
  String get homeSharedAtBottomInfo =>
      'Açıkken paylaşılan notlar kendi notlarının altında durur.';

  @override
  String get homeSharedAtBottomShort => 'Paylaşılanlar altta';

  @override
  String get homeSharedSection => 'Paylaşılan';

  @override
  String get copyAttachment => 'Eki kopyala';

  @override
  String get attachmentCopiedPasteHint =>
      'Ek kopyalandı — başka bir notta + menüsünden yapıştır';

  @override
  String get dividerSettings => 'Çizgi ayarları';

  @override
  String get dividerPreviewText => 'Örnek madde';

  @override
  String get dividerKind => 'Tür';

  @override
  String get dividerColor => 'Renk';

  @override
  String get dividerWeight => 'Kalınlık';

  @override
  String get dividerApplyAll => 'Tüm çizgilere';

  @override
  String get dividerKindSolid => 'Düz';

  @override
  String get dividerKindDashed => 'Kesikli';

  @override
  String get dividerKindDotted => 'Noktalı';

  @override
  String get dividerKindDouble => 'Çift';

  @override
  String get dividerKindWavy => 'Dalgalı';

  @override
  String get itemMenuUnstar => 'Yıldızı al';

  @override
  String get itemMenuMove => 'Taşı';

  @override
  String get itemMenuDelete => 'Sil';

  @override
  String get itemMenuLine => 'Alt çizgi';

  @override
  String get formatStyleText => 'Metin';

  @override
  String get formatStyleH1 => 'Başlık';

  @override
  String get formatStyleH2 => 'Alt başlık';

  @override
  String get formatSizeDown => 'Küçült';

  @override
  String get formatSizeUp => 'Büyüt';

  @override
  String get imageCaptionHint => 'Görüntü açıklaması';

  @override
  String get imageCaptionAdd => 'Açıklama ekle';

  @override
  String get imageCaptionEdit => 'Açıklamayı düzenle';

  @override
  String get voiceRecordResume => 'Kayda devam et';

  @override
  String get voiceRecordDiscard => 'Kaydı at';

  @override
  String get checkboxToggle => 'Onay kutusu';

  @override
  String get noteAppearance => 'Görünüm';

  @override
  String get noteThemeNone => 'Sade';

  @override
  String get noteThemePalm => 'Palmiye';

  @override
  String get noteThemeLagoon => 'Lagün';

  @override
  String get noteThemeNight => 'Gece';

  @override
  String get noteThemeSunset => 'Gün batımı';

  @override
  String get noteThemeSakura => 'Sakura';

  @override
  String get noteThemeWaves => 'Deniz';

  @override
  String get noteThemeMeadow => 'Çayır';

  @override
  String get noteThemePaper => 'Kâğıt';

  @override
  String get pinToHomeScreen => 'Ana ekrana yerleştir';

  @override
  String get pinToHomeSent =>
      'Ana ekranın onayı bekleniyor — kısayol eklenince notu oradan açabilirsin';

  @override
  String get pinToHomeUnsupported => 'Ana ekran bu kısayolu desteklemiyor';

  @override
  String get inkColor => 'Kalem rengi';

  @override
  String get cardMediaHide => 'Görsel önizlemesini gizle';

  @override
  String get cardMediaShow => 'Görsel önizlemesini göster';

  @override
  String get youTubeEmbedInNote => 'Nota göm';

  @override
  String get goToLink => 'Bağlantıya git';

  @override
  String get noteFlatColors => 'Düz renkler';

  @override
  String get youTubeEmbedded => 'Video nota gömüldü';

  @override
  String get inkLasso => 'Kement (seç ve taşı)';

  @override
  String get inkLassoHint =>
      'Çizgilerin çevresini çiz: seçilenler taşınır, renk seçmek boyar.';

  @override
  String get inkDeleteSelection => 'Seçileni sil';

  @override
  String get inkClearSelection => 'Seçimi bırak';

  @override
  String get inkShapeSnapTitle => 'Basılı tutunca şekle dönüştür';

  @override
  String get inkShapeSnapInfo =>
      'Çizgi sonunda kalemi bekletince düz çizgi, daire ya da kare olur.';

  @override
  String get inkQuickSwapTitle => 'Kalem ↔ silgi hızlı düğmesi';

  @override
  String get inkQuickSwapInfo =>
      'Çizgi bitince kalem ile silgi arasında geçiş düğmesi belirir.';

  @override
  String get inkQuickSwapToEraser => 'Silgiye geç';

  @override
  String get inkQuickSwapToPen => 'Kaleme dön';

  @override
  String get inkPartialEraserTitle => 'Kısmi silgi';

  @override
  String get inkPartialEraserInfo =>
      'Silgi yalnız değdiği kısmı siler; kapalıyken bütün çizgiyi siler.';

  @override
  String get inkAutoStylusTitle => 'Kalemi otomatik algıla';

  @override
  String get inkAutoStylusInfo =>
      'Kalem nota değince yazma kipi kendiliğinden açılır.';

  @override
  String get inkStylusDetected => 'Kalem algılandı — yazma kipi açıldı';

  @override
  String get copyAndCheckSelectedItems => 'Kopyala ve işaretle';

  @override
  String get copiedAndChecked => 'Kopyalandı ve işaretlendi';

  @override
  String get formatScopeCaret => 'İmleç';

  @override
  String get formatScopeWord => 'Kelime';

  @override
  String get formatScopeLine => 'Satır';

  @override
  String get formatScopeAll => 'Tümü';

  @override
  String get formatScopeSelection => 'Seçim';

  @override
  String get formatScopeHint =>
      'Biçim neye uygulansın: imleç, kelime, satır ya da tümü';

  @override
  String get formatStyleMenu => 'Paragraf stili';

  @override
  String get colorNameCoral => 'Mercan';

  @override
  String get colorNamePeach => 'Şeftali';

  @override
  String get colorNameHoney => 'Bal';

  @override
  String get colorNameSage => 'Adaçayı';

  @override
  String get colorNameStorm => 'Fırtına';

  @override
  String get colorNameLavender => 'Lavanta';

  @override
  String get colorNameClay => 'Kil';

  @override
  String get colorNameChalk => 'Tebeşir';

  @override
  String get colorNameRed => 'Kırmızı';

  @override
  String get colorNameYellow => 'Sarı';

  @override
  String get colorNameGreen => 'Yeşil';

  @override
  String get colorNameBlue => 'Mavi';

  @override
  String get colorNamePurple => 'Mor';

  @override
  String get colorNameNone => 'Renksiz';

  @override
  String get colorNameOrange => 'Turuncu';

  @override
  String get colorNamePink => 'Pembe';

  @override
  String get colorNameGray => 'Gri';

  @override
  String get colorNameCyan => 'Camgöbeği';

  @override
  String get colorNameWhite => 'Beyaz';

  @override
  String get colorNameBlack => 'Siyah';

  @override
  String get colorToneLight => 'açık';

  @override
  String get colorToneVivid => 'canlı';

  @override
  String get colorToneDark => 'koyu';

  @override
  String colorShade(String color, String tone) {
    return '$color, $tone';
  }

  @override
  String get itemEmptyLabel => 'Boş madde';

  @override
  String bubbleSemantic(int page, String text) {
    return 'Balon, sayfa $page: $text';
  }

  @override
  String bubbleSemanticEmpty(int page) {
    return 'Boş balon, sayfa $page';
  }

  @override
  String mediaBoxSemantic(String kind, String name) {
    return '$kind: $name';
  }

  @override
  String get formatSizeLabel => 'Boyut';

  @override
  String formatSizeValue(int percent) {
    return 'Boyut %$percent';
  }

  @override
  String get customColor => 'Özel renk…';

  @override
  String get embedLasso => 'Daire çizerek seç';

  @override
  String embedLassoHint(String name) {
    return '$name bağlanacak — yazıyı daire içine al ya da kelimeye dokun · iki parmakla kaydır';
  }

  @override
  String get embedSelectMode => 'Seçerek bağla';

  @override
  String get embedLassoMissed =>
      'Dairenin içinde yazı bulunamadı — yazının çevresine çiz';

  @override
  String get gestureItemDeleted => 'Madde silindi';

  @override
  String get itemGesturesSetting => 'Madde jestleri';

  @override
  String get itemGesturesSettingInfo =>
      'Maddeye çiz: üstünü çizer ya da ✓ koyar; karalama siler.';

  @override
  String get pdfEditWorking => 'PDF işleniyor…';

  @override
  String get noteMenu => 'Not menüsü';

  @override
  String get moreActions => 'Diğer işlemler';

  @override
  String get errorOffline =>
      'İnternet bağlantısı yok ya da zayıf. Bağlanınca yeniden dene.';

  @override
  String get errorTimeout => 'İşlem çok uzun sürdü. Biraz sonra yeniden dene.';

  @override
  String get errorQuota =>
      'Kullanım sınırına ulaşıldı. Biraz sonra yeniden dene.';

  @override
  String get errorPermission =>
      'Bunun için izin yok. Hesabını ya da uygulama izinlerini kontrol et.';

  @override
  String get errorTooLarge => 'Dosya çok büyük.';

  @override
  String get errorUnsupported => 'Bu işlem burada desteklenmiyor.';

  @override
  String get errorUnknown =>
      'Beklenmeyen bir sorun oldu. Ayrıntı hata günlüğünde.';

  @override
  String get errorStateTitle => 'Yüklenemedi';

  @override
  String get errorStateOfflineTitle => 'Bağlantı yok';

  @override
  String get copyErrorDetail => 'Ayrıntıyı kopyala';

  @override
  String get accountRequiredTitle => 'Google hesabı gerekir';

  @override
  String get accountRequiredBody =>
      'Kişiler, ortak çalışma ve kopya gönderme e-posta adresiyle çalışır; hesapsız kullanımda seni kimse bulamaz. Google hesabını bağla — notların olduğu gibi kalır.';

  @override
  String get accountRequiredBadge => 'Google hesabı gerekir';

  @override
  String get deletingAccount => 'Hesabın ve verilerin siliniyor…';

  @override
  String get sharedHubShort => 'Gelen';

  @override
  String get itemEmptyHint => 'Madde yaz';

  @override
  String get allFolders => 'Tüm klasörler';

  @override
  String get guestReminderConnect => 'Bağla';

  @override
  String get filterSectionType => 'Tür';

  @override
  String get reorderNotesManually => 'Elle sırala';

  @override
  String get shareIncludeBubbles => 'Balonlar';

  @override
  String sharedFolderBar(String role) {
    return 'Paylaşılan klasör · $role';
  }

  @override
  String get shareSendSection => 'Dışarı gönder';

  @override
  String get shareInAppSection => 'Kişilerle';

  @override
  String get shareTextHint =>
      'Notun yazısını bir uygulamaya gönderir (WhatsApp, e-posta…)';

  @override
  String get shareCopyHint => 'Notun yazısını panoya kopyalar';

  @override
  String get shareQuickPdfHint =>
      'Notu tek dokunuşla PDF dosyası olarak gönderir';

  @override
  String get shareAsImageHint => 'Notu sayfa sayfa resim olarak gönderir';

  @override
  String get shareAttachmentFilesHint =>
      'Nottaki fotoğraf, PDF, ses ve videoların kendisini gönderir';

  @override
  String get shareAsNoteInfo =>
      'Ekler, sayfalar, çizim ve balonlarla tek dosya; Notlar\'da birebir açılır';

  @override
  String get bubbleCopy => 'Kopyala';

  @override
  String get bubblesCopyAll => 'Tümünü kopyala';

  @override
  String get bubblesToNote => 'Nota aktar';

  @override
  String get bubblesToNoteDone => 'Balonlar notun sonuna eklendi';

  @override
  String get bubbleMark => 'İşaret';

  @override
  String get bubbleFormat => 'Biçim';

  @override
  String get sharedHubTagInbox => 'Gelen';

  @override
  String get sharedHubTagShared => 'Paylaşılan';

  @override
  String get sharedHubEmpty => 'Burada gelen ya da paylaşılan not yok';

  @override
  String get sharedHubEmptyHint =>
      'Arkadaşlarının gönderdiği kopyalar ve seni eklediği ortak notlar burada birlikte görünür.';

  @override
  String get settingsModulesTitle => 'Eklentiler ve hızlı not';

  @override
  String settingsModulesSummary(int on, int total) {
    return '$on/$total eklenti açık';
  }

  @override
  String get settingsSoundTitle => 'Sesli dinle ve dikte';

  @override
  String cardElementsSummary(int on, int total) {
    return '$on/$total açık · örnekle gör';
  }

  @override
  String get cardElementsSampleTitle => 'Hafta sonu alışverişi';

  @override
  String cardElementsSampleItem(int n) {
    return 'Madde $n';
  }

  @override
  String get cardElementsSampleTag => 'ev';

  @override
  String get tipListGestures =>
      'İpucu: maddenin üstünü parmakla çiz → işaretlenir.';

  @override
  String get tipMediaPin =>
      'İpucu: görsele basılı tut, en üste sürükle → notun tepesine sabitlenir.';

  @override
  String get tipGridSwipeFolders =>
      'İpucu: ekranı yana kaydır → klasörler arasında geç.';

  @override
  String get tipGridSwipeFilters =>
      'İpucu: ekranı yana kaydır → süzgeçler arasında geç.';

  @override
  String get tipsResetTitle => 'İpuçlarını yeniden göster';

  @override
  String get tipsResetInfo =>
      'Bir kez çıkan küçük ipuçları (jestler, Anlam araması) yeniden çıkar.';

  @override
  String get tipsResetDone => 'İpuçları yeniden gösterilecek';

  @override
  String get tipsEnabledTitle => 'İpuçlarını göster';

  @override
  String get tipsEnabledInfo =>
      'Araçları ilk kez kullanırken kısa, rahatsız etmeyen ipuçları çıkar.';

  @override
  String get tipFormatScope =>
      'İpucu: Kapsam düğmesiyle imleç, kelime, satır veya tümüne uygula; yüzdeye basınca boyut %100\'e döner.';

  @override
  String get tipTableGestures =>
      'İpucu: Sütun çizgisini sürükle → genişlik ayarlanır; Tab ile sonraki hücreye geç.';

  @override
  String get tipItemHoldSelect =>
      'İpucu: Maddeyi basılı tut → çoklu seç; aralık, ters çevir ve toplu biçim alttan açılır.';

  @override
  String get tipVoiceCommands =>
      'İpucu: Diktede \"yeni satır\", \"yeni madde\", \"nokta\" veya \"son kelimeyi sil\" de.';

  @override
  String get tipFolderGestures =>
      'İpucu: Notta veya rafta klasöre basılı tut → hızlı eylemler; notu sürükleyip klasöre bırak → taşınır.';

  @override
  String get tipPinnedSplitResize =>
      'İpucu: Bölme kolunu sürükle → boyutu ayarla; üst çubuktan sabit eki sağa ya da sola al.';

  @override
  String get tipPinnedSmartActions =>
      'İpucu: Sabit ek çubuğundan akıllı işlemleri aç; sayfayı özetle, metni çıkar ya da seçili alana sor.';

  @override
  String get tipCrossAppDosyalarim =>
      'İpucu: Eklediğin PDF ve dosyaları Dosyalarım ile aç; ortak yapay zekâ havuzun iki uygulamada da çalışır.';

  @override
  String get swipeModeInfo =>
      'Izgarada ekranı yana kaydırınca ne olsun; listede satır kaydırma sabitler ya da arşivler.';

  @override
  String get backupInfo =>
      'Bütün notlar ekleri ve klasörleriyle tek dosyada; iki kez yüklemek çoğaltmaz.';

  @override
  String get backupInProgress => 'Yedek hazırlanıyor';

  @override
  String get restoreInProgress => 'Geri yükleniyor';

  @override
  String get backupShareSubject => 'Notlar yedeği';

  @override
  String get backupCancelled => 'İptal edildi';

  @override
  String backupProgressCount(int done, int total) {
    return '$done / $total not';
  }

  @override
  String restoreBackupResult(int restored, int skipped) {
    return '$restored not geri yüklendi, $skipped atlandı (zaten var)';
  }

  @override
  String get accountRecoverBringNotes => 'Notları yanıma al';

  @override
  String accountRecoverBringDone(int count) {
    return 'Hesabına geçildi, $count not taşındı';
  }

  @override
  String get accountRecoverBringFailed =>
      'Hesabına geçildi ama notlar taşınamadı; misafir notları yerinde duruyor';

  @override
  String get appLockTitle => 'Uygulama kilidi';

  @override
  String get appLockInfo =>
      'Açılışta ve arka plandan dönüşte not kilidinin yöntemiyle sorar. Şifreleme değildir; yalnız bu cihazda geçerli.';

  @override
  String get appLockWebNeedsSecret =>
      'Web\'de cihaz kilidi yok: önce yukarıdan şifre ya da desen seç.';

  @override
  String get appLockReason => 'Notlar\'ın kilidini aç';

  @override
  String get appLockLockedTitle => 'Notlar kilitli';

  @override
  String get appLockUnlock => 'Kilidi aç';

  @override
  String get appLockDelayTitle => 'Kilitle:';

  @override
  String get appLockDelayNow => 'hemen';

  @override
  String appLockDelayMinutes(int minutes) {
    return '$minutes dk sonra';
  }

  @override
  String get appLockHideRecents => 'Son uygulamalarda içeriği gizle';

  @override
  String get repeatTitle => 'Tekrar';

  @override
  String get repeatNone => 'Tekrarlama';

  @override
  String get repeatDaily => 'Her gün';

  @override
  String get repeatWeekdays => 'Hafta içi her gün';

  @override
  String get repeatWeekly => 'Her hafta';

  @override
  String repeatWeeklyOn(String days) {
    return 'Her hafta: $days';
  }

  @override
  String get repeatMonthly => 'Her ay';

  @override
  String get repeatYearly => 'Her yıl';

  @override
  String get importOther => 'Başka uygulamadan içe aktar';

  @override
  String get importOtherInfo =>
      'Google Keep (Takeout zip\'i), Markdown/txt (tek dosya ya da zip), Evernote (.enex)';

  @override
  String get importInProgress => 'İçe aktarılıyor';

  @override
  String get importOtherNone => 'Bu dosyada içe aktarılacak not bulunamadı';

  @override
  String importOtherResult(int imported, int skipped, int failed) {
    return '$imported not içe aktarıldı, $skipped atlandı (zaten var), $failed okunamadı';
  }

  @override
  String get noteLinkAction => 'Nota bağla';

  @override
  String get noteLinkOpen => 'Notu aç';

  @override
  String get noteLinkPickTitle => 'Hangi nota bağlansın?';

  @override
  String get noteLinkInserted => 'Nota bağlandı';

  @override
  String get noteLinkMissing => 'Bağlı not bulunamadı (silinmiş olabilir)';

  @override
  String get backlinksTitle => 'Bu nota bağlananlar';

  @override
  String backlinksCount(int count) {
    return '$count bağlantı';
  }

  @override
  String get relatedNotesTitle => 'İlgili notlar';

  @override
  String get relatedNotesNone => 'İlgili not bulunamadı';

  @override
  String get relatedNotesLink => 'Bağla';

  @override
  String get studyCardsTitle => 'Bugünün kartları';

  @override
  String get studyCardsEmpty => 'Burada bugün tekrar edilecek kart yok';

  @override
  String get studyCardsDone => 'Bugünlük bitti!';

  @override
  String get studyCardsEmptyInfo =>
      'Bir notun ⋮ menüsünden \"Kart üret\" ile yapay zekâ nottan soru–cevap kartları çıkarır.';

  @override
  String studyCardsLeft(int count) {
    return '$count kart kaldı';
  }

  @override
  String get studyCardsReveal => 'Cevabı göster';

  @override
  String get studyGradeAgain => 'Tekrar';

  @override
  String get studyGradeHard => 'Zor';

  @override
  String get studyGradeGood => 'İyi';

  @override
  String get studyGradeEasy => 'Kolay';

  @override
  String updateAvailable(String name) {
    return 'Yeni sürüm var: $name';
  }

  @override
  String get pdfNoteFromSelection => 'Not al';

  @override
  String get pdfNoteAtPage => 'Bu sayfaya not al';

  @override
  String get tipPdfReadNote =>
      'İpucu: yazıya basılı tut, seç → \"Not al\": sayfa ve satır nota yazılır, dokununca oraya döner.';

  @override
  String showMoreChecked(int n) {
    return 'İşaretlileri göster ($n gizli)';
  }

  @override
  String get hideMoreChecked => 'İşaretlileri daralt';

  @override
  String get gmailGoogleOnly => 'Gmail için Google hesabıyla giriş yap.';

  @override
  String get tipHomeMicHold =>
      'İpucu: mikrofona basılı tutarsan AI sesli not açılır.';

  @override
  String get itemGesturesFingerAll => 'Sil ve düzelt jestleri parmakla da';

  @override
  String get itemGesturesFingerAllInfo =>
      'Kapalıyken parmak yalnız işaretler; karalama ve daire kalemle.';

  @override
  String get itemAddHeader => 'Ara başlık';

  @override
  String get itemHeaderHint => 'Ara başlık yaz';

  @override
  String get itemMenuToHeader => 'Başlık yap';

  @override
  String get itemMenuToItem => 'Maddeye çevir';

  @override
  String get pinnedMediaFit => 'Sığdır';

  @override
  String get tagRemove => 'Etiketi kaldır';

  @override
  String get itemAlignStart => 'Sola hizala';

  @override
  String get itemAlignCenter => 'Ortala';

  @override
  String get itemAlignEnd => 'Sağa hizala';

  @override
  String get themeLavender => 'Lavanta';

  @override
  String get themeOlive => 'Zeytin';

  @override
  String get tplShopMeat => 'Et, tavuk ve balık';

  @override
  String get tplShopMeatItems =>
      'Kıyma, Tavuk göğsü, Tavuk but, Kuşbaşı et, Balık, Sucuk, Hindi füme, Köfte';

  @override
  String get tplShopDrinks => 'İçecek';

  @override
  String get tplShopDrinksItems =>
      'Su, Maden suyu, Meyve suyu, Ayran, Gazoz, Soğuk çay, Süt';

  @override
  String get tplShopSnacks => 'Atıştırmalık';

  @override
  String get tplShopSnacksItems =>
      'Bisküvi, Çikolata, Cips, Kuruyemiş, Kraker, Gofret, Kuru meyve';

  @override
  String get tplShopFrozen => 'Dondurulmuş';

  @override
  String get tplShopFrozenItems =>
      'Dondurma, Bezelye, Patates kızartması, Mantı, Pizza, Börek';

  @override
  String get tplShopBaby => 'Bebek';

  @override
  String get tplShopBabyItems =>
      'Bez, Islak mendil, Mama, Bebek şampuanı, Pişik kremi';

  @override
  String get tplShopPet => 'Evcil hayvan';

  @override
  String get tplShopPetItems =>
      'Kedi maması, Köpek maması, Kum, Ödül maması, Tüy toplayıcı';

  @override
  String get tplTravelHealth => 'Sağlık';

  @override
  String get tplTravelHealthItems =>
      'Ağrı kesici, Yara bandı, Mide ilacı, Reçeteli ilaçlar, Sivrisinek kovucu, Maske';

  @override
  String get tplTravelBeforeGo => 'Çıkmadan önce';

  @override
  String get tplTravelBeforeGoItems =>
      'Ocağı kontrol et, Pencereleri kapat, Çöpü at, Bitkileri sula, Fişleri çek, Anahtarları al';

  @override
  String get tplCleanKitchen => 'Mutfak';

  @override
  String get tplCleanKitchenItems =>
      'Bulaşık, Tezgâh, Ocak, Fırın içi, Buzdolabı, Lavabo, Mikrodalga';

  @override
  String get tplCleanBath => 'Banyo';

  @override
  String get tplCleanBathItems =>
      'Klozet, Lavabo, Duş, Ayna, Fayans derzleri, Havluları değiştir';

  @override
  String get tplCleanRooms => 'Odalar';

  @override
  String get tplCleanRoomsItems =>
      'Toz al, Süpür, Paspas, Yatakları topla, Camları sil, Halıları silkele';

  @override
  String get tplCleanMonthly => 'Aylık';

  @override
  String get tplCleanMonthlyItems =>
      'Perdeler, Klima filtresi, Dolap içleri, Çamaşır makinesi bakımı, Davlumbaz filtresi';

  @override
  String get tplMoveBefore => 'Taşınmadan önce';

  @override
  String get tplMoveBeforeItems =>
      'Nakliyeci ayarla, Koli ve bant al, Eşyaları ayıkla, Kolileri etiketle, Abonelikleri bildir, Adres değişikliği';

  @override
  String get tplMoveDay => 'Taşınma günü';

  @override
  String get tplMoveDayItems =>
      'Sayaçların fotoğrafı, Anahtar teslimi, Değerli eşyaları yanına al, Son kontrol, İlk gece çantası';

  @override
  String get tplMoveAfter => 'Taşındıktan sonra';

  @override
  String get tplMoveAfterItems =>
      'İnternet kurulumu, Muhtarlık kaydı, Kilitleri değiştir, Banka adresini güncelle, Komşularla tanış';

  @override
  String get tplHabitHealth => 'Sağlık';

  @override
  String get tplHabitHealthItems =>
      '8 bardak su, 30 dakika yürüyüş, Erken yat, Şekersiz gün, Vitamin al, Esneme';

  @override
  String get tplHabitMind => 'Zihin';

  @override
  String get tplHabitMindItems =>
      '20 sayfa kitap, Meditasyon, Günlük yaz, Ekransız bir saat, Yeni kelime öğren';

  @override
  String get tplHabitHome => 'Ev ve düzen';

  @override
  String get tplHabitHomeItems =>
      'Bulaşığı bitir, 10 dakika toparlan, Bitkileri sula, Yarını planla';

  @override
  String get tplWorkoutUpper => 'Üst vücut';

  @override
  String get tplWorkoutUpperItems =>
      'Şınav 3×10, Barfiks 3×6, Omuz pres 3×10, Biceps curl 3×12, Triceps dips 3×10, Plank 3×45 sn';

  @override
  String get tplWorkoutLower => 'Alt vücut';

  @override
  String get tplWorkoutLowerItems =>
      'Squat 3×12, Lunge 3×10, Köprü 3×15, Baldır 3×20, Duvar oturuşu 3×40 sn';

  @override
  String get tplWorkoutCardio => 'Kardiyo';

  @override
  String get tplWorkoutCardioItems =>
      'Koşu 20 dk, İp atlama 5 dk, Bisiklet 30 dk, Jumping jack 3×30, Burpee 3×10';

  @override
  String get tplGiftPeople => 'Kişiler';

  @override
  String get tplGiftPeopleItems =>
      'Anne, Baba, Kardeş, Eş, Arkadaş, Öğretmen, İş arkadaşı, Çocuk';

  @override
  String get tplGiftIdeas => 'Fikirler';

  @override
  String get tplGiftIdeasItems =>
      'Kitap, Çiçek, Parfüm, Saat, Deneyim hediyesi, El yapımı, Kupa, Hediye çeki';

  @override
  String get tplTodoHome => 'Ev';

  @override
  String get tplTodoHomeItems =>
      'Faturaları öde, Çamaşır, Market, Tamir işleri, Randevu al';

  @override
  String get tplTodoErrands => 'Dışarıda';

  @override
  String get tplTodoErrandsItems =>
      'Bankaya uğra, Kargo gönder, Eczane, Kuru temizleme, Postane';

  @override
  String get templateFavorite => 'Favorilere ekle';

  @override
  String get templateUnfavorite => 'Favorilerden çıkar';

  @override
  String get templatesFavorites => 'Favoriler';

  @override
  String get templateFavoritesFull =>
      'En çok 4 favori seçilebilir — önce birini çıkar';

  @override
  String get calendarTitle => 'Takvim';

  @override
  String get calendarToday => 'Bugün';

  @override
  String get calendarViewAgenda => 'Ajanda';

  @override
  String get calendarViewMonth => 'Ay';

  @override
  String get calendarNewEvent => 'Yeni etkinlik';

  @override
  String get calendarEmpty => 'Burada henüz etkinlik yok';

  @override
  String get calendarEmptyHint =>
      'Etkinlik ekle; hatırlatıcılı notlar da burada görünür.';

  @override
  String get calendarNothingThisDay => 'Bu gün için plan yok';

  @override
  String get calendarReminderTag => 'Hatırlatıcı';

  @override
  String get calendarShowMonth => 'Ayı göster';

  @override
  String get calendarHideMonth => 'Ayı gizle';

  @override
  String get calendarPrevMonth => 'Önceki ay';

  @override
  String get calendarNextMonth => 'Sonraki ay';

  @override
  String get calendarMoreDays => 'Daha ileri';

  @override
  String get eventEditTitle => 'Etkinliği düzenle';

  @override
  String get eventTitleHint => 'Başlık ekle';

  @override
  String get eventUntitled => '(Başlıksız)';

  @override
  String get eventAllDay => 'Tüm gün';

  @override
  String get eventStarts => 'Başlangıç';

  @override
  String get eventEnds => 'Bitiş';

  @override
  String get eventReminder => 'Hatırlatma';

  @override
  String get eventReminderNone => 'Hatırlatma yok';

  @override
  String get eventReminderAtStart => 'Başladığında';

  @override
  String get eventReminderAllDayMorning => 'O gün 09:00\'da';

  @override
  String eventReminderMinutes(int count) {
    return '$count dakika önce';
  }

  @override
  String eventReminderHours(int count) {
    return '$count saat önce';
  }

  @override
  String eventReminderDays(int count) {
    return '$count gün önce';
  }

  @override
  String get eventLocation => 'Konum';

  @override
  String get eventDescription => 'Açıklama';

  @override
  String get eventSave => 'Kaydet';

  @override
  String get eventDelete => 'Etkinliği sil';

  @override
  String get eventDeleted => 'Etkinlik silindi';

  @override
  String get eventDeleteRepeatingTitle => 'Tekrarlayan etkinlik';

  @override
  String get eventDeleteThis => 'Yalnız bu etkinlik';

  @override
  String get eventDeleteAll => 'Tüm tekrarlar';

  @override
  String get eventNotificationAllDay => 'Bugün · tüm gün';

  @override
  String get tasksTitle => 'Görevler';

  @override
  String get tasksDefaultList => 'Görevlerim';

  @override
  String get tasksNewTask => 'Yeni görev';

  @override
  String get tasksNewList => 'Yeni liste';

  @override
  String get tasksListNameHint => 'Liste adı';

  @override
  String get tasksRenameList => 'Listeyi yeniden adlandır';

  @override
  String get tasksDeleteList => 'Listeyi sil';

  @override
  String get tasksDeleteListConfirm =>
      'Liste ve içindeki görevler silinsin mi?';

  @override
  String get tasksEmpty => 'Burada görev yok';

  @override
  String get tasksEmptyHint =>
      'Yapılacakları ekle; son tarihli görevler takvimde de görünür.';

  @override
  String tasksCompleted(int count) {
    return 'Tamamlananlar ($count)';
  }

  @override
  String get tasksClearCompleted => 'Tamamlananları sil';

  @override
  String get taskEditTitle => 'Görevi düzenle';

  @override
  String get taskTitleHint => 'Ne yapılacak?';

  @override
  String get taskNotesHint => 'Ayrıntı ekle';

  @override
  String get taskDue => 'Son tarih';

  @override
  String get taskNoDue => 'Tarih yok';

  @override
  String get taskTime => 'Saat';

  @override
  String get taskNoTime => 'Saat yok';

  @override
  String get taskReminderAtDue => 'Zamanı gelince hatırlat';

  @override
  String get taskList => 'Liste';

  @override
  String get taskStar => 'Yıldızla';

  @override
  String get taskDelete => 'Görevi sil';

  @override
  String get taskDeleted => 'Görev silindi';

  @override
  String get taskAddSubtask => 'Alt görev ekle';

  @override
  String get taskOverdue => 'Gecikti';

  @override
  String get calendarViewYear => 'Yıl';

  @override
  String get calendarViewWeek => 'Hafta';

  @override
  String get calendarPinchHint =>
      'İki parmakla yıl, ay ve hafta arasında geçebilirsin';

  @override
  String get calendarPrevious => 'Önceki';

  @override
  String get calendarNext => 'Sonraki';

  @override
  String get themeWhite => 'Beyaz';

  @override
  String get themeStraw => 'Saman';

  @override
  String get calendarSwipe => 'Takvimde kaydırarak hafta/gün değiştir';

  @override
  String get calendarSwipeInfo =>
      'Kapalıyken yalnız ok düğmeleri ay ya da hafta değiştirir.';

  @override
  String calendarMoved(String day) {
    return '$day gününe taşındı';
  }

  @override
  String get gcalTitle => 'Google Takvim';

  @override
  String get gcalInfo =>
      'Google Takvim\'indeki etkinlikler takvimde görünür (yalnız okunur). Etkinliğe not bağlayabilirsin; Google\'a bir şey yazılmaz.';

  @override
  String get gcalConnect => 'Google Takvim\'i bağla';

  @override
  String get gcalConnectFailed => 'Google Takvim bağlanamadı';

  @override
  String get gcalCalendars => 'Gösterilen takvimler';

  @override
  String get gcalRefresh => 'Yenile';

  @override
  String get gcalDisconnect => 'Bağlantıyı kaldır';

  @override
  String get gcalError =>
      'Google Takvim\'e şu an ulaşılamadı; önbellekteki etkinlikler gösteriliyor.';

  @override
  String get gcalReadOnly =>
      'Google Takvim etkinliği · tekrarlı olanlar Google Takvim\'de düzenlenir';

  @override
  String get gcalOpenInGoogle => 'Google Takvim\'de aç';

  @override
  String get calendarMeetingNote => 'Toplantı notu';

  @override
  String get calendarLinkedNotes => 'Bağlı notlar';

  @override
  String get calendarUnlinkNote => 'Bağı kaldır';

  @override
  String gcalSyncedAt(String time) {
    return 'Son eşitleme $time';
  }

  @override
  String get calendarLinked => 'Takvime bağlandı';

  @override
  String get calendarLinkNote => 'Takvime bağla';

  @override
  String get calendarLinkToDay => 'Bir güne bağla';

  @override
  String get calendarLinkNewEvent => 'Yeni etkinlik oluştur ve bağla';

  @override
  String get calendarLinkToEvent => 'Bir etkinliğe bağla';

  @override
  String get calendarHolidays => 'Resmî ve dinî tatiller';

  @override
  String get calendarHolidayEstimated => 'tahmini';

  @override
  String get calendarDayNote => 'Bu güne not';

  @override
  String calendarDayWrittenNotes(int count) {
    return 'O gün yazılan notlar ($count)';
  }

  @override
  String calendarMoreCount(int count) {
    return '+$count daha';
  }

  @override
  String get calendarWeekSummaryTitle => 'Bu hafta';

  @override
  String calendarWeekSummaryPlans(int count) {
    return '$count plan';
  }

  @override
  String calendarWeekSummaryNotes(int count) {
    return '$count not';
  }

  @override
  String get itemMenuTask => 'Görev yap';

  @override
  String get gtasksTitle => 'Google Görevler';

  @override
  String get gtasksConnected => 'Google Görevler bağlandı, görevler eşlendi';

  @override
  String get gtasksFailed => 'Google Görevler ile eşlenemedi';

  @override
  String get gtasksSyncNow => 'Şimdi eşle';

  @override
  String get gtasksSynced => 'Görevler eşlendi';

  @override
  String get eventSaveLocal => 'Tüm cihazlar';

  @override
  String get gcalWriteDenied => 'Google Takvim\'e yazma izni verilmedi';

  @override
  String get gcalDeleteConfirm =>
      'Etkinlik Google Takvim\'den silinsin mi? Bu geri alınamaz.';

  @override
  String get gcalEdit => 'Düzenle';

  @override
  String gcalPending(int count) {
    return 'Google\'a gönderilmeyi bekleyen $count değişiklik';
  }

  @override
  String get ocrToEvent => 'Takvime etkinlik olarak ekle';

  @override
  String get calendarSuggestAction => 'Takvime ekle';

  @override
  String calendarSuggest(String when) {
    return 'Notta $when geçiyor';
  }

  @override
  String get calendarIcsExport => 'Takvimi dışa aktar (.ics)';

  @override
  String get calendarIcsImport => 'Takvim dosyası içe aktar (.ics)';

  @override
  String calendarIcsImported(int count, int skipped) {
    return '$count etkinlik eklendi, $skipped zaten vardı';
  }

  @override
  String get routinesTitle => 'Rutinler';

  @override
  String get routineNew => 'Yeni rutin';

  @override
  String get routineEdit => 'Rutini düzenle';

  @override
  String get routinesEmpty => 'Burada henüz rutin yok';

  @override
  String get routinesEmptyHint =>
      'Sabah rutini gibi tekrarlayan bir plan kur: adımlarını tikle, serini gör.';

  @override
  String get routineDoneToday => 'Bugün tamamlandı';

  @override
  String get routineStartToday => 'Bugünü işaretle';

  @override
  String get routineDone => 'Tamamlandı';

  @override
  String get routineTitleHint => 'Rutinin adı';

  @override
  String get routineTime => 'Saat';

  @override
  String get routineRemind => 'Zamanı gelince hatırlat';

  @override
  String get routineSteps => 'Adımlar';

  @override
  String get routineStepHint => 'Adım';

  @override
  String get routineAddStep => 'Adım ekle';

  @override
  String get routineDeleted => 'Rutin silindi';

  @override
  String routineStreak(int count) {
    return '🔥 $count gün';
  }

  @override
  String routineStepCount(int count) {
    return '$count adım';
  }

  @override
  String routineProgress(int done, int total) {
    return '$done/$total adım';
  }

  @override
  String get menuSearchHint => 'Ara: ad ya da işlev (ör. topla, paylaş)';

  @override
  String get menuSearchEmpty => 'Eşleşen işlem yok';

  @override
  String get menuEdit => 'Menüyü düzenle';

  @override
  String get menuSectionOther => 'Diğer';

  @override
  String get menuQuickRow => 'Hızlı satıra al';

  @override
  String get menuReset => 'Varsayılan';

  @override
  String get themeCream => 'Krem';

  @override
  String get themePeach => 'Şeftali';

  @override
  String get themeMint => 'Nane';

  @override
  String get themeOcean => 'Okyanus';

  @override
  String get themeRose => 'Gül';

  @override
  String get themeTangerine => 'Mandalina';

  @override
  String get themeEmerald => 'Zümrüt';

  @override
  String get themeAmethyst => 'Ametist';

  @override
  String get themePickerTitle => 'Tema';

  @override
  String get reminderQuickInHour => '1 saat sonra';

  @override
  String get reminderSheetTitle => 'Hatırlatıcı';

  @override
  String get reminderSheetRemove => 'Kaldır';

  @override
  String get reminderSheetSave => 'Kaydet';

  @override
  String get homeFolderStripHide => 'Klasör satırını gizle';

  @override
  String get homeViewMenu => 'Görünüm ve süz';

  @override
  String googleApiDisabled(String api) {
    return '$api bu uygulamanın Google Cloud projesinde kapalı. Konsolda etkinleştirip yeniden bağlanın.';
  }

  @override
  String get googleApiEnable => 'Etkinleştir';

  @override
  String googleScopeMissing(String api) {
    return '$api izni verilmedi. Bağlanırken izin kutusunu işaretleyin.';
  }

  @override
  String get friendsEmptyTitle => 'Burada henüz kişi yok';

  @override
  String get friendsFilterHint => 'Kişilerde ara';

  @override
  String get friendsNoName => 'Ad yok';

  @override
  String get friendsSharedFolders => 'Paylaşılan klasörler';

  @override
  String get friendsNoSharedFolders => 'Bu kişiyle henüz klasör paylaşmadın.';

  @override
  String friendsSince(String date) {
    return '$date tarihinden beri kişilerinde';
  }

  @override
  String get friendsCopyEmail => 'E-postayı kopyala';

  @override
  String get friendsEmailCopied => 'E-posta kopyalandı';

  @override
  String get friendsWantsToConnect => 'Seni kişilerine eklemek istiyor';

  @override
  String get friendsSendToEmail => 'Bu adrese istek gönder';

  @override
  String get friendsSent => 'Gönderildi';

  @override
  String get friendsAlreadyShort => 'Kişilerinde';

  @override
  String get settingsGroupAccount => 'Hesap';

  @override
  String get settingsGroupApp => 'Uygulama';

  @override
  String get settingsUpdatesTitle => 'Güncelleme ve sürüm';

  @override
  String get settingsGroupData => 'Veri ve gizlilik';

  @override
  String get settingsGroupOther => 'Diğer';

  @override
  String friendsCountSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kişi',
      zero: 'Henüz kişi yok',
    );
    return '$_temp0';
  }

  @override
  String friendsRequestsSummary(int count) {
    return '$count istek bekliyor';
  }

  @override
  String get inkFixApply => 'Düzgün şekle getir';

  @override
  String get inkShapeSuggestTitle => 'Şekli tanı ve düzeltmeyi öner';

  @override
  String get inkShapeSuggestInfo =>
      'Kaba daire, kare, çizgi ya da ok çizince düzeltme düğmesi çıkar.';

  @override
  String get inkMarkFixTitle => 'Tik ve çarpıyı düzelt';

  @override
  String get inkMarkFixInfo =>
      'Elle çizilen ✓ ve ✗ işaretleri için düzeltme düğmesi çıkar.';

  @override
  String get inkMarkFixAskTitle => 'Otomatik düzeltme açılsın mı?';

  @override
  String get inkMarkFixAskBody =>
      'Elle çizdiğin tik ve çarpılar temiz hâle getirilebilir. Her seferinde yanındaki küçük düğmeyle onaylarsın; kalem ayarlarından kapatabilirsin.';

  @override
  String get inkMarkFixAskYes => 'Aç';

  @override
  String get inkMarkFixAskNo => 'Hayır';

  @override
  String get inkPinPen => 'Bu kalemi sabitle';

  @override
  String get inkPinnedPen => 'Sabit kalem · basılı tut: kaldır';

  @override
  String get reminderLevelTitle => 'Bildirim';

  @override
  String get reminderLevelLow => 'Az';

  @override
  String get reminderLevelNormal => 'Orta';

  @override
  String get reminderLevelHigh => 'Sık';

  @override
  String get reminderLevelUrgent => 'Acil';

  @override
  String get reminderLevelLowInfo => 'Sessiz; yalnız bildirim alanında görünür';

  @override
  String get reminderLevelNormalInfo => 'Normal ses, ekranın üstünde açılmaz';

  @override
  String get reminderLevelHighInfo => 'Sesli, ekranın üstünde öne çıkar';

  @override
  String get reminderLevelUrgentInfo =>
      'Tam ekran, en yüksek öncelik (alarm gibi)';

  @override
  String get itemMenuRemind => 'Hatırlat';

  @override
  String get taskContactHint => 'Kişi (kime / kimden)';

  @override
  String get taskGmailHint => 'Gmail bağlantısı';

  @override
  String dueBadgeTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hatırlatıcı/görev bekliyor',
      one: '1 hatırlatıcı/görev bekliyor',
    );
    return '$_temp0';
  }

  @override
  String get dueBadgeBody =>
      'Zamanı gelenler ve bugünün görevleri — ana ekranda';

  @override
  String get dueBadgeChannel => 'Bekleyenler (simge rozeti)';

  @override
  String get quickRowAttach => 'Ekle';

  @override
  String get quickRowColor => 'Yazı rengi (basılı tut: favori rengi seç)';

  @override
  String get penModePenOnlyOn =>
      'Kalem kipi · Yalnız kalemle yaz: açık (parmak kaydırır)';

  @override
  String get penModePenOnlyOff =>
      'Kalem kipi · Yalnız kalemle yaz: kapalı (parmak da yazar)';

  @override
  String get penModeSettings => 'Ayarla';

  @override
  String get quickRowBold => 'Kalın';

  @override
  String get quickRowBullet => 'Madde imi';

  @override
  String get quickRowHeading => 'Başlık (sırayla)';

  @override
  String get quickRowPhoto => 'Fotoğraf ekle';

  @override
  String get quickRowFile => 'Dosya ekle';

  @override
  String get quickRowPen => 'Kalemle yaz · basılı tut: kalem ayarları';

  @override
  String get editorBarEraser => 'Silgi · kalem kipini silgiyle açar';

  @override
  String get quickRowReminder => 'Hatırlatıcı';

  @override
  String get hideBarWhileTyping => 'Yazarken alt çubuğu gizle';

  @override
  String get hideBarWhileTypingInfo =>
      'Yazmaya başlayınca alt çubuk iner, durunca geri gelir.';

  @override
  String get typingBarHideDelay => 'Gizlenme gecikmesi';

  @override
  String get typingBarHideDelayInfo =>
      'Yazmaya başladıktan ne kadar sonra gizlensin';

  @override
  String get typingBarShowDelay => 'Yeniden görünme gecikmesi';

  @override
  String get typingBarShowDelayInfo =>
      'Yazmayı bırakınca ne kadar sonra geri gelsin';

  @override
  String secondsValue(String value) {
    return '$value sn';
  }

  @override
  String get tipHideBarTyping =>
      'Yazarken alt çubuk gizlenir, durunca geri gelir. Ayarlar → Kartlar bölümünden kapatılabilir.';

  @override
  String get addToNoteTitle => 'Nota ekle';

  @override
  String get addToNewNote => 'Yeni not';

  @override
  String get addToNoteEmpty => 'Henüz başka not yok';

  @override
  String get calendarLinkExistingNote => 'Mevcut notu bağla';

  @override
  String get routineFromNote => 'Nottan rutin oluştur';

  @override
  String get quickRowSubheading => 'Ara başlık';

  @override
  String get quickRowItalic => 'İtalik';

  @override
  String get quickRowUnderline => 'Altı çizili';

  @override
  String get quickRowHighlight => 'Vurgula';

  @override
  String get quickRowSpellOn =>
      'Yazım düzelt: açık (her kelime otomatik düzeltilir)';

  @override
  String get quickRowSpellOff => 'Yazım düzelt: kapalı';

  @override
  String get quickRowPackage => 'Pakete al';

  @override
  String get notePackageHint => 'Uzun yazı — pakete alıp sadeleştir';

  @override
  String get quickRowDictation => 'Sesle yaz';

  @override
  String get notePackageSelectFirst =>
      'Pakete almak için yazıyı seç (ya da uzun bir paragrafa dokun)';

  @override
  String notePackageCount(int count) {
    return '$count madde';
  }

  @override
  String get notePackageUnpack => 'Paketi çöz (nota geri koy)';

  @override
  String get pinnedPenWrite => 'Üzerine kalemle yaz';

  @override
  String get pinnedShrinkToFit => 'Daraltınca küçülsün';

  @override
  String get quickRowCamera => 'Fotoğraf çek';

  @override
  String get quickRowScan => 'Belge tara';

  @override
  String get quickRowDate => 'Tarih ve saat ekle';

  @override
  String get spellAutoTitle => 'Otomatik düzelt';

  @override
  String get spellLearnTitle => 'Öğrenen düzeltme';

  @override
  String get spellCheckDoneTitle => 'İşaretli maddeleri de denetle';

  @override
  String get spellCheckDoneSubtitle =>
      'Kapalıyken yapıldı işaretli maddelerin altı çizilmez';

  @override
  String get spellManualHint => 'Doğrusunu yaz';

  @override
  String get spellManualFix => 'Elle düzelt';

  @override
  String get spellLearnSubtitle =>
      'Kendi düzelttiğin ve klavye önerisinden seçtiğin kelimeleri öğrenir (Türkçe, İngilizce, Çince). Kişisel sözlüğün hesabınla eşitlenir.';

  @override
  String spellLearnedCount(int count) {
    return '$count öğrenilmiş düzeltme';
  }

  @override
  String get spellForget => 'Öğrenilenleri sil';

  @override
  String get spellForgotten => 'Öğrenilenler silindi';

  @override
  String get spellModeTitle => 'Yazım denetimi';

  @override
  String get spellModeInfo =>
      'Yalnız göster: yanlışın altı çizilir. Otomatik: emin olunca düzeltir.';

  @override
  String get spellModeOff => 'Kapalı';

  @override
  String get spellModeShow => 'Yalnız göster';

  @override
  String get spellModeAuto => 'Otomatik';

  @override
  String get spellAddToDictionary => 'Sözlüğe ekle';

  @override
  String spellAlwaysFix(String word) {
    return 'Hep böyle düzelt: $word';
  }

  @override
  String get spellKeepInNote => 'Bu notta dokunma';

  @override
  String get spellReviewAction => 'Yazımı denetle';

  @override
  String get spellReviewNoteOption => 'Bu notu toplu denetle';

  @override
  String get spellReviewClean => 'Yazım hatası bulunamadı';

  @override
  String get spellReviewCleanHint =>
      'Bu nottaki kelimeler sözlükle uyumlu görünüyor.';

  @override
  String spellReviewFixAll(int count) {
    return 'Tümünü düzelt ($count)';
  }

  @override
  String spellReviewApply(int count) {
    return 'Uygula ($count)';
  }

  @override
  String get spellReviewSkip => 'Atla';

  @override
  String get spellReviewHintBadge => 'Bağlam ipucu';

  @override
  String spellReviewFixed(int count) {
    return '$count yazım düzeltildi';
  }

  @override
  String get lineTaskRetime => 'Zamanı değiştir';

  @override
  String get lineTaskDone => 'Tamamlandı';

  @override
  String get lineTaskUndone => 'Tamamlanmadı yap';

  @override
  String get lineTaskDetails => 'Ayrıntılar (düzey, tekrar, kişi)';

  @override
  String get lineTaskDelete => 'Hatırlatıcıyı sil';

  @override
  String get inkShapeTriangle => 'Üçgen';

  @override
  String get inkShapeTable => 'Tablo';

  @override
  String get homeFolderStripShort => 'Klasör satırı';

  @override
  String get homeCalendarStripShort => 'Takvim şeridi';

  @override
  String get homeCalendarStrip => 'Üstte takvim şeridi';

  @override
  String get homeCalendarStripInfo =>
      'Ana ekranın tepesinde etkinlik, görev ve tatilleriyle takvim.';

  @override
  String get homeCalendarStripExpand => 'Takvim şeridini aç';

  @override
  String get homeCalendarStripCollapse => 'Takvim şeridini daralt';

  @override
  String get folderMenuEdit => 'Sırala · sil';

  @override
  String get themeClassic => 'Klasik';

  @override
  String get themeNewsprint => 'Gazete';

  @override
  String get themeNotebook => 'Defter';

  @override
  String get themeGraphite => 'Kurşun kalem';

  @override
  String get themeLedger => 'Klasik yeşil';

  @override
  String get themeGroupCalm => 'Sakin';

  @override
  String get themeGroupPaper => 'Kâğıt';

  @override
  String get themeGroupVivid => 'Canlı';

  @override
  String get spellLearnedTitle => 'Öğrenilen yazımlar';

  @override
  String get spellLearnedInfo =>
      'Yazıp sonra kendin düzelttiğin ya da klavye önerisinden seçtiğin kelimeler burada. Elle de ekleyebilirsin: yanlış → doğru (ilk görüşte uygulanır).';

  @override
  String get spellLearnedSettingInfo =>
      'Öğrenilen düzeltmeleri gör, elle ekle, sil';

  @override
  String get spellLearnedWrong => 'Yanlış';

  @override
  String get spellLearnedRight => 'Doğrusu';

  @override
  String get spellLearnedAdd => 'Ekle';

  @override
  String get spellLearnedEmpty => 'Henüz öğrenilen düzeltme yok.';

  @override
  String spellLearnedSeen(int count) {
    return '$count kez';
  }

  @override
  String get spellLearnedKept =>
      'Dokunulmayan kelimeler (düzeltmeyi geri aldıkların)';

  @override
  String get spellRulesOnlyTitle => 'Yalnız kurallar';

  @override
  String get spellRulesOnlySubtitle =>
      'Yalnız bilinen yazım hataları (herşey → her şey) ve senin öğrettiklerin düzeltilir; tahmin yok.';

  @override
  String get spellRejectedTitle =>
      'Bir daha yapılmayacak düzeltmeler (geri aldıkların ya da değiştirdiklerin)';

  @override
  String get inkEraserOffer => 'Silgiyi seç';

  @override
  String get inkPenOffer => 'Kaleme dön';

  @override
  String get tipPenShapeHold =>
      'Çizginin sonunda parmağını/kalemini bir an beklet: çizgi, kare, daire düzgün şekle oturur.';

  @override
  String get tipPenEraserHold =>
      'Silmek için bir çizginin üstüne basılı tut → çıkan silgi düğmesine dokun. İki parmak = kaydır/yakınlaştır.';

  @override
  String backupStatusCloud(int count) {
    return 'Bulut: $count not Google hesabında, değişiklikler kendiliğinden eşitleniyor';
  }

  @override
  String get backupStatusGuest =>
      'Bulut yedeği yok: notlar yalnız bu cihazda. Google hesabı bağla ya da tam yedek al.';

  @override
  String backupStatusLast(String date, int count) {
    return 'Son tam yedek: $date · $count not';
  }

  @override
  String get backupStatusNever => 'Bu cihazda henüz tam yedek alınmadı';

  @override
  String get attachmentAddText => 'Üstüne yazı ekle';

  @override
  String get stylusTogglesOn => 'Kalem yazar';

  @override
  String get stylusTogglesOff => 'Kalem dokunur (yazmaz)';

  @override
  String updateBanner(String version) {
    return 'Yeni sürüm var: v$version — dokun, indir ve kur';
  }

  @override
  String updateBannerReady(String version) {
    return 'v$version indirildi — dokun, şimdi kur';
  }

  @override
  String updateBannerDownloading(String version, int percent) {
    return 'v$version indiriliyor… %$percent';
  }

  @override
  String updateReadyToInstall(String version) {
    return 'v$version indirildi; uygulamayı bir sonraki açışında kurulacak';
  }

  @override
  String get updateInstallNow => 'Şimdi kur';

  @override
  String get updateDownloadFailed =>
      'Yeni sürüm indirilemedi — bağlantıyı kontrol edip yeniden dokun';

  @override
  String get updateInstallFailed => 'Kurulum tamamlanamadı — yeniden dene';

  @override
  String get autoUpdateTitle => 'Otomatik güncelle';

  @override
  String get autoUpdateInfo =>
      'Yeni sürüm arka planda iner, uygulamayı bir sonraki açışında kurulur';

  @override
  String get updateInstall => 'Güncelle';

  @override
  String get updateNeedsPermission =>
      'Bu uygulamaya \"bilinmeyen uygulama yükleme\" izni ver, sonra yeniden Güncelle\'ye dokun';

  @override
  String get updateTapToCheck => 'Dokun: güncellemeyi denetle';

  @override
  String get updateReopenOn => 'Güncellemeden sonra kendiliğinden açılır';

  @override
  String get updateReopenOff =>
      'Güncellemeden sonra kendiliğinden açılsın: izin ver';

  @override
  String get updateChecking => 'Güncelleme denetleniyor…';

  @override
  String get updateUpToDate => 'En son sürüm kullanılıyor';

  @override
  String get releaseNotesTitle => 'Sürüm notları';

  @override
  String get settingsWritingTitle => 'Kalem, yazım ve ekran';

  @override
  String get settingsWritingSummary =>
      'Kalem · Yazım düzelt · Ana ekran şeritleri';

  @override
  String get settingsPenSection => 'Kalem';

  @override
  String get settingsSpellSection => 'Yazım düzelt';

  @override
  String get settingsScreenSection => 'Ana ekran ve not ekranı';

  @override
  String get settingsShowAllNotes => 'Klasördeki notlar da ana ekranda';

  @override
  String get settingsShowAllNotesInfo =>
      'Klasördeki notlar da ana ekranda görünür (arşiv ve gizli hariç).';

  @override
  String get settingsAttachmentsExpanded => 'Not ekranında ek şeridi açık';

  @override
  String get settingsListPaneCollapsed =>
      'Geniş ekranda not listesi gizli (odak)';

  @override
  String get settingsListPaneCollapsedInfo =>
      'Tablet ve web\'de not açıkken liste kapalı başlar.';

  @override
  String get pinnedSideToggle => 'Yerleşim: üstte / solda / sağda';

  @override
  String get pinnedSideTitle => 'Bölme yerleşimi';

  @override
  String get pinnedSideTop => 'Üstte';

  @override
  String get pinnedSideLeft => 'Solda';

  @override
  String get pinnedSideRight => 'Sağda';

  @override
  String releaseNotesToastTitle(String version) {
    return 'Yenilikler · v$version';
  }

  @override
  String releaseNotesToastMore(int count) {
    return '+$count yenilik daha';
  }

  @override
  String get releaseNotesToastAll => 'Tümünü gör';

  @override
  String get updateInstalling =>
      'İndirildi — kuruluyor; uygulama kapanıp yeniden açılacak';

  @override
  String get updateAborted =>
      'Kurulum iptal edildi — yeniden denemek için dokun';

  @override
  String get updateOpenedBrowser => 'İndirme sayfası tarayıcıda açıldı';

  @override
  String cardHiddenYoutube(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count YouTube videosu',
      one: 'YouTube videosu',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenVideo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count video',
      one: 'Video',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenImage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görsel',
      one: 'Görsel',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenDoc(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count belge',
      one: 'PDF',
    );
    return '$_temp0';
  }

  @override
  String cardHiddenAudio(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ses kaydı',
      one: 'Ses kaydı',
    );
    return '$_temp0';
  }

  @override
  String get quickAddKeepOne => 'En az bir seçenek görünür kalmalı';

  @override
  String get attachmentUploadNow => 'Şimdi dene';

  @override
  String uploadPendingTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek yüklenmeyi bekliyor',
      one: '1 ek yüklenmeyi bekliyor',
    );
    return '$_temp0';
  }

  @override
  String get uploadPendingBody => 'Uygulamayı açınca yüklenir.';

  @override
  String get uploadPendingChannel => 'Bekleyen ek yüklemeleri';

  @override
  String placementHintShort(String view) {
    return '$view olarak eklendi · değiştirmek için anahtara dokun';
  }

  @override
  String get listPaneRight => 'Not listesi sağda';

  @override
  String get listPaneRightInfo =>
      'Bölünmüş görünümde (tablet, geniş pencere) liste notun sağında durur';

  @override
  String get listPaneMoveRight => 'Listeyi sağa al';

  @override
  String get noteOpenSide => 'Yanda aç';

  @override
  String get micBusySideNote => 'Mikrofon yandaki notta kullanılıyor';

  @override
  String get noteCloseSide => 'Yandaki notu kapat';

  @override
  String get listPaneMoveLeft => 'Listeyi sola al';

  @override
  String get quickRowEditTitle => 'Hızlı menü (yazarken üstte)';

  @override
  String get quickRowEditInfo =>
      'Dokun: menüye ekle ya da çıkar. Değişiklik hemen uygulanır, kaydetmeye gerek yok.';

  @override
  String get quickRowEditShown => 'Menüde';

  @override
  String get quickRowEditAvailable => 'Eklenebilir';

  @override
  String get quickRowEditEmpty => 'Menü boş — aşağıdan düğme ekle';

  @override
  String get quickRowEditReset => 'Varsayılana dön';

  @override
  String get quickRowShortPen => 'Kalem';

  @override
  String get quickRowShortSpell => 'Yazım düzelt';

  @override
  String get quickRowShortColor => 'Yazı rengi';

  @override
  String get quickRowShortHeading => 'Başlık';

  @override
  String get quickEntryHint => 'Yaz ya da söyle: muz elma, 2 süt…';

  @override
  String get quickEntryListening => 'Dinliyorum…';

  @override
  String get quickEntryMic => 'Sesle ekle';

  @override
  String get quickEntryMicStop => 'Dinlemeyi durdur';

  @override
  String get quickListEmpty =>
      'Yukarıya yaz, söyle ya da aşağıdan dokun; liste burada oluşur.';

  @override
  String get smartListHint =>
      'Süt, ekmek… yaz ya da söyle; bavul için “bavul listesi” de.';

  @override
  String get quickListDone => 'Bitti';

  @override
  String get quickListAisleSort => 'Reyon sırasına diz';

  @override
  String get quickListOpenInNote => 'Notta aç';

  @override
  String get quickListDiscard => 'Vazgeç';

  @override
  String get quickListFrequent => 'Sık eklediklerin';

  @override
  String get quickListLeftovers => 'Geçen seferden';

  @override
  String get quickListAddAll => 'Hepsini ekle';

  @override
  String quickListSaved(String title) {
    return '“$title” kaydedildi';
  }

  @override
  String get quickListOpen => 'Aç';

  @override
  String get quickListRemove => 'Çıkar';

  @override
  String quickListCorrected(String typed) {
    return '“$typed” yazmıştın; geri almak için dokun';
  }

  @override
  String quickListRestored(String typed) {
    return '“$typed” olarak bırakıldı; bir daha düzeltilmeyecek';
  }

  @override
  String get quickDropTitle => 'Hızlı ekle';

  @override
  String get quickDropInfo => 'Yaz ya da söyle, seçtiğin nota eklensin';

  @override
  String get quickDropHint =>
      'süt, ekmek… ya da “alışveriş listesine süt ekle”';

  @override
  String get quickDropTarget => 'Nereye eklensin?';

  @override
  String get quickDropNoNotesNew =>
      'Eklenecek liste ya da metin notu yok: yazdığın yeni not olarak kaydedilir.';

  @override
  String get quickDropSavingNew => 'Yeni not olarak kaydediliyor…';

  @override
  String get quickDropSavedNew => 'Yeni not olarak kaydedildi';

  @override
  String get quickDropAdd => 'Ekle';

  @override
  String quickDropAdded(int count, String title) {
    return '$count madde “$title” notuna eklendi';
  }

  @override
  String quickDropAddedText(String title) {
    return '“$title” notuna eklendi';
  }

  @override
  String quickDropNothingNew(String title) {
    return 'Hepsi zaten “$title” notunda';
  }

  @override
  String get quickDropKeyboard => 'Açılınca klavye';

  @override
  String get quickDropMicAuto => 'Açılınca dinle';

  @override
  String get noteExpiry => 'Şu zamanda arşivle';

  @override
  String get noteExpiryDay => '1 gün';

  @override
  String get noteExpiry3Days => '3 gün';

  @override
  String get noteExpiryWeek => '1 hafta';

  @override
  String get noteExpiryMonth => '1 ay';

  @override
  String get noteExpiryPick => 'Tarih ve saat seç';

  @override
  String get noteExpiryRemove => 'Süreyi kaldır';

  @override
  String noteExpiryChip(String date) {
    return '$date arşivlenir';
  }

  @override
  String noteExpiryLeftDays(int n) {
    return '$n g';
  }

  @override
  String noteExpiryLeftHours(int n) {
    return '$n sa';
  }

  @override
  String noteExpiryLeftMinutes(int n) {
    return '$n dk';
  }

  @override
  String get smartList => 'Akıllı liste';

  @override
  String get smartListInfo =>
      'Yaz ya da söyle; alışveriş mi bavul mu kendisi anlar, maddeleri reyon reyon dizer';

  @override
  String get smartListGeneric => 'Liste';

  @override
  String get smartListPacking => 'Bavul listesi';

  @override
  String get smartListPharmacy => 'Eczane listesi';

  @override
  String get smartListStationery => 'Kırtasiye listesi';

  @override
  String get smartListHardware => 'Tamirat listesi';

  @override
  String get smartListCamping => 'Kamp listesi';

  @override
  String get smartListBaby => 'Bebek çantası';

  @override
  String get smartListSport => 'Spor çantası';

  @override
  String get sortByGroup => 'Reyona / gruba göre';

  @override
  String get finishShopping => 'Alınanları tamamla';

  @override
  String finishShoppingDone(int count) {
    return '$count alınan madde temizlendi';
  }

  @override
  String get scanAny => 'Tara';

  @override
  String get scanAnyInfo => 'Belge ya da QR kod — QR kendiliğinden tanınır';

  @override
  String get scanAnyHint =>
      'QR kod kendiliğinden tanınır. Belge için “Belge tara”ya dokun.';

  @override
  String get scanQrFound => 'QR kod bulundu';

  @override
  String get scanUseQr => 'QR\'ı kullan';

  @override
  String get listToNumbered => 'Numaralıya çevir';

  @override
  String get listToChecklist => 'Onay kutulu listeye çevir';

  @override
  String get quickDropWhich => 'Hangi nota eklensin?';

  @override
  String get quickDropAsking => 'Hangi not olduğunu soruyorum…';

  @override
  String quickDropAddingTo(String title) {
    return '“$title” notuna ekleniyor…';
  }

  @override
  String get quickDropWait => 'Bekle';

  @override
  String get quickDropAiToggle => 'Emin olunamazsa yapay zekâya sor';

  @override
  String get aiOffTitle => 'Yapay zekâ kapalı';

  @override
  String get aiConsentTitle => 'Yapay zekâ kullanımı';

  @override
  String get aiConsentWhat =>
      'Ne gönderilir: yalnız o iş için seçtiğin metin, not ya da ek (görsel, ses, PDF).';

  @override
  String get aiConsentWhere =>
      'Nereye: Google\'ın Gemini hizmetine (Firebase üzerinden); kendi anahtarını girdiysen seçtiğin sağlayıcıya.';

  @override
  String get aiConsentMistakes =>
      'Yapay zekâ yanılabilir; önemli bilgileri kendin doğrula.';

  @override
  String get aiConsentTurnOff =>
      'İstediğin an Ayarlar → Yapay zekâ\'dan tümden kapatabilirsin.';

  @override
  String get aiConsentAccept => 'Kabul ediyorum';

  @override
  String get aiConsentDecline => 'Vazgeç';

  @override
  String get aiPausedTitle => 'Yapay zekâ geçici olarak kapalı';

  @override
  String get homePullGestureTitle => 'Listeyi tepeden aşağı çekince';

  @override
  String get homeSwipeRightGestureTitle => 'Tümü\'de sağa kaydırınca';

  @override
  String get homeGestureInfo =>
      'Bir not ya da klasör seçersen jest doğrudan onu açar';

  @override
  String get homeGestureFolders => 'Klasörler';

  @override
  String get homeGestureNote => 'Bir not';

  @override
  String get homeGestureFolder => 'Bir klasör';

  @override
  String get homeGestureNone => 'Hiçbiri';

  @override
  String get homeGestureMissing =>
      'Jestin hedefi bulunamadı; Ayarlar → Notlar\'dan yeniden seç';

  @override
  String get calendarExpiryTag => 'Arşivlenir';

  @override
  String get calendarExpiryRemoved => 'Arşivleme süresi kaldırıldı';

  @override
  String get inkFingerAuto => 'Otomatik';

  @override
  String get inkFingerAutoNowScroll =>
      'Otomatik: bu cihazda kalem görüldü, parmak kaydırıyor.';

  @override
  String get inkFingerAutoNowDraw =>
      'Otomatik: kalem görülmedi, parmak çiziyor; kalem ilk değince kaydırmaya geçer.';

  @override
  String get barMoreLeftGroup => 'Sol grup';

  @override
  String get barMoreRightGroup => 'Sağ grup (renkli)';

  @override
  String get barMoreToRight => 'Sağ gruba taşı';

  @override
  String get barMoreToLeft => 'Sol gruba taşı';

  @override
  String get layoutScopeAll => 'Tümüne uygula';

  @override
  String get layoutScopeNote => 'Yalnız bu nota';

  @override
  String get layoutScopeInfoAll => 'Değişiklik bütün notlarda geçerli.';

  @override
  String get layoutScopeInfoNote =>
      'Bu notun kendi düzeni var; değişiklik yalnız bu notta geçerli.';

  @override
  String get layoutScopeReset => 'Bu notun özelleştirmesini sıfırla';

  @override
  String quickRowEditNotHere(String names) {
    return 'Bu notta görünmez: $names';
  }

  @override
  String get barMoreEdit => 'Alt paneli düzenle';

  @override
  String get barMoreEditHint =>
      '📌 olanlar çubukta durur (telefonda ilk 3\'ü sığar), diğerleri bu menüde. Basılı tutup sürükleyerek sırala.';

  @override
  String get barMoreToBar => 'Çubuğa al';

  @override
  String get barMoreToMenu => 'Menüye al';

  @override
  String menuEditInlineHint(int count) {
    return 'Basılı tutup sürükle: sırala · ⊖ gizle · ☆ hızlı satır (en çok $count)';
  }

  @override
  String get menuHiddenGroup => 'Gizlenenler';

  @override
  String get quickDropSettings => 'Hızlı ekle ayarları';

  @override
  String quickDropPreviewText(String title, String text) {
    return '→ $title · $text';
  }

  @override
  String quickDropPreviewItems(String title, String items, int count) {
    return '→ $title · $items ($count madde)';
  }

  @override
  String get quickDropPickMyself => 'Ben seçeyim';

  @override
  String get quickDropFindNote => 'Not bul';

  @override
  String quickDropPreviewReminder(String when, String text) {
    return '⏰ $when · $text';
  }

  @override
  String get quickDropSavedReminder => 'Hatırlatıcılı not kaydedildi';

  @override
  String quickDropPreviewCalendar(String day, String text) {
    return '📅 $day · $text';
  }

  @override
  String quickDropSavedCalendar(String day) {
    return 'Not takvime eklendi · $day';
  }

  @override
  String quickDropPreviewMulti(String summary, int count) {
    return '→ $summary ($count not)';
  }

  @override
  String quickDropAddedMulti(int count) {
    return '$count nota eklendi';
  }

  @override
  String get aiNeedsProTitle => 'Yapay zekâ Pro\'da';

  @override
  String get proTitle => 'Tam sürüm';

  @override
  String get proSettingsSubtitle =>
      'Lite vs Tam Sürüm, karar hakkı, satın alma';

  @override
  String get proStatusFree => 'Şu an: Lite (Ücretsiz · Reklamsız)';

  @override
  String get proStatusLifetime => 'Şu an: Tam Sürüm (Ömür Boyu)';

  @override
  String get proTiersTitle => 'Katmanlar';

  @override
  String get proTierFree => 'Lite';

  @override
  String get proTierLifetime => 'Tam sürüm';

  @override
  String get proRowBasics =>
      'Not, liste, kalem, PDF, hatırlatıcı, takvim; cihazda yazım v3, dikte, OCR, barkod, Mağaza Kipi';

  @override
  String get proRowUnlimited => 'Sınırsız not, klasör, ek ve cihaz';

  @override
  String get proRowSync => 'Bulut eşitleme';

  @override
  String get proSyncPeriodic => 'Aralıklı (5 dk)';

  @override
  String get proSyncInstant => 'Anında';

  @override
  String get proRowAttachments => 'Eklerin yeri';

  @override
  String get proAttachDrive => 'Kendi Drive hesabın';

  @override
  String get proAttachCloud => 'Drive + Ortak';

  @override
  String get proRowHistory => '30 sürüm geçmişi, parolalı tam yedek';

  @override
  String get proRowLooks => 'Tüm temalar, 19 yazı tipi, kâğıt desenleri';

  @override
  String get proRowAi => 'Akıllı Kararlar (reyon, hedef, etiket)';

  @override
  String get proDecisionsIncluded => '750 karar';

  @override
  String get proRowOwnKey => 'Kendi Gemini anahtarın';

  @override
  String get proLockedBadge => 'Tam sürümde';

  @override
  String get proBuyTitle => 'Satın al';

  @override
  String get proPlanLifetime => 'Tam Sürüm · Tek Sefer (Ömür Boyu)';

  @override
  String get proPlanDecisionPack => '+1.000 Akıllı Karar Paketi';

  @override
  String proPriceOnce(String price) {
    return '$price · tek sefer öde, abonelik yok';
  }

  @override
  String get proBuy => 'Satın al';

  @override
  String get proOwned => 'Sende var';

  @override
  String get proRestore => 'Satın alımları geri yükle';

  @override
  String get proTerms =>
      'Abonelik yoktur, reklam yoktur. Tam Sürüm tek seferlik ömür boyu satın almadır ve 750 Akıllı Karar hakkı içerir. Hak bitince uygulama ve tüm cihaz içi özellikler sınırsız çalışmaya devam eder; istersen ek +1.000 Karar Paketi alabilir veya kendi Gemini anahtarını girebilirsin.';

  @override
  String get proLoading => 'Google Play\'den fiyatlar alınıyor…';

  @override
  String get proUnavailable => 'Google Play\'e ulaşılamadı.';

  @override
  String get proElsewhere =>
      'Satın alma telefondan: Android uygulamasında Ayarlar → Tam Sürüm. Aldığın hak bu hesapla burada da açılır.';

  @override
  String get proGuest =>
      'Satın almak için Google hesabıyla giriş yap: misafir hesap yalnız bu cihazda, cihaz değişince satın alman da kaybolurdu.';

  @override
  String get proNoticePending =>
      'Ödeme bekleniyor; onaylanınca hakkın kendiliğinden açılır.';

  @override
  String get proNoticeCanceled => 'Satın alma iptal edildi.';

  @override
  String get proNoticeFailed =>
      'Satın alma tamamlanamadı. Biraz sonra yeniden dene.';

  @override
  String get proNoticeVerifyFailed =>
      'Satın alma doğrulanamadı; uygulama bir sonraki açılışta kendiliğinden yeniden dener. Doğrulanmayan ödemeyi Google Play iade eder.';

  @override
  String get proNoticeOtherAccount =>
      'Bu satın alma başka bir hesaba bağlı. O hesapla giriş yapınca hakkın açılır.';

  @override
  String get proNoticeDone => 'Teşekkürler! Hakkın açıldı.';

  @override
  String get proNoticeRestored => 'Satın alımların geri yüklendi.';

  @override
  String get proNoticeNothing =>
      'Bu Google Play hesabında geri yüklenecek satın alma yok.';

  @override
  String get proIncluded => 'Var';

  @override
  String get proNotIncluded => 'Yok';

  @override
  String get decisionsSectionTitle => 'Akıllı kararlar';

  @override
  String get decisionsSectionSubtitle =>
      'Bilinmeyen ürün reyonu, hızlı ekle hedefi ve etiket önerileri';

  @override
  String get decisionsQuotaByok =>
      'Kendi Gemini anahtarın etkin · Sınırsız akıllı karar';

  @override
  String decisionsQuotaSummary(int calls, String tokens) {
    return 'Kalan akıllı karar: $calls · $tokens jeton bütçesi';
  }

  @override
  String get decisionsQuotaFreeHint =>
      'Cihaz içi akıllı kurallar ücretsiz açık · Tam Sürümde 750 karar dahil';

  @override
  String get decisionsTurnOffTitle => 'Akıllı kararları kapat';

  @override
  String get decisionsTurnOffBody =>
      'Kapalıyken tüm cihaz içi sözlükler, yazım denetimi ve alışveriş kuralları ücretsiz çalışmaya devam eder.';

  @override
  String get decisionsByokTitle => 'Kendi Gemini anahtarım (İleri)';

  @override
  String get decisionsByokInfo =>
      'Karar hakkı bitince kendi Gemini anahtarınla sürdür; anahtar bu cihazda kalır.';

  @override
  String get calendarDayLinkRemoved => 'Not bu günden çıkarıldı';

  @override
  String get calendarLinkTime => 'Saat';

  @override
  String get calendarLinkAllDay => 'Tüm gün';

  @override
  String get driveOnboardTitle => 'Eklerin her cihazda olsun';

  @override
  String get driveOnboardBody =>
      'Fotoğraf, PDF ve ses eklerin Google Drive\'ındaki \"Notlar\" klasörüne yedeklenir; telefon, tablet ve web\'de aynı ekleri görürsün.';

  @override
  String get driveOnboardConnect => 'Drive\'ı bağla';

  @override
  String get driveOnboardLater => 'Sonra';

  @override
  String get exportMarkdownZip => 'Markdown (.zip) dışa aktar';

  @override
  String get exportMarkdownZipInfo =>
      'Notlarını klasör düzeninde açık .md dosyaları olarak dışa aktarır';

  @override
  String get exportMarkdownZipEmpty => 'Dışa aktarılacak not yok';

  @override
  String exportMarkdownZipDone(int count) {
    return '$count not Markdown (.zip) olarak dışa aktarıldı';
  }

  @override
  String get storeMode => 'Mağaza kipi';

  @override
  String get storeModeHideChecked => 'Alınanları gizle';

  @override
  String get storeModeShowChecked => 'Alınanları göster';

  @override
  String storeModeRemaining(int remaining, int total) {
    return '$remaining / $total kaldı';
  }

  @override
  String get storeModeAllDone => 'Hepsi tamam!';

  @override
  String get storeModeAddHint => 'Aklına geleni hızlı ekle…';

  @override
  String get backupPasswordTitle => 'Yedek parolası (isteğe bağlı)';

  @override
  String get backupPasswordInfo =>
      'Parola belirlersen yedek güçlü şifrelemeyle korunur. Parolayı unutursan yedek açılamaz.';

  @override
  String get backupPasswordHint => 'Parola';

  @override
  String get backupPasswordConfirmHint => 'Parolayı doğrula';

  @override
  String get backupPasswordMismatch => 'Parolalar eşleşmiyor';

  @override
  String get backupWithoutPassword => 'Parolasız yedekle';

  @override
  String get backupWithPassword => 'Şifreli yedekle';

  @override
  String get backupPasswordProLocked =>
      'Parolalı yedek Ömür boyu ve Pro katmanında. Parolasız yedek ücretsiz; şifreli bir yedeği geri yüklemek her katmanda serbest.';

  @override
  String get backupSeeTiers => 'Katmanları gör';

  @override
  String get backupEnterPasswordTitle => 'Şifreli yedek';

  @override
  String get backupEnterPasswordBody =>
      'Bu yedek parola ile korunuyor. Geri yüklemek için parolayı gir.';

  @override
  String get backupWrongPassword => 'Parola yanlış veya yedek çözülemedi';

  @override
  String get calendarAddActionTitle => 'Takvimde + ne eklesin';

  @override
  String get calendarAddActionInfo =>
      'Seçili güne (yoksa bugüne) eklenir; pencerede değiştirilebilir.';

  @override
  String get calendarAddNote => 'Not';

  @override
  String get calendarAddEvent => 'Etkinlik';

  @override
  String get calendarAddTask => 'Görev';

  @override
  String get calendarFullPage => 'Tam sayfa takvim';

  @override
  String get calendarNewDayNoteTitle => 'Yeni not';

  @override
  String get calendarNewDayNoteOpen => 'Notu yaz';

  @override
  String calendarSlotAddTitle(String time) {
    return '$time için ekle';
  }

  @override
  String get eraserOn => 'Silgi açık';

  @override
  String get calendarRelToday => 'Bugün';

  @override
  String get calendarRelTomorrow => 'Yarın';

  @override
  String get calendarRelYesterday => 'Dün';

  @override
  String calendarRelInDays(int count) {
    return '$count gün sonra';
  }

  @override
  String calendarRelDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String calendarWeekNumber(int count) {
    return '$count. hafta';
  }

  @override
  String calendarDayEvents(int count) {
    return '$count etkinlik';
  }

  @override
  String calendarDayTasks(int count) {
    return '$count görev';
  }

  @override
  String calendarDayReminders(int count) {
    return '$count hatırlatıcı';
  }

  @override
  String calendarDayNotesCount(int count) {
    return '$count not';
  }

  @override
  String get calendarDayFree => 'Boş gün';

  @override
  String get webWorkspaceSection => 'Çalışma alanı';

  @override
  String get webOrganizeSection => 'Düzenle';

  @override
  String get webViewGrid => 'Izgara görünümü';

  @override
  String get webViewList => 'Liste görünümü';

  @override
  String get webColumnsMenu => 'Sütun yoğunluğu';

  @override
  String get webColumnsAuto => 'Otomatik';

  @override
  String webColumnsCount(int count) {
    return '$count sütun';
  }

  @override
  String webNoteCount(int count) {
    return '$count not';
  }

  @override
  String get webDriveStatusConnected => 'Drive bağlı';

  @override
  String webDriveStatusSyncing(int count) {
    return '$count ek senkronlanıyor';
  }

  @override
  String webDriveStatusAttention(int count) {
    return '$count ek bekliyor';
  }

  @override
  String get webSyncCloudReady => 'Bulut senkronu açık';

  @override
  String get webCacheTitle => 'Tarayıcı ek önbelleği';

  @override
  String webCacheInfo(int count, String size) {
    return '$count dosya · $size (çevrimdışı hazır)';
  }

  @override
  String get webCacheEmpty => 'Önbellekte indirilen ek yok';

  @override
  String get webCacheClear => 'Temizle';

  @override
  String get webCacheCleared => 'Tarayıcı ek önbelleği temizlendi';

  @override
  String get quickRowMoreEdit => 'Hızlı menüyü düzenle';

  @override
  String get quickRowDay => 'Gün ekle';

  @override
  String get tableInsert => 'Tablo';

  @override
  String get tableInsertInfo => '3 satır · 2 sütun, sonra değişir';

  @override
  String get tableName => 'Tablo';

  @override
  String get tableAddRow => 'Satır ekle';

  @override
  String get tableAddRowBelow => 'Altına satır ekle';

  @override
  String get tableDeleteRow => 'Satırı sil';

  @override
  String get tableColumnCount => 'Sütun';

  @override
  String get tableHeaderRow => 'İlk satır başlık';

  @override
  String get tableEqualWidths => 'Sütunları eşitle';

  @override
  String get tableDelete => 'Tabloyu sil';

  @override
  String get tableOptions => 'Tablo ayarları';

  @override
  String get tableColumnsWillDrop =>
      'Son sütundaki yazılar silinecek. Devam edilsin mi?';

  @override
  String get tableMoveHint =>
      'Taşımak için basılı tut, boyut için köşeden sürükle';

  @override
  String get tableRowCount => 'Satır';

  @override
  String get tableRowsWillDrop =>
      'Son satırlardaki yazılar silinecek. Devam edilsin mi?';

  @override
  String get tableEditSection => 'Düzenle';

  @override
  String get tableShareImage => 'Görsel';

  @override
  String get tableSharePdf => 'PDF';

  @override
  String get tableShareWord => 'Word';

  @override
  String get tableShareFailed => 'Tablo paylaşılamadı';

  @override
  String get tableAddRowAbove => 'Üstüne satır ekle';

  @override
  String get tableInsertColumn => 'Sağına sütun ekle';

  @override
  String get tableDeleteColumn => 'Sütunu sil';

  @override
  String get tableColumnsOneWillDrop =>
      'Seçili sütundaki yazılar silinecek. Devam edilsin mi?';

  @override
  String get tableSortAsc => 'A→Z sırala';

  @override
  String get tableSortDesc => 'Z→A sırala';

  @override
  String get tableStripedRows => 'Şeritli satırlar';

  @override
  String get tableDataSection => 'Veri';

  @override
  String get tableCopyMarkdown => 'Markdown kopyala';

  @override
  String get tableCopyCsv => 'CSV kopyala';

  @override
  String get tablePasteData => 'CSV / TSV yapıştır';

  @override
  String get tablePasteWillReplace =>
      'Tablodaki içerik yapıştırılan verilerle değişecek. Devam edilsin mi?';

  @override
  String get tablePasteInvalid => 'Panoda geçerli tablo verisi bulunamadı';

  @override
  String get tablePasted => 'Tablo verileri yapıştırıldı';

  @override
  String get tableSorted => 'Tablo sıralandı';

  @override
  String folderHeaderPinnedCount(int count) {
    return '$count sabit';
  }

  @override
  String get folderNewNote => 'Yeni not';

  @override
  String get folderFilterSort => 'Süz ve sırala';

  @override
  String get folderLivePreview => 'Önizleme';

  @override
  String get pinnedSmartActions => 'Akıllı işlemler';

  @override
  String get pinnedSmartOcr => 'Metni çıkar';

  @override
  String get pinnedSmartSummarize => 'Özetle ve nota ekle';

  @override
  String get pinnedSmartTasks => 'Görevlere çevir';

  @override
  String get pinnedSmartAreaAsk => 'Alan seçip sor';

  @override
  String get dashboardBackgroundGallery => 'Hazır zeminler';

  @override
  String get dashboardBackgroundFromDevice => 'Galeriden seç';

  @override
  String get dashboardBackgroundOpacity => 'Görünürlük';

  @override
  String get wallpaperAuroraBloom => 'Kuzey çiçeği';

  @override
  String get wallpaperCitrusSun => 'Narenciye güneşi';

  @override
  String get wallpaperCoralLagoon => 'Mercan koyu';

  @override
  String get wallpaperBotanicalGarden => 'Botanik bahçe';

  @override
  String get wallpaperLavenderDream => 'Lavanta rüyası';

  @override
  String get wallpaperTerracottaStudio => 'Terrakota atölye';

  @override
  String get wallpaperPastelConfetti => 'Pastel konfeti';

  @override
  String get wallpaperGoldenMeadow => 'Altın çayır';

  @override
  String get wallpaperMidnightAurora => 'Gece aurorası';

  @override
  String get wallpaperVelvetCosmos => 'Kadife kozmos';

  @override
  String get noteThemeAurora => 'Aurora';

  @override
  String get noteThemeCitrus => 'Narenciye';

  @override
  String get noteThemeBotanical => 'Botanik';

  @override
  String get noteThemeTerracotta => 'Terrakota';

  @override
  String get noteThemeConfetti => 'Konfeti';

  @override
  String get noteThemeCobalt => 'Kobalt';

  @override
  String get themeActiveLabel => 'Etkin tema';

  @override
  String get themeGroupAll => 'Tümü';

  @override
  String get itemRangeSelect => 'Aralığı seç';

  @override
  String get itemInvertSelection => 'Seçimi tersine çevir';

  @override
  String get itemMoveUp => 'Yukarı taşı';

  @override
  String get itemMoveDown => 'Aşağı taşı';

  @override
  String get itemDivider => 'Alt çizgi';

  @override
  String get selectionToolbarMore => 'Diğer işlemler';

  @override
  String get selectionMenuEdit => 'Düzenle';

  @override
  String get selectionMenuEditDone => 'Bitti';

  @override
  String get selectionMenuEditHint =>
      'Dokun: ana satıra ekle ya da oradan kaldır';

  @override
  String get itemsBatchFormat => 'Toplu biçim';

  @override
  String itemsDeletedUndo(int count) {
    return '$count madde silindi';
  }

  @override
  String itemsFormattedCount(int count) {
    return '$count madde biçimlendi';
  }

  @override
  String get ecosystemDosyalarimTitle => 'Dosyalarım ile tüm belgeleri yönet';

  @override
  String get ecosystemDosyalarimSubtitle =>
      'PDF imzala, Word ve Excel belgelerini düzenle ve notlarınla kolayca paylaş.';

  @override
  String get ecosystemGetApp => 'Dosyalarım\'ı keşfet';

  @override
  String get ecosystemDismiss => 'Gizle';

  @override
  String shopBudgetCart(String amount) {
    return 'Sepet: $amount ₺';
  }

  @override
  String shopBudgetEstimated(String amount) {
    return 'Tahmini: $amount ₺';
  }

  @override
  String shopBudgetLimit(String amount) {
    return 'Bütçe: $amount ₺';
  }

  @override
  String get shopBudgetSet => 'Bütçe belirle';

  @override
  String get shopBudgetHint => 'Örn. 1500';

  @override
  String get shopAllStores => 'Tümü';

  @override
  String shopPriceTitle(String item) {
    return 'Fiyat & Reyon · $item';
  }

  @override
  String get shopUnitPriceLabel => 'Fiyat (₺)';

  @override
  String get shopStoreLabel => 'Market';

  @override
  String get shopAisleLabel => 'Reyon';

  @override
  String get shopPriceCompareHeader => 'Market fiyat geçmişi';

  @override
  String get shopClearPrice => 'Fiyatı temizle';

  @override
  String get shopRecipesTitle => 'Öğün & Tarif Paketleri';

  @override
  String get shopRecipesSearchHint => 'Tarif ara…';

  @override
  String shopServingsCount(int count) {
    return '$count kişi';
  }

  @override
  String get shopAddToList => 'Listeye ekle';

  @override
  String get shopNewCustomRecipe => 'Yeni tarif kaydet';

  @override
  String get shopRecipeNameHint => 'Tarif adı';

  @override
  String get shopIngredientsHint =>
      'Malzemeler (virgülle ayır: 500 g kıyma, 2 domates)';

  @override
  String get shopCustomBadge => 'Özel';

  @override
  String shopAisleOrderTitle(String store) {
    return 'Reyon Sırası · $store';
  }

  @override
  String get shopResetOrder => 'Varsayılana dön';

  @override
  String get shopReceiptTitle => 'Fişten fiyat güncelle';

  @override
  String get shopReceiptCamera => 'Fiş fotoğrafı çek';

  @override
  String get shopReceiptGallery => 'Galeriden fiş seç';

  @override
  String shopReceiptMatched(int count) {
    return '$count ürün eşleşti';
  }

  @override
  String get shopReceiptNoMatches =>
      'Listedeki ürünlerle eşleşen satır bulunamadı.';

  @override
  String get shopReceiptApply => 'Fiyatları uygula';

  @override
  String get shopDueHeader => 'Bitmiş olabilir';

  @override
  String shopDueEveryDays(int days) {
    return '${days}g';
  }

  @override
  String get shopStatusUnavailable => 'Yoktu / Sonraya';

  @override
  String get shopStatusUnavailableBadge => 'Yoktu';

  @override
  String get shopBarcodeTitle => 'Barkod tara';

  @override
  String shopBarcodeUnknownPrompt(String ean) {
    return 'Yeni barkod ($ean)';
  }

  @override
  String get shopBarcodeNameHint => 'Ürün adı (ör. Türk kahvesi 100 g)';

  @override
  String get shopKeepScreenOn => 'Ekranı açık tut';

  @override
  String get shopAtStoreButton => 'Marketteyim';

  @override
  String shopAtStoreMessage(String name) {
    return '🛒 $name şimdi markette — eksik varsa listeye ekle!';
  }

  @override
  String get shopAtStoreSent => 'Ortak arkadaşlara bildirim gönderildi';

  @override
  String get shopScanReceiptTooltip => 'Fiş tara (OCR)';

  @override
  String get shopRecipesTooltip => 'Tarif paketleri';

  @override
  String get shopAisleOrderTooltip => 'Reyon sırasını düzenle';

  @override
  String shopTakenBy(String name) {
    return '$name aldı';
  }

  @override
  String shopEstimatedPrefix(String amount) {
    return '~$amount ₺';
  }

  @override
  String shopActualPrice(String amount) {
    return '$amount ₺';
  }

  @override
  String shopOpenStoreModeCount(int remaining) {
    return 'Mağaza Kipi ($remaining)';
  }

  @override
  String get shopOpenStoreMode => 'Mağaza kipi';

  @override
  String get shopDictationTooltip => 'Sesle ekle';

  @override
  String get spellManualLearn => 'Bu düzeltmeyi öğren';

  @override
  String get spellManualLearnHint =>
      'Bir dahaki sefere otomatik önerilir ve düzeltilir.';

  @override
  String get spellNoSuggestions => 'Öneri bulunamadı';

  @override
  String get spellHintBadge => 'İpucu';

  @override
  String get spellErrorBadge => 'Yazım';

  @override
  String get wallpaperSakuraBreeze => 'Sakura esintisi';

  @override
  String get wallpaperOceanMist => 'Ege esintisi';

  @override
  String get wallpaperAutumnMaple => 'Sonbahar yaprakları';

  @override
  String get wallpaperSageLinen => 'Okaliptüs keten';

  @override
  String get wallpaperPeachHorizon => 'Şeftali ufku';

  @override
  String get wallpaperNordicPaper => 'İskandinav kağıt';

  @override
  String get wallpaperStarryPine => 'Yıldızlı çam';

  @override
  String get wallpaperObsidianGold => 'Obsidyen altın';

  @override
  String get uiProfileSectionTitle => 'Hazır arayüz profilleri';

  @override
  String get uiProfileSimple => 'Sade';

  @override
  String get uiProfileSimpleDesc =>
      'Günlük hızlı not ve alışveriş için temiz ekran';

  @override
  String get uiProfileStandard => 'Standart';

  @override
  String get uiProfileStandardDesc => 'Tüm araçlar dengeli yerleşimde';

  @override
  String get uiProfileTabletPen => 'Tablet ve kalem';

  @override
  String get uiProfileTabletPenDesc =>
      'Bölünmüş görünüm, kalem ve PDF araçları ön planda';

  @override
  String uiProfileApplied(String name) {
    return '$name profili uygulandı';
  }

  @override
  String get lockNeedSecretOnce =>
      'Bu cihazda ilk kez açmak için kilit şifreni veya desenini bir kez gir.';

  @override
  String get lockForgotConfirmTitle => 'Kilit sıfırlansın mı?';

  @override
  String get lockForgotConfirmBody =>
      'Mevcut şifrenle şifrelenmiş eski kilitli notların metni eski şifre olmadan bir daha çözülemez. Yine de kilit sıfırlansın mı?';

  @override
  String get lockForgotConfirmAction => 'Sıfırla';

  @override
  String get starterShoppingTitle => '🛒 Örnek market listesi';

  @override
  String get starterWelcomeTitle => '⚡ Hızlı başlangıç';

  @override
  String get smartListMoving => 'Taşınma planı';

  @override
  String get smartListCleaning => 'Ev temizliği';

  @override
  String get smartListHabits => 'Alışkanlık takibi';

  @override
  String get smartListWorkout => 'Antrenman programı';

  @override
  String get smartListGifts => 'Hediye planlayıcı';

  @override
  String get smartListWatchlist => 'İzlenecekler';

  @override
  String get smartListEvent => 'Etkinlik ve davet';

  @override
  String get smartListExpense => 'Bütçe ve harcama';

  @override
  String get smartListKindSelect => 'Liste türünü seç';

  @override
  String get smartListCatalog => 'Paketler ve katalog';

  @override
  String get smartListSearchCatalog => 'Madde veya grup ara…';

  @override
  String get smartListStarterPacks => 'Hazır başlangıç paketleri';

  @override
  String get smartListOpenWorkspace => 'Çalışma alanında aç';

  @override
  String get smartListTripWizard => 'Seyahat sihirbazı';

  @override
  String get smartListEventWizard => 'Davet sihirbazı';

  @override
  String get smartListWizardDays => 'Kaç gün?';

  @override
  String get smartListWizardWeather => 'Hava durumu';

  @override
  String get smartListWeatherHot => 'Sıcak';

  @override
  String get smartListWeatherMild => 'Ilık';

  @override
  String get smartListWeatherCold => 'Soğuk';

  @override
  String get smartListWeatherRainy => 'Yağmurlu';

  @override
  String get smartListWizardStyle => 'Seyahat türü';

  @override
  String get smartListStyleBeach => 'Deniz ve plaj';

  @override
  String get smartListStyleCity => 'Şehir gezisi';

  @override
  String get smartListStyleBusiness => 'İş seyahati';

  @override
  String get smartListStyleIntl => 'Yurt dışı';

  @override
  String get smartListStyleCamp => 'Kamp';

  @override
  String get smartListWizardGuests => 'Kaç kişi?';

  @override
  String get smartListEventStyle => 'Etkinlik türü';

  @override
  String get smartListEventBirthday => 'Doğum günü';

  @override
  String get smartListEventDinner => 'Akşam yemeği';

  @override
  String get smartListEventPicnic => 'Piknik';

  @override
  String smartListApplyPlan(int count) {
    return 'Listeye ekle ($count madde)';
  }

  @override
  String smartListPackAdded(String name) {
    return '“$name” paketi eklendi';
  }

  @override
  String get smartListEditItem => 'Maddeyi düzenle';

  @override
  String get smartListItemNameHint => 'Madde adı';

  @override
  String get smartListItemQty => 'Miktar';

  @override
  String get smartListItemUnit => 'Birim';

  @override
  String get smartListAll => 'Tümü';

  @override
  String get smartListResetDone => 'Liste sıfırlandı';

  @override
  String get smartListWorkspaceEmpty =>
      'Henüz madde yok; aşağıdan ekle veya hazır paket seç.';

  @override
  String get smartWorkspaceOpen => 'Çalışma alanını aç';

  @override
  String smartPillHabit(int done, int total) {
    return 'Alışkanlık · $done/$total bugün';
  }

  @override
  String smartPillMoving(int done, int total) {
    return 'Taşınma · $done/$total hazır';
  }

  @override
  String smartPillPacking(int done, int total) {
    return 'Bavul · $done/$total hazır';
  }

  @override
  String smartPillWorkout(int done, int total) {
    return 'Antrenman · $done/$total egzersiz';
  }

  @override
  String smartPillCleaning(int done, int total) {
    return 'Temizlik · $done/$total tamam';
  }

  @override
  String smartPillGifts(int done, int total) {
    return 'Hediyeler · $done/$total hazır';
  }

  @override
  String smartPillWatchlist(int count) {
    return 'İzlenecekler · $count bekliyor';
  }

  @override
  String smartPillExpense(String total) {
    return 'Bütçe · $total ₺';
  }

  @override
  String smartPillDefault(int count) {
    return 'Akıllı çalışma alanı ($count kalan)';
  }

  @override
  String habitDoneToday(int done, int total) {
    return '$done/$total bugün';
  }

  @override
  String habitBestStreak(int days) {
    return 'En iyi seri: $days gün';
  }

  @override
  String habitStreakDays(int days) {
    return '$days gün seri';
  }

  @override
  String get habitWeeklyGoal => 'Haftalık hedef';

  @override
  String habitWeeklyProgress(int done, int goal) {
    return '$done/$goal bu hafta';
  }

  @override
  String get habitTimeMorning => 'Sabah';

  @override
  String get habitTimeAfternoon => 'Öğle';

  @override
  String get habitTimeEvening => 'Akşam';

  @override
  String get habitFilterRemaining => 'Bugün kalan';

  @override
  String get habitLast30Days => 'Son 30 gün';

  @override
  String get habitAddHint => 'Yeni alışkanlık ekle…';

  @override
  String get habitPrevWeek => 'Önceki hafta';

  @override
  String get habitNextWeek => 'Sonraki hafta';

  @override
  String get movingViewTimeline => 'Zaman çizelgesi';

  @override
  String get movingViewRooms => 'Oda ve koliler';

  @override
  String get movingPhaseMonth => '1 ay önce';

  @override
  String get movingPhaseWeek => '1 hafta önce';

  @override
  String get movingPhaseDay => 'Taşınma günü';

  @override
  String get movingPhaseNewHome => 'Yeni evde';

  @override
  String get movingRoomKitchen => 'Mutfak';

  @override
  String get movingRoomLiving => 'Salon';

  @override
  String get movingRoomBedroom => 'Yatak odası';

  @override
  String get movingRoomBath => 'Banyo';

  @override
  String get movingRoomStudy => 'Çalışma';

  @override
  String get movingRoomGeneral => 'Genel';

  @override
  String movingBoxesCount(int count) {
    return '$count koli';
  }

  @override
  String movingFragileCount(int count) {
    return '$count kırılacak';
  }

  @override
  String get movingFragile => 'Kırılacak';

  @override
  String get movingOpenFirst => 'Önce aç';

  @override
  String get movingBoxNumber => 'Koli no (ör. #1)';

  @override
  String get movingAddHint => 'Taşınma adımı veya koli ekle…';

  @override
  String get packingBagChecked => 'Valiz';

  @override
  String get packingBagCabin => 'El bagajı';

  @override
  String get packingBagWear => 'Üstümde';

  @override
  String get packingReset => 'Bavulu sıfırla';

  @override
  String get packingAddHint => 'Eşya ekle (ör. 3 tişört)…';

  @override
  String workoutSetsCount(int done, int total) {
    return '$done/$total set';
  }

  @override
  String get workoutRestTimer => 'Dinlenme sayacı';

  @override
  String workoutRestSeconds(int sec) {
    return '$sec sn';
  }

  @override
  String get workoutAutoTimer => 'Set sonrası otomatik başlat';

  @override
  String get workoutSetsLabel => 'Set';

  @override
  String get workoutRepsLabel => 'Tekrar / süre';

  @override
  String get workoutWeightLabel => 'Ağırlık (ör. 20 kg)';

  @override
  String get workoutZoneWarmup => 'Isınma';

  @override
  String get workoutZoneUpper => 'Üst';

  @override
  String get workoutZoneLower => 'Alt';

  @override
  String get workoutZoneCore => 'Merkez';

  @override
  String get workoutZoneCardio => 'Kardiyo';

  @override
  String get workoutZoneStretch => 'Esneme';

  @override
  String get workoutReset => 'Antrenmanı sıfırla';

  @override
  String get workoutAddHint => 'Egzersiz ekle…';

  @override
  String get cleaningFreqDaily => 'Günlük';

  @override
  String get cleaningFreqWeekly => 'Haftalık';

  @override
  String get cleaningFreqMonthly => 'Aylık';

  @override
  String get cleaningReset => 'Döngüyü sıfırla';

  @override
  String get cleaningAddHint => 'Temizlik adımı ekle…';

  @override
  String get giftStageIdea => 'Fikir';

  @override
  String get giftStageBought => 'Alındı';

  @override
  String get giftStageWrapped => 'Paketlendi';

  @override
  String get giftStageGiven => 'Verildi';

  @override
  String get giftRecipient => 'Kime';

  @override
  String get giftPrice => 'Bütçe (₺)';

  @override
  String giftSummaryPlanned(String total, String bought) {
    return 'Toplam: $total ₺ · Alınan: $bought ₺';
  }

  @override
  String get giftAddHint => 'Hediye veya kişi ekle…';

  @override
  String get watchTypeMovie => 'Film';

  @override
  String get watchTypeSeries => 'Dizi';

  @override
  String get watchTypeBook => 'Kitap';

  @override
  String get watchTypeDoc => 'Belgesel';

  @override
  String get watchTypePodcast => 'Podcast';

  @override
  String get watchStatusQueued => 'Sırada';

  @override
  String get watchStatusWatching => 'Devam ediyor';

  @override
  String get watchStatusDone => 'Bitti';

  @override
  String get watchPlatform => 'Platform veya yazar';

  @override
  String get watchRating => 'Puanın';

  @override
  String get watchAddHint => 'Film, dizi veya kitap ekle…';

  @override
  String get expenseCatMarket => 'Market';

  @override
  String get expenseCatBills => 'Fatura';

  @override
  String get expenseCatTransport => 'Ulaşım';

  @override
  String get expenseCatFood => 'Yemek';

  @override
  String get expenseCatHome => 'Ev';

  @override
  String get expenseCatHealth => 'Sağlık';

  @override
  String get expenseCatFun => 'Keyif';

  @override
  String get expenseCatOther => 'Diğer';

  @override
  String expenseSummaryBar(String total, String paid, String left) {
    return 'Toplam: $total ₺ · Ödenen: $paid ₺ · Kalan: $left ₺';
  }

  @override
  String get expenseAmountHint => 'Tutar (₺)';

  @override
  String get expenseAddHint => 'Kalem ekle (ör. Elektrik 850)…';

  @override
  String get domainGearReset => 'Listeyi sıfırla';

  @override
  String get domainAddHint => 'Yeni madde ekle…';

  @override
  String get quickDropKeepOpen => 'Seri ekle (ekledikten sonra açık kal)';

  @override
  String get quickDropSmartListChip => 'Akıllı liste';

  @override
  String quickDropPreviewSmartList(String kind, String items) {
    return '✨ Yeni $kind: $items';
  }

  @override
  String quickDropSavedSmartList(String title) {
    return '“$title” akıllı listesi oluşturuldu';
  }

  @override
  String quickDropAddedSerial(String title) {
    return 'Eklendi: “$title”';
  }

  @override
  String get quickDropUrgentBadge => 'Acil';

  @override
  String get tplBadgeShopping => 'Reyon · 2 sütun';

  @override
  String get tplBadgeHabits => '7 gün · seri';

  @override
  String get tplBadgeMoving => 'Aşama · koli';

  @override
  String get tplBadgeTravel => 'El · valiz · sihirbaz';

  @override
  String get tplBadgeWorkout => 'Set · dinlenme';

  @override
  String get tplBadgeCleaning => 'Oda · sıklık';

  @override
  String get tplBadgeGifts => 'Fikir · bütçe';

  @override
  String get tplBadgeWatchlist => '5 yıldız · tür';

  @override
  String get tplBadgeExpense => 'Bütçe · toplam';

  @override
  String get templatesMoreSmartLists => 'Diğer akıllı listeler';

  @override
  String get smartListEntryHint =>
      'Yaz ya da söyle: pasaport, 2 süt, kahve 50 ₺…';

  @override
  String get quickListGenericHint => 'Madde yaz ya da söyle…';

  @override
  String get quickDropKeepOpenShort => 'Açık tut';

  @override
  String get quickDropTagHint => '#etiket';

  @override
  String get quickDropUrgentHint => '!acil';

  @override
  String get brightnessModeAuto => 'Otomatik';

  @override
  String get brightnessModeLight => 'Açık';

  @override
  String get brightnessModeDark => 'Koyu';

  @override
  String brightnessModeToggleTooltip(String mode) {
    return 'Görünüm kipi: $mode';
  }

  @override
  String get appearanceTabTheme => 'Tema';

  @override
  String get appearanceTabBackground => 'Zemin';

  @override
  String get appearanceTabLayout => 'Düzen';

  @override
  String get appearanceOpenStudio => 'Zeminler ve görünüm';

  @override
  String get applyHomeBackgroundToNotes => 'Notlara da uygula';

  @override
  String get applyHomeBackgroundToNotesInfo =>
      'Özel zemini olmayan notlar bu zemini kullanır.';

  @override
  String get noteUseHomeBackground => 'Ana ekran zemini';

  @override
  String get bgSubTabWallpapers => 'Görseller';

  @override
  String get bgSubTabIllustrated => 'Çizimli';

  @override
  String get bgSubTabColors => 'Renkler';

  @override
  String get bgSubTabPatterns => 'Desenler';

  @override
  String get bgSubTabFrame => 'Çerçeve';

  @override
  String get bgSubTabPaper => 'Defter';

  @override
  String get personalizeGroupEditor => 'Not editörü çubukları';

  @override
  String get personalizeGroupAddAttach => 'Ekleme ve ekler';

  @override
  String get personalizeEditBars => 'Not çubuklarını düzenle';

  @override
  String get attachmentRename => 'Yeniden adlandır';

  @override
  String get attachmentRenameHint => 'Ek adı';

  @override
  String attachmentsAllTitle(int count) {
    return 'Tüm ekler ($count)';
  }

  @override
  String get attachmentsAllButton => 'Tümü';

  @override
  String get attachmentRetryUpload => 'Yeniden dene';

  @override
  String get pinnedCollapse => 'Küçült';

  @override
  String get pinnedExpand => 'Genişlet';

  @override
  String get pinnedHideKeyboard => 'Klavyeyi gizle';

  @override
  String get floatingSizeSmall => 'Küçük';

  @override
  String get floatingSizeMedium => 'Orta';

  @override
  String get floatingSizeLarge => 'Tam';

  @override
  String get floatingAlignCycle => 'Yatay hiza';

  @override
  String get quickInboxFolderName => 'Hızlı not';

  @override
  String get quickInboxSubtitle => 'Emin olunmayan eklemeler burada toplanır';

  @override
  String get quickDropAddedQuickInbox => 'Hızlı not\'a eklendi';

  @override
  String get quickDropOpen => 'Aç';

  @override
  String quickDropTargetLabel(String target) {
    return 'Hedef: $target';
  }

  @override
  String get quickDropMergeSingle => 'Tek notta birleştir';

  @override
  String get quickDropPriorityUrgent => 'Acil';

  @override
  String get quickDropPriorityHigh => 'Yüksek';

  @override
  String get quickDropPriorityMedium => 'Orta';

  @override
  String get quickDropPriorityLow => 'Düşük';

  @override
  String quickDropContextNow(String title) {
    return 'Şimdi önerilen: $title';
  }

  @override
  String get listModeLabel => 'Liste kipi';

  @override
  String get listModeGeneral => 'Genel';

  @override
  String get listModeShopping => 'Alışveriş';

  @override
  String get listModeRoutine => 'Rutin';

  @override
  String get listModeTemplate => 'Şablon';

  @override
  String get listModeProject => 'Proje';

  @override
  String get listModeResetSchedule => 'Sıfırlama';

  @override
  String get listModeResetNone => 'Kapalı';

  @override
  String get listModeResetDaily => 'Her gece';

  @override
  String get listModeResetWeekly => 'Her hafta';

  @override
  String get listModeResetCustom => 'Özel günler';

  @override
  String get listModeTimeSlot => 'Zaman dilimi';

  @override
  String get listModeSlotAny => 'Her zaman';

  @override
  String get listModeSlotMorning => 'Sabah';

  @override
  String get listModeSlotEvening => 'Akşam';

  @override
  String get listModeSlotWeekend => 'Hafta sonu';

  @override
  String get shoppingGroupToggle => 'Reyonlar';

  @override
  String shoppingBoughtCount(int done, int total) {
    return '$done/$total alındı';
  }

  @override
  String shoppingTotalAmount(String amount) {
    return 'Toplam: $amount';
  }

  @override
  String shoppingSummaryRemaining(int count) {
    return '$count kaldı';
  }

  @override
  String routineTodayProgress(int done, int total) {
    return 'Bugün $done/$total';
  }

  @override
  String routineStreakDays(int count) {
    return '$count gün';
  }

  @override
  String routineBestStreak(int count) {
    return 'En iyi seri: $count gün';
  }

  @override
  String get routineLast30Days => 'Son 30 gün';

  @override
  String get templateResetReuse => 'Tümünü sıfırla ve tekrar kullan';

  @override
  String get templateResetDone => 'Tüm maddeler sıfırlandı';

  @override
  String get templateCopyNew => 'Yeni liste olarak kopyala';

  @override
  String get projectFocusToggle => 'Odak (3)';

  @override
  String get projectFocusExit => 'Odağı kapat';

  @override
  String get projectFocusPick => 'Odak seç';

  @override
  String projectFocusActive(int shown, int total) {
    return 'Odak kipi: $shown/$total';
  }

  @override
  String projectProgressLabel(int percent, int done, int total) {
    return '%$percent · $done/$total';
  }

  @override
  String get itemQuickPostponeTomorrow => 'Yarına ertele';

  @override
  String get itemQuickPriority => 'Öncelik';

  @override
  String get itemQuickDueDate => 'Tarih';

  @override
  String get itemQuickPrice => 'Fiyat';

  @override
  String get itemQuickFocus => 'Odağa al';

  @override
  String get itemQuickUnfocus => 'Odaktan çıkar';

  @override
  String get itemQuickMeta => 'Ayrıntılar';

  @override
  String get itemDueToday => 'Bugün';

  @override
  String get itemDueTomorrow => 'Yarın';

  @override
  String get itemDueNextWeek => 'Gelecek hafta';

  @override
  String get itemDueClear => 'Tarihi kaldır';

  @override
  String get itemPriorityNone => 'Yok';

  @override
  String get listModeNudgeShopping => 'Alışveriş kipine geç?';

  @override
  String get listModeNudgeRoutine => 'Rutin kipine geç?';

  @override
  String get listModeQuickAddHint => 'Örn. 2 kg domates, kahve 180 tl…';

  @override
  String get ghostSuggestionsTitle => 'Önerilen maddeler';

  @override
  String get ghostReasonDue => 'Sık alıyorsun';

  @override
  String get ghostReasonPair => 'Yanında iyi gider';

  @override
  String get ghostReasonFrequent => 'Sık eklediklerin';

  @override
  String get ghostReasonTemplate => 'Eksik olabilir';

  @override
  String get ghostReasonRoutine => 'Günlük öneri';

  @override
  String get itemBreakdownAction => 'Alt adımlara böl';

  @override
  String get itemBreakdownTitle => 'Alt adımlar';

  @override
  String get itemBreakdownApply => 'Alt adımları ekle';

  @override
  String get itemBreakdownEmpty => 'Alt adım önerilemedi';

  @override
  String get textExtractAction => 'Metinden ayıkla';

  @override
  String get textExtractTitle => 'Metinden madde ayıkla';

  @override
  String get textExtractHint =>
      'Mesaj, tarif veya liste metnini buraya yapıştır…';

  @override
  String get textExtractRefineAi => 'Yapay zekâ ile netleştir';

  @override
  String textExtractAddSelected(int count) {
    return 'Seçilenleri ekle ($count)';
  }

  @override
  String textExtractPasteBanner(int count) {
    return 'Metinden $count madde ayıkla';
  }

  @override
  String get listAiQuotaReached =>
      'Günlük yapay zekâ kotan doldu; yerel öneri kullanıldı.';

  @override
  String carryOverBanner(int count) {
    return 'Önceki günden $count görev kaldı';
  }

  @override
  String get carryOverAction => 'Bugüne aktar';

  @override
  String carryOverDone(int count) {
    return '$count görev bugüne aktarıldı';
  }

  @override
  String get contextNowBadge => 'Şimdi';
}
