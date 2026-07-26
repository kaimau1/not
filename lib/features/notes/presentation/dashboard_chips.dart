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
      // Klasör/etiket listeleri uzayabildiği için sayfa kaydırılabilir ve
      // yüksekliği serbest; yoksa alttaki maddeler ekran dışında kalırdı.
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Consumer(
          builder: (context, sheetRef, _) {
            final scheme = Theme.of(context).colorScheme;
            final visible = sheetRef.watch(visibleNoteFiltersProvider);
            final hidden = [
              for (final f in NoteFilter.values)
                if (f != NoteFilter.all && !visible.contains(f)) f,
            ];
            final notifier = sheetRef.read(visibleNoteFiltersProvider.notifier);
            return ConstrainedBox(
              // Yüksekliği sınırla, içeriği kaydır: klasör/etiket listesi
              // uzadıkça sayfa ekranı taşırmasın.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
              child: SingleChildScrollView(
                child: Column(
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
                    // Etiket/klasör çipleri de filtreler gibi gizlenebilir:
                    // çok etiketi/klasörü olan kullanıcıda çip satırı şişiyordu.
                    SwitchListTile(
                      dense: true,
                      secondary: const Icon(Icons.sell_outlined),
                      title: Text(l10n.showTagChips),
                      value: sheetRef.watch(showTagChipsProvider),
                      onChanged: (v) =>
                          sheetRef.read(showTagChipsProvider.notifier).set(v),
                    ),
                    SwitchListTile(
                      dense: true,
                      secondary: const Icon(Icons.folder_outlined),
                      title: Text(l10n.showFolderChips),
                      value: sheetRef.watch(showFolderChipsProvider),
                      onChanged: (v) => sheetRef
                          .read(showFolderChipsProvider.notifier)
                          .set(v),
                    ),
                    const Divider(height: 12),
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
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: scheme.primary,
                          ),
                          onPressed: () => notifier.toggle(filter),
                        ),
                      ),
                    // Her klasör ve her etiket için AYRI aç/kapa (madde 5): tek
                    // "hepsini göster" anahtarı, "şu üç klasörü görmek istiyorum"
                    // isteğine çare olmuyordu.
                    _ChipVisibilitySection(
                      title: l10n.foldersSection,
                      info: l10n.chipPickInfo,
                      entries: [
                        for (final f
                            in sheetRef.watch(foldersStreamProvider).value ??
                                const <NoteFolder>[])
                          (
                            id: f.id,
                            label: f.name,
                            icon: f.hidden
                                ? Icons.visibility_off_outlined
                                : f.iconData,
                          ),
                      ],
                      hidden: sheetRef.watch(hiddenFolderChipsProvider),
                      onToggle: (id) => sheetRef
                          .read(hiddenFolderChipsProvider.notifier)
                          .toggle(id),
                      onSetAll: (ids, visible) => sheetRef
                          .read(hiddenFolderChipsProvider.notifier)
                          .setAll(ids, visible: visible),
                    ),
                    _ChipVisibilitySection(
                      title: l10n.tagsSection,
                      entries: [
                        for (final tag in sheetRef.watch(allTagsProvider))
                          (id: tag, label: '#$tag', icon: Icons.sell_outlined),
                      ],
                      hidden: sheetRef.watch(hiddenTagChipsProvider),
                      onToggle: (id) => sheetRef
                          .read(hiddenTagChipsProvider.notifier)
                          .toggle(id),
                      onSetAll: (ids, visible) => sheetRef
                          .read(hiddenTagChipsProvider.notifier)
                          .setAll(ids, visible: visible),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
    // Klasör çipleri: gizli klasörler (kimlik doğrulanmadıkça) ve kullanıcının
    // çipini tek tek kapattığı klasörler düşer.
    final revealHidden = ref.watch(hiddenFoldersRevealedProvider);
    final hiddenFolderChips = ref.watch(hiddenFolderChipsProvider);
    final folders = [
      for (final f
          in ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[])
        if ((!f.hidden || revealHidden) && !hiddenFolderChips.contains(f.id)) f,
    ];
    final selectedFolder = ref.watch(selectedFolderProvider);
    final hiddenTagChips = ref.watch(hiddenTagChipsProvider);
    final counts = ref.watch(tagCountsProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final expanded = ref.watch(filtersExpandedProvider);
    final showTags = ref.watch(showTagChipsProvider);
    final showFolders = ref.watch(showFolderChipsProvider);

    // "Tümü" başta sabit; gerisi kullanıcının menüde belirlediği SIRAYLA
    // gelir (madde 1).
    final filterEntries = <(NoteFilter, String)>[
      (NoteFilter.all, l10n.filterAll),
      for (final f in visibleFilters) (f, _filterLabel(l10n, f)),
    ];

    // Etiketler: en sık kullanılanlar öne, kalanı "+N" arkasında. Çipi tek tek
    // kapatılmış etiketler hiç girmez.
    final byUsage =
        [
          for (final tag in counts.keys)
            if (!hiddenTagChips.contains(tag)) tag,
        ]..sort((a, b) {
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
    // Kullanılmayan etiketler de dahil, çipi kapatılmamış TÜM etiketler:
    // genişletilmiş panel ve "+N" sayfası bunu gösterir.
    final allVisibleTags = [
      for (final tag in ref.watch(allTagsProvider))
        if (!hiddenTagChips.contains(tag)) tag,
    ];

    // --- Çip üreticileri: hem kompakt satır hem genişletilmiş panel kullanır.
    Widget expandChip() => _compact(
      ActionChip(
        tooltip: expanded ? l10n.collapseFilters : l10n.expandFilters,
        label: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        onPressed: () => ref.read(filtersExpandedProvider.notifier).toggle(),
      ),
    );

    Widget filterMenuChip() => _compact(
      ActionChip(
        tooltip: l10n.editFilters,
        label: Icon(Icons.tune, size: 16, color: scheme.onSurfaceVariant),
        onPressed: () => _showFilterMenu(context, ref),
      ),
    );

    Widget filterChip(NoteFilter f, String label) => _compact(
      FilterChip(
        label: Text(label),
        selected: filter == f,
        showCheckmark: false,
        onSelected: (_) => ref.read(noteFilterProvider.notifier).set(f),
      ),
    );

    // Klasör çipi: simgeli; uzun basış düzenleme/silme menüsü açar.
    Widget folderChip(NoteFolder folder) => GestureDetector(
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
    );

    Widget newFolderChip() => _compact(
      ActionChip(
        tooltip: l10n.newFolder,
        label: Icon(
          Icons.create_new_folder_outlined,
          size: 16,
          color: scheme.onSurfaceVariant,
        ),
        onPressed: () => showFolderEditorDialog(context, ref),
      ),
    );

    Widget tagChip(String tag) => _compact(
      FilterChip(
        label: Text('#$tag'),
        selected: selectedTag == tag,
        showCheckmark: false,
        onSelected: (isSelected) =>
            ref.read(selectedTagProvider.notifier).set(isSelected ? tag : null),
      ),
    );

    Widget moreTagsChip() => _compact(
      ActionChip(
        label: Text('+$hiddenTagCount'),
        onPressed: () =>
            _showAllTags(context, ref, allVisibleTags, selectedTag),
      ),
    );

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );

    // Kompakt (kapalı) görünüm: tek satırda yatay kayan tüm çipler + genişlet
    // düğmesi.
    Widget collapsed() {
      final children = <Widget>[
        expandChip(),
        filterMenuChip(),
        for (final (f, label) in filterEntries) filterChip(f, label),
        if (showFolders) ...[
          for (final folder in folders) folderChip(folder),
          newFolderChip(),
        ],
        if (showTags) ...[
          for (final tag in visibleTags) tagChip(tag),
          if (hiddenTagCount > 0) moreTagsChip(),
        ],
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

    // Genişletilmiş görünüm (madde 4): filtreler tek satırda kalır; klasörler
    // ve etiketler bölümler hâlinde Wrap ile TAM görünür (yatay kaydırma
    // gerektirmeden), açılıp kapatılabilir.
    Widget expandedPanel() {
      final allTags = allVisibleTags;
      final filterRow = <Widget>[
        expandChip(),
        filterMenuChip(),
        for (final (f, label) in filterEntries) filterChip(f, label),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              scrollDirection: Axis.horizontal,
              itemCount: filterRow.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) => Center(child: filterRow[index]),
            ),
          ),
          if (showFolders) ...[
            sectionLabel(l10n.foldersSection),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final folder in folders) folderChip(folder),
                  newFolderChip(),
                ],
              ),
            ),
          ],
          if (showTags && allTags.isNotEmpty) ...[
            sectionLabel(l10n.tagsSection),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final tag in allTags) tagChip(tag)],
              ),
            ),
          ] else
            const SizedBox(height: 10),
        ],
      );
    }

    // Aç/kapa geçişini yumuşat: yükseklik değişimi ani sıçramaz.
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: expanded ? expandedPanel() : collapsed(),
    );
  }
}

/// Filtre menüsündeki "her klasör / her etiket için aç-kapa" bölümü.
/// Katlanır durur: on beş etiketi olan kullanıcıda sayfa şişmesin, isteyen
/// açıp tek tek seçsin. Başlıkta kaç tanesinin görünür olduğu yazar.
class _ChipVisibilitySection extends StatelessWidget {
  const _ChipVisibilitySection({
    required this.title,
    required this.entries,
    required this.hidden,
    required this.onToggle,
    required this.onSetAll,
    this.info,
  });

  final String title;
  final String? info;
  final List<({String id, String label, IconData icon})> entries;

  /// Çipi KAPATILMIŞ kimlikler.
  final Set<String> hidden;
  final ValueChanged<String> onToggle;
  final void Function(Iterable<String> ids, bool visible) onSetAll;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final visibleCount = entries.where((e) => !hidden.contains(e.id)).length;
    final allVisible = visibleCount == entries.length;
    return ExpansionTile(
      dense: true,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(title),
      subtitle: Text(
        '$visibleCount / ${entries.length}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      children: [
        if (info != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              info!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () =>
                  onSetAll([for (final e in entries) e.id], !allVisible),
              icon: Icon(
                allVisible ? Icons.visibility_off_outlined : Icons.done_all,
                size: 18,
              ),
              label: Text(
                allVisible
                    ? context.l10n.hideAllChips
                    : context.l10n.showAllChips,
              ),
            ),
          ),
        ),
        for (final entry in entries)
          SwitchListTile(
            dense: true,
            secondary: Icon(entry.icon, color: scheme.onSurfaceVariant),
            title: Text(
              entry.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: !hidden.contains(entry.id),
            onChanged: (_) => onToggle(entry.id),
          ),
      ],
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
String _filterLabel(AppLocalizations l10n, NoteFilter filter) =>
    switch (filter) {
      NoteFilter.all => l10n.filterAll,
      NoteFilter.text => l10n.filterText,
      NoteFilter.checklist => l10n.filterChecklist,
      NoteFilter.ordered => l10n.filterOrdered,
      NoteFilter.pinned => l10n.filterPinned,
      NoteFilter.starred => l10n.filterStarred,
    };
