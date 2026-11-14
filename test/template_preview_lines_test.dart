import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/archive_template.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/template_preview_card.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P63 iskelet (docs/plan_tasarim_B.md §6.2): şablon kartının minyatür
/// sayfası. Satır türleri saf işlevden gelir; kartta metin yalnız ad.
void main() {
  group('templatePreviewLines', () {
    test('liste notu → her madde check, sıralı → number', () {
      expect(
        templatePreviewLines(
          type: NoteType.checklist,
          body: '',
          items: ['süt', 'ekmek', 'yumurta'],
        ),
        List.filled(3, TemplateLineKind.check),
      );
      expect(
        templatePreviewLines(
          type: NoteType.ordered,
          body: '',
          items: ['a', 'b'],
        ),
        [TemplateLineKind.number, TemplateLineKind.number],
      );
    });

    test('yazı notu: önekler, boş satır gap', () {
      expect(
        templatePreviewLines(
          type: NoteType.text,
          body: '# Gündem\n☐ karar\n• madde\n- tire\n\nserbest yazı',
          items: const [],
          max: 10,
        ),
        [
          TemplateLineKind.heading,
          TemplateLineKind.check,
          TemplateLineKind.bullet,
          TemplateLineKind.bullet,
          TemplateLineKind.gap,
          TemplateLineKind.text,
        ],
      );
    });

    test('gerçek şablon başlığı zengin işaretle yazılır → heading', () {
      final body = buildTemplateText([
        (text: 'Katılımcılar', heading: RichHeading.h2),
        (text: 'Ali, Ayşe', heading: RichHeading.normal),
      ]);
      expect(body.startsWith('# '), isFalse, reason: 'önek değil işaret');
      expect(
        templatePreviewLines(type: NoteType.text, body: body, items: const []),
        [TemplateLineKind.heading, TemplateLineKind.text],
      );
    });

    test('max kırpar; boş içerik boş liste; sondaki boşluklar düşer', () {
      expect(
        templatePreviewLines(
          type: NoteType.checklist,
          body: '',
          items: List.filled(12, 'x'),
        ).length,
        5,
      );
      expect(
        templatePreviewLines(type: NoteType.text, body: '', items: const []),
        isEmpty,
      );
      expect(
        templatePreviewLines(
          type: NoteType.checklist,
          body: '',
          items: const [],
        ),
        isEmpty,
      );
      expect(
        templatePreviewLines(
          type: NoteType.text,
          body: 'tek\n\n\n',
          items: const [],
        ),
        [TemplateLineKind.text],
      );
    });
  });

  group('TemplatePreviewCard', () {
    Widget host(Widget card, {double textScale = 1}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        // Telefonda 3 sütun: kart ~104 dp.
        body: Center(child: SizedBox(width: 104, child: card)),
      ),
    );

    TemplatePreviewCard card({
      bool favorite = false,
      VoidCallback? onTap,
      VoidCallback? onFavorite,
      VoidCallback? onMenu,
      String name = 'Alışveriş',
    }) => TemplatePreviewCard(
      key: const ValueKey('tpl-card-shopping'),
      lines: const [
        TemplateLineKind.heading,
        TemplateLineKind.check,
        TemplateLineKind.check,
      ],
      accent: Colors.teal,
      icon: Icons.shopping_cart_outlined,
      name: name,
      onTap: onTap ?? () {},
      favorite: favorite,
      onFavorite: onFavorite,
      favoriteKey: ValueKey('tpl-fav-$name'),
      onMenu: onMenu,
    );

    testWidgets('minyatür 64 dp, metin yalnız ad', (tester) async {
      await tester.pumpWidget(host(card()));
      expect(
        tester.getSize(find.byKey(const ValueKey('tpl-mini-page'))).height,
        64,
      );
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('Alışveriş'), findsOneWidget);
    });

    testWidgets('favori yıldızı: dolu/boş, dokunuş onFavorite', (tester) async {
      var favs = 0;
      await tester.pumpWidget(host(card(onFavorite: () => favs++)));
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('tpl-fav-Alışveriş')));
      expect(favs, 1);

      await tester.pumpWidget(host(card(favorite: true, onFavorite: () {})));
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.pumpWidget(host(card()));
      expect(find.byKey(const ValueKey('tpl-fav-Alışveriş')), findsNothing);
    });

    testWidgets('alt bandın sağ 40 dp’si onMenu, gerisi onTap', (tester) async {
      var taps = 0, menus = 0;
      await tester.pumpWidget(
        host(card(onTap: () => taps++, onMenu: () => menus++)),
      );
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
      final box = tester.getRect(
        find.byKey(const ValueKey('tpl-card-shopping')),
      );
      await tester.tapAt(box.bottomRight - const Offset(20, 10));
      expect((taps, menus), (0, 1));
      await tester.tapAt(box.bottomLeft + const Offset(20, -10));
      expect((taps, menus), (1, 1));

      await tester.pumpWidget(host(card()));
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('yazı 1.3: ad tek satır, taşma yok', (tester) async {
      await tester.pumpWidget(
        host(
          card(name: 'Haftalık toplantı notları', onMenu: () {}),
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
