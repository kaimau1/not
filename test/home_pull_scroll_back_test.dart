import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KT-22 (tablet turu 2026-11-18): listeyi başa almak için aşağı kaydırırken
/// klasör menüsü kendiliğinden açılıyor, sonraki dokunuşu yutuyordu.
/// KÖK NEDEN: çekiş mesafesi, parmak listeyi tepeye GETİRDİKTEN SONRAKİ
/// aşırı kaydırmadan da sayılıyordu — aşağıdan başlayan uzun bir kaydırma
/// tepeye çarpınca kalan 80 dp "çekiş" oluyordu. Çekiş artık yalnız liste
/// ZATEN tepedeyken başlayan parmak hareketinde sayılır (yenile-çek gibi).
void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            for (var i = 0; i < 40; i++)
              Note(id: 'n$i', type: NoteType.text, title: 'Not $i'),
          ]),
        ),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value(const [
            NoteFolder(id: 'f9', name: 'İş', ownerId: 'ben'),
          ]),
        ),
        sharedFolderRefsProvider.overrideWith(
          (ref) => Stream.value(const <SharedFolderRef>[]),
        ),
        folderUnreadProvider.overrideWith((ref, key) => 0),
        myNoteSharesProvider.overrideWith((ref) => Stream.value(const {})),
        sharedNotesWithMeProvider.overrideWith(
          (ref) => Stream.value(const <NoteShare>[]),
        ),
        inboxNotesProvider.overrideWith(
          (ref) => Stream.value(const <InboxNote>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> slowDrag(WidgetTester tester, double dy) async {
    final g = await tester.startGesture(const Offset(206, 600));
    final steps = (dy.abs() / 12).ceil();
    for (var i = 0; i < steps; i++) {
      await g.moveBy(Offset(0, dy / steps));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Bırakmadan önce dur: fırlatma değil.
    await tester.pump(const Duration(milliseconds: 200));
    await g.up();
    await settle(tester);
  }

  final menu = find.byKey(const ValueKey('folder-radial-menu'));

  testWidgets('KT-22: aşağıdan başlayıp tepeye çarpan kaydırma menü açmaz', (
    tester,
  ) async {
    await pump(tester);
    // Biraz aşağı in (parmak yukarı).
    await slowDrag(tester, -200);
    expect(menu, findsNothing);
    // Tek hamlede geri gel: 200 dp liste + 200 dp tepede aşırı kaydırma.
    await slowDrag(tester, 400);
    expect(menu, findsNothing, reason: 'başa dönüş klasör menüsü açmamalı');
    // Liste artık tepede: bilinçli çekiş yine menüyü açar.
    await slowDrag(tester, 200);
    expect(menu, findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
