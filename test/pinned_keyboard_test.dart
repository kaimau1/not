import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';

/// Kullanıcı bulgusu 2026-10-19: "video sabitken klavye açıldığında video
/// yukarı itiliyor biraz". Sınır o anki yükseklikten alındığı için klavye
/// oturunca bölme büzülüyordu.
void main() {
  test('klavyesiz: eski sınır (%70)', () {
    expect(pinnedMaxHeight(available: 800, stable: 800), closeTo(560, 0.01));
  });

  test('klavye açık: bölme YERİNDE kalır, not satırına yer bırakır', () {
    // Eskiden 0.7 × 480 = 336'ya düşerdi; 380 dp'lik video küçülürdü.
    final max = pinnedMaxHeight(available: 480, stable: 800);
    expect(max, 480 - kPinnedBarHeight - kPinnedNoteMinHeight);
    expect(max, greaterThan(480 * kPinnedMaxFraction));
  });

  test('çok dar alanda bile en küçük yükseklik korunur', () {
    expect(pinnedMaxHeight(available: 150, stable: 800), kPinnedMinHeight);
  });
}
