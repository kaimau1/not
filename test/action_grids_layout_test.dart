import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_actions_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_add_actions.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Not işlem menüsü (⋮ / uzun basış) iki sütunlu, "+" paneli üç sütunlu
/// ızgaradır. Bu testler yerleşimi doğrular: Flutter testlerinde taşma
/// (overflow) hata attığından, sığmayan bir ızgara testi kırar.
void main() {
  Widget host(Widget child) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets('not işlem menüsü iki sütunlu ızgara olarak açılır', (
    tester,
  ) async {
    const note = Note(id: 'n1', type: NoteType.text, title: 'Kitaplık planı');
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showNoteActionsSheet(context, ref, note),
              child: const Text('aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    // Başlık + tüm işlemler görünür (eskiden "Sil" kaydırma gerektiriyordu).
    expect(find.text('Kitaplık planı'), findsOneWidget);
    // Kopyala/Arkadaşa gönder/Dışa aktar Paylaş levhasında (2026-10-17).
    expect(find.text('Arkadaşa gönder'), findsNothing);
    for (final label in ['Sabitle', 'Paylaş', 'Notu çoğalt', 'Seç', 'Sil']) {
      expect(find.text(label), findsOneWidget, reason: '$label görünmeli');
    }

    // Hızlı satır: "Sabitle", "Yıldızla" (2026-10-20'de geri geldi) ve
    // "Paylaş" AYNI satırda, bu sırayla yan yana.
    final pin = tester.getRect(find.text('Sabitle'));
    final star = tester.getRect(find.text('Yıldızla'));
    final share = tester.getRect(find.text('Paylaş'));
    expect(pin.center.dy, closeTo(star.center.dy, 1));
    expect(pin.center.dy, closeTo(share.center.dy, 1));
    expect(pin.center.dx, lessThan(star.center.dx));
    expect(star.center.dx, lessThan(share.center.dx));

    // "Sil" tek başına, alt satırda ve tam genişlikte.
    expect(tester.getRect(find.text('Sil')).center.dy, greaterThan(pin.top));
  });

  testWidgets('"+" paneli tek panel: Metin/Liste altta, seçenekler tek dokunuş', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(host(_FabHost(calls)));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byType(FloatingActionButton).last);
    final text = tester.getRect(find.text('Metin notu'));
    final list = tester.getRect(find.text('Liste'));
    // Birincil ikili yan yana ve PANELİN EN ALTINDA (FAB'a en yakın).
    expect(text.center.dy, closeTo(list.center.dy, 1));
    expect(text.center.dx, lessThan(list.center.dx));
    expect(fab.top - text.bottom, lessThan(60));
    // Ana ekranda sesli not menüde yok (tek mikrofon, F3.1).
    expect(find.text('Sesli not'), findsNothing);
    // Gruplar başlıklı; dosya birincilin hemen üstünde, sonra kamera,
    // "Diğer" en üstte. Sıralı liste birincil satırda.
    final camera = tester.getRect(
      find.byKey(const ValueKey('quick-section-capture')),
    );
    final files = tester.getRect(
      find.byKey(const ValueKey('quick-section-files')),
    );
    final more = tester.getRect(
      find.byKey(const ValueKey('quick-section-more')),
    );
    expect(files.center.dy, lessThan(text.center.dy));
    expect(camera.center.dy, lessThan(files.center.dy));
    expect(more.center.dy, lessThan(camera.center.dy));
    expect(
      tester.getRect(find.text('Sıralı liste')).center.dy,
      closeTo(text.center.dy, 1),
    );
    // Seçenekler PANELDE — kapı levhası yok, tek dokunuşla çalışır.
    expect(find.text('Dosya ekle'), findsOneWidget);
    expect(find.text('YouTube videosu'), findsOneWidget);

    await tester.tap(find.text('YouTube videosu'));
    await tester.pumpAndSettle();
    expect(find.text('Metin notu'), findsNothing, reason: 'panel kapanır');
    expect(calls, ['youtube']);

    // Metin notu tek dokunuş.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metin notu'));
    await tester.pumpAndSettle();
    expect(calls, ['youtube', 'text']);
  });
}

class _FabHost extends ConsumerStatefulWidget {
  const _FabHost(this.calls);

  final List<String> calls;

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
  Future<void> createNote(NoteType type) async => widget.calls.add(type.name);

  @override
  Future<void> createYouTubeNote() async => widget.calls.add('youtube');

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.bottomRight,
      child: CompositedTransformTarget(
        link: _link,
        child: QuickAddFab(anchor: _link, actions: this),
      ),
    ),
  );
}
