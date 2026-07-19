import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

final permissionsServiceProvider = Provider<PermissionsService>(
  (ref) => const PermissionsService(),
);

/// Uygulamanın düzgün çalışması için gereken cihaz izinlerini denetler,
/// ister ve ilgili sistem ayar ekranlarını açar. Yeni bir bağımlılık
/// eklemeden mevcut eklentiler (record, flutter_local_notifications) ve
/// MainActivity'deki küçük MethodChannel üzerinden çalışır.
class PermissionsService {
  const PermissionsService();

  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// İzin sistemi yalnızca Android'de anlamlı (Windows'ta gerekmez).
  bool get isSupported => _isAndroid;

  /// Mikrofon izni verilmiş mi? (sistem iletişim kutusu AÇMADAN okur)
  Future<bool> micGranted() async {
    if (!_isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('micPermissionGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mikrofon iznini ister (gerekirse sistem iletişim kutusunu açar).
  /// record eklentisinin hasPermission'ı hem denetler hem ister.
  Future<bool> requestMic() async {
    if (!_isAndroid) return true;
    final recorder = AudioRecorder();
    try {
      return await recorder.hasPermission();
    } catch (_) {
      return false;
    } finally {
      await recorder.dispose();
    }
  }

  /// Bildirim izni açık mı? (sistem iletişim kutusu AÇMADAN okur)
  Future<bool> notificationsGranted() async {
    if (!_isAndroid) return true;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Bildirim iznini ister (Android 13+ sistem iletişim kutusu).
  Future<bool> requestNotifications() async {
    if (!_isAndroid) return true;
    try {
      final android = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Uygulama detay ayarlarını açar (kalıcı reddedilen izinler için).
  Future<void> openAppSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } catch (_) {}
  }

  /// Pil optimizasyonu ayarını açar (hatırlatıcılar gecikmesin diye).
  Future<void> openBatterySettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openBatterySettings');
    } catch (_) {}
  }
}
