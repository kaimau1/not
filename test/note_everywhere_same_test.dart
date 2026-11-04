import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/note_colors.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/note_pdf.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/l10n/generated/app_localizations_tr.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **NOT HER YERDE AYNI** (TUTARLILIK Faz 37): her tema ailesi × not rengi ×
/// {kart, editör, liste satırı}. Kutucuk, etiket, raptiye aynı renkte; başlık
/// aynı aile, ağırlık ve aralıkta. PDF aynı kuraldan.
const _items = [
  NoteItem(id: 'a', text: 'açık madde'),
  NoteItem(id: 'b', text: 'bitmiş madde', checked: true),
];

Note _note({int? customColor, NoteColor color = NoteColor.none}) => Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Başlık',
  items: _items,
  tags: const ['yazilim'],
  pinned: true,
  customColor: customColor,
  color: color,
);

final _variants = <String, Note>{
  'renksiz': _note(),
  'hazır': _note(color: NoteColor.sage),
  'koyu özel': _note(customColor: 0xFF1A0B1F),
  'açık özel': _note(customColor: 0xFFFFE0B2),
};

Future<void> _pump(WidgetTester tester, ThemeData theme, Widget home) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final note = home is _Probe ? home.note : _note();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      noteStreamProvider('n').overrideWith((ref) => Stream.value(note)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// Pompalanan ekran + notu.
class _Probe extends StatelessWidget {
  const _Probe(this.note, this.child);

  final Note note;
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

Widget _card(Note note) => _Probe(
  note,
  Scaffold(
    body: Center(
      child: SizedBox(width: 300, child: NoteCard(note: note)),
    ),
  ),
);

Widget _row(Note note) => _Probe(
  note,
  Scaffold(
    body: Center(
      child: SizedBox(
        width: 400,
        child: NoteListRow(note: note, selected: false, selectionActive: false),
      ),
    ),
  ),
);

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

Color _pin(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.push_pin).first).color!;

Color _tag(WidgetTester tester) =>
    tester.widget<Text>(find.text('#yazilim').first).style!.color!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('tr'));

  for (final family in ThemeFamily.values) {
    for (final brightness in Brightness.values) {
      final theme = AppTheme.of(family, brightness);
      _variants.forEach((name, note) {
        testWidgets('${family.name}/${brightness.name}/$name', (tester) async {
          await _pump(tester, theme, _card(note));
          final cardPin = _pin(tester);
          final cardTag = _tag(tester);
          final cardChecked = tester
              .widget<Icon>(find.byIcon(Icons.check_box).first)
              .color!;
          final cardUnchecked = tester
              .widget<Icon>(find.byIcon(Icons.check_box_outline_blank).first)
              .color!;
          final cardTitle = tester
              .widget<Text>(
                find.byWidgetPredicate(
                  (w) =>
                      w is Text &&
                      (w.textSpan?.toPlainText().contains('Başlık') ?? false),
                ),
              )
              .textSpan!
              .style!;

          await _pump(tester, theme, _row(note));
          expect(_pin(tester), cardPin, reason: 'satır raptiyesi');
          expect(_tag(tester), cardTag, reason: 'satır etiketi');
          // Satırın tür simgesi boş kutunun çerçevesiyle aynı tonda.
          expect(
            tester.widget<Icon>(find.byIcon(Icons.checklist)).color,
            cardUnchecked,
            reason: 'satır simgesi',
          );
          // Satır zemini notun zemini.
          final row = tester.widget<Material>(
            find
                .descendant(
                  of: find.byType(NoteListRow),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(row.color, NoteColors.noteSurfaceIn(theme, note));
          final rowTitle = tester.widget<Text>(find.text('Başlık')).style!;

          await _pump(
            tester,
            theme,
            _Probe(note, const NoteEditorScreen(noteId: 'n')),
          );
          final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
          final checked = checkboxes.firstWhere((c) => c.value ?? false);
          expect(
            checked.fillColor!.resolve({WidgetState.selected}),
            cardChecked,
            reason: 'editör kutucuğu',
          );
          expect(_pin(tester), cardPin, reason: 'editör raptiyesi');
          final chip = tester.widget<InputChip>(
            find.widgetWithText(InputChip, '#yazilim'),
          );
          expect(chip.labelStyle?.color, cardTag, reason: 'editör etiketi');

          // Başlık: aynı aile, ağırlık, aralık (K9).
          final editorTitle = tester
              .widgetList<EditableText>(find.byType(EditableText))
              .firstWhere((e) => e.controller.text == 'Başlık')
              .style;
          for (final s in [cardTitle, rowTitle]) {
            expect(s.fontFamily, editorTitle.fontFamily);
            expect(s.fontWeight, editorTitle.fontWeight);
            expect(s.letterSpacing, editorTitle.letterSpacing);
          }
          await _end(tester);
        });
      });
    }
  }

  group('yakın hatırlatıcı', () {
    final l10n = AppLocalizationsTr();
    final now = DateTime(2026, 11, 5, 10);
    setUp(() => Intl.defaultLocale = 'tr');

    test('48 saat içi saatli, dışı ve geçmiş yok', () {
      expect(
        cardReminderLabel(l10n, DateTime(2026, 11, 5, 15, 17), now),
        'bugün 15:17',
      );
      expect(
        cardReminderLabel(l10n, DateTime(2026, 11, 6, 15, 17), now),
        'yarın 15:17',
      );
      // Ertesi günden sonraki gün ama 48 saatin içinde: gün adı.
      expect(
        cardReminderLabel(l10n, DateTime(2026, 11, 7, 9, 30), now),
        endsWith(' 09:30'),
      );
      expect(
        cardReminderLabel(l10n, DateTime(2026, 11, 7, 10, 1), now),
        isNull,
      );
      expect(cardReminderLabel(l10n, DateTime(2026, 11, 5, 9), now), isNull);
    });

    testWidgets('yer varken kesilmez', (tester) async {
      final note = _note().copyWith(
        tags: const [],
        reminderAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await _pump(
        tester,
        AppTheme.of(ThemeFamily.sage, Brightness.light),
        _card(note),
      );
      final label = tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.textContaining(RegExp(r'(bugün|yarın) \d\d:\d\d')),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(label.didExceedMaxLines, isFalse);
      await _end(tester);
    });

    testWidgets('kartta ve satırda görünür, dar kartta taşmaz', (tester) async {
      final note = _note().copyWith(
        reminderAt: DateTime.now().add(const Duration(hours: 1)),
      );
      await _pump(
        tester,
        AppTheme.of(ThemeFamily.sage, Brightness.light),
        _Probe(
          note,
          Scaffold(
            body: Center(
              child: SizedBox(width: 120, child: NoteCard(note: note)),
            ),
          ),
        ),
      );
      expect(find.textContaining(RegExp(r'(bugün|yarın) \d\d:\d\d')), findsOne);
      expect(tester.takeException(), isNull);
      await _pump(
        tester,
        AppTheme.of(ThemeFamily.sage, Brightness.light),
        _row(note),
      );
      expect(find.textContaining(RegExp(r'(bugün|yarın) \d\d:\d\d')), findsOne);
      await _end(tester);
    });
  });

  group('PDF notun rengini ve kutucuğunu aynı kuraldan alır', () {
    final theme = AppTheme.of(ThemeFamily.sage, Brightness.light);

    test('renksiz: sayfa boyanmaz, kutucuk temanın vurgusu', () {
      final s = PdfNoteStyle.forNote(theme, _note());
      expect(s.page, isNull);
      expect(s.ink, 0xFF000000);
      expect(
        s.checkFill,
        Color.alphaBlend(
          NoteCheckColors.checked(theme.colorScheme, null),
          const Color(0xFFFFFFFF),
        ).toARGB32(),
      );
    });

    test('hazır renk: sayfa notun zemini, kutucuk notun tonu', () {
      final note = _note(color: NoteColor.sage);
      final s = PdfNoteStyle.forNote(theme, note);
      final surface = NoteColors.noteSurfaceIn(theme, note);
      final accent = NoteColors.noteInkIn(theme, note)!;
      expect(s.page, surface.toARGB32());
      expect(s.checkBorder, accent.toARGB32());
      expect(s.checkMark, surface.toARGB32());
    });

    test('koyu özel renk: zıt mürekkep, yazı okunur', () {
      final s = PdfNoteStyle.forNote(theme, _note(customColor: 0xFF1A0B1F));
      expect(
        NoteColors.contrast(Color(s.ink), Color(s.page!)),
        greaterThanOrEqualTo(NoteColors.minTextContrast),
      );
    });

    test('koyu temada da belge açık hâlden hesaplanır', () {
      final dark = AppTheme.of(ThemeFamily.sage, Brightness.dark);
      final note = _note(color: NoteColor.sage);
      expect(
        PdfNoteStyle.forNote(dark, note).page,
        PdfNoteStyle.forNote(theme, note).page,
      );
    });

    test('boyalı ve renkli PDF üretilir', () async {
      final note = _note(customColor: 0xFF1A0B1F);
      Future<int> build(PdfNoteStyle style) async => (await NotePdf.build(
        title: 'Başlık',
        content: '[x] bitti\n[ ] açık\n%%1:renkli%%',
        palette: NoteColors.richPalette,
        style: style,
      )).length;
      final plain = await build(const PdfNoteStyle());
      final painted = await build(PdfNoteStyle.forNote(theme, note));
      expect(plain, greaterThan(10000));
      // Sayfa dolgusu dosyaya gerçekten yazıldı.
      expect(painted, isNot(plain));
    });
  });
}
