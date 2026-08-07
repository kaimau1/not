import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/auth/presentation/login_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İLK AÇILIŞTA GİRİŞ İTİLMEZ (kullanıcı isteği 2026-08-07).
///
/// Giriş ekranı ilk açılışta kendiliğinden yerel (anonim) oturum açmayı dener;
/// başarılıysa kullanıcı hiç düğmeye dokunmadan notlara girer. Deneme prefs'e
/// işaretlenir: hesabından ÇIKAN kullanıcı yeniden anonim oturuma sokulmamalı,
/// yoksa Google ile hiç giremezdi.
///
/// İkinci bir güvence: anonim giriş Firebase konsolunda kapalıyken gelen
/// `admin-restricted-operation` ham hâliyle değil, ne yapılacağını söyleyen
/// bir metinle gösterilir.
class _FakeAuth implements AuthRepository {
  _FakeAuth({this.error});

  /// signInAnonymously bunu fırlatır (null ise çağrı asla tamamlanmaz —
  /// başarılı girişte ekran zaten yönlendirmeyle kapanır).
  final Object? error;

  int anonymousCalls = 0;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInAnonymously() {
    anonymousCalls++;
    if (error != null) return Future.error(error!);
    return Completer<UserCredential>().future;
  }

  @override
  Future<UserCredential> signInWithGoogle() =>
      Completer<UserCredential>().future;

  @override
  Future<UserCredential> linkWithGoogle() => Completer<UserCredential>().future;

  @override
  Future<void> signOut() async {}
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpLogin(WidgetTester tester, _FakeAuth auth) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('ilk açılış: giriş ekranı gösterilmeden anonim oturum denenir', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await pumpLogin(tester, auth);

    expect(auth.anonymousCalls, 1);
    // Deneme sürerken düğme çizilmez: kullanıcı bir an görüp dokunamayacağı
    // bir giriş ekranıyla karşılaşmasın.
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(prefs.getBool('auto_guest_signin_tried'), isTrue);
  });

  testWidgets('çıkış yapan kullanıcı yeniden anonime sokulmaz', (tester) async {
    await prefs.setBool('auto_guest_signin_tried', true);
    final auth = _FakeAuth();
    await pumpLogin(tester, auth);

    expect(auth.anonymousCalls, 0);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('anonim giriş kapalıysa ham "admin" hatası değil, açıklama', (
    tester,
  ) async {
    final auth = _FakeAuth(
      error: FirebaseAuthException(code: 'admin-restricted-operation'),
    );
    await pumpLogin(tester, auth);
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(find.text(l10n.guestSignInUnavailable), findsOneWidget);
    expect(find.textContaining('admin-restricted-operation'), findsNothing);
    // Giriş yolları geri gelir: kullanıcı Google ile devam edebilmeli.
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
