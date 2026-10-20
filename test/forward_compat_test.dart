import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F1.5 — eski istemci yeni veriyi bozmasın: tanınmayan alanlar ve ek
/// türleri `fromMap` → `toMap` turunda AYNEN korunur.
void main() {
  final created = Timestamp.fromMillisecondsSinceEpoch(1700000000000);

  test('bilinmeyen ek türü ve alanları birebir geri yazılır', () {
    final raw = <String, dynamic>{
      'id': 'a1',
      'kind': 'hologram',
      'fileName': 'x.holo',
      'mimeType': 'application/x-holo',
      'storagePath': 'users/u/notes/n/a1',
      'downloadUrl': '',
      'sizeBytes': 42,
      'align': 'center',
      'createdAt': created,
      'depth': 3,
      'layers': [
        {'z': 1},
      ],
    };
    final a = Attachment.fromMap(raw);
    expect(a.kind, AttachmentKind.unknown);
    expect(a.isUnsupported, isTrue);
    expect(a.skipsUpload, isTrue);
    expect(a.toMap(), raw);
  });

  test('tür alanı olmayan eski kayıt görsel kalır', () {
    final a = Attachment.fromMap({'id': 'a', 'fileName': 'f.jpg'});
    expect(a.kind, AttachmentKind.image);
  });

  test('bilinen türde bilinmeyen alan korunur, copyWith taşır', () {
    final a = Attachment.fromMap({
      'id': 'a',
      'kind': 'text',
      'fileName': 't.txt',
      'mimeType': 'text/plain',
      'text': 'merhaba',
      'createdAt': created,
      'speakerLabels': ['A', 'B'],
    });
    expect(a.kind, AttachmentKind.text);
    final m = a.copyWith(text: 'selam').toMap();
    expect(m['speakerLabels'], ['A', 'B']);
    expect(m['kind'], 'text');
    expect(m['text'], 'selam');
  });

  test('toMap yalnız knownKeys içinde anahtar üretir', () {
    final a = Attachment(
      id: 'a',
      kind: AttachmentKind.pdf,
      fileName: 'f.pdf',
      mimeType: 'application/pdf',
      driveId: 'd',
      width: 1,
      height: 1,
      displayWidth: 1,
      x: 1,
      y: 1,
      pageY: 1,
      asFile: true,
      onPage: true,
      pdfPage: 2,
      pdfTurns: 1,
      pdfMarks: const [1],
      section: 's',
      pageIds: const ['p'],
      webUrl: 'w',
      pinHeight: 1,
      sourceId: 's',
      bubblesHidden: true,
      text: 't',
      transcriptOf: 't',
      sourceDigest: 'd',
    );
    expect(Attachment.knownKeys.containsAll(a.toMap().keys), isTrue);
  });

  test('madde: bilinmeyen alan birebir geri yazılır', () {
    final raw = <String, dynamic>{
      'id': 'i1',
      'text': 'süt',
      'checked': false,
      'dueAt': 123,
      'assignee': 'u2',
    };
    expect(NoteItem.fromMap(raw).toMap(), raw);
    expect(
      NoteItem.fromMap(raw).copyWith(checked: true).toMap()['assignee'],
      'u2',
    );
  });

  test('madde altı ayırıcı çizgi yazılır, okunur; yoksa alan yazılmaz', () {
    const item = NoteItem(id: 'i1', text: 'a', divider: NoteItem.dividerDashed);
    expect(item.toMap()['divider'], 'dashed');
    expect(NoteItem.fromMap(item.toMap()).divider, NoteItem.dividerDashed);
    expect(item.copyWith(divider: '').toMap().containsKey('divider'), isFalse);
    expect(NoteItem.knownKeys, contains('divider'));
  });

  test('not: bilinmeyen üst alanlar korunur, şema yazılır', () {
    final note = Note.fromMap('n1', {
      'type': 'text',
      'title': 'Başlık',
      'body': 'gövde',
      'createdAt': created,
      'createdBy': 'u1',
      'updatedBy': 'u2',
      'mood': 'happy',
      'attachments': [
        {'id': 'a', 'kind': 'hologram', 'createdAt': created},
      ],
    });
    expect(note.hasUnsupportedAttachments, isTrue);
    final m = note.copyWith(title: 'Yeni').toMap();
    expect(m['mood'], 'happy');
    expect(m['createdBy'], 'u1');
    expect(m['schema'], Note.currentSchema);
    expect(m['title'], 'Yeni');
    // updatedBy notla taşınmaz — yazan depo katmanı kendisi koyar.
    expect(m.containsKey('updatedBy'), isFalse);
    expect((m['attachments'] as List).single['kind'], 'hologram');
  });

  test('not toMap yalnız knownKeys içinde anahtar üretir', () {
    const note = Note(
      id: 'n',
      type: NoteType.text,
      pageNotes: {'a#p1': 'x'},
      fontFamily: 'f',
    );
    expect(Note.knownKeys.containsAll(note.toMap().keys), isTrue);
  });

  test('en düşük sürüm kapısı', () {
    expect(isUpdateRequired(0), isFalse);
    expect(isUpdateRequired(kClientDataVersion), isFalse);
    expect(isUpdateRequired(kClientDataVersion + 1), isTrue);
  });
}
