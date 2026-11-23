import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';

/// Kilitli (Pro / Ömür boyu isteyen) öğenin köşesindeki küçük kilit. Öğe
/// GİZLENMEZ: dokununca [openProScreen] ile katman ekranına gidilir
/// (PLAN §1.5 PL6). Yalnız Play derlemesinde çizilir (kapı bayraksızda hep açık).
class ProLockBadge extends StatelessWidget {
  const ProLockBadge({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.proLockedBadge;
    return Tooltip(
      message: label,
      child: Icon(
        Icons.lock_outline,
        size: size,
        semanticLabel: label,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Mevcut Pro ekranını açar (`/premium`; Play'de ProScreen). [popFirst]:
/// çağıran levha/pencere önce kapansın.
void openProScreen(BuildContext context, {bool popFirst = false}) {
  final router = GoRouter.of(context);
  if (popFirst) Navigator.of(context).pop();
  router.push('/premium');
}
