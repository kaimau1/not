import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **SABİT EK YANDA** (kullanıcı isteği 2026-11-09: "tablet ve web'de ekleri
/// sağa veya sola sabitleme yapılabilmeli, PDF'i kişi yana koyar çalışır").
///
/// Cihaz tercihi: sabit ek üstte mi, solda mı, sağda mı; yanda iken bölmenin
/// genişlik oranı. Yan yerleşim yalnız geniş alanda ([kPinnedSideMinWidth])
/// uygulanır — dar ekranda ek yine üstte durur.
enum PinnedSide { top, left, right }

/// Yan yerleşimin açıldığı en dar editör genişliği (dp).
const kPinnedSideMinWidth = 840.0;

class PinnedSideMemory {
  PinnedSideMemory._();

  static const _kSide = 'pinned_side';
  static const _kFraction = 'pinned_side_fraction';

  static SharedPreferences? _prefs;

  static final side = ValueNotifier<PinnedSide>(PinnedSide.top);

  /// Yan bölmenin editör genişliğine oranı (0,25–0,75).
  static double fraction = 0.5;

  static void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final name = prefs.getString(_kSide);
    side.value =
        PinnedSide.values.where((s) => s.name == name).firstOrNull ??
        PinnedSide.top;
    fraction = (prefs.getDouble(_kFraction) ?? 0.5).clamp(0.25, 0.75);
  }

  static void setSide(PinnedSide value) {
    side.value = value;
    _prefs?.setString(_kSide, value.name);
  }

  /// Üst → sol → sağ → üst.
  static PinnedSide next(PinnedSide s) =>
      PinnedSide.values[(s.index + 1) % PinnedSide.values.length];

  static void setFraction(double value) {
    fraction = value.clamp(0.25, 0.75);
    _prefs?.setDouble(_kFraction, fraction);
  }

  @visibleForTesting
  static void reset() {
    _prefs = null;
    side.value = PinnedSide.top;
    fraction = 0.5;
  }
}

/// Medya bölmesi ile not yan yana; aradaki ayraç sürüklenerek genişlik
/// değişir (bırakınca saklanır).
class PinnedSideLayout extends StatefulWidget {
  const PinnedSideLayout({
    super.key,
    required this.side,
    required this.media,
    required this.body,
  });

  final PinnedSide side;
  final Widget media;
  final Widget body;

  @override
  State<PinnedSideLayout> createState() => _PinnedSideLayoutState();
}

class _PinnedSideLayoutState extends State<PinnedSideLayout> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final frac = _drag ?? PinnedSideMemory.fraction;
        final mediaW = (w * frac).clamp(w * 0.25, w * 0.75);
        final left = widget.side == PinnedSide.left;
        final divider = MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            key: const ValueKey('pinned-side-divider'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => setState(() {
              final current = _drag ?? PinnedSideMemory.fraction;
              final delta = d.delta.dx / w;
              _drag = (current + (left ? delta : -delta)).clamp(0.25, 0.75);
            }),
            onHorizontalDragEnd: (_) {
              final f = _drag;
              if (f != null) PinnedSideMemory.setFraction(f);
              setState(() => _drag = null);
            },
            child: SizedBox(
              width: 12,
              child: Center(
                child: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        );
        final media = SizedBox(width: mediaW, child: widget.media);
        final body = Expanded(child: widget.body);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: left ? [media, divider, body] : [body, divider, media],
        );
      },
    );
  }
}
