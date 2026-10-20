import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';

import 'note_lock.dart';

/// Kilitli notlar için kapı yapılandırması (F4.8). Uygulama kökü bağlar
/// (bkz. `noteLockBinderProvider`): seçili yöntem, iletişim kutusunun
/// açılacağı bağlam ve şifre/desen sorusu. Bağlanmamışsa (testler, çok erken
/// açılış) eski davranış: cihaz kilidi.
abstract final class NoteLockGate {
  static NoteLockConfig config = const NoteLockConfig();

  /// Şifre/desen sorulacak bağlam (gezginin bağlamı).
  static BuildContext? Function()? context;

  /// Şifre/desen sorusu (arayüz katmanı kurar). true = açıldı.
  static Future<bool> Function(BuildContext context, String reason)? prompt;
}

/// Kilitli notlara erişim kapısı. Yöntem [NoteLockGate.config]'ten:
/// şifre/desen ise uygulamanın kendi sorusu, değilse cihazın biyometrik /
/// ekran kilidi. Doğrulama iptal/başarısız olursa not açılmaz.
Future<bool> authenticateForNote(String reason) async {
  final config = NoteLockGate.config;
  if (config.usesSecret) {
    final context = NoteLockGate.context?.call();
    final prompt = NoteLockGate.prompt;
    if (context != null && context.mounted && prompt != null) {
      return prompt(context, reason);
    }
    // Soru gösterilemiyor (gezgin yok): kapı KAPALI kalır.
    return false;
  }
  return deviceAuthenticate(reason);
}

/// Cihazın biyometrik / ekran kilidi. Cihazda hiçbir kilit yoksa engel
/// çıkarılmaz (kullanıcı bilinçli olarak korumasız bir cihaz kullanıyor).
Future<bool> deviceAuthenticate(String reason) async {
  // Web'de yerel kimlik doğrulama yok (eklenti desteklemiyor).
  if (kIsWeb) return true;
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
    // bırakır — üstteki isDeviceSupported kuralıyla aynı mantık. Diğer her
    // istisna KAPALI sayılır: özellikle LockedOut (5 kez yanlış parmak izi)
    // eskiden buraya düşüp notu AÇIYORDU, yani kilit bilerek yanlış
    // denemeyle aşılabiliyordu.
    return e.code == 'NotAvailable' ||
        e.code == 'NotEnrolled' ||
        e.code == 'PasscodeNotSet';
  }
}

/// Cihazda parmak izi / ekran kilidi var mı (şifre/desen sorusundaki
/// parmak izi düğmesi için).
Future<bool> deviceAuthAvailable() async {
  if (kIsWeb) return false;
  try {
    return await LocalAuthentication().isDeviceSupported();
  } catch (_) {
    return false;
  }
}
