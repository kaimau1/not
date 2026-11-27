import 'package:flutter/foundation.dart';

import '../../notes/domain/note_item.dart';
import '../../notes/domain/quick_entry.dart';

/// `YYYY-MM-DD` tarih anahtarı (yerel saat).
String isoDayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? parseIsoDayKey(String key) {
  final p = key.split('-');
  if (p.length != 3) return null;
  final y = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

void _setOrRemove(Map<String, dynamic> map, String key, Object? value) {
  if (value == null ||
      (value is String && value.isEmpty) ||
      (value is List && value.isEmpty) ||
      (value is bool && !value)) {
    map.remove(key);
  } else {
    map[key] = value;
  }
}

// ── 1. Alışkanlık takibi ──────────────────────────────────────────────────

@immutable
class HabitItemMeta {
  const HabitItemMeta({
    this.doneDays = const [],
    this.weeklyTarget = 7,
    this.timeOfDay = '',
    this.category = '',
  });

  static const keyDays = 'hd';
  static const keyFreq = 'hf';
  static const keyTime = 'ht';
  static const keyCategory = 'hc';
  static const maxDays = 90;

  /// Sıralı, tekrarsız `YYYY-MM-DD` günleri (en çok [maxDays]).
  final List<String> doneDays;

  /// Haftalık hedef gün sayısı (`1..7`, varsayılan `7`).
  final int weeklyTarget;

  /// `'morning'` | `'afternoon'` | `'evening'` | `''`.
  final String timeOfDay;
  final String category;

  factory HabitItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final rawDays = ex[keyDays];
    final days = <String>{
      if (rawDays is List)
        for (final d in rawDays)
          if (d is String && d.isNotEmpty) d,
    }.toList()..sort();
    final rawF = (ex[keyFreq] as num?)?.toInt() ?? 7;
    return HabitItemMeta(
      doneDays: days.length > maxDays
          ? days.sublist(days.length - maxDays)
          : days,
      weeklyTarget: rawF.clamp(1, 7),
      timeOfDay: (ex[keyTime] as String? ?? '').trim(),
      category: (ex[keyCategory] as String? ?? '').trim(),
    );
  }

  HabitItemMeta copyWith({
    List<String>? doneDays,
    int? weeklyTarget,
    String? timeOfDay,
    String? category,
  }) => HabitItemMeta(
    doneDays: doneDays ?? this.doneDays,
    weeklyTarget: weeklyTarget ?? this.weeklyTarget,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    category: category ?? this.category,
  );

  bool isDoneOn(String dayKey) => doneDays.contains(dayKey);

  HabitItemMeta toggledOn(String dayKey) {
    final next = {...doneDays};
    if (!next.add(dayKey)) next.remove(dayKey);
    final sorted = next.toList()..sort();
    return copyWith(
      doneDays: sorted.length > maxDays
          ? sorted.sublist(sorted.length - maxDays)
          : sorted,
    );
  }

  /// [today] dahil ya da dünden başlayarak ardışık gün serisi.
  int currentStreak(DateTime today) {
    final set = doneDays.toSet();
    final t = DateTime(today.year, today.month, today.day);
    var cursor = set.contains(isoDayKey(t))
        ? t
        : t.subtract(const Duration(days: 1));
    var streak = 0;
    while (set.contains(isoDayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int bestStreak() {
    if (doneDays.isEmpty) return 0;
    var best = 1;
    var cur = 1;
    DateTime? prev;
    for (final s in doneDays) {
      final d = parseIsoDayKey(s);
      if (d == null) continue;
      if (prev != null && d.difference(prev).inDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
      prev = d;
    }
    return best;
  }

  int weekDoneCount(DateTime monday) {
    final set = doneDays.toSet();
    var count = 0;
    for (var i = 0; i < 7; i++) {
      if (set.contains(isoDayKey(monday.add(Duration(days: i))))) count++;
    }
    return count;
  }

  List<bool> last30Days(DateTime today) {
    final set = doneDays.toSet();
    final t = DateTime(today.year, today.month, today.day);
    return [
      for (var i = 29; i >= 0; i--)
        set.contains(isoDayKey(t.subtract(Duration(days: i)))),
    ];
  }

  NoteItem applyToItem(NoteItem item, {String? todayKey}) {
    final next = Map<String, dynamic>.from(item.extras);
    final sorted = doneDays.toSet().toList()..sort();
    final capped = sorted.length > maxDays
        ? sorted.sublist(sorted.length - maxDays)
        : sorted;
    _setOrRemove(next, keyDays, capped);
    _setOrRemove(next, keyFreq, weeklyTarget == 7 ? null : weeklyTarget);
    _setOrRemove(next, keyTime, timeOfDay.trim());
    _setOrRemove(next, keyCategory, category.trim());
    final checked = todayKey != null ? capped.contains(todayKey) : item.checked;
    return item.copyWith(checked: checked, extras: next);
  }
}

// ── 2. Taşınma planı ──────────────────────────────────────────────────────

@immutable
class MovingItemMeta {
  const MovingItemMeta({
    this.phase = 'week',
    this.room = 'general',
    this.box = '',
    this.fragile = false,
    this.openFirst = false,
  });

  static const keyPhase = 'mp';
  static const keyRoom = 'mr';
  static const keyBox = 'mb';
  static const keyFragile = 'mf';
  static const keyOpenFirst = 'mu';

  static const phases = ['month', 'week', 'day', 'new_home'];
  static const rooms = [
    'kitchen',
    'living',
    'bedroom',
    'bath',
    'study',
    'general',
  ];

  /// `'month'` | `'week'` | `'day'` | `'new_home'`.
  final String phase;

  /// `'kitchen'` | `'living'` | `'bedroom'` | `'bath'` | `'study'` | `'general'`.
  final String room;
  final String box;
  final bool fragile;
  final bool openFirst;

  factory MovingItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final phase = (ex[keyPhase] as String? ?? 'week').trim();
    final room = (ex[keyRoom] as String? ?? 'general').trim();
    return MovingItemMeta(
      phase: phases.contains(phase) ? phase : 'week',
      room: rooms.contains(room) ? room : 'general',
      box: (ex[keyBox] as String? ?? '').trim(),
      fragile: ex[keyFragile] == true,
      openFirst: ex[keyOpenFirst] == true,
    );
  }

  MovingItemMeta copyWith({
    String? phase,
    String? room,
    String? box,
    bool? fragile,
    bool? openFirst,
  }) => MovingItemMeta(
    phase: phase ?? this.phase,
    room: room ?? this.room,
    box: box ?? this.box,
    fragile: fragile ?? this.fragile,
    openFirst: openFirst ?? this.openFirst,
  );

  NoteItem applyToItem(NoteItem item) {
    final next = Map<String, dynamic>.from(item.extras);
    _setOrRemove(next, keyPhase, phase == 'week' ? null : phase);
    _setOrRemove(next, keyRoom, room == 'general' ? null : room);
    _setOrRemove(next, keyBox, box.trim());
    _setOrRemove(next, keyFragile, fragile);
    _setOrRemove(next, keyOpenFirst, openFirst);
    return item.copyWith(extras: next);
  }
}

// ── 3. Bavul / Seyahat ────────────────────────────────────────────────────

@immutable
class PackingItemMeta {
  const PackingItemMeta({this.bag = 'checked', this.qty});

  static const keyBag = 'pb';
  static const keyQty = 'q';
  static const bags = ['checked', 'cabin', 'wear'];

  /// `'checked'` (valiz) | `'cabin'` (el bagajı) | `'wear'` (üstümde).
  final String bag;
  final double? qty;

  factory PackingItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final parsed = parseQuickQty(quickQtyOf(item.text));
    final rawQ = ex[keyQty];
    final bag = (ex[keyBag] as String? ?? 'checked').trim();
    return PackingItemMeta(
      bag: bags.contains(bag) ? bag : 'checked',
      qty: rawQ is num ? rawQ.toDouble() : parsed?.value,
    );
  }

  PackingItemMeta copyWith({String? bag, double? qty, bool clearQty = false}) =>
      PackingItemMeta(
        bag: bag ?? this.bag,
        qty: clearQty ? null : (qty ?? this.qty),
      );

  NoteItem applyToItem(NoteItem item, {bool syncTextQty = false}) {
    final next = Map<String, dynamic>.from(item.extras);
    _setOrRemove(next, keyBag, bag == 'checked' ? null : bag);
    _setOrRemove(next, keyQty, qty != null && qty! > 1 ? qty : null);
    var nextText = item.text;
    if (syncTextQty) {
      final base = quickBaseName(item.text);
      final q = qty;
      nextText = q != null && q > 1
          ? quickCompose(base, formatQuickNumber(q))
          : base;
    }
    return item.copyWith(text: nextText, extras: next);
  }
}

// ── 4. Antrenman programı ─────────────────────────────────────────────────

@immutable
class WorkoutItemMeta {
  const WorkoutItemMeta({
    this.sets = 3,
    this.reps = '12',
    this.weight = '',
    this.doneSets = 0,
    this.zone = 'upper',
  });

  static const keySets = 'ws';
  static const keyReps = 'wr';
  static const keyWeight = 'ww';
  static const keyDoneSets = 'wd';
  static const keyZone = 'wg';

  static const zones = [
    'warmup',
    'upper',
    'lower',
    'core',
    'cardio',
    'stretch',
  ];

  final int sets;
  final String reps;
  final String weight;
  final int doneSets;
  final String zone;

  factory WorkoutItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final sets = ((ex[keySets] as num?)?.toInt() ?? 3).clamp(1, 10);
    final rawDone =
        (ex[keyDoneSets] as num?)?.toInt() ?? (item.checked ? sets : 0);
    final zone = (ex[keyZone] as String? ?? 'upper').trim();
    return WorkoutItemMeta(
      sets: sets,
      reps: (ex[keyReps] as String? ?? '12').trim(),
      weight: (ex[keyWeight] as String? ?? '').trim(),
      doneSets: rawDone.clamp(0, sets),
      zone: zones.contains(zone) ? zone : 'upper',
    );
  }

  WorkoutItemMeta copyWith({
    int? sets,
    String? reps,
    String? weight,
    int? doneSets,
    String? zone,
  }) => WorkoutItemMeta(
    sets: sets ?? this.sets,
    reps: reps ?? this.reps,
    weight: weight ?? this.weight,
    doneSets: doneSets ?? this.doneSets,
    zone: zone ?? this.zone,
  );

  /// [setIndex] (1-tabanlı): son tamamlanan sete basılırsa geri alır.
  WorkoutItemMeta toggleSet(int setIndex) {
    final target = setIndex.clamp(1, sets);
    final nextDone = doneSets == target ? target - 1 : target;
    return copyWith(doneSets: nextDone);
  }

  NoteItem applyToItem(NoteItem item) {
    final next = Map<String, dynamic>.from(item.extras);
    final clampedDone = doneSets.clamp(0, sets);
    _setOrRemove(next, keySets, sets == 3 ? null : sets);
    _setOrRemove(next, keyReps, reps.trim() == '12' ? null : reps.trim());
    _setOrRemove(next, keyWeight, weight.trim());
    _setOrRemove(next, keyDoneSets, clampedDone == 0 ? null : clampedDone);
    _setOrRemove(next, keyZone, zone == 'upper' ? null : zone);
    return item.copyWith(checked: clampedDone >= sets, extras: next);
  }
}

// ── 5. Ev temizliği ───────────────────────────────────────────────────────

@immutable
class CleaningItemMeta {
  const CleaningItemMeta({this.room = 'general', this.freq = 'weekly'});

  static const keyRoom = 'cr';
  static const keyFreq = 'cf';
  static const rooms = ['kitchen', 'bath', 'living', 'bedroom', 'general'];
  static const freqs = ['daily', 'weekly', 'monthly'];

  final String room;
  final String freq;

  factory CleaningItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final room = (ex[keyRoom] as String? ?? 'general').trim();
    final freq = (ex[keyFreq] as String? ?? 'weekly').trim();
    return CleaningItemMeta(
      room: rooms.contains(room) ? room : 'general',
      freq: freqs.contains(freq) ? freq : 'weekly',
    );
  }

  CleaningItemMeta copyWith({String? room, String? freq}) =>
      CleaningItemMeta(room: room ?? this.room, freq: freq ?? this.freq);

  NoteItem applyToItem(NoteItem item) {
    final next = Map<String, dynamic>.from(item.extras);
    _setOrRemove(next, keyRoom, room == 'general' ? null : room);
    _setOrRemove(next, keyFreq, freq == 'weekly' ? null : freq);
    return item.copyWith(extras: next);
  }
}

// ── 6. Hediye planlayıcı ──────────────────────────────────────────────────

@immutable
class GiftItemMeta {
  const GiftItemMeta({this.recipient = '', this.price, this.stage = 'idea'});

  static const keyRecipient = 'gr';
  static const keyPrice = 'p';
  static const keyStage = 'gs';
  static const stages = ['idea', 'bought', 'wrapped', 'given'];

  final String recipient;
  final double? price;
  final String stage;

  factory GiftItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final rawStage = (ex[keyStage] as String? ?? '').trim();
    final stage = stages.contains(rawStage)
        ? rawStage
        : (item.checked ? 'bought' : 'idea');
    final rawP = ex[keyPrice];
    return GiftItemMeta(
      recipient: (ex[keyRecipient] as String? ?? '').trim(),
      price: rawP is num ? rawP.toDouble() : null,
      stage: stage,
    );
  }

  GiftItemMeta copyWith({
    String? recipient,
    double? price,
    bool clearPrice = false,
    String? stage,
  }) => GiftItemMeta(
    recipient: recipient ?? this.recipient,
    price: clearPrice ? null : (price ?? this.price),
    stage: stage ?? this.stage,
  );

  GiftItemMeta nextStage() {
    final idx = stages.indexOf(stage);
    final next = stages[(idx + 1) % stages.length];
    return copyWith(stage: next);
  }

  NoteItem applyToItem(NoteItem item) {
    final next = Map<String, dynamic>.from(item.extras);
    _setOrRemove(next, keyRecipient, recipient.trim());
    _setOrRemove(next, keyPrice, price != null && price! > 0 ? price : null);
    _setOrRemove(next, keyStage, stage == 'idea' ? null : stage);
    final done = stage == 'bought' || stage == 'wrapped' || stage == 'given';
    return item.copyWith(checked: done, extras: next);
  }
}

// ── 7. İzlenecek ve okunacaklar ───────────────────────────────────────────

@immutable
class WatchlistItemMeta {
  const WatchlistItemMeta({
    this.mediaType = 'movie',
    this.status = 'queued',
    this.rating = 0,
    this.platform = '',
  });

  static const keyType = 'wt';
  static const keyStatus = 'ws2';
  static const keyRating = 'wr2';
  static const keyPlatform = 'wp';

  static const types = ['movie', 'series', 'book', 'doc', 'podcast'];
  static const statuses = ['queued', 'watching', 'done'];

  final String mediaType;
  final String status;
  final int rating;
  final String platform;

  factory WatchlistItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final t = (ex[keyType] as String? ?? 'movie').trim();
    final rawS = (ex[keyStatus] as String? ?? '').trim();
    final st = statuses.contains(rawS)
        ? rawS
        : (item.checked ? 'done' : 'queued');
    return WatchlistItemMeta(
      mediaType: types.contains(t) ? t : 'movie',
      status: st,
      rating: ((ex[keyRating] as num?)?.toInt() ?? 0).clamp(0, 5),
      platform: (ex[keyPlatform] as String? ?? '').trim(),
    );
  }

  WatchlistItemMeta copyWith({
    String? mediaType,
    String? status,
    int? rating,
    String? platform,
  }) => WatchlistItemMeta(
    mediaType: mediaType ?? this.mediaType,
    status: status ?? this.status,
    rating: rating ?? this.rating,
    platform: platform ?? this.platform,
  );

  NoteItem applyToItem(NoteItem item) {
    final next = Map<String, dynamic>.from(item.extras);
    _setOrRemove(next, keyType, mediaType == 'movie' ? null : mediaType);
    _setOrRemove(next, keyStatus, status == 'queued' ? null : status);
    _setOrRemove(next, keyRating, rating <= 0 ? null : rating.clamp(1, 5));
    _setOrRemove(next, keyPlatform, platform.trim());
    return item.copyWith(checked: status == 'done', extras: next);
  }
}

// ── 8. Bütçe ve harcama ───────────────────────────────────────────────────

@immutable
class ExpenseItemMeta {
  const ExpenseItemMeta({this.amount, this.category = 'other'});

  static const keyAmount = 'p';
  static const keyCategory = 'ec';
  static const categories = [
    'market',
    'bills',
    'transport',
    'food',
    'home',
    'health',
    'fun',
    'other',
  ];

  final double? amount;
  final String category;

  factory ExpenseItemMeta.fromItem(NoteItem item) {
    final ex = item.extras;
    final rawP = ex[keyAmount];
    final cat = (ex[keyCategory] as String? ?? 'other').trim();
    return ExpenseItemMeta(
      amount: rawP is num ? rawP.toDouble() : null,
      category: categories.contains(cat) ? cat : 'other',
    );
  }

  ExpenseItemMeta copyWith({
    double? amount,
    bool clearAmount = false,
    String? category,
  }) => ExpenseItemMeta(
    amount: clearAmount ? null : (amount ?? this.amount),
    category: category ?? this.category,
  );

  NoteItem applyToItem(NoteItem item) {
    final next = Map<String, dynamic>.from(item.extras);
    _setOrRemove(
      next,
      keyAmount,
      amount != null && amount! > 0 ? amount : null,
    );
    _setOrRemove(next, keyCategory, category == 'other' ? null : category);
    return item.copyWith(extras: next);
  }
}

/// `"Elektrik 850"` veya `"Kira 12500 tl"` girdisinden ad + tutar çıkarır.
({String title, double? amount}) parseExpenseQuickInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return (title: '', amount: null);
  final priced = extractInlinePrice(trimmed);
  if (priced.price != null) {
    return (title: quickCapitalize(priced.text), amount: priced.price);
  }
  final m = RegExp(r'^(.+?)\s+(\d+(?:[.,]\d{1,2})?)$').firstMatch(trimmed);
  if (m != null) {
    final v = double.tryParse(m.group(2)!.replaceAll(',', '.'));
    if (v != null && v > 0) {
      return (title: quickCapitalize(m.group(1)!.trim()), amount: v);
    }
  }
  return (title: quickCapitalize(trimmed), amount: null);
}
