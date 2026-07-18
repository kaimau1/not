import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/notes_repository.dart';
import '../data/ai_gate.dart';
import '../data/daily_cache.dart';
import '../data/gemini_service.dart';
import 'ai_generate_prompt.dart';
import 'ai_text_result.dart';

/// Notların tamamına bakarak üretilen öneriler. Sonuç günde bir üretilip
/// diske yazılır; ekranlar arası gezinmede ve uygulama yeniden açılışında
/// korunur, "Yenile" ile zorlanır.
final suggestionsProvider =
    AsyncNotifierProvider<SuggestionsNotifier, String>(SuggestionsNotifier.new);

class SuggestionsNotifier extends StringDailyCache {
  @override
  String get cacheKey => 'cache_suggestions';

  @override
  Future<String> compute() async {
    // read: not değişiminde otomatik yeniden üretme; günlük/Yenile ile tazelenir.
    final notes = await ref.read(notesStreamProvider.future);
    if (notes.isEmpty) return '';
    return ref.read(geminiServiceProvider).suggestFromNotes(notes);
  }
}

/// Son 7 günün notlarından haftalık özet (günlük kalıcı önbellek).
final weeklySummaryProvider = AsyncNotifierProvider<WeeklySummaryNotifier,
    String>(WeeklySummaryNotifier.new);

class WeeklySummaryNotifier extends StringDailyCache {
  @override
  String get cacheKey => 'cache_weekly';

  @override
  Future<String> compute() async {
    final notes = await ref.read(notesStreamProvider.future);
    if (notes.isEmpty) return '';
    return ref.read(geminiServiceProvider).weeklySummary(notes);
  }
}

enum _SuggestionsTab { suggestions, weekly }

class SuggestionsScreen extends ConsumerStatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  ConsumerState<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends ConsumerState<SuggestionsScreen> {
  _SuggestionsTab _tab = _SuggestionsTab.suggestions;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isWeekly = _tab == _SuggestionsTab.weekly;
    final content =
        ref.watch(isWeekly ? weeklySummaryProvider : suggestionsProvider);
    final unlimited = ref.watch(aiUnlimitedProvider);
    final DailyCacheNotifier<String> notifier = isWeekly
        ? ref.read(weeklySummaryProvider.notifier)
        : ref.read(suggestionsProvider.notifier);
    final generatedToday = notifier.generatedToday;

    // Ücretsiz kullanıcı bugün zaten ürettiyse yenileme kotayı boşa harcamaz.
    void onRefresh() {
      if (!unlimited && generatedToday) {
        _showSnack(l10n.aiGeneratedTodayInfo);
        return;
      }
      notifier.refresh();
    }

    // Ücretsiz kullanıcıda içerik otomatik üretilmez: henüz üretilmemişse
    // (yükleme/hata dışında) elle "Oluştur" istemi gösterilir.
    final showPrompt = !unlimited &&
        !generatedToday &&
        !content.isLoading &&
        !content.hasError;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.suggestionsTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<_SuggestionsTab>(
              segments: [
                ButtonSegment(
                  value: _SuggestionsTab.suggestions,
                  label: Text(l10n.suggestionsTitle),
                  icon: const Icon(Icons.lightbulb_outline),
                ),
                ButtonSegment(
                  value: _SuggestionsTab.weekly,
                  label: Text(l10n.weeklySummary),
                  icon: const Icon(Icons.calendar_view_week_outlined),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) =>
                  setState(() => _tab = selection.first),
            ),
          ),
          Expanded(
            child: showPrompt
                ? AiGeneratePrompt(
                    icon: Icons.lightbulb_outline,
                    buttonLabel: l10n.aiGenerate,
                    onGenerate: notifier.refresh,
                  )
                : AiTextResult(
                    value: content,
                    loadingText: l10n.generating,
                    emptyIcon: Icons.lightbulb_outline,
                    emptyTitle: isWeekly
                        ? l10n.weeklySummaryEmpty
                        : l10n.suggestionsEmpty,
                    header: isWeekly
                        ? l10n.weeklySummaryIntro
                        : l10n.suggestionsIntro,
                    onRetry: onRefresh,
                  ),
          ),
        ],
      ),
    );
  }
}
