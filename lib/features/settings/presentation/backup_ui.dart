import 'dart:convert';
import '../../calendar/data/calendar_backup.dart';
import '../../calendar/data/calendar_repository.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../folders/data/folders_repository.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/backup_files.dart';
import '../../notes/data/backup_service.dart';
import '../../notes/data/import_service.dart';
import '../../notes/data/notes_repository.dart';

/// Ayarlar → Hesap → "Tam yedek" ve "Yedekten geri yükle" akışları (F18.4).
/// Hizmet ([BackupService]) arayüzden bağımsız; burada yalnız dosya seçimi,
/// kimlik kapısı, ilerleme + iptal ve sonuç mesajı var.

const _systemChannel = MethodChannel('dev.kaimau.notlar/system');

BackupService? backupServiceOf(WidgetRef ref) {
  final notes = ref.read(notesRepositoryProvider);
  if (notes == null) return null;
  return BackupService(
    notes: notes,
    attachments: ref.read(attachmentRepositoryProvider),
    folders: ref.read(foldersRepositoryProvider),
    calendar: ref.read(calendarRepositoryProvider),
  );
}

/// Takvim/görev/gün bağlarının o anki hâli (yedeğe girer, F46.5).
CalendarSnapshot calendarSnapshotOf(WidgetRef ref) => CalendarSnapshot(
  events: ref.read(eventsStreamProvider).value ?? const [],
  tasks: ref.read(tasksStreamProvider).value ?? const [],
  lists: ref.read(taskListsStreamProvider).value ?? const [],
  dayLinks: ref.read(dayLinksStreamProvider).value ?? const {},
);

String backupFileName([DateTime? now]) {
  final t = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'notlar-yedek-${t.year}-${two(t.month)}-${two(t.day)}'
      '${BackupService.fileExtension}';
}

Future<void> exportFullBackup(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final service = backupServiceOf(ref);
  final notes = ref.read(notesStreamProvider).value;
  if (service == null || notes == null) return;
  // Kilitli notların gövdesi yedekte DÜZ METİNDİR: kapı burada da korunur.
  if (notes.any((n) => n.locked) &&
      !await authenticateForNote(l10n.unlockAuthReason)) {
    return;
  }
  if (!context.mounted) return;
  final folders = ref.read(foldersStreamProvider).value ?? const [];
  final name = backupFileName();
  try {
    final XFile file;
    final progress = BackupProgress();
    final dialog = showBackupProgress(context, l10n.backupInProgress, progress);
    try {
      if (kIsWeb) {
        final sink = MemoryBackupSink();
        await service.export(
          sink,
          allNotes: notes,
          folderList: folders,
          calendarData: calendarSnapshotOf(ref),
          onProgress: progress.update,
          cancelled: () => progress.cancelled,
        );
        file = XFile.fromData(
          sink.bytes!,
          name: name,
          mimeType: 'application/zip',
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/$name';
        await service.export(
          FileBackupSink(path),
          allNotes: notes,
          folderList: folders,
          calendarData: calendarSnapshotOf(ref),
          onProgress: progress.update,
          cancelled: () => progress.cancelled,
        );
        file = XFile(path, mimeType: 'application/zip', name: name);
      }
    } finally {
      progress.finish();
      await dialog;
    }
    // Android: sistemin "kaydet" penceresi (İndirilenler, Drive…). Paylaşım
    // levhası yedeği kolayca Notlar'a "metin" olarak yolluyordu (2026-11-06
    // cihazda: zip baytları "PK..." notu oldu) ve dosya hiçbir yere kalmıyordu.
    if (!kIsWeb && Platform.isAndroid) {
      final saved = await _systemChannel.invokeMethod<bool>('saveDocument', {
        'path': file.path,
        'name': name,
        // octet-stream: zip türünde sistem uzantıyı .zip'e çevirebiliyor.
        'mimeType': 'application/octet-stream',
      });
      if (saved ?? false) messenger.showMessage(l10n.attachmentSavedAs(name));
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [file], subject: l10n.backupShareSubject),
    );
  } on BackupCancelled {
    messenger.showMessage(l10n.backupCancelled);
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  }
}

Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final service = backupServiceOf(ref);
  if (service == null) return;
  final file = await DocPicker.pickOne(
    const XTypeGroup(
      label: 'Yedek',
      extensions: ['notyedek', 'zip', 'json'],
      mimeTypes: [
        'application/zip',
        'application/json',
        'application/octet-stream',
      ],
    ),
  );
  if (file == null || !context.mounted) return;
  final existing = ref.read(notesStreamProvider).value ?? const [];
  final folders = ref.read(foldersStreamProvider).value ?? const [];
  final progress = BackupProgress();
  Future<void>? dialog;
  try {
    final head = await _head(file);
    final RestoreResult result;
    switch (sniffBackup(head)) {
      case BackupFormat.full:
        if (!context.mounted) return;
        dialog = showBackupProgress(context, l10n.restoreInProgress, progress);
        final Archive archive = kIsWeb || file.path.isEmpty
            ? ZipDecoder().decodeBytes(await file.readAsBytes())
            : openBackupFile(file.path);
        result = await service.restore(
          archive,
          existing: existing,
          existingFolders: folders,
          existingCalendar: calendarSnapshotOf(ref),
          onProgress: progress.update,
          cancelled: () => progress.cancelled,
          allowLocalOnly: !kIsWeb,
        );
      case BackupFormat.legacyJson:
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map) throw const FormatException();
        result = await service.restoreLegacyJson(
          Map<String, dynamic>.from(decoded),
          existing: existing,
        );
      case BackupFormat.unknown:
        throw const FormatException();
    }
    messenger.showMessage(
      l10n.restoreBackupResult(result.restored, result.skipped),
    );
  } on BackupCancelled {
    messenger.showMessage(l10n.backupCancelled);
  } on FormatException {
    messenger.showMessage(l10n.importBackupInvalid);
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  } finally {
    progress.finish();
    await dialog;
  }
}

/// Başka uygulamadan içe aktarma (F18.15): Keep Takeout zip'i, Markdown/txt
/// (tek dosya ya da zip), Evernote `.enex`, tek Keep `.json`.
Future<void> importFromOtherApps(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final notes = ref.read(notesRepositoryProvider);
  if (notes == null) return;
  final file = await DocPicker.pickOne(
    const XTypeGroup(
      label: 'Notlar',
      extensions: ['zip', 'md', 'markdown', 'txt', 'enex', 'json'],
      mimeTypes: [
        'application/zip',
        'text/markdown',
        'text/plain',
        'application/json',
        'application/xml',
        'text/xml',
        'application/octet-stream',
      ],
    ),
  );
  if (file == null || !context.mounted) return;
  final name = file.name.toLowerCase();
  final failed = <int>[];
  final progress = BackupProgress();
  Future<void>? dialog;
  try {
    final List<ImportedNote> items;
    final head = await _head(file);
    if (sniffBackup(head) == BackupFormat.full) {
      final Archive archive = kIsWeb || file.path.isEmpty
          ? ZipDecoder().decodeBytes(await file.readAsBytes())
          : openBackupFile(file.path);
      items = looksLikeKeepTakeout(archive)
          ? parseKeepTakeout(archive, failed: failed)
          : parseMarkdownArchive(archive, failed: failed);
    } else if (name.endsWith('.enex')) {
      items = parseEnex(await file.readAsString(), failed: failed);
    } else if (name.endsWith('.json')) {
      final decoded = jsonDecode(await file.readAsString());
      final one = decoded is Map
          ? parseKeepNoteJson(Map<String, dynamic>.from(decoded))
          : null;
      items = [?one];
    } else {
      final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
      final one = parseMarkdownNote(file.name, text);
      items = [?one];
    }
    if (items.isEmpty) {
      messenger.showMessage(l10n.importOtherNone);
      return;
    }
    if (!context.mounted) return;
    dialog = showBackupProgress(context, l10n.importInProgress, progress);
    final result =
        await ImportService(
          notes: notes,
          attachments: ref.read(attachmentRepositoryProvider),
        ).importAll(
          items,
          existing: ref.read(notesStreamProvider).value ?? const [],
          failed: failed.length,
          onProgress: progress.update,
          cancelled: () => progress.cancelled,
        );
    messenger.showMessage(
      l10n.importOtherResult(result.imported, result.skipped, result.failed),
    );
  } on BackupCancelled {
    messenger.showMessage(l10n.backupCancelled);
  } on FormatException {
    messenger.showMessage(l10n.importOtherNone);
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  } finally {
    progress.finish();
    await dialog;
  }
}

Future<Uint8List> _head(XFile file) async {
  if (!kIsWeb && file.path.isNotEmpty) {
    final raf = await File(file.path).open();
    try {
      return await raf.read(16);
    } finally {
      await raf.close();
    }
  }
  final all = await file.readAsBytes();
  return all.length > 16 ? Uint8List.sublistView(all, 0, 16) : all;
}

/// İlerleme durumu + iptal isteği (pencere ile hizmet arasında).
class BackupProgress extends ChangeNotifier {
  int done = 0;
  int total = 0;
  bool cancelled = false;
  bool finished = false;

  void update(int d, int t) {
    done = d;
    total = t;
    notifyListeners();
  }

  void cancel() {
    cancelled = true;
    notifyListeners();
  }

  void finish() {
    if (finished) return;
    finished = true;
    notifyListeners();
  }
}

/// İlerleme penceresi; [progress] bitince kendiliğinden kapanır.
Future<void> showBackupProgress(
  BuildContext context,
  String title,
  BackupProgress progress,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (ctx) => _ProgressDialog(title: title, progress: progress),
);

class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({required this.title, required this.progress});
  final String title;
  final BackupProgress progress;

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_changed);
    if (widget.progress.finished) _close();
  }

  void _changed() {
    if (widget.progress.finished) {
      _close();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _close() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    widget.progress.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: p.total == 0 ? null : p.done / p.total,
            ),
            const SizedBox(height: 12),
            Text(p.total == 0 ? '' : l10n.backupProgressCount(p.done, p.total)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: p.cancelled ? null : p.cancel,
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
