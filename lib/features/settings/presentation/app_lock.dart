import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../notes/presentation/lock/note_lock_ui.dart'
    show noteLockConfigProvider;
import '../settings_providers.dart';

/// **Uygulama kilidi** (F18.6, 2026-11-02; isteğe bağlı, varsayılan KAPALI).
///
/// Not başına kilit (F4.8) dışında bütün uygulamayı kapatır: açılışta ve
/// arka plandan [AppLockSettings.delayMinutes] dakikadan sonra dönüşte not
/// kilidinin YÖNTEMİYLE (cihaz kilidi / şifre / desen) sorar. Kapak
/// gezginin ÜSTÜNDE durduğu için bildirim, widget ya da kısayoldan açılan
/// ekran da altında kalır. Ayar CİHAZA özgüdür (senkronlanmaz).
///
/// Şifreleme değildir: notlar cihazda/bulutta yine açık durur; kilit yalnız
/// ekrana erişimi keser (not kilidiyle aynı uyarı).
class AppLockSettings {
  const AppLockSettings({
    this.enabled = false,
    this.delayMinutes = 1,
    this.hideInRecents = false,
  });

  final bool enabled;

  /// Arka planda bu kadar kalınca kilitlenir (0 = hemen).
  final int delayMinutes;

  /// Android: "son uygulamalar"da içerik gizlenir (FLAG_SECURE — ekran
  /// görüntüsü de alınamaz).
  final bool hideInRecents;

  static const delayChoices = [0, 1, 5, 15];

  static const _kEnabled = 'app_lock_enabled';
  static const _kDelay = 'app_lock_delay_min';
  static const _kSecure = 'app_lock_secure';

  AppLockSettings copyWith({
    bool? enabled,
    int? delayMinutes,
    bool? hideInRecents,
  }) => AppLockSettings(
    enabled: enabled ?? this.enabled,
    delayMinutes: delayMinutes ?? this.delayMinutes,
    hideInRecents: hideInRecents ?? this.hideInRecents,
  );
}

/// Arka plandan dönüşte kilitlenmeli mi (saf → birim testli).
bool appLockShouldRelock({
  required AppLockSettings settings,
  required DateTime? backgroundedAt,
  required DateTime now,
}) {
  if (!settings.enabled || backgroundedAt == null) return false;
  return now.difference(backgroundedAt) >=
      Duration(minutes: settings.delayMinutes);
}

final appLockSettingsProvider =
    NotifierProvider<AppLockSettingsNotifier, AppLockSettings>(
      AppLockSettingsNotifier.new,
    );

class AppLockSettingsNotifier extends Notifier<AppLockSettings> {
  @override
  AppLockSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppLockSettings(
      enabled: prefs.getBool(AppLockSettings._kEnabled) ?? false,
      delayMinutes: prefs.getInt(AppLockSettings._kDelay) ?? 1,
      hideInRecents: prefs.getBool(AppLockSettings._kSecure) ?? false,
    );
  }

  void set(AppLockSettings next) {
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(prefs.setBool(AppLockSettings._kEnabled, next.enabled));
    unawaited(prefs.setInt(AppLockSettings._kDelay, next.delayMinutes));
    unawaited(prefs.setBool(AppLockSettings._kSecure, next.hideInRecents));
  }
}

const _system = MethodChannel('dev.kaimau.notlar/system');

Future<void> _applySecure(bool on) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await _system.invokeMethod<bool>('setSecure', {'enabled': on});
  } catch (_) {
    // Eski yerel kod / test: gizleme yalnız bir kolaylık.
  }
}

/// Kilit cihazda gerçekten bir şey koruyor mu: web'de cihaz kilidi yok
/// (`deviceAuthenticate` hep açar) → web'de yalnız şifre/desenle.
bool appLockAvailable({required bool isWeb, required bool usesSecret}) =>
    !isWeb || usesSecret;

/// Uygulama kökünü saran kapak. Kilitliyken alttaki ağaç KURULU kalır
/// (durum kaybolmaz) ama görünmez, dokunulamaz ve ekran okuyucuya kapalıdır.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late bool _locked;
  DateTime? _backgroundedAt;
  bool _authenticating = false;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appLockSettingsProvider);
    _locked = settings.enabled && _available();
    unawaited(_applySecure(settings.enabled && settings.hideInRecents));
    _lifecycle = AppLifecycleListener(onStateChange: _onState);
  }

  bool _available() => appLockAvailable(
    isWeb: kIsWeb,
    usesSecret: ref.read(noteLockConfigProvider).usesSecret,
  );

  void _onState(AppLifecycleState state) {
    // Kimlik sorusu (biyometrik pencere) uygulamayı kısa süre arka plana
    // atar: o sırada sayaç başlamaz, yoksa soru bitince yeniden kilitlenirdi.
    if (_authenticating) return;
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final relock = appLockShouldRelock(
          settings: ref.read(appLockSettingsProvider),
          backgroundedAt: _backgroundedAt,
          now: DateTime.now(),
        );
        _backgroundedAt = null;
        if (relock && _available() && !_locked) setState(() => _locked = true);
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _unlock(BuildContext promptContext) async {
    if (_authenticating) return;
    _authenticating = true;
    try {
      final reason = context.l10n.appLockReason;
      final config = ref.read(noteLockConfigProvider);
      final ok = config.usesSecret
          ? await (NoteLockGate.prompt?.call(promptContext, reason) ??
                Future.value(false))
          : await deviceAuthenticate(reason);
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {
      // Eklenti yok / beklenmeyen hata: kapak KAPALI kalır, düğme durur.
    } finally {
      _authenticating = false;
      _backgroundedAt = null;
    }
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLockSettingsProvider, (prev, next) {
      unawaited(_applySecure(next.enabled && next.hideInRecents));
      // Ayar kapatılırsa açık kapak da kalkar.
      if (!next.enabled && _locked) setState(() => _locked = false);
    });
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !_locked,
          child: ExcludeSemantics(excluding: _locked, child: widget.child),
        ),
        if (_locked)
          // Kendi gezgini: şifre/desen penceresi kapağın ÜSTÜNDE açılsın
          // (uygulamanın gezgini kapağın altında kalıyor).
          Positioned.fill(
            child: Navigator(
              onGenerateRoute: (_) => PageRouteBuilder<void>(
                pageBuilder: (ctx, _, _) => _LockScreen(onUnlock: _unlock),
              ),
            ),
          ),
      ],
    );
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.onUnlock});
  final Future<void> Function(BuildContext context) onUnlock;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  @override
  void initState() {
    super.initState();
    // Açılır açılmaz bir kez sorulur; vazgeçilirse düğme kalır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.onUnlock(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.appLockLockedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('app-lock-unlock'),
                  icon: const Icon(Icons.lock_open),
                  label: Text(l10n.appLockUnlock),
                  onPressed: () => widget.onUnlock(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ayarlar → Hesap → "Uygulama kilidi".
class AppLockSettingsTile extends ConsumerWidget {
  const AppLockSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(appLockSettingsProvider);
    final notifier = ref.read(appLockSettingsProvider.notifier);
    final available = appLockAvailable(
      isWeb: kIsWeb,
      usesSecret: ref.watch(noteLockConfigProvider).usesSecret,
    );
    String delayLabel(int m) =>
        m == 0 ? l10n.appLockDelayNow : l10n.appLockDelayMinutes(m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const ValueKey('app-lock-switch'),
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.phonelink_lock_outlined),
          title: Text(l10n.appLockTitle),
          subtitle: Text(
            available ? l10n.appLockInfo : l10n.appLockWebNeedsSecret,
          ),
          value: settings.enabled && available,
          onChanged: !available
              ? null
              : (v) async {
                  // Açmak da kapatmak da kilidin kendisini ister (birinin
                  // açık telefonda kilidi kapatıp gitmesin).
                  if (!await authenticateForNote(l10n.appLockReason)) return;
                  notifier.set(settings.copyWith(enabled: v));
                },
        ),
        if (settings.enabled && available) ...[
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.appLockDelayTitle),
                for (final m in AppLockSettings.delayChoices)
                  ChoiceChip(
                    label: Text(delayLabel(m)),
                    selected: settings.delayMinutes == m,
                    onSelected: (_) =>
                        notifier.set(settings.copyWith(delayMinutes: m)),
                  ),
              ],
            ),
          ),
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
            SwitchListTile(
              contentPadding: const EdgeInsets.only(left: 56),
              title: Text(l10n.appLockHideRecents),
              value: settings.hideInRecents,
              onChanged: (v) =>
                  notifier.set(settings.copyWith(hideInRecents: v)),
            ),
        ],
      ],
    );
  }
}
