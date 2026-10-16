import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// "Program genelinde yazı yazarken FPS düşüşü" ve "görseller sürüklenirken
/// aşırı kasma" (kullanıcı 2026-10-16) — kök nedenlerin korumaları.
void main() {
  const style = TextStyle(fontSize: 16, height: 1.4);
  const para =
      'Bugün toplantıda konuşulanlar ve yapılacaklar listesi burada duruyor. ';
  final long = List.generate(80, (i) => '$para$para$i').join('\n');
  const floats = [FloatBox(top: 0, left: 180, right: 360, height: 200)];

  group('planTextWrap — yalnız bandı kapsayan önek ölçülür', () {
    test('uzun metinde plan bir önek taşır; bütün çapalar önekte', () {
      final plan = planTextWrap(
        logical: long,
        style: style,
        columnWidth: 360,
        floats: floats,
      );
      expect(plan.widths, isNotEmpty);
      expect(plan.frozenDisplay, greaterThan(0));
      expect(plan.frozenDisplay, lessThan(plan.display.length));
      // Önek bir paragraf sonunda biter.
      expect(plan.display[plan.frozenDisplay], '\n');
      // Önekten sonra çapa yok — bandın altı dolgu almaz.
      expect(
        plan.display.substring(plan.frozenDisplay).contains(kWrapAnchorChar),
        isFalse,
      );
      // Mantıksal karşılık doğru.
      expect(
        stripWrapAnchors(plan.display.substring(0, plan.frozenDisplay)),
        long.substring(0, plan.frozenLogical),
      );
    });

    test('bandın altına yazmak planı yeniden ÖLÇMEDEN kurar, sonuç aynı', () {
      final plan = planTextWrap(
        logical: long,
        style: style,
        columnWidth: 360,
        floats: floats,
      );
      final edited = '${long}x yeni satırın sonu';
      final reused = reuseWrapPlan(plan, long, edited);
      final fresh = planTextWrap(
        logical: edited,
        style: style,
        columnWidth: 360,
        floats: floats,
      );
      expect(reused, isNotNull);
      expect(reused!.display, fresh.display);
      expect(reused.widths, fresh.widths);
    });

    test('önekin İÇİNE yazmak yeniden kullanılmaz', () {
      final plan = planTextWrap(
        logical: long,
        style: style,
        columnWidth: 360,
        floats: floats,
      );
      expect(reuseWrapPlan(plan, long, 'X$long'), isNull);
      // Önekin sonundaki satır sonu silinirse de (paragraflar birleşir).
      final fl = plan.frozenLogical;
      final joined = long.replaceRange(fl, fl + 1, ' ');
      expect(reuseWrapPlan(plan, long, joined), isNull);
    });

    test('kısa metinde önek yok (metnin tamamı ölçülür)', () {
      final plan = planTextWrap(
        logical: 'kısa not',
        style: style,
        columnWidth: 360,
        floats: floats,
      );
      expect(plan.frozenDisplay, -1);
    });
  });

  testWidgets('paragraf önbelleği: span düz metni ve bağlantı rengi doğru', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final c = WrapTextController(
      text: 'ilk **kalın** satır\nikinci www.ornek.com\nüçüncü',
    )..richTheme = const RichTextTheme(
        palette: [Colors.red],
        markerColor: Colors.grey,
      );
    addTearDown(c.dispose);
    final link = Theme.of(ctx).colorScheme.primary;
    TextSpan build() => c.buildTextSpan(context: ctx, withComposing: false);

    bool hasColor(InlineSpan span, Color color, String text) {
      var found = false;
      span.visitChildren((s) {
        if (s is TextSpan && s.text == text && s.style?.color == color) {
          found = true;
        }
        return true;
      });
      return found;
    }

    expect(build().toPlainText(), c.text);
    expect(hasColor(build(), link, 'www.ornek.com'), isTrue);
    // İLK paragrafa yazınca öbür paragraflar önbellekten gelir — ama
    // çizim aynı kalmalı.
    c.value = TextEditingValue(
      text: 'ilk **kalın** satırX\nikinci www.ornek.com\nüçüncü',
      selection: const TextSelection.collapsed(offset: 20),
    );
    expect(build().toPlainText(), c.text);
    expect(hasColor(build(), link, 'www.ornek.com'), isTrue);
  });

  testWidgets('zaman damgası YALNIZ notta video varken bağlantı rengi alır', (
    tester,
  ) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final c = WrapTextController(text: 'giriş 1:23 burada');
    addTearDown(c.dispose);
    final link = Theme.of(ctx).colorScheme.primary;

    bool stampColored() {
      var found = false;
      c.buildTextSpan(context: ctx, withComposing: false).visitChildren((s) {
        if (s is TextSpan && s.text == '1:23' && s.style?.color == link) {
          found = true;
        }
        return true;
      });
      return found;
    }

    expect(stampColored(), isFalse);
    c.videoTimestamps = true;
    expect(stampColored(), isTrue);
    expect(
      c.buildTextSpan(context: ctx, withComposing: false).toPlainText(),
      c.text,
    );
  });
}
