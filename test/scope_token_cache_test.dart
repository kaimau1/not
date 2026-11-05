import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';

void main() {
  group('ScopeTokenCache', () {
    test(
      'geçerli jeton yenilenmez; süresi yaklaşınca TEK sessiz yenileme',
      () async {
        var now = DateTime.utc(2026, 11, 4, 3);
        var calls = 0;
        final cache = ScopeTokenCache(
          clock: () => now,
          silentRefresh: () async {
            calls++;
            await Future<void>.delayed(Duration.zero);
            return (
              token: 't$calls',
              expiry: now.add(const Duration(hours: 1)),
            );
          },
        );
        cache.put('t0', now.add(const Duration(minutes: 30)));
        expect(await cache.get(), 't0');
        expect(calls, 0);

        now = now.add(const Duration(minutes: 29)); // 1 dk kaldı < 2 dk pay
        final results = await Future.wait([
          cache.get(),
          cache.get(),
          cache.get(),
        ]);
        expect(results, ['t1', 't1', 't1']);
        expect(calls, 1, reason: 'eşzamanlı istekler aynı yenilemeyi bekler');
      },
    );

    test('sessiz yenileme olmazsa null (arayüz "bağla" der)', () async {
      final cache = ScopeTokenCache(silentRefresh: () async => null);
      expect(await cache.get(), isNull);
      final throwing = ScopeTokenCache(
        silentRefresh: () async => throw StateError('pencere gerekli'),
      );
      expect(await throwing.get(), isNull);
    });
  });
}
