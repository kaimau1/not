import 'dart:math' as math;

import '../../../app/app_frame.dart';
import '../../../core/app_icons.dart';
import '../../../core/ecosystem_apps.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart'
    show AuthCredential, FirebaseAuth, FirebaseAuthException;
import 'package:flutter/foundation.dart'
    show kIsWeb, listEquals, ValueListenable, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show
        BoxHitTestResult,
        ContainerBoxParentData,
        ContainerRenderObjectMixin,
        RenderBoxContainerDefaultsMixin;

import '../../../core/widgets/sheet_header.dart';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/search_fold.dart';
import '../../../app/theme/note_colors.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/attachment_text_index.dart';
import '../../../core/crash_reporting.dart';
import '../../../core/error_log.dart';
import '../../../core/feedback_mail.dart';
import '../../../core/constants.dart';
import '../../../app/theme/app_design.dart';
import '../../../app/theme/app_palette.dart' show ThemeFamily;
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/horizontal_wheel_strip.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/play_build.dart';
import '../../../core/tips.dart';
import 'appearance_studio_sheet.dart';
import 'personalize_screen.dart' show PersonalizeModuleSwitches;
import 'theme_picker.dart';
import 'typing_bar_settings.dart';
import '../../../core/utils/channel_counter.dart';
import '../../../core/utils/frame_timing_log.dart';
import '../../../core/utils/diagnostics.dart';
import '../../../core/utils/display_rate.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/widgets/expand_reveal.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/language_names.dart';
import '../../../core/utils/font_downloads.dart';
import '../../../core/utils/note_fonts.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/utils/speech_output.dart';
import '../../ai/data/ai_policy.dart';
import '../../ai/presentation/ai_consent_sheet.dart';
import '../../ai/data/ai_provider.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/decisions/decision_service.dart';
import '../../ai/data/speech_service.dart';
import '../../auth/data/account_service.dart';
import '../../auth/presentation/account_identity_card.dart';
import '../../auth/presentation/auth_errors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/sign_out_actions.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../entitlement/presentation/pro_lock.dart';
import '../../entitlement/presentation/pro_screen.dart'
    show formatDecisionTokens;
import '../../friends/data/friends_repository.dart';
import '../../inbox/data/inbox_repository.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../notes/presentation/lock/note_lock_ui.dart';
import '../../notes/presentation/note_card_media.dart' show CardThumbs;
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/notes_providers.dart'
    show
        noteSortProvider,
        swipeModeProvider,
        homeFolderStripHiddenProvider,
        showAllNotesProvider,
        allNotesGroupByFolderProvider,
        attachmentsExpandedProvider;
import '../../notes/presentation/filter_sheet.dart' show sortLabel;
import '../../notes/presentation/note_card.dart' show NoteCard;
import '../../notes/domain/note_item.dart';
import '../../notes/data/drive_store.dart';
import '../../notes/presentation/drive_ui.dart';
import '../data/permissions_service.dart';
import '../settings_providers.dart';
import 'notes_settings.dart';
import 'backup_ui.dart';

import 'package:intl/intl.dart' show DateFormat;

import '../../../core/app_update.dart'
    show AppUpdate, AppUpdateInfo, autoUpdateProvider;
import 'app_lock.dart';
import '../../notes/data/backup_service.dart';
import '../../notes/data/attachment_repository.dart';
import '../../folders/data/folders_repository.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/delayed_spinner.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/widgets/pop_in.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/friendly_error.dart';
import '../../auth/presentation/account_required.dart';
import '../../../core/a11y/chip_roles.dart';
import '../../../core/a11y/motion.dart';
import '../../../core/widgets/sheet_keyboard.dart';

import '../../notes/presentation/viewers/ink_tools.dart' show InkToolMemory;
import '../../notes/presentation/viewers/ink_layer.dart'
    show InkFingerToolPicker;
import '../../notes/presentation/editor/auto_spell.dart' show AutoSpell;
import '../../notes/presentation/editor/spell_settings_sheet.dart'
    show SpellModePicker, showSpellSettings;
import '../../calendar/data/holiday_source.dart' show showHolidaysProvider;
import '../../../app/split_shell.dart' show listPaneCollapsedProvider;

part 'settings_sections/settings_area.dart';
part 'settings_sections/settings_account.dart';
part 'settings_sections/settings_appearance.dart';
part 'settings_sections/settings_switches.dart';
part 'settings_sections/settings_voice.dart';
part 'settings_sections/settings_ai.dart';
part 'settings_sections/settings_writing.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.initialArea});

  /// Acilista ACIK gelecek alanin kimligi (ornegin 'account'). Rotadan
  /// `?area=` ile gelir: hesap levhasindaki "Hesap ayarlari" dogrudan hesap
  /// kartini acsin diye — kapali bir listeye dusmek "ulasilmaz" hissi
  /// veriyordu (kullanici bulgusu 2026-08-29).
  final String? initialArea;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// Ses secicisinin gosterdigi diller: uygulamanin o anki dili + tr/en.
/// Ses seçicide sunulan diller: uygulamanın dili + beş pazar dili
/// (kullanıcı 2026-11-27: Türkçe, İngilizce, Arapça, Endonezce, Malayca).
/// Arayüz çevirisinden bağımsız: Arapça notu okutmak için arayüzün Arapça
/// olması gerekmez.
List<String> _voiceLanguages(BuildContext context) => <String>{
  Localizations.localeOf(context).languageCode,
  ...kMarketLanguages,
}.toList();

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Acik olan alan. Tek seferde biri acik: dokuz kart alt alta dururken
  /// aranan ayara ulasmak icin ekranlarca kaydirmak gerekiyordu.
  /// Kalici DEGIL. Hepsi KAPALI gelir (kullanıcı isteği 2026-10-20:
  /// "görünüm menüsü varsayılan açık gelmesin") — yalnız rotadan
  /// `?area=` verildiyse o alan açık.
  ///
  /// Bildirici (P62 PA1, S36): geniş ekranda kategori seçmek YALNIZ seçili
  /// iki döşemeyi ve ayrıntı bölmesini kurar — eskiden `setState` bütün
  /// ekranı (arama kutusu, 11 kategori döşemesi, kısayollar) yeniden
  /// kuruyordu (alan değişiminin ilk karesi 551/673 widget).
  late final _openN = ValueNotifier<String>(widget.initialArea ?? '');
  String get _open => _openN.value;
  set _open(String id) => _openN.value = id;
  String _query = '';
  final _searchController = TextEditingController();

  // AI kipi (`matchSettings`, ✨ düğmesi) PLAN §1.6 AI-S1 kararıyla kaldırıldı
  // (2026-11-17): ayar araması yalnız yerel anahtar kelimeyle.

  @override
  void initState() {
    super.initState();
    // Kişiselleştir alanının özeti kayıttan okunur: Kişiselleştir ekranından
    // dönünce güncel olsun.
    Personalize.prefs.addListener(_onPersonalize);
  }

  void _onPersonalize() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Personalize.prefs.removeListener(_onPersonalize);
    _searchController.dispose();
    _openN.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final areas = <_Area>[
      // **HESAP EN ÜSTTE** (kullanıcı isteği 2026-08-18: "ayarlarda hesap
      // ayarlarını üste getir"). Hesap ve kişiler ayarların en dibindeydi:
      // giriş/çıkış, arkadaş ekleme ve hesap silme gibi en sık aranan işler
      // için dokuz alanın altına kadar kaydırmak gerekiyordu.
      _Area(
        id: 'account',
        icon: Icons.manage_accounts_outlined,
        title: l10n.account,
        summary: _accountSummary(l10n),
        keywords: 'cikis hesap sil e-posta',
        // P62 PA2 (plan §4): kimlik + şerit (kart dışı) · Oturum · (Kilit
        // KT-10 ile ayrı "Güvenlik" bölümüne taşındı) ·
        // Hakkında · en altta geri dönüşsüz "Hesabı sil" (sabah bakılacak:
        // eskiden ikinci sıradaydı).
        rows: [
          _SettingRow(
            const _AccountSection(),
            bare: true,
            title: l10n.account,
            keywords: 'hesap e-posta google bagla misafir',
          ),
          if (!ref.watch(isAnonymousProvider))
            _SettingRow(
              const _SignOutRow(),
              group: l10n.settingsGroupSession,
              title: l10n.signOut,
              keywords: 'cikis oturum',
            ),
          _SettingRow(
            const _LegalRow(licenses: false),
            group: l10n.settingsGroupAbout,
            title: l10n.privacyPolicyTitle,
            keywords: 'gizlilik politika hukuk',
          ),
          _SettingRow(
            const _LegalRow(licenses: true),
            title: l10n.licensesTitle,
            keywords: 'lisans acik kaynak',
          ),
          _SettingRow(
            const _FeedbackRow(),
            title: l10n.feedbackSend,
            keywords: 'geri bildirim oneri sorun destek e-posta',
          ),
          _SettingRow(
            const _ErrorLogButton(),
            title: l10n.errorLogShare,
            keywords: 'hata gunlugu bildir',
          ),
          if (CrashReporting.supported)
            _SettingRow(
              const _CrashReportsSwitch(),
              title: l10n.crashReports,
              keywords: 'cokme rapor',
            ),
          _SettingRow(
            const _AppVersionRow(),
            title: l10n.appVersion,
            keywords: 'surum versiyon kopyala',
          ),
          _SettingRow(
            const _DeleteAccountRow(),
            group: '',
            title: l10n.deleteAccount,
            keywords: 'hesap sil veri sil',
          ),
        ],
      ),
      // GÜVENLİK AYRI BÖLÜM (KARAR 1.0, keşif turu KT-10, 2026-11-17): not
      // kilidi ve uygulama kilidi "Hesap" başlığı altında, gizlilik/sürüm
      // satırlarının arasında duruyordu; kilit bir güvenlik ayarı.
      _Area(
        id: 'security',
        icon: Icons.lock_outline,
        title: l10n.settingsSecurityTitle,
        summary: l10n.settingsSecuritySummary,
        keywords: 'guvenlik kilit sifre desen parmak izi gizlilik',
        rows: [
          _SettingRow(
            const NoteLockSettingsTile(),
            title: l10n.lockMethodTitle,
            keywords: 'kilit sifre desen parmak izi gizlilik',
          ),
          _SettingRow(
            const AppLockSettingsTile(),
            title: l10n.appLockTitle,
            keywords: 'uygulama kilidi acilis kilit gizle son uygulamalar',
          ),
        ],
      ),
      // Kullanıcı isteği 2026-08-18: "kişiler kullanıcıya dışarıdan
      // belirleyebilmeli" — arkadaş ekleme ve klasör paylaşımının girişi
      // buradan da erişilebilir (asıl giriş klasör ⋮ menüsündeki "Paylaş").
      _Area(
        id: 'friends',
        icon: AppIcons.friends,
        title: l10n.friendsTitle,
        summary: _friendsSummary(l10n),
        keywords: 'arkadas kisi paylas klasor ortak gelen not',
        rows: [
          _SettingRow(
            const _FriendsRow(),
            title: l10n.friendsTitle,
            keywords: 'arkadas ekle davet e-posta',
          ),
          _SettingRow(
            const _InboxRow(),
            title: l10n.inboxTitle,
            keywords: 'gelen not paylasilan arkadas',
          ),
          _SettingRow(
            const _DiscoverableSwitch(),
            title: l10n.discoverable,
            keywords: '${l10n.discoverableInfo} arama gizlilik kisi bulun',
            group: l10n.settingsGroupPrivacyNotify,
          ),
          // Paylaşım bildirimleri PAYLAŞIMIN yanında (2026-09-26): eskiden
          // Görünüm alanındaydı — bildirimi arayan kullanıcı orada bakmıyordu.
          _SettingRow(
            const _SharedNotificationsSwitch(),
            title: l10n.sharedNotifications,
            keywords:
                '${l10n.sharedNotificationsInfo} bildirim paylasim klasor '
                'sohbet',
          ),
        ],
      ),
      _Area(
        id: 'ai',
        icon: Icons.auto_awesome,
        title: l10n.decisionsSectionTitle,
        summary: _aiSummary(l10n),
        keywords: 'akilli karar reyon hedef etiket api anahtar byok tam surum',
        rows: [
          _SettingRow(
            const _BuiltInAiStatus(),
            title: l10n.proTitle,
            keywords: 'kota karar hak jeton api anahtar tam surum premium',
          ),
          _SettingRow(
            const _AdvancedAiSection(),
            title: l10n.decisionsByokTitle,
            keywords: 'gemini api anahtar byok sinirsiz karar',
          ),
          _SettingRow(
            const _AiOffSwitch(),
            title: l10n.decisionsTurnOffTitle,
            keywords: '${l10n.decisionsTurnOffBody} kapat gizlilik kvkk',
            group: '',
          ),
          if (AiConsentNotifier.required)
            _SettingRow(
              const _AiConsentSwitch(),
              title: l10n.aiConsentTitle,
              keywords: 'riza onay yapay zeka gizlilik kvkk',
              group: '',
            ),
        ],
      ),
      _Area(
        id: 'appearance',
        icon: AppIcons.appearance,
        title: l10n.settingsAppearance,
        summary: _appearanceSummary(l10n),
        keywords: 'tema yazi boyutu zemin koyu acik kagit liste dil kart',
        rows: [
          _SettingRow(
            // ÖRNEK METİN en üstte (kullanıcı isteği 2026-08-16: "görünüm
            // ayarlarına örnek metin"). Tema, yazı tipi ve yazı boyutu
            // ayrı ayrı seçiliyor ama sonucu ancak notu açınca görülüyordu;
            // örnek bunları BİRLİKTE, gerçek bir notun görünümünde gösterir.
            const _AppearancePreview(),
            bare: true,
            title: l10n.appearancePreviewTitle,
            keywords: 'ornek metin onizleme gorunum',
          ),
          _SettingRow(
            // Boşluk seçicinin İÇİNDE: ayrı bir satır olsaydı süzmede tek
            // başına kalıp araya boşluk bırakırdı. Alt başlık da içinde:
            // aramada seçiciyle birlikte gelir.
            // Alt başlık artık grup etiketi (P62 PA1); aramada da eşleşir.
            const _ThemeSelector(),
            group: l10n.settingsThemeHeader,
            title: l10n.settingsAppearance,
            keywords:
                'tema ${l10n.themeSystem} ${l10n.themeSage} '
                '${l10n.themePorcelain} ${l10n.themeClay} ${l10n.themeLavender} '
                '${l10n.themeOlive} ${l10n.themeWhite} ${l10n.themeStraw} '
                '${l10n.themeCream} ${l10n.themePeach} ${l10n.themeMint} '
                '${l10n.themeOcean} ${l10n.themeRose} ${l10n.themeTangerine} '
                '${l10n.themeEmerald} ${l10n.themeAmethyst} '
                '${l10n.themeClassic} ${l10n.themeNewsprint} '
                '${l10n.themeNotebook} ${l10n.themeGraphite} '
                '${l10n.themeLedger} '
                '${l10n.themeDark}',
          ),
          // Yazı tipi + yazı boyutu TEK satırda: ikisi de "yazı nasıl
          // görünsün" işidir ve ayrı kartlarda dururken (üstelik biri
          // katalogdaki 19 yazı tipini çip çip serdiği için) Görünüm alanı
          // okunmaz hâle geliyordu.
          _SettingRow(
            const _TypographySection(),
            group: l10n.settingsGroupText,
            title: '${l10n.appFontSetting} · ${l10n.fontSize}',
            keywords:
                '${l10n.appFontInfo} font yazi tipi boyut '
                '${l10n.fontSizeSmall} ${l10n.fontSizeMedium} '
                '${l10n.fontSizeLarge} ${l10n.fontSizeXLarge} '
                '${l10n.followSystemTextScale} kalin metin erisilebilirlik',
          ),
          // DİL BAŞLIKLI KENDİ KARTINDA (2026-11-27 denetimi: başlıksızdı,
          // "Not listesi sağda" da onun kartına düşmüştü).
          _SettingRow(
            const _LanguageSelector(),
            group: l10n.settingsLanguage,
            title: l10n.settingsLanguage,
            keywords: 'dil language uygulama dili',
          ),
          _SettingRow(
            const _ExpandListItemsSwitch(),
            group: l10n.settingsCardsHeader,
            title: l10n.expandListItems,
            keywords: l10n.expandListItemsInfo,
          ),
          _SettingRow(
            const _ListPaneRightSwitch(),
            title: l10n.listPaneRight,
            keywords: '${l10n.listPaneRightInfo} liste sag sol tablet bolunmus',
          ),
          _SettingRow(
            const TypingBarSettings(),
            title: l10n.hideBarWhileTyping,
            keywords:
                '${l10n.hideBarWhileTypingInfo} alt cubuk yazarken '
                '${l10n.typingBarHideDelay} ${l10n.typingBarShowDelay} '
                'gecikme sure saniye panel',
          ),
          // "Öğrenilen yazımlar" BURADAN KALKTI (2026-11-27): Kalem, yazım ve
          // ekran → Yazım düzelt'te aynısı var; iki kapı yığılmaydı.
          _SettingRow(
            const _ItemGesturesSwitch(),
            title: l10n.itemGesturesSetting,
            keywords: '${l10n.itemGesturesSettingInfo} jest cizim karala',
          ),
          _SettingRow(
            const _ItemGesturesFingerSwitch(),
            title: l10n.itemGesturesFingerAll,
            keywords:
                '${l10n.itemGesturesFingerAllInfo} jest parmak karala daire',
          ),
          // KARTTA GÖRÜNENLER TEK SATIR (F14.2, 2026-10-31): 11 anahtar
          // alt alta Görünüm'ü okunmaz yapıyordu ve sonucu ancak ana ekranda
          // görülüyordu. Artık canlı kart örnekli bir alt levhada; satırın
          // anahtar kelimeleri bütün anahtarları taşır, aramada bulunur.
          _SettingRow(
            const CardElementsRow(),
            title: l10n.cardElementsHeader,
            keywords:
                '${l10n.cardRichPreview} ${l10n.cardHideSensitive} '
                '${l10n.cardShowProgress} ${l10n.cardShowMoreCount} '
                '${l10n.cardShowStatusIcons} ${l10n.cardShowTag} '
                '${l10n.cardShowDate} ${l10n.cardShowMedia} '
                '${l10n.cardShowFiles} ${l10n.cardShowFolder} '
                '${l10n.cardShowPaper} kart sayac ilerleme etiket tarih '
                'gorsel ek klasor defter sifre renk',
          ),
          // ANA EKRAN ZEMİNİ BURADAN KALKTI (kullanıcı isteği 2026-08-16):
          // artık ana ekranın kendi 3 nokta menüsünde (bkz.
          // dashboard_background_sheet.dart). Zeminin sonucu yalnız ana
          // ekranda görülüyor; ayarlara girip çıkarak denemek gerekiyordu.
          _SettingRow(
            const _DarkScheduleEditor(),
            title: l10n.darkSchedule,
            keywords: l10n.darkScheduleInfo,
          ),
          _SettingRow(
            ListTile(
              key: const ValueKey('settings-open-appearance-studio'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wallpaper_outlined),
              title: Text(l10n.appearanceOpenStudio),
              subtitle: Text(l10n.dashboardBackgroundInfo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(
                showAppearanceStudio(
                  context,
                  contextMode: AppearanceContext.settings,
                ),
              ),
            ),
            title: l10n.appearanceOpenStudio,
            keywords:
                '${l10n.dashboardBackground} ${l10n.appearanceTabTheme} ${l10n.appearanceTabBackground}',
          ),
        ],
      ),
      // EKLENTİLER (F14.2, 2026-10-31): eskiden adı "Kişiselleştir"di —
      // üstteki Kişiselleştir kartıyla ikinci giriş, özeti de içinde
      // olmayan video sarma süreleriydi. Kişiselleştir'in TEK kapısı artık
      // üstteki kart; bu alan içindekini adlandırır ve özetler. Kimlik
      // 'personalize' kalır (`?area=` bağlantıları).
      _Area(
        id: 'personalize',
        icon: Icons.extension_outlined,
        title: l10n.settingsModulesTitle,
        summary: _modulesSummary(l10n),
        keywords:
            'kisisellestir gizle goster eklenti duzenleme modu dugme alan '
            'arti menu ekle video sarma saniye ileri geri',
        rows: [
          // EKLENTİLER BURADA DA aç/kapa (kullanıcı isteği 2026-10-16:
          // "kişiselleştirme ayarlar kısmında aç kapa yapılamıyor, oradan da
          // yapılabilmeli") — Kişiselleştir ekranıyla aynı parça, aynı kayıt.
          _SettingRow(
            const PersonalizeModuleSwitches(),
            title: l10n.personalizeModules,
            keywords:
                '${l10n.moduleAi} ${l10n.moduleVoice} ${l10n.moduleVideo} '
                '${l10n.moduleDocuments} ${l10n.moduleScan} '
                '${l10n.moduleDrawing} ${l10n.moduleTemplates} '
                '${l10n.moduleTags} ${l10n.moduleCollaboration} eklenti ac kapa',
          ),
          // TOPARLAMA (kullanıcı isteği 2026-10-17: "tekrarlar düzelsin,
          // menüler anlaşılır olsun"): "Düzenleme modunu başlat" satırı
          // buradan kalktı — aynı iş Ayarlar'ın tepesindeki "Düzenleme modu"
          // kısayol kartında. Ana ekrandaki HIZLI NOT SATIRI bir görünürlük
          // tercihi olduğu için Görünüm'den buraya taşındı (tek yer).
          _SettingRow(
            const _QuickCaptureRowSwitch(),
            title: l10n.quickCaptureRowSetting,
            keywords: '${l10n.quickCaptureRowInfo} duzenleme modu',
          ),
          // BİR KEZ ÇIKAN İPUÇLARI (F14.6) burada açılıp kapatılır ve sıfırlanır.
          _SettingRow(
            const _TipsEnabledTile(),
            title: l10n.tipsEnabledTitle,
            keywords: '${l10n.tipsEnabledInfo} ipucu jest yardim',
          ),
          _SettingRow(
            const _TipsResetTile(),
            title: l10n.tipsResetTitle,
            keywords: '${l10n.tipsResetInfo} ipucu jest yardim',
          ),
        ],
      ),
      // **NOTLAR VE KLASÖRLER** (kullanıcı isteği 2026-09-26: "eksik
      // ayarların düzenlenmesi", "klasör sıralaması ayarlama", "sağ sol
      // kaydırmada klasörler arası geçiş"). Ana ekranın davranış
      // tercihleri ilk kez tek yerde — bkz. notes_settings.dart.
      _Area(
        id: 'notes',
        icon: Icons.dashboard_customize_outlined,
        title: l10n.notesSettingsTitle,
        summary: _notesSummary(context, l10n),
        keywords:
            'klasor sira kaydir yana cek sutun izgara liste siralama arama '
            'raf',
        rows: [
          _SettingRow(
            const SwipeModeSetting(),
            title: l10n.swipeModeTitle,
            keywords:
                '${l10n.swipeModeFolders} ${l10n.swipeModeFilters} kaydir '
                'yana cek',
            // GRUPLAR (2026-11-27, kullanıcı: "ayarlardaki aşırı yığılma"):
            // 15 ayar başlıksız tek karttaydı.
            group: l10n.settingsGroupGestures,
          ),
          _SettingRow(
            HomeGestureSetting(
              provider: homePullGestureProvider,
              title: l10n.homePullGestureTitle,
            ),
            title: l10n.homePullGestureTitle,
            keywords: 'jest asagi cek ustten klasor takvim not',
          ),
          _SettingRow(
            HomeGestureSetting(
              provider: homeSwipeRightGestureProvider,
              title: l10n.homeSwipeRightGestureTitle,
            ),
            title: l10n.homeSwipeRightGestureTitle,
            keywords: 'jest takvim saga kaydir yana cek klasor not',
          ),
          _SettingRow(
            const CalendarAddActionSetting(),
            title: l10n.calendarAddActionTitle,
            keywords: 'takvim arti ekle not etkinlik gorev varsayilan',
            group: l10n.calendarTitle,
          ),
          _SettingRow(
            const CalendarSwipeSetting(),
            title: l10n.calendarSwipe,
            keywords: '${l10n.calendarSwipeInfo} takvim hafta gun kaydir',
          ),
          _SettingRow(
            const FolderOrderSetting(),
            title: l10n.folderOrderTitle,
            keywords:
                '${l10n.folderReorder} ${l10n.folderOrderName} '
                '${l10n.folderOrderNewest} klasor sira',
            group: l10n.settingsGroupSortView,
          ),
          _SettingRow(
            const NoteSortSetting(),
            title: l10n.sortBy,
            keywords: 'siralama not sira',
          ),
          _SettingRow(
            const NoteLayoutSetting(),
            title: l10n.noteViewSetting,
            keywords:
                '${l10n.gridColumnsSetting} ${l10n.noteViewGrid} '
                '${l10n.noteViewList} ${l10n.folderShelfSetting} sutun',
          ),
          _SettingRow(
            _PrefSwitch(
              provider: homeShowSharedProvider,
              icon: AppIcons.shared,
              title: l10n.homeShowShared,
              subtitle: l10n.homeShowSharedInfo,
            ),
            title: l10n.homeShowShared,
            keywords:
                '${l10n.homeShowSharedInfo} paylasilan ortak not ana ekran',
            group: l10n.settingsGroupShared,
          ),
          // "İçerikten not açılışı" (Balonlu / Klasik / Sor) KALKTI
          // (kullanıcı isteği 2026-11-03): not hep klasik açılır, görünüm
          // notun içinde seçilir.
          // EKOSİSTEM (kullanıcı isteği 2026-10-17): kardeş uygulama Dosya
          // Okuyucu kuruluysa dosya seçimi onda, istenen türe süzülmüş açılır.
          // Kurulu değilse satır hiç çizilmez.
          _SettingRow(
            const _FileAppSwitch(),
            title: l10n.fileAppPickerTitle,
            keywords: 'dosya okuyucu secici dosya yoneticisi pdf ses ekle',
            group: l10n.settingsGroupAttachments,
          ),
          _SettingRow(
            const _AttachmentSearchSwitch(),
            title: l10n.searchAttachments,
            keywords:
                '${l10n.searchAttachmentsInfo} arama pdf gorsel ocr ek '
                'icerik',
          ),
        ],
      ),
      // Ses: asistan dugmesinin davranisi + sesli okuma + sistem dili.
      // Tasarim ucunu tek alanda topluyor; kodda uc ayri karttilar ve
      // "okuma hizi" ile "asistan dugmesi" arasinda gezinmek gerekiyordu.
      _Area(
        id: 'sound',
        icon: Icons.record_voice_over_outlined,
        // Alan adı İÇERİĞİ (F14.2): "Sesli okuma" deyip içinde dikte ve dil
        // taşıyordu. Dil artık Görünüm'de.
        title: l10n.settingsSoundTitle,
        summary: _soundSummary(l10n),
        keywords: 'mikrofon ses okuma sesli dinle dikte hiz basili tut',
        rows: [
          // SESLENDİRME TEK BLOKTA (kullanıcı isteği 2026-08-09: "sesli okuma
          // ayarları ve ai ayarları düzenlenmeli ve birleştirilmeli; ai ve
          // cihaz seçimleri tek yerden yapılabilmeli, ses seçimleri tek menüde
          // olmalı").
          //
          // Eskiden: motor seçimi bir satırda, uygulamanın DİLİ BAŞINA ayrı
          // birer ses açılır listesi (2–3 satır), bunların açıklaması ayrı bir
          // satır, hızlar ayrı iki satır — okuma ayarı aramak altı satır
          // gezmek demekti ve "AI sesi" ile "cihaz sesi" ekranın iki ayrı
          // yerinde seçiliyordu. Şimdi hepsi [_VoiceSection]'da: motor, model,
          // ses ve deneme tek yerde; cihaz sesleri TEK menüde (dil seç → ses
          // seç) toplanıyor.
          _SettingRow(
            const _VoiceSection(),
            group: l10n.ttsSectionTitle,
            title: l10n.ttsSectionTitle,
            keywords:
                'seslendirme motor yapay zeka cihaz sesi tts ses tipi '
                '${l10n.speechVoicePickerTitle} ${l10n.speechVoiceAutoInfo}',
          ),
          _SettingRow(const _SpeechRateSlider(), title: l10n.speechRate),
          _SettingRow(
            const _ForeignSpeechRateSlider(),
            title: l10n.speechRateForeign,
          ),
          _SettingRow(const _SpeechPitchSlider(), title: l10n.speechPitch),
          _SettingRow(
            const _VoiceModeSelector(),
            group: l10n.settingsGroupDictation,
            title: l10n.voiceModeSetting,
            keywords: '${l10n.voiceModeHold} ${l10n.voiceModeTap} mikrofon',
          ),
        ],
      ),
      if (const PermissionsService().isSupported)
        _Area(
          id: 'permissions',
          icon: Icons.verified_user_outlined,
          title: l10n.permissionsTitle,
          summary: '',
          keywords: 'mikrofon kamera bildirim izin',
          rows: [
            _SettingRow(
              const _PermissionsSection(),
              title: l10n.permissionsTitle,
              keywords: 'mikrofon kamera bildirim izin',
            ),
          ],
        ),
      // GÜNCELLEME VE SÜRÜM (2026-11-10, kullanıcı: "güncelleme vs ile ilgili
      // şeyler çok dağıldı, bir başlık altında topla"): sürüm notları, denetle,
      // oto güncelleme ve yeniden açılma izni tek alanda.
      _Area(
        id: 'updates',
        icon: Icons.system_update_alt,
        title: l10n.settingsUpdatesTitle,
        summary: '',
        keywords:
            'guncelle guncelleme surum notlar yenilik otomatik indir kur '
            'denetle versiyon yeniden ac izin',
        rows: [
          _SettingRow(
            const _VersionFooter(),
            group: l10n.settingsGroupVersion,
            title: l10n.settingsUpdatesTitle,
            keywords:
                '${l10n.releaseNotesTitle} ${l10n.autoUpdateTitle} '
                '${l10n.updateTapToCheck} versiyon',
          ),
          _SettingRow(
            const Padding(
              padding: EdgeInsets.only(top: AppSpace.s),
              child: CrossAppPromoCard(),
            ),
            title: l10n.ecosystemDosyalarimTitle,
            keywords: 'dosyalarim pdf word excel',
            group: '',
          ),
        ],
      ),
      // KALEM, YAZIM VE EKRAN (2026-11-10): eskiden yalnız kendi ekranından
      // değişen ayarlar (bkz. settings_writing.dart).
      _Area(
        id: 'writing',
        icon: Icons.draw_outlined,
        title: l10n.settingsWritingTitle,
        summary: l10n.settingsWritingSummary,
        keywords:
            'kalem yazim duzelt el yazisi stylus takvim serit tatil klasor '
            'satiri tumu ek seridi odak',
        rows: _writingRows(l10n),
      ),
      _Area(
        id: 'sync',
        icon: Icons.cloud_sync_outlined,
        title: l10n.syncTitle,
        summary: '',
        keywords: 'yedek geri yukle sinir mb yukleme depolama alan kota',
        rows: [
          // EK SENKRONU (kullanıcı isteği 2026-10-15): Google hesabında
          // ekler kullanıcının Drive'ına, misafir hesapta yalnız metin.
          _SettingRow(
            const AttachmentSyncTile(),
            group: l10n.settingsGroupAttachments,
            title: l10n.attachmentSyncTitle,
            keywords: 'google drive ek gorsel pdf senkron bagla kota',
          ),
          _SettingRow(
            const _StorageUsage(),
            group: l10n.deviceStorageTitle,
            title: l10n.storageUsage,
            keywords: 'depolama alan kota gb mb dolu',
          ),
          _SettingRow(
            const DeviceStorageSection(),
            title: l10n.deviceStorageTitle,
            keywords:
                '${l10n.deviceStorageClear} onbellek temizle yer boyut mb '
                'cihaz',
          ),
          _SettingRow(
            const _SyncLimitSelector(),
            title: l10n.syncLimitTitle,
            keywords: '${l10n.syncLimitInfo} sinir mb yukleme',
          ),
          _SettingRow(
            const _BackupStatus(),
            group: l10n.settingsGroupBackup,
            bare: true,
            keywords: 'yedek durum son bulut eslitleme guvende',
          ),
          _SettingRow(
            const _BackupButton(),
            title: l10n.exportBackup,
            keywords: 'yedek disa aktar',
          ),
          _SettingRow(
            const _MarkdownExportButton(),
            title: l10n.exportMarkdownZip,
            keywords: 'markdown md zip disa aktar obsidian notion',
          ),
          _SettingRow(
            const _RestoreButton(),
            title: l10n.importBackup,
            keywords: 'geri yukle ice aktar',
          ),
          _SettingRow(
            const _ImportOtherButton(),
            title: l10n.importOther,
            keywords: 'ice aktar keep evernote markdown takeout txt',
          ),
        ],
      ),
    ];

    final query = foldForSearch(_query.trim());
    final visible = <({_Area area, List<Widget> rows})>[
      for (final a in areas)
        if (a.visible(query)) (area: a, rows: a.visibleRows(query)),
    ]..removeWhere((e) => e.rows.isEmpty);
    final searching = query.isNotEmpty;
    final byId = {for (final a in areas) a.id: a};
    final wide = MediaQuery.sizeOf(context).width >= _kSettingsWide;
    // Geniş ekranda sağ bölme hiç boş kalmasın: ilk alan seçili gelir.
    final openId = byId.containsKey(_open)
        ? _open
        : (wide ? areas.first.id : '');
    final openArea = byId[openId];
    // Dar ekranda alan sayfası açıkken çubuk o alanın adını taşır, arama
    // kutusu gizlenir (sayfa içinde arama yok — kökteki arama her yere bakar).
    final inArea = !wide && openArea != null && !searching;

    void openAreaId(String id) {
      // `FocusScope.of` DEĞİL: geri çağrıda bile ekranı odak kapsamına
      // bağımlı kılıyor, odak değişince BÜTÜN ayarlar yeniden kuruluyordu
      // (S36 ilk dokunuş 590 widget).
      FocusManager.instance.primaryFocus?.unfocus();
      // Geniş ekranda düzen değişmiyor: bildirici yeter (bkz. [_openN]).
      if (wide && !searching) {
        _open = id;
        return;
      }
      setState(() => _open = id);
    }

    final groups = _settingsGroups(l10n, byId);

    Widget root() => ListView(
      key: const PageStorageKey('settings-root'),
      padding: EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.m,
        AppSpace.l,
        AppSpace.l + MediaQuery.paddingOf(context).bottom + AppSpace.xxxl,
      ),
      children: [
        if (searching)
          ..._searchResults(context, visible, openAreaId)
        else ...[
          const _ProfileCard(),
          const SizedBox(height: AppSpace.m),
          // KISAYOLLAR: Kılavuz (ayar arayan çoğu zaman bir özelliğin nasıl
          // kullanıldığını arıyor) ve Kişiselleştir yan yana.
          _ShortcutTiles(
            tiles: [
              _ShortcutTile(
                key: const ValueKey('settings-guide'),
                icon: AppIcons.guide,
                title: l10n.guideTitle,
                subtitle: l10n.guideMenuInfo,
                // Nötr (DENEYIM §2.2 K-D1): kısayol eylem/dikkat değil.
                onTap: () => context.push('/guide'),
              ),
              _ShortcutTile(
                key: const ValueKey('settings-personalize'),
                icon: Icons.tune_rounded,
                title: l10n.personalizeTitle,
                subtitle: l10n.personalizeInfo,
                onTap: () async {
                  final result = await context.push<String>('/personalize');
                  // Kişiselleştir'den düzenleme modu başlatıldıysa ayarlar
                  // da kapanır: kullanıcı düzenleyeceği ekrana iner.
                  if (result == 'edit' && context.mounted) context.pop();
                },
              ),
              // PL6: Pro (katmanlar, satın alma, geri yükleme) YALNIZ Play
              // derlemesinde; kişisel APK / web'de bu kart hiç yok (bekçi
              // `test/billing_test.dart`).
              if (PlayBuild.enabled)
                _ShortcutTile(
                  key: const ValueKey('settings-pro'),
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.proTitle,
                  subtitle: l10n.proSettingsSubtitle,
                  onTap: () => context.push('/premium'),
                ),
            ],
          ),
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s,
                AppSpace.xl,
                AppSpace.s,
                AppSpace.s,
              ),
              child: SectionLabel(g.title),
            ),
            _CategoryGroup(
              areas: g.areas,
              selection: wide ? _openN : null,
              fallbackId: areas.first.id,
              onTap: openAreaId,
            ),
          ],
          _VersionLine(onTap: () => openAreaId('updates')),
        ],
      ],
    );

    Widget areaPage(_Area a) => _AreaPage(
      key: ValueKey('settings-area-${a.id}'),
      area: a,
      showHeader: wide,
    );

    final Widget body;
    if (wide) {
      // KW-21: liste + ayrıntı ÇİFTİ ortada (en çok 380 + 1 + 720); ayrıntı
      // yine listeye yaslı (KT-10), 1920'de sağda ~700 px boşluk kalmaz.
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380 + 1 + 720),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Arama kutusu sol sütunun içinde, sütunla aynı hizada (A10).
              SizedBox(
                width: 380,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.l,
                        AppSpace.xs,
                        AppSpace.l,
                        AppSpace.xs,
                      ),
                      child: _searchBar(context),
                    ),
                    Expanded(child: root()),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: scheme.outlineVariant),
              Expanded(
                child: searching
                    ? const SizedBox.shrink()
                    : ValueListenableBuilder<String>(
                        valueListenable: _openN,
                        builder: (context, id, _) {
                          final a = byId[id] ?? areas.first;
                          // Ayrıntı listeye YASLI (KT-10; ortalıyken arada boşluk
                          // kalıyordu — sabah bakılacak, plan §8.5). Alan değişimi
                          // yalnız solma.
                          return Align(
                            alignment: AlignmentDirectional.topStart,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: AnimatedSwitcher(
                                duration: AppMotion.of(
                                  context,
                                  AppMotion.quick,
                                ),
                                reverseDuration: AppMotion.of(
                                  context,
                                  AppMotion.exitOf(AppMotion.quick),
                                ),
                                child: areaPage(a),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Kök ↔ alan: solma + %6 kayma; giriş `medium`, çıkış onun 2/3'ü
      // (P62 ortak hareket sözlüğü, A11).
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, AppMotion.medium),
            reverseDuration: AppMotion.of(
              context,
              AppMotion.exitOf(AppMotion.medium),
            ),
            switchInCurve: AppMotion.curveOf(context, AppMotion.enter),
            switchOutCurve: AppMotion.curveOf(context, AppMotion.exit),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: motionOf(context)
                      ? Offset(
                          child.key == const ValueKey('root') ? -0.06 : 0.06,
                          0,
                        )
                      : Offset.zero,
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: inArea
                ? KeyedSubtree(
                    key: ValueKey(openArea.id),
                    child: areaPage(openArea),
                  )
                : KeyedSubtree(key: const ValueKey('root'), child: root()),
          ),
        ),
      );
    }

    return PopScope(
      // Dar ekranda alan sayfasından geri → ayarların köküne (ekrandan değil).
      canPop: !inArea,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && inArea) setState(() => _open = '');
      },
      child: Scaffold(
        appBar: HomeInBar(
          appBar: AppBar(
            leading: inArea
                ? BackButton(
                    key: const ValueKey('settings-area-back'),
                    onPressed: () => setState(() => _open = ''),
                  )
                : null,
            title: Text(inArea ? openArea.title : l10n.settings),
            // AYAR ARA EN ÜSTTE, SABİT (kullanıcı isteği 2026-10-20).
            // Geniş ekranda kutu sol sütunun içinde.
            bottom: inArea || wide
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(58),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.l,
                        0,
                        AppSpace.l,
                        AppSpace.s,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 612),
                          child: _searchBar(context),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        body: body,
      ),
    );
  }

  /// Arama sonuçları: her eşleşen alan bir başlık (dokun → alan sayfası) ve
  /// altında YALNIZ eşleşen satırlar.
  List<Widget> _searchResults(
    BuildContext context,
    List<({_Area area, List<Widget> rows})> visible,
    ValueChanged<String> onOpen,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    if (visible.isEmpty) {
      return [
        Padding(
          key: const ValueKey('settings-search-empty'),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xxxl),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.l),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: AppIconSize.l,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.m),
              Text(
                l10n.settingsSearchEmpty(_query.trim()),
                textAlign: TextAlign.center,
                style: text.body.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      for (final e in visible) ...[
        _CategoryTile(
          area: e.area,
          compact: true,
          onTap: () {
            _searchController.clear();
            setState(() => _query = '');
            onOpen(e.area.id);
          },
        ),
        const SizedBox(height: AppSpace.xs),
        _RowsCard(rows: e.rows),
        const SizedBox(height: AppSpace.m),
      ],
    ];
  }

  /// Kök sayfadaki gruplar: Hesap · Uygulama · Veri ve gizlilik.
  List<({String title, List<_Area> areas})> _settingsGroups(
    AppLocalizations l10n,
    Map<String, _Area> byId,
  ) {
    List<_Area> pick(List<String> ids) => [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    final groups = [
      (
        title: l10n.settingsGroupAccount,
        areas: pick(['account', 'security', 'friends']),
      ),
      (
        title: l10n.settingsGroupApp,
        areas: pick([
          'appearance',
          'personalize',
          'notes',
          'writing',
          'sound',
          'ai',
        ]),
      ),
      (
        title: l10n.settingsGroupData,
        areas: pick(['sync', 'permissions', 'updates']),
      ),
    ];
    // Gruplara girmeyen yeni bir alan kaybolmasın: son gruba eklenir.
    final listed = {for (final g in groups) ...g.areas.map((a) => a.id)};
    final rest = [
      for (final a in byId.values)
        if (!listed.contains(a.id)) a,
    ];
    return [
      for (final g in groups)
        if (g.areas.isNotEmpty) g,
      if (rest.isNotEmpty) (title: l10n.settingsGroupOther, areas: rest),
    ];
  }

  /// Tepedeki sabit arama kutusu (yerel anahtar kelime araması).
  Widget _searchBar(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final hasText = _query.trim().isNotEmpty;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: hasText
              ? scheme.primary.withValues(alpha: AppAlpha.muted)
              : tokens.hairline,
        ),
      ),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpace.l,
        end: AppSpace.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: AppIconSize.s,
            color: hasText ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: TextField(
              key: const ValueKey('settings-search'),
              controller: _searchController,
              textInputAction: TextInputAction.done,
              onChanged: (v) => setState(() => _query = v),
              style: text.body,
              decoration: InputDecoration(
                hintText: l10n.settingsSearchHint,
                hintStyle: text.meta,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              // Etiketsiz simge düğmesi ekran okuyucuda "düğme" diye
              // okunuyordu; ipucu hem imleç üstünde hem TalkBack'te ne
              // yaptığını söyler.
              tooltip: l10n.clearSearch,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: AppIconSize.s),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
    );
  }

  /// Hesap özeti: e-posta ya da "Yerel hesap".
  String _accountSummary(AppLocalizations l10n) {
    if (ref.watch(isAnonymousProvider)) return l10n.localAccountBadge;
    return ref.watch(authStateProvider).value?.email ?? '';
  }

  /// Kişiler özeti: kişi sayısı ve bekleyen istek.
  String _friendsSummary(AppLocalizations l10n) {
    if (ref.watch(isAnonymousProvider)) return '';
    final n = ref.watch(friendsStreamProvider).value?.length ?? 0;
    final r = ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
    return [
      l10n.friendsCountSummary(n),
      if (r > 0) l10n.friendsRequestsSummary(r),
    ].join(' · ');
  }

  /// Kaç eklenti açık ("8/9 açık"); kısmen açık eklenti açık sayılmaz.
  String _modulesSummary(AppLocalizations l10n) {
    final p = Personalize.prefs.value;
    final on = UiModule.all.where((m) => p.moduleState(m) ?? false).length;
    return l10n.settingsModulesSummary(on, UiModule.all.length);
  }

  /// Notlar alanının özeti İÇERİKTEN (F14.2): sıralama · yana kaydırma.
  String _notesSummary(BuildContext context, AppLocalizations l10n) =>
      '${sortLabel(l10n, ref.watch(noteSortProvider))} · '
      '${swipeModeLabel(context, ref.watch(swipeModeProvider))}';

  String _aiSummary(AppLocalizations l10n) {
    if ((ref.watch(activeApiKeyProvider).value ?? '').trim().isNotEmpty) {
      return l10n.decisionsQuotaByok;
    }
    final paid =
        !EntitlementGate.active ||
        ref.watch(effectiveTierProvider) == EntitlementTier.lifetime;
    if (!paid) return l10n.proStatusFree;
    final quota = ref.watch(decisionQuotaProvider);
    return l10n.decisionsQuotaSummary(
      quota.remainingCalls,
      formatDecisionTokens(quota.remainingTokens),
    );
  }

  String _appearanceSummary(AppLocalizations l10n) {
    final theme = switch (ref.watch(themeFamilyProvider)) {
      ThemeFamily.sage => l10n.themeSage,
      ThemeFamily.porcelain => l10n.themePorcelain,
      ThemeFamily.clay => l10n.themeClay,
      ThemeFamily.lavender => l10n.themeLavender,
      ThemeFamily.olive => l10n.themeOlive,
      ThemeFamily.white => l10n.themeWhite,
      ThemeFamily.straw => l10n.themeStraw,
      ThemeFamily.cream => l10n.themeCream,
      ThemeFamily.peach => l10n.themePeach,
      ThemeFamily.mint => l10n.themeMint,
      ThemeFamily.ocean => l10n.themeOcean,
      ThemeFamily.rose => l10n.themeRose,
      ThemeFamily.tangerine => l10n.themeTangerine,
      ThemeFamily.emerald => l10n.themeEmerald,
      ThemeFamily.amethyst => l10n.themeAmethyst,
      ThemeFamily.classic => l10n.themeClassic,
      ThemeFamily.newsprint => l10n.themeNewsprint,
      ThemeFamily.notebook => l10n.themeNotebook,
      ThemeFamily.graphite => l10n.themeGraphite,
      ThemeFamily.ledger => l10n.themeLedger,
    };
    final brightnessLabel = switch (ref.watch(themeBrightnessModeProvider)) {
      AppBrightnessMode.system => l10n.brightnessModeAuto,
      AppBrightnessMode.light => l10n.brightnessModeLight,
      AppBrightnessMode.dark => l10n.brightnessModeDark,
    };
    final size = switch (nearestFontScaleStep(ref.watch(fontScaleProvider))) {
      FontScaleStep.small => l10n.fontSizeSmall,
      FontScaleStep.medium => l10n.fontSizeMedium,
      FontScaleStep.large => l10n.fontSizeLarge,
      FontScaleStep.xlarge => l10n.fontSizeXLarge,
    };
    return '$theme ($brightnessLabel) · $size · ${ref.watch(appFontProvider)}';
  }

  String _soundSummary(AppLocalizations l10n) {
    final engine = l10n.ttsEngineDevice;
    final mode = ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold
        ? l10n.voiceModeHold
        : l10n.voiceModeTap;
    return '${l10n.listen}: $engine · ${l10n.liveDictation}: $mode';
  }
}
