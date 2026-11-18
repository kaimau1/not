import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/feedback_mail.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pump(WidgetTester tester, Size size, {String? area}) async {
  tester.view.physicalSize = size;
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

/// PL15 bekçisi: "Geri bildirim gönder" Hesap → Hakkında'da; mailto gövdesi
/// YALNIZ sürüm/derleme/platform/OS taşır (kişisel veri yok).
void main() {
  test('mailto: alıcı tek sabit, gövdede teknik bilgi, boşluk %20', () {
    final info = feedbackTechInfo(
      version: '1.2.70',
      buildNumber: '412',
      platform: 'android',
      osVersion: 'Linux 5.10',
      play: true,
    );
    final uri = feedbackMailUri(
      subject: 'Notlar · Geri bildirim',
      prompt: 'Mesajın:',
      techInfo: info,
    );
    expect(uri.scheme, 'mailto');
    expect(uri.path, kSupportEmail);
    expect(uri.toString(), isNot(contains('+')));
    final body = Uri.decodeComponent(uri.toString().split('&body=').last);
    expect(body, startsWith('Mesajın:'));
    expect(body, contains('1.2.70 (412) · Play'));
    expect(body, contains('Platform: android · Linux 5.10'));
    // Yalnız iki teknik satır: kişisel alan eklenmesin.
    expect(info.split('\n'), hasLength(2));
  });

  test('web: OS sürümü boşsa yalnız platform', () {
    expect(
      feedbackTechInfo(version: '1', buildNumber: '2', platform: 'web'),
      'Sürüm / Version: 1 (2)\nPlatform: web',
    );
  });

  test('destek adresi gizlilik metnindeki iletişim adresiyle aynı', () {
    final policy = File('PRIVACY_POLICY.md').readAsStringSync();
    expect(policy, contains(kSupportEmail));
  });

  testWidgets('Hesap alanında Geri bildirim satırı, hata günlüğünden önce', (
    tester,
  ) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await _pump(tester, const Size(412, 3000), area: 'account');
    final row = find.byKey(const ValueKey('settings-feedback'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text(l10n.feedbackSend)),
      findsOneWidget,
    );
    final logY = tester.getTopLeft(find.text(l10n.errorLogShare)).dy;
    expect(tester.getTopLeft(row).dy, lessThan(logY));
  });
}
