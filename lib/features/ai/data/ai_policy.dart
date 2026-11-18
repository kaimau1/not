import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai_kill_switch.dart';
import '../../../core/personalize.dart';
import '../../../core/play_build.dart';
import '../../settings/settings_providers.dart';
import 'gemini_service.dart' show GeminiErrorKind, GeminiException;

/// **AI KULLANIM İLKESİ — TEK KAPI** (PLAN §1.5 PL2/PL3, 16K §5.3, E11).
///
/// Her AI ağ çağrısı [GeminiService]in başında [AiAdmission.check]ten geçer
/// (dahili yol da, kendi anahtarı da). Sırayla:
///  1. Kullanıcı "Yapay zekâyı tümden kapat"ı açtıysa ([aiTurnedOffProvider]),
///  2. `config/app.aiKillSwitch` true ise ([aiKillSwitchProvider]),
///  3. rıza gerekli ve verilmemişse ([aiConsentProvider]; yalnız Play),
///  4. yerel hız sınırı aşıldıysa ([AiRateLimiter]; yalnız ölçülen çağrı)
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

/// `config/app.aiKillSwitch` (bkz. [AiKillSwitch]); değişince yeniden okunur.
final aiKillSwitchProvider = Provider<bool>((ref) {
  void changed() => ref.invalidateSelf();
  AiKillSwitch.active.addListener(changed);
  ref.onDispose(() => AiKillSwitch.active.removeListener(changed));
  return AiKillSwitch.active.value;
});

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

/// İstemcide basit kayan pencere hız sınırı (PL2). Sunucu sınırının yerini
/// TUTMAZ (istemci atlatılabilir); amacı takılı bir döngünün ya da hızlı
/// art arda dokunuşların faturayı/kotayı yakmasını kesmek. Varsayılanlar
/// cömert: insan elle bu hıza çıkmaz. Anlamsal arama gömmeleri sayılmaz
/// (kendi temposu var: `_Pacer`, semantic_search.dart).
class AiRateLimiter {
  AiRateLimiter({this.perMinute = 30, this.perHour = 300});

  final int perMinute;
  final int perHour;
  final _calls = Queue<DateTime>();

  /// Yer varsa çağrıyı sayar ve true; yoksa saymadan false.
  bool tryAcquire([DateTime? at]) {
    final now = at ?? DateTime.now();
    while (_calls.isNotEmpty &&
        now.difference(_calls.first) >= const Duration(hours: 1)) {
      _calls.removeFirst();
    }
    var lastMinute = 0;
    for (final t in _calls) {
      if (now.difference(t) < const Duration(minutes: 1)) lastMinute++;
    }
    if (_calls.length >= perHour || lastMinute >= perMinute) return false;
    _calls.addLast(now);
    return true;
  }
}

final aiAdmissionProvider = Provider<AiAdmission>(AiAdmission.new);

class AiAdmission {
  AiAdmission(this._ref);

  final Ref _ref;
  final limiter = AiRateLimiter();

  /// Çağrı ağa çıkmadan önce; geçemezse [GeminiException] fırlatır.
  /// [metered] false: hız sınırına sayılmaz (gömme).
  void check({bool metered = true}) {
    if (_ref.read(aiTurnedOffProvider)) {
      throw const GeminiException.of(GeminiErrorKind.aiTurnedOff);
    }
    if (_ref.read(aiKillSwitchProvider)) {
      throw const GeminiException.of(GeminiErrorKind.aiPaused);
    }
    if (!_ref.read(aiConsentProvider)) {
      throw const GeminiException.of(GeminiErrorKind.aiConsentNeeded);
    }
    if (metered && !limiter.tryAcquire()) {
      throw const GeminiException.of(
        GeminiErrorKind.rateLimited,
        detail: 'local',
      );
    }
  }
}
