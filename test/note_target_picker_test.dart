import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_target_picker.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final notes = [
    Note(id: 'a', type: NoteType.text, title: 'Birinci', body: 'metin'),
    Note(id: 'b', type: NoteType.text, title: 'İkinci', body: 'başka'),
    Note(id: 'k', type: NoteType.text, title: 'Gizli', locked: true),
  ];

  Future<NoteTarget?> run(
    WidgetTester tester,
    Finder tap, {
    VoidCallback? pressed,
  }) async {
    NoteTarget? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showNoteTargetPicker(context, preview: 'x'),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    if (pressed != null) {
      final g = await tester.startGesture(tester.getCenter(tap));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      pressed();
      await g.up();
    } else {
      await tester.tap(tap);
    }
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('yeni not kartı yeni not hedefi döner', (tester) async {
    final r = await run(tester, find.byKey(const ValueKey('target-new-note')));
    expect(r, isNotNull);
    expect(r!.note, isNull);
  });

  testWidgets('küçük kart o notu seçer; kilitli not listelenmez', (
    tester,
  ) async {
    final r = await run(tester, find.byKey(const ValueKey('target-b')));
    expect(r?.note?.id, 'b');
    expect(find.byKey(const ValueKey('target-k')), findsNothing);
  });

  // DENEYIM F78.4: hücre basılıyken çöker (önce: görünür basma tepkisi yoktu).
  testWidgets('küçük kart basılıyken küçülür, bırakınca seçer', (tester) async {
    final cell = find.byKey(const ValueKey('target-b'));
    double scale() => tester
        .widget<AnimatedScale>(
          find.descendant(of: cell, matching: find.byType(AnimatedScale)).first,
        )
        .scale;
    final r = await run(
      tester,
      cell,
      pressed: () => expect(scale(), lessThan(1)),
    );
    expect(r?.note?.id, 'b');
  });
}
