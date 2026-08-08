import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../data/attachment_repository.dart';
import '../data/note_pdf.dart';
import '../data/note_share.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';

/// Notun PAYLAŞ menüsü — üç ayrı yol, tek yerde.
///
/// Kök neden (kullanıcı bulgusu 2026-08-08: "paylaş seçenekleri doğru
/// çalışmıyor"): tek bir "Paylaş" düğmesi vardı ve o da notun DÜZ METNİNİ
/// gönderiyordu. PDF notunun düz metni çoğu zaman boş olduğu için düğme hiçbir
/// şey yapmadan kapanıyor, üstelik belgenin üzerindeki balonlar hiçbir yoldan
/// karşı tarafa gitmiyordu.
///
/// Üç yol birbirinin yerine geçmez:
/// * **Düz metin** — nottaki yazı, herhangi bir uygulamaya.
/// * **Not olarak** (`.notpaket`) — başka bir Not kullanıcısına; ekler, sayfa
///   notları, çizimler ve balonlar DÜZENLENEBİLİR gelir.
/// * **Balonlu PDF** — balon/vurgu/çizim belgenin içine basılır; alıcının Not
///   uygulaması olması gerekmez, herhangi bir PDF okuyucu gösterir.
Future<void> showNoteShareSheet(
  BuildContext context,
  WidgetRef ref,
  Note note,
) async {
  final l10n = context.l10n;
  final hasText = note.toPlainText().trim().isNotEmpty;
  final stamped = countStampablePdfs(note);
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(
            sheetContext,
            value: 'text',
            icon: Icons.notes_outlined,
            title: l10n.shareAsText,
            subtitle: hasText ? l10n.shareAsTextInfo : l10n.shareAsTextEmpty,
            enabled: hasText,
          ),
          _tile(
            sheetContext,
            value: 'package',
            icon: Icons.ios_share,
            title: l10n.shareAsNote,
            subtitle: l10n.shareAsNoteInfo,
            enabled: true,
          ),
          _tile(
            sheetContext,
            value: 'pdf',
            icon: Icons.picture_as_pdf_outlined,
            title: l10n.sharePdfWithBubbles,
            subtitle: stamped > 0
                ? l10n.sharePdfWithBubblesInfo
                : l10n.sharePdfWithBubblesNone,
            enabled: stamped > 0,
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  await runNoteShare(context, ref, note, choice);
}

/// Notta damgalanabilecek (balonu ya da çizimi olan) PDF eki sayısı.
int countStampablePdfs(Note note) => note.attachments
    .where(
      (a) =>
          a.kind == AttachmentKind.pdf &&
          (a.bubbles.isNotEmpty || a.ink.isNotEmpty),
    )
    .length;

/// Seçilen paylaşım yolunu koşar. Menüden de (bkz. [showNoteShareSheet]) not
/// işlemleri ızgarasından da aynı gövde çağrılır.
Future<void> runNoteShare(
  BuildContext context,
  WidgetRef ref,
  Note note,
  String choice,
) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final subject = note.displayTitle.trim().isEmpty
      ? l10n.appName
      : note.displayTitle.trim();
  void snack(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  switch (choice) {
    case 'text':
      final text = note.toPlainText();
      // Sessiz kapanmak YOK: boş notta düğmenin neden bir şey yapmadığı
      // söylenir (eski davranışta hiçbir geri bildirim yoktu).
      if (text.trim().isEmpty) {
        snack(l10n.shareAsTextEmpty);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
    case 'package':
      snack(l10n.shareAsNotePreparing);
      try {
        await NoteShare.share(
          note,
          attachments: ref.read(attachmentRepositoryProvider),
          fallbackName: l10n.appName,
          shareSubject: subject,
        );
      } catch (e) {
        snack(l10n.genericError('$e'));
      }
    case 'pdf':
      if (countStampablePdfs(note) == 0) {
        snack(l10n.sharePdfWithBubblesNone);
        return;
      }
      snack(l10n.sharePdfWithBubblesPreparing);
      try {
        // Font ANA izolede okunur: `rootBundle` izolede yok (bkz. NotePdf).
        final font = await rootBundle.load(NotePdf.fontAsset);
        final count = await NoteShare.shareAnnotatedPdfs(
          note,
          attachments: ref.read(attachmentRepositoryProvider),
          fontBytes: font.buffer.asUint8List(
            font.offsetInBytes,
            font.lengthInBytes,
          ),
          fileSuffix: l10n.sharePdfWithBubblesSuffix,
          shareSubject: subject,
        );
        if (count == 0) snack(l10n.sharePdfWithBubblesNone);
      } catch (e) {
        snack(l10n.genericError('$e'));
      }
  }
}

Widget _tile(
  BuildContext context, {
  required String value,
  required IconData icon,
  required String title,
  required String subtitle,
  required bool enabled,
}) {
  final scheme = Theme.of(context).colorScheme;
  return ListTile(
    enabled: enabled,
    leading: Icon(icon, color: enabled ? scheme.primary : null),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: () => Navigator.pop(context, value),
  );
}
