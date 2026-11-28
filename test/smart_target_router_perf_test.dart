import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/smart_target_router.dart';

/// Hızlı ekle donması (kullanıcı 2026-11-28: "hızlı ekle yaparken uygulama
/// aşırı donuyor, çöküyor"): her harfte / her dikte kısmi sonucunda
/// [SmartTargetRouter] bütün adayların bütün maddelerini baştan normalize
/// ediyordu (400+ maddeli notlarda kare başına yüzlerce ms). Not başına
/// özellik önbelleği ile aynı notlarla ikinci ve sonraki çağrılar ucuz olmalı.
void main() {
  List<Note> bigPool() => [
    for (var n = 0; n < 40; n++)
      Note(
        id: 'n$n',
        type: NoteType.checklist,
        title: n == 0 ? 'Alışveriş' : 'Not $n proje kanal site',
        listMode: n == 0 ? ListMode.shopping : ListMode.general,
        items: [
          for (var i = 0; i < 400; i++)
            NoteItem(
              id: '$n-$i',
              text: 'Madde $i görünüm düzenlemesi yapılmalı (${i % 7})',
              checked: i.isEven,
            ),
        ],
      ),
  ];

  test('40 not × 400 madde: yazarken (ısınmış) yönlendirme + bölme ucuz', () {
    final pool = bigPool();
    const typed = 'notlarda geliştirmeler yapılmalı, süt al ve ekmek';
    // Isınma: ilk çağrı önbelleği doldurur.
    SmartTargetRouter.route(typed, pool, locale: 'tr');
    MultiIntentSplitter.split(typed, pool, locale: 'tr');

    final sw = Stopwatch()..start();
    for (var k = 1; k <= typed.length; k++) {
      final prefix = typed.substring(0, k);
      MultiIntentSplitter.split(prefix, pool, locale: 'tr');
      SmartTargetRouter.route(prefix, pool, locale: 'tr');
    }
    final perKey = sw.elapsedMicroseconds / typed.length / 1000;
    // ignore: avoid_print
    print('yonlendirme harf basina: ${perKey.toStringAsFixed(2)} ms');
    // Test makinesi telefondan ~3-5× hızlı; 8 ms burada ≈ bir kare telefonda.
    expect(perKey, lessThan(8));
  });
}
