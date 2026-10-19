import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// **CİHAZDAKİ HATA GÜNLÜĞÜ** (F1.9, 2026-10-19). Yakalanmayan hatalar
/// (`FlutterError.onError`, `PlatformDispatcher.onError`) ve yutulan yazım
/// hataları (ör. Firestore reddi) son [capacity] kayıtlık bir halka
/// tamponda tutulur ve dosyaya yazılır. Hiçbir yere kendiliğinden gitmez:
/// Ayarlar → Hakkında → "Hata günlüğünü paylaş" ile kullanıcı gönderir.
///
/// Web'de Crashlytics yok — oradaki tek kayıt budur. Web'de
/// dosya yok, kayıtlar oturum boyunca bellekte.
class ErrorLog {
  ErrorLog._();

  static const capacity = 200;

  /// Tek kaydın en fazla uzunluğu (uzun yığınlar dosyayı şişirmesin).
  static const maxEntryChars = 4000;

  static final List<ErrorLogEntry> _entries = [];
  static File? _file;
  static Timer? _flush;

  static List<ErrorLogEntry> get entries => List.unmodifiable(_entries);

  /// Günlük dosyasını [dir] altında açar ve önceki kayıtları okur. Açılışta
  /// bir kez; çağrılmazsa günlük yalnız bellekte tutulur.
  static Future<void> attach(String dir) async {
    if (kIsWeb) return;
    try {
      final file = File('$dir${Platform.pathSeparator}error_log.jsonl');
      _file = file;
      if (!await file.exists()) return;
      final lines = await file.readAsLines();
      final loaded = <ErrorLogEntry>[];
      for (final line in lines) {
        final e = ErrorLogEntry.tryParse(line);
        if (e != null) loaded.add(e);
      }
      _entries.insertAll(0, loaded);
      _trim();
    } catch (e) {
      debugPrint('Hata günlüğü okunamadı: $e');
    }
  }

  /// Bir hatayı kaydeder. [source]: nereden geldiği (ör. `flutter`,
  /// `platform`, `firestore-write`).
  static void record(String source, Object error, [StackTrace? stack]) {
    var text = '$error';
    if (stack != null) text = '$text\n$stack';
    if (text.length > maxEntryChars) text = text.substring(0, maxEntryChars);
    _entries.add(
      ErrorLogEntry(time: DateTime.now(), source: source, message: text),
    );
    _trim();
    _scheduleFlush();
  }

  static void clear() {
    _entries.clear();
    _scheduleFlush();
  }

  /// Paylaşılacak düz metin (en yeni en üstte).
  static String exportText({String header = ''}) {
    final buf = StringBuffer();
    if (header.isNotEmpty) buf.writeln(header);
    for (final e in _entries.reversed) {
      buf
        ..writeln('[${e.time.toIso8601String()}] ${e.source}')
        ..writeln(e.message)
        ..writeln();
    }
    return buf.toString();
  }

  static void _trim() {
    if (_entries.length > capacity) {
      _entries.removeRange(0, _entries.length - capacity);
    }
  }

  /// Hata fırtınasında her kayıtta diske yazılmasın: kısa bir gecikmeyle
  /// toplu yazılır.
  static void _scheduleFlush() {
    if (_file == null) return;
    _flush?.cancel();
    _flush = Timer(const Duration(seconds: 2), () => unawaited(flush()));
  }

  static Future<void> flush() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.writeAsString(
        _entries.map((e) => e.toJson()).join('\n'),
        flush: true,
      );
    } catch (_) {
      // Günlük yazılamadıysa kendi hatasını günlüğe yazmaya çalışmak döngü
      // olurdu — sessiz.
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _entries.clear();
    _file = null;
    _flush?.cancel();
  }
}

class ErrorLogEntry {
  const ErrorLogEntry({
    required this.time,
    required this.source,
    required this.message,
  });

  final DateTime time;
  final String source;
  final String message;

  String toJson() =>
      jsonEncode({'t': time.millisecondsSinceEpoch, 's': source, 'm': message});

  static ErrorLogEntry? tryParse(String line) {
    try {
      final m = jsonDecode(line) as Map<String, dynamic>;
      return ErrorLogEntry(
        time: DateTime.fromMillisecondsSinceEpoch((m['t'] as num).toInt()),
        source: m['s'] as String? ?? '',
        message: m['m'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
