import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/note_open_route.dart';

/// F23.4 (AKICILIK_PLANI, K7): genişleyen not geçişinde ara katman yok —
/// içerik boya alfasıyla solar (`Opacity` yok), kenar yumuşatmalı kırpma
/// yalnız köşe yuvarlakken, geçiş bitince kırpma hiç yok.
void main() {
  testWidgets('geçiş: Opacity yok, kırpma yarıçapa göre', (tester) async {
    // Dar (telefon) ekran: geniş ekranda not sağ bölmede, büyüme yok.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final host = GlobalKey<_HostState>();
    await tester.pumpWidget(MaterialApp(home: _Host(key: host)));
    await tester.tap(find.text('KART'));
    await tester.pump();
    expect(find.text('NOT'), findsOneWidget);

    Finder clips() =>
        find.ancestor(of: find.text('NOT'), matching: find.byType(ClipRRect));
    final seen = <Clip>{};
    for (var ms = 0; ms < 520; ms += 20) {
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        find.ancestor(of: find.text('NOT'), matching: find.byType(Opacity)),
        findsNothing,
      );
      for (final e in clips().evaluate()) {
        seen.add((e.widget as ClipRRect).clipBehavior);
      }
    }
    expect(seen, containsAll(<Clip>[Clip.antiAlias, Clip.none]));
    await tester.pumpAndSettle();
    expect(
      clips().evaluate().map((e) => (e.widget as ClipRRect).clipBehavior),
      everyElement(Clip.none),
    );

    // Kapanış da hatasız (görüntü alfayla söner).
    host.currentState!.close();
    for (var ms = 0; ms < 420; ms += 20) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
    expect(find.text('NOT'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _Host extends StatefulWidget {
  const _Host({super.key});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<Page<void>> _pages = [MaterialPage<void>(child: _home())];

  Widget _home() => Scaffold(
    body: Center(
      child: Builder(
        builder: (card) => GestureDetector(
          onTap: () {
            NoteOpenOrigin.register(card, 'n', color: Colors.amber);
            setState(
              () => _pages = [
                ..._pages,
                const NoteOpenPage<void>(
                  noteId: 'n',
                  child: Scaffold(body: Text('NOT')),
                ),
              ],
            );
          },
          child: const SizedBox(width: 150, height: 100, child: Text('KART')),
        ),
      ),
    ),
  );

  void close() => setState(() => _pages = [_pages.first]);

  @override
  Widget build(BuildContext context) => Navigator(
    pages: _pages,
    onDidRemovePage: (p) => setState(() => _pages.remove(p)),
  );
}
