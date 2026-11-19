import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/user_templates.dart';
import 'package:notlar/features/notes/domain/note_templates.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_template_sheet.dart';
import 'package:notlar/features/notes/presentation/template_preview_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P63 PB4 (plan_tasarim_B §2.4): kart minyatürü ve sabit "Oluştur" bandı.
void main() {
  Future<void> open(WidgetTester tester, {UserTemplate? initialUser}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      pickTemplate(context, ref, initialUser: initialUser),
                  child: const Text('aç'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  testWidgets('60 satırlı yazı şablonunda "Oluştur" kaydırmadan görünür', (
    tester,
  ) async {
    await open(
      tester,
      initialUser: UserTemplate(
        id: 'u1',
        name: 'Uzun',
        type: NoteType.text,
        body: [for (var i = 0; i < 60; i++) 'satır $i'].join('\n'),
      ),
    );
    final create = find.byIcon(Icons.check);
    expect(create, findsOneWidget);
    final rect = tester.getRect(create);
    expect(rect.bottom, lessThanOrEqualTo(915), reason: 'ekranın içinde');
    // Kaydırma görünümünün DIŞINDA (sabit alt bant).
    expect(
      find.ancestor(of: create, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
  });

  testWidgets('galeride her hazır şablon minyatürlü kartla', (tester) async {
    await open(tester);
    for (final t in NoteTemplate.values) {
      final card = find.byKey(ValueKey('tpl-card-b:${t.key}'));
      expect(card, findsWidgets, reason: t.key);
      expect(tester.widget(card.first), isA<TemplatePreviewCard>());
    }
    final shopping = tester.widget<TemplatePreviewCard>(
      find.byKey(const ValueKey('tpl-card-b:shopping')).first,
    );
    expect(shopping.lines, everyElement(TemplateLineKind.check));
    final meeting = tester.widget<TemplatePreviewCard>(
      find.byKey(const ValueKey('tpl-card-b:meeting')).first,
    );
    expect(meeting.lines, contains(TemplateLineKind.heading));
  });

  // T7 (K-47/48): aramada her tuş BÜTÜN şablon kartlarını yeniden kuruyordu
  // (kök setState). Girdisi (şablon, yıldız) değişmeyen kart aynı örnekle
  // döner; daralan sonuçta da kalan kartlar anahtarıyla yerinde kalır.
  testWidgets('T7: aramada sonucu değişmeyen kart yeniden kurulmaz', (
    tester,
  ) async {
    await open(tester);
    final search = find.byType(TextField).first;
    await tester.enterText(search, 'a');
    await tester.pumpAndSettle();
    final before = find.byType(TemplatePreviewCard).evaluate().length;
    expect(before, greaterThan(3));
    final counts = <String, int>{};
    debugOnRebuildDirtyWidget = (e, _) {
      final n = e.widget.runtimeType.toString();
      counts[n] = (counts[n] ?? 0) + 1;
    };
    try {
      // Aynı sonuç (büyük/küçük harf katlanır) ve sonra daralan sonuç.
      await tester.enterText(search, 'A');
      await tester.pumpAndSettle();
      await tester.enterText(search, 'al');
      await tester.pumpAndSettle();
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    expect(find.byType(TemplatePreviewCard), findsWidgets);
    expect(counts['TemplatePreviewCard'] ?? 0, 0, reason: '$counts');
  });
}
