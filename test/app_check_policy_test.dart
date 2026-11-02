import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_check_policy.dart';

void main() {
  test('web: anahtar yoksa App Check etkinleştirilmez', () {
    expect(appCheckSupported(isWeb: true, isAndroid: false, webSiteKey: ''),
        isFalse);
    expect(appCheckSupported(isWeb: true, isAndroid: false, webSiteKey: '  '),
        isFalse);
  });
  test('web: anahtar varsa etkinleştirilir', () {
    expect(
        appCheckSupported(isWeb: true, isAndroid: false, webSiteKey: '6Lc_x'),
        isTrue);
  });
  test('Android her zaman, diğer platformlar asla', () {
    expect(appCheckSupported(isWeb: false, isAndroid: true, webSiteKey: ''),
        isTrue);
    expect(appCheckSupported(isWeb: false, isAndroid: false, webSiteKey: 'k'),
        isFalse);
  });
}
