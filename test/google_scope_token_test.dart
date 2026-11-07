import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';

/// GMS'siz Android (Huawei, 2026-11-07): tarayıcıdan alınan kapsam jetonu
/// cihazda `jeton|bitişMs|uid` saklanır; başka hesabın ya da süresi dolmuşu
/// kullanılmaz.
void main() {
  final now = DateTime(2026, 11, 7, 15);
  final later = now.add(const Duration(minutes: 30)).millisecondsSinceEpoch;

  test('geçerli jeton okunur', () {
    expect(parseScopeToken('abc|$later|u1', 'u1', now)?.token, 'abc');
  });

  test('başka hesap, süresi dolmuş ya da bozuk kayıt null', () {
    expect(parseScopeToken('abc|$later|u2', 'u1', now), isNull);
    final past = now.subtract(const Duration(minutes: 1));
    expect(
      parseScopeToken('abc|${past.millisecondsSinceEpoch}|u1', 'u1', now),
      isNull,
    );
    expect(parseScopeToken('bozuk', 'u1', now), isNull);
    expect(parseScopeToken(null, 'u1', now), isNull);
  });
}
