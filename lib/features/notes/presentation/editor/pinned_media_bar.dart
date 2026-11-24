import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/sheet_tile.dart';
import '../viewers/ink_layer.dart';
import '../viewers/ink_pen.dart';
import 'pen_tray.dart' show showInkSettings;

/// Sabit medya ayracı çubuğunun yüksekliği (dp).
const double kPinnedBarHeight = 40;

/// Sabit görsel/PDF akıllı işlemler levhası: Metni çıkar (OCR), Özetle,
/// Görevlere çevir ve Alan seçip sor eylemlerini tek Bento levhada sunar.
Future<void> showPinnedSmartActionsSheet(
  BuildContext context, {
  VoidCallback? onOcr,
  VoidCallback? onSummarize,
  VoidCallback? onExtractTasks,
  VoidCallback? onAreaAsk,
}) async {
  final run = await showAppSheet<VoidCallback>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      void pick(VoidCallback action) => Navigator.pop(sheetContext, action);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.l,
            0,
            AppSpace.l,
            AppSpace.l,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: l10n.pinnedSmartActions,
                padding: const EdgeInsets.only(bottom: AppSpace.m),
              ),
              SheetTileGrid(
                children: [
                  if (onOcr != null)
                    SheetTile.tile(
                      key: const ValueKey('pinned-smart-ocr'),
                      icon: Icons.document_scanner_outlined,
                      label: l10n.pinnedSmartOcr,
                      onTap: () => pick(onOcr),
                    ),
                  if (onSummarize != null)
                    SheetTile.tile(
                      key: const ValueKey('pinned-smart-summarize'),
                      icon: Icons.summarize_outlined,
                      label: l10n.pinnedSmartSummarize,
                      onTap: () => pick(onSummarize),
                    ),
                  if (onExtractTasks != null)
                    SheetTile.tile(
                      key: const ValueKey('pinned-smart-tasks'),
                      icon: Icons.checklist_rtl_outlined,
                      label: l10n.pinnedSmartTasks,
                      onTap: () => pick(onExtractTasks),
                    ),
                  if (onAreaAsk != null)
                    SheetTile.tile(
                      key: const ValueKey('pinned-smart-area-ask'),
                      icon: Icons.crop_free_outlined,
                      label: l10n.pinnedSmartAreaAsk,
                      onTap: () => pick(onAreaAsk),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  if (run != null && context.mounted) run();
}

/// Sabit medya çubuğunda kompakt araç düğmesi.
class PinnedBarButton extends StatelessWidget {
  const PinnedBarButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.filled = false,
    this.tonal = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final bool filled;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final strong = filled && selected;
    final soft = !strong && tonal && selected;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: AppIconSize.m,
      isSelected: selected,
      color: selected && !strong && !soft ? scheme.primary : null,
      style: strong
          ? IconButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            )
          : soft
          ? IconButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
            )
          : null,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}

/// Sabit bölmenin kendi kalem aracı satırı: silgi · hızlı renkler · geri al ·
/// yinele · kalem ayarları.
class PinnedPenQuickTools extends StatelessWidget {
  const PinnedPenQuickTools({
    super.key,
    required this.ink,
    required this.wideBar,
  });

  final InkController ink;
  final bool wideBar;

  static List<Color> quickInkColors(InkController ink) {
    final base = [
      for (final i in const [0, 5, 2, 4]) kInkPalette[i],
    ];
    final current = ink.color.toARGB32();
    if (base.any((c) => c.toARGB32() == current)) return base;
    return [...base.take(3), Color(current)];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: ink,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PinnedBarButton(
            key: const ValueKey('pinned-pen-eraser'),
            tooltip: l10n.eraser,
            icon: ink.eraser
                ? Icons.auto_fix_normal
                : Icons.auto_fix_normal_outlined,
            selected: ink.eraser,
            filled: true,
            onPressed: () => ink.setEraser(!ink.eraser),
          ),
          if (wideBar)
            for (final c in quickInkColors(ink))
              PinnedInkSwatch(
                key: ValueKey('pinned-pen-color-${c.toARGB32()}'),
                color: c,
                selected: !ink.eraser && c.toARGB32() == ink.color.toARGB32(),
                onTap: () => ink.setColor(c),
              ),
          PinnedInkColorMenu(ink: ink),
          PinnedBarButton(
            key: const ValueKey('pinned-pen-undo'),
            tooltip: l10n.undo,
            icon: Icons.undo,
            onPressed: ink.canUndo ? ink.undo : null,
          ),
          PinnedBarButton(
            key: const ValueKey('pinned-pen-redo'),
            tooltip: l10n.redo,
            icon: Icons.redo,
            onPressed: ink.canRedo ? ink.redo : null,
          ),
          PinnedBarButton(
            key: const ValueKey('pinned-pen-settings'),
            tooltip: l10n.inkSettings,
            icon: Icons.tune,
            onPressed: () => showInkSettings(context, ink),
          ),
        ],
      ),
    );
  }
}

/// Çubukta tek mürekkep renk noktası.
class PinnedInkSwatch extends StatelessWidget {
  const PinnedInkSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  static const double _dotSize = 22;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: InkResponse(
        radius: _dotSize,
        onTap: onTap,
        child: SizedBox(
          width: _dotSize + AppSpace.m + AppSpace.xxs,
          height: kPinnedBarHeight,
          child: Center(
            child: Container(
              width: _dotSize + AppSpace.xs + AppSpace.xxs,
              height: _dotSize + AppSpace.xs + AppSpace.xxs,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: AppAlpha.soft),
                    width: 0.8,
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

/// Kalem renk paleti açılır menüsü.
class PinnedInkColorMenu extends StatefulWidget {
  const PinnedInkColorMenu({super.key, required this.ink});

  final InkController ink;

  @override
  State<PinnedInkColorMenu> createState() => _PinnedInkColorMenuState();
}

class _PinnedInkColorMenuState extends State<PinnedInkColorMenu> {
  final _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final ink = widget.ink;
    final current = ink.color.toARGB32();
    return MenuAnchor(
      controller: _menu,
      menuChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xs,
            vertical: AppSpace.xxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in kInkPalette)
                PinnedInkSwatch(
                  key: ValueKey('pinned-pen-palette-${c.toARGB32()}'),
                  color: c,
                  selected: !ink.eraser && c.toARGB32() == current,
                  onTap: () {
                    ink.setColor(c);
                    _menu.close();
                  },
                ),
            ],
          ),
        ),
      ],
      builder: (context, menu, _) => Tooltip(
        message: context.l10n.inkColor,
        child: PinnedInkSwatch(
          key: const ValueKey('pinned-pen-color'),
          color: Color(current),
          selected: menu.isOpen,
          onTap: () => menu.isOpen ? menu.close() : menu.open(),
        ),
      ),
    );
  }
}

/// Medya aşağı çekilip sabitlemeyi bırakma eşiğine gelince çıkan alt rozet.
class PinnedUnpinHint extends StatelessWidget {
  const PinnedUnpinHint({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(AppSpace.s),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.m,
          vertical: AppSpace.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppText.of(theme).meta
              .copyWith(color: scheme.onInverseSurface),
        ),
      ),
    );
  }
}
