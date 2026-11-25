import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../../notes/data/quick_entry_memory.dart';
import '../../notes/domain/quick_entry.dart';
import '../domain/shop_aisles.dart';
import '../domain/shop_recipes.dart';

@immutable
class ShopRecipesOutcome {
  const ShopRecipesOutcome({
    this.selectedIngredients = const [],
    this.newCustomRecipe,
    this.deletedCustomId,
  });

  final List<({String name, String qty, int aisle})> selectedIngredients;
  final ShopRecipe? newCustomRecipe;
  final String? deletedCustomId;
}

/// 18 Türk mutfağı öğün/tarif paketi + kullanıcının kendi tarifleri levhası.
Future<ShopRecipesOutcome?> showShopRecipesSheet(
  BuildContext context, {
  required List<ShopRecipe> customRecipes,
  ValueChanged<ShopRecipe>? onSaveCustomRecipe,
  ValueChanged<String>? onDeleteCustomRecipe,
}) => showAppSheet<ShopRecipesOutcome>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _ShopRecipesSheet(
    customRecipes: customRecipes,
    onSaveCustomRecipe: onSaveCustomRecipe,
    onDeleteCustomRecipe: onDeleteCustomRecipe,
  ),
);

class _ShopRecipesSheet extends StatefulWidget {
  const _ShopRecipesSheet({
    required this.customRecipes,
    this.onSaveCustomRecipe,
    this.onDeleteCustomRecipe,
  });

  final List<ShopRecipe> customRecipes;
  final ValueChanged<ShopRecipe>? onSaveCustomRecipe;
  final ValueChanged<String>? onDeleteCustomRecipe;

  @override
  State<_ShopRecipesSheet> createState() => _ShopRecipesSheetState();
}

class _ShopRecipesSheetState extends State<_ShopRecipesSheet> {
  final _searchCtrl = TextEditingController();
  late List<ShopRecipe> _custom = List<ShopRecipe>.of(widget.customRecipes);
  ShopRecipe? _selected;
  int _servings = 4;
  late List<bool> _checks = const [];
  bool _creating = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openRecipe(ShopRecipe r) {
    setState(() {
      _selected = r;
      _servings = r.baseServings;
      _checks = List<bool>.filled(r.ingredients.length, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final isTr = l10n.localeName.startsWith('tr');

    if (_creating) {
      return _CustomRecipeForm(
        onCancel: () => setState(() => _creating = false),
        onSaved: (recipe) {
          widget.onSaveCustomRecipe?.call(recipe);
          setState(() {
            _custom = [..._custom, recipe];
            _creating = false;
          });
          _openRecipe(recipe);
        },
      );
    }

    final selected = _selected;
    if (selected != null) {
      final scaled = scaleShopRecipe(selected, _servings);
      return SheetInsetPadding(
        extra: AppSpace.l,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(
                title: selected.title(isTr: isTr),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: l10n.back,
                    onPressed: () => setState(() => _selected = null),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.shopServingsCount(_servings),
                      key: const ValueKey('shop-recipe-servings'),
                      style: text.rowTitle,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          key: const ValueKey('shop-recipe-servings-minus'),
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _servings > 1
                              ? () => setState(() => _servings--)
                              : null,
                        ),
                        IconButton(
                          key: const ValueKey('shop-recipe-servings-plus'),
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _servings < 20
                              ? () => setState(() => _servings++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: scaled.length,
                  itemBuilder: (_, i) {
                    final ing = scaled[i];
                    final label = quickCompose(ing.name, ing.qty);
                    return CheckboxListTile(
                      value: _checks[i],
                      title: Text(label, style: text.body),
                      onChanged: (v) => setState(() => _checks[i] = v ?? true),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.l,
                  AppSpace.s,
                  AppSpace.l,
                  0,
                ),
                child: FilledButton.icon(
                  key: const ValueKey('shop-recipe-add-selected'),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(l10n.shopAddToList),
                  onPressed: () {
                    final picked = [
                      for (var i = 0; i < scaled.length; i++)
                        if (_checks[i]) scaled[i],
                    ];
                    Navigator.pop(
                      context,
                      ShopRecipesOutcome(selectedIngredients: picked),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    final q = quickAscii(_searchCtrl.text);
    final all = [..._custom, ...kBuiltInShopRecipes];
    final filtered = [
      for (final r in all)
        if (q.isEmpty || quickAscii(r.title(isTr: isTr)).contains(q)) r,
    ];

    return SheetInsetPadding(
      extra: AppSpace.m,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.shopRecipesTitle,
              actions: [
                TextButton.icon(
                  key: const ValueKey('shop-recipe-new-custom'),
                  icon: const Icon(Icons.add_rounded, size: AppIconSize.s),
                  label: Text(l10n.shopCustomBadge),
                  onPressed: () => setState(() => _creating = true),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.s,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.shopRecipesSearchHint,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final r = filtered[i];
                  return ListTile(
                    key: ValueKey('shop-recipe-${r.id}'),
                    leading: Icon(
                      r.custom
                          ? Icons.bookmark_outline_rounded
                          : Icons.restaurant_menu_rounded,
                      color: scheme.primary,
                    ),
                    title: Text(r.title(isTr: isTr), style: text.rowTitle),
                    subtitle: Text(
                      '${r.ingredients.length} · ${l10n.shopServingsCount(r.baseServings)}',
                      style: text.meta,
                    ),
                    trailing: r.custom
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () {
                              widget.onDeleteCustomRecipe?.call(r.id);
                              setState(() {
                                _custom = [
                                  for (final c in _custom)
                                    if (c.id != r.id) c,
                                ];
                              });
                            },
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openRecipe(r),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRecipeForm extends StatefulWidget {
  const _CustomRecipeForm({required this.onCancel, required this.onSaved});

  final VoidCallback onCancel;
  final ValueChanged<ShopRecipe> onSaved;

  @override
  State<_CustomRecipeForm> createState() => _CustomRecipeFormState();
}

class _CustomRecipeFormState extends State<_CustomRecipeForm> {
  final _nameCtrl = TextEditingController();
  final _ingsCtrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingsCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save(String locale) {
    final name = _nameCtrl.text.trim();
    final rawIngs = _ingsCtrl.text.trim();
    if (name.isEmpty || rawIngs.isEmpty) return;
    final parsed = QuickParser(groceryLexicon(locale))
        .parse(rawIngs, flush: true)
        .items;
    if (parsed.isEmpty) return;
    final ings = [
      for (final p in parsed)
        () {
          final pq = parseQuickQty(p.qty);
          return ShopIngredient(
            name: p.name,
            qty: pq?.value ?? 1,
            unit: pq?.rawUnit ?? '',
            aisle: p.group >= 0 ? p.group : kOtherAisleIndex,
          );
        }(),
    ];
    widget.onSaved(
      ShopRecipe(
        id: 'custom_${const Uuid().v4().substring(0, 8)}',
        titleTr: name,
        titleEn: name,
        baseServings: 4,
        ingredients: ings,
        custom: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SheetInsetPadding(
      extra: AppSpace.l,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: l10n.shopNewCustomRecipe,
            onClose: widget.onCancel,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpace.m,
              children: [
                TextField(
                  key: const ValueKey('shop-custom-recipe-name'),
                  controller: _nameCtrl,
                  focusNode: _focus,
                  decoration: InputDecoration(
                    hintText: l10n.shopRecipeNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                  ),
                ),
                TextField(
                  key: const ValueKey('shop-custom-recipe-ings'),
                  controller: _ingsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: l10n.shopIngredientsHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.m),
                    ),
                  ),
                ),
                FilledButton(
                  key: const ValueKey('shop-custom-recipe-save'),
                  onPressed: () => _save(l10n.localeName),
                  child: Text(l10n.eventSave),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
