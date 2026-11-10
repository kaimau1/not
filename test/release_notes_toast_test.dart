import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/release_notes_toast.dart';

void main() {
  const md = '''
# Sürüm notları

Giriş.

## 10 Kasım 2026 {#2026-11-10}
- **Sesle yazma:** klon giderildi.
- Ana ekranda Tümü bütün notları gösterir. Ayrıntı.

## 9 Kasım 2026 {#2026-11-09}
- Eski madde.
''';

  test('ilk kez: yalnız en yeni bölüm', () {
    final r = unseenReleaseNotes(md);
    expect(r.unseen, hasLength(2));
    expect(r.top, '2026-11-10');
    expect(r.topBullets, hasLength(2));
  });

  test('aynı gün yeni sürüm: yalnız görülmemiş madde', () {
    final r = unseenReleaseNotes(
      md,
      seenTop: '2026-11-10',
      seenBullets: ['**Sesle yazma:** klon giderildi.'],
    );
    expect(r.unseen, ['Ana ekranda Tümü bütün notları gösterir. Ayrıntı.']);
  });

  test('günler sonra: aradaki bütün bölümler', () {
    final r = unseenReleaseNotes(md, seenTop: '2026-11-08');
    expect(r.unseen, hasLength(3));
  });

  test('hepsi görülmüş: boş', () {
    final r = unseenReleaseNotes(
      md,
      seenTop: '2026-11-10',
      seenBullets: unseenReleaseNotes(md).topBullets,
    );
    expect(r.unseen, isEmpty);
  });

  test('kısa özet: kalın başlık ya da ilk cümle', () {
    expect(shortReleaseNote('**Sesle yazma:** klon giderildi.'), 'Sesle yazma');
    expect(
      shortReleaseNote('Ana ekranda Tümü bütün notları gösterir. Ayrıntı.'),
      'Ana ekranda Tümü bütün notları gösterir',
    );
    expect(shortReleaseNote('a' * 200).length, lessThanOrEqualTo(90));
  });
}
