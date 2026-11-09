import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';
import 'package:notlar/features/auth/data/loopback_oauth.dart';

/// GMS'siz Android'de Firebase sayfasız Google yetkisi (tablet 2026-11-09).
void main() {
  test('PKCE: S256 meydan okuma (Python hashlib ile doğrulandı)', () {
    expect(
      pkceChallenge('dBjftJeZ4CVP-mJ92K-fZmY1Hm56rMNWs0sFuaKDp2I'),
      'e8U3LA1AcZCSuJ8HhNodl6OQzeK4ksxQvWmwqwqwKzA',
    );
  });

  test('onay adresi kapsam, PKCE ve çevrimdışı erişim ister', () {
    final u = loopbackAuthUrl(
      clientId: 'c',
      scopes: ['a', 'b'],
      redirect: 'http://127.0.0.1:5000',
      state: 's',
      challenge: 'x',
      email: 'e@x',
    );
    expect(u.queryParameters['scope'], 'a b');
    expect(u.queryParameters['code_challenge_method'], 'S256');
    expect(u.queryParameters['access_type'], 'offline');
    expect(u.queryParameters['login_hint'], 'e@x');
  });

  test('jeton yanıtı ayrıştırılır, bozuk yanıt null', () {
    final now = DateTime(2026, 11, 9);
    final t = parseTokenResponse(
      '{"access_token":"ya29.a","expires_in":3600,"refresh_token":"r"}',
      now,
    )!;
    expect(t.accessToken, 'ya29.a');
    expect(t.refreshToken, 'r');
    expect(t.expiry, now.add(const Duration(seconds: 3540)));
    expect(parseTokenResponse('{"error":"x"}', now), isNull);
    expect(parseTokenResponse('html', now), isNull);
  });

  test('saklı kayıt: yenileme anahtarı yalnız aynı hesabın', () {
    final now = DateTime(2026, 11, 9);
    final past = now.subtract(const Duration(minutes: 1));
    final raw = 'tok|${past.millisecondsSinceEpoch}|u1|ref';
    expect(parseScopeToken(raw, 'u1', now), isNull); // süresi dolmuş
    expect(scopeRefreshToken(raw, 'u1'), 'ref');
    expect(scopeRefreshToken(raw, 'u2'), isNull);
    expect(scopeRefreshToken('tok|1|u1|', 'u1'), isNull);
    final later = now.add(const Duration(minutes: 5)).millisecondsSinceEpoch;
    expect(parseScopeToken('tok|$later|u1|ref', 'u1', now)?.token, 'tok');
  });
}
