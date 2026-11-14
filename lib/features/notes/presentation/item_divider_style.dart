import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/color_dot.dart';
import '../../../core/widgets/color_palette.dart';
import '../../../core/widgets/sheet_header.dart';
import '../domain/note_item.dart';
import '../../../app/theme/app_tokens.dart';
import 'divider_kind_picker.dart';

/// Madde altı ayırıcıyı ([ItemDivider]) çizer — editör satırı ve ana ekran
/// kartı aynı çizimi kullanır (yalnız temel kalınlık ve kenar payı farklı).
///
/// [baseWidth] düz çizginin varsayılan kalınlığı; noktalı çizgi ondan biraz
/// kalın çizilir (ince noktalar düz çizginin üstünde kayboluyordu).
void paintItemDivider(
  Canvas canvas, {
  required ItemDivider style,
  required Color fallbackColor,
  required double left,
  required double right,
  required double y,
  required double baseWidth,
}) {
  if (right <= left) return;
  final color = style.color == null ? fallbackColor : Color(style.color!);
  final dotted = style.kind == NoteItem.dividerDotted;
  final width = baseWidth * style.weight * (dotted ? 1.45 : 1);
  final paint = Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke
    ..strokeCap = dotted ? StrokeCap.round : StrokeCap.butt;
  // TEK ÇİZİM ÇAĞRISI (kullanıcı bulgusu 2026-11-13: "alt çizgi varken
  // madde altında kasma oluyor klavye açılırken"). KÖK NEDEN adayı: kesikli
  // ve noktalı çizgi satır başına 30–70 AYRI `drawLine` (noktada yuvarlak
  // uç), dalgalı çizgi 1,5 px adımlı ~250 noktalı yol çiziyordu. Impeller
  // her çizgi/yolu her karede yeniden üçgenler — klavye açılırken liste
  // kaydıkça görünen her ayırıcılı satırda bu iş her karede tekrarlanıyordu.
  // Artık her tür en çok bir `drawPoints`/`drawPath` (çift çizgi iki
  // `drawLine`); dalga yarım dalga başına tek eğri. Görünüş aynı.
  switch (style.kind) {
    case NoteItem.dividerDashed:
      final dash = 5 + 2.5 * width;
      final gap = 3 + 1.5 * width;
      final points = <Offset>[];
      for (var x = left; x < right; x += dash + gap) {
        points
          ..add(Offset(x, y))
          ..add(Offset(math.min(x + dash, right), y));
      }
      canvas.drawPoints(ui.PointMode.lines, points, paint);
    case NoteItem.dividerDotted:
      final step = math.max(5.0, width * 2.2);
      canvas.drawPoints(ui.PointMode.points, [
        for (var x = left; x < right; x += step) Offset(x, y),
      ], paint);
    case NoteItem.dividerDouble:
      // İki ince çizgi: toplam kalınlık tek çizgiyle aynı ağırlıkta dursun.
      final line = math.max(0.8, width * 0.6);
      final offset = line + math.max(1.5, width * 0.6);
      paint.strokeWidth = line;
      canvas
        ..drawLine(Offset(left, y - offset), Offset(right, y - offset), paint)
        ..drawLine(Offset(left, y), Offset(right, y), paint);
    case NoteItem.dividerWavy:
      final amplitude = 1.5 + width * 0.6;
      final wave = 10 + width * 2;
      // sin dalgası: orta çizgi y − amplitude; her yarım dalga tek ikinci
      // derece eğri (tepe/çukur denetim noktası 2× genlikte — eğrinin tepesi
      // genliğe denk gelir).
      final mid = y - amplitude;
      final half = wave / 2;
      final path = Path()..moveTo(left, mid);
      var up = true;
      for (var x = left; x < right; x += half) {
        final end = math.min(x + half, right);
        final control = (x + end) / 2;
        final peak = up ? -amplitude : amplitude;
        // Ekranda y aşağı artar: eski çizim (`mid + sin·A`) ilk yarım
        // dalgayı AŞAĞI çiziyordu — burada da ilk eğri aşağı.
        path.quadraticBezierTo(
          control,
          mid - peak * 2 * (end - x) / half,
          end,
          mid,
        );
        up = !up;
      }
      paint.strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    default:
      // Düz çizgi ve TANINMAYAN tür (daha yeni sürümün türü): düz çizgi.
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
  }
}

/// Son kullanılan ayırıcı biçimi (oturum boyu): yeni çizgi aynı renk ve
/// kalınlıkla gelsin — her maddede yeniden ayarlamak gerekmesin.
class ItemDividerMemory {
  ItemDividerMemory._();

  static int? color;
  static double weight = 1;

  static void remember(ItemDivider style) {
    color = style.color;
    weight = style.weight;
  }

  /// [kind] türünde, son kullanılan renk/kalınlıkla yeni biçim.
  static ItemDivider fresh(String kind) =>
      ItemDivider(kind, color: color, weight: weight);
}

/// Ayırıcı ayar levhasının sonucu: yeni biçim (null = çizgiyi kaldır) ve
/// listedeki TÜM çizgilere uygulansın mı.
typedef ItemDividerChoice = ({ItemDivider? style, bool applyAll});

/// Tema renkli (renksiz) çizginin vurgu saydamlığı — satır, levha noktası
/// ve önizleme AYNI değeri kullanır (P63 PB6 bulgu 11). Kart tarafı
/// (`note_card.dart`) kendi `AppAlpha.muted`'ını korur.
const double kItemDividerAccentAlpha = 0.75;

/// **ÇİZGİ AYARLARI** levhası (P63 PB6): kâğıt önizleme · beş türün gerçek
/// çizimli seçicisi · renk noktaları · kalınlık · alt düğmeler. "Tamam"la
/// uygulanır (SB9: canlı uygulama ölçülmedi — levhanın önizlemesi canlı).
/// "Tüm çizgilere" listedeki bütün ayırıcıların biçimini birden değiştirir.
Future<ItemDividerChoice?> showItemDividerSheet(
  BuildContext context, {
  required ItemDivider initial,
}) => showAppSheet<ItemDividerChoice>(
  context: context,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => _ItemDividerSheet(initial: initial),
);

/// Önizleme kutusunun yüksekliği (bugünkü değer taşındı).
const double _previewHeight = 52;

class _ItemDividerSheet extends StatefulWidget {
  const _ItemDividerSheet({required this.initial});

  final ItemDivider initial;

  @override
  State<_ItemDividerSheet> createState() => _ItemDividerSheetState();
}

class _ItemDividerSheetState extends State<_ItemDividerSheet> {
  late ItemDivider _style = widget.initial;

  /// Kullanıcının seçebildiği çizgi renkleri (izinli sabit renk istisnası).
  static const _swatches = <Color>[
    Color(0xFF424242),
    Color(0xFF9E9E9E),
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
  ];

  void _done({required bool applyAll}) {
    ItemDividerMemory.remember(_style);
    Navigator.pop(context, (style: _style, applyAll: applyAll));
  }

  Widget _dot(Color? color, ColorScheme scheme) {
    final selected = color == null
        ? _style.color == null
        : _style.color == color.toARGB32();
    return ColorDot(
      color: color ?? scheme.primary.withValues(alpha: kItemDividerAccentAlpha),
      selected: selected,
      tooltip: color == null ? context.l10n.dividerColor : null,
      onTap: () => setState(
        () => _style = color == null
            ? _style.copyWith(clearColor: true)
            : _style.copyWith(color: color.toARGB32()),
      ),
      // Tema rengi: "otomatik" işareti (✨ yalnız yapay zekâ — rol sözleşmesi).
      child: color == null
          ? Icon(
              Icons.brightness_auto_rounded,
              size: AppIconSize.xs,
              color: scheme.onPrimary,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final custom = _style.color;
    final customOutsideSwatches =
        custom != null && !_swatches.any((c) => c.toARGB32() == custom);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.dividerSettings),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.l,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Kâğıt önizleme: örnek madde + satırdakiyle AYNI çizgi.
                  Container(
                    height: _previewHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.m,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.card,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      border: Border.all(color: tokens.hairline),
                    ),
                    child: CustomPaint(
                      painter: _PreviewPainter(_style, scheme.primary),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(l10n.dividerPreviewText, style: text.body),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Semantics(
                    label: l10n.dividerKind,
                    child: DividerKindPicker(
                      selected: _style.kind,
                      style: _style,
                      keyPrefix: 'divider-sheet-kind-',
                      onPick: (kind) =>
                          setState(() => _style = _style.copyWith(kind: kind)),
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Semantics(
                    label: l10n.dividerColor,
                    child: Wrap(
                      spacing: AppSpace.s,
                      runSpacing: AppSpace.s,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _dot(null, scheme),
                        for (final c in _swatches) _dot(c, scheme),
                        if (customOutsideSwatches) _dot(Color(custom), scheme),
                        PaletteButton(
                          title: l10n.paletteMore,
                          current: customOutsideSwatches ? Color(custom) : null,
                          onPicked: (c) => setState(
                            () => _style = _style.copyWith(color: c.toARGB32()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.m),
                  Semantics(
                    label: l10n.dividerWeight,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.s,
                          ),
                          child: Icon(
                            Icons.line_weight_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _style.weight,
                            min: ItemDivider.minWeight,
                            max: ItemDivider.maxWeight,
                            divisions: 10,
                            label: '${_style.weight.toStringAsFixed(1)}×',
                            onChanged: (v) => setState(
                              () => _style = _style.copyWith(weight: v),
                            ),
                          ),
                        ),
                        Text(
                          '${_style.weight.toStringAsFixed(1)}×',
                          style: text.meta.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.s),
                  // Sığmazsa alt alta (yazı 1.3, dar telefon).
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    overflowAlignment: OverflowBarAlignment.end,
                    spacing: AppSpace.s,
                    children: [
                      TextButton.icon(
                        key: const ValueKey('divider-sheet-remove'),
                        onPressed: () => Navigator.pop(
                          context,
                          (style: null, applyAll: false),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: Text(l10n.itemDividerRemove),
                      ),
                      TextButton(
                        key: const ValueKey('divider-sheet-all'),
                        onPressed: () => _done(applyAll: true),
                        child: Text(l10n.dividerApplyAll),
                      ),
                      FilledButton(
                        key: const ValueKey('divider-sheet-ok'),
                        onPressed: () => _done(applyAll: false),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  const _PreviewPainter(this.style, this.fallback);

  final ItemDivider style;
  final Color fallback;

  @override
  void paint(Canvas canvas, Size size) => paintItemDivider(
    canvas,
    style: style,
    fallbackColor: fallback.withValues(alpha: kItemDividerAccentAlpha),
    left: 0,
    right: size.width,
    y: size.height - AppSpace.s,
    baseWidth: 2.2,
  );

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.style.encode() != style.encode() || old.fallback != fallback;
}
