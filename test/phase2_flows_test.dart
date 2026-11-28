import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/starter_notes.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/shopping_summary_bar.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/features/shopping/data/shop_memory.dart';
import 'package:notlar/features/shopping/domain/shop_item_meta.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('starter shopping note sets shopping listKind, canonical names, and canonical aisles', () {
    for (final english in [false, true]) {
      final notes = buildStarterNotes(english: english);
      final shopping = notes.firstWhere((n) => n.id == 'starter_shopping');
      expect(shopping.listKind, 'shopping');
      for (final item in shopping.items) {
        expect(item.category, isNotEmpty);
        expect(ShopItemMeta.fromItem(item).aisle, isA<int>());
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

  testWidgets('ShoppingSummaryBar shows live bought/remaining counts and total price', (tester) async {
    var finishTapped = false;
    final items = <NoteItem>[
      const NoteItem(id: '1', text: 'Süt', checked: true, quantity: 2, price: 30),
      const NoteItem(id: '2', text: 'Peynir', price: 50),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ShoppingSummaryBar(
            items: items,
            onFinishChecked: () => finishTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shopping-summary-bought')), findsOneWidget);
    expect(find.text('1/2 alındı'), findsOneWidget);
    expect(find.text('Toplam: 110 ₺'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shopping-summary-finish')));
    await tester.pump();
    expect(finishTapped, isTrue);
  });
}
