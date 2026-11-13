import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../viewers/ink_tools.dart';

/// **YÜZEN KALEM DÜĞMESİ: "kalem yazar / kalem dokunur"** (kullanıcı isteği
/// 2026-11-09: "kalem varken metne tıklamak istediğimde kalemle yazı yazdığı
/// için metin giremiyorum"; "sabit PDF'e yazamıyorum, gömülüde yazdıklarım
/// sayfaya gidiyor" — "kalem yazma aktif/pasif hızlı erişim butonu, yüzen,
/// kişi istediği yere koyar, yeri hatırlanır, büyük olmaz").
///
/// Tek düğme [InkToolMemory.autoStylus]'u açar/kapar:
/// * AÇIK — kalem değdiği yüzeye yazar (sayfa, sabit PDF, gömülü belge).
/// * KAPALI — kalem parmak gibidir: metne imleç koyar, kaydırır, düğmelere
///   basar; editör kalem kipindeyse o da kapanır.
///
/// Sürükleyerek taşınır, yeri ekran oranı olarak saklanır. Yalnız bu
/// cihazda bir kez kalem görüldüyse çizilir ([InkToolMemory.stylusEver]).
class StylusToggleOverlay extends StatefulWidget {
  const StylusToggleOverlay({
    super.key,
    required this.child,
    this.visible = true,
  });

  final Widget child;

  /// Salt okunur notta / kalemsiz cihazda false.
  final bool visible;

  @override
  State<StylusToggleOverlay> createState() => _StylusToggleOverlayState();
}

class _StylusToggleOverlayState extends State<StylusToggleOverlay> {
  static const _size = 44.0;
  Offset? _dragAt;

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth, h = box.maxHeight;
              if (!w.isFinite || !h.isFinite || w < _size * 2) {
                return const SizedBox.shrink();
              }
              final frac = InkToolMemory.penToggleAt ?? const Offset(1, 0.55);
              final at =
                  _dragAt ??
                  Offset(
                    (frac.dx * (w - _size)).clamp(0, w - _size),
                    (frac.dy * (h - _size)).clamp(0, h - _size),
                  );
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _dragAt == null
                        ? const Duration(milliseconds: 220)
                        : Duration.zero,
                    curve: Curves.easeOutCubic,
                    left: at.dx,
                    top: at.dy,
                    child: GestureDetector(
                      onPanUpdate: (d) => setState(() {
                        final base = _dragAt ?? at;
                        _dragAt = Offset(
                          (base.dx + d.delta.dx).clamp(0, w - _size),
                          (base.dy + d.delta.dy).clamp(0, h - _size),
                        );
                      }),
                      onPanEnd: (_) {
                        final p = _dragAt;
                        if (p == null) return;
                        InkToolMemory.notePenToggleAt(
                          Offset(p.dx / (w - _size), p.dy / (h - _size)),
                        );
                        setState(() => _dragAt = null);
                      },
                      child: const _StylusToggleButton(size: _size),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StylusToggleButton extends StatelessWidget {
  const _StylusToggleButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return ValueListenableBuilder<bool>(
      valueListenable: InkToolMemory.autoStylusListenable,
      builder: (context, on, _) => Semantics(
        button: true,
        toggled: on,
        label: on ? l10n.stylusTogglesOn : l10n.stylusTogglesOff,
        child: Tooltip(
          message: on ? l10n.stylusTogglesOn : l10n.stylusTogglesOff,
          child: Material(
            key: const ValueKey('stylus-toggle'),
            elevation: 3,
            shape: const CircleBorder(),
            color: on ? scheme.primary : scheme.surfaceContainerHigh,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                InkToolMemory.saveAutoStylus(!on);
                // SÜREKLİ ÇIKMASIN (P49 (d), kullanıcı 2026-11-12: "'kalem
                // yazar, parmak dokunur' gibi ipuçları alt kalem panelini
                // kapatmasın, sürekli çıkmasın"): düğmenin simgesi ve rengi
                // durumu zaten gösteriyor; yazı her durum için OTURUMDA BİR
                // KEZ, kalem tepsisinin üstünde.
                if (!InkToolMemory.stylusHintsTold.add(!on)) return;
                final margin = snackBarMarginOverKeyboard();
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1600),
                      behavior: margin == null
                          ? null
                          : SnackBarBehavior.floating,
                      margin: margin,
                      content: Text(
                        !on ? l10n.stylusTogglesOn : l10n.stylusTogglesOff,
                      ),
                    ),
                  );
              },
              child: SizedBox.square(
                dimension: size,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Icon(
                    on ? Icons.draw_rounded : Icons.touch_app_outlined,
                    key: ValueKey(on),
                    size: 22,
                    color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
