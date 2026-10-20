import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/presentation/capture_mode_sheet.dart';
import '../settings_providers.dart';

/// **AYAR SENKRONU** (F4.5, 2026-10-19).
///
/// Tercihler SharedPreferences'ta, yani yalnız cihazda duruyordu; telefon ve
/// web ayrı ayrı ayarlanıyordu. Aşağıdaki "kişiye ait" tercihler kullanıcı
/// belgesine (`users/{uid}/meta/prefs` → `values`) yansıtılır. CİHAZA ÖZGÜ
/// olanlar (Drive bağlantısı, ek boyutu sınırı, ana ekran arka plan dosyası,
/// cihaz sesi, çökme raporu, bildirim izni, bölme genişliği…) listede YOK.
///
/// Yöntem: son eşitlenen değerlerin yerel ANLIK GÖRÜNTÜSÜ tutulur
/// ([planPrefsSync]). Yerelde anlık görüntüden farklılaşan anahtar buluta
/// gider; bulutta farklılaşan (ve yerelde dokunulmamış) anahtar yerele
/// yazılır. Cihazın İLK eşitlemesinde bulut kazanır — yeni kurulan web'in
/// varsayılanları telefonun ayarlarını ezmesin.
const kSyncedPrefKeys = <String>[
  'theme_mode',
  'app_locale',
  'font_scale',
  'app_font',
  'dark_schedule_enabled',
  'dark_schedule_start',
  'dark_schedule_end',
  'tts_engine',
  'model_tts',
  'tts_gemini_voice',
  'auto_title',
  'auto_tag',
  'ai_skip_checked',
  'expand_list_items',
  'quick_capture_row',
  'card_rich_preview',
  'voice_button_mode',
  'voice_auto_stop',
  'voice_silence',
  'voice_smart_commands',
  'home_mic_dictate',
  'briefing_enabled',
  'briefing_minutes',
  'assistant_voice',
  captureModeDefaultKey,
  'user_templates_v1',
];

/// AI görev modeli anahtarları da eşitlenir (bkz. [AiTask]).
List<String> get syncedPrefKeys => [
  ...kSyncedPrefKeys,
  for (final task in AiTask.values) task.prefsKey,
];

const _snapshotKey = 'prefs_sync_snapshot';

/// Eşitleme planı (saf, test edilir).
///
/// [snapshot] null = bu cihaz hiç eşitlenmedi.
({
  Map<String, Object> apply,
  Map<String, Object> push,
  Set<String> remove,
  Map<String, Object> snapshot,
})
planPrefsSync({
  required Map<String, Object> local,
  required Map<String, Object?>? snapshot,
  required Map<String, Object?> remote,
}) {
  final apply = <String, Object>{};
  final push = <String, Object>{};
  final remove = <String>{};
  final next = <String, Object>{};
  final keys = {...local.keys, ...remote.keys, ...?snapshot?.keys};
  for (final key in keys) {
    final l = local[key];
    final r = remote[key];
    if (snapshot == null) {
      // İlk eşitleme: bulutta varsa bulut kazanır, yoksa yerel yüklenir.
      if (r != null) {
        if (!_same(l, r)) apply[key] = r;
        next[key] = r;
      } else if (l != null) {
        push[key] = l;
        next[key] = l;
      }
      continue;
    }
    final s = snapshot[key];
    if (l != null && !_same(l, s)) {
      if (!_same(l, r)) push[key] = l;
      next[key] = l;
    } else if (r != null && !_same(r, s)) {
      if (!_same(l, r)) apply[key] = r;
      next[key] = r;
    } else if (l == null && s != null && r != null) {
      // Yerelde SİLİNDİ (varsayılana dönüldü): buluttan da silinir.
      remove.add(key);
    } else if (l != null) {
      next[key] = l;
    }
  }
  return (apply: apply, push: push, remove: remove, snapshot: next);
}

bool _same(Object? a, Object? b) {
  if (a is List && b is List) return listEquals(a, b);
  if (a is num && b is num) return a == b;
  return a == b;
}

/// Tercih değeri yerelden okunur ([SharedPreferences.get] tür korur).
Map<String, Object> readLocalPrefs(SharedPreferences prefs) => {
  for (final key in syncedPrefKeys)
    if (prefs.get(key) case final Object value) key: value,
};

/// Buluttan gelen değeri yerele yazar (Firestore türü → prefs türü).
Future<void> writeLocalPref(
  SharedPreferences prefs,
  String key,
  Object value,
) async {
  switch (value) {
    case final bool v:
      await prefs.setBool(key, v);
    case final int v:
      await prefs.setInt(key, v);
    case final double v:
      await prefs.setDouble(key, v);
    case final String v:
      await prefs.setString(key, v);
    case final List<dynamic> v:
      await prefs.setStringList(key, [for (final e in v) '$e']);
  }
}

/// Oturum açıkken ayakta durur (bkz. AppServices).
final prefsSyncProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return;
  final sync = _PrefsSync(
    ref.read(sharedPreferencesProvider),
    FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('meta')
        .doc('prefs'),
    onApplied: () => ref.read(prefsRevisionProvider.notifier).bump(),
  );
  ref.onDispose(sync.dispose);
});

class _PrefsSync with WidgetsBindingObserver {
  _PrefsSync(this._prefs, this._doc, {required this.onApplied}) {
    _sub = _doc.snapshots().listen((snap) {
      final values = snap.data()?['values'];
      _remote = values is Map ? Map<String, Object?>.from(values) : {};
      unawaited(_run());
    }, onError: (Object e) => debugPrint('Ayar senkronu dinlenemedi: $e'));
    // Ayar değişikliği bir dokunuştur; kısa aralıkla yoklamak yeter (prefs
    // yazımları kodun her yerinde, tek kancası yok).
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _run());
    WidgetsBinding.instance.addObserver(this);
  }

  final SharedPreferences _prefs;
  final DocumentReference<Map<String, dynamic>> _doc;
  final VoidCallback onApplied;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _timer;
  Map<String, Object?>? _remote;
  bool _running = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) unawaited(_run());
  }

  Future<void> _run() async {
    final remote = _remote;
    // Bulut belgesi henüz okunmadı: ilk eşitleme bulutu beklemeli.
    if (remote == null || _running) return;
    _running = true;
    try {
      final raw = _prefs.getString(_snapshotKey);
      final plan = planPrefsSync(
        local: readLocalPrefs(_prefs),
        snapshot: raw == null
            ? null
            : Map<String, Object?>.from(jsonDecode(raw) as Map),
        remote: remote,
      );
      for (final e in plan.apply.entries) {
        await writeLocalPref(_prefs, e.key, e.value);
      }
      if (plan.push.isNotEmpty || plan.remove.isNotEmpty) {
        await _doc.set({
          'values': {
            ...plan.push,
            for (final key in plan.remove) key: FieldValue.delete(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await _prefs.setString(_snapshotKey, jsonEncode(plan.snapshot));
      if (plan.apply.isNotEmpty) onApplied();
    } catch (e) {
      debugPrint('Ayar senkronu başarısız: $e');
    } finally {
      _running = false;
    }
  }

  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
