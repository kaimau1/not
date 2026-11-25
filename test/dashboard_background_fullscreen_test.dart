import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TAM EKRAN ZEMİN (kullanıcı 2026-11-25, ekran görüntüsü: "arka plan
/// zemini tüm ekranı kaplamıyor, üst ve alt alan kaplanmalı"). KÖK NEDEN:
/// zemin `SafeArea`nın içindeydi (durum çubuğu ve gezinme çubuğu şeridi düz
/// renk), arama çubuğu (AppBar) da üstüne opak `surface` boyuyordu; görsel
/// `AnimatedSwitcher`'da gevşek kısıtla kendi en-boy oranında ortalanıyordu.
void main() {
  Future<void> pump(WidgetTester tester, {String? preset}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    // Telefon: durum çubuğu 24 dp, üç tuşlu gezinme çubuğu 48 dp.
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'dashboard_bg_preset': ?preset});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(
          NotesRepository(FakeFirebaseFirestore(), 'ben'),
        ),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            Note(id: 'a', type: NoteType.text, title: 'Birinci not'),
            Note(id: 'b', type: NoteType.text, title: 'İkinci not'),
          ]),
        ),
        foldersStreamProvider.overrideWith((ref) => Stream.value([])),
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
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Rect wallpaperRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const ValueKey('preset:aurora_bloom')));

  testWidgets('zemin görseli ekranın tamamını kaplar, arama çubuğu saydam', (
    tester,
  ) async {
    await pump(tester, preset: 'aurora_bloom');
    expect(wallpaperRect(tester), const Rect.fromLTWH(0, 0, 412, 915));
    final bar = tester.widget<AppBar>(find.byType(AppBar).first);
    expect(bar.backgroundColor, Colors.transparent);
    // Saydam zeminden tahmin edilse simgeler beyaz olurdu: açık temada koyu.
    expect(bar.systemOverlayStyle?.statusBarIconBrightness, Brightness.dark);
    // Yüzen düğmeler ve ızgaranın sonu gezinme çubuğunun üstünde kalır.
    final fab = tester.getRect(find.byType(FloatingActionButton).last);
    expect(fab.bottom, lessThanOrEqualTo(915 - 48 - 16 + 0.5));
  });

  testWidgets('zemin yokken arama çubuğu temanın zemininde (değişmedi)', (
    tester,
  ) async {
    await pump(tester);
    final bar = tester.widget<AppBar>(find.byType(AppBar).first);
    expect(bar.backgroundColor, isNull);
    expect(bar.systemOverlayStyle, isNull);
  });
}
