import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/menu_layout.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customize_board.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/quick_add_actions.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F60.S10 — "Not ekle" ("+") menüsü düzenlenebilir. 2026-11-15: panelin
/// "Düzenle"si düzen merkezinin "+" panosunu açar (eski panel içi satır
/// düzenleyicisi kalktı); kurallar panoda: gizle/göster, sıra GRUP İÇİNDE,
/// "Varsayılana dön", son görünür öğe gizlenemez.
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

  /// Panel → "Düzenle" → düzen merkezi levhası, "+" panosu seçili.
  Future<void> openBoard(WidgetTester tester) async {
    await openPanel(tester);
    await tester.tap(find.byKey(const ValueKey('quick-add-edit')));
    await tester.pumpAndSettle();
  }

  /// Levhayı kapatıp paneli yeniden aç.
  Future<void> backToPanel(WidgetTester tester) async {
    Navigator.of(tester.element(find.byType(CustomizeBoard))).pop();
    await tester.pumpAndSettle();
    await openPanel(tester);
  }

  CustomizeBoard board(WidgetTester tester) =>
      tester.widget<CustomizeBoard>(find.byType(CustomizeBoard));
  Finder tile(String key) => find.byKey(ValueKey('quick-add-$key'));

  testWidgets('"Düzenle" düzen merkezinin "+" panosunu açar', (tester) async {
    await tester.pumpWidget(host());
    await openBoard(tester);
    expect(
      find.byKey(const ValueKey('quickadd-board-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('customize-surface-addPanel')),
      findsOneWidget,
    );
    expect(tile('text'), findsNothing, reason: 'panel kapandı');
    expect(board(tester).entries.map((e) => e.id), contains('youtube'));
  });

  // 2026-11-16 (kullanıcı isteği, ekran görüntüsünde çarpılanlar): dosya,
  // YouTube, kalem, çizim, defter, Hızlı ekle ve favori şablonlar varsayılan
  // gizli; panoda durur, geri eklenir. Tara (belge+QR) tek karo; Akıllı liste
  // ve Hazır şablonlar şablon bölümünde.
  testWidgets('sade varsayılan: çarpılanlar gizli, panodan geri eklenir', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await openPanel(tester);
    for (final k in const [
      'file',
      'youtube',
      'draw',
      'drawing',
      'archive',
      'quickdrop',
      'fav-b:shopping',
    ]) {
      expect(tile(k), findsNothing, reason: k);
    }
    expect(tile('smartlist'), findsOneWidget);
    expect(tile('template'), findsOneWidget);
    expect(find.text('Hazır şablonlar'), findsOneWidget);
    expect(find.text('Akıllı liste'), findsOneWidget);
    // Birincil satır: üç karo, eşit genişlikte (tam ortada).
    final w = [
      for (final k in const ['text', 'checklist', 'ordered'])
        tester.getSize(tile(k)).width,
    ];
    expect(w[0], closeTo(w[1], 0.5));
    expect(w[1], closeTo(w[2], 0.5));

    await tester.tap(find.byKey(const ValueKey('quick-add-edit')));
    await tester.pumpAndSettle();
    final ids = board(tester).entries.map((e) => e.id);
    expect(ids, containsAll(['file', 'youtube', 'quickdrop', 'archive']));
    expect(board(tester).shown, isNot(contains('youtube')));
    board(tester).onToggle('youtube', true);
    await tester.pumpAndSettle();
    await backToPanel(tester);
    expect(tile('youtube'), findsOneWidget);
  });

  testWidgets('gizle → panelde yok; tekrar göster → geri gelir', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await openBoard(tester);
    final photo = find.byKey(const ValueKey('quickadd-board-photo'));
    await tester.ensureVisible(photo);
    await tester.tap(photo);
    await tester.pumpAndSettle();
    expect(
      Personalize.prefs.value.shows(UiItem.quickAdd('photo')),
      isFalse,
      reason: 'kalıcı (Personalize kaydı)',
    );
    await backToPanel(tester);
    expect(tile('photo'), findsNothing);
    expect(tile('video'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quick-add-edit')));
    await tester.pumpAndSettle();
    board(tester).onToggle('photo', true); // levha uzun: kaydırmadan
    await tester.pumpAndSettle();
    await backToPanel(tester);
    expect(tile('photo'), findsOneWidget);
  });

  testWidgets('sıra grup içinde: başa al, grup dışına bırakınca grubun ucu', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await openBoard(tester);
    var shown = board(tester).shown;
    expect(shown.take(3), ['text', 'checklist', 'ordered']);
    // "Sıralı liste" başa.
    board(tester).onReorder!(shown.indexOf('ordered'), 0);
    await tester.pumpAndSettle();
    shown = board(tester).shown;
    expect(shown.take(3), ['ordered', 'text', 'checklist']);
    // "Metin"i en sona (başka grubun içine) bırak: yazma grubunun sonuna.
    board(tester).onReorder!(shown.indexOf('text'), shown.length - 1);
    await tester.pumpAndSettle();
    shown = board(tester).shown;
    // "Hızlı ekle" ve kalem karoları varsayılan gizli (2026-11-16): yazma
    // grubundan sonra kamera grubu gelir.
    expect(shown.take(4), ['ordered', 'checklist', 'text', 'photo']);

    // Kalıcı: kayıttan yeniden okununca da aynı sıra.
    MenuLayouts.reset();
    MenuLayouts.attach(prefs);
    expect(
      MenuLayouts.of(quickAddMenuId)
          .sorted(['text', 'checklist', 'ordered', 'draw'], (id) => id),
      ['ordered', 'checklist', 'text', 'draw'],
    );
    await backToPanel(tester);
    expect(
      tester.getCenter(tile('ordered')).dx,
      lessThan(tester.getCenter(tile('checklist')).dx),
      reason: 'panel aynı sırayı çizer',
    );
  });

  testWidgets('varsayılana dön: gizliler görünür, sıra varsayılan', (
    tester,
  ) async {
    Personalize.update((p) => p.withVisible(UiItem.quickAdd('photo'), false));
    MenuLayouts.set(
      quickAddMenuId,
      const MenuLayout(order: ['ordered', 'checklist', 'text']),
    );
    await tester.pumpWidget(host());
    await openBoard(tester);
    expect(find.byKey(const ValueKey('quickadd-board-reset')), findsOneWidget);
    board(tester).onReset!();
    await tester.pumpAndSettle();
    expect(MenuLayouts.of(quickAddMenuId).isDefault, isTrue);
    expect(
      Personalize.prefs.value.hidden.where((h) => h.startsWith('quickadd.')),
      isEmpty,
    );
    await backToPanel(tester);
    expect(tile('photo'), findsOneWidget);
    expect(tile('youtube'), findsNothing, reason: 'varsayılan gizli');
    expect(
      tester.getCenter(tile('text')).dx,
      lessThan(tester.getCenter(tile('checklist')).dx),
    );
  });

  testWidgets('son görünür öğe gizlenemez', (tester) async {
    await tester.pumpWidget(host());
    await openBoard(tester);
    final ids = board(tester).shown;
    expect(ids, containsAll(['text', 'checklist', 'photo']));
    for (final k in ids) {
      if (k != 'text') board(tester).onToggle(k, false);
    }
    await tester.pumpAndSettle();
    expect(board(tester).shown, ['text']);
    board(tester).onToggle('text', false);
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.shows(UiItem.quickAdd('text')), isTrue);
    expect(find.text('En az bir seçenek görünür kalmalı'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(CustomizeBoard)))
        .removeCurrentSnackBar();
    await backToPanel(tester);
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
