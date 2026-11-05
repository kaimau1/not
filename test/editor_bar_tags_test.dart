import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/editor_bar_tags.dart';

/// Üst çubukta tarihin solundaki etiketler (kullanıcı isteği 2026-11-05).
void main() {
  testWidgets('etikete dokununca "Etiketi kaldır"; dar alanda taşmaz', (
    tester,
  ) async {
    final removed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Flexible(
                child: EditorBarTags(
                  tags: const ['iş', 'alışveriş', 'çok-uzun-bir-etiket'],
                  removeLabel: 'Etiketi kaldır',
                  onRemove: removed.add,
                ),
              ),
              const SizedBox(width: 700, child: Text('13:45')),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('#iş'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('editor-bar-tag-iş')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Etiketi kaldır'));
    await tester.pumpAndSettle();
    expect(removed, ['iş']);
  });
}
