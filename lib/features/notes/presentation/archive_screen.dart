import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../ai/data/semantic_search.dart';
import 'note_card.dart';
import 'note_grid.dart';
import 'note_sort_menu.dart';
import 'notes_providers.dart';
import 'archive_insights_sheet.dart';
import 'screen_search.dart';
import '../../../core/friendly_error.dart';

/// Arşivlenen notlar. Karta dokununca editör açılır; menüden arşivden
/// çıkarılabilir veya silinebilir.
///
/// **2026-09-05 turu**: ekran tek sütunlu bir `ListView`'dı — ana ekranda
/// iki-dört sütun gören kullanıcı arşive girince tek sütuna düşüyor, üstelik
/// ARAMA da SIRALAMA da bulamıyordu. Arşiv çoğu kullanıcıda en kalabalık
/// yığın (silinmeyen ama görünmesi istenmeyen her not buraya iner) ve içinde
/// bir notu bulmanın tek yolu gözle kaydırmaktı. Artık klasör sayfasıyla
/// birebir aynı yüzey: ızgara + üst barda arama + sıralama + sayaç.
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen> {
  /// Arama kutusu + AI anahtarı (ortak yüzey — bkz. screen_search.dart).
  final _search = ScreenSearch();

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedNotesProvider);
    final count = archived.value?.length;

    return Scaffold(
      appBar: AppBar(
        title: _search.open
            ? ScreenSearchField(search: _search, aiHint: l10n.archiveAiSearchHint)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.archiveTitle),
                  // Arşivin ne kadar dolu olduğu içine bakmadan görünsün.
                  if (count != null && count > 0)
                    Text(
                      l10n.folderNoteCount(count),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
        actions: [
          // ARŞİV ÖZETİ (D5): "Arşivimde neler var?" — çöp analizinin
          // arşiv karşılığı.
          if (!_search.open && (count ?? 0) > 0)
            IconButton(
              tooltip: l10n.archiveInsights,
              icon: const Icon(Icons.insights_outlined),
              onPressed: () =>
                  showArchiveInsightsSheet(context, archived.value ?? const []),
            ),
          ...screenSearchActions(context, _search),
          // Ölçüt ana ekranla ORTAK (klasör sayfasındaki kuralla aynı):
          // kullanıcının seçtiği düzen her yerde aynı olsun.
          NoteSortMenu(
            current: ref.watch(noteSortProvider),
            onPick: (sort) => ref.read(noteSortProvider.notifier).set(sort),
          ),
        ],
      ),
      body: archived.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(friendlyError(l10n, e)),
        ),
        data: (all) => ValueListenableBuilder<TextEditingValue>(
          valueListenable: _search.controller,
          builder: (context, value, _) {
            final result = runScreenSearch(
              ref,
              all,
              value.text,
              semantic: _search.semantic,
              scope: SemanticScope.archive,
            );
            final notes = result.notes;
            final needle = result.needle;
            if (notes.isEmpty) {
              if (result.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return needle.isEmpty
                  ? EmptyState(
                      icon: Icons.archive_outlined,
                      title: l10n.archiveEmpty,
                    )
                  : EmptyState(
                      icon: Icons.search_off,
                      title: l10n.noteSearchNoHit,
                    );
            }
            return Column(
              children: [
                if (needle.isNotEmpty)
                  SearchResultHeader(
                    count: notes.length,
                    loading: result.loading,
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Sütun sayısı ANA EKRANLA ortak: kullanıcı orada iki
                      // parmakla seçtiği yoğunluğu arşivde de görsün.
                      final fixed = ref.watch(gridColumnsProvider);
                      final columns = fixed > 0
                          ? fixed
                          : (constraints.maxWidth / 220).floor().clamp(2, 6);
                      // ANA EKRANLA AYNI KART (kullanıcı bulgusu 2026-08-16:
                      // "arşivdeki notlar açılmıyor, aynı formatta açılmalı")
                      // ve artık aynı IZGARA.
                      return NoteBalancedGrid(
                        notes: notes,
                        columns: columns,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemBuilder: (context, index) =>
                            NoteCard(note: notes[index], highlightQuery: needle),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
