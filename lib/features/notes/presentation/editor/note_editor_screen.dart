import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/constants.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/note_guard.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../ai/data/ai_gate.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/presentation/ai_sheet.dart';
import '../../../ai/presentation/listen_screen.dart';
import '../../../folders/data/folders_repository.dart';
import '../../../folders/domain/note_folder.dart';
import '../../../folders/presentation/folder_sheets.dart';
import '../../../settings/settings_providers.dart';
import '../../data/attachment_repository.dart';
import '../../data/device_speech.dart';
import '../../data/notes_repository.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/note_item.dart';
import '../../domain/note_type.dart';
import '../color_picker_sheet.dart';
import '../notes_providers.dart';
import '../pdf_export_screen.dart';
import 'attachment_strip.dart';
import 'audio_recorder_sheet.dart';
import 'calculator_sheet.dart';
import 'dictation_sheet.dart';
import 'drawing_screen.dart';
import 'items_editor.dart';
import 'note_images.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Bir liste satırının başındaki işaretleri ayıklar: madde imi (-, •, *),
/// numara (1. / 1)) ve onay kutusu ([ ], [x]). Onay kutusu doluysa
/// [checked] true döner. AI çıktısı / yapıştırılan metin nota geri
/// uygulanırken bu işaretlerin öğe metnine sızmasını engeller (madde 1:
/// "notların başına çift parantez ve çarpılı durum ekliyor").
({String text, bool checked}) _parseListLine(String line) {
  var s = line.trim();
  s = s.replaceFirst(RegExp(r'^[-•*]\s+'), '');
  s = s.replaceFirst(RegExp(r'^\d+[.)]\s+'), '');
  var checked = false;
  final box = RegExp(r'^\[\s*([xX])?\s*\]\s*').firstMatch(s);
  if (box != null) {
    checked = box.group(1) != null;
    s = s.substring(box.end);
  }
  return (text: s.trim(), checked: checked);
}

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

  /// Doğrudan (alt sayfasız) dikte durumu.
  StreamSubscription<({String? text, double? level})>? _speechSub;
  bool _dictating = false;

  @override
  void initState() {
    super.initState();
    // İlk açılış kasması (madde 3): editör başlangıçta _note null olduğu için
    // bir kare boyunca CircularProgressIndicator gösterip ardından tüm editörü
    // kuruyordu; bu geçiş, sayfa animasyonuyla aynı anda büyük bir yerleşim
    // sıçraması yaratıyordu. Not zaten dashboard akışında yüklü olduğundan
    // (kullanıcı oradan geldi) onu SENKRON okuyup ilk kareyi dolu kur —
    // spinner→editör takası ve onunla gelen kasma ortadan kalkar.
    final cached = _cachedNote();
    if (cached != null) {
      _note = cached;
      _titleController.text = cached.title;
      _bodyController.text = cached.body;
    }
    if (widget.startDrawing) {
      // El yazısı modu: ilk kareden sonra doğrudan çizim tuvalini aç.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addDrawing();
      });
    }
    _sub = ref.listenManual(noteStreamProvider(widget.noteId), (
      previous,
      next,
    ) {
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
    }, fireImmediately: true);
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
    _speechSub?.cancel();
    _debouncer.dispose();
    _sub?.close();
    _titleController.dispose();
    _bodyController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  /// Dashboard akışında zaten yüklü olan notu senkron döndürür (varsa).
  /// İlk kareyi dolu kurup açılış kasmasını önlemek için kullanılır.
  Note? _cachedNote() {
    final notes = ref.read(notesStreamProvider).value;
    if (notes == null) return null;
    for (final n in notes) {
      if (n.id == widget.noteId) return n;
    }
    return null;
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

  /// "Dosya çok büyük" mesajı — sınır premium'a göre (50 MB) / ücretsiz (10 MB).
  String _tooLargeMessage() {
    final premium = ref.read(premiumProvider).value ?? false;
    final limitMb =
        (premium
            ? AppConstants.maxPremiumAttachmentBytes
            : AppConstants.maxFreeAttachmentBytes) ~/
        (1024 * 1024);
    return context.l10n.attachmentTooLarge(limitMb);
  }

  Future<void> _addImageBytes(Uint8List bytes, String fileName) async {
    final tooLargeMessage = _tooLargeMessage();
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
    } catch (e) {
      // Yalnız FileTooLargeException yakalanıyordu; başka her hata (web'de
      // dosya sistemi yok, disk dolu, izin reddi) yukarı kaçıp await'i
      // tamamlanmadan bırakıyordu → ekran donmuş görünüyor, mesaj çıkmıyordu.
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
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
    // PDF sıkıştırılamaz (görsel ve ses küçültülüyor, bu küçültülemiyor) —
    // büyük dosya Firebase Storage kotasına doğrudan gider. Engellemek yerine
    // boyutu söyleyip kullanıcıya soruyoruz.
    if (bytes.length > AppConstants.largeAttachmentWarnBytes && mounted) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.largeAttachmentTitle),
          content: Text(context.l10n.largeAttachmentBody(mb)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    if (!mounted) return;
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
      if (mounted) _showSnack(_tooLargeMessage());
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
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
      if (mounted) _showSnack(_tooLargeMessage());
    } catch (e) {
      if (mounted) _showSnack(context.l10n.attachmentFailed('$e'));
    }
  }

  Future<void> _addDrawing() async {
    final bytes = await Navigator.of(
      context,
    ).push<Uint8List>(MaterialPageRoute(builder: (_) => const DrawingScreen()));
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

  /// Bir eki (görsel) yeni değerleriyle (genişlik/hiza) değiştirir — kullanıcı
  /// görseli notta elle boyutlandırıp hizalayınca çağrılır.
  void _updateAttachment(Attachment updated) {
    _mutate(
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == updated.id) updated else a,
        ],
      ),
      immediate: true,
    );
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
            // Tarayıcıda gizli: `record` web'de dosya yolu değil blob adresi
            // döndürüyor, ek akışı ise yol bekliyor (bkz. prepareAudio).
            if (!kIsWeb)
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
    final reminder = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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

  /// Editör kapanırken başlıksız kalan nota arka planda AI başlık yazar
  /// (Ayarlar > Yapay Zeka > "Kapatırken başlık öner", varsayılan açık).
  /// "Başlık öner" çipiyle aynı üreticiyi kullanır; akışı kesmez.
  void _autoTitleInBackground(Note note) {
    if (note.isEmpty || !ref.read(autoTitleProvider)) return;
    final service = ref.read(geminiServiceProvider);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    Future(() async {
      try {
        final title = await service.generateTitle(note);
        if (title.isNotEmpty) repo.updateFields(note.id, {'title': title});
      } catch (_) {
        // Kota/anahtar hatasında sessizce geç — başlıksız kalması sorun değil.
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
          ),
        ),
      );
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
          ),
        ),
      );
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

  String _cleanTag(String raw) =>
      raw.trim().replaceAll('#', '').replaceAll(' ', '-').toLowerCase();

  void _applyTag(String cleaned) {
    if (cleaned.isEmpty) return;
    _mutate(
      (n) => n.copyWith(tags: {...n.tags, cleaned}.toList()),
      immediate: true,
    );
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    // Daha önce kullanılmış, bu notta OLMAYAN etiketler diyalogda çip olarak
    // sunulur — kullanıcı yeniden yazmak yerine dokunup ekler.
    final note = _note;
    final existing = [
      for (final t in ref.read(allTagsProvider))
        if (note == null || !note.tags.contains(t)) t,
    ];
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addTag),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.tagHint),
              onSubmitted: (value) => Navigator.pop(dialogContext, value),
            ),
            if (existing.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.existingTagsLabel,
                style: Theme.of(dialogContext).textTheme.labelMedium?.copyWith(
                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              // Çok etiket varsa diyalog taşmasın: sınırlı yükseklikte kaydırılır.
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final t in existing)
                        ActionChip(
                          label: Text('#$t'),
                          onPressed: () {
                            // Çipe dokununca doğrudan eklenir (metin kutusuna
                            // yazmaya gerek yok), diyalog kapanır.
                            Navigator.pop(dialogContext);
                            _applyTag(t);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
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
    if (tag != null) _applyTag(_cleanTag(tag));
  }

  void _removeTag(String tag) => _mutate(
    (n) => n.copyWith(
      tags: [
        for (final t in n.tags)
          if (t != tag) t,
      ],
    ),
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

  /// Notu cihazın TTS'iyle sesli okur (model çağrısı yok). Kilitli notta
  /// ayrıca doğrulama yok — editör zaten açılırken doğruluyor.
  Future<void> _listen() async {
    final note = _note;
    if (note == null) return;
    final title = note.title.trim();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListenScreen(
          title: title.isEmpty ? context.l10n.appName : title,
          // toPlainText değil: başlık ve `- [x]` işaretleri okunmasın.
          loadText: () async => note.toContentText(),
        ),
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
  void _replaceText(String raw, {NoteType? asType, bool keepChecked = false}) {
    final note = _note;
    // Model istenmese de ** / * / # üretebiliyor; not düz metin tuttuğundan
    // temizle.
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    // Değişiklik öncesi anlık görüntü: "Geri al" bununla eski hâle döner.
    final before = note;
    final targetType = asType ?? note.type;
    // İşaretli maddeler AI'a hiç gönderilmemişti (ayar açık): sonuç yalnız
    // işaretsizlerin yerine geçer, işaretli (tamamlanmış) maddeler metni ve
    // işaretiyle AYNEN korunur — sonlarına eklenir (uygulamanın "işaretliler
    // altta" düzeni). Kullanıcının "işaretlilere karışma" isteği.
    if (keepChecked && targetType == NoteType.checklist) {
      const uuid = Uuid();
      final newUnchecked = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty)
            NoteItem(id: uuid.v4(), text: _parseListLine(line).text),
      ];
      final preservedChecked = [
        for (final item in note.items)
          if (item.checked) item,
      ];
      _mutate(
        (n) => n.copyWith(items: [...newUnchecked, ...preservedChecked]),
        immediate: true,
      );
      _offerReplaceUndo(before);
      return;
    }
    if (targetType == NoteType.text) {
      _bodyController.text = text.trim();
      _mutate(
        (n) => n.copyWith(type: targetType, body: text.trim()),
        immediate: true,
      );
    } else {
      const uuid = Uuid();
      final parsed = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line),
      ];
      // Tip korunuyor ve öğe sayısı birebir aynıysa (düzeltme sırayı bozmaz)
      // mevcut kimlikler ve işaretli/işaretsiz durum korunur — kullanıcının
      // işaretlediği maddeler düzeltme sonrası işaretli kalır.
      final keepState =
          targetType == note.type && parsed.length == note.items.length;
      // Sayı/sıra değişse de (kısaltma, yeniden sıralama) işaret durumu
      // kaybolmasın: eski öğelerin normalize metni → işaret eşlemesi kurulur,
      // yeni satır eskisiyle (yazım düzeltilmiş de olsa birebir eşleşen)
      // bulunursa işareti devralır.
      String norm(String s) => s.trim().toLowerCase();
      final oldChecked = {
        for (final item in note.items) norm(item.text): item.checked,
      };
      _mutate(
        (n) => n.copyWith(
          type: targetType,
          // Tip değişiyorsa eski gövde temizlenir; içerik artık öğelerde.
          body: targetType == note.type ? null : '',
          items: [
            for (var i = 0; i < parsed.length; i++)
              NoteItem(
                id: keepState ? n.items[i].id : uuid.v4(),
                text: parsed[i].text,
                // Sıralı listede işaret anlamsız; checklist'te korunur/okunur.
                checked: targetType != NoteType.checklist
                    ? false
                    : keepState
                    ? n.items[i].checked
                    : (oldChecked[norm(parsed[i].text)] ?? parsed[i].checked),
              ),
          ],
        ),
        immediate: true,
      );
      if (targetType != note.type) _bodyController.clear();
    }
    _offerReplaceUndo(before);
  }

  /// "Notu değiştir" sonrası geri alma: eski not anlık görüntüsüne (metin,
  /// öğeler, tip, başlık) tek dokunuşla döner.
  void _offerReplaceUndo(Note before) {
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: context.l10n.noteUpdatedUndo,
      undoLabel: context.l10n.undo,
      onUndo: () {
        _titleController.text = before.title;
        _bodyController.text = before.body;
        setState(() => _note = before);
        ref.read(notesRepositoryProvider)?.updateNote(before);
      },
    );
  }

  /// AI çıktısını ORİJİNAL notu değiştirmeden YENİ bir notta açar (madde 1-2).
  /// Böylece kullanıcıda hem "değiştirmeden" orijinal hem de "düzeltilmiş"
  /// sürüm ayrı notlar olarak kalır. Başlık ve klasör yeni nota taşınır;
  /// [asType] verilirse (liste dönüşümü) yeni not o tipte oluşturulur.
  Future<void> _createNoteFromText(
    String raw, {
    NoteType? asType,
    bool keepChecked = false,
  }) async {
    final note = _note;
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final type = asType ?? note.type;
    final id = await repo.createNote(type);
    final fields = <String, dynamic>{};
    if (note.title.trim().isNotEmpty) fields['title'] = note.title;
    if (note.folderId != null) fields['folderId'] = note.folderId;
    if (type == NoteType.text) {
      fields['body'] = text.trim();
    } else {
      const uuid = Uuid();
      final items = <NoteItem>[];
      for (final line in text.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parsed = _parseListLine(line);
        items.add(
          NoteItem(
            id: uuid.v4(),
            text: parsed.text,
            checked: type == NoteType.checklist ? parsed.checked : false,
          ),
        );
      }
      // İşaretliler kapsam dışıydı: korunan (tamamlanmış) maddeler yeni notta
      // da işaretli olarak sona eklenir (işaretsiz düzeltilmişlerin ardına).
      if (keepChecked && type == NoteType.checklist) {
        for (final item in note.items) {
          if (item.checked) {
            items.add(NoteItem(id: uuid.v4(), text: item.text, checked: true));
          }
        }
      }
      fields['items'] = [for (final it in items) it.toMap()];
      // createNote liste tipini bir boş öğeyle tohumlar; gövde artık öğelerde.
      fields['body'] = '';
    }
    repo.updateFields(id, fields);
    if (mounted) context.push('/note/$id');
  }

  /// AI çıktısını (OCR/döküm) notun gövdesine ya da liste öğelerine ekler.
  void _appendText(String raw) {
    final note = _note;
    final text = stripMarkdown(raw);
    if (note == null || text.trim().isEmpty) return;
    if (note.type == NoteType.text) {
      final combined = note.body.trim().isEmpty
          ? text.trim()
          : '${note.body}\n\n${text.trim()}';
      _bodyController.text = combined;
      _mutate((n) => n.copyWith(body: combined), immediate: true);
    } else {
      const uuid = Uuid();
      final lines = [
        for (final line in text.split('\n'))
          if (line.trim().isNotEmpty) _parseListLine(line).text,
      ];
      _mutate((n) {
        // Listede sonda hep boş bir "yeni öğe" satırı bekler. Yeni maddeler
        // onun ARKASINA eklenince o boş satır ortada kalıyordu; eklemeden
        // önce sondaki boşlar atılır. Dikte ve AI ekleme aynı yoldan
        // geçtiğinden ikisi de düzelir.
        final kept = [...n.items];
        while (kept.isNotEmpty && kept.last.text.trim().isEmpty) {
          kept.removeLast();
        }
        return n.copyWith(
          items: [
            ...kept,
            for (final line in lines) NoteItem(id: uuid.v4(), text: line),
          ],
        );
      }, immediate: true);
    }
  }

  /// Resmin araç çubuğundaki "Metni al" düğmesi: görseldeki metni çıkarır
  /// (OCR) ve nota ekler (madde 3). AI sayfasına girmeden doğrudan resimden
  /// erişilir; sonuç [_appendText] ile gövdeye/öğelere eklenir.
  Future<void> _ocrImage(Attachment image) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    final bytes = await repo.readBytes(image);
    if (!mounted) return;
    if (bytes == null) {
      _showSnack(l10n.attachmentNotSynced);
      return;
    }
    _showSnack(l10n.aiThinking);
    try {
      final service = ref.read(geminiServiceProvider);
      final text = stripMarkdown(
        await service.extractTextFromImage(bytes, image.mimeType),
      ).trim();
      if (!mounted || text.isEmpty) return;
      _appendText(text);
    } on GeminiException catch (e) {
      if (mounted) {
        _showSnack(e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message));
      }
    } catch (e) {
      if (mounted) _showSnack(l10n.aiError('$e'));
    }
  }

  /// Palet düğmesi: zemin rengi ve renkli çerçeve seçimi. İkisi ayrı alanlar —
  /// renkli zeminli bir nota farklı renkte çerçeve verilebilir (madde 4).
  Future<void> _showColorSheet() async {
    final note = _note;
    if (note == null) return;
    _dismissKeyboard();
    final l10n = context.l10n;
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _colorLeading(note.color, frame: false),
              title: Text(l10n.backgroundColor),
              onTap: () => Navigator.pop(sheetContext, 'bg'),
            ),
            ListTile(
              leading: _colorLeading(note.frameColor, frame: true),
              title: Text(l10n.frameColor),
              onTap: () => Navigator.pop(sheetContext, 'frame'),
            ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    final frame = target == 'frame';
    final picked = await showNoteColorPicker(
      context,
      frame: frame,
      current: frame ? note.frameColor : note.color,
    );
    if (picked == null || !mounted) return;
    _mutate(
      (n) => frame ? n.copyWith(frameColor: picked) : n.copyWith(color: picked),
      immediate: true,
    );
  }

  Widget _colorLeading(NoteColor color, {required bool frame}) {
    final swatch = NoteColors.swatch(color);
    return Container(
      width: 28,
      height: 28,
      decoration: frame && color != NoteColor.none
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: swatch, width: 4),
            )
          : BoxDecoration(color: swatch, shape: BoxShape.circle),
      child: color == NoteColor.none
          ? const Icon(Icons.format_color_reset_outlined, size: 16)
          : null,
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
    _mutate((n) => n.copyWith(body: '', items: const []), immediate: true);
  }

  /// Sesli yazdırma. Cihazın yerleşik tanıması varsa düğme DOĞRUDAN dikteyi
  /// başlatır (alt sayfa açılmaz): konuşma anında nota akar, düğmeye tekrar
  /// basınca durur. Yerleşik tanıma yoksa (Windows) eski alt sayfa açılır.
  Future<void> _dictate() async {
    final note = _note;
    if (note == null) return;
    if (_dictating) {
      await _stopInlineDictation();
      return;
    }
    if (await DeviceSpeech.isAvailable()) {
      await _startInlineDictation(note);
      return;
    }
    // Yerleşik tanıma yok: eski alt sayfa yolu.
    if (!mounted) return;
    if (note.type == NoteType.text) {
      final base = _bodyController.text;
      final baseWithSep = base.trim().isEmpty ? '' : '${base.trimRight()}\n';
      void writeLive(String full) => _writeDictated(baseWithSep, full);
      final text = await showDictationSheet(context, onPartial: writeLive);
      if (text != null && text.trim().isNotEmpty) writeLive(text.trim());
      return;
    }
    final text = await showDictationSheet(context);
    if (text == null || text.trim().isEmpty) return;
    _appendText(text);
  }

  /// Dikte metnini gövdeye yazar: taban (mevcut gövde + ayraç) sabit kalır,
  /// üstüne o ana kadarki tam döküm gelir.
  void _writeDictated(String base, String full) {
    // Dikte parçaları artık satır sonuyla ayrılıyor (liste notunda her
    // duraklama ayrı madde olsun diye). Metin notunda paragraf bölünmesin:
    // ayraçlar boşluğa çevrilir. Taban metnin kendi satırları korunur.
    final combined = base + full.replaceAll('\n', ' ');
    _bodyController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
    );
    _mutate((n) => n.copyWith(body: combined), immediate: true);
  }

  Future<void> _startInlineDictation(Note note) async {
    final base = _bodyController.text;
    final baseWithSep = base.trim().isEmpty ? '' : '${base.trimRight()}\n';
    _dictationItemIds.clear();
    setState(() => _dictating = true);
    _speechSub = DeviceSpeech.listen().listen(
      (event) {
        final text = event.text;
        if (text == null) return;
        // Metin notunda anlık gövdeye; liste tiplerinde her duraklama
        // (satır sonu) anında ayrı madde olarak eklenir — eskiden döküm
        // yalnız "Bitir"de tek öğe olarak düşüyordu.
        if (note.type == NoteType.text) {
          _writeDictated(baseWithSep, text);
        } else {
          _syncDictatedItems(text);
        }
      },
      onError: (Object e) {
        _stopInlineDictation();
        if (mounted) _showSnack(context.l10n.aiError(e.toString()));
      },
    );
  }

  /// Bu dikte oturumunun eklediği öğelerin kimlikleri: her olayda dökümün
  /// tamamı yeniden gelir; önceki dikte öğeleri yenileriyle değiştirilir,
  /// kullanıcının elle yazdığı öğelere dokunulmaz.
  final List<String> _dictationItemIds = [];

  void _syncDictatedItems(String full) {
    const uuid = Uuid();
    final lines = [
      for (final line in full.split('\n'))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    _mutate((n) {
      // Sondaki boş "yeni öğe" satırları ve önceki dikte öğeleri çıkarılır.
      final kept = [
        for (final item in n.items)
          if (!_dictationItemIds.contains(item.id)) item,
      ];
      while (kept.isNotEmpty && kept.last.text.trim().isEmpty) {
        kept.removeLast();
      }
      _dictationItemIds
        ..clear()
        ..addAll([for (final _ in lines) uuid.v4()]);
      return n.copyWith(
        items: [
          ...kept,
          for (var i = 0; i < lines.length; i++)
            NoteItem(id: _dictationItemIds[i], text: lines[i]),
        ],
      );
    }, immediate: true);
  }

  Future<void> _stopInlineDictation() async {
    await DeviceSpeech.stop();
    // Son sonucun gelmesi için kısa bekleme (tanıyıcı stop sonrası yazar).
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _speechSub?.cancel();
    _speechSub = null;
    if (!mounted) return;
    setState(() => _dictating = false);
    // Liste tiplerinde öğeler dikte sırasında anlık eklendi (_syncDictatedItems);
    // burada yalnız oturum durumu temizlenir — sonraki dikte bu öğeleri
    // "kendi öğesi" sanıp değiştirmesin.
    _dictationItemIds.clear();
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
          items: [
            ...n.items,
            NoteItem(id: uuid.v4(), text: result),
          ],
        ),
        immediate: true,
      );
    }
  }

  /// Metin notuna boş bir checklist maddesi ekler (karışık içerik). İlk madde
  /// eklenince gövde otomatik ItemsEditor'a geçer; sonrakiler onun "Yeni öğe"
  /// düğmesinden eklenir. Tüm maddeler silinince gövde saf metne döner.
  void _addChecklistItem() {
    const uuid = Uuid();
    _mutate(
      (n) => n.copyWith(
        items: [
          ...n.items,
          NoteItem(id: uuid.v4(), text: ''),
        ],
      ),
      immediate: true,
    );
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
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
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
          label: Text(DateFormat('d MMM HH:mm', 'tr').format(note.reminderAt!)),
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
        InputChip(label: Text('#$tag'), onDeleted: () => _removeTag(tag)),
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
        // Görsel olmayan ekler (PDF/ses) yatay şeritte kalır; görseller ise
        // serbest tuvalde (dokun → seç → sürükle/boyutlandır) istenen yere
        // konumlandırılabilir (madde 5).
        AttachmentStrip(
          attachments: [
            for (final a in note.attachments)
              if (a.kind != AttachmentKind.image) a,
          ],
          onRemove: _removeAttachment,
        ),
        NoteImages(
          images: [
            for (final a in note.attachments)
              if (a.kind == AttachmentKind.image) a,
          ],
          onRemove: _removeAttachment,
          onChanged: _updateAttachment,
          onExtractText: _ocrImage,
        ),
      ],
    );

    // Gövde metin alanı: saf metin modunda ve karışık (metin+madde) modda
    // aynı controller/focus'u paylaşır. Madde varken kısalır (2 satır tabanı).
    final bodyField = TextField(
      controller: _bodyController,
      focusNode: _bodyFocus,
      onChanged: (value) => _mutate((n) => n.copyWith(body: value)),
      maxLines: null,
      minLines: note.items.isEmpty ? 8 : 2,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        hintText: l10n.bodyHint,
        filled: false,
        border: InputBorder.none,
      ),
    );

    final Widget body;
    if (note.type == NoteType.text && note.items.isEmpty) {
      // Saf metin: gövde alanı en az bir ekran boyu yüksekliğe zorlanır ve tüm
      // bu alan (metnin altındaki boşluk dahil) dokunuşla gövdeye odaklanır —
      // yazmaya başlamak için aşağıya doğru her yere dokunmak yeterli.
      body = LayoutBuilder(
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
                    children: [bodyField],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (note.type == NoteType.text) {
      // Karışık içerik: serbest metin + checklist maddeleri. Gövde metni, madde
      // editörünün (ItemsEditor) header'ında durur; tüm ekle/işaretle/sırala/
      // sil mantığı olduğu gibi yeniden kullanılır. Madde kalmayınca (hepsi
      // silinince) note.items boşalır ve editör kendiliğinden saf metne döner.
      body = ItemsEditor(
        key: ValueKey('mixed-${note.id}'),
        items: note.items,
        showCheckboxes: true,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: bodyField,
            ),
          ],
        ),
      );
    } else {
      body = ItemsEditor(
        key: ValueKey('items-${note.id}'),
        items: note.items,
        showCheckboxes: note.type == NoteType.checklist,
        expandItems: ref.watch(expandListItemsProvider),
        onChanged: (items) => _mutate((n) => n.copyWith(items: items)),
        header: header,
      );
    }

    return CallbackShortcuts(
      bindings: {
        if (_isDesktop)
          const SingleActivator(
            LogicalKeyboardKey.keyV,
            control: true,
            shift: true,
          ): _pasteImage,
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
                  pending
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_done_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant
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
              onPressed: () => _mutate(
                (n) => n.copyWith(pinned: !n.pinned),
                immediate: true,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                switch (action) {
                  case 'share':
                    _share();
                  case 'pdf':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PdfExportScreen(note: note),
                      ),
                    );
                  case 'listen':
                    _listen();
                  case 'lock':
                    _toggleLock();
                  case 'archive':
                    _toggleArchive();
                  case 'clear':
                    _clearContent();
                  case 'settings':
                    context.push('/settings');
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
                  value: 'pdf',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(l10n.exportPdf),
                  ),
                ),
                PopupMenuItem(
                  value: 'listen',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.headphones_outlined),
                    title: Text(l10n.listenToNote),
                  ),
                ),
                PopupMenuItem(
                  value: 'lock',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      note.locked
                          ? Icons.lock_open_outlined
                          : Icons.lock_outline,
                    ),
                    title: Text(note.locked ? l10n.unlockNote : l10n.lockNote),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      note.archivedAt != null
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    title: Text(
                      note.archivedAt != null ? l10n.unarchive : l10n.archive,
                    ),
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
                  value: 'settings',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.settings_outlined),
                    title: Text(l10n.settings),
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
        // Renkli çerçeve: seçiliyse editör içeriğini saran ince renkli kenarlık.
        body: SafeArea(
          child: note.frameColor == NoteColor.none
              ? body
              : Container(
                  margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NoteColors.swatch(note.frameColor),
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: body,
                  ),
                ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dikte açıkken kaçırılamayacak bir şerit: tek başına kırmızı
            // ikon yeterince belirgin değildi, mikrofon farkına varılmadan
            // açık kalabiliyordu.
            if (_dictating) _DictationBanner(onStop: _dictate),
            BottomAppBar(
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
                  // Karışık içerik: metin notunun altına checklist maddesi
                  // ekler. Yalnızca metin notunda anlamlı (liste notu zaten
                  // maddeden oluşur).
                  if (note.type == NoteType.text)
                    IconButton(
                      tooltip: l10n.newItemHint,
                      icon: const Icon(Icons.checklist),
                      onPressed: _addChecklistItem,
                    ),
                  const Spacer(),
                  // Mikrofon başparmak bölgesinde, AI'ın yanında ve dolgulu:
                  // yardımcı ikonların arasında kaybolmaz. Ses kaydı eki artık
                  // ataş menüsünde; bu düğme konuşmayı anlık yazıya döker.
                  // Dikte düğmesi: doğrudan başlatır/durdurur, büyük ve dolgulu.
                  // Dinlerken renk değişir ki kaydın sürdüğü açıkça görülsün.
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: _dictating
                        ? IconButton.filled(
                            tooltip: l10n.stopAndSave,
                            iconSize: 28,
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                            ),
                            icon: const Icon(Icons.stop),
                            onPressed: _dictate,
                          )
                        : IconButton.filledTonal(
                            tooltip: l10n.liveDictation,
                            iconSize: 28,
                            icon: const Icon(Icons.mic_none),
                            onPressed: _dictate,
                          ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonalIcon(
                    onPressed: () => showAiSheet(
                      context,
                      note,
                      onAppendText: _appendText,
                      onReplaceText: _replaceText,
                      onCreateNote: _createNoteFromText,
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l10n.aiTitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dikte sürerken alt çubuğun üstünde duran uyarı şeridi. Amacı tek:
/// mikrofonun açık olduğu gözden kaçmasın.
class _DictationBanner extends StatelessWidget {
  const _DictationBanner({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: InkWell(
        onTap: onStop,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.mic, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.dictationListening,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                context.l10n.stopAndSave,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
