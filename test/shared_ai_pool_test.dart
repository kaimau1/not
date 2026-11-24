import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/ecosystem_apps.dart';
import 'package:notlar/features/ai/data/shared_ai_pool.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ByokKeyPool (5 yedek anahtar x model rotasyonu)', () {
    test('dış-anahtar × iç-model sırası ve kota/yetki soğuması', () async {
      final pool = ByokKeyPool();
      final now = DateTime(2026, 11, 24, 12);
      const keys = ['k1', 'k2', 'k3', 'k4', 'k5', 'k6-ignored'];
      const models = ['gemini-2.5-flash', 'gemini-2.5-pro'];

      final initial = pool.orderedSlots(keys: keys, models: models, now: now);
      expect(initial.take(4).toList(), [
        (key: 'k1', model: 'gemini-2.5-flash'),
        (key: 'k1', model: 'gemini-2.5-pro'),
        (key: 'k2', model: 'gemini-2.5-flash'),
        (key: 'k2', model: 'gemini-2.5-pro'),
      ]);

      // k1/flash 429 -> soğur, k1/pro hâlâ uygun.
      pool.markFailure('k1', 'gemini-2.5-flash', statusCode: 429, now: now);
      expect(pool.isCooling('k1', 'gemini-2.5-flash', now: now), isTrue);
      final after429 = pool.orderedSlots(
        keys: keys.take(2).toList(),
        models: models,
        now: now.add(const Duration(seconds: 30)),
      );
      expect(after429.first, (key: 'k1', model: 'gemini-2.5-pro'));

      // Soğuma bitince k1/flash yeniden aday olur.
      expect(
        pool.isCooling(
          'k1',
          'gemini-2.5-flash',
          now: now.add(const Duration(minutes: 4)),
        ),
        isFalse,
      );

      // Kalıcılık: gelecekte süresi bitmemiş soğumayı prefs saklar/yükler.
      final futurePool = ByokKeyPool();
      final futureNow = DateTime.now();
      futurePool.markFailure(
        'k2',
        'gemini-2.5-pro',
        statusCode: 403,
        now: futureNow,
      );
      final prefs = await SharedPreferences.getInstance();
      await futurePool.saveCooldowns(prefs);
      final restored = ByokKeyPool()..loadCooldowns(prefs);
      expect(restored.isCooling('k2', 'gemini-2.5-pro'), isTrue);
    });
  });

  group('SharedAiPoolClient (0-fallback & 0-bakiye güvenlik duvarları)', () {
    test('BYOK kipinde 401/403/429 gelince ortak havuza DÜŞMEZ', () async {
      for (final code in [401, 403, 429]) {
        expect(
          () => SharedAiPoolClient.guardByokFailure(
            mode: AiSourceMode.byok,
            statusCode: code,
          ),
          throwsA(
            isA<SharedAiPoolException>().having(
              (e) => e.kind,
              'kind',
              SharedAiPoolErrorKind.byokExhausted,
            ),
          ),
        );
      }

      var calls = 0;
      final client = SharedAiPoolClient(
        caller: (name, payload) async {
          calls++;
          return {'text': 'unexpected', 'remainingCredits': 499};
        },
      );
      await expectLater(
        client.generate(
          mode: AiSourceMode.byok,
          contents: const [
            {
              'role': 'user',
              'parts': [
                {'text': 'merhaba'},
              ],
            },
          ],
        ),
        throwsA(
          isA<SharedAiPoolException>().having(
            (e) => e.kind,
            'kind',
            SharedAiPoolErrorKind.byokExhausted,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('bilinen bakiye 0 ise hiç ağ isteği atılmaz', () async {
      var calls = 0;
      final client = SharedAiPoolClient(
        caller: (name, payload) async {
          calls++;
          return {'text': 'nope', 'remainingCredits': 0};
        },
      )..setKnownBalanceForTest(0);

      await expectLater(
        client.generate(
          mode: AiSourceMode.sharedPool,
          contents: const [
            {
              'role': 'user',
              'parts': [
                {'text': 'test'},
              ],
            },
          ],
        ),
        throwsA(
          isA<SharedAiPoolException>().having(
            (e) => e.kind,
            'kind',
            SharedAiPoolErrorKind.insufficientCredits,
          ),
        ),
      );
      expect(calls, 0);
    });

    test('fetchStatus ve generate bakiye durumunu günceller', () async {
      String? lastFn;
      final client = SharedAiPoolClient(
        caller: (name, payload) async {
          lastFn = name;
          if (name == 'sharedAiPoolStatus') {
            return {
              'balance': 500,
              'starterGranted': true,
              'apps': ['notlar', 'dosya_okuyucu'],
            };
          }
          return {'text': 'Kısa özet', 'remainingCredits': 499, 'cost': 1};
        },
      );

      final st = await client.fetchStatus();
      expect(lastFn, 'sharedAiPoolStatus');
      expect(st.balance, 500);
      expect(st.starterGranted, isTrue);
      expect(st.apps, contains('dosya_okuyucu'));
      expect(client.knownBalance, 500);

      final res = await client.generate(
        mode: AiSourceMode.sharedPool,
        contents: const [
          {
            'role': 'user',
            'parts': [
              {'text': 'özetle'},
            ],
          },
        ],
      );
      expect(lastFn, 'sharedAiPoolGenerate');
      expect(res.text, 'Kısa özet');
      expect(res.remainingCredits, 499);
      expect(client.knownBalance, 499);
    });

    test('AiSourceMode.fromId ve kalıcı seçim', () async {
      expect(AiSourceMode.fromId(null, hasOwnKey: true), AiSourceMode.byok);
      expect(
        AiSourceMode.fromId(null, hasOwnKey: false),
        AiSourceMode.sharedPool,
      );
      expect(
        AiSourceMode.fromId('sharedPool', hasOwnKey: true),
        AiSourceMode.sharedPool,
      );

      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      container.read(aiSourceModeProvider.notifier).set(AiSourceMode.byok);
      expect(prefs.getString(AiSourceModeNotifier.prefsKey), 'byok');
    });
  });

  group('EcosystemApps & CrossAppPromoCard', () {
    test('kapatılınca 30 gün gizlenir', () async {
      final prefs = await SharedPreferences.getInstance();
      final t0 = DateTime(2026, 11, 24);
      expect(
        EcosystemApps.dosyaOkuyucuPackage,
        'com.dosyaokuyucu.dosya_okuyucu',
      );
      expect(EcosystemApps.shouldShowPromo(prefs, now: t0), isTrue);

      await EcosystemApps.dismissPromo(prefs, now: t0);
      expect(
        EcosystemApps.shouldShowPromo(
          prefs,
          now: t0.add(const Duration(days: 10)),
        ),
        isFalse,
      );
      expect(
        EcosystemApps.shouldShowPromo(
          prefs,
          now: t0.add(const Duration(days: 30)),
        ),
        isTrue,
      );
    });

    testWidgets('CrossAppPromoCard kapatılınca kaybolur', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: CrossAppPromoCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cross-app-dosyalarim-card')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('cross-app-promo-dismiss')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cross-app-dosyalarim-card')),
        findsNothing,
      );
      expect(EcosystemApps.shouldShowPromo(prefs), isFalse);
    });
  });
}
