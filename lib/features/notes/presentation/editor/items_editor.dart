import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/note_item.dart';

/// Checklist ve sıralı liste düzenleyicisi. Öğeler tutamaca UZUN BASIP
/// sürüklenerek sıralanır, Enter yeni öğe ekler. Silme "x" düğmesi yalnızca
/// satır odaklıyken görünür (kaydırma/yazma sırasında yanlışlıkla basılmasın).
/// Checklist modunda işaretlenen öğeler otomatik listenin en altına düşer ve
/// "İşaretlileri sil" ile toplu silinebilir.
class ItemsEditor extends StatefulWidget {
  const ItemsEditor({
    super.key,
    required this.items,
    required this.onChanged,
    required this.showCheckboxes,
    this.expandItems = true,
    this.header,
    this.footer,
  });

  final List<NoteItem> items;
  final ValueChanged<List<NoteItem>> onChanged;
  final bool showCheckboxes;

  /// true: uzun satırlar tamamen sarılıp görünür. false: satır tek satırda
  /// kalır, yalnızca odaklanınca (dokununca) açılır.
  final bool expandItems;

  final Widget? header;
  final Widget? footer;

  @override
  State<ItemsEditor> createState() => _ItemsEditorState();
}

class _ItemsEditorState extends State<ItemsEditor> {
  static const _uuid = Uuid();

  late List<NoteItem> _items;
  final _controllers = <String, TextEditingController>{};
  final _focusNodes = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant ItemsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Editör açıkken yerel durum esastır; yalnızca öğe kimliklerinin
    // tamamen değiştiği (ör. başka cihazdan gelen) durumda yenile.
    final localIds = {for (final i in _items) i.id};
    final incomingIds = {for (final i in widget.items) i.id};
    if (localIds.intersection(incomingIds).isEmpty && incomingIds.isNotEmpty) {
      setState(() => _items = List.of(widget.items));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(NoteItem item) =>
      _controllers.putIfAbsent(
        item.id,
        () => TextEditingController(text: item.text),
      );

  FocusNode _focusFor(NoteItem item) => _focusNodes.putIfAbsent(item.id, () {
        final node = FocusNode();
        // Odak değişince (a) "dokununca aç" modunda satır yüksekliği, (b)
        // silme "x" düğmesinin görünürlüğü değişir; her iki durumda çiz.
        node.addListener(() {
          if (mounted) setState(() {});
        });
        return node;
      });

  void _commit() => widget.onChanged(List.of(_items));

  void _updateText(int index, String text) {
    _items[index] = _items[index].copyWith(text: text);
    _commit();
  }

  /// Checklist'te işaretlenen öğe otomatik listenin en altına düşer;
  /// işareti kalkan öğe işaretsizlerin sonuna geri çıkar (Keep davranışı).
  void _toggle(int index, bool? value) {
    final checked = value ?? false;
    setState(() {
      final item = _items.removeAt(index).copyWith(checked: checked);
      if (checked) {
        _items.add(item);
      } else {
        final firstChecked = _items.indexWhere((i) => i.checked);
        if (firstChecked < 0) {
          _items.add(item);
        } else {
          _items.insert(firstChecked, item);
        }
      }
    });
    _commit();
  }

  void _insertAfter(int index) {
    final item = NoteItem(id: _uuid.v4(), text: '');
    setState(() => _items.insert(index + 1, item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  void _remove(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    _controllers.remove(removed.id)?.dispose();
    _focusNodes.remove(removed.id)?.dispose();
    _commit();
  }

  /// İşaretli tüm öğeleri tek seferde siler (madde 18 — Keep'teki gibi
  /// tek tek silmeye gerek kalmaz).
  void _deleteChecked() {
    final removed = [for (final i in _items) if (i.checked) i];
    if (removed.isEmpty) return;
    setState(() => _items = [for (final i in _items) if (!i.checked) i]);
    for (final item in removed) {
      _controllers.remove(item.id)?.dispose();
      _focusNodes.remove(item.id)?.dispose();
    }
    _commit();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _commit();
  }

  /// Tüm not içeriğini panoya kopyalar ("Tümünü seç" seçeneği — ayrı
  /// TextField'lar arası gerçek seçim mümkün olmadığından pratik karşılığı).
  Future<void> _copyAll() async {
    final buffer = StringBuffer();
    for (var i = 0; i < _items.length; i++) {
      final text = _items[i].text;
      if (widget.showCheckboxes) {
        buffer.writeln('${_items[i].checked ? '[x]' : '[ ]'} $text');
      } else {
        buffer.writeln('${i + 1}. $text');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.allCopied)));
    }
  }

  /// Öğe metni seçim araç çubuğuna iki net seçenek ekler: "Satırı seç"
  /// (yalnız bu satır) ve "Tümünü seç" (tüm not — panoya kopyalar).
  Widget _contextMenu(
    BuildContext context,
    EditableTextState editableState,
    NoteItem item,
  ) {
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    final buttonItems = <ContextMenuButtonItem>[
      // Varsayılan kes/kopyala/yapıştır'ı koru; alandaki "tümünü seç"i
      // (yalnız o satır) kendi "Satırı seç" düğmemizle değiştiriyoruz.
      for (final button in editableState.contextMenuButtonItems)
        if (button.type != ContextMenuButtonType.selectAll) button,
      ContextMenuButtonItem(
        label: l10n.selectRow,
        onPressed: () {
          editableState.hideToolbar();
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        },
      ),
      ContextMenuButtonItem(
        label: l10n.selectAll,
        onPressed: () {
          editableState.hideToolbar();
          _copyAll();
        },
      ),
    ];
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final checkedCount =
        widget.showCheckboxes ? _items.where((i) => i.checked).length : 0;

    // Başlık bölgesi = editörün kendi başlığı + (checklist'te işaretli varsa)
    // "İşaretlileri sil" araç çubuğu.
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.header != null) widget.header!,
        if (checkedCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _deleteChecked,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: Text(l10n.deleteChecked(checkedCount)),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ),
          ),
      ],
    );

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      buildDefaultDragHandles: false,
      header: header,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: () => _insertAfter(_items.length - 1),
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.newItemHint),
            ),
          ),
          if (widget.footer != null) widget.footer!,
        ],
      ),
      itemCount: _items.length,
      onReorderItem: _reorder,
      itemBuilder: (context, index) {
        final item = _items[index];
        final checked = widget.showCheckboxes && item.checked;
        final focused = _focusFor(item).hasFocus;
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Uzun basınca sürükleme: anlık sürükleme dinleyicisi, tutamaca
              // denk gelen parmakta listenin kaydırılmasını engelliyordu
              // (kullanıcı "kaydıramıyorum" diye görüyordu).
              ReorderableDelayedDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              if (widget.showCheckboxes)
                Checkbox(
                  value: item.checked,
                  onChanged: (value) => _toggle(index, value),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '${index + 1}.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _controllerFor(item),
                  focusNode: _focusFor(item),
                  onChanged: (text) => _updateText(index, text),
                  contextMenuBuilder: (context, editableState) =>
                      _contextMenu(context, editableState, item),
                  // Varsayılan "next" davranışı odağı metin dışı bir öğeye
                  // taşıyıp klavyeyi kapatıp açıyordu; onEditingComplete onu
                  // bastırır, odak doğrudan yeni öğeye geçer.
                  onEditingComplete: () => _insertAfter(index),
                  textInputAction: TextInputAction.next,
                  // Tam göster modunda satır sarılıp büyür; "dokununca aç"
                  // modunda odaklanınca açılır, aksi hâlde tek satır.
                  maxLines: widget.expandItems || focused ? null : 1,
                  style: checked
                      ? TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        )
                      : null,
                  decoration: InputDecoration(
                    hintText: l10n.newItemHint,
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              // Silme "x" yalnızca satır odaklıyken görünür: kaydırırken ya
              // da yazarken yanlışlıkla basılmaz (madde 11-12). Odaksızken
              // yerini boş bir kutu tutar ki satırlar yatayda zıplamasın.
              if (focused)
                IconButton(
                  tooltip: l10n.removeItem,
                  icon: const Icon(Icons.close, size: 18),
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  onPressed: () => _remove(index),
                )
              else
                const SizedBox(width: 48),
            ],
          ),
        );
      },
    );
  }
}
