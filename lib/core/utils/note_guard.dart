import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Kilitli notlara erişim için biyometrik/ekran kilidi doğrulaması.
/// Cihazda hiçbir kilit yoksa engel çıkarılmaz (kullanıcı bilinçli olarak
/// korumasız bir cihaz kullanıyordur); doğrulama iptal/başarısız olursa
/// not açılmaz.
Future<bool> authenticateForNote(String reason) async {
  final auth = LocalAuthentication();
  try {
    final supported = await auth.isDeviceSupported();
    if (!supported) return true;
    return await auth.authenticate(
      localizedReason: reason,
      // Uygulama kısa süreliğine arka plana düşse de doğrulama sürsün.
      persistAcrossBackgrounding: true,
    );
  } on PlatformException {
    // Platform doğrulamayı hiç sunamadıysa (ör. Windows'ta Hello kapalı)
    // kullanıcıyı notundan mahrum bırakma.
    return true;
  }
}
