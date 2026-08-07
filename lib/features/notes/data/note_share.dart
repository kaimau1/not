import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/attachment.dart';
import '../domain/note.dart';
import 'attachment_repository.dart';
import 'note_package.dart';
import 'notes_repository.dart';

/// Notu **başka bir Not kullanıcısına** gönderme ve gelen paketi açma.
///
/// Düz metin paylaşımı notun yalnız yazısını taşıyor; bu yol notu her şeyiyle
/// taşır — ekler (PDF, sunum, görsel, ses), PDF/slayt sayfa notları, üzerine
/// yapılan çizimler, **not balonları**, renkler, yazı tipleri ve etiketler.
/// Alıcıda not gönderendeki gibi açılır. Biçim [NotePackage]'ta.
class NoteShare {
  const NoteShare._();

  /// Notu `.notpaket` dosyasına yazıp paylaşım sayfasını açar.
  ///
  /// Ek baytları önce YEREL kopyadan, yoksa buluttan okunur; okunamayan ek
  /// paylaşımı düşürmez (metadata'sıyla pakete girer, alıcıda "cihazda yok"
  /// yer tutucusu olur) — yarım bir paket, hiç paylaşamamaktan iyidir.
  static Future<void> share(
    Note note, {
    required AttachmentRepository? attachments,
    required String fallbackName,
    required String shareSubject,
  }) async {
    final bytes = await packageBytes(note, attachments);
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, notePackageFileName(note, fallback: fallbackName)),
    );
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/zip')],
        subject: shareSubject,
      ),
    );
  }

  /// Notun paket baytları (paylaşmadan; testler ve yedekleme için ayrı).
  static Future<Uint8List> packageBytes(
    Note note,
    AttachmentRepository? attachments,
  ) async {
    final files = <String, Uint8List>{};
    if (attachments != null) {
      for (final attachment in note.attachments) {
        try {
          final bytes = await attachments.readBytes(attachment);
          if (bytes != null) files[attachment.id] = bytes;
        } catch (_) {
          // Okunamayan ek paylaşımı düşürmez (yukarıdaki gerekçe).
        }
      }
    }
    return buildNotePackage(note, files);
  }

  /// Gelen paketi bu hesapta YENİ bir not olarak oluşturur; oluşan notun
  /// kimliğini döner.
  ///
  /// Sıra önemli: önce not oluşturulur (ek dosyaları not kimliğine bağlı bir
  /// klasöre yazılıyor), sonra ekler kaydedilir, en sonda not TEK yazımda
  /// güncellenir. Ekler tek tek yazılsaydı not bir süre yarım görünür ve
  /// senkron her ek için ayrı bir tur atardı.
  static Future<String> import(
    NotePackage package, {
    required NotesRepository notes,
    required AttachmentRepository? attachments,
  }) async {
    final source = package.note;
    final id = await notes.createNote(source.type);

    final stored = <Attachment>[];
    if (attachments != null) {
      for (final meta in source.attachments) {
        final bytes = package.files[meta.id];
        // Baytı gelmemiş ek atlanır: dosyası olmayan bir ek kaydı arayüzde
        // sonsuza dek "senkronlanmadı" olarak durur ve silinemez.
        if (bytes == null) continue;
        try {
          stored.add(
            await attachments.importAttachment(
              noteId: id,
              meta: meta,
              bytes: bytes,
            ),
          );
        } catch (_) {
          // Tavanı aşan ya da yazılamayan ek notun tamamını düşürmesin.
        }
      }
    }

    // `copyWith` kimliği DEĞİŞTİREMEZ (bilerek: var olan bir notun kimliği
    // hiçbir akışta değişmemeli), bu yüzden not burada kurulur.
    final hasBackground = stored.any(
      (a) => a.id == source.backgroundImageId,
    );
    await notes.updateNote(
      Note(
        id: id,
        type: source.type,
        title: source.title,
        body: source.body,
        items: source.items,
        pageNotes: source.pageNotes,
        attachments: stored,
        tags: source.tags,
        color: source.color,
        frameColor: source.frameColor,
        fontFamily: source.fontFamily,
        fontScale: source.fontScale,
        textOpacity: source.textOpacity,
        titleFontFamily: source.titleFontFamily,
        titleFontScale: source.titleFontScale,
        titleTextOpacity: source.titleTextOpacity,
        // Zemin görseli paketten gelmeyen bir eki gösteriyorsa düşürülür;
        // yoksa not "zemini var ama dosyası yok" durumunda kalırdı.
        backgroundImageId: hasBackground ? source.backgroundImageId : null,
        backgroundOpacity: source.backgroundOpacity,
      ),
    );
    return id;
  }
}
