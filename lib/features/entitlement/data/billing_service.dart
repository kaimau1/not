// SATIN ALMA (Play Billing) — PLAN §1.5 PL6.
//
// Akış: satın al → `purchaseStream` → sunucuda doğrula (`verifyPurchase`
// Function'ı Google Play Developer API'ye sorar, `entitlements/{uid}`'i YALNIZ
// o yazar) → `entitlementProvider` belgeyi zaten dinliyor, kapı kendiliğinden
// açılır → satın alma onaylanır (`completePurchase`; sunucu da onaylar).
// Doğrulanamayan satın alma ONAYLANMAZ: Play 3 günde iade eder, kullanıcı
// boşa ödemez; açılışta sessiz geri yükleme yeniden dener ([recover]).
//
// KİŞİSEL APK / WEB: [EntitlementGate.active] false → `InAppPurchase`'a HİÇ
// dokunulmaz (Billing bağlantısı yok), durum [BillingStatus.off].
import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/entitlement.dart';
import 'billing_products.dart';
import 'entitlement_service.dart';

enum BillingStatus {
  /// Play derlemesi değil: satın alma yok.
  off,

  /// Play derlemesi ama Android değil (web): "telefondan al".
  elsewhere,
  loading,
  ready,

  /// Google Play'e ulaşılamadı / ürün tanımlı değil.
  unavailable,
}

/// Kullanıcıya bir kez gösterilecek sonuç (ekran SnackBar'la söyler).
enum BillingNotice {
  pending,
  canceled,
  failed,
  verifyFailed,
  otherAccount,
  guest,
  done,
  restored,
  nothingToRestore,
}

/// Ekrandaki bir satın alma satırı.
class BillingOffer {
  const BillingOffer({
    required this.plan,
    required this.price,
    required this.trial,
    required this.details,
  });

  final BillingPlan plan;

  /// Mağazanın biçimlediği YİNELENEN fiyat (denemede de deneme sonrası).
  final String price;

  /// Ücretsiz deneme teklifi var mı (Play yalnız uygun kullanıcıya listeler).
  final bool trial;

  final ProductDetails details;
}

@immutable
class BillingState {
  const BillingState({
    this.status = BillingStatus.loading,
    this.offers = const [],
    this.busy = false,
    this.notice,
    this.noticeId = 0,
  });

  final BillingStatus status;
  final List<BillingOffer> offers;

  /// Satın alma / doğrulama sürüyor (düğmeler kilitli).
  final bool busy;
  final BillingNotice? notice;

  /// Aynı bildirim art arda gelince de ekran duysun diye sayaç.
  final int noticeId;

  BillingOffer? offer(BillingPlan plan) {
    for (final o in offers) {
      if (o.plan == plan) return o;
    }
    return null;
  }

  BillingState copyWith({
    BillingStatus? status,
    List<BillingOffer>? offers,
    bool? busy,
  }) => BillingState(
    status: status ?? this.status,
    offers: offers ?? this.offers,
    busy: busy ?? this.busy,
    notice: notice,
    noticeId: noticeId,
  );

  BillingState withNotice(BillingNotice n) => BillingState(
    status: status,
    offers: offers,
    notice: n,
    noticeId: noticeId + 1,
  );
}

/// Play'e satın almada verilen `obfuscatedAccountId`: uid'in SHA-256'sı
/// (sunucu `billing_util.js` `accountTag` aynısı). Sunucu başka hesabın
/// satın almasını bununla da reddeder.
String billingAccountTag(String uid) =>
    sha256.convert(utf8.encode(uid)).toString();

/// Mağazanın döndürdüğü ürünlerden ekrandaki satırlar. Abonelikte Play her
/// temel plan + teklif için ayrı kayıt verir: deneme teklifi varsa o, yoksa
/// temel plan seçilir.
List<BillingOffer> billingOffers(List<ProductDetails> products) {
  BillingOffer? best(BillingPlan plan) {
    BillingOffer? pick;
    for (final p in products) {
      if (p is! GooglePlayProductDetails || p.id != plan.productId) continue;
      if (!plan.isSubscription) {
        return BillingOffer(
          plan: plan,
          price: p.price,
          trial: false,
          details: p,
        );
      }
      final i = p.subscriptionIndex;
      final o = i == null
          ? null
          : p.productDetails.subscriptionOfferDetails?[i];
      if (o == null || o.basePlanId != plan.basePlanId) continue;
      if (o.pricingPhases.isEmpty) continue;
      final trial = o.pricingPhases.any((ph) => ph.priceAmountMicros == 0);
      if (pick != null && (pick.trial || !trial)) continue;
      pick = BillingOffer(
        plan: plan,
        price: o.pricingPhases.last.formattedPrice,
        trial: trial,
        details: p,
      );
    }
    return pick;
  }

  return [for (final plan in BillingPlan.values) best(plan)].nonNulls.toList();
}

final billingProvider = NotifierProvider<BillingNotifier, BillingState>(
  BillingNotifier.new,
);

class BillingNotifier extends Notifier<BillingState> {
  /// Testler sahte mağaza / doğrulayıcı verir.
  @visibleForTesting
  static InAppPurchase Function() debugStore = () => InAppPurchase.instance;

  @visibleForTesting
  static Future<void> Function(String productId, String token) debugVerify =
      _verifyOnServer;

  static Future<void> _verifyOnServer(String productId, String token) async {
    await FirebaseFunctions.instance
        .httpsCallable('verifyPurchase')
        .call<Object?>({'productId': productId, 'purchaseToken': token});
  }

  StreamSubscription<List<PurchaseDetails>>? _sub;
  Future<void>? _starting;

  /// Sıradaki `restorePurchases` listesi kimin: sessiz (açılış) mı, elle mi.
  bool? _restoreQuiet;

  @override
  BillingState build() {
    if (!EntitlementGate.active) {
      return const BillingState(status: BillingStatus.off);
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const BillingState(status: BillingStatus.elsewhere);
    }
    ref.onDispose(() => _sub?.cancel());
    return const BillingState();
  }

  bool get _usable =>
      state.status != BillingStatus.off &&
      state.status != BillingStatus.elsewhere;

  /// Mağazaya bağlanır, ürünleri okur (bir kez; "Tekrar dene" yeniden).
  Future<void> start({bool retry = false}) {
    if (!_usable) return Future.value();
    if (retry) _starting = null;
    return _starting ??= _start();
  }

  Future<void> _start() async {
    final store = debugStore();
    _sub ??= store.purchaseStream.listen(
      _onPurchases,
      onError: (Object _) => _say(BillingNotice.failed),
    );
    state = state.copyWith(status: BillingStatus.loading);
    try {
      if (!await store.isAvailable()) {
        state = state.copyWith(status: BillingStatus.unavailable);
        return;
      }
      final res = await store.queryProductDetails(BillingProducts.all);
      final offers = billingOffers(res.productDetails);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: offers.isEmpty
            ? BillingStatus.unavailable
            : BillingStatus.ready,
        offers: offers,
      );
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(status: BillingStatus.unavailable);
      }
    }
  }

  /// Hesap var mı (misafire satılmaz: misafir hesap cihazla kaybolur,
  /// sunucu da reddeder).
  String? _buyerUid() {
    final uid = ref.read(currentUidProvider);
    if (uid == null || ref.read(isAnonymousProvider)) return null;
    return uid;
  }

  Future<void> buy(BillingOffer offer) async {
    if (state.busy || !_usable) return;
    final uid = _buyerUid();
    if (uid == null) return _say(BillingNotice.guest);
    await start();
    state = state.copyWith(busy: true);
    try {
      final launched = await debugStore().buyNonConsumable(
        purchaseParam: GooglePlayPurchaseParam(
          productDetails: offer.details,
          applicationUserName: billingAccountTag(uid),
        ),
      );
      if (!launched) _say(BillingNotice.failed);
    } catch (_) {
      _say(BillingNotice.failed);
    }
  }

  /// "Satın alımları geri yükle" ([quiet] false) ya da açılıştaki sessiz
  /// onarım ([quiet] true: yalnız onaylanmamış ya da hakta görünmeyen satın
  /// almayı doğrular, bildirim göstermez).
  Future<void> recover({bool quiet = false}) async {
    if (!_usable || (quiet && state.busy)) return;
    if (_buyerUid() == null) {
      if (!quiet) _say(BillingNotice.guest);
      return;
    }
    await start();
    if (!quiet) state = state.copyWith(busy: true);
    _restoreQuiet = quiet;
    try {
      await debugStore().restorePurchases();
    } catch (_) {
      _restoreQuiet = null;
      if (!quiet) _say(BillingNotice.failed);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    final quiet = _restoreQuiet;
    final fromRestore =
        list.isEmpty || list.every((p) => p.status == PurchaseStatus.restored);
    if (fromRestore) _restoreQuiet = null;
    var verified = 0;
    BillingNotice? failure;
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          // Belirteç şimdiden hesaba bağlansın: ödeme onaylanınca sunucu
          // (RTDN) hakkı uygulama kapalıyken de açar.
          _say(BillingNotice.pending);
          unawaited(_verify(p));
        case PurchaseStatus.canceled:
          _say(BillingNotice.canceled);
        case PurchaseStatus.error:
          _say(BillingNotice.failed);
        case PurchaseStatus.purchased:
          _say(await _verify(p) ?? BillingNotice.done);
        case PurchaseStatus.restored:
          if (quiet == true && !_needsSync(p)) continue;
          final f = await _verify(p);
          if (f == null) {
            verified++;
          } else {
            failure ??= f;
          }
      }
    }
    if (fromRestore && quiet != true) {
      _say(
        verified > 0
            ? BillingNotice.restored
            : failure ?? BillingNotice.nothingToRestore,
      );
    }
  }

  /// Sessiz onarımda doğrulanmaya değer mi: onaylanmamış (3 gün içinde
  /// onaylanmazsa Play iade eder) ya da hak belgesi bunu henüz göstermiyor
  /// (kaçmış RTDN, yarıda kalmış doğrulama).
  bool _needsSync(PurchaseDetails p) {
    if (p.pendingCompletePurchase) return true;
    final e = ref.read(entitlementProvider).value;
    if (e == null) return true;
    return p.productID == BillingProducts.lifetime
        ? !e.lifetimeOwned
        : !e.proActive(DateTime.now());
  }

  /// Sunucuda doğrular, sonra onaylar. null = tamam; değilse söylenecek
  /// neden. Doğrulanamayan satın alma ONAYLANMAZ (bkz. dosya başı).
  Future<BillingNotice?> _verify(PurchaseDetails p) async {
    try {
      await debugVerify(p.productID, p.verificationData.serverVerificationData);
      if (p.pendingCompletePurchase && p.status != PurchaseStatus.pending) {
        await debugStore().completePurchase(p);
      }
      return null;
    } on FirebaseFunctionsException catch (e) {
      return switch (e.message) {
        'other-account' => BillingNotice.otherAccount,
        'guest' => BillingNotice.guest,
        _ => BillingNotice.verifyFailed,
      };
    } catch (_) {
      return BillingNotice.verifyFailed;
    }
  }

  void _say(BillingNotice n) {
    if (ref.mounted) state = state.withNotice(n);
  }
}

/// Açılışta sessiz onarım (Play + Android): ilk karelerin işine girmesin
/// diye gecikmeli; hak belgesi o arada yüklenmiş olur.
final billingRecoveryProvider = Provider<void>((ref) {
  if (!EntitlementGate.active) return;
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final timer = Timer(const Duration(seconds: 20), () {
    unawaited(ref.read(billingProvider.notifier).recover(quiet: true));
  });
  ref.onDispose(timer.cancel);
});
