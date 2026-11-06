import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/error_log.dart';
import '../../auth/data/google_scope_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/calendar_event.dart' show GoogleLink;
import '../domain/task_item.dart';
import '../domain/task_sync_plan.dart';
import 'calendar_repository.dart';
import 'google_calendar_sync.dart' show googleCalendarAvailableProvider;
import 'google_tasks_api.dart';

/// **GOOGLE GÖREVLER İKİ YÖNLÜ EŞLEME** (TAKVIM_PLANI F50.4, K1/K8).
///
/// Görevler Firestore'da (web + telefon aynı, çevrimdışı); Google bağlıysa
/// görevler ekranına girişte ve ekran açıkken 15 dk'da bir eşlenir. Plan saf
/// ([planTaskSync]); burada yalnız listeleri eşleme ve planı uygulama.
@immutable
class GoogleTasksState {
  const GoogleTasksState({
    this.connected = false,
    this.loading = false,
    this.error,
    this.syncedAt,
  });

  final bool connected;
  final bool loading;
  final Object? error;
  final DateTime? syncedAt;

  GoogleTasksState copyWith({
    bool? connected,
    bool? loading,
    Object? error,
    bool clearError = false,
    DateTime? syncedAt,
  }) => GoogleTasksState(
    connected: connected ?? this.connected,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    syncedAt: syncedAt ?? this.syncedAt,
  );
}

final googleTasksProvider =
    NotifierProvider<GoogleTasksController, GoogleTasksState>(
      GoogleTasksController.new,
    );

class GoogleTasksController extends Notifier<GoogleTasksState> {
  @visibleForTesting
  static GoogleScopeAuth Function()? authOverride;
  @visibleForTesting
  static http.Client Function()? clientOverride;

  static const refreshEvery = Duration(minutes: 15);

  String? _uid;
  String? _defaultList;
  GoogleScopeAuth? _auth;
  ScopeTokenCache? _tokens;
  GoogleTasksApi? _api;
  http.Client? _client;

  String get _key => 'gtasks_${_uid ?? ''}';

  @override
  GoogleTasksState build() {
    _uid = ref.watch(currentUidProvider);
    final available =
        _uid != null &&
        (authOverride != null || ref.watch(googleCalendarAvailableProvider));
    _api = null;
    _tokens = null;
    ref.onDispose(() => _client?.close());
    if (!available) return const GoogleTasksState();
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const GoogleTasksState();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _defaultList = j['default'] as String?;
      final at = (j['at'] as num?)?.toInt();
      return GoogleTasksState(
        connected: j['connected'] == true,
        syncedAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
      );
    } catch (_) {
      return const GoogleTasksState();
    }
  }

  Future<void> _save() => ref
      .read(sharedPreferencesProvider)
      .setString(
        _key,
        jsonEncode({
          'connected': state.connected,
          'default': _defaultList,
          'at': state.syncedAt?.millisecondsSinceEpoch,
        }),
      );

  void _ensureClient() {
    if (_api != null) return;
    final auth = _auth ??=
        authOverride?.call() ?? googleScopeAuth(kTasksScope, 'notlar_gtasks');
    final tokens = _tokens ??= ScopeTokenCache(silentRefresh: auth.silent);
    final client = _client ??= clientOverride?.call() ?? http.Client();
    _api = GoogleTasksApi(client: client, tokens: tokens);
  }

  Future<bool> connect() async {
    _ensureClient();
    try {
      final r = await _auth!.connect();
      if (r == null) return false;
      _tokens!.put(r.token, r.expiry);
    } catch (e) {
      ErrorLog.record('gtasks-connect', e);
      state = state.copyWith(error: e);
      return false;
    }
    state = state.copyWith(connected: true);
    await sync(force: true);
    // API konsolda kapalıysa "bağlandı" demek yanıltır (F19.B10): bağlantı
    // geri alınır, hata arayüzde nedeniyle gösterilir.
    final err = state.error;
    if (err is GoogleTasksException && err.serviceDisabled) {
      _tokens?.invalidate();
      state = GoogleTasksState(error: err);
      return false;
    }
    return true;
  }

  Future<void> disconnect() async {
    _tokens?.invalidate();
    _defaultList = null;
    state = const GoogleTasksState();
    await ref.read(sharedPreferencesProvider).remove(_key);
  }

  /// Bağlıysa eşler; [force] değilse son eşlemeden [refreshEvery] geçmeden
  /// istek atılmaz.
  Future<void> sync({bool force = false, DateTime? now}) async {
    if (!state.connected || state.loading) return;
    final start = now ?? DateTime.now();
    final last = state.syncedAt;
    if (!force && last != null && start.difference(last) < refreshEvery) {
      return;
    }
    final repo = ref.read(calendarRepositoryProvider);
    if (repo == null) return;
    _ensureClient();
    final api = _api!;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final listMap = await _syncLists(api, repo);
      final remotes = <RemoteTask>[
        for (final id in listMap.values.toSet()) ...await api.tasks(id),
      ];
      final locals = await repo.fetchAllTasks();
      await _apply(
        api,
        repo,
        planTaskSync(
          locals: locals,
          remotes: remotes,
          localToRemoteList: listMap,
          lastSync: last,
        ),
        locals,
      );
      state = state.copyWith(loading: false, syncedAt: DateTime.now());
      await _save();
    } catch (e) {
      ErrorLog.record('gtasks-sync', e);
      final unauthorized = e is GoogleTasksException && e.unauthorized;
      if (unauthorized) _tokens?.invalidate();
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// Yerel liste → Google liste. Varsayılan liste ('') Google'daki ilk
  /// listeye ("Görevlerim") eşlenir; eşi olmayan yerel liste Google'da,
  /// Google'daki eşsiz liste yerelde açılır.
  Future<Map<String, String>> _syncLists(
    GoogleTasksApi api,
    CalendarRepository repo,
  ) async {
    final remote = await api.lists();
    if (remote.isEmpty) return const {};
    final remoteIds = {for (final r in remote) r.id};
    if (_defaultList == null || !remoteIds.contains(_defaultList)) {
      _defaultList = remote.first.id;
    }
    final map = <String, String>{TaskList.defaultId: _defaultList!};
    final locals = await repo.watchTaskLists().first;
    for (final l in locals) {
      if (l.isDefault) continue;
      final g = l.google;
      if (g != null && remoteIds.contains(g.id)) {
        map[l.id] = g.id;
        continue;
      }
      final created = await api.createList(
        l.title.trim().isEmpty ? 'Liste' : l.title,
      );
      repo.saveTaskList(
        TaskList(
          id: l.id,
          title: l.title,
          position: l.position,
          createdAt: l.createdAt,
          extras: l.extras,
          google: GoogleLink(container: '', id: created.id),
        ),
      );
      map[l.id] = created.id;
    }
    final mapped = map.values.toSet();
    for (final r in remote) {
      if (mapped.contains(r.id)) continue;
      final saved = repo.saveTaskList(
        TaskList(
          id: '',
          title: r.title,
          position: locals.length + map.length,
          google: GoogleLink(container: '', id: r.id),
        ),
      );
      map[saved.id] = r.id;
    }
    return map;
  }

  Future<void> _apply(
    GoogleTasksApi api,
    CalendarRepository repo,
    List<TaskSyncAction> actions,
    List<TaskItem> locals,
  ) async {
    // Yerel kimlik → Google kimliği (alt görev üstünü bulsun).
    final remoteOf = {
      for (final t in locals)
        if (t.google case final g? when g.id.isNotEmpty) t.id: g.id,
    };
    final localOf = {for (final e in remoteOf.entries) e.value: e.key};
    GoogleLink link(RemoteTask r) => GoogleLink(
      container: r.listId,
      id: r.id,
      etag: r.etag,
      updated: r.updated,
    );

    final creates = actions.whereType<CreateRemote>().toList()
      ..sort(
        (a, b) =>
            (a.local.parentId.isEmpty ? 0 : 1) -
            (b.local.parentId.isEmpty ? 0 : 1),
      );
    for (final a in creates) {
      final parent = a.local.parentId.isEmpty
          ? null
          : remoteOf[a.local.parentId];
      final r = await api.insert(a.remoteListId, a.local, parent: parent);
      remoteOf[a.local.id] = r.id;
      localOf[r.id] = a.local.id;
      repo.saveTask(a.local.copyWith(google: link(r)));
    }
    for (final a in actions) {
      switch (a) {
        case CreateRemote():
          break;
        case UpdateRemote(:final local, :final remote):
          final r = await api.patch(remote.listId, remote.id, local);
          repo.saveTask(local.copyWith(google: link(r)));
        case DeleteRemote(:final local):
          final g = local.google!;
          await api.delete(g.container, g.id);
        case UpdateLocal(:final local, :final remote):
          repo.saveTask(
            applyRemote(local, remote).copyWith(google: link(remote)),
          );
        case TrashLocal(:final local):
          repo.trashTask(local, locals);
        case CreateLocal(:final remote, :final localListId):
          final id = repo.newId();
          localOf[remote.id] = id;
          remoteOf[id] = remote.id;
          repo.saveTask(
            TaskItem(
              id: id,
              listId: localListId,
              parentId: remote.parent.isEmpty
                  ? ''
                  : localOf[remote.parent] ?? '',
              title: remote.title,
              notes: remote.notes,
              due: remote.due,
              completed: remote.completed,
              completedAt: remote.completedAt,
              google: link(remote),
            ),
          );
      }
    }
  }
}
