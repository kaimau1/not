import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/friendly_error.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Giriş hatalarının KULLANICIYA gösterilecek karşılıkları.
///
/// KÖK NEDEN (kullanıcı, 2026-08-07: "Google'sız giriş sadece admin uyarısı
/// veriyor"): giriş ekranı her hatayı `loginError(e.toString())` ile ham
/// basıyordu. Firebase anonim oturum açma yöntemi konsolda KAPALIYKEN gelen
/// `admin-restricted-operation` bu yüzden "Giriş başarısız:
/// [firebase_auth/admin-restricted-operation] ..." diye görünüyor, kullanıcı
/// ne yapacağını anlamıyordu. Kodlar artık anlamlarına çevriliyor.
///
/// [guest] = "Hesapsız devam et" yolu mu? Aynı kod (`operation-not-allowed`)
/// Google yolunda BAŞKA bir şey anlatır (Google sağlayıcısı kapalı).
String authErrorText(
  AppLocalizations l10n,
  Object error, {
  bool guest = false,
}) {
  final code = _codeOf(error);
  if (_isCancel(code)) return l10n.signInCanceled;
  switch (code) {
    case 'admin-restricted-operation':
    case 'operation-not-allowed':
      return guest ? l10n.guestSignInUnavailable : l10n.googleSignInUnavailable;
    case 'network-request-failed':
    case 'unavailable':
      return l10n.signInNetworkError;
  }
  return l10n.loginError(friendlyError(l10n, error));
}

/// Kullanıcının kendisi vazgeçti mi? (Hesap seçiciyi kapattı / geri tuşu.)
/// Bunun için ekrana hata basmak yanlış: ortada bir arıza yok.
bool isSignInCancel(Object error) => _isCancel(_codeOf(error));

bool _isCancel(String code) =>
    code == 'canceled' ||
    code == 'cancelled' ||
    code == 'popup-closed-by-user' ||
    code == 'web-context-canceled' ||
    code == 'sign_in_canceled';

/// Hata kodu. FirebaseAuthException kodu doğrudan taşır; google_sign_in 7.x
/// kendi `GoogleSignInException`ını atıyor (paket türüne bağımlı kalmamak
/// için metninden okunur).
String _codeOf(Object error) {
  if (error is FirebaseAuthException) return error.code;
  final text = error.toString().toLowerCase();
  for (final code in const [
    'admin-restricted-operation',
    'operation-not-allowed',
    'network-request-failed',
    'popup-closed-by-user',
    'web-context-canceled',
    'canceled',
    'cancelled',
  ]) {
    if (text.contains(code)) return code;
  }
  return '';
}
