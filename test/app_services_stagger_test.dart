import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app_services.dart';
import 'package:notlar/app/router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/share_intake.dart';
import 'package:notlar/features/notes/presentation/lock/note_lock_ui.dart';

/// F25.3 (AKICILIK_PLANI, K8): arka plan servisleri ilk karede birden
/// başlamaz — güvenlik/gezinme kapıları ilk karede, gerisi sonraki karelerde
/// birer birer.
void main() {
  testWidgets('kademeler ilk kareden sonra, kare başına bir tane', (
    tester,
  ) async {
    var frame = 0;
    final started = <int, int>{}; // kademe → başladığı kare
    final immediate = <String>[];
    final stages = [
      for (var i = 0; i < 4; i++)
        (WidgetRef ref) => started.putIfAbsent(i, () => frame),
    ];
    debugAppServicesStages = stages;
    addTearDown(() => debugAppServicesStages = null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUidProvider.overrideWithValue('u1'),
          noteLockBinderProvider.overrideWith((ref) => immediate.add('lock')),
          deepLinkHandlerProvider.overrideWith((ref) => immediate.add('link')),
          shareIntakeProvider.overrideWith((ref) => immediate.add('share')),
        ],
        child: const AppServices(child: SizedBox()),
      ),
    );
    expect(immediate, ['lock', 'link', 'share']);
    expect(started, isEmpty, reason: 'ilk karede kademeli servis yok');

    for (var i = 0; i < 20 && started.length < stages.length; i++) {
      frame++;
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(started.keys, [0, 1, 2, 3]);
    expect(
      started.values.toSet().length,
      stages.length,
      reason: 'her kademe ayrı karede',
    );
  });

  testWidgets('oturum yokken hiçbiri başlamaz, zamanlayıcı kalmaz', (
    tester,
  ) async {
    var count = 0;
    debugAppServicesStages = [(_) => count++];
    addTearDown(() => debugAppServicesStages = null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentUidProvider.overrideWithValue(null)],
        child: const AppServices(child: SizedBox()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(count, 0);
  });
}
