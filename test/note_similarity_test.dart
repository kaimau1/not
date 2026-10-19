import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_similarity.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

Note note(
  String id,
  String body, {
  DateTime? createdAt,
  bool locked = false,
  DateTime? archivedAt,
}) => Note(
  id: id,
  type: NoteType.text,
  body: body,
  locked: locked,
  archivedAt: archivedAt,
  createdAt: createdAt ?? DateTime(2026, 1, 1),
);

void main() {
  /// İki metin [threshold] eşiğinde aynı kümeye düşüyor mu (canlı yol:
  /// sayısal trigram + `similarIndexGroups`).
  bool similar(String a, String b, double threshold) => similarIndexGroups([
    trigramCodes(normalizeForCompare(a)),
    trigramCodes(normalizeForCompare(b)),
  ], threshold).isNotEmpty;

  group('benzerlik', () {
    test('aynı metin tam benzer', () {
      expect(similar('alışveriş listesi', 'alışveriş listesi', 1.0), isTrue);
    });

    test('noktalama ve büyük harf farkı benzerliği bozmaz', () {
      expect(
        similar('Süt, ekmek ve yumurta al!', 'süt ekmek ve yumurta al', 0.9),
        isTrue,
      );
    });

    test('alakasız metinler düşük skor alır', () {
      expect(
        similar(
          'yarın sabah dişçi randevusu var',
          'proje sunumu için grafik hazırla',
          0.3,
        ),
        isFalse,
      );
    });
  });

  group('kopya kümeleri', () {
    test('aynı notun iki kopyası tek kümede toplanır', () {
      final groups = duplicateNoteGroups([
        note('a', 'Markete gidince süt ekmek ve yumurta almayı unutma'),
        note('b', 'Markete gidince süt ekmek ve yumurta almayı unutma'),
        note('c', 'Pazartesi toplantısı için sunum dosyasını hazırla'),
      ]);
      expect(groups, hasLength(1));
      expect(groups.first.map((n) => n.id), containsAll(['a', 'b']));
      expect(duplicateCount(groups), 1);
    });

    test('üç kopya tek kümede kalır, ikisi silinebilir sayılır', () {
      const text = 'Ocak ayı bütçe toplantısı notları ve kararlar listesi';
      final groups = duplicateNoteGroups([
        note('a', text),
        note('b', text),
        note('c', text),
      ]);
      expect(groups, hasLength(1));
      expect(groups.first, hasLength(3));
      expect(duplicateCount(groups), 2);
    });

    test('farklı notlar kümelenmez', () {
      final groups = duplicateNoteGroups([
        note('a', 'Yarın sabah dokuzda dişçi randevusu var, unutma'),
        note('b', 'Proje sunumu için grafikleri hazırlamam gerekiyor'),
      ]);
      expect(groups, isEmpty);
      expect(duplicateCount(groups), 0);
    });

    test('çok kısa notlar hiç karşılaştırılmaz', () {
      // "tamam" iki kez geçse de kopya sayılmaz: kısa metinde trigram
      // örtüşmesi rastlantısaldır.
      final groups = duplicateNoteGroups([
        note('a', 'tamam'),
        note('b', 'tamam'),
      ]);
      expect(groups, isEmpty);
    });

    test('kilitli ve arşivli notlar dışarıda kalır', () {
      const text = 'Markete gidince süt ekmek ve yumurta almayı unutma';
      final groups = duplicateNoteGroups([
        note('a', text),
        note('b', text, locked: true),
        note('c', text, archivedAt: DateTime(2026, 2, 1)),
      ]);
      expect(groups, isEmpty);
    });

    test('kümenin başında EN ESKİ not durur (korunacak olan)', () {
      const text = 'Ocak ayı bütçe toplantısı notları ve kararlar listesi';
      final groups = duplicateNoteGroups([
        note('yeni', text, createdAt: DateTime(2026, 5, 1)),
        note('eski', text, createdAt: DateTime(2026, 1, 1)),
      ]);
      expect(groups.first.first.id, 'eski');
    });
  });
}
