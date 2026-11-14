import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_slice.dart';

/// P20 adım 3 (OTURTMA F64.2): dilim dışı alan değişince builder çağrılmaz;
/// kaynak değişince abonelik taşınır.
void main() {
  const base = Note(id: 'n', type: NoteType.text, title: 'a', body: 'b');

  testWidgets('dilim dışı alan → builder yok; dilim → builder', (t) async {
    final src = ValueNotifier<Note?>(base);
    var builds = 0;
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: NoteSlice<bool>(
          source: src,
          select: (n) => n.starred,
          builder: (_, on) {
            builds++;
            return Text('$on');
          },
        ),
      ),
    );
    expect(builds, 1);
    src.value = base.copyWith(body: 'değişti');
    await t.pump();
    expect(builds, 1, reason: 'gövde dilim dışı');
    src.value = null;
    await t.pump();
    expect(find.text('false'), findsOneWidget, reason: 'null → son değer');
    src.value = base.copyWith(starred: true);
    await t.pump();
    expect(builds, 2);
    expect(find.text('true'), findsOneWidget);
  });

  testWidgets('kaynak değişince abonelik taşınır', (t) async {
    final a = ValueNotifier<Note?>(base);
    final b = ValueNotifier<Note?>(base.copyWith(pinned: true));
    Widget host(ValueNotifier<Note?> s) => Directionality(
      textDirection: TextDirection.ltr,
      child: NoteSlice<bool>(
        source: s,
        select: (n) => n.pinned,
        builder: (_, on) => Text('$on'),
      ),
    );
    await t.pumpWidget(host(a));
    expect(find.text('false'), findsOneWidget);
    await t.pumpWidget(host(b));
    expect(find.text('true'), findsOneWidget);
    b.value = base;
    await t.pump();
    expect(find.text('false'), findsOneWidget);
    a.value = base.copyWith(pinned: true);
    await t.pump();
    expect(find.text('false'), findsOneWidget, reason: 'eski kaynak bırakıldı');
  });
}
