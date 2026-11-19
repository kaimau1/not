import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/presentation/quick_entry_bar.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KT-24 (tablet turu 2026-11-18): ⚡ Hızlı ekle ilk dokunuşta açıklamasız
/// sistem mikrofon izni penceresi açıyordu. KÖK NEDEN: levha kendiliğinden
/// dinlemeye başlarken (`autoListen`, kullanıcı isteği 2026-11-16) izni
/// İSTEYEN yolu çağırıyordu. Kendiliğinden dinleme artık yalnız izin ZATEN
/// verilmişse başlar; izin, kullanıcı mikrofona basınca istenir.
void main() {
  const events = EventChannel('dev.kaimau.notlar/speech');
  var listens = 0;

  setUp(() {
    listens = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          events,
          MockStreamHandler.inline(onListen: (_, _) => listens++),
        );
    DeviceSpeech.debugAvailable = true;
  });

  tearDown(() {
    DeviceSpeech.debugAvailable = null;
    DeviceSpeech.debugMicGranted = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(events, null);
  });

  Future<void> pump(
    WidgetTester tester, {
    Duration delay = Duration.zero,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuickEntryBar(
              parser: QuickParser(QuickLexicon()),
              raw: true,
              autoListen: true,
              autoListenDelay: delay,
              onItems: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('KT-24: izin yokken kendiliğinden dinleme izin istemez', (
    tester,
  ) async {
    DeviceSpeech.debugMicGranted = false;
    await pump(tester);
    expect(listens, 0, reason: 'izin sorulmadan dinleme başlamamalı');
    // Mikrofona basınca (izin bu an istenir) dinleme başlar.
    await tester.tap(find.byKey(const ValueKey('quick-entry-mic')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(listens, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('KT-24: izin varken kendiliğinden dinler (değişmedi)', (
    tester,
  ) async {
    DeviceSpeech.debugMicGranted = true;
    await pump(tester);
    expect(listens, 1);
    await tester.pumpWidget(const SizedBox());
  });

  // Kullanıcı bulgusu 2026-11-19 ("hızlı ekle açıkken klavye kasıyor"):
  // tanıyıcı levha + klavye animasyonuyla aynı karelerde açılıyordu; ham
  // kipte dinleme sürerken klavyeyle yazılan bir sonraki sonuçta siliniyordu.
  testWidgets('kendiliğinden dinleme gecikmeyle başlar; önce yazılırsa hiç '
      'başlamaz', (tester) async {
    DeviceSpeech.debugMicGranted = true;
    await pump(tester, delay: const Duration(milliseconds: 700));
    expect(listens, 0, reason: 'animasyonlar sürerken tanıyıcı açılmaz');
    await tester.pump(const Duration(milliseconds: 700));
    expect(listens, 1);
    await tester.pumpWidget(const SizedBox());

    listens = 0;
    await pump(tester, delay: const Duration(milliseconds: 700));
    await tester.enterText(
      find.byKey(const ValueKey('quick-entry-field')),
      'süt',
    );
    await tester.pump(const Duration(milliseconds: 800));
    expect(listens, 0, reason: 'kullanıcı yazmayı seçti');
    expect(find.text('süt'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('ham kipte dinlerken klavyeyle yazmak dinlemeyi keser, yazılan '
      'kalır', (tester) async {
    DeviceSpeech.debugMicGranted = true;
    await pump(tester);
    expect(listens, 1);
    expect(find.byKey(const ValueKey('quick-entry-heard')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('quick-entry-field')),
      'ekmek',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('quick-entry-heard')), findsNothing);
    expect(find.text('ekmek'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
