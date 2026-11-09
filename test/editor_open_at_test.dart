import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/in_note_find.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F56.1 (aramadan açılan not kelimeye gider) ve "zamanı gelenler"
/// şeridinden satır görevine gidiş (2026-11-09).
void main() {
  final note = Note(
    id: 'n',
    type: NoteType.checklist,
    title: 'Liste',
    items: [
      for (var i = 0; i < 60; i++)
        NoteItem(id: 'i$i', text: i == 55 ? 'zeytinyağı al' : 'madde $i'),
    ],
  );

  Future<void> open(WidgetTester tester, NoteEditorScreen screen) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  double scrolled(WidgetTester tester) => tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where((s) => s.position.axis == Axis.vertical)
      .map((s) => s.position.pixels)
      .fold(0.0, (a, b) => a > b ? a : b);

  testWidgets('?find= : arama çubuğu açık, kelimeye kaydırılmış, klavye yok', (
    tester,
  ) async {
    await open(
      tester,
      const NoteEditorScreen(noteId: 'n', initialFind: 'zeytinyağı'),
    );
    expect(find.byType(NoteFindBar), findsOneWidget);
    expect(scrolled(tester), greaterThan(100));
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<EditableText>()),
      reason: 'klavye açılmamalı',
    );
    await close(tester);
  });

  testWidgets('?find= eşleşmesizse arama çubuğu kapanır', (tester) async {
    await open(tester, const NoteEditorScreen(noteId: 'n', initialFind: 'qqq'));
    expect(find.byType(NoteFindBar), findsNothing);
    await close(tester);
  });

  testWidgets('?item= : o maddeye kaydırılır', (tester) async {
    await open(
      tester,
      const NoteEditorScreen(noteId: 'n', revealItemId: 'i55'),
    );
    expect(scrolled(tester), greaterThan(100));
    await close(tester);
  });
}
