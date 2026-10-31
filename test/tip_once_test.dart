import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/tips.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bir kez çıkan ipuçları (F14.6): her ipucu cihazda bir kez, oturumda en
/// fazla bir tane; az önce olanı açıklayan bildirim sınırı aşar.
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    TipOnce.resetSession();
  });

  test('gösterilen ipucu bir daha çıkmaz; oturumda tek ipucu', () {
    expect(TipOnce.due(prefs, TipOnce.listGestures), isTrue);
    TipOnce.markShown(prefs, TipOnce.listGestures);
    expect(TipOnce.due(prefs, TipOnce.listGestures), isFalse);
    // Başka ipucu bu oturumda bekler…
    expect(TipOnce.due(prefs, TipOnce.pdfBubble), isFalse);
    // …ama olayı açıklayan bildirim çıkar.
    expect(
      TipOnce.due(prefs, TipOnce.stylusCanvas, sessionLimit: false),
      isTrue,
    );
    // Yeni oturum: sıradaki ipucu gelir, gösterilen gelmez.
    TipOnce.resetSession();
    expect(TipOnce.due(prefs, TipOnce.pdfBubble), isTrue);
    expect(TipOnce.due(prefs, TipOnce.listGestures), isFalse);
  });

  test('"İpuçlarını yeniden göster" hepsini sıfırlar', () async {
    TipOnce.markShown(prefs, TipOnce.gridSwipe);
    await TipOnce.resetAll(prefs);
    expect(TipOnce.due(prefs, TipOnce.gridSwipe), isTrue);
  });

  testWidgets('show: tek satır bildirim, ikinci çağrıda yok', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(TipOnce.show(ctx, prefs, TipOnce.mediaPin, 'İpucu A'), isTrue);
    await tester.pump();
    expect(find.text('İpucu A'), findsOneWidget);
    TipOnce.resetSession();
    expect(TipOnce.show(ctx, prefs, TipOnce.mediaPin, 'İpucu A'), isFalse);
  });
}
