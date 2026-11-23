import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/attachment_tag.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'image_annotations.dart';
import 'note_pdf.dart';
import 'pdf_edit.dart';
import 'table_export.dart';
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
    PdfNoteStyle style = const PdfNoteStyle(),
  }) async {
    final images = <ExportImage>[];
    if (attachments != null) {
      for (final a in note.attachments) {
        if (a.kind != AttachmentKind.image) continue;
        if (a.id == note.backgroundImageId) continue;
        try {
          final raw = await attachments.readBytes(a);
          if (raw == null) continue;
          // Çizim + açık metin görselin üstüne basılır (F18.13).
          final img = await exportImageBytes(raw, a);
          images.add(
            ExportImage(
              bytes: img.bytes,
              width: img.width ?? 0,
              height: img.height ?? 0,
              mimeType: img.mimeType,
              widthFraction: 0.8,
            ),
          );
        } catch (_) {
          // Erişilemeyen görsel paylaşımı düşürmez.
        }
      }
    }
    // Tablolar metnin sonunda görsel olarak (2026-11-23).
    images.addAll(await TableExport.noteTableImages(note));
    return NotePdf.build(
      title: options.title ? note.title.trim() : '',
      content: contentOf(note, options),
      date: note.updatedAt,
      images: images,
      palette: palette,
      style: style,
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
  }) => filesOf(
    shareableAttachments(note),
    attachments: attachments,
    siblings: note.attachments,
  );

  /// [list]teki eklerin dosyaları ([attachmentFiles] kuralıyla). Tam ekran
  /// görüntüleyicinin "Paylaş" düğmesi tek ekle çağırır (F13.5).
  static Future<List<XFile>> filesOf(
    List<Attachment> list, {
    required AttachmentRepository? attachments,
    List<Attachment> siblings = const [],
  }) async {
    final out = <XFile>[];
    Directory? temp;
    Future<void> add(Uint8List bytes, String name, String mime) async {
      if (kIsWeb) {
        out.add(XFile.fromData(bytes, name: name, mimeType: mime));
        return;
      }
      temp ??= await Directory.systemTemp.createTemp('note_files_');
      final file = File('${temp!.path}/${safeShareName(name)}');
      await file.writeAsBytes(bytes);
      out.add(XFile(file.path, mimeType: mime, name: name));
    }

    for (final a in list) {
      // GÖRSEL BALONLU KİPE ALINDIYSA çizim görselin TÜRETİLMİŞ belgesinde
      // durur (`sourceId`); görsel çizimsiz gidiyordu (kullanıcı bulgusu
      // 2026-11-21). Belge basılıp sayfası GÖRSEL olarak gönderilir.
      final derived = a.kind == AttachmentKind.image && !hasImageAnnotations(a)
          ? siblings
                .where(
                  (x) =>
                      x.kind == AttachmentKind.pdf &&
                      x.sourceId == a.id &&
                      hasPdfAnnotations(x),
                )
                .firstOrNull
          : null;
      final annotated = hasImageAnnotations(a) || hasPdfAnnotations(a);
      if (!kIsWeb &&
          derived == null &&
          !annotated &&
          a.localPath.isNotEmpty &&
          File(a.localPath).existsSync()) {
        // UZANTISIZ DOSYA (kullanıcı bulgusu 2026-11-21: "scaled_1273…490"
        // diye tanınmayan dosya gidiyordu): görsel seçicinin verdiği ad
        // uzantısız olabiliyor; alıcı türü tanımasın diye kopya MIME'den
        // uzantı alır.
        final ext = extensionForMime(a.mimeType);
        if (_hasExtension(a.localPath) || ext == null) {
          out.add(XFile(a.localPath, mimeType: a.mimeType, name: a.fileName));
        } else {
          await add(
            await File(a.localPath).readAsBytes(),
            '${_baseName(a.fileName)}$ext',
            a.mimeType,
          );
        }
        continue;
      }
      if (attachments == null || a.kind == AttachmentKind.video) continue;
      try {
        if (derived != null) {
          final burned = await burnedPdf(derived, attachments);
          if (burned != null) {
            final pages = await pngPages(burned, name: _baseName(a.fileName));
            out.addAll(pages);
            continue;
          }
        }
        final raw = await attachments.readBytes(a);
        if (raw == null) continue;
        if (a.kind == AttachmentKind.pdf && hasPdfAnnotations(a)) {
          // PDF'e kalemle yazılan/balon eklenen belge DAMGALI gider
          // (kullanıcı bulgusu 2026-11-21: "PDF üstüne yazılı paylaşılmalı").
          final burned = await burnedPdf(a, attachments, raw: raw);
          await add(burned ?? raw, a.fileName, 'application/pdf');
          continue;
        }
        // Katmanlı görsel basılmış PNG olarak gider (F18.13).
        final burned = await burnImageAnnotations(raw, a);
        final bytes = burned ?? raw;
        final ext = extensionForMime(a.mimeType);
        final name = burned != null
            ? _pngName(a.fileName)
            : !_hasExtension(a.fileName) && ext != null
            ? '${_baseName(a.fileName)}$ext'
            : a.fileName;
        final mime = burned == null ? a.mimeType : 'image/png';
        await add(bytes, name, mime);
      } catch (_) {
        // Erişilemeyen ek atlanır.
      }
    }
    return out;
  }

  /// PDF ekinin çizim + balonları basılmış kopyası; damga yoksa ya da
  /// dosya okunamazsa null. Font ana izolede okunur (izolede `rootBundle`
  /// yok).
  static Future<Uint8List?> burnedPdf(
    Attachment a,
    AttachmentRepository attachments, {
    Uint8List? raw,
  }) async {
    if (!hasPdfAnnotations(a)) return null;
    final bytes = raw ?? await attachments.readBytes(a);
    if (bytes == null) return null;
    final font = await rootBundle.load(NotePdf.fontAsset);
    return PdfEdit.burnForSharingInBackground(
      bytes,
      bubbles: a.bubbles,
      ink: a.ink,
      fontBytes: font.buffer.asUint8List(font.offsetInBytes, font.lengthInBytes),
    );
  }

  /// Nottaki TÜM PDF eklerinin paylaşılacak kopyaları (ad, bayt): çizimli/
  /// balonlu olan damgalı (balonlar AÇIK basılır), olmayan olduğu gibi.
  /// Metin notunun "PDF" paylaşımı eskiden yalnız notun yazısını diziyordu;
  /// ekteki belge ve üstündeki kalem hiç gitmiyor, boş notta tek sayfalık
  /// "başlık + tarih" çıkıyordu (kullanıcı bulgusu 2026-11-21).
  static Future<List<(String, Uint8List)>> documentPdfs(
    Note note, {
    required AttachmentRepository? attachments,
    required String baseName,
  }) async {
    if (attachments == null) return const [];
    final out = <(String, Uint8List)>[];
    for (final a in shareableAttachments(note)) {
      if (a.kind != AttachmentKind.pdf) continue;
      try {
        final raw = await attachments.readBytes(a);
        if (raw == null) continue;
        final burned = hasPdfAnnotations(a)
            ? await burnedPdf(a, attachments, raw: raw)
            : null;
        final n = out.length + 1;
        out.add((n > 1 ? '$baseName-$n' : baseName, burned ?? raw));
      } catch (_) {
        // Okunamayan belge paylaşımı düşürmez.
      }
    }
    return out;
  }

  /// Notun KENDİ PDF sayfası gerekli mi: başlık dışında yazı ya da görsel
  /// varsa. Yalnız belge taşıyan notta "başlık + tarih" sayfası gönderilmez.
  static bool hasOwnContent(Note note, ShareTextOptions options) =>
      contentOf(note, options).trim().isNotEmpty ||
      note.attachments.any(
        (a) => a.kind == AttachmentKind.image && a.id != note.backgroundImageId,
      );
}

/// PDF ekinin üstünde çizim ya da balon var mı (paylaşımda basılır).
bool hasPdfAnnotations(Attachment a) =>
    a.kind == AttachmentKind.pdf && (a.ink.isNotEmpty || a.bubbles.isNotEmpty);

/// Geçici dosya adı: uzantı KORUNUR (60 karakter kırpması uzantıyı
/// yiyordu — alıcı uygulama dosya türünü tanımıyordu).
String safeShareName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || name.length - dot > 6) return NotePdf.safeFileName(name);
  final base = NotePdf.safeFileName(name.substring(0, dot));
  return '$base${name.substring(dot)}';
}

bool _hasExtension(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  return dot > 0 && name.length - dot <= 6;
}

/// Bilinen MIME türünün dosya uzantısı (yoksa null).
String? extensionForMime(String mime) => switch (mime.toLowerCase()) {
  'image/jpeg' || 'image/jpg' => '.jpg',
  'image/png' => '.png',
  'image/webp' => '.webp',
  'image/gif' => '.gif',
  'image/heic' => '.heic',
  'application/pdf' => '.pdf',
  'audio/mp4' || 'audio/m4a' || 'audio/aac' => '.m4a',
  'audio/mpeg' => '.mp3',
  'video/mp4' => '.mp4',
  _ => mime.startsWith('image/') ? '.jpg' : null,
};

String _baseName(String fileName) {
  final dot = _hasExtension(fileName) ? fileName.lastIndexOf('.') : -1;
  final base = dot > 0 ? fileName.substring(0, dot) : fileName;
  return NotePdf.safeFileName(base.isEmpty ? 'gorsel' : base);
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

String _pngName(String fileName) {
  final dot = _hasExtension(fileName) ? fileName.lastIndexOf('.') : -1;
  final base = dot > 0 ? fileName.substring(0, dot) : fileName;
  return '${base.isEmpty ? 'gorsel' : base}.png';
}
