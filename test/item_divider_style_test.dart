import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';

/// Madde altı çizginin biçimi (kullanıcı isteği 2026-10-23: "çizgi rengi ve
/// özelliklerini ayarlama") `NoteItem.divider` dizesinde saklanır.
void main() {
  test('yalnız tür: dize eskisiyle aynı (eski sürüm birebir okur)', () {
    const style = ItemDivider(NoteItem.dividerDashed);
    expect(style.encode(), 'dashed');
    expect(ItemDivider.parse('dashed')!.kind, NoteItem.dividerDashed);
    expect(ItemDivider.parse('dashed')!.color, isNull);
  });

  test('renk ve kalınlık gidiş-dönüşte korunur', () {
    const style = ItemDivider(
      NoteItem.dividerWavy,
      color: 0xFFE53935,
      weight: 2.5,
    );
    final back = ItemDivider.parse(style.encode())!;
    expect(back.kind, NoteItem.dividerWavy);
    expect(back.color, 0xFFE53935);
    expect(back.weight, closeTo(2.5, 1e-9));
  });

  test('boş dize çizgi yok; bozuk kalınlık sınıra çekilir', () {
    expect(ItemDivider.parse(''), isNull);
    expect(ItemDivider.parse('solid|w:99')!.weight, ItemDivider.maxWeight);
    expect(ItemDivider.parse('solid|w:x')!.weight, 1);
  });

  test('madde kaydında biçimli çizgi aynen yazılır', () {
    const item = NoteItem(id: 'a', text: 'x', divider: 'double|c:FF1E88E5');
    expect(NoteItem.fromMap(item.toMap()).divider, 'double|c:FF1E88E5');
  });
}
