import 'package:cloud_firestore/cloud_firestore.dart';

import 'day_key.dart';
import 'recurrence.dart';

/// Bir kaydın Google'daki karşılığı (Takvim etkinliği ya da Görev).
/// [container] takvim kimliği / görev listesi kimliği; [id] Google kimliği.
class GoogleLink {
  const GoogleLink({
    required this.container,
    required this.id,
    this.etag = '',
    this.updated,
  });

  final String container;
  final String id;
  final String etag;

  /// Google tarafındaki son değişiklik (iki yönlü eşlemede "kim yeni").
  final DateTime? updated;

  static GoogleLink? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'] as String? ?? '';
    if (id.isEmpty) return null;
    return GoogleLink(
      container: raw['container'] as String? ?? '',
      id: id,
      etag: raw['etag'] as String? ?? '',
      updated: (raw['updated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'container': container,
    'id': id,
    'etag': etag,
    if (updated != null) 'updated': Timestamp.fromDate(updated!),
  };
}

/// **ETKİNLİK** — `users/{uid}/events/{id}` (TAKVIM_PLANI §3, K2: kendi
/// etkinliklerim Firestore'da; Google'dakiler yalnız gösterilir).
///
/// Saatli etkinlik `start`/`end` zaman damgası; TÜM GÜN etkinliği
/// `startDay`/`endDay` dizesi (bitiş HARİÇ, Google gibi: tek günlük etkinlik
/// `2026-11-06` → `2026-11-07`). Bellekte ikisi de yerel [DateTime].
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.start,
    required this.end,
    this.title = '',
    this.description = '',
    this.location = '',
    this.allDay = false,
    this.repeat = '',
    this.exdates = const [],
    this.reminders = const [],
    this.color,
    this.noteIds = const [],
    this.google,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.extras = const {},
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final bool allDay;

  /// İlk oluşun başı / sonu (tüm günde gece yarıları, son HARİÇ).
  final DateTime start;
  final DateTime end;

  /// [Recurrence] dizesi; '' = tek seferlik.
  final String repeat;

  /// Tekrardan çıkarılan günler (`YYYY-MM-DD`).
  final List<String> exdates;

  /// Başlangıçtan kaç DAKİKA önce hatırlatılsın (tüm günde gün başından,
  /// 09:00 sayılır — bkz. [reminderBase]).
  final List<int> reminders;

  /// ARGB; null = varsayılan (tema rengi).
  final int? color;

  /// Bağlı notlar (plan §4).
  final List<String> noteIds;

  /// Google'a yazılmışsa karşılığı (Faz 51).
  final GoogleLink? google;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic> extras;

  static const knownKeys = <String>{
    'title',
    'description',
    'location',
    'allDay',
    'start',
    'end',
    'startDay',
    'endDay',
    'startKey',
    'repeat',
    'exdates',
    'reminders',
    'color',
    'noteIds',
    'google',
    'createdAt',
    'updatedAt',
    'deletedAt',
  };

  /// Tüm gün etkinliğinde hatırlatmanın saydığı saat.
  static const allDayReminderHour = 9;

  Duration get duration => end.difference(start);
  /// Google Takvim'den GÖSTERİLEN etkinlik (Faz 48): bizde salt okunur —
  /// sürüklenmez, düzenlenmez, yedeğe girmez. Kimliği `g:<takvim>/<id>`.
  bool get fromGoogle => id.startsWith('g:');

  Recurrence get recurrence => Recurrence.parse(repeat);
  bool get repeats => !recurrence.isNone;

  /// Hatırlatma dakikalarının çıkarıldığı an (oluş başına).
  DateTime reminderBase(DateTime occurrenceStart) => allDay
      ? DateTime(
          occurrenceStart.year,
          occurrenceStart.month,
          occurrenceStart.day,
          allDayReminderHour,
        )
      : occurrenceStart;

  /// `[from, to)` ile KESİŞEN oluşların başlangıçları (çok günlü etkinlik
  /// aralıktan önce başlasa da görünür).
  List<DateTime> occurrencesBetween(DateTime from, DateTime to) {
    // Başı `from − süre`den SONRA olan oluşun sonu `from`u geçer.
    final lower = duration > Duration.zero
        ? from.subtract(duration).add(const Duration(microseconds: 1))
        : from;
    return recurrence.between(start, lower, to, exdates: exdates.toSet());
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    bool? allDay,
    DateTime? start,
    DateTime? end,
    String? repeat,
    List<String>? exdates,
    List<int>? reminders,
    int? color,
    bool clearColor = false,
    List<String>? noteIds,
    GoogleLink? google,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => CalendarEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    location: location ?? this.location,
    allDay: allDay ?? this.allDay,
    start: start ?? this.start,
    end: end ?? this.end,
    repeat: repeat ?? this.repeat,
    exdates: exdates ?? this.exdates,
    reminders: reminders ?? this.reminders,
    color: clearColor ? null : (color ?? this.color),
    noteIds: noteIds ?? this.noteIds,
    google: google ?? this.google,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    extras: extras,
  );

  factory CalendarEvent.fromMap(String id, Map<String, dynamic> map) {
    final allDay = map['allDay'] == true;
    DateTime? ts(String k) => (map[k] as Timestamp?)?.toDate();
    late DateTime start;
    late DateTime end;
    if (allDay) {
      start =
          parseDayKey(map['startDay'] as String?) ??
          ts('start') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      end =
          parseDayKey(map['endDay'] as String?) ??
          DateTime(start.year, start.month, start.day + 1);
    } else {
      start = ts('start') ?? DateTime.fromMillisecondsSinceEpoch(0);
      end = ts('end') ?? start.add(const Duration(hours: 1));
    }
    if (!end.isAfter(start) && allDay) {
      end = DateTime(start.year, start.month, start.day + 1);
    }
    return CalendarEvent(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      allDay: allDay,
      start: start,
      end: end,
      repeat: map['repeat'] as String? ?? '',
      exdates: [
        for (final e in map['exdates'] as List? ?? const [])
          if (e is String) e,
      ],
      reminders: [
        for (final r in map['reminders'] as List? ?? const [])
          if (r is num && r >= 0) r.toInt(),
      ],
      color: (map['color'] as num?)?.toInt(),
      noteIds: [
        for (final n in map['noteIds'] as List? ?? const [])
          if (n is String && n.isNotEmpty) n,
      ],
      google: GoogleLink.fromMap(map['google']),
      createdAt: ts('createdAt'),
      updatedAt: ts('updatedAt'),
      deletedAt: ts('deletedAt'),
      extras: unknownKeys(map, knownKeys),
    );
  }

  Map<String, dynamic> toMap() => {
    ...extras,
    'title': title,
    'description': description,
    'location': location,
    'allDay': allDay,
    if (allDay) ...{
      'startDay': dayKey(start),
      'endDay': dayKey(end),
    } else ...{
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
    },
    // Sıralama/aralık sorgusu için ilk günün anahtarı (her iki türde).
    'startKey': dayKey(start),
    'repeat': repeat,
    'exdates': exdates,
    'reminders': reminders,
    'color': color,
    'noteIds': noteIds,
    if (google != null) 'google': google!.toMap(),
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
  };
}
