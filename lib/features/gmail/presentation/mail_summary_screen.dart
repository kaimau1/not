import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/daily_cache.dart';
import '../../ai/data/gemini_service.dart';
import '../../ai/presentation/ai_generate_prompt.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note_type.dart';
import '../data/gmail_auth.dart';
import '../data/gmail_service.dart';

/// E-postaları çekip Gemini ile önemlilerini seçtirir. Sonuç günde bir kez
/// üretilip diske yazılır: bir kez tarandıktan sonra aynı gün tekrar
/// taranmaz (başka sekmeye geçilse de arka planda biter ve saklanır),
/// gün değişince otomatik tazelenir, "Yenile" ile her an zorlanır.
final importantEmailsProvider =
    AsyncNotifierProvider<ImportantEmailsNotifier, List<ImportantEmail>>(
  ImportantEmailsNotifier.new,
);

class ImportantEmailsNotifier extends DailyCacheNotifier<List<ImportantEmail>> {
  @override
  String get cacheKey => 'cache_important_emails';

  @override
  List<ImportantEmail> get emptyValue => const [];

  @override
  Future<List<ImportantEmail>> compute() async {
    if (!ref.read(gmailConnectedProvider)) return const [];
    final emails = await ref.read(gmailServiceProvider).fetchRecentEmails();
    if (emails.isEmpty) return const [];
    return ref.read(geminiServiceProvider).triageEmails(emails);
  }

  @override
  String encode(List<ImportantEmail> value) => jsonEncode([
        for (final e in value)
          {
            'from': e.from,
            'subject': e.subject,
            'summary': e.summary,
            'reason': e.reason,
            'dueDate': e.dueDate?.toIso8601String(),
          },
      ]);

  @override
  List<ImportantEmail> decode(String raw) => [
        for (final m in jsonDecode(raw) as List)
          ImportantEmail(
            from: m['from'] as String,
            subject: m['subject'] as String,
            summary: m['summary'] as String,
            reason: m['reason'] as String,
            dueDate: m['dueDate'] == null
                ? null
                : DateTime.parse(m['dueDate'] as String),
          ),
      ];
}

class MailSummaryScreen extends ConsumerWidget {
  const MailSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final connected = ref.watch(gmailConnectedProvider);
    final unlimited = ref.watch(aiUnlimitedProvider);
    final notifier = ref.read(importantEmailsProvider.notifier);

    void onRefresh() {
      if (!unlimited && notifier.generatedToday) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.aiGeneratedTodayInfo)));
        return;
      }
      notifier.refresh();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.importantEmails),
        actions: [
          if (connected)
            IconButton(
              tooltip: l10n.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
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

  /// Önemli e-postayı (istenirse son tarihli hatırlatıcıyla) nota çevirir.
  Future<void> _createNote(
    BuildContext context,
    WidgetRef ref,
    ImportantEmail email, {
    required bool withReminder,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    repo.updateFields(id, {
      'title': email.subject,
      'body': '${email.summary}\n\nKimden: ${email.from}',
      'tags': ['e-posta'],
      if (withReminder && email.dueDate != null)
        'reminderAt': Timestamp.fromDate(email.dueDate!),
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.noteCreatedFromEmail)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final emails = ref.watch(importantEmailsProvider);
    final unlimited = ref.watch(aiUnlimitedProvider);
    final notifier = ref.read(importantEmailsProvider.notifier);

    // Ücretsiz kullanıcıda tarama otomatik başlamaz (kota); düğmeyle başlar.
    if (!unlimited &&
        !notifier.generatedToday &&
        !emails.isLoading &&
        !emails.hasError) {
      return AiGeneratePrompt(
        icon: Icons.mark_email_unread_outlined,
        buttonLabel: l10n.aiScanEmails,
        onGenerate: notifier.refresh,
      );
    }

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
                    onPressed: () =>
                        ref.read(importantEmailsProvider.notifier).refresh(),
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
                  if (email.reason.isNotEmpty || email.dueDate != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (email.reason.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              email.reason,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        if (email.dueDate != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  scheme.errorContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.mailDueDate(
                                DateFormat('d MMM HH:mm', 'tr')
                                    .format(email.dueDate!),
                              ),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _createNote(
                          context,
                          ref,
                          email,
                          withReminder: false,
                        ),
                        icon: const Icon(Icons.note_add_outlined, size: 16),
                        label: Text(l10n.convertToNote),
                      ),
                      if (email.dueDate != null)
                        TextButton.icon(
                          onPressed: () => _createNote(
                            context,
                            ref,
                            email,
                            withReminder: true,
                          ),
                          icon: const Icon(Icons.alarm_add_outlined, size: 16),
                          label: Text(l10n.convertToReminderNote),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
