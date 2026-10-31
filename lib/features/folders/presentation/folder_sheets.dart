import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/domain/friend.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folder_order.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';
import 'folder_chat_screen.dart';
import 'folder_tile.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../auth/presentation/account_required.dart';

/// Klasör oluşturma/düzenleme diyaloğu: ad alanı + simge seçici.
/// [existing] verilirse düzenleme modunda açılır. Oluşturulan/düzenlenen
/// klasörün id'sini döner (vazgeçilirse null).
Future<String?> showFolderEditorDialog(
  BuildContext context,
  WidgetRef ref, {
  NoteFolder? existing,
}) async {
  final l10n = context.l10n;
  final nameController = TextEditingController(text: existing?.name ?? '');
  var icon = existing?.icon ?? NoteFolder.defaultIcon;
  var hidden = existing?.hidden ?? false;
  // null = otomatik (kimlikten türetilen renk, bkz. folderAccent).
  var color = existing?.color;

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(existing == null ? l10n.newFolder : l10n.editFolder),
          content: SizedBox(
            // Sabit 340 dar telefonlarda taşıyordu: AlertDialog kenarlardan
            // ~40dp yiyor, 360dp'lik ekranda içeriğe 280dp kalıyor.
            width: math.min(340, MediaQuery.sizeOf(dialogContext).width - 80),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: l10n.folderNameHint),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.folderIcon,
                    style: Theme.of(dialogContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final entry in NoteFolder.iconChoices.entries)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => icon = entry.key),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: icon == entry.key
                                  ? Theme.of(
                                      dialogContext,
                                    ).colorScheme.primaryContainer
                                  : null,
                            ),
                            child: Icon(
                              entry.value,
                              size: 22,
                              color: icon == entry.key
                                  ? Theme.of(
                                      dialogContext,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      dialogContext,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // **RENK** (kullanıcı isteği 2026-09-23: klasörler bakışta
                  // ayırt edilmiyordu). "Otomatik" kimlikten sabit bir renk
                  // verir; seçim yapılmazsa klasör yine renkli görünür.
                  Text(
                    l10n.folderColor,
                    style: Theme.of(dialogContext).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ColorDot(
                        tooltip: l10n.folderColorAuto,
                        selected: color == null,
                        color: existing == null
                            ? Theme.of(dialogContext).colorScheme.outline
                            : folderAccent(existing.id),
                        icon: Icons.auto_awesome,
                        onTap: () => setState(() => color = null),
                      ),
                      for (var i = 0; i < NoteFolder.accentPalette.length; i++)
                        _ColorDot(
                          selected: color == i,
                          color: NoteFolder.accentPalette[i],
                          onTap: () => setState(() => color = i),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Gizli klasör: çip ana ekranda görünmez, notları da not
                  // duvarına/aramaya girmez (bkz. NoteFolder.hidden).
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    title: Text(l10n.hiddenFolder),
                    subtitle: Text(
                      l10n.hiddenFolderInfo,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                    value: hidden,
                    onChanged: (value) => setState(() => hidden = value),
                  ),
                ],
              ),
            ),
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
      ),
    );

    final name = nameController.text.trim();
    if (!(saved ?? false) || name.isEmpty) return null;
    final repo = ref.read(foldersRepositoryProvider);
    if (repo == null) return null;
    if (existing == null) {
      return await repo.createFolder(
        name,
        icon: icon,
        hidden: hidden,
        color: color,
      );
    }
    repo.updateFolder(
      existing.id,
      name: name,
      icon: icon,
      hidden: hidden,
      color: color,
      clearColor: color == null && existing.color != null,
    );
    return existing.id;
  } finally {
    // finally İÇİNDE: showDialog fırlarsa ya da çağıranın rotası programlı
    // kapanırsa denetleyici (ve dinleyicileri) sızıyordu.
    nameController.dispose();
  }
}

/// Klasör çipine uzun basınca açılan menü: düzenle / sil.
Future<void> showFolderActionsSheet(
  BuildContext context,
  WidgetRef ref,
  NoteFolder folder,
) async {
  final l10n = context.l10n;
  final action = await showAppSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.editFolder),
            onTap: () => Navigator.pop(sheetContext, 'edit'),
          ),
          // Gizle/göster: düzenleme diyaloğunu açmadan tek dokunuşla.
          ListTile(
            leading: Icon(
              folder.hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            title: Text(
              folder.hidden ? l10n.makeFolderVisible : l10n.makeFolderHidden,
            ),
            onTap: () => Navigator.pop(sheetContext, 'hide'),
          ),
          // **PAYLAŞ** (kullanıcı isteği 2026-08-18: "ortak notlar klasörü
          // kişiler bağlanır notları ortak görür"). Yerel (anonim) hesapta
          // e-posta olmadığından özellik çalışmaz: kilit rozetiyle görünür,
          // dokununca hesap levhası (F10.5).
          ListTile(
              leading: Icon(
                folder.isShared ? Icons.people : Icons.person_add_alt_outlined,
              ),
              title: Text(l10n.folderShare),
              subtitle: folder.isShared
                  ? Text(l10n.folderShareCount(folder.sharedWith.length))
                  : null,
              trailing: ref.read(isAnonymousProvider)
                  ? const AccountLockBadge()
                  : null,
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
          // **SOHBET** (kullanıcı isteği 2026-08-18: "birde birbirine mesaj
          // gönderme alanı olabilir") — yalnız gerçekten paylaşılmış
          // klasörde: kendi kendine sohbet edilecek bir oda açmanın anlamı
          // yok.
          if (folder.sharedWith.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: Text(l10n.folderChatTitle),
              onTap: () => Navigator.pop(sheetContext, 'chat'),
            ),
          // KLASÖR SIRASI (kullanıcı isteği 2026-09-26): klasörün kendi
          // menüsünden de ulaşılsın — kullanıcı sırayı değiştirmeyi tam
          // klasöre uzun basınca arar.
          ListTile(
            leading: const Icon(Icons.swap_vert),
            title: Text(l10n.folderReorder),
            onTap: () => Navigator.pop(sheetContext, 'order'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.deleteFolder),
            onTap: () => Navigator.pop(sheetContext, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  switch (action) {
    case 'order':
      await showFolderOrderSheet(context);
    case 'edit':
      await showFolderEditorDialog(context, ref, existing: folder);
    case 'hide':
      ref
          .read(foldersRepositoryProvider)
          ?.updateFolder(folder.id, hidden: !folder.hidden);
      // Klasör gizlenirken o an seçiliyse süzgeç bırakılır: aksi hâlde ana
      // ekran, artık çipi görünmeyen bir klasörde kilitli kalırdı.
      if (!folder.hidden && ref.read(selectedFolderProvider) == folder.id) {
        ref.read(selectedFolderProvider.notifier).set(null);
      }
    case 'share':
      if (context.mounted) await showFolderShareSheet(context, ref, folder);
    case 'chat':
      if (context.mounted) {
        await FolderChatScreen.open(
          context,
          folderId: folder.id,
          folderName: folder.name,
        );
      }
    case 'delete':
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.deleteFolder),
          content: Text(l10n.deleteFolderConfirm(folder.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
      if (confirmed ?? false) {
        await ref
            .read(foldersRepositoryProvider)
            ?.deleteFolder(folder.id, shared: folder.isShared);
      }
  }
}

/// Nota klasör seçtiren alt sayfa. Dönüş: klasör id'si, '' (klasörsüz)
/// veya null (vazgeçildi).
Future<String?> showFolderPickSheet(
  BuildContext context,
  WidgetRef ref, {
  String? currentFolderId,
}) async {
  final l10n = context.l10n;
  // Kullanıcının klasör SIRASIYLA (bkz. FolderSort); gizli klasörler yalnız
  // açığa çıkarıldıysa — notu gizli bir klasöre taşıma yolu bile adını ele
  // verirdi. Not zaten gizli bir klasördeyse o klasör listede kalır.
  final revealed = ref.read(hiddenFoldersRevealedProvider);
  final folders = [
    for (final f in ref.read(orderedFoldersProvider))
      if (!f.hidden || revealed || f.id == currentFolderId) f,
  ];
  const newSentinel = '__new__';
  final picked = await showAppSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Yeni klasör" EN ÜSTTE: eskiden tüm klasörlerin altındaydı ve
            // klasörü çok olan kullanıcıda ekran dışında kalıyordu — yeni
            // klasörün doğrudan eklenebildiği fark edilmiyordu.
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.newFolder),
              onTap: () => Navigator.pop(sheetContext, newSentinel),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: Text(l10n.noFolder),
              selected: currentFolderId == null,
              onTap: () => Navigator.pop(sheetContext, ''),
            ),
            for (final folder in folders)
              ListTile(
                leading: Icon(folder.iconData),
                title: Text(folder.name),
                selected: currentFolderId == folder.id,
                onTap: () => Navigator.pop(sheetContext, folder.id),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked != newSentinel) return picked;
  // Yeni klasör: oluşturulunca not doğrudan ona atanır.
  if (!context.mounted) return null;
  return showFolderEditorDialog(context, ref);
}

/// **KLASÖRÜ PAYLAŞ.** Arkadaş listesinden seçim, kişi başına YETKİ
/// (okuma / yazma / her ikisi) ve paylaşılanların yönetimi tek levhada.
///
/// Kullanıcı isteği 2026-08-18: "klasör sahibi paylaşılan klasörde yetki
/// belirleyebilsin yazma, okuma veya her ikisi şeklinde." Seçim yalnız
/// SAHİPTE: davetli kendi rolünü değiştiremez (bkz. firestore.rules).
Future<void> showFolderShareSheet(
  BuildContext context,
  WidgetRef ref,
  NoteFolder folder,
) async {
  if (ref.read(isAnonymousProvider)) {
    await showAccountRequiredSheet(context, ref);
    return;
  }
  await showAppSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Consumer: kutucuklar sabit `folder` yerine CANLI klasör dokümanını
    // izler. Sabit olsaydı bir kutuya dokunmak Firestore'a yazar ama
    // ekrandaki kutu bir sonraki kare geri sıçrardı (setState hiç çağrılmaz).
    builder: (sheetContext) => Consumer(
      builder: (sheetContext, sheetRef, _) {
        final l10n = sheetContext.l10n;
        final liveFolder =
            sheetRef
                .watch(foldersStreamProvider)
                .value
                ?.where((f) => f.id == folder.id)
                .firstOrNull ??
            folder;
        final friends =
            sheetRef.watch(friendsStreamProvider).value ?? const <Friend>[];
        final foldersRepo = sheetRef.watch(foldersRepositoryProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.folderShareTitle(liveFolder.name),
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.folderShareInfo,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (friends.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.friendsEmpty),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            openFriendsScreenOrExplain(context, ref);
                          },
                          icon: const Icon(
                            Icons.person_add_alt_outlined,
                            size: 18,
                          ),
                          label: Text(l10n.friendsAdd),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final friend in friends)
                            _FriendShareRow(
                              folder: liveFolder,
                              friend: friend,
                              repo: foldersRepo,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Paylaşım levhasının tek satırı: kişi + açık/kapalı anahtarı + (paylaşımda
/// ise) yetki seçici. Yetki seçici yalnız paylaşılmış kişide çizilir —
/// paylaşılmayan bir kişinin yetkisini seçmek anlamsız.
class _FriendShareRow extends StatelessWidget {
  const _FriendShareRow({
    required this.folder,
    required this.friend,
    required this.repo,
  });

  final NoteFolder folder;
  final Friend friend;
  final FoldersRepository? repo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final accepted = folder.sharedWith.contains(friend.uid);
    final pending = folder.pending.contains(friend.uid);
    final shared = accepted || pending;
    final role = folder.roleOf(friend.uid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: shared,
          title: Text(friend.name.isEmpty ? friend.email : friend.name),
          subtitle: Text(
            // Davet gönderildi ama yanıtlanmadıysa bunu SÖYLE: kullanıcı
            // "paylaştım ama görmüyor" diye ikinci kez paylaşmaya çalışıyor.
            pending ? l10n.folderInvitePending : friend.email,
            style: pending
                ? TextStyle(color: scheme.tertiary, fontStyle: FontStyle.italic)
                : null,
          ),
          onChanged: repo == null
              ? null
              : (checked) {
                  if (checked ?? false) {
                    repo!.shareFolder(folder, friend.uid, role: role);
                  } else {
                    repo!.unshareFolder(folder, friend.uid);
                  }
                },
        ),
        if (shared)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 10),
            child: Wrap(
              spacing: 6,
              children: [
                for (final option in FolderRole.values)
                  ChoiceChip(
                    label: Text(folderRoleLabel(l10n, option)),
                    selected: role == option,
                    onSelected: repo == null
                        ? null
                        : (_) =>
                              repo!.setFolderRole(folder, friend.uid, option),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Yetkinin okunur adı. Tek yerde: levha, klasör başlığı ve davet kartı aynı
/// kelimeleri kullansın.
String folderRoleLabel(AppLocalizations l10n, FolderRole role) =>
    switch (role) {
      FolderRole.read => l10n.folderRoleRead,
      FolderRole.write => l10n.folderRoleWrite,
      FolderRole.both => l10n.folderRoleBoth,
    };

/// Renk seçicideki tek nokta; seçiliyse kalın halka ve tik.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
    this.tooltip,
  });

  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: icon == null ? color : null,
          border: Border.all(
            color: selected ? scheme.onSurface : color.withValues(alpha: 0.6),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: icon != null
            ? Icon(icon, size: 16, color: color)
            : (selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null),
      ),
    );
    return tooltip == null ? dot : Tooltip(message: tooltip!, child: dot);
  }
}


/// **KLASÖR SIRASI** levhası (kullanıcı isteği 2026-09-26: "klasör sıralaması
/// ayarlama"): sıralama ölçütü + elle sürükleyerek sıralama. Sıra ana
/// ekranın klasör şeridinde, Klasörler sayfasında, "klasöre taşı"
/// listesinde ve yana çekişte AYNI.
Future<void> showFolderOrderSheet(BuildContext context) =>
    showAppSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.8,
        child: FolderOrderPanel(),
      ),
    );

/// [showFolderOrderSheet]'in gövdesi.
class FolderOrderPanel extends ConsumerStatefulWidget {
  const FolderOrderPanel({super.key});

  @override
  ConsumerState<FolderOrderPanel> createState() => _FolderOrderPanelState();
}

class _FolderOrderPanelState extends ConsumerState<FolderOrderPanel> {
  /// Sürüklemenin HEMEN gösterilen sonucu. Yazım akışa dönene kadar liste
  /// eski sıraya sıçramasın diye; akış aynı sırayı getirince bırakılır.
  List<NoteFolder>? _pending;

  void _reorder(List<NoteFolder> visible, int from, int to) {
    final moved = [...visible];
    final item = moved.removeAt(from);
    moved.insert(to, item);
    setState(() => _pending = moved);
    // Gizli (şu an görünmeyen) klasörler YERİNDE kalır: tam listede
    // görünenlerin yuvaları yeni sırayla doldurulur.
    final full = ref.read(orderedFoldersProvider);
    final visibleIds = {for (final f in visible) f.id};
    final queue = moved.iterator;
    final ids = <String>[
      for (final f in full)
        if (visibleIds.contains(f.id)) (queue..moveNext()).current.id else f.id,
    ];
    ref.read(folderSortProvider.notifier).set(FolderSort.manual);
    ref.read(foldersRepositoryProvider)?.reorderFolders(ids);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sort = ref.watch(folderSortProvider);
    final live = ref.watch(visibleOrderedFoldersProvider);
    var folders = live;
    final pending = _pending;
    if (pending != null) {
      final same =
          pending.length == live.length &&
          [
            for (var i = 0; i < live.length; i++) live[i].id == pending[i].id,
          ].every((b) => b);
      if (same) {
        _pending = null;
      } else {
        folders = pending;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(l10n.folderOrderTitle, style: theme.textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FolderSortChoice(
            value: sort,
            onChanged: (v) => ref.read(folderSortProvider.notifier).set(v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(
            l10n.folderOrderHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: folders.isEmpty
              ? Center(child: Text(l10n.foldersEmpty))
              : ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                  itemCount: folders.length,
                  buildDefaultDragHandles: false,
                  onReorderItem: (from, to) => _reorder(folders, from, to),
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      key: ValueKey('order-${folder.id}'),
                      leading: FolderIconBox(
                        accent: folder.accent,
                        icon: folder.iconData,
                        size: 32,
                      ),
                      title: Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Klasör sıralama ölçütü seçici — levhada ve Ayarlar → Notlar'da aynı.
class FolderSortChoice extends StatelessWidget {
  const FolderSortChoice({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final FolderSort value;
  final ValueChanged<FolderSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String label(FolderSort s) => switch (s) {
      FolderSort.manual => l10n.folderOrderManual,
      FolderSort.name => l10n.folderOrderName,
      FolderSort.newest => l10n.folderOrderNewest,
      FolderSort.noteCount => l10n.folderOrderNoteCount,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final s in FolderSort.values)
          ChoiceChip(
            label: Text(label(s)),
            selected: s == value,
            onSelected: (_) => onChanged(s),
          ),
      ],
    );
  }
}
