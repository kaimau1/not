import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **MENÜ DÜZENİ** (kullanıcı isteği 2026-11-06: "menüleri kişi kendine göre
/// düzenleyebilsin, her menüde kendi düzenle butonu olsun").
///
/// Menü başına (kart ⋮, not ⋮, not "+", ana ekran ⋮…) üç tercih: GİZLENEN
/// işlemler, HIZLI SATIRA alınanlar ve SIRA. Cihaz tercihidir
/// (SharedPreferences, `menu_layout_v1`), senkronlanmaz — `Personalize` gibi.
/// Menünün kendi kataloğu değişirse (yeni işlem) yeni işlem varsayılan
/// yerinde görünür: kayıt yalnız kullanıcının dokunduğu işlemleri taşır.
@immutable
class MenuLayout {
  const MenuLayout({this.hidden = const {}, this.quick, this.order = const []});

  final Set<String> hidden;

  /// Hızlı satırdaki işlemler, sırasıyla; null = menünün varsayılanı.
  final List<String>? quick;

  /// Gruplardaki işlemlerin kullanıcı sırası (listede olmayan sonda,
  /// varsayılan sırasıyla).
  final List<String> order;

  bool get isDefault => hidden.isEmpty && quick == null && order.isEmpty;

  /// Hızlı satıra en çok kaç işlem sığar.
  static const maxQuick = 5;

  Map<String, dynamic> toJson() => {
    if (hidden.isNotEmpty) 'hidden': hidden.toList()..sort(),
    'quick': ?quick,
    if (order.isNotEmpty) 'order': order,
  };

  factory MenuLayout.fromJson(Object? raw) {
    if (raw is! Map) return const MenuLayout();
    List<String> list(Object? v) => [
      for (final x in v is List ? v : const [])
        if (x is String) x,
    ];
    return MenuLayout(
      hidden: list(raw['hidden']).toSet(),
      quick: raw['quick'] is List ? list(raw['quick']) : null,
      order: list(raw['order']),
    );
  }

  /// [ids] varsayılan sıradaki işlemler → kullanıcı sırası.
  List<T> sorted<T>(List<T> items, String Function(T) idOf) {
    if (order.isEmpty) return items;
    final rank = {for (var i = 0; i < order.length; i++) order[i]: i};
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final ra = rank[idOf(a.$2)], rb = rank[idOf(b.$2)];
      if (ra != null && rb != null) return ra.compareTo(rb);
      if (ra != null) return -1;
      if (rb != null) return 1;
      return a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}

abstract final class MenuLayouts {
  static const _key = 'menu_layout_v1';
  static SharedPreferences? _store;

  /// Menü kimliği → düzen.
  static final layouts = ValueNotifier<Map<String, MenuLayout>>(const {});

  static MenuLayout of(String menuId) =>
      layouts.value[menuId] ?? const MenuLayout();

  /// Uygulama açılışında (main) bir kez.
  static void attach(SharedPreferences store) {
    _store = store;
    final raw = store.getString(_key);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      layouts.value = {
        for (final e in j.entries) e.key: MenuLayout.fromJson(e.value),
      };
    } catch (_) {
      // Bozuk kayıt: varsayılan menüler.
    }
  }

  static void set(String menuId, MenuLayout layout) {
    final next = {...layouts.value};
    layout.isDefault ? next.remove(menuId) : next[menuId] = layout;
    layouts.value = next;
    _store?.setString(
      _key,
      jsonEncode({for (final e in next.entries) e.key: e.value.toJson()}),
    );
  }

  @visibleForTesting
  static void reset() {
    layouts.value = const {};
    _store = null;
  }
}
