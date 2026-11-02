import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F18.12: ana ekran toplu seçim kopyası, ağır kısmı ayrı belgede olan
/// balonlu notta balonları taşımalı — liste notu HAFİF, metinden önce
/// `hydrate`.
void main() {
  test('hafif not balonsuz, hydrate sonrası balon satırıyla', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db, 'u1');
    final id = await repo.createNote(NoteType.pdf);
    final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
    final points = [for (var i = 0; i < 20000; i++) (i % 97) / 97];
    await repo.updateNote(
      note.copyWith(
        title: 'Fatura',
        attachments: [
          Attachment(
            id: 'a1',
            kind: AttachmentKind.pdf,
            fileName: 'f.pdf',
            mimeType: 'application/pdf',
            createdAt: DateTime(2026, 11, 2),
            ink: [InkStroke(page: 1, color: 0, width: 0.01, points: points)],
            bubbles: const [
              PageBubble(id: 'b', page: 2, x: .5, y: .5, text: 'son ödeme'),
            ],
          ),
        ],
      ),
    );
    final light = (await repo.watchNotes().first).single;
    expect(light.heavyMissing, isTrue);
    String text(n) => joinSelectedShareText([n], pageLabel: (p) => 'Sayfa $p');
    expect(text(light), isNot(contains('son ödeme')));
    final full = await repo.hydrate(light);
    expect(text(full), contains('son ödeme'));
    expect(text(full), contains('Sayfa 2'));
  });
}
