import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// Uzun listenin kademeli kurulumu (`ItemsEditor._growBudget`, F60.S5 yan
/// bulgusu, 2026-11-11). Önce: 120 maddede 2'şerlik adım 52 kare sürüyor,
/// kare başı 367 → 1039 kurulum (toplam ≈ 35 bin) — erken dokunuşta klavye
/// açılışına denk gelip kasıyordu.
final _list120 = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Liste',
  items: [for (var i = 0; i < 120; i++) NoteItem(id: 'i$i', text: 'madde $i')],
);

/// Kurulumun sürdüğü kareler: kare başı kurulum sayıları (sıfırlar atılır).
Future<List<int>> _growFrames(WidgetTester tester) async {
  final counter = BuildCounter()..start();
  var prev = 0;
  int total() => counter.counts.values.fold(0, (a, b) => a + b);
  final frames = <int>[];
  for (var i = 0; i < 80; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    final t = total();
    if (t > prev) frames.add(t - prev);
    prev = t;
  }
  counter.stop();
  return frames;
}

void main() {
  tearDown(() => KeyboardInset.moving.value = false);

  testWidgets('120 madde: kademeli kurulum az karede biter', (tester) async {
    await pumpEditor(tester, _list120);
    await tester.pump(const Duration(milliseconds: 500));
    final frames = await _growFrames(tester);
    final sum = frames.fold(0, (a, b) => a + b);
    // ignore: avoid_print
    print('kademeli kurulum: ${frames.length} kare, toplam $sum, $frames');
    // Sonra (2026-11-11): 11 kare, kare başı 833 → 1393, toplam 12 243.
    expect(frames.length, lessThanOrEqualTo(14), reason: 'önce 52 kare');
    expect(sum, lessThan(15000), reason: 'önce ≈ 35 bin kurulum');
    expect(
      frames.reduce((a, b) => a > b ? a : b),
      lessThan(1600),
      reason: 'tek kare ağırlaşmasın (adım en çok 8 satır)',
    );
    expect(find.text('madde 119'), findsOneWidget);
    await endEditor(tester);
  });

  testWidgets('klavye hareket ederken kademeli kurulum bekler', (tester) async {
    await pumpEditor(tester, _list120);
    KeyboardInset.moving.value = true;
    await tester.pump(const Duration(milliseconds: 500));
    final frozen = await _growFrames(tester);
    expect(frozen, isEmpty, reason: 'klavye karelerinde satır kurulmaz');
    expect(find.text('madde 119'), findsNothing);
    KeyboardInset.moving.value = false;
    await tester.pump(const Duration(milliseconds: 200));
    await _growFrames(tester);
    expect(find.text('madde 119'), findsOneWidget);
    await endEditor(tester);
  });
}
