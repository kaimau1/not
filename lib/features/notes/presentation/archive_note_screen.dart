import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../app/theme/note_colors.dart';
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

/// **DEFTER** ekranı — sayfaları çevrilen, kişiye özel bir arşiv defteri
/// (bkz. [NoteType.archive]).
///
/// **YENİDEN TASARIM (kullanıcı isteği 2026-09-01):** "arşiv defteri özelliği
/// kullanışlı değil, mantığı anla ve kullanışlı bir defter uygulaması olsun…
/// kişiye özel bir defter olsun, her sayfasında notlar resimler ekler olacak,
/// sayfaları çevirecek kişi ve hafif bir defter görünümü olsun, sayfa çevirme
/// özelliği olsun, kişi bilsin defter olduğunu."
///
/// **Eski ekran neden kullanışlı değildi.** Defter, üstünde bir arama kutusu
/// ve bir çip barı olan DÜZ BİR LİSTEYDİ. Çipler dört OTOMATİK sayfaydı —
/// Görseller / Videolar / Belgeler / Metinler — yani içerik TÜRÜNE göre
/// bölünüyordu. Sonucu şuydu: bir konuya ait fotoğraf, PDF ve not asla yan
/// yana gelemiyor, üçü üç ayrı sekmeye dağılıyordu. Defterin en temel
/// vaadi ("bir sayfada bir konu") tam olarak bu yüzden çalışmıyordu.
/// Ekranda hiçbir şey de defter olduğunu söylemiyordu: kartlar, `ListTile`lar
/// ve üç yüzen düğme.
///
/// **Yeni model.**
///  * Defter, YATAY olarak çevrilen SAYFALARDAN oluşur ([PageView] +
///    [_PageTurn] — sayfa gerçekten sırtından döner).
///  * Her sayfa KONU sayfasıdır ve içinde metin, görsel ve dosya birlikte
///    durur. Türe göre ayrım kalktı.
///  * İlk sayfa **Genel**: sayfası atanmamış her girdi burada. Eski
///    defterlerdeki (bölümsüz) girdiler böylece olduğu gibi görünür —
///    göç gerekmez, hiçbir şey kaybolmaz.
///  * Sonraki sayfalar kullanıcının açtıklarıdır (`Note.archivePages`);
///    girdiler `Attachment.section` / `NoteItem.section` ile bağlanır.
///  * Kâğıt görünümü: çizgili sayfa, sırtta cilt gölgesi, kenar boşluğu
///    çizgisi, altta sayfa numarası ([_PaperPainter]).
///
/// Arama defterin TAMAMINDA çalışır ve sonuç hangi sayfadaysa oraya götürür —
/// eski ekranın en iyi yanı buydu, korundu.
///
/// Dosyalar KOPYALANIR (kullanıcının açık tercihi): kaynak not silinse bile
/// defterdeki kopya sağlam kalır. Bedeli, dosyanın depoda iki kez yer
/// kaplaması — bkz. [copyAttachmentsToArchive].
class ArchiveNoteScreen extends ConsumerStatefulWidget {
  const ArchiveNoteScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<ArchiveNoteScreen> createState() => _ArchiveNoteScreenState();
}

/// Defterin bir sayfasındaki tek girdi: ya bir METİN ya da bir DOSYA.
/// İkisi aynı listede akar — sayfa "bir konuya ait her şey" demek.
typedef ArchiveEntry = ({NoteItem? text, Attachment? file});

/// Defterin sayfa adları. İlk eleman her zaman boş dizedir = **Genel**
/// sayfası; kayda YAZILMAZ (uygulamanın dili değişince adı da değişsin).
List<String> archivePageNames(Note note) => ['', ...note.archivePages];

/// [page] sayfasındaki girdiler: önce metinler, sonra dosyalar (kayıttaki
/// sıralarıyla).
///
/// **ÖKSÜZ BÖLÜM GENEL'E DÜŞER.** Sayfası başka bir cihazdan silinmiş (ya da
/// eski bir sürümün yazdığı, artık var olmayan bir bölüme bağlı) girdi hiçbir
/// sayfada görünmezdi — kullanıcı için "belgem kayboldu" demek. Tanınmayan
/// bölüm adı taşıyan her girdi Genel sayfasında listelenir.
List<ArchiveEntry> archiveEntriesOf(Note note, String page) {
  final known = note.archivePages.toSet();
  bool onPage(String section) => page.isEmpty
      ? (section.isEmpty || !known.contains(section))
      : section == page;
  return [
    for (final item in note.items)
      if (onPage(item.section)) (text: item, file: null),
    for (final a in note.attachments)
      if (onPage(a.section)) (text: null, file: a),
  ];
}

class _ArchiveNoteScreenState extends ConsumerState<ArchiveNoteScreen> {
  /// Sayfa numaraları burada; `PageController` kaydırma konumunu tutar.
  late final PageController _pageController = PageController();

  /// O an açık sayfanın numarası (0 = Genel). `PageController.page` yalnız
  /// yerleşimden sonra okunabildiği için ayrıca saklanır.
  int _page = 0;

  final _searchController = TextEditingController();
  bool _searching = false;
  bool _busy = false;

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim().toLowerCase();

  NotesRepository? get _repo => ref.read(notesRepositoryProvider);

  String _pageLabel(String name) =>
      name.isEmpty ? context.l10n.archiveGeneralPage : name;

  static bool _matches(String text, String query) =>
      text.toLowerCase().contains(query);

  /// Aramanın sonucu: eşleşen girdiler ve her birinin SAYFA numarası.
  List<({ArchiveEntry entry, int page})> _searchHits(Note note) {
    final query = _query;
    if (query.isEmpty) return const [];
    final names = archivePageNames(note);
    return [
      for (var i = 0; i < names.length; i++)
        for (final entry in archiveEntriesOf(note, names[i]))
          if (_matches(
            entry.text != null
                ? '${entry.text!.title}\n${entry.text!.text}'
                : entry.file!.fileName,
            query,
          ))
            (entry: entry, page: i),
    ];
  }

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

  /// Sayfaya git ama BİR KARE SONRA.
  ///
  /// Yeni sayfa açan akışlar kaydı yazdıktan hemen sonra oraya gitmek ister;
  /// oysa sayfa listesi Firestore akışından geri geldiğinde büyür. Aynı
  /// karede atlanırsa [PageView] henüz o sayfayı tanımıyor ve atlama son
  /// sayfada takılıyor.
  void _goToPageSoon(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _goToPage(index);
    });
  }

  /// Sayfaya git (çevirme animasyonuyla).
  void _goToPage(int index) {
    if (!_pageController.hasClients) {
      setState(() => _page = index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  // ————————————————————————————————— SAYFA İŞLERİ

  /// Yeni sayfa açar ve oraya geçer.
  Future<void> _addPage(Note note) async {
    final name = await _askName(
      title: context.l10n.archiveNewPage,
      hint: context.l10n.archivePageName,
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || note.archivePages.contains(trimmed)) return;
    await _mutate(
      note,
      (n) => n.copyWith(archivePages: [...n.archivePages, trimmed]),
    );
    if (!mounted) return;
    // Yeni sayfa listenin sonunda: Genel + var olan sayfalar kadar ileride.
    _goToPageSoon(note.archivePages.length + 1);
  }

  /// Sayfayı yeniden adlandırır; girdilerin bağı da yeni ada taşınır.
  Future<void> _renamePage(Note note, String current) async {
    final name = await _askName(
      title: context.l10n.archiveRenamePage,
      hint: context.l10n.archivePageName,
      initial: current,
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty ||
        trimmed == current ||
        note.archivePages.contains(trimmed)) {
      return;
    }
    await _mutate(
      note,
      (n) => n.copyWith(
        archivePages: [
          for (final page in n.archivePages)
            if (page == current) trimmed else page,
        ],
        // Bölüm adı GİRDİNİN üzerinde saklandığı için ad değişince bağlar da
        // taşınmalı; taşınmazsa sayfa boşalır ve girdiler Genel'e düşerdi.
        items: [
          for (final i in n.items)
            if (i.section == current) i.copyWith(section: trimmed) else i,
        ],
        attachments: [
          for (final a in n.attachments)
            if (a.section == current) a.copyWith(section: trimmed) else a,
        ],
      ),
    );
  }

  /// Sayfayı siler. **Girdiler SİLİNMEZ**, Genel sayfasına taşınır: bir
  /// sayfayı kaldırmak "bu başlığı istemiyorum" demektir, "bu belgeleri
  /// istemiyorum" demek değil.
  Future<void> _deletePage(Note note, String name) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveDeletePage),
        content: Text(l10n.archiveDeletePageInfo(name)),
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
    if (ok != true) return;
    await _mutate(
      note,
      (n) => n.copyWith(
        archivePages: [
          for (final page in n.archivePages)
            if (page != name) page,
        ],
        items: [
          for (final i in n.items)
            if (i.section == name) i.copyWith(section: '') else i,
        ],
        attachments: [
          for (final a in n.attachments)
            if (a.section == name) a.copyWith(section: '') else a,
        ],
      ),
    );
    if (mounted) _goToPage(0);
  }

  /// Tek satırlık ad soran ortak diyalog (sayfa aç / yeniden adlandır).
  Future<String?> _askName({
    required String title,
    required String hint,
    String initial = '',
  }) async {
    final controller = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (value) => Navigator.pop(dialogContext, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(dialogContext.l10n.ok),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  // ————————————————————————————————— GİRDİ İŞLERİ

  /// Metin girdisi ekler/düzenler (açık sayfaya).
  ///
  /// [existing] verilirse o girdi düzenlenir. Girdinin BAŞLIĞI ve bağlı
  /// olduğu DOSYA da buradan ayarlanır (kullanıcı isteği 2026-08-16:
  /// "metinler görsel veya belge ile bağlanabilmesi… hepsinin başlığı
  /// ayarlanabilmeli"): bir alıntının hangi belgeden geldiği, bir notun
  /// hangi fotoğrafa ait olduğu defterde kaybolmasın.
  Future<void> _editText(Note note, String page, {NoteItem? existing}) async {
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
            section: page,
          ),
        ],
      );
    });
  }

  /// Ekin defterdeki ADINI değiştirir (dosya adı = girdinin başlığı).
  Future<void> _renameAttachment(Note note, Attachment attachment) async {
    final name = await _askName(
      title: context.l10n.archiveEntryTitle,
      hint: context.l10n.archiveEntryTitle,
      initial: attachment.fileName,
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == attachment.fileName) return;
    // YALNIZ görünen ad değişir; dosyanın kendisi (yerel yol, depo yolu)
    // olduğu gibi kalır — yeniden adlandırma yükleme kuyruğunu tetiklemesin.
    await _mutate(
      note,
      (n) => n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == attachment.id) a.copyWith(fileName: trimmed) else a,
        ],
      ),
    );
  }

  /// Girdiyi BAŞKA bir sayfaya taşır (metin ya da dosya).
  Future<void> _moveEntry(Note note, ArchiveEntry entry) async {
    final names = archivePageNames(note);
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final name in names)
              ListTile(
                leading: Icon(
                  name.isEmpty ? Icons.auto_stories_outlined : Icons.bookmark_outline,
                ),
                title: Text(_pageLabel(name)),
                onTap: () => Navigator.pop(sheetContext, name),
              ),
          ],
        ),
      ),
    );
    if (target == null) return;
    await _mutate(note, (n) {
      final item = entry.text;
      if (item != null) {
        return n.copyWith(
          items: [
            for (final i in n.items)
              if (i.id == item.id) i.copyWith(section: target) else i,
          ],
        );
      }
      final file = entry.file!;
      return n.copyWith(
        attachments: [
          for (final a in n.attachments)
            if (a.id == file.id) a.copyWith(section: target) else a,
        ],
      );
    });
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
  Future<void> _captureFromImage(Note note, String page) async {
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
        page: page,
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
    required String page,
    required ({String category, String title, String text}) suggestion,
    required Uint8List imageBytes,
    required String imageName,
  }) async {
    final textController = TextEditingController(text: suggestion.text);
    final pageController = TextEditingController(
      text: suggestion.category.isEmpty ? page : suggestion.category,
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
                  decoration: InputDecoration(
                    labelText: l10n.archiveCaptureText,
                  ),
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
    final target = pageController.text.trim();
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
      final pages = target.isEmpty || n.archivePages.contains(target)
          ? n.archivePages
          : [...n.archivePages, target];
      return n.copyWith(
        archivePages: pages,
        items: [
          ...n.items,
          NoteItem(id: const Uuid().v4(), text: text, section: target),
        ],
        attachments: stored == null
            ? n.attachments
            : [
                ...n.attachments,
                stored.copyWith(asFile: true, section: target),
              ],
      );
    });
    if (!mounted) return;
    // Girdi hangi sayfaya düştüyse oraya çevrilir: kullanıcı az önce
    // kaydettiği şeyi görmeli. Model YENİ bir sayfa önerdiyse o sayfa
    // listenin sonuna eklendi.
    final names = [
      '',
      ...note.archivePages,
      if (target.isNotEmpty && !note.archivePages.contains(target)) target,
    ];
    final index = names.indexOf(target);
    _goToPageSoon(index < 0 ? 0 : index);
  }

  /// Galeriden/diskten dosya seçip açık sayfaya KOPYALAR.
  Future<void> _addFiles(Note note, String page) async {
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
        // Defterdeki ek sayfada YÜZMEZ: defter bir dizin, bir tuval değil.
        added.add(stored.copyWith(asFile: true, section: page));
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

  Future<void> _removeItem(Note note, NoteItem item) => _mutate(
    note,
    (n) => n.copyWith(
      items: [
        for (final i in n.items)
          if (i.id != item.id) i,
      ],
    ),
  );

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

  /// Alt çubuktaki "+": sayfaya ne ekleneceğini soran levha.
  Future<void> _addSheet(Note note, String page) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.post_add),
              title: Text(l10n.archiveAddText),
              subtitle: Text(_pageLabel(page)),
              onTap: () => Navigator.pop(sheetContext, 'text'),
            ),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: Text(l10n.archiveAddFile),
              onTap: () => Navigator.pop(sheetContext, 'file'),
            ),
            if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: Text(l10n.archiveCaptureTitle),
                onTap: () => Navigator.pop(sheetContext, 'capture'),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.library_add_outlined),
              title: Text(l10n.archiveNewPage),
              onTap: () => Navigator.pop(sheetContext, 'page'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'text':
        await _editText(note, page);
      case 'file':
        await _addFiles(note, page);
      case 'capture':
        await _captureFromImage(note, page);
      case 'page':
        await _addPage(note);
    }
  }

  /// Sayfa listesi levhası: uzun defterde sayfa sayfa çevirmek yerine
  /// doğrudan atlamak için (alt çubuktaki "3 / 12" yazısına dokununca).
  Future<void> _pagesSheet(Note note) async {
    final names = archivePageNames(note);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < names.length; i++)
              ListTile(
                selected: i == _page,
                leading: CircleAvatar(
                  radius: 14,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(_pageLabel(names[i])),
                subtitle: Text(
                  sheetContext.l10n.archiveEntryCount(
                    archiveEntriesOf(note, names[i]).length,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, i),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _goToPage(picked);
  }

  // ————————————————————————————————— ÇİZİM

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

    final names = archivePageNames(note);
    // Sayfa başka cihazdan silinmiş olabilir: numara listenin dışına
    // taşmasın (aksi hâlde PageView boş bir sayfa çizer).
    final page = _page.clamp(0, names.length - 1);
    final paper = NoteColors.surface(context, note.color);

    return Scaffold(
      // Zemin, kâğıdın ARKASI: defter masanın üstünde duruyor gibi görünsün
      // diye kâğıttan biraz koyu.
      backgroundColor: Color.alphaBlend(
        scheme.onSurface.withValues(alpha: 0.06),
        paper,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.archiveSearchHint,
                ),
              )
            : Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.displayTitle.trim().isEmpty
                          ? l10n.archiveNotebook
                          : note.displayTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            tooltip: _searching ? l10n.close : l10n.archiveSearchHint,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchController.clear();
            }),
          ),
          if (!_searching)
            PopupMenuButton<String>(
              tooltip: l10n.more,
              onSelected: (value) async {
                switch (value) {
                  case 'new':
                    await _addPage(note);
                  case 'rename':
                    await _renamePage(note, names[page]);
                  case 'delete':
                    await _deletePage(note, names[page]);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'new', child: Text(l10n.archiveNewPage)),
                // Genel sayfası kaydın bir parçası değil (adı dilden geliyor):
                // yeniden adlandırılamaz, silinemez.
                if (page > 0) ...[
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(l10n.archiveRenamePage),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.archiveDeletePage),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : (_searching && _query.isNotEmpty)
          ? _searchResults(note)
          : _book(note, names, paper),
      bottomNavigationBar: (_searching && _query.isNotEmpty)
          ? null
          : _pageBar(note, names, page),
    );
  }

  /// Defterin kendisi: sayfaları çevrilen [PageView].
  Widget _book(Note note, List<String> names, Color paper) => PageView.builder(
    controller: _pageController,
    itemCount: names.length,
    onPageChanged: (index) => setState(() => _page = index),
    itemBuilder: (context, index) => _PageTurn(
      controller: _pageController,
      index: index,
      child: _NotebookPage(
        paper: paper,
        title: _pageLabel(names[index]),
        number: index + 1,
        total: names.length,
        child: _pageBody(note, names[index]),
      ),
    ),
  );

  /// Bir sayfanın içeriği: metin ve dosya girdileri birlikte.
  Widget _pageBody(Note note, String name) {
    final entries = archiveEntriesOf(note, name);
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.archivePageEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(38, 8, 16, 28),
      itemCount: entries.length,
      itemBuilder: (context, i) => _entryTile(note, entries[i]),
    );
  }

  Widget _entryTile(Note note, ArchiveEntry entry) {
    final item = entry.text;
    if (item != null) {
      final linked = item.attachmentId.isEmpty
          ? null
          : note.attachments
                .where((a) => a.id == item.attachmentId)
                .firstOrNull;
      return _TextEntry(
        item: item,
        linked: linked,
        onOpenLinked: linked == null ? null : () => _open(linked),
        onTap: () => _editText(note, item.section, existing: item),
        onMove: () => _moveEntry(note, entry),
        onDelete: () => _removeItem(note, item),
      );
    }
    final file = entry.file!;
    return _FileEntry(
      attachment: file,
      onTap: () => _open(file),
      onRename: () => _renameAttachment(note, file),
      onMove: () => _moveEntry(note, entry),
      onDelete: () => _removeAttachment(note, file),
    );
  }

  /// Arama sonuçları: defterin tamamı, sayfa etiketiyle.
  Widget _searchResults(Note note) {
    final hits = _searchHits(note);
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(context.l10n.noteSearchNoHit),
        ),
      );
    }
    final names = archivePageNames(note);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final hit = hits[i];
        final item = hit.entry.text;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              item != null
                  ? Icons.notes_outlined
                  : _iconFor(hit.entry.file!.kind),
            ),
            title: Text(
              item != null
                  ? (item.title.isNotEmpty
                        ? item.title
                        : item.text.split('\n').first)
                  : hit.entry.file!.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_pageLabel(names[hit.page])),
            onTap: () {
              setState(() {
                _searching = false;
                _searchController.clear();
              });
              // Sayfaya git: PageView bu karede yeniden kurulduğu için
              // atlama bir sonraki kareye bırakılır.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _goToPage(hit.page);
              });
            },
          ),
        );
      },
    );
  }

  static IconData _iconFor(AttachmentKind kind) => switch (kind) {
    AttachmentKind.image => Icons.image_outlined,
    AttachmentKind.video => Icons.videocam_outlined,
    AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
    AttachmentKind.slide => Icons.slideshow_outlined,
    AttachmentKind.audio => Icons.audiotrack_outlined,
  };

  /// Alt çubuk: sayfa çevirme okları, konum göstergesi ve "+".
  Widget _pageBar(Note note, List<String> names, int page) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.archivePrevPage,
              icon: const Icon(Icons.chevron_left),
              onPressed: page > 0 ? () => _goToPage(page - 1) : null,
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _pagesSheet(note),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pageLabel(names[page]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${page + 1} / ${names.length}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.archiveNextPage,
              icon: const Icon(Icons.chevron_right),
              onPressed: page < names.length - 1
                  ? () => _goToPage(page + 1)
                  : null,
            ),
            const SizedBox(width: 4),
            FloatingActionButton.small(
              heroTag: 'notebook-add',
              tooltip: l10n.archiveAddEntry,
              onPressed: () => _addSheet(note, names[page]),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

/// **SAYFA ÇEVİRME.** Sayfa, defterin sırtı (SOL kenar) çevresinde döner.
///
/// [PageView] çocuklarını kendi kaydırmasıyla yatayda kaydırır; burada o
/// kaydırma önce GERİ ALINIR (`Transform.translate`), sonra sayfa sırtından
/// döndürülür. Böylece sayfalar yan yana kaymak yerine üst üste durup çevrilir
/// — istenen "defter" hissini veren şey budur.
///
/// Dönüş 90°'nin biraz altında bırakılır: tam 90°'de sayfa sıfır genişliğe
/// iner ve bir kare için tümüyle kaybolur (göze "takılma" gibi görünür).
class _PageTurn extends StatelessWidget {
  const _PageTurn({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: controller,
      // `child` sabit: sayfa içeriği her karede değil, yalnız veri değişince
      // kurulur — çevirme animasyonu boyunca yalnız dönüşüm hesaplanır.
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        // Yerleşim bitmeden `page` okunamaz; ilk karede sayfa düz durur.
        final position = controller.hasClients && controller.position.haveDimensions
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final t = (index - position).clamp(-1.0, 1.0);
        if (t == 0) return child!;
        // Sırt SOLDA — ama sağdan sola yazılan dillerde defter de ters
        // açılır: hem `PageView`ın kaydırma yönü hem de cildin yeri döner.
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final sign = rtl ? -1.0 : 1.0;
        return Transform.translate(
          // PageView'ın kendi kaydırmasını geri al: sayfa yerinde kalsın.
          offset: Offset(-t * constraints.maxWidth * sign, 0),
          child: Transform(
            alignment: rtl ? Alignment.centerRight : Alignment.centerLeft,
            transform: Matrix4.identity()
              // Perspektif: uzaklaşan kenar daralsın, yoksa dönüş düz bir
              // yatay ezilme gibi görünür.
              ..setEntry(3, 2, 0.0012)
              ..rotateY(-t * sign * math.pi / 2 * 0.96),
            child: Opacity(
              // Çevrilen sayfa kenara yaklaştıkça hafifçe soluklaşır: iki
              // sayfa üst üste dururken hangisinin öne geldiği belli olsun.
              // Fazlası kâğıdı camlaştırır, altındaki sayfa okunur hâle gelir.
              opacity: (1 - t.abs() * 0.4).clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

/// Tek bir defter sayfası: çizgili kâğıt, cilt gölgesi, üstte sayfa başlığı,
/// altta sayfa numarası.
class _NotebookPage extends StatelessWidget {
  const _NotebookPage({
    required this.paper,
    required this.title,
    required this.number,
    required this.total,
    required this.child,
  });

  final Color paper;
  final String title;
  final int number;
  final int total;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(4),
            right: Radius.circular(14),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _PaperPainter(
            line: scheme.onSurface.withValues(alpha: 0.07),
            margin: const Color(0xFFC96A6A).withValues(alpha: 0.35),
            spine: scheme.onSurface.withValues(alpha: 0.10),
          ),
          child: Column(
            children: [
              // Sayfa başlığı EL YAZISI hissi versin diye eğik ve altı
              // çizili: defterin sayfa başına yazılan başlığı gibi.
              Padding(
                padding: const EdgeInsets.fromLTRB(38, 12, 16, 6),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$number / $total',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kâğıdın kendisi: yatay çizgiler, sol kenar boşluğu çizgisi ve sırt gölgesi.
/// Boyacı ayrı: her karede yeniden çizilen tek şey bu ve içerik ağacından
/// bağımsız kalsın.
class _PaperPainter extends CustomPainter {
  const _PaperPainter({
    required this.line,
    required this.margin,
    required this.spine,
  });

  final Color line;
  final Color margin;
  final Color spine;

  /// Satır aralığı: gövde yazısının satır yüksekliğine yakın olsun ki
  /// çizgiler metnin arasına düşsün, üstünden geçmesin.
  static const double _gap = 28;

  /// Sol kenar boşluğu çizgisinin yeri (içerik dolgusuyla aynı).
  static const double _marginX = 30;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var y = _gap * 2; y < size.height - 20; y += _gap) {
      canvas.drawLine(Offset(_marginX, y), Offset(size.width - 12, y), linePaint);
    }
    canvas.drawLine(
      const Offset(_marginX, 8),
      Offset(_marginX, size.height - 8),
      Paint()
        ..color = margin
        ..strokeWidth = 1.2,
    );
    // Cilt: sol kenarda içeri doğru sönen bir gölge şeridi.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 14, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [spine, spine.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, 14, size.height)),
    );
  }

  @override
  bool shouldRepaint(_PaperPainter old) =>
      old.line != line || old.margin != margin || old.spine != spine;
}

/// Sayfadaki METİN girdisi: başlık, gövde, bağlı dosya ve satır menüsü.
class _TextEntry extends StatelessWidget {
  const _TextEntry({
    required this.item,
    required this.linked,
    required this.onTap,
    required this.onMove,
    required this.onDelete,
    this.onOpenLinked,
  });

  final NoteItem item;
  final Attachment? linked;
  final VoidCallback onTap;
  final VoidCallback onMove;
  final VoidCallback onDelete;
  final VoidCallback? onOpenLinked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.title.isNotEmpty)
                    Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  Text(item.text, style: theme.textTheme.bodyMedium),
                  if (linked != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: onOpenLinked,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 14, color: scheme.primary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                linked!.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
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
            ),
            _EntryMenu(onMove: onMove, onDelete: onDelete),
          ],
        ),
      ),
    );
  }
}

/// Sayfadaki DOSYA girdisi. Görsel ise küçük bir önizleme, değilse tür
/// simgesi — sayfada "ne olduğu" bakınca anlaşılsın.
class _FileEntry extends StatelessWidget {
  const _FileEntry({
    required this.attachment,
    required this.onTap,
    required this.onRename,
    required this.onMove,
    required this.onDelete,
  });

  final Attachment attachment;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 52,
                height: 52,
                child: _thumb(context, scheme),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formatBytes(attachment.sizeBytes),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _EntryMenu(
              onRename: onRename,
              onMove: onMove,
              onDelete: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context, ColorScheme scheme) {
    final icon = Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        _ArchiveNoteScreenState._iconFor(attachment.kind),
        size: 24,
        color: scheme.onSurfaceVariant,
      ),
    );
    if (attachment.kind != AttachmentKind.image) return icon;
    if (localFileExists(attachment.localPath)) {
      return Image.file(
        File(attachment.localPath),
        fit: BoxFit.cover,
        cacheWidth: 156,
        errorBuilder: (_, _, _) => icon,
      );
    }
    if (attachment.isUploaded) {
      return CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        fit: BoxFit.cover,
        memCacheWidth: 156,
        errorWidget: (_, _, _) => icon,
      );
    }
    return icon;
  }
}

/// Girdi satırının ⋮ menüsü: yeniden adlandır (dosya), sayfa değiştir, sil.
class _EntryMenu extends StatelessWidget {
  const _EntryMenu({
    required this.onMove,
    required this.onDelete,
    this.onRename,
  });

  final VoidCallback? onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      tooltip: l10n.more,
      onSelected: (value) => switch (value) {
        'rename' => onRename?.call(),
        'move' => onMove(),
        _ => onDelete(),
      },
      itemBuilder: (context) => [
        if (onRename != null)
          PopupMenuItem(value: 'rename', child: Text(l10n.archiveEntryTitle)),
        PopupMenuItem(value: 'move', child: Text(l10n.archiveMoveEntry)),
        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
      ],
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
