import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spoken_repeat.dart';
import 'package:notlar/features/notes/domain/reminder_repeat.dart';

void main() {
  final mon = DateTime(2026, 11, 2, 9); // pazartesi
  String p(String s) => parseSpokenRepeat(s, mon).encode();

  test('Türkçe', () {
    expect(p("her pazartesi 9'da toplantı"), 'weekly:1');
    expect(p('her cumartesi ve pazar spor'), 'weekly:6,7');
    expect(p('her cuma'), 'weekly:5');
    expect(p('her gün ilaç'), 'daily');
    expect(p('hafta içi her gün 8de'), 'weekdays');
    expect(p('her hafta rapor'), 'weekly:1');
    expect(p('her ay kira'), 'monthly:2');
    expect(p('her yıl doğum günü'), 'yearly:11-2');
    expect(p("yarın 9'da toplantı"), '');
    expect(p('herkese mesaj at'), '');
  });

  test('English', () {
    expect(p('every monday at 9'), 'weekly:1');
    expect(p('every day'), 'daily');
    expect(p('every weekday standup'), 'weekdays');
    expect(p('pay rent every month'), 'monthly:2');
    expect(p('tomorrow at 9'), '');
    expect(parseSpokenRepeat('every year', mon), isA<ReminderRepeat>());
  });
}
