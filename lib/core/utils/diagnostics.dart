import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Hata ayıklama/profil derlemesinde teşhis sayaçları (F9.2). [enabled]
/// derleme sabiti: release'te sayaç kodu ağaçtan atılır.
abstract final class Diagnostics {
  static const enabled = kDebugMode || kProfileMode;

  /// Açık tek-not akışları (F5.1 doğrulaması: editör kapanınca düşmeli).
  static int openNoteStreams = 0;

  /// Sayaç satırı (Ayarlar → Hakkında; yalnız [enabled]).
  static String summary({required int thumbBytes}) {
    final cache = PaintingBinding.instance.imageCache;
    String mb(int b) => (b / (1 << 20)).toStringAsFixed(1);
    return 'Açık not akışı: $openNoteStreams · '
        'Kart küçük resmi: ${mb(thumbBytes)} MB · '
        'Görsel önbelleği: ${cache.currentSize} / '
        '${mb(cache.currentSizeBytes)} MB '
        '(tavan ${mb(cache.maximumSizeBytes)} MB)';
  }
}
