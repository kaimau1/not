import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/app_notice.dart';
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
        builder: (context, child) => AppNoticeHost(child: child!),
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
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('show: şerit doluyken ipucu ertelenir, gösterildi SAYILMAZ', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppNoticeHost(child: child!),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    appNotice.show(const AppNoticeData(text: 'Kaydedildi'));
    await tester.pump();
    expect(TipOnce.show(ctx, prefs, TipOnce.gridSwipe, 'İpucu B'), isFalse);
    expect(TipOnce.due(prefs, TipOnce.gridSwipe), isTrue);
    // Ertelendi: ileti kalkınca kendiliğinden çıkar ve o zaman sayılır.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('İpucu B'), findsOneWidget);
    expect(TipOnce.due(prefs, TipOnce.gridSwipe), isFalse);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('KW-18: ertelenen ipucu sayfası arkada kalınca çıkmaz', (
    tester,
  ) async {
    late BuildContext ctx;
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        builder: (context, child) => AppNoticeHost(child: child!),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    appNotice.show(const AppNoticeData(text: 'Kaydedildi'));
    await tester.pump();
    expect(TipOnce.show(ctx, prefs, TipOnce.gridSwipe, 'İpucu D'), isFalse);
    // Kullanıcı başka sayfaya geçti (ör. /privacy).
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.text('İpucu D'), findsNothing);
    expect(TipOnce.due(prefs, TipOnce.gridSwipe), isTrue, reason: 'sayılmaz');
    await tester.pumpAndSettle();
  });

  testWidgets('show: şerit yokken (yalın test) false, sayılmaz', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(TipOnce.show(ctx, prefs, TipOnce.mediaPin, 'İpucu C'), isFalse);
    expect(TipOnce.due(prefs, TipOnce.mediaPin), isTrue);
  });

  testWidgets('tips_enabled kapalıyken hiçbir ipucu çıkmaz ve sayılmaz', (
    tester,
  ) async {
    await prefs.setBool(TipOnce.enabledKey, false);
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppNoticeHost(child: child!),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(TipOnce.due(prefs, TipOnce.formatScope), isFalse);
    expect(
      TipOnce.show(
        ctx,
        prefs,
        TipOnce.formatScope,
        'Biçim ipucu',
        sessionLimit: false,
      ),
      isFalse,
    );
    await tester.pump();
    expect(find.text('Biçim ipucu'), findsNothing);
    await prefs.setBool(TipOnce.enabledKey, true);
    expect(TipOnce.due(prefs, TipOnce.formatScope), isTrue);
  });

  testWidgets('90 sn bekleme süresi ardışık ipuçlarını yumuşatır', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppNoticeHost(child: child!),
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(
      TipOnce.show(
        ctx,
        prefs,
        TipOnce.formatScope,
        'İpucu 1',
        sessionLimit: false,
      ),
      isTrue,
    );
    await tester.pump();
    expect(find.text('İpucu 1'), findsOneWidget);
    // Aynı 90 sn içinde ikinci genel ipucu beklemeye alınır / çıkmaz.
    expect(
      TipOnce.show(
        ctx,
        prefs,
        TipOnce.tableGestures,
        'İpucu 2',
        sessionLimit: false,
      ),
      isFalse,
    );
    expect(
      TipOnce.due(prefs, TipOnce.tableGestures, sessionLimit: false),
      isTrue,
    );
    // 90 sn geçmiş gibi işaretlendiğinde sıradaki ipucu çıkabilir.
    TipOnce.lastShownAt = DateTime.now().subtract(
      TipOnce.minGap + const Duration(seconds: 1),
    );
    await tester.pump(const Duration(seconds: 6));
    expect(
      TipOnce.show(
        ctx,
        prefs,
        TipOnce.tableGestures,
        'İpucu 2',
        sessionLimit: false,
      ),
      isTrue,
    );
    await tester.pump();
    expect(find.text('İpucu 2'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}
