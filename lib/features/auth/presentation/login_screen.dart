import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../data/auth_repository.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _signIn() =>
      _run((auth) => auth.signInWithGoogle());

  /// "Hesapsız devam et": Firebase anonim girişi. Google hesabı istemeden
  /// anında not almaya başlanır; kısıtlar [_localAccountNote]'ta yazılı.
  ///
  /// Neden bu var: Play'de ilk açılışta hesap zorunluluğu en büyük kurulum
  /// kaybı sebeplerinden biri. Anonim giriş uid ürettiği için veri katmanı
  /// (tamamı uid'e bağlı) olduğu gibi çalışır, sonradan `linkWithGoogle` ile
  /// aynı uid gerçek hesaba yükseltilir ve notlar taşınmaya gerek kalmadan
  /// yerinde kalır.
  Future<void> _continueLocal() =>
      _run((auth) => auth.signInAnonymously());

  Future<void> _run(Future<void> Function(AuthRepository) action) async {
    setState(() => _busy = true);
    try {
      await action(ref.read(authRepositoryProvider));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loginError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.sticky_note_2_rounded,
                  size: 64,
                  color: scheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _busy ? null : _signIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(l10n.signInWithGoogle),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _continueLocal,
                  child: Text(l10n.continueWithoutAccount),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.localAccountInfo,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
