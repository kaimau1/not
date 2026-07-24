import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../data/permissions_service.dart';
import '../settings_providers.dart';

/// Uygulama İLK açıldığında bir kez gösterilen izin tanıtımı: hangi iznin
/// hangi özellik için gerektiğini söyler ve isteyen kullanıcıya hepsini tek
/// akışta verdirir.
///
/// İzinler zorunlu değildir — reddeden kullanıcı uygulamayı kullanmaya devam
/// eder, ilgili özelliği ilk kullandığında sistem yine sorar. Bayrak
/// SharedPreferences'ta tutulur; ekran ikinci kez açılmaz.
class PermissionsOnboarding {
  static const _key = 'perms_onboarded';

  /// Daha önce gösterilmediyse alt sayfayı açar. Android dışında (Windows)
  /// izin kavramı olmadığından hiçbir şey yapmaz.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final service = ref.read(permissionsServiceProvider);
    if (!service.isSupported) return;
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(_key) ?? false) return;
    // Bayrak ekran AÇILIRKEN yazılır: kullanıcı kapatsa da bir daha çıkmaz
    // (izinler Ayarlar > İzinler'den her zaman yönetilebilir).
    await prefs.setBool(_key, true);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PermissionsSheet(service: service),
    );
  }
}

class _PermissionsSheet extends StatefulWidget {
  const _PermissionsSheet({required this.service});

  final PermissionsService service;

  @override
  State<_PermissionsSheet> createState() => _PermissionsSheetState();
}

class _PermissionsSheetState extends State<_PermissionsSheet> {
  bool _busy = false;

  Future<void> _grantAll() async {
    setState(() => _busy = true);
    // Sırayla: her biri kendi sistem kutusunu açar, biri reddedilse de
    // diğerleri sorulur.
    await widget.service.requestMic();
    await widget.service.requestCamera();
    await widget.service.requestNotifications();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.permOnboardTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.permOnboardInfo,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _row(Icons.mic_none, l10n.permMic, l10n.permMicInfo),
            _row(Icons.videocam_outlined, l10n.permCamera, l10n.permCameraInfo),
            _row(
              Icons.notifications_none,
              l10n.permNotifications,
              l10n.permNotificationsInfo,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: Text(l10n.permOnboardSkip),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _grantAll,
                  child: Text(l10n.permOnboardGrantAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String title, String info) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(
                  info,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
