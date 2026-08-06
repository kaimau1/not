import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/upload_queue.dart';

/// Ek yükleme hata durumu: şeritteki "yeniden dene" rozeti buna bakıyor.
/// Kalıcı hatada kullanıcı sonsuz çarka bakıyordu (2026-08-06).
void main() {
  late ProviderContainer container;
  UploadFailuresNotifier notifier() =>
      container.read(uploadFailuresProvider.notifier);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('başlangıçta hata yok', () {
    expect(container.read(uploadFailuresProvider), isEmpty);
  });

  test('fail deneme sayısını yazar, clear siler', () {
    notifier().fail('a', 1);
    notifier().fail('a', 2);
    expect(container.read(uploadFailuresProvider)['a'], 2);

    notifier().clear('a');
    expect(container.read(uploadFailuresProvider), isEmpty);
  });

  test('olmayan anahtarı temizlemek durumu değiştirmez', () {
    notifier().fail('a', 1);
    final before = container.read(uploadFailuresProvider);
    notifier().clear('yok');
    expect(identical(container.read(uploadFailuresProvider), before), isTrue);
  });

  test('retain yalnız hâlâ var olan ekleri tutar', () {
    notifier().fail('a', 3);
    notifier().fail('silinen', 5);
    notifier().retain({'a'});
    expect(container.read(uploadFailuresProvider), {'a': 3});
  });

  test('retain hepsi yaşıyorsa yeni harita üretmez', () {
    notifier().fail('a', 1);
    final before = container.read(uploadFailuresProvider);
    notifier().retain({'a', 'b'});
    expect(identical(container.read(uploadFailuresProvider), before), isTrue);
  });

  // Rozet eşiği: 3 deneme ≈ 1+2+4 dk. Geçici kesinti bu eşiğe gelmeden
  // düzelir; eşik düşerse geçici hatada da "yüklenemedi" gösterilir.
  test('eşik altındaki deneme sayısı rozeti tetiklemez', () {
    notifier().fail('a', 2);
    expect((container.read(uploadFailuresProvider)['a'] ?? 0) >= 3, isFalse);
    notifier().fail('a', 3);
    expect((container.read(uploadFailuresProvider)['a'] ?? 0) >= 3, isTrue);
  });
}
