import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/personalize.dart';
import '../../../core/play_build.dart';
import '../../settings/settings_providers.dart';
import 'gemini_service.dart' show GeminiErrorKind, GeminiException;

/// **AI KULLANIM İLKESİ — TEK KAPI** (PLAN §1.5 PL2/PL3, 16K §5.3, E11).
///
/// Her AI ağ çağrısı [GeminiService]in başında [AiAdmission.check]ten geçer
/// (dahili yol da, kendi anahtarı da). Sırayla:
///  1. Kullanıcı "Yapay zekâyı tümden kapat"ı açtıysa ([aiTurnedOffProvider]),
///  2. rıza gerekli ve verilmemişse ([aiConsentProvider]; yalnız Play)
///  çağrı ağa ÇIKMADAN [GeminiException] ile reddedilir.
/// Düğmelerin durumu aynı kaynaklardan [aiAvailabilityProvider]da (ai_gate).

/// "Yapay zekâyı tümden kapat" (Ayarlar → Yapay zekâ). Varsayılan kapalı
/// (bugünkü davranış). Açıkken [Personalize.aiOff] Yapay zekâ eklentisinin
/// girişlerini gizler; kalan girişler kilitli görünür, çağrılar reddedilir.
final aiTurnedOffProvider = NotifierProvider<AiTurnedOffNotifier, bool>(
  AiTurnedOffNotifier.new,
);

class AiTurnedOffNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sharedPreferencesProvider).getBool(Personalize.aiOffKey) ??
      false;

  void set(bool off) {
    if (off == state) return;
    state = off;
    Personalize.aiOff.value = off;
    final prefs = ref.read(sharedPreferencesProvider);
    unawaited(
      off
          ? prefs.setBool(Personalize.aiOffKey, true)
          : prefs.remove(Personalize.aiOffKey),
    );
  }
}

/// İlk AI kullanımında rıza (PL3 a, KVKK): ne gönderilir, nereye, "AI
/// yanılabilir". KARAR (en güvenli, sabah bakılacak): yalnız Play
/// derlemesinde ([PlayBuild.aiConsent]) sorulur; kişisel APK'da ve web'de
/// sorulmaz (kabul sayılır — bugünkü davranış). Kabul cihazda kalıcıdır.
final aiConsentProvider = NotifierProvider<AiConsentNotifier, bool>(
  AiConsentNotifier.new,
);

class AiConsentNotifier extends Notifier<bool> {
  /// Metin özünden değişirse sürüm artırılır → herkese yeniden sorulur.
  static const key = 'ai_consent_v1';

  /// Testler Play davranışını bayraksız deneyebilsin diye.
  @visibleForTesting
  static bool? debugRequired;

  static bool get required => debugRequired ?? PlayBuild.aiConsent;

  @override
  bool build() =>
      !required || (ref.read(sharedPreferencesProvider).getBool(key) ?? false);

  void accept() {
    state = true;
    unawaited(ref.read(sharedPreferencesProvider).setBool(key, true));
  }
}

final aiAdmissionProvider = Provider<AiAdmission>(AiAdmission.new);

class AiAdmission {
  AiAdmission(this._ref);

  final Ref _ref;

  /// Çağrı ağa çıkmadan önce; geçemezse [GeminiException] fırlatır.
  void check({bool metered = true}) {
    if (_ref.read(aiTurnedOffProvider)) {
      throw const GeminiException.of(GeminiErrorKind.aiTurnedOff);
    }
    if (!_ref.read(aiConsentProvider)) {
      throw const GeminiException.of(GeminiErrorKind.aiConsentNeeded);
    }
  }
}
