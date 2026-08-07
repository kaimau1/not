import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// ESKİ SÜRÜM UYUMU — GERİYE DÖNÜK ONARIM (2026-08-07 / 15. tur).
///
/// Okuma yönü güvenliydi: eski sürüm `pageNotes` alanını hiç yazmadığı için
/// `set(merge: true)` onu koruyor. Ama eski sürüm `type` alanını KOŞULSUZ
/// yazıyor ve tanımadığı `pdf`/`slides` kimliğini `text`e düşürüp öyle GERİ
/// KAYDEDİYOR — o andan sonra not yeni sürümde de düz metin notu olarak
/// açılır, sayfa notları dokümanda durur ama arayüzden erişilemezdi.
void main() {
  test('eski sürümün text\'e düşürdüğü PDF notu geri yükseltilir', () {
    expect(
      repairNoteType(
        NoteType.text,
        attachmentKinds: const ['pdf'],
        hasPageNotes: true,
      ),
      NoteType.pdf,
    );
  });

  test('sunum notu da geri yükseltilir', () {
    expect(
      repairNoteType(
        NoteType.text,
        attachmentKinds: const ['image', 'slide'],
        hasPageNotes: true,
      ),
      NoteType.slides,
    );
  });

  test('sayfa notu YOKSA dokunulmaz — PDF eki olan metin notu meşrudur', () {
    expect(
      repairNoteType(
        NoteType.text,
        attachmentKinds: const ['pdf'],
        hasPageNotes: false,
      ),
      NoteType.text,
    );
  });

  test('belge eki YOKSA dokunulmaz (yetim sayfa notu tipi değiştirmez)', () {
    expect(
      repairNoteType(
        NoteType.text,
        attachmentKinds: const ['image', null],
        hasPageNotes: true,
      ),
      NoteType.text,
    );
  });

  test('kayıtlı tip zaten doğruysa olduğu gibi kalır', () {
    for (final type in NoteType.values) {
      if (type == NoteType.text) continue;
      expect(
        repairNoteType(
          type,
          attachmentKinds: const ['pdf'],
          hasPageNotes: true,
        ),
        type,
      );
    }
  });
}
