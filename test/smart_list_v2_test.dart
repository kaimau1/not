import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note_templates.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';
import 'package:notlar/features/notes/domain/smart_lexicon_v2.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/note_template_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_list_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });
  setUp(() => AutoSpell.memory = SpellMemory());

  group('SmartList v2 — 16 specialized kinds & bilingual detection', () {
    test(
      'smartKindFromPhrase recognizes TR & EN triggers for all 16 kinds',
      () {
        expect(smartKindFromPhrase('taşınma listesi'), SmartListKind.moving);
        expect(smartKindFromPhrase('moving checklist'), SmartListKind.moving);
        expect(smartKindFromPhrase('temizlik planı'), SmartListKind.cleaning);
        expect(
          smartKindFromPhrase('cleaning schedule'),
          SmartListKind.cleaning,
        );
        expect(smartKindFromPhrase('alışkanlık takibi'), SmartListKind.habits);
        expect(smartKindFromPhrase('habit tracker'), SmartListKind.habits);
        expect(
          smartKindFromPhrase('antrenman programı'),
          SmartListKind.workout,
        );
        expect(smartKindFromPhrase('workout routine'), SmartListKind.workout);
        expect(smartKindFromPhrase('hediye listesi'), SmartListKind.gifts);
        expect(smartKindFromPhrase('gift ideas'), SmartListKind.gifts);
        expect(
          smartKindFromPhrase('izlenecekler listesi'),
          SmartListKind.watchlist,
        );
        expect(smartKindFromPhrase('watchlist'), SmartListKind.watchlist);
        expect(smartKindFromPhrase('etkinlik planı'), SmartListKind.event);
        expect(smartKindFromPhrase('party planning'), SmartListKind.event);
        expect(smartKindFromPhrase('bütçe takibi'), SmartListKind.expense);
        expect(smartKindFromPhrase('expense tracker'), SmartListKind.expense);
        expect(smartKindFromPhrase('eczane listesi'), SmartListKind.pharmacy);
        expect(smartKindFromPhrase('kırtasiye'), SmartListKind.stationery);
        expect(smartKindFromPhrase('nalbur'), SmartListKind.hardware);
        expect(smartKindFromPhrase('kamp'), SmartListKind.camping);
        expect(smartKindFromPhrase('bebek'), SmartListKind.baby);
        expect(smartKindFromPhrase('spor ekipman'), SmartListKind.sport);
        expect(smartKindFromPhrase('bavul'), SmartListKind.packing);
        expect(smartKindFromPhrase('market'), SmartListKind.shopping);
      },
    );

    test('detectSmartKindFromItems infers all new domain kinds cleanly', () {
      expect(
        detectSmartKindFromItems(const [
          'Koli ve bant al',
          'Nakliye günü rezervasyonu',
          'Balonlu naylon al',
        ], locale: 'tr'),
        SmartListKind.moving,
      );
      expect(
        detectSmartKindFromItems(const [
          'Bench press',
          'Squat',
          'Plank',
        ], locale: 'en'),
        SmartListKind.workout,
      );
      expect(
        detectSmartKindFromItems(const [
          'Parol',
          'Yara bandı',
          'Termometre',
        ], locale: 'tr'),
        SmartListKind.pharmacy,
      );
      expect(
        detectSmartKindFromItems(const [
          'Uyku tulumu',
          'Kamp ocağı',
          'Çadır kazığı',
        ], locale: 'tr'),
        SmartListKind.camping,
      );
    });

    test('kSmartKindSpecs covers all 16 non-generic kinds with TR/EN data', () {
      for (final kind in SmartListKind.values) {
        if (kind == SmartListKind.generic) continue;
        final spec = kSmartKindSpecs[kind];
        expect(spec, isNotNull, reason: 'Missing spec for $kind');
        expect(spec!.groups, isNotEmpty, reason: 'Empty groups for $kind');
        expect(
          spec.starterPacks,
          isNotEmpty,
          reason: 'Empty starterPacks for $kind',
        );
        for (final g in spec.groups) {
          expect(g.label(isTr: true), isNotEmpty);
          expect(g.label(isTr: false), isNotEmpty);
          expect(g.items(isTr: true), isNotEmpty);
          expect(g.items(isTr: false), isNotEmpty);
        }
        final trLex = lexiconForSmartKind(kind, 'tr');
        final enLex = lexiconForSmartKind(kind, 'en');
        expect(trLex.isEmpty, isFalse);
        expect(enLex.isEmpty, isFalse);
      }
    });

    test(
      'wizards generate day/weather-scaled packing & guest-scaled event',
      () {
        final beachTr = generatePackingPlan(
          days: 5,
          weather: TripWeather.hot,
          style: TripStyle.beach,
          isTr: true,
        );
        expect(beachTr, isNotEmpty);
        expect(
          beachTr.any((e) => e.text.toLowerCase().contains('mayo')),
          isTrue,
        );

        final intlEn = generatePackingPlan(
          days: 3,
          weather: TripWeather.cold,
          style: TripStyle.international,
          isTr: false,
        );
        expect(
          intlEn.any((e) => e.text.toLowerCase().contains('passport')),
          isTrue,
        );
        expect(
          intlEn.any((e) => e.text.toLowerCase().contains('coat')),
          isTrue,
        );

        final partyTr = generateEventPlan(
          guests: 20,
          style: EventStyle.birthday,
          isTr: true,
        );
        expect(partyTr, isNotEmpty);
        expect(partyTr.any((e) => e.text.contains('20')), isTrue);
      },
    );
  });

  group('QuickEntry v2 — EN quantities, multipliers & inline price', () {
    test('extractInlinePrice parses TL, ₺, \$, € cleanly', () {
      final tr = extractInlinePrice('Süt 45 TL');
      expect(tr.text, 'Süt');
      expect(tr.price, 45.0);

      final sym = extractInlinePrice('Kahve 120.50₺');
      expect(sym.text, 'Kahve');
      expect(sym.price, 120.5);

      final usd = extractInlinePrice('Headphones \$79');
      expect(usd.text, 'Headphones');
      expect(usd.price, 79.0);

      final none = extractInlinePrice('2 kilo elma');
      expect(none.price, isNull);
      expect(none.text, '2 kilo elma');
    });

    test('EN parser supports compound quantities and multipliers', () {
      final lex = QuickLexicon()
        ..add('Egg', group: 1)
        ..add('Milk', group: 1)
        ..add('Tomato', group: 0)
        ..add('Apple', group: 0);
      final p = QuickParser(lex);

      final eggs = p.parse('a dozen eggs', flush: true);
      expect(eggs.items, hasLength(1));
      expect(eggs.items.single.name, 'Egg');
      expect(eggs.items.single.qty, '12');

      final mult = p.parse('3x tomato, 2x milk', flush: true);
      expect(mult.items.length, 2);
      expect(mult.items[0].name, 'Tomato');
      expect(mult.items[0].qty, '3');
      expect(mult.items[1].name, 'Milk');
      expect(mult.items[1].qty, '2');

      final half = p.parse('one and a half kg apple', flush: true);
      expect(half.items.single.name, 'Apple');
      expect(half.items.single.qty, '1,5 kg');
    });

    test('NoteTemplate.expense is now an expense checklist template', () {
      expect(NoteTemplate.expense.smartKind, SmartListKind.expense);
      expect(NoteTemplate.moving.smartKind, SmartListKind.moving);
      expect(NoteTemplate.habits.smartKind, SmartListKind.habits);
    });
  });

  group('QuickListScreen v2 widget interactions', () {
    testWidgets('shows kind pill, catalog button, and opens kind picker', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(430, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notesStreamProvider.overrideWithValue(const AsyncData([])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Builder(
              builder: (ctx) =>
                  Scaffold(body: QuickListScreen(args: smartListArgs(ctx))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('quick-list-kind-pill')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('quick-list-catalog')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quick-list-kind-pill')));
      await tester.pumpAndSettle();
      final opt = find.byKey(const ValueKey('smart-kind-option-shopping'));
      expect(opt, findsOneWidget);

      await tester.tap(opt);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('quick-list-catalog')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
