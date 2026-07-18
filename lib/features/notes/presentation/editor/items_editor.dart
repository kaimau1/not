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
    // Gelen liste yerelden farklıysa benimse. ESKİDEN yalnızca kimliklerin
    // TAMAMEN değiştiği durumda yenileniyordu; dikte/hesap makinesi/AI bir
    // öğe eklediğinde eski kimlikler durduğundan koşul tutmuyor ve eklenen
    // öğe ekranda HİÇ görünmüyordu (editörden çıkıp girince beliriyordu).
    //
    // Yerel yazımda döngü riski yok: onChanged çağıran taraf durumu aynı
    // karede günceller, dönen liste yerelle birebir aynı olur ve buradaki
    // karşılaştırma false kalır.
    if (!_sameItems(_items, widget.items)) {
      setState(() => _items = List.of(widget.items));
    }
  }

  /// İki liste görünür olarak aynı mı (sıra + kimlik + metin + işaret).
  static bool _sameItems(List<NoteItem> a, List<NoteItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].text != b[i].text ||
          a[i].checked != b[i].checked) {
        return false;
      }
    }
    return true;
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

  void _updateText(NoteItem target, String text) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(text: text);
    _commit();
  }

  /// İşaretsizlerin bittiği (= ilk işaretlinin başladığı) konum. Hem yeni
  /// öğe hem de işareti değişen öğe buraya girer:
  /// - işaretlenen öğe → işaretli bloğun EN ÜSTÜne (en son işaretlenen üstte)
  /// - işareti kalkan öğe → işaretsizlerin sonuna
  int get _checkedStart {
    final first = _items.indexWhere((i) => i.checked);
    return first < 0 ? _items.length : first;
  }

  void _toggleItem(NoteItem target, bool? value) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    setState(() {
      final item = _items.removeAt(index).copyWith(checked: value ?? false);
      _items.insert(_checkedStart, item);
    });
    _commit();
  }

  void _insertAfter(NoteItem after) {
    final index = _items.indexWhere((i) => i.id == after.id);
    if (index < 0) return;
    final item = NoteItem(id: _uuid.v4(), text: '');
    setState(() => _items.insert(index + 1, item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  /// "Yeni öğe" düğmesiyle öğe ekler; işaretsizlerin sonuna girer.
  void _addItem() {
    final item = NoteItem(id: _uuid.v4(), text: '');
    setState(() => _items.insert(_checkedStart, item));
    _commit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(item).requestFocus();
    });
  }

  void _removeItem(NoteItem target) {
    setState(() => _items.removeWhere((i) => i.id == target.id));
    _controllers.remove(target.id)?.dispose();
    _focusNodes.remove(target.id)?.dispose();
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

  /// Öğe metni seçim araç çubuğu. Varsayılan araçlar (kes/kopyala/yapıştır ve
  /// "Tümünü seç") olduğu gibi korunur — böylece bir satırın metninin TAMAMI
  /// seçilebilir (madde 8; eskiden "Tümünü seç" seçim yerine panoya kopyalıyor,
  /// gerçek seçim ise kaldırılmıştı). Ayrıca ayrı bir "Tüm notu kopyala"
  /// seçeneği eklenir (alanlar arası gerçek seçim mümkün olmadığından tüm
  /// notu panoya almak için pratik karşılık).
  Widget _contextMenu(
    BuildContext context,
    EditableTextState editableState,
  ) {
    final l10n = context.l10n;
    final buttonItems = <ContextMenuButtonItem>[
      ...editableState.contextMenuButtonItems,
      ContextMenuButtonItem(
        label: l10n.copyWholeNote,
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

  /// Tek öğe satırı. [reorderIndex] verilirse satır sürüklenebilir;
  /// footer'daki işaretli öğelerde tutamak yoktur (sıraları zaten sabit).
  /// [orderNumber] sıralı listede gösterilen numaradır.
  Widget _itemRow(
    NoteItem item, {
    int? reorderIndex,
    int? orderNumber,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
          if (reorderIndex != null)
            ReorderableDelayedDragStartListener(
              index: reorderIndex,
              child: Icon(
                Icons.drag_indicator,
                size: 18,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            )
          else
            const SizedBox(width: 18),
          if (widget.showCheckboxes)
            Checkbox(
              value: item.checked,
              onChanged: (value) => _toggleItem(item, value),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${orderNumber ?? 0}.',
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
              onChanged: (text) => _updateText(item, text),
              contextMenuBuilder: (context, editableState) =>
                  _contextMenu(context, editableState),
              // Varsayılan "next" davranışı odağı metin dışı bir öğeye
              // taşıyıp klavyeyi kapatıp açıyordu; onEditingComplete onu
              // bastırır, odak doğrudan yeni öğeye geçer.
              onEditingComplete: () => _insertAfter(item),
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
              onPressed: () => _removeItem(item),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final showChecks = widget.showCheckboxes;

    // Checklist'te işaretli öğeler sürüklenebilir listenin DIŞINDA, footer'da
    // ayrı bir blok olarak durur (Keep'in "tamamlananlar" bölümü gibi).
    // Böylece "Yeni öğe" düğmesi tam istenen yere — işaretsizlerin altına,
    // işaretlilerin üstüne — doğal olarak düşer.
    final checkedItems =
        showChecks ? [for (final i in _items) if (i.checked) i] : const <NoteItem>[];
    final listItems =
        showChecks ? [for (final i in _items) if (!i.checked) i] : _items;

    final addButton = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add, size: 20),
        label: Text(l10n.newItemHint),
      ),
    );

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        addButton,
        for (final item in checkedItems) _itemRow(item),
        if (checkedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: TextButton.icon(
              onPressed: _deleteChecked,
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              label: Text(l10n.deleteChecked(checkedItems.length)),
              style: TextButton.styleFrom(foregroundColor: scheme.error),
            ),
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      buildDefaultDragHandles: false,
      header: widget.header,
      footer: footer,
      itemCount: listItems.length,
      // İşaretsizler _items'ın başında tutulduğundan (bkz. _checkedStart)
      // buradaki index'ler _items index'leriyle birebir örtüşür.
      onReorderItem: _reorder,
      itemBuilder: (context, index) => _itemRow(
        listItems[index],
        reorderIndex: index,
        orderNumber: index + 1,
      ),
    );
  }
}
