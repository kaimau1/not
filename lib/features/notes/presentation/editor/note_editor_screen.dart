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
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/presentation/ai_sheet.dart';
import '../../../folders/data/folders_repository.dart';
import '../../../folders/domain/note_folder.dart';
import '../../../folders/presentation/folder_sheets.dart';
import '../../../settings/settings_providers.dart';
import '../../data/attachment_repository.dart';
import '../../data/notes_repository.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/note_item.dart';
import '../../domain/note_type.dart';
import 'attachment_strip.dart';
import 'audio_recorder_sheet.dart';
import 'calculator_sheet.dart';
import 'dictation_sheet.dart';
import 'drawing_screen.dart';
import 'items_editor.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.startDrawing = false,
  });

  final String noteId;

  /// El yazısı modu: editör açılır açılmaz çizim tuvali gösterilir,
  /// kaydedilen çizim nota görsel eki olarak girer.
  final bool startDrawing;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  Note? _note;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _bodyFocus = FocusNode();
  final _debouncer = Debouncer();
  ProviderSubscription<AsyncValue<Note?>>? _sub;
  bool _deleted = false;

  @override
  void initState() {
    super.initState();
    if (widget.startDrawing) {
      // El yazısı modu: ilk kareden sonra doğrudan çizim tuvalini aç.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addDrawing();
      });
    }
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
    }
    _debouncer.dispose();
    _sub?.close();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
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

  /// Alt bardaki bir düğme (görünüm/renk, ek, hesap makinesi) alt sayfa/menü
  /// açmadan önce klavyeyi kesin kapatır. Klavye elle kapatılmış olsa bile bir
  /// metin alanı odakta kalabiliyor; alt sayfa kapanınca odak geri gelip
  /// klavye kendiliğinden açılıyordu (madde 10). Odağı düşürüp sonraki karede
  /// tekrar düşürerek bu geri açılmayı engelliyoruz.
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  Future<void> _showAttachMenu() async {
    _dismissKeyboard();
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
            ListTile(
              leading: const Icon(Icons.mic_none),
              title: Text(l10n.recordAudio),
              onTap: () => Navigator.pop(sheetContext, 'audio'),
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
      case 'audio':
        await _recordAudio();
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

  bool _titleGenerating = false;

  /// "Başlık öner" çipi: nota AI ile kısa bir başlık üretir ve doğrudan
  /// başlık alanına yazar (etiket önerisi gibi bağımsız, isteğe bağlı buton;
  /// eski "kapanırken otomatik başlık" genel ayarının yerini aldı).
  Future<void> _suggestTitle() async {
    final note = _note;
    if (note == null || note.isEmpty || _titleGenerating) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _titleGenerating = true);
    try {
      final title = await ref.read(geminiServiceProvider).generateTitle(note);
      if (!mounted || title.isEmpty) return;
      _titleController.text = title;
      _mutate((n) => n.copyWith(title: title), immediate: true);
    } on GeminiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content:
            Text(e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message)),
      ));
    } finally {
      if (mounted) setState(() => _titleGenerating = false);
    }
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

  /// Notu bir klasöre taşır (ya da klasörden çıkarır).
  Future<void> _pickFolder() async {
    final note = _note;
    if (note == null) return;
    final picked = await showFolderPickSheet(
      context,
      ref,
      currentFolderId: note.folderId,
    );
    if (picked == null) return;
    _mutate(
      (n) => picked.isEmpty
          ? n.copyWith(clearFolderId: true)
          : n.copyWith(folderId: picked),
      immediate: true,
    );
  }

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
  /// [asType] verilirse not o çalışma moduna da geçirilir: "maddelere çevir"
  /// sonucu yalnızca metni değil notun tipini de checklist/sıralı yapar.
  void _replaceText(String raw, {NoteType? asType}) {
    final note = _note;
    // Model istenmese de ** / * / # üretebiliyor; not düz metin tuttuğundan
    // temizle.
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    final targetType = asType ?? note.type;
    if (targetType == NoteType.text) {
      _bodyController.text = text.trim();
      _mutate(
        (n) => n.copyWith(type: targetType, body: text.trim()),
        immediate: true,
      );
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty)
            line.trim().replaceFirst(RegExp(r'^[-•*\d.]+\s*'), ''),
      ];
      _mutate(
        (n) => n.copyWith(
          type: targetType,
          // Tip değişiyorsa eski gövde temizlenir; içerik artık öğelerde.
          body: targetType == note.type ? null : '',
          items: [for (final line in lines) NoteItem(id: uuid.v4(), text: line)],
        ),
        immediate: true,
      );
      if (targetType != note.type) _bodyController.clear();
    }
  }

  /// AI çıktısını (OCR/döküm) notun gövdesine ya da liste öğelerine ekler.
  void _appendText(String raw) {
    final note = _note;
    final text = stripMarkdown(raw);
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
    _dismissKeyboard();
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

  /// Notun içeriğini (gövde + liste öğeleri) onay alarak temizler;
  /// başlık, etiketler ve ekler yerinde kalır.
  Future<void> _clearContent() async {
    final note = _note;
    if (note == null) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearNote),
        content: Text(l10n.clearNoteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.clearNote),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    _bodyController.clear();
    _mutate(
      (n) => n.copyWith(body: '', items: const []),
      immediate: true,
    );
  }

  /// Sesli yazdırma: konuşma yazıya döner. Metin notunda (anahtar varsa)
  /// konuşuldukça ANINDA nota yansır; liste tiplerinde bitişte öğe eklenir.
  Future<void> _dictate() async {
    final note = _note;
    if (note == null) return;
    if (note.type == NoteType.text) {
      // Diktenin ekleneceği taban: mevcut gövde + ayraç. Canlı döküm bunun
      // üstüne yazılır, böylece kullanıcı yazının notta belirdiğini görür.
      final base = _bodyController.text;
      final baseWithSep = base.trim().isEmpty ? '' : '${base.trimRight()}\n';
      void writeLive(String full) {
        final combined = baseWithSep + full;
        _bodyController.value = TextEditingValue(
          text: combined,
          selection: TextSelection.collapsed(offset: combined.length),
        );
        _mutate((n) => n.copyWith(body: combined), immediate: true);
      }

      final text = await showDictationSheet(context, onPartial: writeLive);
      // Anahtarsız yolda canlı akış olmaz; dönen son metni burada yaz.
      if (text != null && text.trim().isNotEmpty) writeLive(text.trim());
      return;
    }
    final text = await showDictationSheet(context);
    if (text == null || text.trim().isEmpty) return;
    _appendText(text);
  }

  /// Dahili hesap makinesi: sonucu metin notunda imlecin bulunduğu yere,
  /// listelerde yeni öğe olarak ekler.
  Future<void> _openCalculator() async {
    // Gövde odağını bırak: alt sayfa kapanınca klavye kendiliğinden geri
    // açılmasın (odaklı alan kalırsa Flutter klavyeyi yeniden gösterir).
    _dismissKeyboard();
    final result = await showCalculatorSheet(context);
    // Sonuç metne/öğeye programatik eklenir; kullanıcı yazmıyordu, klavye
    // kapalı kalsın (sonuç eklendikten sonra alan odaklanmaz).
    _dismissKeyboard();
    if (result == null || result.isEmpty) return;
    final note = _note;
    if (note == null) return;
    if (note.type == NoteType.text) {
      final body = _bodyController.text;
      final selection = _bodyController.selection;
      final start = selection.isValid ? selection.start : body.length;
      final end = selection.isValid ? selection.end : body.length;
      final updated = body.replaceRange(start, end, result);
      _bodyController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: start + result.length),
      );
      _mutate((n) => n.copyWith(body: updated), immediate: true);
    } else {
      // _appendText liste öğelerinde satır başındaki rakamları madde
      // numarası sanıp kırpar; sonuç sayı içerdiğinden öğe doğrudan eklenir.
      const uuid = Uuid();
      _mutate(
        (n) => n.copyWith(
          items: [...n.items, NoteItem(id: uuid.v4(), text: result)],
        ),
        immediate: true,
      );
    }
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

    // Notun bağlı olduğu klasör (varsa) çipte gösterilir.
    final folders =
        ref.watch(foldersStreamProvider).value ?? const <NoteFolder>[];
    NoteFolder? noteFolder;
    if (note.folderId != null) {
      for (final f in folders) {
        if (f.id == note.folderId) {
          noteFolder = f;
          break;
        }
      }
    }

    // Etiket/öneri EYLEMLERİ tek bir menüde toplanır: hatırlatıcı, klasör ve
    // etiket çipleriyle birlikte tek satırda kalır (madde 7). Menüden kullanıcı
    // hangi ekleme/öneri işlemini uygulayacağını seçer — çipler satırı taşırıp
    // dikeyde yer kaplamaz. Uzun etiket dizileri yatayda kaydırılır.
    final actionEntries = <PopupMenuEntry<String>>[
      PopupMenuItem(
        value: 'add-tag',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.new_label_outlined),
          title: Text(l10n.addTag),
        ),
      ),
      if (!note.isEmpty)
        PopupMenuItem(
          value: 'suggest-tags',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.auto_awesome),
            title: Text(l10n.suggestTags),
          ),
        ),
      if (!note.isEmpty && note.title.trim().isEmpty)
        PopupMenuItem(
          value: 'suggest-title',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.title),
            title: Text(l10n.suggestTitle),
          ),
        ),
      if (note.reminderAt == null)
        PopupMenuItem(
          value: 'add-reminder',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.alarm_add_outlined),
            title: Text(l10n.addReminder),
          ),
        ),
    ];

    final actionsMenu = PopupMenuButton<String>(
      tooltip: l10n.noteMetaMenu,
      onSelected: (action) {
        switch (action) {
          case 'add-tag':
            _addTag();
          case 'suggest-tags':
            _suggestTags();
          case 'suggest-title':
            _suggestTitle();
          case 'add-reminder':
            _pickReminder();
        }
      },
      itemBuilder: (context) => actionEntries,
      child: Chip(
        avatar: _titleGenerating
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome, size: 16),
        label: Text(l10n.noteMetaMenu),
      ),
    );

    final metaChildren = <Widget>[
      if (note.reminderAt != null)
        InputChip(
          avatar: const Icon(Icons.alarm, size: 16),
          label: Text(
            DateFormat('d MMM HH:mm', 'tr').format(note.reminderAt!),
          ),
          onPressed: _pickReminder,
          onDeleted: _clearReminder,
        ),
      // Klasör çipi: doluysa klasör adı+simge, boşsa "Klasör" ekleme.
      ActionChip(
        avatar: Icon(
          noteFolder?.iconData ?? Icons.create_new_folder_outlined,
          size: 16,
        ),
        label: Text(noteFolder?.name ?? l10n.folder),
        onPressed: _pickFolder,
      ),
      for (final tag in note.tags)
        InputChip(
          label: Text('#$tag'),
          onDeleted: () => _removeTag(tag),
        ),
      actionsMenu,
    ];

    final metaChips = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < metaChildren.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              metaChildren[i],
            ],
          ],
        ),
      ),
    );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleField,
        metaChips,
        // Son güncelleme zamanı — kullanıcı en son ne zaman dokunduğunu görür.
        if (note.updatedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              l10n.editedAt(
                DateFormat('d MMM y HH:mm', 'tr').format(note.updatedAt!),
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        AttachmentStrip(
          attachments: note.attachments,
          onRemove: _removeAttachment,
        ),
      ],
    );

    final Widget body = switch (note.type) {
      // Gövde alanı en az bir ekran boyu yüksekliğe zorlanır ve tüm bu alan
      // (metnin bittiği yerin altındaki boşluk dahil) dokunuşla gövdeye
      // odaklanır — böylece yazmaya başlamak için sadece üst kısma değil,
      // aşağıya doğru her yere dokunmak yeterlidir.
      NoteType.text => LayoutBuilder(
          builder: (context, constraints) => ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              header,
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!_bodyFocus.hasFocus) _bodyFocus.requestFocus();
                },
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _bodyController,
                          focusNode: _bodyFocus,
                          onChanged: (value) =>
                              _mutate((n) => n.copyWith(body: value)),
                          maxLines: null,
                          minLines: 8,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: l10n.bodyHint,
                            filled: false,
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
              tooltip: note.starred ? l10n.unstar : l10n.star,
              icon: Icon(
                note.starred ? Icons.star : Icons.star_outline,
                color: note.starred ? Colors.amber.shade600 : null,
              ),
              onPressed: () => _mutate(
                (n) => n.copyWith(starred: !n.starred),
                immediate: true,
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
                  case 'clear':
                    _clearContent();
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
                  value: 'clear',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.backspace_outlined),
                    title: Text(l10n.clearNote),
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
                tooltip: l10n.calculatorTitle,
                icon: const Icon(Icons.calculate_outlined),
                onPressed: _openCalculator,
              ),
              const Spacer(),
              // Mikrofon başparmak bölgesinde, AI'ın yanında ve dolgulu:
              // yardımcı ikonların arasında kaybolmaz. Ses kaydı eki artık
              // ataş menüsünde; bu düğme konuşmayı anlık yazıya döker.
              IconButton.filledTonal(
                tooltip: l10n.liveDictation,
                icon: const Icon(Icons.mic_none),
                onPressed: _dictate,
              ),
              const SizedBox(width: 4),
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
