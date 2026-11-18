// AI KULLANIM İLKESİ BEKÇİSİ (PLAN §1.5 PL3): "Yapay zekâyı tümden kapat",
// Play'de ilk kullanım rızası, "AI yanılabilir" + yerel "Bildir".
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/error_log.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/ai_report.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/presentation/ai_result_note.dart';
import 'package:notlar/features/auth/presentation/account_required.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _KeyStore extends ApiKeyStore {
  int reads = 0;

  @override
  Future<String?> read(AiProvider provider) async {
    reads++;
    return 'k';
  }
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  setUp(() {
    Personalize.debugReset();
    AiConsentNotifier.debugRequired = null;
  });
  tearDown(() {
    Personalize.debugReset();
    AiConsentNotifier.debugRequired = null;
  });

  Future<ProviderContainer> container({
    String? key,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        isAnonymousProvider.overrideWithValue(false),
        currentUidProvider.overrideWithValue(null),
        activeApiKeyProvider.overrideWith((ref) async => key),
        sharedPreferencesProvider.overrideWithValue(store),
      ],
    );
    addTearDown(c.dispose);
    await c.read(activeApiKeyProvider.future);
    return c;
  }

  Matcher rejectedWith(GeminiErrorKind kind) =>
      throwsA(isA<GeminiException>().having((e) => e.kind, 'kind', kind));

  group('tümden kapat (PL3 c)', () {
    test('varsayılan açık; kapatınca kendi anahtarı olsa da durum kapalı, '
        'çağrı reddedilir, kayıt kalıcı', () async {
      final c = await container(key: 'k');
      expect(c.read(aiTurnedOffProvider), isFalse);
      expect(c.read(aiAvailabilityProvider), AiAvailability.ready);
      c.read(aiAdmissionProvider).check();

      c.read(aiTurnedOffProvider.notifier).set(true);
      expect(c.read(aiAvailabilityProvider), AiAvailability.turnedOff);
      expect(c.read(aiAvailabilityProvider).looksLocked, isTrue);
      expect(
        () => c.read(aiAdmissionProvider).check(),
        rejectedWith(GeminiErrorKind.aiTurnedOff),
      );
      final prefs = c.read(sharedPreferencesProvider);
      expect(prefs.getBool(Personalize.aiOffKey), isTrue);

      // Yeniden açılış: kayıttan okunur, Personalize de açılışta alır.
      final again = await container(prefs: {Personalize.aiOffKey: true});
      expect(again.read(aiTurnedOffProvider), isTrue);
      Personalize.attach(again.read(sharedPreferencesProvider));
      expect(Personalize.aiOff.value, isTrue);
    });

    test('Yapay zekâ eklentisinin girişleri gizli, kayıt bozulmaz', () async {
      final c = await container();
      final prefs = Personalize.current;
      expect(prefs.shows(UiItem.barAi), isTrue);
      expect(prefs.shows(UiItem.homeAi), isTrue);

      var notified = 0;
      void count() => notified++;
      Personalize.listenable.addListener(count);
      addTearDown(() => Personalize.listenable.removeListener(count));

      c.read(aiTurnedOffProvider.notifier).set(true);
      expect(notified, 1, reason: 'editör çubuğu yeniden çizilsin');
      expect(prefs.shows(UiItem.barAi), isFalse);
      expect(prefs.shows(UiItem.homeAi), isFalse);
      // Kullanıcının kendi seçimi aynen (anahtar kapanınca geri gelir).
      expect(prefs.storedShows(UiItem.barAi), isTrue);
      expect(prefs.moduleState(UiModule.ai), isTrue);
      // AI dışı öğe etkilenmez.
      expect(prefs.shows(UiItem.barDictation), isTrue);

      c.read(aiTurnedOffProvider.notifier).set(false);
      expect(prefs.shows(UiItem.barAi), isTrue);
    });

    test('GeminiService kapalıyken ağa/anahtara uğramadan reddeder', () async {
      final c = await container();
      c.read(aiTurnedOffProvider.notifier).set(true);
      final keys = _KeyStore();
      final service = GeminiService(
        keys,
        admit: c.read(aiAdmissionProvider).check,
      );
      const note = Note(
        id: 'n',
        type: NoteType.text,
        title: 't',
        body: 'Uzun bir not metni burada duruyor.',
      );
      await expectLater(
        service.summarizeNote(note),
        rejectedWith(GeminiErrorKind.aiTurnedOff),
      );
      await expectLater(
        service.embedTexts(['x']),
        rejectedWith(GeminiErrorKind.aiTurnedOff),
      );
      expect(keys.reads, 0);
    });

    test('uygulamadaki servis kapıyı bağlıyor (tek kapı)', () {
      final src = File('lib/features/ai/data/gemini_service.dart')
          .readAsStringSync();
      expect(src, contains('admit: ref.read(aiAdmissionProvider).check'));
      // Ağa çıkan her yol izinli anahtar okumasından geçer; doğrudan
      // `_keyStore.read` yalnız izin yardımcısında ve model listelerinde.
      expect(
        RegExp(r'_keyStore\.read\(').allMatches(src).length,
        3,
        reason: 'yeni bir yol _admittedKey() kullanmalı',
      );
    });
  });

  group('rıza (PL3 a)', () {
    test('kişisel APK\'da sorulmaz (kabul sayılır)', () async {
      final c = await container();
      expect(AiConsentNotifier.required, isFalse);
      expect(c.read(aiConsentProvider), isTrue);
      expect(c.read(aiAvailabilityProvider), AiAvailability.ready);
    });

    test('Play\'de ilk kullanımda sorulur; kabul kalıcı', () async {
      AiConsentNotifier.debugRequired = true;
      final c = await container(key: 'k');
      expect(c.read(aiAvailabilityProvider), AiAvailability.consentNeeded);
      expect(c.read(aiAvailabilityProvider).looksLocked, isFalse);
      expect(
        () => c.read(aiAdmissionProvider).check(),
        rejectedWith(GeminiErrorKind.aiConsentNeeded),
      );
      c.read(aiConsentProvider.notifier).accept();
      expect(c.read(aiAvailabilityProvider), AiAvailability.ready);
      c.read(aiAdmissionProvider).check();

      final again = await container(prefs: {AiConsentNotifier.key: true});
      expect(again.read(aiConsentProvider), isTrue);
    });
  });

  Future<void> pumpDoor(
    WidgetTester tester, {
    Map<String, Object> prefs = const {},
    required VoidCallback onReady,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final store = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isAnonymousProvider.overrideWithValue(false),
          currentUidProvider.overrideWithValue(null),
          activeApiKeyProvider.overrideWith((ref) async => 'k'),
          sharedPreferencesProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => FilledButton(
                key: const ValueKey('door'),
                onPressed: () {
                  if (ensureAiReady(context, ref)) onReady();
                },
                child: const Text('kapı'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('kapalıyken düğme levha açar; "Yapay zekâyı aç" geri getirir', (
    tester,
  ) async {
    var ran = 0;
    await pumpDoor(
      tester,
      prefs: {Personalize.aiOffKey: true},
      onReady: () => ran++,
    );
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(ran, 0);
    expect(find.text(l10n.aiOffTitle), findsOneWidget);
    expect(find.text(l10n.guestAiAddKey), findsNothing);
    await tester.tap(find.byKey(const ValueKey('ai-turn-on')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('door')));
    expect(ran, 1);
  });

  testWidgets('Play rızası: Vazgeç iş yapmaz, Kabul sonrası çalışır', (
    tester,
  ) async {
    AiConsentNotifier.debugRequired = true;
    var ran = 0;
    await pumpDoor(tester, onReady: () => ran++);
    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.aiConsentTitle), findsOneWidget);
    expect(find.textContaining(l10n.aiConsentMistakes), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('ai-consent-decline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-consent-decline')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.aiConsentTitle), findsNothing);
    expect(ran, 0);

    await tester.tap(find.byKey(const ValueKey('door')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('ai-consent-accept')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-consent-accept')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('door')));
    expect(ran, 1);
  });

  group('yanılabilir + Bildir (PL3 b)', () {
    test('bildirim yalnız yerel günlük, metin YAZILMAZ', () {
      ErrorLog.clear();
      const secret = 'Gizli not içeriği 12345';
      const AiReportService().report(content: secret, source: 'ai_sheet');
      final entry = ErrorLog.entries.last;
      expect(entry.source, AiReportService.logSource);
      expect(entry.message, contains('ai_sheet'));
      expect(entry.message, isNot(contains('12345')));
      // Sunucuya yazan eski yol geri gelmesin.
      final src = File('lib/features/ai/data/ai_report.dart')
          .readAsStringSync();
      expect(src, isNot(contains('cloud_firestore')));
    });

    testWidgets('ipucu + Bildir → teşekkür', (tester) async {
      ErrorLog.clear();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AiResultNote(content: 'yanıt', source: 'test'),
            ),
          ),
        ),
      );
      expect(find.text(l10n.aiMayBeWrong), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('ai-report')));
      await tester.pump();
      expect(find.text(l10n.aiReportThanks), findsOneWidget);
      expect(ErrorLog.entries.last.source, AiReportService.logSource);
    });

    test('AI yanıt yüzeyleri ipucunu taşır', () {
      for (final path in [
        'lib/features/ai/presentation/ai_sheet.dart',
        'lib/features/ai/presentation/ai_chat_screen.dart',
        'lib/features/ai/presentation/ai_text_result.dart',
      ]) {
        expect(
          File(path).readAsStringSync(),
          contains('AiResultNote('),
          reason: path,
        );
      }
    });
  });
}
