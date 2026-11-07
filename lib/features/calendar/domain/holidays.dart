import 'day_key.dart';

/// Tatilin türü: tam gün resmî/dinî tatil, yarım gün (arife) ya da sonradan
/// açıklanan ek gün (uzatma, idari izin).
enum HolidayKind { national, religious, halfDay, extra }

/// Bir günün tatili. [short] dar hücrede (ay ızgarası) görünür.
class Holiday {
  const Holiday({
    required this.name,
    required this.short,
    required this.kind,
    this.estimated = false,
  });

  final String name;
  final String short;
  final HolidayKind kind;

  /// Dinî bayram tarihi henüz kesinleşmedi (Diyanet açıklamadı; ay
  /// takviminden hesap). Uzaktaki liste kesin tarihi yazınca kalkar.
  final bool estimated;

  /// Tam gün tatil mi (arife yarım gün sayılmaz).
  bool get isOff => kind != HolidayKind.halfDay;

  Holiday merge(Holiday o) => Holiday(
    name: '$name · ${o.name}',
    short: short,
    kind: isOff ? kind : o.kind,
    estimated: estimated || o.estimated,
  );

  @override
  bool operator ==(Object other) =>
      other is Holiday &&
      other.name == name &&
      other.short == short &&
      other.kind == kind &&
      other.estimated == estimated;

  @override
  int get hashCode => Object.hash(name, short, kind, estimated);
}

/// Dinî bayramların İLK günleri (Diyanet). `estimated`: henüz açıklanmadı.
///
/// TUZAK: Bu tablo yalnız yedek. Bayram uzatmaları / idari izinler ve kesin
/// tarihler `tool/tatiller.json` → CI (`deploy`) → Firestore
/// `config/holidays` yoluyla APK yeniden derlenmeden gelir
/// ([HolidayOverrides]). Hükümet uzatmayı genelde bayrama birkaç gün kala
/// açıklar; o zaman JSON'a `extra` satırı eklenir.
const Map<int, ({String ramazan, String kurban, bool estimated})>
kReligiousHolidays = {
  2024: (ramazan: '2024-04-10', kurban: '2024-06-16', estimated: false),
  2025: (ramazan: '2025-03-30', kurban: '2025-06-06', estimated: false),
  2026: (ramazan: '2026-03-20', kurban: '2026-05-27', estimated: false),
  2027: (ramazan: '2027-03-09', kurban: '2027-05-16', estimated: false),
  2028: (ramazan: '2028-02-26', kurban: '2028-05-04', estimated: true),
  2029: (ramazan: '2029-02-14', kurban: '2029-04-23', estimated: true),
  2030: (ramazan: '2030-02-04', kurban: '2030-04-13', estimated: true),
  2031: (ramazan: '2031-01-24', kurban: '2031-04-02', estimated: true),
  2032: (ramazan: '2032-01-14', kurban: '2032-03-22', estimated: true),
};

/// Uzaktan gelen düzeltmeler (`config/holidays`):
/// ```json
/// {
///   "religious": {"2028": {"ramazan": "2028-02-26", "kurban": "2028-05-04"}},
///   "extra": {"2026-05-25": "İdari izin"},
///   "removed": ["2026-05-26"]
/// }
/// ```
/// `religious` yazılan yıl KESİN sayılır (tahmini işareti kalkar).
class HolidayOverrides {
  const HolidayOverrides({
    this.religious = const {},
    this.extra = const {},
    this.removed = const {},
  });

  static const none = HolidayOverrides();

  final Map<int, ({String? ramazan, String? kurban})> religious;

  /// Gün anahtarı (`YYYY-MM-DD`) → ad.
  final Map<String, String> extra;
  final Set<String> removed;

  bool get isEmpty => religious.isEmpty && extra.isEmpty && removed.isEmpty;

  /// Bozuk alanlar sessizce atlanır (liste uygulamayı düşürmemeli).
  factory HolidayOverrides.fromMap(Map<String, dynamic>? m) {
    if (m == null) return none;
    final religious = <int, ({String? ramazan, String? kurban})>{};
    final r = m['religious'];
    if (r is Map) {
      r.forEach((k, v) {
        final year = int.tryParse('$k');
        if (year == null || v is! Map) return;
        String? day(Object? s) =>
            s is String && parseDayKey(s) != null ? s : null;
        religious[year] = (
          ramazan: day(v['ramazan']),
          kurban: day(v['kurban']),
        );
      });
    }
    final extra = <String, String>{};
    final e = m['extra'];
    if (e is Map) {
      e.forEach((k, v) {
        if (k is String && parseDayKey(k) != null && v is String) {
          final name = v.trim();
          if (name.isNotEmpty) extra[k] = name;
        }
      });
    }
    final removed = <String>{};
    final x = m['removed'];
    if (x is List) {
      for (final k in x) {
        if (k is String && parseDayKey(k) != null) removed.add(k);
      }
    }
    return HolidayOverrides(
      religious: religious,
      extra: extra,
      removed: removed,
    );
  }
}

/// Türkiye'nin resmî ve dinî tatilleri. Yıl başına bir kez hesaplanır,
/// bellekte tutulur (hücre başına hesap YOK).
class HolidayCalendar {
  HolidayCalendar([this.overrides = HolidayOverrides.none])
    : enabled = true,
      _cache = {};

  /// Tatil gösterilmez (ayar kapalı / test).
  const HolidayCalendar.off()
    : enabled = false,
      overrides = HolidayOverrides.none,
      _cache = const {};

  final bool enabled;
  final HolidayOverrides overrides;
  final Map<int, Map<String, Holiday>> _cache;

  Holiday? on(DateTime day) {
    if (!enabled) return null;
    return year(day.year)[dayKey(day)];
  }

  Map<String, Holiday> year(int y) {
    if (!enabled) return const {};
    return _cache[y] ??= buildHolidays(y, overrides);
  }
}

String _key(int y, int m, int d) => dayKey(DateTime(y, m, d));

/// [year] yılının tatilleri (gün anahtarı → tatil). Saf; test edilir.
Map<String, Holiday> buildHolidays(
  int year, [
  HolidayOverrides overrides = HolidayOverrides.none,
]) {
  final out = <String, Holiday>{};
  void add(String key, Holiday h) {
    final prev = out[key];
    out[key] = prev == null ? h : prev.merge(h);
  }

  void fixed(int m, int d, String name, String short, {bool half = false}) =>
      add(
        _key(year, m, d),
        Holiday(
          name: name,
          short: short,
          kind: half ? HolidayKind.halfDay : HolidayKind.national,
        ),
      );

  fixed(1, 1, 'Yılbaşı', 'Yılbaşı');
  fixed(4, 23, 'Ulusal Egemenlik ve Çocuk Bayramı', '23 Nisan');
  fixed(5, 1, 'Emek ve Dayanışma Günü', '1 Mayıs');
  fixed(5, 19, 'Atatürk\'ü Anma, Gençlik ve Spor Bayramı', '19 Mayıs');
  if (year >= 2017) {
    fixed(7, 15, 'Demokrasi ve Millî Birlik Günü', '15 Temmuz');
  }
  fixed(8, 30, 'Zafer Bayramı', 'Zafer Bayramı');
  fixed(10, 28, 'Cumhuriyet Bayramı Arifesi (yarım gün)', 'Arife', half: true);
  // Kısa ad dar hücrede sözcük ortasından bölünmesin ('Cumhuriy-et').
  fixed(10, 29, 'Cumhuriyet Bayramı', '29 Ekim Bayramı');

  final base = kReligiousHolidays[year];
  final fix = overrides.religious[year];
  void feast(String? first, int days, String name, bool estimated) {
    final start = first == null ? null : parseDayKey(first);
    if (start == null) return;
    final arife = DateTime(start.year, start.month, start.day - 1);
    add(
      dayKey(arife),
      Holiday(
        name: '$name Arifesi (yarım gün)',
        short: 'Arife',
        kind: HolidayKind.halfDay,
        estimated: estimated,
      ),
    );
    for (var i = 0; i < days; i++) {
      add(
        dayKey(DateTime(start.year, start.month, start.day + i)),
        Holiday(
          name: '$name ${i + 1}. gün',
          short: name,
          kind: HolidayKind.religious,
          estimated: estimated,
        ),
      );
    }
  }

  feast(
    fix?.ramazan ?? base?.ramazan,
    3,
    'Ramazan Bayramı',
    fix?.ramazan == null && (base?.estimated ?? false),
  );
  feast(
    fix?.kurban ?? base?.kurban,
    4,
    'Kurban Bayramı',
    fix?.kurban == null && (base?.estimated ?? false),
  );

  for (final k in overrides.removed) {
    out.remove(k);
  }
  overrides.extra.forEach((k, name) {
    if (!k.startsWith('$year-')) return;
    add(k, Holiday(name: name, short: name, kind: HolidayKind.extra));
  });
  return out;
}
