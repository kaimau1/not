import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/starter_notes.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/store_mode_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/features/shopping/data/shop_memory.dart';
import 'package:notlar/features/shopping/domain/shop_item_meta.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('starter shopping note sets shopping listKind, canonical names, and integer aisles', () {
    for (final english in [false, true]) {
      final notes = buildStarterNotes(english: english);
      final shopping = notes.firstWhere((n) => n.id == 'starter_shopping');
      expect(shopping.listKind, 'shopping');
      for (final item in shopping.items) {
        expect(item.extras['g'], isA<int>());
        expect(item.text, contains('('));
      }
    }
    expect(starterNotesSeededKeyFor('userA'), isNot(starterNotesSeededKeyFor('userB')));
  });

  test('ShopMemoryNotifier isolates persisted shop memory per signed-in UID', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final c1 = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('uid-a'),
      ],
    );
    c1.read(shopMemoryProvider.notifier).recordPrice('Süt', 42, store: 'bim');
    expect(c1.read(shopMemoryProvider).lastPrice('Süt')?.price, 42);
    c1.dispose();

    final c2 = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('uid-b'),
      ],
    );
    addTearDown(c2.dispose);
    expect(c2.read(shopMemoryProvider).lastPrice('Süt'), isNull);
  });

  test('AutoSpell.seedFrom recovers after an empty startup snapshot', () async {
    final prevMode = AutoSpell.mode.value;
    AutoSpell.mode.value = SpellMode.show;
    AutoSpell.memory = SpellMemory();
    try {
      await AutoSpell.seedFrom(() => const []);
      expect(AutoSpell.memory.seeded, isEmpty);
      await AutoSpell.seedFrom(() => const ['kahvaltılık alışveriş listesi']);
      expect(AutoSpell.memory.seeded, contains('kahvaltılık'));
    } finally {
      AutoSpell.memory = SpellMemory();
      AutoSpell.mode.value = prevMode;
    }
  });

  test('AutoSpell.trimMemoryForWeb shrinks words while keeping fixes and keep set', () async {
    final mem = SpellMemory()
      ..fixes['kalwm'] = ('kalem', 3)
      ..keep.add('özelkelime')
      ..rejected.add('yanlis>dogru');
    for (var i = 0; i < 4000; i++) {
      mem.words['uzunkelime$i'] = i % 5 + 1;
    }
    final trimmedRaw = AutoSpell.trimMemoryForWeb(mem, maxBytes: 8000);
    expect(trimmedRaw.length, lessThanOrEqualTo(8000));
    final restored = SpellMemory.decode(trimmedRaw);
    expect(restored.fixes['kalwm'], ('kalem', 3));
    expect(restored.keep, contains('özelkelime'));
    expect(restored.rejected, contains('yanlis>dogru'));
  });

  testWidgets('StoreModeScreen empty list shows cart icon and active-store filters progress & finish', (tester) async {
    Widget wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

    await tester.pumpWidget(
      wrap(
        StoreModeScreen(
          title: 'Boş Market',
          initialItems: const [],
          onToggleItem: (_) => const [],
          onAddItem: (_) => const [],
          onSortByGroup: () => const [],
          onFinishChecked: () => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline_rounded), findsNothing);

    var items = <NoteItem>[
      const ShopItemMeta(
        store: 'bim',
        unitPrice: 30,
        status: ShopItemStatus.inCart,
      ).applyToItem(const NoteItem(id: '1', text: 'Süt')),
      const ShopItemMeta(
        store: 'migros',
        unitPrice: 50,
        status: ShopItemStatus.inCart,
      ).applyToItem(const NoteItem(id: '2', text: 'Peynir')),
    ];

    await tester.pumpWidget(
      wrap(
        StoreModeScreen(
          key: const ValueKey('populated-store'),
          title: 'Market',
          initialItems: items,
          barcodeScanner: (_) async => '8699999',
          barcodeLookup: (code, _) async => ShopBarcodeProduct(
            ean: code,
            name: 'Özel Marka Kahve',
            qty: '250 g',
            aisle: 5,
          ),
          onToggleItem: (_) => items,
          onUpdateItem: (u) {
            items = [for (final i in items) if (i.id == u.id) u else i];
            return items;
          },
          onReplaceItems: (next) => items = next,
          onAddItem: (raw) {
            items = [...items, NoteItem(id: 'new-${items.length}', text: raw)];
            return items;
          },
          onSortByGroup: () => items,
          onFinishChecked: () {
            items = [for (final i in items) if (!i.checked) i];
            return items;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Filter to BIM only -> progress shows 0 / 1 remaining (total 1), Finish only deletes BIM item.
    await tester.tap(find.byKey(const ValueKey('store-filter-bim')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('store-mode-finish')));
    await tester.pumpAndSettle();
    expect(items.any((i) => i.id == '1'), isFalse);
    expect(items.any((i) => i.id == '2'), isTrue);

    // Clear filter and scan barcode -> preserves exact product name and applies aisle.
    await tester.tap(find.byKey(const ValueKey('store-filter-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('store-mode-barcode')));
    await tester.pumpAndSettle();
    final scanned = items.firstWhere((i) => i.text == 'Özel Marka Kahve (250 g)');
    expect(ShopItemMeta.fromItem(scanned).aisle, 5);
  });
}
