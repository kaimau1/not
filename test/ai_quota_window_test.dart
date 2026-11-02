import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';

void main() {
  final now = DateTime(2026, 11, 2, 12);
  test('pencere açıksa başlangıç + 24 saat', () {
    expect(
      aiQuotaRenewsAt(DateTime(2026, 11, 2, 9, 30), now),
      DateTime(2026, 11, 3, 9, 30),
    );
  });
  test('pencere bitmişse ya da bilinmiyorsa null', () {
    expect(aiQuotaRenewsAt(DateTime(2026, 11, 1, 11), now), isNull);
    expect(aiQuotaRenewsAt(null, now), isNull);
  });
}
