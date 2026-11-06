import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/friends/domain/friend.dart';
import 'package:notlar/features/friends/domain/friend_list.dart';
import 'package:notlar/features/friends/presentation/friends_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kişiler ekranı baştan (kullanıcı isteği 2026-11-06).
void main() {
  const people = [
    Friend(uid: 'u1', email: 'zeynep@x.com', name: 'Zeynep'),
    Friend(uid: 'u2', email: 'ilker@x.com', name: 'ilker'),
    Friend(uid: 'u3', email: 'cem@x.com', name: 'Çiğdem'),
    Friend(uid: 'u4', email: 'ali@x.com', name: ''),
  ];

  test('Türkçe sıra, baş harf kümeleri, arama, e-posta tanıma', () {
    final groups = groupFriends(people);
    expect(groups.map((g) => g.letter).toList(), ['A', 'Ç', 'İ', 'Z']);
    expect(personInitial('ılgaz'), 'I');
    expect(personInitial('9lu'), '#');
    expect(filterFriends(people, 'İLKER').single.uid, 'u2');
    expect(filterFriends(people, 'x.com').length, 4);
    expect(friendLabel('', 'a@b.c'), 'a@b.c');
    expect(looksLikeEmail('a@b.co'), isTrue);
    expect(looksLikeEmail('ali'), isFalse);
  });

  Widget app({
    List<Friend> friends = people,
    List<FriendRequest> requests = const [],
  }) => ProviderScope(
    overrides: [
      currentUidProvider.overrideWithValue(null),
      friendsStreamProvider.overrideWith((_) => Stream.value(friends)),
      incomingFriendRequestsProvider.overrideWith(
        (_) => Stream.value(requests),
      ),
      foldersStreamProvider.overrideWith(
        (_) => Stream.value(const [
          NoteFolder(
            id: 'f1',
            name: 'Tatil',
            ownerId: 'me',
            sharedWith: ['u1'],
          ),
        ]),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('tr'),
      home: FriendsScreen(),
    ),
  );

  testWidgets('liste, istek kartı ve kişi kartında paylaşılan klasör', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(
        requests: const [
          FriendRequest(fromUid: 'r1', fromEmail: 'r@x.com', fromName: 'Rana'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('request-r1')), findsOneWidget);
    expect(find.byKey(const ValueKey('request-accept-r1')), findsOneWidget);
    expect(find.text('Zeynep'), findsOneWidget);
    expect(find.text('Ç'), findsNWidgets(2)); // küme harfi + avatar
    await tester.tap(find.byKey(const ValueKey('friend-u1')));
    await tester.pumpAndSettle();
    expect(find.text('Tatil'), findsOneWidget);
    expect(find.byKey(const ValueKey('friend-remove')), findsOneWidget);
  });

  testWidgets('boş: açıklama ve Ekle düğmesi; ekleme levhası e-posta önerir', (
    tester,
  ) async {
    await tester.pumpWidget(app(friends: const []));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('friends-empty')), findsOneWidget);
    await tester.tap(find.text('Arkadaş ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('friends-add-field')),
      'yeni@ornek.com',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('friends-send-email')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
  });
}
