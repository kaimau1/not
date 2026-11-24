import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../core/a11y/color_names.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import 'format_menu.dart';
import 'text_wrap.dart';

/// Metin seçimi ve yazım önerisi için yeniden tasarlanmış Bento araç çubuğu.
///
/// Hem telefon (dokunmatik) hem tablet/web (fare sağ tık / seçim) için:
///  * En üstte bağlam / yazım önerisi hapları (varsa).
///  * Ana satırda Kopyala · Kes · Yapıştır · Tümünü seç (simge + kısa etiket).
///  * Metin seçiliyken ve [formatController] verilmişken hızlı satır içi
///    biçim şeridi (B · I · U · Renk · Vurgu · Biçim…).
///  * Aynı kart içinde `⋯` ile yerinde açılan ikincil eylemler (Ek göm,
///    Nota bağla, Tüm notu kopyala, Paylaş…).
class NoteSelectionToolbar extends StatefulWidget {
  const NoteSelectionToolbar({
    super.key,
    required this.editableState,
    required this.buttonItems,
    this.formatController,
    this.onFormatCommit,
    this.readOnly = false,
  }) : _spellSuggestions = const [],
       _spellActions = const [];

  const NoteSelectionToolbar.spell({
    super.key,
    required this.editableState,
    required List<ContextMenuButtonItem> suggestions,
    required List<ContextMenuButtonItem> actions,
  }) : buttonItems = const [],
       formatController = null,
       onFormatCommit = null,
       readOnly = false,
       _spellSuggestions = suggestions,
       _spellActions = actions;

  final EditableTextState editableState;
  final List<ContextMenuButtonItem> buttonItems;
  final WrapTextController? formatController;
  final VoidCallback? onFormatCommit;
  final bool readOnly;

  final List<ContextMenuButtonItem> _spellSuggestions;
  final List<ContextMenuButtonItem> _spellActions;

  bool get _isSpell => _spellSuggestions.isNotEmpty || _spellActions.isNotEmpty;

  @override
  State<NoteSelectionToolbar> createState() => _NoteSelectionToolbarState();
}

class _NoteSelectionToolbarState extends State<NoteSelectionToolbar>
    with SingleTickerProviderStateMixin {
  bool _moreOpen = false;
  _ColorStrip? _colorStrip;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );

  @override
  void initState() {
    super.initState();
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  static const _primaryTypes = <ContextMenuButtonType>{
    ContextMenuButtonType.copy,
    ContextMenuButtonType.cut,
    ContextMenuButtonType.paste,
    ContextMenuButtonType.selectAll,
  };

  ({
    List<ContextMenuButtonItem> leading,
    List<ContextMenuButtonItem> primary,
    List<ContextMenuButtonItem> secondary,
  })
  _partition() {
    final items = widget.buttonItems;
    final firstPrimary = items.indexWhere(
      (i) => _primaryTypes.contains(i.type),
    );
    final split = firstPrimary < 0 ? 0 : firstPrimary;
    final leading = <ContextMenuButtonItem>[];
    final primary = <ContextMenuButtonItem>[];
    final secondary = <ContextMenuButtonItem>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (_primaryTypes.contains(item.type)) {
        primary.add(item);
      } else if (i < split) {
        leading.add(item);
      } else {
        secondary.add(item);
      }
    }
    return (leading: leading, primary: primary, secondary: secondary);
  }

  void _toggleFormat(RichFormat format, {int? colorIndex}) {
    final ctl = widget.formatController;
    if (ctl == null || widget.readOnly) return;
    AppHaptics.tick();
    if (applyRichFormat(ctl, format, colorIndex: colorIndex)) {
      widget.onFormatCommit?.call();
    }
    if (mounted) setState(() {});
  }

  void _removeFormat(RichFormat format) {
    final ctl = widget.formatController;
    if (ctl == null || widget.readOnly) return;
    AppHaptics.tick();
    if (removeRichFormat(ctl, format)) {
      widget.onFormatCommit?.call();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = AppTokens.of(context);
    final text = AppText.of(theme);
    final l10n = context.l10n;
    final anchors = widget.editableState.contextMenuAnchors;
    final viewPad = MediaQuery.paddingOf(context);
    final keyboard = KeyboardInset.liveOf(context);
    final bottomInset = math.max(keyboard, viewPad.bottom) + AppSpace.s;
    final topInset = viewPad.top + AppSpace.s;
    const horizInset = AppSpace.s;
    final screen = MediaQuery.sizeOf(context);
    final maxCardWidth = math.min(screen.width - horizInset * 2, 400.0);

    final Widget cardBody;
    if (widget._isSpell) {
      cardBody = _buildSpellBody(context, theme, scheme, text);
    } else {
      cardBody = _buildMainBody(context, theme, scheme, text, l10n);
    }

    final anim = CurvedAnimation(
      parent: _enter,
      curve: AppMotion.curveOf(context, AppMotion.emphasized),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizInset,
        topInset,
        horizInset,
        bottomInset,
      ),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchors.primaryAnchor - Offset(horizInset, topInset),
          anchorBelow:
              (anchors.secondaryAnchor ?? anchors.primaryAnchor) -
              Offset(horizInset, topInset),
        ),
        child: TextFieldTapRegion(
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: anim.drive(Tween<double>(begin: 0.96, end: 1)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Material(
                  key: const ValueKey('note-selection-toolbar'),
                  color: scheme.surfaceContainerHigh,
                  elevation: 6,
                  shadowColor: scheme.shadow.withValues(alpha: AppAlpha.scrim),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.l),
                    side: BorderSide(
                      color: tokens.accentBorder ?? tokens.hairline,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xs + AppSpace.xxs),
                    child: cardBody,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpellBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    AppText text,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget._spellSuggestions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget._spellSuggestions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpace.xs),
                  _ActionPill(
                    label: widget._spellSuggestions[i].label ?? '',
                    accent: i == 0,
                    onTap: widget._spellSuggestions[i].onPressed,
                    text: text,
                    scheme: scheme,
                  ),
                ],
              ],
            ),
          ),
        if (widget._spellSuggestions.isNotEmpty &&
            widget._spellActions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
            ),
          ),
        if (widget._spellActions.isNotEmpty)
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final item in widget._spellActions)
                _ActionPill(
                  label: item.label ?? '',
                  onTap: item.onPressed,
                  text: text,
                  scheme: scheme,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainBody(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    AppText text,
    dynamic l10n,
  ) {
    final parts = _partition();
    final ctl = widget.formatController;
    final sel = widget.editableState.textEditingValue.selection;
    final hasSelection = sel.isValid && !sel.isCollapsed;
    final showFormat = !widget.readOnly && ctl != null && hasSelection;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parts.leading.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < parts.leading.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpace.xs),
                  _ActionPill(
                    icon: _iconForItem(parts.leading[i]),
                    label: _labelFor(context, parts.leading[i]),
                    accent: true,
                    onTap: parts.leading[i].onPressed,
                    text: text,
                    scheme: scheme,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        if (parts.primary.isNotEmpty || parts.secondary.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (parts.primary.isNotEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < parts.primary.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpace.xxs),
                          _PrimaryClipButton(
                            icon: _iconForType(parts.primary[i].type),
                            label: _labelFor(context, parts.primary[i]),
                            onTap: parts.primary[i].onPressed,
                            text: text,
                            scheme: scheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (parts.secondary.isNotEmpty) ...[
                if (parts.primary.isNotEmpty)
                  Container(
                    width: 1,
                    height: AppIconSize.l,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                    color: scheme.outlineVariant.withValues(
                      alpha: AppAlpha.soft,
                    ),
                  ),
                Tooltip(
                  message: l10n.selectionToolbarMore as String,
                  child: InkWell(
                    key: const ValueKey('selection-toolbar-more'),
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    onTap: () => setState(() => _moreOpen = !_moreOpen),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s,
                        vertical: AppSpace.xs + AppSpace.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: _moreOpen
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest.withValues(
                                alpha: AppAlpha.muted,
                              ),
                        borderRadius: BorderRadius.circular(AppRadius.m),
                      ),
                      child: Icon(
                        _moreOpen
                            ? Icons.expand_less_rounded
                            : Icons.more_horiz_rounded,
                        size: AppIconSize.m,
                        color: _moreOpen
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (showFormat) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
            ),
          ),
          _QuickFormatRow(
            controller: ctl,
            activeStrip: _colorStrip,
            onToggle: _toggleFormat,
            onToggleStrip: (strip) => setState(
              () => _colorStrip = _colorStrip == strip ? null : strip,
            ),
            scheme: scheme,
            text: text,
          ),
          if (_colorStrip != null) ...[
            const SizedBox(height: AppSpace.xs),
            _QuickColorRow(
              mode: _colorStrip!,
              onPick: (index) => _toggleFormat(
                _colorStrip == _ColorStrip.text
                    ? RichFormat.color
                    : RichFormat.highlight,
                colorIndex: index,
              ),
              onRemove: () => _removeFormat(
                _colorStrip == _ColorStrip.text
                    ? RichFormat.color
                    : RichFormat.highlight,
              ),
              scheme: scheme,
            ),
          ],
        ],
        if (_moreOpen && parts.secondary.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
            child: Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
            ),
          ),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              for (final item in parts.secondary)
                _ActionPill(
                  icon: _iconForItem(item),
                  label: _labelFor(context, item),
                  onTap: item.onPressed,
                  text: text,
                  scheme: scheme,
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _labelFor(BuildContext context, ContextMenuButtonItem item) {
    final custom = item.label;
    if (custom != null && custom.isNotEmpty) return custom;
    return AdaptiveTextSelectionToolbar.getButtonLabel(context, item);
  }

  IconData _iconForType(ContextMenuButtonType type) => switch (type) {
    ContextMenuButtonType.copy => AppIcons.copy,
    ContextMenuButtonType.cut => Icons.content_cut_rounded,
    ContextMenuButtonType.paste => Icons.content_paste_rounded,
    ContextMenuButtonType.selectAll => Icons.select_all_rounded,
    ContextMenuButtonType.delete => Icons.delete_outline_rounded,
    ContextMenuButtonType.share => Icons.share_outlined,
    ContextMenuButtonType.lookUp => Icons.manage_search_rounded,
    ContextMenuButtonType.searchWeb => Icons.travel_explore_rounded,
    ContextMenuButtonType.liveTextInput => Icons.document_scanner_outlined,
    ContextMenuButtonType.custom => Icons.bolt_rounded,
  };

  IconData _iconForItem(ContextMenuButtonItem item) {
    if (item.type != ContextMenuButtonType.custom) {
      return _iconForType(item.type);
    }
    return Icons.auto_awesome_outlined;
  }
}

enum _ColorStrip { text, highlight }

class _PrimaryClipButton extends StatelessWidget {
  const _PrimaryClipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.text,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final AppText text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.m),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.s, color: scheme.primary),
            const SizedBox(height: AppSpace.xxs),
            Text(
              label,
              style: text.meta.copyWith(
                color: scheme.onSurface,
                fontWeight: AppWeight.medium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    this.icon,
    required this.label,
    required this.onTap,
    required this.text,
    required this.scheme,
    this.accent = false,
  });

  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final AppText text;
  final ColorScheme scheme;
  final bool accent;

  @override
  Widget build(BuildContext context) => Material(
    color: accent
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: AppAlpha.muted),
    borderRadius: BorderRadius.circular(AppRadius.s),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.s),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s,
          vertical: AppSpace.xs + AppSpace.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: AppIconSize.xs,
                color: accent
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpace.xs),
            ],
            Text(
              label,
              style: text.meta.copyWith(
                color: accent ? scheme.onPrimaryContainer : scheme.onSurface,
                fontWeight: AppWeight.medium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuickFormatRow extends StatelessWidget {
  const _QuickFormatRow({
    required this.controller,
    required this.activeStrip,
    required this.onToggle,
    required this.onToggleStrip,
    required this.scheme,
    required this.text,
  });

  final WrapTextController controller;
  final _ColorStrip? activeStrip;
  final void Function(RichFormat format, {int? colorIndex}) onToggle;
  final ValueChanged<_ColorStrip> onToggleStrip;
  final ColorScheme scheme;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final mark = activeRichFormats(controller);
        Widget btn({
          required Key key,
          required IconData icon,
          required String tooltip,
          required bool active,
          required VoidCallback onTap,
        }) => Tooltip(
          message: tooltip,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(AppRadius.s),
            onTap: onTap,
            child: Container(
              width: AppSpace.xxl + AppSpace.s,
              height: AppSpace.xxl + AppSpace.xs,
              decoration: BoxDecoration(
                color: active ? scheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.s),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: AppIconSize.s,
                color: active
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            btn(
              key: const ValueKey('sel-fmt-bold'),
              icon: Icons.format_bold_rounded,
              tooltip: l10n.formatBold,
              active: mark.bold,
              onTap: () => onToggle(RichFormat.bold),
            ),
            btn(
              key: const ValueKey('sel-fmt-italic'),
              icon: Icons.format_italic_rounded,
              tooltip: l10n.formatItalic,
              active: mark.italic,
              onTap: () => onToggle(RichFormat.italic),
            ),
            btn(
              key: const ValueKey('sel-fmt-underline'),
              icon: Icons.format_underlined_rounded,
              tooltip: l10n.formatUnderline,
              active: mark.underline,
              onTap: () => onToggle(RichFormat.underline),
            ),
            btn(
              key: const ValueKey('sel-fmt-color'),
              icon: Icons.format_color_text_rounded,
              tooltip: l10n.formatTextColor,
              active: activeStrip == _ColorStrip.text || mark.color != null,
              onTap: () => onToggleStrip(_ColorStrip.text),
            ),
            btn(
              key: const ValueKey('sel-fmt-highlight'),
              icon: Icons.border_color_rounded,
              tooltip: l10n.formatHighlight,
              active:
                  activeStrip == _ColorStrip.highlight ||
                  mark.highlight != null,
              onTap: () => onToggleStrip(_ColorStrip.highlight),
            ),
          ],
        );
      },
    );
  }
}

class _QuickColorRow extends StatelessWidget {
  const _QuickColorRow({
    required this.mode,
    required this.onPick,
    required this.onRemove,
    required this.scheme,
  });

  final _ColorStrip mode;
  final ValueChanged<int> onPick;
  final VoidCallback onRemove;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final palette = NoteColors.richPalette;
    final names = richPaletteNames(context.l10n);
    final filled = mode == _ColorStrip.highlight;
    final title = filled
        ? context.l10n.formatHighlight
        : context.l10n.formatTextColor;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < palette.length; i++)
          Semantics(
            button: true,
            label: '$title: ${names[i]}',
            excludeSemantics: true,
            onTap: () => onPick(i + 1),
            child: InkWell(
              onTap: () => onPick(i + 1),
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.xs),
                child: Container(
                  width: AppIconSize.l,
                  height: AppIconSize.l,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled
                        ? palette[i].withValues(alpha: AppAlpha.soft)
                        : Colors.transparent,
                    border: Border.all(color: palette[i], width: AppSpace.xxs),
                  ),
                ),
              ),
            ),
          ),
        Tooltip(
          message: context.l10n.formatRemove,
          child: InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xs),
              child: Icon(
                Icons.format_color_reset_outlined,
                size: AppIconSize.s,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
