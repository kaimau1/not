import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_type.dart';
import '../../notes/presentation/note_card.dart';
import '../../notes/presentation/notes_providers.dart';
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
class FolderScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final myUid = ref.watch(currentUidProvider);
    final shared = ownerId != null && ownerId != myUid;

    if (shared) return _SharedFolderView(folderId: folderId, ownerId: ownerId!);

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
        title: _FolderTitle(icon: folder?.iconData, name: folder?.name),
        actions: [
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
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newTextNote,
        onPressed: () => _createNote(context, ref),
        child: const Icon(Icons.add),
      ),
      body: _NotesGrid(async: notesAsync),
    );
  }

  /// Klasörün içinde yeni not: `folderId` doğrudan yazılır, kullanıcı notu
  /// oluşturduktan sonra ayrıca "klasöre taşı" adımı yapmasın.
  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createNote(NoteType.text, folderId: folderId);
    if (!context.mounted) return;
    await openNoteRoute(
      context,
      Note(id: id, type: NoteType.text, folderId: folderId),
    );
  }
}

class _FolderTitle extends StatelessWidget {
  const _FolderTitle({required this.icon, required this.name});

  final IconData? icon;
  final String? name;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon ?? Icons.folder_outlined, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          name ?? context.l10n.filterSectionFolder,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({
    required this.async,
    this.ownerId,
    this.readOnly = false,
  });

  final AsyncValue<List<Note>> async;

  /// Paylaşılan klasörde notların SAHİBİ — kart bunu editöre taşır, yoksa
  /// not kendi koleksiyonumda aranır ve "bulunamadı" olur.
  final String? ownerId;

  /// Yalnız okuma yetkisi: editör kilitli açılır.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          EmptyState(icon: Icons.error_outline, title: l10n.genericError('$e')),
      data: (notes) => notes.isEmpty
          ? EmptyState(
              icon: Icons.folder_open_outlined,
              title: l10n.folderEmpty,
              subtitle: l10n.folderEmptyHint,
            )
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
            ),
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
class _SharedFolderView extends ConsumerWidget {
  const _SharedFolderView({required this.folderId, required this.ownerId});

  final String folderId;
  final String ownerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            title: _FolderTitle(
              icon: folder?.iconData ?? share?.iconData,
              name: name,
            ),
            actions: [
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
              ? _NotesGrid(
                  ownerId: ownerId,
                  readOnly: !role.canWrite,
                  async: ref.watch(
                    sharedFolderNotesProvider((
                      ownerId: ownerId,
                      folderId: folderId,
                    )),
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
      final repo = NotesRepository(FirebaseFirestore.instance, ownerId);
      final id = await repo.createNote(
        NoteType.text,
        folderId: folderId,
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
    final repo = NotesRepository(FirebaseFirestore.instance, ownerId);
    final id = await repo.createNote(NoteType.text, folderId: folderId);
    if (!context.mounted) return;
    await openNoteRoute(
      context,
      Note(id: id, type: NoteType.text, folderId: folderId),
      ownerId: ownerId,
    );
  }
}
