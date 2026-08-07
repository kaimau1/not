import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/presentation/editor/format_menu.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// BEKLEYEN BİÇİMİN CANLI ÖNİZLEMESİ.
///
/// KULLANICI (2026-08-07): "biçimli yazmada bir çok sorun oluştu yine
/// markdownlar çıkıyor ayrıca kalın butonuna basıp kalın yazamıyorum mesela —
/// Word'daki gibi olmalı."
///
/// Word'de "kalın"a basmak imleci O AN kalınlaştırır; yazılan her harf kalın
/// çıkar. Bizde biçim metnin İÇİNDE işaretle taşındığı için (bkz.
/// rich_text.dart dosya başlığı) işaretler tampona ancak koşu bitince
/// yazılabiliyor — yoksa Gboard'la yarışıp eşi olmayan ham markdown üretiyor.
/// Aradaki boşluğu ÇİZİM kapatır: koşunun aralığı ekranda biçimli çizilir,
/// tampona hiç dokunulmadan.
///
/// Bu dosya iki şeyi birden kilitler: (a) düz metin uzunluğu DEĞİŞMEZ —
/// imleç/seçim konumları buna bağlı, (b) aralık gerçekten biçimli çizilir.
void main() {
  /// [span] ağacının düz metni.
  String plainOf(InlineSpan span) {
    final buffer = StringBuffer();
    span.visitChildren((child) {
      if (child is TextSpan && child.text != null) buffer.write(child.text);
      return true;
    });
    return buffer.toString();
  }

  /// [span] ağacında [needle] metnini taşıyan parçanın stili.
  TextStyle? styleOf(InlineSpan span, String needle) {
    TextStyle? found;
    span.visitChildren((child) {
      if (child is TextSpan && child.text == needle) {
        found = child.style;
        return false;
      }
      return true;
    });
    return found;
  }

  group('restyleRange', () {
    test('düz metin uzunluğu DEĞİŞMEZ (imleç konumları buna bağlı)', () {
      const span = TextSpan(text: 'merhaba dunya');
      final out = restyleRange(
        span,
        0,
        7,
        (s) => (s ?? const TextStyle()).copyWith(fontWeight: FontWeight.w700),
      );
      expect(plainOf(out), 'merhaba dunya');
    });

    test('yalnız aralık biçimlenir, gerisi dokunulmaz kalır', () {
      const span = TextSpan(text: 'merhaba dunya');
      final out = restyleRange(
        span,
        0,
        7,
        (s) => (s ?? const TextStyle()).copyWith(fontWeight: FontWeight.w700),
      );
      expect(styleOf(out, 'merhaba')?.fontWeight, FontWeight.w700);
      expect(styleOf(out, ' dunya')?.fontWeight, isNot(FontWeight.w700));
    });

    test('çocukları olan ağaçta da uzunluk korunur', () {
      const span = TextSpan(
        children: [
          TextSpan(text: 'bir '),
          TextSpan(text: 'iki '),
          TextSpan(text: 'uc'),
        ],
      );
      final out = restyleRange(
        span,
        2,
        6,
        (s) => (s ?? const TextStyle()).copyWith(fontStyle: FontStyle.italic),
      );
      expect(plainOf(out), 'bir iki uc');
    });

    test('boş aralık hiçbir şey değiştirmez', () {
      const span = TextSpan(text: 'abc');
      expect(identical(restyleRange(span, 2, 2, (s) => s!), span), isTrue);
    });
  });

  group('canlı önizleme', () {
    late WrapTextController controller;

    setUp(() {
      controller = WrapTextController()
        ..selection = const TextSelection.collapsed(offset: 0)
        ..richTheme = const RichTextTheme(
          palette: [Colors.red, Colors.green, Colors.blue],
          markerColor: Colors.grey,
        );
    });

    void type(String typed) {
      final caret = controller.selection.baseOffset;
      controller.value = TextEditingValue(
        text: controller.text.replaceRange(caret, caret, typed),
        selection: TextSelection.collapsed(offset: caret + typed.length),
      );
    }

    testWidgets('"kalın"a basıp yazınca harfler HEMEN kalın çizilir', (
      tester,
    ) async {
      applyRichFormat(controller, RichFormat.bold);
      type('merhaba');

      // Tamponda işaret YOK (IME ile yarışılmıyor).
      expect(controller.logicalText, 'merhaba');

      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      // ...ama EKRANDA kalın.
      expect(plainOf(span), 'merhaba');
      expect(styleOf(span, 'merhaba')?.fontWeight, FontWeight.w700);
    });

    testWidgets('biçim bekleMEYEN metin olduğu gibi çizilir', (tester) async {
      type('merhaba');
      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(plainOf(span), 'merhaba');
      expect(styleOf(span, 'merhaba')?.fontWeight, isNot(FontWeight.w700));
    });

    testWidgets('önizleme yalnız KOŞUYU kaplar, önceki metni değil', (
      tester,
    ) async {
      type('duz ');
      applyRichFormat(controller, RichFormat.bold);
      type('kalin');
      expect(controller.pendingRange, (4, 9));

      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                style: const TextStyle(fontSize: 16),
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(plainOf(span), 'duz kalin');
      expect(styleOf(span, 'kalin')?.fontWeight, FontWeight.w700);
      expect(styleOf(span, 'duz ')?.fontWeight, isNot(FontWeight.w700));
    });
  });
}
