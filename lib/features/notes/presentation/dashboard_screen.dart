import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/ai_gate.dart';
import '../../ai/data/semantic_search.dart';
import '../../ai/presentation/read_document.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../data/notes_repository.dart';
import '../data/reminder_service.dart';
import '../data/share_intake.dart';
import '../data/upload_queue.dart';
import '../data/widget_service.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'color_picker_sheet.dart';
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

  /// "+" menüsünün demirlendiği nokta: mikrofon + "+" sütununun tamamı.
  final _fabColumnLink = LayerLink();

  /// Filtreler arası geçiş yönü (madde 2): sola çekiş → sonraki (sağdan girer),
  /// sağa çekiş → önceki (soldan girer). Geçiş animasyonu bu yönü kullanır.
  bool _swipeForward = true;

  @override
  void initState() {
    super.initState();
    // Odak değişince aksiyon butonlarını gizle/göster (dar ekranlarda arama
    // alanına yer açmak için).
    _searchFocus.addListener(() => setState(() {}));
    // Widget/derin bağlantı bu ekran mount olmadan önce bas-başlat istemiş
    // olabilir (uygulama kapalıyken ya da başka ekrandayken). İlk kareden
    // sonra kontrol et; take() varsa asistanı başlatır.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutostartVoice());
  }

  /// Ana ekran mikrofon widget'ının bas-başlat isteği varsa Sesli Not
  /// Asistanı'nı başlatır (tek seferlik — bayrak take ile tüketilir).
  void _maybeAutostartVoice() {
    if (!mounted) return;
    if (ref.read(voiceAutostartProvider.notifier).take()) {
      ref
          .read(voiceAssistantProvider.notifier)
          .start(micPermissionDeniedText: context.l10n.micPermissionDenied);
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

  List<Note> _selectedNotes(Set<String> ids) {
    final all = ref.read(notesStreamProvider).value ?? const <Note>[];
    return [
      for (final n in all)
        if (ids.contains(n.id)) n,
    ];
  }

  void _archiveSelected(Set<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    for (final id in ids) {
      repo.setArchived(id, true);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesArchivedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final id in ids) {
          repo.setArchived(id, false);
        }
      },
    );
  }

  void _setPinnedSelected(Set<String> ids, bool pinned) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final id in ids) {
      repo.setPinned(id, pinned);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  void _setStarredSelected(Set<String> ids, bool starred) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final id in ids) {
      repo.setStarred(id, starred);
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  /// Seçili notların metnini birleştirir. Kilitli notlardan yalnız başlık
  /// alınır (içerik kimlik doğrulaması olmadan sızmasın).
  String _joinSelected(Set<String> ids) {
    final parts = [
      for (final n in _selectedNotes(ids))
        if (n.locked) n.title.trim() else n.toPlainText(),
    ];
    return parts.where((t) => t.trim().isNotEmpty).join('\n\n———\n\n');
  }

  Future<void> _copySelected(Set<String> ids) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: _joinSelected(ids)));
    ref.read(selectedNoteIdsProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.copied)));
  }

  Future<void> _shareSelected(Set<String> ids) async {
    final text = _joinSelected(ids);
    ref.read(selectedNoteIdsProvider.notifier).clear();
    if (text.trim().isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _colorSelected(Set<String> ids, {required bool frame}) async {
    final picked = await showNoteColorPicker(context, frame: frame);
    if (picked == null) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final id in ids) {
      if (frame) {
        repo.setFrameColor(id, picked);
      } else {
        repo.setColor(id, picked);
      }
    }
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  /// Dashboard sıralama ölçütünü seçtiren alt sayfa.
  Future<void> _pickSort() async {
    final l10n = context.l10n;
    final current = ref.read(noteSortProvider);
    final options = <(NoteSort, String, IconData)>[
      (NoteSort.manual, l10n.sortManual, Icons.drag_indicator),
      (NoteSort.updated, l10n.sortUpdated, Icons.update),
      (NoteSort.created, l10n.sortCreated, Icons.schedule_outlined),
      (NoteSort.title, l10n.sortTitle, Icons.sort_by_alpha),
    ];
    final picked = await showModalBottomSheet<NoteSort>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l10n.sortBy,
                style: Theme.of(sheetContext).textTheme.titleSmall,
              ),
            ),
            for (final (sort, label, icon) in options)
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                trailing: current == sort
                    ? Icon(
                        Icons.check,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, sort),
              ),
          ],
        ),
      ),
    );
    if (picked != null) ref.read(noteSortProvider.notifier).set(picked);
  }

  /// Ana ekranı yatay çekince (madde 1) aktif görünümü sonraki/önceki
  /// segmente taşır. Gezinme sırası: Tümü → görünür filtreler (kullanıcı
  /// sırası) → klasörler. [direction] +1 sola çekiş (sonraki), -1 sağa çekiş.
  void _cycleFilterFolder(int direction) {
    final visibleFilters = ref.read(visibleNoteFiltersProvider);
    final folders =
        ref.read(foldersStreamProvider).value ?? const <NoteFolder>[];
    final segments = <(NoteFilter, String?)>[
      (NoteFilter.all, null),
      for (final f in visibleFilters) (f, null),
      for (final folder in folders) (NoteFilter.all, folder.id),
    ];
    if (segments.length < 2) return;
    final curFilter = ref.read(noteFilterProvider);
    final curFolder = ref.read(selectedFolderProvider);
    var index = segments.indexWhere(
      (s) => s.$1 == curFilter && s.$2 == curFolder,
    );
    if (index < 0) index = 0;
    var next = (index + direction) % segments.length;
    if (next < 0) next += segments.length;
    final (filter, folderId) = segments[next];
    // Geçiş animasyonunun yönünü çekiş yönüne göre ayarla (madde 2).
    _swipeForward = direction > 0;
    ref.read(noteFilterProvider.notifier).set(filter);
    ref.read(selectedFolderProvider.notifier).set(folderId);
    HapticFeedback.selectionClick();
  }

  /// Bir bölümde (sabitliler / diğerleri) notu basılı tutup sürükleyince
  /// (madde 1) çağrılır: [draggedId] notunu [toIndex] konumuna taşır ve yeni
  /// sırayı kalıcılaştırır. Elle sıra görünsün diye sıralama ölçütü manuel'e
  /// alınır.
  void _reorderSection(List<Note> section, String draggedId, int toIndex) {
    final from = section.indexWhere((n) => n.id == draggedId);
    if (from < 0 || from == toIndex) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final list = [...section];
    final item = list.removeAt(from);
    var target = toIndex;
    if (from < target) target -= 1;
    list.insert(target, item);
    if (ref.read(noteSortProvider) != NoteSort.manual) {
      ref.read(noteSortProvider.notifier).set(NoteSort.manual);
    }
    repo.reorderNotes(list);
    HapticFeedback.mediumImpact();
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
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeAutostartVoice(),
        );
      }
    });

    final l10n = context.l10n;
    final query = ref.watch(searchQueryProvider);
    final semanticActive =
        ref.watch(semanticSearchEnabledProvider) && query.trim().length > 2;
    final notesAsync = semanticActive
        ? ref.watch(semanticSearchProvider(query.trim()))
        : ref.watch(filteredNotesProvider);
    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final selectionActive = selectedIds.isNotEmpty;
    // Dar ekranda arama odaklıyken sağdaki butonlar gizlenir; arama alanı
    // tüm genişliği kullanır. Klavye kapatılınca (sistem geri tuşu dahil)
    // odak sürse bile bar kendiliğinden daralır — viewInsets bunu izler.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final searchExpanded =
        _searchFocus.hasFocus &&
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
                    final columns = (constraints.maxWidth / 220).floor().clamp(
                      2,
                      6,
                    );
                    // Masonry hücre genişliği: sürükle-sırala sırasında taşınan
                    // notun "hayalet" kopyası (feedback) bu genişlikte çizilir.
                    // gridPadding yatayda 12+12, crossAxisSpacing 8.
                    final cellWidth =
                        (constraints.maxWidth - 24 - 8 * (columns - 1)) /
                        columns;
                    // Aktif segment (filtre|klasör|etiket) anahtarı: değişince
                    // AnimatedSwitcher yeni görünümü kaydırarak getirir (madde 2).
                    // Arama sorgusu anahtara DAHİL DEĞİL — her tuşta yeniden
                    // animasyon tetiklenmez.
                    final segmentKey =
                        '${ref.watch(noteFilterProvider)}'
                        '|${ref.watch(selectedFolderProvider) ?? ''}'
                        '|${ref.watch(selectedTagProvider) ?? ''}';
                    return GestureDetector(
                      // Yatay çekişle filtreler/klasörler arasında gezin
                      // (madde 1). Dikey kaydırma CustomScrollView'de kalır;
                      // eksenler farklı olduğundan çakışmaz.
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity.abs() < 200) return;
                        _cycleFilterFolder(velocity < 0 ? 1 : -1);
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          // Çekiş yönüne göre yumuşak kaydır + soldur.
                          final begin = Offset(_swipeForward ? 0.12 : -0.12, 0);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(
                                begin: begin,
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        layoutBuilder: (currentChild, previousChildren) => Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                        child: CustomScrollView(
                        key: ValueKey(segmentKey),
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
                            // Kopyala/arşivle/sil ve diğer tüm not işlemleri
                            // seçim yapılınca BURADA toplanır (madde 3): sık
                            // kullanılanlar simge, gerisi taşma menüsünde.
                            actions: [
                              IconButton(
                                tooltip: l10n.archive,
                                icon: const Icon(Icons.archive_outlined),
                                onPressed: () => _archiveSelected(selectedIds),
                              ),
                              IconButton(
                                tooltip: l10n.copy,
                                icon: const Icon(Icons.copy_outlined),
                                onPressed: () => _copySelected(selectedIds),
                              ),
                              IconButton(
                                tooltip: l10n.deleteSelected,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteSelected(selectedIds),
                              ),
                              PopupMenuButton<String>(
                                tooltip: l10n.noteMetaMenu,
                                onSelected: (action) {
                                  switch (action) {
                                    case 'pin':
                                      _setPinnedSelected(selectedIds, true);
                                    case 'unpin':
                                      _setPinnedSelected(selectedIds, false);
                                    case 'star':
                                      _setStarredSelected(selectedIds, true);
                                    case 'unstar':
                                      _setStarredSelected(selectedIds, false);
                                    case 'share':
                                      _shareSelected(selectedIds);
                                    case 'color':
                                      _colorSelected(selectedIds, frame: false);
                                    case 'frame':
                                      _colorSelected(selectedIds, frame: true);
                                  }
                                },
                                itemBuilder: (context) => [
                                  _menuItem(
                                    'pin',
                                    Icons.push_pin_outlined,
                                    l10n.pin,
                                  ),
                                  _menuItem(
                                    'unpin',
                                    Icons.push_pin,
                                    l10n.unpin,
                                  ),
                                  _menuItem(
                                    'star',
                                    Icons.star_outline,
                                    l10n.star,
                                  ),
                                  _menuItem('unstar', Icons.star, l10n.unstar),
                                  const PopupMenuDivider(),
                                  _menuItem(
                                    'color',
                                    Icons.palette_outlined,
                                    l10n.backgroundColor,
                                  ),
                                  _menuItem(
                                    'frame',
                                    Icons.border_color_outlined,
                                    l10n.frameColor,
                                  ),
                                  _menuItem(
                                    'share',
                                    Icons.share_outlined,
                                    l10n.share,
                                  ),
                                ],
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
                                      onPressed: () =>
                                          context.push('/translate'),
                                    ),
                                    IconButton(
                                      tooltip: l10n.chatTitle,
                                      icon: const Icon(Icons.forum_outlined),
                                      onPressed: () => context.push('/chat'),
                                    ),
                                    PopupMenuButton<String>(
                                      // Menü ekranın altına taşıp sistem gezinme
                                      // çubuğunun arkasında kalıyordu; yükseklik
                                      // sınırlanınca içerik kaydırılabilir olur ve
                                      // son maddeler çubuğun altında kalmaz.
                                      // minWidth kaldırıldı: menüyü 200 px'e
                                      // zorlamak dar ekranda gereksiz yer
                                      // kaplıyordu, artık içeriğe göre daralır.
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            MediaQuery.sizeOf(context).height *
                                            0.55,
                                      ),
                                      onSelected: (action) => switch (action) {
                                        'sort' => _pickSort(),
                                        'suggestions' => context.push(
                                          '/suggestions',
                                        ),
                                        'mail' => context.push('/mail'),
                                        'briefing' => context.push('/briefing'),
                                        'listen' => pickAndReadDocument(
                                          context,
                                        ),
                                        'reminders' => context.push(
                                          '/reminders',
                                        ),
                                        'archive' => context.push('/archive'),
                                        'trash' => context.push('/trash'),
                                        'settings' => context.push('/settings'),
                                        _ => null,
                                      },
                                      // Menü üç ayrı cinsten madde taşıyor:
                                      // AI araçları, içerik yerleri (arşiv/
                                      // çöp/hatırlatıcı) ve ayarlar. Ayraçsız
                                      // tek liste karma çekmece gibi
                                      // okunuyordu; gruplar ayrıldı.
                                      itemBuilder: (context) => [
                                        // --- Sıralama ---
                                        _menuItem(
                                          'sort',
                                          Icons.sort,
                                          l10n.sortBy,
                                        ),
                                        const PopupMenuDivider(),
                                        // --- AI araçları ---
                                        _menuItem(
                                          'suggestions',
                                          Icons.auto_awesome_outlined,
                                          l10n.aiSuggestions,
                                        ),
                                        _menuItem(
                                          'mail',
                                          Icons.mark_email_unread_outlined,
                                          l10n.importantEmails,
                                        ),
                                        _menuItem(
                                          'briefing',
                                          Icons.wb_sunny_outlined,
                                          l10n.briefingTitle,
                                        ),
                                        _menuItem(
                                          'listen',
                                          Icons.headphones_outlined,
                                          l10n.readDocument,
                                        ),
                                        const PopupMenuDivider(),
                                        // --- İçerik yerleri ---
                                        _menuItem(
                                          'reminders',
                                          Icons.alarm_outlined,
                                          l10n.remindersTitle,
                                        ),
                                        _menuItem(
                                          'archive',
                                          Icons.archive_outlined,
                                          l10n.archiveTitle,
                                        ),
                                        _menuItem(
                                          'trash',
                                          Icons.delete_outline,
                                          l10n.trashTitle,
                                        ),
                                        const PopupMenuDivider(),
                                        _menuItem(
                                          'settings',
                                          Icons.settings_outlined,
                                          l10n.settings,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                          ),
                        // Hızlı ekleme barı kaldırıldı: sunduğu üç tipin
                        // tamamını sağ alttaki "+" düğmesi zaten veriyordu
                        // (üstelik el yazısı da). Her ekranda 52dp prime alan
                        // yiyen ikinci bir oluşturma yolu için sebep yoktu.
                        // Filtre + klasör + etiket çipleri tek kompakt satırda.
                        const SliverToBoxAdapter(child: DashboardChipsRow()),
                        ...notesAsync.when(
                          data: (notes) => _buildNoteSlivers(
                            context,
                            notes,
                            columns,
                            cellWidth: cellWidth,
                            selectionActive: selectionActive,
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
                      ),
                      ),
                    );
                  },
                ),
                // Sesli asistan paneli düğmelerin ÜSTÜnde sabit konumda yüzer.
                // Düğmeler floatingActionButton'da kaldığından panel açılıp
                // kapanırken yerinden oynamaz (stabil); yalnız kayıt/işleme/
                // sonuç sırasında görünür, ana sayfanın ortasına yakın.
                // Asistan paneli, "not silindi" bildirimiyle aynı yerleşimi
                // kullanır: düğmelerin ÜSTÜnde değil SOLUNDA, ekranın dibinde.
                // Sağda düğme sütunu kadar boşluk bırakılır.
                const Positioned(
                  left: 8,
                  right: 88,
                  bottom: 16,
                  child: VoiceAssistantPanel(),
                ),
                // Düğmeler Scaffold.floatingActionButton yerine BURADA durur:
                // Scaffold bir FAB tanıdığında yüzen bildirimleri ("not
                // silindi") onun ÜSTÜne iter. Düğmeler Stack'te olunca
                // bildirim ekranın dibinde, düğmelerin solunda kalır.
                Positioned(
                  right: 16,
                  bottom: 16,
                  // Bağlantı noktası TÜM sütunu sarar: "+" menüsü kendi
                  // düğmesine değil sütunun tepesine demirlenir, böylece
                  // açılınca mikrofonun üstünü örtmez. Mikrofon yüksekliğini
                  // sabit sayı olarak yazmaya gerek kalmaz.
                  child: CompositedTransformTarget(
                    link: _fabColumnLink,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Sesli Not Asistanı: sayfa değiştirmeden burada dinler.
                        const VoiceAssistantButton(),
                        const SizedBox(height: 6),
                        // Keep tarzı açılan "+": metin/madde/sıralı/el yazısı.
                        QuickAddFab(
                          anchor: _fabColumnLink,
                          onCreate: _createNote,
                          onHandwriting: _createHandwritingNote,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem<String>(
        value: value,
        height: 40,
        // ListTile satırı daima erişilebilir tüm genişliği kaplıyordu; menü de
        // bu yüzden sağ-sol ekseninde gereksiz genişliyordu (madde 5). İçeriğe
        // göre daralan Row ile menü yalnız ikon + etiket kadar yer kaplar.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      );

  List<Widget> _buildNoteSlivers(
    BuildContext context,
    List<Note> notes,
    int columns, {
    required double cellWidth,
    required bool selectionActive,
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

    final pinned = [
      for (final n in notes)
        if (n.pinned) n,
    ];
    final others = [
      for (final n in notes)
        if (!n.pinned) n,
    ];

    final query = ref.read(searchQueryProvider).trim();
    // Sürükle-sırala (madde 1) yalnızca süzgeçsiz görünümde açıktır: arama,
    // etiket, klasör ya da tip filtresi bir alt küme gösterdiğinde elle sıra
    // anlamsızdır (yalnız görünen notların orderIndex'i değişir). Seçim
    // modunda da kapalıdır.
    final reorderEnabled =
        !selectionActive &&
        !searchActive &&
        ref.read(noteFilterProvider) == NoteFilter.all &&
        ref.read(selectedFolderProvider) == null &&
        ref.read(selectedTagProvider) == null;

    Widget grid(List<Note> items) => SliverMasonryGrid.count(
      crossAxisCount: columns,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childCount: items.length,
      itemBuilder: (context, index) {
        final note = items[index];
        final card = NoteCard(note: note, highlightQuery: query);
        if (!reorderEnabled) {
          return KeyedSubtree(key: ValueKey(note.id), child: card);
        }
        return _ReorderableNoteCell(
          key: ValueKey(note.id),
          noteId: note.id,
          index: index,
          cellWidth: cellWidth,
          inSection: (id) => items.any((n) => n.id == id),
          onReorder: (draggedId, to) => _reorderSection(items, draggedId, to),
          feedback: SizedBox(
            width: cellWidth,
            child: NoteCard(note: note, highlightQuery: query),
          ),
          child: card,
        );
      },
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

/// Bir not kartını basılı tutup sürükleyerek yeniden sıralamayı sağlayan
/// sarmalayıcı (madde 1). Uzun basış sürüklemeyi başlatır; başka bir kartın
/// üzerine bırakılınca [onReorder] çağrılır. Sürükleme aynı bölümle
/// sınırlıdır ([inSection]) — sabitliler ile diğerleri karışmaz.
class _ReorderableNoteCell extends StatelessWidget {
  const _ReorderableNoteCell({
    super.key,
    required this.noteId,
    required this.index,
    required this.cellWidth,
    required this.inSection,
    required this.onReorder,
    required this.feedback,
    required this.child,
  });

  final String noteId;
  final int index;
  final double cellWidth;
  final bool Function(String draggedId) inSection;
  final void Function(String draggedId, int toIndex) onReorder;
  final Widget feedback;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          details.data != noteId && inSection(details.data),
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return LongPressDraggable<String>(
          data: noteId,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: cellWidth, child: feedback),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hovering ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: child,
          ),
        );
      },
    );
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
        hintText: semantic
            ? context.l10n.semanticSearchHint
            : context.l10n.searchHint,
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
