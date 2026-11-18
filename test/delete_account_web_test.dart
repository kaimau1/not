import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/router.dart';
import 'package:notlar/features/settings/presentation/delete_account_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/l10n/generated/app_localizations_tr.dart';

/// PL4 bekçisi (16K E6): web'den hesap silme. `web/hesap-silme.html`
/// `/#/delete-account`'a bağlanır; oturum yoksa giriş, sonra yine silme
/// sayfası. Sayfa ayarlardaki AYNI onaylı silme akışını açar.
void main() {
  group('authRedirect', () {
    String? go(bool loggedIn, String location) {
      final uri = Uri.parse(location);
      return authRedirect(
        loggedIn: loggedIn,
        matchedLocation: uri.path,
        uri: uri,
      );
    }

    test('oturumsuz silme adresi → giriş, girişten sonra silme sayfası', () {
      expect(go(false, kDeleteAccountPath), '/login?next=$kDeleteAccountPath');
      expect(go(true, '/login?next=$kDeleteAccountPath'), kDeleteAccountPath);
    });

    test('öteki adresler eskisi gibi (açık yönlendirme yok)', () {
      expect(go(false, '/settings'), '/login');
      expect(go(false, '/login'), isNull);
      expect(go(true, '/login'), '/');
      expect(go(true, '/login?next=/settings'), '/');
      expect(go(true, '/login?next=https://kotu.example'), '/');
      expect(go(true, kDeleteAccountPath), isNull);
    });
  });

  testWidgets('silme sayfası ne silineceğini anlatır, onay ister', (
    tester,
  ) async {
    final l10n = AppLocalizationsTr();
    final router = GoRouter(
      initialLocation: kDeleteAccountPath,
      routes: [
        GoRoute(
          path: kDeleteAccountPath,
          builder: (context, state) => const DeleteAccountScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.deleteAccountPageInfo), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('delete-account-page-button')));
    await tester.pumpAndSettle();
    // Ayarlardaki onay penceresi; vazgeçince hiçbir şey silinmez.
    expect(find.text(l10n.deleteAccountWarning), findsOneWidget);
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.deleteAccountWarning), findsNothing);
  });
}
