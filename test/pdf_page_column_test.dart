import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_column.dart';

/// F65.8 (kullanıcı 2026-11-09: "sayfa sayfa değil; bütün sayfalar alt alta,
/// yalnız kaydırıyoruz. Sağa-sola kaydırmayı kaldır. Sayfa sayısı sağ altta
/// ufak yazsın"). Sabit bölmenin belgesi artık TEMBEL dikey sütun: uzun
/// PDF'te canlı sayfa sayısı (bellek + kare maliyeti) belge boyuyla
/// büyümemeli, sayfa numarası kaydırma DURUNCA yazılmalı.
void main() {
  const width = 400.0, height = 700.0;
  double a4(int _) => 1.41;

  group('sayfa geometrisi', () {
    test('sayfa başı ve ortadaki sayfa birbirini tutar', () {
      for (final page in [1, 2, 150, 300]) {
        final top = pdfColumnOffset(page, width, a4);
        expect(pdfColumnPageAt(top, height, width, 300, a4), page);
      }
    });

    test('karışık boylu belgede de (yatay sayfa araya girince)', () {
      double mixed(int i) => i == 3 ? 0.7 : 1.41;
      final top = pdfColumnOffset(6, width, mixed);
      expect(top, closeTo(4 * (400 * 1.41 + 8) + (400 * 0.7 + 8), 0.01));
      expect(pdfColumnPageAt(top, height, width, 10, mixed), 6);
    });

    test('sınırlar: baş 1, son sayfadan öte son', () {
      expect(pdfColumnPageAt(0, height, width, 3, a4), 1);
      expect(pdfColumnPageAt(1e9, height, width, 3, a4), 3);
      expect(pdfColumnPageAt(0, height, width, 0, a4), 1);
    });
  });

  testWidgets('300 sayfa: canlı sayfa sayısı sabit, numara durunca yazılır', (
    tester,
  ) async {
    final live = <int>{};
    var maxLive = 0;
    final changed = <int>[];
    final settled = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: PdfPageColumn(
              count: 300,
              initialPage: 1,
              ratioOf: a4,
              onPageChanged: changed.add,
              onPageSettled: settled.add,
              itemBuilder: (context, i) => _Counted(index: i, live: live),
            ),
          ),
        ),
      ),
    );
    maxLive = live.length;
    for (var i = 0; i < 12; i++) {
      await tester.fling(
        find.byType(PdfPageColumn),
        const Offset(0, -900),
        4000,
      );
      for (var f = 0; f < 30; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (live.length > maxLive) maxLive = live.length;
      }
      await tester.pumpAndSettle();
    }
    // Görünür ±2 sayfa; 300 sayfanın hepsi değil.
    expect(maxLive, lessThanOrEqualTo(5));
    expect(changed, isNotEmpty);
    expect(changed.last, greaterThan(20));
    // Her kare değil, her duruş: 12 fırlatma → en çok 12 yazım.
    expect(settled.length, lessThanOrEqualTo(12));
    expect(settled.last, changed.last);
  });

  testWidgets('başlangıç sayfası ve atlama (yer imi, 📖 s.N)', (tester) async {
    final key = GlobalKey<PdfPageColumnState>();
    final settled = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: PdfPageColumn(
              key: key,
              count: 300,
              initialPage: 120,
              ratioOf: a4,
              onPageSettled: settled.add,
              itemBuilder: (context, i) => Text('s${i + 1}'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('s120'), findsOneWidget);
    expect(find.text('s1'), findsNothing);
    key.currentState!.showPage(250);
    await tester.pumpAndSettle();
    expect(find.text('s250'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('s250')).dy,
      closeTo(tester.getTopLeft(find.byType(PdfPageColumn)).dy, 1),
    );
  });

  testWidgets('sayfa hapı: "12 / 240", soluklaşma Opacity katmanı değil', (
    tester,
  ) async {
    final page = ValueNotifier(12);
    final lit = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PdfPagePill(page: page, count: 240, lit: lit),
        ),
      ),
    );
    expect(find.text('12 / 240'), findsOneWidget);
    page.value = 13;
    lit.value = false;
    await tester.pumpAndSettle();
    expect(find.text('13 / 240'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PdfPagePill),
        matching: find.byWidgetPredicate(
          (w) => w is Opacity || w is AnimatedOpacity || w is FadeTransition,
        ),
      ),
      findsNothing,
    );
  });

  test('sabit bölme: sütun kurulur, yana çevirme ve ‹ n/N › yok', () {
    final box = File('lib/features/notes/presentation/editor/pdf_page_box.dart')
        .readAsStringSync();
    expect(box.contains('PdfPageColumn('), isTrue);
    expect(box.contains('PdfPagePill('), isTrue);
    // Eski dikey çekişle sayfa geçişi (KALEM K1) ve çubuktaki gezinme.
    expect(box.contains('_onPageScroll'), isFalse);
    expect(box.contains("'pinned-pdf-prev'"), isFalse);
    expect(box.contains("'pinned-pdf-next'"), isFalse);
  });
}

class _Counted extends StatefulWidget {
  const _Counted({required this.index, required this.live});
  final int index;
  final Set<int> live;

  @override
  State<_Counted> createState() => _CountedState();
}

class _CountedState extends State<_Counted> {
  @override
  void initState() {
    super.initState();
    widget.live.add(widget.index);
  }

  @override
  void dispose() {
    widget.live.remove(widget.index);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white);
}
