import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/filter_sheet.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/notes_providers.dart';
import '../../notes/presentation/quick_add_actions.dart';
import '../../notes/presentation/quick_add_fab.dart';
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

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen>
    with QuickAddActions {
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
    await context.push(
      type == NoteType.archive
          ? archiveNoteRoutePath(id)
          : noteRoutePath(id, query: query),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folderId = widget.folderId;
    final ownerId = widget.ownerId;
    final l10n = context.l10n;
    final myUid = ref.watch(currentUidProvider);
    final shared = ownerId != null && ownerId != myUid;

    if (shared) return _SharedFolderView(folderId: folderId, ownerId: ownerId);

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
          _SortMenu(
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
      // Ana ekrandakinin AYNISI: metin/madde, el yazısı, sesli, görüntülü,
      // foto, belge tarama, PDF, görsel, sunum ve QR. Eskiden burada düz bir
      // FAB vardı ve yalnız boş bir METİN notu açıyordu (kullanıcı bulgusu
      // 2026-08-29: "klasör içlerindeki ekle butonu sadece metin notu
      // açıyor"). Davranış [QuickAddActions] ile ORTAK, kopya değil.
      floatingActionButton: CompositedTransformTarget(
        link: _fabLink,
        child: QuickAddFab(
          anchor: _fabLink,
          onCreate: createNote,
          onHandwriting: createHandwritingNote,
          onVoiceCapture: createVoiceCaptureNote,
          onVideoNote: createVideoNote,
          onPhotoNote: createPhotoNote,
          onScanNote: createScanNote,
          onPdfNote: createPdfNote,
          onImageNote: createImageNote,
          onSlidesNote: createSlidesNote,
          onQrNote: createQrNote,
        ),
      ),
      // Kutu değişince ızgara yeniden süzülsün: sorgu denetleyicide durur,
      // dinleyici yalnız gövdeyi çizer (üst bar aynı kalır).
      body: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) =>
            _NotesGrid(async: notesAsync, query: value.text),
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
    ),
  );
}

/// Sıralama ölçütü menüsü — ana ekranın süzgeç levhasındaki listenin klasör
/// içindeki kısa hâli. [NoteSort.manual] BURADA YOK: elle sıralama ana
/// ekranın sürükle-bırak kipiyle kurulur, klasörde o kip çalışmıyor.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current, required this.onPick});

  final NoteSort current;
  final ValueChanged<NoteSort> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<NoteSort>(
      tooltip: l10n.sortBy,
      icon: const Icon(Icons.sort),
      initialValue: current,
      onSelected: onPick,
      itemBuilder: (context) => [
        for (final sort in NoteSort.values)
          if (sort != NoteSort.manual)
            PopupMenuItem<NoteSort>(
              value: sort,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: sort == current
                        ? const Icon(Icons.check, size: 18)
                        : null,
                  ),
                  Expanded(child: Text(sortLabel(l10n, sort))),
                ],
              ),
            ),
      ],
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

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({
    required this.async,
    this.ownerId,
    this.readOnly = false,
    this.query = '',
  });

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
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final needle = query.trim().toLowerCase();
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
                )
              : EmptyState(
                  icon: Icons.search_off,
                  title: l10n.noteSearchNoHit,
                ))
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 220).floor().clamp(
                  2,
                  6,
                );
                return MasonryGridView.count(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  crossAxisCount: columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: notes.length,
                  itemBuilder: (context, index) => NoteCard(
                    note: notes[index],
                    ownerId: ownerId,
                    readOnly: readOnly,
                  ),
                );
              },
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
      final repo = NotesRepository(FirebaseFirestore.instance, widget.ownerId);
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
    final repo = NotesRepository(FirebaseFirestore.instance, widget.ownerId);
    final id = await repo.createNote(NoteType.text, folderId: widget.folderId);
    if (!context.mounted) return;
    await openNoteRoute(
      context,
      Note(id: id, type: NoteType.text, folderId: widget.folderId),
      ownerId: widget.ownerId,
    );
  }
}
