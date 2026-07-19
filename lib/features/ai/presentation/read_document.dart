import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../notes/data/doc_text.dart';
import '../../notes/data/pdf_text.dart';
import 'listen_screen.dart';

/// Cihazdan bir belge seçip sesli dinleme ekranını açar.
///
/// Dosya nota EKLENMEZ ve Firebase'e yüklenmez — amaç onu okumak. 30 MB'lık
/// bir sunumu yalnızca dinlemek için Storage kotasına yazmanın anlamı yoktu.
/// Nota kalıcı olarak eklemek isteyen zaten editördeki ek düğmesini kullanır.
Future<void> pickAndReadDocument(BuildContext context) async {
  const group = XTypeGroup(
    label: 'Belge',
    extensions: ['pdf', 'docx', 'pptx', 'txt', 'md'],
    // Android dosya seçici uzantıya değil MIME'a bakar; yalnız `extensions`
    // verilirse Word/PowerPoint dosyaları seçilemez halde (soluk) görünür.
    mimeTypes: [
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'text/plain',
    ],
  );
  final file = await openFile(acceptedTypeGroups: const [group]);
  if (file == null || !context.mounted) return;

  final path = file.path;
  final isPdf = DocText.extensionOf(path) == 'pdf';
  if (!isPdf && !DocText.supports(path)) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.readDocUnsupported)));
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ListenScreen(
        title: file.name,
        loadText: () async => isPdf
            ? PdfText.cleanForSpeech(await PdfText.extract(path))
            : DocText.extract(path),
      ),
    ),
  );
}
