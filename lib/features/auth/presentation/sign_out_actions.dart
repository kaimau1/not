import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import 'auth_errors.dart';
import 'auth_providers.dart';

/// Oturumu kapatma onayı + çıkış. Ayarlar → Hesap ve ana ekranın hesap
/// levhası (kullanıcı isteği 2026-11-02: "ana ekrandaki hesap kısmına oturumu
/// kapat, hesap değiştir seçenekleri olmalı") aynı kapıdan geçer.
///
/// Anonim (yerel) hesapta çıkış GERİ DÖNÜŞSÜZ veri kaybıdır: uid bir daha
/// ele geçirilemez, "Yerel devam et" YENİ uid açar. Sıradan onay yetmez —
/// diyalog açık uyarır ve düğme silme düğmesi gibi kırmızıdır.
Future<bool> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final anonymous = ref.read(isAnonymousProvider);
  final confirmed = await _confirm(
    context,
    title: l10n.signOut,
    body: anonymous ? l10n.signOutAnonymousWarning : l10n.signOutConfirm,
    action: l10n.signOut,
    danger: anonymous,
  );
  if (!confirmed) return false;
  await ref.read(authRepositoryProvider).signOut();
  return true;
}

/// **Hesap değiştir**: bu hesaptan çıkar ve Google hesap seçicisini hemen
/// açar. Seçici kapatılırsa kullanıcı giriş ekranında kalır (oradan yine
/// girebilir); başka hata giriş ekranına değil bildirime yazılır.
Future<void> confirmAndSwitchAccount(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final anonymous = ref.read(isAnonymousProvider);
  final confirmed = await _confirm(
    context,
    title: l10n.switchAccount,
    body: anonymous
        ? l10n.switchAccountGuestWarning
        : l10n.switchAccountConfirm,
    action: l10n.switchAccount,
    danger: anonymous,
  );
  if (!confirmed) return;
  // Kapsayıcı ve bildirim kökü ÖNCEDEN: çıkışla bu ekran ağaçtan kalkar.
  final auth = ref.read(authRepositoryProvider);
  final messenger = rootScaffoldMessengerKey.currentState;
  final errorText = l10n;
  await auth.signOut();
  try {
    await auth.signInWithGoogle();
  } catch (e) {
    if (isSignInCancel(e)) return;
    messenger?.showMessage(authErrorText(errorText, e));
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  required bool danger,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
