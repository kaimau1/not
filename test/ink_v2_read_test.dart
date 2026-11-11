import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/ink_pack.dart';
import 'package:notlar/features/notes/domain/ink_plan.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F61.5: okuma tarafı iki biçimi birden okur (v2 yazımı bayrakla kapalı;
/// v2 belgeleri burada elle kuruluyor).
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
  });

  InkStroke stroke(int color, {double y = 0.2}) => InkStroke(
    page: 1,
    color: color,
    width: 0.004,
    points: [0.1, y, 0.2, y + 0.01, 0.3, y],
  );

  Future<void> putInk(String id, String surface, List<InkStroke> s) async {
    final docs = planInkDocs(surface: surface, strokes: s, order: InkOrder());
    for (final e in docs.entries) {
      await db.doc('users/u1/notes/$id/$kInkCollection/${e.key}').set({
        'v': 1,
        'b': Blob(e.value),
        'n': decodeInkPack(e.value).strokes.length,
      });
    }
  }

  Future<String> v1Note() async {
    final id = await repo.createNote(NoteType.text, body: 'metin');
    final note = (await repo.watchNote(id).firstWhere((n) => n != null))!;
    await repo.updateNote(
      note.copyWith(
        pageInk: [stroke(0xFF000001)],
        attachments: [
          Attachment(
            id: 'a1',
            kind: AttachmentKind.pdf,
            fileName: 'x.pdf',
            mimeType: 'application/pdf',
            createdAt: DateTime(2026, 11, 11),
            ink: [stroke(0xFF0000A1)],
          ),
        ],
      ),
    );
    return id;
  }

  test(
    'v2 YAZIMI KAPALI: kayıt ink koleksiyonuna yazmaz, inkV koymaz',
    () async {
      final id = await v1Note();
      final main = (await db.doc('users/u1/notes/$id').get()).data()!;
      expect(main.containsKey('inkV'), isFalse);
      final ink = await db
          .collection('users/u1/notes/$id/$kInkCollection')
          .get();
      expect(ink.docs, isEmpty);
    },
  );

  test('v1 not olduğu gibi açılır', () async {
    final id = await v1Note();
    final n = (await repo.watchNote(id).firstWhere((n) => n != null))!;
    expect(n.pageInk.single.color, 0xFF000001);
    expect(n.attachments.single.ink.single.color, 0xFF0000A1);
    expect(n.heavyMissing, isFalse);
  });

  test('v2 not açılır; karışıkta v2 kazanır, v2siz yüzey v1 kalır', () async {
    final id = await v1Note();
    await putInk(id, kPageInkId, [stroke(0xFF000002), stroke(0xFF000003)]);
    await db.doc('users/u1/notes/$id').update({'inkV': 2});
    final n = (await repo
        .watchNote(id)
        .firstWhere((n) => n != null && n.pageInk.length == 2))!;
    // Sayfa v2'den, ek v1'den.
    expect(n.pageInk.map((s) => s.color), [0xFF000002, 0xFF000003]);
    expect(n.attachments.single.ink.single.color, 0xFF0000A1);
    expect(n.heavyMissing, isFalse);
  });

  test('yalnız v2 (ana belgede mürekkep yok) not açılır', () async {
    final id = await repo.createNote(NoteType.text);
    await putInk(id, 'a9', [stroke(0xFF0000B1), stroke(0xFF0000B2, y: 2.5)]);
    await db.doc('users/u1/notes/$id').update({
      'inkV': 2,
      'attachments': [
        {'id': 'a9', 'kind': 'pdf', 'fileName': 'y.pdf'},
      ],
    });
    final n = (await repo
        .watchNote(id)
        .firstWhere(
          (n) => n != null && n.attachments.isNotEmpty && !n.heavyMissing,
        ))!;
    expect(n.attachments.single.ink.map((s) => s.color), [
      0xFF0000B1,
      0xFF0000B2,
    ]);
  });

  test(
    'hydrate v2 mürekkebi doldurur; hafif liste notu eksik sayılır',
    () async {
      final id = await repo.createNote(NoteType.text);
      await putInk(id, kPageInkId, [stroke(0xFF000007)]);
      await db.doc('users/u1/notes/$id').update({
        'inkV': 2,
        'attachments': [
          {'id': kPageInkId, 'kind': 'pageInk'},
        ],
      });
      final light = (await repo.watchNotes().first).firstWhere(
        (n) => n.id == id,
      );
      expect(light.pageInk, isEmpty);
      expect(needsHydrate(light), isTrue);
      final full = await repo.hydrate(light);
      expect(full.pageInk.single.color, 0xFF000007);
      expect(needsHydrate(full), isFalse);
    },
  );

  test('bozuk / bilinmeyen sürümlü belge atlanır, çökme yok', () async {
    final id = await repo.createNote(NoteType.text);
    await putInk(id, kPageInkId, [stroke(0xFF000008)]);
    await db.doc('users/u1/notes/$id/$kInkCollection/$kPageInkId~1~5').set({
      'v': 9,
      'b': Blob(encodeInkPack([stroke(1)])),
    });
    await db.doc('users/u1/notes/$id/$kInkCollection/$kPageInkId~1~6').set({
      'v': 1,
      'b': Blob(Uint8List.fromList([1, 2, 3])),
    });
    await db.doc('users/u1/notes/$id').update({'inkV': 2});
    final n = (await repo
        .watchNote(id)
        .firstWhere((n) => n != null && n.pageInk.isNotEmpty))!;
    expect(n.pageInk.single.color, 0xFF000008);
  });

  test('InkDocCache: değişmeyen yüzey aynı liste örneği', () {
    final cache = InkDocCache();
    final order = InkOrder();
    final a = planInkDocs(surface: 'a', strokes: [stroke(1)], order: order);
    final b = planInkDocs(surface: 'b', strokes: [stroke(2)], order: order);
    final first = cache.apply({...a, ...b}, order);
    final b2 = planInkDocs(surface: 'b', strokes: [stroke(3)], order: order);
    final second = cache.apply({...a, ...b2}, order);
    expect(identical(first['a'], second['a']), isTrue);
    expect(second['b']!.single.color, 3);
    final third = cache.apply(a, order);
    expect(third.containsKey('b'), isFalse);
  });
}
