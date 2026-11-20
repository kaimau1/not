import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/router.dart' show quickAddLinkText;
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// ⚡ Hızlı ekle'nin uygulama dışı kapıları (KARAR PLAN 1.0b P2/P3,
/// 2026-11-20): uygulama kısayolu `notlar://ekle`, isteğe bağlı `?metin=`.
void main() {
  test('notlar://ekle adresi levhanın metnini verir, başka adres vermez', () {
    expect(quickAddLinkText(Uri.parse('notlar://ekle')), '');
    expect(
      quickAddLinkText(Uri.parse('notlar://ekle?metin=s%C3%BCt%20ekmek')),
      'süt ekmek',
    );
    expect(quickAddLinkText(Uri.parse('notlar://add?text=milk')), 'milk');
    expect(quickAddLinkText(Uri.parse('notlar://voice')), isNull);
    expect(quickAddLinkText(Uri.parse('notlar://new?type=text')), isNull);
    expect(quickAddLinkText(Uri.parse('https://ekle?metin=x')), isNull);
    final long = 'a' * 5000;
    expect(
      quickAddLinkText(Uri.parse('notlar://ekle?metin=$long'))!.length,
      2000,
    );
  });

  test('istek tek seferlik tüketilir', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final n = c.read(quickDropRequestProvider.notifier);
    expect(n.take(), isNull);
    n.request();
    expect(c.read(quickDropRequestProvider), '');
    expect(n.take(), '');
    expect(n.take(), isNull);
    n.request('süt');
    expect(n.take(), 'süt');
  });
}
