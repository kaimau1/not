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
import 'dashboard_chips.dart';
import 'note_card.dart';
import 'notes_providers.dart';
import 'quick_add_fab.dart';
import 'voice_assistant.dart';
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
    // Widget/derin bağlantı bu ekran mount olmadan önce bas-başlat istemiş
    // olabilir (uygulama kapalıyken ya da başka ekrandayken). İlk kareden
    // sonra kontrol et; take() varsa asistanı başlatır.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeAutostartVoice());
  }

  /// Ana ekran mikrofon widget'ının bas-başlat isteği varsa Sesli Not
  /// Asistanı'nı başlatır (tek seferlik — bayrak take ile tüketilir).
  void _maybeAutostartVoice() {
    if (!mounted) return;
    if (ref.read(voiceAutostartProvider.notifier).take()) {
      ref.read(voiceAssistantProvider.notifier).start(
            micPermissionDeniedText: context.l10n.micPermissionDenied,
          );
    }
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
    // Aktif bir klasör filtresi varsa yeni not o klasöre doğar.
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id');
  }

  /// El yazısı modu: not oluşturulur ve editör doğrudan çizim tuvalini
  /// açarak başlar; çizim nota görsel eki olarak kaydedilir.
  Future<void> _createHandwritingNote() async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text);
    final folderId = ref.read(selectedFolderProvider);
    if (folderId != null) repo.updateFields(id, {'folderId': folderId});
    if (mounted) await context.push('/note/$id?draw=1');
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

    // Ana ekran mikrofon widget'ından (notlar://voice) gelen bas-başlat
    // isteği: uygulama zaten ana sayfadayken gelirse burada yakalanır.
    // (Uygulama başka ekrandayken/soğuk açılışta gelen istek initState'teki
    // kontrolle okunur; take() çift başlatmayı önler.)
    ref.listen(voiceAutostartProvider, (previous, next) {
      if (next) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _maybeAutostartVoice());
      }
    });

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
            child: Stack(
              children: [
                LayoutBuilder(
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
                    // Filtre + klasör + etiket çipleri tek kompakt satırda.
                    const SliverToBoxAdapter(child: DashboardChipsRow()),
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
                // Sesli asistan paneli düğmelerin ÜSTÜnde sabit konumda yüzer.
                // Düğmeler floatingActionButton'da kaldığından panel açılıp
                // kapanırken yerinden oynamaz (stabil); yalnız kayıt/işleme/
                // sonuç sırasında görünür, ana sayfanın ortasına yakın.
                const Positioned(
                  left: 8,
                  right: 8,
                  bottom: 168,
                  child: VoiceAssistantPanel(),
                ),
                // Düğmeler Scaffold.floatingActionButton yerine BURADA durur:
                // Scaffold bir FAB tanıdığında yüzen bildirimleri ("not
                // silindi") onun ÜSTÜne iter. Düğmeler Stack'te olunca
                // bildirim ekranın dibinde, düğmelerin solunda kalır.
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Sesli Not Asistanı: sayfa değiştirmeden burada dinler.
                      const VoiceAssistantButton(),
                      const SizedBox(height: 6),
                      // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                      QuickAddFab(
                        onCreate: _createNote,
                        onHandwriting: _createHandwritingNote,
                      ),
                    ],
                  ),
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
