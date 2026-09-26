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

import '../../../app/theme/note_colors.dart';
import '../../ai/data/attachment_text_index.dart';
import '../../../core/constants.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/doc_picker.dart';
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
import '../data/permissions_service.dart';
import '../settings_providers.dart';
import 'notes_settings.dart';

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
  void dispose() {
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
            const _QuickCaptureRowSwitch(),
            title: l10n.quickCaptureRowSetting,
            keywords: l10n.quickCaptureRowInfo,
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

    final query = _query.trim().toLowerCase();
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

/// Ayarlar alaninin tanimi. Arama hem baslikta hem [keywords] icinde arar:
/// kullanici "mikrofon" yazinca hem Izinler hem Ses alani cikmali.
/// Alanin icindeki TEK bir ayar satiri.
///
/// Eskiden alanlar duz `List<Widget>` tasiyordu ve arama yalnizca ALAN
/// basligina bakiyordu: "hiz" arayan kullaniciya Ses alaninin tamami aciliyor,
/// aradigi satiri yine gozle bulmasi gerekiyordu. Satirin aranabilir bir
/// tanimi olunca suzme satir satir yapilabiliyor.
class _SettingRow {
  const _SettingRow(this.child, {this.title = '', this.keywords = ''});

  final Widget child;

  /// Satirin ekranda gorunen basligi (l10n'dan) — ayni metin arandiginda
  /// eslessin diye burada tekrarlanir.
  final String title;

  /// Baslikta gecmeyen ama kullanicinin arayabilecegi kelimeler.
  final String keywords;

  bool matches(String query) =>
      title.toLowerCase().contains(query) ||
      keywords.toLowerCase().contains(query);
}

class _Area {
  const _Area({
    required this.id,
    required this.icon,
    required this.title,
    required this.summary,
    required this.keywords,
    required this.rows,
  });

  final String id;
  final IconData icon;
  final String title;
  final String summary;
  final String keywords;
  final List<_SettingRow> rows;

  bool matches(String query) =>
      title.toLowerCase().contains(query) ||
      summary.toLowerCase().contains(query) ||
      keywords.toLowerCase().contains(query);

  /// Sorguda gorunecek satirlar.
  ///
  /// ALANIN KENDISI eslesiyorsa (kullanici "ses" yazdi) alanin TUM satirlari
  /// gosterilir — bolumun adini arayan kisi bolumun tamamini ister. Alan
  /// eslesmiyorsa yalnizca eslesen satirlar kalir.
  List<Widget> visibleRows(String query) {
    if (query.isEmpty || matches(query)) return [for (final r in rows) r.child];
    return [
      for (final r in rows)
        if (r.matches(query)) r.child,
    ];
  }

  /// Alan listede hic gorunmeli mi: kendisi ya da bir satiri eslesiyorsa.
  bool visible(String query) =>
      query.isEmpty || matches(query) || rows.any((r) => r.matches(query));
}

/// Akordeon alan: kapaliyken baslik + DURUM OZETI, acikken icerik.
///
/// Ozet satiri tasarimin asil fikri: kullanici alani acmadan "tema kagit,
/// yazi %100" gibi guncel durumu okuyabiliyor.
class _SettingsArea extends StatelessWidget {
  const _SettingsArea({
    required this.area,
    required this.rows,
    required this.open,
    required this.onTap,
  });

  final _Area area;

  /// Cizilecek satirlar — aramada suzulmus olabilir (bkz. [_Area.visibleRows]).
  final List<Widget> rows;

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: open ? scheme.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      area.icon,
                      size: 21,
                      color: open ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            area.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (area.summary.isNotEmpty)
                            Text(
                              area.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        Icons.expand_more,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                // DERLİ TOPLU SATIRLAR (kullanıcı isteği 2026-09-26: ekran
                // görüntüsündeki alanlar "görsel ve işlevsel olarak
                // geliştirilsin"). Anahtar satırlarının başlığı gövde
                // metninden BÜYÜK, açıklaması başlık kadar iriydi; uzun
                // açıklamalı beş satır ekranı dolduruyordu. Başlık 14/w600,
                // açıklama küçük ve soluk — göz önce başlığı tarar.
                child: ListTileTheme.merge(
                  dense: true,
                  titleTextStyle: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  subtitleTextStyle: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// _SettingsGroup (basliksiz kart grubu) kaldirildi: yerini akordeon
// _SettingsArea aldi, dokuz grup alti alana indi.

/// "Kişiler" alanının tek satırı: arkadaş listesine/isteklere götürür.
/// Yerel (anonim) hesapta e-posta olmadığı için özellik anlamsız —
/// `openFriendsScreenOrExplain` dokununca bunu açıklar.
class _FriendsRow extends ConsumerWidget {
  const _FriendsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requestCount =
        ref.watch(incomingFriendRequestsProvider).value?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.people_outline),
      title: Text(l10n.friendsTitle),
      subtitle: Text(l10n.friendsRowInfo),
      trailing: requestCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$requestCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => openFriendsScreenOrExplain(context, ref),
    );
  }
}

/// "Gelen notlar" satırı — bir arkadaşın GÖNDERDİĞİ, henüz kabul edilmemiş
/// notlar (kullanıcı isteği 2026-08-18: "paylaşılan not alıcıda farklı gelen
/// notlar klasöründe görülsün").
class _InboxRow extends ConsumerWidget {
  const _InboxRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(inboxNotesProvider).value?.length ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.move_to_inbox_outlined),
      title: Text(l10n.inboxTitle),
      subtitle: Text(l10n.inboxEmptyHint),
      trailing: count > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => InboxScreen.open(context),
    );
  }
}

/// Ayarların en üstündeki kimlik kartı: avatar, ad, e-posta ve senkron durumu.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).value;
    // Yerel (anonim) hesabın adı da e-postası da yok; kart adsız kalmasın —
    // kullanıcı hangi hesap türünde olduğunu buradan görür.
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.trim().isNotEmpty ?? false)
        ? user!.email!
        : (ref.watch(isAnonymousProvider) ? l10n.localAccountBadge : '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person_outline)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if ((user?.email ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                // Anonim hesapta "Senkronize edildi" YANILTICIYDI: veri başka
                // cihazdan açılamaz ve hesap kaybolursa geri gelmez. Rozet
                // gerçeği söyler; ayrıntısı alttaki yerel hesap kartında.
                Row(
                  children: [
                    Icon(
                      ref.watch(isAnonymousProvider)
                          ? Icons.smartphone
                          : Icons.cloud_done_outlined,
                      size: 14,
                      color: ref.watch(isAnonymousProvider)
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      ref.watch(isAnonymousProvider)
                          ? l10n.localAccountBadge
                          : l10n.synced,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uygulamanın düzgün çalışması için gereken izinleri gösterir ve ister.
/// Sistem ayarından dönüldüğünde (resume) durum kendiliğinden tazelenir.
class _PermissionsSection extends ConsumerStatefulWidget {
  const _PermissionsSection();

  @override
  ConsumerState<_PermissionsSection> createState() =>
      _PermissionsSectionState();
}

class _PermissionsSectionState extends ConsumerState<_PermissionsSection>
    with WidgetsBindingObserver {
  bool? _mic;
  bool? _camera;
  bool? _notifications;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı sistem izin ekranından dönünce yeni durumu göster.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final service = ref.read(permissionsServiceProvider);
    final mic = await service.micGranted();
    final camera = await service.cameraGranted();
    final notifications = await service.notificationsGranted();
    if (mounted) {
      setState(() {
        _mic = mic;
        _camera = camera;
        _notifications = notifications;
      });
    }
  }

  Future<void> _requestCamera() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestCamera();
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  Future<void> _requestMic() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestMic();
    // İstek dönüşü false ise izin kalıcı reddedilmiş olabilir; kullanıcının
    // elle açabilmesi için sistem ayarına yönlendir.
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  Future<void> _requestNotifications() async {
    final service = ref.read(permissionsServiceProvider);
    final ok = await service.requestNotifications();
    if (!ok) await service.openAppSettings();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = ref.read(permissionsServiceProvider);
    return Column(
      children: [
        _PermissionTile(
          icon: Icons.mic_none,
          title: l10n.permMic,
          subtitle: l10n.permMicInfo,
          granted: _mic,
          onAction: _requestMic,
        ),
        _PermissionTile(
          icon: Icons.videocam_outlined,
          title: l10n.permCamera,
          subtitle: l10n.permCameraInfo,
          granted: _camera,
          onAction: _requestCamera,
        ),
        _PermissionTile(
          icon: Icons.notifications_none,
          title: l10n.permNotifications,
          subtitle: l10n.permNotificationsInfo,
          granted: _notifications,
          onAction: _requestNotifications,
        ),
        // Pil muafiyeti durumu güvenilir okunamadığından her zaman "Ayarları
        // aç" gösterir; kullanıcı uygulamayı pil kısıtlamasından muaf tutar.
        _PermissionTile(
          icon: Icons.battery_saver_outlined,
          title: l10n.permBattery,
          subtitle: l10n.permBatteryInfo,
          granted: null,
          actionLabel: l10n.permOpenSettings,
          onAction: service.openBatterySettings,
        ),
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onAction,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// true = verildi, false = reddedildi, null = durum okunamıyor (muafiyet).
  final bool? granted;
  final Future<void> Function() onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isGranted = granted == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.permGranted,
                  style: TextStyle(color: Colors.green.shade600, fontSize: 12),
                ),
              ],
            )
          else
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel ?? context.l10n.permGrant),
            ),
        ],
      ),
    );
  }
}

/// Uygulama dili. Dil adları kendi dillerinde yazılır ("English"), yoksa
/// dilini bilmediği bir arayüzde doğru satırı bulamayan kullanıcı sıkışır.
/// Dil seçimi.
///
/// Az sayıda dilde radyo listesi en hızlı yol; liste büyüyünce (hedef 100+)
/// aynı düzen kullanılamaz — ayarlar sayfası yüz satırla dolar ve kullanıcı
/// kendi dilini kaydırarak arar. Bu yüzden eşiği aşınca ARAMALI bir alt
/// sayfaya geçilir. İki ayrı ekran yazmak yerine eşik konuldu: dört dilde
/// arama kutusu göstermek de gereksiz sürtünmedir.
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  /// Üzerinde aramalı sayfaya geçilen dil sayısı.
  static const _inlineLimit = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 'system' yer tutucu: RadioGroup null'ı "seçim yok" saydığından sistem
    // seçeneği null değerle temsil edilemez.
    const system = 'system';
    final languages = supportedLanguages;
    final selected = ref.watch(localeProvider)?.toLanguageTag();
    final current = selected ?? system;

    if (languages.length > _inlineLimit) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(context.l10n.settingsLanguage),
        subtitle: Text(
          selected == null
              ? context.l10n.languageSystem
              : languageLabel(selected),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _pick(context, ref, languages, selected),
      );
    }

    return RadioGroup<String>(
      groupValue: current,
      onChanged: (value) =>
          ref.read(localeProvider.notifier).set(value == system ? null : value),
      child: Column(
        children: [
          RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: system,
            title: Text(context.l10n.languageSystem),
          ),
          for (final entry in languages.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: entry.key,
              title: Text(entry.value),
            ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    Map<String, String> languages,
    String? selected,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _LanguageSheet(languages: languages, selected: selected),
    );
    if (choice == null) return;
    ref.read(localeProvider.notifier).set(choice == 'system' ? null : choice);
  }
}

class _LanguageSheet extends StatefulWidget {
  const _LanguageSheet({required this.languages, required this.selected});

  final Map<String, String> languages;
  final String? selected;

  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<_LanguageSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Arama hem dilin KENDİ adında hem de kodunda yapılır: kullanıcı
  /// "日本語" yazamıyorsa "ja" yazabilmeli. Büyük/küçük harf yok sayılır;
  /// `toLowerCase` Türkçe'nin I/ı çiftinde bile burada güvenli, çünkü
  /// karşılaştırma iki tarafta da aynı dönüşümden geçiyor.
  bool _matches(MapEntry<String, String> entry) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return entry.value.toLowerCase().contains(q) ||
        entry.key.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches = widget.languages.entries.where(_matches).toList();
    return Padding(
      // Klavye açılınca liste kısalsın, arama kutusu klavyenin altında kalmasın.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.settingsLanguage,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (_query.isEmpty)
                    ListTile(
                      title: Text(l10n.languageSystem),
                      trailing: widget.selected == null
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, 'system'),
                    ),
                  for (final entry in matches)
                    ListTile(
                      title: Text(entry.value),
                      subtitle: Text(entry.key),
                      trailing: entry.key == widget.selected
                          ? const Icon(Icons.check)
                          : null,
                      onTap: () => Navigator.pop(context, entry.key),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Görünüm ayarlarının CANLI örneği: seçilen tema, yazı tipi ve yazı boyutu
/// gerçek bir notun görünümünde birlikte gösterilir.
///
/// Kullanıcı isteği 2026-08-16: "görünüm ayarlarına örnek metin". Eskiden tek
/// satırlık bir yazı boyutu önizlemesi vardı ([_TypographySection] içinde) ve
/// yalnız BOYUTU gösteriyordu; başlığın gövdeden ne kadar büyük olduğu, satır
/// içi biçimlerin (kalın, vurgu, altı çizili) seçilen yazı tipinde nasıl
/// durduğu, madde satırlarının nasıl göründüğü ancak notu açınca anlaşılıyordu.
///
/// Önizleme gerçek çizim yollarını kullanır — [richSpans] ile satır içi
/// biçimler, [applyNoteFont] ile yazı tipi, not paleti ile renkler. Kendi
/// başına bir "örnek görünüm" çizilseydi ayarların gerçek sonucundan
/// ayrışırdı.
class _AppearancePreview extends ConsumerWidget {
  const _AppearancePreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final font = ref.watch(appFontProvider);
    final step = nearestFontScaleStep(ref.watch(fontScaleProvider));

    TextStyle styled(TextStyle? base) =>
        applyNoteFont(base ?? const TextStyle(), font);

    // Örneğin KENDİSİ sistem yazı ölçeğinden muaf; ayarın kendi kademesini
    // uygular ([_TypographySection]'daki önizlemeyle aynı gerekçe: seçici
    // büyüyünce satır taşıyordu).
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appearancePreviewNoteTitle,
              textScaler: TextScaler.linear(step.scale),
              style: styled(
                theme.textTheme.titleMedium,
              ).copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: richSpans(
                  l10n.appearancePreviewBody,
                  styled(
                    theme.textTheme.bodyMedium,
                  ).copyWith(color: scheme.onSurface),
                  palette: NoteColors.richPalette,
                  markerColor: const Color(0x00000000),
                ),
              ),
              textScaler: TextScaler.linear(step.scale),
            ),
            const SizedBox(height: 8),
            // Madde satırı: liste notlarının görünümü de yazı tipinden
            // etkileniyor, örnek onu da kapsamalı.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_box_outlined,
                  size: 16 * step.scale,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.appearancePreviewItem,
                    textScaler: TextScaler.linear(step.scale),
                    style: styled(
                      theme.textTheme.bodyMedium,
                    ).copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  /// TEMA KARTLARI (kullanıcı isteği 2026-09-26, ekran görüntüsü): eski
  /// seçici dört ETİKETSİZ simgeydi — telefon genişliğinde etiketler sığmadığı
  /// için düşüyordu ve "kitap" simgesinin Kağıt tema olduğu anlaşılmıyordu.
  /// Artık her seçenek küçük bir ÖNİZLEME (o temanın zemini, kartı ve yazı
  /// rengi) + altında adı; seçili kart birincil renkle çerçevelenir.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(themeChoiceProvider);
    final font = ref.watch(appFontProvider);
    final light = AppTheme.light(font: font).colorScheme;
    final dark = AppTheme.dark(font: font).colorScheme;
    final paper = AppTheme.paper(font: font).colorScheme;
    final options = <(AppThemeChoice, String, List<ColorScheme>)>[
      (AppThemeChoice.system, l10n.themeSystem, [light, dark]),
      (AppThemeChoice.light, l10n.themeLight, [light]),
      (AppThemeChoice.dark, l10n.themeDark, [dark]),
      (AppThemeChoice.paper, l10n.themePaper, [paper]),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ThemeCard(
              label: options[i].$2,
              schemes: options[i].$3,
              selected: choice == options[i].$1,
              onTap: () =>
                  ref.read(themeChoiceProvider.notifier).set(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tek tema seçeneği: mini önizleme + ad. [schemes] iki tane ise (Sistem)
/// önizleme ortadan açık/koyu ikiye bölünür.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.schemes,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final List<ColorScheme> schemes;
  final bool selected;
  final VoidCallback onTap;

  Widget _preview(ColorScheme c) => ColoredBox(
    color: c.surface,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 22, height: 4, color: c.onSurface),
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 3,
                color: c.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 3),
              Container(width: 18, height: 3, color: c.primary),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        for (final c in schemes)
                          Expanded(child: _preview(c)),
                      ],
                    ),
                    if (selected)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: scheme.primary,
                          child: Icon(
                            Icons.check,
                            size: 11,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? scheme.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uzun bir ayar alanının içindeki küçük bölüm başlığı (Tema, Kartlar ve
/// listeler…). Aramada gizlenir (başlığı/anahtar kelimesi yok): arama tek
/// tek satırları getirir.
class _SubHeader extends StatelessWidget {
  const _SubHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 14, 0, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
  );
}

/// Sesli Not Asistanı düğmesinin kullanım şekli: basılı tut (varsayılan)
/// veya bas-başlat / bas-bitir.
class _VoiceModeSelector extends ConsumerWidget {
  const _VoiceModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(voiceButtonModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.voiceModeSetting),
        const SizedBox(height: 8),
        SegmentedButton<VoiceButtonMode>(
          segments: [
            ButtonSegment(
              value: VoiceButtonMode.hold,
              label: Text(l10n.voiceModeHold),
              icon: const Icon(Icons.touch_app_outlined),
            ),
            ButtonSegment(
              value: VoiceButtonMode.tap,
              label: Text(l10n.voiceModeTap),
              icon: const Icon(Icons.play_circle_outline),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (selection) =>
              ref.read(voiceButtonModeProvider.notifier).set(selection.first),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.voiceModeInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Yazı boyutu çarpanı.
///
/// KÖK NEDEN (kaydırıcı parmağın altından kaçıyordu): `fontScaleProvider`
/// `app.dart`'ta TÜM uygulamanın `textScaler`'ını sürüyor. Her `onChanged`
/// anında yazılınca Ayarlar'ın kendisi de yeniden boyutlanıyor: kaydırıcının
/// ÜSTÜNDEKİ satırlar uzayıp kısaldığı için kaydırıcı dikeyde kayıyor, "%100"
/// → "%95" etiketi daraldığı için de yatayda. İki önlem birlikte gerekiyor:
///  1. gerçek ayar yalnız parmak KALKINCA yazılır (`onChangeEnd`); sürüklerken
///     değer yerelde tutulur, böylece hiçbir şey yeniden akmaz,
///  2. denetimin kendisi ölçekten muaf (`withNoTextScaling`) ve yüzde etiketi
///     sabit genişlikte — yoksa yazılan değer denetimi kendi altından kaydırır.
/// Canlı geri bildirim kaybolmasın diye altta sabit yükseklikte bir önizleme
/// satırı sürüklenen değerle ölçeklenir (yüksekliği sabit olduğundan
/// büyümesi üstteki kaydırıcıyı oynatmaz).

/// TİPOGRAFİ TEK BLOKTA: yazı tipi + yazı boyutu + ORTAK önizleme.
///
/// KÖK NEDEN (kullanıcı: "ayarlarda font seçimi vs çok dağınık"): Görünüm
/// alanı iki ayrı kartla açılıyordu ve ikincisi katalogdaki **19 yazı tipini
/// çip çip ekrana seriyordu** — tek başına dört-beş satır kaplayan, altındaki
/// bütün ayarları (liste, hızlı not, kart önizlemesi, zemin, koyu tema
/// zamanlaması) aşağı iten bir duvar. Üstelik her iki kartın da kendi
/// önizlemesi/açıklaması vardı; "yazı" ile ilgili tek bir iş iki yere
/// bölünmüştü.
///
/// Artık tek satır: yazı tipi bir SATIR (seçilen adı kendi yazı tipiyle
/// gösterir, dokununca öbeklenmiş bir levha açar), yazı boyutu dört kademe,
/// altta ikisini birlikte gösteren tek önizleme.
class _TypographySection extends ConsumerWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final font = ref.watch(appFontProvider);
    final step = nearestFontScaleStep(ref.watch(fontScaleProvider));
    final bodyStyle = theme.textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.text_fields, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.appFontSetting)),
          ],
        ),
        const SizedBox(height: 8),
        // Yazı tipi satırı: seçili ad KENDİ yazı tipiyle yazılır.
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAppFontSheet(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    font,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: applyNoteFont(
                      const TextStyle(fontSize: 15.5),
                      font,
                    ).copyWith(color: scheme.onSurface),
                  ),
                ),
                Icon(
                  Icons.unfold_more,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.format_size, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.fontSize)),
          ],
        ),
        const SizedBox(height: 8),
        // Seçicinin KENDİSİ ölçeklenmez: "Çok büyük" seçildiğinde düğmelerin
        // de büyümesi satırı taşırıyordu. Önizleme ölçeği kendi uygular.
        MediaQuery.withNoTextScaling(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in FontScaleStep.values)
                ChoiceChip(
                  label: Text(_fontScaleLabel(l10n, value)),
                  selected: value == step,
                  onSelected: (_) =>
                      ref.read(fontScaleProvider.notifier).setStep(value),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ORTAK önizleme: seçilen yazı tipi VE boyut birlikte görünür.
        // Kutu en büyük kademeye göre boyutlanır ki seçim değişince
        // yüksekliği zıplamasın.
        MediaQuery.withNoTextScaling(
          child: SizedBox(
            height:
                (bodyStyle?.fontSize ?? 14) * FontScaleStep.xlarge.scale * 1.6,
            width: double.infinity,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.fontSizePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.linear(step.scale),
                style: applyNoteFont(
                  bodyStyle ?? const TextStyle(),
                  font,
                ).copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.appFontInfo,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Yazı tipi seçme levhası: katalog ÖBEKLENMİŞ (sade / kitap / daktilo /
/// el yazısı) ve her satır kendi yazı tipiyle yazılıyor.
Future<void> _showAppFontSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  String groupLabel(NoteFontGroup group) => switch (group) {
    NoteFontGroup.sans => l10n.fontGroupSans,
    NoteFontGroup.serif => l10n.fontGroupSerif,
    NoteFontGroup.mono => l10n.fontGroupMono,
    NoteFontGroup.hand => l10n.fontGroupHand,
  };
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(appFontProvider);
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Text(
                  l10n.appFontSetting,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final group in NoteFontGroup.values) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Text(
                    groupLabel(group),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                for (final font in kCatalogFonts)
                  if (font.group == group)
                    ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: font.id == current,
                      title: Text(
                        font.id == kAppDefaultFont
                            ? '${font.label} · ${l10n.appFontDefaultSuffix}'
                            : font.label,
                        // Satır aynı zamanda ÖRNEK: seçmeden önce nasıl
                        // duracağı görünür.
                        style: applyNoteFont(
                          const TextStyle(fontSize: 16),
                          font.id,
                        ),
                      ),
                      trailing: font.id == current
                          ? Icon(Icons.check, size: 20, color: scheme.primary)
                          : null,
                      onTap: () =>
                          ref.read(appFontProvider.notifier).set(font.id!),
                    ),
              ],
            ],
          );
        },
      );
    },
  );
}

/// Yazı boyutu kademelerinin görünen adları.
///
/// KÖK NEDEN — eskiden 0.85–1.4 arası sürekli bir KAYDIRICIydı: "%107" gibi
/// hatırlanmayan değerler seçilebiliyor, iki cihazda aynı boyutu tutturmak
/// imkânsız oluyordu (kullanıcı isteği 2026-08-07). Kademeler tek dokunuşla
/// seçiliyor ve her cihazda aynı dört görünümü veriyor. Kaydırıcı döneminden
/// kalan değer en yakın kademede görünür — kimsenin boyutu güncellemede
/// kendiliğinden değişmez.
String _fontScaleLabel(AppLocalizations l10n, FontScaleStep step) =>
    switch (step) {
      FontScaleStep.small => l10n.fontSizeSmall,
      FontScaleStep.medium => l10n.fontSizeMedium,
      FontScaleStep.large => l10n.fontSizeLarge,
      FontScaleStep.xlarge => l10n.fontSizeXLarge,
    };

class _ExpandListItemsSwitch extends ConsumerWidget {
  const _ExpandListItemsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.expandListItems),
      subtitle: Text(l10n.expandListItemsInfo),
      value: ref.watch(expandListItemsProvider),
      onChanged: (value) =>
          ref.read(expandListItemsProvider.notifier).set(value),
    );
  }
}

/// **EK İÇERİĞİNDE ARAMA** (kullanıcı isteği 2026-09-04: "anlamsal arama
/// görsel ve pdf'leri de arayabilir, seçenek olarak sunmalıyız").
///
/// Varsayılan KAPALI: açmak bir kerelik tarama bedeli demek (PDF ayrıştırma
/// + cihaz-içi OCR) — bkz. attachment_text_index.dart.
class _AttachmentSearchSwitch extends ConsumerWidget {
  const _AttachmentSearchSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.searchAttachments),
      subtitle: Text(l10n.searchAttachmentsInfo),
      value: ref.watch(attachmentSearchProvider),
      onChanged: (value) =>
          ref.read(attachmentSearchProvider.notifier).set(value),
    );
  }
}

/// **PAYLAŞILAN KLASÖR BİLDİRİMLERİ** (kullanıcı isteği 2026-09-04:
/// "ayarlardan kapatılabilir olarak"). Kapatmak yalnız telefon bildirimini
/// susturur; ana ekrandaki rozet çalışmaya devam eder.
class _SharedNotificationsSwitch extends ConsumerWidget {
  const _SharedNotificationsSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.sharedNotifications),
      subtitle: Text(l10n.sharedNotificationsInfo),
      value: ref.watch(sharedNotificationsProvider),
      onChanged: (value) =>
          ref.read(sharedNotificationsProvider.notifier).set(value),
    );
  }
}

class _QuickCaptureRowSwitch extends ConsumerWidget {
  const _QuickCaptureRowSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.quickCaptureRowSetting),
      subtitle: Text(l10n.quickCaptureRowInfo),
      value: ref.watch(quickCaptureRowProvider),
      onChanged: (value) =>
          ref.read(quickCaptureRowProvider.notifier).set(value),
    );
  }
}

/// Ana ekrandaki kartlarda satır içi biçim (renk, vurgu, kalın, altı çizili)
/// çizilsin mi? Varsayılan açık; kapatan kullanıcı düz metin önizlemeye döner.
class _CardRichPreviewSwitch extends ConsumerWidget {
  const _CardRichPreviewSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.cardRichPreview),
      subtitle: Text(l10n.cardRichPreviewInfo),
      value: ref.watch(cardRichPreviewProvider),
      onChanged: (value) =>
          ref.read(cardRichPreviewProvider.notifier).set(value),
    );
  }
}

/// Kullanılan bulut depolama alanı: "12,4 MB / 50 MB kullanıldı" + çubuk.
///
/// Tavan olmadan lifetime paketinin maliyeti öngörülemiyordu; tavan konunca
/// kullanıcının nerede olduğunu görebileceği bir yer de gerekti — "ek
/// eklenemiyor" hatasını ilk kez yükleme anında görmek kötü bir sürpriz.
class _StorageUsage extends ConsumerWidget {
  const _StorageUsage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final premium = ref.watch(premiumProvider).value ?? false;
    final quota = premium
        ? AppConstants.maxPremiumStorageBytes
        : AppConstants.maxFreeStorageBytes;
    final used = ref.watch(storageUsedBytesProvider);
    final ratio = (used / quota).clamp(0.0, 1.0);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.storageUsage),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              // Doluya yaklaşınca uyarı rengi: çubuğun kendisi zaten
              // okunuyorsa ayrıca metin okumaya gerek kalmasın.
              color: ratio >= 0.9 ? scheme.error : scheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.storageUsageValue(formatBytes(used), formatBytes(quota))),
        ],
      ),
    );
  }
}

/// Eklerin buluta otomatik yüklenmesi için boyut sınırı seçici.
/// Sınırı aşan dosyalar cihazda kalır (not metni yine senkronlanır).
class _SyncLimitSelector extends ConsumerWidget {
  const _SyncLimitSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(syncLimitMbProvider);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.syncLimitTitle),
      subtitle: Text(l10n.syncLimitInfo),
      trailing: DropdownButton<int>(
        value: SyncLimitMbNotifier.options.contains(value) ? value : 25,
        items: [
          for (final mb in SyncLimitMbNotifier.options)
            DropdownMenuItem(
              value: mb,
              child: Text(mb == 0 ? l10n.syncLimitUnlimited : '$mb MB'),
            ),
        ],
        onChanged: (v) {
          if (v != null) ref.read(syncLimitMbProvider.notifier).set(v);
        },
      ),
    );
  }
}

/// Cihaz sesiyle KISA bir deneme okur.
///
/// Hız/ton kaydırıcıları eskiden sessizdi: kullanıcı değeri değiştiriyor ama
/// nasıl duyulduğunu ancak bir notu açıp okutarak öğreniyordu (kullanıcı
/// isteği 2026-08-09: "hızı tonu sesi tipi seçince test sesi gelmeli").
/// Cihaz TTS'i yerel ve bedava — burada kota kaygısı yok.
void _previewDeviceVoice(BuildContext context, WidgetRef ref) {
  final language = Localizations.localeOf(context).languageCode;
  unawaited(
    ref
        .read(speechOutputProvider.notifier)
        .speak(
          SpeechOutputController.voiceSample(language),
          languageCode: language,
        ),
  );
}

class _SpeechRateSlider extends ConsumerStatefulWidget {
  const _SpeechRateSlider();

  @override
  ConsumerState<_SpeechRateSlider> createState() => _SpeechRateSliderState();
}

class _SpeechRateSliderState extends ConsumerState<_SpeechRateSlider> {
  double? _rate;

  @override
  void initState() {
    super.initState();
    ref.read(speechOutputProvider.notifier).rate().then((value) {
      if (mounted) setState(() => _rate = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;
    if (rate == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(context.l10n.speechRate),
          Expanded(
            child: Slider(
              value: rate,
              min: 0.2,
              max: 1,
              divisions: 8,
              label: '${(rate * 2).toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _rate = value),
              onChangeEnd: (value) async {
                await ref.read(speechOutputProvider.notifier).setRate(value);
                if (context.mounted) _previewDeviceVoice(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Yabancı diller (Türkçe dışı) için ayrı okuma hızı: çeviri seslendirmesi,
/// İngilizce/Almanca vb. sesli okuma bu hızı kullanır. Motorlar yabancı dili
/// Türkçe'ye göre hızlı okuyabildiğinden ayrı, genelde daha düşük tutulur.
class _ForeignSpeechRateSlider extends ConsumerStatefulWidget {
  const _ForeignSpeechRateSlider();

  @override
  ConsumerState<_ForeignSpeechRateSlider> createState() =>
      _ForeignSpeechRateSliderState();
}

class _ForeignSpeechRateSliderState
    extends ConsumerState<_ForeignSpeechRateSlider> {
  double? _rate;

  @override
  void initState() {
    super.initState();
    ref.read(speechOutputProvider.notifier).foreignRate().then((value) {
      if (mounted) setState(() => _rate = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rate = _rate;
    if (rate == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.speechRateForeign)),
          Expanded(
            flex: 2,
            child: Slider(
              value: rate,
              min: 0.2,
              max: 1,
              divisions: 8,
              label: '${(rate * 2).toStringAsFixed(1)}x',
              onChanged: (value) => setState(() => _rate = value),
              onChangeEnd: (value) async {
                await ref
                    .read(speechOutputProvider.notifier)
                    .setForeignRate(value);
                // Yabancı hız İNGİLİZCE örnekle denenir: Türkçe cümleyi
                // Türkçe hızla okur, ayarın etkisi duyulmazdı.
                if (!context.mounted) return;
                unawaited(
                  ref
                      .read(speechOutputProvider.notifier)
                      .speak(
                        SpeechOutputController.voiceSample('en'),
                        languageCode: 'en',
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Sesin TONU (perde): aynı ses daha kalın ya da daha ince okur.
///
/// Ayarlarda YOKTU (kullanıcı isteği 2026-08-09: "eksik ayar varsa
/// eklenmeli"). Motorların kabul ettiği aralık 0,5–2,0; 1,0 sesin kendi tonu.
class _SpeechPitchSlider extends ConsumerStatefulWidget {
  const _SpeechPitchSlider();

  @override
  ConsumerState<_SpeechPitchSlider> createState() => _SpeechPitchSliderState();
}

class _SpeechPitchSliderState extends ConsumerState<_SpeechPitchSlider> {
  double? _pitch;

  @override
  void initState() {
    super.initState();
    ref.read(speechOutputProvider.notifier).pitch().then((value) {
      if (mounted) setState(() => _pitch = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pitch = _pitch;
    if (pitch == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(context.l10n.speechPitch)),
          Expanded(
            flex: 2,
            child: Slider(
              value: pitch,
              min: 0.5,
              max: 2,
              divisions: 6,
              label: pitch.toStringAsFixed(1),
              onChanged: (value) => setState(() => _pitch = value),
              // Kaydırırken DEĞİL bırakınca yazılır: her karede motor ayarı
              // yeniden kurmak sesi tutukluyor (madde 9 — kasma olmamalı).
              onChangeEnd: (value) async {
                await ref.read(speechOutputProvider.notifier).setPitch(value);
                if (context.mounted) _previewDeviceVoice(context, ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkScheduleEditor extends ConsumerWidget {
  const _DarkScheduleEditor();

  String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final schedule = ref.read(darkScheduleProvider);
    final current = isStart ? schedule.startMinutes : schedule.endMinutes;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (time == null) return;
    final minutes = time.hour * 60 + time.minute;
    ref
        .read(darkScheduleProvider.notifier)
        .update(
          startMinutes: isStart ? minutes : null,
          endMinutes: isStart ? null : minutes,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final schedule = ref.watch(darkScheduleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.darkSchedule),
          subtitle: Text(l10n.darkScheduleInfo),
          value: schedule.enabled,
          onChanged: (value) =>
              ref.read(darkScheduleProvider.notifier).update(enabled: value),
        ),
        if (schedule.enabled)
          Row(
            children: [
              const SizedBox(width: 4),
              ActionChip(
                avatar: const Icon(Icons.dark_mode_outlined, size: 16),
                label: Text(_format(schedule.startMinutes)),
                onPressed: () => _pick(context, ref, isStart: true),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              ActionChip(
                avatar: const Icon(Icons.light_mode_outlined, size: 16),
                label: Text(_format(schedule.endMinutes)),
                onPressed: () => _pick(context, ref, isStart: false),
              ),
            ],
          ),
      ],
    );
  }
}

/// Dahili AI durumu: kendi anahtarı varsa "sınırsız", premium'sa "premium",
/// değilse bugünkü kalan ücretsiz hak gösterilir.
class _BuiltInAiStatus extends ConsumerWidget {
  const _BuiltInAiStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasKey = (ref.watch(activeApiKeyProvider).value ?? '').isNotEmpty;
    final premium = ref.watch(premiumProvider).value ?? false;
    final remaining = ref.watch(freeAiRemainingProvider);

    final (icon, text) = hasKey
        // Kendi anahtarı varsa hesap türü fark etmez: maliyet kullanıcıda,
        // sınır yok. Yerel hesap uyarısı bu durumda yanıltıcı olurdu.
        ? (Icons.key, l10n.aiBuiltInByok)
        : ref.watch(isAnonymousProvider)
        ? (Icons.phonelink_lock_outlined, l10n.localAccountInfo)
        : premium
        ? (Icons.workspace_premium_outlined, l10n.aiBuiltInPremium(remaining))
        : (Icons.bolt_outlined, l10n.aiBuiltInRemaining(remaining));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // Satır artık Premium sayfasına götürüyor: kota/puan farkının ne
      // kazandırdığı hiçbir yerde anlatılmıyordu (premium çalışması).
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/premium'),
        child: Row(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// AI bölümündeki form alanlarının ORTAK görünümü.
///
/// Genel tema alanları yalnız dolgu rengiyle çiziyor (kenarlık yok); kâğıt
/// temada o dolgu kart zeminiyle neredeyse aynı olduğundan açılır listeler ve
/// anahtar kutusu "sayfaya dağılmış yazılar" gibi duruyordu. Burada görünür
/// kenarlık + tek tip iç boşluk verilir, alanların nerede başlayıp bittiği
/// belli olur.
InputDecoration _aiFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
}) {
  final scheme = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: scheme.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(scheme.outlineVariant),
    enabledBorder: border(scheme.outlineVariant),
    focusedBorder: border(scheme.primary, 1.6),
  );
}

class _GeminiKeyEditor extends ConsumerStatefulWidget {
  const _GeminiKeyEditor();

  @override
  ConsumerState<_GeminiKeyEditor> createState() => _GeminiKeyEditorState();
}

class _GeminiKeyEditorState extends ConsumerState<_GeminiKeyEditor> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validateAndSave() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _busy = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final provider = ref.read(activeProviderProvider);
    try {
      final valid = await ref.read(geminiServiceProvider).validateKey(key);
      if (!valid) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeyInvalid)));
        return;
      }
      await ref.read(apiKeyStoreProvider).save(provider, key);
      _invalidateKeys(provider);
      _controller.clear();
      messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeyValid)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeKey() async {
    final provider = ref.read(activeProviderProvider);
    await ref.read(apiKeyStoreProvider).clear(provider);
    _invalidateKeys(provider);
  }

  /// Anahtar değişince model listesi de tazelenmeli: katalog anahtarla
  /// çekiliyor, eski liste yanlış sağlayıcıya ait kalırdı.
  void _invalidateKeys(AiProvider provider) {
    ref.invalidate(activeApiKeyProvider);
    ref.invalidate(providerApiKeyProvider(provider));
    ref.invalidate(availableModelsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = ref.watch(activeProviderProvider);
    final storedKey = ref.watch(activeApiKeyProvider).value;
    final hasKey = storedKey != null && storedKey.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AiProvider>(
          initialValue: provider,
          isExpanded: true,
          decoration: _aiFieldDecoration(context, label: l10n.aiProvider),
          items: [
            for (final option in AiProvider.values)
              DropdownMenuItem(
                value: option,
                child: Text(
                  option.freeTier
                      ? '${option.label} · ${l10n.freeTierBadge}'
                      : option.label,
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            ref.read(activeProviderProvider.notifier).set(value);
            // Sağlayıcı değişti: anahtar ve model listesi o sağlayıcıya ait
            // olmalı, önceki sağlayıcının önbelleği gösterilmemeli.
            _controller.clear();
            _invalidateKeys(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          l10n.aiProviderInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        // Sağlayıcı bloğu ile anahtar bloğu arasına ayırıcı: ikisi arka arkaya
        // duran metin yığını gibi okunuyordu.
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        if (hasKey)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.key, size: 16),
                  label: Text('${provider.label}: ${l10n.apiKeySavedBadge}'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _removeKey,
                  child: Text(l10n.removeApiKey),
                ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          obscureText: true,
          decoration: _aiFieldDecoration(
            context,
            label: '${provider.label} · ${l10n.apiKeyFieldLabel}',
            // İpucu sağlayıcının anahtar biçimi: yanlış sağlayıcıya
            // yapıştırıldığında kullanıcı hatayı beklemeden görür.
            hint: provider.keyHint,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.geminiApiKeyInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => launchUrl(
              Uri.parse(provider.keyUrl),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(l10n.getApiKey),
          ),
        ),
        const SizedBox(height: 4),
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _validateAndSave,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(l10n.validateAndSave),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const _AiDiagnosticsTile(),
      ],
    );
  }
}

/// Dahili AI'ın son ham hataları. Kullanıcıya gösterilen mesajlar sadeleştirilmiş
/// olduğundan ("şu an yanıt veremiyor"), gerçek neden yalnız burada görünür.
class _AiDiagnosticsTile extends StatefulWidget {
  const _AiDiagnosticsTile();

  @override
  State<_AiDiagnosticsTile> createState() => _AiDiagnosticsTileState();
}

class _AiDiagnosticsTileState extends State<_AiDiagnosticsTile> {
  @override
  Widget build(BuildContext context) {
    final entries = AiDiagnostics.entries;
    final scheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(context.l10n.aiDiagnostics),
      subtitle: Text(
        entries.isEmpty
            ? context.l10n.aiDiagnosticsEmpty
            : context.l10n.aiDiagnosticsCount(entries.length),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onExpansionChanged: (_) => setState(() {}),
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SelectableText(
              e,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        if (entries.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(AiDiagnostics.clear),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(context.l10n.clear),
            ),
          ),
      ],
    );
  }
}

/// Model seçimi: **satır + tam boy seçim levhası**.
///
/// KÖK NEDEN (kullanıcı üç kez bildirdi, 2026-08-09: "ayarlarda model seçim
/// ekranını 3. kez yazıyorum, hâlâ değişen bir şey yok"): burada beş tane
/// `DropdownButtonFormField` alt alta duruyordu. Her biri sağlayıcının
/// ONLARCA modelini iki satırlık (ad + gerekçe) öğelerle listeliyor; telefonda
/// açılan menü ekranı kaplıyor, aranan model ancak uzun uzun kaydırarak
/// bulunuyor ve beş kutu üst üste gelince bölüm bir duvara dönüşüyordu.
///
/// Şimdi her kullanım alanı TEK SATIR: solda işin adı, altında o an seçili
/// model. Dokununca arama kutulu, "Önerilen" ve "Diğer" diye ayrılmış bir
/// levha açılır — model adı yazılarak bulunur, seçilince levha kapanır.
Widget _modelPickerTile({
  required BuildContext context,
  required String label,
  required List<AiModel> models,
  required String? value,
  required String autoLabel,
  required String recommendedLabel,
  required ValueChanged<String?> onChanged,
  bool allowShowAll = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  // Kayıtlı model artık listede yoksa (kaldırılmış olabilir ya da sağlayıcı
  // değişmiş olabilir) yine göster; zincir zaten çalışan bir modele düşer.
  final items = value != null && !models.any((m) => m.id == value)
      ? [AiModel(id: value, label: value), ...models]
      : models;
  final current = value == null
      ? autoLabel
      : _ModelSelectors._friendlyModel(
          items.firstWhere(
            (m) => m.id == value,
            orElse: () => AiModel(id: value, label: value),
          ),
        );
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showModalBottomSheet<_ModelChoice>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (_) => _ModelPickerSheet(
              title: label,
              models: items,
              value: value,
              autoLabel: autoLabel,
              recommendedLabel: recommendedLabel,
              allowShowAll: allowShowAll,
            ),
          );
          if (picked != null) onChanged(picked.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      current,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Levhadan dönen seçim. `null` DEĞERİ "Otomatik" demek olduğu için levhanın
/// "iptal" ile "otomatik"i ayırt edebilmesi gerekiyor — sarmalayıcı tip bunu
/// sağlar (iptalde levha null döner, "Otomatik"te `_ModelChoice(null)`).
class _ModelChoice {
  const _ModelChoice(this.id);

  final String? id;
}

/// Model seçim levhası: arama + "Önerilen" / "Diğer" grupları.
class _ModelPickerSheet extends ConsumerStatefulWidget {
  const _ModelPickerSheet({
    required this.title,
    required this.models,
    required this.value,
    required this.autoLabel,
    required this.recommendedLabel,
    this.allowShowAll = false,
  });

  final String title;
  final List<AiModel> models;
  final String? value;
  final String autoLabel;
  final String recommendedLabel;

  /// "Tümünü göster" anahtarı çizilsin mi? Yalnız METİN seçicisinde: orada
  /// liste uygulamanın kullandığı sohbet modelleriyle sınırlı, kullanıcı
  /// sağlayıcısında ne varsa görmek isteyebilir (kullanıcı isteği
  /// 2026-08-09: "tüm modeller çekilmeli"). Seslendirme seçicisi zaten
  /// kendi türünü gösteriyor.
  final bool allowShowAll;

  @override
  ConsumerState<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<_ModelPickerSheet> {
  final _search = TextEditingController();
  String _query = '';
  bool _showAll = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AiModel m) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return m.id.toLowerCase().contains(q) ||
        m.label.toLowerCase().contains(q) ||
        _ModelSelectors._friendlyModel(m).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // "Tümünü göster" açıksa katalogtaki HER model listelenir (aynı
    // önbellekten gelir, ikinci bir ağ isteği yok).
    final source = _showAll
        ? (ref.watch(allModelsProvider).value ?? widget.models)
        : widget.models;
    final shown = [
      for (final m in source)
        if (_matches(m)) m,
    ];
    final recommended = [
      for (final m in shown)
        if (m.recommended) m,
    ];
    final others = [
      for (final m in shown)
        if (!m.recommended) m,
    ];

    // `RadioListTile.groupValue`/`onChanged` KULLANILMAZ (kullanımdan kalktı):
    // seçili değer ve geri çağrı dıştaki [RadioGroup]'tan gelir — dil
    // seçicisiyle aynı desen.
    Widget tile(AiModel m) => RadioListTile<String?>(
      value: m.id,
      dense: true,
      title: Row(
        children: [
          Flexible(
            child: Text(
              _ModelSelectors._friendlyModel(m),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (m.recommended) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.recommendedLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: m.note == null ? null : Text(m.note!),
    );

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: l10n.aiModelSearch,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (widget.allowShowAll)
            SwitchListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(l10n.aiModelShowAll),
              subtitle: Text(l10n.aiModelShowAllInfo),
              value: _showAll,
              onChanged: (v) => setState(() => _showAll = v),
            ),
          Flexible(
            child: RadioGroup<String?>(
              groupValue: widget.value,
              onChanged: (v) => Navigator.pop(context, _ModelChoice(v)),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  RadioListTile<String?>(
                    value: null,
                    dense: true,
                    title: Text(widget.autoLabel),
                    subtitle: Text(l10n.aiModelAutoInfo),
                  ),
                  if (recommended.isNotEmpty) ...[
                    header(widget.recommendedLabel),
                    for (final m in recommended) tile(m),
                  ],
                  if (others.isNotEmpty) ...[
                    header(l10n.aiModelOthers),
                    for (final m in others) tile(m),
                  ],
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.aiModelNoMatch)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kullanım alanı başına Gemini model seçimi. "Otomatik" = uygulamanın
/// kendi sıralı zinciri; belirli model seçilirse o ilk sırada denenir.
class _ModelSelectors extends ConsumerWidget {
  const _ModelSelectors();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Anahtarı olmayanlarda da gösterilir: `availableModels()` anahtar yoksa
    // uygulamanın yerleşik tercih listesini döndürüyor ve dahili (Firebase)
    // yol da seçilen modeli uyguluyor. Eskiden buradaki anahtar koşulu
    // seçiciyi anahtarsız kullanıcıdan tamamen gizliyordu.
    //
    // Liste önbellekli sağlayıcıdan (availableModelsProvider) izlenir; inline
    // FutureBuilder her rebuild'de yeni bir future kurup bölümü boşaltıp
    // yeniden doldurduğu için ayarlar sayfası zıplıyordu (madde 3).
    final models =
        ref.watch(availableModelsProvider).value ?? const <AiModel>[];
    if (models.isEmpty) return const SizedBox.shrink();
    final selected = ref.watch(aiTaskModelsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final task in AiTask.values) ...[
          _modelPickerTile(
            context: context,
            label: _taskLabel(l10n, task),
            models: models,
            value: selected[task],
            autoLabel: l10n.aiModelAuto,
            recommendedLabel: l10n.recommendedModel,
            allowShowAll: true,
            onChanged: (v) =>
                ref.read(aiTaskModelsProvider.notifier).set(task, v),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          l10n.aiModelsInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static String _taskLabel(AppLocalizations l10n, AiTask task) =>
      switch (task) {
        AiTask.general => l10n.aiModelChat,
        AiTask.document => l10n.aiModelDocument,
        AiTask.podcast => l10n.aiModelPodcast,
        AiTask.translate => l10n.aiModelTranslate,
        AiTask.voice => l10n.aiModelVoice,
      };

  /// Ham model kimliği yerine okunur ad: "gemini-3.5-flash" → "3.5 Flash".
  /// Sağlayıcı bir görünen ad verdiyse (OpenAI/Anthropic veriyor) o kullanılır;
  /// yalnızca Gemini gibi ham kimlik dönen sağlayıcılarda güzelleştirilir.
  static String _friendlyModel(AiModel model) {
    if (model.label != model.id) return model.label;
    var name = model.id.replaceFirst('gemini-', '').replaceAll('-preview', '');
    final lower = name.toLowerCase();
    final hint = lower.contains('flash-lite')
        ? 'en hızlı'
        : lower.contains('flash')
        ? 'hızlı'
        : lower.contains('pro')
        ? 'en güçlü'
        : lower.contains('live')
        ? 'canlı ses'
        : null;
    // "3.5-flash" → "3.5 Flash": tire boşluk olur, parçalar büyük harfle başlar.
    name = name
        .split('-')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
    return hint == null ? name : '$name — $hint';
  }

}

class _BriefingEditor extends ConsumerWidget {
  const _BriefingEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(briefingSettingsProvider);
    final time =
        '${(settings.minutes ~/ 60).toString().padLeft(2, '0')}:${(settings.minutes % 60).toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.briefingSetting),
          subtitle: Text(l10n.briefingSettingInfo),
          value: settings.enabled,
          onChanged: (value) => ref
              .read(briefingSettingsProvider.notifier)
              .update(enabled: value),
        ),
        if (settings.enabled)
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.schedule, size: 16),
                label: Text(time),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: settings.minutes ~/ 60,
                      minute: settings.minutes % 60,
                    ),
                  );
                  if (picked != null) {
                    ref
                        .read(briefingSettingsProvider.notifier)
                        .update(minutes: picked.hour * 60 + picked.minute);
                  }
                },
              ),
              // Ayar ile ekran birbirine bağlansın: brifing buradan da açılır.
              ActionChip(
                avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                label: Text(context.l10n.openBriefing),
                onPressed: () => context.push('/briefing'),
              ),
            ],
          ),
      ],
    );
  }
}

/// AI alanındaki anahtar satırlarının ORTAK biçimi.
///
/// Dördü de ayrı ayrı `SwitchListTile` kuruyordu: başlıklar gövde punto,
/// açıklamalar aynı puntoda ve tam genişlikte olduğundan satırlar birbirine
/// karışıyor, hangi açıklamanın hangi anahtara ait olduğu okunmuyordu
/// (kullanıcı: "ai kısmında görünüm bozuk ve karışık"). Tek yerde: başlık
/// vurgulu, açıklama küçük ve soluk, anahtar sağda hizalı.
class _AiSwitchTile extends StatelessWidget {
  const _AiSwitchTile({
    required this.title,
    required this.info,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String info;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _AutoTagSwitch extends ConsumerWidget {
  const _AutoTagSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.autoTagSetting,
      info: l10n.autoTagSettingInfo,
      value: ref.watch(autoTagProvider),
      onChanged: (value) => ref.read(autoTagProvider.notifier).set(value),
    );
  }
}

class _AutoTitleSwitch extends ConsumerWidget {
  const _AutoTitleSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.autoTitleSetting,
      info: l10n.autoTitleSettingInfo,
      value: ref.watch(autoTitleProvider),
      onChanged: (value) => ref.read(autoTitleProvider.notifier).set(value),
    );
  }
}

/// Sesli asistan yanıtını yüksek sesle okusun mu? (Asistan panelindeki
/// "sustur" düğmesiyle aynı anahtar.)
class _AssistantVoiceSwitch extends ConsumerWidget {
  const _AssistantVoiceSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.assistantVoiceSetting,
      info: l10n.assistantVoiceSettingInfo,
      value: ref.watch(assistantVoiceProvider),
      onChanged: (value) =>
          ref.read(assistantVoiceProvider.notifier).set(value),
    );
  }
}

class _AiSkipCheckedSwitch extends ConsumerWidget {
  const _AiSkipCheckedSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return _AiSwitchTile(
      title: l10n.aiSkipCheckedSetting,
      info: l10n.aiSkipCheckedInfo,
      value: ref.watch(aiSkipCheckedProvider),
      onChanged: (value) => ref.read(aiSkipCheckedProvider.notifier).set(value),
    );
  }
}

/// Model seçimi ve API anahtarı, katlanır "Gelişmiş" bölümünde: çoğu
/// kullanıcının hiç dokunmayacağı teknik ayarlar günlük ayarları boğmasın.
class _AdvancedAiSection extends ConsumerWidget {
  const _AdvancedAiSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Theme(
      // ExpansionTile'ın kendi üst/alt ayraç çizgileri grup kartında kirli
      // duruyor; kaldır.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        // Üstteki boşluk ŞART: içeriğin ilk çocuğu, etiketi kutunun ÜSTÜNE
        // taşan bir form alanı (sağlayıcı açılır listesi). Boşluksuzken o
        // etiket başlığın alt satırının üstüne biniyor ve bölüm "bozuk ve
        // karışık" görünüyordu.
        childrenPadding: const EdgeInsets.only(top: 14, bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: const Icon(Icons.tune),
        title: Text(l10n.aiAdvanced),
        subtitle: Text(
          l10n.aiAdvancedInfo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        children: const [
          _GeminiKeyEditor(),
          SizedBox(height: 14),
          _ModelSelectors(),
        ],
      ),
    );
  }
}

/// **Seslendirme — tek blok.** Okuma işini kim yapacak (cihazın yerleşik sesi
/// mi, yapay zekâ mı), hangi modelle ve hangi sesle: hepsi burada.
///
/// KÖK NEDEN (kullanıcı isteği 2026-08-09: "ai ve cihaz seçimleri tek yerden
/// yapılabilmesi, ses seçimleri tek menüde olmalı"): motor seçimi bir satırda,
/// yapay zekâ sesi başka bir satırda, CİHAZ sesleri ise uygulamanın diline
/// göre iki-üç ayrı açılır listede duruyordu. "Sesi değiştireyim" diyen
/// kullanıcı hangi kutunun hangi motorun sesini seçtiğini ayırt edemiyordu.
/// Artık seçilen motora göre TEK bir ses seçimi görünür; cihaz sesleri de tek
/// menüde (dil seç → ses seç) toplanır.
class _VoiceSection extends ConsumerWidget {
  const _VoiceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final engine = ref.watch(ttsEngineProvider);
    final models = ref.watch(availableTtsModelsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ttsSectionTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        SegmentedButton<TtsEngine>(
          segments: [
            ButtonSegment(
              value: TtsEngine.device,
              icon: const Icon(Icons.smartphone, size: 18),
              label: Text(l10n.ttsEngineDevice),
            ),
            ButtonSegment(
              value: TtsEngine.gemini,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.ttsEngineAi),
            ),
          ],
          selected: {engine},
          onSelectionChanged: (value) =>
              ref.read(ttsEngineProvider.notifier).set(value.first),
        ),
        const SizedBox(height: 6),
        Text(
          engine == TtsEngine.gemini
              ? l10n.ttsEngineAiInfo
              : l10n.ttsEngineDeviceInfo,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        // KULLANILABİLİR Mİ: yapay zekâ sesi kullanıcının KENDİ Gemini
        // anahtarını ister (dahili yol ses döndürmüyor). Eskiden ayar
        // seçilebiliyor ama okuma sessizce cihaz sesiyle yapılıyordu —
        // kullanıcı "AI seçince çalışmıyor, hâlâ android sesiyle okuyor"
        // dedi. Artık sebebi burada yazıyor.
        if (engine == TtsEngine.gemini &&
            !ref.read(aiSpeechProvider.notifier).isAvailable)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.ttsEngineAiUnavailable,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
        // Model ve ses YALNIZ yapay zekâ sesi seçiliyken anlamlı: cihaz
        // sesinin modeli yok, sesi de sistemden gelir (aşağıdaki menü).
        if (engine == TtsEngine.gemini) ...[
          const SizedBox(height: 14),
          _modelPickerTile(
            context: context,
            label: l10n.ttsModel,
            models: models,
            value: ref.watch(ttsModelProvider),
            autoLabel: l10n.aiModelAuto,
            recommendedLabel: l10n.recommendedModel,
            onChanged: (value) =>
                ref.read(ttsModelProvider.notifier).set(value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: ref.watch(ttsVoiceProvider),
            isExpanded: true,
            decoration: _aiFieldDecoration(context, label: l10n.ttsVoice),
            items: [
              for (final voice in AppConstants.geminiTtsVoices)
                DropdownMenuItem<String>(value: voice, child: Text(voice)),
            ],
            onChanged: (value) {
              if (value != null) ref.read(ttsVoiceProvider.notifier).set(value);
            },
          ),
          // Ses adı ("Kore", "Puck") tek başına hiçbir şey anlatmıyor: seçimin
          // nasıl duyulduğu ancak dinleyerek anlaşılır. Örnek AYNI ses için bir
          // kez üretilir, sonra kayıttan çalar — deneme kota yakmaz.
          const SizedBox(height: 6),
          const _AiVoicePreviewButton(),
        ] else ...[
          const SizedBox(height: 6),
          // CİHAZ SESLERİ TEK MENÜDE: dil başına ayrı satırlar yerine tek bir
          // satır, dokununca dil + ses listesi açılır.
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.record_voice_over_outlined),
            title: Text(l10n.speechVoicePickerTitle),
            subtitle: Text(l10n.speechVoiceAutoInfo),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const _VoicePickerSheet(),
            ),
          ),
        ],
      ],
    );
  }
}

/// Yapay zekâ sesinin deneme düğmesi (bkz. [AiSpeechController.previewVoice]).
///
/// Örnek cümle uygulamanın dilindedir ve model başına BİR KEZ üretilir; ikinci
/// dokunuş kayıttan çalar. Üretim sürerken düğme beklemeye geçer: seslendirme
/// modeli birkaç saniye sürebiliyor ve tepki vermeyen düğme "çalışmıyor" gibi
/// görünüyordu.
class _AiVoicePreviewButton extends ConsumerStatefulWidget {
  const _AiVoicePreviewButton();

  @override
  ConsumerState<_AiVoicePreviewButton> createState() =>
      _AiVoicePreviewButtonState();
}

class _AiVoicePreviewButtonState extends ConsumerState<_AiVoicePreviewButton> {
  bool _busy = false;

  Future<void> _play() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final sample = SpeechOutputController.voiceSample(language);
    try {
      await ref.read(aiSpeechProvider.notifier).previewVoice(sample);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _play,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow, size: 18),
          label: Text(l10n.voicePreview),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.voicePreviewCached,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Cihaz seslerinin TEK menüsü: üstte dil seçimi, altında o dilin sesleri.
/// Seçilen ses hemen O DİLDE bir örnek cümle okur — ad ("tr-tr-x-ama#male_1")
/// tek başına hiçbir şey anlatmıyor.
class _VoicePickerSheet extends ConsumerStatefulWidget {
  const _VoicePickerSheet();

  @override
  ConsumerState<_VoicePickerSheet> createState() => _VoicePickerSheetState();
}

class _VoicePickerSheetState extends ConsumerState<_VoicePickerSheet> {
  late List<String> _languages;
  String? _language;
  List<SpeechVoice>? _voices;
  SpeechVoice? _selected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_language != null) return;
    _languages = _voiceLanguages(context);
    _language = _languages.isEmpty ? 'tr' : _languages.first;
    _load();
  }

  Future<void> _load() async {
    final language = _language!;
    setState(() => _voices = null);
    final controller = ref.read(speechOutputProvider.notifier);
    final voices = await controller.voices(language: language);
    final selected = await controller.selectedVoice(language);
    if (!mounted || _language != language) return;
    setState(() {
      _voices = voices;
      _selected = selected;
    });
  }

  Future<void> _pick(SpeechVoice voice) async {
    final language = _language!;
    final controller = ref.read(speechOutputProvider.notifier);
    await controller.setVoice(language, voice);
    if (!mounted) return;
    setState(() => _selected = voice);
    // Örnek cümle SEÇİLEN DİLDEDİR: yabancı sese Türkçe cümle okutmak ne
    // telaffuzu ne tınıyı gösteriyordu.
    await controller.speak(
      SpeechOutputController.voiceSample(language),
      languageCode: language,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final voices = _voices;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.speechVoicePickerTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (_languages.length > 1)
              Wrap(
                spacing: 8,
                children: [
                  for (final code in _languages)
                    ChoiceChip(
                      label: Text(languageLabel(code)),
                      selected: _language == code,
                      onSelected: (_) {
                        if (_language == code) return;
                        setState(() => _language = code);
                        _load();
                      },
                    ),
                ],
              ),
            const SizedBox(height: 6),
            // Yükseklik sınırlı: uzun ses listesi levhayı ekranın dışına
            // taşırmasın, kendi içinde kaysın.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: voices == null
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : voices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(l10n.speechNoVoices),
                    )
                  : RadioGroup<String>(
                      groupValue: _selected?.id,
                      onChanged: (id) {
                        final voice = voices
                            .where((v) => v.id == id)
                            .firstOrNull;
                        if (voice != null) _pick(voice);
                      },
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: voices.length,
                        itemBuilder: (context, i) => RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: voices[i].id,
                          title: Text(
                            voices[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(voices[i].locale),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tüm notları (arşiv dahil, çöp hariç) tek JSON dosyası olarak dışa
/// aktarıp paylaşım sayfasını açar. Ek dosyaları bulutta kaldığından
/// yalnızca adları ve bağlantıları yazılır.
class _BackupButton extends ConsumerWidget {
  const _BackupButton();

  Map<String, dynamic> _exportNote(Note n) => {
    'id': n.id,
    'type': n.type.id,
    'title': n.title,
    'body': n.body,
    'items': [
      for (final i in n.items) {'text': i.text, 'checked': i.checked},
    ],
    'tags': n.tags,
    'color': n.color.id,
    'frameColor': n.frameColor.id,
    'folderId': n.folderId,
    'pinned': n.pinned,
    'starred': n.starred,
    'locked': n.locked,
    'createdAt': n.createdAt?.toIso8601String(),
    'updatedAt': n.updatedAt?.toIso8601String(),
    'archivedAt': n.archivedAt?.toIso8601String(),
    'reminderAt': n.reminderAt?.toIso8601String(),
    'attachments': [
      // BİLEREK storagePath, downloadUrl DEĞİL: downloadUrl içindeki
      // `?token=` Storage kurallarını atlayan, süresi dolmayan bir anahtardır.
      // Yedek dosyası e-posta/bulut diskle elden ele dolaşır; URL yazılsaydı
      // yedeği gören herkes kullanıcının tüm eklerine oturum açmadan süresiz
      // erişirdi. storagePath tek başına işe yaramaz (kural denetiminden
      // geçer); geri yükleme ekleri zaten atlıyor (bkz. _RestoreButton).
      for (final a in n.attachments)
        {'fileName': a.fileName, 'kind': a.kind.name, 'path': a.storagePath},
    ],
  };

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return;
    // Kilitli not varsa dışa aktarma kimlik ister: yedek, kilitli notların
    // gövdesini DÜZ METİN taşır — kapı yalnız ekran geçişinde kalsaydı kilit
    // buradan boşaltılabilirdi (locked bayrağı yedekte yine de yazılıdır).
    if (notes.any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    try {
      final payload = const JsonEncoder.withIndent('  ').convert({
        'app': 'notlar',
        'exportedAt': DateTime.now().toIso8601String(),
        'noteCount': notes.length,
        'notes': [for (final n in notes) _exportNote(n)],
      });
      final now = DateTime.now();
      final stamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final fileName = 'notlar-yedek-$stamp.json';
      if (kIsWeb) {
        // Web'de dosya sistemi/path_provider yok: baytlar bellekten paylaşılır.
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                utf8.encode(payload),
                name: fileName,
                mimeType: 'application/json',
              ),
            ],
            subject: 'Notlar yedeği',
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(payload);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], subject: 'Notlar yedeği'),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.genericError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.file_download_outlined),
      label: Text(context.l10n.exportBackup),
      onPressed: () => _export(context, ref),
    );
  }
}

/// Dışa aktarılan JSON yedeği geri okur: her kayıt YENİ not olarak oluşturulur
/// (mevcut notlara dokunulmaz — id çakışması/veri ezme riski yok). Ekler
/// bulut bağlantısı olarak dışa aktarıldığından geri yüklemede atlanır.
class _RestoreButton extends ConsumerWidget {
  const _RestoreButton();

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final file = await DocPicker.pickOne(
      const XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
        mimeTypes: ['application/json'],
      ),
    );
    if (file == null) return;
    try {
      final decoded = jsonDecode(await file.readAsString());
      final rawNotes = (decoded as Map<String, dynamic>)['notes'];
      if (rawNotes is! List) throw const FormatException();
      const uuid = Uuid();
      var count = 0;
      for (final raw in rawNotes) {
        if (raw is! Map) continue;
        final map = raw.cast<String, dynamic>();
        final type = NoteType.fromId(map['type'] as String?);
        final title = map['title'] as String? ?? '';
        final body = map['body'] as String? ?? '';
        final items = [
          for (final i in (map['items'] as List<dynamic>? ?? const []))
            if (i is Map)
              {
                'id': uuid.v4(),
                'text': i['text'] as String? ?? '',
                'checked': i['checked'] as bool? ?? false,
              },
        ];
        if (title.trim().isEmpty && body.trim().isEmpty && items.isEmpty) {
          continue;
        }
        final id = await repo.createNote(type);
        // Yedekteki alanların OLABİLDİĞİNCE çoğu geri yazılır. Eskiden yalnız
        // title/body/items/tags/pinned dönüyordu: kilitli notlar KİLİTSİZ
        // (içerik açıkta!), arşivdekiler ana duvara, renk/hatırlatıcı/tarih
        // kayıp geliyordu. Klasör geri yüklenmez (id başka hesapta anlamsız).
        Timestamp? ts(String key) {
          final v = map[key] as String?;
          final parsed = v == null ? null : DateTime.tryParse(v);
          return parsed == null ? null : Timestamp.fromDate(parsed);
        }

        repo.updateFields(id, {
          'title': title,
          'body': body,
          'items': items,
          'tags': [
            for (final t in (map['tags'] as List<dynamic>? ?? const []))
              t.toString(),
          ],
          'pinned': map['pinned'] as bool? ?? false,
          'starred': map['starred'] as bool? ?? false,
          'locked': map['locked'] as bool? ?? false,
          if (map['color'] is String) 'color': map['color'],
          if (map['frameColor'] is String) 'frameColor': map['frameColor'],
          if (ts('createdAt') != null) 'createdAt': ts('createdAt'),
          if (ts('archivedAt') != null) 'archivedAt': ts('archivedAt'),
          // Geçmişte kalmış hatırlatıcı geri kurulmaz (bildirim zaten
          // planlanmaz, "Geçmiş" listesini şişirir).
          if (ts('reminderAt') != null &&
              ts('reminderAt')!.toDate().isAfter(DateTime.now()))
            'reminderAt': ts('reminderAt'),
        });
        count++;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importBackupDone(count))),
      );
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importBackupInvalid)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.genericError(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.file_upload_outlined),
      label: Text(context.l10n.importBackup),
      onPressed: () => _import(context, ref),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    // Silme sürerken kapatılamayan bir bekleme göstergesi.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      await ref.read(accountServiceProvider).deleteAccountAndData();
      // Başarıda auth durumu değişir; router login ekranına yönlendirir.
      navigator.pop();
    } catch (e) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.genericError(e.toString()))),
        );
    }
  }

  /// Yerel hesabı Google hesabına BAĞLAR — yeni giriş DEĞİL.
  ///
  /// `signInWithGoogle` çağrılsaydı yeni bir uid oluşur ve anonim hesapta
  /// biriken bütün notlar erişilemez hâle gelirdi. `linkWithGoogle` uid'i
  /// koruyarak hesabı yükseltir; notlar taşınmaya gerek kalmadan yerinde
  /// kalır ve o andan itibaren yedeklenir.
  Future<void> _linkAccount(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).linkWithGoogle();
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountLinked)));
    } on FirebaseAuthException catch (e) {
      // Hesap seçiciyi kapatmak hata değil: sessizce geçilir.
      if (isSignInCancel(e)) return;
      // **credential-already-in-use — KÖK NEDEN düzeltmesi** (kullanıcı
      // bulgusu 2026-08-18: "çıkış yaptım tekrar giremiyorum bu hatayı
      // veriyor"). Seçilen Google hesabı zaten BAŞKA bir Firebase
      // kullanıcısına (kullanıcının kendi ESKİ gerçek hesabına) bağlı —
      // Firebase iki uid'i BİRLEŞTİREMEZ, yalnız hata verir. Eskiden burada
      // ham hata metni gösterilip kullanıcı çıkmaza düşüyordu ("Google
      // hesabı bağla" dışında bir yol yoktu, oysa gerekli olan BAĞLAMAK
      // değil o hesaba doğrudan GİRİŞ yapmaktı).
      //
      // ÇÖZÜM: `e.credential` (reddedilen ama GEÇERLİ Google kimlik bilgisi)
      // ile doğrudan giriş yapılır — Google hesap seçiciyi TEKRAR açmaya
      // gerek kalmaz. Bu, o anki (yeni/anonim) oturumdaki notları TERK EDER;
      // boşsa (neredeyse her zaman — bu ekrana yeni bir anonim oturumla
      // düşülmüştür) sormadan geçilir, doluysa önce onay istenir.
      if (e.code == 'credential-already-in-use' && e.credential != null) {
        if (context.mounted) {
          await _recoverExistingAccount(context, ref, e.credential!);
        }
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
    } catch (e) {
      if (isSignInCancel(e)) return;
      messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
    }
  }

  /// [credential] zaten BAŞKA (gerçek) bir Firebase hesabına ait — o hesaba
  /// doğrudan giriş yapar. Şu anki (yeni/anonim) oturumun notları varsa
  /// (nadir ama imkânsız değil — kullanıcı hesaptan çıkmadan önce bu cihazda
  /// birkaç not almış olabilir) önce onay ister; kaybolacakları açıkça söyler.
  Future<void> _recoverExistingAccount(
    BuildContext context,
    WidgetRef ref,
    AuthCredential credential,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final noteCount = (ref.read(notesStreamProvider).value ?? const [])
        .where((n) => !n.isEmpty)
        .length;
    if (noteCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.accountRecoverConflictTitle),
          content: Text(l10n.accountRecoverConflictBody(noteCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.accountRecoverConflictProceed),
            ),
          ],
        ),
      );
      if (proceed != true || !context.mounted) return;
    }
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Başarıda auth durumu değişir; kullanıcı gerçek hesabına döner,
      // notları olduğu gibi orada bekliyor olur.
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.accountLinked)));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(authErrorText(l10n, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Kimlik (avatar/ad/e-posta) artık ayarların en üstündeki profil kartında;
    // burada yalnızca hesap EYLEMLERİ kalır.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Yerel (anonim) hesapta yükseltme yolu HER ZAMAN görünür olmalı:
        // kullanıcı notlarının yalnız bu cihazda olduğunu bilmeden aylarca
        // kullanıp uygulamayı silince hepsini kaybedebilir.
        if (ref.watch(isAnonymousProvider)) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phonelink_lock_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.localAccountBadge,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.localAccountInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(l10n.linkGoogleAccount),
                    onPressed: () => _linkAccount(context, ref),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
          onPressed: () async {
            // Anonim (yerel) hesapta çıkış GERİ DÖNÜŞSÜZ veri kaybıdır: uid
            // bir daha ele geçirilemez, "Yerel devam et" YENİ uid açar ve
            // eski notların tamamı erişilmez kalır. Sıradan onay yetmez —
            // diyalog açık uyarır ve silme düğmesi gibi kırmızı görünür.
            final anonymous = ref.read(isAnonymousProvider);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.signOut),
                content: Text(
                  anonymous
                      ? l10n.signOutAnonymousWarning
                      : l10n.signOutConfirm,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    style: anonymous
                        ? FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              dialogContext,
                            ).colorScheme.error,
                            foregroundColor: Theme.of(
                              dialogContext,
                            ).colorScheme.onError,
                          )
                        : null,
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await ref.read(authRepositoryProvider).signOut();
            }
          },
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          icon: const Icon(Icons.delete_forever_outlined),
          label: Text(l10n.deleteAccount),
          onPressed: () => _deleteAccount(context, ref),
        ),
        const SizedBox(height: 16),
        // Hukuki şeffaflık: gizlilik politikası + açık kaynak lisansları.
        TextButton.icon(
          icon: const Icon(Icons.privacy_tip_outlined),
          label: Text(l10n.privacyPolicyTitle),
          onPressed: () => context.push('/privacy'),
        ),
        TextButton.icon(
          icon: const Icon(Icons.description_outlined),
          label: Text(l10n.licensesTitle),
          onPressed: () =>
              showLicensePage(context: context, applicationName: l10n.appName),
        ),
        const _AppVersionRow(),
      ],
    );
  }
}

/// **UYGULAMA SÜRÜMÜ** — kullanıcı "hangi sürümdeyim" sorusuna hiçbir yerde
/// cevap bulamıyordu.
///
/// Güncelleme akışı "yeni APK'yı üstüne kur" olduğu için bu bilgi pratikte
/// zorunlu: telefondaki sürümün CI'ın ürettiğinden eski olup olmadığı ancak
/// böyle görülür. Aynı zamanda hata bildirmenin de ön koşulu.
///
/// Dokununca panoya kopyalanır: numarayı elle okuyup yazmak gerekmesin.
class _AppVersionRow extends StatefulWidget {
  const _AppVersionRow();

  @override
  State<_AppVersionRow> createState() => _AppVersionRowState();
}

class _AppVersionRowState extends State<_AppVersionRow> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {
      // Sürüm okunamadı (beklenmedik platform): satır hiç çizilmez, ayarların
      // geri kalanı çalışmaya devam eder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      icon: const Icon(Icons.info_outline),
      label: Text('${l10n.appVersion}: $version'),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(
          ClipboardData(text: '${l10n.appName} $version'),
        );
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.appVersionCopied)));
      },
    );
  }
}

/// Arama suzgecinin test kancalari.
///
/// `_Area` ve `_SettingRow` bu dosyaya ozel (private) kalmali — ayar ekrani
/// disinda kullanilacak seyler degil. Suzme mantigi ise sinanmaya deger:
/// satir duzeyi suzme "hangi satir gorunur" sorusunun cevabi ve gozle
/// dogrulamasi zahmetli. Bu iki yapici testin nesne kurmasina izin verir,
/// tipi disari acmadan.
@visibleForTesting
Object settingsRowForTest(
  Widget child, {
  String title = '',
  String keywords = '',
}) => _SettingRow(child, title: title, keywords: keywords);

@visibleForTesting
dynamic settingsAreaForTest({
  required String id,
  required String title,
  required String summary,
  required String keywords,
  required List<Object> rows,
}) => _Area(
  id: id,
  icon: Icons.settings,
  title: title,
  summary: summary,
  keywords: keywords,
  rows: [for (final r in rows) r as _SettingRow],
);
