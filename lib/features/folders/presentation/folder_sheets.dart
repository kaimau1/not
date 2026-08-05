import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/presentation/notes_providers.dart';
import '../data/folders_repository.dart';
import '../domain/note_folder.dart';

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

  try {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(existing == null ? l10n.newFolder : l10n.editFolder),
          content: SizedBox(
            width: 340,
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
      return repo.createFolder(name, icon: icon, hidden: hidden);
    }
    repo.updateFolder(existing.id, name: name, icon: icon, hidden: hidden);
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
  final action = await showModalBottomSheet<String>(
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
        await ref.read(foldersRepositoryProvider)?.deleteFolder(folder.id);
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
  final folders = ref.read(foldersStreamProvider).value ?? const <NoteFolder>[];
  const newSentinel = '__new__';
  final picked = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.newFolder),
              onTap: () => Navigator.pop(sheetContext, newSentinel),
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
