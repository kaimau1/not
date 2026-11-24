import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/haptics.dart';
import '../../../../core/l10n_ext.dart';
import '../../domain/note_item.dart';

/// AL-5 **MAĞAZA KİPİ** (PLAN §1.4/4 + §1.5): alışveriş/hazırlık listelerinde
/// tek elle yürürken rahat işaretleme ekranı.
///
/// - Büyük 56+ dp dokunma satırları, klavye yanlışlıkla açılmaz.
/// - Üstte kalan madde sayacı + ilerleme çubuğu, "Alınanları gizle/göster"
///   ve tek dokunuşla "Reyona / gruba göre sırala".
/// - Altta hızlı ekleme çubuğu ve işaretli madde varken "Alınanları tamamla".
/// - [liveItems] verilirse ortak alışveriş/ikinci cihaz değişiklikleri canlı
///   olarak yansır (P1-1).
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
  });

  final String title;
  final List<NoteItem> initialItems;

  /// Canlı madde akışı (ortak liste / başka cihaz senkronu). Null ise yalnız
  /// yerel geri dönüş değerleri kullanılır.
  final ValueListenable<List<NoteItem>>? liveItems;

  /// Tek maddeyi işaretle / kaldır; güncel liste döner.
  final List<NoteItem> Function(String itemId) onToggleItem;

  /// Aklına geleni hızlı ekle (miktar toplama + reyon yerleştirme ile).
  final List<NoteItem> Function(String text) onAddItem;

  /// Reyona / gruba göre sırala; güncel liste döner.
  final List<NoteItem> Function() onSortByGroup;

  /// İşaretli maddeleri tamamla (hafıza + geri al editörde); güncel liste döner.
  final List<NoteItem> Function() onFinishChecked;

  @override
  State<StoreModeScreen> createState() => _StoreModeScreenState();
}

class _StoreModeScreenState extends State<StoreModeScreen> {
  late List<NoteItem> _items = List<NoteItem>.of(
    widget.liveItems?.value ?? widget.initialItems,
  );
  bool _hideChecked = false;
  final _addCtrl = TextEditingController();
  final _addFocus = FocusNode();

  void _onLiveItemsChanged() {
    final live = widget.liveItems;
    if (!mounted || live == null) return;
    setState(() => _items = List<NoteItem>.of(live.value));
  }

  @override
  void initState() {
    super.initState();
    widget.liveItems?.addListener(_onLiveItemsChanged);
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
  }

  @override
  void dispose() {
    widget.liveItems?.removeListener(_onLiveItemsChanged);
    _addCtrl.dispose();
    _addFocus.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    unawaited(AppHaptics.tick());
    setState(() => _items = widget.onToggleItem(id));
  }

  void _submitAdd() {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    unawaited(AppHaptics.tick());
    _addCtrl.clear();
    setState(() => _items = widget.onAddItem(text));
  }

  void _sortByGroup() {
    unawaited(AppHaptics.tick());
    setState(() => _items = widget.onSortByGroup());
  }

  void _finishChecked() {
    unawaited(AppHaptics.tick());
    setState(() => _items = widget.onFinishChecked());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);

    final realItems = [
      for (final i in _items)
        if (!i.header && i.text.trim().isNotEmpty) i,
    ];
    final total = realItems.length;
    final checkedCount = realItems.where((i) => i.checked).length;
    final remaining = total - checkedCount;
    final progress = total == 0 ? 1.0 : checkedCount / total;

    final visibleRows = [
      for (final i in _items)
        if (i.text.trim().isNotEmpty &&
            (i.header || !_hideChecked || !i.checked))
          i,
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
          Expanded(
            child: visibleRows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: AppSpace.s,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: AppIconSize.l,
                            color: scheme.primary,
                          ),
                          Text(
                            l10n.storeModeAllDone,
                            style: text.sheetTitle,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.l,
                      AppSpace.s,
                      AppSpace.l,
                      AppSpace.l,
                    ),
                    itemCount: visibleRows.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.s),
                    itemBuilder: (context, index) {
                      final item = visibleRows[index];
                      if (item.header) {
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpace.s),
                          child: Text(
                            item.text.trim(),
                            style: text.section.copyWith(
                              color: scheme.primary,
                              fontWeight: AppWeight.strong,
                            ),
                          ),
                        );
                      }
                      final checked = item.checked;
                      return Material(
                        key: ValueKey('store-item-${item.id}'),
                        color: checked
                            ? scheme.surfaceContainerLow
                            : scheme.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.m),
                          side: BorderSide(
                            color: checked
                                ? scheme.outlineVariant.withValues(
                                    alpha: AppAlpha.soft,
                                  )
                                : scheme.primary.withValues(
                                    alpha: AppAlpha.soft,
                                  ),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _toggle(item.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.l,
                              vertical: AppSpace.m,
                            ),
                            child: Row(
                              spacing: AppSpace.m,
                              children: [
                                Icon(
                                  checked
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: AppIconSize.l,
                                  color: checked
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                                Expanded(
                                  child: Text(
                                    item.text.trim(),
                                    style: text.sheetTitle.copyWith(
                                      color: checked
                                          ? scheme.onSurfaceVariant
                                          : scheme.onSurface,
                                      decoration: checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
