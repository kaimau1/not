import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../../folders/presentation/folder_sheets.dart';
import 'notes_providers.dart';

/// Ana ekranın TEK satırlık kompakt çip barı: filtre menüsü + görünür
/// filtreler + klasörler + en sık etiketler yatay kayan tek satırda durur.
/// Eski iki ayrı satıra (filtreler 46px + etiketler 42px) göre yarı yer
/// kaplar; tip filtreleri varsayılanda gizlidir, filtre menüsünden eklenir.
class DashboardChipsRow extends ConsumerWidget {
  const DashboardChipsRow({super.key});

  static const _maxVisibleTags = 8;

  /// Kompakt çip görünümü: yükseklik ve iç dolgu küçültülür.
  static Widget _compact(Widget chip) => ChipTheme(
    data: const ChipThemeData(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      labelPadding: EdgeInsets.symmetric(horizontal: 2),
    ),
    child: chip,
  );

  Future<void> _showFilterMenu(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Consumer(
          builder: (context, sheetRef, _) {
            final scheme = Theme.of(context).colorScheme;
            final visible = sheetRef.watch(visibleNoteFiltersProvider);
            final hidden = [
              for (final f in NoteFilter.values)
                if (f != NoteFilter.all && !visible.contains(f)) f,
            ];
            final notifier = sheetRef.read(
              visibleNoteFiltersProvider.notifier,
            );
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    l10n.editFilters,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.editFiltersInfo,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Görünür filtreler: sürükleme tutamacıyla yeri değiştirilir
                // (madde 1 — "filtrelerin yeri ayarlanabilir olsun"), eksi
                // düğmesiyle gizlenir.
                if (visible.isNotEmpty)
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    // Yeni API `onReorderItem` newIndex'i kendi içinde
                    // düzeltiyor; buradaki reorder klasik `onReorder`
                    // semantiğine göre (newIndex ham) yazıldığından onu koruyup
                    // deprecation uyarısını bu satırda bastırıyoruz.
                    // ignore: deprecated_member_use
                    onReorder: notifier.reorder,
                    itemBuilder: (context, index) {
                        final filter = visible[index];
                        return ListTile(
                          key: ValueKey(filter),
                          dense: true,
                          leading: Icon(_filterIcon(filter)),
                          title: Text(_filterLabel(l10n, filter)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.editFilters,
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: scheme.error,
                                ),
                                onPressed: () => notifier.toggle(filter),
                              ),
                              ReorderableDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                  ),
                // Gizli filtreler: artı düğmesiyle eklenir.
                for (final filter in hidden)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      _filterIcon(filter),
                      color: scheme.onSurfaceVariant,
                    ),
                    title: Text(_filterLabel(l10n, filter)),
                    trailing: IconButton(
                      tooltip: l10n.editFilters,
                      icon: Icon(Icons.add_circle_outline, color: scheme.primary),
                      onPressed: () => notifier.toggle(filter),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showAllTags(
    BuildContext context,
    WidgetRef ref,
    List<String> tags,
    String? selected,
  ) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags)
                FilterChip(
                  label: Text('#$tag'),
                  selected: selected == tag,
                  onSelected: (isSelected) =>
                      Navigator.pop(sheetContext, isSelected ? tag : ''),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    ref.read(selectedTagProvider.notifier).set(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final filter = ref.watch(noteFilterProvider);
    final visibleFilters = ref.watch(visibleNoteFiltersProvider);
    final folders =
        ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
    final selectedFolder = ref.watch(selectedFolderProvider);
    final counts = ref.watch(tagCountsProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    // "Tümü" başta sabit; gerisi kullanıcının menüde belirlediği SIRAYLA
    // gelir (madde 1).
    final filterEntries = <(NoteFilter, String)>[
      (NoteFilter.all, l10n.filterAll),
      for (final f in visibleFilters) (f, _filterLabel(l10n, f)),
    ];

    // Etiketler: en sık kullanılanlar öne, kalanı "+N" arkasında.
    final byUsage = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    final visibleTags = byUsage.take(_maxVisibleTags).toList();
    if (selectedTag != null &&
        counts.containsKey(selectedTag) &&
        !visibleTags.contains(selectedTag)) {
      visibleTags.insert(0, selectedTag);
    }
    final hiddenTagCount = byUsage.length - visibleTags.length;

    final children = <Widget>[
      // Filtre menüsü: hangi çiplerin görüneceğini kullanıcı seçer.
      _compact(
        ActionChip(
          tooltip: l10n.editFilters,
          label: Icon(Icons.tune, size: 16, color: scheme.onSurfaceVariant),
          onPressed: () => _showFilterMenu(context, ref),
        ),
      ),
      for (final (f, label) in filterEntries)
        _compact(
          FilterChip(
            label: Text(label),
            selected: filter == f,
            showCheckmark: false,
            onSelected: (_) => ref.read(noteFilterProvider.notifier).set(f),
          ),
        ),
      // Klasörler: simgeli çipler; uzun basış düzenleme/silme menüsü açar.
      for (final folder in folders)
        GestureDetector(
          onLongPress: () => showFolderActionsSheet(context, ref, folder),
          child: _compact(
            FilterChip(
              avatar: Icon(
                folder.iconData,
                size: 16,
                color: selectedFolder == folder.id
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
              ),
              label: Text(folder.name),
              selected: selectedFolder == folder.id,
              showCheckmark: false,
              onSelected: (isSelected) => ref
                  .read(selectedFolderProvider.notifier)
                  .set(isSelected ? folder.id : null),
            ),
          ),
        ),
      _compact(
        ActionChip(
          tooltip: l10n.newFolder,
          label: Icon(
            Icons.create_new_folder_outlined,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          onPressed: () => showFolderEditorDialog(context, ref),
        ),
      ),
      for (final tag in visibleTags)
        _compact(
          FilterChip(
            label: Text('#$tag'),
            selected: selectedTag == tag,
            showCheckmark: false,
            onSelected: (isSelected) => ref
                .read(selectedTagProvider.notifier)
                .set(isSelected ? tag : null),
          ),
        ),
      if (hiddenTagCount > 0)
        _compact(
          ActionChip(
            label: Text('+$hiddenTagCount'),
            onPressed: () => _showAllTags(
              context,
              ref,
              ref.read(allTagsProvider),
              selectedTag,
            ),
          ),
        ),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) => Center(child: children[index]),
      ),
    );
  }
}

/// Filtre türünün simgesi — hem çip barında hem filtre menüsünde kullanılır.
IconData _filterIcon(NoteFilter filter) => switch (filter) {
  NoteFilter.all => Icons.all_inclusive,
  NoteFilter.text => Icons.notes,
  NoteFilter.checklist => Icons.check_box_outlined,
  NoteFilter.ordered => Icons.format_list_numbered_rounded,
  NoteFilter.pinned => Icons.push_pin_outlined,
  NoteFilter.starred => Icons.star_outline,
};

/// Filtre türünün yerelleştirilmiş etiketi.
String _filterLabel(AppLocalizations l10n, NoteFilter filter) => switch (filter) {
  NoteFilter.all => l10n.filterAll,
  NoteFilter.text => l10n.filterText,
  NoteFilter.checklist => l10n.filterChecklist,
  NoteFilter.ordered => l10n.filterOrdered,
  NoteFilter.pinned => l10n.filterPinned,
  NoteFilter.starred => l10n.filterStarred,
};
