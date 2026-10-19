import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart'
    show AuthCredential, FirebaseAuth, FirebaseAuthException;
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/search_fold.dart';
import '../../../app/theme/note_colors.dart';
import '../../ai/data/attachment_text_index.dart';
import '../../../core/crash_reporting.dart';
import '../../../core/error_log.dart';
import '../../../core/constants.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/personalize.dart';
import 'personalize_screen.dart' show PersonalizeModuleSwitches;
import '../../../core/utils/doc_picker.dart';
import '../../../core/widgets/pop_in.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/language_names.dart';
import '../../../core/utils/note_fonts.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/speech_output.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/ai_speech.dart';
import '../../ai/data/ai_provider.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/model_catalog.dart';
import '../../ai/data/firebase_ai_client.dart';
import '../../ai/data/gemini_service.dart';
import '../../auth/data/account_service.dart';
import '../../auth/presentation/auth_errors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../friends/data/friends_repository.dart';
import '../../inbox/data/inbox_repository.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/notes_providers.dart' show swipeModeProvider;
import '../../notes/data/drive_store.dart';
import '../../notes/presentation/drive_ui.dart';
import '../data/permissions_service.dart';
import '../settings_providers.dart';
import 'notes_settings.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/press_scale.dart';

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
  /// Kalici DEGIL - her acilista "Gorunum" acik gelir (en sik dokunulan).
  late String _open = widget.initialArea ?? 'appearance';
  String _query = '';
  final _searchController = TextEditingController();

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
        summary: '',
        keywords: 'cikis hesap sil e-posta',
        rows: [
          _SettingRow(
            const _AccountSection(),
            title: l10n.account,
            keywords: 'cikis hesap sil e-posta ${l10n.deleteAccount}',
          ),
        ],
      ),
      // Kullanıcı isteği 2026-08-18: "kişiler kullanıcıya dışarıdan
      // belirleyebilmeli" — arkadaş ekleme ve klasör paylaşımının girişi
      // buradan da erişilebilir (asıl giriş klasör ⋮ menüsündeki "Paylaş").
      _Area(
        id: 'friends',
        icon: Icons.people_outline,
        title: l10n.friendsTitle,
        summary: '',
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
        icon: Icons.palette_outlined,
        title: l10n.settingsAppearance,
        summary: _appearanceSummary(l10n),
        keywords: 'tema yazi boyutu zemin koyu acik kagit liste',
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
                'tema ${l10n.themeSystem} ${l10n.themeLight} '
                '${l10n.themeDark} ${l10n.themePaper}',
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
                '${l10n.fontSizeLarge} ${l10n.fontSizeXLarge}',
          ),
          _SettingRow(_SubHeader(l10n.settingsCardsHeader)),
          _SettingRow(
            const _ExpandListItemsSwitch(),
            title: l10n.expandListItems,
            keywords: l10n.expandListItemsInfo,
          ),
          _SettingRow(
            const _CardRichPreviewSwitch(),
            title: l10n.cardRichPreview,
            keywords: '${l10n.cardRichPreviewInfo} renk alti cizili kalin',
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
      // KİŞİSELLEŞTİR (kullanıcı isteği 2026-10-16): asıl ekran ayrı
      // (`/personalize`); bu alan aramada bulunsun ve özet versin diye.
      _Area(
        id: 'personalize',
        icon: Icons.tune_rounded,
        title: l10n.personalizeTitle,
        summary: _personalizeSummary(l10n),
        keywords:
            'kisisellestir gizle goster eklenti duzenleme modu dugme alan '
            'arti menu ekle video sarma saniye ileri geri',
        rows: [
          _SettingRow(
            ListTile(
              key: const ValueKey('settings-personalize-row'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.extension_outlined),
              title: Text(l10n.personalizeOpen),
              subtitle: Text(l10n.personalizeInfo),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await context.push<String>('/personalize');
                if (result == 'edit' && context.mounted) context.pop();
              },
            ),
            title: l10n.personalizeTitle,
            keywords:
                '${l10n.personalizeModules} ${l10n.personalizeQuickAdd} '
                '${l10n.videoSeekBack} ${l10n.videoSeekForward}',
          ),
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
        summary: swipeModeLabel(context, ref.watch(swipeModeProvider)),
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
            const CaptureModeSetting(),
            title: l10n.captureModeSetting,
            keywords:
                '${l10n.captureModeBubbles} ${l10n.captureModeClassic} '
                'balonlu klasik kip',
          ),
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
        title: l10n.settingsSpeech,
        summary: _soundSummary(l10n),
        keywords: 'mikrofon ses okuma hiz dil basili tut',
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
          _SettingRow(
            const _LanguageSelector(),
            title: l10n.settingsLanguage,
            keywords: 'dil language uygulama dili',
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
        ],
      ),
    ];

    final query = foldForSearch(_query.trim());
    final visible = [
      for (final a in areas)
        if (a.visible(query)) a,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              14,
              12,
              14,
              16 + MediaQuery.paddingOf(context).bottom + 48,
            ),
            children: [
              const _ProfileCard(),
              const SizedBox(height: 8),
              // KISAYOL KARTLARI (kullanıcı isteği 2026-10-16: "ayarların
              // toparlanması, görsel ve özellik olarak geliştirilmesi"):
              // KULLANIM KILAVUZU (ayar arayan çoğu zaman bir özelliğin
              // nasıl kullanıldığını arıyor), KİŞİSELLEŞTİR (hangi alan ve
              // düğme görünsün — eklentiler) ve DÜZENLEME MODU (ekranların
              // kendisinde gizle/göster) en üstte, yan yana.
              _ShortcutTiles(
                tiles: [
                  _ShortcutTile(
                    key: const ValueKey('settings-guide'),
                    icon: Icons.menu_book_outlined,
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
                      // Kişiselleştir'den düzenleme modu başlatıldıysa
                      // ayarlar da kapanır: kullanıcı düzenleyeceği ekrana
                      // iner.
                      if (result == 'edit' && context.mounted) context.pop();
                    },
                  ),
                  _ShortcutTile(
                    key: const ValueKey('settings-edit-mode'),
                    icon: Icons.touch_app_outlined,
                    title: l10n.customizeModeTitle,
                    subtitle: l10n.customizeModeShort,
                    color: scheme.tertiary,
                    onTap: () {
                      Personalize.startEditing();
                      context.pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ayar arama: alan basliklarinda ve anahtar kelimelerde arar.
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 19,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: l10n.settingsSearchHint,
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
                    if (query.isNotEmpty)
                      IconButton(
                        // Etiketsiz simge düğmesi ekran okuyucuda "düğme"
                        // diye okunuyordu; ipucu hem imleç üstünde hem
                        // TalkBack'te ne yaptığını söyler.
                        tooltip: l10n.clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 42,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.settingsSearchEmpty(_query.trim())),
                    ],
                  ),
                )
              else
                for (final area in visible)
                  _SettingsArea(
                    area: area,
                    // Arama sirasinda yalnizca ESLESEN satirlar cizilir;
                    // "hiz" arayan kullanici Ses alaninin tamamini degil iki
                    // hiz kaydiricisini gorur.
                    rows: area.visibleRows(query),
                    // Arama sirasinda eslesen alanlar acik gelir: kullanici
                    // buldugu seyi bir de elle acmak zorunda kalmasin.
                    open: query.isNotEmpty || _open == area.id,
                    onTap: () =>
                        setState(() => _open = _open == area.id ? '' : area.id),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kaç öğe gizli + sarma süreleri ("3 gizli · ⏪10 ⏩10 sn").
  String _personalizeSummary(AppLocalizations l10n) {
    final p = Personalize.prefs.value;
    final seek =
        '${l10n.videoSeekBack} ${l10n.secondsShort(p.seekBack)} · '
        '${l10n.videoSeekForward} ${l10n.secondsShort(p.seekForward)}';
    return p.hidden.isEmpty
        ? seek
        : '${l10n.personalizeHiddenSummary(p.hidden.length)} · $seek';
  }

  String _aiSummary(AppLocalizations l10n) =>
      l10n.aiBuiltInRemaining(ref.watch(freeAiRemainingProvider));

  String _appearanceSummary(AppLocalizations l10n) {
    final theme = switch (ref.watch(themeChoiceProvider)) {
      AppThemeChoice.system => l10n.themeSystem,
      AppThemeChoice.light => l10n.themeLight,
      AppThemeChoice.dark => l10n.themeDark,
      AppThemeChoice.paper => l10n.themePaper,
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
  String _soundSummary(AppLocalizations l10n) =>
      ref.watch(voiceButtonModeProvider) == VoiceButtonMode.hold
      ? l10n.voiceModeHold
      : l10n.voiceModeTap;
}
