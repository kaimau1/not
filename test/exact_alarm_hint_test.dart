import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/reminders_screen.dart';
import 'package:notlar/features/settings/data/permissions_service.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KONTROL 36 (KARAR 2026-11-17, PLAN 1.0): tam zamanlı alarm izni kapalıyken
/// uyarı yalnız Ayarlar → İzinler'deydi; ilk hatırlatıcı kurulunca BİR KEZ
/// ipucu çıkar ("İzni aç" sistem ekranını açar).
class _FakePermissions extends PermissionsService {
  _FakePermissions({required this.exact});

  final bool exact;
  int requested = 0;

  @override
  Future<bool> exactAlarmsGranted() async => exact;

  @override
  Future<void> requestExactAlarms() async => requested++;

  @override
  Future<bool> isXiaomi() async => false;
}

void main() {
  Future<BuildContext> pump(
    WidgetTester tester,
    PermissionsService service,
    SharedPreferences prefs,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          permissionsServiceProvider.overrideWithValue(service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );
    return ctx;
  }

  testWidgets('izin kapalı: ilk hatırlatıcıda bir kez ipucu, eylem izni '
      'ister', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = _FakePermissions(exact: false);
    final ctx = await pump(tester, service, prefs);
    final l10n = lookupAppLocalizations(const Locale('tr'));

    await maybeShowAutoStartHint(ctx);
    await tester.pumpAndSettle();
    expect(find.text(l10n.exactAlarmHint), findsOneWidget);
    await tester.tap(find.text(l10n.exactAlarmHintAction));
    await tester.pump();
    expect(service.requested, 1);

    // İkinci hatırlatıcı: ipucu tekrar çıkmaz.
    ScaffoldMessenger.of(ctx).removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await maybeShowAutoStartHint(ctx);
    await tester.pump();
    expect(find.text(l10n.exactAlarmHint), findsNothing);
  });

  testWidgets('izin açık: ipucu yok', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final ctx = await pump(tester, _FakePermissions(exact: true), prefs);
    final l10n = lookupAppLocalizations(const Locale('tr'));
    await maybeShowAutoStartHint(ctx);
    await tester.pump();
    expect(find.text(l10n.exactAlarmHint), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
