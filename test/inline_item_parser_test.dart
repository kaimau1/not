import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/inline_item_parser.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';

void main() {
  final refNow = DateTime(2026, 11, 27, 8, 30);

  group('InlineItemParser', () {
    test('miktar + birim ("2 kg domates") ayrıştırır ve alışveriş reyonunu çözer', () {
      final parsed = InlineItemParser.parse(
        '2 kg domates',
        mode: ListMode.shopping,
        now: refNow,
      );
      expect(parsed.title, 'Domates');
      expect(parsed.quantity, 2.0);
      expect(parsed.unit, 'kg');
      expect(parsed.category, 'produce');

      final item = parsed.toNoteItem(id: 'i1');
      expect(item.text, 'Domates');
      expect(item.quantity, 2.0);
      expect(item.unit, 'kg');
      expect(item.category, 'produce');
    });

    test('açık para birimli fiyatı ("kahve 180 tl") yakalar, çıplak sayıyı fiyat sanmaz', () {
      final priced = InlineItemParser.parse(
        'kahve 180 tl',
        mode: ListMode.shopping,
        now: refNow,
      );
      expect(priced.title, 'Kahve');
      expect(priced.price, 180.0);

      // Proje kipinde "Rapor 2026" ne miktar ne fiyat olarak kesilmez!
      final project = InlineItemParser.parse(
        'Rapor 2026',
        mode: ListMode.project,
        now: refNow,
      );
      expect(project.title, 'Rapor 2026');
      expect(project.quantity, isNull);
      expect(project.price, isNull);
    });

    test('tarih/saat ("yarın 10:00 kargo"), #etiket ve !öncelik ayrıştırır', () {
      final parsed = InlineItemParser.parse(
        'yarın 10:00 kargo #ev !acil',
        mode: ListMode.project,
        now: refNow,
      );
      expect(parsed.title, 'Kargo');
      expect(parsed.dueDate, DateTime(2026, 11, 28, 10));
      expect(parsed.hasDueTime, isTrue);
      expect(parsed.priority, ItemPriority.urgent);
      expect(parsed.tags, ['ev']);

      // Kullanıcı çipi kapatırsa (dismissed) alan uygulanmaz.
      final dismissed = parsed.toNoteItem(
        id: 'i2',
        dismissed: const {InlineParsedChipKind.dueDate},
      );
      expect(dismissed.dueDate, isNull);
      expect(dismissed.priority, ItemPriority.urgent);
    });
  });
}
