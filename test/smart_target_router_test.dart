import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/smart_target_router.dart';

void main() {
  final candidates = [
    const Note(
      id: 'shop',
      type: NoteType.checklist,
      title: 'Alışveriş',
      listKind: 'shopping',
      listMode: ListMode.shopping,
      items: [NoteItem(id: 's1', text: 'Elma')],
    ),
    const Note(
      id: 'routine',
      type: NoteType.checklist,
      title: 'Günlük Rutin',
      listKind: 'habits',
      listMode: ListMode.routine,
      items: [NoteItem(id: 'r1', text: 'Su iç')],
    ),
    const Note(
      id: 'project',
      type: NoteType.checklist,
      title: 'Proje Görevleri',
      listMode: ListMode.project,
      items: [NoteItem(id: 'p1', text: 'Sunum hazırla')],
    ),
    const Note(
      id: 'random',
      type: NoteType.text,
      title: 'Günlük Düşünceler',
      body: 'Rastgele not',
    ),
  ];

  group('SmartTargetRouter', () {
    test('tek market ürünü ("süt al") yüksek güvenle Alışveriş listesine yönlenir', () {
      final r = SmartTargetRouter.route('süt al', candidates, locale: 'tr');
      expect(r.isQuickInbox, isFalse);
      expect(r.noteId, 'shop');
      expect(r.confidence, greaterThanOrEqualTo(SmartTargetRouter.autoThreshold));
      expect(r.content.toLowerCase(), 'süt');
    });

    test('düşük güvenli alakasız ifade son nota değil Hızlı Not\'a düşer', () {
      final r = SmartTargetRouter.route(
        'mavi gökyüzü çok huzurlu',
        candidates,
        locale: 'tr',
      );
      expect(r.isQuickInbox, isTrue);
      expect(r.noteId, isNull);
      expect(r.confidence, lessThan(SmartTargetRouter.autoThreshold));
    });

    test('kilitli not asla aday veya hedef olmaz', () {
      final lockedOnly = [
        const Note(
          id: 'secret-shop',
          type: NoteType.checklist,
          title: 'Alışveriş',
          listMode: ListMode.shopping,
          locked: true,
        ),
      ];
      final r = SmartTargetRouter.route('süt al', lockedOnly, locale: 'tr');
      expect(r.isQuickInbox, isTrue);
      expect(r.noteId, isNull);
    });
  });

  group('MultiIntentSplitter', () {
    test('tek nefeste 3 farklı niyeti 3 ayrı listeye böler', () {
      final segments = MultiIntentSplitter.split(
        'süt al, yarın su iç, proje dosyasını kontrol et',
        candidates,
        locale: 'tr',
      );
      expect(segments, hasLength(3));
      expect(segments[0].noteId, 'shop');
      expect(segments[0].content.toLowerCase(), 'süt');
      expect(segments[1].noteId, 'routine');
      expect(segments[1].content, contains('su iç'));
      expect(segments[2].noteId, 'project');
      expect(segments[2].content, contains('proje'));
    });

    test('aynı hedefe giden çoklu ürünler bölünmez', () {
      final segments = MultiIntentSplitter.split(
        'süt, ekmek, yumurta',
        candidates,
        locale: 'tr',
      );
      expect(segments, isEmpty);
    });
  });
}
