import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/listening_visuals.dart';
import 'package:notlar/features/notes/presentation/voice_level_wave.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart';

/// P63 PB5 (plan §4.4): dinleme kartı GERÇEK ses düzeyini gösterir, düzey
/// olayı kartı kurmaz; sessizlik geri sayımı kartın içinde, yuvası hep
/// ayrılmış (kart boyu sabit); geniş ekranda kart 560'ta durur, çubuklar
/// şişmez.
void main() {
  final level = ValueNotifier<double>(0);
  final silence = ValueNotifier<double>(0);
  setUp(() {
    level.value = 0;
    silence.value = 0;
  });

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ListeningCard(
              mode: ListeningMode.dictation,
              active: true,
              title: 'Dinliyorum...',
              subtitle: 'Konuştukça imlecin olduğu yere yazılır',
              silenceHint: 'Sessizlik — birazdan biter',
              level: level,
              silence: silence,
              clock: const Text('0:02'),
              action: ListeningActionButton(
                listening: true,
                label: 'Bitir',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  final card = find.byKey(const ValueKey('listening-card-dictation'));

  testWidgets('düzey olayı kartı kurmaz; dalga düzeyi dinler', (tester) async {
    await pump(tester, const Size(360, 800));
    expect(find.byType(VoiceLevelWave), findsOneWidget);
    final counter = BuildCounter()..start();
    addTearDown(counter.stop);
    for (var i = 0; i < 10; i++) {
      level.value = i / 10;
      await tester.pump(const Duration(milliseconds: 50));
    }
    counter.stop();
    expect(counter.of('ListeningCard'), 0);
    expect(counter.of('ListeningActionButton'), 0);
  });

  testWidgets('sessizlik 0 → 0.5 → 1: kart boyu sabit, çizgi ve alt yazı', (
    tester,
  ) async {
    await pump(tester, const Size(360, 800));
    final h0 = tester.getSize(card).height;
    expect(find.byKey(const ValueKey('voice-silence-bar')), findsOneWidget);
    expect(find.text('Sessizlik — birazdan biter'), findsNothing);
    for (final v in const [0.5, 1.0]) {
      silence.value = v;
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(card).height, h0);
    }
    expect(find.text('Sessizlik — birazdan biter'), findsOneWidget);
    expect(h0, inInclusiveRange(90, 150));
  });

  testWidgets('1280 dp: kart 560 dp, ortalı; dalga çubuğu şişmez', (
    tester,
  ) async {
    await pump(tester, const Size(1280, 800));
    final rect = tester.getRect(card);
    expect(rect.width, lessThanOrEqualTo(560));
    expect(rect.center.dx, closeTo(640, 1));
    final wave = tester.getSize(find.byType(VoiceLevelWave));
    // Çubuk adımı 7 dp (3 + 4): sayı genişlikten türer.
    expect(waveBarsFor(wave.width), (wave.width / 7).floor().clamp(16, 64));
  });
}
