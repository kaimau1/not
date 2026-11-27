import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai_kill_switch.dart';
import '../../../core/friendly_error.dart';
import '../../../core/personalize.dart';
import '../../../core/play_build.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../settings/settings_providers.dart';

/// Karar API çağrısının politika kapısından geçememe nedeni.
enum AiPolicyErrorKind {
  aiTurnedOff,
  aiPaused,
  aiConsentNeeded,
  rateLimited,
  needsFullVersion,
}

class AiPolicyException implements UserFacingException {
  const AiPolicyException(this.kind, {this.detail});

  final AiPolicyErrorKind kind;
  final String? detail;

  @override
  String? get message => null;

  @override
  String localized(AppLocalizations l10n) => switch (kind) {
    AiPolicyErrorKind.aiTurnedOff => l10n.aiOffTitle,
    AiPolicyErrorKind.aiPaused => l10n.aiPausedTitle,
    AiPolicyErrorKind.aiConsentNeeded => l10n.aiConsentTitle,
    AiPolicyErrorKind.rateLimited => l10n.errorQuota,
    AiPolicyErrorKind.needsFullVersion => l10n.aiNeedsProTitle,
  };

  @override
  String toString() => detail == null
      ? 'AiPolicyException(${kind.name})'
      : 'AiPolicyException(${kind.name}: $detail)';
}

/// **AI / KARAR KULLANIM İLKESİ — TEK KAPI** (PLAN §1.5 PL2/PL3, Faz 1).
///
/// Her `DecisionService` ağ çağrısı [AiAdmission.check]ten geçer
/// (sunucu vekili de, kendi Gemini anahtarı da). Sırayla:
///  1. Kullanıcı "Akıllı kararları kapat"ı açtıysa ([aiTurnedOffProvider]),
///  2. `config/app.aiKillSwitch` true ise ([aiKillSwitchProvider]),
///  3. rıza gerekli ve verilmemişse ([aiConsentProvider]; yalnız Play),
///  4. yerel hız sınırı aşıldıysa ([AiRateLimiter]; yalnız ölçülen çağrı),
///  5. Play katmanı yetmiyorsa ([AiAdmission.checkTier])
///  çağrı ağa ÇIKMADAN [AiPolicyException] ile reddedilir.
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

/// İlk akıllı karar kullanımında rıza (PL3 a, KVKK): yalnız Play
/// derlemesinde ([PlayBuild.aiConsent]) sorulur; kişisel APK/web'de kabul
/// sayılır.
final aiConsentProvider = NotifierProvider<AiConsentNotifier, bool>(
  AiConsentNotifier.new,
);

class AiConsentNotifier extends Notifier<bool> {
  static const key = 'ai_consent_v1';

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

  void revoke() {
    state = !required;
    unawaited(ref.read(sharedPreferencesProvider).setBool(key, false));
  }
}

/// İstemcide basit kayan pencere hız sınırı (PL2). Sunucu sınırının yerini
/// TUTMAZ; amacı takılı bir döngünün kotayı yakmasını kesmek.
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

  /// Çağrı ağa çıkmadan önce; geçemezse [AiPolicyException] fırlatır.
  void check({bool metered = true}) {
    if (_ref.read(aiTurnedOffProvider)) {
      throw const AiPolicyException(AiPolicyErrorKind.aiTurnedOff);
    }
    if (_ref.read(aiKillSwitchProvider)) {
      throw const AiPolicyException(AiPolicyErrorKind.aiPaused);
    }
    if (!_ref.read(aiConsentProvider)) {
      throw const AiPolicyException(AiPolicyErrorKind.aiConsentNeeded);
    }
    if (metered && !limiter.tryAcquire()) {
      throw const AiPolicyException(
        AiPolicyErrorKind.rateLimited,
        detail: 'local',
      );
    }
  }

  /// Katman kapısı: Tam Sürüm (50 TL tek seferlik) veya kendi Gemini anahtarı.
  void checkTier({required bool hasOwnKey}) {
    if (!EntitlementGate.active) return;
    final feature = hasOwnKey
        ? ProFeature.ownApiKey
        : ProFeature.smartDecisions;
    if (!_ref.read(proFeatureProvider(feature))) {
      throw const AiPolicyException(AiPolicyErrorKind.needsFullVersion);
    }
  }
}
