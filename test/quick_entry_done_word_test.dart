import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/domain/done_word.dart';
import 'package:notlar/features/notes/presentation/quick_entry_bar.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// H1 (17K §4.1; 2026-11-20 hızlı ekle / akıllı liste turu): akıllı listede
/// "süt bitti" (= süt kalmadı) deyip devam eden kullanıcının listesi
/// kapanıyordu — tanıma noktalama vermez, "süt ekmek bitti" ile "süt bitti"
/// metinden ayrılmaz. Karar konuşmanın zamanından: önünde duraklama varsa ya
/// da ardından konuşma gelmezse bitiş; konuşma sürerse içerik.
void main() {
  const events = EventChannel('dev.kaimau.notlar/speech');
  MockStreamHandlerEventSink? sink;

  setUp(() {
    sink = null;
    DeviceSpeech.debugAvailable = true;
    DeviceSpeech.debugMicGranted = true;
  });

  tearDown(() {
    DeviceSpeech.debugAvailable = null;
    DeviceSpeech.debugMicGranted = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(events, null);
  });

  test('yalın ve kesin bitiş sözü ayrılır', () {
    expect(matchDoneWord('süt ekmek bitti'), (rest: 'süt ekmek', bare: true));
    expect(matchDoneWord('süt ekmek bu kadar'), (
      rest: 'süt ekmek',
      bare: false,
    ));
    expect(matchDoneWord('süt liste bitti'), (rest: 'süt', bare: false));
    expect(matchDoneWord('bitti'), (rest: '', bare: false));
    expect(matchDoneWord('süt ekmek'), isNull);
  });

  late List<String> items;
  late int done;

  Future<void> pump(WidgetTester tester) async {
    items = [];
    done = 0;
    // Sahte tanıyıcı akışı test GÖVDESİNDE kurulur (setUp'ta kurulunca
    // dinleme açılıyor ama olaylar oturuma ulaşmıyordu).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          events,
          MockStreamHandler.inline(
            onListen: (_, s) {
              sink = s;
            },
          ),
        );
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final parser = buildQuickParser(
      buildQuickLexicon(locale: 'tr', grocery: true),
      spell: SpellMemory(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: QuickEntryBar(
              parser: parser,
              autoListen: true,
              onItems: (r) => items.addAll([for (final i in r) i.text]),
              onDoneWord: () => done++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(sink, isNotNull, reason: 'dinleme başlamalı');
  }

  Future<void> say(WidgetTester tester, String text) async {
    sink!.success({'text': text});
    // Olay bir sonraki karede işlenir.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('"süt bitti" deyip devam edince liste kapanmaz, "bitti" madde '
      'olmaz', (tester) async {
    await pump(tester);
    await say(tester, 'süt');
    await tester.pump(const Duration(milliseconds: 300));
    await say(tester, 'süt bitti');
    await tester.pump(const Duration(milliseconds: 400));
    await say(tester, 'süt bitti ekmek');
    await tester.pump(const Duration(milliseconds: 300));
    await say(tester, 'süt bitti ekmek yumurta');
    await tester.pump(const Duration(seconds: 2));
    expect(done, 0, reason: 'konuşma sürdü: "bitti" içerikti');
    expect(items, containsAll(['Süt', 'Ekmek']));
    expect(items, isNot(contains('Bitti')));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('duraklamadan sonra "bitti": hemen biter', (tester) async {
    await pump(tester);
    await say(tester, 'süt ekmek yumurta');
    await tester.pump(const Duration(seconds: 1));
    await say(tester, 'süt ekmek yumurta bitti');
    expect(done, 1);
    expect(items, ['Süt', 'Ekmek', 'Yumurta']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('duraklamasız "bitti", ardından sessizlik: kısa beklemeyle '
      'biter', (tester) async {
    await pump(tester);
    await say(tester, 'süt ekmek');
    await tester.pump(const Duration(milliseconds: 200));
    await say(tester, 'süt ekmek bitti');
    expect(done, 0);
    await tester.pump(QuickEntryBarState.doneGrace);
    expect(done, 1);
    expect(items, ['Süt', 'Ekmek']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('"bu kadar" / "liste bitti" hep hemen biter', (tester) async {
    await pump(tester);
    await say(tester, 'süt');
    await tester.pump(const Duration(milliseconds: 200));
    await say(tester, 'süt bu kadar');
    expect(done, 1);
    expect(items, ['Süt']);
    await tester.pumpWidget(const SizedBox());
  });
}
