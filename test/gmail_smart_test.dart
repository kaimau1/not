import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/gmail/domain/gmail_smart.dart';

void main() {
  final now = DateTime(2026, 11, 8);

  test('sayısal tarih + saat', () {
    final r = findSmartDates('Toplantı 12.11.2026 saat 14:30 odada', now);
    expect(r.single.when, DateTime(2026, 11, 12, 14, 30));
    expect(r.single.hasTime, isTrue);
  });

  test('adlı ay, yılsız; saatsiz', () {
    final r = findSmartDates('Teslim: 20 Kasım', now);
    expect(r.single.when, DateTime(2026, 11, 20));
    expect(r.single.hasTime, isFalse);
  });

  test('ISO, yinelenen tek; geçersiz tarih atlanır', () {
    final r = findSmartDates('2026-12-01 ve 01.12.2026 ve 31.02.2026', now);
    expect(r.map((e) => e.when), [DateTime(2026, 12)]);
  });

  test('geride kalan yılsız tarih gelecek yıla kayar', () {
    final r = findSmartDates('3 Ocak', now);
    expect(r.single.when, DateTime(2027, 1, 3));
  });

  test('gönderen ayrıştırma', () {
    expect(parseSender('Ali Veli <a@b.co>')?.email, 'a@b.co');
    expect(parseSender('Ali Veli <a@b.co>')?.name, 'Ali Veli');
    expect(parseSender('yok'), isNull);
  });
}
