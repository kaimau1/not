import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';
import 'package:notlar/features/ai/data/decisions/decision_profiles.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/domain/quick_lexicon_data.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/text_merge.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/shopping_summary_bar.dart';
import 'package:notlar/features/shopping/data/barcode_lookup.dart';
import 'package:notlar/features/shopping/data/receipt_ocr_parser.dart';
import 'package:notlar/features/shopping/data/shop_memory.dart';
import 'package:notlar/features/shopping/domain/shop_item_meta.dart';
import 'package:notlar/features/shopping/domain/shop_recipes.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  group('NoteItem.extras + Rule 5 + 3-way merge', () {
    test('copyWith(extras) + sameNoteItemExtras + mergeItems3', () {
      const base = NoteItem(id: '1', text: 'Süt (2)');
      expect(base.toMap().containsKey('q'), isFalse);

      final updated = const ShopItemMeta(
        qty: 2,
        unitPrice: 38.5,
        store: 'bim',
      ).applyToItem(base);
      expect(updated.price, 38.5);
      expect(updated.quantity, 2.0);
      expect(updated.extras.containsKey('p'), isFalse);
      expect(updated.extras['s'], 'bim');
      expect(sameItems([base], [updated]), isFalse);
      expect(sameItemsVisually([base], [updated]), isFalse);

      // 3-yönlü birleştirme: yerel alanlar ve extras değişikliği korunur.
      final merged = mergeItems3([base], [updated], [base]);
      expect(merged.single.price, 38.5);
      expect(merged.single.extras['s'], 'bim');

      // Varsayılana dönünce extras ve fiyat tamamen temizlenir (S16 +0 bayt).
      final cleared = const ShopItemMeta().applyToItem(updated);
      expect(cleared.extras, isEmpty);
      expect(cleared.price, isNull);
      expect(cleared.toMap().containsKey('price'), isFalse);
      expect(cleared.toMap().containsKey('p'), isFalse);
    });
  });

  group('QuickParser buçuk & çapraz birim dönüşümü', () {
    test('bir buçuk, iki buçuk, yarım ve çeyrek ayrıştırır', () {
      final lex = buildQuickLexicon(locale: 'tr', grocery: true);
      final p = QuickParser(lex);
      final parsed = p.parse(
        'bir buçuk litre süt, iki buçuk kilo patates, yarım kilo peynir',
        flush: true,
      );
      expect(
        [for (final i in parsed.items) i.text],
        ['Süt (1,5 lt)', 'Patates (2,5 kg)', 'Peynir (½ kg)'],
      );
    });

    test('combineQuickQuantities g↔kg ve ml↔lt dönüşümlerini yapar', () {
      expect(combineQuickQuantities('500 g', '250 g'), '750 g');
      expect(combineQuickQuantities('500 g', '500 g'), '1 kg');
      expect(combineQuickQuantities('500 g', '1 kg'), '1,5 kg');
      expect(combineQuickQuantities('½ kg', '500 g'), '1 kg');
      expect(combineQuickQuantities('500 ml', '1 lt'), '1,5 lt');
      expect(combineQuickQuantities('500 ml', '500 ml'), '1 lt');
      expect(combineQuickQuantities('1,5 L', '0,5 L'), '2 L');
    });
  });

  group('ShopItemMeta & ShopMemory', () {
    test('roundtrip, stepShopItemQty ve shopItemLineTotal', () {
      const raw = NoteItem(id: 'a', text: 'Domates (500 g)');
      final meta = ShopItemMeta.fromItem(raw);
      expect(meta.qty, 500);
      expect(meta.unit, 'g');

      final steppedUp = stepShopItemQty(raw, increase: true);
      expect(steppedUp.text, 'Domates (750 g)');

      final steppedDown = stepShopItemQty(raw, increase: false);
      expect(steppedDown.text, 'Domates (250 g)');

      const kgItem = NoteItem(id: 'b', text: 'Elma (1 kg)');
      expect(stepShopItemQty(kgItem, increase: true).text, 'Elma (1,5 kg)');

      const gramPromo = NoteItem(id: 'gp', text: 'Peynir (750 g)');
      final promotedKg = stepShopItemQty(gramPromo, increase: true);
      expect(promotedKg.text, 'Peynir (1 kg)');
      expect(ShopItemMeta.fromItem(promotedKg).unit, 'kg');

      const mlPromo = NoteItem(id: 'mp', text: 'Zeytinyağı (750 ml)');
      final promotedLt = stepShopItemQty(mlPromo, increase: true);
      expect(promotedLt.text, 'Zeytinyağı (1 lt)');
      expect(ShopItemMeta.fromItem(promotedLt).unit, 'lt');

      final pricedCount = const ShopItemMeta(
        qty: 3,
        unit: 'adet',
        unitPrice: 20,
      ).applyToItem(const NoteItem(id: 'c', text: 'Ekmek (3 adet)'));
      expect(shopItemLineTotal(pricedCount), 60);

      final unavailable = const ShopItemMeta(status: ShopItemStatus.unavailable)
          .applyToItem(raw);
      expect(unavailable.checked, isFalse);
      expect(ShopItemMeta.fromItem(unavailable).isUnavailable, isTrue);
    });

    test(
      'ShopMemory encode/decode, fiyat kıyaslama, erteleme ve reyon sırası',
      () {
        final now = DateTime(2026, 11, 25, 10);
        var mem = const ShopMemory()
            .withRecordedPrice('Süt', 42, store: 'migros', at: now)
            .withRecordedPrice('Süt', 35, store: 'bim', at: now)
            .withStoreAisleOrder('bim', [2, 1, 0])
            .withBudget('n1', 1500)
            .withBarcode(
              const ShopBarcodeProduct(
                ean: '8690001',
                name: 'Türk kahvesi',
                qty: '100 g',
                aisle: 5,
              ),
            )
            .withDueDismissed('Yumurta', now: now)
            .withTrip(
              ShopTripRecord(
                epochDay: ShopMemory.epochDayOf(now),
                store: 'bim',
                total: 420,
                itemCount: 8,
              ),
            );

        final restored = ShopMemory.decode(mem.encode());
        expect(restored.lastPrice('Süt', store: 'bim')?.price, 35);
        final cmp = restored.storeComparisons('Süt');
        expect(cmp.map((e) => e.store).toList(), ['bim', 'migros']);
        expect(restored.aisleOrderFor('bim').take(3), [2, 1, 0]);
        expect(restored.budgetFor('n1'), 1500);
        expect(restored.barcodes['8690001']?.name, 'Türk kahvesi');
        expect(
          restored.isDueDismissed(
            'Yumurta',
            now.add(const Duration(hours: 12)),
          ),
          isTrue,
        );
        expect(
          restored.isDueDismissed(
            'Yumurta',
            now.add(const Duration(hours: 25)),
          ),
          isFalse,
        );
        expect(restored.trips.single.total, 420);
      },
    );
  });

  group('ShopRecipes ölçekleme ve birleştirme', () {
    test('Menemen 4 → 8 kişi ölçekler ve mevcut listeye g↔kg birleştirir', () {
      final menemen = kBuiltInShopRecipes.firstWhere((r) => r.id == 'menemen');
      final scaled = scaleShopRecipe(menemen, 8);
      final tomato = scaled.firstWhere((i) => i.name == 'Domates');
      expect(tomato.qty, '1,5 kg');

      final merged = mergeRecipeIntoItems(
        [const NoteItem(id: 'd1', text: 'Domates (500 g)')],
        [tomato],
        locale: 'tr',
        newId: () => 'new-1',
      );
      expect(merged.single.text, 'Domates (2 kg)');

      const bottleRecipe = ShopRecipe(
        id: 'r_bottle',
        titleTr: 'Limonata',
        titleEn: 'Lemonade',
        baseServings: 4,
        ingredients: [
          ShopIngredient(name: 'Maden suyu', qty: 1, unit: 'şişe', aisle: 5),
        ],
      );
      final bottleScaled = scaleShopRecipe(bottleRecipe, 5);
      expect(bottleScaled.single.qty, '2 şişe');
    });
  });

  group('Barkod + Fiş OCR + Decisions D1', () {
    test(
      'lookupBarcodeProduct yerel önbellek, Open Food Facts ve hata düşüşü',
      () async {
        const mem = ShopMemory(
          barcodes: {
            '869111': ShopBarcodeProduct(
              ean: '869111',
              name: 'Süt',
              qty: '1 lt',
              aisle: 2,
            ),
          },
        );
        final hit = await lookupBarcodeProduct('869111', memory: mem);
        expect(hit?.name, 'Süt');

        final apiClient = MockClient((req) async {
          expect(req.url.path, contains('869222'));
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name_tr': 'Yulaf Ezmesi',
                'brands': 'Eti',
                'quantity': '500 g',
                'categories_tags': ['en:breakfasts'],
              },
            }),
            200,
          );
        });
        final fromApi = await lookupBarcodeProduct(
          '869222',
          memory: const ShopMemory(),
          client: apiClient,
        );
        expect(fromApi?.displayText, 'Eti Yulaf Ezmesi (500 g)');

        final offlineClient = MockClient(
          (_) async => throw Exception('offline'),
        );
        final fail = await lookupBarcodeProduct(
          '869333',
          memory: const ShopMemory(),
          client: offlineClient,
        );
        expect(fail, isNull);
      },
    );

    test(
      'parseTurkishReceipt ve matchReceiptToList gerçekçi TR fişini eşler',
      () {
        const ocr = '''
BIM BIRLESIK MAGAZALAR A.S.
TARIH: 25.11.2026
DOST SUT 1 LT %1 *38,50
YUMURTA 15 LI %1 *69,90
2 ADET EKMEK *20,00
TOPKDV *3,40
TOPLAM *128,40
KREDI KARTI *128,40
''';
        final parsed = parseTurkishReceipt(ocr);
        expect(parsed.storeId, 'bim');
        expect(parsed.detectedTotal, 128.40);
        expect(parsed.lines, hasLength(3));

        final list = const [
          NoteItem(id: '1', text: 'Süt (1 lt)'),
          NoteItem(id: '2', text: 'Yumurta (15 adet)'),
          NoteItem(id: '3', text: 'Domates'),
        ];
        final matches = matchReceiptToList(parsed.lines, list);
        expect(matches.map((m) => m.itemId), ['1', '2']);
        expect(matches[0].receiptLine.price, 38.50);
        expect(matches[1].receiptLine.price, 69.90);

        final wordBoundary = parseTurkishReceipt('''
TOPKEK VISNELI *15,50
KARTOF CIPS *32,00
KART *47,50
''');
        expect(wordBoundary.lines.map((l) => l.rawName), [
          'TOPKEK VISNELI',
          'KARTOF CIPS',
        ]);

        const breadLine = ReceiptLine(rawName: 'EKMEK', price: 20, qty: 2);
        expect(
          receiptUnitPriceForItem(
            breadLine,
            const ShopItemMeta(qty: 2, unit: 'adet'),
          ),
          10,
        );
        expect(
          receiptUnitPriceForItem(
            breadLine,
            const ShopItemMeta(qty: 500, unit: 'g'),
          ),
          20,
        );
      },
    );

    test('Decisions D1 decideShopAisle güven eşiği ve reyon dönüşü', () async {
      AiDecisionsFlag.debugReset();
      addTearDown(AiDecisionsFlag.debugReset);

      DecisionService svcWith(double conf, String choice) => DecisionService(
        key: () async => 'k',
        http: JsonHttp(
          baseUrl: AiProvider.gemini.baseUrl,
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'answers': {
                  'reyon': {
                    'type': 'choice',
                    'choice': choice,
                    'confidence': conf,
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            ),
          ),
        ),
      );

      final high = await decideShopAisle(svcWith(0.88, 'r12'), 'Kedi kumu');
      expect(high, QuickAisle.pet);

      final low = await decideShopAisle(svcWith(0.50, 'r12'), 'Bilinmeyen');
      expect(low, isNull);
    });
  });

  group('Doğrudan not üzerinde alışveriş kipi widget akışları', () {
    testWidgets(
      'daraltılabilir reyon başlıkları, Kural 5 ID bazlı −/+ miktar ve canlı özet',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        var items = <NoteItem>[
          const NoteItem(
            id: '1',
            text: 'Süt (1 lt)',
            quantity: 1,
            unit: 'lt',
            price: 38,
          ),
          const NoteItem(
            id: '2',
            text: 'Domates (1 kg)',
            quantity: 1,
            unit: 'kg',
            price: 40,
          ),
        ];

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (ctx, setState) => MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              locale: const Locale('tr'),
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: ItemsEditor(
                        items: items,
                        showCheckboxes: true,
                        listMode: ListMode.shopping,
                        groupByAisle: true,
                        onChanged: (next) => setState(() => items = next),
                      ),
                    ),
                    ShoppingSummaryBar(items: items),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Reyon başlıkları görünür (Manav = 0, Süt & Kahvaltılık = 2).
        expect(find.byKey(const ValueKey('aisle-header-0')), findsOneWidget);
        expect(find.byKey(const ValueKey('aisle-header-2')), findsOneWidget);
        expect(find.text('Toplam: 78 ₺'), findsOneWidget);

        // Kural 5: Domates backing listede indeks 1'de, görselde Manav (0)
        // altında ilk sırada; + dokunuşu id='2' üzerinden doğru satırı günceller!
        await tester.tap(find.byKey(const ValueKey('shop-qty-inc-2')));
        await tester.pumpAndSettle();
        expect(items.firstWhere((i) => i.id == '2').text, 'Domates (1,5 kg)');
        expect(items.firstWhere((i) => i.id == '1').text, 'Süt (1 lt)');
        expect(find.text('Toplam: 98 ₺'), findsOneWidget);

        // Manav başlığını daralt → Domates gizlenir, Süt görünür kalır.
        await tester.tap(find.byKey(const ValueKey('aisle-header-0')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('shop-qty-inc-2')), findsNothing);
        expect(find.byKey(const ValueKey('shop-qty-inc-1')), findsOneWidget);
      },
    );
  });
}
