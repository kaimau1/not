import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../app/theme/app_design.dart';
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
    barrierColor: Theme.of(
      context,
    ).colorScheme.scrim.withValues(alpha: AppAlpha.muted),
    transitionDuration: AppMotion.quick,
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
          curve: AppMotion.emphasized,
        ).drive(Tween(begin: 0.92, end: 1)),
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
  double gap = 14,
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
  final limitX = screen.width / 2 - maxW / 2 - AppSpace.m;
  final limitY = math.min(screen.height / 2 - maxH / 2 - AppSpace.m, 260.0);
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
const double _kActionsBar = 80;

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

  Widget _actionButtons(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FilledButton.tonalIcon(
            key: const ValueKey('folder-menu-new'),
            onPressed: () => Navigator.of(context).pop(_kNewFolder),
            icon: const Icon(
              Icons.create_new_folder_outlined,
              size: AppIconSize.s,
            ),
            label: Text(
              l10n.newFolder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (canEdit) ...[
          const SizedBox(width: AppSpace.s),
          Flexible(
            child: FilledButton.tonalIcon(
              key: const ValueKey('folder-menu-edit'),
              onPressed: () => Navigator.of(context).pop(_kEditFolders),
              icon: const Icon(Icons.swap_vert, size: AppIconSize.s),
              label: Text(
                l10n.folderMenuEdit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    // Izgara kartında eylemler kartın kendi alt çubuğuna yerleşir: ana
    // ekrandaki "+" FAB ile çakışmaz, tek bütüncül levha olur.
    if (radii == null) {
      return Material(
        key: const ValueKey('folder-radial-menu'),
        type: MaterialType.transparency,
        child: _grid(context, size, tile),
      );
    }
    final menu = _ring(context, tile, radii);
    if (!actions) {
      return Material(
        key: const ValueKey('folder-radial-menu'),
        type: MaterialType.transparency,
        child: menu,
      );
    }
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
            left: AppSpace.l,
            right: AppSpace.l,
            bottom: AppSpace.l + bottom,
            child: Center(
              child: DecoratedBox(
                decoration: AppSurface.floating(theme, radius: AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xs),
                  child: _actionButtons(context),
                ),
              ),
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
        width: radii.width * 2 + tile.width + AppSpace.s,
        height: radii.height * 2 + tile.height + AppSpace.s,
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
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.l),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: size.height * 0.76,
          ),
          child: DecoratedBox(
            key: const ValueKey('folder-grid-menu'),
            decoration: AppSurface.floating(theme, radius: AppRadius.xl),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      key: const ValueKey('folder-radial-all'),
                      onTap: () => Navigator.of(context).pop(-1),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.xl,
                          AppSpace.m,
                          AppSpace.m,
                          AppSpace.m,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_copy_outlined,
                              color: scheme.primary,
                              size: AppIconSize.m,
                            ),
                            const SizedBox(width: AppSpace.m),
                            Expanded(
                              child: Text(
                                l10n.foldersTitle,
                                style: text.rowTitle.copyWith(
                                  fontWeight: AppWeight.strong,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurfaceVariant,
                              size: AppIconSize.m,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: tokens.hairline,
                      child: const SizedBox(height: 1),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.m,
                          AppSpace.m,
                          AppSpace.m,
                          AppSpace.m,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpace.s,
                          runSpacing: AppSpace.s,
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
                    if (actions) ...[
                      ColoredBox(
                        color: tokens.hairline,
                        child: const SizedBox(height: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.m,
                          vertical: AppSpace.s,
                        ),
                        child: _actionButtons(context),
                      ),
                    ],
                  ],
                ),
              ),
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
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    return Material(
      color: tokens.card,
      shape: CircleBorder(
        side: BorderSide(
          color: scheme.primary.withValues(alpha: AppAlpha.soft),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('folder-radial-all'),
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: _kCenterDiameter,
          height: _kCenterDiameter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_copy_outlined,
                color: scheme.primary,
                size: AppIconSize.m,
              ),
              const SizedBox(height: AppSpace.xxs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                child: Text(
                  context.l10n.foldersTitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.badge.copyWith(color: scheme.onSurfaceVariant),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.fromTheme(theme);
    final text = AppText.of(theme);
    final accent = stop.color ?? scheme.primary;
    final discBg = current
        ? accent
        : Color.alphaBlend(
            accent.withValues(alpha: AppAlpha.pressed),
            scheme.surfaceContainerHigh,
          );
    final count = stop.count ?? 0;
    return Semantics(
      button: true,
      selected: current,
      label: stop.name,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: flat
            ? BoxDecoration(
                color: current
                    ? accent.withValues(alpha: AppAlpha.hairline)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.l),
                border: current
                    ? Border.all(color: accent.withValues(alpha: AppAlpha.soft))
                    : null,
              )
            : AppSurface.floating(theme, radius: AppRadius.l).copyWith(
                border: Border.all(
                  color: current
                      ? accent.withValues(alpha: AppAlpha.muted)
                      : tokens.hairline,
                  width: current ? 1.5 : 1,
                ),
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.l),
          child: Material(
            type: MaterialType.transparency,
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
                            size: AppIconSize.m,
                            color: current ? _onColor(accent) : accent,
                          ),
                        ),
                        if (count > 0)
                          PositionedDirectional(
                            top: -2,
                            end: -6,
                            child: Container(
                              constraints: const BoxConstraints(minWidth: 18),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.xs,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: current
                                    ? scheme.primaryContainer
                                    : tokens.card,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                border: Border.all(color: tokens.hairline),
                              ),
                              child: Text(
                                count > 999 ? '999+' : '$count',
                                textAlign: TextAlign.center,
                                style: text.badge.copyWith(
                                  color: current
                                      ? scheme.onPrimaryContainer
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xs,
                      ),
                      child: Text(
                        stop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: text.meta.copyWith(
                          fontWeight: current
                              ? AppWeight.strong
                              : AppWeight.medium,
                          color: current ? accent : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
