import 'package:flutter/material.dart';

import '../../notes/data/quick_entry_memory.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';
import '../../notes/domain/quick_lexicon_data.dart';
import 'shop_item_meta.dart';

/// Görsel reyon meta verisi (ikon, renk, Türkçe/İngilizce ad).
@immutable
class ShopAisleMeta {
  const ShopAisleMeta({
    required this.index,
    required this.key,
    required this.nameTr,
    required this.nameEn,
    required this.icon,
    required this.color,
  });

  final int index;
  final String key;
  final String nameTr;
  final String nameEn;
  final IconData icon;
  final Color color;

  String label({required bool isTr}) => isTr ? nameTr : nameEn;
}

const kOtherAisleIndex = -1;

const kOtherAisleMeta = ShopAisleMeta(
  index: kOtherAisleIndex,
  key: 'other',
  nameTr: 'Diğer',
  nameEn: 'Other',
  icon: Icons.category_outlined,
  color: Color(0xFF64748B),
);

/// 13 market reyonunun varsayılan sırası, renkleri ve ikonları.
const List<ShopAisleMeta> kShopAisles = [
  ShopAisleMeta(
    index: 0,
    key: 'produce',
    nameTr: 'Manav',
    nameEn: 'Produce',
    icon: Icons.eco_outlined,
    color: Color(0xFF2E7D32),
  ),
  ShopAisleMeta(
    index: 1,
    key: 'bakery',
    nameTr: 'Fırın & Unlu',
    nameEn: 'Bakery',
    icon: Icons.bakery_dining_outlined,
    color: Color(0xFFD97706),
  ),
  ShopAisleMeta(
    index: 2,
    key: 'breakfast',
    nameTr: 'Süt & Kahvaltılık',
    nameEn: 'Dairy & Breakfast',
    icon: Icons.egg_alt_outlined,
    color: Color(0xFF0284C7),
  ),
  ShopAisleMeta(
    index: 3,
    key: 'meat',
    nameTr: 'Kasap & Balık',
    nameEn: 'Meat & Fish',
    icon: Icons.set_meal_outlined,
    color: Color(0xFFC62828),
  ),
  ShopAisleMeta(
    index: 4,
    key: 'pantry',
    nameTr: 'Bakliyat & Kiler',
    nameEn: 'Pantry',
    icon: Icons.kitchen_outlined,
    color: Color(0xFF8D6E63),
  ),
  ShopAisleMeta(
    index: 5,
    key: 'drinks',
    nameTr: 'İçecek',
    nameEn: 'Drinks',
    icon: Icons.local_cafe_outlined,
    color: Color(0xFF00897B),
  ),
  ShopAisleMeta(
    index: 6,
    key: 'snacks',
    nameTr: 'Atıştırmalık',
    nameEn: 'Snacks',
    icon: Icons.cookie_outlined,
    color: Color(0xFFE65100),
  ),
  ShopAisleMeta(
    index: 7,
    key: 'frozen',
    nameTr: 'Dondurulmuş',
    nameEn: 'Frozen',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF1565C0),
  ),
  ShopAisleMeta(
    index: 8,
    key: 'cleaning',
    nameTr: 'Temizlik',
    nameEn: 'Cleaning',
    icon: Icons.cleaning_services_outlined,
    color: Color(0xFF00ACC1),
  ),
  ShopAisleMeta(
    index: 9,
    key: 'home',
    nameTr: 'Ev & Gereç',
    nameEn: 'Home',
    icon: Icons.home_repair_service_outlined,
    color: Color(0xFF5E35B1),
  ),
  ShopAisleMeta(
    index: 10,
    key: 'personal',
    nameTr: 'Kişisel Bakım',
    nameEn: 'Personal Care',
    icon: Icons.spa_outlined,
    color: Color(0xFFAD1457),
  ),
  ShopAisleMeta(
    index: 11,
    key: 'baby',
    nameTr: 'Bebek',
    nameEn: 'Baby',
    icon: Icons.child_care_outlined,
    color: Color(0xFFEC407A),
  ),
  ShopAisleMeta(
    index: 12,
    key: 'pet',
    nameTr: 'Evcil Hayvan',
    nameEn: 'Pet',
    icon: Icons.pets_outlined,
    color: Color(0xFF6D4C41),
  ),
];

ShopAisleMeta shopAisleMetaOfIndex(int index) {
  if (index >= 0 && index < kShopAisles.length) return kShopAisles[index];
  return kOtherAisleMeta;
}

ShopAisleMeta shopAisleMetaOf(QuickAisle aisle) => kShopAisles[aisle.index];

/// Yaygın Türkiye market profilleri (`NoteItem.extras['s']` anahtarları).
@immutable
class ShopStoreProfile {
  const ShopStoreProfile({required this.id, required this.label});

  final String id;
  final String label;
}

const List<ShopStoreProfile> kDefaultShopStores = [
  ShopStoreProfile(id: 'bim', label: 'BİM'),
  ShopStoreProfile(id: 'a101', label: 'A101'),
  ShopStoreProfile(id: 'sok', label: 'ŞOK'),
  ShopStoreProfile(id: 'migros', label: 'Migros'),
  ShopStoreProfile(id: 'carrefour', label: 'CarrefourSA'),
  ShopStoreProfile(id: 'pazar', label: 'Pazar'),
  ShopStoreProfile(id: 'kasap', label: 'Kasap/Manav'),
];

String shopStoreLabel(String id) {
  for (final s in kDefaultShopStores) {
    if (s.id == id) return s.label;
  }
  return id.toUpperCase();
}

/// Ürünün reyonunu çözer: önce maddedeki açık atama (`extras.g`), yoksa
/// kullanıcının öğrettiği (`itemGroups`), yoksa sözlük, yoksa `-1`.
int resolveItemAisle(
  NoteItem item, {
  required String locale,
  Map<String, int> learnedGroups = const {},
}) {
  final meta = ShopItemMeta.fromItem(item);
  if (meta.aisle != null &&
      meta.aisle! >= 0 &&
      meta.aisle! < kShopAisles.length) {
    return meta.aisle!;
  }
  final key = quickItemKey(item.text);
  final learned = learnedGroups[key];
  if (learned != null && learned >= 0 && learned < kShopAisles.length) {
    return learned;
  }
  final lexGroup = groceryLexicon(locale).groupOf(item.text);
  if (lexGroup >= 0 && lexGroup < kShopAisles.length) return lexGroup;
  return kOtherAisleIndex;
}
