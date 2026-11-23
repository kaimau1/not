import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../domain/attachment.dart';
import '../../domain/note_table.dart';

/// Tablonun İÇİ bu referans genişlikte dizilir ve kutuya ölçeklenir
/// (`FittedBox`, metin kutusuyla aynı yol — bkz. `TextPageBox`): kutunun
/// oranı cihazdan bağımsız kalır, köşeden boyutlandırmak tabloyu bütünüyle
/// büyütür/küçültür.
const double kTableRefWidth = 340;

/// Hücre yazısının satır yüksekliği (AppText.body 14/20) — dikme yazı
/// [StrutStyle] ile bu yüksekliğe kilitlenir: tablonun boyu platformdan
/// bağımsız (oran senkronda iki cihaz arasında gidip gelmesin).
const double _kLine = 20;
const EdgeInsets _kCellPad = EdgeInsets.symmetric(
  horizontal: AppSpace.s,
  vertical: AppSpace.xs + AppSpace.xxs,
);
const double _kFooter = 34;
const double _kBorder = 1;

/// Yeni tablonun kutu oranı için yükseklik (genişlik 1000 birim).
int tableHeightUnits(int rows) {
  final h =
      rows * (_kLine + _kCellPad.vertical + _kBorder) + _kBorder + _kFooter;
  return (1000 * h / kTableRefWidth).round();
}

/// Odaktaki (ya da az önce bırakılan) tablo hücresi: "Gün ekle" gibi
/// "imlece yaz" işleri tablo hücresine de yazsın (kullanıcı isteği
/// 2026-11-23). Başka bir metin alanı (gövde, madde, başlık) odak alınca
/// hedef düşer — menü/levha açılınca düşmez (oradan seçilen iş hücreye
/// yazsın).
abstract final class NoteTableFocus {
  static _TablePageBoxState? _owner;
  static bool _listening = false;

  /// Yeni eklenen tablonun kimliği: kutu ilk çizildiğinde ilk hücreyi açar.
  static String? openOnMount;

  static void _claim(_TablePageBoxState s) {
    _owner = s;
    if (_listening) return;
    FocusManager.instance.addListener(_onFocus);
    _listening = true;
  }

  static void _release(_TablePageBoxState s) {
    if (identical(_owner, s)) _drop();
  }

  static void _drop() {
    _owner = null;
    if (!_listening) return;
    FocusManager.instance.removeListener(_onFocus);
    _listening = false;
  }

  static void _onFocus() {
    final f = FocusManager.instance.primaryFocus;
    final owner = _owner;
    if (f == null || owner == null || identical(f, owner._focus)) return;
    if (f.context?.findAncestorStateOfType<EditableTextState>() != null) {
      _drop();
    }
  }

  /// [text]'i odaktaki / son tablo hücresinin imlecine yazar; hücre yoksa
  /// false (çağıran gövdeye yazar).
  static bool insert(String text) => _owner?._insert(text) ?? false;
}

/// **SAYFADA TABLO** (kullanıcı isteği 2026-11-23). Hücreye dokun = yaz
/// (yalnız açık hücre metin alanıdır — büyük tabloda yüzlerce alan
/// kurulmaz), Enter = sonraki hücre (son hücrede yeni satır), "+ Satır ekle",
/// ⚙ = seçenekler (satır ekle/sil, 2-3-4 sütun, başlık satırı, sütunları
/// eşitle, sil). Hücre yazarken sütun sınırları sürüklenerek genişlik
/// ayarlanır; basılı tutmak tabloyu taşır, seçince köşeden boyutlanır.
///
/// Yazı gecikmeli ([_TablePageBoxState._commits]: 1 sn, en geç 8 sn) nota
/// geçer; boy değişince (yeni satır, satıra sığmayan yazı) hemen — kutu
/// tabloyla birlikte uzasın.
class TablePageBox extends StatefulWidget {
  const TablePageBox({
    super.key,
    required this.attachment,
    required this.onChanged,
    this.onRemove,
    this.editable = true,
  });

  final Attachment attachment;
  final ValueChanged<Attachment> onChanged;
  final VoidCallback? onRemove;

  /// false: salt görüntü (önizleme, salt okunur not).
  final bool editable;

  @override
  State<TablePageBox> createState() => _TablePageBoxState();
}

class _TablePageBoxState extends State<TablePageBox> {
  late NoteTable _table = NoteTable.of(widget.attachment) ?? NoteTable.blank(2);

  /// Açık hücre (satır, sütun) ve son açılan (seçenekler / Gün ekle için).
  (int, int)? _editing;
  (int, int)? _last;
  TextSelection? _lastSelection;
  TextEditingController? _ctl;
  FocusNode? _focus;

  /// Yazının nota geçişi: 1 sn durunca, aralıksız yazarken en geç 8 sn.
  /// Her geçiş editörü baştan kurar (ek değişti — görsel taşımakla aynı yol);
  /// yazarken seyrek olsun diye uzun. Boy değişince ve hücreden çıkınca
  /// HEMEN yazılır; editör kapanırken bekleyen yazı [dispose]'da gider.
  final _commits = Debouncer(
    delay: const Duration(seconds: 1),
    maxWait: const Duration(seconds: 8),
  );

  /// Yerel değişiklik nota yazılmayı bekliyor.
  bool _pending = false;

  /// Açılıştaki tek seferlik oran düzeltmesi yapıldı mı (bkz. [_onNatural]).
  bool _corrected = false;

  /// Tablonun referans genişlikteki gerçek boyu.
  double _natural = 0;

  /// Sürüklenen sütun sınırı.
  int? _dragBorder;

  @override
  void initState() {
    super.initState();
    if (widget.editable && NoteTableFocus.openOnMount == widget.attachment.id) {
      NoteTableFocus.openOnMount = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startEdit(0, 0);
      });
    }
  }

  @override
  void didUpdateWidget(TablePageBox old) {
    super.didUpdateWidget(old);
    final incoming = NoteTable.of(widget.attachment);
    if (incoming == null || incoming == _table) return;
    // Yerel yazım sürerken (hücre açık ya da kayıt bekliyor) gelen eski
    // yankı/uzak kopya yazıyı geri almasın; yerel kayıt üstüne yazar.
    if (_editing != null || _pending) return;
    _table = incoming;
  }

  @override
  void dispose() {
    _commits.cancel();
    if (_pending) {
      // Editör kapanırken açık hücre: son yazı kaybolmasın. Editör de
      // kapanıyorsa (en sık yol) onun kaydı bunu taşır; tablo tek başına
      // kalkıyorsa (çok nadir) çağrı ağaç kilitliyken reddedilebilir.
      try {
        widget.onChanged(_applied());
      } catch (_) {}
    }
    NoteTableFocus._release(this);
    _focus?.dispose();
    _ctl?.dispose();
    super.dispose();
  }

  Attachment _applied() {
    var a = _table.applyTo(widget.attachment);
    if (_natural > 0) {
      a = a.copyWith(
        width: 1000,
        height: (1000 * _natural / kTableRefWidth).round(),
      );
    }
    return a;
  }

  void _commitNow() {
    _commits.cancel();
    _pending = false;
    widget.onChanged(_applied());
  }

  void _scheduleCommit() {
    _pending = true;
    _commits(() {
      if (mounted && _pending) _commitNow();
    });
  }

  /// Kayıttaki oranın verdiği boy ile gerçek boy arasındaki fark (oran).
  double _mismatch() {
    final w = widget.attachment.width ?? 0, h = widget.attachment.height ?? 0;
    if (w <= 0 || h <= 0 || _natural <= 0) return 1;
    final stored = kTableRefWidth * h / w;
    return (stored - _natural).abs() / _natural;
  }

  /// Tablonun boyu değişti. Oran YALNIZ yerel değişiklikte (açık hücre ya da
  /// bekleyen iş) ve açılışta bir kez yazılır: uzaktan gelen değişiklik
  /// yüzünden yazmak, iki açık cihaz arasında oranı gidip getirebilirdi.
  void _onNatural(double h) {
    if ((h - _natural).abs() < 0.5) return;
    _natural = h;
    if (!widget.editable || !mounted) return;
    final local = _editing != null || _pending;
    final first = !_corrected;
    _corrected = true;
    final off = _mismatch();
    if ((local && off > 0.01) || (first && off > 0.04)) _commitNow();
  }

  void _startEdit(int row, int column) {
    if (!widget.editable) return;
    if (_editing == (row, column)) return;
    if (row >= _table.rows || column >= _table.columns) return;
    final oldCtl = _ctl, oldFocus = _focus;
    final text = _table.cell(row, column);
    final ctl = TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: text.length);
    ctl.addListener(() => _onText(ctl, row, column));
    final focus = FocusNode(debugLabel: 'note-table-cell');
    focus.addListener(() => _onFocusChange(focus));
    _ctl = ctl;
    _focus = focus;
    // Bağlanmamış düğüme odak isteği bağlanınca uygulanır: eski hücre
    // aynı karede kalkar, klavye kapanıp açılmaz.
    focus.requestFocus();
    NoteTableFocus._claim(this);
    setState(() => _editing = (row, column));
    if (oldCtl != null || oldFocus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldFocus?.dispose();
        oldCtl?.dispose();
      });
    }
  }

  void _onText(TextEditingController ctl, int row, int column) {
    if (!identical(ctl, _ctl)) return;
    final next = _table.withCell(row, column, ctl.text);
    if (identical(next, _table)) return;
    _table = next;
    _scheduleCommit();
  }

  void _onFocusChange(FocusNode node) {
    if (!identical(node, _focus) || node.hasFocus) return;
    _endEdit();
  }

  void _endEdit() {
    final cell = _editing;
    if (cell == null || !mounted) return;
    _last = cell;
    _lastSelection = _ctl?.selection;
    if (_pending) _commitNow();
    setState(() => _editing = null);
  }

  /// Enter: sonraki hücre; son hücrede yeni satır açılır.
  void _next() {
    final cell = _editing;
    if (cell == null) return;
    final (r, c) = cell;
    if (c + 1 < _table.columns) {
      _startEdit(r, c + 1);
      return;
    }
    if (r + 1 >= _table.rows) {
      if (_table.rows >= kTableMaxRows) return;
      _table = _table.insertRow(_table.rows);
      _pending = true;
    }
    _startEdit(r + 1, 0);
  }

  void _addRow({int? after}) {
    if (_table.rows >= kTableMaxRows) return;
    final at = after == null ? _table.rows : after + 1;
    _table = _table.insertRow(at);
    _pending = true;
    _startEdit(at, 0);
    // Hücre açılamadıysa (salt okunur değil ama aynı hücre) yine kaydet.
    if (_editing == null) _commitNow();
  }

  bool _insert(String text) {
    if (!mounted || !widget.editable) return false;
    final ctl = _ctl;
    if (_editing != null && ctl != null) {
      final sel = ctl.selection;
      final range = sel.isValid
          ? TextRange(start: sel.start, end: sel.end)
          : TextRange.collapsed(ctl.text.length);
      ctl.value = ctl.value.replaced(range, text);
      return true;
    }
    final cell = _last;
    if (cell == null) return false;
    final (r, c) = cell;
    if (r >= _table.rows || c >= _table.columns) return false;
    final old = _table.cell(r, c);
    final sel = _lastSelection;
    final at = sel != null && sel.isValid
        ? sel.end.clamp(0, old.length)
        : old.length;
    _table = _table.withCell(r, c, old.replaceRange(at, at, text));
    _lastSelection = TextSelection.collapsed(offset: at + text.length);
    setState(() {});
    _commitNow();
    return true;
  }

  void _apply(NoteTable next) {
    if (next == _table) return;
    setState(() => _table = next);
    _commitNow();
  }

  Future<void> _openOptions() async {
    final row = (_editing ?? _last)?.$1;
    final l10n = context.l10n;
    final action = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => _TableOptions(table: _table, row: row),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'add-below' when row != null:
        _addRow(after: row);
      case 'delete-row' when row != null:
        _last = null;
        _apply(_table.removeRow(row));
      case 'header':
        _apply(_table.withHeader(!_table.header));
      case 'even':
        _apply(_table.evenedWidths());
      case 'delete':
        widget.onRemove?.call();
      default:
        if (action.startsWith('cols:')) {
          final n = int.tryParse(action.substring(5)) ?? _table.columns;
          if (_table.dropsText(n)) {
            final ok = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                content: Text(l10n.tableColumnsWillDrop),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            );
            if (ok != true || !mounted) return;
          }
          _last = null;
          _apply(_table.withColumns(n));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = AppText.of(theme).body.copyWith(color: scheme.onSurface);
    final strong = body.copyWith(fontWeight: AppWeight.strong);
    final strut = StrutStyle.fromTextStyle(body, forceStrutHeight: true);
    final line = scheme.outlineVariant;
    final table = _table;

    Widget cell(int r, int c) {
      final head = table.header && r == 0;
      final style = head ? strong : body;
      final editing = _editing == (r, c);
      final Widget content = editing
          ? TextField(
              key: ValueKey('note-table-field-$r-$c'),
              controller: _ctl,
              focusNode: _focus,
              style: style,
              strutStyle: strut,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration.collapsed(hintText: null),
              onEditingComplete: () {},
              onSubmitted: (_) => _next(),
            )
          : Text(
              table.cell(r, c),
              style: style,
              strutStyle: strut,
              textScaler: TextScaler.noScaling,
            );
      final padded = Padding(padding: _kCellPad, child: content);
      return TableCell(
        child: !widget.editable || editing
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: editing
                      ? scheme.primary.withValues(alpha: AppAlpha.hairline)
                      : Colors.transparent,
                ),
                child: padded,
              )
            // Yalnız DOKUNUŞ: basılı tutmak tuvale geçer (tabloyu taşır).
            : GestureDetector(
                key: ValueKey('note-table-cell-$r-$c'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _startEdit(r, c),
                child: padded,
              ),
      );
    }

    final grid = Table(
      columnWidths: {
        for (var c = 0; c < table.columns; c++)
          c: FractionColumnWidth(table.widths[c]),
      },
      border: TableBorder.all(
        color: line,
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      children: [
        for (var r = 0; r < table.rows; r++)
          TableRow(
            decoration: table.header && r == 0
                ? BoxDecoration(
                    color: scheme.primary.withValues(alpha: AppAlpha.hairline),
                  )
                : null,
            children: [for (var c = 0; c < table.columns; c++) cell(r, c)],
          ),
      ],
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.s),
          // Ağaç ŞEKLİ hücre açılıp kapanınca değişmez (kasma listesi md. 4):
          // tutamaklar yalnız liste olarak gelir/gider, ızgara yerinde kalır.
          child: Stack(
            children: [
              grid,
              if (widget.editable && _editing != null)
                ..._borderHandles(table, scheme),
            ],
          ),
        ),
        SizedBox(
          height: _kFooter,
          child: widget.editable ? _footer(context, scheme) : null,
        ),
      ],
    );

    return Semantics(
      label: widget.attachment.fileName,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: kTableRefWidth,
          child: Material(
            type: MaterialType.transparency,
            // Sistem yazı ölçeği tabloyu büyütmez: boy (oran) cihazdan
            // bağımsız; büyütmek için kutu köşeden boyutlanır.
            child: MediaQuery.withNoTextScaling(
              child: _NaturalHeight(onHeight: _onNatural, child: content),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    final label = AppText.of(Theme.of(context)).label
        .copyWith(color: scheme.primary);
    return Row(
      children: [
        InkWell(
          key: const ValueKey('note-table-add-row'),
          borderRadius: BorderRadius.circular(AppRadius.s),
          onTap: _addRow,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s,
              vertical: AppSpace.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: AppIconSize.s,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  l10n.tableAddRow,
                  style: label,
                  textScaler: TextScaler.noScaling,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Tooltip(
          message: l10n.tableOptions,
          child: InkWell(
            key: const ValueKey('note-table-options'),
            borderRadius: BorderRadius.circular(AppRadius.s),
            onTap: () => unawaited(_openOptions()),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xs + AppSpace.xxs),
              child: Icon(
                Icons.tune_rounded,
                size: AppIconSize.s,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hücre yazarken sütun sınırlarında sürükleme tutamağı.
  List<Widget> _borderHandles(NoteTable table, ColorScheme scheme) {
    final handles = <Widget>[];
    var x = 0.0;
    for (var b = 1; b < table.columns; b++) {
      x += table.widths[b - 1] * kTableRefWidth;
      final dragging = _dragBorder == b;
      handles.add(
        Positioned(
          key: ValueKey('note-table-border-$b'),
          left: x - AppSpace.s,
          width: AppSpace.l,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => setState(() => _dragBorder = b),
            onHorizontalDragUpdate: (d) => setState(
              () => _table = _table.moveBorder(b, d.delta.dx / kTableRefWidth),
            ),
            onHorizontalDragEnd: (_) {
              setState(() => _dragBorder = null);
              _commitNow();
            },
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpace.xs),
                child: Container(
                  width: AppSpace.s,
                  height: AppSpace.l + AppSpace.s,
                  decoration: BoxDecoration(
                    color: dragging
                        ? scheme.primary
                        : scheme.primary.withValues(alpha: AppAlpha.muted),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return handles;
  }
}

/// Tablo seçenekleri levhası; seçilen işin kimliğini döner.
class _TableOptions extends StatelessWidget {
  const _TableOptions({required this.table, required this.row});

  final NoteTable table;

  /// Son yazılan hücrenin satırı (yoksa satır işleri gösterilmez).
  final int? row;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: l10n.tableOptions),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.s,
              ),
              child: Text(l10n.tableMoveHint, style: text.meta),
            ),
            if (row != null) ...[
              ListTile(
                key: const ValueKey('note-table-add-below'),
                leading: const Icon(Icons.playlist_add_rounded),
                title: Text(l10n.tableAddRowBelow),
                onTap: () => Navigator.pop(context, 'add-below'),
              ),
              ListTile(
                key: const ValueKey('note-table-delete-row'),
                leading: const Icon(Icons.playlist_remove_rounded),
                title: Text(l10n.tableDeleteRow),
                onTap: () => Navigator.pop(context, 'delete-row'),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.l,
                vertical: AppSpace.s,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.view_column_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpace.l),
                  Expanded(
                    child: Text(l10n.tableColumnCount, style: text.body),
                  ),
                  for (final n in {...kTableColumnChoices, table.columns})
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpace.xs,
                      ),
                      child: ChoiceChip(
                        key: ValueKey('note-table-cols-$n'),
                        label: Text('$n'),
                        selected: n == table.columns,
                        onSelected: (_) => Navigator.pop(context, 'cols:$n'),
                      ),
                    ),
                ],
              ),
            ),
            SwitchListTile(
              key: const ValueKey('note-table-header'),
              secondary: const Icon(Icons.table_rows_outlined),
              title: Text(l10n.tableHeaderRow),
              value: table.header,
              onChanged: (_) => Navigator.pop(context, 'header'),
            ),
            if (!table.evenWidths)
              ListTile(
                key: const ValueKey('note-table-even'),
                leading: const Icon(Icons.view_week_outlined),
                title: Text(l10n.tableEqualWidths),
                onTap: () => Navigator.pop(context, 'even'),
              ),
            ListTile(
              key: const ValueKey('note-table-delete'),
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                l10n.tableDelete,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: AppSpace.s),
          ],
        ),
      ),
    );
  }
}

/// Çocuğun yerleşimden sonraki boyunu bildirir (değişince, kare sonunda).
class _NaturalHeight extends SingleChildRenderObjectWidget {
  const _NaturalHeight({required this.onHeight, super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderNaturalHeight(onHeight);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderNaturalHeight).onHeight = onHeight;
}

class _RenderNaturalHeight extends RenderProxyBox {
  _RenderNaturalHeight(this.onHeight);

  ValueChanged<double> onHeight;
  double _reported = -1;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if ((h - _reported).abs() < 0.5) return;
    _reported = h;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(h);
    });
  }
}

/// Tablo seçici: kaç sütun (2 · 3 · 4). Seçilen sütun sayısını döner.
Future<int?> showTablePicker(BuildContext context) => showAppSheet<int>(
  context: context,
  showDragHandle: true,
  builder: (context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
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
              title: l10n.tablePickTitle,
              padding: const EdgeInsets.only(bottom: AppSpace.s),
            ),
            Row(
              children: [
                for (final (i, n) in kTableColumnChoices.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: Material(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.m),
                      child: InkWell(
                        key: ValueKey('table-pick-$n'),
                        borderRadius: BorderRadius.circular(AppRadius.m),
                        onTap: () => Navigator.pop(context, n),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpace.m),
                          child: Column(
                            children: [
                              _MiniGrid(columns: n, color: scheme.primary),
                              const SizedBox(height: AppSpace.s),
                              Text(
                                l10n.tableColumns(n),
                                style: text.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  },
);

/// Seçicideki küçük tablo resmi.
class _MiniGrid extends StatelessWidget {
  const _MiniGrid({required this.columns, required this.color});

  final int columns;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSpace.xxxl + AppSpace.s,
    child: Table(
      border: TableBorder.all(
        color: color.withValues(alpha: AppAlpha.muted),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      children: [
        for (var r = 0; r < 3; r++)
          TableRow(
            decoration: r == 0
                ? BoxDecoration(color: color.withValues(alpha: AppAlpha.soft))
                : null,
            children: [
              for (var c = 0; c < columns; c++)
                const SizedBox(height: AppSpace.m),
            ],
          ),
      ],
    ),
  );
}
