import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_design.dart';
import 'package:notlar/core/widgets/app_banner.dart';

/// Kalıcı şeridin tek kılığı (P62 PA6, plan_tasarim_A §5.4).
void main() {
  Future<void> pump(WidgetTester tester, Widget banner) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: banner),
      ),
    ),
  );

  testWidgets('detail: başlıkla aynı satırda, tek satır, tam 44 dp', (
    tester,
  ) async {
    await pump(
      tester,
      AppBanner(
        key: const ValueKey('b'),
        title: 'Çok uzun bir hatırlatma başlığı ' * 4,
        detail: '5 Kas 15:17',
        icon: Icons.alarm_rounded,
        tone: AppTone.attention,
        trailing: IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () {},
          icon: const Icon(Icons.close_rounded),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const ValueKey('b'))).height, 44);
    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('5 Kas 15:17'),
      ),
    );
    expect(rich.maxLines, 1);
  });

  testWidgets('renk yalnız tondan; ilerleme çizgisi dipte', (tester) async {
    await pump(
      tester,
      const AppBanner(
        key: ValueKey('b'),
        title: 'Yeni sürüm iniyor',
        tone: AppTone.danger,
        progress: 0.4,
      ),
    );
    final scheme = Theme.of(tester.element(find.byKey(const ValueKey('b'))))
        .colorScheme;
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(const ValueKey('b')),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, AppTone.danger.colors(scheme).bg);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(AnimatedSize), findsNothing);
  });
}
