import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/language_names.dart';
import '../../../core/utils/speech_output.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/ai_provider.dart';
import '../../ai/data/api_key_store.dart';
import '../../ai/data/model_catalog.dart';
import '../../ai/data/firebase_ai_client.dart';
import '../../ai/data/gemini_service.dart';
import '../../auth/data/account_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../data/permissions_service.dart';
import '../settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Ses secicisi cizilecek diller: uygulamanin o anki dili + tr/en.
  static List<String> _voiceLanguages(BuildContext context) {
    final supported = supportedLanguages.keys.toSet();
    return <String>{
      Localizations.localeOf(context).toLanguageTag(),
      'tr',
      'en',
    }.where(supported.contains).toList();
  }

  /// Acik olan alan. Tek seferde biri acik: dokuz kart alt alta dururken
  /// aranan ayara ulasmak icin ekranlarca kaydirmak gerekiyordu.
  /// Kalici DEGIL - her acilista "Gorunum" acik gelir (en sik dokunulan).
  String _open = 'appearance';
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
            // Boşluk seçicinin İÇİNDE: ayrı bir satır olsaydı süzmede tek
            // başına kalıp araya boşluk bırakırdı.
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_ThemeSelector(), SizedBox(height: 12)],
            ),
            title: l10n.settingsAppearance,
            keywords:
                'tema ${l10n.themeSystem} ${l10n.themeLight} '
                '${l10n.themeDark} ${l10n.themePaper}',
          ),
          _SettingRow(const _FontScaleSlider(), title: l10n.fontSize),
          _SettingRow(
            const _ExpandListItemsSwitch(),
            title: l10n.expandListItems,
            keywords: l10n.expandListItemsInfo,
          ),
          _SettingRow(
            const _DashboardBackgroundTile(),
            title: l10n.dashboardBackground,
            keywords: l10n.dashboardBackgroundInfo,
          ),
          _SettingRow(
            const _DarkScheduleEditor(),
            title: l10n.darkSchedule,
            keywords: l10n.darkScheduleInfo,
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
          _SettingRow(
            const _VoiceModeSelector(),
            title: l10n.voiceModeSetting,
            keywords: '${l10n.voiceModeHold} ${l10n.voiceModeTap} mikrofon',
          ),
          for (final code in _voiceLanguages(context))
            _SettingRow(
              _SpeechVoiceSelector(
                language: code,
                title: l10n.speechVoiceLanguage(languageLabel(code)),
              ),
              title: l10n.speechVoiceLanguage(languageLabel(code)),
              keywords: 'ses tipi seslendirme',
            ),
          _SettingRow(
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l10n.speechVoiceAutoInfo,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            // Bu satır bir AÇIKLAMA: üstündeki ses seçicilerle aynı sorgularda
            // görünsün ki seçiciler süzülünce açıklaması da gelsin.
            keywords: '${l10n.speechVoiceAutoInfo} ses tipi seslendirme',
          ),
          _SettingRow(const _SpeechRateSlider(), title: l10n.speechRate),
          _SettingRow(
            const _ForeignSpeechRateSlider(),
            title: l10n.speechRateForeign,
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
        keywords: 'yedek geri yukle sinir mb yukleme',
        rows: [
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
                    onTap: () => setState(
                      () => _open = _open == area.id ? '' : area.id,
                    ),
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
    final scale = (ref.watch(fontScaleProvider) * 100).round();
    return '$theme · $scale%';
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
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
                Row(
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 14,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      l10n.synced,
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
      builder: (sheetContext) => _LanguageSheet(
        languages: languages,
        selected: selected,
      ),
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

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choice = ref.watch(themeChoiceProvider);
    final options = <(AppThemeChoice, String, IconData)>[
      (AppThemeChoice.system, l10n.themeSystem, Icons.brightness_auto_outlined),
      (AppThemeChoice.light, l10n.themeLight, Icons.light_mode_outlined),
      (AppThemeChoice.dark, l10n.themeDark, Icons.dark_mode_outlined),
      (AppThemeChoice.paper, l10n.themePaper, Icons.menu_book_outlined),
    ];
    // Dört seçenek TEK SATIRA sığar: eskiden yatay kaydırmaya bırakılmıştı ve
    // son seçenek ("Kağıt") ekranın dışında kalıyordu — kullanıcı orada bir
    // seçenek olduğunu göremiyordu. Sığdırma üç adımda yapılır:
    //  1. seçim tiki kaldırılır (segment başına ~28 px kazanç; seçili olan
    //     zaten dolgu rengiyle belli),
    //  2. dolgu daraltılır,
    //  3. yer gerçekten yetmiyorsa (küçük ekran + büyük yazı ölçeği) etiketler
    //     düşer, simge + ipucu kalır.
    return LayoutBuilder(
      builder: (context, constraints) {
        final perSegment = constraints.maxWidth / options.length;
        // Bir segmentin etiketli hâli: simge (18) + boşluk + ~6 karakter.
        final charWidth = MediaQuery.textScalerOf(context).scale(14) * 0.62;
        final iconsOnly = perSegment < 26 + 6 * charWidth + 16;
        return SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppThemeChoice>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.symmetric(horizontal: iconsOnly ? 4 : 8),
            ),
            segments: [
              for (final (value, label, icon) in options)
                ButtonSegment(
                  value: value,
                  tooltip: label,
                  icon: Icon(icon, size: 18),
                  label: iconsOnly
                      ? null
                      : Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                ),
            ],
            selected: {choice},
            onSelectionChanged: (selection) =>
                ref.read(themeChoiceProvider.notifier).set(selection.first),
          ),
        );
      },
    );
  }
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

/// Ana ekranın zemin görseli: seç / görünürlük / kaldır.
///
/// Görsel uygulamanın kendi klasörüne KOPYALANIR: galeriden seçilen yol
/// geçici olabiliyor (Android paylaşım önbelleği), kopyalanmazsa zemin bir
/// süre sonra kendiliğinden kayboluyordu.
class _DashboardBackgroundTile extends ConsumerWidget {
  const _DashboardBackgroundTile();

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    final Uint8List bytes;
    if (kIsWeb) return;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      const group = XTypeGroup(
        label: 'Görseller',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      bytes = await file.readAsBytes();
    } else {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      bytes = await file.readAsBytes();
    }
    final dir = await getApplicationDocumentsDirectory();
    // Dosya adı her seferinde değişir: aynı yol yeniden yazılsa Flutter'ın
    // görsel önbelleği eski kareyi göstermeye devam ederdi.
    final target = File('${dir.path}/dashboard_bg_${const Uuid().v4()}.img');
    await target.writeAsBytes(bytes);
    final previous = ref.read(dashboardBackgroundProvider).path;
    ref.read(dashboardBackgroundProvider.notifier).setPath(target.path);
    if (previous != null && previous != target.path) {
      unawaited(File(previous).delete().catchError((_) => File(previous)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final background = ref.watch(dashboardBackgroundProvider);
    final hasImage =
        background.path != null && File(background.path!).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.wallpaper),
          title: Text(l10n.dashboardBackground),
          subtitle: Text(l10n.dashboardBackgroundInfo),
          trailing: hasImage
              ? IconButton(
                  tooltip: l10n.removeBackgroundImage,
                  icon: const Icon(Icons.hide_image_outlined),
                  onPressed: () => ref
                      .read(dashboardBackgroundProvider.notifier)
                      .setPath(null),
                )
              : null,
          onTap: () => _pick(context, ref),
        ),
        if (hasImage)
          Row(
            children: [
              const Icon(Icons.opacity, size: 18),
              Expanded(
                child: Slider(
                  value: background.opacity.clamp(0.05, 1),
                  min: 0.05,
                  max: 1,
                  onChanged: (value) => ref
                      .read(dashboardBackgroundProvider.notifier)
                      .setOpacity(value),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '%${(background.opacity * 100).round()}',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _FontScaleSlider extends ConsumerStatefulWidget {
  const _FontScaleSlider();

  @override
  ConsumerState<_FontScaleSlider> createState() => _FontScaleSliderState();
}

class _FontScaleSliderState extends ConsumerState<_FontScaleSlider> {
  static const _min = 0.85;
  static const _max = 1.4;

  /// Sürükleme sürerken geçerli olan değer; parmak kalkınca null'a döner ve
  /// kaydırıcı yeniden sağlayıcıyı izler.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final double value = _dragging ?? ref.watch(fontScaleProvider);
    final percent = '${(value * 100).round()}%';
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return MediaQuery.withNoTextScaling(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_size, size: 18),
              const SizedBox(width: 8),
              Text(l10n.fontSize),
              Expanded(
                child: Slider(
                  value: value,
                  min: _min,
                  max: _max,
                  divisions: 11,
                  label: percent,
                  onChanged: (v) => setState(() => _dragging = v),
                  onChangeEnd: (v) {
                    ref.read(fontScaleProvider.notifier).set(v);
                    setState(() => _dragging = null);
                  },
                ),
              ),
              // Sabit genişlik: "%85" ile "%140" arasındaki genişlik farkı
              // kaydırıcıyı daraltıp genişletiyordu.
              SizedBox(
                width: 44,
                child: Text(percent, textAlign: TextAlign.end),
              ),
            ],
          ),
          // Önizleme kutusu en büyük ölçeğe göre boyutlanır ki sürüklerken
          // yüksekliği değişmesin.
          SizedBox(
            height: (bodyStyle?.fontSize ?? 14) * _max * 1.6,
            width: double.infinity,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.fontSizePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.linear(value),
                style: bodyStyle?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

/// Bir dilin sesli okuma sesi. Yalnız Türkçe ve İngilizce kullanıcıya
/// sorulur; kalan diller otomatik erkek sesiyle okunur. Liste cihazdan gelir
/// (kurulu TTS motoruna göre değişir), bu yüzden sabit katalog tutulmuyor.
class _SpeechVoiceSelector extends ConsumerStatefulWidget {
  const _SpeechVoiceSelector({required this.language, required this.title});

  final String language;
  final String title;

  @override
  ConsumerState<_SpeechVoiceSelector> createState() =>
      _SpeechVoiceSelectorState();
}

class _SpeechVoiceSelectorState extends ConsumerState<_SpeechVoiceSelector> {
  List<SpeechVoice>? _voices;
  SpeechVoice? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = ref.read(speechOutputProvider.notifier);
    final voices = await controller.voices(language: widget.language);
    final selected = await controller.selectedVoice(widget.language);
    if (!mounted) return;
    setState(() {
      _voices = voices;
      _selected = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final voices = _voices;
    if (voices == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.title),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (voices.isEmpty) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(widget.title),
        subtitle: Text(l10n.speechNoVoices),
      );
    }
    final current = _selected;
    final value = current != null && voices.any((v) => v.id == current.id)
        ? current.id
        : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.title),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 190),
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(l10n.speechSystemDefault),
          items: [
            for (final voice in voices)
              DropdownMenuItem(
                value: voice.id,
                child: Text(
                  voice.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (id) async {
            final picked = voices.firstWhere((v) => v.id == id);
            final controller = ref.read(speechOutputProvider.notifier);
            await controller.setVoice(widget.language, picked);
            if (!mounted) return;
            setState(() => _selected = picked);
            // Seçilen ses hemen duyulsun: adından anlaşılmıyor. Cümle
            // SEÇİLEN DİLDEDİR (bkz. SpeechOutputController.voiceSample) —
            // yabancı sese Türkçe cümle okutmak ne telaffuzu ne tınıyı
            // gösteriyordu.
            await controller.speak(
              SpeechOutputController.voiceSample(widget.language),
              languageCode: widget.language,
            );
          },
        ),
      ),
    );
  }
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
              onChangeEnd: (value) =>
                  ref.read(speechOutputProvider.notifier).setRate(value),
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
              onChangeEnd: (value) =>
                  ref.read(speechOutputProvider.notifier).setForeignRate(value),
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
        ],
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
          _modelDropdown(
            context: context,
            label: _taskLabel(l10n, task),
            models: models,
            value: selected[task],
            autoLabel: l10n.aiModelAuto,
            recommendedLabel: l10n.recommendedModel,
            onChanged: (v) =>
                ref.read(aiTaskModelsProvider.notifier).set(task, v),
          ),
          const SizedBox(height: 10),
        ],
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
        AiTask.translate => l10n.aiModelTranslate,
        AiTask.voice => l10n.aiModelVoice,
      };

  /// Ham model kimliği yerine okunur ad: "gemini-3.5-flash" → "3.5 Flash".
  /// Sağlayıcı bir görünen ad verdiyse (OpenAI/Anthropic veriyor) o kullanılır;
  /// yalnızca Gemini gibi ham kimlik dönen sağlayıcılarda güzelleştirilir.
  static String _friendlyModel(AiModel model) {
    if (model.label != model.id) return model.label;
    var name = model.id
        .replaceFirst('gemini-', '')
        .replaceAll('-preview', '');
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

  Widget _modelDropdown({
    required BuildContext context,
    required String label,
    required List<AiModel> models,
    required String? value,
    required String autoLabel,
    required String recommendedLabel,
    required ValueChanged<String?> onChanged,
  }) {
    // Kayıtlı model artık listede yoksa (kaldırılmış olabilir ya da sağlayıcı
    // değişmiş olabilir) yine göster; zincir zaten çalışan bir modele düşer.
    final items = value != null && !models.any((m) => m.id == value)
        ? [AiModel(id: value, label: value), ...models]
        : models;
    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      decoration: _aiFieldDecoration(context, label: label),
      // Seçili öğe kapalı hâlde TEK satıra sığmalı: açık listedeki iki satırlı
      // (ad + gerekçe) görünüm alana sığmayıp taşma çizgisi veriyordu.
      selectedItemBuilder: (context) => [
        Text(autoLabel, overflow: TextOverflow.ellipsis),
        for (final m in items)
          Text(_friendlyModel(m), overflow: TextOverflow.ellipsis),
      ],
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(autoLabel)),
        for (final m in items)
          DropdownMenuItem<String?>(
            value: m.id,
            child: _modelEntry(m, recommendedLabel),
          ),
      ],
      onChanged: onChanged,
    );
  }

  /// Liste satırı: ad + (varsa) ÖNERİLEN rozeti ve tek satırlık gerekçe.
  /// Kullanıcı sağlayıcının onlarca modeli arasından hangisinin not almaya
  /// uygun olduğunu tahmin etmek zorunda kalmasın.
  static Widget _modelEntry(AiModel model, String recommendedLabel) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _friendlyModel(model),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (model.recommended) ...[
            const SizedBox(width: 6),
            Builder(
              builder: (context) {
                final scheme = Theme.of(context).colorScheme;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    recommendedLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      if (model.note != null)
        Builder(
          builder: (context) => Text(
            model.note!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
    ],
  );
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
    'pinned': n.pinned,
    'locked': n.locked,
    'createdAt': n.createdAt?.toIso8601String(),
    'updatedAt': n.updatedAt?.toIso8601String(),
    'archivedAt': n.archivedAt?.toIso8601String(),
    'reminderAt': n.reminderAt?.toIso8601String(),
    'attachments': [
      for (final a in n.attachments)
        {'fileName': a.fileName, 'kind': a.kind.name, 'url': a.downloadUrl},
    ],
  };

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return;
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
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
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
        repo.updateFields(id, {
          'title': title,
          'body': body,
          'items': items,
          'tags': [
            for (final t in (map['tags'] as List<dynamic>? ?? const []))
              t.toString(),
          ],
          'pinned': map['pinned'] as bool? ?? false,
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
    } catch (e) {
      // En sık hata: seçilen Google hesabı BAŞKA bir hesaba zaten bağlı
      // (credential-already-in-use). Bu durumda birleştirme yapılamaz —
      // Firebase iki uid'i tek başına birleştiremez.
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.loginError(e.toString()))),
      );
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
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.signOut),
                content: Text(l10n.signOutConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
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
      ],
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
