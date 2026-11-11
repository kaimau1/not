import 'package:flutter/gestures.dart' show PointerDeviceKind;

/// Mürekkep katmanı olan yüzeyler.
enum PenSurface {
  /// Not sayfası (editör gövdesinin üstündeki katman).
  page,

  /// Sabit (bölmedeki) belge.
  pinnedDoc,

  /// Sayfaya gömülü belge.
  embeddedDoc,

  /// Tam ekran görüntüleyici / belge notu (PDF, slayt, görsel).
  viewer,

  /// El yazısı çizim ekranı.
  drawing,

  /// Not paketi önizlemesi.
  package,
}

/// **KALEM KURALI — TEK DOĞRULUK TABLOSU** (OTURTMA F63.1; hedef davranış
/// `KALEM_PLANI.md` "Kurallar 1–4"). Kural eskiden dört yerde ayrı ayrı
/// yazılıydı (editör, sabit bölme, gömülü belge, not paketi) — B3/B4/B5
/// hataları kopyaların ayrışmasından çıktı. Saf işlev: girdiler dışında hiçbir
/// şeye bakmaz. Tablo `test/pen_policy_test.dart`'ta kilitli.
class PenPolicy {
  const PenPolicy({
    required this.allowedKinds,
    required this.fingerScrolls,
    required this.showFloatingToggle,
    required this.layerActive,
  });

  /// Yalnız bu girdiler çizer; null = hepsi. ("Yalnız kalem" ayrıca
  /// `InkController.accepts`'te parmağı durdurur.)
  final Set<PointerDeviceKind>? allowedKinds;

  /// Parmak çizmez: kaydırır / alttaki içeriğe gider.
  final bool fingerScrolls;

  /// Yüzen "kalem yazar / dokunur" düğmesi bu yüzeyde görünür mü.
  final bool showFloatingToggle;

  /// false = mürekkep katmanı hiç kurulmaz (basılı tut seçim parmakta kalsın).
  final bool layerActive;

  static const stylusKinds = {
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  /// [penMode]: yüzeyin açık kalem kipi (editörün kalem kipi, bölmenin ya da
  /// paketin kalem düğmesi, görüntüleyicide çizim kipi). [autoStylus]: yüzen
  /// düğme "kalem yazar". [stylusEver]: cihazda kalem görüldü. [penOnly]:
  /// "yalnız kalemle yaz".
  static PenPolicy resolve({
    required PenSurface surface,
    required bool penMode,
    required bool autoStylus,
    required bool stylusEver,
    required bool penOnly,
  }) {
    final Set<PointerDeviceKind>? kinds;
    final bool active;
    switch (surface) {
      case PenSurface.page:
        kinds = {
          if (penMode || autoStylus) ...stylusKinds,
          if (penMode) ...const [
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          ],
        };
        active = true;
      case PenSurface.pinnedDoc:
        kinds = penMode ? null : stylusKinds;
        // Kalemsiz cihazda otomatik katman yok: basılı tut + "Not al" parmakta.
        active = penMode || (autoStylus && stylusEver);
      case PenSurface.embeddedDoc:
        kinds = stylusKinds;
        active = autoStylus && stylusEver;
      case PenSurface.package:
        kinds = penMode ? null : stylusKinds;
        active = true;
      case PenSurface.viewer:
        // F63.4: sabit belgeyle aynı — çizim kipi herkesi çizdirir; kip
        // kapalıyken yüzen düğme "kalem yazar" ise yalnız kalem.
        kinds = penMode ? null : stylusKinds;
        active = penMode || (autoStylus && stylusEver);
      case PenSurface.drawing:
        kinds = null;
        active = true;
    }
    final fingerDraws =
        active &&
        !penOnly &&
        (kinds == null || kinds.contains(PointerDeviceKind.touch));
    return PenPolicy(
      allowedKinds: kinds,
      fingerScrolls: !fingerDraws,
      // Düğme editörün örtüsünde (sayfa + sabit + gömülü) ve tam ekran
      // görüntüleyicilerin kendi örtüsünde (`ViewerPen`).
      showFloatingToggle:
          stylusEver &&
          (surface == PenSurface.page ||
              surface == PenSurface.pinnedDoc ||
              surface == PenSurface.embeddedDoc ||
              surface == PenSurface.viewer),
      layerActive: active,
    );
  }
}
