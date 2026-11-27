import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'note_e2ee.dart';
import 'note_lock.dart';
import 'run_heavy.dart';

/// Faz 4 — **Kilitli Not E2EE Anahtar Oturumu**.
///
/// Kilitli notun gövdesi ve maddeleri buluta yazılmadan önce istemcide
/// `AES-256-GCM` ([NoteE2ee]) ile şifrelenir.
///
/// Anahtar kaynağı:
///  1. Şifre/desen kilidi kuruluysa: kullanıcı sırrından + tuzdan PBKDF2 ile
///     türetilir (tüm cihazlarda aynı şifreyle aynı anahtar üretilir!).
///  2. Cihaz kilidi kullanılıyorsa: `FlutterSecureStorage`'da saklanan 256-bit
///     cihaz anahtarı.
///
/// Anahtar oturum boyunca bellekte tutulur; çıkışta [clear] çağrılır.
/// Testlerde [setKey] ile doğrudan bellek anahtarı verilebilir.
abstract final class NoteE2eeSession {
  static const _storageKey = 'notlar_e2ee_master_v1';
  static const _storage = FlutterSecureStorage();

  static Uint8List? _key;

  /// Etkin 256-bit E2EE anahtarı; henüz yüklenmediyse/kilidi açılmadıysa null.
  static Uint8List? get key => _key;

  static bool get isReady => _key != null;

  /// Bellek anahtarını doğrudan ayarlar (ör. şifre/desen kilidi açıldığında
  /// ya da testlerde).
  static void setKey(Uint8List? value) {
    if (value != null && value.length != NoteE2ee.keyLength) {
      throw ArgumentError('E2EE key must be 32 bytes');
    }
    _key = value == null ? null : Uint8List.fromList(value);
  }

  /// Şifre/desen kilidinin sırrından deterministik 256-bit anahtar türetip
  /// etkinleştirir ve cihazın güvenli deposunda saklar.
  static Future<Uint8List> unlockWithSecret(
    NoteLockConfig config,
    String secret,
  ) async {
    final salt = 'e2ee:${config.salt}';
    final iterations = config.iterations;
    final derived = await runHeavy(
      () => NoteE2ee.deriveKey(secret, salt, iterations: iterations),
    );
    _key = derived;
    await _persist(derived);
    return derived;
  }

  /// Cihazın güvenli deposundaki mevcut anahtarı YALNIZ okur; yoksa yeni
  /// anahtar üretmez (`null` döner). Şifre/desen kilidinde biyometrik açılış
  /// bu metodu kullanmalıdır.
  static Future<Uint8List?> loadCachedKey() async {
    if (_key != null) return _key;
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = base64Url.decode(raw);
        if (decoded.length == NoteE2ee.keyLength) {
          _key = Uint8List.fromList(decoded);
          return _key;
        }
      }
    } catch (_) {
      // Depoya erişilemezse null döner.
    }
    return null;
  }

  /// Cihazın güvenli deposundan mevcut anahtarı yükler; yoksa cihaz kilidi
  /// için yeni 256-bit anahtar üretir.
  static Future<Uint8List?> ensureDeviceKey() async {
    final cached = await loadCachedKey();
    if (cached != null) return cached;
    try {
      final fresh = NoteE2ee.generateKey();
      _key = fresh;
      await _persist(fresh);
      return fresh;
    } catch (_) {
      return _key;
    }
  }

  /// Güvenli depodaki anahtarı ve bellek kopyasını siler (sıfırlama/çıkış).
  static Future<void> clearPersistedKey() async {
    clear();
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {
      // Test veya desteklenmeyen ortamda sessizce geçer.
    }
  }

  static Future<void> _persist(Uint8List key) async {
    try {
      await _storage.write(key: _storageKey, value: base64Url.encode(key));
    } catch (_) {
      // Test veya desteklenmeyen ortamda yalnız bellekte kalır.
    }
  }

  /// Oturum kapandığında bellekteki anahtarı temizler.
  static void clear() {
    if (_key != null) {
      _key!.fillRange(0, _key!.length, 0);
      _key = null;
    }
  }

  @visibleForTesting
  static void debugReset() => clear();
}
