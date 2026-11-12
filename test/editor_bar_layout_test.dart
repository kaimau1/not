import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/editor_bar_layout.dart';

/// Editörün alt çubuğu taşmak yerine sığar (bkz. [planEditorBar]).
///
/// F75.1 (K-D6): Paylaş kapsülden çıktı, yerine Kalem geldi. Metin notunun
/// sabitleri Biçim · Ekle · ☑ = 3 (+ Kalem, + Ara plandan). Genişlik =
/// ekran − 24 (BottomAppBar dolgusu).
void main() {
  /// Planın gerçekten SIĞDIĞI: sol kapsül + boşluk + sağ kapsül ≤ genişlik
  /// (planEditorBar'ın kendi hesabının bağımsız tekrarı).
  double used(EditorBarPlan plan, {bool files = false}) {
    final n = 3 + (plan.search ? 1 : 0) + (plan.pen ? 1 : 0);
    return 8 +
        n * kEditorBarSegment +
        (n - 1) * kEditorBarSegmentGap +
        (files ? 52 + kEditorBarSegmentGap : 0) +
        8 +
        (8 + 3 * plan.button + 2 * plan.gap);
  }

  EditorBarPlan plan(double screen, {required bool files}) =>
      planEditorBar(width: screen - 24, fixedSegments: 3, attachments: files);

  test('geniş ekranda her şey tam boy', () {
    expect(plan(624, files: true), (
      button: 44.0,
      gap: 2.0,
      search: true,
      pen: true,
    ));
  });

  test('412 dp: ekler yokken tam boy; ekliyken Ara çıkar', () {
    expect(plan(412, files: false), (
      button: 44.0,
      gap: 2.0,
      search: true,
      pen: true,
    ));
    expect(plan(412, files: true), (
      button: 40.0,
      gap: 2.0,
      search: false,
      pen: true,
    ));
  });

  test('393 dp: önce düğmeler küçülür, ekliyken Ara çıkar', () {
    expect(plan(393, files: false), (
      button: 40.0,
      gap: 2.0,
      search: true,
      pen: true,
    ));
    expect(plan(393, files: true), (
      button: 36.0,
      gap: 2.0,
      search: false,
      pen: true,
    ));
  });

  test('360 dp: Ara çıkar, Kalem kalır; ekliyken Kalem de çıkar', () {
    expect(plan(360, files: false), (
      button: 40.0,
      gap: 2.0,
      search: false,
      pen: true,
    ));
    expect(plan(360, files: true), (
      button: 40.0,
      gap: 2.0,
      search: false,
      pen: false,
    ));
  });

  test('360 / 393 / 412 dp: taşma yok (ekli ve eksiz)', () {
    for (final screen in [360.0, 393.0, 412.0]) {
      for (final files in [false, true]) {
        expect(
          used(plan(screen, files: files), files: files),
          lessThanOrEqualTo(screen - 24),
          reason: '$screen dp, ek: $files',
        );
      }
    }
  });

  test('kalem istenmiyorsa (gizli / salt okunur) planda da yok', () {
    final plan = planEditorBar(
      width: 600,
      fixedSegments: 3,
      attachments: false,
      pen: false,
    );
    expect(plan.pen, isFalse);
  });

  test('çok dar pencerede en sıkı plan (kapsül kendi içinde kayar)', () {
    final plan = planEditorBar(width: 200, fixedSegments: 3, attachments: true);
    expect(plan, (button: 36.0, gap: 2.0, search: false, pen: false));
  });
}
