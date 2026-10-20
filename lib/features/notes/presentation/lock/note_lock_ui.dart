import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../app/router.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/utils/note_lock.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../auth/data/android_google_auth.dart';
import '../../../settings/settings_providers.dart';
import 'pattern_pad.dart';

/// Not kilidinin yapılandırması (F4.8) — SharedPreferences'ta, ayar
/// senkronuyla cihazlar arası.
final noteLockConfigProvider =
    NotifierProvider<NoteLockConfigNotifier, NoteLockConfig>(
      NoteLockConfigNotifier.new,
    );

class NoteLockConfigNotifier extends Notifier<NoteLockConfig> {
  @override
  NoteLockConfig build() => NoteLockConfig.fromJson(
    watchPrefs(ref).getString(NoteLockConfig.prefsKey),
  );

  void set(NoteLockConfig config) {
    state = config;
    final prefs = ref.read(sharedPreferencesProvider);
    if (config.method == NoteLockMethod.device && !config.usesSecret) {
      prefs.remove(NoteLockConfig.prefsKey);
    } else {
      prefs.setString(NoteLockConfig.prefsKey, config.toJson());
    }
  }
}

/// Kapıyı (bkz. [NoteLockGate]) uygulama köküne bağlar.
final noteLockBinderProvider = Provider<void>((ref) {
  NoteLockGate.config = ref.watch(noteLockConfigProvider);
  final router = ref.watch(routerProvider);
  NoteLockGate.context = () =>
      router.routerDelegate.navigatorKey.currentContext;
  NoteLockGate.prompt = (context, reason) => showNoteUnlockDialog(
    context,
    reason: reason,
    config: NoteLockGate.config,
    onForgot: () async {
      if (!await reauthenticateWithGoogle()) return false;
      ref.read(noteLockConfigProvider.notifier).set(const NoteLockConfig());
      return true;
    },
  );
});

/// Google hesabıyla yeniden doğrulama ("şifremi unuttum"). Misafir hesapta
/// mümkün değil (false).
Future<bool> reauthenticateWithGoogle() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || user.isAnonymous) return false;
  try {
    if (kIsWeb) {
      await user.reauthenticateWithPopup(GoogleAuthProvider());
    } else {
      await AndroidGoogleAuth.ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: account.authentication.idToken),
      );
    }
    return true;
  } catch (e) {
    debugPrint('Yeniden doğrulama başarısız: $e');
    return false;
  }
}

/// Art arda yanlış denemeden sonra bekleme (kaba kuvvete karşı).
const _maxAttempts = 5;
const _lockout = Duration(seconds: 30);
int _failures = 0;
DateTime? _lockedUntil;

/// Şifre / desen sorusu. true = doğru girildi (ya da parmak iziyle açıldı).
Future<bool> showNoteUnlockDialog(
  BuildContext context, {
  required String reason,
  required NoteLockConfig config,
  Future<bool> Function()? onForgot,
}) async {
  final bio = config.biometric && await deviceAuthAvailable();
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _UnlockDialog(
      reason: reason,
      config: config,
      biometric: bio,
      onForgot: onForgot,
    ),
  );
  return ok ?? false;
}

class _UnlockDialog extends StatefulWidget {
  const _UnlockDialog({
    required this.reason,
    required this.config,
    required this.biometric,
    this.onForgot,
  });

  final String reason;
  final NoteLockConfig config;
  final bool biometric;
  final Future<bool> Function()? onForgot;

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _controller = TextEditingController();
  bool _error = false;
  bool _checking = false;
  Timer? _tick;

  bool get _locked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _lockedUntil != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check(String secret) async {
    if (_locked || _checking || secret.isEmpty) return;
    setState(() => _checking = true);
    // Özet hesaplama ~20 bin tur: bir kare bekleyip çark görünsün.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final ok = verifyNoteLock(widget.config, secret);
    if (!mounted) return;
    if (ok) {
      _failures = 0;
      Navigator.pop(context, true);
      return;
    }
    _failures++;
    if (_failures >= _maxAttempts) {
      _failures = 0;
      _lockedUntil = DateTime.now().add(_lockout);
    }
    _controller.clear();
    setState(() {
      _error = true;
      _checking = false;
    });
  }

  Future<void> _useBiometric() async {
    final ok = await deviceAuthenticate(widget.reason);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pattern = widget.config.method == NoteLockMethod.pattern;
    final wait = _locked
        ? _lockedUntil!.difference(DateTime.now()).inSeconds + 1
        : 0;
    return AlertDialog(
      icon: const Icon(Icons.lock_outline),
      title: Text(pattern ? l10n.lockDrawPattern : l10n.lockEnterPassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.reason, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (pattern)
              IgnorePointer(
                ignoring: _locked || _checking,
                child: PatternPad(
                  size: 220,
                  error: _error,
                  onComplete: (dots) => _check(patternSecret(dots)),
                ),
              )
            else
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                enabled: !_locked,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.lockPassword,
                  errorText: _error ? l10n.lockWrong : null,
                ),
                onSubmitted: _check,
              ),
            if (pattern && _error && !_locked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.lockWrong,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            if (_locked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.lockTooManyAttempts(wait),
                  style: TextStyle(color: scheme.error),
                ),
              ),
            if (_checking) const LinearProgressIndicator(),
            if (widget.biometric)
              TextButton.icon(
                onPressed: _useBiometric,
                icon: const Icon(Icons.fingerprint),
                label: Text(l10n.lockUseFingerprint),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.onForgot != null)
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final text = l10n.lockForgotFailed;
              if (await widget.onForgot!()) {
                navigator.pop(true);
              } else {
                messenger.showMessage(text);
              }
            },
            child: Text(l10n.lockForgot),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        if (!pattern)
          FilledButton(
            onPressed: _locked ? null : () => _check(_controller.text),
            child: Text(l10n.ok),
          ),
      ],
    );
  }
}

/// Yeni şifre (iki kez) ya da yeni desen (iki kez) ister; sır döner.
Future<String?> askNewLockSecret(BuildContext context, NoteLockMethod method) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NewSecretDialog(method: method),
    );

class _NewSecretDialog extends StatefulWidget {
  const _NewSecretDialog({required this.method});

  final NoteLockMethod method;

  @override
  State<_NewSecretDialog> createState() => _NewSecretDialogState();
}

class _NewSecretDialogState extends State<_NewSecretDialog> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _pattern;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  void _password() {
    final l10n = context.l10n;
    final a = _first.text;
    if (a.length < kMinPasswordLength) {
      setState(() => _error = l10n.lockPasswordTooShort(kMinPasswordLength));
      return;
    }
    if (a != _second.text) {
      setState(() => _error = l10n.lockMismatch);
      return;
    }
    Navigator.pop(context, a);
  }

  void _drawn(List<int> dots) {
    final l10n = context.l10n;
    if (dots.length < kMinPatternDots) {
      setState(() => _error = l10n.lockPatternTooShort(kMinPatternDots));
      return;
    }
    final secret = patternSecret(dots);
    if (_pattern == null) {
      setState(() {
        _pattern = secret;
        _error = null;
      });
      return;
    }
    if (_pattern != secret) {
      setState(() {
        _pattern = null;
        _error = l10n.lockMismatch;
      });
      return;
    }
    Navigator.pop(context, secret);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pattern = widget.method == NoteLockMethod.pattern;
    return AlertDialog(
      title: Text(pattern ? l10n.lockNewPattern : l10n.lockNewPassword),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pattern) ...[
              Text(
                _pattern == null ? l10n.lockDrawPattern : l10n.lockDrawAgain,
              ),
              const SizedBox(height: 12),
              PatternPad(size: 220, error: _error != null, onComplete: _drawn),
            ] else ...[
              TextField(
                controller: _first,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.lockPassword,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _second,
                obscureText: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: l10n.lockPasswordAgain,
                ),
                onSubmitted: (_) => _password(),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: scheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        if (!pattern) FilledButton(onPressed: _password, child: Text(l10n.ok)),
      ],
    );
  }
}

/// Ayarlar → Hesap → Not kilidi: yöntem (parmak izi / şifre / desen),
/// "parmak iziyle de aç" ve kilidin şifreleme olmadığı açık uyarısı.
class NoteLockSettingsTile extends ConsumerWidget {
  const NoteLockSettingsTile({super.key});

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    NoteLockMethod method,
  ) async {
    final current = ref.read(noteLockConfigProvider);
    // Yöntemi değiştirmek (ya da sırrı yenilemek) önce mevcut kilidi ister.
    if (current.usesSecret || method != NoteLockMethod.device) {
      if (!await authenticateForNote(context.l10n.lockChangeAuthReason)) {
        return;
      }
    }
    if (!context.mounted) return;
    final notifier = ref.read(noteLockConfigProvider.notifier);
    if (method == NoteLockMethod.device) {
      notifier.set(const NoteLockConfig());
      return;
    }
    final secret = await askNewLockSecret(context, method);
    if (secret == null) return;
    notifier.set(createNoteLock(method, secret, biometric: current.biometric));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(noteLockConfigProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.lockMethodTitle),
          subtitle: Text(l10n.lockMethodInfo),
        ),
        SegmentedButton<NoteLockMethod>(
          segments: [
            ButtonSegment(
              value: NoteLockMethod.device,
              icon: const Icon(Icons.fingerprint),
              label: Text(l10n.lockMethodDevice),
            ),
            ButtonSegment(
              value: NoteLockMethod.password,
              icon: const Icon(Icons.password),
              label: Text(l10n.lockMethodPassword),
            ),
            ButtonSegment(
              value: NoteLockMethod.pattern,
              icon: const Icon(Icons.pattern),
              label: Text(l10n.lockMethodPattern),
            ),
          ],
          selected: {config.method},
          showSelectedIcon: false,
          onSelectionChanged: (s) => _choose(context, ref, s.first),
        ),
        if (config.usesSecret) ...[
          if (!kIsWeb)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.lockAlsoFingerprint),
              value: config.biometric,
              onChanged: (v) => ref
                  .read(noteLockConfigProvider.notifier)
                  .set(
                    NoteLockConfig(
                      method: config.method,
                      salt: config.salt,
                      hash: config.hash,
                      iterations: config.iterations,
                      biometric: v,
                    ),
                  ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _choose(context, ref, config.method),
              child: Text(
                config.method == NoteLockMethod.pattern
                    ? l10n.lockChangePattern
                    : l10n.lockChangePassword,
              ),
            ),
          ),
        ] else if (kIsWeb)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.lockWebDeviceInfo,
              style: theme.textTheme.bodySmall,
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l10n.lockNotEncryption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
