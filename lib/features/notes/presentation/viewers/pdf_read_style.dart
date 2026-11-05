import 'package:flutter/material.dart';

/// **PDF OKUMA GÖRÜNÜMÜNÜN TEK STİL KAYNAĞI** (F28.4, kullanıcı kararı
/// 2026-11-03: "sabit mod doğru; balonlu sabit moda benzetilsin").
///
/// Sabit bölme (`PinnedMediaPane` → `PdfPageBox(fitWidth)`) ile balonlu
/// belge (`pdfLayerParams` → pdfrx `PdfViewer`) aynı belgeyi iki ayrı
/// kodla çiziyordu ve pdfrx varsayılanları (gri zemin, 8 dp kenar boşluğu,
/// sayfa gölgesi) balonluda ayrı bir "kâğıt masa" görünümü veriyordu.
/// Ortak değerler artık burada: ikisi de aynı zemini, aynı kenar boşluğunu,
/// gölgesizliği buradan okur — biri değişirse öbürü ayrı kalamaz.
@immutable
class PdfReadStyle {
  const PdfReadStyle({required this.background});

  factory PdfReadStyle.of(BuildContext context) => PdfReadStyle(
    background: Theme.of(context).colorScheme.surfaceContainerHigh,
  );

  /// Sayfaların arkasındaki zemin.
  final Color background;

  /// Ekin araç satırı: sabit bölmenin çubuğu ve balonlu sayfa çubuğu AYNI
  /// zemin ve çizgi (F40.6).
  static Color barColor(ColorScheme scheme) => scheme.surfaceContainer;
  static BorderSide barLine(ColorScheme scheme) =>
      BorderSide(color: scheme.outlineVariant);

  /// Sayfa kenar boşluğu / sayfalar arası ince ayraç (dp). Sabit bölmede
  /// sayfa genişliğe oturur; balonluda ayraç yalnız sayfaları ayırır.
  static const double pageGap = 2;

  /// Sayfa gölgesi yok (sabit bölmede de yok).
  static const BoxShadow? pageShadow = null;

  @override
  bool operator ==(Object other) =>
      other is PdfReadStyle && other.background == background;

  @override
  int get hashCode => background.hashCode;
}
