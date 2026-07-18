import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/presentation/ai_sheet.dart';
import '../../../settings/settings_providers.dart';
import '../../data/attachment_repository.dart';
import '../../data/notes_repository.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/note_item.dart';
import '../../domain/note_type.dart';
import 'attachment_strip.dart';
import 'audio_recorder_sheet.dart';
import 'drawing_screen.dart';
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
    } else if (!_deleted && note != null) {
      if (note.tags.isEmpty) _autoTagInBackground(note);
      if (note.title.trim().isEmpty) _autoTitleInBackground(note);
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

  Future<void> _recordAudio() async {
    final result = await showAudioRecorderSheet(context);
    if (result == null) return;
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    try {
      final attachment = await repo.prepareAudio(
        noteId: widget.noteId,
        sourcePath: result.path,
        duration: result.duration,
      );
      _mutate(
        (n) => n.copyWith(attachments: [...n.attachments, attachment]),
        immediate: true,
      );
    } on FileTooLargeException {
      if (mounted) _showSnack(context.l10n.attachmentTooLarge);
    }
  }

  Future<void> _addDrawing() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => const DrawingScreen()),
    );
    if (bytes == null) return;
    await _addImageBytes(bytes, 'cizim.png');
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
            ListTile(
              leading: const Icon(Icons.brush_outlined),
              title: Text(l10n.addDrawing),
              onTap: () => Navigator.pop(sheetContext, 'drawing'),
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
      case 'drawing':
        await _addDrawing();
      case 'paste':
        await _pasteImage();
    }
  }

  // ---- Diğer eylemler -------------------------------------------------

  Future<void> _pickReminder() async {
    final note = _note;
    if (note == null) return;
    final now = DateTime.now();
    final initial = note.reminderAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final reminder =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    _mutate((n) => n.copyWith(reminderAt: reminder), immediate: true);
  }

  void _clearReminder() =>
      _mutate((n) => n.copyWith(clearReminderAt: true), immediate: true);

  /// Ayarlarda açıksa, editör kapanırken etiketsiz notu arka planda
  /// AI ile etiketler.
  void _autoTagInBackground(Note note) {
    if (note.toPlainText().length < 20) return;
    final enabled = ref.read(autoTagProvider);
    if (!enabled) return;
    final service = ref.read(geminiServiceProvider);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    Future(() async {
      try {
        final tags = await service.suggestTags(note);
        if (tags.isNotEmpty) repo.updateFields(note.id, {'tags': tags});
      } catch (_) {
        // Anahtar yoksa veya istek başarısızsa sessizce geç.
      }
    });
  }

  /// Ayarlarda açıksa (varsayılan açık), editör kapanırken başlıksız nota
  /// arka planda hızlı lite modelle kısa bir başlık üretir.
  void _autoTitleInBackground(Note note) {
    if (note.toPlainText().length < 20) return;
    if (!ref.read(autoTitleProvider)) return;
    final service = ref.read(geminiServiceProvider);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    Future(() async {
      try {
        final title = await service.generateTitle(note);
        if (title.isNotEmpty) repo.updateFields(note.id, {'title': title});
      } catch (_) {
        // Anahtar yoksa veya istek başarısızsa sessizce geç.
      }
    });
  }

  /// AI'dan etiket önerisi al ve seçtir.
  Future<void> _suggestTags() async {
    final note = _note;
    if (note == null || note.isEmpty) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    List<String> suggestions;
    try {
      suggestions = await ref.read(geminiServiceProvider).suggestTags(note);
    } on GeminiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message)),
      ));
      return;
    }
    suggestions = [
      for (final tag in suggestions)
        if (!note.tags.contains(tag)) tag,
    ];
    if (suggestions.isEmpty || !mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Wrap(
            spacing: 8,
            children: [
              for (final tag in suggestions)
                ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => Navigator.pop(sheetContext, tag),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      _mutate(
        (n) => n.copyWith(tags: {...n.tags, selected}.toList()),
        immediate: true,
      );
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addTag),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.tagHint),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    final cleaned =
        tag?.trim().replaceAll('#', '').replaceAll(' ', '-').toLowerCase();
    if (cleaned == null || cleaned.isEmpty) return;
    _mutate(
      (n) => n.copyWith(tags: {...n.tags, cleaned}.toList()),
      immediate: true,
    );
  }

  void _removeTag(String tag) => _mutate(
        (n) => n.copyWith(tags: [for (final t in n.tags) if (t != tag) t]),
        immediate: true,
      );

  Future<void> _share() async {
    final note = _note;
    if (note == null) return;
    final text = note.toPlainText();
    if (text.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: note.title.trim().isEmpty ? 'Not' : note.title.trim(),
      ),
    );
  }

  /// Not kilidi: kilitlemek serbest, kilidi kaldırmak kimlik doğrulaması
  /// ister (kart zaten açarken doğruluyor ama menüden de korunmalı).
  Future<void> _toggleLock() async {
    final note = _note;
    if (note == null) return;
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok) return;
    }
    _mutate((n) => n.copyWith(locked: !n.locked), immediate: true);
  }

  void _toggleArchive() {
    final note = _note;
    if (note == null) return;
    final archived = note.archivedAt != null;
    _mutate(
      (n) => archived
          ? n.copyWith(clearArchivedAt: true)
          : n.copyWith(archivedAt: DateTime.now()),
      immediate: true,
    );
    if (!archived) Navigator.of(context).pop();
  }

  /// AI çıktısıyla notun içeriğini değiştirir ("Geliştir" sonuçları için).
  void _replaceText(String text) {
    final note = _note;
    if (note == null || text.trim().isEmpty) return;
    if (note.type == NoteType.text) {
      _bodyController.text = text.trim();
      _mutate((n) => n.copyWith(body: text.trim()), immediate: true);
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty)
            line.trim().replaceFirst(RegExp(r'^[-•*\d.]+\s*'), ''),
      ];
      _mutate(
        (n) => n.copyWith(
          items: [for (final line in lines) NoteItem(id: uuid.v4(), text: line)],
        ),
        immediate: true,
      );
    }
  }

  /// AI çıktısını (OCR/döküm) notun gövdesine ya da liste öğelerine ekler.
  void _appendText(String text) {
    final note = _note;
    if (note == null || text.trim().isEmpty) return;
    if (note.type == NoteType.text) {
      final combined =
          note.body.trim().isEmpty ? text.trim() : '${note.body}\n\n${text.trim()}';
      _bodyController.text = combined;
      _mutate((n) => n.copyWith(body: combined), immediate: true);
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty)
            line.trim().replaceFirst(RegExp(r'^[-•*\d.]+\s*'), ''),
      ];
      _mutate(
        (n) => n.copyWith(items: [
          ...n.items,
          for (final line in lines) NoteItem(id: uuid.v4(), text: line),
        ]),
        immediate: true,
      );
    }
  }

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

    final metaChips = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (note.reminderAt != null)
            InputChip(
              avatar: const Icon(Icons.alarm, size: 16),
              label: Text(
                DateFormat('d MMM HH:mm', 'tr').format(note.reminderAt!),
              ),
              onPressed: _pickReminder,
              onDeleted: _clearReminder,
            ),
          for (final tag in note.tags)
            InputChip(
              label: Text('#$tag'),
              onDeleted: () => _removeTag(tag),
            ),
          ActionChip(
            avatar: const Icon(Icons.new_label_outlined, size: 16),
            label: Text(l10n.addTag),
            onPressed: _addTag,
          ),
          if (!note.isEmpty)
            ActionChip(
              avatar: const Icon(Icons.auto_awesome, size: 16),
              label: Text(l10n.suggestTags),
              onPressed: _suggestTags,
            ),
          if (note.reminderAt == null)
            ActionChip(
              avatar: const Icon(Icons.alarm_add_outlined, size: 16),
              label: Text(l10n.addReminder),
              onPressed: _pickReminder,
            ),
        ],
      ),
    );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleField,
        metaChips,
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
          expandItems: ref.watch(expandListItemsProvider),
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
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'share':
                    _share();
                  case 'lock':
                    _toggleLock();
                  case 'archive':
                    _toggleArchive();
                  case 'delete':
                    _delete();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share_outlined),
                    title: Text(l10n.share),
                  ),
                ),
                PopupMenuItem(
                  value: 'lock',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(note.locked
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline),
                    title:
                        Text(note.locked ? l10n.unlockNote : l10n.lockNote),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(note.archivedAt != null
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined),
                    title: Text(note.archivedAt != null
                        ? l10n.unarchive
                        : l10n.archive),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.delete),
                  ),
                ),
              ],
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
              IconButton(
                tooltip: l10n.recordAudio,
                icon: const Icon(Icons.mic_none),
                onPressed: _recordAudio,
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => showAiSheet(
                  context,
                  note,
                  onAppendText: _appendText,
                  onReplaceText: _replaceText,
                ),
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
