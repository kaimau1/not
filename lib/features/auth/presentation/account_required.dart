import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../settings/presentation/settings_screen.dart';

/// **MİSAFİRDE HESAP GEREKTİREN İŞLER** (F10.5, 2026-10-31).
///
/// Kişiler, Ortak çalışanlar, Kopya gönder ve Birlikte düzenle misafirde
/// kilit rozetiyle görünür ([AccountLockBadge]) ve dokununca hep AYNI levha
/// açılır: neden + "Google ile giriş yap" (hesap BAĞLANIR, notlar yerinde
/// kalır — bkz. [linkGuestAccount]).
Future<void> showAccountRequiredSheet(BuildContext context, WidgetRef ref) {
  return showAppSheet<void>(
    context: context,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_outline, size: 32, color: scheme.primary),
              const SizedBox(height: 12),
              Text(
                l10n.accountRequiredTitle,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accountRequiredBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('account-required-sign-in'),
                icon: const Icon(Icons.login),
                label: Text(l10n.signInWithGoogle),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  linkGuestAccount(context, ref);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Misafirde kilitli girişin sonundaki küçük kilit (ekran okuyucu "Google
/// hesabı gerekir" der).
class AccountLockBadge extends StatelessWidget {
  const AccountLockBadge({super.key, this.size = 18});

  /// Simge köşesinde (ray, hızlı satır) 14.
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.l10n.accountRequiredBadge,
    child: Icon(
      Icons.lock_outline,
      size: size,
      semanticLabel: context.l10n.accountRequiredBadge,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}
