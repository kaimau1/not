import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/data/folders_repository.dart';
import '../data/attachment_repository.dart';
import '../data/note_shares_repository.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';

/// Bu cihazda "yalnız bu cihazda" özelliği var mı (web'de yok — bkz.
/// `LocalNotesStore.forUid`).
bool localOnlySupported(WidgetRef ref) =>
    ref.read(notesRepositoryProvider)?.local != null;

/// **SENKRONU KAPAT / AÇ** (kullanıcı isteği 2026-09-26: "senkronizasyon
/// kapatma nota özel"). Editörün ⋮ menüsü ve kartın işlem levhası aynı yolu
/// kullanır.
///
/// Kapatmadan önce ONAY: not buluttan silinir, başka cihazlarda görünmez,
/// uygulama silinirse kaybolur — geri dönüşü olan ama sonucu büyük bir iş.
/// Paylaşılan not (ortak not ya da paylaşılan klasördeki) yerel yapılamaz:
/// ortak çalışanlar bir anda notu kaybederdi.
///
/// Sonucu (yeni durum) döner; vazgeçildiyse/olmadıysa null.
Future<bool?> toggleNoteLocalOnly(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void snack(String text) => messenger
    ..hideCurrentSnackBar()
    ..showMessage(text);
  final repo = ref.read(notesRepositoryProvider);
  if (repo == null || repo.local == null) return null;
  final nowLocal = repo.isLocal(note.id);
  if (!nowLocal) {
    final collaborative =
        ref.read(myNoteSharesProvider).value?.containsKey(note.id) ?? false;
    final folderShared =
        note.folderId != null &&
        (ref.read(foldersStreamProvider).value ?? const [])
            .where((f) => f.id == note.folderId)
            .any((f) => f.isShared);
    if (collaborative || folderShared) {
      snack(l10n.localOnlySharedBlocked);
      return null;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.cloud_off_outlined),
        title: Text(l10n.localOnlyConfirmTitle),
        content: Text(l10n.localOnlyConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.localOnlyConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return null;
  }
  try {
    await repo.setLocalOnly(
      note,
      localOnly: !nowLocal,
      attachments: ref.read(attachmentRepositoryProvider),
    );
  } on LocalOnlyException {
    snack(l10n.localOnlyDownloadFailed);
    return null;
  } catch (e) {
    snack(l10n.genericError('$e'));
    return null;
  }
  snack(nowLocal ? l10n.localOnlyOffDone : l10n.localOnlyOnDone);
  return !nowLocal;
}
