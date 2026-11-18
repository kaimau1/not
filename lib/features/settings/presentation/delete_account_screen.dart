import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_frame.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import 'settings_screen.dart' show confirmAndDeleteAccount;

/// Web'den hesap silme adresi (PL4, 16K E6). Play, uygulamayı kurmadan da
/// silme talebi yapılabilecek bir adres ister: `web/hesap-silme.html`
/// (PRIVACY_POLICY.md'den üretilir) buraya `/#/delete-account` ile bağlanır.
/// Oturum yoksa yönlendirici giriş ekranını açar ve girişten sonra BURAYA
/// döner (router `redirect`, yalnız bu adres için).
const kDeleteAccountPath = '/delete-account';

/// Ne silineceğini anlatan tek sayfa + ayarlardaki AYNI silme akışı
/// ([confirmAndDeleteAccount]: onay → ilerleme → silme).
class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: HomeInBar(appBar: AppBar(title: Text(l10n.deleteAccount))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.xl),
            children: [
              Text(
                l10n.deleteAccountPageInfo,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpace.xxl),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const ValueKey('delete-account-page-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(l10n.deleteAccount),
                  onPressed: () => confirmAndDeleteAccount(context, ref),
                ),
              ),
              const SizedBox(height: AppSpace.m),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: Text(l10n.privacyPolicyTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
