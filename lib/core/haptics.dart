import 'package:flutter/services.dart';

/// **DOKUNSAL DİL** (DENEYIM F77.2): uygulamadaki her titreşim buradan geçer
/// (`test/design_tokens_guard_test.dart` `haptic` mandalı: bu dosya dışı 0).
/// Göçte çağrının TÜRÜ korunur; "daha uygun" diye tür değiştirilmez.
abstract final class AppHaptics {
  /// Seçim, çip, anahtar, eşik geçişi (`selectionClick`).
  static Future<void> tick() => HapticFeedback.selectionClick();

  /// İş tamamlandı: madde işaretlendi, kart bırakıldı (`lightImpact`).
  static Future<void> thud() => HapticFeedback.lightImpact();

  /// Uzun basışla tutma, yıkıcı onay, çöpe hedefleme (`mediumImpact`).
  static Future<void> heavy() => HapticFeedback.mediumImpact();

  /// Yalnız çöpe BIRAKMA (P30 çöp efekti; tür korunur: `heavyImpact`).
  static Future<void> heaviest() => HapticFeedback.heavyImpact();
}
