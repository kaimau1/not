import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../notes/data/quick_entry_memory.dart';
import '../../notes/domain/quick_entry.dart';
import '../domain/shop_aisles.dart';
import 'shop_memory.dart';

/// Barkod (EAN/UPC) ürün çözümleyicisi:
/// 1) Önce yerel [ShopMemory.barcodes] önbelleğine bakar (anında, çevrimdışı).
/// 2) Yoksa ücretsiz Open Food Facts API v2'yi sorgular (4 sn zaman aşımı).
/// 3) Çevrimdışı veya bulunamazsa `null` döner (asla istisna atmaz).
Future<ShopBarcodeProduct?> lookupBarcodeProduct(
  String rawCode, {
  required ShopMemory memory,
  http.Client? client,
}) async {
  final ean = rawCode.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').trim();
  if (ean.length < 4) return null;

  final cached = memory.barcodes[ean];
  if (cached != null) return cached;

  final ownedClient = client == null;
  final httpClient = client ?? http.Client();
  try {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$ean.json',
      {
        'fields':
            'product_name_tr,product_name,brands,quantity,categories_tags',
      },
    );
    final res = await httpClient
        .get(uri, headers: {'User-Agent': 'NotlarApp/1.2'})
        .timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return null;
    if ((decoded['status'] as num?)?.toInt() != 1) return null;
    final p = decoded['product'];
    if (p is! Map) return null;

    final nameTr = '${p['product_name_tr'] ?? ''}'.trim();
    final nameEn = '${p['product_name'] ?? ''}'.trim();
    final name = nameTr.isNotEmpty ? nameTr : nameEn;
    if (name.isEmpty) return null;

    final brandRaw = '${p['brands'] ?? ''}'.split(',').first.trim();
    final qty = '${p['quantity'] ?? ''}'.trim();
    final tags = [
      for (final t in (p['categories_tags'] as List?) ?? const []) '$t',
    ];
    final aisle = _inferAisleFromProduct(name, tags);

    return ShopBarcodeProduct(
      ean: ean,
      name: quickCapitalize(name),
      brand: brandRaw,
      qty: qty,
      aisle: aisle,
    );
  } catch (_) {
    return null;
  } finally {
    if (ownedClient) httpClient.close();
  }
}

int _inferAisleFromProduct(String name, List<String> tags) {
  final lexGroup = groceryLexicon('tr').groupOf(name);
  if (lexGroup >= 0 && lexGroup < kShopAisles.length) return lexGroup;
  final joined = tags.join(' ').toLowerCase();
  if (joined.contains('dairy') ||
      joined.contains('milk') ||
      joined.contains('cheese') ||
      joined.contains('yogurt') ||
      joined.contains('egg')) {
    return 2;
  }
  if (joined.contains('bread') || joined.contains('bakery')) return 1;
  if (joined.contains('fruit') || joined.contains('vegetable')) return 0;
  if (joined.contains('meat') ||
      joined.contains('fish') ||
      joined.contains('poultry')) {
    return 3;
  }
  if (joined.contains('beverage') ||
      joined.contains('drink') ||
      joined.contains('water') ||
      joined.contains('coffee') ||
      joined.contains('tea')) {
    return 5;
  }
  if (joined.contains('snack') ||
      joined.contains('chocolate') ||
      joined.contains('biscuit') ||
      joined.contains('chip')) {
    return 6;
  }
  if (joined.contains('frozen')) return 7;
  if (joined.contains('clean') || joined.contains('detergent')) return 8;
  if (joined.contains('baby') || joined.contains('diaper')) return 11;
  if (joined.contains('pet') ||
      joined.contains('cat') ||
      joined.contains('dog')) {
    return 12;
  }
  if (joined.contains('pasta') ||
      joined.contains('rice') ||
      joined.contains('flour') ||
      joined.contains('oil') ||
      joined.contains('spice')) {
    return 4;
  }
  return kOtherAisleIndex;
}
