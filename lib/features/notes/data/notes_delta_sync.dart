import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/note.dart' show kSyncAtField;

/// **S1 "YALNIZ DEĞİŞENİ DİNLE"** (P67, 17K raporu §1.3; 2026-11-17).
///
/// SORUN: ana liste `deletedAt == null` sorgusunu SUNUCUDAN dinler. Uygulama
/// 30 dk'dan uzun kapalı kaldıysa Firestore her açılışta sonuçtaki BÜTÜN
/// belgeleri yeniden okunmuş sayar (300 not → 300 okuma / açılış).
///
/// YENİ YOL (bayrakla, VARSAYILAN KAPALI):
/// 1. Liste aynı sorguyu yalnız YEREL ÖNBELLEKTEN dinler
///    (`ListenSource.cache` — sunucu okuması yok; yerel bekleyen yazımlar
///    da anında görünür).
/// 2. Önbelleğin ilk görüntüsünden imleç = en büyük `syncAt` (SUNUCU saati;
///    cihaz saati hiç kullanılmaz). Sunucuya yalnız
///    `syncAt > imleç − [kOverlap]` sorgusu bağlanır ("besleyici"); gelen
///    belgeler önbelleğe yazılır, 1. adımdaki dinleyici onları gösterir.
///    Çöpe atma da bir yazım (`deletedAt` + damga) → besleyiciye girer.
/// 3. Güvenlik ağı: sunucudan `count()` (1000 belge başına 1 okuma)
///    önbellekteki sayıyla karşılaştırılır. Tutmazsa (başka cihazda kalıcı
///    silme, önbellekten atılmış belge, yeni yazılmamış not) ESKİ YOLA döner.
///
/// ESKİ YOLA DÖNÜŞ (bugünkü davranışın AYNISI: sorgu sunucudan dinlenir):
/// önbellek boş (ilk açılış, hesap değişimi, web'de temiz sekme) · hiçbir
/// belgede damga yok · imleç [kMaxCursorAge]'den eski · sayım alınamadı
/// (çevrimdışı/hata/zaman aşımı) ya da tutmadı · besleyici hata verdi.
/// Bu kararlar akış başına bir kez verilir (açılış, hesap değişimi).
///
/// BİLİNEN SINIR: oturum SÜRERKEN başka cihazda KALICI silinen (çöpten
/// değil doğrudan — "senkronu kapat" ile buluttan kaldırılan) ve besleyicide
/// olmayan not bu oturumun sonuna dek listede kalır; sonraki açılışta sayım
/// tutmaz → eski yol. Çöp kutusundan kalıcı silme listeyi etkilemez (not
/// zaten çöpteydi).
enum NotesFeedMode { delta, legacy }

/// Uzaktan bayrak + yerel geri alma.
abstract final class SyncDeltaFlag {
  /// `config/app` alanı (istemci yazamaz, herkes okur). Yalnız `true`
  /// açar; alan yok/başka değer = kapalı.
  static const remoteKey = 'syncDeltaListen';

  /// Son görülen uzak değer: akış kurulurken eşzamanlı okunabilsin diye
  /// yerelde tutulur → bayrak değişikliği SONRAKİ açılışta geçerli.
  static const prefKey = 'sync_delta_listen';

  /// Yerel geri alma: true ise uzak bayrak açık olsa da eski yol.
  static const offKey = 'sync_delta_off';

  static bool enabled(SharedPreferences prefs) =>
      (prefs.getBool(prefKey) ?? false) && !(prefs.getBool(offKey) ?? false);

  /// `config/app` verisini yerele yazar (değiştiyse).
  static Future<void> remember(
    Map<String, dynamic>? config,
    SharedPreferences prefs,
  ) async {
    final on = config?[remoteKey] == true;
    if ((prefs.getBool(prefKey) ?? false) != on) {
      await prefs.setBool(prefKey, on);
    }
  }
}

/// Akışın bir yayını. [reset] = önceki belgeleri unut (yol değişti; yeni
/// dinleyicinin ilk görüntüsü bütün listeyi "added" olarak getirir).
class NotesFeedEvent {
  const NotesFeedEvent(this.snapshot, {this.reset = false});
  final QuerySnapshot<Map<String, dynamic>> snapshot;
  final bool reset;
}

/// Okuma muhasebesi (testler ve tanı için). Sunucudan gelen (önbellekten
/// olmayan) görüntülerdeki belge değişiklikleri faturalanan okumanın
/// üst tahminidir; `count()` 1000 belge başına 1 okuma.
class NotesFeedStats {
  NotesFeedMode mode = NotesFeedMode.delta;
  String reason = '';
  int docReads = 0;
  int countReads = 0;
  int get totalReads => docReads + countReads;

  @override
  String toString() =>
      '${mode.name} ($reason): $docReads belge + $countReads sayım okuması';
}

/// Sunucudan sayım. null = alınamadı.
typedef ServerCount = Future<int?> Function(Query<Map<String, dynamic>> q);

Future<int?> _defaultServerCount(Query<Map<String, dynamic>> q) async {
  final s = await q.count().get();
  return s.count;
}

/// Ana not listesinin S1 akışı. Bkz. dosya başı.
class NotesDeltaFeed {
  NotesDeltaFeed(
    this._notes, {
    DateTime Function()? now,
    ServerCount? serverCount,
    @visibleForTesting this.cacheSource = ListenSource.cache,
    @visibleForTesting CollectionReference<Map<String, dynamic>>? cacheNotes,
  }) : _cacheNotes = cacheNotes ?? _notes,
       _now = now ?? DateTime.now,
       _serverCount = serverCount ?? _defaultServerCount;

  /// İmleç örtüşmesi: aynı anda işlenen yazımların damga sırası ile
  /// görünürlük sırası arasındaki küçük fark için. Bedeli yalnız son
  /// 10 dk'da değişen notların bir kez daha okunması.
  static const kOverlap = Duration(minutes: 10);

  /// İmleç bundan eskiyse eski yol: çöpün 30 günlük kalıcı silmesi.
  static const kMaxCursorAge = Duration(days: 30);

  static const kCountTimeout = Duration(seconds: 20);

  final CollectionReference<Map<String, dynamic>> _notes;

  /// Testte "cihaz önbelleği"ni ayrı bir sahte veritabanıyla taklit etmek
  /// için (sahte Firestore önbellek/sunucu ayrımı yapmaz). Uygulamada
  /// [_notes]'un kendisi.
  final CollectionReference<Map<String, dynamic>> _cacheNotes;
  final DateTime Function() _now;
  final ServerCount _serverCount;
  final ListenSource cacheSource;

  final stats = NotesFeedStats();

  Query<Map<String, dynamic>> get _live =>
      _notes.where('deletedAt', isNull: true);

  /// Önbellekteki görüntüden imleç: en büyük SUNUCU damgası. Bekleyen
  /// (sunucuya ulaşmamış) yazımda damga null gelir, sayılmaz.
  @visibleForTesting
  static Timestamp? cursorOf(Iterable<Map<String, dynamic>?> docs) {
    Timestamp? max;
    for (final d in docs) {
      final t = d?[kSyncAtField];
      if (t is Timestamp && (max == null || t.compareTo(max) > 0)) max = t;
    }
    return max;
  }

  Stream<NotesFeedEvent> events() {
    late StreamController<NotesFeedEvent> out;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? cacheSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legacySub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? feederSub;
    var planned = false;
    var legacy = false;
    var closed = false;

    void toLegacy(String reason) {
      if (legacy || closed) return;
      legacy = true;
      stats
        ..mode = NotesFeedMode.legacy
        ..reason = reason;
      debugPrint('Not akışı eski yola döndü: $reason');
      unawaited(feederSub?.cancel());
      feederSub = null;
      unawaited(cacheSub?.cancel());
      var first = true;
      // BUGÜNKÜ YOL: sorgu sunucudan dinlenir.
      legacySub = _live.snapshots().listen((s) {
        if (!s.metadata.isFromCache) stats.docReads += s.docChanges.length;
        out.add(NotesFeedEvent(s, reset: first));
        first = false;
      }, onError: out.addError);
    }

    Future<void> checkCount(int cachedCount) async {
      int? server;
      try {
        server = await _serverCount(_live).timeout(kCountTimeout);
        stats.countReads += 1 + (server ?? 0) ~/ 1000;
      } catch (e) {
        server = null;
      }
      if (closed || legacy) return;
      if (server == null) {
        toLegacy('sayım alınamadı');
      } else if (server != cachedCount) {
        toLegacy('sayım tutmadı: sunucu $server, önbellek $cachedCount');
      }
    }

    void plan(QuerySnapshot<Map<String, dynamic>> first) {
      planned = true;
      if (first.docs.isEmpty) return toLegacy('önbellek boş');
      final cursor = cursorOf(first.docs.map((d) => d.data()));
      if (cursor == null) return toLegacy('damgalı belge yok');
      // Cihaz saati İLERİDEYSE gereksiz yere eski yol (güvenli taraf);
      // GERİDEYSE sayım ağı yakalar. İmlecin kendisi sunucu saati.
      if (_now().difference(cursor.toDate()) > kMaxCursorAge) {
        return toLegacy('imleç 30 günden eski');
      }
      final from = Timestamp.fromDate(cursor.toDate().subtract(kOverlap));
      stats
        ..mode = NotesFeedMode.delta
        ..reason = 'imleç ${cursor.toDate().toIso8601String()}';
      feederSub = _notes
          .where(kSyncAtField, isGreaterThan: from)
          .snapshots()
          .listen((s) {
            // Veri kullanılmaz: önbelleğe yazılır, önbellek dinleyicisi
            // gösterir. Yalnız muhasebe.
            if (!s.metadata.isFromCache) {
              stats.docReads += s.docChanges.length;
            }
          }, onError: (Object e) => toLegacy('besleyici hata: $e'));
      unawaited(checkCount(first.size));
    }

    out = StreamController<NotesFeedEvent>(
      onListen: () {
        var first = true;
        cacheSub = _cacheNotes
            .where('deletedAt', isNull: true)
            .snapshots(source: cacheSource)
            .listen(
              (s) {
                if (legacy) return;
                if (!planned) {
                  plan(s);
                  if (legacy) return;
                }
                out.add(NotesFeedEvent(s, reset: first));
                first = false;
              },
              onError: (Object e) => toLegacy('önbellek dinleyicisi hata: $e'),
            );
        // İlk görüntü eşzamanlı geldiyse ve eski yola dönüldüyse.
        if (legacy) unawaited(cacheSub?.cancel());
      },
      onCancel: () async {
        closed = true;
        await feederSub?.cancel();
        await cacheSub?.cancel();
        await legacySub?.cancel();
      },
    );
    return out.stream;
  }
}
