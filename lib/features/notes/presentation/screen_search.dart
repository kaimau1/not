import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/search_fold.dart';
import '../domain/note.dart';
import 'notes_providers.dart';

/// **ORTAK ARAMA YÜZEYİ** — arşiv, çöp ve klasör ekranlarının ortak arama
/// çubuğu. Yerel tam metin araması ([noteMatchesQuery]).
class ScreenSearch extends ChangeNotifier {
  final controller = TextEditingController();

  /// Kutu açık mı (üst bar başlığın yerine kutuyu çizer).
  bool open = false;

  void toggle() {
    open = !open;
    if (!open) {
      controller.clear();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

/// Üst bardaki arama kutusu.
class ScreenSearchField extends StatelessWidget {
  const ScreenSearchField({super.key, required this.search});

  final ScreenSearch search;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      controller: search.controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: l10n.searchHint,
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

/// Üst barın arama düğmesi: ara/kapat.
List<Widget> screenSearchActions(
  BuildContext context,
  ScreenSearch search, {
  bool enabled = true,
}) {
  final l10n = context.l10n;
  return [
    IconButton(
      tooltip: search.open ? l10n.close : l10n.searchHint,
      icon: Icon(search.open ? Icons.close : Icons.search),
      onPressed: enabled ? search.toggle : null,
    ),
  ];
}

/// Aramanın sonucu: eşleşen notlar ve aranan dizge.
typedef ScreenSearchResult = ({List<Note> notes, bool loading, String needle});

/// [all] içinde yerel tam metin araması ([noteMatchesQuery]).
ScreenSearchResult runScreenSearch(
  WidgetRef ref,
  List<Note> all,
  String query,
) {
  final needle = foldForSearch(query.trim());
  if (needle.isEmpty) return (notes: all, loading: false, needle: needle);
  final notes = [
    for (final n in all)
      if (noteMatchesQuery(n, needle)) n,
  ];
  return (notes: notes, loading: false, needle: needle);
}

/// Sonuç sayacı ("3 sonuç").
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
