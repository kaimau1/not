import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/search_fold.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import 'note_card.dart';
import 'note_grid.dart';
import 'note_sort_menu.dart';
import 'notes_providers.dart';

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
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final archived = ref.watch(archivedNotesProvider);
    final count = archived.value?.length;

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.searchHint,
                ),
              )
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
          IconButton(
            tooltip: _searching ? l10n.close : l10n.searchHint,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
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
          title: l10n.genericError(e.toString()),
        ),
        data: (all) => ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            final needle = foldForSearch(value.text.trim());
            // Eşleşme kuralı ana ekranınkiyle AYNI işlevden gelir.
            final notes = needle.isEmpty
                ? all
                : [
                    for (final n in all)
                      if (noteMatchesQuery(n, needle)) n,
                  ];
            if (notes.isEmpty) {
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        l10n.searchResultCount(notes.length),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
