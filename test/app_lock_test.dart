import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/presentation/app_lock.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F18.6 uygulama kilidi: kapak ve yeniden kilitleme kuralı.
void main() {
  final t0 = DateTime(2026, 11, 2, 12);

  test('kapalıyken hiç kilitlemez', () {
    expect(
      appLockShouldRelock(
        settings: const AppLockSettings(),
        backgroundedAt: t0,
        now: t0.add(const Duration(hours: 1)),
      ),
      isFalse,
    );
  });

  test('süre dolunca kilitler, dolmadan kilitlemez', () {
    const s = AppLockSettings(enabled: true, delayMinutes: 5);
    expect(
      appLockShouldRelock(
        settings: s,
        backgroundedAt: t0,
        now: t0.add(const Duration(minutes: 4)),
      ),
      isFalse,
    );
    expect(
      appLockShouldRelock(
        settings: s,
        backgroundedAt: t0,
        now: t0.add(const Duration(minutes: 5)),
      ),
      isTrue,
    );
    expect(
      appLockShouldRelock(
        settings: const AppLockSettings(enabled: true, delayMinutes: 0),
        backgroundedAt: t0,
        now: t0,
      ),
      isTrue,
    );
  });

  test('web yalnız şifre/desenle', () {
    expect(appLockAvailable(isWeb: true, usesSecret: false), isFalse);
    expect(appLockAvailable(isWeb: true, usesSecret: true), isTrue);
    expect(appLockAvailable(isWeb: false, usesSecret: false), isTrue);
  });

  Future<void> pump(WidgetTester tester, Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppLockGate(child: Text('gizli içerik')),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('açıkken açılışta kapak gelir, içerik ekran okuyucuya kapalı', (
    tester,
  ) async {
    await pump(tester, {'app_lock_enabled': true});
    expect(find.text('Notlar kilitli'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-lock-unlock')), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('gizli içerik'), findsNothing);
    semantics.dispose();
  });

  testWidgets('kapalıyken kapak yok', (tester) async {
    await pump(tester, {});
    expect(find.text('Notlar kilitli'), findsNothing);
    expect(find.text('gizli içerik'), findsOneWidget);
  });
}
