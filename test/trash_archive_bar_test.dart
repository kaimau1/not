import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_screen.dart';
import 'package:notlar/features/notes/presentation/trash_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F79.4 (DENEYIM D19): Çöp ve Arşiv üst çubuğu "Ara + ⋮"; toplu işler
/// ⋮'te, "Çöpü boşalt" `error` renginde en altta. Çöp kartının altında iki
/// ETİKETLİ düğme: "Geri al" · "Sil" (`error`).
void main() {
  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final deleted = DateTime.now().subtract(const Duration(days: 10));
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        trashStreamProvider.overrideWith(
          (ref) => Stream.value([
            Note(
              id: 't',
              type: NoteType.text,
              title: 'Silinen not',
              deletedAt: deleted,
            ),
          ]),
        ),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            Note(
              id: 'a',
              type: NoteType.text,
              title: 'Arşivdeki not',
              archivedAt: deleted,
            ),
          ]),
        ),
        foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('çöp: Ara + ⋮, kartta etiketli Geri al · Sil', (tester) async {
    await pump(tester, const TrashScreen());
    // Toplu işler artık üst çubukta simge değil.
    expect(find.byTooltip('Çöpü boşalt'), findsNothing);
    expect(find.byTooltip('Hepsini geri yükle'), findsNothing);
    expect(find.byTooltip('Akıllı analiz'), findsNothing);

    final restore = find.widgetWithText(TextButton, 'Geri al');
    final delete = find.widgetWithText(TextButton, 'Sil');
    expect(restore, findsOneWidget);
    expect(delete, findsOneWidget);
    final scheme = Theme.of(tester.element(delete)).colorScheme;
    final deleteStyle = tester.widget<TextButton>(delete).style!;
    expect(deleteStyle.foregroundColor!.resolve({}), scheme.error);
    expect(tester.getSize(delete).width, greaterThanOrEqualTo(48));

    await tester.tap(find.byKey(const ValueKey('trash-more')));
    await tester.pumpAndSettle();
    expect(find.text('Akıllı analiz'), findsOneWidget);
    expect(find.text('Hepsini geri yükle'), findsOneWidget);
    final empty = tester.widget<Text>(find.text('Çöpü boşalt'));
    expect(empty.style?.color, scheme.error);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arşiv: Ara + ⋮ (özet + sıralama)', (tester) async {
    await pump(tester, const ArchiveScreen());
    expect(find.byTooltip('Arşivimde neler var?'), findsNothing);
    expect(find.byTooltip('Sıralama'), findsNothing);
    await tester.tap(find.byTooltip('Diğer'));
    await tester.pumpAndSettle();
    expect(find.text('Arşivimde neler var?'), findsOneWidget);
    expect(find.text('Sıralama'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
