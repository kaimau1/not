import 'dart:math' as math;
import '../../../app/app_frame.dart';
import '../../../core/app_icons.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart'
    show AuthCredential, FirebaseAuth, FirebaseAuthException;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';

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
import '../../../core/constants.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import '../../../core/tips.dart';
import 'personalize_screen.dart' show PersonalizeModuleSwitches;
import 'theme_picker.dart';
import '../../../core/utils/channel_counter.dart';
import '../../../core/utils/diagnostics.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/widgets/expand_reveal.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/language_names.dart';
import '../../../core/utils/note_fonts.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/utils/speech_output.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/ai_speech.dart';
import '../../ai/data/antalia/antalia_engine.dart';
import '../../ai/data/antalia/antalia_speech.dart';
import '../../ai/data/speech_service.dart';
import '../../ai/data/ai_provider.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/model_catalog.dart';
import '../../ai/data/firebase_ai_client.dart';
import '../../ai/data/gemini_service.dart';
import '../../auth/data/account_service.dart';
import '../../auth/presentation/auth_errors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/sign_out_actions.dart';
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
    show noteSortProvider, swipeModeProvider;
import '../../notes/presentation/filter_sheet.dart' show sortLabel;
import '../../notes/presentation/note_card.dart' show NoteCard;
import '../../notes/domain/note_item.dart';
import '../../notes/data/drive_store.dart';
import '../../notes/presentation/drive_ui.dart';
import '../data/permissions_service.dart';
import '../settings_providers.dart';
import 'notes_settings.dart';
import 'backup_ui.dart';
import '../../../core/app_update.dart'
    show newVersionAvailableProvider, openReleasesPage;
import 'app_lock.dart';
import '../../notes/data/backup_service.dart';
import '../../notes/data/attachment_repository.dart';
import '../../folders/data/folders_repository.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/press_scale.dart';
import '../../../core/friendly_error.dart';
import '../../auth/presentation/account_required.dart';
import '../../../core/a11y/chip_roles.dart';
import '../../../core/a11y/min_tap_target.dart';

part 'settings_sections/settings_area.dart';
part 'settings_sections/settings_account.dart';
part 'settings_sections/settings_appearance.dart';
part 'settings_sections/settings_switches.dart';
part 'settings_sections/settings_voice.dart';
part 'settings_sections/settings_ai.dart';

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
List<String> _voiceLanguages(BuildContext context) {
  final supported = supportedLanguages.keys.toSet();
  return <String>{
    Localizations.localeOf(context).toLanguageTag(),
    'tr',
    'en',
  }.where(supported.contains).toList();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Acik olan alan. Tek seferde biri acik: dokuz kart alt alta dururken
  /// aranan ayara ulasmak icin ekranlarca kaydirmak gerekiyordu.
  /// Kalici DEGIL. Hepsi KAPALI gelir (kullanıcı isteği 2026-10-20:
  /// "görünüm menüsü varsayılan açık gelmesin") — yalnız rotadan
  /// `?area=` verildiyse o alan açık.
  late String _open = widget.initialArea ?? '';
  String _query = '';
  final _searchController = TextEditingController();

  /// **AI KİPİ** (kullanıcı isteği 2026-10-20): arama kutusundaki ✨ açıkken
  /// yazılan cümle anahtar kelimeyle değil yapay zekâyla eşlenir ("yazılar
  /// çok küçük" → Yazı boyutu). Sonuç `alan:satır` anahtarları; null =
  /// henüz sorulmadı.
  bool _aiMode = false;
  bool _aiBusy = false;
  Set<String>? _aiKeys;

  /// Son build'deki ayar kataloğu (AI'a giden satır adları ve anahtarları).
  List<String> _catalog = const [];
  List<String> _catalogKeys = const [];

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
        rows: [
          _SettingRow(
            const _AccountSection(),
            title: l10n.account,
            keywords: 'cikis hesap sil e-posta ${l10n.deleteAccount}',
          ),
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
        title: l10n.settingsAi,
        summary: _aiSummary(l10n),
        keywords: 'brifing etiket baslik asistan model api anahtar',
        rows: [
          _SettingRow(
            const _BuiltInAiStatus(),
            title: l10n.settingsAi,
            keywords: 'kota puan hak api anahtar premium',
          ),
          _SettingRow(
            const _BriefingEditor(),
            title: l10n.briefingSetting,
            keywords: l10n.briefingSettingInfo,
          ),
          _SettingRow(
            const _AutoTagSwitch(),
            title: l10n.autoTagSetting,
            keywords: l10n.autoTagSettingInfo,
          ),
          _SettingRow(
            const _AutoTitleSwitch(),
            title: l10n.autoTitleSetting,
            keywords: l10n.autoTitleSettingInfo,
          ),
          _SettingRow(
            const _AssistantVoiceSwitch(),
            title: l10n.assistantVoiceSetting,
            keywords: l10n.assistantVoiceSettingInfo,
          ),
          _SettingRow(
            const _AiSkipCheckedSwitch(),
            title: l10n.aiSkipCheckedSetting,
            keywords: l10n.aiSkipCheckedInfo,
          ),
          _SettingRow(
            const _AdvancedAiSection(),
            title: l10n.aiAdvanced,
            keywords:
                '${l10n.aiAdvancedInfo} gemini openai claude openrouter '
                'api anahtar model tanilama',
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
            title: l10n.appearancePreviewTitle,
            keywords: 'ornek metin onizleme gorunum',
          ),
          _SettingRow(
            // Boşluk seçicinin İÇİNDE: ayrı bir satır olsaydı süzmede tek
            // başına kalıp araya boşluk bırakırdı. Alt başlık da içinde:
            // aramada seçiciyle birlikte gelir.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SubHeader(l10n.settingsThemeHeader),
                const _ThemeSelector(),
                const SizedBox(height: 12),
              ],
            ),
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
            title: '${l10n.appFontSetting} · ${l10n.fontSize}',
            keywords:
                '${l10n.appFontInfo} font yazi tipi boyut '
                '${l10n.fontSizeSmall} ${l10n.fontSizeMedium} '
                '${l10n.fontSizeLarge} ${l10n.fontSizeXLarge} '
                '${l10n.followSystemTextScale} kalin metin erisilebilirlik',
          ),
          _SettingRow(
            const _LanguageSelector(),
            title: l10n.settingsLanguage,
            keywords: 'dil language uygulama dili',
          ),
          _SettingRow(_SubHeader(l10n.settingsCardsHeader)),
          _SettingRow(
            const _ExpandListItemsSwitch(),
            title: l10n.expandListItems,
            keywords: l10n.expandListItemsInfo,
          ),
          _SettingRow(
            const _HideBarWhileTypingSwitch(),
            title: l10n.hideBarWhileTyping,
            keywords: '${l10n.hideBarWhileTypingInfo} alt cubuk yazarken',
          ),
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
          // BİR KEZ ÇIKAN İPUÇLARI (F14.6) burada sıfırlanır.
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
          ),
          _SettingRow(
            const SwipeCalendarSetting(),
            title: l10n.swipeLeftCalendar,
            keywords: 'takvim sola kaydir yana cek',
          ),
          _SettingRow(
            const FolderOrderSetting(),
            title: l10n.folderOrderTitle,
            keywords:
                '${l10n.folderReorder} ${l10n.folderOrderName} '
                '${l10n.folderOrderNewest} klasor sira',
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
          ),
          _SettingRow(
            _PrefSwitch(
              provider: homeSharedAtBottomProvider,
              icon: Icons.vertical_align_bottom,
              title: l10n.homeSharedAtBottom,
              subtitle: l10n.homeSharedAtBottomInfo,
            ),
            title: l10n.homeSharedAtBottom,
            keywords:
                '${l10n.homeSharedAtBottomInfo} paylasilan siralama alt ust',
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
            title: l10n.attachmentSyncTitle,
            keywords: 'google drive ek gorsel pdf senkron bagla kota',
          ),
          _SettingRow(
            const _StorageUsage(),
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
            const _BackupButton(),
            title: l10n.exportBackup,
            keywords: 'yedek disa aktar',
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

    // AI'a gidecek katalog: başlıklı her satır "Alan › Satır — anahtarlar".
    _catalog = [];
    _catalogKeys = [];
    for (final a in areas) {
      for (var i = 0; i < a.rows.length; i++) {
        final r = a.rows[i];
        if (r.title.isEmpty) continue;
        final words = r.keywords.length > 140
            ? r.keywords.substring(0, 140)
            : r.keywords;
        _catalog.add('${a.title} › ${r.title} — $words');
        _catalogKeys.add('${a.id}:$i');
      }
    }

    final aiKeys = _aiMode ? _aiKeys : null;
    // AI kipinde metin süzgeci yok: kutudaki cümle anahtar kelime değil.
    final query = _aiMode ? '' : foldForSearch(_query.trim());
    final visible = <({_Area area, List<Widget> rows})>[
      for (final a in areas)
        if (aiKeys != null)
          (
            area: a,
            rows: [
              for (var i = 0; i < a.rows.length; i++)
                if (aiKeys.contains('${a.id}:$i')) a.rows[i].child,
            ],
          )
        else if (a.visible(query))
          (area: a, rows: a.visibleRows(query)),
    ]..removeWhere((e) => e.rows.isEmpty);
    final searching = query.isNotEmpty || aiKeys != null;
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
      FocusScope.of(context).unfocus();
      setState(() => _open = id);
    }

    final groups = _settingsGroups(l10n, byId);

    Widget root() => ListView(
      key: const PageStorageKey('settings-root'),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.paddingOf(context).bottom + 48,
      ),
      children: [
        if (searching)
          ..._searchResults(context, visible, aiKeys != null, openAreaId)
        else ...[
          const _ProfileCard(),
          const SizedBox(height: 12),
          // KISAYOLLAR: Kılavuz (ayar arayan çoğu zaman bir özelliğin nasıl
          // kullanıldığını arıyor) ve Kişiselleştir yan yana.
          _ShortcutTiles(
            tiles: [
              _ShortcutTile(
                key: const ValueKey('settings-guide'),
                icon: AppIcons.guide,
                title: l10n.guideTitle,
                subtitle: l10n.guideMenuInfo,
                color: scheme.secondary,
                onTap: () => context.push('/guide'),
              ),
              _ShortcutTile(
                key: const ValueKey('settings-personalize'),
                icon: Icons.tune_rounded,
                title: l10n.personalizeTitle,
                subtitle: l10n.personalizeInfo,
                color: scheme.primary,
                onTap: () async {
                  final result = await context.push<String>('/personalize');
                  // Kişiselleştir'den düzenleme modu başlatıldıysa ayarlar
                  // da kapanır: kullanıcı düzenleyeceği ekrana iner.
                  if (result == 'edit' && context.mounted) context.pop();
                },
              ),
            ],
          ),
          for (final g in groups) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              child: SectionLabel(g.title),
            ),
            _CategoryGroup(
              areas: g.areas,
              selectedId: wide ? openId : null,
              onTap: openAreaId,
            ),
          ],
          const _VersionFooter(),
        ],
      ],
    );

    Widget areaPage(_Area a) => _AreaPage(
      key: ValueKey('settings-area-${a.id}'),
      area: a,
      rows: [for (final r in a.rows) r.child],
      showHeader: wide,
    );

    final Widget body;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 380, child: root()),
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(
            child: searching || openArea == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: areaPage(openArea),
                    ),
                  ),
          ),
        ],
      );
    } else {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AnimatedSwitcher(
            duration: AppMotion.of(context, const Duration(milliseconds: 200)),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(
                    child.key == const ValueKey('root') ? -0.06 : 0.06,
                    0,
                  ),
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
            bottom: inArea
                ? null
                : PreferredSize(
                    preferredSize: Size.fromHeight(_aiBusy ? 58 : 54),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
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
    bool ai,
    ValueChanged<String> onOpen,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (visible.isEmpty) {
      return [
        Padding(
          key: const ValueKey('settings-search-empty'),
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 42, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                ai
                    ? l10n.settingsAiSearchEmpty
                    : l10n.settingsSearchEmpty(_query.trim()),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }
    return [
      if (ai)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.settingsAiSearchFound,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: scheme.primary),
              ),
            ],
          ),
        ),
      for (final e in visible) ...[
        _CategoryTile(
          area: e.area,
          compact: true,
          onTap: () {
            _searchController.clear();
            setState(() {
              _query = '';
              _aiKeys = null;
            });
            onOpen(e.area.id);
          },
        ),
        _RowsCard(rows: e.rows),
        const SizedBox(height: 12),
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
      (title: l10n.settingsGroupAccount, areas: pick(['account', 'friends'])),
      (
        title: l10n.settingsGroupApp,
        areas: pick(['appearance', 'personalize', 'notes', 'sound', 'ai']),
      ),
      (title: l10n.settingsGroupData, areas: pick(['sync', 'permissions'])),
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

  /// Tepedeki sabit arama kutusu: metin araması ya da (✨ açıkken) AI kipi.
  Widget _searchBar(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasText = _query.trim().isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          decoration: BoxDecoration(
            color: _aiMode
                ? scheme.primaryContainer.withValues(alpha: 0.45)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _aiMode
                  ? scheme.primary.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
          child: Row(
            children: [
              Icon(
                _aiMode ? Icons.auto_awesome : Icons.search,
                size: 19,
                color: _aiMode ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('settings-search'),
                  controller: _searchController,
                  textInputAction: _aiMode
                      ? TextInputAction.search
                      : TextInputAction.done,
                  onChanged: (v) => setState(() {
                    _query = v;
                    // Cümle değişince eski AI sonucu geçersiz.
                    if (_aiMode) _aiKeys = null;
                  }),
                  onSubmitted: (_) {
                    if (_aiMode) unawaited(_runAiSearch());
                  },
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _aiMode
                        ? l10n.settingsAiSearchHint
                        : l10n.settingsSearchHint,
                    hintStyle: TextStyle(
                      fontSize: 13.5,
                      color: scheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (hasText)
                IconButton(
                  // Etiketsiz simge düğmesi ekran okuyucuda "düğme"
                  // diye okunuyordu; ipucu hem imleç üstünde hem
                  // TalkBack'te ne yaptığını söyler.
                  tooltip: l10n.clearSearch,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                      _aiKeys = null;
                    });
                  },
                ),
              if (_aiMode && hasText)
                TextButton(
                  key: const ValueKey('settings-ai-search-go'),
                  onPressed: _aiBusy ? null : _runAiSearch,
                  child: Text(l10n.settingsAiSearchGo),
                ),
              // compact = 40 dp görünüm; dokunma alanı 48 dp (F15.4).
              MinTapTarget(
                child: IconButton(
                  key: const ValueKey('settings-ai-search'),
                  tooltip: l10n.settingsAiSearch,
                  isSelected: _aiMode,
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: _aiMode ? scheme.primary : null,
                    foregroundColor: _aiMode
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  onPressed: () => setState(() {
                    _aiMode = !_aiMode;
                    _aiKeys = null;
                  }),
                ),
              ),
            ],
          ),
        ),
        if (_aiBusy)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  /// AI kipinde cümleyi ayar kataloğuyla eşler.
  Future<void> _runAiSearch() async {
    if (!ensureAiReady(context, ref)) return;
    final text = _query.trim();
    if (text.isEmpty || _aiBusy) return;
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final catalog = _catalog;
    final keys = _catalogKeys;
    setState(() => _aiBusy = true);
    try {
      final hits = await ref
          .read(geminiServiceProvider)
          .matchSettings(text, catalog);
      if (!mounted) return;
      setState(() => _aiKeys = {for (final i in hits) keys[i]});
    } on GeminiException catch (e) {
      messenger.showMessage(aiErrorText(l10n, e));
    } catch (e) {
      messenger.showMessage(aiErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _aiBusy = false);
    }
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

  // Sırası `_BuiltInAiStatus` ile aynı: misafire ve kendi anahtarı olana "ücretsiz
  // puan" denmez (cihaz turu 2026-11-01: misafir özeti "kalan puan 30" diyordu).
  String _aiSummary(AppLocalizations l10n) {
    final remaining = ref.watch(freeAiRemainingProvider);
    if ((ref.watch(activeApiKeyProvider).value ?? '').isNotEmpty) {
      return l10n.aiBuiltInByok;
    }
    if (ref.watch(isAnonymousProvider)) return l10n.guestAiTitle;
    return (ref.watch(premiumProvider).value ?? false)
        ? l10n.aiBuiltInPremium(remaining)
        : l10n.aiBuiltInRemaining(remaining);
  }

  String _appearanceSummary(AppLocalizations l10n) {
    final theme = switch (ref.watch(themeChoiceProvider)) {
      AppThemeChoice.system => l10n.themeSystem,
      AppThemeChoice.sage => l10n.themeSage,
      AppThemeChoice.porcelain => l10n.themePorcelain,
      AppThemeChoice.clay => l10n.themeClay,
      AppThemeChoice.lavender => l10n.themeLavender,
      AppThemeChoice.olive => l10n.themeOlive,
      AppThemeChoice.white => l10n.themeWhite,
      AppThemeChoice.straw => l10n.themeStraw,
      AppThemeChoice.cream => l10n.themeCream,
      AppThemeChoice.peach => l10n.themePeach,
      AppThemeChoice.mint => l10n.themeMint,
      AppThemeChoice.ocean => l10n.themeOcean,
      AppThemeChoice.rose => l10n.themeRose,
      AppThemeChoice.tangerine => l10n.themeTangerine,
      AppThemeChoice.emerald => l10n.themeEmerald,
      AppThemeChoice.amethyst => l10n.themeAmethyst,
      AppThemeChoice.classic => l10n.themeClassic,
      AppThemeChoice.newsprint => l10n.themeNewsprint,
      AppThemeChoice.notebook => l10n.themeNotebook,
      AppThemeChoice.graphite => l10n.themeGraphite,
      AppThemeChoice.ledger => l10n.themeLedger,
      AppThemeChoice.dark => l10n.themeDark,
    };
    // Yüzde yerine KADEME ADI: ayar artık dört adlı seçenekten ibaret,
    // özet satırında "%107" görmek kullanıcıya hiçbir şey anlatmıyordu.
    final size = switch (nearestFontScaleStep(ref.watch(fontScaleProvider))) {
      FontScaleStep.small => l10n.fontSizeSmall,
      FontScaleStep.medium => l10n.fontSizeMedium,
      FontScaleStep.large => l10n.fontSizeLarge,
      FontScaleStep.xlarge => l10n.fontSizeXLarge,
    };
    return '$theme · $size · ${ref.watch(appFontProvider)}';
  }

  /// Okuma HIZI ozete girmiyor: hiz motordan asenkron okunuyor
  /// (speechOutputProvider.rate()), ozet satiri ise senkron bir String
  /// istiyor. Yaninda bekleyen bir "%100" yazmaktansa yalniz dugme modunu
  /// gosteriyorum.
  String _soundSummary(AppLocalizations l10n) {
    final engine = switch (ref.watch(ttsEngineProvider)) {
      TtsEngine.device => l10n.ttsEngineDevice,
      TtsEngine.gemini => l10n.ttsEngineAi,
      TtsEngine.antalia => l10n.ttsEngineLocal,
    };
    final mode = ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold
        ? l10n.voiceModeHold
        : l10n.voiceModeTap;
    return '${l10n.listen}: $engine · ${l10n.liveDictation}: $mode';
  }
}
