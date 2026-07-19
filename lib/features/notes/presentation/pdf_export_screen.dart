import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../data/note_pdf.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'viewers/pdf_viewer_screen.dart';

/// Notu PDF'e aktarmadan önce düzenleme ekranı.
///
/// Başlık ve içerik ayrı ayrı düzenlenebilir; içerik tek bir düz metin
/// kutusudur ve yapı satır başlarındaki işaretlerden okunur (`[x]`, `1.`,
/// `-`). Böylece kullanıcı madde ekleyip silebiliyor, işaretli/işaretsiz
/// durumu da metinle birlikte taşınıyor — ayrı bir liste düzenleyicisi
/// yazmaya gerek kalmadı.
class PdfExportScreen extends StatefulWidget {
  const PdfExportScreen({super.key, required this.note});

  final Note note;

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.note.title.trim(),
  );
  late final TextEditingController _content = TextEditingController(
    text: _contentOf(widget.note),
  );
  bool _includeDate = true;
  bool _busy = false;

  static String _contentOf(Note note) => switch (note.type) {
    NoteType.text => note.body.trimRight(),
    NoteType.checklist => [
      for (final item in note.items) '[${item.checked ? 'x' : ' '}] ${item.text}',
    ].join('\n'),
    NoteType.ordered => [
      for (var i = 0; i < note.items.length; i++) '${i + 1}. ${note.items[i].text}',
    ].join('\n'),
  };

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<String?> _generate() async {
    setState(() => _busy = true);
    try {
      final title = _title.text.trim();
      final bytes = await NotePdf.build(
        title: title,
        content: _content.text,
        date: _includeDate
            ? (widget.note.updatedAt ?? widget.note.createdAt ?? DateTime.now())
            : null,
      );
      return await NotePdf.writeTemp(bytes, title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.aiError(e.toString()))),
          );
      }
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
            ],
          ),
        ),
      ),
    );
  }
}
