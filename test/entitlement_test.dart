// HAK KAPISI BEKÇİSİ (PLAN §1.5 PL14).
//
// Bayraksız (`flutter test`) koşu: kişisel APK / web bugünkü gibi — her
// kapı açık, Firestore'a gidilmez. Play koşusu:
//   flutter test test/entitlement_test.dart --dart-define=NOTLAR_PLAY=true
// aynı testte ücretsiz katmanda Pro özelliklerin kapandığını doğrular.
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

  group('model (derlemeden bağımsız)', () {
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

    test('Pro yalnız süresi içinde; proUntil yoksa Pro değil', () {
      Entitlement pro(DateTime? until) =>
          Entitlement.fromMap({'tier': 'pro', 'proUntil': until});
      expect(pro(future).effectiveTier(now), EntitlementTier.pro);
      expect(pro(past).effectiveTier(now), EntitlementTier.free);
      expect(pro(null).effectiveTier(now), EntitlementTier.free);
    });

    test('7 gün deneme: süresi içinde Pro, bitince ücretsiz', () {
      expect(
        Entitlement.fromMap({'trialEndsAt': future}).effectiveTier(now),
        EntitlementTier.pro,
      );
      expect(
        Entitlement.fromMap({'trialEndsAt': past}).effectiveTier(now),
        EntitlementTier.free,
      );
    });

    test('ömür boyu kalıcı; Pro bitince ömür boyu hakları kalır', () {
      expect(
        Entitlement.fromMap({'tier': 'lifetime'}).effectiveTier(now),
        EntitlementTier.lifetime,
      );
      final e = Entitlement.fromMap({
        'tier': 'pro',
        'proUntil': past,
        'lifetimeOwned': true,
      });
      expect(e.effectiveTier(now), EntitlementTier.lifetime);
    });

    test('Pro bitince ekler okunur kalır, Drive önerisi bayrağı', () {
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
      expect(e.effectiveTier(now), EntitlementTier.pro);
    });
  });

  group('kapı', () {
    test('kapı yalnız Play derlemesinde etkin', () {
      expect(EntitlementGate.active, PlayBuild.enabled);
    });

    test(
      'ücretsiz: bayraksızda her şey açık, Play\'de Pro özellikler kapalı',
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

    test('Pro her şeyi açar; ömür boyu dahili AI ve bulut ekini açmaz', () {
      final pro = Entitlement.fromMap({'tier': 'pro', 'proUntil': future});
      final life = Entitlement.fromMap({'tier': 'lifetime'});
      for (final f in ProFeature.values) {
        expect(EntitlementGate.allows(f, pro, now), isTrue, reason: f.name);
        final lifeOk = f.minTier != EntitlementTier.pro;
        expect(
          EntitlementGate.allows(f, life, now),
          lifeOk || !PlayBuild.enabled,
          reason: f.name,
        );
      }
      // Yer tutucu listenin PLAN §1.5 tablosuyla bağı (sabah bakılacak).
      expect(ProFeature.builtInAi.minTier, EntitlementTier.pro);
      expect(ProFeature.cloudAttachments.minTier, EntitlementTier.pro);
      expect(ProFeature.ownApiKey.minTier, EntitlementTier.lifetime);
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

    test('denemedeki hesap Pro', () {
      final c = containerWith(
        Entitlement(trialEndsAt: DateTime.now().add(const Duration(days: 7))),
      );
      expect(c.read(effectiveTierProvider), EntitlementTier.pro);
      expect(c.read(proFeatureProvider(ProFeature.builtInAi)), isTrue);
    });

    test('bayraksız derlemede sağlayıcı Firestore\'a gitmez', () async {
      if (PlayBuild.enabled) return;
      final c = ProviderContainer();
      addTearDown(c.dispose);
      // Firebase başlatılmadığı hâlde hata yok: doğrudan Entitlement.none.
      // (Riverpod 3 dinleyicisiz sağlayıcıyı duraklatır → dinle.)
      final sub = c.listen(entitlementProvider, (_, _) {});
      addTearDown(sub.close);
      final e = await c.read(entitlementProvider.future);
      expect(e.tier, EntitlementTier.free);
      expect(c.read(proFeatureProvider(ProFeature.builtInAi)), isTrue);
    });
  });
}
