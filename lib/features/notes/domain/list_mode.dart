import 'quick_lexicon_data.dart';

/// Liste notunun davranış kipi.
///
/// Eski notlarda bu alan kayıtlı değildir; `Note.fromMap` eski `listKind`
/// değerinden ([listModeFromLegacyKind]) geriye dönük türetir.
enum ListMode {
  general('general'),
  shopping('shopping'),
  routine('routine'),
  template('template'),
  project('project');

  const ListMode(this.id);

  final String id;

  static ListMode fromId(String? id) {
    if (id == null || id.isEmpty) return ListMode.general;
    for (final m in ListMode.values) {
      if (m.id == id) return m;
    }
    return ListMode.general;
  }
}

/// Rutin / alışkanlık listelerinin otomatik sıfırlama takvimi.
enum ResetSchedule {
  none('none'),
  daily('daily'),
  weekly('weekly'),
  customDays('customDays');

  const ResetSchedule(this.id);

  final String id;

  static ResetSchedule fromId(String? id) {
    if (id == null || id.isEmpty) return ResetSchedule.none;
    for (final r in ResetSchedule.values) {
      if (r.id == id) return r;
    }
    return ResetSchedule.none;
  }
}

/// Listenin öne çıkacağı gün içi bağlam dilimi.
enum ContextTimeSlot {
  any('any'),
  morning('morning'),
  evening('evening'),
  weekend('weekend');

  const ContextTimeSlot(this.id);

  final String id;

  static ContextTimeSlot fromId(String? id) {
    if (id == null || id.isEmpty) return ContextTimeSlot.any;
    for (final c in ContextTimeSlot.values) {
      if (c.id == id) return c;
    }
    return ContextTimeSlot.any;
  }
}

/// Madde öncelik düzeyi (özellikle Proje / Odak kipinde ve Hızlı Ekle'de).
enum ItemPriority {
  none('none', 0),
  low('low', 1),
  medium('medium', 2),
  high('high', 3),
  urgent('urgent', 4);

  const ItemPriority(this.id, this.weight);

  final String id;
  final int weight;

  bool get isSet => this != ItemPriority.none;

  ItemPriority next() => switch (this) {
    ItemPriority.none => ItemPriority.medium,
    ItemPriority.low => ItemPriority.medium,
    ItemPriority.medium => ItemPriority.high,
    ItemPriority.high => ItemPriority.urgent,
    ItemPriority.urgent => ItemPriority.none,
  };

  static ItemPriority fromId(String? id) {
    if (id == null || id.isEmpty) return ItemPriority.none;
    for (final p in ItemPriority.values) {
      if (p.id == id) return p;
    }
    return ItemPriority.none;
  }
}

/// Eski `Note.listKind` değerinden varsayılan [ListMode] türetir.
ListMode listModeFromLegacyKind(String? listKind) => switch (listKind) {
  'shopping' => ListMode.shopping,
  'habits' || 'cleaning' || 'workout' => ListMode.routine,
  'packing' || 'camping' || 'sport' || 'baby' => ListMode.template,
  'moving' || 'event' => ListMode.project,
  _ => ListMode.general,
};

/// Eski `Note.listKind` değerinden varsayılan [ResetSchedule] türetir.
ResetSchedule defaultResetScheduleForLegacyKind(String? listKind) =>
    switch (listKind) {
      'habits' => ResetSchedule.daily,
      'cleaning' || 'workout' => ResetSchedule.weekly,
      _ => ResetSchedule.none,
    };

/// Market reyon sıra numarası (`0..12`) → kanonik kategori anahtarı.
String? aisleCategoryKey(int? index) {
  if (index == null || index < 0 || index >= QuickAisle.values.length) {
    return null;
  }
  return QuickAisle.values[index].name;
}

/// Kanonik kategori anahtarı → market reyon sıra numarası (`0..12`), yoksa null.
int? aisleIndexFromCategory(String category) {
  final c = category.trim().toLowerCase();
  if (c.isEmpty) return null;
  for (final aisle in QuickAisle.values) {
    if (aisle.name == c) return aisle.index;
  }
  final parsed = int.tryParse(c);
  if (parsed != null && parsed >= 0 && parsed < QuickAisle.values.length) {
    return parsed;
  }
  return null;
}

/// Yerel tarih için `YYYY-MM-DD` anahtarı.
String isoDayKeyOf(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// `YYYY-MM-DD` anahtarını yerel gece yarısı [DateTime]'a çevirir.
DateTime? parseIsoDayKeyLocal(String key) {
  final p = key.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}
