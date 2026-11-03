import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **BİR KEZ ÇIKAN İPUÇLARI** (F14.6, 2026-10-31; plandaki öneri uygulandı:
/// dört jest + oturumda en fazla bir ipucu).
///
/// Uygulamada en az on görünmez jest var (madde çizme, PDF'e basılı tutma,
/// medyayı yukarı sürükleme, ızgarada yana kaydırma…). İpucu, iş İLK KEZ
/// mümkün olduğunda bağlamında tek satır çıkar; gösterilenler CİHAZDA
/// tutulur (hesaba bağlı değil — her cihazda bir kez görmek doğru), Ayarlar
/// → "İpuçlarını yeniden göster" hepsini sıfırlar.
///
/// Oturum sınırı: kullanıcı aynı açılışta art arda ipucu görmesin. Az önce
/// OLAN bir şeyi açıklayan bildirim (kalem tuvali açtı) sınırı aşabilir —
/// [TipOnce.show] `sessionLimit: false`.
abstract final class TipOnce {
  static const prefsKey = 'tips_shown';

  /// Liste notu ilk açıldı: madde jestleri.
  static const listGestures = 'list_gestures';

  /// İlk PDF/sunum notu: basılı tut → balon.
  static const pdfBubble = 'pdf_bubble';

  /// Notta ilk görsel: yukarı sürükle → üste sabitle.
  static const mediaPin = 'media_pin';

  /// Üste sabit PDF: yazıya basılı tut → "Not al" (2026-11-03).
  static const pdfReadNote = 'pdf_read_note';

  /// İlk ızgara + klasör: ekranı yana kaydır → klasörler arası.
  static const gridSwipe = 'grid_swipe';

  /// Kalem metin notunda el yazısı tuvalini açtı (F14.4).
  static const stylusCanvas = 'stylus_canvas';

  /// Arama kutusundaki "Anlam" anahtarı ilk kez göründü (F14.4).
  static const semanticSearch = 'semantic_search';

  static bool _sessionUsed = false;

  /// Bu ipucu gösterilmeli mi? (Gösterilmemiş ve — sınırlıysa — bu
  /// oturumda başka ipucu çıkmamış.)
  static bool due(
    SharedPreferences prefs,
    String id, {
    bool sessionLimit = true,
  }) {
    if (sessionLimit && _sessionUsed) return false;
    return !(prefs.getStringList(prefsKey) ?? const []).contains(id);
  }

  /// Gösterildi say (kalıcı) ve oturum hakkını kullan.
  static void markShown(SharedPreferences prefs, String id) {
    _sessionUsed = true;
    final shown = {...?prefs.getStringList(prefsKey), id};
    prefs.setStringList(prefsKey, shown.toList()..sort()).ignore();
  }

  /// İpucunu gerekiyorsa en yakın messenger'da tek satır gösterir. true =
  /// gösterildi.
  static bool show(
    BuildContext context,
    SharedPreferences prefs,
    String id,
    String text, {
    bool sessionLimit = true,
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!due(prefs, id, sessionLimit: sessionLimit)) return false;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return false;
    markShown(prefs, id);
    final scheme = Theme.of(context).colorScheme;
    messenger.showSnackBar(
      SnackBar(
        key: ValueKey('tip-$id'),
        duration: duration,
        content: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 18,
              color: scheme.inversePrimary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
    return true;
  }

  /// Ayarlar → "İpuçlarını yeniden göster".
  static Future<void> resetAll(SharedPreferences prefs) async {
    _sessionUsed = false;
    await prefs.remove(prefsKey);
  }

  /// Testler arası oturum sınırını sıfırlar.
  @visibleForTesting
  static void resetSession() => _sessionUsed = false;
}
