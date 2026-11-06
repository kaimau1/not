import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../auth/data/google_scope_auth.dart' show ScopeTokenCache;
import 'google_api_problem.dart';
import '../domain/day_key.dart';
import '../domain/task_item.dart';
import '../domain/task_sync_plan.dart';

/// **GOOGLE GÖREVLER** (TAKVIM_PLANI F50.4). Kapsam `tasks` (okuma+yazma)
/// Gmail/Drive/Takvim'den AYRI istenir. Konsol: Tasks API etkin + kapsam
/// (F19.B10).
const kTasksScope = 'https://www.googleapis.com/auth/tasks';

const _api = 'https://tasks.googleapis.com/tasks/v1';

class GoogleTasksException implements Exception {
  GoogleTasksException(this.status, this.body);
  final int status;
  final String body;
  bool get unauthorized => status == 401 || (status == 403 && !serviceDisabled);

  /// Google Cloud'da Tasks API etkin değil (F19.B10).
  bool get serviceDisabled => googleServiceDisabled(status, body);
  bool get notFound => status == 404 || status == 410;
  @override
  String toString() => 'GoogleTasksException($status)';
}

/// Google görev listesi.
class RemoteTaskList {
  const RemoteTaskList({required this.id, required this.title, this.updated});
  final String id;
  final String title;
  final DateTime? updated;
}

/// Google görev JSON'u → [RemoteTask].
RemoteTask remoteTaskFromJson(Map<String, dynamic> j, String listId) {
  final due = j['due'] as String? ?? '';
  return RemoteTask(
    id: j['id'] as String? ?? '',
    listId: listId,
    title: j['title'] as String? ?? '',
    notes: j['notes'] as String? ?? '',
    due: due.length >= 10 && parseDayKey(due.substring(0, 10)) != null
        ? due.substring(0, 10)
        : '',
    completed: j['status'] == 'completed',
    completedAt: DateTime.tryParse(j['completed'] as String? ?? ''),
    parent: j['parent'] as String? ?? '',
    deleted: j['deleted'] == true,
    updated: DateTime.tryParse(j['updated'] as String? ?? ''),
    etag: j['etag'] as String? ?? '',
  );
}

/// Yerel görevin Google'a giden gövdesi (yalnız Google'ın tuttuğu alanlar).
Map<String, dynamic> remoteTaskBody(TaskItem t) => {
  'title': t.title,
  'notes': t.notes,
  // Google yalnız günü saklar; saat bizde kalır.
  'due': t.due.isEmpty ? null : '${t.due}T00:00:00.000Z',
  'status': t.completed ? 'completed' : 'needsAction',
  if (!t.completed) 'completed': null,
};

class GoogleTasksApi {
  GoogleTasksApi({required this._client, required this._tokens});

  final http.Client _client;
  final ScopeTokenCache _tokens;

  Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    Future<http.Response> once() async {
      final token = await _tokens.get();
      if (token == null) throw GoogleTasksException(401, 'jeton yok');
      final headers = {
        'Authorization': 'Bearer $token',
        if (body != null) 'Content-Type': 'application/json; charset=utf-8',
      };
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.bodyBytes = utf8.encode(jsonEncode(body));
      return http.Response.fromStream(await _client.send(request));
    }

    var res = await once();
    if (res.statusCode == 401) {
      _tokens.invalidate();
      res = await once();
    }
    if (res.statusCode >= 300) {
      throw GoogleTasksException(res.statusCode, res.body);
    }
    if (res.bodyBytes.isEmpty) return const {};
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<RemoteTaskList>> lists() async {
    final out = <RemoteTaskList>[];
    String? page;
    var guard = 0;
    do {
      final j = await _send(
        'GET',
        Uri.parse(
          '$_api/users/@me/lists',
        ).replace(queryParameters: {'maxResults': '100', 'pageToken': ?page}),
      );
      for (final raw in j['items'] as List? ?? const []) {
        if (raw is! Map) continue;
        out.add(
          RemoteTaskList(
            id: raw['id'] as String? ?? '',
            title: raw['title'] as String? ?? '',
            updated: DateTime.tryParse(raw['updated'] as String? ?? ''),
          ),
        );
      }
      page = j['nextPageToken'] as String?;
    } while (page != null && ++guard < 20);
    return out;
  }

  Future<RemoteTaskList> createList(String title) async {
    final j = await _send(
      'POST',
      Uri.parse('$_api/users/@me/lists'),
      body: {'title': title},
    );
    return RemoteTaskList(id: j['id'] as String, title: title);
  }

  /// Listenin BÜTÜN görevleri (tamamlanmış, gizli ve silinmiş dahil).
  Future<List<RemoteTask>> tasks(String listId) async {
    final out = <RemoteTask>[];
    String? page;
    var guard = 0;
    do {
      final j = await _send(
        'GET',
        Uri.parse('$_api/lists/${Uri.encodeComponent(listId)}/tasks').replace(
          queryParameters: {
            'maxResults': '100',
            'showCompleted': 'true',
            'showHidden': 'true',
            'showDeleted': 'true',
            'pageToken': ?page,
          },
        ),
      );
      for (final raw in j['items'] as List? ?? const []) {
        if (raw is! Map) continue;
        final t = remoteTaskFromJson(Map<String, dynamic>.from(raw), listId);
        if (t.id.isNotEmpty) out.add(t);
      }
      page = j['nextPageToken'] as String?;
    } while (page != null && ++guard < 50);
    return out;
  }

  Future<RemoteTask> insert(String listId, TaskItem t, {String? parent}) async {
    final j = await _send(
      'POST',
      Uri.parse('$_api/lists/${Uri.encodeComponent(listId)}/tasks')
          .replace(queryParameters: {'parent': ?parent}),
      body: remoteTaskBody(t),
    );
    return remoteTaskFromJson(j, listId);
  }

  Future<RemoteTask> patch(String listId, String taskId, TaskItem t) async {
    final j = await _send(
      'PATCH',
      Uri.parse(
        '$_api/lists/${Uri.encodeComponent(listId)}/tasks/'
        '${Uri.encodeComponent(taskId)}',
      ),
      body: remoteTaskBody(t),
    );
    return remoteTaskFromJson(j, listId);
  }

  Future<void> delete(String listId, String taskId) async {
    try {
      await _send(
        'DELETE',
        Uri.parse(
          '$_api/lists/${Uri.encodeComponent(listId)}/tasks/'
          '${Uri.encodeComponent(taskId)}',
        ),
      );
    } on GoogleTasksException catch (e) {
      // Zaten silinmiş: amaç gerçekleşmiş.
      if (!e.notFound) rethrow;
    }
  }
}
