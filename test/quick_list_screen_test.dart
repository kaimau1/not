import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_templates.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart'
    show QuickParser, quickAscii;
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

  /// Yeni not olarak kaydedilenler (H11): (tür, gövde).
  final created = <(NoteType, String)>[];

  @override
  Future<String> createNote(
    NoteType type, {
    double? orderIndex,
    String title = '',
    String body = '',
    List<String>? items,
    String? folderId,
    DateTime? reminderAt,
    int listColumns = 1,
  }) {
    created.add((type, body));
    return Future.value('yeni${created.length}');
  }

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) {
    writes[noteId] = fields;
    return Future.value();
  }
}

/// Hızlı liste ekranı ve "Hızlı ekle" (kullanıcı isteği 2026-11-15).
void main() {
  // Hedef şeridi yatay ve tembel: "Yeni not" çipi başta olduğundan dar
  // test ekranında sondaki çipler kaydırılınca kurulur.
  Future<void> tapTarget(WidgetTester tester, String id) async {
    final chip = find.byKey(ValueKey('quick-drop-target-$id'));
    await tester.scrollUntilVisible(
      chip,
      80,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('quick-drop-targets')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
  }

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
    AiAvailability ai = AiAvailability.needsKey,
    List<Override> extra = const [],
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
          aiAvailabilityProvider.overrideWithValue(ai),
          ...extra,
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

    // HE-2 (17K §4.2): önizleme satırı Ekle'ye basmadan nota GİRECEKLERİ
    // gösterir — quickDropFields ile aynı ayrıştırma, yazım yok.
    test('HE-2 önizleme: yeni + yeniden açılan maddeler; yazı notunda '
        'satırlar; hepsi notta → boş', () {
      QuickParser parser() => quickDropListParser(shopping, locale: 'tr');
      expect(quickDropPreview(shopping, 'sut ekmek 2 muz', parser: parser), [
        'Muz (2)',
        'Süt',
      ]);
      expect(quickDropPreview(shopping, 'ekmek', parser: parser), isEmpty);
      expect(
        quickDropPreview(
          text,
          'kargoyu sor bir de faturayı yatır',
          parser: () => throw StateError('yazı notu ayrıştırıcı kurmaz'),
        ),
        ['kargoyu sor', 'faturayı yatır'],
      );
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
      // HE-2: içerik düğmede değil önizleme satırında (işaretli Süt açılır).
      expect(find.text('→ Alışveriş listesi · Süt (1 madde)'), findsOneWidget);
      expect(find.text('Ekle'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        'bir fikir',
      );
      await tester.pumpAndSettle();
      await tapTarget(tester, 'c');
      await tester.pumpAndSettle();
      expect(chip('c').selected, isTrue);
      expect(find.text('→ Fikirler · bir fikir'), findsOneWidget);
    });

    // HE-2: üç anahtar başlıkta değil ⚙ menüsünde.
    testWidgets('HE-2: anahtarlar ⚙ arkasında, menüden değişir', (
      tester,
    ) async {
      final prefs = await pumpHost(
        tester,
        notes: [shopping, todo, text],
        prefs: {'quick_drop_mic': false},
        onTap: (context, ref) => showQuickDropSheet(context),
      );
      await tester.pump();
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-drop-keyboard')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quick-drop-settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-drop-keyboard')));
      await tester.pumpAndSettle();
      expect(prefs.getBool('quick_drop_keyboard'), isFalse);
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

    // H11 (17K §4.1): uygun not yokken levha çıkmaz sokaktı (yazma alanı
    // yoktu, yalnız "önce not oluştur"). Artık yazılan yeni not olur.
    testWidgets('not yokken yazılan yeni not olarak kaydedilir (yazarak ve '
        'konuşarak)', (tester) async {
      final repo = await openSheet(tester, const []);
      expect(find.byKey(const ValueKey('quick-drop-no-notes')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-entry-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('quick-entry-field')),
        'kargoyu sor',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
      await tester.pumpAndSettle();
      expect(repo.created, [(NoteType.text, 'kargoyu sor')]);
      expect(find.text('Yeni not olarak kaydedildi'), findsOneWidget);

      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await say(tester, 'faturayı yatır');
      expect(find.text('Yeni not olarak kaydediliyor…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repo.created.last, (NoteType.text, 'faturayı yatır'));
    });

    // H11 2. yarı (2026-11-19): not varken de "Yeni not" çipi HEP en başta.
    testWidgets('"Yeni not" çipi en başta; seçilince yazılan yeni not olur', (
      tester,
    ) async {
      final repo = await openSheet(tester, [shopping, todo, text]);
      final strip = find.byKey(const ValueKey('quick-drop-targets'));
      final chips = tester
          .widgetList<ChoiceChip>(
            find.descendant(of: strip, matching: find.byType(ChoiceChip)),
          )
          .toList();
      expect(chips.first.key, const ValueKey('quick-drop-target-new'));
      expect(chips.first.selected, isFalse);
      await tester.tap(find.byKey(const ValueKey('quick-drop-target-new')));
      await tester.pumpAndSettle();
      await say(tester, 'kargoyu sor');
      expect(find.text('Yeni not olarak kaydediliyor…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repo.created, [(NoteType.text, 'kargoyu sor')]);
      expect(repo.writes, isEmpty, reason: 'var olan nota eklenmez');
    });

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
      await tapTarget(tester, 'c');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
      await tester.pumpAndSettle();
      expect(repo.writes.keys, ['c']);
    });

    // DA-1 (plan_decisions_api): bayrak açıkken hedefi Decisions seçer.
    DecisionService fakeDecisions(Map<String, Object> answers) =>
        DecisionService(
          key: () async => 'k',
          http: JsonHttp(
            baseUrl: AiProvider.gemini.baseUrl,
            client: MockClient(
              (_) async => http.Response(
                jsonEncode({'answers': answers}),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
            ),
          ),
        );

    Map<String, Object> target(String choice, double confidence) => {
      'hedef': {'type': 'choice', 'choice': choice, 'confidence': confidence},
    };

    Future<_DropRepo> openWithDecisions(
      WidgetTester tester,
      Map<String, Object> answers, {
      String feature = DecisionFeature.dropTarget,
    }) async {
      AiDecisionsFlag.apply({
        'aiDecisionsFeatures': [feature],
      });
      addTearDown(AiDecisionsFlag.debugReset);
      final repo = _DropRepo();
      await pumpHost(
        tester,
        notes: [shopping, todo, text],
        repo: repo,
        prefs: {'quick_drop_mic': false},
        ai: AiAvailability.ready,
        extra: [
          decisionServiceProvider.overrideWithValue(fakeDecisions(answers)),
        ],
        onTap: (context, ref) => showQuickDropSheet(context),
      );
      await tester.pump();
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('DA-1: Decisions emin → geri sayımla o nota, ad içerikte yok', (
      tester,
    ) async {
      // Aday sırası: Yapılacaklar (n00), Fikirler (n01), Alışveriş (n02).
      final repo = await openWithDecisions(tester, target('n01', 0.93));
      await say(tester, 'yeni logo taslağı fikir defterine ekle');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('quick-drop-counting')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(repo.writes.keys, ['c']);
      expect(repo.writes['c']!['body'], 'ilk satır\nyeni logo taslağı');
    });

    testWidgets('DA-1: Decisions orta güven → seçili gelir ama sorulur', (
      tester,
    ) async {
      final repo = await openWithDecisions(tester, target('n01', 0.6));
      await say(tester, 'yeni logo taslağı fikir defterine ekle');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('quick-drop-ask')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(repo.writes, isEmpty);
    });

    // HE-2 (17K §4.2): yapay zekâ beklerken ilk 300 ms hiçbir şey yanıp
    // sönmez; sonra ince ilerleme + "Ben seçeyim" — dokununca beklemeden
    // kullanıcı seçer, geç gelen yanıt eklemez.
    testWidgets('HE-2: yapay zekâ beklerken 300 ms sonra "Ben seçeyim"', (
      tester,
    ) async {
      AiDecisionsFlag.apply({
        'aiDecisionsFeatures': [DecisionFeature.dropTarget],
      });
      addTearDown(AiDecisionsFlag.debugReset);
      final repo = _DropRepo();
      await pumpHost(
        tester,
        notes: [shopping, todo, text],
        repo: repo,
        prefs: {'quick_drop_mic': false},
        ai: AiAvailability.ready,
        extra: [
          decisionServiceProvider.overrideWithValue(
            DecisionService(
              key: () async => 'k',
              http: JsonHttp(
                baseUrl: AiProvider.gemini.baseUrl,
                client: MockClient((_) async {
                  await Future<void>.delayed(const Duration(seconds: 1));
                  return http.Response(
                    jsonEncode({'answers': target('n01', 0.93)}),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8',
                    },
                  );
                }),
              ),
            ),
          ),
        ],
        onTap: (context, ref) => showQuickDropSheet(context),
      );
      await tester.pump();
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await say(tester, 'yeni logo taslağı fikir defterine ekle');
      final waiting = find.byKey(const ValueKey('quick-drop-thinking'));
      double opacity() => tester
          .widget<AnimatedOpacity>(
            find
                .ancestor(of: waiting, matching: find.byType(AnimatedOpacity))
                .first,
          )
          .opacity;
      expect(opacity(), 0, reason: 'ilk 300 ms görünmez');
      await tester.pump(const Duration(milliseconds: 350));
      expect(opacity(), 1);
      await tester.tap(find.byKey(const ValueKey('quick-drop-pick-myself')));
      await tester.pump();
      expect(find.byKey(const ValueKey('quick-drop-ask')), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(repo.writes, isEmpty, reason: 'geç gelen yanıt eklemez');
    });

    // DA-14: bulanık düzeltme geri sayım içinde doğrulanır.
    test(
      'quickDropFixes yalnız bulanık düzeltmeyi verir; veto bu eklemede',
      () {
        final fixes = quickDropFixes(shopping, 'yunurta süt', locale: 'tr');
        expect(fixes, [(typed: 'yunurta', fixed: 'Yumurta')]);
        expect(quickDropFixes(text, 'yunurta', locale: 'tr'), isEmpty);
        final r = quickDropFields(
          shopping,
          'yunurta',
          locale: 'tr',
          memory: quickDropVetoed(const QuickEntryMemory(), fixes),
          newId: () => 'y',
        );
        final items = (r.fields['items'] as List).cast<Map<String, dynamic>>();
        expect(items.last['text'], isNot('Yumurta'));
        expect(quickAscii(items.last['text'] as String), 'yunurta');
      },
    );

    for (final (p, kept) in [(0.1, false), (0.95, true)]) {
      testWidgets(
        'DA-14: Decisions noul=$p → düzeltme ${kept ? 'kalır' : 'geri alınır'}',
        (tester) async {
          final repo = await openWithDecisions(tester, {
            'd00': {'type': 'noul', 'noul': p},
          }, feature: DecisionFeature.spellFixOk);
          await say(tester, 'alışveriş listesine yunurta ekle');
          expect(
            find.byKey(const ValueKey('quick-drop-counting')),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          final items = repo.writes['a']!['items'] as List;
          final last = (items.last as Map)['text'] as String;
          expect(last == 'Yumurta', kept);
        },
      );
    }

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
      await tapTarget(tester, 'pb');
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
