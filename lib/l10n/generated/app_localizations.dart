import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

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

  /// No description provided for @redo.
  ///
  /// In tr, this message translates to:
  /// **'Yinele'**
  String get redo;

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

  /// No description provided for @addAttachmentMore.
  ///
  /// In tr, this message translates to:
  /// **'Diğer ek türleri…'**
  String get addAttachmentMore;

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

  /// No description provided for @addSlide.
  ///
  /// In tr, this message translates to:
  /// **'Slayt ekle'**
  String get addSlide;

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

  /// No description provided for @noNoteSelected.
  ///
  /// In tr, this message translates to:
  /// **'Soldan bir not seç'**
  String get noNoteSelected;

  /// No description provided for @attachmentFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ek eklenemedi: {error}'**
  String attachmentFailed(String error);

  /// No description provided for @attachmentUploading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get attachmentUploading;

  /// No description provided for @attachmentUploadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yüklenemedi — yeniden denemek için dokun'**
  String get attachmentUploadFailed;

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

  /// No description provided for @storageFull.
  ///
  /// In tr, this message translates to:
  /// **'Depolama doldu ({limit}). Yer açmak için eski ekleri sil.'**
  String storageFull(String limit);

  /// No description provided for @storageUsage.
  ///
  /// In tr, this message translates to:
  /// **'Depolama'**
  String get storageUsage;

  /// No description provided for @storageUsageValue.
  ///
  /// In tr, this message translates to:
  /// **'{used} / {limit} kullanıldı'**
  String storageUsageValue(String used, String limit);

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

  /// No description provided for @summaryDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Özet türü'**
  String get summaryDetailTitle;

  /// No description provided for @summaryShort.
  ///
  /// In tr, this message translates to:
  /// **'Kısa özet'**
  String get summaryShort;

  /// No description provided for @summaryShortInfo.
  ///
  /// In tr, this message translates to:
  /// **'Birkaç cümlelik genel bakış ve ana maddeler'**
  String get summaryShortInfo;

  /// No description provided for @summaryDetailed.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı özet'**
  String get summaryDetailed;

  /// No description provided for @summaryDetailedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kaynağa bakmayı gereksiz kılan kapsamlı özet'**
  String get summaryDetailedInfo;

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

  /// No description provided for @settingsSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Ayar ara — “brifing”, “mikrofon”'**
  String get settingsSearchHint;

  /// No description provided for @settingsSearchEmpty.
  ///
  /// In tr, this message translates to:
  /// **'«{query}» için ayar yok'**
  String settingsSearchEmpty(String query);

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
  /// **'Dahili AI: Premium — bugün kalan puan {count}'**
  String aiBuiltInPremium(int count);

  /// No description provided for @aiBuiltInRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Dahili AI: bugün kalan ücretsiz puan {count}'**
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

  /// No description provided for @quickCaptureRowSetting.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı not satırı'**
  String get quickCaptureRowSetting;

  /// No description provided for @quickCaptureRowInfo.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranın üstünde tek satırlık \"Yeni not...\" alanı görünür. Kapalıyken yeni not \"+\" düğmesinden açılır.'**
  String get quickCaptureRowInfo;

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

  /// No description provided for @clear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get clear;

  /// No description provided for @aiDiagnostics.
  ///
  /// In tr, this message translates to:
  /// **'AI tanılama'**
  String get aiDiagnostics;

  /// No description provided for @aiDiagnosticsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı hata yok'**
  String get aiDiagnosticsEmpty;

  /// No description provided for @aiDiagnosticsCount.
  ///
  /// In tr, this message translates to:
  /// **'Son {count} hata kaydı'**
  String aiDiagnosticsCount(int count);

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

  /// No description provided for @signOutAnonymousWarning.
  ///
  /// In tr, this message translates to:
  /// **'Yerel hesaptasın: çıkış yaparsan bu hesaba ve TÜM notlarına bir daha ERİŞİLEMEZ — yedeğin yoksa geri getirilemezler. Notlarını korumak için önce Google hesabı bağla. Yine de çıkış yapılsın mı?'**
  String get signOutAnonymousWarning;

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

  /// No description provided for @assistantDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Asistan \"{title}\" notunu çöp kutusuna taşımak istiyor. Onaylıyor musun?'**
  String assistantDeleteConfirm(String title);

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

  /// No description provided for @speechRecognitionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma tanıma çalışmadı. Mikrofon izninin verildiğinden ve Google uygulamasının güncel olduğundan emin ol.'**
  String get speechRecognitionFailed;

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
  /// **'Not Asistanı'**
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

  /// No description provided for @fontSize.
  ///
  /// In tr, this message translates to:
  /// **'Yazı boyutu'**
  String get fontSize;

  /// No description provided for @fontSizePreview.
  ///
  /// In tr, this message translates to:
  /// **'Notların bu boyutta görünecek'**
  String get fontSizePreview;

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

  /// No description provided for @aiTranslate.
  ///
  /// In tr, this message translates to:
  /// **'Çevir'**
  String get aiTranslate;

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
  /// **'Notu düzelt'**
  String get aiFixNote;

  /// No description provided for @fixLevelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne kadar düzeltilsin?'**
  String get fixLevelTitle;

  /// No description provided for @fixSimple.
  ///
  /// In tr, this message translates to:
  /// **'Basit'**
  String get fixSimple;

  /// No description provided for @fixSimpleInfo.
  ///
  /// In tr, this message translates to:
  /// **'Yalnız imla ve yazım hataları'**
  String get fixSimpleInfo;

  /// No description provided for @fixBalanced.
  ///
  /// In tr, this message translates to:
  /// **'Dengeli'**
  String get fixBalanced;

  /// No description provided for @fixBalancedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Cümle yapısı da düzeltilir, daha düzgün yazı'**
  String get fixBalancedInfo;

  /// No description provided for @fixDetailed.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı'**
  String get fixDetailed;

  /// No description provided for @fixDetailedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Yazıyı baştan aşağı yeniden düzenler'**
  String get fixDetailedInfo;

  /// No description provided for @existingTagsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Önceki etiketler'**
  String get existingTagsLabel;

  /// No description provided for @aiSkipCheckedSetting.
  ///
  /// In tr, this message translates to:
  /// **'İşaretlileri AI düzenlemesi dışında tut'**
  String get aiSkipCheckedSetting;

  /// No description provided for @aiSkipCheckedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Checklist notunu AI ile düzeltir/çevirirken tamamlanmış (işaretli) maddeler değiştirilmeden korunur; yalnız işaretsiz maddeler düzenlenir.'**
  String get aiSkipCheckedInfo;

  /// No description provided for @noteUpdatedUndo.
  ///
  /// In tr, this message translates to:
  /// **'Not güncellendi'**
  String get noteUpdatedUndo;

  /// No description provided for @aiImprove.
  ///
  /// In tr, this message translates to:
  /// **'Notu geliştir'**
  String get aiImprove;

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

  /// No description provided for @openAsNewNote.
  ///
  /// In tr, this message translates to:
  /// **'Yeni not olarak'**
  String get openAsNewNote;

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

  /// No description provided for @reminderInPast.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen zaman geçmişte — gelecekte bir zaman seç.'**
  String get reminderInPast;

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

  /// No description provided for @voiceCaptureReady.
  ///
  /// In tr, this message translates to:
  /// **'Konuşma hazır'**
  String get voiceCaptureReady;

  /// No description provided for @voiceCaptureEditHint.
  ///
  /// In tr, this message translates to:
  /// **'Düzeltmek için metne dokun'**
  String get voiceCaptureEditHint;

  /// No description provided for @voiceCapturePunctuation.
  ///
  /// In tr, this message translates to:
  /// **'{language} · noktalama otomatik'**
  String voiceCapturePunctuation(String language);

  /// No description provided for @voiceCaptureAddToNote.
  ///
  /// In tr, this message translates to:
  /// **'Nota ekle'**
  String get voiceCaptureAddToNote;

  /// No description provided for @voiceCaptureCreateNote.
  ///
  /// In tr, this message translates to:
  /// **'Yeni not oluştur'**
  String get voiceCaptureCreateNote;

  /// No description provided for @voiceCaptureAiNote.
  ///
  /// In tr, this message translates to:
  /// **'AI not'**
  String get voiceCaptureAiNote;

  /// No description provided for @voiceCapturePlainNote.
  ///
  /// In tr, this message translates to:
  /// **'Düz not'**
  String get voiceCapturePlainNote;

  /// No description provided for @voiceCloseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konuştukların duruyor'**
  String get voiceCloseTitle;

  /// No description provided for @voiceCloseKeepTalking.
  ///
  /// In tr, this message translates to:
  /// **'Konuşmaya devam et'**
  String get voiceCloseKeepTalking;

  /// No description provided for @voiceCaptureRestart.
  ///
  /// In tr, this message translates to:
  /// **'Baştan dinle'**
  String get voiceCaptureRestart;

  /// No description provided for @voiceChipSummarizeAdd.
  ///
  /// In tr, this message translates to:
  /// **'Özetleyerek ekle'**
  String get voiceChipSummarizeAdd;

  /// No description provided for @voiceChipSummarizeSave.
  ///
  /// In tr, this message translates to:
  /// **'Özetleyerek kaydet'**
  String get voiceChipSummarizeSave;

  /// No description provided for @voiceChipToItems.
  ///
  /// In tr, this message translates to:
  /// **'Maddelere böl'**
  String get voiceChipToItems;

  /// No description provided for @voiceChipAsList.
  ///
  /// In tr, this message translates to:
  /// **'Liste notu yap'**
  String get voiceChipAsList;

  /// No description provided for @voiceChipFix.
  ///
  /// In tr, this message translates to:
  /// **'Düzelt'**
  String get voiceChipFix;

  /// No description provided for @voiceChipCompose.
  ///
  /// In tr, this message translates to:
  /// **'Asistan oluştursun'**
  String get voiceChipCompose;

  /// No description provided for @editorToolList.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get editorToolList;

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
  /// **'Sesli not ve dikte için gerekli'**
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

  /// No description provided for @showTagChips.
  ///
  /// In tr, this message translates to:
  /// **'Etiket çiplerini göster'**
  String get showTagChips;

  /// No description provided for @showFolderChips.
  ///
  /// In tr, this message translates to:
  /// **'Klasör çiplerini göster'**
  String get showFolderChips;

  /// No description provided for @videoTooBigForAi.
  ///
  /// In tr, this message translates to:
  /// **'Video AI\'ya göndermek için çok büyük ({mb} MB). Daha kısa çek.'**
  String videoTooBigForAi(int mb);

  /// No description provided for @permCamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get permCamera;

  /// No description provided for @permCameraInfo.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülü not ve fotoğraf çekimi için gerekli'**
  String get permCameraInfo;

  /// No description provided for @permOnboardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlamadan önce'**
  String get permOnboardTitle;

  /// No description provided for @permOnboardInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notlar bu izinleri yalnızca sen ilgili özelliği kullanınca ister. Şimdi vermek istersen aşağıdan açabilirsin; sonra Ayarlar > İzinler\'den de değiştirebilirsin.'**
  String get permOnboardInfo;

  /// No description provided for @permOnboardGrantAll.
  ///
  /// In tr, this message translates to:
  /// **'İzinleri ver'**
  String get permOnboardGrantAll;

  /// No description provided for @permOnboardSkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get permOnboardSkip;

  /// No description provided for @newVideoNote.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülü not'**
  String get newVideoNote;

  /// No description provided for @videoLocalOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bu video yalnızca bu cihazda saklanır (buluta yüklenmez)'**
  String get videoLocalOnly;

  /// No description provided for @videoToNote.
  ///
  /// In tr, this message translates to:
  /// **'Videodan not çıkar'**
  String get videoToNote;

  /// No description provided for @videoToNoteRunning.
  ///
  /// In tr, this message translates to:
  /// **'Video inceleniyor…'**
  String get videoToNoteRunning;

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

  /// No description provided for @newVoiceCapture.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not'**
  String get newVoiceCapture;

  /// No description provided for @suggestTitle.
  ///
  /// In tr, this message translates to:
  /// **'Başlık öner'**
  String get suggestTitle;

  /// No description provided for @noteMetaMenu.
  ///
  /// In tr, this message translates to:
  /// **'Etiket · Başlık · Alarm'**
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

  /// No description provided for @speechVoiceLanguage.
  ///
  /// In tr, this message translates to:
  /// **'{language} sesi'**
  String speechVoiceLanguage(String language);

  /// No description provided for @speechVoiceAutoInfo.
  ///
  /// In tr, this message translates to:
  /// **'Diğer diller otomatik olarak erkek sesiyle okunur'**
  String get speechVoiceAutoInfo;

  /// No description provided for @listening.
  ///
  /// In tr, this message translates to:
  /// **'Dinleniyor...'**
  String get listening;

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

  /// No description provided for @exportIncludeImages.
  ///
  /// In tr, this message translates to:
  /// **'Görselleri ekle'**
  String get exportIncludeImages;

  /// No description provided for @exportWord.
  ///
  /// In tr, this message translates to:
  /// **'Word olarak paylaş (.docx)'**
  String get exportWord;

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

  /// No description provided for @reorderNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notları sırala'**
  String get reorderNotes;

  /// No description provided for @reorderModeActive.
  ///
  /// In tr, this message translates to:
  /// **'Kartları sürükleyerek sırala'**
  String get reorderModeActive;

  /// No description provided for @reorderDone.
  ///
  /// In tr, this message translates to:
  /// **'Bitti'**
  String get reorderDone;

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

  /// No description provided for @settingsLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem dili'**
  String get languageSystem;

  /// No description provided for @settingsSpeech.
  ///
  /// In tr, this message translates to:
  /// **'Sesli okuma'**
  String get settingsSpeech;

  /// No description provided for @aiAdvanced.
  ///
  /// In tr, this message translates to:
  /// **'Gelişmiş: model ve API anahtarı'**
  String get aiAdvanced;

  /// No description provided for @aiAdvancedInfo.
  ///
  /// In tr, this message translates to:
  /// **'Model seçimi ve kendi Gemini anahtarın. Çoğu kullanıcı için gerekli değildir.'**
  String get aiAdvancedInfo;

  /// No description provided for @openBriefing.
  ///
  /// In tr, this message translates to:
  /// **'Brifingi aç'**
  String get openBriefing;

  /// No description provided for @syncTitle.
  ///
  /// In tr, this message translates to:
  /// **'Senkronizasyon'**
  String get syncTitle;

  /// No description provided for @syncLimitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik yükleme sınırı'**
  String get syncLimitTitle;

  /// No description provided for @syncLimitInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bu boyuttan büyük ekler cihazda kalır, buluta yüklenmez. Not metni her zaman senkronlanır.'**
  String get syncLimitInfo;

  /// No description provided for @syncLimitUnlimited.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız'**
  String get syncLimitUnlimited;

  /// No description provided for @backupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedek'**
  String get backupTitle;

  /// No description provided for @importBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekten geri yükle (JSON)'**
  String get importBackup;

  /// No description provided for @importBackupDone.
  ///
  /// In tr, this message translates to:
  /// **'{count} not geri yüklendi'**
  String importBackupDone(int count);

  /// No description provided for @importBackupInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz yedek dosyası'**
  String get importBackupInvalid;

  /// No description provided for @aiHubTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapay Zeka'**
  String get aiHubTitle;

  /// No description provided for @aiSummarizeInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kısa bir özet çıkarır'**
  String get aiSummarizeInfo;

  /// No description provided for @aiAnalyzeInfo.
  ///
  /// In tr, this message translates to:
  /// **'Ana noktaları ve yapılacakları listeler'**
  String get aiAnalyzeInfo;

  /// No description provided for @aiImproveInfo.
  ///
  /// In tr, this message translates to:
  /// **'Üslubu değiştirir: resmî, kısa ya da liste'**
  String get aiImproveInfo;

  /// No description provided for @aiTranslateInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notu seçtiğin dile çevirir'**
  String get aiTranslateInfo;

  /// No description provided for @aiFixNoteInfo.
  ///
  /// In tr, this message translates to:
  /// **'Yazım ve noktalamayı düzeltir'**
  String get aiFixNoteInfo;

  /// No description provided for @moveToFolder.
  ///
  /// In tr, this message translates to:
  /// **'Klasöre taşı'**
  String get moveToFolder;

  /// No description provided for @voiceAssistantBadge.
  ///
  /// In tr, this message translates to:
  /// **'Asistan'**
  String get voiceAssistantBadge;

  /// No description provided for @assistantGenericError.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorun oluştu, tekrar dener misin?'**
  String get assistantGenericError;

  /// No description provided for @quickAddTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yeni not — tip seç'**
  String get quickAddTooltip;

  /// No description provided for @autoTitleSetting.
  ///
  /// In tr, this message translates to:
  /// **'Kapatırken başlık öner'**
  String get autoTitleSetting;

  /// No description provided for @autoTitleSettingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Editörden çıkarken başlıksız kalan nota içeriğinden otomatik kısa bir başlık yazılır.'**
  String get autoTitleSettingInfo;

  /// No description provided for @hubChatInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notlarına dayanarak soru-cevap'**
  String get hubChatInfo;

  /// No description provided for @hubBriefingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Güne bakış: hatırlatıcılar ve son notlar'**
  String get hubBriefingInfo;

  /// No description provided for @hubReadInfo.
  ///
  /// In tr, this message translates to:
  /// **'PDF/Word belgesini sesli dinle'**
  String get hubReadInfo;

  /// No description provided for @annotate.
  ///
  /// In tr, this message translates to:
  /// **'Üzerine yaz'**
  String get annotate;

  /// No description provided for @annotateDone.
  ///
  /// In tr, this message translates to:
  /// **'Yazmayı bitir'**
  String get annotateDone;

  /// No description provided for @crop.
  ///
  /// In tr, this message translates to:
  /// **'Kırp'**
  String get crop;

  /// No description provided for @cropApply.
  ///
  /// In tr, this message translates to:
  /// **'Kırpmayı uygula'**
  String get cropApply;

  /// No description provided for @cropReset.
  ///
  /// In tr, this message translates to:
  /// **'Seçimi sıfırla'**
  String get cropReset;

  /// No description provided for @cropHint.
  ///
  /// In tr, this message translates to:
  /// **'Köşeleri sürükleyerek alanı seç. Kırpma geri alınamaz.'**
  String get cropHint;

  /// No description provided for @cropFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel kırpılamadı.'**
  String get cropFailed;

  /// No description provided for @penBallpoint.
  ///
  /// In tr, this message translates to:
  /// **'Tükenmez kalem'**
  String get penBallpoint;

  /// No description provided for @penMarker.
  ///
  /// In tr, this message translates to:
  /// **'Keçeli kalem'**
  String get penMarker;

  /// No description provided for @penHighlighter.
  ///
  /// In tr, this message translates to:
  /// **'Fosforlu kalem'**
  String get penHighlighter;

  /// No description provided for @eraser.
  ///
  /// In tr, this message translates to:
  /// **'Silgi'**
  String get eraser;

  /// No description provided for @clearInk.
  ///
  /// In tr, this message translates to:
  /// **'Çizimleri temizle'**
  String get clearInk;

  /// No description provided for @inkTwoFingerHint.
  ///
  /// In tr, this message translates to:
  /// **'Tek parmak çizer · iki parmakla kaydır ve yakınlaştır'**
  String get inkTwoFingerHint;

  /// No description provided for @slideOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sunum açılamadı'**
  String get slideOpenFailed;

  /// No description provided for @newPhotoNote.
  ///
  /// In tr, this message translates to:
  /// **'Foto çek not al'**
  String get newPhotoNote;

  /// No description provided for @newScanNote.
  ///
  /// In tr, this message translates to:
  /// **'Belge tara not al'**
  String get newScanNote;

  /// No description provided for @scanDocument.
  ///
  /// In tr, this message translates to:
  /// **'Belge tara'**
  String get scanDocument;

  /// No description provided for @scanDocumentSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kenarları bulur, düzleştirir ve nota ekler'**
  String get scanDocumentSubtitle;

  /// No description provided for @scanUnsupported.
  ///
  /// In tr, this message translates to:
  /// **'Belge tarama bu cihazda desteklenmiyor'**
  String get scanUnsupported;

  /// No description provided for @scanFailed.
  ///
  /// In tr, this message translates to:
  /// **'Belge taranamadı: {error}'**
  String scanFailed(String error);

  /// No description provided for @scanPagesAdded.
  ///
  /// In tr, this message translates to:
  /// **'{count} sayfa nota eklendi'**
  String scanPagesAdded(int count);

  /// No description provided for @scanTextTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yazılar da tanınsın mı?'**
  String get scanTextTitle;

  /// No description provided for @scanTextBody.
  ///
  /// In tr, this message translates to:
  /// **'Sayfalardaki yazı tanınıp notun içine yazılır. Görüntü aynen kalır. Sayfa başına birkaç saniye sürer.'**
  String get scanTextBody;

  /// No description provided for @scanImageOnly.
  ///
  /// In tr, this message translates to:
  /// **'Sadece görüntü'**
  String get scanImageOnly;

  /// No description provided for @scanRecognizeText.
  ///
  /// In tr, this message translates to:
  /// **'Yazıları da tanı'**
  String get scanRecognizeText;

  /// No description provided for @scanRecognizing.
  ///
  /// In tr, this message translates to:
  /// **'Yazılar tanınıyor…'**
  String get scanRecognizing;

  /// No description provided for @takePhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf çek'**
  String get takePhoto;

  /// No description provided for @qrScanTitle.
  ///
  /// In tr, this message translates to:
  /// **'QR kod tara'**
  String get qrScanTitle;

  /// No description provided for @qrScanSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kameradan ya da fotoğraftan oku'**
  String get qrScanSubtitle;

  /// No description provided for @qrScanHint.
  ///
  /// In tr, this message translates to:
  /// **'Kodu çerçevenin içine getir'**
  String get qrScanHint;

  /// No description provided for @qrFromPhoto.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraftan oku'**
  String get qrFromPhoto;

  /// No description provided for @qrNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu görselde kod bulunamadı'**
  String get qrNotFound;

  /// No description provided for @qrLinkFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu kod bir bağlantı'**
  String get qrLinkFound;

  /// No description provided for @qrOpenLink.
  ///
  /// In tr, this message translates to:
  /// **'Linke git'**
  String get qrOpenLink;

  /// No description provided for @qrSaveToNote.
  ///
  /// In tr, this message translates to:
  /// **'Nota kaydet'**
  String get qrSaveToNote;

  /// No description provided for @openLink.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı aç'**
  String get openLink;

  /// No description provided for @linkOpenFailed.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı açılamadı'**
  String get linkOpenFailed;

  /// No description provided for @qrScanFailed.
  ///
  /// In tr, this message translates to:
  /// **'Kod okunamadı: {error}'**
  String qrScanFailed(String error);

  /// No description provided for @qrTorch.
  ///
  /// In tr, this message translates to:
  /// **'Işık'**
  String get qrTorch;

  /// No description provided for @attachmentsCount.
  ///
  /// In tr, this message translates to:
  /// **'Ekler ({count})'**
  String attachmentsCount(int count);

  /// No description provided for @hideAttachments.
  ///
  /// In tr, this message translates to:
  /// **'Gizle'**
  String get hideAttachments;

  /// No description provided for @showAttachments.
  ///
  /// In tr, this message translates to:
  /// **'Göster'**
  String get showAttachments;

  /// No description provided for @videoBack10.
  ///
  /// In tr, this message translates to:
  /// **'10 sn geri'**
  String get videoBack10;

  /// No description provided for @videoForward10.
  ///
  /// In tr, this message translates to:
  /// **'10 sn ileri'**
  String get videoForward10;

  /// No description provided for @selectAllItems.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü seç'**
  String get selectAllItems;

  /// No description provided for @showAllChips.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü göster'**
  String get showAllChips;

  /// No description provided for @hideAllChips.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü gizle'**
  String get hideAllChips;

  /// No description provided for @chipPickInfo.
  ///
  /// In tr, this message translates to:
  /// **'Hangi klasör ve etiketlerin çipi ana ekranda görünsün?'**
  String get chipPickInfo;

  /// No description provided for @hiddenFolder.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasör'**
  String get hiddenFolder;

  /// No description provided for @hiddenFolderInfo.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasör ve içindeki notlar ana ekranda görünmez. Göstermek için ⋮ menüsünden \"Gizli klasörler\" seçilir ve kimlik doğrulanır.'**
  String get hiddenFolderInfo;

  /// No description provided for @hiddenFoldersMenu.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasörler'**
  String get hiddenFoldersMenu;

  /// No description provided for @hiddenFolderAuthReason.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasörleri göstermek için kimliğini doğrula'**
  String get hiddenFolderAuthReason;

  /// No description provided for @hiddenFoldersShown.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasörler gösteriliyor'**
  String get hiddenFoldersShown;

  /// No description provided for @hiddenFoldersHiddenAgain.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasörler yeniden saklandı'**
  String get hiddenFoldersHiddenAgain;

  /// No description provided for @makeFolderHidden.
  ///
  /// In tr, this message translates to:
  /// **'Gizle'**
  String get makeFolderHidden;

  /// No description provided for @makeFolderVisible.
  ///
  /// In tr, this message translates to:
  /// **'Gizlemeyi kaldır'**
  String get makeFolderVisible;

  /// No description provided for @gridColumnsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} sütun'**
  String gridColumnsCount(int count);

  /// No description provided for @addImageOnPageSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayfaya yerleşir, yazı etrafından akar'**
  String get addImageOnPageSubtitle;

  /// No description provided for @addImageAsFile.
  ///
  /// In tr, this message translates to:
  /// **'Görseli ek olarak yükle'**
  String get addImageAsFile;

  /// No description provided for @addImageAsFileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayfaya girmez, alttaki ek şeridinde durur'**
  String get addImageAsFileSubtitle;

  /// No description provided for @moveImageToAttachments.
  ///
  /// In tr, this message translates to:
  /// **'Ek olarak taşı'**
  String get moveImageToAttachments;

  /// No description provided for @moveImageToPage.
  ///
  /// In tr, this message translates to:
  /// **'Sayfaya koy'**
  String get moveImageToPage;

  /// No description provided for @attachmentCopied.
  ///
  /// In tr, this message translates to:
  /// **'Ek kopyalandı'**
  String get attachmentCopied;

  /// No description provided for @pasteAttachment.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalanan eki yapıştır'**
  String get pasteAttachment;

  /// No description provided for @fullscreen.
  ///
  /// In tr, this message translates to:
  /// **'Tam ekran'**
  String get fullscreen;

  /// No description provided for @more.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get more;

  /// No description provided for @undone.
  ///
  /// In tr, this message translates to:
  /// **'Geri alındı'**
  String get undone;

  /// No description provided for @filterOthers.
  ///
  /// In tr, this message translates to:
  /// **'Diğerleri'**
  String get filterOthers;

  /// No description provided for @chatSuggestion1.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş listemde ne eksik?'**
  String get chatSuggestion1;

  /// No description provided for @chatSuggestion2.
  ///
  /// In tr, this message translates to:
  /// **'Bu haftaki iş notlarımı özetle'**
  String get chatSuggestion2;

  /// No description provided for @chatSuggestion3.
  ///
  /// In tr, this message translates to:
  /// **'Yarın için hatırlatıcım var mı?'**
  String get chatSuggestion3;

  /// No description provided for @aiPointsToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü puan'**
  String get aiPointsToday;

  /// No description provided for @aiPointsOf.
  ///
  /// In tr, this message translates to:
  /// **'{used} / {total}'**
  String aiPointsOf(int used, int total);

  /// No description provided for @aiPointsRenew.
  ///
  /// In tr, this message translates to:
  /// **'gece yarısı yenilenir'**
  String get aiPointsRenew;

  /// No description provided for @aiChatWithNotes.
  ///
  /// In tr, this message translates to:
  /// **'Not Asistanı'**
  String get aiChatWithNotes;

  /// No description provided for @aiChatInputHint.
  ///
  /// In tr, this message translates to:
  /// **'Notlarına bir şey sor…'**
  String get aiChatInputHint;

  /// No description provided for @aiChatLooking.
  ///
  /// In tr, this message translates to:
  /// **'notlarına bakıyor…'**
  String get aiChatLooking;

  /// No description provided for @aiChatFullScreen.
  ///
  /// In tr, this message translates to:
  /// **'Tam ekran'**
  String get aiChatFullScreen;

  /// No description provided for @aiOnYourNotes.
  ///
  /// In tr, this message translates to:
  /// **'NOTLARIN ÜZERİNDE'**
  String get aiOnYourNotes;

  /// No description provided for @aiTaskDuplicates.
  ///
  /// In tr, this message translates to:
  /// **'Kopyaları temizle'**
  String get aiTaskDuplicates;

  /// No description provided for @aiTaskDuplicatesInfo.
  ///
  /// In tr, this message translates to:
  /// **'{count} kopya not var'**
  String aiTaskDuplicatesInfo(int count);

  /// No description provided for @duplicatesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kopya notlar'**
  String get duplicatesTitle;

  /// No description provided for @duplicatesHint.
  ///
  /// In tr, this message translates to:
  /// **'Her kümede en eski not korunur, kalanlar çöp kutusuna taşınır.'**
  String get duplicatesHint;

  /// No description provided for @duplicatesKeepBadge.
  ///
  /// In tr, this message translates to:
  /// **'korunur'**
  String get duplicatesKeepBadge;

  /// No description provided for @duplicatesDeleteAll.
  ///
  /// In tr, this message translates to:
  /// **'Kopyaları çöpe taşı'**
  String get duplicatesDeleteAll;

  /// No description provided for @duplicatesDone.
  ///
  /// In tr, this message translates to:
  /// **'{count} kopya çöp kutusuna taşındı'**
  String duplicatesDone(int count);

  /// No description provided for @aiRecentActions.
  ///
  /// In tr, this message translates to:
  /// **'SON İŞLEMLER'**
  String get aiRecentActions;

  /// No description provided for @aiHistoryClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get aiHistoryClear;

  /// No description provided for @aiHistoryQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Soru'**
  String get aiHistoryQuestion;

  /// No description provided for @aiHistoryNoteAction.
  ///
  /// In tr, this message translates to:
  /// **'Not işlemi'**
  String get aiHistoryNoteAction;

  /// No description provided for @aiHistoryVoiceNote.
  ///
  /// In tr, this message translates to:
  /// **'Sesli not'**
  String get aiHistoryVoiceNote;

  /// No description provided for @aiRecentOps.
  ///
  /// In tr, this message translates to:
  /// **'SON İŞLEMLER'**
  String get aiRecentOps;

  /// No description provided for @aiTaskWeekSummary.
  ///
  /// In tr, this message translates to:
  /// **'Haftayı özetle'**
  String get aiTaskWeekSummary;

  /// No description provided for @aiTaskWeekSummaryInfo.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günün notlarından tek özet'**
  String get aiTaskWeekSummaryInfo;

  /// No description provided for @aiTaskTagUntagged.
  ///
  /// In tr, this message translates to:
  /// **'Etiketsizleri etiketle'**
  String get aiTaskTagUntagged;

  /// No description provided for @aiTaskTagUntaggedInfo.
  ///
  /// In tr, this message translates to:
  /// **'{count} not etiket bekliyor'**
  String aiTaskTagUntaggedInfo(int count);

  /// No description provided for @aiTaskSuggestTitles.
  ///
  /// In tr, this message translates to:
  /// **'Başlık öner'**
  String get aiTaskSuggestTitles;

  /// No description provided for @aiTaskSuggestTitlesInfo.
  ///
  /// In tr, this message translates to:
  /// **'{count} başlıksız not var'**
  String aiTaskSuggestTitlesInfo(int count);

  /// No description provided for @sectionPinnedShort.
  ///
  /// In tr, this message translates to:
  /// **'SABİT'**
  String get sectionPinnedShort;

  /// No description provided for @sectionToday.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN'**
  String get sectionToday;

  /// No description provided for @sectionThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'BU HAFTA'**
  String get sectionThisWeek;

  /// No description provided for @sectionEarlier.
  ///
  /// In tr, this message translates to:
  /// **'DAHA ÖNCE'**
  String get sectionEarlier;

  /// No description provided for @sectionNoteCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} not'**
  String sectionNoteCount(int count);

  /// No description provided for @emptySearchSemanticHint.
  ///
  /// In tr, this message translates to:
  /// **'Anlam sekmesini dene'**
  String get emptySearchSemanticHint;

  /// No description provided for @quickCaptureHint.
  ///
  /// In tr, this message translates to:
  /// **'Yeni not…'**
  String get quickCaptureHint;

  /// No description provided for @quickCaptureSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get quickCaptureSave;

  /// No description provided for @quickAddWrite.
  ///
  /// In tr, this message translates to:
  /// **'YAZ'**
  String get quickAddWrite;

  /// No description provided for @quickAddCapture.
  ///
  /// In tr, this message translates to:
  /// **'YAKALA — İÇERİKTEN NOT OLUŞTURUR'**
  String get quickAddCapture;

  /// No description provided for @viewToggle.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get viewToggle;

  /// No description provided for @searchModeText.
  ///
  /// In tr, this message translates to:
  /// **'Metin'**
  String get searchModeText;

  /// No description provided for @searchModeMeaning.
  ///
  /// In tr, this message translates to:
  /// **'Anlam'**
  String get searchModeMeaning;

  /// No description provided for @filterReminded.
  ///
  /// In tr, this message translates to:
  /// **'Alarmlı'**
  String get filterReminded;

  /// No description provided for @filterLocked.
  ///
  /// In tr, this message translates to:
  /// **'Kilitli'**
  String get filterLocked;

  /// No description provided for @sortColor.
  ///
  /// In tr, this message translates to:
  /// **'Renk'**
  String get sortColor;

  /// No description provided for @filterSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Süz'**
  String get filterSheetTitle;

  /// No description provided for @filterReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get filterReset;

  /// No description provided for @filterSectionStatus.
  ///
  /// In tr, this message translates to:
  /// **'DURUM'**
  String get filterSectionStatus;

  /// No description provided for @filterSectionFolder.
  ///
  /// In tr, this message translates to:
  /// **'KLASÖR'**
  String get filterSectionFolder;

  /// No description provided for @filterSectionTag.
  ///
  /// In tr, this message translates to:
  /// **'ETİKET'**
  String get filterSectionTag;

  /// No description provided for @filterSectionSort.
  ///
  /// In tr, this message translates to:
  /// **'SIRALAMA'**
  String get filterSectionSort;

  /// No description provided for @filterFavoriteHint.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda kısayol olarak görünmesi için bir seçeneğin yıldızına dokun'**
  String get filterFavoriteHint;

  /// No description provided for @filterSheetSortHint.
  ///
  /// In tr, this message translates to:
  /// **'Tarih grupları (BUGÜN, BU HAFTA…) yalnız “Son düzenlenen” sıralamasında gösterilir.'**
  String get filterSheetSortHint;

  /// No description provided for @formatTitle.
  ///
  /// In tr, this message translates to:
  /// **'Biçim'**
  String get formatTitle;

  /// No description provided for @formatBold.
  ///
  /// In tr, this message translates to:
  /// **'Kalın'**
  String get formatBold;

  /// No description provided for @formatItalic.
  ///
  /// In tr, this message translates to:
  /// **'İtalik'**
  String get formatItalic;

  /// No description provided for @formatUnderline.
  ///
  /// In tr, this message translates to:
  /// **'Altı çizili'**
  String get formatUnderline;

  /// No description provided for @formatTextColor.
  ///
  /// In tr, this message translates to:
  /// **'Yazı rengi'**
  String get formatTextColor;

  /// No description provided for @formatHighlight.
  ///
  /// In tr, this message translates to:
  /// **'Renkli vurgu'**
  String get formatHighlight;

  /// No description provided for @formatInfo.
  ///
  /// In tr, this message translates to:
  /// **'Biçim, metnin içinde işaretle taşınır (**kalın** gibi); dışa aktarmada ve okumada işaretler görünmez.'**
  String get formatInfo;

  /// No description provided for @formatMenu.
  ///
  /// In tr, this message translates to:
  /// **'Biçim…'**
  String get formatMenu;

  /// No description provided for @noteFont.
  ///
  /// In tr, this message translates to:
  /// **'Yazı tipi'**
  String get noteFont;

  /// No description provided for @noteFontDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get noteFontDefault;

  /// No description provided for @noteFontSerif.
  ///
  /// In tr, this message translates to:
  /// **'Kitap (serif)'**
  String get noteFontSerif;

  /// No description provided for @noteFontMono.
  ///
  /// In tr, this message translates to:
  /// **'Daktilo'**
  String get noteFontMono;

  /// No description provided for @noteTextSize.
  ///
  /// In tr, this message translates to:
  /// **'Yazı boyutu'**
  String get noteTextSize;

  /// No description provided for @formatClear.
  ///
  /// In tr, this message translates to:
  /// **'Biçimi temizle'**
  String get formatClear;

  /// No description provided for @noteTextOpacity.
  ///
  /// In tr, this message translates to:
  /// **'Şeffaflık'**
  String get noteTextOpacity;

  /// No description provided for @assistantVoiceSetting.
  ///
  /// In tr, this message translates to:
  /// **'Asistan sesli yanıtlasın'**
  String get assistantVoiceSetting;

  /// No description provided for @assistantVoiceSettingInfo.
  ///
  /// In tr, this message translates to:
  /// **'Sesli asistan yanıtını yüksek sesle okur (yalnız telefonda).'**
  String get assistantVoiceSettingInfo;

  /// No description provided for @assistantMute.
  ///
  /// In tr, this message translates to:
  /// **'Sesi kapat'**
  String get assistantMute;

  /// No description provided for @assistantUnmute.
  ///
  /// In tr, this message translates to:
  /// **'Sesi aç'**
  String get assistantUnmute;

  /// No description provided for @assistantMakeNote.
  ///
  /// In tr, this message translates to:
  /// **'Yine de nota dönüştür'**
  String get assistantMakeNote;

  /// No description provided for @assistantNoteCreated.
  ///
  /// In tr, this message translates to:
  /// **'Not oluşturuldu'**
  String get assistantNoteCreated;

  /// No description provided for @noteNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Not bulunamadı. Silinmiş olabilir.'**
  String get noteNotFound;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get back;

  /// No description provided for @addTextBlock.
  ///
  /// In tr, this message translates to:
  /// **'Metin ekle'**
  String get addTextBlock;

  /// No description provided for @attachNoteContent.
  ///
  /// In tr, this message translates to:
  /// **'Not içeriği'**
  String get attachNoteContent;

  /// No description provided for @noteBackgroundImage.
  ///
  /// In tr, this message translates to:
  /// **'Zemin görseli'**
  String get noteBackgroundImage;

  /// No description provided for @chooseBackgroundImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel seç'**
  String get chooseBackgroundImage;

  /// No description provided for @changeBackgroundImage.
  ///
  /// In tr, this message translates to:
  /// **'Görseli değiştir'**
  String get changeBackgroundImage;

  /// No description provided for @removeBackgroundImage.
  ///
  /// In tr, this message translates to:
  /// **'Zemini kaldır'**
  String get removeBackgroundImage;

  /// No description provided for @dashboardBackground.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekran zemini'**
  String get dashboardBackground;

  /// No description provided for @dashboardBackgroundInfo.
  ///
  /// In tr, this message translates to:
  /// **'Not ızgarasının arkasında duran görsel (yalnız bu cihazda).'**
  String get dashboardBackgroundInfo;

  /// No description provided for @aiProvider.
  ///
  /// In tr, this message translates to:
  /// **'Yapay zeka sağlayıcısı'**
  String get aiProvider;

  /// No description provided for @aiProviderInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kendi anahtarınla çalışan sağlayıcıyı seç. Her sağlayıcının anahtarı ayrı saklanır; aralarında geçiş yapınca yeniden girmen gerekmez.'**
  String get aiProviderInfo;

  /// No description provided for @apiKeyFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'API anahtarı'**
  String get apiKeyFieldLabel;

  /// No description provided for @getApiKey.
  ///
  /// In tr, this message translates to:
  /// **'Anahtarı nereden alırım?'**
  String get getApiKey;

  /// No description provided for @recommendedModel.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen'**
  String get recommendedModel;

  /// No description provided for @freeTierBadge.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz kademe var'**
  String get freeTierBadge;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesapsız devam et'**
  String get continueWithoutAccount;

  /// No description provided for @localAccountInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notların yalnız bu cihazda kalır: başka cihazdan açılamaz, uygulamayı silersen geri getirilemez ve dahili yapay zeka kapalı olur. İstediğin an Google hesabı bağlayabilirsin — notların olduğu gibi kalır.'**
  String get localAccountInfo;

  /// No description provided for @localAccountBadge.
  ///
  /// In tr, this message translates to:
  /// **'Yerel hesap'**
  String get localAccountBadge;

  /// No description provided for @linkGoogleAccount.
  ///
  /// In tr, this message translates to:
  /// **'Google hesabı bağla'**
  String get linkGoogleAccount;

  /// No description provided for @accountLinked.
  ///
  /// In tr, this message translates to:
  /// **'Google hesabın bağlandı. Notların artık yedekleniyor.'**
  String get accountLinked;

  /// No description provided for @scanReviewPage.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa {current} / {total}'**
  String scanReviewPage(int current, int total);

  /// No description provided for @scanRotatePage.
  ///
  /// In tr, this message translates to:
  /// **'Sayfayı döndür'**
  String get scanRotatePage;

  /// No description provided for @scanDeletePage.
  ///
  /// In tr, this message translates to:
  /// **'Sayfayı sil'**
  String get scanDeletePage;

  /// No description provided for @scanLastPage.
  ///
  /// In tr, this message translates to:
  /// **'Son sayfa silinemez'**
  String get scanLastPage;

  /// No description provided for @scanDiscardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Taranan sayfalar atılsın mı?'**
  String get scanDiscardTitle;

  /// No description provided for @scanDiscardConfirm.
  ///
  /// In tr, this message translates to:
  /// **'At'**
  String get scanDiscardConfirm;

  /// No description provided for @scanAdjustCorners.
  ///
  /// In tr, this message translates to:
  /// **'Köşeleri ayarla'**
  String get scanAdjustCorners;

  /// No description provided for @scanFilterOriginal.
  ///
  /// In tr, this message translates to:
  /// **'Özgün'**
  String get scanFilterOriginal;

  /// No description provided for @scanFilterAuto.
  ///
  /// In tr, this message translates to:
  /// **'Netleştir'**
  String get scanFilterAuto;

  /// No description provided for @scanFilterGray.
  ///
  /// In tr, this message translates to:
  /// **'Gri'**
  String get scanFilterGray;

  /// No description provided for @scanFilterBw.
  ///
  /// In tr, this message translates to:
  /// **'Siyah-beyaz'**
  String get scanFilterBw;

  /// No description provided for @scanApplyAll.
  ///
  /// In tr, this message translates to:
  /// **'Hepsine uygula'**
  String get scanApplyAll;

  /// No description provided for @scanPageFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa görüntülenemedi'**
  String get scanPageFailed;

  /// No description provided for @scanCropHint.
  ///
  /// In tr, this message translates to:
  /// **'Yamuk sayfayı \"Köşeleri ayarla\" ile düzeltebilirsin'**
  String get scanCropHint;

  /// No description provided for @scanAddAsPdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF olarak ekle'**
  String get scanAddAsPdf;

  /// No description provided for @scanAddAsImages.
  ///
  /// In tr, this message translates to:
  /// **'Görsel olarak ekle'**
  String get scanAddAsImages;

  /// No description provided for @scanBuildingPdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF hazırlanıyor…'**
  String get scanBuildingPdf;

  /// No description provided for @scanOcrProgress.
  ///
  /// In tr, this message translates to:
  /// **'Metin tanınıyor… {done}/{total}'**
  String scanOcrProgress(int done, int total);

  /// No description provided for @scanAutoDetect.
  ///
  /// In tr, this message translates to:
  /// **'Kenarları otomatik bul'**
  String get scanAutoDetect;

  /// No description provided for @scanReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get scanReset;

  /// No description provided for @scanDetecting.
  ///
  /// In tr, this message translates to:
  /// **'Kenarlar aranıyor…'**
  String get scanDetecting;

  /// No description provided for @scanAutoFound.
  ///
  /// In tr, this message translates to:
  /// **'Kenarlar otomatik bulundu; gerekirse tutamaçlardan ince ayar yap'**
  String get scanAutoFound;

  /// No description provided for @scanDragHint.
  ///
  /// In tr, this message translates to:
  /// **'Köşeleri kâğıdın kenarlarına sürükle'**
  String get scanDragHint;

  /// No description provided for @scanApplyCorners.
  ///
  /// In tr, this message translates to:
  /// **'Düzelt ve uygula'**
  String get scanApplyCorners;

  /// No description provided for @scanWorking.
  ///
  /// In tr, this message translates to:
  /// **'Düzeltiliyor…'**
  String get scanWorking;

  /// No description provided for @scanPdfAdded.
  ///
  /// In tr, this message translates to:
  /// **'Tarama, PDF eki olarak nota eklendi'**
  String get scanPdfAdded;

  /// No description provided for @premiumTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium'**
  String get premiumTitle;

  /// No description provided for @premiumStatusActive.
  ///
  /// In tr, this message translates to:
  /// **'Premium etkin — {date} tarihine kadar'**
  String premiumStatusActive(String date);

  /// No description provided for @premiumStatusFree.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz sürümü kullanıyorsun'**
  String get premiumStatusFree;

  /// No description provided for @premiumPerksTitle.
  ///
  /// In tr, this message translates to:
  /// **'Premium ile ne değişir?'**
  String get premiumPerksTitle;

  /// No description provided for @premiumPerkAi.
  ///
  /// In tr, this message translates to:
  /// **'Günlük yapay zeka puanı'**
  String get premiumPerkAi;

  /// No description provided for @premiumPerkAttach.
  ///
  /// In tr, this message translates to:
  /// **'Ek dosya boyutu'**
  String get premiumPerkAttach;

  /// No description provided for @premiumPerkStorage.
  ///
  /// In tr, this message translates to:
  /// **'Bulut depolama alanı'**
  String get premiumPerkStorage;

  /// No description provided for @premiumPerkAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik günlük içerik'**
  String get premiumPerkAuto;

  /// No description provided for @premiumPerkAutoBody.
  ///
  /// In tr, this message translates to:
  /// **'Günlük brifing ve öneriler her gün kendiliğinden hazırlanır; ücretsizde yalnız düğmeyle üretilir.'**
  String get premiumPerkAutoBody;

  /// No description provided for @premiumHowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl edinilir?'**
  String get premiumHowTitle;

  /// No description provided for @premiumHowBody.
  ///
  /// In tr, this message translates to:
  /// **'Premium yakında Play Store üzerinden satın alınabilecek. Şu an erken erişim dönemindeyiz.'**
  String get premiumHowBody;

  /// No description provided for @premiumByokHint.
  ///
  /// In tr, this message translates to:
  /// **'Kendi Gemini API anahtarını girersen yapay zeka özellikleri kotasız çalışır — Premium\'dan bağımsız (Ayarlar → Yapay Zeka).'**
  String get premiumByokHint;

  /// No description provided for @premiumDiscoverTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gözden kaçan özellikler'**
  String get premiumDiscoverTitle;

  /// No description provided for @discoverScanBody.
  ///
  /// In tr, this message translates to:
  /// **'Kamerayla taranan sayfalar kenar bulma ve netleştirmeyle düzelir, tek dokunuşla ARANABİLİR PDF olur — metin katmanı cihazda, ücretsiz üretilir.'**
  String get discoverScanBody;

  /// No description provided for @discoverSemanticBody.
  ///
  /// In tr, this message translates to:
  /// **'Arama kutusundaki \"Akıllı\" sekmesi kelime değil ANLAM arar: \"uçak saatleri\" yazınca seyahat notun çıkar.'**
  String get discoverSemanticBody;

  /// No description provided for @discoverAssistantBody.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrandaki mikrofon konuşmanı nota, listeye ve hatırlatıcıya kendisi çevirir — \"yarın 9\'da diş randevusu\" demen yeter.'**
  String get discoverAssistantBody;

  /// No description provided for @discoverLockBody.
  ///
  /// In tr, this message translates to:
  /// **'Bir notu parmak izi/yüz kilidiyle kilitleyebilirsin: içeriği aramaya, widget\'a ve AI\'a hiç sızmaz.'**
  String get discoverLockBody;

  /// No description provided for @discoverHiddenBody.
  ///
  /// In tr, this message translates to:
  /// **'Gizli klasördeki notlar ana ekranda ve aramada hiç görünmez; klasörü göstermek kimlik doğrulaması ister.'**
  String get discoverHiddenBody;

  /// No description provided for @discoverExportBody.
  ///
  /// In tr, this message translates to:
  /// **'Her not görselleriyle birlikte PDF ya da Word olarak dışa aktarılabilir (paylaş menüsünde).'**
  String get discoverExportBody;

  /// No description provided for @guestSignInUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Hesapsız giriş şu an kapalı: Firebase konsolunda Authentication → Sign-in method → Anonymous açık değil. Google ile giriş yapabilir ya da yönetici bu yöntemi açtıktan sonra yeniden deneyebilirsin.'**
  String get guestSignInUnavailable;

  /// No description provided for @googleSignInUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Google ile giriş şu an kapalı: Firebase konsolunda Google oturum açma yöntemi etkin değil.'**
  String get googleSignInUnavailable;

  /// No description provided for @signInNetworkError.
  ///
  /// In tr, this message translates to:
  /// **'İnternete ulaşılamadı. Bağlantını kontrol edip yeniden dene.'**
  String get signInNetworkError;

  /// No description provided for @signInCanceled.
  ///
  /// In tr, this message translates to:
  /// **'Giriş iptal edildi.'**
  String get signInCanceled;

  /// No description provided for @cardRichPreview.
  ///
  /// In tr, this message translates to:
  /// **'Kartlarda biçimli metin'**
  String get cardRichPreview;

  /// No description provided for @cardRichPreviewInfo.
  ///
  /// In tr, this message translates to:
  /// **'Notların rengi, vurgusu, kalın ve altı çizili yazıları ana ekrandaki kartlarda da görünür. Kapalıyken kartlar düz metin gösterir.'**
  String get cardRichPreviewInfo;

  /// No description provided for @fontSizeSmall.
  ///
  /// In tr, this message translates to:
  /// **'Küçük'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get fontSizeMedium;

  /// No description provided for @fontSizeLarge.
  ///
  /// In tr, this message translates to:
  /// **'Büyük'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeXLarge.
  ///
  /// In tr, this message translates to:
  /// **'Çok büyük'**
  String get fontSizeXLarge;

  /// No description provided for @appFontSetting.
  ///
  /// In tr, this message translates to:
  /// **'Yazı tipi'**
  String get appFontSetting;

  /// No description provided for @appFontInfo.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın her yerinde kullanılan yazı tipi. Notun kendi yazı tipi seçimi bunun üstüne biner. Tüm yazı tipleri uygulamayla birlikte geliyor — internet gerekmez.'**
  String get appFontInfo;

  /// No description provided for @fontGroupSans.
  ///
  /// In tr, this message translates to:
  /// **'Sade'**
  String get fontGroupSans;

  /// No description provided for @fontGroupSerif.
  ///
  /// In tr, this message translates to:
  /// **'Kitap'**
  String get fontGroupSerif;

  /// No description provided for @fontGroupMono.
  ///
  /// In tr, this message translates to:
  /// **'Daktilo'**
  String get fontGroupMono;

  /// No description provided for @fontGroupHand.
  ///
  /// In tr, this message translates to:
  /// **'El yazısı'**
  String get fontGroupHand;

  /// No description provided for @appFontDefaultSuffix.
  ///
  /// In tr, this message translates to:
  /// **'varsayılan'**
  String get appFontDefaultSuffix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
