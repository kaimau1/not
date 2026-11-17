import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// **EŞİTLEME DAMGASI BEKÇİSİ** (P67 / S1, 2026-11-17).
///
/// "Yalnız değişeni dinle" açıkken ana liste sunucudan yalnız
/// `syncAt > son görülen` belgeleri çeker. Bir yazım yolu `syncAt` koymazsa
/// o değişiklik öbür cihazlarda GÖRÜNMEZ (sessiz eşitleme kaybı). Bu test her
/// yazım yolunun damgayı tazelediğini doğrular.
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;
  final old = Timestamp.fromMillisecondsSinceEpoch(1000);

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
  });

  DocumentReference<Map<String, dynamic>> ref(String id) =>
      db.collection('users').doc('u1').collection('notes').doc(id);

  /// Damgayı eskiye çeker, [op]'u koşar, damganın tazelendiğini doğrular.
  Future<void> expectStamped(
    String id,
    Future<void> Function() op, {
    required String reason,
  }) async {
    await ref(id).update({kSyncAtField: old});
    await op();
    await Future<void>.delayed(Duration.zero);
    final stamp = (await ref(id).get()).data()?[kSyncAtField];
    expect(stamp, isA<Timestamp>(), reason: reason);
    expect(stamp, isNot(old), reason: reason);
  }

  Future<Note> noteOf(String id) async => Note.fromDoc(await ref(id).get());

  test('oluşturma ve kopya damgalı doğar', () async {
    final id = await repo.createNote(NoteType.text, title: 'a');
    expect((await ref(id).get()).data()![kSyncAtField], isA<Timestamp>());
    final copyId = await repo.duplicateNote(await noteOf(id));
    expect((await ref(copyId).get()).data()![kSyncAtField], isA<Timestamp>());
  });

  test('her güncelleme yolu damgayı tazeler', () async {
    final id = await repo.createNote(NoteType.text, title: 'a');
    final b = await repo.createNote(NoteType.text, title: 'b');

    await expectStamped(id, () async {
      await repo.updateNote((await noteOf(id)).copyWith(body: 'x'));
    }, reason: 'updateNote');
    await expectStamped(id, () async {
      await repo.updateNote(
        (await noteOf(id)).copyWith(body: 'y'),
        clientTime: true,
      );
    }, reason: 'updateNote(clientTime)');
    await expectStamped(
      id,
      () => repo.updateFieldsAndWait(id, {'pinned': true}),
      reason: 'updateFieldsAndWait',
    );
    await expectStamped(id, () async {
      repo.setColor(id, NoteColor.values.last);
    }, reason: 'updateFields');
    await expectStamped(
      id,
      () => repo.batchUpdateEach({
        id: {'starred': true},
      }),
      reason: 'batchUpdateEach',
    );
    // Sıralama `updatedAt`e dokunmaz ama damgayı tazelemeli.
    await expectStamped(id, () async {
      final notes = [await noteOf(b), await noteOf(id)];
      repo.reorderNotes(notes);
    }, reason: 'reorderNotes');
    await expectStamped(
      id,
      () => repo.softDeleteAll([id]),
      reason: 'çöpe atma (silme delta sorgusuna girmeli)',
    );
    await expectStamped(
      id,
      () => repo.restoreAll([id]),
      reason: 'geri yükleme',
    );
    await expectStamped(
      id,
      () => repo.setArchivedAll([id], true),
      reason: 'arşiv',
    );
  });

  test('ek yolları (işlem içi yazım) damgayı tazeler', () async {
    final id = await repo.createNote(NoteType.text, title: 'a');
    final att = Attachment(
      id: 'e1',
      kind: AttachmentKind.image,
      fileName: 'a.png',
      mimeType: 'image/png',
      sizeBytes: 1,
      createdAt: DateTime(2026),
    );
    await expectStamped(
      id,
      () => repo.appendAttachments(id, [att]),
      reason: 'appendAttachments',
    );
    await expectStamped(
      id,
      () => repo.patchAttachment(id, att),
      reason: 'patchAttachment',
    );
    await expectStamped(
      id,
      () => repo.patchAttachmentSync(id, 'e1', {'s': 1}),
      reason: 'patchAttachmentSync',
    );
  });

  test('kaynak bekçisi: depodaki her bulut yazımı damga taşır', () {
    // Paylaşılan yolda kural `updatedBy` istiyor → depodaki her not yazımı
    // `updatedBy` taşır. Her birinin yanında damga da olmalı.
    final src = File('lib/features/notes/data/notes_repository.dart')
        .readAsStringSync();
    final writes = RegExp(r"'updatedBy': editorUid,").allMatches(src).length;
    final stamps = RegExp(
      r"'updatedBy': editorUid,\s*kSyncAtField: FieldValue\.serverTimestamp\(\)",
    ).allMatches(src).length;
    expect(writes, greaterThan(5));
    expect(stamps, writes, reason: 'damgasız not yazımı var');
    // Kotlin köprüsü de not yazar.
    for (final path in [
      'android/app/src/main/kotlin/dev/kaimau/notlar/YerelNot.kt',
      'android/app/src/kisisel/kotlin/dev/kaimau/notlar/HaritaNotlari.kt',
    ]) {
      final kt = File(path).readAsStringSync();
      final updatedAt = '"updatedAt" to FieldValue.serverTimestamp()'
          .allMatchesIn(kt);
      final syncAt = '"syncAt" to FieldValue.serverTimestamp()'.allMatchesIn(
        kt,
      );
      expect(syncAt, updatedAt, reason: '$path: damgasız yazım');
    }
  });
}

extension on String {
  int allMatchesIn(String s) =>
      RegExp(RegExp.escape(this)).allMatches(s).length;
}
