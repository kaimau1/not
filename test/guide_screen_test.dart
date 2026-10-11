import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/presentation/guide_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Uygulama içi KULLANIM KILAVUZU (2026-10-11).
void main() {
  test('ayrıştırıcı: giriş, bölüm, alt başlık, madde, adım, kalın', () {
    final g = parseGuide('''
# Başlık
Giriş paragrafı.

## İlk bölüm {#bir}
Paragraf **kalın** yazı.
### Alt
- madde
1. adım bir
2. adım iki
## İkinci {#iki}
- tek
''');
    expect(g.intro.single.text, 'Giriş paragrafı.');
    expect(g.sections.map((s) => s.id), ['bir', 'iki']);
    final blocks = g.sections.first.blocks;
    expect(blocks.map((b) => b.kind), [
      GuideBlockKind.paragraph,
      GuideBlockKind.subheading,
      GuideBlockKind.bullet,
      GuideBlockKind.step,
      GuideBlockKind.step,
    ]);
    expect(blocks[4].number, 2);
    final spans = guideInlineSpans('a **b** c', const TextStyle());
    expect(spans.map((s) => s.text), ['a ', 'b', ' c']);
  });

  test('her dilin kılavuzu AYNI bölümleri aynı sırayla taşır', () {
    final files = Directory('assets/guide')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    expect(files.length, greaterThanOrEqualTo(2));
    final reference = parseGuide(
      File('assets/guide/guide_tr.md').readAsStringSync(),
    ).sections.map((s) => s.id).toList();
    expect(reference, contains('pages'));
    expect(reference, contains('embed'));
    for (final f in files) {
      final ids = parseGuide(
        f.readAsStringSync(),
      ).sections.map((s) => s.id).toList();
      expect(ids, reference, reason: f.path);
      // Bilinmeyen kimlik genel simgeye düşerdi: her bölümün simgesi var.
      for (final id in ids) {
        expect(
          guideSectionMeta(id).icon,
          isNot(Icons.article_outlined),
          reason: id,
        );
      }
    }
  });

  Future<void> pump(WidgetTester tester, {String? section}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: GuideScreen(initialSection: section),
      ),
    );
    // Kılavuz dosyası gerçek G/Ç ile okunur (rootBundle): sahte saat
    // ilerletmek yetmez, okumanın bitmesi beklenir.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('içindekiler bölümü açar, arama süzer', (tester) async {
    await pump(tester);
    expect(find.text('Kullanım kılavuzu'), findsOneWidget);
    // Bölümler kapalı başlar.
    expect(find.textContaining('Başlığın altında'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('guide-chip-pages')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Başlığın altında', findRichText: true),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('guide-search')),
      'youtube',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guide-section-video')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide-section-reminders')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('guide-search')),
      'zzzyok',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('zzzyok'), findsWidgets);
  });

  testWidgets('bölüm parametresiyle o bölüm açık gelir', (tester) async {
    await pump(tester, section: 'embed');
    expect(
      find.textContaining('Gömmeyi kaldır', findRichText: true),
      findsWidgets,
    );
  });
}
