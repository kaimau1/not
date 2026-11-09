import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/hard_keyboard.dart';

/// Bluetooth klavye uyuyunca "çıkarıldı" gelir; yakın zamanda tuşa
/// basıldıysa sanal klavye açılmasın (tablet bulgusu 2026-11-09).
void main() {
  setUp(HardKeyboard.resetForTest);
  tearDown(HardKeyboard.resetForTest);

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
}
