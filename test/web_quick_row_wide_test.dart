import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı bulgusu 2026-11-27 ("webte üst hızlı menü yok"): geniş web
/// bölmesinde `titleSpacing` (okuma payı) başlığın iki yanına sayılıyor,
/// başlığa 0 dp kalıyordu — hızlı satırda yalnız ⋯ görünüyor, ⋯ tarihin
/// üstüne biniyordu.
final _noteDated = Note(
  id: 'n',
  type: NoteType.text,
  title: 'TEST',
  body: 'yazı',
  updatedAt: DateTime(2020, 1, 2, 14, 35),
);
const _note = Note(id: 'n', type: NoteType.text, title: 'TEST', body: 'yazı');

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Note note = _note,
  Size size = const Size(1200, 800),
  bool startDrawing = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    // Firebase'siz sağlayıcılar yeniden denemesin (bekleyen zamanlayıcı).
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
        // Uygulamadaki gibi bildirim şeridi (ipuçları şeritte çıkar).
        builder: (context, child) => AppNoticeHost(child: child!),
        home: NoteEditorScreen(noteId: 'n', startDrawing: startDrawing),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

void main() {
  for (final width in [1800.0, 1200.0, 800.0]) {
    testWidgets('geniş web: hızlı satır düğmeleri görünür, ⋯ tarihe binmez '
        '(${width.toInt()} dp)', (tester) async {
      debugWideWebQuickRow = true;
      addTearDown(() => debugWideWebQuickRow = false);
      await _pump(tester, note: _noteDated, size: Size(width, 900));
      for (final k in ['pen', 'spell', 'bold']) {
        expect(
          find.byKey(ValueKey('quick-row-$k')),
          findsOneWidget,
          reason: '$k satırda',
        );
      }
      final more = tester.getRect(find.byKey(const ValueKey('quick-row-more')));
      final date = tester.getRect(find.textContaining('2020'));
      expect(more.left, greaterThanOrEqualTo(date.right));
      final title = tester.getRect(find.byType(NavigationToolbar));
      expect(more.right, lessThanOrEqualTo(title.right));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    });
  }
}
