import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_actions.dart';

/// Kullanıcı isteği 2026-11-09: görsel ve PDF'e tek dokunuşla açık metin —
/// bütün görünümlerde. Menüde "Üstüne yazı ekle" (şerit, gömülü, sağ tık);
/// yüzen ve sabitte çubuğun kendi "T" düğmesi olduğundan menüde yok.
void main() {
  const caps = AttachmentCaps(addText: true);
  Attachment of(AttachmentKind kind) =>
      Attachment(id: 'a', kind: kind, fileName: 'x', mimeType: '');

  test('görsel ve PDF: şerit/gömülü/sağ tık menüsünde var', () {
    for (final kind in [AttachmentKind.image, AttachmentKind.pdf]) {
      for (final surface in [
        AttachmentSurface.strip,
        AttachmentSurface.embedded,
        AttachmentSurface.contextMenu,
      ]) {
        expect(
          attachmentActionsFor(of(kind), surface, caps),
          contains(AttachmentAction.addText),
          reason: '$kind $surface',
        );
      }
    }
  });

  test('yüzen/sabitte menüde yok (çubukta T); video/sesde hiç yok', () {
    for (final surface in [
      AttachmentSurface.floating,
      AttachmentSurface.pinned,
    ]) {
      expect(
        attachmentActionsFor(of(AttachmentKind.image), surface, caps),
        isNot(contains(AttachmentAction.addText)),
      );
    }
    for (final kind in [AttachmentKind.video, AttachmentKind.audio]) {
      expect(
        attachmentActionsFor(of(kind), AttachmentSurface.strip, caps),
        isNot(contains(AttachmentAction.addText)),
      );
    }
    // Salt okunur (yetki yok): hiç yok.
    expect(
      attachmentActionsFor(
        of(AttachmentKind.image),
        AttachmentSurface.strip,
        const AttachmentCaps(),
      ),
      isNot(contains(AttachmentAction.addText)),
    );
  });
}
