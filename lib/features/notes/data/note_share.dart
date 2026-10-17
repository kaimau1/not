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
import 'pdf_edit.dart';

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

  /// Notun PDF eklerini **balonlarıyla birlikte** paylaşır.
  ///
  /// [share] bütün notu gönderir (`.notpaket`); bu yol ise **belgeyi** gönderir:
  /// balonlar, vurgular ve el yazısı PDF'in içine basılır, yani dosya herhangi
  /// bir PDF okuyucuda olduğu gibi görünür.
  ///
  /// Alıcının Notlar'ı varsa dosya orada **düzenlenebilir** açılır: damga
  /// adlandırılmış bir katmana çizilir ve balon verisi PDF'e ek dosya olarak
  /// iliştirilir (bkz. [PdfEdit.burnForSharing] / [PdfEdit.readSharedPdf]).
  ///
  /// Ekin kendisine DOKUNULMAZ: damgalı kopya geçici klasöre yazılır, uygulama
  /// içindeki belge katmanlı (yani hâlâ düzenlenebilir) kalır.
  ///
  /// Paylaşılan dosya sayısını döner; 0 = notta damgalanacak PDF yok.
  ///
  /// **Dosya adı NOTUN BAŞLIĞINDAN** gelir (kullanıcı isteği 2026-08-09:
  /// "balonlu notlarda notun başlığı, oluşturulan yeni PDF'ye ad olarak
  /// verilmeli"). Görselden/fotoğraftan kurulan balonlu notlarda belgeye
  /// yakalama kipinin adı veriliyordu ("Foto çek not al.pdf"); paylaşılan
  /// dosya da o adla gidiyor, alıcıda hangi not olduğu anlaşılmıyordu.
  /// Başlık boşsa ekin kendi adına düşülür — adsız dosya üretilmez.
  static Future<int> shareAnnotatedPdfs(
    Note note, {
    required AttachmentRepository? attachments,
    required Uint8List fontBytes,
    required String fileSuffix,
    required String shareSubject,
  }) async {
    if (attachments == null) return 0;
    final files = <XFile>[];
    final dir = await getTemporaryDirectory();
    final titleBase = safePdfBaseName(note.displayTitle);
    // Aynı notta birden çok damgalı belge varsa adlar çakışmasın.
    var stamped = 0;
    for (final attachment in note.attachments) {
      if (attachment.kind != AttachmentKind.pdf) continue;
      if (attachment.bubbles.isEmpty && attachment.ink.isEmpty) continue;
      final bytes = await attachments.readBytes(attachment);
      if (bytes == null) continue;
      final out = await PdfEdit.burnForSharingInBackground(
        bytes,
        bubbles: attachment.bubbles,
        ink: attachment.ink,
        fontBytes: fontBytes,
      );
      stamped++;
      final fallback = p.basenameWithoutExtension(attachment.fileName);
      final base = titleBase ?? fallback;
      final suffixed = stamped > 1 ? '$base-$stamped' : base;
      final file = File(p.join(dir.path, '$suffixed$fileSuffix.pdf'));
      await file.writeAsBytes(out, flush: true);
      files.add(XFile(file.path, mimeType: 'application/pdf'));
    }
    if (files.isEmpty) return 0;
    await SharePlus.instance.share(
      ShareParams(files: files, subject: shareSubject),
    );
    return files.length;
  }

  /// Notun paket baytları (paylaşmadan; testler ve yedekleme için ayrı).
  static Future<Uint8List> packageBytes(
    Note note,
    AttachmentRepository? attachments,
  ) async {
    final files = <String, Uint8List>{};
    if (attachments != null) {
      for (final attachment in note.attachments) {
        // Metin eki içeriğini kaydında taşır; ayrı dosya gereksiz.
        if (attachment.kind == AttachmentKind.text) continue;
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
        // YouTube eki ve metin eki dosyasızdır: kayıt olduğu gibi taşınır.
        if (meta.isWebVideo || meta.kind == AttachmentKind.text) {
          stored.add(meta);
          continue;
        }
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
        textPages: source.textPages,
        activePage: source.activePage,
      ),
    );
    return id;
  }
}

/// Balonlu (belge) notta duran BELGENİN adını kurar.
///
/// **KÖK NEDEN (kullanıcı bulgusu 2026-08-18: "balonlu modda başlık hatası —
/// oluşturulan PDF'nin adı 'PDF ekle not al' oluyor, orijinal adı buna
/// değiştiriliyor").** Belgeye şimdiye dek YAKALAMA KİPİNİN MENÜ ETİKETİ
/// veriliyordu ("PDF ekle not al.pdf", "Görsel ekle not al.pdf"): ana ekran
/// birbirinin aynı adlarla doluyor, seçilen dosyanın kendi adı da kayboluyordu.
///
/// Kural artık tek: **belgenin adı NOTUN BAŞLIĞIDIR**; başlık boşsa belgenin
/// KENDİ adı korunur ve yanına "notlar" eklenir (`rapor` → `rapor notlar`).
/// Yakalama kipinin adı hiçbir yerde dosya adı olmaz.
///
/// [originalName] uzantılı ya da uzantısız olabilir; dönen ad UZANTISIZDIR —
/// çağıran kendi uzantısını ekler.
String documentBaseName({
  required String noteTitle,
  required String originalName,
  required String notesSuffix,
}) {
  final titled = safePdfBaseName(noteTitle);
  if (titled != null) return titled;
  final base = p.basenameWithoutExtension(originalName).trim();
  if (base.isEmpty) return notesSuffix.trim();
  return safePdfBaseName('$base $notesSuffix') ?? base;
}

/// Not başlığından **dosya adı** üretir: dosya sisteminde sorun çıkaran
/// karakterler atılır, uzunluk sınırlanır. Kullanılabilir bir ad çıkmazsa
/// (başlık boş ya da tamamen işaretten ibaret) null döner — çağıran o zaman
/// kendi yedek adına düşer.
String? safePdfBaseName(String title) {
  final cleaned = title
      .trim()
      // Windows ve Android'in kabul etmediği karakterler + kontrol karakteri.
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'[\x00-\x1f]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return null;
  return cleaned.length > 60 ? cleaned.substring(0, 60).trim() : cleaned;
}
