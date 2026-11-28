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

  group('çok maddeli not (kullanıcı bulgusu 2026-11-28)', () {
    // 411 işaretli maddelik bir fikir notu: içinde "ekmek", "koy", "yeni
    // liste" gibi kısa maddeler var. Eski kural maddenin metni cümlede ALT
    // DİZGE olarak geçince 0,76 veriyordu → konuşma bu nota gidiyordu.
    final big = Note(
      id: 'notlar',
      type: NoteType.checklist,
      title: 'Notlar',
      tags: const ['yazilim'],
      items: [
        const NoteItem(id: 'b0', text: 'ekmek', checked: true),
        const NoteItem(id: 'b1', text: 'koy', checked: true),
        const NoteItem(id: 'b2', text: 'yeni liste', checked: true),
        for (var i = 3; i < 411; i++)
          NoteItem(id: 'b$i', text: 'Arka plan rengi düzeltilmeli $i', checked: true),
      ],
    );
    test('uzun cümle tek kısa madde yüzünden o nota gitmez', () {
      for (final s in [
        'Eee oraya da elma armut peynir ekmek',
        'Yeni bir alışveriş listesi oluştur ve en başa koy',
      ]) {
        final r = SmartTargetRouter.route(s, [big], locale: 'tr');
        expect(r.noteId, isNot('notlar'), reason: s);
      }
    });
    test('maddenin kendisi yine o nota gider', () {
      final r = SmartTargetRouter.route('yeni liste', [big], locale: 'tr');
      expect(r.noteId, 'notlar');
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
