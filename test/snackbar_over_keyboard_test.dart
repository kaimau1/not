import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/core/widgets/undo_snackbar.dart';

/// Cihaz turu kök nedeni (2026-11-05): `resizeToAvoidBottomInset: false`
/// ekranlarda bildirim klavyenin arkasında kalıyordu.
void main() {
  const keyboard = 400.0;

  Future<void> pump(WidgetTester tester, {required bool resizes}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: Scaffold(
          resizeToAvoidBottomInset: resizes,
          body: const TextField(autofocus: true),
        ),
      ),
    );
    await tester.pump();
  }

  Future<double> showAndMeasure(
    WidgetTester tester,
    void Function(ScaffoldMessengerState) show,
  ) async {
    show(tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return tester.getRect(find.byType(Material).last).bottom;
  }

  testWidgets('düz bildirim klavyenin üstünde', (tester) async {
    await pump(tester, resizes: false);
    await showAndMeasure(tester, (m) => m.showMessage('mesaj'));
    expect(
      tester.getBottomLeft(find.text('mesaj')).dy,
      lessThanOrEqualTo(800 - keyboard),
    );
  });

  testWidgets('eylemli bildirim klavyenin üstünde', (tester) async {
    await pump(tester, resizes: false);
    await showAndMeasure(
      tester,
      (m) => m.showMessage(
        'mesaj',
        action: SnackBarAction(label: 'Aç', onPressed: () {}),
      ),
    );
    expect(
      tester.getBottomLeft(find.text('Aç')).dy,
      lessThanOrEqualTo(800 - keyboard),
    );
  });

  testWidgets('klavyeyi kendi hesaplayan ekranda boşluk iki kez eklenmez', (
    tester,
  ) async {
    await pump(tester, resizes: true);
    await showAndMeasure(tester, (m) => m.showMessage('mesaj'));
    // Klavyenin hemen üstünde: iki katı (klavye + boşluk) kadar yükselmez.
    expect(
      tester.getBottomLeft(find.text('mesaj')).dy,
      greaterThan(800 - keyboard - 80),
    );
  });

  // P62 PA5: uygulamada iletiler bildirim şeridinde (Navigator'ın üstünde);
  // klavye payı Scaffold'dan bağımsız, doğrudan viewInsets.
  Future<void> pumpHosted(WidgetTester tester, {required double inset}) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: inset);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppNoticeHost(child: child!),
        home: const Scaffold(
          resizeToAvoidBottomInset: false,
          body: TextField(autofocus: true),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('şeritte düz ve eylemli ileti klavyenin üstünde', (tester) async {
    await pumpHosted(tester, inset: keyboard);
    final m = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    );
    m.showMessage('mesaj');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getBottomLeft(find.text('mesaj')).dy,
      lessThanOrEqualTo(800 - keyboard),
    );
    m.showMessage(
      'mesaj2',
      action: SnackBarAction(label: 'Aç', onPressed: () {}),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      tester.getBottomLeft(find.text('Aç')).dy,
      lessThanOrEqualTo(800 - keyboard),
    );
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('şeritte klavyesiz ekranda ileti dipte', (tester) async {
    await pumpHosted(tester, inset: 0);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .showMessage('mesaj');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.getBottomLeft(find.text('mesaj')).dy, greaterThan(800 - 80));
    await tester.pump(const Duration(seconds: 5));
  });
}
