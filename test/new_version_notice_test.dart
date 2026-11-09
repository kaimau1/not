import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_update.dart';

/// F18.21: "Yeni sürüm var" yalnız gerçekten yeni derlemede.
void main() {
  test('yeni derleme', () {
    expect(isNewerBuild(600, 583), isTrue);
    expect(isNewerBuild(583, 583), isFalse);
    expect(isNewerBuild(500, 583), isFalse);
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
