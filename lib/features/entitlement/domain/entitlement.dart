// HAK (entitlement) MODELİ — PLAN §3 (Faz 1: 2-katmanlı 50 TL tek seferlik model).
// Saf Dart (Firebase yok): kapı kararı test edilebilsin, web ve Android aynı
// kodu koşsun.
//
// KİŞİSEL APK / WEB DEĞİŞMEZ: kapı yalnız `PlayBuild.enabled` iken etkili;
// bayraksız derlemede [EntitlementGate.allows] her özellik için `true`.
import '../../../core/play_build.dart';

/// Satın alınmış katman. Sunucu `entitlements/{uid}.tier` alanına yazar.
///
/// İki net katman, sıfır abonelik:
/// - [free]: Lite (Ücretsiz, reklamsız)
/// - [lifetime]: Tam Sürüm (50 TL tek seferlik, ömür boyu)
enum EntitlementTier {
  free,
  lifetime;

  static EntitlementTier parse(Object? raw) => switch (raw) {
    'lifetime' || 'pro' => EntitlementTier.lifetime,
    // Tanınmayan / eksik değer → en güvenli: ücretsiz.
    _ => EntitlementTier.free,
  };
}

/// Tam Sürüm (50 TL tek seferlik) isteyen özellikler — TEK LİSTE.
enum ProFeature {
  smartDecisions(EntitlementTier.lifetime),
  cloudAttachments(EntitlementTier.lifetime),
  ownApiKey(EntitlementTier.lifetime),
  smartShoppingPro(EntitlementTier.lifetime),
  versionHistory(EntitlementTier.lifetime),
  encryptedBackup(EntitlementTier.lifetime),
  extraAppearance(EntitlementTier.lifetime),
  instantSync(EntitlementTier.lifetime);

  const ProFeature(this.minTier);

  /// Bu özelliği açan en düşük katman (`lifetime ⊃ free`).
  final EntitlementTier minTier;
}

/// [ProFeature.extraAppearance] için ÜCRETSİZ TEMEL SET (PLAN §3).
///
/// Temel 3 tema (Sistem, Adaçayı, Koyu) + varsayılan yazı tipi (`Inter Tight`)
/// ücretsizdir. Kullanıcının hâlihazırda seçili olan teması/yazı tipi asla
/// kilitlenmez.
abstract final class AppearanceGate {
  /// `AppThemeChoice.name` değerleri.
  static const freeThemes = {'system', 'sage', 'dark'};

  /// Uygulama yazı tipi kimlikleri (`kAppDefaultFont`; test eşitliği korur).
  static const freeFonts = {'Inter Tight'};

  /// [id] seçeneği şimdi kilitli mi ([unlocked]: `extraAppearance` kapısı).
  static bool locked(
    String id, {
    required Set<String> free,
    required String? current,
    required bool unlocked,
  }) => !unlocked && id != current && !free.contains(id);
}

/// `entitlements/{uid}` belgesinin istemci görüntüsü. Belge yoksa Lite.
class Entitlement {
  const Entitlement({
    this.tier = EntitlementTier.free,
    this.proUntil,
    this.trialEndsAt,
    this.lifetimeOwned = false,
    this.decisionCredits = 0,
    this.decisionTokenCredits = 0,
  });

  /// Belge yok / okunamadı / oturum yok: Lite (ücretsiz).
  static const none = Entitlement();

  factory Entitlement.fromMap(Map<String, dynamic>? data) {
    if (data == null) return none;
    final rawTier = data['tier'];
    final proUntil = _date(data['proUntil']);
    final trialEndsAt = _date(data['trialEndsAt']);
    final lifetimeOwned =
        rawTier == 'lifetime' || data['lifetimeOwned'] == true;
    final tier = lifetimeOwned
        ? EntitlementTier.lifetime
        : EntitlementTier.parse(rawTier);
    return Entitlement(
      tier: tier,
      proUntil: proUntil,
      trialEndsAt: trialEndsAt,
      lifetimeOwned: lifetimeOwned,
      decisionCredits: _nonNegInt(data['decisionCredits']),
      decisionTokenCredits: _nonNegInt(data['decisionTokenCredits']),
    );
  }

  final EntitlementTier tier;

  /// Eski süreli kayıtlarla geriye uyum (varsa süre bitimine dek Tam Sürüm).
  final DateTime? proUntil;
  final DateTime? trialEndsAt;

  /// Tek seferlik Tam Sürüm satın alınmış mı.
  final bool lifetimeOwned;

  /// Satın alınmış ek Akıllı Karar paketi çağrı hakkı (`decision_pack_1000`).
  final int decisionCredits;

  /// Satın alınmış ek Akıllı Karar paketi girdi jetonu bütçesi.
  final int decisionTokenCredits;

  bool get hasFullVersion => lifetimeOwned;

  bool trialActive(DateTime now) => trialEndsAt?.isAfter(now) ?? false;

  /// Süreli eski hak / deneme aktif mi.
  bool legacyTimedActive(DateTime now) =>
      (proUntil?.isAfter(now) ?? false) || trialActive(now);

  /// Şu an geçerli katman.
  EntitlementTier effectiveTier(DateTime now) {
    if (lifetimeOwned || legacyTimedActive(now)) {
      return EntitlementTier.lifetime;
    }
    return EntitlementTier.free;
  }

  /// Eski süreli Pro bitti ve ömür boyu alınmamışsa true.
  bool proLapsed(DateTime now) =>
      !lifetimeOwned &&
      !legacyTimedActive(now) &&
      (proUntil != null || trialEndsAt != null);

  /// Katman kararının değişeceği ilk an (yalnız eski süreli kayıtlarda).
  DateTime? nextChange(DateTime now) {
    if (lifetimeOwned) return null;
    final times = [
      proUntil,
      trialEndsAt,
    ].whereType<DateTime>().where((t) => t.isAfter(now));
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  static DateTime? _date(Object? raw) => raw is DateTime ? raw : null;

  static int _nonNegInt(Object? raw) =>
      raw is num && raw.isFinite && raw > 0 ? raw.toInt() : 0;
}

/// Tek kapı: web ve Android aynı kararı verir.
abstract final class EntitlementGate {
  /// Kapı etkin mi: YALNIZ Play derlemesinde. Bayraksız (kişisel APK, web)
  /// derlemede herkes her şeye erişir.
  static const bool active = PlayBuild.enabled;

  static bool allows(ProFeature feature, Entitlement e, DateTime now) {
    if (!active) return true;
    if (feature == ProFeature.smartDecisions && e.decisionCredits > 0) {
      return true;
    }
    return e.effectiveTier(now).index >= feature.minTier.index;
  }

  /// Bulutta kalmış ekler HER katmanda okunur.
  static const bool canReadCloudAttachments = true;

  /// "Eski ekleri Drive'a taşı" önerisi gösterilmeli mi.
  static bool offerMoveToDrive(Entitlement e, DateTime now) =>
      active && e.proLapsed(now);

  static const moveToDriveDraft =
      'Buluttaki eski eklerin silinmedi, okumaya devam edebilirsin; '
      'yeni ekler kendi Google Drive hesabına kaydedilir.';
}
