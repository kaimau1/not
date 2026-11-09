import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_update.dart';

/// F18.21: "Yeni sürüm var" yalnız gerçekten yeni derlemede.
void main() {
  test('yeni derleme', () {
    expect(isNewerBuild(600, 583), isTrue);
    expect(isNewerBuild(583, 583), isFalse);
    expect(isNewerBuild(500, 583), isFalse);
  });

  test('sürüm adı hane hane karşılaştırılır (2026-11-09)', () {
    expect(isNewerVersion('1.2.33', '1.2.31'), isTrue);
    expect(isNewerVersion('1.2.10', '1.2.9'), isTrue);
    expect(isNewerVersion('1.3.0', '1.2.99'), isTrue);
    expect(isNewerVersion('1.2.31', '1.2.31'), isFalse);
    expect(isNewerVersion('1.2.30', '1.2.31'), isFalse);
  });

  test('bilinmeyen ya da yerel (1) derlemede söylenmez', () {
    expect(isNewerBuild(null, 583), isFalse);
    expect(isNewerBuild(600, null), isFalse);
    expect(isNewerBuild(600, 1), isFalse);
  });

  test('Release APK adresi CI adlandırmasıyla aynı (2026-11-09)', () {
    expect(
      releaseApkUrl('1.2.29'),
      'https://github.com/kaimau1/not/releases/download/v1.2.29/notlar-v1.2.29.apk',
    );
  });
}
