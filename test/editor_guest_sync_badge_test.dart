import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// F60.4: misafir (anonim hesap) notunda üst çubuk "Senkronize" diyordu;
/// ana ekran ve hesap levhası "yalnız bu cihazda" diyor. Gösterge aynı dili
/// konuşmalı.
void main() {
  const note = Note(id: 'n', type: NoteType.text, title: 'Misafir notu');

  testWidgets('misafir: bulut yerine "Yalnız bu cihazda"', (tester) async {
    await pumpEditor(
      tester,
      note,
      overrides: [isAnonymousProvider.overrideWithValue(true)],
    );
    expect(find.byTooltip('Yalnız bu cihazda'), findsOneWidget);
    expect(find.byTooltip('Senkronize'), findsNothing);
    expect(find.byIcon(Icons.cloud_done_outlined), findsNothing);
    await endEditor(tester);
  });

  testWidgets('hesaplı kullanıcı: bulut göstergesi aynen', (tester) async {
    await pumpEditor(
      tester,
      note,
      overrides: [isAnonymousProvider.overrideWithValue(false)],
    );
    expect(find.byTooltip('Senkronize'), findsOneWidget);
    expect(find.byTooltip('Yalnız bu cihazda'), findsNothing);
    await endEditor(tester);
  });
}
