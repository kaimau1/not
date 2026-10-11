import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/editor_bar_layout.dart';

/// Editörün alt çubuğu taşmak yerine sığar (bkz. [planEditorBar]).
void main() {
  test('geniş ekranda her şey tam boy', () {
    final plan = planEditorBar(
      width: 600,
      fixedSegments: 3,
      attachments: true,
      pen: false,
    );
    expect(plan, (button: 44.0, gap: 2.0, search: true, share: true));
  });

  test('393 dp telefonda önce düğmeler küçülür, sonra Paylaş çıkar', () {
    // 393 − 24 (BottomAppBar dolgusu) = 369.
    final fits = planEditorBar(
      width: 369,
      fixedSegments: 3,
      attachments: false,
      pen: false,
    );
    expect(fits.button, 40);
    expect(fits.search, isTrue);
    expect(fits.share, isTrue);

    final withFiles = planEditorBar(
      width: 369,
      fixedSegments: 3,
      attachments: true,
      pen: false,
    );
    expect(withFiles.share, isFalse);
  });

  test('ekran görüntüsündeki durum (411 dp, 5 segment) sığar', () {
    final plan = planEditorBar(
      width: 411 - 24,
      fixedSegments: 3,
      attachments: false,
      pen: false,
    );
    expect(plan.search && plan.share, isTrue);
  });

  test('çok dar pencerede en sıkı plan', () {
    final plan = planEditorBar(
      width: 200,
      fixedSegments: 3,
      attachments: true,
      pen: true,
    );
    expect(plan, (button: 40.0, gap: 2.0, search: false, share: false));
  });
}
