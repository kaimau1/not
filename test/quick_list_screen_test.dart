import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_templates.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/note_template_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_entry_bar.dart';
import 'package:notlar/features/notes/presentation/quick_list_screen.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart' show CountingNotesRepository;

/// Hızlı ekle yazımlarını yakalayan depo.
class _DropRepo extends CountingNotesRepository {
  final writes = <String, Map<String, dynamic>>{};

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) {
    writes[noteId] = fields;
    return Future.value();
  }
}

/// Hızlı liste ekranı ve "Hızlı ekle" (kullanıcı isteği 2026-11-15).
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
  });
  setUp(() => AutoSpell.memory = SpellMemory());

  Future<SharedPreferences> pumpHost(
    WidgetTester tester, {
    required Future<void> Function(BuildContext, WidgetRef) onTap,
    List<Note> notes = const [],
    Map<String, Object> prefs = const {},
    Size size = const Size(412, 915),
    NotesRepository? repo,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(p),
          notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
          notesRepositoryProvider.overrideWithValue(repo),
          // Testte yapay zekâ yok: hızlı ekle "hangi not?" diye sorar.
          aiAvailabilityProvider.overrideWithValue(AiAvailability.needsKey),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Consumer(
            builder: (context, ref, _) {
              // Uygulamada ana ekran akışı hep dinler: değer hazırdır.
              ref.watch(notesStreamProvider);
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => onTap(context, ref),
                    child: const Text('aç'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    return p;
  }

  Finder row(String text) => find.descendant(
    of: find.byKey(const ValueKey('quick-list-scroll')),
    matching: find.text(text),
  );

  testWidgets(
    'alışveriş şablonu doğrudan hızlı listeye açılır: boş başlar, yazarken canlı dolar',
    (tester) async {
      TemplateOutcome? outcome;
      final prefs = await pumpHost(
        tester,
        onTap: (context, ref) async => outcome = await pickTemplate(
          context,
          ref,
          initial: NoteTemplate.shopping,
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.byType(QuickListScreen), findsOneWidget);
      // Hazır maddeler listeye GİRMEZ; "Sık eklediklerin"de çip olarak durur.
      expect(find.byKey(const ValueKey('quick-list-scroll')), findsNothing);
      expect(find.byKey(const ValueKey('quick-chip-Süt')), findsOneWidget);

      // Kullanıcının örneği: yan yana, virgüllü, yapışık, bozuk.
      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        'muz armut,çilekkivi un yunurta ',
      );
      await tester.pumpAndSettle();
      for (final t in ['Muz', 'Armut', 'Çilek', 'Kivi', 'Un', 'Yumurta']) {
        expect(row(t), findsOneWidget, reason: t);
      }
      // Tamamlanan kısım alandan eksildi.
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('quick-entry-field')))
            .controller!
            .text
            .trim(),
        '',
      );

      // Çip: tek dokunuşla girer, şeritten düşer.
      await tester.tap(find.byKey(const ValueKey('quick-chip-Süt')));
      await tester.pumpAndSettle();
      expect(row('Süt'), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-chip-Süt')), findsNothing);

      // Aynı madde yeniden yazılınca çoğalmaz; miktar gelirse güncellenir.
      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        '2 süt, deterjan,',
      );
      await tester.pumpAndSettle();
      expect(row('Süt (2)'), findsOneWidget);
      expect(row('Süt'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('quick-list-done')));
      await tester.pumpAndSettle();
      expect(find.byType(QuickListScreen), findsNothing);
      final c = outcome!.content;
      expect(outcome!.open, isFalse);
      expect(outcome!.quick, isTrue);
      expect(c.type, NoteType.checklist);
      expect(c.columns, 2, reason: 'iki sütun varsayılan');
      // Reyon sırası: manav → kahvaltılık → temel gıda → temizlik.
      expect(c.items, [
        'Muz',
        'Armut',
        'Çilek',
        'Kivi',
        'Yumurta',
        'Süt (2)',
        'Un',
        'Deterjan',
      ]);
      expect(prefs.getStringList('recent_templates'), ['b:shopping']);
      // Eklenenler hafızaya girdi: sonraki sefer "Sık eklediklerin"de.
      final memory = QuickEntryMemory.decode(
        prefs.getString('quick_entry_memory_v1'),
      );
      expect(memory.top('b:shopping', count: 20), contains('Deterjan'));
      // Kabul edilen düzeltme yazım hafızasına gözlem oldu.
      expect(AutoSpell.memory.fixes['yunurta']?.$1, 'yumurta');
      // Yazım hafızasının gecikmeli kaydı bitsin.
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('değişmeyen satır aynı örnek; düzeltme geri alınır; sütun', (
    tester,
  ) async {
    TemplateOutcome? outcome;
    await pumpHost(
      tester,
      onTap: (context, ref) async => outcome = await pickTemplate(
        context,
        ref,
        initial: NoteTemplate.shopping,
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('quick-entry-field'));
    await tester.enterText(field, 'muz yunurta ');
    await tester.pumpAndSettle();
    Widget rowWidget(String text) => tester.widget(
      find.ancestor(
        of: row(text),
        matching: find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_QuickRow',
        ),
      ),
    );
    final before = rowWidget('Muz');
    await tester.enterText(field, 'armut ');
    await tester.pumpAndSettle();
    expect(identical(rowWidget('Muz'), before), isTrue);
    // Yazarken (madde çıkmadan) liste hiç kurulmaz: satır yine aynı örnek.
    await tester.enterText(field, 'elm');
    await tester.pump();
    expect(identical(rowWidget('Muz'), before), isTrue);
    await tester.enterText(field, '');

    // "yunurta" → Yumurta düzeltildi; simgeye dokununca yazıldığı gibi kalır.
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w.key.toString().contains('quick-row-revert-'),
      ),
    );
    await tester.pumpAndSettle();
    expect(row('Yunurta'), findsOneWidget);
    expect(row('Yumurta'), findsNothing);
    // Bir daha düzeltilmez.
    await tester.enterText(field, 'yunurta ');
    await tester.pumpAndSettle();
    expect(row('Yumurta'), findsNothing);

    // Tek sütuna geç: not tek sütun doğar.
    await tester.tap(find.byKey(const ValueKey('quick-list-columns')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-list-done')));
    await tester.pumpAndSettle();
    expect(outcome!.content.columns, 1);
    // Bildirimin kapanma sayacı bitsin.
    await tester.pump(const Duration(seconds: 8));
  });

  testWidgets('boş bırakılırsa not oluşmaz; geri = kaydet', (tester) async {
    TemplateOutcome? outcome;
    var calls = 0;
    await pumpHost(
      tester,
      onTap: (context, ref) async {
        calls++;
        outcome = await pickTemplate(
          context,
          ref,
          initial: NoteTemplate.shopping,
        );
      },
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(outcome, isNull);

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    // Yazılıp bırakılan (ayırıcısız) kelime de listeye girer.
    await tester.enterText(
      find.byKey(const ValueKey('quick-entry-field')),
      'muz',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(outcome!.content.items, ['Muz']);
  });

  testWidgets(
    'galeriden liste şablonu hızlı listeye, yazı şablonu önizlemeye',
    (tester) async {
      TemplateOutcome? outcome;
      await pumpHost(
        tester,
        size: const Size(420, 2400),
        onTap: (context, ref) async =>
            outcome = await pickTemplate(context, ref),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seyahat çantası').last);
      await tester.pumpAndSettle();
      expect(find.byType(QuickListScreen), findsOneWidget);
      // Seyahat: kendi öneri grupları sekme olarak.
      expect(find.byKey(const ValueKey('quick-list-tabs')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('quick-list-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(outcome, isNull);

      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toplantı').last);
      await tester.pumpAndSettle();
      expect(find.byType(QuickListScreen), findsNothing);
      expect(find.byType(TemplateComposer), findsOneWidget);
    },
  );

  test(
    'geçen seferden kalanlar: aynı başlıklı en yeni listenin işaretsizleri',
    () {
      final notes = [
        Note(
          id: 'eski',
          type: NoteType.checklist,
          title: 'Alışveriş listesi',
          updatedAt: DateTime(2026, 11),
          items: const [NoteItem(id: '1', text: 'Tuz')],
        ),
        Note(
          id: 'yeni',
          type: NoteType.checklist,
          title: 'Alışveriş listesi',
          updatedAt: DateTime(2026, 11, 10),
          items: const [
            NoteItem(id: '1', text: 'Süt', checked: true),
            NoteItem(id: '2', text: 'Ekmek'),
            NoteItem(id: '3', text: ''),
            NoteItem(id: '4', text: 'Peynir (1 kg)'),
          ],
        ),
        Note(
          id: 'cop',
          type: NoteType.checklist,
          title: 'Alışveriş listesi',
          updatedAt: DateTime(2026, 11, 12),
          deletedAt: DateTime(2026, 11, 12),
          items: const [NoteItem(id: '1', text: 'Çöpteki')],
        ),
      ];
      expect(quickLeftovers(notes, 'Alışveriş listesi'), [
        'Ekmek',
        'Peynir (1 kg)',
      ]);
      expect(quickLeftovers(notes, 'Seyahat çantası'), isEmpty);
    },
  );

  group('hızlı ekle', () {
    final shopping = Note(
      id: 'a',
      type: NoteType.checklist,
      title: 'Alışveriş listesi',
      updatedAt: DateTime(2026, 11, 10),
      items: const [
        NoteItem(id: '1', text: 'Süt', checked: true),
        NoteItem(id: '2', text: 'Ekmek'),
      ],
    );
    final todo = Note(
      id: 'b',
      type: NoteType.checklist,
      title: 'Yapılacaklar',
      updatedAt: DateTime(2026, 11, 12),
      items: const [NoteItem(id: '1', text: 'Faturayı öde')],
    );
    final text = Note(
      id: 'c',
      type: NoteType.text,
      title: 'Fikirler',
      body: 'ilk satır',
      updatedAt: DateTime(2026, 11, 11),
    );

    test('adaylar: son kullanılan önce; kilitli/çöpteki/başlıksız yok', () {
      final locked = Note(
        id: 'k',
        type: NoteType.text,
        title: 'Gizli',
        locked: true,
      );
      final list = quickDropCandidates(
        [
          shopping,
          todo,
          text,
          locked,
          const Note(id: 'x', type: NoteType.text),
        ],
        ['c'],
      );
      expect([for (final n in list) n.id], ['c', 'b', 'a']);
    });

    test('alışveriş listesine kelime kelime; tekrar yok, işaretli açılır', () {
      var n = 0;
      final r = quickDropFields(
        shopping,
        'sut ekmek 2 muz',
        locale: 'tr',
        newId: () => 'yeni${n++}',
      );
      final items = (r.fields['items'] as List).cast<Map<String, dynamic>>();
      expect([for (final i in items) i['text']], ['Süt', 'Ekmek', 'Muz (2)']);
      expect(items[0]['checked'], isFalse);
      expect(r.added, 2);
    });

    test('cümleli listede yalnız virgül böler; yazı notunda sona satır', () {
      final r = quickDropFields(
        todo,
        'annemi ara, elma bahçesine git',
        locale: 'tr',
        newId: () => 'y',
      );
      final items = (r.fields['items'] as List).cast<Map<String, dynamic>>();
      expect(
        [for (final i in items) i['text']],
        ['Faturayı öde', 'Annemi ara', 'Elma bahçesine git'],
      );
      final t = quickDropFields(text, 'ikinci fikir', locale: 'tr');
      expect(t.fields['body'], 'ilk satır\nikinci fikir');
      expect(quickDropFields(shopping, 'ekmek', locale: 'tr').fields, isEmpty);
    });

    testWidgets('levha: hedef metinden çözülür, çiple değiştirilir', (
      tester,
    ) async {
      await pumpHost(
        tester,
        notes: [shopping, todo, text],
        prefs: {'quick_drop_mic': false},
        onTap: (context, ref) => showQuickDropSheet(context),
      );
      await tester.pump();
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      ChoiceChip chip(String id) =>
          tester.widget(find.byKey(ValueKey('quick-drop-target-$id')));
      // Varsayılan hedef: en son değişen not.
      expect(chip('b').selected, isTrue);
      final add = find.byKey(const ValueKey('quick-drop-add'));
      expect(tester.widget<FilledButton>(add).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        'alışveriş listesine süt ekle',
      );
      await tester.pumpAndSettle();
      expect(chip('a').selected, isTrue);
      expect(find.text('Ekle · süt'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        'bir fikir',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-drop-target-c')));
      await tester.pumpAndSettle();
      expect(chip('c').selected, isTrue);
      expect(find.text('Ekle · bir fikir'), findsOneWidget);
    });

    // Kullanıcı bulgusu 2026-11-16: konuşma bitince hedefi söylemeden yanlış
    // nota ekleniyordu. Artık geri sayım (Bekle ile durur); "… ekle" dendi
    // ama ad bulunamadıysa ya da başa baş kaldıysa sorulur.
    Future<_DropRepo> openSheet(WidgetTester tester, List<Note> notes) async {
      final repo = _DropRepo();
      await pumpHost(
        tester,
        notes: notes,
        repo: repo,
        prefs: {'quick_drop_mic': false},
        onTap: (context, ref) => showQuickDropSheet(context),
      );
      await tester.pump();
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      return repo;
    }

    Future<void> say(WidgetTester tester, String text) async {
      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        text,
      );
      await tester.pump();
      tester.widget<QuickEntryBar>(find.byType(QuickEntryBar)).onSpeechEnd!();
      await tester.pump();
    }

    testWidgets('konuşma sonu: geri sayım, sonra eklenir; Bekle durdurur', (
      tester,
    ) async {
      final repo = await openSheet(tester, [shopping, todo, text]);
      await say(tester, 'kargoyu sor');
      expect(find.byKey(const ValueKey('quick-drop-counting')), findsOneWidget);
      expect(find.text('“Yapılacaklar” notuna ekleniyor…'), findsOneWidget);
      expect(repo.writes, isEmpty, reason: 'hemen eklenmez');
      await tester.tap(find.byKey(const ValueKey('quick-drop-wait')));
      await tester.pump(const Duration(seconds: 3));
      expect(repo.writes, isEmpty, reason: 'Bekle durdurdu');

      await say(tester, 'kargoyu sor bir de faturayı yatır');
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final items = repo.writes['b']!['items'] as List;
      expect(
        [for (final i in items) (i as Map)['text']],
        ['Faturayı öde', 'Kargoyu sor', 'Faturayı yatır'],
      );
    });

    testWidgets('"… ekle" dendi, ad bulunamadı: sorulur, eklenmez', (
      tester,
    ) async {
      final repo = await openSheet(tester, [shopping, todo, text]);
      await say(tester, 'yeni fikir hatalar notuna ekle');
      expect(find.byKey(const ValueKey('quick-drop-ask')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(repo.writes, isEmpty);
      // Çipe dokunup Ekle: kullanıcının seçtiği nota.
      await tester.tap(find.byKey(const ValueKey('quick-drop-target-c')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
      await tester.pumpAndSettle();
      expect(repo.writes.keys, ['c']);
    });

    testWidgets('başa baş kalan iki not: Ekle "hangi not?" bekler', (
      tester,
    ) async {
      final a = Note(
        id: 'pa',
        type: NoteType.checklist,
        title: 'Proje A',
        updatedAt: DateTime(2026, 11, 13),
      );
      final b = Note(
        id: 'pb',
        type: NoteType.checklist,
        title: 'Proje B',
        updatedAt: DateTime(2026, 11, 12),
      );
      final repo = await openSheet(tester, [a, b, todo]);
      await say(tester, 'logo hazırla projeye ekle');
      final add = find.byKey(const ValueKey('quick-drop-add'));
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
      expect(find.text('Hangi nota eklensin?'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('quick-drop-target-pb')));
      await tester.pump();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(repo.writes.keys, ['pb']);
    });

    testWidgets('sonda söylenen ad kökten bulunur', (tester) async {
      final files = Note(
        id: 'f',
        type: NoteType.checklist,
        title: 'Dosyalarımdaki hatalar',
        updatedAt: DateTime(2026, 11, 2),
      );
      final repo = await openSheet(tester, [todo, files]);
      await say(tester, 'dosyalar geliştirme yapılması lazım dosyalara ekle');
      expect(
        find.text('“Dosyalarımdaki hatalar” notuna ekleniyor…'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      final items = repo.writes['f']!['items'] as List;
      expect(
        (items.single as Map)['text'],
        'Dosyalar geliştirme yapılması lazım',
      );
    });
  });
}
