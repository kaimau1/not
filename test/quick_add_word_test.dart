// "… ekle" bitiş sözü (kullanıcı isteği 2026-11-26: "hızlı ekle sonunda ekle
// dediğim zaman o notu çok kısa bir beklemeden sonra direkt eklemeli").
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/domain/quick_drop.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_entry_bar.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('domain', () {
    test('sonda "ekle" ailesi', () {
      expect(endsWithAddCommand('süt ekmek ekle'), isTrue);
      expect(endsWithAddCommand('markete süt ekler misin.'), isTrue);
      expect(endsWithAddCommand('ekle sonra süt'), isFalse);
      expect(endsWithAddCommand('eklemeyi unutma'), isFalse);
      expect(endsWithAddCommand('rapor yaz'), isFalse);
    });

    test('adlandırılmış ama bilinmeyen hedef yalnız açık işaretle', () {
      // Ad söylenmedi: seçili nota gider.
      expect(dropNamesUnknownTarget('süt ekle'), isFalse);
      expect(dropNamesUnknownTarget('elma ekle'), isFalse);
      expect(dropNamesUnknownTarget('çikolata ekle'), isFalse);
      expect(dropNamesUnknownTarget('dosya ekle'), isFalse);
      expect(dropNamesUnknownTarget('süt ekmek'), isFalse);
      // Ad söylendi (işaret, kesme, iyelikli/kaynaştırmalı yönelme).
      expect(dropNamesUnknownTarget('yeni fikir hatalar notuna ekle'), isTrue);
      expect(dropNamesUnknownTarget('süt alışveriş listesine ekle'), isTrue);
      expect(dropNamesUnknownTarget("süt Market'e ekle"), isTrue);
      expect(
        dropNamesUnknownTarget('logo taslağı fikir defterine ekle'),
        isTrue,
      );
      expect(dropNamesUnknownTarget('video fikri kanallarıma ekle'), isTrue);
      expect(dropNamesUnknownTarget('hata siteye ekle'), isTrue);
    });
  });

  group('QuickEntryBar onAddWord', () {
    const speechEvents = EventChannel('dev.kaimau.notlar/speech');
    tearDown(() {
      DeviceSpeech.debugAvailable = null;
      DeviceSpeech.debugMicGranted = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(speechEvents, null);
    });

    Future<MockStreamHandlerEventSink? Function()> pumpBar(
      WidgetTester tester, {
      required VoidCallback onAddWord,
      required ValueChanged<String> onRaw,
    }) async {
      MockStreamHandlerEventSink? sink;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            speechEvents,
            MockStreamHandler.inline(
              onListen: (_, s) {
                sink = s;
              },
              onCancel: (_) {
                sink = null;
              },
            ),
          );
      DeviceSpeech.debugAvailable = true;
      DeviceSpeech.debugMicGranted = true;
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
                onRawChanged: onRaw,
                onAddWord: onAddWord,
                onItems: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      return () => sink;
    }

    testWidgets('"… ekle" + kısa sessizlik → dinleme biter, eklenir', (
      tester,
    ) async {
      var adds = 0;
      var raw = '';
      final sink = await pumpBar(
        tester,
        onAddWord: () => adds++,
        onRaw: (t) => raw = t,
      );
      expect(sink(), isNotNull);
      sink()!.success({'text': 'markete süt'});
      await tester.pump();
      sink()!.success({'text': 'markete süt ekle'});
      await tester.pump(const Duration(milliseconds: 300));
      expect(adds, 0, reason: 'hemen değil: konuşma sürüyor olabilir');
      // Aynı sonucun tekrarı beklemeyi uzatmaz.
      sink()!.success({'text': 'markete süt ekle'});
      await tester.pump(const Duration(milliseconds: 350));
      expect(adds, 1);
      expect(raw, 'markete süt ekle');
      expect(sink(), isNull, reason: 'oturum kapandı');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('"ekle"den sonra konuşma sürerse eklenmez', (tester) async {
      var adds = 0;
      final sink = await pumpBar(
        tester,
        onAddWord: () => adds++,
        onRaw: (_) {},
      );
      sink()!.success({'text': 'süt ekle'});
      await tester.pump(const Duration(milliseconds: 300));
      sink()!.success({'text': 'süt eklemeyi unutma'});
      await tester.pump(const Duration(seconds: 1));
      expect(adds, 0);
      expect(sink(), isNotNull, reason: 'dinleme sürüyor');
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('komutla biten konuşmada geri sayım kısa', () {
    expect(
      QuickDropSheet.commandCountdown,
      lessThanOrEqualTo(const Duration(milliseconds: 800)),
    );
    expect(
      QuickDropSheet.commandCountdown + QuickEntryBarState.addWordPause,
      lessThan(const Duration(milliseconds: 1500)),
      reason: '"ekle"den sonra toplam bekleme çok kısa',
    );
  });
}
