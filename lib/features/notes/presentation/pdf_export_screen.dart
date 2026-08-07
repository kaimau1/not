import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../data/attachment_repository.dart';
import '../data/note_docx.dart';
import '../data/note_pdf.dart';
import '../domain/attachment.dart';
import '../../../core/utils/rich_text.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'viewers/pdf_viewer_screen.dart';

/// Notu PDF'e ya da Word'e (.docx) aktarmadan önce düzenleme ekranı.
///
/// Başlık ve içerik ayrı ayrı düzenlenebilir; içerik tek bir düz metin
/// kutusudur ve yapı satır başlarındaki işaretlerden okunur (`[x]`, `1.`,
/// `-`). Böylece kullanıcı madde ekleyip silebiliyor, işaretli/işaretsiz
/// durumu da metinle birlikte taşınıyor — ayrı bir liste düzenleyicisi
/// yazmaya gerek kalmadı. Notun görselleri (el yazısı çizimleri dahil)
/// istenirse iki biçime de gömülür.
class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key, required this.note, this.layout});

  final Note note;

  /// Notun EKRANDAKİ sayfa ölçüleri (editörden gelir): görsellerin metnin
  /// neresinde durduğunu bulmak için gerekir. Eskiden tüm görseller metnin
  /// SONUNA ekleniyordu — dışa aktarılan belge nottaki düzene benzemiyordu.
  /// null ise (paylaş menüsünden çağrı) eski davranış sürer.
  final ({double bodyTop, double pageWidth, double pageHeight})? layout;

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.note.title.trim(),
  );
  late final TextEditingController _content = TextEditingController(
    text: _contentOf(widget.note),
  );
  bool _includeDate = true;
  bool _includeImages = true;
  bool _busy = false;

  bool get _hasImages =>
      widget.note.attachments.any((a) => a.kind == AttachmentKind.image);

  /// Dışa aktarılan metin: satır içi biçim işaretleri sökülür (PDF/Word
  /// çıktısında "**kalın**" görünmemeli).
  static String _contentOf(Note note) => stripRichMarkers(switch (note.type) {
    NoteType.text => note.body.trimRight(),
    NoteType.checklist => [
      for (final item in note.items)
        '[${item.checked ? 'x' : ' '}] ${item.text}',
    ].join('\n'),
    NoteType.ordered => [
      for (var i = 0; i < note.items.length; i++)
        '${i + 1}. ${note.items[i].text}',
    ].join('\n'),
    // PDF notu dışa aktarılırken KAYNAK BELGE değil, kullanıcının sayfa
    // notları yazılır (belgenin kendisi zaten ek olarak duruyor ve buradaki
    // dışa aktarma metin + görsel üretiyor).
    NoteType.pdf => note.pageNotesText().trimRight(),
  });

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  /// Nota bağlı görsellerin baytlarını toplar (yerel → yoksa Storage).
  /// Erişilemeyen görsel (henüz senkronlanmamış, dosyası silinmiş) atlanır —
  /// dışa aktarma tek görsel yüzünden tümden başarısız olmasın.
  Future<List<ExportImage>> _loadImages() async {
    if (!_includeImages) return const [];
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return const [];
    final out = <ExportImage>[];
    for (final a in widget.note.attachments) {
      if (a.kind != AttachmentKind.image) continue;
      try {
        final bytes = await repo.readBytes(a);
        if (bytes == null) continue;
        out.add(
          ExportImage(
            bytes: bytes,
            width: a.width ?? 0,
            height: a.height ?? 0,
            mimeType: a.mimeType,
            line: _lineFor(a),
            widthFraction: widget.layout == null ? null : a.displayWidth,
            align: _alignFor(a),
          ),
        );
      } catch (_) {
        // Erişilemeyen görsel dışa aktarmayı düşürmez.
      }
    }
    return out;
  }

  /// Görselin nottaki dikey yerini, dışa aktarılan metnin satır sırasına
  /// çevirir. Metin notunda konum BİREBİR hesaplanır: ekrandaki sütun
  /// genişliği ve yazı stiliyle dizilen metinde, görselin üst kenarının
  /// düştüğü satır bulunur. Liste notlarında satırlar ayrı alanlar olduğundan
  /// oranla (görselin sayfadaki yeri / sayfa yüksekliği) yaklaşılır.
  int? _lineFor(Attachment a) {
    final layout = widget.layout;
    if (layout == null || a.pageY == null) return null;
    final content = _content.text;
    if (content.isEmpty) return 0;
    final bandTop = a.pageY! - layout.bodyTop;
    if (bandTop <= 0) return 0;
    if (widget.note.type == NoteType.text) {
      final style = Theme.of(context).textTheme.bodyLarge;
      final painter = TextPainter(
        text: TextSpan(text: content, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: (layout.pageWidth - 32).clamp(1.0, double.infinity));
      final offset = painter
          .getPositionForOffset(Offset(0, bandTop))
          .offset
          .clamp(0, content.length);
      painter.dispose();
      return '\n'.allMatches(content.substring(0, offset)).length;
    }
    final body = (layout.pageHeight - layout.bodyTop).clamp(
      1.0,
      double.infinity,
    );
    final lineCount = '\n'.allMatches(content).length + 1;
    return ((bandTop / body) * lineCount).round().clamp(0, lineCount);
  }

  /// Nottaki yatay konumdan hiza: sol çeyrekte sola, sağ çeyrekte sağa yaslı.
  ExportAlign _alignFor(Attachment a) {
    if (widget.layout == null || a.x == null) return ExportAlign.center;
    final center = a.x! + (a.displayWidth ?? 0.5) / 2;
    if (center < 0.4) return ExportAlign.left;
    if (center > 0.6) return ExportAlign.right;
    return ExportAlign.center;
  }

  DateTime? get _date => _includeDate
      ? (widget.note.updatedAt ?? widget.note.createdAt ?? DateTime.now())
      : null;

  void _showError(Object e) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.aiError(e.toString()))),
      );
  }

  Future<String?> _generate() async {
    setState(() => _busy = true);
    try {
      final title = _title.text.trim();
      final bytes = await NotePdf.build(
        title: title,
        content: _content.text,
        date: _date,
        images: await _loadImages(),
      );
      return await NotePdf.writeTemp(bytes, title);
    } catch (e) {
      if (mounted) _showError(e);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Word (.docx) üretip geçici dosya yolunu döner.
  Future<String?> _generateDocx() async {
    setState(() => _busy = true);
    try {
      final title = _title.text.trim();
      final bytes = await NoteDocx.build(
        title: title,
        content: _content.text,
        date: _date,
        images: await _loadImages(),
      );
      return await NoteDocx.writeTemp(bytes, title);
    } catch (e) {
      if (mounted) _showError(e);
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareWord() async {
    final path = await _generateDocx();
    if (path == null || !mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
        ],
        subject: _title.text.trim().isEmpty
            ? context.l10n.appName
            : _title.text.trim(),
      ),
    );
  }

  Future<void> _preview() async {
    final path = await _generate();
    if (path == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfViewerScreen(
          attachment: Attachment(
            id: 'preview',
            kind: AttachmentKind.pdf,
            fileName: NotePdf.safeFileName(_title.text),
            mimeType: 'application/pdf',
            localPath: path,
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final path = await _generate();
    if (path == null || !mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        subject: _title.text.trim().isEmpty
            ? context.l10n.appName
            : _title.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportPdf)),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          children: [
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.pdfTitleField,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _content,
              minLines: 10,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.pdfContentField,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                helperMaxLines: 3,
                helperText: l10n.pdfMarkupHint,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.pdfIncludeDate),
              value: _includeDate,
              onChanged: (v) => setState(() => _includeDate = v),
            ),
            if (_hasImages)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.exportIncludeImages),
                value: _includeImages,
                onChanged: (v) => setState(() => _includeImages = v),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_busy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: LinearProgressIndicator(),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _busy ? null : _preview,
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(l10n.pdfPreview),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: scheme.primary,
                      ),
                      onPressed: _busy ? null : _share,
                      icon: const Icon(Icons.ios_share),
                      label: Text(l10n.share),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Word: aynı içerik .docx olarak paylaşılır (Word'de açıp
              // düzenlemeye devam etmek isteyenler için).
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _busy ? null : _shareWord,
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.exportWord),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
