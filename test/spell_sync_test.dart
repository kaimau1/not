import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/settings/data/spell_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Y-6 SpellMemory 3-yollu birleştirme', () {
    test('iki cihazda farklı eklemeler birleşir, words haritası dahil değil', () {
      final localMem = SpellMemory()
        ..keep.add('kaimau')
        ..addWord('sadeceyerel')
        ..addWord('sadeceyerel')
        ..addWord('sadeceyerel')
        ..addManualFix('togh', 'togg');
      final local = localMem.toSyncMap();
      expect(local.containsKey('w'), isFalse);

      final remoteMem = SpellMemory()
        ..keep.add('notlar')
        ..rejectPair('kalen', 'kalem')
        ..addManualFix('yarin', 'yarın');
      final remote = remoteMem.toSyncMap();

      final plan = SpellMemory.mergeSync(
        local: local,
        remote: remote,
        snapshot: const {},
      );
      expect(plan.localChanged, isTrue);
      expect(plan.remoteChanged, isTrue);
      final applied = SpellMemory()..applySyncMap(plan.merged);
      expect(applied.keep, containsAll(['kaimau', 'notlar']));
      expect(applied.isRejected('kalen', 'kalem'), isTrue);
      expect(applied.fixes['togh']?.$1, 'togg');
      expect(applied.fixes['yarin']?.$1, 'yarın');
    });

    test('yerelde silinen kelime bulutta dokunulmadıysa silinir', () {
      final snap = (SpellMemory()
            ..keep.addAll(['eski', 'kalsin'])
            ..addManualFix('togh', 'togg'))
          .toSyncMap();
      final local = (SpellMemory()..keep.add('kalsin')).toSyncMap();
      final remote = (SpellMemory()
            ..keep.addAll(['eski', 'kalsin', 'yenibulut'])
            ..addManualFix('togh', 'togg'))
          .toSyncMap();

      final plan = SpellMemory.mergeSync(
        local: local,
        remote: remote,
        snapshot: snap,
      );
      final applied = SpellMemory()..applySyncMap(plan.merged);
      expect(applied.keep, {'kalsin', 'yenibulut'});
      expect(applied.fixes, isEmpty);
    });

    test('bulutta silinen kelime yerelde dokunulmadıysa yerelden de kalkar', () {
      final snap = (SpellMemory()
            ..keep.addAll(['silindi', 'duruyor'])
            ..rejectPair('a', 'b'))
          .toSyncMap();
      final local = (SpellMemory()
            ..keep.addAll(['silindi', 'duruyor', 'yerelyeni'])
            ..rejectPair('a', 'b'))
          .toSyncMap();
      final remote = (SpellMemory()..keep.add('duruyor')).toSyncMap();

      final plan = SpellMemory.mergeSync(
        local: local,
        remote: remote,
        snapshot: snap,
      );
      final applied = SpellMemory()..applySyncMap(plan.merged);
      expect(applied.keep, {'duruyor', 'yerelyeni'});
      expect(applied.isRejected('a', 'b'), isFalse);
    });
  });

  group('Y-6 SpellSync yaşam döngüsü ve maliyet disiplini', () {
    test('açılışta tek okuma, değiş yoksa pause anında 0 yazma', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localMem = SpellMemory()..keep.add('ortak');
      var reads = 0;
      var writes = 0;

      final sync = SpellSync(
        prefs: prefs,
        loadLocal: () async {},
        readLocal: localMem.toSyncMap,
        applyLocal: (m) async => localMem.applySyncMap(m),
        readRemote: () async {
          reads++;
          return (SpellMemory()..keep.add('ortak')).toSyncMap();
        },
        writeRemote: (_) async => writes++,
      );
      await sync.pullOnce();
      expect(reads, 1);
      expect(writes, 0);

      await sync.flush();
      expect(writes, 0, reason: 'değişiklik yoksa buluta yazılmaz');
      sync.dispose();
    });

    test('yerelde eklenince yalnız pause anında tek yazma gider', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localMem = SpellMemory();
      Map<String, Object?>? pushed;
      var writes = 0;

      final sync = SpellSync(
        prefs: prefs,
        loadLocal: () async {},
        readLocal: localMem.toSyncMap,
        applyLocal: (m) async => localMem.applySyncMap(m),
        readRemote: () async => (SpellMemory()..keep.add('bulut')).toSyncMap(),
        writeRemote: (data) async {
          writes++;
          pushed = data;
        },
      );
      await sync.pullOnce();
      expect(localMem.keep, {'bulut'});
      expect(writes, 0);

      localMem.keep.add('yeni');
      // Alta atılmadan önce yazım yok.
      expect(writes, 0);

      sync.didChangeAppLifecycleState(AppLifecycleState.paused);
      await Future<void>.delayed(Duration.zero);
      expect(writes, 1);
      expect(pushed?['k'], containsAll(['bulut', 'yeni']));

      // İkinci pause'da yeni değişiklik yok → 0 ek yazma.
      await sync.flush();
      expect(writes, 1);
      sync.dispose();
    });

    test('açılış okuması başarısızsa pause bulutu ezmez', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localMem = SpellMemory()..keep.add('yerel');
      var writes = 0;

      final sync = SpellSync(
        prefs: prefs,
        loadLocal: () async {},
        readLocal: localMem.toSyncMap,
        applyLocal: (m) async => localMem.applySyncMap(m),
        readRemote: () async => throw StateError('offline'),
        writeRemote: (_) async => writes++,
      );
      await sync.pullOnce();
      await sync.flush();
      expect(writes, 0);
      sync.dispose();
    });
  });
}
