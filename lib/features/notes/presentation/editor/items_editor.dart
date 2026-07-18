import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/note_item.dart';

/// Checklist ve sıralı liste düzenleyicisi. Öğeler tutamaca UZUN BASIP
/// sürüklenerek sıralanır, Enter yeni öğe ekler, çöp ikonu siler.
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
        // "Dokununca aç" modunda odak değişince satırın kaç satır
        // göstereceği değişir; yeniden çiz.
        node.addListener(() {
          if (mounted && !widget.expandItems) setState(() {});
        });
        return node;
      });

  void _commit() => widget.onChanged(List.of(_items));

  void _updateText(int index, String text) {
    _items[index] = _items[index].copyWith(text: text);
    _commit();
  }

  void _toggle(int index, bool? value) {
    setState(() {
      _items[index] = _items[index].copyWith(checked: value ?? false);
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

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      buildDefaultDragHandles: false,
      header: widget.header,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton.icon(
              onPressed: () => _insertAfter(_items.length - 1),
              icon: const Icon(Icons.add, size: 20),
              label: Text(context.l10n.newItemHint),
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
                  // Varsayılan "next" davranışı odağı metin dışı bir öğeye
                  // taşıyıp klavyeyi kapatıp açıyordu; onEditingComplete onu
                  // bastırır, odak doğrudan yeni öğeye geçer.
                  onEditingComplete: () => _insertAfter(index),
                  textInputAction: TextInputAction.next,
                  // Tam göster modunda satır sarılıp büyür; "dokununca aç"
                  // modunda odaklanınca açılır, aksi hâlde tek satır.
                  maxLines: widget.expandItems || _focusFor(item).hasFocus
                      ? null
                      : 1,
                  style: checked
                      ? TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                        )
                      : null,
                  decoration: InputDecoration(
                    hintText: context.l10n.newItemHint,
                    filled: false,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                onPressed: () => _remove(index),
              ),
            ],
          ),
        );
      },
    );
  }
}
