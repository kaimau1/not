import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// **NOT KİLİDİNİN YÖNTEMİ** (F4.8, kullanıcı kararı 2026-10-19: "kilitli not
/// hem şifre hem desen hem parmak izi seçenekleri olsun").
///
///  * [device]: telefonun parmak izi / ekran kilidi (eski tek yol). Web'de
///    ve ekran kilidi olmayan cihazda engel yoktur.
///  * [password] / [pattern]: uygulamaya özel şifre ya da 3×3 desen. Web'de
///    de çalışır (ayar senkronuyla aynı sır her cihazda). İsteğe bağlı
///    "parmak iziyle de açılsın".
///
/// KİLİT ŞİFRELEME DEĞİLDİR: içerik Firestore'da ve önbellekte düz metin;
/// kilit yalnız uygulamanın notu göstermesini engeller (Ayarlar'da açıkça
/// yazar). Sır düz saklanmaz: PBKDF2-HMAC-SHA256 özeti + rastgele tuz.
enum NoteLockMethod { device, password, pattern }

class NoteLockConfig {
  const NoteLockConfig({
    this.method = NoteLockMethod.device,
    this.salt = '',
    this.hash = '',
    this.iterations = kLockIterations,
    this.biometric = false,
  });

  /// SharedPreferences anahtarı (ayar senkronunda eşitlenir).
  static const prefsKey = 'note_lock';

  final NoteLockMethod method;
  final String salt;
  final String hash;
  final int iterations;

  /// Şifre/desen yönteminde parmak izi (cihaz kilidi) de kabul edilir mi.
  final bool biometric;

  bool get usesSecret =>
      method != NoteLockMethod.device && salt.isNotEmpty && hash.isNotEmpty;

  String toJson() => jsonEncode({
    'method': method.name,
    if (salt.isNotEmpty) 'salt': salt,
    if (hash.isNotEmpty) 'hash': hash,
    'iter': iterations,
    'bio': biometric,
  });

  static NoteLockConfig fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const NoteLockConfig();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final method = NoteLockMethod.values.firstWhere(
        (m) => m.name == map['method'],
        orElse: () => NoteLockMethod.device,
      );
      final config = NoteLockConfig(
        method: method,
        salt: map['salt'] as String? ?? '',
        hash: map['hash'] as String? ?? '',
        iterations: (map['iter'] as num?)?.toInt() ?? kLockIterations,
        biometric: map['bio'] as bool? ?? false,
      );
      // Sırsız şifre/desen kaydı (bozuk) cihaz kilidine düşer.
      return config.method == NoteLockMethod.device || config.usesSecret
          ? config
          : const NoteLockConfig();
    } catch (_) {
      return const NoteLockConfig();
    }
  }
}

const kLockIterations = 20000;

/// Desenin metin hâli: noktaların sırası (0–8), tireyle.
String patternSecret(List<int> dots) => dots.join('-');

/// En az 4 nokta (Android'in kuralı).
const kMinPatternDots = 4;
const kMinPasswordLength = 4;

/// Yeni sır için yapılandırma (rastgele tuz).
NoteLockConfig createNoteLock(
  NoteLockMethod method,
  String secret, {
  bool biometric = false,
  int iterations = kLockIterations,
  Random? random,
}) {
  final rnd = random ?? Random.secure();
  final salt = base64Url.encode([
    for (var i = 0; i < 16; i++) rnd.nextInt(256),
  ]);
  return NoteLockConfig(
    method: method,
    salt: salt,
    hash: hashLockSecret(secret, salt, iterations),
    iterations: iterations,
    biometric: biometric,
  );
}

bool verifyNoteLock(NoteLockConfig config, String secret) {
  if (!config.usesSecret) return false;
  final a = hashLockSecret(secret, config.salt, config.iterations);
  final b = config.hash;
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// PBKDF2-HMAC-SHA256, tek blok (32 bayt), base64.
String hashLockSecret(String secret, String salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  var u = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= u[j];
    }
  }
  return base64Url.encode(out);
}
