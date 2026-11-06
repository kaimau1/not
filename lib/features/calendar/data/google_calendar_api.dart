import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/google_scope_auth.dart' show ScopeTokenCache;
import '../domain/calendar_event.dart';
import '../domain/day_key.dart';

/// **GOOGLE TAKVİM — YALNIZ OKUMA** (TAKVIM_PLANI Faz 48).
///
/// Kapsam `calendar.readonly` Gmail ve Drive'dan AYRI istenir (§5). Bu
/// istemci yalnız GET yapar (`google_calendar_test` doğrular); yazma Faz 51.
/// Tekrarları Google açar (`singleEvents=true`, K3) — RRULE çözmek bize
/// düşmez. Konsol adımı: Calendar API etkin + onay ekranına kapsam (F19).
const kCalendarReadonlyScope =
    'https://www.googleapis.com/auth/calendar.readonly';

const _api = 'https://www.googleapis.com/calendar/v3';

/// Google etkinliğinin bizdeki kimlik öneki: yerel etkinliklerle çakışmasın,
/// sürüklenmesin/düzenlenmesin ([CalendarEvent.isGoogle]).
const kGoogleEventPrefix = 'g:';

class GoogleCalendarException implements Exception {
  GoogleCalendarException(this.status, this.body);
  final int status;
  final String body;
  bool get unauthorized => status == 401 || status == 403;

  /// `syncToken` geçersiz: tam çekiş gerekir.
  bool get gone => status == 410;
  @override
  String toString() => 'GoogleCalendarException($status)';
}

/// Kullanıcının takvim listesindeki bir takvim.
class GoogleCalendarInfo {
  const GoogleCalendarInfo({
    required this.id,
    required this.summary,
    this.color,
    this.primary = false,
    this.selected = true,
  });

  final String id;
  final String summary;

  /// ARGB; Google'ın `backgroundColor`ı.
  final int? color;
  final bool primary;

  /// Google'da "göster" işaretli mi (varsayılan seçimimiz).
  final bool selected;

  Map<String, dynamic> toJson() => {
    'id': id,
    'summary': summary,
    'color': ?color,
    if (primary) 'primary': true,
    if (!selected) 'selected': false,
  };

  factory GoogleCalendarInfo.fromJson(Map<String, dynamic> j) =>
      GoogleCalendarInfo(
        id: j['id'] as String? ?? '',
        summary: j['summary'] as String? ?? '',
        color: (j['color'] as num?)?.toInt(),
        primary: j['primary'] == true,
        selected: j['selected'] != false,
      );
}

/// Bir takvimin çekiş sonucu: değişen etkinlikler, silinenlerin Google
/// kimlikleri ve bir sonraki artımlı çekişin jetonu.
class GoogleEventsPage {
  const GoogleEventsPage({
    this.events = const [],
    this.cancelled = const [],
    this.syncToken,
  });

  final List<CalendarEvent> events;
  final List<String> cancelled;
  final String? syncToken;
}

/// `#RRGGBB` → ARGB.
int? parseHexColor(String? hex) {
  if (hex == null) return null;
  final h = hex.replaceFirst('#', '');
  if (h.length != 6) return null;
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : 0xFF000000 | v;
}

/// Google etkinlik JSON'u → [CalendarEvent] (iptal/eksik zamanlı: null).
CalendarEvent? googleEventFromJson(
  Map<String, dynamic> j, {
  required String calendarId,
  int? color,
}) {
  final id = j['id'] as String? ?? '';
  if (id.isEmpty || j['status'] == 'cancelled') return null;
  final start = j['start'] as Map? ?? const {};
  final end = j['end'] as Map? ?? const {};
  final allDay = start['date'] is String;
  DateTime? at(Map m) => allDay
      ? parseDayKey(m['date'] as String?)
      : DateTime.tryParse(m['dateTime'] as String? ?? '')?.toLocal();
  final s = at(start);
  if (s == null) return null;
  final e = at(end) ?? (allDay ? DateTime(s.year, s.month, s.day + 1) : s);
  final updated = DateTime.tryParse(j['updated'] as String? ?? '');
  final link = j['htmlLink'] as String?;
  return CalendarEvent(
    id: '$kGoogleEventPrefix$calendarId/$id',
    title: j['summary'] as String? ?? '',
    description: j['description'] as String? ?? '',
    location: j['location'] as String? ?? '',
    allDay: allDay,
    start: s,
    end: e,
    color: color,
    google: GoogleLink(
      container: calendarId,
      id: id,
      etag: j['etag'] as String? ?? '',
      updated: updated,
    ),
    extras: {'htmlLink': ?link},
  );
}

class GoogleCalendarApi {
  GoogleCalendarApi({required this._client, required this._tokens});

  final http.Client _client;
  final ScopeTokenCache _tokens;

  /// YALNIZ GET — yazma uç noktası bu sınıfta yok.
  Future<Map<String, dynamic>> _get(Uri uri) async {
    Future<http.Response> once() async {
      final token = await _tokens.get();
      if (token == null) throw GoogleCalendarException(401, 'jeton yok');
      return _client.get(uri, headers: {'Authorization': 'Bearer $token'});
    }

    var res = await once();
    if (res.statusCode == 401) {
      _tokens.invalidate();
      res = await once();
    }
    if (res.statusCode >= 300) {
      throw GoogleCalendarException(res.statusCode, res.body);
    }
    // Başlıkta charset yoksa http latin1 çözer (Gmail tuzağı, HAFIZA).
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<GoogleCalendarInfo>> calendars() async {
    final out = <GoogleCalendarInfo>[];
    String? page;
    var guard = 0;
    do {
      final j = await _get(
        Uri.parse(
          '$_api/users/me/calendarList',
        ).replace(queryParameters: {'maxResults': '250', 'pageToken': ?page}),
      );
      for (final raw in j['items'] as List? ?? const []) {
        if (raw is! Map) continue;
        final id = raw['id'] as String? ?? '';
        if (id.isEmpty) continue;
        out.add(
          GoogleCalendarInfo(
            id: id,
            summary:
                raw['summaryOverride'] as String? ??
                raw['summary'] as String? ??
                id,
            color: parseHexColor(raw['backgroundColor'] as String?),
            primary: raw['primary'] == true,
            selected: raw['selected'] == true || raw['primary'] == true,
          ),
        );
      }
      page = j['nextPageToken'] as String?;
    } while (page != null && ++guard < 20);
    return out;
  }

  /// [calendarId]'nin etkinlikleri. [syncToken] varsa ARTIMLI (zaman aralığı
  /// verilemez — Google kuralı); yoksa [from]–[to] tam çekiş. 410 →
  /// [GoogleCalendarException.gone] (çağıran tam çekişe döner).
  Future<GoogleEventsPage> events(
    String calendarId, {
    String? syncToken,
    DateTime? from,
    DateTime? to,
    int? color,
  }) async {
    final events = <CalendarEvent>[];
    final cancelled = <String>[];
    String? page;
    String? next;
    var guard = 0;
    do {
      final j = await _get(
        Uri.parse('$_api/calendars/${Uri.encodeComponent(calendarId)}/events')
            .replace(
              queryParameters: {
                'singleEvents': 'true',
                'maxResults': '250',
                if (syncToken != null)
                  'syncToken': syncToken
                else ...{
                  if (from != null) 'timeMin': from.toUtc().toIso8601String(),
                  if (to != null) 'timeMax': to.toUtc().toIso8601String(),
                },
                'pageToken': ?page,
              },
            ),
      );
      for (final raw in j['items'] as List? ?? const []) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final e = googleEventFromJson(
          map,
          calendarId: calendarId,
          color: color,
        );
        if (e != null) {
          events.add(e);
        } else if (map['id'] is String) {
          cancelled.add('$kGoogleEventPrefix$calendarId/${map['id']}');
        }
      }
      page = j['nextPageToken'] as String?;
      next = j['nextSyncToken'] as String? ?? next;
    } while (page != null && ++guard < 40);
    return GoogleEventsPage(
      events: events,
      cancelled: cancelled,
      syncToken: next,
    );
  }
}
