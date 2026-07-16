import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../ai/data/gemini_service.dart';
import '../data/gmail_auth.dart';
import '../data/gmail_service.dart';

/// E-postaları çekip Gemini ile önemlilerini seçtirir. Sonuç yalnızca
/// bellekte tutulur; "Yenile" ile tekrar taranır.
final importantEmailsProvider =
    FutureProvider.autoDispose<List<ImportantEmail>>((ref) async {
  final emails =
      await ref.watch(gmailServiceProvider).fetchRecentEmails();
  if (emails.isEmpty) return const [];
  return ref.watch(geminiServiceProvider).triageEmails(emails);
});

class MailSummaryScreen extends ConsumerWidget {
  const MailSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final connected = ref.watch(gmailConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importantEmails),
        actions: [
          if (connected)
            IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(importantEmailsProvider),
            ),
        ],
      ),
      body: connected ? const _EmailList() : const _ConnectPrompt(),
    );
  }
}

class _ConnectPrompt extends ConsumerStatefulWidget {
  const _ConnectPrompt();

  @override
  ConsumerState<_ConnectPrompt> createState() => _ConnectPromptState();
}

class _ConnectPromptState extends ConsumerState<_ConnectPrompt> {
  bool _busy = false;

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      await ref.read(gmailAuthProvider).connect();
      ref.invalidate(gmailConnectedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.genericError(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.gmailInfo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: Text(l10n.connectGmail),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailList extends ConsumerWidget {
  const _EmailList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final emails = ref.watch(importantEmailsProvider);

    return emails.when(
      loading: () => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.mailScanning),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e is GeminiException && e.isAuthError
                    ? l10n.aiNoApiKey
                    : l10n.genericError(e.toString()),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(importantEmailsProvider),
                    child: Text(l10n.retry),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push('/settings'),
                    child: Text(l10n.settings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: l10n.mailEmpty,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final email = list[index];
            final scheme = Theme.of(context).colorScheme;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          email.from,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.subject,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (email.reason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        email.reason,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
