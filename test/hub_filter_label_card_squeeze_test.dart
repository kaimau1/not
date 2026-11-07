import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı bulguları 2026-11-07: (1) Gelen açıkken Süz düğmesinde klasör
/// adı yoktu (başka klasörlerde var); (2) 3–4 sütunda kart sıkışıyordu.
void main() {
  testWidgets('Gelen açıkken Süz düğmesi "Gelen" yazar; × kapatır', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notesStreamProvider.overrideWith((ref) => Stream.value(const <Note>[])),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value(const <NoteFolder>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: Center(child: HomeFilterButton())),
        ),
      ),
    );
    expect(find.text('Gelen'), findsNothing);
    container.read(sharedHubOnHomeProvider.notifier).set(true);
    await tester.pumpAndSettle();
    expect(find.text('Gelen'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('home-filter-clear')));
    await tester.pumpAndSettle();
    expect(container.read(sharedHubOnHomeProvider), isFalse);
    expect(find.text('Gelen'), findsNothing);
  });

  test('kart sıkışma eşikleri: 2 sütun normal, 3 dar, 4 çok dar', () {
    expect(noteCardSqueezeFor(null), 0);
    expect(noteCardSqueezeFor(196), 0); // telefon 2 sütun
    expect(noteCardSqueezeFor(128), 1); // 3 sütun
    expect(noteCardSqueezeFor(94), 2); // 4 sütun
  });
}
