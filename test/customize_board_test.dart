import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/customize_board.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.1): düzenleme panosu. Pano sıra
/// HESAPLAMAZ ve kayıt TUTMAZ — verileni çizer, dokunuşu bildirir.
void main() {
  const entries = <CustomizeEntry>[
    (id: 'bold', icon: Icons.format_bold, label: 'Kalın'),
    (id: 'italic', icon: Icons.format_italic, label: 'İtalik'),
    (id: 'list', icon: Icons.checklist, label: 'Liste'),
  ];

  Widget host({
    required List<String> shown,
    void Function(String id, bool visible)? onToggle,
    void Function(int from, int to)? onReorder,
    VoidCallback? onReset,
    String? emptyLabel,
    String keyPrefix = 'customize-',
    Widget? Function(String id)? trailingOf,
    double textScale = 1,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: CustomizeBoard(
          entries: entries,
          shown: shown,
          onToggle: onToggle ?? (_, _) {},
          onReorder: onReorder,
          onReset: onReset,
          shownLabel: 'Görünenler',
          availableLabel: 'Eklenebilir',
          emptyLabel: emptyLabel,
          resetLabel: 'Varsayılana dön',
          keyPrefix: keyPrefix,
          trailingOf: trailingOf,
        ),
      ),
    ),
  );

  testWidgets('karoya dokun → onToggle(id, !visible)', (tester) async {
    final calls = <(String, bool)>[];
    await tester.pumpWidget(
      host(shown: ['bold'], onToggle: (id, v) => calls.add((id, v))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('customize-bold')));
    await tester.tap(find.byKey(const ValueKey('customize-list')));
    expect(calls, [('bold', false), ('list', true)]);
  });

  testWidgets('görünenler shown sırasında; başlıklar sayıyı taşır', (
    tester,
  ) async {
    await tester.pumpWidget(host(shown: ['list', 'bold']));
    await tester.pumpAndSettle();
    final list = tester.getTopLeft(
      find.byKey(const ValueKey('customize-list')),
    );
    final bold = tester.getTopLeft(
      find.byKey(const ValueKey('customize-bold')),
    );
    expect(list.dx, lessThan(bold.dx), reason: 'varsayılan sıra değil, shown');
    expect(find.text('Görünenler · 2'), findsOneWidget);
    expect(find.text('Eklenebilir · 1'), findsOneWidget);
    // Önizleme şeridi de aynı sırada.
    final strip = find.byKey(const ValueKey('customize-preview'));
    final icons = tester
        .widgetList<Icon>(
          find.descendant(of: strip, matching: find.byType(Icon)),
        )
        .map((i) => i.icon)
        .toList();
    expect(icons, [Icons.checklist, Icons.format_bold]);
  });

  testWidgets('onReorder yokken sürükleme tutamağı yok, varken her simgede', (
    tester,
  ) async {
    await tester.pumpWidget(host(shown: ['bold', 'italic']));
    expect(find.byType(ReorderableDelayedDragStartListener), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
    await tester.pumpWidget(
      host(shown: ['bold', 'italic'], onReorder: (_, _) {}),
    );
    expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(2));
  });

  testWidgets('tümü görünürken "Eklenebilir" başlığı çizilmez', (tester) async {
    await tester.pumpWidget(host(shown: ['bold', 'italic', 'list']));
    expect(find.textContaining('Eklenebilir'), findsNothing);
    expect(find.text('Görünenler · 3'), findsOneWidget);
  });

  testWidgets('hiç görünen yokken emptyLabel önizleme şeridinde', (
    tester,
  ) async {
    await tester.pumpWidget(host(shown: const [], emptyLabel: 'Boş'));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('customize-preview')),
        matching: find.text('Boş'),
      ),
      findsOneWidget,
    );
    expect(find.text('Eklenebilir · 3'), findsOneWidget);
  });

  testWidgets('anahtar öneki karo, önizleme ve sıfırlamaya uygulanır; '
      'onReset yoksa düğme yok; trailingOf karonun sonunda', (tester) async {
    var resets = 0;
    await tester.pumpWidget(
      host(
        shown: ['bold'],
        keyPrefix: 'bar-switch-',
        onReset: () => resets++,
        trailingOf: (id) => id == 'bold'
            ? const Icon(Icons.swap_horiz, key: ValueKey('bar-move-bold'))
            : null,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bar-switch-bold')), findsOneWidget);
    expect(find.byKey(const ValueKey('bar-switch-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('customize-bold')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bar-switch-bold')),
        matching: find.byKey(const ValueKey('bar-move-bold')),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('bar-switch-reset')));
    expect(resets, 1);

    await tester.pumpWidget(host(shown: ['bold']));
    expect(find.byKey(const ValueKey('customize-reset')), findsNothing);
  });

  testWidgets('360 dp + yazı 1.3: taşma yok', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(shown: ['bold', 'italic'], onReset: () {}, textScale: 1.3),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
