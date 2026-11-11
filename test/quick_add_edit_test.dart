import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/menu_layout.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/quick_add_actions.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F60.S10 — "Not ekle" ("+") menüsü düzenlenebilir: menüdeki "Düzenle" →
/// her öğede göz (gizle/göster) + tutamaçla sıralama, "Bitti",
/// "Varsayılana dön". Son görünür öğe gizlenemez.
void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    Personalize.debugReset();
    MenuLayouts.reset();
    Personalize.attach(prefs);
    MenuLayouts.attach(prefs);
  });
  tearDown(() {
    Personalize.debugReset();
    MenuLayouts.reset();
  });

  Widget host() => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _FabHost(),
    ),
  );

  Future<void> openPanel(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton).first);
    await tester.pumpAndSettle();
  }

  Future<void> openEditor(WidgetTester tester) async {
    await openPanel(tester);
    await tester.tap(find.byKey(const ValueKey('quick-add-edit')));
    await tester.pumpAndSettle();
  }

  Future<void> done(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('quick-edit-done')));
    await tester.pumpAndSettle();
  }

  Finder eye(String key) => find.byKey(ValueKey('quick-edit-eye-$key'));
  Finder tile(String key) => find.byKey(ValueKey('quick-add-$key'));

  testWidgets('gizle → normal kipte yok; tekrar göster → geri gelir', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await openEditor(tester);
    // Düzen kipinde öğeler karo değil, satır: karolar yok.
    expect(tile('youtube'), findsNothing);
    await tester.ensureVisible(eye('youtube'));
    await tester.tap(eye('youtube'));
    await tester.pumpAndSettle();
    await done(tester);

    expect(find.text('Metin notu'), findsOneWidget, reason: 'panel açık kalır');
    expect(tile('youtube'), findsNothing);
    expect(tile('file'), findsOneWidget);
    expect(
      Personalize.prefs.value.shows(UiItem.quickAdd('youtube')),
      isFalse,
      reason: 'kalıcı (Personalize kaydı)',
    );

    await tester.tap(find.byKey(const ValueKey('quick-add-edit')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(eye('youtube'));
    await tester.tap(eye('youtube'));
    await tester.pumpAndSettle();
    await done(tester);
    expect(tile('youtube'), findsOneWidget);
  });

  testWidgets('sırala → normal kipte sıra uygulanır ve kalıcı', (tester) async {
    await tester.pumpWidget(host());
    await openEditor(tester);
    final handle = find.byKey(const ValueKey('quick-edit-handle-ordered'));
    await tester.ensureVisible(handle);
    await tester.pumpAndSettle();
    final text = tester.getCenter(
      find.byKey(const ValueKey('quick-edit-row-text')),
    );
    final from = tester.getCenter(handle);
    final gesture = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 100));
    final dy = (text.dy - from.dy) - 20;
    for (var i = 1; i <= 10; i++) {
      await gesture.moveBy(Offset(0, dy / 10));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    await done(tester);

    final ordered = tester.getCenter(tile('ordered'));
    final textNote = tester.getCenter(tile('text'));
    expect(
      ordered.dx,
      lessThan(textNote.dx),
      reason: 'Sıralı liste başa geçti',
    );

    // Kalıcı: kayıttan yeniden okununca da aynı sıra.
    MenuLayouts.reset();
    MenuLayouts.attach(prefs);
    expect(
      MenuLayouts.of(quickAddMenuId)
          .sorted(['text', 'checklist', 'ordered'], (id) => id),
      ['ordered', 'text', 'checklist'],
    );
  });

  testWidgets('varsayılana dön: gizliler görünür, sıra varsayılan', (
    tester,
  ) async {
    Personalize.update((p) => p.withVisible(UiItem.quickAdd('youtube'), false));
    MenuLayouts.set(
      quickAddMenuId,
      const MenuLayout(order: ['ordered', 'checklist', 'text']),
    );
    await tester.pumpWidget(host());
    await openPanel(tester);
    expect(tile('youtube'), findsNothing);
    expect(
      tester.getCenter(tile('ordered')).dx,
      lessThan(tester.getCenter(tile('text')).dx),
    );

    await tester.tap(find.byKey(const ValueKey('quick-add-edit')));
    await tester.pumpAndSettle();
    final reset = find.byKey(const ValueKey('quick-edit-reset'));
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await done(tester);

    expect(tile('youtube'), findsOneWidget);
    expect(
      tester.getCenter(tile('text')).dx,
      lessThan(tester.getCenter(tile('checklist')).dx),
    );
    expect(
      tester.getCenter(tile('checklist')).dx,
      lessThan(tester.getCenter(tile('ordered')).dx),
    );
    expect(MenuLayouts.of(quickAddMenuId).isDefault, isTrue);
    expect(
      Personalize.prefs.value.hidden.where((h) => h.startsWith('quickadd.')),
      isEmpty,
    );
  });

  testWidgets('son görünür öğe gizlenemez', (tester) async {
    await tester.pumpWidget(host());
    await openEditor(tester);
    // Metin notu dışında hepsini gizle.
    final keys = <String>[
      for (final w in tester.widgetList(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('quick-edit-eye-'),
        ),
      ))
        (w.key! as ValueKey<String>).value.substring('quick-edit-eye-'.length),
    ];
    expect(keys, containsAll(['text', 'checklist', 'youtube']));
    for (final k in keys) {
      if (k == 'text') continue;
      await tester.ensureVisible(eye(k));
      await tester.tap(eye(k));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(eye('text'));
    final button = tester.widget<IconButton>(eye('text'));
    expect(button.onPressed, isNull, reason: 'son görünür öğe kilitli');
    await tester.tap(eye('text'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.shows(UiItem.quickAdd('text')), isTrue);

    await done(tester);
    expect(tile('text'), findsOneWidget);
  });
}

class _FabHost extends ConsumerStatefulWidget {
  const _FabHost();

  @override
  ConsumerState<_FabHost> createState() => _FabHostState();
}

class _FabHostState extends ConsumerState<_FabHost>
    with QuickAddActions<_FabHost> {
  final _link = LayerLink();

  @override
  String? get quickAddFolderId => null;

  @override
  Future<void> openNewNote(
    String id, {
    String query = '',
    NoteType? type,
  }) async {}

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.bottomRight,
      child: CompositedTransformTarget(
        link: _link,
        child: QuickAddFab(anchor: _link, actions: () => this),
      ),
    ),
  );
}
