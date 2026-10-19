import 'dart:io';

import 'attachment_repository.dart';
import 'doc_text.dart';
import 'pdf_text.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// Bir notun SESLİ OKUNACAK metni.
///
/// **KÖK NEDEN (kullanıcı bulgusu 2026-08-08: "PDF sesli oku çalışmıyor").**
/// Okuma ekranına notun düz metni veriliyordu; PDF/sunum notunda o metin
/// SAYFA NOTLARIDIR ve çoğu notta boştur, dolayısıyla ekran "bu belgeden
/// okunabilir metin çıkmadı" diyordu — oysa okunacak metin belgenin İÇİNDE
/// duruyordu. Artık belge notunda belgenin kendi metni de çıkarılıyor.
///
/// Sıra: önce kullanıcının kendi yazdığı (başlıksız gövde + sayfa notları),
/// sonra belgenin metni. Belgeye erişilemezse (henüz senkronlanmamış) o kısım
/// sessizce atlanır — notun kendi metni yine okunur.
Future<String> noteSpeechText(
  Note note,
  AttachmentRepository? attachments,
) async {
  final parts = <String>[];
  final own = note.toContentText().trim();
  if (own.isNotEmpty) parts.add(own);

  if (note.type == NoteType.pdf || note.type == NoteType.slides) {
    for (final doc in note.attachments) {
      if (doc.kind != AttachmentKind.pdf && doc.kind != AttachmentKind.slide) {
        continue;
      }
      final text = await _documentText(doc, attachments);
      if (text.trim().isNotEmpty) parts.add(text.trim());
    }
  }
  return parts.join('\n\n');
}

/// Tek bir belgenin metni. PDF'te metin katmanı `pdfrx` ile okunur (taranmış
/// belgede boş döner), sunumda XML'den çıkarılır.
Future<String> _documentText(
  Attachment doc,
  AttachmentRepository? attachments,
) async {
  try {
    if (doc.kind == AttachmentKind.pdf) {
      // pdfrx DOSYA yolu ister; yerel kopya yoksa bulut baytları geçici bir
      // dosyaya yazılır (ikinci cihazda not açıldığında da okunabilsin).
      final path = doc.localPath.isNotEmpty && File(doc.localPath).existsSync()
          ? doc.localPath
          : await _tempCopy(doc, attachments);
      if (path == null) return '';
      return PdfText.cleanForSpeech(await PdfText.extract(path));
    }
    final bytes = await attachments?.readBytes(doc);
    if (bytes == null) return '';
    // `await` ŞART: try içinde await'siz dönen Future'ın hatası catch'e
    // düşmüyordu (bozuk PPTX okumayı düşürüyordu — F1.7).
    return await DocText.extractFromBytes('pptx', bytes);
  } catch (_) {
    // Bozuk/şifreli belge okumayı düşürmesin: notun kendi metni yine okunur.
    return '';
  }
}

Future<String?> _tempCopy(
  Attachment doc,
  AttachmentRepository? attachments,
) async {
  final bytes = await attachments?.readBytes(doc);
  if (bytes == null) return null;
  final file = File(
    '${Directory.systemTemp.path}/not-oku-${doc.id}.pdf',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
