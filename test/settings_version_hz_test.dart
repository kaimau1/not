import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-11-16 hatası: " · 120 Hz" eki yalnız arama ile bulunan "Uygulama
/// sürümü" satırına eklenmişti; kullanıcının gördüğü iki satır (Ayarlar dibi
/// ve "Güncelleme ve sürüm") yalnız "Notlar · v1.2.83" yazıyordu.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pump(WidgetTester tester, {String? area}) async {
  tester.view.physicalSize = const Size(412, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_NoAuth()),
        currentUidProvider.overrideWithValue(null),
        isAnonymousProvider.overrideWithValue(true),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(initialArea: area),
      ),
    ),
  );
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  const system = MethodChannel('dev.kaimau.notlar/system');

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Notlar',
      packageName: 'dev.kaimau.notlar',
      version: '1.2.83',
      buildNumber: '83',
      buildSignature: '',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          system,
          (call) async => call.method == 'refreshRate' ? 120.0 : null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(system, null);
  });

  testWidgets('Ayarlar dibi ve "Güncelleme ve sürüm": v1.2.83 · 120 Hz', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _pump(tester);
      expect(find.text('Notlar · v1.2.83 · 120 Hz'), findsOneWidget);

      await _pump(tester, area: 'updates');
      expect(find.text('Notlar · v1.2.83 · 120 Hz'), findsWidgets);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
