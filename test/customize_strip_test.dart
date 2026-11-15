import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P63 PB1 (plan_tasarim_B §1.2 "yerinde mod"): düzen modu şeridi tek satır,
/// "Sırala" düğmesi, gizli sayısı hapı, hareketi azalt; mod kapalıyken
/// `Customizable` çıplak çocuk döndürür.
void main() {
  setUp(() {
    Personalize.debugReset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(Personalize.debugReset);

  var reorders = 0;

  Widget app(Widget home, {bool reduceMotion = false}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(top: 24),
        disableAnimations: reduceMotion,
      ),
      child: CustomizeModeHost(onReorder: () => reorders++, child: child!),
    ),
    home: home,
  );

  const strip = ValueKey('customize-strip');
  const pill = ValueKey('customize-hidden-count');

  testWidgets('şerit tek satır: boy = üst güvenli alan + 48', (tester) async {
    await tester.pumpWidget(app(const Scaffold()));
    expect(find.byKey(strip), findsNothing);
    Personalize.startEditing();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(strip)).height, 24 + 48);
    // İkinci satır (ipucu) yok.
    expect(
      find.text('Dokun: gizle ya da göster · anında uygulanır'),
      findsNothing,
    );
  });

  testWidgets('"Sırala" düğmesi var ve geri çağrıyı çalıştırır', (
    tester,
  ) async {
    reorders = 0;
    await tester.pumpWidget(app(const Scaffold()));
    Personalize.startEditing();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('customize-reorder')));
    await tester.pump();
    expect(reorders, 1);
  });

  testWidgets('gizli sayısı hapı yalnız sayı > 0 iken', (tester) async {
    await tester.pumpWidget(app(const Scaffold()));
    Personalize.startEditing();
    await tester.pumpAndSettle();
    expect(find.byKey(pill), findsNothing);
    Personalize.toggle('x');
    await tester.pumpAndSettle();
    expect(find.byKey(pill), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(pill), matching: find.text('1')),
      findsOneWidget,
    );
  });

  testWidgets('hareketi azalt: giriş ≤ 150 ms, Bitti sonrası şerit kalkar', (
    tester,
  ) async {
    await tester.pumpWidget(app(const Scaffold(), reduceMotion: true));
    Personalize.startEditing();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final fade = tester.widget<FadeTransition>(
      find
          .descendant(
            of: find.byKey(strip),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    await tester.tap(find.byKey(const ValueKey('customize-done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 151));
    await tester.pump();
    expect(find.byKey(strip), findsNothing);
  });

  testWidgets('mod kapalıyken Customizable çıplak çocuk (sarmalayıcı yok)', (
    tester,
  ) async {
    const child = Text('düğme');
    await tester.pumpWidget(
      app(
        const Center(
          child: Customizable(id: 'a', child: child),
        ),
      ),
    );
    final el = tester.element(find.byWidget(child));
    Element? parent;
    el.visitAncestorElements((e) {
      parent = e;
      return false;
    });
    expect(parent!.widget, isA<Customizable>());
  });

  // Konfor (2026-11-15): küçük telefonda (360 dp, tur "telefon-kucuk")
  // başlık "Düzenlem…" diye kesiliyordu. Sığmayınca kısa etiket; tam ad
  // erişilebilirlik etiketinde.
  testWidgets('küçük telefonda başlık kesilmez, tam ad semantikte', (
    tester,
  ) async {
    // Testin kutu yazısı (her harf 1 em) gerçekten ~2 kat geniş: ölçü
    // gerçekçi olsun diye SDK'nın Roboto'su yüklenir (tur da böyle).
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
    for (final w in ['Regular', 'Medium', 'Bold']) {
      final f = File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
      if (!f.existsSync()) continue;
      await (FontLoader('Roboto')
            ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync()))))
          .load();
    }
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const Scaffold()));
    Personalize.startEditing();
    Personalize.toggle('x'); // gizli sayısı hapı da yer kaplasın
    await tester.pumpAndSettle();
    final title = find.descendant(
      of: find.byKey(const ValueKey('customize-title')),
      matching: find.byType(RichText),
    );
    expect(title, findsOneWidget);
    final p = tester.renderObject<RenderParagraph>(title);
    expect(p.didExceedMaxLines, isFalse, reason: 'üç noktayla kesilmesin');
    final label = tester.widget<Semantics>(
      find.descendant(
        of: find.byKey(const ValueKey('customize-title')),
        matching: find.byType(Semantics),
      ).first,
    );
    expect(label.properties.label, 'Düzenleme modu');
    expect(label.excludeSemantics, isTrue);
  });
}
