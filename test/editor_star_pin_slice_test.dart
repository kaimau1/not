import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// P20 adım 4 (M4): yıldız/iğne `NoteSlice` ile dinlenir — tuval kurulmaz,
/// simge yine anında değişir, kayıt yazılır.
void main() {
  // Tarih şeridi (yıldız göstergesi orada) yalnız tarihli notta çizilir.
  final text = Note(
    id: 'n',
    type: NoteType.text,
    title: 'Kısa',
    body: 'yazı',
    updatedAt: DateTime(2026, 11, 14),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<int> canvasBuilds(Future<void> Function() body) async {
    final counter = BuildCounter()..start();
    try {
      await body();
    } finally {
      counter.stop();
    }
    return counter.of('NotePageCanvas');
  }

  testWidgets('üst çubuk iğnesi: tuval 0, simge dolu, kayıt pinned', (
    tester,
  ) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, text, repo: repo);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    final n = await canvasBuilds(() async {
      await tester.tap(find.byTooltip('Sabitle'));
      await settle(tester);
    });
    expect(n, 0, reason: 'iğne tuvali kurmamalı');
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.byTooltip('Sabitlemeyi kaldır'), findsOneWidget);
    expect(repo.lastSaved!.pinned, isTrue);
    await endEditor(tester);
  });

  testWidgets('yıldız (⋮ levhası): tuval 0, tarih yanında yıldız', (
    tester,
  ) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, text, repo: repo);
    expect(find.byTooltip('Yıldızı kaldır'), findsNothing);
    final n = await canvasBuilds(() async {
      await tester.tap(find.byKey(const ValueKey('editor-more')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('menu-quick-star')));
      await settle(tester);
    });
    expect(n, 0, reason: 'yıldız tuvali kurmamalı');
    expect(find.byTooltip('Yıldızı kaldır'), findsOneWidget);
    expect(repo.lastSaved!.starred, isTrue);
    // Göstergeye dokununca yıldız kalkar — yine kök kurulmadan.
    await tester.tap(find.byTooltip('Yıldızı kaldır'));
    await settle(tester);
    expect(find.byTooltip('Yıldızı kaldır'), findsNothing);
    expect(repo.lastSaved!.starred, isFalse);
    await endEditor(tester);
  });
}
