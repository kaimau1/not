import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/data/user_templates.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_templates.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_template_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hazır not şablonları (kullanıcı isteği 2026-09-26: "modlar, alışveriş
/// listesi gibi").
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    await initializeDateFormatting('tr');
    l10n = lookupAppLocalizations(const Locale('tr'));
  });

  final monday = DateTime(2026, 9, 28); // pazartesi

  test('alışveriş listesi: madde listesi, hazır maddeler', () {
    final c = buildNoteTemplate(NoteTemplate.shopping, l10n, now: monday);
    expect(c.type, NoteType.checklist);
    expect(c.title, 'Alışveriş listesi');
    expect(c.items, ['Ekmek', 'Süt', 'Yumurta', 'Meyve', 'Sebze']);
  });

  test('yapılacaklar tarihli ve boş', () {
    final c = buildNoteTemplate(NoteTemplate.todo, l10n, now: monday);
    expect(c.type, NoteType.checklist);
    expect(c.title, contains('28 Eylül'));
    expect(c.items, isEmpty);
  });

  test('haftalık plan yedi gün başlığı taşır', () {
    final c = buildNoteTemplate(
      NoteTemplate.weekly,
      l10n,
      now: DateTime(2026, 10, 1), // çarşamba → hafta 28 Eylül'de başlar
    );
    expect(c.type, NoteType.text);
    final plain = stripRichMarkers(c.body);
    for (final day in ['Pazartesi', 'Salı', 'Çarşamba', 'Pazar']) {
      expect(plain, contains(day));
    }
    expect(c.title, contains('28 Eyl'));
  });

  test('her şablon içerik üretir', () {
    for (final t in NoteTemplate.values) {
      final c = buildNoteTemplate(t, l10n, now: monday);
      expect(c.title, isNotEmpty, reason: '$t');
      expect(c.body.isNotEmpty || c.type == NoteType.checklist, isTrue);
      expect(t.label(l10n), isNotEmpty);
      expect(t.description(l10n), isNotEmpty);
    }
  });

  test('her şablon bir bölüme ait; her bölüm dolu', () {
    for (final c in TemplateCategory.values) {
      expect(
        NoteTemplate.values.where((t) => t.category == c),
        isNotEmpty,
        reason: '$c',
      );
    }
  });

  test('kimlikler tekrarsız (son kullanılanlar bunlarla saklanıyor)', () {
    final keys = NoteTemplate.values.map((t) => t.key).toSet();
    expect(keys, hasLength(NoteTemplate.values.length));
  });

  test('alışveriş ve seyahat listelerinin ÖNERİ grupları var', () {
    final shopping = templateSuggestions(NoteTemplate.shopping, l10n);
    expect(shopping.map((g) => g.label), contains('Meyve ve sebze'));
    expect(shopping.expand((g) => g.items), contains('Domates'));
    expect(templateSuggestions(NoteTemplate.travel, l10n), isNotEmpty);
    // Grubu olmayan şablon boş liste döner.
    expect(templateSuggestions(NoteTemplate.meeting, l10n), isEmpty);
  });

  test('yeni liste şablonları gerçek madde listesi', () {
    for (final t in [
      NoteTemplate.habits,
      NoteTemplate.cleaning,
      NoteTemplate.moving,
      NoteTemplate.workout,
    ]) {
      final c = buildNoteTemplate(t, l10n, now: monday);
      expect(c.type, NoteType.checklist, reason: '$t');
      expect(c.items, isNotEmpty, reason: '$t');
    }
  });

  test('hedefler şablonu yılı başlığa yazar', () {
    final c = buildNoteTemplate(NoteTemplate.goals, l10n, now: monday);
    expect(c.title, contains('2026'));
    expect(stripRichMarkers(c.body), contains('Bu hafta'));
  });

  group('önizlemede biçilen içerik', () {
    NoteTemplateContent base() =>
        buildNoteTemplate(NoteTemplate.shopping, l10n, now: monday);

    test('seçilen maddeler ve liste türü nota geçer', () {
      final c = composeTemplateContent(
        base(),
        title: '  Market  ',
        type: NoteType.ordered,
        items: ['Süt', '  ', 'Domates '],
      );
      expect(c.title, 'Market');
      expect(c.type, NoteType.ordered);
      expect(c.items, ['Süt', 'Domates']);
    });

    test('başlık silinirse şablonun başlığı kalır', () {
      final c = composeTemplateContent(
        base(),
        title: '',
        type: NoteType.checklist,
        items: const [],
      );
      expect(c.title, 'Alışveriş listesi');
    });

    test('yazı şablonunun türü ve gövdesi değişmez', () {
      final meeting = buildNoteTemplate(
        NoteTemplate.meeting,
        l10n,
        now: monday,
      );
      final c = composeTemplateContent(
        meeting,
        title: 'Pazartesi toplantısı',
        type: NoteType.checklist,
        items: const ['x'],
      );
      expect(c.type, NoteType.text);
      expect(c.body, meeting.body);
      expect(c.items, isEmpty);
    });
  });

  group('kendi şablonum', () {
    const list = Note(
      id: 'n1',
      type: NoteType.checklist,
      title: 'Haftalık market',
      items: [
        NoteItem(id: '1', text: 'Süt', checked: true),
        NoteItem(id: '2', text: ''),
        NoteItem(id: '3', text: 'Ekmek'),
      ],
    );

    test('nottan şablon: boş maddeler atılır, işaretler saklanmaz', () {
      final t = UserTemplate.fromNote(list, id: 'u1');
      expect(t.name, 'Haftalık market');
      expect(t.type, NoteType.checklist);
      expect(t.items, ['Süt', 'Ekmek']);
    });

    test('kayıt gidip gelir; bozuk kayıt boş liste olur', () {
      final t = UserTemplate.fromNote(list, id: 'u1', name: 'Market');
      final back = decodeUserTemplates(encodeUserTemplates([t]));
      expect(back.single.id, 'u1');
      expect(back.single.name, 'Market');
      expect(back.single.items, ['Süt', 'Ekmek']);
      expect(decodeUserTemplates('{bozuk'), isEmpty);
      expect(decodeUserTemplates(null), isEmpty);
    });

    test('yalnız metin ve liste notları şablon olabilir', () {
      expect(canSaveAsTemplate(list), isTrue);
      expect(
        canSaveAsTemplate(const Note(id: 'p', type: NoteType.pdf)),
        isFalse,
      );
      expect(
        canSaveAsTemplate(const Note(id: 'a', type: NoteType.archive)),
        isFalse,
      );
    });
  });

  testWidgets('galeri → önizleme: öneri eklenir, not maddeleriyle doğar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    NoteTemplateContent? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async =>
                      result = await showNoteTemplateSheet(context),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Listeler'), findsWidgets);

    await tester.tap(find.text('Alışveriş listesi'));
    await tester.pumpAndSettle();
    // Varsayılan madde işaretli gelir; öneri çipi listeye ekler.
    expect(find.widgetWithText(CheckboxListTile, 'Süt'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Domates'));
    await tester.pumpAndSettle();
    // "Ekmek" listeden çıkarılır.
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Ekmek'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.type, NoteType.checklist);
    expect(result!.items, contains('Domates'));
    expect(result!.items, isNot(contains('Ekmek')));
    expect(result!.items, contains('Süt'));
    // Son kullanılanlara girdi.
    expect(prefs.getStringList('recent_templates'), ['b:shopping']);
  });
}
