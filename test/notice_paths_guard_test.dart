import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BİLDİRİM YOLLARI MANDALI (P62 PA5, docs/plan_tasarim_A.md §5.3): geçici
/// bildirimler `appNotice` hunisinden geçer. Sayılar YALNIZ DÜŞER; çitte
/// (P63: editor/**, note_template_sheet) kalan 9 ham `showSnackBar` PA9'da
/// (2026-11-15) `showMessage`'a çevrildi → 0.
void main() {
  Iterable<File> dartFiles() =>
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

  test('undo_snackbar.dart dışında ham showSnackBar yok', () {
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
    expect(total, 0, reason: hits.join('\n'));
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
