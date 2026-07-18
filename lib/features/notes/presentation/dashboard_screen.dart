import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/semantic_search.dart';
import '../data/notes_repository.dart';
import '../data/reminder_service.dart';
import '../data/share_intake.dart';
import '../data/upload_queue.dart';
import '../data/widget_service.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'note_card.dart';
import 'notes_providers.dart';
import 'voice_assistant_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Odak değişince aksiyon butonlarını gizle/göster (dar ekranlarda arama
    // alanına yer açmak için).
    _searchFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Seçilen notları çöp kutusuna taşır; tek dokunuşla geri alınabilir.
  void _deleteSelected(Set<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    for (final id in ids) {
      repo.softDelete(id);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesDeletedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final id in ids) {
          repo.restore(id);
        }
      },
    );
  }

  Future<void> _createNote(NoteType type) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(type);
    if (mounted) await context.push('/note/$id');
  }

  @override
  Widget build(BuildContext context) {
    // Arka plan servislerini ayakta tut: ek yükleme kuyruğu, hatırlatıcı
    // bildirimleri, ana ekran widget'ı ve derin bağlantı dinleyicisi.
    ref.watch(uploadQueueProvider);
    ref.watch(reminderServiceProvider);
    ref.watch(widgetServiceProvider);
    ref.watch(deepLinkHandlerProvider);
    // Premium akışını canlı tut: AI kapısı (AiGate.consume) senkron okur.
    ref.watch(premiumProvider);
    // Paylaş menüsünden gelen içerikleri dinle (Android).
    ref.watch(shareIntakeProvider);

    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final semanticActive = ref.watch(semanticSearchEnabledProvider) &&
        query.trim().length > 2;
    final notesAsync = semanticActive
        ? ref.watch(semanticSearchProvider(query.trim()))
        : ref.watch(filteredNotesProvider);
    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final selectionActive = selectedIds.isNotEmpty;
    // Dar ekranda arama odaklıyken sağdaki butonlar gizlenir; arama alanı
    // tüm genişliği kullanır. Klavye kapatılınca (sistem geri tuşu dahil)
    // odak sürse bile bar kendiliğinden daralır — viewInsets bunu izler.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searchExpanded = _searchFocus.hasFocus &&
        keyboardOpen &&
        MediaQuery.sizeOf(context).width < 600;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            _createNote(NoteType.text),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    (constraints.maxWidth / 220).floor().clamp(2, 6);
                return CustomScrollView(
                  slivers: [
                    if (selectionActive)
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        pinned: true,
                        leading: IconButton(
                          tooltip: l10n.cancel,
                          icon: const Icon(Icons.close),
                          onPressed: () => ref
                              .read(selectedNoteIdsProvider.notifier)
                              .clear(),
                        ),
                        title: Text(l10n.selectedCount(selectedIds.length)),
                        actions: [
                          IconButton(
                            tooltip: l10n.deleteSelected,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteSelected(selectedIds),
                          ),
                          const SizedBox(width: 4),
                        ],
                      )
                    else
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        titleSpacing: searchExpanded ? 0 : 12,
                        // Genişkenken geri oku: odağı bırakır, bar daralır.
                        leading: searchExpanded
                            ? IconButton(
                                tooltip: l10n.close,
                                icon: const Icon(Icons.arrow_back),
                                onPressed: _searchFocus.unfocus,
                              )
                            : null,
                        automaticallyImplyLeading: false,
                        title: _SearchField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                        ),
                        actions: searchExpanded
                            ? const [SizedBox(width: 4)]
                            : [
                                IconButton(
                                  tooltip: l10n.translatorTitle,
                                  icon: const Icon(Icons.translate),
                                  onPressed: () => context.push('/translate'),
                                ),
                                IconButton(
                                  tooltip: l10n.chatTitle,
                                  icon: const Icon(Icons.forum_outlined),
                                  onPressed: () => context.push('/chat'),
                                ),
                                IconButton(
                                  tooltip: l10n.aiSuggestions,
                                  icon:
                                      const Icon(Icons.auto_awesome_outlined),
                                  onPressed: () =>
                                      context.push('/suggestions'),
                                ),
                                IconButton(
                                  tooltip: l10n.importantEmails,
                                  icon: const Icon(
                                      Icons.mark_email_unread_outlined),
                                  onPressed: () => context.push('/mail'),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) => switch (action) {
                                    'briefing' => context.push('/briefing'),
                                    'reminders' => context.push('/reminders'),
                                    'archive' => context.push('/archive'),
                                    'trash' => context.push('/trash'),
                                    'settings' => context.push('/settings'),
                                    _ => null,
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'briefing',
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                            Icons.wb_sunny_outlined),
                                        title: Text(l10n.briefingTitle),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'reminders',
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading:
                                            const Icon(Icons.alarm_outlined),
                                        title: Text(l10n.remindersTitle),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'archive',
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                            Icons.archive_outlined),
                                        title: Text(l10n.archiveTitle),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'trash',
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading:
                                            const Icon(Icons.delete_outline),
                                        title: Text(l10n.trashTitle),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'settings',
                                      child: ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                            Icons.settings_outlined),
                                        title: Text(l10n.settings),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                              ],
                      ),
                    SliverToBoxAdapter(
                      child: _QuickAddBar(onCreate: _createNote),
                    ),
                    const SliverToBoxAdapter(child: _FilterChips()),
                    const SliverToBoxAdapter(child: _TagChips()),
                    ...notesAsync.when(
                      data: (notes) => _buildNoteSlivers(
                        context,
                        notes,
                        columns,
                        searchActive: query.trim().isNotEmpty,
                      ),
                      loading: () => [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                      error: (e, _) => [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.error_outline,
                            title: l10n.genericError(e.toString()),
                          ),
                        ),
                      ],
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                );
              },
            ),
          ),
          // Asistanın durumu (kayıt + canlı döküm, işleme, sonuç, hata) artık
          // en dipte değil, FAB sütununda düğmelerin ÜSTÜnde yüzer — daha
          // ortada ve okunaklı; boştayken gizli. Genişlik ekranı doldurur
          // ama sağdaki düğmeler yerinde kalır (crossAxisAlignment.end).
          floatingActionButton: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  (MediaQuery.sizeOf(context).width - 24).clamp(0.0, 460.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const VoiceAssistantPanel(),
                // Sesli Not Asistanı: sayfa değiştirmeden burada dinler.
                const VoiceAssistantButton(),
                const SizedBox(height: 6),
                FloatingActionButton(
                  heroTag: 'add-fab',
                  tooltip: l10n.newTextNote,
                  onPressed: () => _createNote(NoteType.text),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNoteSlivers(
    BuildContext context,
    List<Note> notes,
    int columns, {
    required bool searchActive,
  }) {
    final l10n = context.l10n;
    if (notes.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: searchActive
              ? EmptyState(icon: Icons.search_off, title: l10n.emptySearch)
              : EmptyState(
                  icon: Icons.sticky_note_2_outlined,
                  title: l10n.emptyNotes,
                  subtitle: l10n.emptyNotesHint,
                ),
        ),
      ];
    }

    final pinned = [for (final n in notes) if (n.pinned) n];
    final others = [for (final n in notes) if (!n.pinned) n];

    final query = ref.read(searchQueryProvider).trim();
    Widget grid(List<Note> items) => SliverMasonryGrid.count(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childCount: items.length,
          itemBuilder: (context, index) => NoteCard(
            key: ValueKey(items[index].id),
            note: items[index],
            highlightQuery: query,
          ),
        );

    Widget header(String text) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.1,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );

    const gridPadding = EdgeInsets.symmetric(horizontal: 12);

    if (pinned.isEmpty || others.isEmpty) {
      return [
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverPadding(padding: gridPadding, sliver: grid(notes)),
      ];
    }
    return [
      header(l10n.sectionPinned),
      SliverPadding(padding: gridPadding, sliver: grid(pinned)),
      header(l10n.sectionOthers),
      SliverPadding(padding: gridPadding, sliver: grid(others)),
    ];
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField({required this.controller, this.focusNode});

  final TextEditingController controller;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final semantic = ref.watch(semanticSearchEnabledProvider);
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (value) => ref.read(searchQueryProvider.notifier).set(value),
      // Alan dışına dokununca odak bırakılır; bar daralır, butonlar döner.
      onTapOutside: (_) => focusNode?.unfocus(),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText:
            semantic ? context.l10n.semanticSearchHint : context.l10n.searchHint,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.semanticSearchToggle,
              icon: Icon(
                Icons.auto_awesome,
                size: 18,
                color: semantic ? scheme.primary : scheme.onSurfaceVariant,
              ),
              onPressed: () =>
                  ref.read(semanticSearchEnabledProvider.notifier).toggle(),
            ),
            if (query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).set('');
                },
              ),
          ],
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

/// Keep tarzı hızlı ekleme çubuğu: tıkla → metin notu; sağdaki ikonlar
/// diğer tipleri tek dokunuşla oluşturur.
class _QuickAddBar extends StatelessWidget {
  const _QuickAddBar({required this.onCreate});

  final Future<void> Function(NoteType) onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Material(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onCreate(NoteType.text),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.quickAddHint,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.newChecklist,
                        icon: const Icon(Icons.check_box_outlined, size: 20),
                        onPressed: () => onCreate(NoteType.checklist),
                      ),
                      IconButton(
                        tooltip: l10n.newOrderedList,
                        icon: const Icon(
                          Icons.format_list_numbered_rounded,
                          size: 20,
                        ),
                        onPressed: () => onCreate(NoteType.ordered),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Notlarda kullanılan etiketlerin filtre çipleri (etiket yoksa gizli).
/// Etiketler çoğaldıkça satır şişmesin diye yalnızca en sık kullanılanlar
/// gösterilir; kalanlar "+N" çipinin açtığı listeden seçilir.
class _TagChips extends ConsumerWidget {
  const _TagChips();

  static const _maxVisible = 8;

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
    final counts = ref.watch(tagCountsProvider);
    final selected = ref.watch(selectedTagProvider);
    if (counts.isEmpty) return const SizedBox.shrink();

    final byUsage = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    final visible = byUsage.take(_maxVisible).toList();
    // Seçili etiket gizli kalmasın: listede yoksa başa al.
    if (selected != null && counts.containsKey(selected) &&
        !visible.contains(selected)) {
      visible.insert(0, selected);
    }
    final hidden = byUsage.length - visible.length;
    final allSorted = ref.watch(allTagsProvider);

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: visible.length + (hidden > 0 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return ActionChip(
              label: Text('+$hidden'),
              onPressed: () =>
                  _showAllTags(context, ref, allSorted, selected),
            );
          }
          final tag = visible[index];
          return FilterChip(
            label: Text('#$tag'),
            selected: selected == tag,
            onSelected: (isSelected) => ref
                .read(selectedTagProvider.notifier)
                .set(isSelected ? tag : null),
          );
        },
      ),
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(noteFilterProvider);

    final entries = <(NoteFilter, String)>[
      (NoteFilter.all, l10n.filterAll),
      (NoteFilter.text, l10n.filterText),
      (NoteFilter.checklist, l10n.filterChecklist),
      (NoteFilter.ordered, l10n.filterOrdered),
      (NoteFilter.pinned, l10n.filterPinned),
      (NoteFilter.starred, l10n.filterStarred),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final (filter, label) = entries[index];
          return FilterChip(
            label: Text(label),
            selected: selected == filter,
            onSelected: (_) =>
                ref.read(noteFilterProvider.notifier).set(filter),
          );
        },
      ),
    );
  }
}
