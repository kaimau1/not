import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/search_fold.dart';
import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/note_grid.dart';
import '../../notes/presentation/note_sort_menu.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/presentation/quick_add_actions.dart';
import '../../notes/presentation/quick_add_fab.dart';
import '../data/folder_activity.dart';
import '../data/folder_order.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_chat_screen.dart';
import 'folder_sheets.dart';

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

  static Future<void> open(
    BuildContext context,
    String folderId, {
    String? ownerId,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FolderScreen(folderId: folderId, ownerId: ownerId),
    ),
  );

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
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _searchController.clear();
    });
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
    final notesAsync = ref.watch(folderNotesProvider(folderId));

    // Klasör silinmiş olabilir (başka cihazdan): sayfa boş bir kabuk olarak
    // kalmaz, kendiliğinden kapanır.
    if (folders != null && folder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? _FolderSearchField(controller: _searchController)
            : _FolderTitle(
                icon: folder?.iconData,
                name: folder?.name,
                count: notesAsync.value?.length,
              ),
        actions: [
          IconButton(
            tooltip: _searching ? l10n.close : l10n.searchHint,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          // SIRALAMA klasörün içinde de değiştirilebilsin: ölçüt ana ekranla
          // ORTAK (bkz. folderNotesProvider) — kullanıcının seçtiği düzen her
          // yerde aynı olsun, iki ayrı ayar iki ayrı sürpriz demek.
          NoteSortMenu(
            current: ref.watch(noteSortProvider),
            onPick: (sort) =>
                ref.read(noteSortProvider.notifier).set(sort),
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
              onPressed: () => showFolderActionsSheet(context, ref, folder),
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
            _searching || ref.watch(swipeModeProvider) == SwipeMode.off
            ? null
            : (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() < 300) return;
                final rtl =
                    Directionality.of(context) == TextDirection.rtl;
                final forward = rtl ? velocity > 0 : velocity < 0;
                _swipeTo(forward ? 1 : -1);
              },
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) => _NotesGrid(
            async: notesAsync,
            query: value.text,
            onCreateNote: () => createNote(NoteType.text),
          ),
        ),
      ),
    );
  }
}

/// Üst bardaki arama kutusu (klasör içi). Ayrı widget: `autofocus` yalnız
/// kutu AĞACA GİRDİĞİNDE bir kez çalışsın — üst bar her sayımda yeniden
/// çizildiğinde odak yeniden istenirse klavye kapanıp açılırdı.
class _FolderSearchField extends StatelessWidget {
  const _FolderSearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: true,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      border: InputBorder.none,
      hintText: context.l10n.searchHint,
      // Kutuyu tek dokunuşta boşalt: eskiden ya harf harf silmek ya da
      // aramayı tümden kapatıp yeniden açmak gerekiyordu.
      suffixIcon: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) => value.text.isEmpty
            ? const SizedBox.shrink()
            : IconButton(
                tooltip: context.l10n.clearSearch,
                icon: const Icon(Icons.close, size: 18),
                onPressed: controller.clear,
              ),
      ),
    ),
  );
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
    this.onCreateNote,
  });

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
    final needle = foldForSearch(query.trim());
    // Sütun sayısı ANA EKRANLA ortak: kullanıcı orada iki parmakla seçtiği
    // yoğunluğu klasörde de görsün (sıralamayla aynı gerekçe). 0 = otomatik.
    final fixedColumns = ref.watch(gridColumnsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          EmptyState(icon: Icons.error_outline, title: l10n.genericError('$e')),
      data: (all) {
        final notes = needle.isEmpty
            ? all
            : [
                for (final n in all)
                  if (noteMatchesQuery(n, needle)) n,
              ];
        return notes.isEmpty
          ? (needle.isEmpty
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
                      final columns = fixedColumns > 0
                          ? fixedColumns
                          : (constraints.maxWidth / 220).floor().clamp(2, 6);
                      // ANA EKRANLA AYNI IZGARA (bkz. [NoteBalancedGrid]):
                      // klasör de masonry'nin "kart sütun değiştiriyor,
                      // sağ sütunda boşluk kalıyor" hatasından kurtuldu.
                      return NoteBalancedGrid(
                        notes: notes,
                        columns: columns,
                        itemBuilder: (context, index) => NoteCard(
                          note: notes[index],
                          ownerId: ownerId,
                          readOnly: readOnly,
                          highlightQuery: needle,
                          showFolder: false,
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
  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
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
            title: _searching
                ? _FolderSearchField(controller: _searchController)
                : _FolderTitle(
                    icon: folder?.iconData ?? share?.iconData,
                    name: name,
                  ),
            actions: [
              if (role.canRead)
                IconButton(
                  tooltip: _searching ? l10n.close : l10n.searchHint,
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _searchController.clear();
                  }),
                ),
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
                  valueListenable: _searchController,
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
