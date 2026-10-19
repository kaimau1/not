import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/local_file.dart';
import '../domain/note.dart';

/// **YALNIZ BU CİHAZDA TUTULAN NOTLAR** (kullanıcı isteği 2026-09-26:
/// "senkronizasyon kapatma nota özel").
///
/// Firestore'da bir belgeyi senkrondan "hariç tutmanın" yolu yok: çevrimdışı
/// önbellek de bekleyen yazımları ilk fırsatta sunucuya gönderir. Bu yüzden
/// senkronu kapatılan not Firestore'dan ÇIKARILIR ve burada, cihazdaki bir
/// JSON dosyasında yaşar. `NotesRepository` kimliğe bakıp yazımları buraya
/// yönlendirir, akışlar iki kaynağı birleştirir — ekranların geri kalanı
/// notun nerede durduğunu bilmez ([Note.localOnly] yalnız rozet için).
///
/// Kayıtlar Firestore BİÇİMİNDE tutulur (`Note.toMap()`'in çıktısı):
/// `Note.fromMap` iki kaynağı aynı yoldan okur, alan eklemek tek yerde kalır.
/// Diskte `Timestamp` → `{"__ts": ms}`.
///
/// Kullanıcı (uid) başına ayrı dosya; web'de dosya sistemi yok → özellik
/// kapalı ([forUid] null döner).
class LocalNotesStore {
  LocalNotesStore._(this._file) {
    _load();
  }

  /// Testler için: dosya yolu verilerek kurulur.
  @visibleForTesting
  LocalNotesStore.atPath(String path) : _file = File(path) {
    _load();
  }

  static final Map<String, LocalNotesStore> _instances = {};

  /// [uid]in deposu; web'de ya da destek klasörü çözülemediyse null.
  static LocalNotesStore? forUid(String uid) {
    if (kIsWeb) return null;
    final base = appSupportPath;
    if (base == null) return null;
    return _instances.putIfAbsent(
      uid,
      () => LocalNotesStore._(File(p.join(base, 'local_notes_$uid.json'))),
    );
  }

  /// Bütün açık depoları diske yazar (uygulama arka plana geçerken).
  static Future<void> flushAll() async {
    for (final store in _instances.values) {
      await store.flush();
    }
  }

  final File _file;
  final Map<String, Map<String, dynamic>> _docs = {};
  final _changes = StreamController<void>.broadcast();
  Timer? _saveTimer;

  /// Değişiklik olduğunda bir olay (içerik yok — okuyan [notes]'a bakar).
  Stream<void> get changes => _changes.stream;

  bool get isEmpty => _docs.isEmpty;

  bool contains(String id) => _docs.containsKey(id);

  /// SENKRON okuma, BİLEREK: depo ilk kez istendiğinde (not deposu
  /// kurulurken) içerik HAZIR olmalı. Asenkron yüklenseydi açılışın ilk
  /// anlarında yerel bir nota yapılan yazım "yerel değil" sanılıp Firestore'a
  /// gider ve bulutta yarım bir hayalet not doğardı.
  void _load() {
    try {
      if (!_file.existsSync()) return;
      final raw = jsonDecode(_file.readAsStringSync());
      if (raw is! Map) return;
      for (final e in raw.entries) {
        final value = _decode(e.value);
        if (value is Map<String, dynamic>) _docs[e.key.toString()] = value;
      }
    } catch (_) {
      // Bozuk dosya: yedeği bırak, boş başla (sessizce üstüne yazılmasın).
      try {
        _file.copySync('${_file.path}.bozuk');
      } catch (_) {}
    }
  }

  /// Silinmemiş (ya da [deleted] ise silinmiş) notlar.
  List<Note> notes({bool deleted = false}) => [
    for (final e in _docs.entries)
      if ((e.value['deletedAt'] != null) == deleted) _parsed(e.key, e.value),
  ];

  /// Ayrıştırılmış not önbelleği — anahtar kayıt haritasının KİMLİĞİ: her
  /// yazım haritayı yenisiyle değiştirdiği için ([_resolve]) değişmeyen
  /// notlar AYNI `Note` örneği kalır. Ana ekranın türetilmiş sağlayıcıları
  /// (F2.1) değişmeyen listeyi örnek kimliğiyle tanır; her yayında bütün
  /// yerel notlar yeniden ayrıştırılırsa her kart yeniden kurulurdu.
  final Map<String, (Map<String, dynamic>, Note)> _parsedCache = {};

  Note _parsed(String id, Map<String, dynamic> map) {
    final hit = _parsedCache[id];
    if (hit != null && identical(hit.$1, map)) return hit.$2;
    final note = Note.fromMap(id, map, localOnly: true);
    _parsedCache[id] = (map, note);
    return note;
  }

  Note? note(String id) {
    final map = _docs[id];
    return map == null ? null : Note.fromMap(id, map, localOnly: true);
  }

  /// Notun kaydını BÜTÜNÜYLE koyar (senkronu kapatırken).
  void put(String id, Map<String, dynamic> firestoreMap) {
    _docs[id] = _resolve(firestoreMap, const {});
    _changed(immediate: true);
  }

  /// Firestore'daki `set(merge: true)` karşılığı: verilen alanlar üstüne
  /// yazılır (sığ), `FieldValue.serverTimestamp()` şimdiye, `delete()`
  /// alanın silinmesine çevrilir.
  void merge(String id, Map<String, dynamic> fields) {
    final current = _docs[id];
    if (current == null) return;
    _docs[id] = _resolve(fields, current);
    _changed();
  }

  /// Birden çok notu TEK değişiklik bildirimiyle birleştirir (toplu
  /// işlemler — bkz. `NotesRepository.batchUpdateEach`).
  void mergeAll(Map<String, Map<String, dynamic>> fieldsById) {
    var any = false;
    for (final e in fieldsById.entries) {
      final current = _docs[e.key];
      if (current == null) continue;
      _docs[e.key] = _resolve(e.value, current);
      any = true;
    }
    if (any) _changed();
  }

  void remove(String id) {
    _parsedCache.remove(id);
    if (_docs.remove(id) != null) _changed(immediate: true);
  }

  /// Silinen bir klasörü notlardan düşürür (Firestore'daki toplu
  /// `folderId: null` yazımının yerel karşılığı).
  void clearFolder(String folderId) {
    var any = false;
    for (final e in _docs.entries.toList()) {
      if (e.value['folderId'] == folderId) {
        // Yerinde değiştirme YOK: ayrıştırma önbelleği haritanın kimliğine
        // bakıyor (bkz. [_parsed]).
        _docs[e.key] = {...e.value, 'folderId': null};
        any = true;
      }
    }
    if (any) _changed();
  }

  /// Hepsini siler (hesap silinirken).
  Future<void> clearAll() async {
    _docs.clear();
    _parsedCache.clear();
    _changed(immediate: true);
    await flush();
  }

  Map<String, dynamic> _resolve(
    Map<String, dynamic> fields,
    Map<String, dynamic> base,
  ) {
    final out = Map<String, dynamic>.from(base);
    for (final e in fields.entries) {
      final v = e.value;
      if (v == FieldValue.delete()) {
        out.remove(e.key);
      } else if (v == FieldValue.serverTimestamp()) {
        out[e.key] = Timestamp.now();
      } else if (v is FieldValue) {
        // arrayUnion vb. yerel depoda desteklenmiyor: çağıranlar
        // `NotesRepository.appendAttachments`'ı kullanır.
        assert(false, 'LocalNotesStore: desteklenmeyen FieldValue $v');
      } else {
        out[e.key] = _deepResolve(v);
      }
    }
    return out;
  }

  /// İç içe haritalardaki (ör. `aiSummary.createdAt`) sunucu damgaları.
  dynamic _deepResolve(dynamic v) {
    if (v == FieldValue.serverTimestamp()) return Timestamp.now();
    if (v is Map) {
      return {
        for (final e in v.entries) e.key.toString(): _deepResolve(e.value),
      };
    }
    if (v is List) return [for (final x in v) _deepResolve(x)];
    return v;
  }

  void _changed({bool immediate = false}) {
    _changes.add(null);
    _saveTimer?.cancel();
    if (immediate) {
      unawaited(flush());
    } else {
      // Yazarken her tuşta disk yazımı olmasın.
      _saveTimer = Timer(const Duration(milliseconds: 600), () {
        unawaited(flush());
      });
    }
  }

  /// Bekleyen değişiklikleri diske yazar. Önce geçici dosyaya, sonra
  /// yeniden adlandırma: yazım yarıda kesilirse eski dosya sağlam kalır.
  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      final json = jsonEncode({
        for (final e in _docs.entries) e.key: _encode(e.value),
      });
      final tmp = File('${_file.path}.tmp');
      await tmp.parent.create(recursive: true);
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(_file.path);
    } catch (_) {
      // Disk dolu vb.: bir sonraki değişiklikte yeniden denenir.
    }
  }

  static dynamic _encode(dynamic v) {
    if (v is Timestamp) return {'__ts': v.millisecondsSinceEpoch};
    if (v is DateTime) return {'__ts': v.millisecondsSinceEpoch};
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): _encode(e.value)};
    }
    if (v is List) return [for (final x in v) _encode(x)];
    return v;
  }

  static dynamic _decode(dynamic v) {
    if (v is Map) {
      if (v.length == 1 && v['__ts'] is int) {
        return Timestamp.fromMillisecondsSinceEpoch(v['__ts'] as int);
      }
      return <String, dynamic>{
        for (final e in v.entries) e.key.toString(): _decode(e.value),
      };
    }
    if (v is List) return [for (final x in v) _decode(x)];
    return v;
  }
}
