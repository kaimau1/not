import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/utils/local_file.dart';
import '../../ai/data/gemini_service.dart';
import '../data/attachment_repository.dart';
import '../data/notes_repository.dart';
import '../data/scan/scan_ocr.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import 'editor/note_images.dart';
import 'viewers/pdf_viewer_screen.dart';

/// **Arşiv defteri** ekranı — kendi sayfaları olan, içine dosya KOPYASI alan
/// uzun soluklu not (bkz. [NoteType.archive]).
///
/// Kullanıcı isteği 2026-08-16: "arşiv özelliği önemli notları belgeleri
/// toplayan bir klasör, resimli notlar videolar ayrı bir klasör açar ve oraya
/// kopya oluşturur, arama çok hızlı ve kolaydır."
///
/// Neden ayrı bir ekran (not editörünün içinde bir kip değil): editör tek bir
/// "sayfa" üstünde çalışıyor — gövde metni, üstünde yüzen görseller, altında
/// ek şeridi. Arşivin içeriği ise sayfalara BÖLÜNMÜŞ bir dizin ve asıl işlemi
/// aramak/gezinmek, yazmak değil. İkisini tek ekrana sığdırmak her iki tarafın
/// da yerleşimini bozardı.
///
/// Sayfalar iki türlü:
///  * **Otomatik** — Görseller, Videolar, Belgeler, Metinler. Her defterde
///    vardır, girdinin türüne göre kendiliğinden dolar. Adları dilden geldiği
///    için kayda YAZILMAZ (uygulamanın dili değişince adlar da değişsin).
///  * **Özel** — kullanıcının açtığı sayfalar; adları `Note.archivePages`te
///    durur, girdiler `Attachment.section` / `NoteItem.section` ile bağlanır.
///
/// Dosyalar KOPYALANIR (kullanıcının açık tercihi): kaynak not silinse bile
/// arşivdeki kopya sağlam kalır. Bedeli, dosyanın depoda iki kez yer
/// kaplaması — bkz. [copyAttachmentsToArchive].
class ArchiveNoteScreen extends ConsumerStatefulWidget {
  const ArchiveNoteScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<ArchiveNoteScreen> createState() => _ArchiveNoteScreenState();
}

/// Otomatik sayfalar. Sıra ekranda göründüğü sıradır.
enum _AutoPage { images, videos, documents, texts }

class _ArchiveNoteScreenState extends ConsumerState<ArchiveNoteScreen> {
  final _searchController = TextEditingController();

  /// Seçili sayfa: otomatik sayfalardan biri ya da özel bir sayfanın adı.
  _AutoPage? _autoPage = _AutoPage.images;
  String? _customPage;

  bool _busy = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  NotesRepository? get _repo => ref.read(notesRepositoryProvider);

  /// Ekin ait olduğu otomatik sayfa (özel sayfaya konmamışsa).
  static _AutoPage _autoPageOf(Attachment a) => switch (a.kind) {
    AttachmentKind.image => _AutoPage.images,
    AttachmentKind.video => _AutoPage.videos,
    _ => _AutoPage.documents,
  };

  String _autoLabel(_AutoPage page) => switch (page) {
    _AutoPage.images => context.l10n.archivePageImages,
    _AutoPage.videos => context.l10n.archivePageVideos,
    _AutoPage.documents => context.l10n.archivePageDocuments,
    _AutoPage.texts => context.l10n.archivePageTexts,
  };

  /// Seçili sayfadaki EKLER (arama uygulanmış).
  List<Attachment> _attachmentsOf(Note note) {
    final query = _query;
    return [
      for (final a in note.attachments)
        if (_matchesPage(a) && (query.isEmpty || _matches(a.fileName, query)))
          a,
    ];
  }

  bool _matchesPage(Attachment a) {
    // Arama YAZILIYKEN sayfa süzgeci kalkar: kullanıcı defterin tamamında
    // arıyor, hangi sayfada olduğunu bilseydi zaten oraya giderdi
    // ("arama çok hızlı ve kolaydır").
    if (_query.isNotEmpty) return true;
    if (_customPage != null) return a.section == _customPage;
    return a.section.isEmpty && _autoPageOf(a) == _autoPage;
  }

  /// Seçili sayfadaki METİN girdileri (arama uygulanmış).
  List<NoteItem> _itemsOf(Note note) {
    final query = _query;
    return [
      for (final item in note.items)
        if ((query.isNotEmpty ||
                (_customPage != null
                    ? item.section == _customPage
                    : item.section.isEmpty && _autoPage == _AutoPage.texts)) &&
            (query.isEmpty || _matches(item.text, query)))
          item,
    ];
  }

  static bool _matches(String text, String query) =>
      text.toLowerCase().contains(query);

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _mutate(Note note, Note Function(Note) change) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.updateNote(change(note));
  }

  /// Yeni ÖZEL sayfa açar.
  Future<void> _addPage(Note note) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.archiveNewPage),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.archivePageName),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    // Otomatik sayfaların adıyla çakışan özel sayfa açılamaz: iki sekme aynı
    // adı taşısaydı hangisinin hangisi olduğu anlaşılmazdı.
    if (trimmed.isEmpty ||
        note.archivePages.contains(trimmed) ||
        _AutoPage.values.any((page) => _autoLabel(page) == trimmed)) {
      return;
    }
    await _mutate(note, (n) => n.copyWith(archivePages: [...n.archivePages, trimmed]));
    if (!mounted) return;
    setState(() {
      _autoPage = null;
      _customPage = trimmed;
    });
  }

  /// Metin girdisi ekler/düzenler (seçili sayfaya).
  ///
  /// [existing] verilirse o girdi düzenlenir. Girdinin BAŞLIĞI ve bağlı
  /// olduğu DOSYA da buradan ayarlanır (kullanıcı isteği 2026-08-16:
  /// "metinler görsel veya belge ile bağlanabilmesi… hepsinin başlığı
  /// ayarlanabilmeli"): bir alıntının hangi belgeden geldiği, bir notun
  /// hangi fotoğrafa ait olduğu defterde kaybolmasın.
  Future<void> _editText(Note note, {NoteItem? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final textController = TextEditingController(text: existing?.text ?? '');
    var linkedId = existing?.attachmentId ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.archiveAddText),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.archiveEntryTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: textController,
                    autofocus: existing == null,
                    maxLines: 8,
                    minLines: 3,
                    decoration: InputDecoration(
                      labelText: l10n.archiveCaptureText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // BAĞLI DOSYA: defterdeki eklerden biri seçilir. Yeni dosya
                  // yüklemek ayrı bir iş (alttaki "Dosya ekle"); burada
                  // yalnız VAR OLANA bağlanır, yoksa aynı dosya iki kez
                  // yüklenirdi.
                  DropdownButtonFormField<String>(
                    initialValue: linkedId.isEmpty ? '' : linkedId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.archiveLinkedFile,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(l10n.archiveNoLink),
                      ),
                      for (final a in note.attachments)
                        DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            a.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => linkedId = value ?? ''),
                  ),
                ],
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
        );
      },
    );
    final title = titleController.text.trim();
    final text = textController.text.trim();
    titleController.dispose();
    textController.dispose();
    if (saved != true || text.isEmpty) return;

    await _mutate(note, (n) {
      if (existing != null) {
        return n.copyWith(
          items: [
            for (final i in n.items)
              if (i.id == existing.id)
                i.copyWith(text: text, title: title, attachmentId: linkedId)
              else
                i,
          ],
        );
      }
      return n.copyWith(
        items: [
          ...n.items,
          NoteItem(
            id: const Uuid().v4(),
            text: text,
            title: title,
            attachmentId: linkedId,
            section: _customPage ?? '',
          ),
        ],
      );
    });
  }

  /// Ekin defterdeki ADINI değiştirir (dosya adı = girdinin başlığı).
  Future<void> _renameAttachment(Note note, Attachment attachment) async {
    final controller = TextEditingController(text: attachment.fileName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.archiveEntryTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.ok),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (saved != true || name.isEmpty || name == attachment.fileName) return;
    // YALNIZ görünen ad değişir; dosyanın kendisi (yerel yol, depo yolu)
    // olduğu gibi kalır — yeniden adlandırma yükleme kuyruğunu tetiklemesin.
    await _mutate(
      note,
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == attachment.id) a.copyWith(fileName: name) else a,
        ],
      ),
    );
  }

  /// **Görselden yakala**: ekran görüntüsünü OCR'lar, metni yapay zekâya
  /// düzelttirir, türünü tahmin ettirir ve deftere kaydeder.
  ///
  /// Kullanıcı isteği 2026-08-16: "SS'le kaydedilen not defteri OCR ile
  /// çıkarır ai ile olur ve kaydeder — hadis defteri, film arşivi vs."
  ///
  /// Akış bilerek bu sırada:
  ///  1. **OCR cihazda** ([ScanOcr]) — bedava, çevrimdışı, kotasız.
  ///  2. Metin çıkmadıysa DURULUR: modele boş metin göndermek kotayı boşa
  ///     yakar (görselde yazı yoksa yapılacak bir şey yok).
  ///  3. Model metni düzeltir ve türü söyler ([GeminiService.tidyCapture]);
  ///     tür, defterin var olan sayfalarından biriyse oraya, değilse yeni
  ///     bir sayfa olarak açılır.
  ///  4. Sonuç ONAYA sunulur — model metni değiştirebiliyor ve sayfa açmak
  ///     kalıcı bir karar; sessizce kaydetmek yanlış yere düşen girdilerle
  ///     defteri kirletirdi.
  ///
  /// Görselin kendisi de deftere KOPYALANIR: metin yanlış çıkarsa kaynağa
  /// bakmanın tek yolu odur.
  Future<void> _captureFromImage(Note note) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (!ScanOcr.supported) {
      _snack(context.l10n.imageOcrNone);
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final lines = await ScanOcr.recognizeImageLines(picked.path);
      final raw = [for (final line in lines) line.text].join('\n').trim();
      if (raw.isEmpty) {
        if (!mounted) return;
        setState(() => _busy = false);
        _snack(context.l10n.imageOcrNone);
        return;
      }
      final tidied = await ref
          .read(geminiServiceProvider)
          .tidyCapture(raw, known: note.archivePages);
      if (!mounted) return;
      setState(() => _busy = false);
      await _confirmCapture(
        note,
        suggestion: tidied,
        imageBytes: await picked.readAsBytes(),
        imageName: picked.name,
      );
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack(context.l10n.aiError('$e'));
    }
  }

  /// Yakalanan metni ve önerilen sayfayı onaya sunar, onaylanırsa kaydeder.
  Future<void> _confirmCapture(
    Note note, {
    required ({String category, String title, String text}) suggestion,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final textController = TextEditingController(text: suggestion.text);
    final pageController = TextEditingController(
      text: suggestion.category.isEmpty
          ? (_customPage ?? '')
          : suggestion.category,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return AlertDialog(
          title: Text(l10n.archiveCaptureTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: pageController,
                  decoration: InputDecoration(
                    labelText: l10n.archiveCapturePage,
                    helperText: l10n.archiveCapturePageInfo,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 10,
                  minLines: 4,
                  decoration: InputDecoration(labelText: l10n.archiveCaptureText),
                ),
              ],
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
        );
      },
    );
    final text = textController.text.trim();
    final page = pageController.text.trim();
    textController.dispose();
    pageController.dispose();
    if (confirmed != true || text.isEmpty || !mounted) return;

    setState(() => _busy = true);
    Attachment? stored;
    try {
      stored = await ref
          .read(attachmentRepositoryProvider)
          ?.prepareImage(
            noteId: note.id,
            bytes: imageBytes,
            fileName: imageName,
          );
    } catch (_) {
      // Görsel eklenemese de (çok büyük, depo dolu) METİN kaydedilsin:
      // yakalamanın asıl değeri yazıda.
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _mutate(note, (n) {
      // Model yeni bir sayfa adı önerdiyse sayfa da açılır; var olansa
      // ikinci kez eklenmez.
      final pages = page.isEmpty || n.archivePages.contains(page)
          ? n.archivePages
          : [...n.archivePages, page];
      return n.copyWith(
        archivePages: pages,
        items: [
          ...n.items,
          NoteItem(id: const Uuid().v4(), text: text, section: page),
        ],
        attachments: stored == null
            ? n.attachments
            : [
                ...n.attachments,
                stored.copyWith(asFile: true, section: page),
              ],
      );
    });
    if (!mounted) return;
    setState(() {
      _autoPage = page.isEmpty ? _AutoPage.texts : null;
      _customPage = page.isEmpty ? null : page;
    });
  }

  /// Galeriden/diskten dosya seçip deftere KOPYALAR.
  Future<void> _addFiles(Note note) async {
    if (kIsWeb) return;
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;
    final files = <({String name, Uint8List bytes})>[];
    if (Platform.isAndroid || Platform.isIOS) {
      final picked = await ImagePicker().pickMultiImage(
        maxWidth: 2400,
        maxHeight: 2400,
      );
      for (final file in picked) {
        files.add((name: file.name, bytes: await file.readAsBytes()));
      }
    } else {
      const group = XTypeGroup(
        label: 'Belge / görsel',
        extensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      for (final file in await openFiles(acceptedTypeGroups: const [group])) {
        files.add((name: file.name, bytes: await file.readAsBytes()));
      }
    }
    if (files.isEmpty || !mounted) return;
    setState(() => _busy = true);
    final added = <Attachment>[];
    for (final file in files) {
      try {
        final isPdf = p.extension(file.name).toLowerCase() == '.pdf';
        final stored = isPdf
            ? await repo.preparePdf(
                noteId: note.id,
                bytes: file.bytes,
                fileName: file.name,
              )
            : await repo.prepareImage(
                noteId: note.id,
                bytes: file.bytes,
                fileName: file.name,
              );
        // Arşivdeki ek sayfada YÜZMEZ: defter bir dizin, bir tuval değil.
        added.add(stored.copyWith(asFile: true, section: _customPage ?? ''));
      } catch (_) {
        // Tek dosya okunamazsa/çok büyükse kalanlar yine eklensin.
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (added.isEmpty) return;
    await _mutate(
      note,
      (n) => n.copyWith(attachments: [...n.attachments, ...added]),
    );
  }

  Future<void> _removeAttachment(Note note, Attachment attachment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.delete),
        content: Text(context.l10n.archiveDeleteEntry(attachment.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(attachmentRepositoryProvider)
        ?.deleteFromStorage(attachment)
        .catchError((Object _) {});
    await _mutate(
      note,
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id != attachment.id) a,
        ],
      ),
    );
  }

  void _open(Attachment attachment) {
    switch (attachment.kind) {
      case AttachmentKind.image:
        openImageViewer(context, attachment, (_) {});
      case AttachmentKind.pdf:
        if (localFileExists(attachment.localPath)) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PdfViewerScreen(attachment: attachment),
            ),
          );
        }
      case AttachmentKind.video:
      case AttachmentKind.audio:
      case AttachmentKind.slide:
        // Video/ses/sunum defterde yalnız listelenir; oynatma/görüntüleme
        // kendi ekranlarında ve o ekranlar notun düzenine bağlı.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final async = ref.watch(noteStreamProvider(widget.noteId));
    final note = async.value;

    if (note == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.archiveNotebook)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final attachments = _attachmentsOf(note);
    final items = _itemsOf(note);
    final searching = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          note.displayTitle.trim().isEmpty
              ? l10n.archiveNotebook
              : note.displayTitle,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: l10n.archiveNewPage,
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: () => _addPage(note),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.archiveSearchHint,
                    border: const OutlineInputBorder(),
                    suffixIcon: searching
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () =>
                                setState(_searchController.clear),
                          )
                        : null,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final page in _AutoPage.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_autoLabel(page)),
                          selected: !searching && _autoPage == page,
                          onSelected: (_) => setState(() {
                            _autoPage = page;
                            _customPage = null;
                            _searchController.clear();
                          }),
                        ),
                      ),
                    for (final page in note.archivePages)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: const Icon(Icons.folder_outlined, size: 16),
                          label: Text(page),
                          selected: !searching && _customPage == page,
                          onSelected: (_) => setState(() {
                            _autoPage = null;
                            _customPage = page;
                            _searchController.clear();
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : (attachments.isEmpty && items.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  searching ? l10n.noteSearchNoHit : l10n.archivePageEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
              children: [
                for (final item in items)
                  Builder(
                    builder: (context) {
                      // Bağlı dosya: kimliği ek listesinde bulunamıyorsa
                      // (ek silinmiş) bağ sessizce yok sayılır.
                      final linked = item.attachmentId.isEmpty
                          ? null
                          : note.attachments
                                .where((a) => a.id == item.attachmentId)
                                .firstOrNull;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          isThreeLine: item.title.isNotEmpty,
                          leading: const Icon(Icons.notes_outlined),
                          title: Text(
                            item.title.isNotEmpty
                                ? item.title
                                : item.text.split('\n').first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (linked != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: InkWell(
                                    onTap: () => _open(linked),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.link,
                                          size: 14,
                                          color: scheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            linked.fileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: scheme.primary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _editText(note, existing: item),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _mutate(
                              note,
                              (n) => n.copyWith(
                                items: [
                                  for (final i in n.items)
                                    if (i.id != item.id) i,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                for (final attachment in attachments)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(switch (attachment.kind) {
                        AttachmentKind.image => Icons.image_outlined,
                        AttachmentKind.video => Icons.videocam_outlined,
                        AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
                        AttachmentKind.slide => Icons.slideshow_outlined,
                        AttachmentKind.audio => Icons.audiotrack_outlined,
                      }),
                      title: Text(
                        attachment.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          formatBytes(attachment.sizeBytes),
                          if (attachment.section.isNotEmpty) attachment.section,
                        ].join(' · '),
                      ),
                      onTap: () => _open(attachment),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Dosyanın defterdeki ADI = girdinin başlığı
                          // (kullanıcı isteği 2026-08-16).
                          IconButton(
                            tooltip: l10n.archiveEntryTitle,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _renameAttachment(note, attachment),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                _removeAttachment(note, attachment),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: searching
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'archive-text',
                  tooltip: l10n.archiveAddText,
                  onPressed: () => _editText(note),
                  child: const Icon(Icons.post_add),
                ),
                const SizedBox(width: 10),
                // Ekran görüntüsünden yakalama (kullanıcı isteği 2026-08-16).
                FloatingActionButton.small(
                  heroTag: 'archive-capture',
                  tooltip: l10n.archiveCaptureTitle,
                  onPressed: () => _captureFromImage(note),
                  child: const Icon(Icons.document_scanner_outlined),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.extended(
                  heroTag: 'archive-file',
                  onPressed: () => _addFiles(note),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l10n.archiveAddFile),
                ),
              ],
            ),
    );
  }
}

/// Bir notun eklerini arşiv defterine **fiziksel kopya** olarak taşır.
///
/// Kullanıcının açık tercihi (2026-08-16): "içeriğindeki belgeleri resimleri
/// kopyalasın kaybolmaması için". Aynı dosyayı paylaşmak (ikinci bir ek
/// kaydının aynı Storage yolunu göstermesi) depodan tasarruf ederdi ama
/// kaynak not silindiğinde dosya da silinirdi — arşivin varlık sebebi tam
/// olarak bunun olmaması.
///
/// Bedeli: dosya Storage'da İKİ KEZ yer kaplar ve ikinci kopya yükleme
/// kuyruğuna girer.
///
/// Döndürdüğü değer kopyalanan ek sayısıdır.
Future<int> copyAttachmentsToArchive({
  required Note source,
  required Note archive,
  required AttachmentRepository attachments,
  required NotesRepository notes,
  String section = '',
}) async {
  final copied = <Attachment>[];
  for (final original in source.attachments) {
    try {
      final bytes = await attachments.readBytes(original);
      if (bytes == null) continue;
      final stored = switch (original.kind) {
        AttachmentKind.pdf => await attachments.preparePdf(
          noteId: archive.id,
          bytes: bytes,
          fileName: original.fileName,
        ),
        AttachmentKind.slide => await attachments.prepareSlide(
          noteId: archive.id,
          bytes: bytes,
          fileName: original.fileName,
        ),
        _ => await attachments.prepareImage(
          noteId: archive.id,
          bytes: bytes,
          fileName: original.fileName,
        ),
      };
      copied.add(stored.copyWith(asFile: true, section: section));
    } catch (_) {
      // Okunamayan/çok büyük ek kalanları düşürmesin.
    }
  }
  if (copied.isEmpty) return 0;
  await notes.updateNote(
    archive.copyWith(attachments: [...archive.attachments, ...copied]),
  );
  return copied.length;
}
