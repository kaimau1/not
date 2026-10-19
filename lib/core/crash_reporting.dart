import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'error_log.dart';

/// **HATA İŞLEYİCİLERİ** (F1.9, 2026-10-19). Eskiden hiç yoktu: yakalanmayan
/// bir hata yalnız konsola düşüyor, kullanıcı "uygulama kapandı" demekten
/// öteye bir şey bildiremiyordu.
///
/// Her hata önce cihazdaki [ErrorLog]'a yazılır (her platform). Android'de
/// kullanıcı açık bıraktıysa (Ayarlar → Hakkında → "Çökme raporlarını
/// gönder", varsayılan AÇIK — kullanıcı kararı) Firebase Crashlytics'e de
/// gider. Rapora not içeriği konmaz: yalnız hata ve yığın.
class CrashReporting {
  CrashReporting._();

  /// Crashlytics eklentisi yalnız mobilde var; web'de çağrı hata
  /// verir.
  static bool get supported => !kIsWeb && Platform.isAndroid;

  static bool _enabled = false;

  /// [enabled]: kullanıcının tercihi. Hata ayıklama derlemesi rapor
  /// GÖNDERMEZ (geliştirme hataları gerçek kullanıcı sinyalini boğmasın).
  static void install({required bool enabled}) {
    unawaited(setEnabled(enabled));
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      ErrorLog.record('flutter', details.exception, details.stack);
      if (_enabled) {
        unawaited(
          FirebaseCrashlytics.instance.recordFlutterFatalError(details),
        );
      }
      (previous ?? FlutterError.presentError)(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorLog.record('platform', error, stack);
      if (_enabled) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
      }
      return true;
    };
  }

  static Future<void> setEnabled(bool enabled) async {
    _enabled = supported && enabled && !kDebugMode;
    if (!supported) return;
    try {
      final crash = FirebaseCrashlytics.instance;
      await crash.setCrashlyticsCollectionEnabled(_enabled);
      // Kapatınca cihazda bekleyen (henüz gönderilmemiş) raporlar da gitmesin.
      if (!_enabled) await crash.deleteUnsentReports();
    } catch (e) {
      debugPrint('Crashlytics ayarlanamadı: $e');
    }
  }

  /// Yakalanıp YUTULAN ama bilinmesi gereken hata (ör. sunucunun yazımı
  /// reddetmesi): günlüğe yazılır, Crashlytics'e ölümcül olmayan olarak.
  static void recordNonFatal(String source, Object error, [StackTrace? stack]) {
    ErrorLog.record(source, error, stack);
    if (_enabled) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, reason: source),
      );
    }
  }
}
