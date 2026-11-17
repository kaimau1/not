import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/attachment_actions.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// T10 (S53 yazılırken görüldü): görsel açıklama levhası kapanırken
/// denetleyici `whenComplete` ile atılıyordu — gelecek `pop` anında biter,
/// levha ise kapanış animasyonu boyunca alanı yeniden çizer: atılmış
/// denetleyici kullanılıyordu (debug uyarısı). Denetleyici levhanın kendi
/// durumunda yaşar, rota kalkınca atılır.
void main() {
  testWidgets('onay: metin döner, kapanışta atılmış denetleyici yok', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    String? got;
    var done = false;
    unawaited(
      showCaptionSheet(ctx, 'eski').then((v) {
        got = v;
        done = true;
      }),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('caption-sheet-field')),
      '  yeni açıklama ',
    );
    await tester.tap(find.byKey(const ValueKey('caption-sheet-done')));
    // Kapanış animasyonu kare kare: her karede alan yeniden çizilir.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(done, isTrue);
    expect(got, 'yeni açıklama');
    expect(find.byKey(const ValueKey('caption-sheet-field')), findsNothing);
  });

  testWidgets('vazgeç (dışarı dokun): null döner, hata yok', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    String? got = 'x';
    unawaited(showCaptionSheet(ctx, 'eski').then((v) => got = v));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(got, isNull);
  });
}
