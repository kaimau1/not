import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BİLDİRİM YOLLARI MANDALI (P62 PA5, docs/plan_tasarim_A.md §5.3): geçici
/// bildirimler `appNotice` hunisinden geçer. Sayılar YALNIZ DÜŞER; çitte
/// (P63: editor/**, note_template_sheet) kalan ham `showSnackBar`lar PA9'da
/// sıfırlanır.
void main() {
  Iterable<File> dartFiles() =>
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

  test('undo_snackbar.dart dışında ham showSnackBar ≤ 9', () {
    final hits = <String>[];
    for (final f in dartFiles()) {
      if (f.path.replaceAll('\\', '/').endsWith('undo_snackbar.dart')) {
        continue;
      }
      final n = 'showSnackBar('.allMatches(f.readAsStringSync()).length;
      if (n > 0) hits.add('${f.path}: $n');
    }
    final total = hits.fold<int>(
      0,
      (s, h) => s + int.parse(h.split(': ').last),
    );
    expect(total, lessThanOrEqualTo(9), reason: hits.join('\n'));
  });

  test('tips.dart OverlayEntry kullanmaz', () {
    expect(
      File('lib/core/tips.dart').readAsStringSync().contains('OverlayEntry'),
      isFalse,
    );
  });

  test('app.dart tam bir AppNoticeHost kurar', () {
    final src = File('lib/app/app.dart').readAsStringSync();
    expect('AppNoticeHost('.allMatches(src).length, 1);
  });
}
