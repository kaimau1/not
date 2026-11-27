import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/keep_screen_on.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/sheet_keyboard.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../shopping/data/barcode_lookup.dart';
import '../../../shopping/data/receipt_ocr_parser.dart' show receiptUnitPriceForItem;
import '../../../shopping/data/shop_memory.dart';
import '../../../shopping/domain/shop_aisles.dart';
import '../../../shopping/domain/shop_item_meta.dart';
import '../../../shopping/domain/shop_recipes.dart';
import '../../../shopping/presentation/shop_aisle_order_sheet.dart';
import '../../../shopping/presentation/shop_budget_bar.dart';
import '../../../shopping/presentation/shop_due_strip.dart';
import '../../../shopping/presentation/shop_price_sheet.dart';
import '../../../shopping/presentation/shop_receipt_sheet.dart';
import '../../../shopping/presentation/shop_recipes_sheet.dart';
import '../../data/device_speech.dart';
import '../../data/quick_entry_memory.dart';
import '../../data/scan/scan_ocr.dart';
import '../../domain/note_item.dart';
import '../../domain/quick_entry.dart';
import '../../domain/smart_list.dart';
import '../qr_scan_screen.dart';

part 'store_mode_cards.dart';

sealed class _StoreRow {
  const _StoreRow();
}

class _AisleHeaderRow extends _StoreRow {
  const _AisleHeaderRow({
    required this.aisleIndex,
    required this.label,
    required this.remaining,
    required this.total,
    required this.allDone,
  });

  final int aisleIndex;
  final String label;
  final int remaining;
  final int total;
  final bool allDone;
}

class _ItemRow extends _StoreRow {
  const _ItemRow({required this.item, required this.aisleIndex});

  final NoteItem item;
  final int aisleIndex;
}

/// AL-5 + Faz 3 **MAĞAZA KİPİ v2**: tek elle, reyon/bütçe/market profilli,
/// canlı ortak senkronlu, ses + barkod + fiş OCR + tarif paketli alışveriş
/// deneyimi.
class StoreModeScreen extends StatefulWidget {
  const StoreModeScreen({
    super.key,
    required this.title,
    required this.initialItems,
    required this.onToggleItem,
    required this.onAddItem,
    required this.onSortByGroup,
    required this.onFinishChecked,
    this.liveItems,
    this.noteId = '',
    this.listKind = SmartListKind.shopping,
    this.isShared = false,
    this.currentUserName = '',
    this.learnedGroups = const {},
    this.shopMemoryListenable,
    this.dueItems = const [],
    this.onUpdateItem,
    this.onReplaceItems,
    this.onRecordPrice,
    this.onSetBudget,
    this.onSaveAisleOrder,
    this.onSaveBarcode,
    this.onSaveCustomRecipe,
    this.onDeleteCustomRecipe,
    this.onLearnAisle,
    this.onClassifyUnknownItem,
    this.onDismissDue,
    this.onNotifyAtStore,
    this.onRecordTrip,
    this.barcodeScanner,
    this.barcodeLookup,
  });

  final String title;
  final List<NoteItem> initialItems;

  /// Canlı madde akışı (ortak liste / başka cihaz senkronu).
  final ValueListenable<List<NoteItem>>? liveItems;

  /// Tek maddeyi işaretle / kaldır; güncel liste döner.
  final List<NoteItem> Function(String itemId) onToggleItem;

  /// Aklına geleni hızlı ekle (miktar toplama + reyon yerleştirme ile).
  final List<NoteItem> Function(String text) onAddItem;

  /// Reyona / gruba göre sırala; güncel liste döner.
  final List<NoteItem> Function() onSortByGroup;

  /// İşaretli maddeleri tamamla (hafıza + geri al editörde); güncel liste döner.
  final List<NoteItem> Function() onFinishChecked;

  final String noteId;
  final SmartListKind listKind;
  final bool isShared;
  final String currentUserName;
  final Map<String, int> learnedGroups;
  final ValueListenable<ShopMemory>? shopMemoryListenable;
  final List<({String name, int avgDays, int daysSince})> dueItems;

  final List<NoteItem> Function(NoteItem updated)? onUpdateItem;
  final List<NoteItem> Function(List<NoteItem> updated)? onReplaceItems;
  final void Function(
    String itemText,
    double price, {
    String store,
    String unit,
  })?
  onRecordPrice;
  final ValueChanged<double?>? onSetBudget;
  final void Function(String storeId, List<int> order)? onSaveAisleOrder;
  final ValueChanged<ShopBarcodeProduct>? onSaveBarcode;
  final ValueChanged<ShopRecipe>? onSaveCustomRecipe;
  final ValueChanged<String>? onDeleteCustomRecipe;
  final void Function(String itemText, int aisle)? onLearnAisle;
  final Future<int?> Function(String itemId, String itemName)?
  onClassifyUnknownItem;
  final ValueChanged<String>? onDismissDue;
  final Future<void> Function()? onNotifyAtStore;
  final ValueChanged<ShopTripRecord>? onRecordTrip;
  final Future<String?> Function(BuildContext context)? barcodeScanner;
  final Future<ShopBarcodeProduct?> Function(String code, ShopMemory memory)?
  barcodeLookup;

  @override
  State<StoreModeScreen> createState() => _StoreModeScreenState();
}

class _StoreModeScreenState extends State<StoreModeScreen> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  late ShopMemory _memory =
      widget.shopMemoryListenable?.value ?? const ShopMemory();
  bool _hideChecked = false;
  bool _keepScreenOn = true;
  String _activeStore = '';
  final Set<int> _collapsedAisles = {};
  final Set<String> _dismissedDueLocal = {};
  final _addCtrl = TextEditingController();
  final _addFocus = FocusNode();
  final _scrollCtrl = ScrollController();

  bool _speechAvailable = false;
  bool _dictating = false;
  bool _lookingUpBarcode = false;
  StreamSubscription<({String? text, double? level})>? _speechSub;

  void _onLiveItemsChanged() {
    final live = widget.liveItems;
    if (!mounted || live == null) return;
    setState(() => _items = List<NoteItem>.of(live.value));
  }

  void _onMemoryChanged() {
    final mem = widget.shopMemoryListenable;
    if (!mounted || mem == null) return;
    setState(() => _memory = mem.value);
  }

  @override
  void initState() {
    super.initState();
    widget.liveItems?.addListener(_onLiveItemsChanged);
    widget.shopMemoryListenable?.addListener(_onMemoryChanged);
    unawaited(KeepScreenOn.set(true));
    unawaited(_checkSpeech());
  }

  Future<void> _checkSpeech() async {
    final ok = await DeviceSpeech.isAvailable();
    if (mounted && ok != _speechAvailable) {
      setState(() => _speechAvailable = ok);
    }
  }

  @override
  void didUpdateWidget(covariant StoreModeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveItems != widget.liveItems) {
      oldWidget.liveItems?.removeListener(_onLiveItemsChanged);
      widget.liveItems?.addListener(_onLiveItemsChanged);
      final live = widget.liveItems;
      if (live != null) {
        _items = List<NoteItem>.of(live.value);
      }
    }
    if (oldWidget.shopMemoryListenable != widget.shopMemoryListenable) {
      oldWidget.shopMemoryListenable?.removeListener(_onMemoryChanged);
      widget.shopMemoryListenable?.addListener(_onMemoryChanged);
      final mem = widget.shopMemoryListenable;
      if (mem != null) {
        _memory = mem.value;
      }
    }
  }

  @override
  void dispose() {
    widget.liveItems?.removeListener(_onLiveItemsChanged);
    widget.shopMemoryListenable?.removeListener(_onMemoryChanged);
    unawaited(_speechSub?.cancel());
    if (_dictating) unawaited(DeviceSpeech.stop());
    unawaited(KeepScreenOn.set(false));
    _addCtrl.dispose();
    _addFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _isShopping =>
      widget.listKind == SmartListKind.shopping ||
      widget.listKind == SmartListKind.generic;

  void _toggle(NoteItem item) {
    unawaited(AppHaptics.tick());
    if (widget.onUpdateItem == null) {
      setState(() => _items = widget.onToggleItem(item.id));
      return;
    }
    final meta = ShopItemMeta.fromItem(item);
    final nextStatus = meta.status == ShopItemStatus.inCart
        ? ShopItemStatus.todo
        : ShopItemStatus.inCart;
    final next = meta
        .copyWith(
          status: nextStatus,
          takenBy: nextStatus == ShopItemStatus.inCart
              ? widget.currentUserName
              : '',
        )
        .applyToItem(item);
    setState(() => _items = widget.onUpdateItem!(next));
  }

  void _toggleUnavailable(NoteItem item) {
    unawaited(AppHaptics.tick());
    final meta = ShopItemMeta.fromItem(item);
    final nextStatus = meta.status == ShopItemStatus.unavailable
        ? ShopItemStatus.todo
        : ShopItemStatus.unavailable;
    final next = meta
        .copyWith(status: nextStatus, takenBy: '')
        .applyToItem(item);
    if (widget.onUpdateItem != null) {
      setState(() => _items = widget.onUpdateItem!(next));
    } else {
      setState(() {
        _items = [
          for (final i in _items)
            if (i.id == item.id) next else i,
        ];
      });
    }
  }

  void _stepQty(NoteItem item, {required bool increase}) {
    unawaited(AppHaptics.tick());
    final next = stepShopItemQty(item, increase: increase);
    if (widget.onUpdateItem != null) {
      setState(() => _items = widget.onUpdateItem!(next));
    } else {
      setState(() {
        _items = [
          for (final i in _items)
            if (i.id == item.id) next else i,
        ];
      });
    }
  }

  void _submitAdd() {
    final raw = _addCtrl.text.trim();
    if (raw.isEmpty) return;
    unawaited(AppHaptics.tick());
    _addCtrl.clear();
    _addParsedText(raw);
  }

  void _addParsedText(String raw) {
    final locale = context.l10n.localeName;
    final parsed = QuickParser(
      groceryLexicon(locale),
      phrasesOnly: !_isShopping,
    ).parse(raw, flush: true);

    if (parsed.items.length <= 1) {
      final singleText = parsed.items.isNotEmpty ? parsed.items.first.text : raw;
      final beforeIds = {for (final i in _items) i.id};
      final updated = widget.onAddItem(singleText);
      setState(() => _items = updated);
      _maybeClassifyNewItems(updated, beforeIds, locale);
      return;
    }

    var updated = _items;
    final beforeIds = {for (final i in _items) i.id};
    for (final p in parsed.items) {
      updated = widget.onAddItem(p.text);
    }
    setState(() => _items = updated);
    _maybeClassifyNewItems(updated, beforeIds, locale);
  }

  void _maybeClassifyNewItems(
    List<NoteItem> updated,
    Set<String> beforeIds,
    String locale,
  ) {
    final classifier = widget.onClassifyUnknownItem;
    if (classifier == null || !_isShopping) return;
    for (final item in updated) {
      if (beforeIds.contains(item.id) || item.header) continue;
      final aisle = resolveItemAisle(
        item,
        locale: locale,
        learnedGroups: widget.learnedGroups,
      );
      if (aisle == kOtherAisleIndex) {
        unawaited(() async {
          final predicted = await classifier(item.id, quickBaseName(item.text));
          if (predicted == null || !mounted) return;
          final currentIdx = _items.indexWhere((i) => i.id == item.id);
          if (currentIdx < 0) return;
          final cur = _items[currentIdx];
          final updatedItem = ShopItemMeta.fromItem(
            cur,
          ).copyWith(aisle: predicted).applyToItem(cur);
          if (widget.onUpdateItem != null) {
            setState(() => _items = widget.onUpdateItem!(updatedItem));
          }
          widget.onLearnAisle?.call(cur.text, predicted);
        }());
      }
    }
  }

  void _sortByGroup() {
    unawaited(AppHaptics.tick());
    setState(() => _items = widget.onSortByGroup());
  }

  void _finishChecked() {
    unawaited(AppHaptics.tick());
    final storeFiltered = _activeStore.isNotEmpty;
    final checkedItems = [
      for (final i in _items)
        if (!i.header &&
            i.checked &&
            (!storeFiltered ||
                ShopItemMeta.fromItem(i).store.isEmpty ||
                ShopItemMeta.fromItem(i).store == _activeStore))
          i,
    ];
    if (checkedItems.isNotEmpty) {
      var cartSum = 0.0;
      for (final item in checkedItems) {
        final fallback = _memory
            .lastPrice(
              item.text,
              store: _activeStore.isEmpty ? null : _activeStore,
            )
            ?.price;
        final total = shopItemLineTotal(item, fallbackUnitPrice: fallback);
        if (total != null) cartSum += total;
      }
      widget.onRecordTrip?.call(
        ShopTripRecord(
          epochDay: ShopMemory.epochDayOf(DateTime.now()),
          store: _activeStore,
          total: cartSum,
          itemCount: checkedItems.length,
        ),
      );
    }
    if (storeFiltered && widget.onReplaceItems != null) {
      final removeIds = {for (final i in checkedItems) i.id};
      setState(
        () => _items = widget.onReplaceItems!([
          for (final i in _items)
            if (!removeIds.contains(i.id)) i,
        ]),
      );
      return;
    }
    setState(() => _items = widget.onFinishChecked());
  }

  Future<void> _editPrice(NoteItem item, int currentAisle) async {
    final res = await showShopPriceSheet(
      context,
      item: item,
      currentAisle: currentAisle,
      memory: _memory,
      activeStore: _activeStore,
    );
    if (res == null || !mounted) return;
    final oldMeta = ShopItemMeta.fromItem(item);
    final next = oldMeta
        .copyWith(
          unitPrice: res.price,
          clearPrice: res.price == null,
          store: res.store,
          aisle: res.aisle >= 0 ? res.aisle : null,
          clearAisle: res.aisle < 0,
        )
        .applyToItem(item);

    if (res.price != null && res.price! > 0) {
      widget.onRecordPrice?.call(
        item.text,
        res.price!,
        store: res.store,
        unit: oldMeta.unit,
      );
      if (widget.shopMemoryListenable == null) {
        _memory = _memory.withRecordedPrice(
          item.text,
          res.price!,
          store: res.store,
          unit: oldMeta.unit,
        );
      }
    }
    if (res.aisle >= 0 && res.aisle != currentAisle) {
      widget.onLearnAisle?.call(item.text, res.aisle);
    }
    if (widget.onUpdateItem != null) {
      setState(() => _items = widget.onUpdateItem!(next));
    } else {
      setState(() {
        _items = [
          for (final i in _items)
            if (i.id == item.id) next else i,
        ];
      });
    }
  }

  Future<void> _toggleDictation() async {
    if (_dictating) {
      await _speechSub?.cancel();
      _speechSub = null;
      await DeviceSpeech.stop();
      if (mounted) setState(() => _dictating = false);
      return;
    }
    final granted = await DeviceSpeech.ensureMicPermission();
    if (!granted || !mounted) return;
    final l10n = context.l10n;
    final speechLocale = l10n.localeName.startsWith('tr') ? 'tr-TR' : 'en-US';
    setState(() => _dictating = true);
    _speechSub = DeviceSpeech.listen(locale: speechLocale).listen(
      (ev) {
        final t = ev.text;
        if (t != null && mounted) {
          _addCtrl.text = t;
          _addCtrl.selection = TextSelection.collapsed(offset: t.length);
        }
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _dictating = false);
        if (_addCtrl.text.trim().isNotEmpty) {
          _submitAdd();
        }
      },
      onError: (_) {
        if (mounted) setState(() => _dictating = false);
      },
    );
  }

  Future<void> _scanBarcode() async {
    if (_lookingUpBarcode) return;
    final scanner = widget.barcodeScanner ?? openQrScanner;
    final code = await scanner(context);
    if (code == null || code.trim().isEmpty || !mounted) return;
    final lookup =
        widget.barcodeLookup ??
        (c, mem) => lookupBarcodeProduct(c, memory: mem);
    setState(() => _lookingUpBarcode = true);
    ShopBarcodeProduct? product;
    try {
      product = await lookup(code, _memory);
    } finally {
      if (mounted) setState(() => _lookingUpBarcode = false);
    }
    if (!mounted) return;

    if (product == null) {
      final manualName = await _askUnknownBarcodeName(code);
      if (manualName == null || manualName.trim().isEmpty || !mounted) return;
      final lexGroup = groceryLexicon(context.l10n.localeName).groupOf(manualName);
      product = ShopBarcodeProduct(
        ean: code.trim(),
        name: quickCapitalize(manualName.trim()),
        aisle: lexGroup,
      );
    }

    widget.onSaveBarcode?.call(product);
    if (widget.shopMemoryListenable == null) {
      _memory = _memory.withBarcode(product);
    }
    final beforeIds = {for (final i in _items) i.id};
    var updated = widget.onAddItem(product.displayText);
    if (product.aisle >= 0 && widget.onUpdateItem != null) {
      final added = updated.where((i) => !beforeIds.contains(i.id)).firstOrNull;
      if (added != null) {
        updated = widget.onUpdateItem!(
          ShopItemMeta.fromItem(added)
              .copyWith(aisle: product.aisle)
              .applyToItem(added),
        );
      }
    }
    setState(() => _items = updated);
  }

  Future<String?> _askUnknownBarcodeName(String ean) => showAppSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _UnknownBarcodeSheet(ean: ean),
  );

  Future<void> _openRecipes() async {
    final res = await showShopRecipesSheet(
      context,
      customRecipes: _memory.customRecipes,
      onSaveCustomRecipe: (r) {
        widget.onSaveCustomRecipe?.call(r);
        if (widget.shopMemoryListenable == null) {
          setState(() => _memory = _memory.withCustomRecipe(r));
        }
      },
      onDeleteCustomRecipe: (id) {
        widget.onDeleteCustomRecipe?.call(id);
        if (widget.shopMemoryListenable == null) {
          setState(() => _memory = _memory.withoutCustomRecipe(id));
        }
      },
    );
    if (res == null || res.selectedIngredients.isEmpty || !mounted) return;
    final locale = context.l10n.localeName;
    final nextItems = mergeRecipeIntoItems(
      _items,
      res.selectedIngredients,
      locale: locale,
      learnedGroups: widget.learnedGroups,
      newId: () => const Uuid().v4(),
    );
    if (widget.onReplaceItems != null) {
      setState(() => _items = widget.onReplaceItems!(nextItems));
    } else {
      for (final ing in res.selectedIngredients) {
        _items = widget.onAddItem(quickCompose(ing.name, ing.qty));
      }
      setState(() {});
    }
  }

  Future<void> _openReceiptScanner() async {
    final res = await showShopReceiptSheet(context, items: _items);
    if (res == null || res.matches.isEmpty || !mounted) return;
    final store = res.storeId.isNotEmpty ? res.storeId : _activeStore;
    final byId = {for (final m in res.matches) m.itemId: m.receiptLine};
    final updated = [
      for (final item in _items)
        if (byId.containsKey(item.id))
          () {
            final line = byId[item.id]!;
            final oldMeta = ShopItemMeta.fromItem(item);
            final unitPrice = receiptUnitPriceForItem(line, oldMeta);
            widget.onRecordPrice?.call(
              item.text,
              unitPrice,
              store: store,
              unit: oldMeta.unit,
            );
            return oldMeta
                .copyWith(unitPrice: unitPrice, store: store)
                .applyToItem(item);
          }()
        else
          item,
    ];
    if (widget.onReplaceItems != null) {
      setState(() => _items = widget.onReplaceItems!(updated));
    } else {
      setState(() => _items = updated);
    }
  }

  Future<void> _customizeAisleOrder() async {
    final storeId = _activeStore.isEmpty ? 'default' : _activeStore;
    final label = _activeStore.isEmpty
        ? context.l10n.shopAllStores
        : shopStoreLabel(_activeStore);
    final res = await showShopAisleOrderSheet(
      context,
      storeLabel: label,
      currentOrder: _memory.aisleOrderFor(storeId),
    );
    if (res == null || !mounted) return;
    widget.onSaveAisleOrder?.call(storeId, res);
    if (widget.shopMemoryListenable == null) {
      setState(() => _memory = _memory.withStoreAisleOrder(storeId, res));
    }
  }

  Future<void> _notifyAtStore() async {
    final l10n = context.l10n;
    if (widget.onNotifyAtStore != null) {
      await widget.onNotifyAtStore!();
      if (mounted) showAppMessage(context, l10n.shopAtStoreSent);
    }
  }

  List<_StoreRow> _buildRows(
    List<NoteItem> visibleItems, {
    required String locale,
    required bool isTr,
  }) {
    final hasManualHeaders = visibleItems.any((i) => i.header);
    if (!_isShopping || hasManualHeaders) {
      return [
        for (final i in visibleItems)
          if (i.header)
            _AisleHeaderRow(
              aisleIndex: kOtherAisleIndex,
              label: i.text.trim(),
              remaining: 0,
              total: 0,
              allDone: false,
            )
          else
            _ItemRow(item: i, aisleIndex: kOtherAisleIndex),
      ];
    }

    final grouped = <int, List<NoteItem>>{};
    for (final item in visibleItems) {
      final aisle = resolveItemAisle(
        item,
        locale: locale,
        learnedGroups: widget.learnedGroups,
      );
      grouped.putIfAbsent(aisle, () => []).add(item);
    }

    final orderKey = _activeStore.isEmpty ? 'default' : _activeStore;
    final order = [..._memory.aisleOrderFor(orderKey), kOtherAisleIndex];

    // Tamamlanmış reyonları sona indir (kullanıcının aktif reyonu önce kalsın).
    final activeAisles = <int>[];
    final completedAisles = <int>[];
    for (final idx in order) {
      final list = grouped[idx];
      if (list == null || list.isEmpty) continue;
      final rem = list.where((i) => !i.checked).length;
      if (rem == 0) {
        completedAisles.add(idx);
      } else {
        activeAisles.add(idx);
      }
    }

    final out = <_StoreRow>[];
    for (final idx in [...activeAisles, ...completedAisles]) {
      final list = grouped[idx]!;
      final meta = shopAisleMetaOfIndex(idx);
      final rem = list.where((i) => !i.checked).length;
      final allDone = rem == 0;
      out.add(
        _AisleHeaderRow(
          aisleIndex: idx,
          label: meta.label(isTr: isTr),
          remaining: rem,
          total: list.length,
          allDone: allDone,
        ),
      );
      if (!_collapsedAisles.contains(idx)) {
        final unchecked = [
          for (final i in list)
            if (!i.checked) i,
        ];
        final checked = [
          for (final i in list)
            if (i.checked) i,
        ];
        for (final i in [...unchecked, ...checked]) {
          out.add(_ItemRow(item: i, aisleIndex: idx));
        }
      }
    }
    return out;
  }

  void _jumpToAisle(List<_StoreRow> rows, int aisleIndex) {
    final rowIndex = rows.indexWhere(
      (r) => r is _AisleHeaderRow && r.aisleIndex == aisleIndex,
    );
    if (rowIndex < 0 || !_scrollCtrl.hasClients) return;
    if (_collapsedAisles.contains(aisleIndex)) {
      setState(() => _collapsedAisles.remove(aisleIndex));
    }
    final target = (rowIndex * 66.0).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );
    unawaited(
      _scrollCtrl.animateTo(
        target,
        duration: AppMotion.medium,
        curve: AppMotion.emphasized,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');
    final locale = l10n.localeName;

    final realItems = [
      for (final i in _items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final storeFilteredItems = [
      for (final i in _items)
        if (i.text.trim().isNotEmpty &&
            (i.header ||
                _activeStore.isEmpty ||
                ShopItemMeta.fromItem(i).store.isEmpty ||
                ShopItemMeta.fromItem(i).store == _activeStore))
          i,
    ];
    final storeRealItems = [
      for (final i in storeFilteredItems)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final visibleItems = [
      for (final i in storeFilteredItems)
        if (i.header || !_hideChecked || !i.checked) i,
    ];

    final total = storeRealItems.length;
    final checkedCount = storeRealItems.where((i) => i.checked).length;
    final remaining = total - checkedCount;
    final progress = total == 0 ? 1.0 : checkedCount / total;

    var cartTotal = 0.0;
    var estimatedTotal = 0.0;
    for (final item in storeRealItems) {
      final meta = ShopItemMeta.fromItem(item);
      if (meta.status == ShopItemStatus.unavailable) continue;
      final fallback = _memory
          .lastPrice(
            item.text,
            store: _activeStore.isEmpty ? null : _activeStore,
          )
          ?.price;
      final line = shopItemLineTotal(item, fallbackUnitPrice: fallback);
      if (line != null && line > 0) {
        estimatedTotal += line;
        if (item.checked) cartTotal += line;
      }
    }

    final rows = _buildRows(visibleItems, locale: locale, isTr: isTr);
    final aisleHeaders = [
      for (final r in rows)
        if (r is _AisleHeaderRow && r.aisleIndex != kOtherAisleIndex && !r.allDone)
          r,
    ];

    final now = DateTime.now();
    final existingKeys = {
      for (final i in realItems) quickItemKey(i.text),
    };
    final visibleDue = [
      for (final d in widget.dueItems)
        if (!existingKeys.contains(quickItemKey(d.name)) &&
            !_dismissedDueLocal.contains(quickItemKey(d.name)) &&
            !_memory.isDueDismissed(d.name, now))
          d,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title.trim().isEmpty ? l10n.storeMode : widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              remaining == 0 && total > 0
                  ? l10n.storeModeAllDone
                  : l10n.storeModeRemaining(remaining, total),
              key: const ValueKey('store-mode-progress-label'),
              style: text.meta.copyWith(color: scheme.primary),
            ),
          ],
        ),
        actions: [
          if (widget.isShared && widget.onNotifyAtStore != null)
            IconButton(
              key: const ValueKey('store-mode-at-store'),
              tooltip: l10n.shopAtStoreButton,
              icon: const Icon(Icons.notifications_active_outlined),
              onPressed: _notifyAtStore,
            ),
          if (_isShopping && ScanOcr.supported)
            IconButton(
              key: const ValueKey('store-mode-receipt'),
              tooltip: l10n.shopScanReceiptTooltip,
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: _openReceiptScanner,
            ),
          if (_isShopping)
            IconButton(
              key: const ValueKey('store-mode-recipes'),
              tooltip: l10n.shopRecipesTooltip,
              icon: const Icon(Icons.restaurant_menu_rounded),
              onPressed: _openRecipes,
            ),
          IconButton(
            key: const ValueKey('store-mode-keep-screen'),
            tooltip: l10n.shopKeepScreenOn,
            icon: Icon(
              _keepScreenOn
                  ? Icons.wb_sunny_rounded
                  : Icons.wb_sunny_outlined,
              color: _keepScreenOn ? scheme.primary : null,
            ),
            onPressed: () {
              final next = !_keepScreenOn;
              setState(() => _keepScreenOn = next);
              unawaited(KeepScreenOn.set(next));
            },
          ),
          IconButton(
            key: const ValueKey('store-mode-sort'),
            tooltip: l10n.sortByGroup,
            icon: const Icon(Icons.sort_rounded),
            onPressed: _sortByGroup,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: AppSpace.xs,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.l,
              AppSpace.s,
              AppSpace.l,
              AppSpace.xs,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterChip(
                    key: const ValueKey('store-mode-hide-checked'),
                    selected: _hideChecked,
                    label: Text(
                      _hideChecked
                          ? l10n.storeModeShowChecked
                          : l10n.storeModeHideChecked,
                    ),
                    avatar: Icon(
                      _hideChecked
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: AppIconSize.s,
                    ),
                    onSelected: (v) => setState(() => _hideChecked = v),
                  ),
                  if (checkedCount > 0)
                    FilledButton.tonalIcon(
                      key: const ValueKey('store-mode-finish'),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        size: AppIconSize.s,
                      ),
                      label: Text('${l10n.finishShopping} ($checkedCount)'),
                      onPressed: _finishChecked,
                    ),
                ],
              ),
            ),
          ),
          if (_isShopping)
            ShopBudgetBar(
              cartTotal: cartTotal,
              estimatedTotal: estimatedTotal,
              budgetLimit: widget.noteId.isNotEmpty
                  ? _memory.budgetFor(widget.noteId)
                  : null,
              onEditBudget: (limit) {
                if (widget.noteId.isEmpty) return;
                widget.onSetBudget?.call(limit);
                if (widget.shopMemoryListenable == null) {
                  setState(() => _memory = _memory.withBudget(widget.noteId, limit));
                }
              },
            ),
          if (_isShopping)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.s),
                    child: ChoiceChip(
                      key: const ValueKey('store-filter-all'),
                      label: Text(l10n.shopAllStores),
                      selected: _activeStore.isEmpty,
                      onSelected: (_) => setState(() => _activeStore = ''),
                    ),
                  ),
                  for (final s in kDefaultShopStores)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.s),
                      child: ChoiceChip(
                        key: ValueKey('store-filter-${s.id}'),
                        label: Text(s.label),
                        selected: _activeStore == s.id,
                        onSelected: (_) => setState(
                          () => _activeStore = _activeStore == s.id ? '' : s.id,
                        ),
                      ),
                    ),
                  IconButton(
                    key: const ValueKey('store-aisle-order-btn'),
                    tooltip: l10n.shopAisleOrderTooltip,
                    icon: const Icon(Icons.tune_rounded, size: AppIconSize.s),
                    onPressed: _customizeAisleOrder,
                  ),
                ],
              ),
            ),
          if (aisleHeaders.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                  itemCount: aisleHeaders.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.xs),
                  itemBuilder: (_, i) {
                    final h = aisleHeaders[i];
                    final meta = shopAisleMetaOfIndex(h.aisleIndex);
                    return ActionChip(
                      key: ValueKey('store-jump-${h.aisleIndex}'),
                      avatar: Icon(
                        meta.icon,
                        size: AppIconSize.xs,
                        color: meta.color,
                      ),
                      label: Text('${h.label} (${h.remaining})', style: text.badge),
                      onPressed: () => _jumpToAisle(rows, h.aisleIndex),
                    );
                  },
                ),
              ),
            ),
          if (visibleDue.isNotEmpty)
            ShopDueStrip(
              dueItems: visibleDue,
              onAddDue: (name) {
                unawaited(AppHaptics.tick());
                _addParsedText(name);
              },
              onDismissDue: (name) {
                widget.onDismissDue?.call(name);
                setState(() {
                  _dismissedDueLocal.add(quickItemKey(name));
                  if (widget.shopMemoryListenable == null) {
                    _memory = _memory.withDueDismissed(name);
                  }
                });
              },
            ),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpace.s,
                        children: [
                          Icon(
                            total == 0
                                ? Icons.shopping_cart_outlined
                                : Icons.check_circle_outline_rounded,
                            size: AppIconSize.l,
                            color: total == 0
                                ? scheme.onSurfaceVariant
                                : scheme.primary,
                          ),
                          Text(
                            total == 0
                                ? l10n.quickListEmpty
                                : l10n.storeModeAllDone,
                            textAlign: TextAlign.center,
                            style: text.sheetTitle,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.l,
                      AppSpace.s,
                      AppSpace.l,
                      AppSpace.l,
                    ),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row is _AisleHeaderRow) {
                        final meta = shopAisleMetaOfIndex(row.aisleIndex);
                        final collapsed = _collapsedAisles.contains(row.aisleIndex);
                        return InkWell(
                          key: ValueKey('store-aisle-header-${row.aisleIndex}'),
                          borderRadius: BorderRadius.circular(AppRadius.s),
                          onTap: row.aisleIndex == kOtherAisleIndex
                              ? null
                              : () => setState(() {
                                  if (collapsed) {
                                    _collapsedAisles.remove(row.aisleIndex);
                                  } else {
                                    _collapsedAisles.add(row.aisleIndex);
                                  }
                                }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpace.xs,
                              horizontal: AppSpace.xs,
                            ),
                            child: Row(
                              spacing: AppSpace.s,
                              children: [
                                if (row.aisleIndex != kOtherAisleIndex)
                                  Icon(
                                    meta.icon,
                                    size: AppIconSize.s,
                                    color: row.allDone
                                        ? scheme.onSurfaceVariant
                                        : meta.color,
                                  ),
                                Expanded(
                                  child: Text(
                                    row.label,
                                    style: text.section.copyWith(
                                      color: row.allDone
                                          ? scheme.onSurfaceVariant
                                          : meta.color,
                                      fontWeight: AppWeight.strong,
                                    ),
                                  ),
                                ),
                                if (row.total > 0)
                                  Text(
                                    '${row.total - row.remaining}/${row.total}',
                                    style: text.meta,
                                  ),
                                if (row.aisleIndex != kOtherAisleIndex)
                                  Icon(
                                    collapsed
                                        ? Icons.expand_more_rounded
                                        : Icons.expand_less_rounded,
                                    size: AppIconSize.s,
                                    color: scheme.onSurfaceVariant,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      final itemRow = row as _ItemRow;
                      final item = itemRow.item;
                      return _StoreItemCard(
                        item: item,
                        aisleIndex: itemRow.aisleIndex,
                        memory: _memory,
                        activeStore: _activeStore,
                        isShopping: _isShopping,
                        onToggle: () => _toggle(item),
                        onToggleUnavailable: () => _toggleUnavailable(item),
                        onEditPrice: () =>
                            _editPrice(item, itemRow.aisleIndex),
                        onStepQty: (inc) => _stepQty(item, increase: inc),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                AppSpace.s,
                AppSpace.l,
                AppSpace.m,
              ),
              child: Row(
                spacing: AppSpace.s,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('store-mode-add-field'),
                      controller: _addCtrl,
                      focusNode: _addFocus,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submitAdd(),
                      decoration: InputDecoration(
                        hintText: l10n.storeModeAddHint,
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.l),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.l,
                          vertical: AppSpace.m,
                        ),
                      ),
                    ),
                  ),
                  if (_speechAvailable)
                    IconButton.filledTonal(
                      key: const ValueKey('store-mode-mic'),
                      tooltip: l10n.shopDictationTooltip,
                      icon: Icon(
                        _dictating ? Icons.stop_rounded : AppIcons.dictation,
                        color: _dictating ? scheme.error : null,
                      ),
                      onPressed: _toggleDictation,
                    ),
                  if (_isShopping &&
                      (qrScanSupported || widget.barcodeScanner != null))
                    IconButton.filledTonal(
                      key: const ValueKey('store-mode-barcode'),
                      tooltip: l10n.shopBarcodeTitle,
                      icon: _lookingUpBarcode
                          ? const SizedBox.square(
                              dimension: AppIconSize.s,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_scanner_rounded),
                      onPressed: _lookingUpBarcode ? null : _scanBarcode,
                    ),
                  IconButton.filled(
                    key: const ValueKey('store-mode-add-submit'),
                    tooltip: l10n.quickAddTooltip,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: _submitAdd,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

