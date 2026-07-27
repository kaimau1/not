import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/notes_repository.dart';
import '../data/ai_gate.dart';
import '../data/daily_cache.dart';
import '../data/gemini_service.dart';
import 'ai_generate_prompt.dart';
import 'ai_text_result.dart';

/// Günlük brifing: bugünün hatırlatıcıları + son notlardaki yapılacaklar, tek
/// AI özetinde. Sonuç günde bir kez üretilip diske yazılır; ekranlar arası ve
/// uygulama yeniden açılışında korunur, "Yenile" ile hemen tazelenir.
final briefingProvider = AsyncNotifierProvider<BriefingNotifier, String>(
  BriefingNotifier.new,
);

class BriefingNotifier extends StringDailyCache {
  @override
  String get cacheKey => 'cache_briefing';

  @override
  Future<String> compute() async {
    // read: her not değişikliğinde brifingi yeniden üretme; günlük/Yenile ile.
    final notes = await ref.read(notesStreamProvider.future);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final buffer = StringBuffer();

    // Bugünün ve yarının hatırlatıcıları
    buffer.writeln('HATIRLATICILAR:');
    var hasReminder = false;
    for (final note in notes) {
      final reminder = note.reminderAt;
      if (reminder == null || note.deletedAt != null) continue;
      if (reminder.isBefore(today) ||
          reminder.isAfter(tomorrow.add(const Duration(days: 1)))) {
        continue;
      }
      hasReminder = true;
      // Kilitli notun içeriği brifinge sızmasın; başlık yoksa jenerik ad.
      final label = note.title.trim().isNotEmpty
          ? note.title
          : note.locked
          ? '(kilitli not)'
          : note.toPlainText().split('\n').first;
      buffer.writeln(
        '- ${DateFormat('d MMM HH:mm', 'tr').format(reminder)}: $label',
      );
    }
    if (!hasReminder) buffer.writeln('- (yok)');

    // Son 3 günün notları
    buffer.writeln('\nSON NOTLAR:');
    final cutoff = now.subtract(const Duration(days: 3));
    var count = 0;
    for (final note in notes) {
      if (note.archivedAt != null || note.locked) continue;
      if (!((note.updatedAt ?? note.createdAt)?.isAfter(cutoff) ?? false)) {
        continue;
      }
      final text = note.toPlainText();
      buffer.writeln(
        '- ${text.length > 200 ? '${text.substring(0, 200)}…' : text}'
            .replaceAll('\n', ' / '),
      );
      if (++count >= 15) break;
    }
    if (count == 0) buffer.writeln('- (yok)');

    return ref.read(geminiServiceProvider).composeBriefing(buffer.toString());
  }
}

class BriefingScreen extends ConsumerWidget {
  const BriefingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final briefing = ref.watch(briefingProvider);
    final unlimited = ref.watch(aiUnlimitedProvider);
    final notifier = ref.read(briefingProvider.notifier);
    final generatedToday = notifier.generatedToday;

    void onRefresh() {
      if (!unlimited && generatedToday) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.aiGeneratedTodayInfo)));
        return;
      }
      notifier.refresh();
    }

    // Ücretsiz kullanıcıda brifing otomatik üretilmez (kota); düğmeyle üretilir.
    if (!unlimited &&
        !generatedToday &&
        !briefing.isLoading &&
        !briefing.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.briefingTitle)),
        body: AiGeneratePrompt(
          icon: Icons.wb_sunny_outlined,
          buttonLabel: l10n.aiGenerate,
          onGenerate: notifier.refresh,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.briefingTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: AiTextResult(
        value: briefing,
        loadingText: l10n.briefingLoading,
        emptyIcon: Icons.wb_sunny_outlined,
        emptyTitle: l10n.briefingEmpty,
        header: DateFormat('d MMMM EEEE', 'tr').format(DateTime.now()),
        onRetry: onRefresh,
      ),
    );
  }
}
