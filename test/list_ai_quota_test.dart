import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/list_ai_service.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ListAiService — kota, SHA-256 önbellek ve yerel yedek', () {
    test(
      'aynı görev için 2. çağrı SHA-256 önbellekten 0 krediyle döner',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        var remoteCalls = 0;
        final service = ListAiService(
          prefs: prefs,
          remoteInvoker:
              ({
                required taskProfile,
                required prompt,
                required maxOutputTokens,
              }) async {
                remoteCalls++;
                expect(taskProfile, 'list_breakdown');
                expect(maxOutputTokens, lessThanOrEqualTo(350));
                return '["Taslak çıkar", "Grafikleri ekle", "Gözden geçir"]';
              },
          isPro: () => false,
          readOwnKey: () async => null,
          isAiAllowed: () => true,
          isSignedInNonAnonymous: () => true,
          clock: () => DateTime(2026, 11, 28, 10),
        );

        final r1 = await service.breakdownTask(
          'Yıllık sunumu hazırla',
          locale: 'tr',
        );
        expect(r1.usedAi, isTrue);
        expect(r1.fromCache, isFalse);
        expect(r1.items, ['Taslak çıkar', 'Grafikleri ekle', 'Gözden geçir']);
        expect(remoteCalls, 1);

        final r2 = await service.breakdownTask(
          'Yıllık sunumu hazırla',
          locale: 'tr',
        );
        expect(r2.usedAi, isTrue);
        expect(r2.fromCache, isTrue);
        expect(r2.items, r1.items);
        expect(remoteCalls, 1); // Ağa hiç çıkmadı!
      },
    );

    test('ücretsiz kullanıcıda 5/gün yumuşak sınırı dolunca yerel yedeğe düşer ve quotaReached döner', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var remoteCalls = 0;
      final service = ListAiService(
        prefs: prefs,
        remoteInvoker:
            ({
              required taskProfile,
              required prompt,
              required maxOutputTokens,
            }) async {
              remoteCalls++;
              return '["Adım A", "Adım B", "Adım C"]';
            },
        isPro: () => false,
        readOwnKey: () async => null,
        isAiAllowed: () => true,
        isSignedInNonAnonymous: () => true,
        clock: () => DateTime(2026, 11, 28, 11),
      );

      for (var i = 0; i < ListAiService.dailyLimitFree; i++) {
        final r = await service.breakdownTask('Görev #$i', locale: 'tr');
        expect(r.usedAi, isTrue);
        expect(r.quotaReached, isFalse);
      }
      expect(remoteCalls, 5);

      // 6. farklı görev: kota doldu -> ağa çıkma, yerel yedek + quotaReached: true
      final over = await service.breakdownTask('Sunum hazırla', locale: 'tr');
      expect(remoteCalls, 5);
      expect(over.usedAi, isFalse);
      expect(over.usedFallback, isTrue);
      expect(over.quotaReached, isTrue);
      expect(over.items, isNotEmpty);
    });

    test(
      'kilitli notta veya AI kapalıyken ağa ASLA çıkmaz, yerel yedek döner',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        var remoteCalls = 0;
        final service = ListAiService(
          prefs: prefs,
          remoteInvoker:
              ({
                required taskProfile,
                required prompt,
                required maxOutputTokens,
              }) async {
                remoteCalls++;
                return '["Olmamalı"]';
              },
          isPro: () => true,
          readOwnKey: () async => 'AIzaFakeKey',
          isAiAllowed: () => true,
          isSignedInNonAnonymous: () => true,
        );

        final lockedRes = await service.breakdownTask(
          'Gizli proje planı',
          locale: 'tr',
          noteLocked: true,
        );
        expect(remoteCalls, 0);
        expect(lockedRes.usedFallback, isTrue);
        expect(lockedRes.items, isNotEmpty);

        final extractLocked = await service.extractItems(
          '- Süt\n- Ekmek',
          mode: ListMode.shopping,
          locale: 'tr',
          noteLocked: true,
        );
        expect(remoteCalls, 0);
        expect(extractLocked.usedFallback, isTrue);
        expect(extractLocked.items.map((e) => e.item.text).toList(), [
          'Süt',
          'Ekmek',
        ]);
      },
    );

    test('BYOK kendi Gemini anahtarı günlük yumuşak sınıra takılmaz', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var remoteCalls = 0;
      final service = ListAiService(
        prefs: prefs,
        remoteInvoker:
            ({
              required taskProfile,
              required prompt,
              required maxOutputTokens,
            }) async {
              remoteCalls++;
              return '["Adım 1", "Adım 2"]';
            },
        isPro: () => false,
        readOwnKey: () async => 'AIzaOwnKey',
        isAiAllowed: () => true,
        isSignedInNonAnonymous: () => false,
      );

      for (var i = 0; i < 7; i++) {
        final r = await service.breakdownTask('BYOK görev $i', locale: 'tr');
        expect(r.usedAi, isTrue);
        expect(r.quotaReached, isFalse);
      }
      expect(remoteCalls, 7);
    });
  });
}
