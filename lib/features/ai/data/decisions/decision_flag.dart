import 'package:flutter/foundation.dart';

import '../../../../core/play_build.dart';

/// Karar noktası kimlikleri = `config/app` bayrak dizilerindeki adlar
/// (plan §4.4, DA-16).
abstract final class DecisionFeature {
  /// DA-1 Hızlı ekle hedef notu.
  static const dropTarget = 'dropTarget';

  /// DA-2 Sessiz düzen (etiket/klasör/başlık/hatırlatıcı önerisi).
  static const noteTriage = 'noteTriage';

  /// DA-13 AI başlığı doğrulama.
  static const titleOk = 'titleOk';

  /// DA-14 Hızlı ekle yazım düzeltmesi doğrulama.
  static const spellFixOk = 'spellFixOk';
}

enum DecisionMode {
  /// Bugünkü yol AYNEN; ağ yok.
  off,

  /// Bugünkü yol AYNEN; karar yanında hesaplanır, yalnız günlüğe yazılır.
  shadow,

  /// Karar birincil; belirsiz/yanıtsızsa bugünkü yola düşülür.
  live,
}

/// **UZAKTAN BAYRAK** (plan §4.4): `config/app` alanları, VARSAYILAN KAPALI.
///  - `aiDecisionsFeatures`: dizi; listedeki özellik Decisions'ı birincil yapar.
///  - `aiDecisionsShadow`: dizi; gölge kip — YALNIZ kişisel derleme
///    (`!PlayBuild.enabled`; çift çağrı/çift veri gönderimi Play'de yok).
///  - `aiDecisionsModel`: dize; model adı sürüm çıkarmadan değişsin.
/// Alan yok / boş / bozuk = hiçbiri (bugünkü davranış). İstemci YAZMAZ;
/// değer [saveCadenceSyncProvider] dinleyicisinden gelir (kill switch kalıbı).
abstract final class AiDecisionsFlag {
  static const featuresField = 'aiDecisionsFeatures';
  static const shadowField = 'aiDecisionsShadow';
  static const modelField = 'aiDecisionsModel';
  static const defaultModel = 'gemini-decision-1';

  static Set<String> _live = const {};
  static Set<String> _shadow = const {};
  static String _model = defaultModel;

  static String get model => _model;

  static Set<String> _names(Object? v) => v is List
      ? {
          for (final e in v)
            if (e is String && e.isNotEmpty) e,
        }
      : const {};

  static void apply(Map<String, dynamic>? data) {
    _live = _names(data?[featuresField]);
    _shadow = PlayBuild.enabled ? const {} : _names(data?[shadowField]);
    final m = data?[modelField];
    _model = m is String && m.trim().isNotEmpty ? m.trim() : defaultModel;
  }

  static DecisionMode modeOf(String feature) => _live.contains(feature)
      ? DecisionMode.live
      : _shadow.contains(feature)
      ? DecisionMode.shadow
      : DecisionMode.off;

  @visibleForTesting
  static void debugReset() => apply(null);
}
