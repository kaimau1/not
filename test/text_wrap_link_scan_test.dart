import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/link_text.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

void main() {
  testWidgets(
    'T8 (K-28): tek uzun düz paragrafta açılış ve 5 tuşta bağlantı regex taraması 0 kez çalışır',
    (tester) async {
      final base =
          'Bu uzun paragraf 14.30 civarında hız ölçümü için yazıldı. ' * 200;
      final controller = WrapTextController(text: base);
      addTearDown(controller.dispose);

      debugLinkRegexCalls = 0;
      debugLinkRegexChars = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller, maxLines: null),
          ),
        ),
      );

      // Açılış + 5 tuş (ÖNCE: 6 tam paragraf regex taraması = ~69.615 karakter;
      // SONRA: 0 regex çağrısı, 0 karakter).
      for (var i = 0; i < 5; i++) {
        controller.text = '${controller.text}a';
        await tester.pump();
      }

      expect(debugLinkRegexCalls, 0);
      expect(debugLinkRegexChars, 0);
    },
  );

  testWidgets(
    'T8 (K-28): bağlantılı ve biçimli tek uzun paragrafta yalnız aday token taranır ve ikinci geçiş önbellekten döner',
    (tester) async {
      const url = 'https://ornek.com.tr/rapor';
      final base =
          '${'Bu uzun paragraf 14.30 civarında hız ölçümü için yazıldı. ' * 200}'
          '**önemli** kaynak $url adresindedir ';
      final controller = WrapTextController(text: base);
      addTearDown(controller.dispose);

      debugLinkRegexCalls = 0;
      debugLinkRegexChars = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(controller: controller, maxLines: null),
          ),
        ),
      );

      // İlk çizimde _scanPlainness + _paragraphSpan (linkSpans) aynı paragrafı
      // iki kez sorar: tek girişlik önbellekle regex yalnız 1 kez ve yalnız
      // 26 karakterlik URL token'ı üzerinde koşar (ÖNCE: 2 çağrı, ~23.300 karakter).
      expect(debugLinkRegexCalls, 1);
      expect(debugLinkRegexChars, url.length);

      for (var i = 0; i < 5; i++) {
        controller.text = '${controller.text}a';
        await tester.pump();
      }

      // Açılış + 5 tuş toplamı:
      // ÖNCE: 12 tam paragraf regex çağrısı (~139.800 karakter).
      // SONRA: 6 token regex çağrısı (6 × 26 = 156 karakter).
      expect(debugLinkRegexCalls, 6);
      expect(debugLinkRegexChars, 6 * url.length);

      // Görünüş girdileri değişmeden copyLooksFrom çağrıldığında önbellek silinmez.
      final mirror = WrapTextController(text: controller.text);
      addTearDown(mirror.dispose);
      mirror.copyLooksFrom(controller);
      final element = tester.element(find.byType(TextField));
      mirror.buildTextSpan(context: element, withComposing: false);
      final callsAfterFirstMirror = debugLinkRegexCalls;
      mirror.copyLooksFrom(controller);
      mirror.buildTextSpan(context: element, withComposing: false);
      expect(debugLinkRegexCalls, callsAfterFirstMirror);
    },
  );
}
