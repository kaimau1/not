// SATIN ALMA BEKÇİSİ (PLAN §1.5 PL6).
//
// Bayraksız (`flutter test`, CI) koşu: kişisel APK / web'de HİÇBİR görünür
// değişiklik yok — Ayarlar'da Pro kartı yok, mağazaya dokunulmaz, AI katman
// kapısı etkisiz. Play koşusu:
//   flutter test test/billing_test.dart --dart-define=NOTLAR_PLAY=true
// satın al → sunucuda doğrula → onayla akışını sahte mağazayla sınar.
import 'dart:async';
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
import 'package:notlar/features/ai/data/gemini_service.dart';
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

const _phase = PricingPhaseWrapper(
  billingCycleCount: 0,
  billingPeriod: 'P1M',
  formattedPrice: '₺99,99',
  priceAmountMicros: 99990000,
  priceCurrencyCode: 'TRY',
  recurrenceMode: RecurrenceMode.infiniteRecurring,
);
const _free = PricingPhaseWrapper(
  billingCycleCount: 1,
  billingPeriod: 'P1W',
  formattedPrice: 'Ücretsiz',
  priceAmountMicros: 0,
  priceCurrencyCode: 'TRY',
  recurrenceMode: RecurrenceMode.finiteRecurring,
);

List<ProductDetails> _storeProducts() => [
  ...GooglePlayProductDetails.fromProductDetails(
    const ProductDetailsWrapper(
      description: '',
      name: 'Pro',
      productId: BillingProducts.pro,
      productType: ProductType.subs,
      title: 'Pro',
      subscriptionOfferDetails: [
        SubscriptionOfferDetailsWrapper(
          basePlanId: BillingProducts.monthlyPlan,
          offerTags: [],
          offerIdToken: 'm-base',
          pricingPhases: [_phase],
        ),
        SubscriptionOfferDetailsWrapper(
          basePlanId: BillingProducts.monthlyPlan,
          offerId: 'trial-7d',
          offerTags: [],
          offerIdToken: 'm-trial',
          pricingPhases: [_free, _phase],
        ),
        SubscriptionOfferDetailsWrapper(
          basePlanId: BillingProducts.yearlyPlan,
          offerTags: [],
          offerIdToken: 'y-base',
          pricingPhases: [
            PricingPhaseWrapper(
              billingCycleCount: 0,
              billingPeriod: 'P1Y',
              formattedPrice: '₺799,99',
              priceAmountMicros: 799990000,
              priceCurrencyCode: 'TRY',
              recurrenceMode: RecurrenceMode.infiniteRecurring,
            ),
          ],
        ),
      ],
    ),
  ),
  ...GooglePlayProductDetails.fromProductDetails(
    const ProductDetailsWrapper(
      description: '',
      name: 'Ömür boyu',
      productId: BillingProducts.lifetime,
      productType: ProductType.inapp,
      title: 'Ömür boyu',
      oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(
        formattedPrice: '₺1.499,99',
        priceAmountMicros: 1499990000,
        priceCurrencyCode: 'TRY',
      ),
    ),
  ),
];

class _Store extends Fake implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <String>[];
  List<PurchaseDetails> owned = const [];
  PurchaseParam? bought;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: _storeProducts(), notFoundIDs: []);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    bought = purchaseParam;
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
    expect(js, contains('PRO_SUBSCRIPTION = "${BillingProducts.pro}"'));
    expect(js, contains('LIFETIME_PRODUCT = "${BillingProducts.lifetime}"'));
    // Fiyat koda yazılmaz: mağazadan okunur.
    final dart = File('lib/features/entitlement/data/billing_products.dart')
        .readAsStringSync();
    expect(RegExp(r'[₺$€]\s*\d').hasMatch(dart), isFalse);
  });

  test('hesap etiketi sunucuyla aynı özet (SHA-256)', () {
    // `node -e "require('./billing_util').accountTag('uid-1')"`
    expect(
      billingAccountTag('uid-1'),
      '4a49acf8a6bd727728495d1e541a840898fcc36747cdcdb9e8e68effc62bb15c',
    );
  });

  test('mağaza satırları: deneme teklifi seçilir, fiyat yinelenen fiyat', () {
    final offers = billingOffers(_storeProducts());
    expect(offers.map((o) => o.plan), BillingPlan.values);
    final monthly = offers.first;
    expect(monthly.trial, isTrue);
    expect(monthly.price, '₺99,99');
    expect((monthly.details as GooglePlayProductDetails).offerToken, 'm-trial');
    expect(offers[1].trial, isFalse);
    expect(offers[1].price, '₺799,99');
    expect(offers.last.price, '₺1.499,99');
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
      // Ücretsiz katmanda bile AI serbest (bugünkü davranış).
      c.read(aiAdmissionProvider).checkTier(hasOwnKey: false);
      expect(c.read(proFeatureProvider(ProFeature.builtInAi)), isTrue);
    });
  });

  testWidgets('Ayarlar\'da Pro kartı yalnız Play derlemesinde', (tester) async {
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

  test('/premium rotası yalnız Play\'de Pro ekranına açılır', () {
    final router = File('lib/app/router.dart').readAsStringSync();
    expect(
      router,
      contains('PlayBuild.enabled ? const ProScreen() : const PremiumScreen()'),
    );
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
      // Riverpod 3 dinleyicisiz akışı duraklatır (HAFIZA veri.md).
      c.listen(billingProvider, (_, _) {});
      c.listen(entitlementProvider, (_, _) {});
      return c;
    }

    test('satın al → sunucuda doğrula → onayla; hesap etiketi gider', () async {
      final c = container();
      final n = c.read(billingProvider.notifier);
      await n.start();
      expect(c.read(billingProvider).status, BillingStatus.ready);
      await n.buy(c.read(billingProvider).offers.first);
      expect(store.bought!.applicationUserName, billingAccountTag('uid-1'));
      store.updates.add([
        _purchase(BillingProducts.pro, PurchaseStatus.purchased),
      ]);
      await pumpEventQueue();
      expect(verified, [(BillingProducts.pro, 'token-pro')]);
      expect(store.completed, [BillingProducts.pro]);
      expect(c.read(billingProvider).notice, BillingNotice.done);
      expect(c.read(billingProvider).busy, isFalse);
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
              trial: false,
              details: _storeProducts().last,
            ),
          );
      expect(store.bought, isNull);
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

      // Ayrı mağaza: öncekinin aboneliği bu geri yüklemeyi duymasın.
      store = _Store()..owned = [owned];
      final missing = container();
      await missing.read(entitlementProvider.future);
      await missing.read(billingProvider.notifier).recover(quiet: true);
      await pumpEventQueue();
      expect(verified, [(BillingProducts.lifetime, 'token-lifetime')]);
      expect(missing.read(billingProvider).notice, isNull);
    });

    test('AI katman kapısı: ücretsizde yok, ömür boyu kendi anahtarıyla', () {
      final free = container();
      expect(
        () => free.read(aiAdmissionProvider).checkTier(hasOwnKey: false),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.kind,
            'kind',
            GeminiErrorKind.needsPro,
          ),
        ),
      );
      final life = container(e: Entitlement.fromMap({'tier': 'lifetime'}));
      return life.read(entitlementProvider.future).then((_) {
        life.read(aiAdmissionProvider).checkTier(hasOwnKey: true);
        expect(
          () => life.read(aiAdmissionProvider).checkTier(hasOwnKey: false),
          throwsA(isA<GeminiException>()),
        );
      });
    });

    testWidgets('Pro ekranı: katmanlar, mağaza fiyatı, geri yükle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWithValue('uid-1'),
            isAnonymousProvider.overrideWithValue(false),
            entitlementProvider.overrideWith(
              (ref) => Stream.value(Entitlement.none),
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
      expect(find.text('Şu an: Ücretsiz'), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-tiers')), findsOneWidget);
      expect(find.text('7 gün ücretsiz, sonra ₺99,99 / ay'), findsOneWidget);
      expect(find.text('₺799,99 / yıl'), findsOneWidget);
      expect(find.text('₺1.499,99 · bir kez öde'), findsOneWidget);
      expect(find.byKey(const ValueKey('pro-restore')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
