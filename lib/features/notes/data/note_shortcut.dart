import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show StringCharacters;

import '../../../core/error_log.dart';

/// **ANA EKRANA YERLEŞTİR** (kullanıcı isteği 2026-10-28, örnek uygulamanın
/// not menüsündeki "Ana ekrana yerleştir"): notu telefonun başlatıcısına
/// sabit kısayol olarak koyar; dokununca not doğrudan açılır
/// (`notlar://note/<id>`, bkz. NotKisayolu.kt ve router.dart).
abstract final class NoteShortcut {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  /// Yalnız Android (web'de/masaüstünde başlatıcı kısayolu yok).
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Simgedeki harf: başlığın (yoksa gövdenin) ilk görünür karakteri.
  @visibleForTesting
  static String glyphOf(String title, String body) {
    for (final source in [title, body]) {
      final trimmed = source.replaceAll(RegExp(r'[*_~=#%&\s]'), '');
      if (trimmed.isEmpty) continue;
      return trimmed.characters.first.toUpperCase();
    }
    return 'N';
  }

  /// Başlatıcıya kısayol isteği gönderir. Başlatıcı onay penceresini kendisi
  /// gösterir; true = istek iletildi, false = desteklenmiyor/başarısız.
  static Future<bool> pin({
    required String id,
    required String title,
    required String body,
    required int color,
  }) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('pinNoteShortcut', {
            'id': id,
            'label': title.trim(),
            'color': color,
            'glyph': glyphOf(title, body),
          }) ??
          false;
    } catch (e, s) {
      ErrorLog.record('note shortcut', e, s);
      return false;
    }
  }
}
