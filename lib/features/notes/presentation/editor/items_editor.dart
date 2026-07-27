import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/note_item.dart';
import 'text_wrap.dart';

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
    this.floats = const [],
    this.pageBox,
    this.shrinkWrap = false,
    this.contentInsertion,
  });

  final List<NoteItem> items;
  final ValueChanged<List<NoteItem>> onChanged;
  final bool showCheckboxes;

  /// Sayfadaki görsellerin kapladığı bantlar (sayfa uzayı): madde metni
  /// bunların etrafından akar. Boşsa satırlar sıradan davranır.
  final List<FloatBox> floats;

  /// Sayfa içeriğinin kök kutusu — satırların konumu buna göre ölçülür.
  /// null ise sarma tümüyle kapalıdır.
  final RenderBox? Function()? pageBox;

  /// true: liste kendi kaydırmasını yapmaz, dıştaki sayfa kaydırır (serbest
  /// görsel tuvalinin içindeyken şart — iç içe iki kaydırıcı olamaz).
  /// ponytail: sürükleyerek sıralarken kenara gelince otomatik kaydırma
  /// çalışmaz; kısa listelerde sorun değil, gerekirse dış kaydırıcıyı
  /// sürükleme sırasında elle sürmek gerekir.
  final bool shrinkWrap;

  /// true: uzun satırlar tamamen sarılıp görünür. false: satır tek satırda
  /// kalır, yalnızca odaklanınca (dokununca) açılır.
  final bool expandItems;

  final Widget? header;
  final Widget? footer;

  /// Klavyeden gelen görselin nereye gideceği (Gboard pano çubuğu /
  /// "Yapıştır"). Ekleri not editörü yönettiğinden yapılandırma dışarıdan
  /// verilir; null ise klavye görseli hiç göndermez.
  final ContentInsertionConfiguration? contentInsertion;

  @override
  State<ItemsEditor> createState() => _ItemsEditorState();
}

class _ItemsEditorState extends State<ItemsEditor> {
  static const _uuid = Uuid();

  late List<NoteItem> _items;
  final _controllers = <String, WrapTextController>{};
  final _focusNodes = <String, FocusNode>{};

  /// Toplu işlem için seçilen öğeler.
  /// Metin alanları ayrı TextField olduğundan sistemin metin seçimi
  /// satırlar arasına geçemez; toplu kopyalama/silme bu modla yapılır.
  final _selected = <String>{};

  /// "Seç" düğmesiyle açılan mod. Seçim satırın sol kenarına uzun basışla da
  /// açılıyordu ama o bölge dar ve görünmez — hiçbir yerde yazmadığı için
  /// bulunamıyordu; düğme aynı modu görünür kılar (henüz hiçbir öğe
  /// seçilmemişken de açık kalması gerektiğinden ayrı bayrak şart).
  bool _selectMode = false;

  bool get _selectionMode => _selectMode || _selected.isNotEmpty;

  /// Seçim çubuğunu ekranın DİBİNE demirleyen katman denetleyicisi.
  /// Çubuk eskiden listenin header'ındaydı ve listeyle birlikte kayıyordu:
  /// uzun bir listede aşağıdaki maddeleri seçtikten sonra kopyalamak için
  /// başa dönmek gerekiyordu. Overlay'e taşınınca çubuk sayfa neresinde
  /// olursa olsun görünür kalır (madde 1).
  final _barController = OverlayPortalController();

  void _syncBar() {
    if (_selectionMode) {
      if (!_barController.isShowing) _barController.show();
    } else if (_barController.isShowing) {
      _barController.hide();
    }
  }

  void _exitSelection() {
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
    _syncBar();
  }

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

  WrapTextController _controllerFor(NoteItem item) => _controllers
      .putIfAbsent(item.id, () => WrapTextController(text: item.text));

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

  /// Satırların son ölçülen kaydırma değerleri (id → sol/sağ dolgu). Yeni
  /// eklenen satır KOMŞUSUNUN değeriyle doğsun diye tutulur: aksi hâlde satır
  /// bir kare kaymadan çizilip sonraki karede yerine atlıyor ve madde
  /// eklerken titreme görünüyordu.
  final _pads = <String, ({double start, double end})>{};

  /// Satırın TAMAMINI (tutamaç + kutucuk + metin + sil düğmesi) görselin
  /// yanına kaydırır. Yalnız metni sarmak yetmiyordu: kutucuk ve tutamaç
  /// satırın sol başında durduğundan görselin ALTINDA kalıyordu.
  Widget _floatRow(Widget child, {String? id}) {
    final pageBox = widget.pageBox;
    if (pageBox == null || widget.floats.isEmpty) return child;
    return _FloatRow(
      floats: widget.floats,
      pageBox: pageBox,
      initial: id == null ? null : (_pads[id] ?? _padOfNeighbour(id)),
      onMeasured: id == null ? null : (pad) => _pads[id] = pad,
      child: child,
    );
  }

  /// Yeni satırın başlangıç tahmini: bir üstündeki maddenin kaydırması
  /// (aynı görselin bandındaysa birebir doğrudur).
  ({double start, double end})? _padOfNeighbour(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index <= 0) return null;
    return _pads[_items[index - 1].id];
  }

  /// Madde metnini, sayfadaki görsellerin etrafından akacak şekilde ölçüme
  /// bağlar. Sayfa kutusu yoksa (liste serbest tuvalin dışında) dokunmaz.
  Widget _wrapped(
    WrapTextController controller,
    TextStyle style,
    Widget field,
  ) {
    final pageBox = widget.pageBox;
    if (pageBox == null) return field;
    return WrapFieldMeasure(
      controller: controller,
      style: style,
      floats: widget.floats,
      pageBox: pageBox,
      child: field,
    );
  }

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

  /// İşareti yeni değişmiş öğeler: id → YERLEŞİMDE kullanılacak eski durum.
  ///
  /// İşaretli öğeler listenin footer'ında ayrı bir blokta durduğundan, işaret
  /// anında değişirse satır bir widget ağacından diğerine taşınır; taşınan
  /// widget'ın State'i yeniden yaratıldığı için hiçbir geçiş animasyonu
  /// oynayamaz. Çözüm: görünüm hemen değişsin (solma oynar), YERLEŞİM kısa
  /// bir süre eski blokta kalsın, animasyon bitince gerçek yerine taşınsın.
  final _settling = <String, bool>{};

  static const _settleDuration = Duration(milliseconds: 220);

  /// Öğe hangi blokta çizilsin: yerleşiyorsa eski durumu, değilse gerçeği.
  bool _placedAsChecked(NoteItem item) => _settling[item.id] ?? item.checked;

  void _toggleItem(NoteItem target, bool? value) {
    final index = _items.indexWhere((i) => i.id == target.id);
    if (index < 0) return;
    final wasChecked = _items[index].checked;
    setState(() {
      _items[index] = _items[index].copyWith(checked: value ?? false);
      _settling[target.id] = wasChecked;
    });
    _commit();
    Future<void>.delayed(_settleDuration, () {
      if (!mounted) return;
      setState(() {
        _settling.remove(target.id);
        final current = _items.indexWhere((i) => i.id == target.id);
        if (current < 0) return;
        final item = _items.removeAt(current);
        _items.insert(_checkedStart, item);
      });
      _commit();
    });
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
    final removed = [
      for (final i in _items)
        if (i.checked) i,
    ];
    if (removed.isEmpty) return;
    setState(
      () => _items = [
        for (final i in _items)
          if (!i.checked) i,
      ],
    );
    for (final item in removed) {
      _controllers.remove(item.id)?.dispose();
      _focusNodes.remove(item.id)?.dispose();
    }
    _commit();
  }

  void _toggleSelection(NoteItem item) {
    setState(() {
      if (!_selected.remove(item.id)) _selected.add(item.id);
    });
    _syncBar();
  }

  /// Tümünü seç / seçimi bırak. Çubuk artık altta sabit olduğundan uzun
  /// listede tek dokunuşla hepsini kopyalamak mümkün.
  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((i) => i.id));
      }
    });
    _syncBar();
  }

  /// Seçili maddeleri liste sırasıyla panoya kopyalar.
  Future<void> _copySelected() async {
    final buffer = StringBuffer();
    var order = 1;
    for (final item in _items) {
      if (!_selected.contains(item.id)) continue;
      if (widget.showCheckboxes) {
        buffer.writeln('${item.checked ? '[x]' : '[ ]'} ${item.text}');
      } else {
        buffer.writeln('${order++}. ${item.text}');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    if (!mounted) return;
    _exitSelection();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.l10n.copied)));
  }

  void _deleteSelected() {
    final removed = [
      for (final i in _items)
        if (_selected.contains(i.id)) i,
    ];
    if (removed.isEmpty) return;
    setState(() {
      _items = [
        for (final i in _items)
          if (!_selected.contains(i.id)) i,
      ];
      _selected.clear();
      _selectMode = false;
    });
    _syncBar();
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
  Widget _contextMenu(BuildContext context, EditableTextState editableState) {
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
  Widget _itemRow(NoteItem item, {int? reorderIndex, int? orderNumber}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final controller = _controllerFor(item);
    final baseStyle = theme.textTheme.bodyLarge ?? const TextStyle();
    final checked = widget.showCheckboxes && item.checked;
    final focused = _focusFor(item).hasFocus;
    final selected = _selected.contains(item.id);

    // Sol bölge (tutamak + kutucuk/numara). Uzun basış seçim modunu açar:
    // metin alanına uzun basmak Android'in kendi metin seçimini açtığı için
    // madde seçimi buraya bağlandı, ikisi çakışmaz.
    final leading = GestureDetector(
      onLongPress: () => _toggleSelection(item),
      onTap: _selectionMode ? () => _toggleSelection(item) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seçim modunda sürükleme kapalı: iki uzun basış davranışı
          // birbirine karışmasın.
          if (reorderIndex != null && !_selectionMode)
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
          if (_selectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            )
          else if (widget.showCheckboxes)
            Checkbox(
              value: item.checked,
              onChanged: (value) => _toggleItem(item, value),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '${orderNumber ?? 0}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: _floatRow(
        id: item.id,
        Container(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
      // İşaretleme geçişi: satır sertçe sönmek yerine yumuşak solar.
      // Kutucuğun kendi tik animasyonu Material'dan geliyor; buradaki solma
      // ona eşlik eder. Üstü çizili hâl anında gelir — çizgi kısmi çizilemez,
      // yarım çizgi animasyonu için satırı yeniden çizmek gerekirdi.
      child: AnimatedOpacity(
        opacity: checked ? 0.55 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Row(
          children: [
            leading,
            Expanded(
              // Seçim modunda metne dokunmak düzenlemeye değil seçime gider.
              child: GestureDetector(
                onTap: _selectionMode ? () => _toggleSelection(item) : null,
                child: AbsorbPointer(
                  absorbing: _selectionMode,
                  child: _wrapped(
                    controller,
                    baseStyle,
                    TextField(
                      controller: controller,
                      focusNode: _focusFor(item),
                      onChanged: (_) => _updateText(item, controller.logicalText),
                      contextMenuBuilder: (context, editableState) =>
                          _contextMenu(context, editableState),
                      contentInsertionConfiguration: widget.contentInsertion,
                      // Varsayılan "next" davranışı odağı metin dışı bir öğeye
                      // taşıyıp klavyeyi kapatıp açıyordu; onEditingComplete onu
                      // bastırır, odak doğrudan yeni öğeye geçer.
                      onEditingComplete: () => _insertAfter(item),
                      textInputAction: TextInputAction.next,
                      // Tam göster modunda satır sarılıp büyür; "dokununca aç"
                      // modunda odaklanınca açılır, aksi hâlde tek satır.
                      maxLines: widget.expandItems || focused ? null : 1,
                      // Sarma planı bu stille hesaplanır; TextField'ın örtük
                      // varsayılanına bırakılırsa ölçüm ile çizim ayrışır ve
                      // satırlar yanlış kırılır (M3 varsayılanı zaten bodyLarge).
                      // Solma AnimatedOpacity'e bırakıldı (aşağıya bak); burada
                      // alfa verilirse iki kez soluyor.
                      style: checked
                          ? baseStyle.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: scheme.onSurfaceVariant,
                            )
                          : baseStyle,
                      decoration: InputDecoration(
                        hintText: l10n.newItemHint,
                        filled: false,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Silme "x" yalnızca satır odaklıyken görünür: kaydırırken ya
            // da yazarken yanlışlıkla basılmaz (madde 11-12). Odaksızken
            // yerini boş bir kutu tutar ki satırlar yatayda zıplamasın.
            if (focused && !_selectionMode)
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
      ),
        ),
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
    // Blok seçimi _placedAsChecked ile yapılır: işareti yeni değişen öğe,
    // solma animasyonu bitene kadar eski bloğunda kalır (bkz. _settling).
    final checkedItems = showChecks
        ? [
            for (final i in _items)
              if (_placedAsChecked(i)) i,
          ]
        : const <NoteItem>[];
    final listItems = showChecks
        ? [
            for (final i in _items)
              if (!_placedAsChecked(i)) i,
          ]
        : _items;

    final addButton = _floatRow(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.newItemHint),
          ),
          const Spacer(),
          // Toplu kopyalama/silme girişi. Uzun basış hâlâ çalışıyor ama
          // görünmez olduğundan bulunamıyordu.
          if (!_selectionMode && _items.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() => _selectMode = true);
                _syncBar();
              },
              icon: const Icon(Icons.checklist, size: 20),
              label: Text(l10n.select),
            ),
          ],
        ),
      ),
    );

    final footer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        addButton,
        for (final item in checkedItems) _itemRow(item),
        if (checkedItems.isNotEmpty)
          _floatRow(
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: TextButton.icon(
                onPressed: _deleteChecked,
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                label: Text(l10n.deleteChecked(checkedItems.length)),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
              ),
            ),
          ),
        if (widget.footer != null) widget.footer!,
      ],
    );

    final list = ReorderableListView.builder(
      // Alt dolgu, altta sabit duran seçim çubuğunun son maddeyi örtmemesi
      // için seçim modunda büyür.
      padding: EdgeInsets.only(bottom: _selectionMode ? 152 : 96),
      buildDefaultDragHandles: false,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
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

    // Seçim çubuğu ekranın dibinde, kaydırmadan bağımsız bir katmanda durur:
    // liste nerede olursa olsun "Kopyala" hep parmağın altındadır.
    return OverlayPortal(
      controller: _barController,
      overlayChildBuilder: _selectionBar,
      child: list,
    );
  }

  /// Ekranın dibine demirlenmiş seçim çubuğu (Overlay çocuğu). Klavye
  /// açıkken onun üstüne çıkar; sistem gezinme çubuğunun altında kalmaz.
  Widget _selectionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final allSelected = _items.isNotEmpty && _selected.length == _items.length;
    final hasSelection = _selected.isNotEmpty;
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8 + media.viewInsets.bottom + media.viewPadding.bottom,
      child: Material(
        color: scheme.primaryContainer,
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.cancel,
                icon: const Icon(Icons.close, size: 20),
                onPressed: _exitSelection,
              ),
              Expanded(
                child: Text(
                  l10n.itemsSelected(_selected.length),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: l10n.selectAllItems,
                icon: Icon(
                  allSelected ? Icons.deselect : Icons.select_all,
                  size: 20,
                ),
                onPressed: _items.isEmpty ? null : _toggleSelectAll,
              ),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: hasSelection ? _copySelected : null,
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: scheme.error,
                onPressed: hasSelection ? _deleteSelected : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sayfadaki görsellerin bandına denk gelen liste satırını görselin yanına
/// kaydırır (soldaki görsel → sağa iter, sağdaki görsel → sola daraltır).
/// Konum yerleşimden SONRA ölçülür; dolgu satırın DIŞINDAN uygulandığı için
/// ölçüm kendi kendini beslemez (ölçülen kutu her zaman tam genişliktir).
///
/// ponytail: satıra dörtte birden az yer kalıyorsa (görsel sütunu kaplıyor)
/// satır kaydırılmaz — altına itmek listenin dikey akışını değiştirmeyi
/// gerektirir; kullanıcı görseli daraltarak/taşıyarak çözer.
class _FloatRow extends StatefulWidget {
  const _FloatRow({
    required this.floats,
    required this.pageBox,
    required this.child,
    this.initial,
    this.onMeasured,
  });

  final List<FloatBox> floats;
  final RenderBox? Function() pageBox;

  /// Ölçüm gelene kadarki başlangıç kaydırması (komşu satırın değeri).
  final ({double start, double end})? initial;

  /// Ölçüm sonucu — çağıran, sonraki satırlara tahmin olarak verir.
  final ValueChanged<({double start, double end})>? onMeasured;

  final Widget child;

  @override
  State<_FloatRow> createState() => _FloatRowState();
}

class _FloatRowState extends State<_FloatRow> {
  late double _start = widget.initial?.start ?? 0;
  late double _end = widget.initial?.end ?? 0;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    return Padding(
      padding: EdgeInsets.only(left: _start, right: _end),
      child: widget.child,
    );
  }

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject();
    final page = widget.pageBox();
    if (box is! RenderBox || !box.hasSize || page == null || !page.hasSize) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: page);
    final width = box.size.width;
    final bottom = origin.dy + box.size.height;
    var start = 0.0;
    var end = 0.0;
    for (final f in widget.floats) {
      if (f.bottom <= origin.dy || f.top >= bottom) continue;
      final left = f.left - origin.dx;
      final right = f.right - origin.dx;
      if (right <= 0 || left >= width) continue;
      // Satır görselin GENİŞ tarafına geçer (metin sarmasıyla aynı kural).
      if (width - right >= left) {
        if (right > start) start = right;
      } else {
        final pad = width - left;
        if (pad > end) end = pad;
      }
    }
    if (width - start - end < width * 0.25) {
      start = 0;
      end = 0;
    }
    widget.onMeasured?.call((start: start, end: end));
    if ((start - _start).abs() > 0.5 || (end - _end).abs() > 0.5) {
      setState(() {
        _start = start;
        _end = end;
      });
    }
  }
}
