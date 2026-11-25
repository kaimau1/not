// AI KULLANIM İLKESİ BEKÇİSİ (PLAN §1.5 PL2/PL3, Faz 1):
// "Akıllı kararları kapat", Play'de ilk kullanım rızası, acil kapatma
// (kill switch), yerel hız sınırı ve 2-katmanlı erişim kapısı.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/ai_kill_switch.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/play_build.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  setUp(() {
    AiKillSwitch.debugReset();
    Personalize.debugReset();
    AiConsentNotifier.debugRequired = false;
  });
  tearDown(() {
    AiKillSwitch.debugReset();
    Personalize.debugReset();
    AiConsentNotifier.debugRequired = null;
  });

  Future<ProviderContainer> container({
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        isAnonymousProvider.overrideWithValue(false),
        currentUidProvider.overrideWithValue(null),
        sharedPreferencesProvider.overrideWithValue(store),
        proFeatureProvider.overrideWith((ref, _) => true),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Matcher rejectedWith(AiPolicyErrorKind kind) =>
      throwsA(isA<AiPolicyException>().having((e) => e.kind, 'kind', kind));

  group('tümden kapat (PL3 c)', () {
    test('varsayılan açık; kapatınca çağrı reddedilir, kayıt kalıcı', () async {
      final c = await container();
      expect(c.read(aiTurnedOffProvider), isFalse);
      c.read(aiAdmissionProvider).check();

      c.read(aiTurnedOffProvider.notifier).set(true);
      expect(
        () => c.read(aiAdmissionProvider).check(),
        rejectedWith(AiPolicyErrorKind.aiTurnedOff),
      );
      final prefs = c.read(sharedPreferencesProvider);
      expect(prefs.getBool(Personalize.aiOffKey), isTrue);

      // Yeniden açılış: kayıttan okunur, Personalize de açılışta alır.
      final again = await container(prefs: {Personalize.aiOffKey: true});
      expect(again.read(aiTurnedOffProvider), isTrue);
      Personalize.attach(again.read(sharedPreferencesProvider));
      expect(Personalize.aiOff.value, isTrue);
    });

    test('AI kapalıyken AI dışı çubuk öğeleri etkilenmez', () async {
      final c = await container();
      final prefs = Personalize.current;

      var notified = 0;
      void count() => notified++;
      Personalize.listenable.addListener(count);
      addTearDown(() => Personalize.listenable.removeListener(count));

      c.read(aiTurnedOffProvider.notifier).set(true);
      expect(notified, 1);
      expect(prefs.shows(UiItem.barDictation), isTrue);

      c.read(aiTurnedOffProvider.notifier).set(false);
      expect(prefs.shows(UiItem.barDictation), isTrue);
    });
  });

  group('rıza (PL3 a)', () {
    test(
      'rıza yalnız Play derlemesinde istenir (kişisel APK\'da kabul sayılır)',
      () async {
        AiConsentNotifier.debugRequired = null;
        expect(AiConsentNotifier.required, PlayBuild.aiConsent);
        final c = await container();
        expect(c.read(aiConsentProvider), !PlayBuild.enabled);
      },
    );

    test('Play\'de ilk kullanımda sorulur; kabul kalıcı', () async {
      AiConsentNotifier.debugRequired = true;
      final c = await container();
      expect(
        () => c.read(aiAdmissionProvider).check(),
        rejectedWith(AiPolicyErrorKind.aiConsentNeeded),
      );
      c.read(aiConsentProvider.notifier).accept();
      c.read(aiAdmissionProvider).check();

      final again = await container(prefs: {AiConsentNotifier.key: true});
      expect(again.read(aiConsentProvider), isTrue);
    });
  });

  group('acil kapatma + yerel hız sınırı (PL2)', () {
    test(
      'config/app.aiKillSwitch: yalnız tam true kapatır; canlı izlenir',
      () async {
        final c = await container();
        AiKillSwitch.apply({'aiKillSwitch': 'true'});
        expect(c.read(aiKillSwitchProvider), isFalse);
        AiKillSwitch.apply({'aiKillSwitch': true, 'minClient': 3});
        expect(c.read(aiKillSwitchProvider), isTrue);
        expect(
          () => c.read(aiAdmissionProvider).check(),
          rejectedWith(AiPolicyErrorKind.aiPaused),
        );
        expect(
          const AiPolicyException(AiPolicyErrorKind.aiPaused).localized(l10n),
          l10n.aiPausedTitle,
        );
        AiKillSwitch.apply(null);
        expect(c.read(aiKillSwitchProvider), isFalse);
        c.read(aiAdmissionProvider).check();
      },
    );

    test('değer config/app dinleyicisinden gelir, istemci yazmaz', () {
      final src = File('lib/core/save_cadence.dart').readAsStringSync();
      expect(src, contains('AiKillSwitch.apply(d.data())'));
      for (final f in Directory('lib').listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        final text = f.readAsStringSync();
        expect(
          RegExp(r"aiKillSwitch'\s*:").hasMatch(text),
          isFalse,
          reason: '${f.path} config/app bayrağını yazmamalı',
        );
      }
    });

    test('hız sınırı: dakikada 30, saatte 300; pencere kayar', () {
      final limiter = AiRateLimiter();
      final t0 = DateTime(2026, 11, 18, 10);
      for (var i = 0; i < 30; i++) {
        expect(limiter.tryAcquire(t0), isTrue);
      }
      expect(limiter.tryAcquire(t0.add(const Duration(seconds: 59))), isFalse);
      expect(limiter.tryAcquire(t0.add(const Duration(minutes: 1))), isTrue);

      final hourly = AiRateLimiter(perMinute: 1000);
      for (var i = 0; i < 300; i++) {
        expect(hourly.tryAcquire(t0.add(Duration(seconds: i))), isTrue);
      }
      expect(hourly.tryAcquire(t0.add(const Duration(minutes: 30))), isFalse);
      expect(hourly.tryAcquire(t0.add(const Duration(hours: 1))), isTrue);
    });

    test('kapı: sınır aşılınca ağa çıkmadan red; ölçülmez çağrı geçer', () async {
      final c = await container();
      final admission = c.read(aiAdmissionProvider);
      for (var i = 0; i < admission.limiter.perMinute; i++) {
        admission.check();
      }
      expect(admission.check, rejectedWith(AiPolicyErrorKind.rateLimited));
      admission.check(metered: false);
    });
  });
}
