import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/gizlilik_sayfalari.dart';

/// PL4 bekçisi (16K E5/E6): gizlilik metninin TEK kaynağı
/// `PRIVACY_POLICY.md`; web'deki iki sayfa ondan üretilir. Metin değişip
/// sayfalar üretilmezse kırmızı: `dart run tool/gizlilik_sayfalari.dart`.
void main() {
  final md = File('PRIVACY_POLICY.md').readAsStringSync();

  test('web/gizlilik.html PRIVACY_POLICY.md ile aynı', () {
    expect(
      File('web/gizlilik.html').readAsStringSync(),
      privacyHtml(md),
      reason: 'dart run tool/gizlilik_sayfalari.dart',
    );
  });

  test('web/hesap-silme.html PRIVACY_POLICY.md ile aynı', () {
    expect(
      File('web/hesap-silme.html').readAsStringSync(),
      deletionHtml(md),
      reason: 'dart run tool/gizlilik_sayfalari.dart',
    );
  });

  test(
    'silme sayfası adımları, silineni ve giriş yapıp silme bağlantısını taşır',
    () {
      final html = deletionHtml(md);
      expect(html, contains('href="$deleteAccountAppPath"'));
      expect(html, contains('<h2>Veri saklama ve silme</h2>'));
      expect(html, contains('<h2>İletişim</h2>'));
      expect(html, contains('mailto:'));
    },
  );

  test('politika Google izinlerini ve web silme sayfasını anlatır', () {
    // Eskiden yalnız web/gizlilik.html anlatıyordu (E5 tutarsızlığı).
    for (final scope in [
      'drive.appdata',
      'drive.file',
      'calendar.readonly',
      'calendar.events',
      'tasks',
      'gmail.readonly',
    ]) {
      expect(md, contains(scope));
    }
    expect(md, contains('Sınırlı Kullanım'));
    expect(md, contains('hesap-silme.html'));
  });
}
