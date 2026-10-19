import 'dart:async';

import '../domain/attachment.dart';
import '../domain/note.dart';
import 'attachment_repository.dart';
import 'notes_repository.dart';

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
    // SES ve VİDEO kopyalanamaz (defterde oynatıcı yolu yok, video zaten
    // yalnız cihazda). KÖK NEDEN (2026-09-23): bunlar da aşağıdaki "görsel"
    // dalına düşüyordu — dosyanın TAMAMI belleğe okunup (bir video yüzlerce
    // MB) görsel diye çözülmeye çalışılıyor, çözülemeyince sessizce
    // atılıyordu. Sonuç aynıydı ama bedeli bellek taşması ve pil.
    if (original.kind == AttachmentKind.audio ||
        original.kind == AttachmentKind.video) {
      continue;
    }
    // Metin eki baytsız kopyalanır (yoksa görsel diye çözülmeye çalışılırdı).
    if (original.kind == AttachmentKind.text) {
      final copy = await attachments.duplicate(
        noteId: archive.id,
        source: original,
      );
      copied.add(copy.copyWith(asFile: true, section: section));
      continue;
    }
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
  // EKLEME yazımı (`arrayUnion`), notun tamamı değil. KÖK NEDEN: kopyalama
  // (okuma + sıkıştırma) saniyeler sürüyor ve [archive], kullanıcının defteri
  // seçtiği andaki kopya. Tamamını geri yazmak, o arada deftere yazılan
  // yazıyı, eklenen dosyayı ya da açılan sayfayı geri alıyordu.
  // Yerel (yalnız bu cihazda) defterde de çalışır (bkz. appendAttachments).
  await notes
      .appendAttachments(archive.id, copied)
      .timeout(const Duration(seconds: 3), onTimeout: () {})
      .catchError((Object _) {});
  return copied.length;
}
