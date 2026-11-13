import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/haptics.dart';

/// F77.2: `AppHaptics` göçünde çağrının TÜRÜ korunur — her ad tek bir
/// platform titreşimine eşlenir.
void main() {
  testWidgets('AppHaptics adları doğru titreşim türüne gider', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await AppHaptics.tick();
    await AppHaptics.thud();
    await AppHaptics.heavy();
    await AppHaptics.heaviest();

    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });
}
