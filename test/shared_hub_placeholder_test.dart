import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/empty_state.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/inbox/presentation/shared_hub_screen.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F79.6 (3): ana ekranın "Gelen" süzgeci okuma hatasında "burada not yok"
/// diyordu. Boş yer tutucu artık ayrı ekranla ortak: hata → hata görünümü +
/// Tekrar dene; gerçekten boş → boş mesajı.
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  Future<void> pump(
    WidgetTester tester, {
    required Stream<List<InboxNote>> Function() inbox,
    bool skeleton = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inboxNotesProvider.overrideWith((ref) => inbox()),
          sharedNotesWithMeProvider.overrideWith(
            (ref) => Stream.value(const <NoteShare>[]),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) =>
                  sharedHubPlaceholder(context, ref, skeleton: skeleton),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('okuma hatasında "not yok" değil hata + Tekrar dene', (
    tester,
  ) async {
    await pump(
      tester,
      inbox: () => Stream<List<InboxNote>>.error(
        Exception('SocketException: Failed host lookup'),
      ),
    );
    expect(find.text(l10n.sharedHubEmpty), findsNothing);
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('gerçekten boşsa boş mesajı', (tester) async {
    await pump(tester, inbox: () => Stream.value(const <InboxNote>[]));
    expect(find.text(l10n.sharedHubEmpty), findsOneWidget);
  });

  testWidgets('ana ekran kipinde yüklenirken boş mesajı yok, iskelet yok', (
    tester,
  ) async {
    final c = StreamController<List<InboxNote>>();
    addTearDown(c.close);
    await pump(tester, inbox: () => c.stream);
    expect(find.text(l10n.sharedHubEmpty), findsNothing);
    expect(find.byKey(const ValueKey('list-skeleton')), findsNothing);
  });
}
