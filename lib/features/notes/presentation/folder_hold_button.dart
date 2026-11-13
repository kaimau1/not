import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/haptics.dart';

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

/// Klasör menüsünü açar (düğme ve ana ekranda yukarıdan aşağı çekiş — kullanıcı
/// isteği 2026-11-06, 5. tur; ikisi de AYNI kapı). Klasöre dokun → [onSelect];
/// ortadaki daire → [onOpen]; boşluk / geri → vazgeç.
Future<void> openFolderMenu(
  BuildContext context, {
  required List<FolderStop> stops,
  required String? currentId,
  required VoidCallback onOpen,
  required ValueChanged<String?> onSelect,
  VoidCallback? onNewFolder,
  VoidCallback? onEditFolders,
}) async {
  if (stops.length <= 1 && onNewFolder == null) {
    onOpen();
    return;
  }
  unawaited(AppHaptics.tick());
  final picked = await showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.l10n.close,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.42),
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, _, _) => _RadialFolderMenu(
      stops: stops,
      currentId: currentId,
      actions: onNewFolder != null || onEditFolders != null,
      canEdit: onEditFolders != null && stops.length > 1,
    ),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        ).drive(Tween(begin: 0.9, end: 1)),
        child: child,
      ),
    ),
  );
  if (picked == null) return;
  if (picked == _kNewFolder) {
    onNewFolder?.call();
  } else if (picked == _kEditFolders) {
    onEditFolders?.call();
  } else if (picked < 0) {
    onOpen();
  } else if (stops[picked].id != currentId) {
    onSelect(stops[picked].id);
  }
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
  Future<void> _openMenu() => openFolderMenu(
    context,
    stops: widget.stops,
    currentId: widget.currentId,
    onOpen: widget.onOpen,
    onSelect: widget.onSelect,
  );

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
const double _kCenterDiameter = 76;

/// **KOMPAKT KARO** (kullanıcı isteği 2026-11-06, 5. tur: "yuvarlak menü çok
/// dağınık, daha kompakt ve seçilmesi kolay olmalı"): uzun adlı yatay çipler
/// halkayı geniş bir ovale yayıyordu. Artık her durak SABİT boyda bir karo
/// (renkli simge dairesi + altında tek satır ad): halka küçük ve yuvarlak
/// kalır, dokunma hedefi her durakta aynı (74 × 76 dp).
const Size _kTile = Size(74, 76);

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
  double gap = 4,
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
  final start = _kCenterDiameter / 2 + maxH / 2;
  Size? best;
  for (var rx = start; rx <= limitX; rx += 6) {
    // Toplu dursun: oval en çok %30 uzun (eskiden uzun bir yumurtaya
    // yayılıyordu — "dağınık").
    for (var ry = rx; ry <= math.min(limitY, rx * 1.3); ry += 6) {
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
/// Menüden dönen özel değerler (duraklar 0.., "Klasörler" ekranı -1).
const _kNewFolder = -2;
const _kEditFolders = -3;

/// Menünün altındaki eylem satırının payı (dp).
const double _kActionsBar = 72;

class _RadialFolderMenu extends StatelessWidget {
  const _RadialFolderMenu({
    required this.stops,
    required this.currentId,
    this.actions = false,
    this.canEdit = false,
  });

  final List<FolderStop> stops;
  final String? currentId;

  /// Altta "Yeni klasör" / "Sırala · sil" satırı (kullanıcı isteği
  /// 2026-11-08: "yukarıdan çekilen klasörler ekranında klasör ekle,
  /// sıralama ve silme o ekranda olsun").
  final bool actions;
  final bool canEdit;

  void _pick(BuildContext context, int i) {
    unawaited(AppHaptics.tick());
    Navigator.of(context).pop(i);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final scaler = MediaQuery.textScalerOf(context);
    // Büyük yazı boyutunda karo da büyür (ad tek satırda kesilir).
    final tile = Size(
      _kTile.width,
      _kTile.height + (scaler.scale(12) - 12).clamp(0, 12),
    );
    final chips = List.filled(stops.length, tile);
    final body = actions
        ? Size(size.width, size.height - _kActionsBar)
        : size;
    final radii = radialRadiiFor(chips, body);
    final menu = radii == null
        ? _grid(context, body, tile)
        : _ring(context, tile, radii);
    if (!actions) {
      return Material(
        key: const ValueKey('folder-radial-menu'),
        type: MaterialType.transparency,
        child: menu,
      );
    }
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      key: const ValueKey('folder-radial-menu'),
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: _kActionsBar,
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: menu,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottom,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('folder-menu-new'),
                    onPressed: () => Navigator.of(context).pop(_kNewFolder),
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(
                      l10n.newFolder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('folder-menu-edit'),
                      onPressed: () =>
                          Navigator.of(context).pop(_kEditFolders),
                      icon: const Icon(Icons.swap_vert),
                      label: Text(
                        l10n.folderMenuEdit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring(BuildContext context, Size tile, Size radii) {
    final n = stops.length;
    return Center(
      child: SizedBox(
        key: const ValueKey('folder-ring-menu'),
        width: radii.width * 2 + tile.width + 8,
        height: radii.height * 2 + tile.height + 8,
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
                child: _FolderTile(
                  key: ValueKey('folder-radial-$i'),
                  stop: stops[i],
                  current: stops[i].id == currentId,
                  size: tile,
                  onTap: () => _pick(context, i),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// **IZGARA** — halkaya sığmayan kalabalık klasör listesi: ortada bir
  /// levha, başlıkta "Klasörler" (dokun → ekran), altında aynı karolar
  /// satır satır; çok uzunsa kayar. Hiçbir karo ötekinin üstüne binmez.
  Widget _grid(BuildContext context, Size size, Size tile) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
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
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                    child: Row(
                      children: [
                        Icon(Icons.folder_copy_outlined, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.foldersTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: AppWeight.strong,
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
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < stops.length; i++)
                          _FolderTile(
                            key: ValueKey('folder-radial-$i'),
                            stop: stops[i],
                            current: stops[i].id == currentId,
                            size: tile,
                            flat: true,
                            onTap: () => _pick(context, i),
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
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_copy_outlined, color: scheme.primary, size: 22),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                context.l10n.foldersTitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: AppWeight.strong,
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

/// Sabit boyutlu durak karosu: renkli simge dairesi (sayı rozeti köşede),
/// altında tek satır ad. Geçerli durak dolu renkte.
class _FolderTile extends StatelessWidget {
  const _FolderTile({
    super.key,
    required this.stop,
    required this.current,
    required this.size,
    required this.onTap,
    this.flat = false,
  });

  final FolderStop stop;
  final bool current;
  final Size size;
  final VoidCallback onTap;

  /// Izgara levhasında gölgesiz (levhanın kendi zemini var).
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = stop.color ?? scheme.primary;
    final discBg = current
        ? accent
        : Color.alphaBlend(
            accent.withValues(alpha: 0.16),
            scheme.surfaceContainerHigh,
          );
    final count = stop.count ?? 0;
    return Semantics(
      button: true,
      selected: current,
      label: stop.name,
      excludeSemantics: true,
      child: Material(
        color: flat ? Colors.transparent : scheme.surfaceContainerLow,
        elevation: flat ? 0 : 3,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: discBg,
                      ),
                      child: Icon(
                        stop.icon,
                        size: 21,
                        color: current ? _onColor(accent) : accent,
                      ),
                    ),
                    if (count > 0)
                      PositionedDirectional(
                        top: -4,
                        end: -10,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            count > 999 ? '999+' : '$count',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: current ? AppWeight.strong : FontWeight.w500,
                      color: current ? accent : scheme.onSurface,
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
