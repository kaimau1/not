import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';

/// F45.2: bölüm başlığı tek stil, sıfır rozet çizilmez, ek menüleri tek
/// katalogdan.
void main() {
  final sources = [
    for (final f in Directory('lib').listSync(recursive: true))
      if (f is File &&
          f.path.endsWith('.dart') &&
          !f.path.contains('l10n${Platform.pathSeparator}generated'))
        f,
  ];

  test('harf aralıklı başlık deseni yok: sectionLabelStyle', () {
    // Harf aralığı yalnız küçük rozetlerde (kart ve şerit türü).
    const badges = {'note_card_media.dart', 'attachment_strip.dart'};
    final spaced = RegExp(r'letterSpacing: 0\.[3-9]');
    expect([
      for (final f in sources)
        if (!badges.contains(f.uri.pathSegments.last))
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (spaced.hasMatch(line)) '${f.path}:${i + 1}',
    ], isEmpty);
  });

  test('ek menüsü olan her yüzey katalogdan okur (F40.1)', () {
    const surfaces = [
      'attachment_strip.dart',
      'note_images.dart',
      'note_image_tools.dart',
      'pinned_media_pane.dart',
    ];
    for (final name in surfaces) {
      final file = sources.singleWhere((f) => f.uri.pathSegments.last == name);
      expect(
        file.readAsStringSync(),
        contains('attachmentActionsFor('),
        reason: name,
      );
    }
  });

  test('sabit bölme de Kopyala ve Metni çıkar sunar (cihaz turu)', () {
    final pane = sources
        .singleWhere((f) => f.uri.pathSegments.last == 'pinned_media_pane.dart')
        .readAsStringSync();
    expect(pane, contains('copy: widget.onCopy != null'));
    expect(pane, contains('extractText: widget.onExtractText != null'));
    final view = sources
        .singleWhere(
          (f) => f.uri.pathSegments.last == 'note_editor_media_view.dart',
        )
        .readAsStringSync();
    expect(view, contains('onExtractText: _readOnly'));
  });

  testWidgets('sayı 0 ise rozet çizilmez', (tester) async {
    Widget menu(int count) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ActionMenu(
            quick: [MenuAction('a', 'Klasör', Icons.folder, count: count)],
            sections: [
              MenuSection('Grup', [
                MenuAction('b', 'Etiket', Icons.label, count: count),
              ]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(menu(0));
    expect(find.text('0'), findsNothing);
    await tester.pumpWidget(menu(3));
    expect(find.text('3'), findsNWidgets(2));
  });
}
