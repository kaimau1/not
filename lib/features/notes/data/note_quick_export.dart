import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/painting.dart' show Color;
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/attachment_tag.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'note_pdf.dart';
import 'pdf/pdf_page_render.dart';

/// Paylaşım levhasının TEK DOKUNUŞLUK dosya çıktıları (kullanıcı isteği
/// 2026-10-16: "paylaşım seçenekleri düzenlenmeli ve geliştirilmeli").
///
/// Eskiden notu dosya olarak göndermenin tek yolu dışa aktarma ekranıydı
/// (başlık/metin düzenle, görsel ayarla, sonra Paylaş — dört adım); notu
/// WhatsApp'a RESİM olarak atmak ve nottaki ekleri (fotoğraf, PDF, video)
/// dosya olarak göndermek hiç yoktu. Burada:
/// * [pdf] — dışa aktarma ekranıyla AYNI içerik, görseller metnin sonunda;
/// * [pngPages] — o PDF'in sayfaları resim olarak (mesajlaşmada önizlenir);
/// * [attachmentFiles] — nottaki eklerin kendileri.
/// Ayrıntılı düzen (görsel yeri/boyu, Word) dışa aktarma ekranında kalır.
class NoteQuickExport {
  const NoteQuickExport._();

  /// Dışa aktarılacak metin (biçim işaretleriyle) — dışa aktarma ekranıyla
  /// aynı kural: metin notunda gövde + maddeler, belge notunda sayfa
  /// notları. Paylaşım çipleri uygulanır: tamamlananlar ve etiketler.
  @visibleForTesting
  static String contentOf(Note note, ShareTextOptions options) {
    String box(bool checked, String text) => '[${checked ? 'x' : ' '}] $text';
    final lines = <String>[
      if (note.body.trim().isNotEmpty) note.body.trimRight(),
      switch (note.type) {
        NoteType.ordered => [
          for (var i = 0; i < note.items.length; i++)
            '${i + 1}. ${note.items[i].text}',
        ].join('\n'),
        NoteType.pdf || NoteType.slides => note.pageNotesText().trimRight(),
        NoteType.archive => [
          for (final i in note.items)
            if (i.text.trim().isNotEmpty) i.text,
        ].join('\n\n'),
        _ => [
          for (final i in note.items)
            if (i.text.trim().isNotEmpty && (options.checked || !i.checked))
              box(i.checked, i.text),
        ].join('\n'),
      },
      if (options.links)
        for (final v in shareableVideoLinks(note))
          '▶ ${v.fileName == 'YouTube' ? '' : '${v.fileName.trim()} — '}'
              '${v.webUrl.trim()}',
      if (options.tags && note.tags.isNotEmpty)
        [for (final t in note.tags) '#${t.replaceAll(' ', '_')}'].join(' '),
    ].where((l) => l.trim().isNotEmpty).toList();
    return exportAttachmentTags(lines.join('\n\n'), [
      for (final a in note.attachments) a.fileName,
    ]);
  }

  /// Notun PDF'i (görseller metnin sonunda).
  static Future<Uint8List> pdf(
    Note note, {
    required ShareTextOptions options,
    required AttachmentRepository? attachments,
    List<Color> palette = const [],
  }) async {
    final images = <ExportImage>[];
    if (attachments != null) {
      for (final a in note.attachments) {
        if (a.kind != AttachmentKind.image) continue;
        if (a.id == note.backgroundImageId) continue;
        try {
          final bytes = await attachments.readBytes(a);
          if (bytes == null) continue;
          images.add(
            ExportImage(
              bytes: bytes,
              width: a.width ?? 0,
              height: a.height ?? 0,
              mimeType: a.mimeType,
              widthFraction: 0.8,
            ),
          );
        } catch (_) {
          // Erişilemeyen görsel paylaşımı düşürmez.
        }
      }
    }
    return NotePdf.build(
      title: options.title ? note.title.trim() : '',
      content: contentOf(note, options),
      date: note.updatedAt,
      images: images,
      palette: palette,
    );
  }

  /// [bytes] PDF'inin sayfaları PNG dosyası olarak (en çok [maxPages]).
  /// Web'de dosya sistemi yok: sayfalar bellekten ([XFile.fromData]) verilir
  /// (F13.4, 2026-10-31 — web'de "Görsel" düğmesi bu yüzden gizliydi).
  static Future<List<XFile>> pngPages(
    Uint8List bytes, {
    required String name,
    int maxPages = 10,
    double width = 1240,
  }) async {
    final doc = await PdfDocument.openData(bytes);
    final out = <XFile>[];
    try {
      final dir = kIsWeb
          ? null
          : await Directory.systemTemp.createTemp('note_png_');
      final count = doc.pages.length < maxPages ? doc.pages.length : maxPages;
      for (var i = 0; i < count; i++) {
        final png = await renderPdfPagePng(doc.pages[i], width: width);
        if (png == null) continue;
        final suffix = count > 1 ? '_${i + 1}' : '';
        final fileName = '$name$suffix.png';
        if (dir == null) {
          out.add(XFile.fromData(png, name: fileName, mimeType: 'image/png'));
          continue;
        }
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(png);
        out.add(XFile(file.path, mimeType: 'image/png', name: fileName));
      }
    } finally {
      await doc.dispose();
    }
    return out;
  }

  /// Nottaki eklerin DOSYALARI (görsel, PDF, sunum, video, ses). Cihazda
  /// olmayan küçük dosya (görsel/PDF) buluttan okunup geçici klasöre
  /// yazılır; cihazda olmayan video atlanır (video buluta çıkmıyor).
  /// YouTube eki dosya değil — bağlantısı metne gider.
  static Future<List<XFile>> attachmentFiles(
    Note note, {
    required AttachmentRepository? attachments,
  }) => filesOf(shareableAttachments(note), attachments: attachments);

  /// [list]teki eklerin dosyaları ([attachmentFiles] kuralıyla). Tam ekran
  /// görüntüleyicinin "Paylaş" düğmesi tek ekle çağırır (F13.5).
  static Future<List<XFile>> filesOf(
    List<Attachment> list, {
    required AttachmentRepository? attachments,
  }) async {
    final out = <XFile>[];
    Directory? temp;
    for (final a in list) {
      if (!kIsWeb && a.localPath.isNotEmpty && File(a.localPath).existsSync()) {
        out.add(XFile(a.localPath, mimeType: a.mimeType, name: a.fileName));
        continue;
      }
      if (attachments == null || a.kind == AttachmentKind.video) continue;
      try {
        final bytes = await attachments.readBytes(a);
        if (bytes == null) continue;
        if (kIsWeb) {
          out.add(
            XFile.fromData(bytes, name: a.fileName, mimeType: a.mimeType),
          );
          continue;
        }
        temp ??= await Directory.systemTemp.createTemp('note_files_');
        final file = File('${temp.path}/${NotePdf.safeFileName(a.fileName)}');
        await file.writeAsBytes(bytes);
        out.add(XFile(file.path, mimeType: a.mimeType, name: a.fileName));
      } catch (_) {
        // Erişilemeyen ek atlanır.
      }
    }
    return out;
  }
}

/// Dosya olarak paylaşılabilecek ekler: YouTube (dosyasız) ve notun arka
/// plan görseli hariç hepsi; bir görselden türetilmiş GİZLİ belge de
/// hariç (görselin kendisi gider).
List<Attachment> shareableAttachments(Note note) => [
  for (final a in note.attachments)
    if (!a.isWebVideo &&
        a.id != note.backgroundImageId &&
        !note.hidesDerivedDocument(a))
      a,
];
