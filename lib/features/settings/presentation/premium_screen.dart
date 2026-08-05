import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/constants.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/api_key_store.dart';
import '../../auth/presentation/auth_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Premium sayfası: mevcut durum + ücretsiz/premium karşılaştırması + gözden
/// kaçan özelliklerin vitrini.
///
/// "Premium kullanım çalışması" (2026-08-06): uygulamada premium'un ne
/// kazandırdığı HİÇBİR yerde anlatılmıyordu — puan/kota farkları kodda vardı
/// ama kullanıcı görmüyordu; sık kullanılan özellikler de (tarama→PDF,
/// anlamsal arama, kilit, gizli klasör) menülerde gömülü kaldığı için fark
/// edilmiyordu. Bu ekran ikisini tek yerde toplar. Satın alma Play Billing
/// gelene kadar bilgilendirme olarak kalır (bkz. KALANLAR).
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final premium = ref.watch(premiumProvider).value ?? false;
    final hasKey = (ref.watch(activeApiKeyProvider).value ?? '').isNotEmpty;
    final until = ref.watch(_premiumUntilProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // Durum kartı.
          Card(
            color: premium ? scheme.primaryContainer : scheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    premium
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    size: 36,
                    color: premium ? scheme.onPrimaryContainer : scheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      premium && until != null
                          ? l10n.premiumStatusActive(
                              DateFormat('d MMMM y').format(until),
                            )
                          : premium
                          ? l10n.premiumTitle
                          : l10n.premiumStatusFree,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            l10n.premiumPerksTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _PerkRow(
            icon: Icons.auto_awesome,
            title: l10n.premiumPerkAi,
            free: '${AppConstants.freeDailyAiPoints}',
            paid: '${AppConstants.premiumDailyAiPoints}',
          ),
          _PerkRow(
            icon: Icons.attach_file,
            title: l10n.premiumPerkAttach,
            free: formatBytes(AppConstants.maxFreeAttachmentBytes),
            paid: formatBytes(AppConstants.maxPremiumAttachmentBytes),
          ),
          _PerkRow(
            icon: Icons.cloud_outlined,
            title: l10n.premiumPerkStorage,
            free: formatBytes(AppConstants.maxFreeStorageBytes),
            paid: formatBytes(AppConstants.maxPremiumStorageBytes),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(l10n.premiumPerkAuto),
              subtitle: Text(l10n.premiumPerkAutoBody),
            ),
          ),
          const SizedBox(height: 12),
          // BYOK her zaman görünür: premium'un alternatifi olduğu saklanmaz —
          // dürüst olmayan bir satış sayfası güveni de satar.
          Card(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.key_outlined, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasKey ? l10n.aiBuiltInByok : l10n.premiumByokHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!premium) ...[
            const SizedBox(height: 20),
            Text(
              l10n.premiumHowTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.premiumHowBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),

          Text(
            l10n.premiumDiscoverTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _DiscoverTile(
            icon: Icons.document_scanner_outlined,
            title: l10n.scanDocument,
            body: l10n.discoverScanBody,
          ),
          _DiscoverTile(
            icon: Icons.auto_awesome_outlined,
            title: l10n.semanticSearchToggle,
            body: l10n.discoverSemanticBody,
          ),
          _DiscoverTile(
            icon: Icons.mic_outlined,
            title: l10n.newVoiceCapture,
            body: l10n.discoverAssistantBody,
          ),
          _DiscoverTile(
            icon: Icons.lock_outline,
            title: l10n.lockNote,
            body: l10n.discoverLockBody,
          ),
          _DiscoverTile(
            icon: Icons.visibility_off_outlined,
            title: l10n.hiddenFolder,
            body: l10n.discoverHiddenBody,
          ),
          _DiscoverTile(
            icon: Icons.picture_as_pdf_outlined,
            title: l10n.exportPdf,
            body: l10n.discoverExportBody,
          ),
        ],
      ),
    );
  }
}

/// `users/{uid}.premiumUntil` — durum kartındaki bitiş tarihi için.
/// (premiumProvider yalnız bool döndürüyor; tarihi ayrıca okuyoruz.)
final _premiumUntilProvider = StreamProvider.autoDispose<DateTime?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .snapshots()
      .map((doc) => (doc.data()?['premiumUntil'] as Timestamp?)?.toDate());
});

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.title,
    required this.free,
    required this.paid,
  });

  final IconData icon;
  final String title;
  final String free;
  final String paid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              free,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              paid,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(body),
      ),
    );
  }
}
