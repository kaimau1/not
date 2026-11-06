import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/data/google_calendar_api.dart';
import 'package:notlar/features/calendar/data/google_calendar_sync.dart';
import 'package:notlar/features/calendar/domain/agenda.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/recurrence.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TAKVIM_PLANI Faz 48: Google Takvim salt okuma.
class _FakeAuth implements GoogleScopeAuth {
  @override
  Future<({String token, DateTime expiry})?> connect() async =>
      (token: 'tok', expiry: DateTime.now().add(const Duration(hours: 1)));
  @override
  Future<({String token, DateTime expiry})?> silent() => connect();
}

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, dynamic> _event(
  String id,
  String summary, {
  String? dateTime,
  String? date,
  String status = 'confirmed',
}) => {
  'id': id,
  'status': status,
  'summary': summary,
  'htmlLink': 'https://calendar.google.com/event?eid=$id',
  'start': {'dateTime': ?dateTime, 'date': ?date},
  'end': {
    if (dateTime != null)
      'dateTime': DateTime.parse(dateTime)
          .add(const Duration(hours: 1))
          .toIso8601String(),
    if (date != null) 'date': '2026-11-08',
  },
};

void main() {
  group('istemci', () {
    test('yalnız GET; takvimler ve etkinlikler çözülür (UTF-8)', () async {
      final methods = <String>{};
      final client = MockClient((req) async {
        methods.add(req.method);
        if (req.url.path.endsWith('/calendarList')) {
          return _json({
            'items': [
              {
                'id': 'ben@x.com',
                'summary': 'Kişisel',
                'backgroundColor': '#16a765',
                'primary': true,
              },
              {'id': 'tatil', 'summary': 'Tatiller', 'selected': false},
            ],
          });
        }
        expect(req.url.queryParameters['singleEvents'], 'true');
        expect(req.url.queryParameters['timeMin'], isNotNull);
        return _json({
          'items': [
            _event(
              'a',
              'Diş hekimi — çarşamba',
              dateTime: '2026-11-06T14:00:00Z',
            ),
            _event('b', 'Bayram', date: '2026-11-07'),
            _event('c', '', status: 'cancelled'),
          ],
          'nextSyncToken': 'S1',
        });
      });
      final api = GoogleCalendarApi(
        client: client,
        tokens: ScopeTokenCache(silentRefresh: _FakeAuth().silent),
      );
      final cals = await api.calendars();
      expect(cals.map((c) => c.summary), ['Kişisel', 'Tatiller']);
      expect(cals.first.color, 0xFF16A765);
      expect(cals.last.selected, isFalse);

      final page = await api.events(
        'ben@x.com',
        from: DateTime(2026, 10),
        to: DateTime(2026, 12),
        color: 0xFF16A765,
      );
      expect(methods, {'GET'});
      expect(page.syncToken, 'S1');
      expect(page.cancelled, ['g:ben@x.com/c']);
      final timed = page.events.first;
      expect(timed.title, 'Diş hekimi — çarşamba');
      expect(timed.fromGoogle, isTrue);
      expect(timed.google!.id, 'a');
      expect(timed.extras['htmlLink'], contains('eid=a'));
      expect(timed.start.isUtc, isFalse);
      final allDay = page.events.last;
      expect(allDay.allDay, isTrue);
      expect(allDay.start, DateTime(2026, 11, 7));
      expect(allDay.end, DateTime(2026, 11, 8));
      // Google etkinliği sürüklenmez.
      expect(canMoveEntry(EventOccurrence(timed, timed.start)), isFalse);
    });

    test('önbellek kodlaması gidiş-dönüş', () {
      final e = googleEventFromJson(
        _event('a', 'X', dateTime: '2026-11-06T14:00:00Z'),
        calendarId: 'k',
        color: 1,
      )!;
      final back = decodeGoogleEvent(
        jsonDecode(jsonEncode(encodeGoogleEvent(e))),
      )!;
      expect(back.id, e.id);
      expect(back.start, e.start);
      expect(back.end, e.end);
      expect(back.google!.container, 'k');
      expect(back.extras['htmlLink'], e.extras['htmlLink']);
    });
  });

  group('eşitleme', () {
    late ProviderContainer container;
    late List<Uri> calls;
    late List<http.Response Function(http.Request)> eventReplies;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      calls = [];
      eventReplies = [];
      GoogleCalendarController.authOverride = _FakeAuth.new;
      GoogleCalendarController.clientOverride = () => MockClient((req) async {
        calls.add(req.url);
        if (req.url.path.endsWith('/calendarList')) {
          return _json({
            'items': [
              {'id': 'k', 'summary': 'Kişisel', 'primary': true},
            ],
          });
        }
        return eventReplies.removeAt(0)(req);
      });
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('u1'),
          eventLinksStreamProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      GoogleCalendarController.authOverride = null;
      GoogleCalendarController.clientOverride = null;
    });

    test(
      'bağlan → tam çekiş; sonra syncToken ile artımlı; 410 → tam',
      () async {
        final now = DateTime(2026, 11, 6, 12);
        eventReplies.add(
          (_) => _json({
            'items': [
              _event('a', 'Bir', dateTime: '2026-11-06T14:00:00Z'),
              _event('b', 'İki', dateTime: '2026-11-07T14:00:00Z'),
            ],
            'nextSyncToken': 'S1',
          }),
        );
        final ctrl = container.read(googleCalendarProvider.notifier);
        expect(await ctrl.connect(), isTrue);
        expect(container.read(googleCalendarProvider).events, hasLength(2));

        // Artımlı: b iptal, c yeni.
        eventReplies.add((req) {
          expect(req.url.queryParameters['syncToken'], 'S1');
          expect(req.url.queryParameters.containsKey('timeMin'), isFalse);
          return _json({
            'items': [
              _event('b', '', status: 'cancelled'),
              _event('c', 'Üç', dateTime: '2026-11-08T14:00:00Z'),
            ],
            'nextSyncToken': 'S2',
          });
        });
        await ctrl.refresh(force: true, now: now);
        expect(
          container.read(googleCalendarProvider).events.map((e) => e.title),
          unorderedEquals(['Bir', 'Üç']),
        );

        // 15 dk dolmadan zorlamasız tazeleme istek atmaz.
        final before = calls.length;
        await ctrl.refresh(now: now.add(const Duration(minutes: 5)));
        expect(calls.length, before);

        // Jeton bayat: 410 → tam çekiş.
        eventReplies
          ..add((_) => _json({'error': 'gone'}, 410))
          ..add((req) {
            expect(req.url.queryParameters['timeMin'], isNotNull);
            return _json({
              'items': [_event('d', 'Dört', dateTime: '2026-11-09T14:00:00Z')],
              'nextSyncToken': 'S3',
            });
          });
        await ctrl.refresh(force: true, now: now);
        expect(
          container.read(googleCalendarProvider).events.map((e) => e.title),
          ['Dört'],
        );

        // Önbellek: yeni denetleyici ağsız açılır, etkinlik yerinde.
        final prefs = container.read(sharedPreferencesProvider);
        final again = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue('u1'),
            eventLinksStreamProvider.overrideWith((ref) => Stream.value({})),
          ],
        );
        addTearDown(again.dispose);
        final cached = again.read(googleCalendarProvider);
        expect(cached.connected, isTrue);
        expect(cached.events.single.title, 'Dört');
      },
    );

    test('gizlenen takvimin etkinlikleri gösterilmez', () async {
      eventReplies.add(
        (_) => _json({
          'items': [_event('a', 'Bir', dateTime: '2026-11-06T14:00:00Z')],
          'nextSyncToken': 'S1',
        }),
      );
      final ctrl = container.read(googleCalendarProvider.notifier);
      await ctrl.connect();
      await ctrl.setShown('k', false);
      expect(container.read(googleCalendarProvider).events, isEmpty);
      expect(container.read(googleCalendarEventsProvider), isEmpty);
    });
  });

  group('Google\'a yazma (Faz 51)', () {
    test('tekrar RRULE\'a, etkinlik gövdeye çevrilir', () {
      expect(rruleOf(Recurrence.parse('daily')), 'RRULE:FREQ=DAILY');
      expect(
        rruleOf(Recurrence.parse('weekly:1,3;every=2;count=5')),
        'RRULE:FREQ=WEEKLY;BYDAY=MO,WE;INTERVAL=2;COUNT=5',
      );
      expect(
        rruleOf(Recurrence.parse('monthly;until=2026-12-31')),
        'RRULE:FREQ=MONTHLY;UNTIL=20261231T235959Z',
      );
      expect(rruleOf(Recurrence.none), isNull);
      final body = googleEventBody(
        CalendarEvent(
          id: '',
          title: 'Plan',
          allDay: true,
          start: DateTime(2026, 11, 6),
          end: DateTime(2026, 11, 7),
          reminders: const [30],
        ),
      );
      expect(body['start'], {'date': '2026-11-06', 'dateTime': null});
      expect(body['recurrence'], isEmpty);
      expect((body['reminders'] as Map)['overrides'], [
        {'method': 'popup', 'minutes': 30},
      ]);
    });

    test(
      'kaydet: anında görünür; ağ yoksa kuyrukta, sonra gönderilir',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        var down = true;
        final posts = <Map<String, dynamic>>[];
        GoogleCalendarController.authOverride = _FakeAuth.new;
        GoogleCalendarController.writeAuthOverride = _FakeAuth.new;
        GoogleCalendarController.clientOverride = () => MockClient((req) async {
          if (req.url.path.endsWith('/calendarList')) {
            return _json({
              'items': [
                {'id': 'k', 'summary': 'Kişisel', 'primary': true},
              ],
            });
          }
          if (req.method == 'GET') {
            return _json({'items': [], 'nextSyncToken': 'S'});
          }
          if (down) return http.Response('yok', 503);
          final body =
              jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;
          posts.add(body);
          return _json({
            ...body,
            'id': 'yeni',
            'status': 'confirmed',
            'start': {'dateTime': '2026-11-06T14:00:00Z'},
            'end': {'dateTime': '2026-11-06T15:00:00Z'},
          });
        });
        addTearDown(() {
          GoogleCalendarController.authOverride = null;
          GoogleCalendarController.writeAuthOverride = null;
          GoogleCalendarController.clientOverride = null;
        });
        final c = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue('u1'),
            eventLinksStreamProvider.overrideWith((ref) => Stream.value({})),
          ],
        );
        addTearDown(c.dispose);
        final ctrl = c.read(googleCalendarProvider.notifier);
        await ctrl.connect();
        expect(await ctrl.connectWrite(), isTrue);

        await ctrl.saveToGoogle(
          CalendarEvent(
            id: '',
            title: 'Diş',
            start: DateTime(2026, 11, 6, 17),
            end: DateTime(2026, 11, 6, 18),
          ),
        );
        var s = c.read(googleCalendarProvider);
        expect(s.events.single.title, 'Diş');
        expect(s.events.single.fromGoogle, isTrue);
        expect(s.pending, 1);

        down = false;
        await ctrl.refresh(force: true);
        s = c.read(googleCalendarProvider);
        expect(s.pending, 0);
        expect(posts.single['summary'], 'Diş');
        expect(s.events.single.google!.id, 'yeni');
      },
    );
  });
}
