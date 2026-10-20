import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/search_fold.dart';
import '../../ai/data/semantic_search.dart';
import '../domain/note.dart';
import 'notes_providers.dart';

/// **ORTAK ARAMA YÜZEYİ** (geliştirme raporu B4, 2026-10-20): arşiv, çöp ve
/// klasör ekranlarının her biri kendi arama kutusunu, sayaç metnini ve AI
/// anahtarını ayrı kuruyordu (dört kopya; AI yalnız arşivdeydi). Üst bardaki
/// kutu, AI/kapat düğmeleri, sonuç sayacı ve eşleştirme artık burada.
///
/// Durum ekranda kalır ([ScreenSearch] — ekran kapanınca sorgu da gider).
class ScreenSearch extends ChangeNotifier {
  final controller = TextEditingController();

  /// Kutu açık mı (üst bar başlığın yerine kutuyu çizer).
  bool open = false;

  /// AI (anlamsal) arama açık mı — ekrana özgü, ana ekranın tercihini
  /// değiştirmez.
  bool semantic = false;

  void toggle() {
    open = !open;
    if (!open) {
      controller.clear();
      semantic = false;
    }
    notifyListeners();
  }

  void toggleSemantic() {
    semantic = !semantic;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Üst bardaki arama kutusu. Ayrı widget: `autofocus` yalnız kutu AĞACA
/// GİRDİĞİNDE bir kez çalışsın — üst bar her sayımda yeniden çizildiğinde
/// odak yeniden istenirse klavye kapanıp açılırdı.
class ScreenSearchField extends StatelessWidget {
  const ScreenSearchField({super.key, required this.search, this.aiHint});

  final ScreenSearch search;

  /// AI açıkken ipucu ("Arşivde anlamca ara…"); null = genel ipucu.
  final String? aiHint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: search.controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: search.semantic
            ? (aiHint ?? l10n.screenAiSearchHint)
            : l10n.searchHint,
        // Kutuyu tek dokunuşta boşalt.
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: search.controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: l10n.clearSearch,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: search.controller.clear,
                ),
        ),
      ),
    );
  }
}

/// Üst barın arama düğmeleri: kutu açıkken ✨ AI anahtarı ([ai] true ise),
/// sonra ara/kapat.
List<Widget> screenSearchActions(
  BuildContext context,
  ScreenSearch search, {
  bool ai = true,
  bool enabled = true,
}) {
  final l10n = context.l10n;
  return [
    if (search.open && ai)
      IconButton(
        key: const ValueKey('screen-search-ai'),
        tooltip: l10n.archiveAiSearch,
        isSelected: search.semantic,
        icon: const Icon(Icons.auto_awesome_outlined),
        selectedIcon: const Icon(Icons.auto_awesome),
        onPressed: search.toggleSemantic,
      ),
    IconButton(
      tooltip: search.open ? l10n.close : l10n.searchHint,
      icon: Icon(search.open ? Icons.close : Icons.search),
      onPressed: enabled ? search.toggle : null,
    ),
  ];
}

/// Aramanın sonucu: eşleşen notlar ve AI sonucu bekleniyor mu.
typedef ScreenSearchResult = ({List<Note> notes, bool loading, String needle});

/// [all] içinde [query] araması. AI açıkken (en az 3 harf — ana ekranla aynı
/// eşik) [scope]un anlamsal sonuçları; gelene kadar düz arama sonuçları
/// durur. Eşleşme kuralı ana ekranınkiyle AYNI işlevden ([noteMatchesQuery]).
ScreenSearchResult runScreenSearch(
  WidgetRef ref,
  List<Note> all,
  String query, {
  required bool semantic,
  SemanticScope? scope,
  String? folderId,
}) {
  final trimmed = query.trim();
  final needle = foldForSearch(trimmed);
  if (needle.isEmpty) return (notes: all, loading: false, needle: needle);
  final ai = semantic && scope != null && trimmed.length > 2
      ? ref.watch(
          scopedSemanticSearchProvider((
            scope: scope,
            folderId: folderId,
            query: trimmed,
          )),
        )
      : null;
  final ids = {for (final n in all) n.id};
  final aiNotes = ai?.value;
  final notes = aiNotes != null
      // Anlamsal sonuç ekranın kendi listesine süzülür (sıralama/gizli
      // süzgeç ekranda nasılsa öyle kalsın).
      ? [
          for (final n in aiNotes)
            if (ids.contains(n.id)) n,
        ]
      : [
          for (final n in all)
            if (noteMatchesQuery(n, needle)) n,
        ];
  return (notes: notes, loading: ai?.isLoading ?? false, needle: needle);
}

/// Sonuç sayacı ("3 sonuç") + AI beklerken ince ilerleme çubuğu.
class SearchResultHeader extends StatelessWidget {
  const SearchResultHeader({
    super.key,
    required this.count,
    this.loading = false,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  final int count;
  final bool loading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: padding,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.l10n.searchResultCount(count),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
