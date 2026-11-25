// HAK KAPISI BEKÇİSİ (PLAN §1.5 PL14, Faz 1 — 2 katmanlı model: Lite / Tam Sürüm).
//
// Bayraksız (`flutter test`) koşu: kişisel APK / web bugünkü gibi — her
// kapı açık, Firestore'a gidilmez. Play koşusu:
//   flutter test test/entitlement_test.dart --dart-define=NOTLAR_PLAY=true
// aynı testte ücretsiz katmanda Tam Sürüm özelliklerinin kapandığını doğrular.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/play_build.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';

void main() {
  final now = DateTime.utc(2026, 11, 18, 12);
  final past = now.subtract(const Duration(days: 1));
  final future = now.add(const Duration(days: 3));

  group('model (derlemeden bağımsız — 2 katman: free / lifetime)', () {
    test('belge yok / tanınmayan katman → ücretsiz', () {
      expect(
        Entitlement.fromMap(null).effectiveTier(now),
        EntitlementTier.free,
      );
      expect(
        Entitlement.fromMap({'tier': 'altın'}).effectiveTier(now),
        EntitlementTier.free,
      );
    });

    test('eski abonelik kaydı geriye uyumlu: süresi içinde Tam Sürüm, bitince ücretsiz', () {
      Entitlement pro(DateTime? until) =>
          Entitlement.fromMap({'tier': 'pro', 'proUntil': until});
      expect(pro(future).effectiveTier(now), EntitlementTier.lifetime);
      expect(pro(past).effectiveTier(now), EntitlementTier.free);
      expect(pro(null).effectiveTier(now), EntitlementTier.free);
    });

    test('deneme süresi: süresi içinde Tam Sürüm, bitince ücretsiz', () {
      expect(
        Entitlement.fromMap({'trialEndsAt': future}).effectiveTier(now),
        EntitlementTier.lifetime,
      );
      expect(
        Entitlement.fromMap({'trialEndsAt': past}).effectiveTier(now),
        EntitlementTier.free,
      );
    });

    test('Tam Sürüm (lifetime) kalıcı; ek karar paketi kredileri okunur', () {
      final life = Entitlement.fromMap({
        'tier': 'lifetime',
        'decisionCredits': 1000,
        'decisionTokenCredits': 800000,
      });
      expect(life.effectiveTier(now), EntitlementTier.lifetime);
      expect(life.decisionCredits, 1000);
      expect(life.decisionTokenCredits, 800000);

      final legacy = Entitlement.fromMap({
        'tier': 'pro',
        'proUntil': past,
        'lifetimeOwned': true,
      });
      expect(legacy.effectiveTier(now), EntitlementTier.lifetime);
    });

    test('eski Pro bitince ekler okunur kalır, Drive önerisi bayrağı', () {
      expect(EntitlementGate.canReadCloudAttachments, isTrue);
      final lapsed = Entitlement.fromMap({'tier': 'pro', 'proUntil': past});
      expect(lapsed.proLapsed(now), isTrue);
      expect(Entitlement.none.proLapsed(now), isFalse);
      final active = Entitlement.fromMap({'tier': 'pro', 'proUntil': future});
      expect(active.proLapsed(now), isFalse);
      expect(EntitlementGate.offerMoveToDrive(lapsed, now), PlayBuild.enabled);
      expect(EntitlementGate.moveToDriveDraft, isNotEmpty);
    });

    test('nextChange en yakın gelecek bitiş', () {
      final e = Entitlement.fromMap({
        'tier': 'pro',
        'proUntil': future,
        'trialEndsAt': now.add(const Duration(hours: 1)),
      });
      expect(e.nextChange(now), now.add(const Duration(hours: 1)));
      expect(Entitlement.none.nextChange(now), isNull);
    });

    test('Firestore Timestamp alanları çevrilir', () {
      final e = entitlementFromFirestore({
        'tier': 'pro',
        'proUntil': Timestamp.fromDate(future),
      });
      expect(e.proUntil!.isAtSameMomentAs(future), isTrue);
      expect(e.effectiveTier(now), EntitlementTier.lifetime);
    });
  });

  group('kapı', () {
    test('kapı yalnız Play derlemesinde etkin', () {
      expect(EntitlementGate.active, PlayBuild.enabled);
    });

    test(
      'ücretsiz: bayraksızda her şey açık, Play\'de Tam Sürüm özellikleri kapalı',
      () {
        for (final f in ProFeature.values) {
          expect(
            EntitlementGate.allows(f, Entitlement.none, now),
            !PlayBuild.enabled,
            reason: f.name,
          );
        }
      },
    );

    test('Tam Sürüm (lifetime) bütün özellikleri açar (2-katmanlı model)', () {
      final life = Entitlement.fromMap({'tier': 'lifetime'});
      for (final f in ProFeature.values) {
        expect(EntitlementGate.allows(f, life, now), isTrue, reason: f.name);
        expect(f.minTier, EntitlementTier.lifetime, reason: f.name);
      }
      expect(
        ProFeature.values,
        containsAll([
          ProFeature.smartDecisions,
          ProFeature.smartShoppingPro,
          ProFeature.cloudAttachments,
          ProFeature.versionHistory,
          ProFeature.ownApiKey,
        ]),
      );
    });
  });

  group('sağlayıcı', () {
    ProviderContainer containerWith(Entitlement e) {
      final c = ProviderContainer(
        overrides: [entitlementProvider.overrideWithValue(AsyncData(e))],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('ücretsiz hesapta özellik kapısı derlemeye göre', () {
      final c = containerWith(Entitlement.none);
      for (final f in ProFeature.values) {
        expect(c.read(proFeatureProvider(f)), !PlayBuild.enabled);
      }
      expect(c.read(offerMoveToDriveProvider), isFalse);
    });

    test('Tam Sürüm hesapta tüm özellikler açık', () {
      final c = containerWith(Entitlement.fromMap({'tier': 'lifetime'}));
      expect(c.read(effectiveTierProvider), EntitlementTier.lifetime);
      expect(c.read(proFeatureProvider(ProFeature.smartDecisions)), isTrue);
      expect(c.read(proFeatureProvider(ProFeature.cloudAttachments)), isTrue);
    });

    test('bayraksız derlemede sağlayıcı Firestore\'a gitmez', () async {
      if (PlayBuild.enabled) return;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final sub = c.listen(entitlementProvider, (_, _) {});
      addTearDown(sub.close);
      final e = await c.read(entitlementProvider.future);
      expect(e.tier, EntitlementTier.free);
      expect(c.read(proFeatureProvider(ProFeature.smartDecisions)), isTrue);
    });
  });
}
