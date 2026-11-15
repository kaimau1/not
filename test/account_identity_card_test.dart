import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_design.dart';
import 'package:notlar/core/widgets/app_banner.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/account_identity_card.dart';
import 'package:notlar/features/auth/presentation/account_sheet.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P62 PA2 (plan_tasarim_A §3, §4): kimlik kartı levhada, ayarlar kökünde ve
/// Hesap sayfasında AYNI bileşen; misafir hapı dikkat tonunda; Hesap
/// sayfasında "Hesabı sil" en altta, misafir bandı `AppBanner`, ikinci dolu
/// düğme yok.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeUser implements User {
  @override
  String? get displayName => 'Ada Yılmaz';

  @override
  String? get email => 'ada@example.com';

  @override
  String? get photoURL => null;

  @override
  bool get isAnonymous => false;

  @override
  String get uid => 'u1';

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  required bool guest,
  String? area,
}) async {
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
        authStateProvider.overrideWith(
          (ref) => Stream.value(guest ? null : _FakeUser()),
        ),
        currentUidProvider.overrideWithValue(guest ? null : 'u1'),
        isAnonymousProvider.overrideWithValue(guest),
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
  testWidgets('ayarlar kökünde kimlik kartı + misafirde Giriş yap', (
    tester,
  ) async {
    await _pumpSettings(tester, guest: true);
    expect(find.byType(AccountIdentityCard), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profile-google-sign-in')),
      findsOneWidget,
    );
  });

  testWidgets('misafir hapı dikkat tonunda, en çok iki satır', (tester) async {
    await _pumpSettings(tester, guest: true);
    final pill = find.byKey(const ValueKey('account-status-pill'));
    final scheme = Theme.of(tester.element(pill)).colorScheme;
    final text = tester.widget<Text>(
      find.descendant(of: pill, matching: find.byType(Text)),
    );
    expect(text.maxLines, 2);
    expect(text.style?.color, AppTone.attention.colors(scheme).fg);
  });

  testWidgets('misafir Hesap sayfası: kart + şerit, tek dolu düğme yok, '
      'Hesabı sil en altta', (tester) async {
    await _pumpSettings(tester, guest: true, area: 'account');
    final page = find.byKey(const ValueKey('settings-area-account'));
    expect(
      find.descendant(of: page, matching: find.byType(AccountIdentityCard)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byType(AppBanner)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byType(FilledButton)),
      findsNothing,
    );
    final delete = tester.getTopLeft(
      find.byKey(const ValueKey('settings-delete-account')),
    );
    final signOut = tester.getTopLeft(
      find.byKey(const ValueKey('settings-sign-out')),
    );
    expect(delete.dy, greaterThan(signOut.dy));
    // Son satır: altında başka ListTile yok.
    for (final e
        in find
            .descendant(of: page, matching: find.byType(ListTile))
            .evaluate()) {
      final y = tester.getTopLeft(find.byWidget(e.widget)).dy;
      expect(y, lessThanOrEqualTo(delete.dy));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('girişli Hesap sayfası: ad + e-posta, şerit yok', (tester) async {
    await _pumpSettings(tester, guest: false, area: 'account');
    final page = find.byKey(const ValueKey('settings-area-account'));
    expect(
      find.descendant(of: page, matching: find.text('Ada Yılmaz')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.text('ada@example.com')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byType(AppBanner)),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hesap levhasında aynı kimlik kartı', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_NoAuth()),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          isAnonymousProvider.overrideWithValue(true),
          incomingFriendRequestsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          premiumProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAccountSheet(context),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountIdentityCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
