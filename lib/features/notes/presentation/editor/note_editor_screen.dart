import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../ai/presentation/ai_sheet.dart';
import '../../data/attachment_repository.dart';
import '../../data/notes_repository.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/note_type.dart';
import 'attachment_strip.dart';
import 'items_editor.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  Note? _note;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _debouncer = Debouncer();
  ProviderSubscription<AsyncValue<Note?>>? _sub;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual(
      noteStreamProvider(widget.noteId),
      (previous, next) {
        final incoming = next.value;
        if (incoming == null) return;
        if (_note == null) {
          setState(() {
            _note = incoming;
            _titleController.text = incoming.title;
            _bodyController.text = incoming.body;
          });
        } else {
          // Editör açıkken yerel metin esastır; yalnızca arka planda değişen
          // alanları (ek yüklemeleri, AI özeti) benimse.
          setState(() {
            _note = _note!.copyWith(
              attachments: incoming.attachments,
              aiSummary: incoming.aiSummary,
            );
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _debouncer.flush();
    final note = _note;
    if (!_deleted && note != null && note.isEmpty) {
      // İçi boş kalan not çıkarken sessizce silinir.
      ref.read(notesRepositoryProvider)?.hardDelete(note.id);
    }
    _debouncer.dispose();
    _sub?.close();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _mutate(Note Function(Note) transform, {bool immediate = false}) {
    final note = _note;
    if (note == null) return;
    setState(() => _note = transform(note));
    void save() {
      final current = _note;
      if (current != null && !_deleted) {
        ref.read(notesRepositoryProvider)?.updateNote(current);
      }
    }

    if (immediate) {
      _debouncer.cancel();
      save();
    } else {
      _debouncer(save);
    }
  }

  // ---- Ekler ----------------------------------------------------------

  Future<void> _addImageBytes(Uint8List bytes, String fileName) async {
    final tooLargeMessage = context.l10n.attachmentTooLarge;
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.prepareImage(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: fileName,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      _showSnack(tooLargeMessage);
    }
  }

  Future<void> _pickImage() async {
    if (_isDesktop) {
      const group = XTypeGroup(
        label: 'Görseller',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
      );
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      await _addImageBytes(await file.readAsBytes(), file.name);
    } else {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      await _addImageBytes(await file.readAsBytes(), file.name);
    }
  }

  Future<void> _pickPdf() async {
    const group = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    final file = await openFile(acceptedTypeGroups: const [group]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.preparePdf(
        noteId: widget.noteId,
        bytes: bytes,
        fileName: file.name,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      if (mounted) _showSnack(context.l10n.attachmentTooLarge);
    }
  }

  Future<void> _pasteImage() async {
    final bytes = await Pasteboard.image;
    if (bytes == null) {
      if (mounted) _showSnack(context.l10n.clipboardEmpty);
      return;
    }
    await _addImageBytes(bytes, 'pano.png');
  }

  void _removeAttachment(Attachment attachment) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id != attachment.id) a,
        ],
      ),
      immediate: true,
    );
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo != null) {
      repo.deleteFromStorage(attachment).ignore();
    }
    if (attachment.localPath.isNotEmpty) {
      File(attachment.localPath).delete().ignore();
    }
  }

  Future<void> _showAttachMenu() async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.addImage),
              onTap: () => Navigator.pop(sheetContext, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.addPdf),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
            if (_isDesktop)
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: Text(l10n.pasteImage),
                onTap: () => Navigator.pop(sheetContext, 'paste'),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'image':
        await _pickImage();
      case 'pdf':
        await _pickPdf();
      case 'paste':
        await _pasteImage();
    }
  }

  // ---- Diğer eylemler -------------------------------------------------

  Future<void> _showColorSheet() async {
    final note = _note;
    if (note == null) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Wrap(
            spacing: 12,
            children: [
              for (final color in NoteColor.values)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    _mutate((n) => n.copyWith(color: color), immediate: true);
                    Navigator.pop(sheetContext);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: NoteColors.swatch(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: note.color == color
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: color == NoteColor.none
                        ? const Icon(Icons.format_color_reset_outlined, size: 20)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _delete() {
    final repo = ref.read(notesRepositoryProvider);
    final note = _note;
    if (repo == null || note == null) return;
    _deleted = true;
    repo.softDelete(note.id);
    Navigator.of(context).pop();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Arayüz ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = _note;

    if (note == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final pending =
        ref.watch(pendingWritesProvider(widget.noteId)).value ?? false;
    final background = NoteColors.surface(context, note.color);

    final titleField = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _titleController,
        onChanged: (value) => _mutate((n) => n.copyWith(title: value)),
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600),
        maxLines: null,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: l10n.titleHint,
          filled: false,
          border: InputBorder.none,
        ),
      ),
    );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleField,
        AttachmentStrip(
          attachments: note.attachments,
          onRemove: _removeAttachment,
        ),
      ],
    );

    final Widget body = switch (note.type) {
      NoteType.text => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            header,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _bodyController,
                onChanged: (value) => _mutate((n) => n.copyWith(body: value)),
                maxLines: null,
                minLines: 10,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: l10n.bodyHint,
                  filled: false,
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      NoteType.checklist || NoteType.ordered => ItemsEditor(
          key: ValueKey('items-${note.id}'),
          items: note.items,
          showCheckboxes: note.type == NoteType.checklist,
          onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
          header: header,
        ),
    };

    return CallbackShortcuts(
      bindings: {
        if (_isDesktop)
          const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
              _pasteImage,
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: pending ? l10n.syncPending : l10n.synced,
                child: Icon(
                  pending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                  size: 18,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: pending ? 0.9 : 0.5),
                ),
              ),
            ),
            IconButton(
              tooltip: note.pinned ? l10n.unpin : l10n.pin,
              icon: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () =>
                  _mutate((n) => n.copyWith(pinned: !n.pinned), immediate: true),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
        ),
        body: SafeArea(child: body),
        bottomNavigationBar: BottomAppBar(
          color: background,
          height: 56,
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.color,
                icon: const Icon(Icons.palette_outlined),
                onPressed: _showColorSheet,
              ),
              IconButton(
                tooltip: l10n.addAttachment,
                icon: const Icon(Icons.attach_file),
                onPressed: _showAttachMenu,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => showAiSheet(context, note),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(l10n.aiTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
