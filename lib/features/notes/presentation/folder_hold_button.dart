import 'dart:math' as math;

import 'dart:async';

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

/// **KLASÖR DÜĞMESİ** (kullanıcı isteği 2026-11-06, 4. tur): DOKUN → ekranın
/// ortasında klasörler tek halkada açılır (simge, renk, not sayısı); bir
/// klasöre dokun → [onSelect]; ortadaki "Klasörler" dairesi → [onOpen];
/// boşluk / geri → vazgeç. Basılı tutup sürükleme kaldırıldı.
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
  /// DOKUN → HALKA (kullanıcı isteği 2026-11-06, dördüncü tur: "basılı
  /// tutarak değil basılınca açılsın ve tıklansın; basılı tutup sürükleme
  /// kaldırılsın"). Halkada klasöre dokun = o klasör; ortadaki daire =
  /// Klasörler ekranı; boşluğa dokun / geri = vazgeç.
  Future<void> _openMenu() async {
    if (widget.stops.length <= 1) {
      widget.onOpen();
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    final picked = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.close,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, _, _) =>
          _RadialFolderMenu(stops: widget.stops, currentId: widget.currentId),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutBack,
          ).drive(Tween(begin: 0.85, end: 1)),
          child: child,
        ),
      ),
    );
    if (!mounted || picked == null) return;
    if (picked < 0) {
      widget.onOpen();
    } else if (widget.stops[picked].id != widget.currentId) {
      widget.onSelect(widget.stops[picked].id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = widget.stops
        .where((s) => s.id == widget.currentId)
        .firstOrNull;
    return Semantics(
      button: true,
      label: current == null || current.id == null
          ? l10n.allFolders
          : current.name,
      child: FloatingActionButton.small(
        key: const ValueKey('folder-hold-button'),
        heroTag: 'folderHold',
        onPressed: _openMenu,
        child: Icon(
          current?.id == null ? Icons.folder_outlined : current!.icon,
        ),
      ),
    );
  }
}

/// Orta dairenin çapı (dp).
const double _kCenterDiameter = 104;

/// Durak çipinin en geniş hâli halkada (dp); ızgarada daha geniş.
const double _kRingChipMax = 120;
const double _kGridChipMax = 220;

/// **SIĞIYOR MU** (kullanıcı isteği 2026-11-06: "klasörlerde sığmıyor, üst
/// üste geliyor"). Eskiden halka ekrana sığsın diye YARIÇAP küçültülüyor ama
/// çipler aynı boyda kalıyordu → 10+ klasörde çipler birbirinin ve orta
/// dairenin üstüne biniyordu. Artık [chips] boyutlarındaki duraklar [radius]
/// yarıçaplı halkada yerleştirildiğinde HİÇBİR çip ötekine ya da orta daireye
/// ([centerRadius]) [gap] dp'den yakın değilse true; değilse menü ızgaraya
/// geçer.
bool radialLayoutFits(
  List<Size> chips,
  double radius, {
  double? radiusY,
  double centerRadius = _kCenterDiameter / 2,
  double gap = 6,
}) {
  final n = chips.length;
  final ry = radiusY ?? radius;
  final rects = [
    for (var i = 0; i < n; i++)
      Rect.fromCenter(
        center: Offset(
          math.cos(radialAngle(0, i, n)) * radius,
          math.sin(radialAngle(0, i, n)) * ry,
        ),
        width: chips[i].width + gap,
        height: chips[i].height + gap,
      ),
  ];
  for (var i = 0; i < n; i++) {
    // Orta daireye en yakın nokta.
    final r = rects[i];
    final cx = 0.0.clamp(r.left, r.right);
    final cy = 0.0.clamp(r.top, r.bottom);
    if (Offset(cx, cy).distance < centerRadius + gap / 2) return false;
    for (var j = i + 1; j < n; j++) {
      if (r.overlaps(rects[j])) return false;
    }
  }
  return true;
}

/// Ekrana sığan ve çakışmayan en küçük halka: `width` yatay, `height`
/// dikey yarıçap (dar telefonda dikey OVAL — çipler geniş, ekran uzun).
/// Sığmıyorsa null (ızgara).
Size? radialRadiiFor(List<Size> chips, Size screen) {
  if (chips.isEmpty) return null;
  final maxW = chips.map((c) => c.width).reduce(math.max);
  final maxH = chips.map((c) => c.height).reduce(math.max);
  final limitX = screen.width / 2 - maxW / 2 - 12;
  final limitY = math.min(screen.height / 2 - maxH / 2 - 12, 260.0);
  final start = _kCenterDiameter / 2 + maxH;
  Size? best;
  for (var rx = start; rx <= limitX; rx += 6) {
    for (var ry = rx; ry <= limitY; ry += 6) {
      if (best != null && rx + ry >= best.width + best.height) break;
      if (radialLayoutFits(chips, rx, radiusY: ry)) {
        best = Size(rx, ry);
        break;
      }
    }
  }
  return best;
}

/// Halka ya da ızgara: duraklar dokunulur. Seçim `pop(i)` ile döner;
/// "Klasörler" (orta daire / başlık) `pop(-1)` = Klasörler ekranı.
class _RadialFolderMenu extends StatelessWidget {
  const _RadialFolderMenu({required this.stops, required this.currentId});

  final List<FolderStop> stops;
  final String? currentId;

  /// Çipin gerçekte çizileceği boyut (seçili çip 1,18 büyür).
  Size _chipSize(BuildContext context, FolderStop stop, double maxWidth) {
    final scaler = MediaQuery.textScalerOf(context);
    final selected = stop.id == currentId;
    TextPainter measure(String text, TextStyle style) => TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final name = measure(
      stop.name,
      TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    var w = 20.0 + 4 + 16 + 5 + name.width;
    if (stop.count != null && stop.count! > 0) {
      w += 4 + measure('${stop.count}', const TextStyle(fontSize: 11)).width;
    }
    final double h = 18 + math.max(16, name.height);
    final size = Size(math.min(w, maxWidth).toDouble(), h);
    return selected ? size * 1.18 : size;
  }

  void _pick(BuildContext context, int i) {
    unawaited(HapticFeedback.selectionClick());
    Navigator.of(context).pop(i);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final chips = [for (final s in stops) _chipSize(context, s, _kRingChipMax)];
    final radii = radialRadiiFor(chips, size);
    return Material(
      key: const ValueKey('folder-radial-menu'),
      type: MaterialType.transparency,
      child: radii == null
          ? _grid(context, size)
          : _ring(context, chips, radii),
    );
  }

  Widget _ring(BuildContext context, List<Size> chips, Size radii) {
    final n = stops.length;
    final maxW = chips.map((c) => c.width).reduce(math.max);
    final maxH = chips.map((c) => c.height).reduce(math.max);
    return Center(
      child: SizedBox(
        key: const ValueKey('folder-ring-menu'),
        width: radii.width * 2 + maxW + 8,
        height: radii.height * 2 + maxH + 8,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _CenterDisc(onTap: () => Navigator.of(context).pop(-1)),
            for (var i = 0; i < n; i++)
              Transform.translate(
                offset: Offset(
                  math.cos(radialAngle(0, i, n)) * radii.width,
                  math.sin(radialAngle(0, i, n)) * radii.height,
                ),
                child: GestureDetector(
                  key: ValueKey('folder-radial-$i'),
                  onTap: () => _pick(context, i),
                  child: _RadialChip(
                    stop: stops[i],
                    selected: stops[i].id == currentId,
                    current: stops[i].id == currentId,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// **IZGARA** — halkaya sığmayan kalabalık klasör listesi: ortada bir
  /// levha, başlıkta "Klasörler" (dokun → ekran), altında satır satır
  /// sarılan çipler; çok uzunsa kayar. Hiçbir çip ötekinin üstüne binmez.
  Widget _grid(BuildContext context, Size size) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: size.height * 0.75,
          ),
          child: Material(
            key: const ValueKey('folder-grid-menu'),
            color: scheme.surfaceContainerLow,
            elevation: 6,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  key: const ValueKey('folder-radial-all'),
                  onTap: () => Navigator.of(context).pop(-1),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        Icon(Icons.folder_copy_outlined, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.foldersTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: scheme.outlineVariant),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < stops.length; i++)
                          GestureDetector(
                            key: ValueKey('folder-radial-$i'),
                            onTap: () => _pick(context, i),
                            child: _RadialChip(
                              stop: stops[i],
                              // Izgarada büyütme yok: komşusuna taşmasın.
                              selected: false,
                              current: stops[i].id == currentId,
                              maxWidth: _kGridChipMax,
                              large: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Halkanın ortasındaki "Klasörler" dairesi.
class _CenterDisc extends StatelessWidget {
  const _CenterDisc({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      key: const ValueKey('folder-radial-all'),
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Ink(
        width: _kCenterDiameter,
        height: _kCenterDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest,
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_copy_outlined, color: scheme.primary),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.l10n.foldersTitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
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
    this.maxWidth = _kRingChipMax,
    this.large = false,
  });

  final FolderStop stop;
  final bool selected;
  final bool current;
  final double maxWidth;

  /// Izgarada daha iri (dokunma hedefi ≥ 40 dp).
  final bool large;

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
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 14 : 10,
          vertical: large ? 10 : 7,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: current ? accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: large
              ? null
              : const [BoxShadow(blurRadius: 6, color: Colors.black26)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stop.icon,
              size: large ? 18 : 16,
              color: selected ? fg : accent,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: large ? 14 : 12.5,
                  fontWeight: selected || (large && current)
                      ? FontWeight.w700
                      : FontWeight.w500,
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
