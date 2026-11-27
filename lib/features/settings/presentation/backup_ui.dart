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

import '../../../app/theme/app_tokens.dart';
import '../../../core/friendly_error.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/utils/note_e2ee_session.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../entitlement/presentation/pro_lock.dart';
import '../../folders/data/folders_repository.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/backup_files.dart';
import '../../notes/data/backup_service.dart';
import '../../notes/data/import_service.dart';
import '../../notes/data/markdown_export.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/data/zip_guard.dart';
import '../settings_providers.dart' show sharedPreferencesProvider;

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

/// Takvim/görev/rutin/gün bağlarının o anki hâli (yedeğe girer, F46.5).
CalendarSnapshot calendarSnapshotOf(WidgetRef ref) => CalendarSnapshot(
  events: ref.read(eventsStreamProvider).value ?? const [],
  tasks: ref.read(tasksStreamProvider).value ?? const [],
  lists: ref.read(taskListsStreamProvider).value ?? const [],
  dayLinks: ref.read(dayLinksStreamProvider).value ?? const {},
  routines: ref.read(routinesStreamProvider).value ?? const [],
  routineLogs: [
    for (final byDay
        in (ref.read(routineLogsStreamProvider).value ?? const {}).values)
      ...byDay.values,
  ],
);

String backupFileName([DateTime? now]) {
  final t = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'notlar-yedek-${t.year}-${two(t.month)}-${two(t.day)}'
      '${BackupService.fileExtension}';
}

/// SON TAM YEDEK (F54.2, rakip yorumlarındaki "yedek alındı sanıyordum"
/// şikâyeti): yedek dosyası GERÇEKTEN kaydedildiğinde (sistem Kaydet
/// penceresi onaylandı / paylaşım tamamlandı) zamanı ve not sayısı cihaz
/// tercihine yazılır; Ayarlar'daki gösterge bunu okur. null = hiç alınmadı.
final lastBackupProvider =
    NotifierProvider<LastBackup, ({DateTime at, int count})?>(LastBackup.new);

class LastBackup extends Notifier<({DateTime at, int count})?> {
  static const _atKey = 'last_full_backup_at';
  static const _countKey = 'last_full_backup_count';

  @override
  ({DateTime at, int count})? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final at = prefs.getInt(_atKey);
    if (at == null) return null;
    return (
      at: DateTime.fromMillisecondsSinceEpoch(at),
      count: prefs.getInt(_countKey) ?? 0,
    );
  }

  void record(int count, {DateTime? at}) {
    final when = at ?? DateTime.now();
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt(_atKey, when.millisecondsSinceEpoch);
    prefs.setInt(_countKey, count);
    state = (at: when, count: count);
  }
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
  final choice = await showBackupExportPasswordDialog(context);
  if (choice == null || !context.mounted) return;
  final password = choice.password;
  // PL6 `encryptedBackup` kapısı (savunma): pencere kilitliyken parola
  // döndürmez; yine de gelirse parolalı yedek yazılmaz. Parolasız yedek ve
  // şifreli yedeği GERİ YÜKLEME (restoreBackup) kapısızdır.
  if (password != null &&
      !ref.read(proFeatureProvider(ProFeature.encryptedBackup))) {
    openProScreen(context);
    return;
  }
  final folders = ref.read(foldersStreamProvider).value ?? const [];
  final exportNotes = [
    for (final n in notes)
      n.locked ? n.decryptWithKey(NoteE2eeSession.key) : n,
  ];
  final name = backupFileName();
  try {
    final XFile file;
    final progress = BackupProgress();
    final dialog = showBackupProgress(context, l10n.backupInProgress, progress);
    try {
      if (kIsWeb) {
        final sink = MemoryBackupSink(password: password);
        await service.export(
          sink,
          allNotes: exportNotes,
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
          FileBackupSink(path, password: password),
          allNotes: exportNotes,
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
      if (saved ?? false) {
        ref.read(lastBackupProvider.notifier).record(notes.length);
        messenger.showMessage(l10n.attachmentSavedAs(name));
      }
      return;
    }
    final shared = await SharePlus.instance.share(
      ShareParams(files: [file], subject: l10n.backupShareSubject),
    );
    // Web'de dosya indirilir (durum "unavailable" döner); vazgeçilen
    // paylaşım yedek sayılmaz.
    if (shared.status != ShareResultStatus.dismissed) {
      ref.read(lastBackupProvider.notifier).record(notes.length);
    }
  } on BackupCancelled {
    messenger.showMessage(l10n.backupCancelled);
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  }
}

/// Kolay dışa aktarma (PLAN §1.4/6): tüm etkin notları klasör düzeninde
/// standart Markdown (`.md`) dosyaları olarak tek `.zip` arşivinde dışa aktarır.
Future<void> exportMarkdownZip(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final notes = ref.read(notesStreamProvider).value;
  if (notes == null) return;
  final active = [
    for (final n in notes)
      if (n.deletedAt == null) n,
  ];
  if (active.isEmpty) {
    messenger.showMessage(l10n.exportMarkdownZipEmpty);
    return;
  }
  if (active.any((n) => n.locked) &&
      !await authenticateForNote(l10n.unlockAuthReason)) {
    return;
  }
  if (!context.mounted) return;
  final decryptedActive = [
    for (final n in active)
      n.locked ? n.decryptWithKey(NoteE2eeSession.key) : n,
  ];
  final folders = ref.read(foldersStreamProvider).value ?? const [];
  final name = markdownExportFileName();
  try {
    final isEn = l10n.localeName.startsWith('en');
    final result = buildMarkdownZip(
      decryptedActive,
      folders: folders,
      archiveFolderName: l10n.archive,
      untitled: l10n.untitledNote,
      pagePrefix: isEn ? 'Page' : 'Sayfa',
      attachmentsHeading: isEn ? 'Attachments' : 'Ekler',
    );
    final XFile file;
    if (kIsWeb) {
      file = XFile.fromData(
        result.bytes,
        name: name,
        mimeType: 'application/zip',
      );
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$name';
      await File(path).writeAsBytes(result.bytes, flush: true);
      file = XFile(path, mimeType: 'application/zip', name: name);
    }
    if (!kIsWeb && Platform.isAndroid) {
      final saved = await _systemChannel.invokeMethod<bool>('saveDocument', {
        'path': file.path,
        'name': name,
        'mimeType': 'application/zip',
      });
      if (saved ?? false) {
        messenger.showMessage(l10n.exportMarkdownZipDone(result.exportedCount));
      }
      return;
    }
    final shared = await SharePlus.instance.share(
      ShareParams(files: [file], subject: l10n.exportMarkdownZip),
    );
    if (shared.status != ShareResultStatus.dismissed) {
      messenger.showMessage(l10n.exportMarkdownZipDone(result.exportedCount));
    }
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
    final encrypted = isEncryptedZipHead(head);
    final RestoreResult result;
    switch (sniffBackup(head)) {
      case BackupFormat.full:
        String? password;
        if (encrypted) {
          if (!context.mounted) return;
          password = await showBackupRestorePasswordDialog(context);
          if (password == null || password.isEmpty || !context.mounted) return;
        }
        if (!context.mounted) return;
        dialog = showBackupProgress(context, l10n.restoreInProgress, progress);
        final Archive archive = kIsWeb || file.path.isEmpty
            ? ZipGuard.decodeBytes(
                await file.readAsBytes(),
                password: password,
              )
            : openBackupFile(file.path, password: password);
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
  } on ArchiveException {
    messenger.showMessage(l10n.backupWrongPassword);
  } on FormatException {
    messenger.showMessage(l10n.importBackupInvalid);
  } catch (e) {
    messenger.showMessage(l10n.genericError(friendlyError(l10n, e)));
  } finally {
    progress.finish();
    await dialog;
  }
}

/// Parolalı tam yedek dışa aktarma penceresi (P91, PLAN §1.4/6).
/// `null` = iptal, `(password: null)` = parolasız, `(password: '...')` = AES-256.
Future<({String? password})?> showBackupExportPasswordDialog(
  BuildContext context,
) => showDialog<({String? password})>(
  context: context,
  builder: (_) => const _ExportPasswordDialog(),
);

/// Şifreli yedek geri yüklerken parola soran pencere (P91).
Future<String?> showBackupRestorePasswordDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _RestorePasswordDialog(),
    );

class _ExportPasswordDialog extends ConsumerStatefulWidget {
  const _ExportPasswordDialog();

  @override
  ConsumerState<_ExportPasswordDialog> createState() =>
      _ExportPasswordDialogState();
}

class _ExportPasswordDialogState extends ConsumerState<_ExportPasswordDialog> {
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submitEncrypted() {
    final p = _pass.text;
    if (p.isEmpty) {
      Navigator.pop(context, (password: null));
      return;
    }
    if (p != _confirm.text) {
      setState(() => _error = context.l10n.backupPasswordMismatch);
      return;
    }
    Navigator.pop(context, (password: p));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // PL6: parolalı yedek kilitliyse alanlar gizlenir, "Parolasız yedekle"
    // kalır, şifreli düğme kilit taşıyıp Pro ekranına götürür.
    final unlocked = ref.watch(proFeatureProvider(ProFeature.encryptedBackup));
    return AlertDialog(
      title: Text(l10n.backupPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s,
        children: [
          Text(
            unlocked ? l10n.backupPasswordInfo : l10n.backupPasswordProLocked,
            style: AppText.of(theme).meta,
          ),
          if (unlocked) ...[
            TextField(
              key: const ValueKey('backup-export-pass'),
              controller: _pass,
              obscureText: _obscure,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: l10n.backupPasswordHint,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            TextField(
              key: const ValueKey('backup-export-pass-confirm'),
              controller: _confirm,
              obscureText: _obscure,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submitEncrypted(),
              decoration: InputDecoration(
                labelText: l10n.backupPasswordConfirmHint,
                errorText: _error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('backup-export-no-pass'),
          onPressed: () => Navigator.pop(context, (password: null)),
          child: Text(l10n.backupWithoutPassword),
        ),
        if (unlocked)
          FilledButton(
            key: const ValueKey('backup-export-with-pass'),
            onPressed: _submitEncrypted,
            child: Text(l10n.backupWithPassword),
          )
        else
          FilledButton.icon(
            key: const ValueKey('backup-export-pro'),
            onPressed: () => openProScreen(context, popFirst: true),
            icon: const Icon(Icons.lock_outline, size: AppIconSize.s),
            label: Text(l10n.backupSeeTiers),
          ),
      ],
    );
  }
}

class _RestorePasswordDialog extends StatefulWidget {
  const _RestorePasswordDialog();

  @override
  State<_RestorePasswordDialog> createState() => _RestorePasswordDialogState();
}

class _RestorePasswordDialogState extends State<_RestorePasswordDialog> {
  final _pass = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    final p = _pass.text;
    if (p.isEmpty) return;
    Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.backupEnterPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.s,
        children: [
          Text(l10n.backupEnterPasswordBody, style: AppText.of(theme).meta),
          TextField(
            key: const ValueKey('backup-restore-pass'),
            controller: _pass,
            obscureText: _obscure,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.backupPasswordHint,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('backup-restore-pass-submit'),
          onPressed: _submit,
          child: Text(l10n.ok),
        ),
      ],
    );
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
          ? ZipGuard.decodeBytes(await file.readAsBytes())
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
