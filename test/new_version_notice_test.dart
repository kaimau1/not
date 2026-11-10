import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_update.dart';

/// Oto güncelleme (2026-11-10 yeniden yazım): GitHub Release'inden bizim APK
/// seçilir, sürüm adı hane hane karşılaştırılır.
void main() {
  test('sürüm adı hane hane karşılaştırılır (2026-11-09)', () {
    expect(isNewerVersion('1.2.33', '1.2.31'), isTrue);
    expect(isNewerVersion('1.2.10', '1.2.9'), isTrue);
    expect(isNewerVersion('1.3.0', '1.2.99'), isTrue);
    expect(isNewerVersion('1.2.31', '1.2.31'), isFalse);
    expect(isNewerVersion('1.2.30', '1.2.31'), isFalse);
    // Yerel derleme (pubspec 1.2.0) CI sürümünden hep eskidir.
    expect(isNewerVersion('1.2.5', '1.2.0'), isTrue);
  });

  test('Release APK adresi CI adlandırmasıyla aynı (2026-11-09)', () {
    expect(
      releaseApkUrl('1.2.29'),
      'https://github.com/kaimau1/not/releases/download/v1.2.29/notlar-v1.2.29.apk',
    );
  });

  test('Release JSON\'undan notlar APK\'sı seçilir', () {
    final info = AppUpdate.pickAsset({
      'tag_name': 'v1.2.40',
      'assets': [
        {'name': 'app-release.aab', 'browser_download_url': 'x', 'size': 1},
        {
          'name': 'notlar-v1.2.40.apk',
          'browser_download_url': 'https://example.invalid/a.apk',
          'size': 61234567,
        },
      ],
    });
    expect(info?.version, '1.2.40');
    expect(info?.url, 'https://example.invalid/a.apk');
    expect(info?.size, 61234567);
  });

  test('varlık yoksa etiketten adres kurulur; bozuk JSON null', () {
    final info = AppUpdate.pickAsset({'tag_name': 'v1.2.41', 'assets': []});
    expect(info?.url, releaseApkUrl('1.2.41'));
    expect(AppUpdate.pickAsset({'tag_name': 'nightly', 'assets': []}), isNull);
    expect(AppUpdate.pickAsset('çöp'), isNull);
  });
}
