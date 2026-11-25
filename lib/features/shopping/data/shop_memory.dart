import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notes/domain/quick_entry.dart';
import '../../settings/settings_providers.dart';
import '../domain/shop_aisles.dart';
import '../domain/shop_recipes.dart';

@immutable
class ShopPriceEntry {
  const ShopPriceEntry({
    required this.price,
    this.store = '',
    this.unit = '',
    required this.epochDay,
  });

  final double price;
  final String store;
  final String unit;
  final int epochDay;

  Map<String, Object?> toJson() => {
    'p': price,
    if (store.isNotEmpty) 's': store,
    if (unit.isNotEmpty) 'u': unit,
    'd': epochDay,
  };

  factory ShopPriceEntry.fromJson(Map<String, dynamic> j) => ShopPriceEntry(
    price: (j['p'] as num?)?.toDouble() ?? 0,
    store: '${j['s'] ?? ''}',
    unit: '${j['u'] ?? ''}',
    epochDay: (j['d'] as num?)?.toInt() ?? 0,
  );
}

@immutable
class ShopBarcodeProduct {
  const ShopBarcodeProduct({
    required this.ean,
    required this.name,
    this.brand = '',
    this.qty = '',
    this.aisle = -1,
  });

  final String ean;
  final String name;
  final String brand;
  final String qty;
  final int aisle;

  String get displayText {
    final full =
        brand.isNotEmpty && !quickAscii(name).contains(quickAscii(brand))
        ? '$brand $name'
        : name;
    return quickCompose(full.trim(), qty.trim());
  }

  Map<String, Object?> toJson() => {
    'e': ean,
    'n': name,
    if (brand.isNotEmpty) 'b': brand,
    if (qty.isNotEmpty) 'q': qty,
    if (aisle >= 0) 'a': aisle,
  };

  factory ShopBarcodeProduct.fromJson(Map<String, dynamic> j) =>
      ShopBarcodeProduct(
        ean: '${j['e'] ?? ''}',
        name: '${j['n'] ?? ''}',
        brand: '${j['b'] ?? ''}',
        qty: '${j['q'] ?? ''}',
        aisle: (j['a'] as num?)?.toInt() ?? -1,
      );
}

@immutable
class ShopTripRecord {
  const ShopTripRecord({
    required this.epochDay,
    this.store = '',
    required this.total,
    required this.itemCount,
  });

  final int epochDay;
  final String store;
  final double total;
  final int itemCount;

  Map<String, Object?> toJson() => {
    'd': epochDay,
    if (store.isNotEmpty) 's': store,
    't': total,
    'c': itemCount,
  };

  factory ShopTripRecord.fromJson(Map<String, dynamic> j) => ShopTripRecord(
    epochDay: (j['d'] as num?)?.toInt() ?? 0,
    store: '${j['s'] ?? ''}',
    total: (j['t'] as num?)?.toDouble() ?? 0,
    itemCount: (j['c'] as num?)?.toInt() ?? 0,
  );
}

/// Faz 3 alışveriş hafızası: ürün + market fiyat geçmişi, markete göre özel
/// reyon sırası, liste bütçeleri, barkod önbelleği, özel tarifler, "bitmek
/// üzere" erteleme ve alışveriş özeti geçmişi.
@immutable
class ShopMemory {
  const ShopMemory({
    this.prices = const {},
    this.storeAisleOrders = const {},
    this.budgets = const {},
    this.barcodes = const {},
    this.customRecipes = const [],
    this.dismissedDueUntilMs = const {},
    this.trips = const [],
  });

  static const _maxPricesPerItem = 10;
  static const _maxPriceItems = 300;
  static const _maxBarcodes = 500;
  static const _maxTrips = 60;

  final Map<String, List<ShopPriceEntry>> prices;
  final Map<String, List<int>> storeAisleOrders;
  final Map<String, double> budgets;
  final Map<String, ShopBarcodeProduct> barcodes;
  final List<ShopRecipe> customRecipes;
  final Map<String, int> dismissedDueUntilMs;
  final List<ShopTripRecord> trips;

  static int epochDayOf(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;

  /// Ürünün son fiyatını döner (önce [store] eşleşmesi, yoksa en son fiyat).
  ShopPriceEntry? lastPrice(String itemText, {String? store}) {
    final list = prices[quickItemKey(itemText)];
    if (list == null || list.isEmpty) return null;
    final st = (store ?? '').trim();
    if (st.isNotEmpty) {
      for (var i = list.length - 1; i >= 0; i--) {
        if (list[i].store == st) return list[i];
      }
    }
    return list.last;
  }

  /// Market başına en güncel fiyatı kıyaslama için döner (ucuzdan pahalıya).
  List<({String store, double price, int epochDay})> storeComparisons(
    String itemText,
  ) {
    final list = prices[quickItemKey(itemText)];
    if (list == null || list.isEmpty) return const [];
    final latestByStore = <String, ShopPriceEntry>{};
    for (final e in list) {
      if (e.store.isEmpty) continue;
      latestByStore[e.store] = e;
    }
    final out = [
      for (final e in latestByStore.entries)
        (store: e.key, price: e.value.price, epochDay: e.value.epochDay),
    ]..sort((a, b) => a.price.compareTo(b.price));
    return out;
  }

  /// Seçili market için reyon sırası (kayıtlı değilse varsayılan 0..12).
  List<int> aisleOrderFor(String? storeId) {
    final defaults = [for (final a in kShopAisles) a.index];
    final key = (storeId ?? '').trim();
    final saved = key.isEmpty ? null : storeAisleOrders[key];
    if (saved == null || saved.isEmpty) return defaults;
    final seen = <int>{};
    final out = <int>[];
    for (final idx in saved) {
      if (idx >= 0 && idx < kShopAisles.length && seen.add(idx)) {
        out.add(idx);
      }
    }
    for (final idx in defaults) {
      if (seen.add(idx)) out.add(idx);
    }
    return out;
  }

  double? budgetFor(String noteId) => budgets[noteId];

  bool isDueDismissed(String itemText, DateTime now) {
    final until = dismissedDueUntilMs[quickItemKey(itemText)];
    if (until == null) return false;
    return now.millisecondsSinceEpoch < until;
  }

  ShopMemory withRecordedPrice(
    String itemText,
    double price, {
    String store = '',
    String unit = '',
    DateTime? at,
  }) {
    final key = quickItemKey(itemText);
    if (key.isEmpty || price <= 0) return this;
    final day = epochDayOf(at ?? DateTime.now());
    final nextPrices = {
      for (final e in prices.entries) e.key: List<ShopPriceEntry>.of(e.value),
    };
    final list = nextPrices.putIfAbsent(key, () => []);
    list.add(
      ShopPriceEntry(
        price: price,
        store: store.trim(),
        unit: unit.trim(),
        epochDay: day,
      ),
    );
    if (list.length > _maxPricesPerItem) {
      list.removeRange(0, list.length - _maxPricesPerItem);
    }
    while (nextPrices.length > _maxPriceItems) {
      nextPrices.remove(nextPrices.keys.firstWhere((k) => k != key));
    }
    return _copyWith(prices: nextPrices);
  }

  ShopMemory withStoreAisleOrder(String storeId, List<int> order) {
    final key = storeId.trim();
    if (key.isEmpty) return this;
    final next = {
      for (final e in storeAisleOrders.entries) e.key: List<int>.of(e.value),
    };
    if (order.isEmpty) {
      next.remove(key);
    } else {
      next[key] = List<int>.of(order);
    }
    return _copyWith(storeAisleOrders: next);
  }

  ShopMemory withBudget(String noteId, double? budget) {
    final next = Map<String, double>.of(budgets);
    if (budget == null || budget <= 0) {
      next.remove(noteId);
    } else {
      next[noteId] = budget;
    }
    return _copyWith(budgets: next);
  }

  ShopMemory withBarcode(ShopBarcodeProduct product) {
    if (product.ean.trim().isEmpty || product.name.trim().isEmpty) return this;
    final next = Map<String, ShopBarcodeProduct>.of(barcodes);
    next[product.ean.trim()] = product;
    while (next.length > _maxBarcodes) {
      next.remove(next.keys.first);
    }
    return _copyWith(barcodes: next);
  }

  ShopMemory withCustomRecipe(ShopRecipe recipe) {
    final next = [
      for (final r in customRecipes)
        if (r.id != recipe.id) r,
      recipe,
    ];
    if (next.length > 40) next.removeAt(0);
    return _copyWith(customRecipes: next);
  }

  ShopMemory withoutCustomRecipe(String id) => _copyWith(
    customRecipes: [
      for (final r in customRecipes)
        if (r.id != id) r,
    ],
  );

  ShopMemory withDueDismissed(String itemText, {DateTime? now}) {
    final key = quickItemKey(itemText);
    if (key.isEmpty) return this;
    final t = now ?? DateTime.now();
    final until = t.add(const Duration(hours: 24)).millisecondsSinceEpoch;
    final next = Map<String, int>.of(dismissedDueUntilMs)
      ..removeWhere((_, exp) => exp <= t.millisecondsSinceEpoch);
    next[key] = until;
    return _copyWith(dismissedDueUntilMs: next);
  }

  ShopMemory withTrip(ShopTripRecord trip) {
    if (trip.itemCount <= 0) return this;
    final next = [...trips, trip];
    if (next.length > _maxTrips) {
      next.removeRange(0, next.length - _maxTrips);
    }
    return _copyWith(trips: next);
  }

  ShopMemory _copyWith({
    Map<String, List<ShopPriceEntry>>? prices,
    Map<String, List<int>>? storeAisleOrders,
    Map<String, double>? budgets,
    Map<String, ShopBarcodeProduct>? barcodes,
    List<ShopRecipe>? customRecipes,
    Map<String, int>? dismissedDueUntilMs,
    List<ShopTripRecord>? trips,
  }) => ShopMemory(
    prices: prices ?? this.prices,
    storeAisleOrders: storeAisleOrders ?? this.storeAisleOrders,
    budgets: budgets ?? this.budgets,
    barcodes: barcodes ?? this.barcodes,
    customRecipes: customRecipes ?? this.customRecipes,
    dismissedDueUntilMs: dismissedDueUntilMs ?? this.dismissedDueUntilMs,
    trips: trips ?? this.trips,
  );

  String encode() => jsonEncode({
    if (prices.isNotEmpty)
      'p': {
        for (final e in prices.entries)
          e.key: [for (final p in e.value) p.toJson()],
      },
    if (storeAisleOrders.isNotEmpty) 'o': storeAisleOrders,
    if (budgets.isNotEmpty) 'b': budgets,
    if (barcodes.isNotEmpty)
      'bc': {for (final e in barcodes.entries) e.key: e.value.toJson()},
    if (customRecipes.isNotEmpty)
      'r': [for (final r in customRecipes) r.toJson()],
    if (dismissedDueUntilMs.isNotEmpty) 'd': dismissedDueUntilMs,
    if (trips.isNotEmpty) 't': [for (final t in trips) t.toJson()],
  });

  static ShopMemory decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ShopMemory();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final prices = <String, List<ShopPriceEntry>>{};
      (j['p'] as Map?)?.forEach((k, v) {
        if (v is List) {
          prices['$k'] = [
            for (final e in v)
              if (e is Map)
                ShopPriceEntry.fromJson(Map<String, dynamic>.from(e)),
          ];
        }
      });
      final orders = <String, List<int>>{};
      (j['o'] as Map?)?.forEach((k, v) {
        if (v is List) {
          orders['$k'] = [
            for (final n in v)
              if (n is num) n.toInt(),
          ];
        }
      });
      final budgets = <String, double>{};
      (j['b'] as Map?)?.forEach((k, v) {
        if (v is num) budgets['$k'] = v.toDouble();
      });
      final barcodes = <String, ShopBarcodeProduct>{};
      (j['bc'] as Map?)?.forEach((k, v) {
        if (v is Map) {
          barcodes['$k'] = ShopBarcodeProduct.fromJson(
            Map<String, dynamic>.from(v),
          );
        }
      });
      final recipes = <ShopRecipe>[];
      if (j['r'] is List) {
        for (final item in j['r'] as List) {
          if (item is Map) {
            recipes.add(ShopRecipe.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      final dismissed = <String, int>{};
      (j['d'] as Map?)?.forEach((k, v) {
        if (v is num) dismissed['$k'] = v.toInt();
      });
      final trips = <ShopTripRecord>[];
      if (j['t'] is List) {
        for (final item in j['t'] as List) {
          if (item is Map) {
            trips.add(ShopTripRecord.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }
      return ShopMemory(
        prices: prices,
        storeAisleOrders: orders,
        budgets: budgets,
        barcodes: barcodes,
        customRecipes: recipes,
        dismissedDueUntilMs: dismissed,
        trips: trips,
      );
    } catch (_) {
      return const ShopMemory();
    }
  }
}

final shopMemoryProvider = NotifierProvider<ShopMemoryNotifier, ShopMemory>(
  ShopMemoryNotifier.new,
);

class ShopMemoryNotifier extends Notifier<ShopMemory> {
  static const _key = 'shop_memory_v1';

  @override
  ShopMemory build() =>
      ShopMemory.decode(ref.watch(sharedPreferencesProvider).getString(_key));

  void _save(ShopMemory next) {
    state = next;
    ref.read(sharedPreferencesProvider).setString(_key, next.encode());
  }

  void recordPrice(
    String itemText,
    double price, {
    String store = '',
    String unit = '',
  }) =>
      _save(state.withRecordedPrice(itemText, price, store: store, unit: unit));

  void saveStoreAisleOrder(String storeId, List<int> order) =>
      _save(state.withStoreAisleOrder(storeId, order));

  void setBudget(String noteId, double? budget) =>
      _save(state.withBudget(noteId, budget));

  void saveBarcode(ShopBarcodeProduct product) =>
      _save(state.withBarcode(product));

  void saveCustomRecipe(ShopRecipe recipe) =>
      _save(state.withCustomRecipe(recipe));

  void deleteCustomRecipe(String id) => _save(state.withoutCustomRecipe(id));

  void dismissDueItem(String itemText) =>
      _save(state.withDueDismissed(itemText));

  void recordTrip(ShopTripRecord trip) => _save(state.withTrip(trip));
}
