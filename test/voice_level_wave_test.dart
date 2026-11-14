import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/voice_level_wave.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.4): gerçek ses düzeyini izleyen
/// dalga. Tek ticker + tek CustomPaint; düzey olayı widget KURMAZ.
void main() {
  test('çubuk sayısı genişlikten: 16–64', () {
    expect(waveBarsFor(360), 51);
    expect(waveBarsFor(1280), 64);
    expect(waveBarsFor(80), 16);
  });

  test('smoothLevel: yükseliş düşüşten hızlı', () {
    const dt = Duration(milliseconds: 40);
    final up = smoothLevel(0.2, 0.8, dt) - 0.2;
    final down = 0.8 - smoothLevel(0.8, 0.2, dt);
    expect(up, greaterThan(down * 2));
    expect(smoothLevel(0.5, 0.5, dt), 0.5);
  });

  test('düzey 0 → tabanda, 1 → orta çubuk tavanda', () {
    const n = 32;
    for (var ms = 0; ms < 3000; ms += 97) {
      final t = Duration(milliseconds: ms);
      for (var i = 0; i < n; i++) {
        expect(waveBarFactor(i, n, 0, t), lessThanOrEqualTo(0.2));
      }
      expect(waveBarFactor(n ~/ 2, n, 1, t), greaterThanOrEqualTo(0.8));
    }
    // Zarf: uç çubuk ortadakinden alçak.
    expect(
      waveBarFactor(0, n, 1, Duration.zero, reduceMotion: true),
      lessThan(waveBarFactor(n ~/ 2, n, 1, Duration.zero, reduceMotion: true)),
    );
  });

  test('reduceMotion: zamanla değişmez', () {
    for (final level in [0.0, 0.4, 1.0]) {
      final a = waveBarFactor(5, 20, level, Duration.zero, reduceMotion: true);
      final b = waveBarFactor(
        5,
        20,
        level,
        const Duration(milliseconds: 1234),
        reduceMotion: true,
      );
      expect(a, b);
    }
  });

  Widget host(Widget child, {bool disableAnimations = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    ),
  );

  CustomPainter painterOf(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(VoiceLevelWave),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;

  testWidgets('active: false → ticker durur, kare istenmez', (tester) async {
    await tester.pumpWidget(
      host(const VoiceLevelWave(active: false, color: Colors.red)),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.getSize(find.byType(VoiceLevelWave)).height, 32);

    await tester.pumpWidget(
      host(const VoiceLevelWave(active: true, color: Colors.red)),
    );
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(
      host(const VoiceLevelWave(active: false, color: Colors.red)),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('düzey olayı widget kurmaz, yalnız boyar', (tester) async {
    final level = ValueNotifier<double>(0);
    addTearDown(level.dispose);
    await tester.pumpWidget(
      host(VoiceLevelWave(active: true, color: Colors.red, level: level)),
    );
    final painter = painterOf(tester);
    level.value = 0.9;
    await tester.pump(const Duration(milliseconds: 16));
    level.value = 0.3;
    await tester.pump(const Duration(milliseconds: 16));
    expect(identical(painterOf(tester), painter), isTrue);
    expect(
      find.descendant(
        of: find.byType(VoiceLevelWave),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('hareketi azalt: ticker yok, düzey değişince boyanır', (
    tester,
  ) async {
    final level = ValueNotifier<double>(0);
    addTearDown(level.dispose);
    await tester.pumpWidget(
      host(
        VoiceLevelWave(active: true, color: Colors.red, level: level),
        disableAnimations: true,
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    level.value = 0.7;
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'repaint: level');
    await tester.pump();
  });
}
