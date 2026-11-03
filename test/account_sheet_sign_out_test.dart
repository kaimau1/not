import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/account_sheet.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-11-03: "hesap değiştir ve oturumu kapat tepki
/// vermiyor". Hesap levhası düğmeye basınca kapanıyor, levhanın `WidgetRef`i
/// onay diyaloğu açıkken ağaçtan kalkıyordu; onaydan sonraki `ref.read` hata
/// atıp çıkışı hiç yapmıyordu.
class _FakeAuth implements AuthRepository {
  int signOuts = 0;
  int googleSignIns = 0;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Stream<User?> userChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInAnonymously() =>
      Completer<UserCredential>().future;

  @override
  Future<UserCredential> signInWithGoogle() {
    googleSignIns++;
    return Completer<UserCredential>().future;
  }

  @override
  Future<UserCredential> linkWithGoogle() => Completer<UserCredential>().future;

  @override
  Future<void> signOut() async => signOuts++;
}

void main() {
  Future<_FakeAuth> pumpSheet(WidgetTester tester) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          incomingFriendRequestsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          premiumProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAccountSheet(context),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('levhadan "Oturumu kapat" onaylanınca çıkış yapılır', (
    tester,
  ) async {
    final auth = await pumpSheet(tester);
    await tester.tap(find.byKey(const ValueKey('account-sign-out')));
    // Levha kapanır, onay diyaloğu açılır.
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('levhadan "Hesap değiştir": çıkış + Google seçici', (
    tester,
  ) async {
    final auth = await pumpSheet(tester);
    await tester.tap(find.byKey(const ValueKey('account-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(auth.googleSignIns, 1);
    expect(tester.takeException(), isNull);
  });
}
