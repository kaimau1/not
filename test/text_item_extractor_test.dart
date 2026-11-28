import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/text_item_extractor.dart';
import 'package:notlar/features/notes/presentation/text_extract_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TextItemExtractor (0 kredi yerel ayıklama)', () {
    test('WhatsApp sohbet zaman damgası ve selamlaşmayı temizleyip maddeleri ayırır', () {
      const chat = '''
[14:20] Ahmet: Selam
[14:21] Ahmet: Akşama şunları alabilir misin: 2 kg domates, 1 lt süt ve ekmek
[14:22] Ayşe: Tamam
[14:23] Ahmet: Kahve 180 tl lazım
''';
      expect(TextItemExtractor.isExtractablePaste(chat), isTrue);
      final drafts = TextItemExtractor.extractLocal(
        chat,
        mode: ListMode.shopping,
      );
      final names = [for (final d in drafts) d.item.text];
      expect(names, containsAll(['Domates', 'Süt', 'Ekmek', 'Kahve']));
      expect(names.any((n) => n.toLowerCase().contains('selam')), isFalse);
      expect(names.any((n) => n.toLowerCase().contains('tamam')), isFalse);

      final domates = drafts.firstWhere((d) => d.item.text == 'Domates').item;
      expect(domates.quantity, 2);
      expect(domates.unit, 'kg');

      final kahve = drafts.firstWhere((d) => d.item.text == 'Kahve').item;
      expect(kahve.price, 180);
    });

    test('tarif malzeme listesi ve numaralı maddelerde tekrarları eler', () {
      const recipe = '''
Malzemeler:
1. 3 yumurta
2. 250 g kaşar peyniri
- tereyağı
- 3 yumurta
''';
      final drafts = TextItemExtractor.extractLocal(
        recipe,
        mode: ListMode.shopping,
      );
      expect(drafts, hasLength(3));
      expect(drafts.first.item.text, 'Yumurta');
      expect(drafts.first.item.quantity, 3);
      expect(drafts[1].item.quantity, 250);
      expect(drafts[1].item.unit, 'g');
    });

    testWidgets('showTextExtractSheet seçilen maddeleri onaylayıp döndürür', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      List<NoteItem>? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () async {
                    result = await showTextExtractSheet(
                      context,
                      ref,
                      initialText: '- 2 kg elma\n- süt\n- ekmek',
                      mode: ListMode.shopping,
                    );
                  },
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text('Elma'), findsOneWidget);
      expect(find.text('Süt'), findsOneWidget);
      expect(find.text('Ekmek'), findsOneWidget);

      // İkinci maddenin seçimini kaldır.
      await tester.tap(find.byKey(const ValueKey('text-extract-item-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('text-extract-confirm')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.map((e) => e.text).toList(), ['Elma', 'Ekmek']);
    });
  });
}
