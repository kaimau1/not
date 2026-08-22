import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';

/// [KeyboardSnap] + [KeyboardSlide] ikilisi klavye açılıp kapanırken HAREKET
/// ile YERLEŞİMİ ayırır: çubuk kare kare (yalnız boyayarak) kayar, gövde ise
/// animasyon boyunca hiç ölçülmez. Testler ikisini birden doğruluyor —
/// "zıplama" ve "kasma" kusurlarının ikisi de bu ayrımın bozulmasından
/// doğuyordu (bkz. widget açıklamaları).
void main() {
  const screen = Size(800, 600);
  const barHeight = 60.0;

  Widget host(double live, Widget child) => MediaQuery(
    data: MediaQueryData(
      size: screen,
      viewInsets: EdgeInsets.only(bottom: live),
    ),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );

  /// Gerçek editördeki kuruluşun küçültülmüş hâli: gövde `Expanded`, çubuk
  /// [KeyboardSlide] ile sarılı ve `builder`ın DIŞINDA kurulmuş.
  Widget page(Widget bar, {ValueChanged<double>? onBuild}) => KeyboardSnap(
    builder: (context, inset) {
      onBuild?.call(inset);
      return Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Column(
          children: [
            const Expanded(child: SizedBox.expand(key: Key('body'))),
            KeyboardSlide(inset: inset, child: bar),
          ],
        ),
      );
    },
  );

  final bar = Container(
    key: const Key('bar'),
    height: barHeight,
    width: double.infinity,
    color: const Color(0xFFFF0000),
  );

  double barBottom(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('bar'))).bottom;

  testWidgets('çubuk HER karede klavyenin üstünde durur (kademe/zıplama yok)', (
    tester,
  ) async {
    await tester.pumpWidget(host(0, page(bar)));
    expect(barBottom(tester), screen.height);

    // Açılış animasyonu: ara değerler kademelenmeden birebir izlenir. Eski
    // sürüm bunları 96 dp'ye yuvarladığı için çubuk sıçraya sıçraya
    // çıkıyordu — kullanıcının bildirdiği zıplama buydu.
    for (final live in [12.0, 57.0, 133.0, 244.0, 300.0]) {
      await tester.pumpWidget(host(live, page(bar)));
      expect(
        barBottom(tester),
        screen.height - live,
        reason: '$live dp klavyede çubuk tam klavyenin üstünde olmalı',
      );
    }

    // Animasyon durdu: gövde şimdi ölçülür ama çubuk KIPIRDAMAZ. Oturma anı
    // ekranda görünmemeli — asıl önemli olan bu.
    await tester.pump(const Duration(milliseconds: 200));
    expect(barBottom(tester), screen.height - 300);

    // Kapanış: yine kare kare, sıçramasız.
    for (final live in [244.0, 133.0, 57.0, 12.0, 0.0]) {
      await tester.pumpWidget(host(live, page(bar)));
      expect(barBottom(tester), screen.height - live);
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(barBottom(tester), screen.height);
  });

  testWidgets('gövde animasyon boyunca ölçülmez, klavye durunca oturur', (
    tester,
  ) async {
    final insets = <double>[];
    // AYNI widget örneği: gerçek ekranda da klavye oynarken editörün kendisi
    // yeniden kurulmuyor.
    final snap = page(bar, onBuild: insets.add);

    await tester.pumpWidget(host(0, snap));
    expect(insets, [0]);

    // Açılışın bütün ara kareleri: gövde TEK BİR KEZ bile yeniden kurulmaz.
    for (final live in [12.0, 57.0, 133.0, 244.0, 300.0]) {
      await tester.pumpWidget(host(live, snap));
    }
    expect(insets, [0], reason: 'açılış animasyonunda gövde yerleşimi yok');

    // Klavye durdu → tek ölçüm, gerçek yükseklikle.
    await tester.pump(const Duration(milliseconds: 200));
    expect(insets, [0, 300]);

    // Kapanışın İLK karesinde gövde tam boya döner (açılacak alan boş değil,
    // içeriğiyle ortaya çıksın diye) ve kapanış boyunca bir daha ölçülmez.
    for (final live in [244.0, 133.0, 57.0, 12.0, 0.0]) {
      await tester.pumpWidget(host(live, snap));
    }
    expect(insets, [0, 300, 0]);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      insets,
      [0, 300, 0],
      reason: 'tam açılış+kapanış çevrimi toplam ÜÇ yerleşim',
    );
  });

  testWidgets('klavye açıkken gövde klavyenin üstünde kalır', (tester) async {
    await tester.pumpWidget(host(0, page(bar)));
    await tester.pumpWidget(host(220, page(bar)));
    await tester.pump(const Duration(milliseconds: 200));

    // Gövde: ekran − klavye − çubuk.
    expect(
      tester.getSize(find.byKey(const Key('body'))).height,
      screen.height - 220 - barHeight,
    );
    expect(barBottom(tester), screen.height - 220);
  });

  testWidgets('boşluk oturunca onSettled ÇAĞRILIR (odaklı alan görünür kalsın)', (
    tester,
  ) async {
    final settled = <double>[];
    Widget build(double live) => host(
      live,
      KeyboardSnap(
        onSettled: settled.add,
        builder: (context, inset) => const SizedBox.expand(),
      ),
    );

    await tester.pumpWidget(build(0));
    await tester.pumpWidget(build(150));
    await tester.pumpWidget(build(300));
    expect(settled, isEmpty, reason: 'animasyon sürerken haber verilmez');

    await tester.pump(const Duration(milliseconds: 200));
    expect(settled, [300]);

    // Kapanışta boşluk zaten ilk karede kalkıyor; oturma diye bir şey yok.
    await tester.pumpWidget(build(0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(settled, [300]);
  });

  testWidgets('üst ekran yeniden kurulunca önbellek düşer (bayat ağaç yok)', (
    tester,
  ) async {
    var label = 'ilk';
    Widget build() =>
        host(0, KeyboardSnap(builder: (context, inset) => Text(label)));

    await tester.pumpWidget(build());
    expect(find.text('ilk'), findsOneWidget);

    label = 'ikinci';
    await tester.pumpWidget(build());
    expect(find.text('ikinci'), findsOneWidget);
  });

  testWidgets('KeyboardSlide farkı ÖTELEMEYLE kapatır, yerleşimi bozmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(180, const KeyboardSlide(inset: 300, child: SizedBox(height: 40))),
    );
    // Kararlı boşluk 300, canlı 180 → 120 dp AŞAĞI.
    expect(
      tester.getRect(find.byType(SizedBox)).top -
          tester.getRect(find.byType(KeyboardSlide)).top,
      120,
    );
  });
}
