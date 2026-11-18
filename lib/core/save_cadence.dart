import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notes/data/notes_delta_sync.dart';
import '../features/settings/settings_providers.dart';
import 'ai_kill_switch.dart';

/// **OTOMATİK KAYDIN BULUT SIKLIĞI** (senkron maliyeti planı S2 + korkuluk
/// 5, 2026-11-17).
///
/// Her otomatik kayıt bir Firestore YAZMASI ve (414 notta) ~21–27 ms Dart
/// işidir (kasma envanteri K-22). Sessizlik 2 sn kalır; aralıksız yazımda
/// üst sınır 10 → 20 sn: sürekli yazarken yazma sayısı yarıya iner. Çıkış
/// kapıları (kapanış, not değişimi, arka plan, `inactive`) eskisi gibi
/// HEMEN yazar; bedel: uygulama çökerse en çok ~20 sn'lik yazı.
///
/// **Uzaktan fren:** `config/app` belgesine (istemci yazamaz, herkes okur)
/// isteğe bağlı `saveDelaySec` ve `saveMaxWaitSec` sayıları yazılırsa yeni
/// açılan editörler onları kullanır (uygulama güncellemesi beklemeden;
/// fatura beklenmedik yükselirse). Alan yoksa varsayılan. Değerler
/// [apply]'da sınırlanır: sessizlik 2–120 sn, üst sınır sessizlik–300 sn.
abstract final class SaveCadence {
  static const defaultDelay = Duration(seconds: 2);
  static const defaultMaxWait = Duration(seconds: 20);

  static Duration _delay = defaultDelay;
  static Duration _maxWait = defaultMaxWait;

  static Duration get delay => _delay;
  static Duration get maxWait => _maxWait;

  /// `config/app` verisinden sıklığı kurar (alan yoksa varsayılan).
  static void apply(Map<String, dynamic>? data) {
    final d = (data?['saveDelaySec'] as num?)?.toInt();
    final m = (data?['saveMaxWaitSec'] as num?)?.toInt();
    final delaySec = d == null ? defaultDelay.inSeconds : d.clamp(2, 120);
    final maxSec = m == null
        ? _max(defaultMaxWait.inSeconds, delaySec)
        : m.clamp(delaySec, 300);
    _delay = Duration(seconds: delaySec);
    _maxWait = Duration(seconds: maxSec);
  }

  static int _max(int a, int b) => a > b ? a : b;

  @visibleForTesting
  static void reset() {
    _delay = defaultDelay;
    _maxWait = defaultMaxWait;
  }
}

/// `config/app`'i dinleyip [SaveCadence]'ı güncel tutar (AppServices).
/// Aynı dinleyici S1 bayrağını (`syncDeltaListen`) yerele yazar; ana liste
/// onu SONRAKİ açılışta okur (bkz. [SyncDeltaFlag]).
final saveCadenceSyncProvider = Provider<void>((ref) {
  // Firebase kurulmamışsa (testler, kurulum hatası) varsayılan kalır.
  if (Firebase.apps.isEmpty) return;
  final prefs = ref.read(sharedPreferencesProvider);
  final sub = FirebaseFirestore.instance
      .collection('config')
      .doc('app')
      .snapshots()
      .listen(
        (d) {
          SaveCadence.apply(d.data());
          // PL2: AI acil kapatma aynı belgede — ayrı okuma yok.
          AiKillSwitch.apply(d.data());
          unawaited(SyncDeltaFlag.remember(d.data(), prefs));
        },
        onError: (Object e) => debugPrint('Kayıt sıklığı okunamadı: $e'),
      );
  ref.onDispose(() => unawaited(sub.cancel()));
});
