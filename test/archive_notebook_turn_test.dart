import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/archive_semantic_search.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_note_screen.dart';

/// **SAYFA ÇEVİRMENİN GÖRSEL MANTIĞI** (kullanıcı bulgusu 2026-09-06:
/// "defterde sayfa çevirme animasyonu ters").
///
/// Gerçek defterde gelecek sayfa zaten AÇIK SAYFANIN ALTINDA düz durur;
/// hareket eden yaprak elden bırakılan ESKİ sayfadır. Önceki sürüm bunun
/// tersini yapıyordu (dönen yaprak gelecek sayfaydı) ve ileri gitmek geri
/// dönüyormuş gibi görünüyordu. Kural artık tek cümle ve ölçülüyor: **dönen
/// yaprak geride kalan sayfadır; gelecek sayfa yalnız boşalan şeritten
/// görünür.**
void main() {
  group('archivePageTurn', () {
    test('açık sayfa (t=0) düz durur ve tamamı görünür', () {
      final state = archivePageTurn(0);
      expect(state.visible, isTrue);
      expect(state.angle, 0);
      expect(state.revealFrom, 0);
    });

    test('GERİDE KALAN yaprak döner ve açı t ile büyür', () {
      final quarter = archivePageTurn(-0.25);
      final half = archivePageTurn(-0.5);
      expect(quarter.angle, greaterThan(0));
      expect(half.angle, greaterThan(quarter.angle));
      expect(half.angle, lessThan(math.pi / 2));
    });

    test('GELECEK sayfa dönmez — yalnız boşalan şeritten görünür', () {
      for (final t in [0.1, 0.5, 0.9]) {
        final state = archivePageTurn(t);
        expect(state.visible, isTrue, reason: 't=\$t görünmeli');
        expect(state.angle, 0, reason: 't=\$t dönmemeli');
      }
      // Çevirme ilerledikçe (t küçüldükçe) şerit genişler: kırpma sınırı
      // sayfanın soluna doğru kayar.
      expect(
        archivePageTurn(0.2).revealFrom,
        lessThan(archivePageTurn(0.8).revealFrom),
      );
    });

    test('çevirme başlarken gelecek sayfa TÜMÜYLE örtülü', () {
      // t=1'e yakın: kalkan yaprak henüz düz, altındaki sayfa görünmemeli.
      expect(archivePageTurn(0.99).revealFrom, closeTo(1, 0.01));
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
      expect(turning, [0]);
    });
  });

  group('archiveTurnEdge', () {
    test('düz yaprak altındaki sayfayı TÜMÜYLE örter', () {
      expect(archiveTurnEdge(0), closeTo(1, 0.001));
    });

    test('ilerleme boyunca tek yönlü daralır — sıçrama yok', () {
      var previous = archiveTurnEdge(0);
      for (var i = 1; i <= 40; i++) {
        final value = archiveTurnEdge(i / 40);
        expect(
          value,
          lessThanOrEqualTo(previous + 1e-9),
          reason: 'ilerleme \${i / 40} sınırı geri genişletmemeli',
        );
        previous = value;
      }
    });

    test('sonunda ŞERİT KALMAZ: kenar sıfıra iner', () {
      // Cilt kenarındaki ince açık şerit hatası (2026-09-02) böyle eriyor.
      expect(archiveTurnEdge(1), 0);
      expect(archiveTurnEdge(0.95), lessThan(0.1));
    });

    test('menzil dışı ilerleme kırpılır', () {
      expect(archiveTurnEdge(-1), closeTo(1, 0.001));
      expect(archiveTurnEdge(2), 0);
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
