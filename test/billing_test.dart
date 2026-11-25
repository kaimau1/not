// SATIN ALMA BEKÇİSİ (PLAN §1.5 PL6 + Faz 1: abonelik yok, tek seferlik
// Tam Sürüm + isteğe bağlı tüketilebilir +1.000 Akıllı Karar Paketi).
//
// Bayraksız (`flutter test`, CI) koşu: kişisel APK / web'de mağazaya
// dokunulmaz, katman kapısı etkisiz. Play koşusu:
//   flutter test test/billing_test.dart --dart-define=NOTLAR_PLAY=true
// satın al → sunucuda doğrula → onayla akışını sahte mağazayla sınar.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:notlar/core/play_build.dart';
import 'package:notlar/features/ai/data/ai_policy.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/entitlement/data/billing_products.dart';
import 'package:notlar/features/entitlement/data/billing_service.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/entitlement/presentation/pro_screen.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<ProductDetails> _storeProducts() => [
  ...GooglePlayProductDetails.fromProductDetails(
    const ProductDetailsWrapper(
      description: '',
      name: 'Tam Sürüm',
      productId: BillingProducts.lifetime,
      productType: ProductType.inapp,
      title: 'Tam Sürüm',
      oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(
        formattedPrice: '₺49,99',
        priceAmountMicros: 49990000,
        priceCurrencyCode: 'TRY',
      ),
    ),
  ),
  ...GooglePlayProductDetails.fromProductDetails(
    const ProductDetailsWrapper(
      description: '',
      name: '+1.000 Akıllı Karar Paketi',
      productId: BillingProducts.decisionPack1000,
      productType: ProductType.inapp,
      title: '+1.000 Akıllı Karar Paketi',
      oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(
        formattedPrice: '₺29,99',
        priceAmountMicros: 29990000,
        priceCurrencyCode: 'TRY',
      ),
    ),
  ),
];

class _Store extends Fake implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  List<PurchaseDetails> owned = const [];
  PurchaseParam? boughtNonConsumable;
  PurchaseParam? boughtConsumable;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: _storeProducts(), notFoundIDs: []);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    boughtNonConsumable = purchaseParam;
    return true;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    boughtConsumable = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  @override
  Future<void> restorePurchases({String? applicationUserName}) async =>
      updates.add(owned);
}

PurchaseDetails _purchase(String id, PurchaseStatus status) => PurchaseDetails(
  productID: id,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: 'token-$id',
    source: 'google_play',
  ),
  transactionDate: '0',
  status: status,
)..pendingCompletePurchase = true;

void main() {
  test('ürün kimlikleri sunucuyla aynı (functions/billing_util.js)', () {
    final js = File('functions/billing_util.js').readAsStringSync();
    expect(js, contains('LIFETIME_PRODUCT = "${BillingProducts.lifetime}"'));
    expect(
      js,
      contains('DECISION_PACK_1000 = "${BillingProducts.decisionPack1000}"'),
    );
    // Fiyat koda yazılmaz: mağazadan okunur.
    final dart = File('lib/features/entitlement/data/billing_products.dart')
        .readAsStringSync();
    expect(RegExp(r'[₺$€]\s*\d').hasMatch(dart), isFalse);
  });

  test('hesap etiketi sunucuyla aynı özet (SHA-256)', () {
    expect(
      billingAccountTag('uid-1'),
      '4a49acf8a6bd727728495d1e541a840898fcc36747cdcdb9e8e68effc62bb15c',
    );
  });

  test('mağaza satırları: Tam Sürüm + tüketilebilir Karar Paketi', () {
    final offers = billingOffers(_storeProducts());
    expect(offers.map((o) => o.plan), BillingPlan.values);
    expect(offers.first.plan, BillingPlan.lifetime);
    expect(offers.first.plan.consumable, isFalse);
    expect(offers.first.price, '₺49,99');
    expect(offers.last.plan, BillingPlan.decisionPack1000);
    expect(offers.last.plan.consumable, isTrue);
    expect(offers.last.price, '₺29,99');
  });

  group('kişisel APK / web (bayraksız)', skip: PlayBuild.enabled, () {
    test('mağazaya dokunulmaz, AI katman kapısı etkisiz', () async {
      BillingNotifier.debugStore = () => throw StateError('dokunulmamalı');
      addTearDown(
        () => BillingNotifier.debugStore = () => InAppPurchase.instance,
      );
      final c = ProviderContainer(
        overrides: [currentUidProvider.overrideWithValue('u1')],
      );
      addTearDown(c.dispose);
      expect(c.read(billingProvider).status, BillingStatus.off);
      final n = c.read(billingProvider.notifier);
      await n.start();
      await n.recover();
      expect(c.read(billingProvider).status, BillingStatus.off);
      c.read(billingRecoveryProvider);
      // Ücretsiz katmanda bile kişisel APK'da serbest.
      c.read(aiAdmissionProvider).checkTier(hasOwnKey: false);
      expect(c.read(proFeatureProvider(ProFeature.smartDecisions)), isTrue);
    });
  });

  testWidgets('Ayarlar\'da Tam Sürüm kartı yalnız Play derlemesinde', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue(null),
        isAnonymousProvider.overrideWithValue(true),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('settings-guide')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('settings-pro')),
      PlayBuild.enabled ? findsOneWidget : findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  test('/premium rotası tek ProScreen\'e açılır (eski PremiumScreen yok)', () {
    final router = File('lib/app/router.dart').readAsStringSync();
    expect(router, contains('const ProScreen()'));
    expect(router, isNot(contains('PremiumScreen')));
  });

  group('Play akışı (NOTLAR_PLAY=true)', skip: !PlayBuild.enabled, () {
    late _Store store;
    late List<(String, String)> verified;
    Object? verifyError;

    setUp(() {
      store = _Store();
      verified = [];
      verifyError = null;
      BillingNotifier.debugStore = () => store;
      BillingNotifier.debugVerify = (id, token) async {
        if (verifyError != null) throw verifyError!;
        verified.add((id, token));
      };
    });
    tearDown(() {
      BillingNotifier.debugStore = () => InAppPurchase.instance;
    });

    ProviderContainer container({bool guest = false, Entitlement? e}) {
      final c = ProviderContainer(
        overrides: [
          currentUidProvider.overrideWithValue('uid-1'),
          isAnonymousProvider.overrideWithValue(guest),
          entitlementProvider.overrideWith(
            (ref) => Stream.value(e ?? Entitlement.none),
          ),
        ],
      );
      addTearDown(c.dispose);
      c.listen(billingProvider, (_, _) {});
      c.listen(entitlementProvider, (_, _) {});
      return c;
    }

    test('Tam Sürüm: buyNonConsumable → doğrula → onayla', () async {
      final c = container();
      final n = c.read(billingProvider.notifier);
      await n.start();
      expect(c.read(billingProvider).status, BillingStatus.ready);
      await n.buy(c.read(billingProvider).offers.first);
      expect(
        store.boughtNonConsumable!.applicationUserName,
        billingAccountTag('uid-1'),
      );
      store.updates.add([
        _purchase(BillingProducts.lifetime, PurchaseStatus.purchased),
      ]);
      await pumpEventQueue();
      expect(verified, [(BillingProducts.lifetime, 'token-lifetime')]);
      expect(store.completed, [BillingProducts.lifetime]);
      expect(c.read(billingProvider).notice, BillingNotice.done);
      expect(c.read(billingProvider).busy, isFalse);
    });

    test('+1.000 Karar Paketi: buyConsumable → doğrula → onayla', () async {
      final c = container(e: Entitlement.fromMap({'tier': 'lifetime'}));
      final n = c.read(billingProvider.notifier);
      await n.start();
      final pack = c.read(billingProvider).offers.last;
      expect(pack.plan, BillingPlan.decisionPack1000);
      await n.buy(pack);
      expect(
        store.boughtConsumable!.applicationUserName,
        billingAccountTag('uid-1'),
      );
      store.updates.add([
        _purchase(BillingProducts.decisionPack1000, PurchaseStatus.purchased),
      ]);
      await pumpEventQueue();
      expect(verified, [
        (BillingProducts.decisionPack1000, 'token-decision_pack_1000'),
      ]);
      expect(store.completed, [BillingProducts.decisionPack1000]);
    });

    test('başka hesaba bağlı / doğrulanamayan satın alma ONAYLANMAZ', () async {
      final c = container();
      await c.read(billingProvider.notifier).start();
      // ignore: invalid_use_of_protected_member
      verifyError = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'other-account',
      );
      store.updates.add([
        _purchase(BillingProducts.lifetime, PurchaseStatus.purchased),
      ]);
      await pumpEventQueue();
      expect(store.completed, isEmpty);
      expect(c.read(billingProvider).notice, BillingNotice.otherAccount);
    });

    test('misafir satın alamaz; boş geri yükleme söylenir', () async {
      final g = container(guest: true);
      await g
          .read(billingProvider.notifier)
          .buy(
            BillingOffer(
              plan: BillingPlan.lifetime,
              price: '',
              details: _storeProducts().first,
            ),
          );
      expect(store.boughtNonConsumable, isNull);
      expect(g.read(billingProvider).notice, BillingNotice.guest);

      final c = container();
      await c.read(billingProvider.notifier).recover();
      await pumpEventQueue();
      expect(c.read(billingProvider).notice, BillingNotice.nothingToRestore);
    });

    test('sessiz onarım yalnız hakta görünmeyeni doğrular', () async {
      final owned = _purchase(BillingProducts.lifetime, PurchaseStatus.restored)
        ..pendingCompletePurchase = false;
      store.owned = [owned];
      final has = container(e: Entitlement.fromMap({'tier': 'lifetime'}));
      await has.read(entitlementProvider.future);
      await has.read(billingProvider.notifier).recover(quiet: true);
      await pumpEventQueue();
      expect(verified, isEmpty);

      store = _Store()..owned = [owned];
      final missing = container();
      await missing.read(entitlementProvider.future);
      await missing.read(billingProvider.notifier).recover(quiet: true);
      await pumpEventQueue();
      expect(verified, [(BillingProducts.lifetime, 'token-lifetime')]);
      expect(missing.read(billingProvider).notice, isNull);
    });

    test('AI katman kapısı: ücretsizde red, Tam Sürümde serbest', () {
      final free = container();
      expect(
        () => free.read(aiAdmissionProvider).checkTier(hasOwnKey: false),
        throwsA(
          isA<AiPolicyException>().having(
            (e) => e.kind,
            'kind',
            AiPolicyErrorKind.needsFullVersion,
          ),
        ),
      );
      final life = container(e: Entitlement.fromMap({'tier': 'lifetime'}));
      return life.read(entitlementProvider.future).then((_) {
        life.read(aiAdmissionProvider).checkTier(hasOwnKey: false);
        life.read(aiAdmissionProvider).checkTier(hasOwnKey: true);
      });
    });

    testWidgets('ProScreen: 2 sütunlu tablo, tek seferlik Tam Sürüm + kota', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        DecisionQuotaNotifier.prefsKey: jsonEncode(
          const DecisionQuotaSnapshot(
            remainingCalls: 640,
            remainingTokens: 512000,
            syncedFromServer: true,
          ).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue('uid-1'),
            isAnonymousProvider.overrideWithValue(false),
            entitlementProvider.overrideWith(
              (ref) => Stream.value(Entitlement.fromMap({'tier': 'lifetime'})),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pro-tiers')), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-status')), findsOneWidget);
      expect(find.textContaining('640'), findsWidgets);
      expect(find.textContaining('512K'), findsWidgets);
      expect(find.textContaining('₺29,99'), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-restore')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
