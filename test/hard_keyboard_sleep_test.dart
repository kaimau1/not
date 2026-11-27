import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/hard_keyboard.dart';

/// Bluetooth klavye uyuyunca "çıkarıldı" gelir; yakın zamanda tuşa
/// basıldıysa sanal klavye açılmasın (tablet bulgusu 2026-11-09).
void main() {
  setUp(HardKeyboard.resetForTest);
  tearDown(HardKeyboard.resetForTest);

  testWidgets('init() açılışta klavye varsa kapatma izleyicisini kurar', (
    tester,
  ) async {
    addTearDown(tester.view.resetViewInsets);
    const ch = MethodChannel('dev.kaimau.notlar/keyboard');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (call) async {
          if (call.method == 'present') return true;
          return null;
        });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await HardKeyboard.init();
      expect(HardKeyboard.present.value, isTrue);

      HardKeyboard.toggleSoft();
      expect(HardKeyboard.softWanted.value, isTrue);

      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await tester.pump();
      expect(HardKeyboard.softWanted.value, isTrue);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      expect(HardKeyboard.softWanted.value, isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, null);
    }
  });

  testWidgets('toggleSoft odakli alanin odagini korur', (tester) async {
    final f1 = FocusNode();
    final f2 = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(focusNode: f1),
              TextField(focusNode: f2),
            ],
          ),
        ),
      ),
    );

    HardKeyboard.report(true);
    f1.requestFocus();
    await tester.pump();
    expect(f1.hasFocus, isTrue);

    HardKeyboard.toggleSoft();
    await tester.pump();
    expect(f1.hasFocus, isTrue);
    expect(f2.hasFocus, isFalse);

    await tester.pumpWidget(const SizedBox());
    f1.dispose();
    f2.dispose();
  });

  testWidgets('son tuştan hemen sonra gelen "çıktı" yok sayılır', (
    tester,
  ) async {
    HardKeyboard.report(true);
    expect(HardKeyboard.present.value, isTrue);
    // Tuş: el ile kaydet (test motoru tuşu işler).
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    HardKeyboard.report(false);
    // Kanal yok (test): yeniden sorgu olmadan önce hâlâ takılı sayılır.
    expect(HardKeyboard.present.value, isTrue);
    HardKeyboard.resetForTest(); // bekleyen yeniden sorgu zamanlayıcısı
  });

  test('hiç tuş yoksa "çıktı" hemen geçerli', () {
    HardKeyboard.report(true);
    HardKeyboard.report(false);
    expect(HardKeyboard.present.value, isFalse);
  });

  testWidgets('süre geçtiyse "çıktı" geçerli', (tester) async {
    var now = DateTime(2026, 11, 9, 12);
    HardKeyboard.clock = () => now;
    HardKeyboard.report(true);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    now = now.add(HardKeyboard.sleepGrace + const Duration(seconds: 1));
    HardKeyboard.report(false);
    expect(HardKeyboard.present.value, isFalse);
  });

  // P78 KT-18 (tablet turu 2026-11-18): GERİ sanal klavyeyi kapatınca ⌨
  // "açık" kalıyordu; sonraki ⌨ onu kapatıyordu ("iki kez bastım").
  testWidgets('KT-18: sanal klavye kapanınca ⌨ isteği düşer', (tester) async {
    addTearDown(tester.view.resetViewInsets);
    HardKeyboard.report(true);
    HardKeyboard.toggleSoft();
    expect(HardKeyboard.softWanted.value, isTrue);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pump();
    expect(HardKeyboard.softWanted.value, isTrue);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    expect(HardKeyboard.softWanted.value, isFalse);
    // İstek yokken pay değişimi bir şey yapmaz; yeni ⌨ yine AÇAR.
    HardKeyboard.toggleSoft();
    expect(HardKeyboard.softWanted.value, isTrue);
  });
}
