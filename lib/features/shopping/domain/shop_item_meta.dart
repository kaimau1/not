import 'package:flutter/foundation.dart';

import '../../notes/domain/list_mode.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';

/// Mağaza Kipi 3 durumlu madde akışı (`extras['st']`).
enum ShopItemStatus {
  /// Henüz alınacak (0).
  todo,

  /// Sepette / alındı (1, `checked = true`).
  inCart,

  /// Markette yoktu / sonraya bırakıldı (2, `checked = false` → "Bitir"de silinmez).
  unavailable,
}

/// Alışveriş madde meta verisi — miktar, birim, fiyat ve reyon doğrudan
/// kanonik [NoteItem] alanları üzerinde ince bir sarmalayıcıdır (çift yazım
/// yok). Yalnız alışverişe özgü alanlar (`s`: market, `st`: durum, `by`:
/// kimin aldığı) `NoteItem.extras` içinde tutulur.
@immutable
class ShopItemMeta {
  const ShopItemMeta({
    this.qty,
    this.unit = '',
    this.unitPrice,
    this.store = '',
    this.status = ShopItemStatus.todo,
    this.aisle,
    this.takenBy = '',
  });

  static const keyQty = 'q';
  static const keyUnit = 'u';
  static const keyPrice = 'p';
  static const keyStore = 's';
  static const keyStatus = 'st';
  static const keyAisle = 'g';
  static const keyTakenBy = 'by';

  final double? qty;
  final String unit;
  final double? unitPrice;
  final String store;
  final ShopItemStatus status;
  final int? aisle;
  final String takenBy;

  bool get isUnavailable => status == ShopItemStatus.unavailable;

  factory ShopItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final parsed = parseQuickQty(quickQtyOf(item.text));
    final rawQ = ex[keyQty];
    final qty =
        item.quantity ?? (rawQ is num ? rawQ.toDouble() : null) ?? parsed?.value;
    final rawU = ex[keyUnit];
    final unit = item.unit.isNotEmpty
        ? item.unit
        : (rawU is String && rawU.isNotEmpty ? rawU : (parsed?.rawUnit ?? ''));
    final rawP = ex[keyPrice];
    final price = item.price ?? (rawP is num ? rawP.toDouble() : null);
    final store = (ex[keyStore] as String? ?? '').trim();
    final rawSt = ex[keyStatus];
    final stCode = rawSt is num ? rawSt.toInt() : (item.checked ? 1 : 0);
    final status = switch (stCode) {
      2 when !item.checked => ShopItemStatus.unavailable,
      1 => ShopItemStatus.inCart,
      _ => item.checked ? ShopItemStatus.inCart : ShopItemStatus.todo,
    };
    final rawG = ex[keyAisle];
    final aisle =
        aisleIndexFromCategory(item.category) ??
        (rawG is num ? rawG.toInt() : null);
    final takenBy = (ex[keyTakenBy] as String? ?? '').trim();
    return ShopItemMeta(
      qty: qty,
      unit: unit,
      unitPrice: price,
      store: store,
      status: status,
      aisle: aisle,
      takenBy: takenBy,
    );
  }

  ShopItemMeta copyWith({
    double? qty,
    bool clearQty = false,
    String? unit,
    double? unitPrice,
    bool clearPrice = false,
    String? store,
    ShopItemStatus? status,
    int? aisle,
    bool clearAisle = false,
    String? takenBy,
  }) => ShopItemMeta(
    qty: clearQty ? null : (qty ?? this.qty),
    unit: unit ?? this.unit,
    unitPrice: clearPrice ? null : (unitPrice ?? this.unitPrice),
    store: store ?? this.store,
    status: status ?? this.status,
    aisle: clearAisle ? null : (aisle ?? this.aisle),
    takenBy: takenBy ?? this.takenBy,
  );

  /// Kanonik [NoteItem] alanlarını günceller; eski `q`/`u`/`p`/`g` anahtarlarını
  /// `extras`'tan temizler (çift yazım yok, S16 +0 bayt kuralı).
  NoteItem applyToItem(NoteItem item, {bool syncTextQty = false}) {
    final next = Map<String, dynamic>.from(item.extras)
      ..remove(keyQty)
      ..remove(keyUnit)
      ..remove(keyPrice)
      ..remove(keyAisle);

    void setOrRemove(String k, Object? v) {
      if (v == null || (v is String && v.isEmpty)) {
        next.remove(k);
      } else {
        next[k] = v;
      }
    }

    setOrRemove(keyStore, store.trim());
    setOrRemove(keyStatus, status == ShopItemStatus.unavailable ? 2 : null);
    setOrRemove(
      keyTakenBy,
      status == ShopItemStatus.inCart ? takenBy.trim() : null,
    );

    final validQty = qty != null && qty! > 0 ? qty : null;
    final validUnit = validQty != null ? unit.trim() : '';
    final validPrice = unitPrice != null && unitPrice! > 0 ? unitPrice : null;
    final aisleKey = aisleCategoryKey(aisle);
    final nextCategory = aisleKey ??
        (aisleIndexFromCategory(item.category) != null ? '' : item.category);

    var nextText = item.text;
    if (syncTextQty) {
      final base = quickBaseName(item.text);
      final qLabel = formatShopQty(validQty, validUnit);
      nextText = quickCompose(base, qLabel);
    }

    return item.copyWith(
      text: nextText,
      checked: status == ShopItemStatus.inCart,
      quantity: validQty,
      clearQuantity: validQty == null,
      unit: validUnit,
      price: validPrice,
      clearPrice: validPrice == null,
      category: nextCategory,
      extras: next,
    );
  }
}

/// Sayı ve birimi temiz etikete çevirir (`2`, `1,5 kg`, `500 g`).
String formatShopQty(double? qty, String unit) {
  if (qty == null || qty <= 0) return '';
  final u = unit.trim();
  if (qty == 1 && u.isEmpty) return '';
  final n = formatQuickNumber(qty);
  return u.isEmpty ? n : '$n $u';
}

/// Satır içi `− / +` miktar adımlama:
/// - `kg` / `lt`: `< 2` veya küsuratlıysa `0,5`, yoksa `1` adım (alt sınır `0,25`).
/// - `g` / `ml`: `< 500` ise `100`, değilse `250` adım (alt sınır `50`).
/// - Diğer/birimsiz: `1` adım (alt sınır `1`).
NoteItem stepShopItemQty(NoteItem item, {required bool increase}) {
  final meta = ShopItemMeta.fromItem(item);
  final u = quickAscii(meta.unit);
  final cur = meta.qty ?? 1.0;

  double next = cur;
  var nextUnit = meta.unit;
  if (u == 'kg' ||
      u == 'kilo' ||
      u == 'kilogram' ||
      u == 'lt' ||
      u == 'l' ||
      u == 'litre') {
    final step = (cur < 2 || (cur % 1).abs() > 1e-4) ? 0.5 : 1.0;
    next = increase ? cur + step : (cur - step).clamp(0.25, 9999.0);
  } else if (u == 'g' || u == 'gr' || u == 'gram' || u == 'ml') {
    final step = cur < 500 ? 100.0 : 250.0;
    next = increase ? cur + step : (cur - step).clamp(50.0, 99999.0);
    if (next >= 1000) {
      next = next / 1000;
      nextUnit = u == 'ml' ? 'lt' : 'kg';
    }
  } else {
    next = increase ? cur + 1.0 : (cur - 1.0).clamp(1.0, 9999.0);
  }
  return meta.copyWith(qty: next, unit: nextUnit).applyToItem(
    item,
    syncTextQty: true,
  );
}

/// Satır tutarını (₺) hesaplar.
///
/// Kural: birim fiyat (`unitPrice` ya da geçmiş fiyat `fallbackUnitPrice`)
/// verilmişse, `g`/`ml` gibi alt birimlerde kullanıcı genellikle paket fiyatı
/// girdiğinden çarpan `1.0` alınır; `adet`/`paket`/`kg`/`lt`/birimsiz satırlarda
/// `qty ?? 1.0` ile çarpılır.
double? shopItemLineTotal(NoteItem item, {double? fallbackUnitPrice}) {
  final meta = ShopItemMeta.fromItem(item);
  final unitPrice = meta.unitPrice ?? fallbackUnitPrice;
  if (unitPrice == null || unitPrice <= 0) return null;
  final u = quickAscii(meta.unit);
  final q = meta.qty;
  if (q == null || q <= 0) return unitPrice;
  if (u == 'g' || u == 'gr' || u == 'gram' || u == 'ml') {
    return unitPrice;
  }
  return unitPrice * q;
}
