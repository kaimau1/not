import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/data/google_tasks_sync.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/domain/task_sync_plan.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TAKVIM_PLANI F50.4: Google Görevler iki yönlü eşleme.
class _FakeAuth implements GoogleScopeAuth {
  @override
  Future<({String token, DateTime expiry})?> connect() async =>
      (token: 't', expiry: DateTime.now().add(const Duration(hours: 1)));
  @override
  Future<({String token, DateTime expiry})?> silent() => connect();
}

final _t0 = DateTime.utc(2026, 11, 1, 1);
final _t1 = DateTime.utc(2026, 11, 2);
final _t2 = DateTime.utc(2026, 11, 3);

TaskItem _local(
  String id, {
  String title = 'A',
  String? gid,
  DateTime? seen,
  DateTime? updatedAt,
  bool completed = false,
  DateTime? deletedAt,
  String listId = '',
}) => TaskItem(
  id: id,
  title: title,
  listId: listId,
  completed: completed,
  updatedAt: updatedAt ?? _t0,
  deletedAt: deletedAt,
  google: gid == null
      ? null
      : GoogleLink(container: 'L', id: gid, updated: seen ?? _t0),
);

RemoteTask _remote(
  String id, {
  String title = 'A',
  DateTime? updated,
  bool deleted = false,
  bool completed = false,
  String parent = '',
}) => RemoteTask(
  id: id,
  listId: 'L',
  title: title,
  updated: updated ?? _t0,
  deleted: deleted,
  completed: completed,
  parent: parent,
);

List<String> _kinds(List<TaskSyncAction> a) => [
  for (final x in a) '${x.runtimeType}',
];

void main() {
  group('plan', () {
    List<TaskSyncAction> plan(List<TaskItem> l, List<RemoteTask> r) =>
        planTaskSync(
          locals: l,
          remotes: r,
          localToRemoteList: const {'': 'L'},
          lastSync: _t0,
        );

    test('eşsizler karşıya açılır; aynı içerik hiç yazılmaz', () {
      expect(
        _kinds(
          plan(
            [_local('1'), _local('2', gid: 'g2')],
            [_remote('g2'), _remote('g3')],
          ),
        ),
        ['CreateRemote', 'CreateLocal'],
      );
    });

    test('yalnız Google değiştiyse yerel, yalnız yerel değiştiyse Google', () {
      expect(
        _kinds(
          plan(
            [_local('1', gid: 'g')],
            [_remote('g', title: 'B', updated: _t1)],
          ),
        ),
        ['UpdateLocal'],
      );
      expect(
        _kinds(
          plan(
            [_local('1', gid: 'g', title: 'B', updatedAt: _t1)],
            [_remote('g')],
          ),
        ),
        ['UpdateRemote'],
      );
    });

    test('ikisi de değiştiyse daha yeni kazanır', () {
      final l = _local('1', gid: 'g', title: 'Yerel', updatedAt: _t2);
      expect(_kinds(plan([l], [_remote('g', title: 'Uzak', updated: _t1)])), [
        'UpdateRemote',
      ]);
      final l2 = _local('1', gid: 'g', title: 'Yerel', updatedAt: _t1);
      expect(_kinds(plan([l2], [_remote('g', title: 'Uzak', updated: _t2)])), [
        'UpdateLocal',
      ]);
    });

    test('silme iki yöne taşınır', () {
      expect(
        _kinds(plan([_local('1', gid: 'g', deletedAt: _t1)], [_remote('g')])),
        ['DeleteRemote'],
      );
      expect(
        _kinds(plan([_local('1', gid: 'g')], [_remote('g', deleted: true)])),
        ['TrashLocal'],
      );
      // Google'da silinmiş ama yerelde sonradan düzenlenmiş: yeniden açılır.
      expect(
        _kinds(
          plan(
            [_local('1', gid: 'g', updatedAt: _t1, title: 'B')],
            [_remote('g', deleted: true)],
          ),
        ),
        ['CreateRemote'],
      );
    });

    test('yerele uygularken saat, tekrar ve bağlar korunur', () {
      final l = const TaskItem(
        id: '1',
        title: 'A',
        due: '2026-11-06',
        dueTime: '09:00',
        repeat: 'daily',
        noteId: 'n',
        starred: true,
      );
      final applied = applyRemote(
        l,
        const RemoteTask(id: 'g', listId: 'L', title: 'B', due: '2026-11-07'),
      );
      expect(applied.title, 'B');
      expect(applied.due, '2026-11-07');
      expect(applied.dueTime, '09:00');
      expect(applied.repeat, 'daily');
      expect(applied.noteId, 'n');
      expect(applied.starred, isTrue);
    });
  });

  group('eşleme (sahte Google + Firestore)', () {
    test(
      'bağlan → yerel Google\'a, Google yerele; sonra uzak düzenleme gelir',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = FakeFirebaseFirestore();
        final repo = CalendarRepository(db, 'u1');
        repo.saveTask(const TaskItem(id: 'loc', title: 'Yerel görev'));
        await Future<void>.delayed(Duration.zero);

        final remote = <String, Map<String, dynamic>>{
          'r1': {
            'id': 'r1',
            'title': 'Google görevi — ş',
            'status': 'needsAction',
            'due': '2026-11-09T00:00:00.000Z',
            'updated': '2026-11-01T10:00:00.000Z',
          },
        };
        final methods = <String>[];
        var counter = 0;
        http.Response json(Object body) => http.Response.bytes(
          utf8.encode(jsonEncode(body)),
          200,
          headers: {'content-type': 'application/json'},
        );
        GoogleTasksController.authOverride = _FakeAuth.new;
        GoogleTasksController.clientOverride = () => MockClient((req) async {
          methods.add('${req.method} ${req.url.path}');
          if (req.url.path.endsWith('/users/@me/lists')) {
            return json({
              'items': [
                {'id': 'L', 'title': 'Görevlerim'},
              ],
            });
          }
          if (req.method == 'GET') {
            return json({'items': remote.values.toList()});
          }
          if (req.method == 'POST') {
            final body = jsonDecode(utf8.decode(req.bodyBytes)) as Map;
            final id = 'new${counter++}';
            remote[id] = {
              ...body.cast<String, dynamic>(),
              'id': id,
              'updated': DateTime.now().toUtc().toIso8601String(),
            };
            return json(remote[id]!);
          }
          return json({});
        });
        addTearDown(() {
          GoogleTasksController.authOverride = null;
          GoogleTasksController.clientOverride = null;
        });
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue('u1'),
            calendarRepositoryProvider.overrideWithValue(repo),
          ],
        );
        addTearDown(container.dispose);

        final ctrl = container.read(googleTasksProvider.notifier);
        expect(await ctrl.connect(), isTrue);
        expect(container.read(googleTasksProvider).error, isNull);
        await Future<void>.delayed(Duration.zero);

        var tasks = await repo.fetchAllTasks();
        final mine = tasks.firstWhere((t) => t.id == 'loc');
        expect(mine.google?.id, startsWith('new'));
        expect(remote[mine.google!.id]!['title'], 'Yerel görev');
        final pulled = tasks.firstWhere((t) => t.google?.id == 'r1');
        expect(pulled.title, 'Google görevi — ş');
        expect(pulled.due, '2026-11-09');
        expect(methods.where((m) => m.startsWith('POST')), hasLength(1));

        // Google'da tamamlandı → bir sonraki eşlemede yerelde de tamam.
        remote['r1'] = {
          ...remote['r1']!,
          'status': 'completed',
          'updated': '2099-01-01T00:00:00.000Z',
        };
        await ctrl.sync(force: true);
        await Future<void>.delayed(Duration.zero);
        tasks = await repo.fetchAllTasks();
        expect(tasks.firstWhere((t) => t.google?.id == 'r1').completed, isTrue);
        // Kendi yazımlarımız Google'a geri yazılmadı (ping-pong yok).
        expect(methods.where((m) => m.startsWith('PATCH')), isEmpty);
      },
    );
  });
}
