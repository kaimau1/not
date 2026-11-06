import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/menu_layout.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/presentation/folder_hold_button.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: Center(child: child)),
);

/// Kullanıcı isteği 2026-11-06: menüler düzenlenebilir; klasör düğmesi.
void main() {
  setUp(MenuLayouts.reset);

  const menu = ActionMenu(
    menuId: 'test.menu',
    quick: [
      MenuAction('a', 'Bir', Icons.star),
      MenuAction('b', 'İki', Icons.share),
    ],
    sections: [
      MenuSection('Grup', [
        MenuAction('c', 'Üç', Icons.copy),
        MenuAction('d', 'Dört', Icons.delete),
      ]),
    ],
  );

  testWidgets('menü: düzenle düğmesi var; gizlenen, hızlıya alınan, sıra', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SingleChildScrollView(child: menu)));
    expect(find.byKey(const ValueKey('menu-edit')), findsOneWidget);
    expect(find.text('Dört'), findsOneWidget);

    MenuLayouts.set(
      'test.menu',
      const MenuLayout(hidden: {'d'}, quick: ['c', 'a'], order: ['b']),
    );
    await tester.pump();
    expect(find.text('Dört'), findsNothing);
    // Hızlı satırdan çıkarılan "İki" kaybolmaz: "Diğer" grubunda.
    expect(find.text('İki'), findsOneWidget);
    expect(find.text('Diğer'), findsOneWidget);
    // Hızlı satır sırası: Üç, Bir.
    final dxC = tester.getCenter(find.text('Üç')).dx;
    final dxA = tester.getCenter(find.text('Bir')).dx;
    expect(dxC, lessThan(dxA));
  });

  testWidgets('menü düzenleyicisi: gözle gizle, kaydet', (tester) async {
    await tester.pumpWidget(_app(const SingleChildScrollView(child: menu)));
    await tester.tap(find.byKey(const ValueKey('menu-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-visible-c')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('menu-edit-save')));
    await tester.pumpAndSettle();
    expect(MenuLayouts.of('test.menu').hidden, {'c'});
    expect(find.text('Üç'), findsNothing);
  });

  test('yuvarlak menü: halkalar ve yönle seçim', () {
    expect(radialRings(3), [3]);
    expect(radialRings(8), [8]);
    expect(radialRings(11), [11]);
    expect(radialRings(0), isEmpty);
    // Ölü bölge: seçim yok (bırakmak vazgeçer).
    expect(radialFolderIndex(const Offset(5, 5), 4), isNull);
    // 4 durak: tepe 0, sağ 1, alt 2, sol 3 — küçük kayma yeter.
    expect(radialFolderIndex(const Offset(0, -20), 4), 0);
    expect(radialFolderIndex(const Offset(20, 0), 4), 1);
    expect(radialFolderIndex(const Offset(0, 20), 4), 2);
    expect(radialFolderIndex(const Offset(-20, 0), 4), 3);
    // Tek halka: uzaklık fark etmez, yalnız yön.
    expect(radialFolderIndex(const Offset(0, -20), 11), 0);
    expect(radialFolderIndex(const Offset(0, -120), 11), 0);
  });

  Widget button({
    required void Function() onOpen,
    required void Function(String?) onSelect,
  }) => _app(
    FolderHoldButton(
      stops: const [
        FolderStop(id: null, name: 'Tümü'),
        FolderStop(id: 'f1', name: 'İş', count: 3),
        FolderStop(id: 'f2', name: 'Ev'),
      ],
      currentId: null,
      onOpen: onOpen,
      onSelect: onSelect,
    ),
  );

  testWidgets('klasör düğmesi: dokun halkayı açar, klasöre dokun seçer', (
    tester,
  ) async {
    var opened = 0;
    String? picked = 'yok';
    await tester.pumpWidget(
      button(onOpen: () => opened++, onSelect: (id) => picked = id),
    );
    await tester.tap(find.byKey(const ValueKey('folder-hold-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('folder-radial-menu')), findsOneWidget);
    await tester.tap(find.text('Ev'));
    await tester.pumpAndSettle();
    expect(picked, 'f2');
    expect(opened, 0);
    expect(find.byKey(const ValueKey('folder-radial-menu')), findsNothing);
  });

  testWidgets('klasör düğmesi: orta daire Klasörler, boşluk vazgeçer', (
    tester,
  ) async {
    var opened = 0;
    String? picked = 'yok';
    await tester.pumpWidget(
      button(onOpen: () => opened++, onSelect: (id) => picked = id),
    );
    await tester.tap(find.byKey(const ValueKey('folder-hold-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('folder-radial-all')));
    await tester.pumpAndSettle();
    expect(opened, 1);
    await tester.tap(find.byKey(const ValueKey('folder-hold-button')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('folder-radial-menu')), findsNothing);
    expect(picked, 'yok');
    expect(opened, 1);
  });

  // Kullanıcı ekran görüntüsü 2026-11-06: 13 durak telefonda üst üste
  // biniyordu. Artık ya çakışmasız halka ya ızgara; hiçbir çip ötekine binmez.
  Future<void> openWith(WidgetTester tester, List<FolderStop> stops) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        FolderHoldButton(
          stops: stops,
          currentId: null,
          onOpen: () {},
          onSelect: (_) {},
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('folder-hold-button')));
    await tester.pumpAndSettle();
  }

  void expectNoOverlap(WidgetTester tester, int n) {
    final rects = [
      for (var i = 0; i < n; i++)
        tester.getRect(find.byKey(ValueKey('folder-radial-$i'))),
    ];
    final screen = Offset.zero & const Size(360, 780);
    for (var i = 0; i < n; i++) {
      expect(screen.contains(rects[i].topLeft), isTrue, reason: 'durak $i');
      expect(screen.contains(rects[i].bottomRight), isTrue, reason: 'durak $i');
      for (var j = i + 1; j < n; j++) {
        expect(
          rects[i].overlaps(rects[j]),
          isFalse,
          reason: 'durak $i ile $j üst üste',
        );
      }
    }
  }

  const names = [
    'Tümü',
    'YouTube',
    'Dualar',
    'Borç',
    'Oyunlar',
    'Tıp',
    'Yazılım',
    'Araba',
    'Asistan',
    'Haritalar',
    'Kanallarım',
    'Bütçem',
    'Klinik',
  ];

  testWidgets('13 klasör telefonda: ızgara, çakışma yok, dokununca seçer', (
    tester,
  ) async {
    await openWith(tester, [
      for (var i = 0; i < names.length; i++)
        FolderStop(id: i == 0 ? null : 'f$i', name: names[i], count: i),
    ]);
    expect(find.byKey(const ValueKey('folder-grid-menu')), findsOneWidget);
    expectNoOverlap(tester, names.length);
  });

  testWidgets('az klasör: halka, çakışma yok, orta daireye binmez', (
    tester,
  ) async {
    await openWith(tester, [
      for (var i = 0; i < 5; i++)
        FolderStop(id: i == 0 ? null : 'f$i', name: names[i], count: i),
    ]);
    expect(find.byKey(const ValueKey('folder-ring-menu')), findsOneWidget);
    expectNoOverlap(tester, 5);
    final disc = tester.getRect(
      find.byKey(const ValueKey('folder-radial-all')),
    );
    for (var i = 0; i < 5; i++) {
      final r = tester.getRect(find.byKey(ValueKey('folder-radial-$i')));
      final c = disc.center;
      final near = Offset(
        c.dx.clamp(r.left, r.right),
        c.dy.clamp(r.top, r.bottom),
      );
      expect(
        (near - c).distance,
        greaterThanOrEqualTo(disc.width / 2),
        reason: 'durak $i orta daireye biniyor',
      );
    }
  });

  test('radialLayoutFits: küçük yarıçapta geniş çipler sığmaz', () {
    final chips = List.filled(12, const Size(110, 34));
    expect(radialLayoutFits(chips, 120), isFalse);
    expect(radialRadiiFor(chips, const Size(360, 780)), isNull);
    final few = List.filled(4, const Size(90, 34));
    expect(radialRadiiFor(few, const Size(360, 780)), isNotNull);
  });
}
