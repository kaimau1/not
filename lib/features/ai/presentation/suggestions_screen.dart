import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../notes/data/notes_repository.dart';
import '../data/ai_gate.dart';
import '../data/daily_cache.dart';
import '../data/gemini_service.dart';
import 'ai_generate_prompt.dart';

/// Notların tamamına bakarak üretilen öneriler. Sonuç günde bir üretilip
/// diske yazılır; ekranlar arası gezinmede ve uygulama yeniden açılışında
/// korunur, "Yenile" ile zorlanır.
final suggestionsProvider =
    AsyncNotifierProvider<SuggestionsNotifier, String>(SuggestionsNotifier.new);

class SuggestionsNotifier extends DailyCacheNotifier<String> {
  @override
  String get cacheKey => 'cache_suggestions';

  @override
  String get emptyValue => '';

  @override
  String encode(String value) => value;

  @override
  String decode(String raw) => raw;

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

class WeeklySummaryNotifier extends DailyCacheNotifier<String> {
  @override
  String get cacheKey => 'cache_weekly';

  @override
  String get emptyValue => '';

  @override
  String encode(String value) => value;

  @override
  String decode(String raw) => raw;

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
                : _buildBody(context, content, onRefresh),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<String> content,
    VoidCallback refresh,
  ) {
    final l10n = context.l10n;
    return content.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.generating),
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
                      : l10n.aiError(e.toString()),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: refresh,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (text) {
          if (text.isEmpty) {
            return EmptyState(
              icon: Icons.lightbulb_outline,
              title: _tab == _SuggestionsTab.weekly
                  ? l10n.weeklySummaryEmpty
                  : l10n.suggestionsEmpty,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _tab == _SuggestionsTab.weekly
                    ? l10n.weeklySummaryIntro
                    : l10n.suggestionsIntro,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
                child: SelectableText(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          );
        },
    );
  }
}
