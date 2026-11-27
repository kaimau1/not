part of 'table_page_box.dart';

/// Tablo ayarları levhası: satır/sütun sayısı ve başlık CANLI ([onTable]);
/// kapatan işlerin (satır ekle/sil, paylaş, sil) kimliğini döner. Karolar
/// ⋯ ızgarasıyla aynı dilde.
class _TableOptions extends StatefulWidget {
  const _TableOptions({
    required this.table,
    required this.row,
    required this.col,
    required this.onTable,
    required this.confirmDrop,
  });

  final NoteTable table;

  /// Son yazılan hücrenin satırı (yoksa satır işleri gösterilmez).
  final int? row;

  /// Etkin sütun (sıralama ve sütun ekle/sil hedefi).
  final int col;
  final ValueChanged<NoteTable> onTable;
  final Future<bool> Function(String message) confirmDrop;

  @override
  State<_TableOptions> createState() => _TableOptionsState();
}

class _TableOptionsState extends State<_TableOptions> {
  late NoteTable _t = widget.table;

  Future<void> _set(NoteTable next, {String? drop}) async {
    if (next == _t) return;
    if (drop != null && !await widget.confirmDrop(drop)) return;
    if (!mounted) return;
    setState(() => _t = next);
    widget.onTable(next);
  }

  bool _colHasText(int col) {
    if (col < 0 || col >= _t.columns) return false;
    for (var r = 0; r < _t.rows; r++) {
      if (_t.cell(r, col).trim().isNotEmpty) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final row = widget.row;
    final col = widget.col.clamp(0, _t.columns - 1);
    final canSort = _t.rows - (_t.header ? 1 : 0) >= 2;
    Widget pair(Widget a, Widget? b) => Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: AppSpace.s),
        Expanded(child: b ?? const SizedBox.shrink()),
      ],
    );
    final edits = <Widget>[
      if (row != null) ...[
        _OptionTile(
          key: const ValueKey('note-table-add-above'),
          icon: Icons.vertical_align_top_rounded,
          label: l10n.tableAddRowAbove,
          onTap: () => Navigator.pop(context, 'add-above'),
        ),
        _OptionTile(
          key: const ValueKey('note-table-add-below'),
          icon: Icons.playlist_add_rounded,
          label: l10n.tableAddRowBelow,
          onTap: () => Navigator.pop(context, 'add-below'),
        ),
        _OptionTile(
          key: const ValueKey('note-table-delete-row'),
          icon: Icons.playlist_remove_rounded,
          label: l10n.tableDeleteRow,
          onTap: () => Navigator.pop(context, 'delete-row'),
        ),
      ],
      if (_t.columns < kTableMaxColumns)
        _OptionTile(
          key: const ValueKey('note-table-add-col'),
          icon: Icons.view_column_outlined,
          label: l10n.tableInsertColumn,
          onTap: () => _set(_t.insertColAt(col + 1)),
        ),
      if (_t.columns > 2)
        _OptionTile(
          key: const ValueKey('note-table-del-col'),
          icon: Icons.delete_sweep_outlined,
          label: l10n.tableDeleteColumn,
          onTap: () => _set(
            _t.deleteColAt(col),
            drop: _colHasText(col) ? l10n.tableColumnsOneWillDrop : null,
          ),
        ),
      if (canSort) ...[
        _OptionTile(
          key: const ValueKey('note-table-sort-asc'),
          icon: Icons.arrow_upward_rounded,
          label: l10n.tableSortAsc,
          onTap: () => Navigator.pop(context, 'sort-asc'),
        ),
        _OptionTile(
          key: const ValueKey('note-table-sort-desc'),
          icon: Icons.arrow_downward_rounded,
          label: l10n.tableSortDesc,
          onTap: () => Navigator.pop(context, 'sort-desc'),
        ),
      ],
      if (!_t.evenWidths)
        _OptionTile(
          key: const ValueKey('note-table-even'),
          icon: Icons.view_week_outlined,
          label: l10n.tableEqualWidths,
          onTap: () => _set(_t.evenedWidths()),
        ),
    ];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
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
              title: l10n.tableOptions,
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
            ),
            Text(l10n.tableMoveHint, style: text.meta),
            const SizedBox(height: AppSpace.m),
            pair(
              _Stepper(
                key: const ValueKey('note-table-rows'),
                icon: Icons.table_rows_outlined,
                label: l10n.tableRowCount,
                value: _t.rows,
                min: 1,
                max: kTableMaxRows,
                onChanged: (n) => _set(
                  _t.withRows(n),
                  drop: _t.dropsRowText(n) ? l10n.tableRowsWillDrop : null,
                ),
              ),
              _Stepper(
                key: const ValueKey('note-table-cols'),
                icon: Icons.view_column_outlined,
                label: l10n.tableColumnCount,
                value: _t.columns,
                min: 1,
                max: kTableMaxColumns,
                onChanged: (n) => _set(
                  _t.withColumns(n),
                  drop: _t.dropsText(n) ? l10n.tableColumnsWillDrop : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s),
            _OptionTile(
              key: const ValueKey('note-table-header'),
              icon: Icons.title_rounded,
              label: l10n.tableHeaderRow,
              active: _t.header,
              trailing: Switch(
                value: _t.header,
                onChanged: (v) => _set(_t.withHeader(v)),
              ),
              onTap: () => _set(_t.withHeader(!_t.header)),
            ),
            const SizedBox(height: AppSpace.s),
            _OptionTile(
              key: const ValueKey('note-table-striped'),
              icon: Icons.table_rows_rounded,
              label: l10n.tableStripedRows,
              active: _t.striped,
              trailing: Switch(
                value: _t.striped,
                onChanged: (v) => _set(_t.withStriped(v)),
              ),
              onTap: () => _set(_t.withStriped(!_t.striped)),
            ),
            if (edits.isNotEmpty) ...[
              const SizedBox(height: AppSpace.l),
              SectionLabel(l10n.tableEditSection),
              const SizedBox(height: AppSpace.s),
              for (var i = 0; i < edits.length; i += 2) ...[
                if (i > 0) const SizedBox(height: AppSpace.s),
                pair(edits[i], i + 1 < edits.length ? edits[i + 1] : null),
              ],
            ],
            const SizedBox(height: AppSpace.l),
            SectionLabel(l10n.tableDataSection),
            const SizedBox(height: AppSpace.s),
            Row(
              children: [
                Expanded(
                  child: _OptionTile(
                    key: const ValueKey('note-table-copy-md'),
                    icon: AppIcons.copy,
                    label: l10n.tableCopyMarkdown,
                    vertical: true,
                    onTap: () => Navigator.pop(context, 'copy-md'),
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: _OptionTile(
                    key: const ValueKey('note-table-copy-csv'),
                    icon: Icons.grid_on_outlined,
                    label: l10n.tableCopyCsv,
                    vertical: true,
                    onTap: () => Navigator.pop(context, 'copy-csv'),
                  ),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: _OptionTile(
                    key: const ValueKey('note-table-paste-data'),
                    icon: Icons.content_paste_outlined,
                    label: l10n.tablePasteData,
                    vertical: true,
                    onTap: () => Navigator.pop(context, 'paste-data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.l),
            SectionLabel(l10n.share),
            const SizedBox(height: AppSpace.s),
            Row(
              children: [
                for (final (i, (kind, icon, label)) in [
                  ('image', Icons.image_outlined, l10n.tableShareImage),
                  ('pdf', Icons.picture_as_pdf_outlined, l10n.tableSharePdf),
                  ('word', Icons.description_outlined, l10n.tableShareWord),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: _OptionTile(
                      key: ValueKey('note-table-share-$kind'),
                      icon: icon,
                      label: label,
                      vertical: true,
                      onTap: () => Navigator.pop(context, 'share-$kind'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.l),
            _OptionTile(
              key: const ValueKey('note-table-delete'),
              icon: Icons.delete_outline,
              label: l10n.tableDelete,
              color: scheme.error,
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ⋯ ızgarasıyla aynı karo (tonlu zemin, yuvarlak köşe, vurgu renkli simge).
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.vertical = false,
    this.active = false,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool vertical;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainer;
    final style = AppText.of(theme).meta.copyWith(
      color: color ?? scheme.onSurface,
      fontWeight: AppWeight.medium,
    );
    final iconWidget = Icon(
      icon,
      size: AppIconSize.m,
      color: color ?? scheme.primary,
    );
    final labelWidget = Text(
      label,
      maxLines: vertical ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      textAlign: vertical ? TextAlign.center : TextAlign.start,
      style: style,
    );
    return Material(
      color: active ? scheme.primaryContainer : bg,
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.m),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: kMinInteractiveDimension,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s,
              vertical: AppSpace.xs,
            ),
            child: vertical
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpace.xs),
                      iconWidget,
                      const SizedBox(height: AppSpace.xs),
                      labelWidget,
                      const SizedBox(height: AppSpace.xs),
                    ],
                  )
                : Row(
                    children: [
                      iconWidget,
                      const SizedBox(width: AppSpace.s),
                      Expanded(child: labelWidget),
                      ?trailing,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Satır/sütun sayısı: − sayı + (basılı tutmak hızlı değiştirmez; satır
/// sayısı büyükse "+ Satır ekle" ya da İleri tuşu daha rahat).
class _Stepper extends StatelessWidget {
  const _Stepper({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final bg = theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainer;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s,
          AppSpace.s,
          AppSpace.s,
          AppSpace.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: AppIconSize.xs, color: scheme.primary),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.meta.copyWith(fontWeight: AppWeight.medium),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  key: const ValueKey('minus'),
                  tooltip: '−',
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: text.rowTitle.copyWith(fontWeight: AppWeight.strong),
                  ),
                ),
                IconButton(
                  key: const ValueKey('plus'),
                  tooltip: '+',
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Çocuğun yerleşimden sonraki boyunu (en ve boy) bildirir (kare sonunda).
class _NaturalSize extends SingleChildRenderObjectWidget {
  const _NaturalSize({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNaturalSize(onSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderNaturalSize).onSize = onSize;
}

class _RenderNaturalSize extends RenderProxyBox {
  _RenderNaturalSize(this.onSize);

  ValueChanged<Size> onSize;
  Size _reported = Size.zero;

  @override
  void performLayout() {
    super.performLayout();
    final next = size;
    if ((next.width - _reported.width).abs() < 0.5 &&
        (next.height - _reported.height).abs() < 0.5) {
      return;
    }
    _reported = next;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(next);
    });
  }
}
