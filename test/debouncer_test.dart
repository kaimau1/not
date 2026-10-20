import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/debouncer.dart';

/// Regresyon: "not düzenlerken uygulamayı tamamen kapatınca not kaydolmuyor,
/// kayboluyor". Kaybın bir ayağı buradaydı: debounce zamanlayıcısı her tuş
/// vuruşunda sıfırlandığından aralıksız yazan kullanıcıda hiç kayıt olmuyordu.
///
/// `testWidgets` kullanılıyor çünkü sahte saati (`tester.pump(duration)`)
/// fazladan bağımlılık olmadan yalnız o sağlıyor.
void main() {
  testWidgets('aralıksız yazımda maxWait dolunca kayıt yapılır', (tester) async {
    final debouncer = Debouncer(
      
    );
    var saves = 0;
    // 5 saniye boyunca her 100 ms'de bir "tuş vuruşu": delay hiç dolmaz.
    for (var i = 0; i < 50; i++) {
      debouncer(() => saves++);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(saves, greaterThanOrEqualTo(1));
    debouncer.dispose();
  });

  testWidgets('maxWait dolduktan sonra yeni yazım yine kaydedilir', (
    tester,
  ) async {
    final debouncer = Debouncer(
      
    );
    var saves = 0;
    for (var i = 0; i < 40; i++) {
      debouncer(() => saves++);
      await tester.pump(const Duration(milliseconds: 100));
    }
    final afterFirst = saves;
    expect(afterFirst, greaterThanOrEqualTo(1));
    // Üst sınır zamanlayıcısı tetiklendikten sonra SIFIRLANMALI; yoksa ikinci
    // turda bir daha hiç tetiklenmezdi.
    for (var i = 0; i < 40; i++) {
      debouncer(() => saves++);
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(saves, greaterThan(afterFirst));
    debouncer.dispose();
  });

  testWidgets('flush bekleyen kaydı hemen çalıştırır, ikinci kez çalıştırmaz', (
    tester,
  ) async {
    final debouncer = Debouncer();
    var saves = 0;
    debouncer(() => saves++);
    debouncer.flush();
    expect(saves, 1);
    // Bekleyen kalmadı: ne ikinci flush ne de zamanlayıcı bir daha yazmalı.
    debouncer.flush();
    await tester.pump(const Duration(seconds: 5));
    expect(saves, 1);
    debouncer.dispose();
  });

  testWidgets('cancel bekleyen kaydı çalıştırmaz', (tester) async {
    final debouncer = Debouncer();
    var saves = 0;
    debouncer(() => saves++);
    debouncer.cancel();
    await tester.pump(const Duration(seconds: 5));
    expect(saves, 0);
    debouncer.dispose();
  });

  testWidgets('duraklamada delay dolar ve tek kayıt yapılır', (tester) async {
    final debouncer = Debouncer();
    var saves = 0;
    debouncer(() => saves++);
    debouncer(() => saves++);
    debouncer(() => saves++);
    await tester.pump(const Duration(milliseconds: 600));
    expect(saves, 1);
    debouncer.dispose();
  });
}
