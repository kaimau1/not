import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F79.2 (DENEYIM D18): misafirde profil kartı "Misafir" + "Yalnız bu
/// cihazda" ve "Giriş yap" düğmesi; kısayol kartları (Kılavuz,
/// Kişiselleştir) AYNI nötr tonda.
void main() {
  testWidgets('misafir profil kartı ve nötr kısayollar', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue(null),
        isAnonymousProvider.overrideWithValue(true),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Misafir'), findsOneWidget);
    expect(find.text('Yalnız bu cihazda'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profile-google-sign-in')),
        matching: find.text('Giriş yap'),
      ),
      findsOneWidget,
    );

    Color tone(String key) => tester
        .widget<Material>(
          find
              .ancestor(
                of: find.byKey(ValueKey(key)),
                matching: find.byType(Material),
              )
              .first,
        )
        .color!;
    expect(tone('settings-guide'), tone('settings-personalize'));
    expect(tester.takeException(), isNull);
  });
}
