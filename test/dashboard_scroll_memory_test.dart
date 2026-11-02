import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/dashboard_scroll_memory.dart';

/// F18.11: genişlik değişince liste aynı bölgede kalır.
void main() {
  setUp(DashboardScrollMemory.clear);

  test('aynı bölümde oranla yeni düzene taşınır', () {
    DashboardScrollMemory.save('all', 3000, 6000); // dar: 1 sütun
    // Geniş ekranda 2 sütun → liste yarı uzunlukta.
    expect(DashboardScrollMemory.restoreOffset('all', 3000), 1500);
  });

  test('başka bölümde ya da tepede dönülmez', () {
    DashboardScrollMemory.save('all', 3000, 6000);
    expect(DashboardScrollMemory.restoreOffset('folder:x', 3000), isNull);
    DashboardScrollMemory.save('all', 0, 6000);
    expect(DashboardScrollMemory.restoreOffset('all', 3000), isNull);
  });
}
