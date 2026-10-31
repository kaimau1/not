import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/reminders_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 11 — ana ekran sadeleşmesi: varsayılan sıralama, Süz levhasının yeni
/// düzeni, boş hatırlatıcılarda tek düğme.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app(Widget home, {List<Note> notes = const []}) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
      foldersStreamProvider.overrideWith(
        (ref) => Stream.value(const <NoteFolder>[]),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  group('F11.4 varsayılan sıralama', () {
    test('kayıt yokken "Son güncellenen"; kayıtlı "Elle" korunur', () async {
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      expect(c.read(noteSortProvider), NoteSort.updated);

      SharedPreferences.setMockInitialValues({'note_sort': 'manual'});
      final stored = await SharedPreferences.getInstance();
      final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(stored)],
      );
      addTearDown(c2.dispose);
      expect(c2.read(noteSortProvider), NoteSort.manual);
    });

    test('yalnız sürüklemeyle sıra almış not "Elle"yi korur', () {
      const fresh = Note(id: 'a', type: NoteType.text, orderIndex: -1e12);
      const legacy = Note(id: 'b', type: NoteType.text);
      const dragged = Note(id: 'c', type: NoteType.text, orderIndex: 2000);
      expect(shouldKeepManualSort([fresh, legacy]), isFalse);
      expect(shouldKeepManualSort([fresh, dragged]), isTrue);
    });
  });

  testWidgets('F11.4 Süz: Tür ve Durum ayrı, görünüm segmentli, Elle sırala '
      'metinli', (tester) async {
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFilterSheet(context),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('filter-view-mode')), findsOneWidget);
    expect(find.byType(Switch), findsWidgets);
    expect(find.text('Tür'), findsOneWidget);
    expect(find.text('Durum'), findsOneWidget);
    // "Metin" Tür'de, "Sabitlenmiş" Durum'da: Tür bölümü Durum'un üstünde.
    final typeTop = tester.getTopLeft(find.text('Tür')).dy;
    final statusTop = tester.getTopLeft(find.text('Durum')).dy;
    final textY = tester.getCenter(find.text('Metin')).dy;
    expect(textY, greaterThan(typeTop));
    expect(textY, lessThan(statusTop));
    expect(find.text('Klasörsüz ve etiketsiz'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Elle sırala'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    expect(find.text('Elle sırala'), findsOneWidget);
  });

  testWidgets('F11.7 hatırlatıcı yokken yüzen düğme yok', (tester) async {
    await tester.pumpWidget(app(const RemindersScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Yeni hatırlatıcı'), findsOneWidget);
  });

  testWidgets('F11.7 hatırlatıcı varken yüzen düğme var', (tester) async {
    await tester.pumpWidget(
      app(
        const RemindersScreen(),
        notes: [
          Note(
            id: 'r',
            type: NoteType.text,
            title: 'Toplantı',
            reminderAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
