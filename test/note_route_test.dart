import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/router.dart';

void main() {
  // v1.0.181: rota metni elle kuruluyordu ve kacan bir ters bolu yuzunden
  // '/note/$id' DUZ METIN olarak gitti; uygulama olmayan bir notu bekledigi
  // icin yeni not acan butun modlar "yukleniyor" ekraninda kaldi. Derleyici
  // ve testler goremedi (gecerli bir dizeydi). Artik tek yer, tek test.
  test('not rotasi id ve sorguyu YERINE KOYAR', () {
    expect(noteRoutePath('abc123'), '/note/abc123');
    expect(noteRoutePath('abc123', query: '?draw=1'), '/note/abc123?draw=1');
    expect(noteRoutePath('x').contains(r'$'), isFalse);
  });

  // 2026-10-02: "arsivdeki notlar acilmiyor, basinca siyah ekran".
  test('kabuk disindan acilan not kabuk disi esine gider', () {
    expect(notePushPath('/', '/note/a'), '/note/a');
    expect(notePushPath('/note/b', '/note/a'), '/note/a');
    expect(notePushPath('/notebook/b', '/notebook/a'), '/notebook/a');
    for (final here in [
      '/archive',
      '/trash',
      '/reminders',
      '/folders',
      '/inbox',
      '/ai',
      '/settings',
      '/open/note/b',
    ]) {
      expect(notePushPath(here, '/note/a?ro=1'), '/open/note/a?ro=1');
      expect(notePushPath(here, '/notebook/a'), '/open/notebook/a');
    }
  });

  // Uygulamanin rota iskeletinin aynisi: dis kabuk (AppFrame) > [liste+not
  // kabugu (SplitShell) > [/, /note/:id], /archive, /open/note/:id].
  GoRouter buildRouter() => GoRouter(
    routes: [
      ShellRoute(
        builder: (c, s, child) => child,
        routes: [
          ShellRoute(
            builder: (c, s, child) => child,
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => const Scaffold(body: Text('HOME')),
              ),
              GoRoute(
                path: '/note/:id',
                builder: (c, s) =>
                    Scaffold(body: Text('NOTE ${s.pathParameters['id']}')),
              ),
            ],
          ),
          GoRoute(
            path: '/archive',
            builder: (c, s) => const Scaffold(body: Text('ARCHIVE')),
          ),
          GoRoute(
            path: '$kOutsideShellNotePrefix/note/:id',
            builder: (c, s) =>
                Scaffold(body: Text('NOTE ${s.pathParameters['id']}')),
          ),
        ],
      ),
    ],
  );

  testWidgets('arsivden not acilir, geri arsive doner (siyah ekran yok)', (
    tester,
  ) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    unawaited(router.push('/archive'));
    await tester.pumpAndSettle();
    expect(find.text('ARCHIVE'), findsOneWidget);

    unawaited(router.pushNote(noteRoutePath('x')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('NOTE x').hitTestable(), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('ARCHIVE').hitTestable(), findsOneWidget);
  });

  testWidgets('ana ekrandan not kabuk icindeki yoldan acilir', (tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    unawaited(router.pushNote(noteRoutePath('y')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/note/y');
    expect(find.text('NOTE y').hitTestable(), findsOneWidget);
  });

  // Klasor sayfasi gibi Navigator.push ile acilan (sayfasiz) ekrandan:
  // yonlendirici onu gormez, not kabuk icine girse sayfanin ALTINDA kalirdi.
  testWidgets('sayfasiz ekrandan acilan not en uste biner', (tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final home = tester.element(find.text('HOME'));
    late BuildContext folderContext;
    Navigator.of(home).push(
      MaterialPageRoute<void>(
        builder: (context) {
          folderContext = context;
          return const Scaffold(body: Text('FOLDER'));
        },
      ),
    );
    await tester.pumpAndSettle();
    unawaited(folderContext.pushNote(noteRoutePath('z')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('NOTE z').hitTestable(), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('FOLDER').hitTestable(), findsOneWidget);
  });
}
