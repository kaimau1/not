import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/editor_bar_layout.dart';

/// Editörün alt çubuğu taşmak yerine sığar (bkz. [planEditorBar]).
///
/// F75.1 (K-D6): Paylaş kapsülden çıktı, Kalem sabit segment. Metin notunun
/// sabitleri: Biçim · Ekle · Kalem · ☑ = 4. Genişlik = ekran − 24
/// (BottomAppBar dolgusu).
void main() {
  /// Planın gerçekten SIĞDIĞI: sol kapsül + boşluk + sağ kapsül ≤ genişlik
  /// (planEditorBar'ın kendi hesabının bağımsız tekrarı).
  double used(EditorBarPlan plan, {required int fixed, bool files = false}) {
    final n = fixed + (plan.search ? 1 : 0);
    return 8 +
        n * kEditorBarSegment +
        (n - 1) * kEditorBarSegmentGap +
        (files ? 52 + kEditorBarSegmentGap : 0) +
        8 +
        (8 + 3 * plan.button + 2 * plan.gap);
  }

  test('geniş ekranda her şey tam boy', () {
    final plan = planEditorBar(width: 600, fixedSegments: 4, attachments: true);
    expect(plan, (button: 44.0, gap: 2.0, search: true));
  });

  test('412 dp: ekler yokken tam boy; ekliyken Ara çıkar, taşma yok', () {
    const width = 412.0 - 24;
    final plain = planEditorBar(
      width: width,
      fixedSegments: 4,
      attachments: false,
    );
    expect(plain, (button: 44.0, gap: 2.0, search: true));
    expect(used(plain, fixed: 4), lessThanOrEqualTo(width));

    final files = planEditorBar(
      width: width,
      fixedSegments: 4,
      attachments: true,
    );
    expect(files, (button: 40.0, gap: 2.0, search: false));
    expect(used(files, fixed: 4, files: true), lessThanOrEqualTo(width));
  });

  test('393 dp: önce düğmeler küçülür, ekliyken Ara çıkar; taşma yok', () {
    const width = 393.0 - 24;
    final plain = planEditorBar(
      width: width,
      fixedSegments: 4,
      attachments: false,
    );
    expect(plain, (button: 40.0, gap: 2.0, search: true));
    expect(used(plain, fixed: 4), lessThanOrEqualTo(width));

    final files = planEditorBar(
      width: width,
      fixedSegments: 4,
      attachments: true,
    );
    expect(files, (button: 36.0, gap: 2.0, search: false));
    expect(used(files, fixed: 4, files: true), lessThanOrEqualTo(width));
  });

  test('360 dp: Ara çıkar, Kalem kalır; taşma yok', () {
    const width = 360.0 - 24;
    final plain = planEditorBar(
      width: width,
      fixedSegments: 4,
      attachments: false,
    );
    expect(plain, (button: 40.0, gap: 2.0, search: false));
    expect(used(plain, fixed: 4), lessThanOrEqualTo(width));
    // Liste/belge notu (Biçim · Ekle · Kalem) + ekler de sığar.
    final files = planEditorBar(
      width: width,
      fixedSegments: 3,
      attachments: true,
    );
    expect(used(files, fixed: 3, files: true), lessThanOrEqualTo(width));
  });

  test('çok dar pencerede en sıkı plan (kapsül kendi içinde kayar)', () {
    final plan = planEditorBar(width: 200, fixedSegments: 4, attachments: true);
    expect(plan, (button: 36.0, gap: 2.0, search: false));
  });
}
