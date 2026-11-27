import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'
    show
        Clipboard,
        ClipboardData,
        HardwareKeyboard,
        KeyDownEvent,
        KeyRepeatEvent,
        LogicalKeyboardKey;

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/note_colors.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/utils/rich_text.dart' show richSpans;
import '../../../../core/l10n_ext.dart';
import '../../../../core/tips.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/undo_snackbar.dart' show showAppMessage;
import '../../domain/attachment.dart';
import '../../data/table_export.dart';
import '../../domain/note_table.dart';
import 'selection_toolbar.dart';
import 'tag_tap.dart' show arrangeSelectionMenu;
import 'text_wrap.dart'
    show RichTextTheme, WrapTextController, cleanClipboardMenuItems;

part 'table_page_options.dart';

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

  /// **BİÇİM PANELİ HÜCREYE YAZAR** (kullanıcı bulgusu 2026-11-23: "tabloda
  /// biçim paneli çalışmıyor, tek tek çalışmalı"): açılan hücre editörün
  /// biçim hedefi olur ([cellFocused]: denetleyici, odak, kayıt, hiza);
  /// hücre kapanınca [cellDisposed]. Editör kurulurken bağlar, kapanırken
  /// (kendisiyse) çözer — sayfadaki, sabit bölmedeki kutular aynı yoldan.
  static void Function(
    WrapTextController controller,
    FocusNode focus,
    VoidCallback commit,
    ValueNotifier<TextAlign> align,
  )?
  cellFocused;
  static void Function(WrapTextController controller)? cellDisposed;
}

TextAlign _textAlign(CellAlign a) => switch (a) {
  CellAlign.start => TextAlign.start,
  CellAlign.center => TextAlign.center,
  CellAlign.end => TextAlign.end,
};

CellAlign _cellAlign(TextAlign a) => switch (a) {
  TextAlign.center => CellAlign.center,
  TextAlign.end || TextAlign.right => CellAlign.end,
  _ => CellAlign.start,
};

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
    this.onAspect,
    this.editable = true,
  });

  final Attachment attachment;

  /// Tablo İÇERİĞİ (hücreler, yapı, oran). Editörde kök KURULMADAN kaydedilir
  /// (`_updateTableContent`): yazarken editör baştan kurulmaz.
  final ValueChanged<Attachment> onChanged;
  final VoidCallback? onRemove;

  /// Gerçek boyun verdiği oran (genişlik / yükseklik) her değişince: tuval
  /// kutuyu kök kurulmadan büyütür/küçültür.
  final ValueChanged<double>? onAspect;

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
  WrapTextController? _ctl;
  FocusNode? _focus;

  /// Açık hücrenin hizası (biçim panelindeki Sola/Ortala/Sağa).
  ValueNotifier<TextAlign>? _align;

  /// Yazının nota geçişi (0,5 sn; aralıksız yazarken en geç 3 sn). Geçiş
  /// editörü KURMAZ ([TablePageBox.onChanged]); boy değişince ve hücreden
  /// çıkınca hemen yazılır, editör kapanırken bekleyen yazı [dispose]'da.
  final _commits = Debouncer();

  /// Yerel değişiklik nota yazılmayı bekliyor.
  bool _pending = false;

  /// Açılıştaki tek seferlik oran düzeltmesi yapıldı mı (bkz. [_onNatural]).
  bool _corrected = false;

  /// Tablonun mevcut yerleşim genişliğindeki gerçek boyu ve son ölçülen eni.
  double _natural = 0;
  double _layoutWidth = kTableRefWidth;
  double _measuredWidth = -1;

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
    final ctl = _ctl;
    if (ctl != null) NoteTableFocus.cellDisposed?.call(ctl);
    _focus?.dispose();
    ctl?.dispose();
    _align?.dispose();
    super.dispose();
  }

  Attachment _applied() {
    var a = _table.applyTo(widget.attachment);
    if (_natural > 0 && _layoutWidth > 0) {
      a = a.copyWith(
        width: 1000,
        height: (1000 * _natural / _layoutWidth).round(),
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
    final stored = _layoutWidth * h / w;
    return (stored - _natural).abs() / _natural;
  }

  /// Tablonun eni/boyu değişti. Oran yerel değişiklikte (açık hücre ya da
  /// bekleyen iş) ve referans genişlikte açılışta yazılır; farklı ekran
  /// genişliğinde canlı oran yine `onAspect` ile sayfaya bildirilir.
  void _onNatural(Size size) {
    final w = size.width > 0 ? size.width : _layoutWidth;
    final h = size.height;
    if (h <= 0) return;
    if ((h - _natural).abs() < 0.5 && (w - _measuredWidth).abs() < 0.5) return;
    _natural = h;
    _measuredWidth = w;
    if (!mounted) return;
    widget.onAspect?.call(w / h);
    if (!widget.editable) return;
    final local = _editing != null || _pending;
    final first = !_corrected;
    _corrected = true;
    final off = _mismatch();
    final refWidth = (w - kTableRefWidth).abs() < 1;
    if ((local && off > 0.01) || (first && off > 0.04 && refWidth)) {
      _commitNow();
    }
  }

  void _startEdit(int row, int column) {
    if (!widget.editable) return;
    if (_editing == (row, column)) return;
    if (row >= _table.rows || column >= _table.columns) return;
    TipOnce.showDeferred(
      context,
      TipOnce.tableGestures,
      () => context.l10n.tipTableGestures,
      icon: Icons.table_chart_outlined,
    );
    final oldCtl = _ctl, oldFocus = _focus, oldAlign = _align;
    final text = _table.cell(row, column);
    final ctl = WrapTextController(text: text)
      ..selection = TextSelection.collapsed(offset: text.length);
    ctl.richTheme = _richTheme();
    ctl.addListener(() => _onText(ctl, row, column));
    final focus = FocusNode(
      debugLabel: 'note-table-cell',
      onKeyEvent: _onCellKeyEvent,
    );
    focus.addListener(() => _onFocusChange(focus));
    final align = ValueNotifier(_textAlign(_table.alignOf(row, column)));
    align.addListener(() => _onAlign(align, row, column));
    _ctl = ctl;
    _focus = focus;
    _align = align;
    // Bağlanmamış düğüme odak isteği bağlanınca uygulanır: eski hücre
    // aynı karede kalkar, klavye kapanıp açılmaz.
    focus.requestFocus();
    NoteTableFocus._claim(this);
    NoteTableFocus.cellFocused?.call(ctl, focus, _commitNow, align);
    setState(() => _editing = (row, column));
    if (oldCtl != null || oldFocus != null) {
      if (oldCtl != null) NoteTableFocus.cellDisposed?.call(oldCtl);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldFocus?.dispose();
        oldCtl?.dispose();
        oldAlign?.dispose();
      });
    }
  }

  RichTextTheme _richTheme() {
    final scheme = Theme.of(context).colorScheme;
    return RichTextTheme(
      palette: NoteColors.richPalette,
      markerColor: scheme.onSurfaceVariant.withValues(alpha: AppAlpha.disabled),
    );
  }

  void _onAlign(ValueNotifier<TextAlign> align, int row, int column) {
    if (!identical(align, _align) || !mounted) return;
    final next = _table.withAlign(row, column, _cellAlign(align.value));
    if (identical(next, _table)) return;
    setState(() => _table = next);
    _commitNow();
  }

  void _onText(WrapTextController ctl, int row, int column) {
    if (!identical(ctl, _ctl)) return;
    final next = _table.withCell(row, column, ctl.logicalText);
    if (identical(next, _table)) return;
    if (_editing != (row, column)) {
      // Hücre düzenlemeden çıkmışken gelen değişiklik (biçim panelinden
      // kalın/renk/boyut): düz çizim [_table]'dan okunur — yeniden çizilip
      // HEMEN kaydedilir. Eskiden yalnız kayıt bekletiliyor, değişiklik
      // nota yazılana dek (1–2 sn) görünmüyordu (kullanıcı 2026-11-24).
      setState(() => _table = next);
      _commitNow();
      return;
    }
    _table = next;
    _scheduleCommit();
  }

  void _onFocusChange(FocusNode node) {
    if (!identical(node, _focus) || node.hasFocus) return;
    // Bekleyen biçim ("kalın"a basıp yazılan koşu) odak kaybında metne
    // yazılır — gövdedeki `_flushPending` ile aynı kural.
    final ctl = _ctl;
    if (ctl != null && ctl.hasPendingFormat) ctl.flushPendingFormat();
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

  KeyEventResult _onCellKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    if (key == LogicalKeyboardKey.tab) {
      if (shift) {
        _prev();
      } else {
        _next();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (shift) {
        _insert('\n');
        return KeyEventResult.handled;
      }
      _next();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
      _endEdit();
      _focus?.unfocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Shift+Tab: önceki hücre.
  void _prev() {
    final cell = _editing;
    if (cell == null) return;
    final (r, c) = cell;
    if (c > 0) {
      _startEdit(r, c - 1);
      return;
    }
    if (r > 0) {
      _startEdit(r - 1, _table.columns - 1);
    }
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
    var addedRow = false;
    if (r + 1 >= _table.rows) {
      if (_table.rows >= kTableMaxRows) return;
      _predictRow();
      _table = _table.insertRow(_table.rows);
      addedRow = true;
    }
    _startEdit(r + 1, 0);
    if (addedRow) _commitNow();
  }

  void _addRow({int? after, bool above = false}) {
    if (_table.rows >= kTableMaxRows) return;
    final at = after == null
        ? _table.rows
        : (above ? after : after + 1);
    _predictRow();
    _table = _table.insertRow(at);
    _pending = true;
    _startEdit(at, 0);
    // Yapısal satır eklemesi hücre odaklansa da bekletilmeden kaydedilir.
    _commitNow();
  }

  /// Boş satırın boyu (yazı satırı + dolgu + çizgi).
  static const double _rowHeight = _kLine + 12 + _kBorder;

  /// **SATIR EKLERKEN TİTREME YOK**: yeni satırın boyu bilindiği için kutu
  /// aynı karede büyür; ölçüm sonra yalnız ince farkı düzeltir.
  void _predictRow() {
    if (_natural <= 0) return;
    widget.onAspect?.call(_layoutWidth / (_natural + _rowHeight));
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

  Future<bool> _confirmDrop(String message) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
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
    return ok ?? false;
  }

  /// TABLO AYARLARI (kullanıcı isteği 2026-11-23: "satır ve sütun sayısı
  /// kendi ayarında değiştirilebilir; görsel veya PDF olarak paylaşılabilir,
  /// Word'e aktarılabilir"). Sayılar ve başlık levha açıkken CANLI uygulanır.
  Future<void> _openOptions() async {
    final l10n = context.l10n;
    final cell = _editing ?? _last;
    final row = cell?.$1;
    final col = cell?.$2 ?? 0;
    final action = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _TableOptions(
        table: _table,
        row: row,
        col: col,
        onTable: (next) {
          if (!mounted) return;
          _last = null;
          _apply(next);
        },
        confirmDrop: _confirmDrop,
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'add-above' when row != null:
        _addRow(after: row, above: true);
      case 'add-below' when row != null:
        _addRow(after: row);
      case 'delete-row' when row != null:
        _last = null;
        _apply(_table.removeRow(row));
      case 'sort-asc':
        _last = null;
        _apply(_table.sortByColumn(col));
        showAppMessage(context, l10n.tableSorted);
      case 'sort-desc':
        _last = null;
        _apply(_table.sortByColumn(col, ascending: false));
        showAppMessage(context, l10n.tableSorted);
      case 'copy-md':
        await Clipboard.setData(ClipboardData(text: _table.toMarkdown()));
        if (mounted) showAppMessage(context, l10n.copied);
      case 'copy-csv':
        await Clipboard.setData(ClipboardData(text: _table.toCsv()));
        if (mounted) showAppMessage(context, l10n.copied);
      case 'paste-data':
        unawaited(_pasteDelimited());
      case 'delete':
        widget.onRemove?.call();
      case 'share-image':
        unawaited(_share(TableExportKind.image));
      case 'share-pdf':
        unawaited(_share(TableExportKind.pdf));
      case 'share-word':
        unawaited(_share(TableExportKind.word));
    }
  }

  Future<void> _pasteDelimited() async {
    final l10n = context.l10n;
    final data = await Clipboard.getData('text/plain');
    final parsed = NoteTable.fromDelimited(data?.text ?? '');
    if (!mounted) return;
    if (parsed == null) {
      showAppMessage(context, l10n.tablePasteInvalid);
      return;
    }
    final hasContent = _table.cells.any((c) => c.trim().isNotEmpty);
    if (hasContent && !await _confirmDrop(l10n.tablePasteWillReplace)) return;
    if (!mounted) return;
    _last = null;
    _editing = null;
    _apply(parsed.withStriped(_table.striped));
    showAppMessage(context, l10n.tablePasted);
  }

  Future<void> _share(TableExportKind kind) async {
    final failed = context.l10n.tableShareFailed;
    try {
      await TableExport.share(
        _table,
        title: widget.attachment.fileName,
        kind: kind,
      );
    } catch (_) {
      if (mounted) showAppMessage(context, failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = AppText.of(theme).body.copyWith(color: scheme.onSurface);
    final strong = body.copyWith(fontWeight: AppWeight.strong);
    // Taban satır boyu sabit (boy platformdan bağımsız); biçim paneliyle
    // BÜYÜTÜLEN yazı satırı uzatabilir (zorlanmış satır boyu büyük yazıyı
    // üst üste bindirirdi).
    final strut = StrutStyle.fromTextStyle(body);
    final rich = _richTheme();
    final line = scheme.outlineVariant;
    final table = _table;

    Widget cell(int r, int c) {
      final head = table.header && r == 0;
      final style = head ? strong : body;
      final editing = _editing == (r, c);
      final align = _textAlign(table.alignOf(r, c));
      final raw = table.cell(r, c);
      final Widget content = editing
          ? TextField(
              key: ValueKey('note-table-field-$r-$c'),
              controller: _ctl,
              focusNode: _focus,
              style: style,
              strutStyle: strut,
              textAlign: align,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration.collapsed(hintText: null),
              contextMenuBuilder: (menuContext, state) => NoteSelectionToolbar(
                editableState: state,
                formatController: _ctl,
                onFormatCommit: _commitNow,
                buttonItems: arrangeSelectionMenu(
                  platform: cleanClipboardMenuItems(state),
                ),
              ),
              onEditingComplete: () {},
              onSubmitted: (_) => _next(),
            )
          : Text.rich(
              TextSpan(
                style: style,
                children: richSpans(
                  raw,
                  style,
                  palette: rich.palette,
                  markerColor: rich.markerColor,
                ),
              ),
              strutStyle: strut,
              textAlign: align,
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
                : (table.striped && r.isOdd
                      ? BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(
                            alpha: AppAlpha.soft,
                          ),
                        )
                      : null),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avail = constraints.maxWidth;
          final wide = avail.isFinite && avail >= kTableRefWidth;
          final layoutW = wide ? avail : kTableRefWidth;
          _layoutWidth = layoutW;
          // Geniş tuvalde (web/tablet) tabloyu büyütüp yazıları şişirmeyiz:
          // doğrudan gerçek genişlikte 1:1 ölçekte dizilir; yalnız çok dar
          // bölmelerde taşmayı önlemek için aşağı ölçeklenir.
          final box = SizedBox(
            width: layoutW,
            child: Material(
              type: MaterialType.transparency,
              child: MediaQuery.withNoTextScaling(
                child: _NaturalSize(onSize: _onNatural, child: content),
              ),
            ),
          );
          if (wide) return box;
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: box,
          );
        },
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
    final layoutW = _layoutWidth > 0 ? _layoutWidth : kTableRefWidth;
    var x = 0.0;
    for (var b = 1; b < table.columns; b++) {
      x += table.widths[b - 1] * layoutW;
      final dragging = _dragBorder == b;
      handles.add(
        Positioned(
          key: ValueKey('note-table-border-$b'),
          left: x - AppSpace.s,
          width: AppSpace.l,
          top: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => setState(() => _dragBorder = b),
              onHorizontalDragUpdate: (d) => setState(
                () => _table = _table.moveBorder(b, d.delta.dx / layoutW),
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
        ),
      );
    }
    return handles;
  }
}

/// Tabloyu PAYLAŞ (ek menüsü, sabit bölme, şerit — `shareAttachment`):
/// Görsel · PDF · Word seçilir, dosya üretilip sistem paylaşımı açılır.
Future<void> shareNoteTable(BuildContext context, Attachment a) async {
  final table = NoteTable.of(a);
  if (table == null) return;
  final l10n = context.l10n;
  final kind = await showAppSheet<TableExportKind>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
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
              title: l10n.share,
              padding: const EdgeInsets.only(bottom: AppSpace.s),
            ),
            Row(
              children: [
                for (final (i, (kind, icon, label)) in [
                  (
                    TableExportKind.image,
                    Icons.image_outlined,
                    l10n.tableShareImage,
                  ),
                  (
                    TableExportKind.pdf,
                    Icons.picture_as_pdf_outlined,
                    l10n.tableSharePdf,
                  ),
                  (
                    TableExportKind.word,
                    Icons.description_outlined,
                    l10n.tableShareWord,
                  ),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.s),
                  Expanded(
                    child: _OptionTile(
                      key: ValueKey('table-share-${kind.name}'),
                      icon: icon,
                      label: label,
                      vertical: true,
                      onTap: () => Navigator.pop(context, kind),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (kind == null) return;
  try {
    await TableExport.share(table, title: a.fileName, kind: kind);
  } catch (_) {
    if (context.mounted) showAppMessage(context, l10n.tableShareFailed);
  }
}

