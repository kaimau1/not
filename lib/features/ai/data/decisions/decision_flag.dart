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

  /// D1 Alışveriş ürünü reyon eşleme (kalıcı önbellekli).
  static const shopAisle = 'shopAisle';

  /// D3 Tek cümle niyet yönlendirici (alışveriş / görev / etkinlik / not).
  static const captureRoute = 'captureRoute';

  /// D5 Akıllı liste türü sınıflama (kalıcı önbellekli).
  static const listClassify = 'listClassify';
}

enum DecisionMode {
  /// Bugünkü yol AYNEN; ağ yok.
  off,

  /// Bugünkü yol AYNEN; karar yanında hesaplanır, yalnız günlüğe yazılır.
  shadow,

  /// Karar birincil; belirsiz/yanıtsızsa bugünkü yola düşülür.
  live,
}

/// **UZAKTAN BAYRAK** (plan §4.4): `config/app` alanları.
///  - `aiDecisionsFeatures`: dizi; listedeki özellik Decisions'ı birincil yapar.
///    Alan YOKSA [defaultLive] canlı (kullanıcı kararı 2026-11-22: yazım
///    doğrulaması hariç hepsi); boş dizi `[]` = hepsi kapalı (uzaktan kapatma).
///  - `aiDecisionsShadow`: dizi; gölge kip — YALNIZ kişisel derleme
///    (`!PlayBuild.enabled`; çift çağrı/çift veri gönderimi Play'de yok).
///  - `aiDecisionsModel`: dize; model adı sürüm çıkarmadan değişsin.
/// Gölge alanı yok / boş / bozuk = hiçbiri. İstemci YAZMAZ;
/// değer [saveCadenceSyncProvider] dinleyicisinden gelir (kill switch kalıbı).
abstract final class AiDecisionsFlag {
  static const featuresField = 'aiDecisionsFeatures';
  static const shadowField = 'aiDecisionsShadow';
  static const modelField = 'aiDecisionsModel';
  static const defaultModel = 'gemini-decision-1';

  /// `aiDecisionsFeatures` alanı yok ya da dizi değilse canlı olanlar.
  /// Yazım doğrulaması (`spellFixOk`) bilerek YOK: ECE 0,15 > 0,10.
  static const Set<String> defaultLive = {
    DecisionFeature.dropTarget,
    DecisionFeature.noteTriage,
    DecisionFeature.titleOk,
    DecisionFeature.shopAisle,
    DecisionFeature.captureRoute,
    DecisionFeature.listClassify,
  };

  static Set<String> _live = defaultLive;
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
    final live = data?[featuresField];
    _live = live is List ? _names(live) : defaultLive;
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
