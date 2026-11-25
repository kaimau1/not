import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';
import '../../notes/domain/smart_list.dart';
import 'shop_item_meta.dart';

/// Öğün / tarif paketi tek malzemesi.
@immutable
class ShopIngredient {
  const ShopIngredient({
    required this.name,
    required this.qty,
    this.unit = '',
    required this.aisle,
  });

  final String name;
  final double qty;
  final String unit;
  final int aisle;

  Map<String, Object?> toJson() => {
    'n': name,
    if (qty != 1) 'q': qty,
    if (unit.isNotEmpty) 'u': unit,
    'a': aisle,
  };

  factory ShopIngredient.fromJson(Map<String, dynamic> j) => ShopIngredient(
    name: '${j['n'] ?? ''}',
    qty: (j['q'] as num?)?.toDouble() ?? 1,
    unit: '${j['u'] ?? ''}',
    aisle: (j['a'] as num?)?.toInt() ?? 0,
  );
}

/// Hazır veya kullanıcının kaydettiği Türk mutfağı alışveriş paketi.
@immutable
class ShopRecipe {
  const ShopRecipe({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.baseServings,
    required this.ingredients,
    this.custom = false,
  });

  final String id;
  final String titleTr;
  final String titleEn;
  final int baseServings;
  final List<ShopIngredient> ingredients;
  final bool custom;

  String title({required bool isTr}) =>
      isTr ? titleTr : (titleEn.isEmpty ? titleTr : titleEn);

  Map<String, Object?> toJson() => {
    'id': id,
    'tr': titleTr,
    'en': titleEn,
    's': baseServings,
    'c': custom,
    'i': [for (final ing in ingredients) ing.toJson()],
  };

  factory ShopRecipe.fromJson(Map<String, dynamic> j) => ShopRecipe(
    id: '${j['id'] ?? ''}',
    titleTr: '${j['tr'] ?? ''}',
    titleEn: '${j['en'] ?? ''}',
    baseServings: (j['s'] as num?)?.toInt() ?? 4,
    custom: j['c'] as bool? ?? true,
    ingredients: [
      for (final item in (j['i'] as List?) ?? const [])
        if (item is Map)
          ShopIngredient.fromJson(Map<String, dynamic>.from(item)),
    ],
  );
}

/// 18 hazır Türk mutfağı & ev alışverişi paketi (%100 cihaz içi).
const List<ShopRecipe> kBuiltInShopRecipes = [
  ShopRecipe(
    id: 'weekly_basics',
    titleTr: 'Haftalık Temel Alışveriş',
    titleEn: 'Weekly Basics',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Ekmek', qty: 2, aisle: 1),
      ShopIngredient(name: 'Süt', qty: 2, unit: 'lt', aisle: 2),
      ShopIngredient(name: 'Yumurta', qty: 15, unit: 'adet', aisle: 2),
      ShopIngredient(name: 'Beyaz peynir', qty: 500, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Yoğurt', qty: 1, unit: 'kg', aisle: 2),
      ShopIngredient(name: 'Domates', qty: 1, unit: 'kg', aisle: 0),
      ShopIngredient(name: 'Salatalık', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Patates', qty: 2, unit: 'kg', aisle: 0),
      ShopIngredient(name: 'Soğan', qty: 1, unit: 'kg', aisle: 0),
      ShopIngredient(name: 'Tavuk göğsü', qty: 750, unit: 'g', aisle: 3),
    ],
  ),
  ShopRecipe(
    id: 'sunday_breakfast',
    titleTr: 'Pazar Kahvaltısı',
    titleEn: 'Sunday Breakfast',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Simit', qty: 4, unit: 'adet', aisle: 1),
      ShopIngredient(name: 'Beyaz peynir', qty: 300, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Kaşar peyniri', qty: 250, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Siyah zeytin', qty: 250, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Yumurta', qty: 6, unit: 'adet', aisle: 2),
      ShopIngredient(name: 'Sucuk', qty: 250, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Domates', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Salatalık', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Bal', qty: 1, unit: 'kavanoz', aisle: 2),
      ShopIngredient(name: 'Kaymak', qty: 200, unit: 'g', aisle: 2),
    ],
  ),
  ShopRecipe(
    id: 'menemen',
    titleTr: 'Menemen',
    titleEn: 'Turkish Menemen',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Yumurta', qty: 6, unit: 'adet', aisle: 2),
      ShopIngredient(name: 'Domates', qty: 750, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Sivri biber', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Tereyağı', qty: 100, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Ekmek', qty: 2, aisle: 1),
    ],
  ),
  ShopRecipe(
    id: 'mercimek_corbasi',
    titleTr: 'Mercimek Çorbası',
    titleEn: 'Red Lentil Soup',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Kırmızı mercimek', qty: 500, unit: 'g', aisle: 4),
      ShopIngredient(name: 'Soğan', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Havuç', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Patates', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Domates salçası', qty: 1, unit: 'kutu', aisle: 4),
      ShopIngredient(name: 'Limon', qty: 2, unit: 'adet', aisle: 0),
    ],
  ),
  ShopRecipe(
    id: 'karniyarik',
    titleTr: 'Karnıyarık',
    titleEn: 'Stuffed Eggplant (Karnıyarık)',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Patlıcan', qty: 1, unit: 'kg', aisle: 0),
      ShopIngredient(name: 'Dana kıyma', qty: 400, unit: 'g', aisle: 3),
      ShopIngredient(name: 'Soğan', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Yeşil biber', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Domates', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Sarımsak', qty: 1, aisle: 0),
      ShopIngredient(name: 'Maydanoz', qty: 1, unit: 'demet', aisle: 0),
      ShopIngredient(name: 'Domates salçası', qty: 1, unit: 'kutu', aisle: 4),
    ],
  ),
  ShopRecipe(
    id: 'kiymali_makarna',
    titleTr: 'Kıymalı Makarna',
    titleEn: 'Pasta with Minced Beef',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Makarna', qty: 1, unit: 'paket', aisle: 4),
      ShopIngredient(name: 'Dana kıyma', qty: 300, unit: 'g', aisle: 3),
      ShopIngredient(name: 'Domates sosu', qty: 1, unit: 'kavanoz', aisle: 4),
      ShopIngredient(name: 'Soğan', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Yoğurt', qty: 500, unit: 'g', aisle: 2),
    ],
  ),
  ShopRecipe(
    id: 'mangal',
    titleTr: 'Mangal Keyfi',
    titleEn: 'BBQ Bundle',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Tavuk kanat', qty: 1, unit: 'kg', aisle: 3),
      ShopIngredient(name: 'Köftelik kıyma', qty: 500, unit: 'g', aisle: 3),
      ShopIngredient(name: 'Lavaş', qty: 1, unit: 'paket', aisle: 1),
      ShopIngredient(name: 'Domates', qty: 1, unit: 'kg', aisle: 0),
      ShopIngredient(name: 'Yeşil biber', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Ayran', qty: 2, unit: 'lt', aisle: 2),
      ShopIngredient(name: 'Mangal kömürü', qty: 1, unit: 'paket', aisle: 9),
    ],
  ),
  ShopRecipe(
    id: 'misafir_cayi',
    titleTr: 'Misafir Çayı & İkram',
    titleEn: 'Tea Time & Guests',
    baseServings: 6,
    ingredients: [
      ShopIngredient(name: 'Siyah çay', qty: 500, unit: 'g', aisle: 5),
      ShopIngredient(name: 'Kurabiye', qty: 500, unit: 'g', aisle: 1),
      ShopIngredient(name: 'Börek', qty: 500, unit: 'g', aisle: 1),
      ShopIngredient(name: 'Limon', qty: 3, unit: 'adet', aisle: 0),
      ShopIngredient(name: 'Peçete', qty: 1, unit: 'paket', aisle: 8),
    ],
  ),
  ShopRecipe(
    id: 'hasta_paketi',
    titleTr: 'Hasta / Toparlanma Paketi',
    titleEn: 'Recovery Care Pack',
    baseServings: 2,
    ingredients: [
      ShopIngredient(name: 'Tavuk göğsü', qty: 500, unit: 'g', aisle: 3),
      ShopIngredient(name: 'Arpa şehriye', qty: 1, unit: 'paket', aisle: 4),
      ShopIngredient(name: 'Limon', qty: 4, unit: 'adet', aisle: 0),
      ShopIngredient(name: 'Ihlamur', qty: 1, unit: 'paket', aisle: 5),
      ShopIngredient(name: 'Nane limon', qty: 1, unit: 'paket', aisle: 5),
      ShopIngredient(name: 'Kağıt mendil', qty: 2, unit: 'paket', aisle: 8),
    ],
  ),
  ShopRecipe(
    id: 'kuru_fasulye_pilav',
    titleTr: 'Kuru Fasulye & Pilav',
    titleEn: 'White Beans & Rice',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Kuru fasulye', qty: 500, unit: 'g', aisle: 4),
      ShopIngredient(name: 'Baldo pirinç', qty: 500, unit: 'g', aisle: 4),
      ShopIngredient(name: 'Soğan', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Domates salçası', qty: 1, unit: 'kutu', aisle: 4),
      ShopIngredient(name: 'Tereyağı', qty: 250, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Turşu', qty: 1, unit: 'kavanoz', aisle: 4),
    ],
  ),
  ShopRecipe(
    id: 'tavuk_sote',
    titleTr: 'Tavuk Sote',
    titleEn: 'Chicken Sauté',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Tavuk göğsü', qty: 600, unit: 'g', aisle: 3),
      ShopIngredient(name: 'Kapya biber', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Yeşil biber', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Domates', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Mantar', qty: 400, unit: 'g', aisle: 0),
    ],
  ),
  ShopRecipe(
    id: 'peynirli_borek',
    titleTr: 'Peynirli Börek',
    titleEn: 'Cheese Pastry (Börek)',
    baseServings: 6,
    ingredients: [
      ShopIngredient(name: 'Yufka', qty: 1, unit: 'paket', aisle: 1),
      ShopIngredient(name: 'Beyaz peynir', qty: 500, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Maydanoz', qty: 1, unit: 'demet', aisle: 0),
      ShopIngredient(name: 'Süt', qty: 500, unit: 'ml', aisle: 2),
      ShopIngredient(name: 'Yumurta', qty: 3, unit: 'adet', aisle: 2),
      ShopIngredient(name: 'Soda', qty: 1, unit: 'şişe', aisle: 5),
    ],
  ),
  ShopRecipe(
    id: 'ev_koftesi',
    titleTr: 'Ev Yapımı Köfte',
    titleEn: 'Homemade Meatballs',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Köftelik kıyma', qty: 500, unit: 'g', aisle: 3),
      ShopIngredient(name: 'Soğan', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Galeta unu', qty: 1, unit: 'paket', aisle: 4),
      ShopIngredient(name: 'Patates', qty: 1, unit: 'kg', aisle: 0),
      ShopIngredient(name: 'Ayran', qty: 1, unit: 'lt', aisle: 2),
    ],
  ),
  ShopRecipe(
    id: 'mevsim_salatasi',
    titleTr: 'Mevsim Salatası & Meze',
    titleEn: 'Fresh Salad & Mezze',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Göbek marul', qty: 1, unit: 'adet', aisle: 0),
      ShopIngredient(name: 'Roka', qty: 1, unit: 'demet', aisle: 0),
      ShopIngredient(name: 'Cherry domates', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Havuç', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Nar ekşisi', qty: 1, unit: 'şişe', aisle: 4),
      ShopIngredient(name: 'Zeytinyağı', qty: 1, unit: 'lt', aisle: 4),
    ],
  ),
  ShopRecipe(
    id: 'manti_yogurt',
    titleTr: 'Mantı & Yoğurt',
    titleEn: 'Turkish Mantı',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Mantı', qty: 500, unit: 'g', aisle: 7),
      ShopIngredient(name: 'Süzme yoğurt', qty: 500, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Sarımsak', qty: 1, aisle: 0),
      ShopIngredient(name: 'Tereyağı', qty: 100, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Kuru nane', qty: 1, unit: 'paket', aisle: 4),
    ],
  ),
  ShopRecipe(
    id: 'kahve_keyfi',
    titleTr: 'Çay & Kahve Keyfi',
    titleEn: 'Coffee & Snacks',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Türk kahvesi', qty: 250, unit: 'g', aisle: 5),
      ShopIngredient(name: 'Filtre kahve', qty: 250, unit: 'g', aisle: 5),
      ShopIngredient(name: 'Süt', qty: 1, unit: 'lt', aisle: 2),
      ShopIngredient(name: 'Bitter çikolata', qty: 2, unit: 'paket', aisle: 6),
      ShopIngredient(name: 'Bisküvi', qty: 2, unit: 'paket', aisle: 6),
    ],
  ),
  ShopRecipe(
    id: 'sebze_turlu',
    titleTr: 'Sebzeli Türlü / Güveç',
    titleEn: 'Vegetable Stew',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Kabak', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Patlıcan', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Taze fasulye', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Domates', qty: 500, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Biber', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Dana kuşbaşı', qty: 400, unit: 'g', aisle: 3),
    ],
  ),
  ShopRecipe(
    id: 'ev_pizza',
    titleTr: 'Evde Pizza Akşamı',
    titleEn: 'Homemade Pizza Night',
    baseServings: 4,
    ingredients: [
      ShopIngredient(name: 'Pizza hamuru', qty: 2, unit: 'paket', aisle: 1),
      ShopIngredient(name: 'Mozzarella', qty: 300, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Domates sosu', qty: 1, unit: 'kavanoz', aisle: 4),
      ShopIngredient(name: 'Sucuk', qty: 200, unit: 'g', aisle: 2),
      ShopIngredient(name: 'Kültür mantarı', qty: 250, unit: 'g', aisle: 0),
      ShopIngredient(name: 'Konserve mısır', qty: 1, unit: 'kutu', aisle: 4),
    ],
  ),
];

/// Tarif miktarlarını hedef kişi sayısına göre ölçekler (`>= 1000 g → kg`,
/// `>= 1000 ml → lt` dönüşümüyle).
List<({String name, String qty, int aisle})> scaleShopRecipe(
  ShopRecipe recipe,
  int servings,
) {
  final factor =
      servings / (recipe.baseServings <= 0 ? 4 : recipe.baseServings);
  return [
    for (final ing in recipe.ingredients)
      () {
        var scaled = ing.qty * factor;
        var unit = ing.unit;
        final u = quickAscii(unit);
        if ((u == 'g' || u == 'gr' || u == 'gram') && scaled >= 1000) {
          scaled = scaled / 1000;
          unit = 'kg';
        } else if (u == 'ml' && scaled >= 1000) {
          scaled = scaled / 1000;
          unit = 'lt';
        } else if (u == 'adet' ||
            u.isEmpty ||
            u == 'paket' ||
            u == 'kutu' ||
            u == 'kavanoz' ||
            u == 'demet' ||
            u == 'şişe') {
          scaled = scaled.ceilToDouble();
        }
        return (
          name: ing.name,
          qty: formatShopQty(scaled, unit),
          aisle: ing.aisle,
        );
      }(),
  ];
}

/// Seçilen tarif malzemelerini mevcut listeye birim dönüştürerek ekler:
/// aynı madde varsa miktarları `combineQuickQuantities` ile toplar (işaretliyse
/// yeniden açar), yoksa reyon sırasına göre yerleştirir.
List<NoteItem> mergeRecipeIntoItems(
  List<NoteItem> existing,
  List<({String name, String qty, int aisle})> selected, {
  required String locale,
  Map<String, int> learnedGroups = const {},
  String Function()? newId,
}) {
  if (selected.isEmpty) return existing;
  final genId = newId ?? () => const Uuid().v4();
  final out = List<NoteItem>.of(existing);
  final toInsert = <NoteItem>[];

  for (final ing in selected) {
    final key = quickItemKey(ing.name);
    final idx = out.indexWhere((i) => !i.header && quickItemKey(i.text) == key);
    if (idx >= 0) {
      final cur = out[idx];
      final oldMeta = ShopItemMeta.fromItem(cur);
      final oldQty = quickQtyOf(cur.text);
      final nextQty = cur.checked
          ? ing.qty
          : (oldQty.isEmpty
                ? ing.qty
                : (ing.qty.isEmpty
                      ? oldQty
                      : combineQuickQuantities(oldQty, ing.qty)));
      final parsed = parseQuickQty(nextQty);
      out[idx] = oldMeta
          .copyWith(
            qty: parsed?.value,
            clearQty: parsed == null,
            unit: parsed?.rawUnit ?? '',
            status: ShopItemStatus.todo,
            aisle: oldMeta.aisle ?? ing.aisle,
          )
          .applyToItem(
            cur.copyWith(text: quickCompose(quickBaseName(cur.text), nextQty)),
          );
    } else {
      final parsed = parseQuickQty(ing.qty);
      final item =
          ShopItemMeta(
            qty: parsed?.value,
            unit: parsed?.rawUnit ?? '',
            aisle: ing.aisle,
          ).applyToItem(
            NoteItem(id: genId(), text: quickCompose(ing.name, ing.qty)),
          );
      toInsert.add(item);
    }
  }

  return insertItemsBySmartGroup(
    out,
    toInsert,
    kind: SmartListKind.shopping,
    locale: locale,
    learnedGroups: learnedGroups,
  );
}
