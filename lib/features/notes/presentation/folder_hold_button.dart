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

/// Ekranın ortasında açılan halka; duraklar dokunulur. Seçim `pop(i)` ile
/// döner; ortadaki daire `pop(-1)` = Klasörler ekranı.
class _RadialFolderMenu extends StatelessWidget {
  const _RadialFolderMenu({required this.stops, required this.currentId});

  final List<FolderStop> stops;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final n = stops.length;
    final ringR = radialRadius(n);
    final outer = ringR + 44;
    final fit = math.min(size.width, size.height) / 2 - 8;
    final scale = outer > fit ? fit / outer : 1.0;
    final radius = ringR * scale;
    return Center(
      child: Material(
        key: const ValueKey('folder-radial-menu'),
        type: MaterialType.transparency,
        child: SizedBox(
          width: outer * 2 * scale,
          height: outer * 2 * scale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Ortadaki daire: Klasörler ekranı.
              InkWell(
                key: const ValueKey('folder-radial-all'),
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(-1),
                child: Ink(
                  width: 96 * scale + 8,
                  height: 96 * scale + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.surfaceContainerHighest,
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black26),
                    ],
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
              ),
              for (var i = 0; i < n; i++)
                Transform.translate(
                  offset: Offset(
                    math.cos(radialAngle(0, i, n)) * radius,
                    math.sin(radialAngle(0, i, n)) * radius,
                  ),
                  child: GestureDetector(
                    key: ValueKey('folder-radial-$i'),
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      Navigator.of(context).pop(i);
                    },
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
