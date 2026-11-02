import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notlar/features/auth/data/android_google_auth.dart';

void main() {
  const fast = Duration(milliseconds: 200);
  const slow = Duration(seconds: 4);

  test('anında gelen iptal = seçici hiç açılmadı → tarayıcı akışı', () {
    expect(
      AndroidGoogleAuth.shouldUseBrowserFlow(
        GoogleSignInExceptionCode.canceled,
        fast,
      ),
      isTrue,
    );
  });

  test('insan hızında iptal = kullanıcı kapattı → sessiz', () {
    expect(
      AndroidGoogleAuth.shouldUseBrowserFlow(
        GoogleSignInExceptionCode.canceled,
        slow,
      ),
      isFalse,
    );
  });

  test('yapılandırma hatası her zaman tarayıcıya düşer', () {
    for (final code in [
      GoogleSignInExceptionCode.clientConfigurationError,
      GoogleSignInExceptionCode.providerConfigurationError,
      GoogleSignInExceptionCode.uiUnavailable,
      GoogleSignInExceptionCode.unknownError,
    ]) {
      expect(AndroidGoogleAuth.shouldUseBrowserFlow(code, slow), isTrue);
    }
  });

  test('başka hesap seçildiyse yeniden sorulmaz', () {
    expect(
      AndroidGoogleAuth.shouldUseBrowserFlow(
        GoogleSignInExceptionCode.userMismatch,
        fast,
      ),
      isFalse,
    );
  });
}
