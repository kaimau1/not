import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error_log.dart';
import '../../auth/data/google_scope_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/drive_store.dart' show isGoogleUser;
import '../../settings/settings_providers.dart';
import '../domain/calendar_event.dart';
import 'calendar_repository.dart';
import 'google_calendar_api.dart';

/// **GOOGLE TAKVİM EŞİTLEMESİ** (TAKVIM_PLANI Faz 48, K2/K8).
///
/// Google etkinlikleri Firestore'a YAZILMAZ: kaynak Google, kopyası cihazda
/// (`SharedPreferences`, uid'e bağlı) — açılışta önbellekten anında, sonra
/// arka planda tazelenir. Çekiş: ilk kez görünür aralık ±60 gün, sonra
/// takvim başına `syncToken` ile artımlı; 410 → tam çekiş. Yalnız uygulama
/// açıkken (takvim ekranına giriş + ekran açıkken 15 dk'da bir, K8).

/// Google Takvim yalnız Google hesabında ve Android/web'de (Gmail kuralı).
final googleCalendarAvailableProvider = Provider<bool>((ref) {
  if (!isGoogleUser(ref.watch(authStateProvider).value)) return false;
  return kIsWeb || Platform.isAndroid;
});

/// Bir takvimin önbelleği.
@immutable
class _CalendarCache {
  const _CalendarCache({this.syncToken, this.events = const {}});
  final String? syncToken;

  /// Bizdeki kimlik (`g:<takvim>/<id>`) → etkinlik.
  final Map<String, CalendarEvent> events;
}

@immutable
class GoogleCalendarState {
  const GoogleCalendarState({
    this.connected = false,
    this.calendars = const [],
    this.shown,
    this.events = const [],
    this.loading = false,
    this.error,
    this.syncedAt,
  });

  /// Bir kez bağlandı (önbellekte takvim listesi var).
  final bool connected;
  final List<GoogleCalendarInfo> calendars;

  /// Kullanıcının seçtiği takvimler; null = Google'daki "göster" seçimi.
  final Set<String>? shown;

  /// Gösterilen takvimlerin etkinlikleri.
  final List<CalendarEvent> events;
  final bool loading;
  final Object? error;
  final DateTime? syncedAt;

  bool isShown(GoogleCalendarInfo c) =>
      shown?.contains(c.id) ?? (c.selected || c.primary);

  GoogleCalendarState copyWith({
    bool? connected,
    List<GoogleCalendarInfo>? calendars,
    Set<String>? shown,
    List<CalendarEvent>? events,
    bool? loading,
    Object? error,
    bool clearError = false,
    DateTime? syncedAt,
  }) => GoogleCalendarState(
    connected: connected ?? this.connected,
    calendars: calendars ?? this.calendars,
    shown: shown ?? this.shown,
    events: events ?? this.events,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    syncedAt: syncedAt ?? this.syncedAt,
  );
}

/// Önbellekteki etkinliğin JSON'u (Firestore biçimi değil — Timestamp yok).
Map<String, dynamic> encodeGoogleEvent(CalendarEvent e) => {
  'id': e.id,
  't': e.title,
  if (e.description.isNotEmpty) 'd': e.description,
  if (e.location.isNotEmpty) 'l': e.location,
  if (e.allDay) 'a': true,
  's': e.start.millisecondsSinceEpoch,
  'e': e.end.millisecondsSinceEpoch,
  'c': ?e.color,
  if (e.google case final g?) ...{'gc': g.container, 'gi': g.id, 'ge': g.etag},
  if (e.extras['htmlLink'] case final String link) 'u': link,
};

CalendarEvent? decodeGoogleEvent(Object? raw) {
  if (raw is! Map) return null;
  final id = raw['id'] as String? ?? '';
  final s = raw['s'], e = raw['e'];
  if (id.isEmpty || s is! num || e is! num) return null;
  final gi = raw['gi'] as String? ?? '';
  return CalendarEvent(
    id: id,
    title: raw['t'] as String? ?? '',
    description: raw['d'] as String? ?? '',
    location: raw['l'] as String? ?? '',
    allDay: raw['a'] == true,
    start: DateTime.fromMillisecondsSinceEpoch(s.toInt()),
    end: DateTime.fromMillisecondsSinceEpoch(e.toInt()),
    color: (raw['c'] as num?)?.toInt(),
    google: gi.isEmpty
        ? null
        : GoogleLink(
            container: raw['gc'] as String? ?? '',
            id: gi,
            etag: raw['ge'] as String? ?? '',
          ),
    extras: {'htmlLink': ?raw['u'] as String?},
  );
}

final googleCalendarProvider =
    NotifierProvider<GoogleCalendarController, GoogleCalendarState>(
      GoogleCalendarController.new,
    );

class GoogleCalendarController extends Notifier<GoogleCalendarState> {
  /// Testte sahte istemci/jeton için.
  @visibleForTesting
  static GoogleScopeAuth Function()? authOverride;
  @visibleForTesting
  static http.Client Function()? clientOverride;

  static const refreshEvery = Duration(minutes: 15);
  static const window = Duration(days: 60);

  final Map<String, _CalendarCache> _cache = {};
  GoogleScopeAuth? _auth;
  ScopeTokenCache? _tokens;
  GoogleCalendarApi? _api;
  http.Client? _client;
  String? _uid;

  String get _key => 'gcal_cache_${_uid ?? ''}';

  @override
  GoogleCalendarState build() {
    _uid = ref.watch(currentUidProvider);
    final available =
        authOverride != null || ref.watch(googleCalendarAvailableProvider);
    _cache.clear();
    _api = null;
    _tokens = null;
    ref.onDispose(() => _client?.close());
    if (_uid == null || !available) return const GoogleCalendarState();
    final prefs = ref.read(sharedPreferencesProvider);
    return _load(prefs);
  }

  GoogleCalendarState _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return const GoogleCalendarState();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final calendars = [
        for (final c in j['calendars'] as List? ?? const [])
          if (c is Map) GoogleCalendarInfo.fromJson(Map.from(c)),
      ];
      final per = j['per'] as Map? ?? const {};
      for (final entry in per.entries) {
        final v = entry.value as Map? ?? const {};
        _cache[entry.key.toString()] = _CalendarCache(
          syncToken: v['token'] as String?,
          events: {
            for (final ev in [
              for (final e in v['events'] as List? ?? const [])
                ?decodeGoogleEvent(e),
            ])
              ev.id: ev,
          },
        );
      }
      final at = (j['at'] as num?)?.toInt();
      final base = GoogleCalendarState(
        connected: calendars.isNotEmpty,
        calendars: calendars,
        shown: j['shown'] is List
            ? {
                for (final h in j['shown'] as List)
                  if (h is String) h,
              }
            : null,
        syncedAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
      );
      return base.copyWith(events: _visible(base));
    } catch (e) {
      ErrorLog.record('gcal-cache', e);
      return const GoogleCalendarState();
    }
  }

  Future<void> _save() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _key,
      jsonEncode({
        'calendars': [for (final c in state.calendars) c.toJson()],
        'shown': state.shown?.toList(),
        'at': state.syncedAt?.millisecondsSinceEpoch,
        'per': {
          for (final e in _cache.entries)
            e.key: {
              'token': e.value.syncToken,
              'events': [
                for (final ev in e.value.events.values) encodeGoogleEvent(ev),
              ],
            },
        },
      }),
    );
  }

  List<CalendarEvent> _visible(GoogleCalendarState s) => [
    for (final c in s.calendars)
      if (s.isShown(c)) ...?_cache[c.id]?.events.values,
  ];

  void _ensureClient() {
    if (_api != null) return;
    final auth = _auth ??=
        authOverride?.call() ??
        googleScopeAuth(kCalendarReadonlyScope, 'notlar_gcal_token');
    final tokens = _tokens ??= ScopeTokenCache(silentRefresh: auth.silent);
    final client = _client ??= clientOverride?.call() ?? http.Client();
    _api = GoogleCalendarApi(client: client, tokens: tokens);
  }

  /// Kullanıcıdan izin ister ve ilk çekişi yapar. İzin verilmezse false.
  Future<bool> connect() async {
    _ensureClient();
    try {
      final r = await _auth!.connect();
      if (r == null) return false;
      _tokens!.put(r.token, r.expiry);
    } catch (e) {
      ErrorLog.record('gcal-connect', e);
      state = state.copyWith(error: e);
      return false;
    }
    await refresh(force: true);
    return state.connected;
  }

  /// Bağlıysa tazeler. [force] değilse son çekişten [refreshEvery] geçmeden
  /// istek atılmaz.
  Future<void> refresh({bool force = false, DateTime? now}) async {
    final at = now ?? DateTime.now();
    if (!force) {
      if (!state.connected || state.loading) return;
      final last = state.syncedAt;
      if (last != null && at.difference(last) < refreshEvery) return;
    }
    _ensureClient();
    final api = _api!;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final calendars = await api.calendars();
      final next = state.copyWith(calendars: calendars, connected: true);
      for (final c in calendars) {
        if (!next.isShown(c)) continue;
        await _sync(api, c, at);
      }
      _cache.removeWhere((id, _) => !calendars.any((c) => c.id == id));
      state = next.copyWith(
        loading: false,
        syncedAt: at,
        events: _visible(next),
      );
      await _save();
    } catch (e) {
      ErrorLog.record('gcal-sync', e);
      final unauthorized = e is GoogleCalendarException && e.unauthorized;
      state = state.copyWith(loading: false, error: unauthorized ? null : e);
      if (unauthorized) _tokens?.invalidate();
    }
  }

  Future<void> _sync(
    GoogleCalendarApi api,
    GoogleCalendarInfo c,
    DateTime at,
  ) async {
    final cached = _cache[c.id];
    GoogleEventsPage page;
    var full = cached?.syncToken == null;
    try {
      page = full
          ? await api.events(
              c.id,
              from: at.subtract(window),
              to: at.add(window),
              color: c.color,
            )
          : await api.events(
              c.id,
              syncToken: cached!.syncToken,
              color: c.color,
            );
    } on GoogleCalendarException catch (e) {
      if (!e.gone) rethrow;
      full = true;
      page = await api.events(
        c.id,
        from: at.subtract(window),
        to: at.add(window),
        color: c.color,
      );
    }
    final events = full
        ? <String, CalendarEvent>{}
        : Map<String, CalendarEvent>.of(cached!.events);
    for (final id in page.cancelled) {
      events.remove(id);
    }
    for (final e in page.events) {
      events[e.id] = e;
    }
    _cache[c.id] = _CalendarCache(
      syncToken: page.syncToken ?? cached?.syncToken,
      events: events,
    );
  }

  /// Takvimi göster/gizle (önbellek kalır; açılınca yeniden çekilir).
  Future<void> setShown(String calendarId, bool shown) async {
    final ids = {
      ...state.shown ??
          {
            for (final c in state.calendars)
              if (c.selected || c.primary) c.id,
          },
    };
    shown ? ids.add(calendarId) : ids.remove(calendarId);
    final next = state.copyWith(shown: ids);
    state = next.copyWith(events: _visible(next));
    await _save();
    if (shown && _cache[calendarId] == null) await refresh(force: true);
  }

  /// Bağlantıyı unutur (önbellek silinir; Google'daki izin kalır).
  Future<void> disconnect() async {
    _cache.clear();
    _tokens?.invalidate();
    state = const GoogleCalendarState();
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

/// Takvimde gösterilecek Google etkinlikleri, bağlı notlarıyla (F48.4).
final googleCalendarEventsProvider = Provider<List<CalendarEvent>>((ref) {
  final events = ref.watch(googleCalendarProvider.select((s) => s.events));
  if (events.isEmpty) return const [];
  final links =
      ref.watch(eventLinksStreamProvider).value ??
      const <String, List<String>>{};
  if (links.isEmpty) return events;
  return [
    for (final e in events)
      if (links[e.google?.id] case final ids? when ids.isNotEmpty)
        e.copyWith(noteIds: ids)
      else
        e,
  ];
});
