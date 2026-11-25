import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// P62 PA4 (plan_tasarim_A §2.2 "yan ekranlar", bulgu A12): yan ekranlarda ham
// `Card` yok — grup yüzeyi (`GroupCard` / `AppSurface.group`) kullanılır.
const _files = [
  'lib/features/settings/presentation/privacy_screen.dart',
  'lib/features/settings/presentation/guide_screen.dart',
  'lib/features/settings/presentation/backup_ui.dart',
  'lib/features/friends/presentation/friends_screen.dart',
  'lib/features/auth/presentation/account_required.dart',
  'lib/features/entitlement/presentation/pro_screen.dart',
];

void main() {
  test('yan ekranlarda ham Card yok', () {
    final raw = RegExp(r'(^|[^A-Za-z_])Card\(');
    final hits = <String>[];
    for (final p in _files) {
      final lines = File(p).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (raw.hasMatch(lines[i])) hits.add('$p:${i + 1}');
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
