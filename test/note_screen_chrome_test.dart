import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Not ekranının kabuğu (TUTARLILIK Faz 38): üst çubuk, "+", işaretli blok,
/// klavye turu.
Future<void> _pump(WidgetTester tester, Note note) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 30, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 48);
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
        theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const NoteEditorScreen(noteId: 'n'),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

const _list = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Başlık',
  items: [
    NoteItem(id: 'a', text: 'açık'),
    NoteItem(id: 'b', text: 'bitti bir', checked: true),
    NoteItem(id: 'c', text: 'bitti iki', checked: true),
  ],
);

final _dated = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Başlık',
  updatedAt: DateTime(2026, 11, 5),
);

void main() {
  testWidgets('üst çubuk sade: düzenleme yokken geri al/yinele/palet yok', (
    tester,
  ) async {
    // Kullanıcı isteği 2026-11-05 "üst alanda sadeleşme": açılışta çubukta
    // yalnız tarih · senkron · sabitle · ⋮ (palet ⋮ menüsünde).
    await _pump(tester, _dated);
    Finder inBar(IconData icon) =>
        find.descendant(of: find.byType(AppBar), matching: find.byIcon(icon));
    expect(inBar(Icons.undo), findsNothing);
    expect(inBar(Icons.redo), findsNothing);
    expect(inBar(Icons.palette_outlined), findsNothing);
    expect(
      tester.getCenter(inBar(Icons.push_pin_outlined)).dx,
      lessThan(tester.getCenter(inBar(Icons.more_vert)).dx),
    );
    await _end(tester);
  });

  test('üst çubuk tarihi kısa', () {
    final now = DateTime(2026, 11, 5, 15);
    expect(editorBarDate(DateTime(2026, 11, 5, 13, 7), now), '13:07');
    expect(editorBarDate(DateTime(2026, 3, 2, 9, 5), now), contains('09:05'));
    expect(editorBarDate(DateTime(2025, 3, 2, 9, 5), now), contains('2025'));
    expect(
      editorBarDate(DateTime(2025, 3, 2, 9, 5), now),
      isNot(contains('09:05')),
    );
  });

  testWidgets('geri yokken tarih kenara yapışmaz (F38.2)', (tester) async {
    await _pump(tester, _dated);
    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.titleSpacing, 16);
    await _end(tester);
  });

  testWidgets('başlıkta tek "+": levha açar, başlık alanı genişler (F38.3)', (
    tester,
  ) async {
    await _pump(tester, _list);
    final plus = find.byKey(const ValueKey('note-meta-chip'));
    expect(tester.widget(plus), isA<IconButton>());
    expect(tester.getSize(plus).width, lessThanOrEqualTo(48));
    await tester.tap(plus);
    await tester.pumpAndSettle();
    for (final id in ['add-tag', 'reminder', 'folder']) {
      expect(
        find.byKey(ValueKey('menu-quick-$id')),
        findsOneWidget,
        reason: id,
      );
    }
    expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
    await _end(tester);
  });

  testWidgets('işaretlileri sil bloğun başında (F38.4)', (tester) async {
    await _pump(tester, _list);
    expect(find.text('İşaretliler (2)'), findsOneWidget);
    final delete = tester.getTopLeft(
      find.byKey(const ValueKey('items-delete-checked')),
    );
    final firstChecked = tester.getTopLeft(find.text('bitti bir'));
    expect(delete.dy, lessThan(firstChecked.dy));
    await _end(tester);
  });

  testWidgets('klavye turları birikmez, editör gövdesi kurulmaz (F38.7)', (
    tester,
  ) async {
    await _pump(
      tester,
      _list.copyWith(body: List.generate(30, (i) => 'Satır $i').join('\n')),
    );
    final counts = <String, int>{};
    debugOnRebuildDirtyWidget = (e, _) {
      final name = e.widget.runtimeType.toString();
      counts[name] = (counts[name] ?? 0) + 1;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    Future<void> frame(double inset) async {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      tester.view.padding = FakeViewPadding(
        top: 30,
        bottom: (48 - inset).clamp(0.0, 48.0),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    Future<Map<String, int>> cycle() async {
      counts.clear();
      for (final i in [20.0, 60.0, 120.0, 200.0, 300.0]) {
        await frame(i);
      }
      // Hareket sırasında gövde kurulmaz (oturma kurulumu aşağıda, ayrı).
      final moving = Map<String, int>.of(counts);
      await tester.pump(const Duration(milliseconds: 300));
      for (final i in [200.0, 120.0, 60.0, 20.0, 0.0]) {
        await frame(i);
      }
      await tester.pump(const Duration(milliseconds: 300));
      return moving;
    }

    final first = await cycle();
    expect(first, isNot(contains('NoteEditorScreen')));
    expect(first, isNot(contains('EditableText')));
    expect(first, isNot(contains('ItemsEditor')));
    // Kullanıcı bildirimi: "her açılışta artarak". 20. tur 1. turla aynı.
    await cycle();
    final baseline = await cycle();
    for (var i = 0; i < 17; i++) {
      final later = await cycle();
      expect(later, baseline, reason: 'tur ${i + 4}');
    }
    expect(tester.binding.transientCallbackCount, 0);
    await _end(tester);
  });

  testWidgets('klavye açıkken üstte hızlı işlev satırı, kapanınca tarih', (
    tester,
  ) async {
    await _pump(tester, _dated);
    expect(find.byKey(const ValueKey('editor-quick-row')), findsNothing);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('editor-quick-row')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-bold')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-pen')), findsOneWidget);
    // Yazarken üst çubuk: hızlı satır + geri al/yinele + en sağda ⋮
    // (kullanıcı isteği 2026-11-08: "3 nokta geri gelsin").
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-spell')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-row-customize')), findsOneWidget);
    // Sonradan eklenen düğme varsayılan gizli.
    expect(find.byKey(const ValueKey('quick-row-italic')), findsNothing);
    expect(find.byIcon(Icons.undo), findsOneWidget);
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.byKey(const ValueKey('editor-quick-row')), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsWidgets);
    await _end(tester);
  });
}
