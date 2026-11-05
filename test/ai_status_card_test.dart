import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/auth/presentation/account_required.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F42.2: AI düğmesi durumu gösterir, dokununca tek açıklama levhası açılır.
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  String todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'ai_points_used_${now.year}-$m-$d';
  }

  Future<void> pump(
    WidgetTester tester, {
    bool anonymous = false,
    Map<String, Object> prefs = const {},
    required VoidCallback onReady,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAnonymousProvider.overrideWithValue(anonymous),
          currentUidProvider.overrideWithValue(null),
          activeApiKeyProvider.overrideWith((ref) async => null),
          sharedPreferencesProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton.icon(
                key: const ValueKey('door'),
                icon: const AiIcon(),
                label: const Text('kapı'),
                onPressed: () {
                  if (ensureAiReady(context, ref)) onReady();
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hazırsa düğme ✨, iş çalışır, levha yok', (tester) async {
    var ran = 0;
    await pump(tester, onReady: () => ran++);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(ran, 1);
    expect(find.byKey(const ValueKey('ai-status-card')), findsNothing);
  });

  testWidgets('misafirde kilit, levhada giriş ve anahtar', (tester) async {
    var ran = 0;
    await pump(tester, anonymous: true, onReady: () => ran++);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(ran, 0);
    expect(find.text(l10n.guestAiTitle), findsOneWidget);
    expect(find.text(l10n.signInWithGoogle), findsOneWidget);
    expect(find.text(l10n.guestAiAddKey), findsOneWidget);
  });

  testWidgets('dahili kapalı: Tekrar dene levhayı kapatır, düğme açılır', (
    tester,
  ) async {
    var ran = 0;
    await pump(
      tester,
      prefs: {'ai_builtin_off_at': DateTime.now().millisecondsSinceEpoch},
      onReady: () => ran++,
    );
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.aiStatusBuiltInOffTitle), findsOneWidget);
    await tester.tap(find.text(l10n.retry));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-status-card')), findsNothing);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(ran, 1);
  });

  testWidgets('kota bitti: yenilenme saati görünür', (tester) async {
    final start = DateTime.now().subtract(const Duration(hours: 1));
    await pump(
      tester,
      prefs: {
        todayKey(): 100000,
        'ai_quota_window_start': start.millisecondsSinceEpoch,
      },
      onReady: () {},
    );
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.aiStatusQuotaTitle), findsOneWidget);
    final renews = start.add(const Duration(hours: 24));
    final hour = renews.hour.toString().padLeft(2, '0');
    final minute = renews.minute.toString().padLeft(2, '0');
    expect(find.textContaining('$hour:$minute'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
