import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ai/data/semantic_search.dart' show SemanticScope;
import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/filter_sheet.dart';
import '../../notes/presentation/note_grid.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/presentation/quick_add_actions.dart';
import '../../notes/presentation/quick_add_fab.dart';
import '../../notes/presentation/screen_search.dart';
import '../data/folder_activity.dart';
import '../data/folder_order.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_chat_screen.dart';
import 'folder_sheets.dart';
import '../../../core/friendly_error.dart';

/// **KLASÖRÜN KENDİ SAYFASI.**
///
/// Kullanıcı isteği 2026-08-18: "şu an etiketle klasör aynı şey; klasör
/// mantığı şu olsun: klasör dashboard'ta bir not gibi yer kaplar ama görüntüsü
/// klasör gibidir, basılınca kendi içerisindeki notlar görülür AYRI BİR
/// SAYFADA."
///
/// Eskiden klasör yalnızca bir SÜZGEÇTİ: ana ekranın çip barından seçiliyor,
/// aynı ızgara daralıyordu — yani etiketin yaptığı işin aynısı. Klasör artık
/// bir YER: ana ekranda karosu var, içine girilir, içinden çıkılır.
///
/// **PAYLAŞILAN klasörler de AYNI ekranı kullanır** (kullanıcı isteği
/// 2026-08-18: "ortak notlar klasörü kişiler bağlanır notları ortak görür").
/// [ownerId] verilmezse (ya da kendi uid'imse) BENİM klasörümdür — eski yol.
/// Başka bir uid verilirse bir arkadaşın PAYLAŞTIĞI klasördür: klasör ve
/// notlar SAHİBİNİN koleksiyonundan okunur/yazılır (bkz.
/// `sharedFolderNotesProvider`), kopyalanmaz.
///
/// Rota DEĞİL, `Navigator.push` ile açılır: geniş ekranda GoRouter kabuğu
/// (SplitShell) sağ paneli not editörüne ayırıyor; klasör listesi oraya
/// sıkışmamalı, tam sayfa açılmalı.
class FolderScreen extends ConsumerStatefulWidget {
  const FolderScreen({super.key, required this.folderId, this.ownerId});

  final String folderId;

  /// null = kendi klasörüm. Dolu ve benden farklıysa paylaşılan bir klasör.
  final String? ownerId;

  /// **KENDİ KLASÖRÜM = SÜZGEÇLİ ANA EKRAN** (kullanıcı isteği 2026-10-28:
  /// "klasörün kendi sayfası ve dashboard aynı olsun, klasör sanki filtre
  /// uygulanmış gibi olsun"). Kendi klasörüm ayrı sayfa açmaz: ana ekran o
  /// klasöre SÜZÜLÜR (`selectedFolderProvider`) — aynı ızgara, aynı kartlar,
  /// aynı arama/süz/seçim/sıralama, "+" yeni notu klasöre koyar. Süz
  /// düğmesinde klasörün adı ve × görünür; geri tuşu süzgeci kaldırır.
  ///
  /// PAYLAŞILAN klasör ([ownerId] dolu) başka kullanıcının koleksiyonundan
  /// okunur — ana ekranın akışında yok; o hâlâ bu sayfada açılır.
  static Future<void> open(
    BuildContext context,
    String folderId, {
    String? ownerId,
  }) {
    if (ownerId == null) {
      showFolderOnHome(context, folderId);
      return Future.value();
    }
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FolderScreen(folderId: folderId, ownerId: ownerId),
      ),
    );
  }

  /// Ana ekranı [folderId] klasörüne süzer; ana ekran dışındaysa (Klasörler
  /// sayfası, arşiv…) ana ekrana döner. Klasörü açmak oradaki her şeyi
  /// okunmuş sayar (rozet söner — eski klasör sayfasıyla aynı).
  static void showFolderOnHome(BuildContext context, String folderId) {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(noteFilterProvider.notifier).set(NoteFilter.all);
    container.read(selectedTagProvider.notifier).set(null);
    container.read(selectedFolderProvider.notifier).set(folderId);
    container.read(folderSeenProvider.notifier).markSeen(folderId);
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    // Sayfasız rota (ör. klasör levhası) üstteyse ana ekrana kadar kapanır.
    Navigator.of(context).popUntil((route) => route.settings is Page);
    if (!isSplitShellLocation(router.state.uri.path)) router.go('/');
  }

  /// Yana çekişle KOMŞU klasöre geçer (kullanıcı isteği 2026-09-26:
  /// "sağ sol kaydırmada klasörler arası geçiş"). Yığın BÜYÜMEZ: sayfa
  /// yerini komşusuna bırakır, geri tuşu yine ana ekrana döner. Geçiş
  /// parmağın yönünde kayar.
  static Future<void> replaceWith(
    BuildContext context,
    String folderId, {
    required bool forward,
  }) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final from = (forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => FolderScreen(folderId: folderId),
        transitionsBuilder: (context, animation, secondary, child) =>
            SlideTransition(
              position: Tween(
                begin: Offset(from, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
      ),
    );
  }

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen>
    with QuickAddActions {
  /// **OKUNDU damgası**: klasörü açmak oradaki her şeyi okunmuş sayar —
  /// ana ekrandaki rozet (ve duran bildirim) böyle söner. Kare SONUNDA:
  /// build sırasında sağlayıcı yazmak yasak.
  void _markSeenSoon(String folderId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(folderSeenProvider.notifier).markSeen(folderId);
    });
  }

  /// "+" menüsünün demirlendiği nokta (bkz. QuickAddFab.anchor).
  final _fabLink = LayerLink();

  /// **KLASÖR İÇİ ARAMA** (kullanıcı bulgusu 2026-09-01: "klasör içerisinde
  /// ayarlar eksik, arama yok vb. ek özellikler eksik").
  ///
  /// Klasör bir YER olduğundan (bkz. sınıf açıklaması) ana ekranın arama
  /// kutusu buraya erişmiyordu: kullanıcı klasöre girip yüz notun arasında
  /// aradığını gözle bulmak zorundaydı. Kutu üst barda, dokunmadan
  /// görünmez — açılınca aramaya odaklanır, kapanınca sorgu düşer.
  final _search = ScreenSearch();

  /// Seçim kümesi ana ekranla ORTAK sağlayıcıda; klasörden çıkınca
  /// boşaltılır (ana ekrana seçili kartlarla dönülmesin). `dispose`ta `ref`
  /// kullanılamaz — denetleyici build'de alınır.
  SelectedNoteIdsNotifier? _selection;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => setState(() {});

  @override
  void dispose() {
    _search.dispose();
    final selection = _selection;
    // Ağaç sökülürken sağlayıcı yazılmaz: bir sonraki mikro göreve.
    if (selection != null) Future.microtask(selection.clear);
    super.dispose();
  }

  // ── Seçim kipi toplu işleri (ana ekranla aynı işler; kullanıcı isteği
  // 2026-10-28: "dashboard'da ne varsa klasörde de aynı olmalı"). Eskiden
  // kartın ⋮ → "Seç"i klasörde seçimi açıyor ama hiçbir işlem çubuğu
  // çıkmıyordu.

  void _clearSelection() => ref.read(selectedNoteIdsProvider.notifier).clear();

  Future<void> _deleteSelected(Set<String> ids, List<Note> notes) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    if (notes.any((n) => ids.contains(n.id) && n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    if (!mounted) return;
    _clearSelection();
    unawaited(repo.softDeleteAll(ids));
    showUndoSnackBar(
      context,
      message: l10n.notesDeletedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.restoreAll(ids),
    );
  }

  void _archiveSelected(Set<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    unawaited(repo.setArchivedAll(ids, true));
    _clearSelection();
    showUndoSnackBar(
      context,
      message: l10n.notesArchivedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.setArchivedAll(ids, false),
    );
  }

  Future<void> _moveSelected(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    final picked = await showFolderPickSheet(context, ref);
    if (picked == null || !mounted) return;
    unawaited(
      repo.batchUpdate(ids, {'folderId': picked.isEmpty ? null : picked}),
    );
    _clearSelection();
    showUndoSnackBar(
      context,
      message: l10n.notesMovedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.batchUpdate(ids, {'folderId': widget.folderId}),
    );
  }

  void _updateSelected(Set<String> ids, Map<String, Object?> fields) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    unawaited(repo.batchUpdate(ids, fields));
    _clearSelection();
  }

  PreferredSizeWidget _selectionBar(List<Note> visible) {
    final l10n = context.l10n;
    final ids = ref.watch(selectedNoteIdsProvider);
    final visibleIds = [for (final n in visible) n.id];
    final allSelected = visibleIds.isNotEmpty && visibleIds.every(ids.contains);
    return AppBar(
      leading: IconButton(
        tooltip: l10n.cancel,
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text(l10n.selectedCount(ids.length)),
      actions: [
        IconButton(
          tooltip: allSelected ? l10n.selectNone : l10n.selectAll,
          icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
          onPressed: () =>
              ref.read(selectedNoteIdsProvider.notifier).selectAll(visibleIds),
        ),
        IconButton(
          tooltip: l10n.moveToFolder,
          icon: const Icon(Icons.drive_file_move_outline),
          onPressed: () => _moveSelected(ids),
        ),
        IconButton(
          tooltip: l10n.archive,
          icon: const Icon(Icons.archive_outlined),
          onPressed: () => _archiveSelected(ids),
        ),
        IconButton(
          tooltip: l10n.deleteSelected,
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteSelected(ids, visible),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.moreActions,
          onSelected: (action) => switch (action) {
            'pin' => _updateSelected(ids, {'pinned': true}),
            'unpin' => _updateSelected(ids, {'pinned': false}),
            'star' => _updateSelected(ids, {'starred': true}),
            _ => _updateSelected(ids, {'starred': false}),
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'pin', child: Text(l10n.pin)),
            PopupMenuItem(value: 'unpin', child: Text(l10n.unpin)),
            PopupMenuItem(value: 'star', child: Text(l10n.star)),
            PopupMenuItem(value: 'unstar', child: Text(l10n.unstar)),
          ],
        ),
      ],
    );
  }

  /// Yana çekiş: kullanıcının klasör sırasında sonraki/önceki klasör
  /// (bkz. `visibleOrderedFoldersProvider`). Uçlarda başa/sona SARAR — ana
  /// ekrandaki çekişle aynı halka mantığı.
  void _swipeTo(int direction) {
    final ids = [
      for (final f in ref.read(visibleOrderedFoldersProvider)) f.id,
    ];
    final index = ids.indexOf(widget.folderId);
    if (index < 0 || ids.length < 2) return;
    var next = (index + direction) % ids.length;
    if (next < 0) next += ids.length;
    HapticFeedback.selectionClick();
    FolderScreen.replaceWith(context, ids[next], forward: direction > 0);
  }

  /// Bu sayfada oluşturulan her not, doğrudan BU klasöre doğar.
  @override
  String? get quickAddFolderId => widget.folderId;

  @override
  Future<void> openNewNote(
    String id, {
    String query = '',
    NoteType? type,
  }) async {
    if (!mounted) return;
    await context.pushNote(noteRoutePath(id, query: query));
  }

  @override
  Widget build(BuildContext context) {
    final folderId = widget.folderId;
    final ownerId = widget.ownerId;
    final l10n = context.l10n;
    final myUid = ref.watch(currentUidProvider);
    final shared = ownerId != null && ownerId != myUid;

    if (shared) return _SharedFolderView(folderId: folderId, ownerId: ownerId);

    _markSeenSoon(folderId);
    final folders = ref.watch(foldersStreamProvider).value;
    final folder = folders?.where((f) => f.id == folderId).firstOrNull;
    final rawAsync = ref.watch(folderNotesProvider(folderId));
    final folderFilter = ref.watch(
      folderFilterProvider.select((m) => m[folderId]),
    );
    final notesAsync = rawAsync.whenData(
      (list) => applyFolderFilter(list, folderFilter),
    );
    _selection = ref.read(selectedNoteIdsProvider.notifier);
    final selecting = ref.watch(
      selectedNoteIdsProvider.select((s) => s.isNotEmpty),
    );
    final filterLabels = [
      if (folderFilter != null && folderFilter.filter != NoteFilter.all)
        filterLabel(l10n, folderFilter.filter),
      if (folderFilter?.tag != null) '#${folderFilter!.tag}',
    ];

    // Klasör silinmiş olabilir (başka cihazdan): sayfa boş bir kabuk olarak
    // kalmaz, kendiliğinden kapanır.
    if (folders != null && folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    return PopScope(
      // Geri tuşu önce seçimi bırakır (ana ekranla aynı kural).
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: selecting
            ? _selectionBar(notesAsync.value ?? const [])
            : AppBar(
                title: _search.open
                    ? ScreenSearchField(search: _search)
                    : _FolderTitle(
                        icon: folder?.iconData,
                        name: folder?.name,
                        count: rawAsync.value?.length,
                      ),
                actions: [
                  // ✨ AI araması klasörde de (B4).
                  ...screenSearchActions(context, _search),
                  // SÜZ (ana ekrandakiyle aynı levha): durum ve etiket KLASÖRE
                  // özgü, görünüm ve SIRALAMA ana ekranla ORTAK (bkz.
                  // folderNotesProvider) — kullanıcının seçtiği düzen her yerde
                  // aynı olsun. Eskiden burada yalnız sıralama menüsü vardı.
                  IconButton(
                    key: const ValueKey('folder-filter'),
                    tooltip: l10n.filterSheetTitle,
                    isSelected: filterLabels.isNotEmpty,
                    icon: Badge(
                      isLabelVisible: filterLabels.isNotEmpty,
                      smallSize: 8,
                      child: const Icon(Icons.tune),
                    ),
                    onPressed: () =>
                        showFilterSheet(context, folderId: folderId),
                  ),
                  // Sohbet, PAYLAŞILMIŞ klasörde tek dokunuş uzakta olsun: sahip de
                  // katılımcılar da aynı odayı kullanıyor (bkz. FolderChatScreen).
                  if (folder != null && folder.sharedWith.isNotEmpty)
                    IconButton(
                      tooltip: l10n.folderChatTitle,
                      icon: const Icon(Icons.forum_outlined),
                      onPressed: () => FolderChatScreen.open(
                        context,
                        folderId: folder.id,
                        folderName: folder.name,
                      ),
                    ),
                  if (folder != null)
                    IconButton(
                      tooltip: l10n.folderManage,
                      icon: const Icon(Icons.more_vert),
                      onPressed: () =>
                          showFolderActionsSheet(context, ref, folder),
                    ),
                ],
              ),
        // Ana ekrandakinin AYNISI (+ sesli not: klasörde ayrı mikrofon yok).
        // Davranış [QuickAddActions] ile ORTAK, kopya değil.
        floatingActionButton: CompositedTransformTarget(
          link: _fabLink,
          child: QuickAddFab(
            anchor: _fabLink,
            actions: this,
            onVoiceCapture: createVoiceCaptureNote,
          ),
        ),
        // Kutu değişince ızgara yeniden süzülsün: sorgu denetleyicide durur,
        // dinleyici yalnız gövdeyi çizer (üst bar aynı kalır).
        body: GestureDetector(
          // Dikey kaydırma ızgarada kalır; eksenler farklı, çakışmaz. Arama
          // açıkken kapalı: kullanıcı sonuçlar arasındayken klasör değişmesin.
          onHorizontalDragEnd:
              _search.open || ref.watch(swipeModeProvider) == SwipeMode.off
              ? null
              : (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity.abs() < 300) return;
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  final forward = rtl ? velocity > 0 : velocity < 0;
                  _swipeTo(forward ? 1 : -1);
                },
          child: Column(
            children: [
              // UYGULANAN SÜZGEÇ: adı + × (ana ekrandaki Süz düğmesinin
              // karşılığı) — boş klasör sanılmasın.
              if (filterLabels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: InputChip(
                      key: const ValueKey('folder-filter-chip'),
                      avatar: const Icon(Icons.tune, size: 16),
                      label: Text(filterLabels.join(' · ')),
                      onPressed: () =>
                          showFilterSheet(context, folderId: folderId),
                      onDeleted: () => ref
                          .read(folderFilterProvider.notifier)
                          .set(folderId, kNoFolderFilter),
                    ),
                  ),
                ),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _search.controller,
                  builder: (context, value, _) => _NotesGrid(
                    async: notesAsync,
                    query: value.text,
                    semantic: _search.semantic,
                    folderId: folderId,
                    filtered: filterLabels.isNotEmpty,
                    onCreateNote: () => createNote(NoteType.text),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderTitle extends StatelessWidget {
  const _FolderTitle({required this.icon, required this.name, this.count});

  final IconData? icon;
  final String? name;

  /// Klasördeki not sayısı (biliniyorsa) — adın altında küçük satır.
  /// Klasörün ne kadar dolu olduğu içine girmeden de görünsün.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon ?? Icons.folder_outlined, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name ?? context.l10n.filterSectionFolder,
                overflow: TextOverflow.ellipsis,
              ),
              if (count != null)
                Text(
                  context.l10n.folderNoteCount(count!),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotesGrid extends ConsumerWidget {
  const _NotesGrid({
    required this.async,
    this.ownerId,
    this.readOnly = false,
    this.query = '',
    this.semantic = false,
    this.folderId,
    this.onCreateNote,
    this.filtered = false,
  });

  /// Klasör süzgeci uygulanmış mı (boş sonuçta "boş klasör" denmesin).
  final bool filtered;

  /// AI (anlamsal) arama açık mı; [folderId] kendi klasörümde verilir
  /// (paylaşılan klasörde AI yok — notlar başkasının).
  final bool semantic;
  final String? folderId;

  /// Boş klasörde gösterilen "Metin notu" düğmesi. null = düğme çizilmez
  /// (yalnız-okuma yetkisiyle açılmış paylaşılan klasör).
  final VoidCallback? onCreateNote;

  final AsyncValue<List<Note>> async;

  /// Klasör içi arama sorgusu; boşsa süzgeç yoktur. Eşleşme kuralı ana
  /// ekranınkiyle AYNI işlevden gelir (bkz. [noteMatchesQuery]).
  final String query;

  /// Paylaşılan klasörde notların SAHİBİ — kart bunu editöre taşır, yoksa
  /// not kendi koleksiyonumda aranır ve "bulunamadı" olur.
  final String? ownerId;

  /// Yalnız okuma yetkisi: editör kilitli açılır.
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // Sütun sayısı ANA EKRANLA ortak: kullanıcı orada iki parmakla seçtiği
    // yoğunluğu klasörde de görsün (sıralamayla aynı gerekçe). 0 = otomatik.
    final fixedColumns = ref.watch(gridColumnsProvider);
    final listView = ref.watch(noteListViewProvider);
    final selectionActive = ref.watch(
      selectedNoteIdsProvider.select((s) => s.isNotEmpty),
    );
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          EmptyState(icon: Icons.error_outline, title: l10n.genericError(friendlyError(l10n, e))),
      data: (all) {
        final result = runScreenSearch(
          ref,
          all,
          query,
          semantic: semantic,
          scope: folderId == null ? null : SemanticScope.folder,
          folderId: folderId,
        );
        final notes = result.notes;
        final needle = result.needle;
        if (notes.isEmpty && result.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return notes.isEmpty
          ? (needle.isEmpty && !filtered
              ? EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: l10n.folderEmpty,
                  subtitle: l10n.folderEmptyHint,
                  // Boş klasörde istenen şey belli: bir not. Kullanıcı
                  // eskiden ekranın dibindeki "+"yı aramak zorundaydı.
                  actionLabel: onCreateNote == null ? null : l10n.newTextNote,
                  actionIcon: Icons.add,
                  onAction: onCreateNote,
                )
              : EmptyState(
                  icon: Icons.search_off,
                  title: l10n.noteSearchNoHit,
                ))
          : Column(
              children: [
                // ARAMA SONUÇ SAYISI: sorgu doluyken kaç not eşleşti,
                // ızgaranın üstünde tek satır. Eşleşme yoksa zaten boş
                // durum çiziliyor.
                if (needle.isNotEmpty)
                  SearchResultHeader(
                    count: notes.length,
                    loading: result.loading,
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // LİSTE GÖRÜNÜMÜ ana ekranla ortak (Süz → Görünüm).
                      if (listView) {
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                          itemCount: notes.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 2),
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return Consumer(
                              key: ValueKey(note.id),
                              builder: (context, cellRef, _) {
                                final selected = cellRef.watch(
                                  selectedNoteIdsProvider.select(
                                    (s) => s.contains(note.id),
                                  ),
                                );
                                return GestureDetector(
                                  onLongPress: ownerId == null
                                      ? () => cellRef
                                            .read(
                                              selectedNoteIdsProvider.notifier,
                                            )
                                            .toggle(note.id)
                                      : null,
                                  child: NoteListRow(
                                    note: note,
                                    selected: selected,
                                    selectionActive: selectionActive,
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                      final columns = fixedColumns > 0
                          ? fixedColumns
                          : (constraints.maxWidth / 220).floor().clamp(2, 6);
                      // ANA EKRANLA AYNI IZGARA (bkz. [NoteBalancedGrid]):
                      // klasör de masonry'nin "kart sütun değiştiriyor,
                      // sağ sütunda boşluk kalıyor" hatasından kurtuldu.
                      return NoteBalancedGrid(
                        notes: notes,
                        columns: columns,
                        // Uzun basış SEÇER (ana ekranla aynı); paylaşılan
                        // klasörde toplu işler yok.
                        itemBuilder: (context, index) => GestureDetector(
                          onLongPress: ownerId == null
                              ? () => ref
                                    .read(selectedNoteIdsProvider.notifier)
                                    .toggle(notes[index].id)
                              : null,
                          child: NoteCard(
                            note: notes[index],
                            ownerId: ownerId,
                            readOnly: readOnly,
                            highlightQuery: needle,
                            showFolder: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
      },
    );
  }
}

/// Paylaşılan klasörün gövdesi: klasör dokümanı da notlar da SAHİBİNİN
/// koleksiyonundan canlı okunur (bkz. sınıf açıklaması).
///
/// **YETKİ** (kullanıcı isteği 2026-08-18): sahibin verdiği rol ekranı
/// biçimlendirir — yalnız okuma yetkisinde "yeni not" düğmesi YOK, yalnız
/// yazma yetkisinde notlar listelenmez (kural da okumayı reddeder, arayüz
/// bunu bir hata gibi değil bir açıklama gibi gösterir).
class _SharedFolderView extends ConsumerStatefulWidget {
  const _SharedFolderView({required this.folderId, required this.ownerId});

  final String folderId;
  final String ownerId;

  @override
  ConsumerState<_SharedFolderView> createState() => _SharedFolderViewState();
}

class _SharedFolderViewState extends ConsumerState<_SharedFolderView> {
  /// **OKUNDU damgası**: klasörü açmak oradaki her şeyi okunmuş sayar —
  /// ana ekrandaki rozet (ve duran bildirim) böyle söner. Kare SONUNDA:
  /// build sırasında sağlayıcı yazmak yasak.
  void _markSeenSoon(String folderId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(folderSeenProvider.notifier).markSeen(folderId);
    });
  }

  /// Paylaşılan klasörde de arama var: kendi klasörümdekiyle aynı kutu,
  /// aynı eşleşme kuralı (bkz. [_FolderScreenState._searchController]).
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
    final folderId = widget.folderId;
    final ownerId = widget.ownerId;
    final l10n = context.l10n;
    _markSeenSoon(folderId);
    // Yetki, paylaşım aynasındaki `roles` haritasından gelir; ayna zaten ana
    // ekranın raf listesi için dinleniyor, ek bir okuma maliyeti yok.
    final share = ref
        .watch(sharedFolderRefsProvider)
        .value
        ?.where((s) => s.folderId == folderId)
        .firstOrNull;
    final role = share?.role ?? FolderRole.both;
    return StreamBuilder<NoteFolder?>(
      stream: FoldersRepository.watchSharedFolder(
        FirebaseFirestore.instance,
        ownerId,
        folderId,
      ),
      builder: (context, snapshot) {
        final folder = snapshot.data;
        // Yükleniyor DEĞİL ama klasör YOK: paylaşım kaldırılmış ya da klasör
        // silinmiş. Sayfa kendiliğinden kapanır (kendi klasörümdeki kural).
        if (snapshot.connectionState != ConnectionState.waiting &&
            folder == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
        final name = folder?.name ?? share?.name;
        return Scaffold(
          appBar: AppBar(
            title: _search.open
                ? ScreenSearchField(search: _search)
                : _FolderTitle(
                    icon: folder?.iconData ?? share?.iconData,
                    name: name,
                  ),
            actions: [
              if (role.canRead)
                ...screenSearchActions(context, _search, ai: false),
              IconButton(
                tooltip: l10n.folderChatTitle,
                icon: const Icon(Icons.forum_outlined),
                onPressed: () => FolderChatScreen.open(
                  context,
                  folderId: folderId,
                  folderName: name ?? '',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Tooltip(
                  message: '${l10n.folderShared} · ${folderRoleLabel(l10n, role)}',
                  child: Icon(
                    role == FolderRole.both
                        ? Icons.people_outline
                        : Icons.lock_outline,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: role.canWrite
              ? FloatingActionButton(
                  tooltip: l10n.newTextNote,
                  // YALNIZ YAZMA yetkisinde editör AÇILAMAZ: editör notu
                  // geri OKUMAK zorunda ve okuma reddediliyor — ekran boş
                  // bir "yükleniyor"da kalırdı. O yetkide not küçük bir
                  // yazma penceresinden tek seferde bırakılır.
                  onPressed: () => role.canRead
                      ? _createNote(context)
                      : _composeWriteOnly(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: role.canRead
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _search.controller,
                  builder: (context, value, _) => _NotesGrid(
                    ownerId: ownerId,
                    readOnly: !role.canWrite,
                    query: value.text,
                    async: ref.watch(
                      sharedFolderNotesProvider((
                        ownerId: ownerId,
                        folderId: folderId,
                      )),
                    ),
                  ),
                )
              // Yalnız YAZMA yetkisi: notları göremez ama bırakabilir. Boş
              // liste yerine NEDENİ yazılır, yoksa "klasör bozuk" sanılır.
              : EmptyState(
                  icon: Icons.drive_file_move_outline,
                  title: l10n.folderWriteOnlyTitle,
                  subtitle: l10n.folderWriteOnlyHint,
                ),
        );
      },
    );
  }

  /// **YALNIZ YAZMA** yetkisinde not bırakma penceresi: başlık + metin,
  /// tek yazımda kaydedilir ve editör hiç açılmaz (kullanıcı notu geri
  /// okuyamıyor — bkz. [FolderRole.write]).
  Future<void> _composeWriteOnly(BuildContext context) async {
    final l10n = context.l10n;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.newTextNote),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.titleHint),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: l10n.bodyHint),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      final title = titleController.text.trim();
      final body = bodyController.text.trim();
      if (!(saved ?? false) || (title.isEmpty && body.isEmpty)) return;
      final repo = NotesRepository(
        FirebaseFirestore.instance,
        widget.ownerId,
        editorUid: ref.read(currentUidProvider),
      );
      final id = await repo.createNote(
        NoteType.text,
        folderId: widget.folderId,
        body: body,
      );
      if (title.isNotEmpty) repo.updateFields(id, {'title': title});
    } finally {
      // finally İÇİNDE: diyalog fırlarsa ya da rota programlı kapanırsa
      // denetleyiciler sızardı (klasör düzenleme diyaloğuyla aynı gerekçe).
      titleController.dispose();
      bodyController.dispose();
    }
  }

  /// Paylaşılan klasöre yeni not: not SAHİBİN koleksiyonuna yazılır
  /// (klasörle birlikte yaşasın diye — bkz. sınıf açıklaması).
  Future<void> _createNote(BuildContext context) async {
    final repo = NotesRepository(
      FirebaseFirestore.instance,
      widget.ownerId,
      editorUid: ref.read(currentUidProvider),
    );
    final id = await repo.createNote(NoteType.text, folderId: widget.folderId);
    if (!context.mounted) return;
    await openNoteRoute(
      context,
      Note(id: id, type: NoteType.text, folderId: widget.folderId),
      ownerId: widget.ownerId,
    );
  }
}
