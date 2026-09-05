import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/archive_semantic_search.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_note_screen.dart';

/// **SAYFA ÇEVİRMENİN GÖRSEL MANTIĞI** (kullanıcı bulgusu 2026-09-04:
/// "sayfa çevirirken sanki görsel mantık hatası var, ileri ve geri aynı
/// şekilde oluyor").
///
/// Eski sürümde İKİ yaprak birden, birbirinin aynası olacak biçimde
/// dönüyordu; ekranda sayfa çevrilmiyor, iki kâğıt akordeon gibi açılıp
/// kapanıyordu. Kural artık tek cümle ve ölçülüyor: **dönen yaprak her
/// zaman gelecek sayfadır.**
void main() {
  group('archivePageTurn', () {
    test('açık sayfa (t=0) düz durur', () {
      final state = archivePageTurn(0);
      expect(state.visible, isTrue);
      expect(state.angle, 0);
    });

    test('GEÇMİŞ yapraklar düz durur — dönen yaprağın altında', () {
      for (final t in [-0.1, -0.5, -0.9]) {
        final state = archivePageTurn(t);
        expect(state.visible, isTrue, reason: 't=$t görünmeli');
        expect(state.angle, 0, reason: 't=$t dönmemeli');
      }
    });

    test('GELECEK yaprak döner ve açı t ile büyür', () {
      final quarter = archivePageTurn(0.25);
      final half = archivePageTurn(0.5);
      expect(quarter.angle, greaterThan(0));
      expect(half.angle, greaterThan(quarter.angle));
      expect(half.angle, lessThan(math.pi / 2));
    });

    test('menzil dışındaki yapraklar HİÇ çizilmez (cilt kenarındaki şerit)', () {
      expect(archivePageTurn(1).visible, isFalse);
      expect(archivePageTurn(-1).visible, isFalse);
      expect(archivePageTurn(2).visible, isFalse);
      expect(archivePageTurn(-3).visible, isFalse);
    });

    test('aynı anda YALNIZ BİR yaprak döner', () {
      // İleri çevirmenin ortası: konum 0 ile 1 arasında.
      const position = 0.5;
      final turning = [
        for (var index = -1; index <= 2; index++)
          if (archivePageTurn(index - position).angle != 0) index,
      ];
      expect(turning, [1]);
    });
  });

  group('archivePageCorpus', () {
    Note notebook() => Note(
      id: 'n1',
      type: NoteType.archive,
      archivePages: const ['Seyahat'],
      items: const [
        NoteItem(id: 'a', text: 'genel sayfadaki fatura'),
        NoteItem(id: 'b', title: 'Bilet', text: 'uçak bileti', section: 'Seyahat'),
      ],
    );

    test('sayfa ADI da arama metnine girer', () {
      final corpus = archivePageCorpus(
        notebook(),
        'Seyahat',
        generalLabel: 'Genel',
      );
      expect(corpus, contains('Seyahat'));
      expect(corpus, contains('Bilet'));
      expect(corpus, contains('uçak bileti'));
      // Başka sayfanın içeriği KARIŞMAZ: arama sayfayı gösterecek.
      expect(corpus, isNot(contains('genel sayfadaki fatura')));
    });

    test('Genel sayfasının adı DİLDEN gelir', () {
      final corpus = archivePageCorpus(notebook(), '', generalLabel: 'Genel');
      expect(corpus, contains('Genel'));
      expect(corpus, contains('genel sayfadaki fatura'));
    });

    test('defterin tamamı sayfa SIRASINDA dizilir', () {
      final corpus = archiveCorpus(notebook(), generalLabel: 'Genel');
      expect(corpus, hasLength(2));
      expect(corpus.first, contains('Genel'));
      expect(corpus.last, contains('Seyahat'));
    });
  });

  group('ArchiveSemanticIndex.rank', () {
    Float32List v(List<double> values) =>
        ArchiveSemanticIndex.normalize(values);

    test('skora göre AZALAN sıralar ve eşiğin altını atar', () {
      final query = v([1, 0]);
      final ranked = ArchiveSemanticIndex.rank([
        v([0, 1]), // dik: skor 0 → eşiğin altında
        v([1, 0]), // birebir
        v([1, 1]), // ~0.71
      ], query);
      expect([for (final hit in ranked) hit.page], [1, 2]);
      expect(ranked.first.score, greaterThan(ranked.last.score));
    });

    test('BOŞ sayfa (vektörü olmayan) sonuçlara girmez', () {
      final ranked = ArchiveSemanticIndex.rank([null, v([1, 0])], v([1, 0]));
      expect([for (final hit in ranked) hit.page], [1]);
    });
  });
}
