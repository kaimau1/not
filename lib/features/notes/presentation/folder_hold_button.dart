import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n_ext.dart';

/// Yuvarlak klasör menüsündeki bir durak. [id] `null` = "Tümü".
class FolderStop {
  const FolderStop({
    required this.id,
    required this.name,
    this.icon = Icons.folder_outlined,
    this.color,
    this.count,
  });

  final String? id;
  final String name;
  final IconData icon;

  /// Klasörün vurgu rengi (null = tema rengi).
  final Color? color;

  /// İçindeki not sayısı (null = gösterilmez).
  final int? count;
}

/// **TEK HALKA** (kullanıcı isteği 2026-11-06, üçüncü tur: "ikinci uzak
/// sıraya geçmek zor, tek sıraya sığsın"): bütün duraklar aynı halkada; çok
/// klasör olunca halka büyür, dilim incelir — seçim yalnız YÖNLE.
List<int> radialRings(int count) => count <= 0 ? const [] : [count];

/// Basılı tutma süresi — varsayılan 500 ms "çok geç" bulundu (2026-11-06).
const kFolderHoldDelay = Duration(milliseconds: 220);

/// Tek halkanın yarıçapı (dp): duraklar yan yana sığsın diye sayıyla büyür.
double radialRadius(int count) => math.max(104, count * 76 / (2 * math.pi));

/// Halka [ring]'deki [slot]. durağın açısı (radyan): ilki tepede (−90°),
/// saat yönünde. Dış halkalar yarım dilim kaydırılır — iç halkadaki
/// komşusunun tam arkasına düşmesin.
double radialAngle(int ring, int slot, int ringCount) {
  final step = 2 * math.pi / ringCount;
  final shift = ring.isOdd ? step / 2 : 0.0;
  return -math.pi / 2 + slot * step + shift;
}

/// **KÜÇÜK HAREKETLE SEÇİM**: parmağın başladığı yerden [delta] kadar
/// kaydığında hangi durak seçili. Yön dilimi seçer (yarıçap değil — ufak bir
/// kayma yeter), uzaklık halkayı: [dead] dp içinde seçim YOK (bırakmak
/// vazgeçer), sonra her [ringStep] dp bir dış halka. Döndürülen değer düz
/// dizideki sıradır; ölü bölgede null.
int? radialFolderIndex(
  Offset delta,
  int count, {
  double dead = 14,
  double ringStep = 56,
}) {
  if (count <= 0) return null;
  final dist = delta.distance;
  if (dist < dead) return null;
  final rings = radialRings(count);
  final ring = ((dist - dead) / ringStep).floor().clamp(0, rings.length - 1);
  final n = rings[ring];
  final step = 2 * math.pi / n;
  final shift = ring.isOdd ? step / 2 : 0.0;
  // Tepeden (−90°) saat yönünde açı, [0, 2π).
  var a = math.atan2(delta.dy, delta.dx) + math.pi / 2 - shift;
  a %= 2 * math.pi;
  final slot = ((a + step / 2) / step).floor() % n;
  var offset = 0;
  for (var r = 0; r < ring; r++) {
    offset += rings[r];
  }
  return offset + slot;
}

/// **KLASÖR DÜĞMESİ** (kullanıcı isteği 2026-11-06, ikinci tur: "tutunca
/// yuvarlak bir menü açsın ekranın ortasında; tutarken ufak hareketlerle
/// klasörler arası geçiş olmalı, bırakınca hangi klasör üzerindeyse ona
/// geçiş").
///
/// Dokun → [onOpen] (Klasörler ekranı). Basılı tut → ekranın ortasında
/// klasörler halka hâlinde açılır (simgesi, rengi, not sayısı); parmağı
/// hangi YÖNE biraz kaydırırsan o klasör seçilir (her değişimde hafif
/// titreşim), daha uzağa kaydırmak dış halkaya geçer. Bırakınca [onSelect]
/// o klasörü açar; ortada bırakmak vazgeçer. Üstteki klasör şeridi ve
/// yatay kaydırma ayrıca çalışmaya devam eder.
class FolderHoldButton extends StatefulWidget {
  const FolderHoldButton({
    super.key,
    required this.stops,
    required this.currentId,
    required this.onOpen,
    required this.onSelect,
  });

  /// İlki "Tümü" (`id == null`).
  final List<FolderStop> stops;
  final String? currentId;
  final VoidCallback onOpen;
  final ValueChanged<String?> onSelect;

  @override
  State<FolderHoldButton> createState() => _FolderHoldButtonState();
}

class _FolderHoldButtonState extends State<FolderHoldButton> {
  OverlayEntry? _entry;
  final _selected = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _close();
    _selected.dispose();
    super.dispose();
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _begin(LongPressStartDetails _) {
    HapticFeedback.mediumImpact();
    _selected.value = null;
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (_) => _RadialFolderMenu(
        stops: widget.stops,
        currentId: widget.currentId,
        selected: _selected,
      ),
    );
    overlay.insert(_entry!);
  }

  void _move(LongPressMoveUpdateDetails d) {
    final next = radialFolderIndex(d.offsetFromOrigin, widget.stops.length);
    if (next != _selected.value) {
      if (next != null) HapticFeedback.selectionClick();
      _selected.value = next;
    }
  }

  void _end(LongPressEndDetails _) {
    final i = _selected.value;
    _selected.value = null;
    _close();
    if (i != null && widget.stops[i].id != widget.currentId) {
      widget.onSelect(widget.stops[i].id);
    }
  }

  void _cancel() {
    _selected.value = null;
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = widget.stops
        .where((s) => s.id == widget.currentId)
        .firstOrNull;
    final enabled = widget.stops.length > 1;
    return Semantics(
      button: true,
      label: current == null || current.id == null
          ? l10n.allFolders
          : current.name,
      hint: l10n.folderHoldHint,
      child: RawGestureDetector(
        key: const ValueKey('folder-hold-button'),
        gestures: {
          if (enabled)
            LongPressGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  LongPressGestureRecognizer
                >(
                  () => LongPressGestureRecognizer(
                    duration: kFolderHoldDelay,
                    debugOwner: this,
                  ),
                  (r) => r
                    ..onLongPressStart = _begin
                    ..onLongPressMoveUpdate = _move
                    ..onLongPressEnd = _end
                    ..onLongPressCancel = _cancel,
                ),
        },
        child: FloatingActionButton.small(
          heroTag: 'folderHold',
          // İpucu YOK: Tooltip basılı tutmayı kendisi yakalar, kaydırarak
          // klasör seçme hiç başlamazdı (ad Semantics'te).
          onPressed: widget.onOpen,
          child: Icon(
            current?.id == null ? Icons.folder_outlined : current!.icon,
          ),
        ),
      ),
    );
  }
}

/// Ekranın ortasında açılan halka. Dokunuşları YUTMAZ (IgnorePointer):
/// jest düğmede sürer, halka yalnız gösterir.
class _RadialFolderMenu extends StatefulWidget {
  const _RadialFolderMenu({
    required this.stops,
    required this.currentId,
    required this.selected,
  });

  final List<FolderStop> stops;
  final String? currentId;
  final ValueListenable<int?> selected;

  @override
  State<_RadialFolderMenu> createState() => _RadialFolderMenuState();
}

class _RadialFolderMenuState extends State<_RadialFolderMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final rings = radialRings(widget.stops.length);
    // Tek halka; ekrana sığmazsa küçülür.
    final ringR = radialRadius(widget.stops.length);
    final outer = ringR + 44;
    final fit = math.min(size.width, size.height) / 2 - 8;
    final scale = outer > fit ? fit / outer : 1.0;
    return IgnorePointer(
      child: FadeTransition(
        opacity: _open,
        child: Material(
          key: const ValueKey('folder-radial-menu'),
          color: scheme.scrim.withValues(alpha: 0.42),
          child: Center(
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _open,
                curve: Curves.easeOutBack,
              ).drive(Tween(begin: 0.85, end: 1)),
              child: ValueListenableBuilder<int?>(
                valueListenable: widget.selected,
                builder: (context, sel, _) {
                  final children = <Widget>[];
                  var i = 0;
                  for (var r = 0; r < rings.length; r++) {
                    final radius = ringR * scale;
                    for (var s = 0; s < rings[r]; s++, i++) {
                      final a = radialAngle(r, s, rings[r]);
                      children.add(
                        Transform.translate(
                          offset: Offset(
                            math.cos(a) * radius,
                            math.sin(a) * radius,
                          ),
                          child: _RadialChip(
                            stop: widget.stops[i],
                            selected: sel == i,
                            current: widget.stops[i].id == widget.currentId,
                          ),
                        ),
                      );
                    }
                  }
                  final picked = sel == null ? null : widget.stops[sel];
                  return SizedBox(
                    width: outer * 2 * scale,
                    height: outer * 2 * scale,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Ortadaki daire: seçili klasörün adı; seçim yoksa
                        // "bırak = vazgeç" ipucu.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 96 * scale + 8,
                          height: 96 * scale + 8,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: picked == null
                                ? scheme.surfaceContainerHighest
                                : (picked.color ?? scheme.primary),
                            boxShadow: const [
                              BoxShadow(blurRadius: 12, color: Colors.black26),
                            ],
                          ),
                          child: Text(
                            picked?.name ?? context.l10n.folderRadialCancel,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: picked == null
                                  ? scheme.onSurfaceVariant
                                  : _onColor(picked.color ?? scheme.primary),
                            ),
                          ),
                        ),
                        ...children,
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _onColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark
    ? Colors.white
    : Colors.black87;

class _RadialChip extends StatelessWidget {
  const _RadialChip({
    required this.stop,
    required this.selected,
    required this.current,
  });

  final FolderStop stop;
  final bool selected;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = stop.color ?? scheme.primary;
    final bg = selected ? accent : scheme.surfaceContainerHigh;
    final fg = selected ? _onColor(accent) : scheme.onSurface;
    return AnimatedScale(
      scale: selected ? 1.18 : 1,
      duration: const Duration(milliseconds: 120),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 104),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: current ? accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stop.icon, size: 16, color: selected ? fg : accent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
            if (stop.count != null && stop.count! > 0) ...[
              const SizedBox(width: 4),
              Text(
                '${stop.count}',
                style: TextStyle(
                  fontSize: 11,
                  color: fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
