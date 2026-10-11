import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import 'note_images.dart';

/// Sabit bölmenin yüksekliği bu sınırlar arasında kalır (dp / oran).
const double kPinnedMinHeight = 96;
const double kPinnedMaxFraction = 0.7;

/// Ayraç bu yüksekliğin altına çekilip bırakılırsa medya sayfaya geri döner.
const double kPinnedUnpinHeight = 72;

/// Yeni sabitlenen medyanın ilk yüksekliği: ekran genişliğinde medyanın kendi
/// oranı, ekranın %45'ini geçmeden. Oranı bilinmeyen video 16:9 sayılır.
double defaultPinnedHeight(Attachment media, Size screen) {
  final w = (media.width ?? 0).toDouble();
  final h = (media.height ?? 0).toDouble();
  final ratio = w > 0 && h > 0
      ? h / w
      : (media.kind == AttachmentKind.video ? 9 / 16 : 3 / 4);
  final natural = screen.width * ratio;
  final max = screen.height * 0.45;
  return natural.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );
}

/// **ÜSTTE MEDYA, ALTTA NOT** (kullanıcı isteği 2026-10-11).
///
/// Görsel ya da video notun tepesinde SABİT durur, not ([child]) altında
/// kendi başına kayar — video izlerken ya da bir görsele bakarken yazmak
/// için. Bölme ile not arasındaki AYRAÇ sürüklenerek boyutlanır (bırakınca
/// [onHeightChanged] kaydeder); ayraç en alta değil en ÜSTE, bölmeyi
/// kapatacak kadar çekilirse ya da medya basılı tutulup nota doğru aşağı
/// sürüklenirse medya sayfaya geri döner ([onUnpin]).
class PinnedMediaPane extends StatefulWidget {
  const PinnedMediaPane({
    super.key,
    required this.media,
    required this.onHeightChanged,
    required this.onUnpin,
    required this.onOpen,
    required this.child,
  });

  final Attachment media;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onUnpin;

  /// Tam ekran (görsel görüntüleyici / video oynatıcı).
  final VoidCallback onOpen;

  final Widget child;

  @override
  State<PinnedMediaPane> createState() => _PinnedMediaPaneState();
}

class _PinnedMediaPaneState extends State<PinnedMediaPane> {
  /// Ayraç sürüklenirken canlı yükseklik (ham — sınırlanmamış).
  double? _live;

  /// Medya basılı tutulup aşağı sürüklenirken parmağın yer değiştirmesi.
  double _pullDown = 0;
  bool _pulling = false;

  double _clamp(double h, double max) => h.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );

  bool get _unpinArmed =>
      (_live != null && _live! < kPinnedUnpinHeight) ||
      (_pulling && _pullDown > 96);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isVideo = widget.media.kind == AttachmentKind.video;
    return LayoutBuilder(
      builder: (context, constraints) {
        final max = constraints.maxHeight * kPinnedMaxFraction;
        final live = _live;
        // Sürüklerken bölme sınırın altına da iner (geri bırakma hissi);
        // bırakınca sınıra oturur ya da sayfaya döner.
        final height = live != null
            ? live.clamp(0.0, max < kPinnedMinHeight ? kPinnedMinHeight : max)
            : _clamp(widget.media.pinHeight, max);
        return Column(
          children: [
            SizedBox(
              height: height,
              child: GestureDetector(
                onTap: isVideo ? null : widget.onOpen,
                onLongPressStart: (_) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _pulling = true;
                    _pullDown = 0;
                  });
                },
                onLongPressMoveUpdate: (d) =>
                    setState(() => _pullDown = d.offsetFromOrigin.dy),
                onLongPressEnd: (_) {
                  final unpin = _unpinArmed;
                  setState(() {
                    _pulling = false;
                    _pullDown = 0;
                  });
                  if (unpin) widget.onUnpin();
                },
                onLongPressCancel: () => setState(() {
                  _pulling = false;
                  _pullDown = 0;
                }),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: isVideo
                          ? Colors.black
                          : scheme.surfaceContainerHigh,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          _pulling ? _pullDown.clamp(0, 140) : 0,
                        ),
                        child: Opacity(
                          opacity: _pulling ? 0.6 : 1,
                          child: NoteMediaBox(
                            // Ek değişince (başka medya sabitlenince)
                            // oynatıcı da yenilensin.
                            key: ValueKey(widget.media.id),
                            attachment: widget.media,
                            fit: BoxFit.contain,
                            inlineWebVideo: true,
                          ),
                        ),
                      ),
                    ),
                    if (_unpinArmed) _UnpinHint(label: l10n.unpinMediaRelease),
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PaneButton(
                            tooltip: l10n.fullscreen,
                            icon: Icons.fullscreen,
                            onPressed: widget.onOpen,
                          ),
                          const SizedBox(width: 6),
                          _PaneButton(
                            tooltip: l10n.unpinMedia,
                            icon: Icons.vertical_align_bottom,
                            onPressed: widget.onUnpin,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // AYRAÇ: dikey sürükleme bölmeyi boyutlar. 22 dp dokunma alanı,
            // ortada görünür bir tutamaç çizgisi.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => setState(() => _live = height),
              onVerticalDragUpdate: (d) =>
                  setState(() => _live = (_live ?? height) + d.delta.dy),
              onVerticalDragEnd: (_) {
                final raw = _live ?? height;
                setState(() => _live = null);
                if (raw < kPinnedUnpinHeight) {
                  widget.onUnpin();
                } else {
                  widget.onHeightChanged(_clamp(raw, max));
                }
              },
              onVerticalDragCancel: () => setState(() => _live = null),
              child: Semantics(
                label: l10n.pinnedMediaResize,
                child: Container(
                  height: 22,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _live != null
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}

class _PaneButton extends StatelessWidget {
  const _PaneButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: Colors.white,
      icon: Icon(icon),
      onPressed: onPressed,
    ),
  );
}

class _UnpinHint extends StatelessWidget {
  const _UnpinHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}
