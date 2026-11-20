// HAK (entitlement) MODELİ — PLAN §1.5 PL14. Saf Dart (Firebase yok): kapı
// kararı test edilebilsin, web ve Android aynı kodu koşsun.
//
// KİŞİSEL APK / WEB DEĞİŞMEZ: kapı yalnız `PlayBuild.enabled` iken etkili;
// bayraksız derlemede [EntitlementGate.allows] her özellik için `true`.
import '../../../core/play_build.dart';

/// Satın alınmış katman. Sunucu `entitlements/{uid}.tier` alanına yazar.
enum EntitlementTier {
  free,
  lifetime,
  pro;

  static EntitlementTier parse(Object? raw) => switch (raw) {
    'pro' => EntitlementTier.pro,
    'lifetime' => EntitlementTier.lifetime,
    // Tanınmayan / eksik değer → en güvenli: ücretsiz.
    _ => EntitlementTier.free,
  };
}

/// Pro (ya da ömür boyu) isteyen özellikler — TEK LİSTE.
///
/// PLAN §1.5 katman tablosundan: ömür boyu = sürüm geçmişi, parolalı yedek,
/// ek görünüm, kendi Gemini anahtarı, anında eşitleme; Pro = bunların hepsi
/// + dahili AI + bulut ekleri. BAĞLI kapılar (PL6, 2026-11-20): [builtInAi] ve
/// [ownApiKey] (`aiAvailabilityProvider`, `AiAdmission`). Kalanlar henüz hiçbir
/// ekranda okunmuyor — kimsenin elinden özellik alınmasın diye (en güvenli,
/// sabah bakılacak: temel tema/yazı tipi setinin sınırı, eşitleme aralığı S1,
/// bulut ekleri S4).
enum ProFeature {
  builtInAi(EntitlementTier.pro),
  cloudAttachments(EntitlementTier.pro),
  ownApiKey(EntitlementTier.lifetime),
  versionHistory(EntitlementTier.lifetime),
  encryptedBackup(EntitlementTier.lifetime),
  extraAppearance(EntitlementTier.lifetime),
  instantSync(EntitlementTier.lifetime);

  const ProFeature(this.minTier);

  /// Bu özelliği açan en düşük katman (pro ⊃ lifetime ⊃ free).
  final EntitlementTier minTier;
}

/// `entitlements/{uid}` belgesinin istemci görüntüsü. Belge yoksa ücretsiz.
class Entitlement {
  const Entitlement({
    this.tier = EntitlementTier.free,
    this.proUntil,
    this.trialEndsAt,
    this.lifetimeOwned = false,
  });

  /// Belge yok / okunamadı / oturum yok: ücretsiz, deneme yok.
  static const none = Entitlement();

  factory Entitlement.fromMap(Map<String, dynamic>? data) {
    if (data == null) return none;
    final tier = EntitlementTier.parse(data['tier']);
    return Entitlement(
      tier: tier,
      proUntil: _date(data['proUntil']),
      trialEndsAt: _date(data['trialEndsAt']),
      // Ömür boyudan Pro'ya geçen ömür boyu haklarını korur (PLAN §1.5
      // yürütücü varsayılanı): `tier` pro olsa da bu bayrak kalır.
      lifetimeOwned:
          tier == EntitlementTier.lifetime || data['lifetimeOwned'] == true,
    );
  }

  final EntitlementTier tier;

  /// Pro aboneliğinin bittiği an (sunucu, Play'den doğrulanmış).
  final DateTime? proUntil;

  /// 7 günlük Pro denemesinin bittiği an (ilk girişte sunucu yazar).
  final DateTime? trialEndsAt;

  /// Ömür boyu satın alınmış mı.
  final bool lifetimeOwned;

  bool trialActive(DateTime now) => trialEndsAt?.isAfter(now) ?? false;

  /// Pro şu an açık mı: ödenmiş süre ya da deneme. `proUntil` yoksa Pro
  /// sayılmaz (sunucu süresiz Pro'yu uzak bir tarihle yazar).
  bool proActive(DateTime now) =>
      (tier == EntitlementTier.pro && (proUntil?.isAfter(now) ?? false)) ||
      trialActive(now);

  /// Şu an geçerli katman.
  EntitlementTier effectiveTier(DateTime now) {
    if (proActive(now)) return EntitlementTier.pro;
    if (lifetimeOwned) return EntitlementTier.lifetime;
    return EntitlementTier.free;
  }

  /// Bir zamanlar Pro'ydu (ödenmiş ya da deneme), artık değil. Bulutta
  /// kalmış ekler SİLİNMEZ, KİLİTLENMEZ — okunur kalır; yeni ekler kendi
  /// Drive'ına gider (PLAN §1.5 "Pro biterse").
  bool proLapsed(DateTime now) =>
      !proActive(now) && (proUntil != null || trialEndsAt != null);

  /// Katman kararının değişeceği ilk an (deneme/abonelik bitişi) — sağlayıcı
  /// o an kendini yeniler; uygulama açıkken deneme bitince kapı kapanır.
  DateTime? nextChange(DateTime now) {
    final times = [
      proUntil,
      trialEndsAt,
    ].whereType<DateTime>().where((t) => t.isAfter(now));
    if (times.isEmpty) return null;
    return times.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Zaman alanları [DateTime] olarak gelir; Firestore `Timestamp` dönüşümü
  /// veri katmanında ([entitlementProvider]).
  static DateTime? _date(Object? raw) => raw is DateTime ? raw : null;
}

/// Tek kapı: web ve Android aynı kararı verir.
abstract final class EntitlementGate {
  /// Kapı etkin mi: YALNIZ Play derlemesinde. Bayraksız (kişisel APK, web)
  /// derlemede herkes bugünkü gibi her şeye erişir.
  static const bool active = PlayBuild.enabled;

  static bool allows(ProFeature feature, Entitlement e, DateTime now) {
    if (!active) return true;
    return e.effectiveTier(now).index >= feature.minTier.index;
  }

  /// AI çağrısının istediği hak (PL6 katman kapısı): kendi anahtarıyla
  /// ömür boyu yeter, dahili AI Pro ister. Ücretsizde ikisi de kapalı.
  static ProFeature aiFeature({required bool hasOwnKey}) =>
      hasOwnKey ? ProFeature.ownApiKey : ProFeature.builtInAi;

  /// Bulutta (Storage) kalmış ekler HER katmanda okunur — Pro bitince de.
  static const bool canReadCloudAttachments = true;

  /// "Eski ekleri Drive'a taşı" önerisi gösterilmeli mi (UI YOK, taslak).
  static bool offerMoveToDrive(Entitlement e, DateTime now) =>
      active && e.proLapsed(now);

  /// "Drive'a taşı" metin taslağı (UI gelince l10n'a taşınır).
  static const moveToDriveDraft =
      'Pro süren bitti. Buluttaki eklerin silinmedi, okumaya devam '
      'edebilirsin; yeni ekler Drive\'ına kaydedilir. Eskileri de tek '
      'dokunuşla Drive\'ına taşıyabilirsin.';
}
