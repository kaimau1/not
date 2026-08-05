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
  } on PlatformException catch (e) {
    // Yalnızca "cihazda hiç kilit/kimlik kurulu değil" durumları serbest
    // bırakır (ör. Windows'ta Hello kapalı) — üstteki isDeviceSupported
    // kuralıyla aynı mantık. Diğer her istisna KAPALI sayılır: özellikle
    // LockedOut (5 kez yanlış parmak izi) eskiden buraya düşüp notu AÇIYORDU,
    // yani kilit bilerek yanlış denemeyle aşılabiliyordu.
    return e.code == 'NotAvailable' ||
        e.code == 'NotEnrolled' ||
        e.code == 'PasscodeNotSet';
  }
}
