import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../core/utils/firestore_size.dart';
import '../../../core/utils/spell_learn.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/presentation/editor/auto_spell.dart';
import '../settings_providers.dart';

/// **YAZIM SÖZLÜĞÜ EŞİTLEMESİ** (Y-6, 17K §3.3).
///
/// Kişisel sözlük (`keep`), reddedilen çiftler (`rejected`) ve öğretilen
/// düzeltmeler (`fixes`) `users/{uid}/meta/spell` belgesinde eşitlenir.
/// 5000 kelimelik `words` sıklık sayacı cihaza özel kalır (belge şişmesin).
///
/// Maliyet disiplini:
/// * Sürekli dinleyici YOK — açılışta TEK okuma (`get`).
/// * Yazım sırasında yazma YOK — uygulama alta atılınca (`paused`) TEK yazma,
///   yalnız buluttaki son durumdan fark varsa.
/// * Üç yollu birleştirme ([SpellMemory.mergeSync]): son eşitlenen anlık
///   görüntüye göre yerel ve bulut eklemeleri birleşir, silinenler yayılır.
const kSpellSyncSnapshotKey = 'spell_sync_snapshot_v1';

/// Oturum açıkken ayakta durur (bkz. `AppServices`).
final spellSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  final doc = FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(uid)
      .collection('meta')
      .doc('spell');
  final sync = SpellSync(
    prefs: ref.read(sharedPreferencesProvider),
    readRemote: () async {
      final snap = await doc.get();
      final raw = snap.data()?['memory'];
      return raw is Map ? Map<String, Object?>.from(raw) : {};
    },
    writeRemote: (data) => doc.set({
      'memory': data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );
  sync.start();
  ref.onDispose(sync.dispose);
});

class SpellSync with WidgetsBindingObserver {
  SpellSync({
    required this.prefs,
    required this.readRemote,
    required this.writeRemote,
    Future<void> Function()? loadLocal,
    Map<String, Object?> Function()? readLocal,
    Future<void> Function(Map<String, Object?> merged)? applyLocal,
  }) : _loadLocal = loadLocal ?? AutoSpell.load,
       _readLocal = readLocal ?? (() => AutoSpell.memory.toSyncMap()),
       _applyLocal = applyLocal ?? AutoSpell.applyRemoteSync;

  final SharedPreferences prefs;
  final Future<Map<String, Object?>> Function() readRemote;
  final Future<void> Function(Map<String, Object?> data) writeRemote;
  final Future<void> Function() _loadLocal;
  final Map<String, Object?> Function() _readLocal;
  final Future<void> Function(Map<String, Object?> merged) _applyLocal;

  Map<String, Object?>? _lastRemote;
  bool _disposed = false;
  bool _flushing = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(pullOnce());
  }

  /// Açılışta tek okuma ve üç yollu birleştirme (buluta yazmaz).
  Future<void> pullOnce() async {
    try {
      await _loadLocal();
      if (_disposed) return;
      final remote = await readRemote();
      if (_disposed) return;
      final snapshot = _readSnapshot();
      final local = _readLocal();
      final plan = SpellMemory.mergeSync(
        local: local,
        remote: remote,
        snapshot: snapshot ?? const {},
      );
      if (plan.localChanged) {
        await _applyLocal(plan.merged);
      }
      _lastRemote = remote;
      // Bulutla zaten özdeşse anlık görüntüyü güncelle; fark varsa alta
      // atılınca buluta yazılıp o zaman anlık görüntü kaydedilir.
      if (!plan.remoteChanged) {
        await _writeSnapshotIfChanged(snapshot, plan.merged);
      }
    } catch (e) {
      debugPrint('Yazım sözlüğü okunamadı: $e');
    }
  }

  /// Uygulama alta atılınca: yalnız buluttan fark varsa tek yazma.
  Future<void> flush() async {
    final lastRemote = _lastRemote;
    if (_disposed || _flushing || lastRemote == null) return;
    final local = _readLocal();
    if (sameFirestoreValue(local, lastRemote)) return;
    _flushing = true;
    try {
      await writeRemote(local);
      _lastRemote = local;
      await _writeSnapshotIfChanged(_readSnapshot(), local);
    } catch (e) {
      debugPrint('Yazım sözlüğü yazılamadı: $e');
    } finally {
      _flushing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(flush());
    }
  }

  Map<String, Object?>? _readSnapshot() {
    final raw = prefs.getString(kSpellSyncSnapshotKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSnapshotIfChanged(
    Map<String, Object?>? before,
    Map<String, Object?> after,
  ) async {
    if (before != null && sameFirestoreValue(before, after)) return;
    await prefs.setString(kSpellSyncSnapshotKey, jsonEncode(after));
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }
}
