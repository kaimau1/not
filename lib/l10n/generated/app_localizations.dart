import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// No description provided for @appName.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get appName;

  /// No description provided for @loginTagline.
  ///
  /// In tr, this message translates to:
  /// **'Notların her cihazda seninle'**
  String get loginTagline;

  /// No description provided for @signInWithGoogle.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş yap'**
  String get signInWithGoogle;

  /// No description provided for @loginError.
  ///
  /// In tr, this message translates to:
  /// **'Giriş başarısız: {error}'**
  String loginError(String error);

  /// No description provided for @searchHint.
  ///
  /// In tr, this message translates to:
  /// **'Notlarda ara...'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get filterAll;

  /// No description provided for @filterText.
  ///
  /// In tr, this message translates to:
  /// **'Metin'**
  String get filterText;

  /// No description provided for @filterChecklist.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get filterChecklist;

  /// No description provided for @filterOrdered.
  ///
  /// In tr, this message translates to:
  /// **'Sıralı'**
  String get filterOrdered;

  /// No description provided for @filterPinned.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlenmiş'**
  String get filterPinned;

  /// No description provided for @filterStarred.
  ///
  /// In tr, this message translates to:
  /// **'Yıldızlı'**
  String get filterStarred;

  /// No description provided for @star.
  ///
  /// In tr, this message translates to:
  /// **'Yıldızla'**
  String get star;

  /// No description provided for @unstar.
  ///
  /// In tr, this message translates to:
  /// **'Yıldızı kaldır'**
  String get unstar;

  /// No description provided for @editedAt.
  ///
  /// In tr, this message translates to:
  /// **'Düzenlendi: {date}'**
  String editedAt(String date);

  /// No description provided for @sectionPinned.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlenmiş'**
  String get sectionPinned;

  /// No description provided for @sectionOthers.
  ///
  /// In tr, this message translates to:
  /// **'Diğerleri'**
  String get sectionOthers;

  /// No description provided for @emptyNotes.
  ///
  /// In tr, this message translates to:
  /// **'Henüz not yok'**
  String get emptyNotes;

  /// No description provided for @emptyNotesHint.
  ///
  /// In tr, this message translates to:
  /// **'İlk notunu eklemek için + düğmesine dokun'**
  String get emptyNotesHint;

  /// No description provided for @emptySearch.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadı'**
  String get emptySearch;

  /// No description provided for @newTextNote.
  ///
  /// In tr, this message translates to:
  /// **'Metin notu'**
  String get newTextNote;

  /// No description provided for @newChecklist.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get newChecklist;

  /// No description provided for @newOrderedList.
  ///
  /// In tr, this message translates to:
  /// **'Sıralı liste'**
  String get newOrderedList;

  /// No description provided for @noteDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Not silindi'**
  String get noteDeleted;

  /// No description provided for @notesDeletedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} not silindi'**
  String notesDeletedCount(int count);

  /// No description provided for @selectedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} seçildi'**
  String selectedCount(int count);

  /// No description provided for @deleteSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilenleri sil'**
  String get deleteSelected;

  /// No description provided for @undo.
  ///
  /// In tr, this message translates to:
  /// **'Geri Al'**
  String get undo;

  /// No description provided for @titleHint.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get titleHint;

  /// No description provided for @bodyHint.
  ///
  /// In tr, this message translates to:
  /// **'Not...'**
  String get bodyHint;

  /// No description provided for @newItemHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni öğe'**
  String get newItemHint;

  /// No description provided for @checkedItemsCount.
  ///
  /// In tr, this message translates to:
  /// **'İşaretlenenler ({count})'**
  String checkedItemsCount(int count);

  /// No description provided for @moreItemsCount.
  ///
  /// In tr, this message translates to:
  /// **'+{count} öğe daha'**
  String moreItemsCount(int count);

  /// No description provided for @addAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get addAttachment;

  /// No description provided for @addImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel ekle'**
  String get addImage;

  /// No description provided for @addPdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF ekle'**
  String get addPdf;

  /// No description provided for @pasteImage.
  ///
  /// In tr, this message translates to:
  /// **'Panodan görsel yapıştır'**
  String get pasteImage;

  /// No description provided for @clipboardEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Panoda görsel yok'**
  String get clipboardEmpty;

  /// No description provided for @attachmentUploading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get attachmentUploading;

  /// No description provided for @attachmentNotSynced.
  ///
  /// In tr, this message translates to:
  /// **'Dosya bu cihaza henüz senkronlanmadı'**
  String get attachmentNotSynced;

  /// No description provided for @attachmentTooLarge.
  ///
  /// In tr, this message translates to:
  /// **'Dosya çok büyük (en fazla {limit} MB)'**
  String attachmentTooLarge(int limit);

  /// No description provided for @removeAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Eki kaldır'**
  String get removeAttachment;

  /// No description provided for @pin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitle'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitlemeyi kaldır'**
  String get unpin;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @color.
  ///
  /// In tr, this message translates to:
  /// **'Renk'**
  String get color;

  /// No description provided for @aiTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka'**
  String get aiTitle;

  /// No description provided for @aiSummarize.
  ///
  /// In tr, this message translates to:
  /// **'Notu özetle'**
  String get aiSummarize;

  /// No description provided for @aiAnalyze.
  ///
  /// In tr, this message translates to:
  /// **'Analiz et'**
  String get aiAnalyze;

  /// No description provided for @aiSectionNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu not'**
  String get aiSectionNote;

  /// No description provided for @aiSectionAttachments.
  ///
  /// In tr, this message translates to:
  /// **'Ekler'**
  String get aiSectionAttachments;

  /// No description provided for @summarize.
  ///
  /// In tr, this message translates to:
  /// **'Özetle'**
  String get summarize;

  /// No description provided for @listen.
  ///
  /// In tr, this message translates to:
  /// **'Sesli dinle'**
  String get listen;

  /// No description provided for @ask.
  ///
  /// In tr, this message translates to:
  /// **'Soru sor'**
  String get ask;

  /// No description provided for @extractText.
  ///
  /// In tr, this message translates to:
  /// **'Metni çıkar'**
  String get extractText;

  /// No description provided for @transcribe.
  ///
  /// In tr, this message translates to:
  /// **'Yazıya dök'**
  String get transcribe;

  /// No description provided for @listenToNote.
  ///
  /// In tr, this message translates to:
  /// **'Sesli oku'**
  String get listenToNote;

  /// No description provided for @aiSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Öneriler'**
  String get aiSuggestions;

  /// No description provided for @aiNoApiKey.
  ///
  /// In tr, this message translates to:
  /// **'Önce Ayarlar\'dan Gemini API anahtarını gir'**
  String get aiNoApiKey;

  /// No description provided for @aiError.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka isteği başarısız: {error}'**
  String aiError(String error);

  /// No description provided for @aiSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'AI Özeti'**
  String get aiSummaryTitle;

  /// No description provided for @aiThinking.
  ///
  /// In tr, this message translates to:
  /// **'Düşünüyor...'**
  String get aiThinking;

  /// No description provided for @copy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get copied;

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @settingsAppearance.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get settingsAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get themeDark;

  /// No description provided for @settingsAi.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka'**
  String get settingsAi;

  /// No description provided for @geminiApiKey.
  ///
  /// In tr, this message translates to:
  /// **'Gemini API Anahtarı'**
  String get geminiApiKey;

  /// No description provided for @geminiApiKeyHint.
  ///
  /// In tr, this message translates to:
  /// **'AIza... ile başlayan anahtarı yapıştır'**
  String get geminiApiKeyHint;

  /// No description provided for @geminiApiKeyInfo.
  ///
  /// In tr, this message translates to:
  /// **'Anahtar girmek isteğe bağlıdır: girmezsen AI istekleri uygulamanın dahili altyapısından yapılır (günlük ücretsiz hak, Premium ile daha yüksek günlük hak). Kendi anahtarınla sınırsız kullanım için aistudio.google.com adresinden ücretsiz anahtar alabilirsin; anahtar yalnızca bu cihazda güvenli depoda saklanır.'**
  String get geminiApiKeyInfo;

  /// No description provided for @aiBuiltInPremium.
  ///
  /// In tr, this message translates to:
  /// **'Dahili AI: Premium — bugün kalan hak {count}'**
  String aiBuiltInPremium(int count);

  /// No description provided for @aiBuiltInRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Dahili AI: bugün kalan ücretsiz hak {count}'**
  String aiBuiltInRemaining(int count);

  /// No description provided for @aiBuiltInByok.
  ///
  /// In tr, this message translates to:
  /// **'Kendi anahtarın kullanılıyor — sınırsız'**
  String get aiBuiltInByok;

  /// No description provided for @aiReport.
  ///
  /// In tr, this message translates to:
  /// **'Yanıtı bildir'**
  String get aiReport;

  /// No description provided for @aiReportThanks.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimin alındı, teşekkürler'**
  String get aiReportThanks;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicyTitle;

  /// No description provided for @lockNote.
  ///
  /// In tr, this message translates to:
  /// **'Kilitle'**
  String get lockNote;

  /// No description provided for @unlockNote.
  ///
  /// In tr, this message translates to:
  /// **'Kilidi kaldır'**
  String get unlockNote;

  /// No description provided for @lockedNote.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli not'**
  String get lockedNote;

  /// No description provided for @unlockAuthReason.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli notu açmak için kimliğini doğrula'**
  String get unlockAuthReason;

  /// No description provided for @exportBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği dışa aktar (JSON)'**
  String get exportBackup;

  /// No description provided for @expandListItems.
  ///
  /// In tr, this message translates to:
  /// **'Liste satırlarını tam göster'**
  String get expandListItems;

  /// No description provided for @expandListItemsInfo.
  ///
  /// In tr, this message translates to:
  /// **'Uzun liste/işaret öğeleri birkaç satıra sarılıp tamamen görünür. Kapalıyken satır tek satırda kalır, dokununca açılır.'**
  String get expandListItemsInfo;

  /// No description provided for @emptyTrash.
  ///
  /// In tr, this message translates to:
  /// **'Çöpü boşalt'**
  String get emptyTrash;

  /// No description provided for @emptyTrashConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{count} not kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misin?'**
  String emptyTrashConfirm(int count);

  /// No description provided for @trashEmptied.
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu boşaltıldı'**
  String get trashEmptied;

  /// No description provided for @validateAndSave.
  ///
  /// In tr, this message translates to:
  /// **'Doğrula ve Kaydet'**
  String get validateAndSave;

  /// No description provided for @apiKeyValid.
  ///
  /// In tr, this message translates to:
  /// **'API anahtarı doğrulandı ve kaydedildi'**
  String get apiKeyValid;

  /// No description provided for @apiKeyInvalid.
  ///
  /// In tr, this message translates to:
  /// **'API anahtarı geçersiz'**
  String get apiKeyInvalid;

  /// No description provided for @apiKeySavedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı'**
  String get apiKeySavedBadge;

  /// No description provided for @removeApiKey.
  ///
  /// In tr, this message translates to:
  /// **'Anahtarı sil'**
  String get removeApiKey;

  /// No description provided for @settingsGmail.
  ///
  /// In tr, this message translates to:
  /// **'Gmail'**
  String get settingsGmail;

  /// No description provided for @connectGmail.
  ///
  /// In tr, this message translates to:
  /// **'Gmail\'i Bağla'**
  String get connectGmail;

  /// No description provided for @gmailConnected.
  ///
  /// In tr, this message translates to:
  /// **'Gmail bağlı'**
  String get gmailConnected;

  /// No description provided for @gmailChangeAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap değiştir'**
  String get gmailChangeAccount;

  /// No description provided for @gmailInfo.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka, gelen kutundaki son e-postaları tarayıp önemli olanları kısaca özetler. E-posta içeriği hiçbir yere kaydedilmez.'**
  String get gmailInfo;

  /// No description provided for @disconnectGmail.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kes'**
  String get disconnectGmail;

  /// No description provided for @importantEmails.
  ///
  /// In tr, this message translates to:
  /// **'Önemli E-postalar'**
  String get importantEmails;

  /// No description provided for @refresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get refresh;

  /// No description provided for @account.
  ///
  /// In tr, this message translates to:
  /// **'Hesap'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yapmak istediğine emin misin?'**
  String get signOutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabımı ve verilerimi sil'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz: tüm notların, eklerin ve hesabın kalıcı olarak silinir. Devam etmek istediğine emin misin?'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı olarak sil'**
  String get deleteAccountConfirm;

  /// No description provided for @licensesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açık kaynak lisansları'**
  String get licensesTitle;

  /// No description provided for @mailEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Önemli e-posta bulunamadı'**
  String get mailEmpty;

  /// No description provided for @mailScanning.
  ///
  /// In tr, this message translates to:
  /// **'E-postalar taranıyor...'**
  String get mailScanning;

  /// No description provided for @mailWhyImportant.
  ///
  /// In tr, this message translates to:
  /// **'Neden önemli: {reason}'**
  String mailWhyImportant(String reason);

  /// No description provided for @suggestionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öneriler'**
  String get suggestionsTitle;

  /// No description provided for @suggestionsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Öneri üretebilmek için birkaç not ekle'**
  String get suggestionsEmpty;

  /// No description provided for @suggestionsIntro.
  ///
  /// In tr, this message translates to:
  /// **'Notlarına göre öneriler'**
  String get suggestionsIntro;

  /// No description provided for @generating.
  ///
  /// In tr, this message translates to:
  /// **'Üretiliyor...'**
  String get generating;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @syncPending.
  ///
  /// In tr, this message translates to:
  /// **'Senkron bekleniyor'**
  String get syncPending;

  /// No description provided for @synced.
  ///
  /// In tr, this message translates to:
  /// **'Senkronize'**
  String get synced;

  /// No description provided for @genericError.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti: {error}'**
  String genericError(String error);

  /// No description provided for @addTag.
  ///
  /// In tr, this message translates to:
  /// **'Etiket'**
  String get addTag;

  /// No description provided for @tagHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. iş, ev, okul'**
  String get tagHint;

  /// No description provided for @addReminder.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlat'**
  String get addReminder;

  /// No description provided for @share.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get share;

  /// No description provided for @archive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get archive;

  /// No description provided for @unarchive.
  ///
  /// In tr, this message translates to:
  /// **'Arşivden çıkar'**
  String get unarchive;

  /// No description provided for @archiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv'**
  String get archiveTitle;

  /// No description provided for @archiveEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Arşivde not yok'**
  String get archiveEmpty;

  /// No description provided for @trashTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çöp Kutusu'**
  String get trashTitle;

  /// No description provided for @trashEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Çöp kutusu boş'**
  String get trashEmpty;

  /// No description provided for @trashInfo.
  ///
  /// In tr, this message translates to:
  /// **'Silinen notlar burada durur; geri alabilir veya kalıcı olarak silebilirsin.'**
  String get trashInfo;

  /// No description provided for @restore.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get restore;

  /// No description provided for @deleteForever.
  ///
  /// In tr, this message translates to:
  /// **'Kalıcı olarak sil'**
  String get deleteForever;

  /// No description provided for @deleteForeverConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Bu not kalıcı olarak silinecek. Emin misin?'**
  String get deleteForeverConfirm;

  /// No description provided for @recordAudio.
  ///
  /// In tr, this message translates to:
  /// **'Ses kaydı'**
  String get recordAudio;

  /// No description provided for @recording.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get recording;

  /// No description provided for @stopAndSave.
  ///
  /// In tr, this message translates to:
  /// **'Bitir ve ekle'**
  String get stopAndSave;

  /// No description provided for @micPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon izni verilmedi'**
  String get micPermissionDenied;

  /// No description provided for @addDrawing.
  ///
  /// In tr, this message translates to:
  /// **'Çizim ekle'**
  String get addDrawing;

  /// No description provided for @drawingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizim'**
  String get drawingTitle;

  /// No description provided for @addToNote.
  ///
  /// In tr, this message translates to:
  /// **'Nota ekle'**
  String get addToNote;

  /// No description provided for @chatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Notlarla Sohbet'**
  String get chatTitle;

  /// No description provided for @chatHint.
  ///
  /// In tr, this message translates to:
  /// **'Notların hakkında soru sor: \"geçen hafta yazdığım tarif neydi?\", \"alışveriş listemde ne eksik?\"'**
  String get chatHint;

  /// No description provided for @chatInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir soru yaz...'**
  String get chatInputHint;

  /// No description provided for @weeklySummary.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Özet'**
  String get weeklySummary;

  /// No description provided for @weeklySummaryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günde not eklenmemiş'**
  String get weeklySummaryEmpty;

  /// No description provided for @weeklySummaryIntro.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günün özeti'**
  String get weeklySummaryIntro;

  /// No description provided for @fontSize.
  ///
  /// In tr, this message translates to:
  /// **'Yazı boyutu'**
  String get fontSize;

  /// No description provided for @darkSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Koyu tema zamanlaması'**
  String get darkSchedule;

  /// No description provided for @darkScheduleInfo.
  ///
  /// In tr, this message translates to:
  /// **'Belirlediğin saatler arasında koyu temaya geçilir'**
  String get darkScheduleInfo;

  /// No description provided for @convertToNote.
  ///
  /// In tr, this message translates to:
  /// **'Nota çevir'**
  String get convertToNote;

  /// No description provided for @convertToReminderNote.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılı not'**
  String get convertToReminderNote;

  /// No description provided for @noteCreatedFromEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-postadan not oluşturuldu'**
  String get noteCreatedFromEmail;

  /// No description provided for @mailDueDate.
  ///
  /// In tr, this message translates to:
  /// **'Son tarih: {date}'**
  String mailDueDate(String date);

  /// No description provided for @translatorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çevirmen'**
  String get translatorTitle;

  /// No description provided for @aiTranslate.
  ///
  /// In tr, this message translates to:
  /// **'Çevir'**
  String get aiTranslate;

  /// No description provided for @swapLanguages.
  ///
  /// In tr, this message translates to:
  /// **'Dilleri değiştir'**
  String get swapLanguages;

  /// No description provided for @liveMode.
  ///
  /// In tr, this message translates to:
  /// **'Canlı'**
  String get liveMode;

  /// No description provided for @pushToTalkMode.
  ///
  /// In tr, this message translates to:
  /// **'Bas-Konuş'**
  String get pushToTalkMode;

  /// No description provided for @liveTranslateInfo.
  ///
  /// In tr, this message translates to:
  /// **'Gemini 3.5 Live Translate ile kesintisiz çeviri: başlatın ve konuşun; hangi dilde konuşulduğu otomatik algılanır, karşı dile hem sesli hem yazılı çevrilir.'**
  String get liveTranslateInfo;

  /// No description provided for @startLive.
  ///
  /// In tr, this message translates to:
  /// **'Canlı çeviriyi başlat'**
  String get startLive;

  /// No description provided for @stopLive.
  ///
  /// In tr, this message translates to:
  /// **'Durdur'**
  String get stopLive;

  /// No description provided for @connecting.
  ///
  /// In tr, this message translates to:
  /// **'Bağlanıyor...'**
  String get connecting;

  /// No description provided for @heardLabel.
  ///
  /// In tr, this message translates to:
  /// **'Duyulan'**
  String get heardLabel;

  /// No description provided for @translationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri'**
  String get translationLabel;

  /// No description provided for @liveTranslateError.
  ///
  /// In tr, this message translates to:
  /// **'Canlı çeviri hatası: {error}'**
  String liveTranslateError(String error);

  /// No description provided for @pushToTalk.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmak için dokun'**
  String get pushToTalk;

  /// No description provided for @pushToTalkHint.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofona dokunup konuş; hangi dilde konuştuğun otomatik algılanır ve karşı dile çevrilir. Karşındaki de aynı düğmeyle kendi dilinde yanıt verebilir.'**
  String get pushToTalkHint;

  /// No description provided for @autoSpeak.
  ///
  /// In tr, this message translates to:
  /// **'Çeviriyi sesli oku'**
  String get autoSpeak;

  /// No description provided for @speakTranslation.
  ///
  /// In tr, this message translates to:
  /// **'Sesli oku'**
  String get speakTranslation;

  /// No description provided for @voiceCommand.
  ///
  /// In tr, this message translates to:
  /// **'Sesli komut'**
  String get voiceCommand;

  /// No description provided for @semanticSearchToggle.
  ///
  /// In tr, this message translates to:
  /// **'AI ile anlamsal arama'**
  String get semanticSearchToggle;

  /// No description provided for @semanticSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Anlamıyla ara: \"araba masrafları\"...'**
  String get semanticSearchHint;

  /// No description provided for @briefingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Brifing'**
  String get briefingTitle;

  /// No description provided for @briefingLoading.
  ///
  /// In tr, this message translates to:
  /// **'Brifing hazırlanıyor...'**
  String get briefingLoading;

  /// No description provided for @briefingEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bugün için içerik yok'**
  String get briefingEmpty;

  /// No description provided for @briefingSetting.
  ///
  /// In tr, this message translates to:
  /// **'Günlük brifing bildirimi'**
  String get briefingSetting;

  /// No description provided for @briefingSettingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Her sabah seçtiğin saatte günün özeti için bildirim al'**
  String get briefingSettingInfo;

  /// No description provided for @autoTagSetting.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik etiketle'**
  String get autoTagSetting;

  /// No description provided for @autoTagSettingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Not kapanırken etiketi yoksa yapay zeka uygun etiketi kendisi ekler'**
  String get autoTagSettingInfo;

  /// No description provided for @suggestTags.
  ///
  /// In tr, this message translates to:
  /// **'Etiket öner'**
  String get suggestTags;

  /// No description provided for @aiFixNote.
  ///
  /// In tr, this message translates to:
  /// **'Notu düzelt (yazım + düzen)'**
  String get aiFixNote;

  /// No description provided for @aiImprove.
  ///
  /// In tr, this message translates to:
  /// **'Notu geliştir'**
  String get aiImprove;

  /// No description provided for @improveFix.
  ///
  /// In tr, this message translates to:
  /// **'Yazımı ve dilbilgisini düzelt'**
  String get improveFix;

  /// No description provided for @improveFormal.
  ///
  /// In tr, this message translates to:
  /// **'Daha resmî yap'**
  String get improveFormal;

  /// No description provided for @improveShorten.
  ///
  /// In tr, this message translates to:
  /// **'Kısalt'**
  String get improveShorten;

  /// No description provided for @improveBullets.
  ///
  /// In tr, this message translates to:
  /// **'Madde listesine çevir'**
  String get improveBullets;

  /// No description provided for @improveNumbered.
  ///
  /// In tr, this message translates to:
  /// **'Sıralı (numaralı) listeye çevir'**
  String get improveNumbered;

  /// No description provided for @replaceNote.
  ///
  /// In tr, this message translates to:
  /// **'Notu değiştir'**
  String get replaceNote;

  /// No description provided for @pdfChatHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu PDF hakkında soru sor: \"özetle\", \"cezai şart var mı?\", \"son teslim tarihi ne?\"'**
  String get pdfChatHint;

  /// No description provided for @pdfChatInputHint.
  ///
  /// In tr, this message translates to:
  /// **'PDF hakkında bir soru yaz...'**
  String get pdfChatInputHint;

  /// No description provided for @voiceNoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sesli Not'**
  String get voiceNoteTitle;

  /// No description provided for @voiceCaptureHint.
  ///
  /// In tr, this message translates to:
  /// **'Konuş: \"süt ve ekmek al\" ya da \"yarın 9\'da toplantı, hatırlat\" — bitince notunu yapay zeka oluşturur.'**
  String get voiceCaptureHint;

  /// No description provided for @voiceFinish.
  ///
  /// In tr, this message translates to:
  /// **'Bitir'**
  String get voiceFinish;

  /// No description provided for @voiceProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Söyledikleriniz uygulanıyor...'**
  String get voiceProcessing;

  /// No description provided for @voiceNothingHeard.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtta konuşma algılanamadı'**
  String get voiceNothingHeard;

  /// No description provided for @voiceNoteSaved.
  ///
  /// In tr, this message translates to:
  /// **'Sesli notun kaydedildi'**
  String get voiceNoteSaved;

  /// No description provided for @openNote.
  ///
  /// In tr, this message translates to:
  /// **'Notu aç'**
  String get openNote;

  /// No description provided for @remindersTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar'**
  String get remindersTitle;

  /// No description provided for @remindersEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcı yok'**
  String get remindersEmpty;

  /// No description provided for @remindersEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir nota hatırlatıcı ekle veya + düğmesiyle yeni bir hatırlatıcılı not oluştur'**
  String get remindersEmptyHint;

  /// No description provided for @remindersUpcoming.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşan'**
  String get remindersUpcoming;

  /// No description provided for @remindersPast.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get remindersPast;

  /// No description provided for @newReminder.
  ///
  /// In tr, this message translates to:
  /// **'Yeni hatırlatıcı'**
  String get newReminder;

  /// No description provided for @remindersUntitled.
  ///
  /// In tr, this message translates to:
  /// **'Adsız not'**
  String get remindersUntitled;

  /// No description provided for @remindersEdit.
  ///
  /// In tr, this message translates to:
  /// **'Zamanı değiştir'**
  String get remindersEdit;

  /// No description provided for @remindersRemove.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcıyı kaldır'**
  String get remindersRemove;

  /// No description provided for @aiModelChat.
  ///
  /// In tr, this message translates to:
  /// **'Özet, başlık, etiket ve sohbet'**
  String get aiModelChat;

  /// No description provided for @aiModelDocument.
  ///
  /// In tr, this message translates to:
  /// **'Podcast ve belge sohbeti'**
  String get aiModelDocument;

  /// No description provided for @aiModelTranslate.
  ///
  /// In tr, this message translates to:
  /// **'Çeviri'**
  String get aiModelTranslate;

  /// No description provided for @aiModelVoice.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not'**
  String get aiModelVoice;

  /// No description provided for @aiModelAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik (önerilen)'**
  String get aiModelAuto;

  /// No description provided for @aiModelsInfo.
  ///
  /// In tr, this message translates to:
  /// **'Her iş için ayrı model seçebilirsin: kısa metin işleri hızlı modelle yeter, uzun belge işi yetenekli model ister. Seçtiğin model kota doldurur veya kaldırılırsa sıradaki otomatik denenir.'**
  String get aiModelsInfo;

  /// No description provided for @clearNote.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clearNote;

  /// No description provided for @clearNoteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Notun içeriği (metin ve liste öğeleri) silinecek. Emin misin?'**
  String get clearNoteConfirm;

  /// No description provided for @themePaper.
  ///
  /// In tr, this message translates to:
  /// **'Kağıt'**
  String get themePaper;

  /// No description provided for @calculatorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Makinesi'**
  String get calculatorTitle;

  /// No description provided for @calcExpressionHint.
  ///
  /// In tr, this message translates to:
  /// **'ör. 12,5×3+40'**
  String get calcExpressionHint;

  /// No description provided for @calcInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz ifade'**
  String get calcInvalid;

  /// No description provided for @liveDictation.
  ///
  /// In tr, this message translates to:
  /// **'Sesli yazdır'**
  String get liveDictation;

  /// No description provided for @dictationListening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleniyor... konuştukça metin yazılır'**
  String get dictationListening;

  /// No description provided for @dictationNoKeyInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda anlık yazdırma yok; kayıt bitince tek seferde yazıya dökülecek.'**
  String get dictationNoKeyInfo;

  /// No description provided for @dictationHoldHint.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofonu basılı tutup konuşun, bırakınca yazılır'**
  String get dictationHoldHint;

  /// No description provided for @itemsSelected.
  ///
  /// In tr, this message translates to:
  /// **'{count} madde seçildi'**
  String itemsSelected(int count);

  /// No description provided for @noteChatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu notla sohbet et'**
  String get noteChatTitle;

  /// No description provided for @noteChatHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu not hakkında bir şey sor'**
  String get noteChatHint;

  /// No description provided for @noteChatIntro.
  ///
  /// In tr, this message translates to:
  /// **'Notun içeriği ve ekleri (PDF/görsel) okunur, sorunu ona göre yanıtlar.'**
  String get noteChatIntro;

  /// No description provided for @dictationProcessing.
  ///
  /// In tr, this message translates to:
  /// **'Yazıya dökülüyor...'**
  String get dictationProcessing;

  /// No description provided for @aiDailyManualInfo.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz planda bu içerik günlük hakkını boşa harcamamak için otomatik oluşturulmaz. Günde bir kez, aşağıdaki düğmeyle oluşturabilirsin.'**
  String get aiDailyManualInfo;

  /// No description provided for @aiGenerate.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get aiGenerate;

  /// No description provided for @aiScanEmails.
  ///
  /// In tr, this message translates to:
  /// **'E-postaları tara'**
  String get aiScanEmails;

  /// No description provided for @aiGeneratedTodayInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu içerik bugün oluşturuldu. Ücretsiz planda günde bir kez yenilenir; yarın tekrar oluşturabilirsin.'**
  String get aiGeneratedTodayInfo;

  /// No description provided for @voiceAssistantTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sesli Not Asistanı'**
  String get voiceAssistantTitle;

  /// No description provided for @voiceListening.
  ///
  /// In tr, this message translates to:
  /// **'Dinliyorum...'**
  String get voiceListening;

  /// No description provided for @voiceHoldHint.
  ///
  /// In tr, this message translates to:
  /// **'Basılı tutarak konuş; bırakınca notun oluşturulur'**
  String get voiceHoldHint;

  /// No description provided for @voiceTapHint.
  ///
  /// In tr, this message translates to:
  /// **'Dokun ve konuş; bitirmek için tekrar dokun'**
  String get voiceTapHint;

  /// No description provided for @voiceTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt çok kısaydı, tekrar dene'**
  String get voiceTooShort;

  /// No description provided for @voiceModeSetting.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım şekli'**
  String get voiceModeSetting;

  /// No description provided for @voiceModeHold.
  ///
  /// In tr, this message translates to:
  /// **'Basılı tut'**
  String get voiceModeHold;

  /// No description provided for @voiceModeTap.
  ///
  /// In tr, this message translates to:
  /// **'Bas-başlat / bas-bitir'**
  String get voiceModeTap;

  /// No description provided for @voiceModeInfo.
  ///
  /// In tr, this message translates to:
  /// **'Basılı tut: düğmeye bastığın sürece dinler, bırakınca notu oluşturur. Bas-başlat: bir dokunuşla kayıt başlar, ikinci dokunuşla biter.'**
  String get voiceModeInfo;

  /// No description provided for @voiceHeardLive.
  ///
  /// In tr, this message translates to:
  /// **'Algılanan konuşma'**
  String get voiceHeardLive;

  /// No description provided for @permissionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzinler'**
  String get permissionsTitle;

  /// No description provided for @permMic.
  ///
  /// In tr, this message translates to:
  /// **'Mikrofon'**
  String get permMic;

  /// No description provided for @permMicInfo.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not, dikte ve canlı çeviri için gerekli'**
  String get permMicInfo;

  /// No description provided for @permNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get permNotifications;

  /// No description provided for @permNotificationsInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcılar ve günlük brifing için gerekli'**
  String get permNotificationsInfo;

  /// No description provided for @permBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu'**
  String get permBattery;

  /// No description provided for @permBatteryInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatıcıların gecikmeden gelmesi için uygulamayı pil kısıtlamasından muaf tut'**
  String get permBatteryInfo;

  /// No description provided for @permGranted.
  ///
  /// In tr, this message translates to:
  /// **'İzin verildi'**
  String get permGranted;

  /// No description provided for @permGrant.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get permGrant;

  /// No description provided for @permOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get permOpenSettings;

  /// No description provided for @newHandwriting.
  ///
  /// In tr, this message translates to:
  /// **'El yazısı'**
  String get newHandwriting;

  /// No description provided for @suggestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlık öner'**
  String get suggestTitle;

  /// No description provided for @noteMetaMenu.
  ///
  /// In tr, this message translates to:
  /// **'Ekle / Öner'**
  String get noteMetaMenu;

  /// No description provided for @folder.
  ///
  /// In tr, this message translates to:
  /// **'Klasör'**
  String get folder;

  /// No description provided for @noFolder.
  ///
  /// In tr, this message translates to:
  /// **'Klasörsüz'**
  String get noFolder;

  /// No description provided for @newFolder.
  ///
  /// In tr, this message translates to:
  /// **'Yeni klasör'**
  String get newFolder;

  /// No description provided for @editFolder.
  ///
  /// In tr, this message translates to:
  /// **'Klasörü düzenle'**
  String get editFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In tr, this message translates to:
  /// **'Klasörü sil'**
  String get deleteFolder;

  /// No description provided for @deleteFolderConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{name}\" klasörü silinecek. İçindeki notlar silinmez, klasörsüz kalır.'**
  String deleteFolderConfirm(String name);

  /// No description provided for @folderNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Klasör adı'**
  String get folderNameHint;

  /// No description provided for @folderIcon.
  ///
  /// In tr, this message translates to:
  /// **'Simge'**
  String get folderIcon;

  /// No description provided for @editFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri düzenle'**
  String get editFilters;

  /// No description provided for @editFiltersInfo.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda görünmesini istediğin filtreleri seç. Kapalı filtreler sayfayı sade tutar.'**
  String get editFiltersInfo;

  /// No description provided for @select.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get select;

  /// No description provided for @noteArchived.
  ///
  /// In tr, this message translates to:
  /// **'Not arşivlendi'**
  String get noteArchived;

  /// No description provided for @deleteChecked.
  ///
  /// In tr, this message translates to:
  /// **'İşaretlileri sil ({count})'**
  String deleteChecked(int count);

  /// No description provided for @removeItem.
  ///
  /// In tr, this message translates to:
  /// **'Öğeyi sil'**
  String get removeItem;

  /// No description provided for @copyWholeNote.
  ///
  /// In tr, this message translates to:
  /// **'Tüm notu kopyala'**
  String get copyWholeNote;

  /// No description provided for @allCopied.
  ///
  /// In tr, this message translates to:
  /// **'Tüm not panoya kopyalandı'**
  String get allCopied;

  /// No description provided for @speechPlay.
  ///
  /// In tr, this message translates to:
  /// **'Sesli oku'**
  String get speechPlay;

  /// No description provided for @speechPause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get speechPause;

  /// No description provided for @speechResume.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get speechResume;

  /// No description provided for @speechStop.
  ///
  /// In tr, this message translates to:
  /// **'Durdur'**
  String get speechStop;

  /// No description provided for @speechVoice.
  ///
  /// In tr, this message translates to:
  /// **'Ses tipi'**
  String get speechVoice;

  /// No description provided for @speechVoiceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sesli okumada kullanilacak ses'**
  String get speechVoiceSubtitle;

  /// No description provided for @speechRate.
  ///
  /// In tr, this message translates to:
  /// **'Okuma hizi'**
  String get speechRate;

  /// No description provided for @speechSystemDefault.
  ///
  /// In tr, this message translates to:
  /// **'Sistem varsayilani'**
  String get speechSystemDefault;

  /// No description provided for @speechNoVoices.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda yuklu ses bulunamadi'**
  String get speechNoVoices;

  /// No description provided for @aiSummarySpeak.
  ///
  /// In tr, this message translates to:
  /// **'Ozeti sesli oku'**
  String get aiSummarySpeak;

  /// No description provided for @speechVoiceTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe ses'**
  String get speechVoiceTurkish;

  /// No description provided for @speechVoiceEnglish.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce ses'**
  String get speechVoiceEnglish;

  /// No description provided for @speechVoiceAutoInfo.
  ///
  /// In tr, this message translates to:
  /// **'Diğer diller otomatik olarak erkek sesiyle okunur'**
  String get speechVoiceAutoInfo;

  /// No description provided for @nothingHeard.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma algılanmadı'**
  String get nothingHeard;

  /// No description provided for @listening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleniyor...'**
  String get listening;

  /// No description provided for @translateDownloadingModel.
  ///
  /// In tr, this message translates to:
  /// **'Dil modeli indiriliyor (bir kez)...'**
  String get translateDownloadingModel;

  /// No description provided for @translateQuality.
  ///
  /// In tr, this message translates to:
  /// **'Gemini ile çevir (daha iyi kalite)'**
  String get translateQuality;

  /// No description provided for @translateQualityInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kapalıyken çeviri cihazda yapılır: bedava, çevrimdışı ve kota harcamaz. Açıkken Gemini kullanılır — deyim ve uzun cümlede daha iyi, ama kota harcar. ML Kit\'in desteklemediği dillerde (ör. Azerbaycanca) bu ayar ne olursa olsun Gemini kullanılır.'**
  String get translateQualityInfo;

  /// No description provided for @listenPlay.
  ///
  /// In tr, this message translates to:
  /// **'Sesli dinle'**
  String get listenPlay;

  /// No description provided for @listenReadingPdf.
  ///
  /// In tr, this message translates to:
  /// **'Belge okunuyor...'**
  String get listenReadingPdf;

  /// No description provided for @listenConvertWithAi.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zekâ ile dönüştür'**
  String get listenConvertWithAi;

  /// No description provided for @listenMakePodcast.
  ///
  /// In tr, this message translates to:
  /// **'Tam podcast'**
  String get listenMakePodcast;

  /// No description provided for @listenMakePodcastSummary.
  ///
  /// In tr, this message translates to:
  /// **'Özet podcast'**
  String get listenMakePodcastSummary;

  /// No description provided for @listenOriginalText.
  ///
  /// In tr, this message translates to:
  /// **'Özgün metin'**
  String get listenOriginalText;

  /// No description provided for @listenPodcastReady.
  ///
  /// In tr, this message translates to:
  /// **'Podcast anlatımı hazır'**
  String get listenPodcastReady;

  /// No description provided for @listenPodcastCached.
  ///
  /// In tr, this message translates to:
  /// **'Daha önce üretilmişti — token harcanmadı'**
  String get listenPodcastCached;

  /// No description provided for @listenRegenerate.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden üret'**
  String get listenRegenerate;

  /// No description provided for @listenNoText.
  ///
  /// In tr, this message translates to:
  /// **'Bu belgeden okunabilir metin çıkmadı. Taranmış bir PDF ise metin katmanı yoktur, sunumsa yalnızca görsel içeriyor olabilir.'**
  String get listenNoText;

  /// No description provided for @readDocument.
  ///
  /// In tr, this message translates to:
  /// **'Belge oku (Word, PDF, sunum)'**
  String get readDocument;

  /// No description provided for @readDocUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya türü okunamıyor.'**
  String get readDocUnsupported;

  /// No description provided for @exportPdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF olarak dışa aktar'**
  String get exportPdf;

  /// No description provided for @pdfTitleField.
  ///
  /// In tr, this message translates to:
  /// **'Başlık'**
  String get pdfTitleField;

  /// No description provided for @pdfContentField.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get pdfContentField;

  /// No description provided for @pdfMarkupHint.
  ///
  /// In tr, this message translates to:
  /// **'Satır başındaki işaretler biçime dönüşür: [x] ve [ ] onay kutusu, 1. numaralı liste, - madde imi.'**
  String get pdfMarkupHint;

  /// No description provided for @pdfIncludeDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi ekle'**
  String get pdfIncludeDate;

  /// No description provided for @pdfPreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizle'**
  String get pdfPreview;

  /// No description provided for @largeAttachmentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Büyük dosya'**
  String get largeAttachmentTitle;

  /// No description provided for @largeAttachmentBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosya {size} MB. PDF\'ler sıkıştırılamıyor; olduğu gibi buluta yüklenecek ve depolama alanından düşecek. Devam edilsin mi?'**
  String largeAttachmentBody(String size);

  /// No description provided for @speechRateForeign.
  ///
  /// In tr, this message translates to:
  /// **'Yabancı dil hızı'**
  String get speechRateForeign;

  /// No description provided for @notesArchivedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} not arşivlendi'**
  String notesArchivedCount(int count);

  /// No description provided for @backgroundColor.
  ///
  /// In tr, this message translates to:
  /// **'Zemin rengi'**
  String get backgroundColor;

  /// No description provided for @backgroundColorInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notun arka plan rengi'**
  String get backgroundColorInfo;

  /// No description provided for @frameColor.
  ///
  /// In tr, this message translates to:
  /// **'Çerçeve'**
  String get frameColor;

  /// No description provided for @frameColorInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notun çevresine seçtiğin renkte bir çerçeve çizilir'**
  String get frameColorInfo;

  /// No description provided for @sortBy.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama'**
  String get sortBy;

  /// No description provided for @sortManual.
  ///
  /// In tr, this message translates to:
  /// **'Elle (sürükleme sırası)'**
  String get sortManual;

  /// No description provided for @sortUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son güncellenen'**
  String get sortUpdated;

  /// No description provided for @sortCreated.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma tarihi'**
  String get sortCreated;

  /// No description provided for @sortTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlığa göre (A-Z)'**
  String get sortTitle;

  /// No description provided for @foldersSection.
  ///
  /// In tr, this message translates to:
  /// **'Klasörler'**
  String get foldersSection;

  /// No description provided for @tagsSection.
  ///
  /// In tr, this message translates to:
  /// **'Etiketler'**
  String get tagsSection;

  /// No description provided for @expandFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri genişlet'**
  String get expandFilters;

  /// No description provided for @collapseFilters.
  ///
  /// In tr, this message translates to:
  /// **'Filtreleri daralt'**
  String get collapseFilters;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
