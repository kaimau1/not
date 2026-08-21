import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_backup.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// Yedek alma/geri yükleme mantığı ayarlar ekranının widget'larından
/// `NoteBackup`'a çıkarıldı (KALANLAR: hesap birleştirme akışının ön koşulu).
/// Buradaki testler o mantığın ekransız da doğru çalıştığını sabitler.
void main() {
  final now = DateTime(2026, 8, 21, 12);

  final note = Note(
    id: 'n1',
    type: NoteType.checklist,
    title: 'Alışveriş',
    body: 'market',
    items: const [
      NoteItem(id: 'i1', text: 'süt', checked: true),
      NoteItem(id: 'i2', text: 'ekmek'),
    ],
    tags: const ['ev'],
    color: NoteColor.amber,
    pinned: true,
    locked: true,
    createdAt: DateTime(2026, 1, 2),
    archivedAt: DateTime(2026, 2, 3),
    reminderAt: now.add(const Duration(days: 1)),
    attachments: const [
      Attachment(
        id: 'a1',
        kind: AttachmentKind.image,
        fileName: 'foto.jpg',
        mimeType: 'image/jpeg',
        storagePath: 'users/u/foto.jpg',
        downloadUrl: 'https://example.com/foto.jpg?token=gizli',
      ),
    ],
  );

  test('yedek eklerin indirme BAGLANTISINI tasimaz', () {
    final json = NoteBackup.encode([note], at: now);
    expect(json.contains('token=gizli'), isFalse);
    expect(json.contains('users/u/foto.jpg'), isTrue);
    final map = jsonDecode(json) as Map<String, dynamic>;
    expect(map['app'], NoteBackup.appTag);
    expect(map['noteCount'], 1);
  });

  test('gidip gelen not alanlarini korur', () {
    final restored = NoteBackup.decode(
      NoteBackup.encode([note], at: now),
      now: now,
    );
    expect(restored, hasLength(1));
    final first = restored.single;
    expect(first.type, NoteType.checklist);
    expect(first.fields['title'], 'Alışveriş');
    expect(first.fields['body'], 'market');
    expect(first.fields['pinned'], isTrue);
    // Kilit geri gelmeli: kilitsiz geri yüklenirse içerik açıkta kalır.
    expect(first.fields['locked'], isTrue);
    expect(first.fields['tags'], ['ev']);
    expect(first.fields['archivedAt'], isA<Timestamp>());
    expect(first.fields['reminderAt'], isA<Timestamp>());
    final items = first.fields['items'] as List;
    expect(items, hasLength(2));
    expect((items.first as Map)['text'], 'süt');
    expect((items.first as Map)['checked'], isTrue);
    // Madde kimlikleri YENİDEN üretilir (not yeni bir kayıt olarak açılıyor).
    expect((items.first as Map)['id'], isNot('i1'));
    // Klasör başka hesapta anlamsız: geri yazılmaz.
    expect(first.fields.containsKey('folderId'), isFalse);
  });

  test('gecmiste kalan hatirlatici geri kurulmaz', () {
    final past = Note(
      id: 'n2',
      type: NoteType.text,
      title: 'eski',
      reminderAt: now.subtract(const Duration(days: 2)),
    );
    final restored = NoteBackup.decode(
      NoteBackup.encode([past], at: now),
      now: now,
    );
    expect(restored.single.fields.containsKey('reminderAt'), isFalse);
  });

  test('bos kayitlar atlanir, bozuk bicim FormatException', () {
    final empty = Note(id: 'n3', type: NoteType.text);
    expect(NoteBackup.decode(NoteBackup.encode([empty], at: now)), isEmpty);
    expect(() => NoteBackup.decode('[]'), throwsFormatException);
    expect(() => NoteBackup.decode('{"a":1}'), throwsFormatException);
  });

  test('dosya adi tarihten kurulur', () {
    expect(NoteBackup.fileName(DateTime(2026, 8, 5)), 'notlar-yedek-2026-08-05.json');
  });
}
