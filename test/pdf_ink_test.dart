import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

/// PDF üzerine yapılan çizimin nota kayıtlı kalması, ekin haritasına yazılıp
/// geri okunabilmesine bağlı; bu kırılırsa çizim sessizce kaybolur.
void main() {
  test('ink strokes survive map round-trip', () {
    final a = Attachment(
      id: 'a1',
      kind: AttachmentKind.pdf,
      fileName: 'x.pdf',
      mimeType: 'application/pdf',
      ink: const [
        InkStroke(
          page: 2,
          color: 0xFFE53935,
          width: 0.005,
          points: [0.1, 0.2, 0.3, 0.4],
        ),
      ],
      createdAt: DateTime(2026),
    );

    final back = Attachment.fromMap(a.toMap());

    expect(back.ink.length, 1);
    expect(back.ink.first.page, 2);
    expect(back.ink.first.color, 0xFFE53935);
    expect(back.ink.first.width, closeTo(0.005, 1e-9));
    expect(back.ink.first.points, [0.1, 0.2, 0.3, 0.4]);
  });

  test('clearing ink writes an empty layer', () {
    final a = Attachment(
      id: 'a1',
      kind: AttachmentKind.pdf,
      fileName: 'x.pdf',
      mimeType: 'application/pdf',
      ink: const [
        InkStroke(page: 1, color: 0, width: 0.004, points: [0, 0]),
      ],
      createdAt: DateTime(2026),
    );

    final cleared = a.copyWith(ink: const []);

    expect(cleared.ink, isEmpty);
    expect(Attachment.fromMap(cleared.toMap()).ink, isEmpty);
  });
}
