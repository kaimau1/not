import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/card_preview.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kart önizlemesi notun yalnız görünebilecek kadarını işler (F21, telefonda
/// ölçülen kaydırma/arama kasmasının kök nedeni: kart TÜM gövdeyi maskeden,
/// biçimden ve metin motorundan geçiriyordu).
void main() {
  String lines(int n) => [for (var i = 0; i < n; i++) 'satır $i'].join('\n');

  bool hasLoneSurrogate(String s) {
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c >= 0xD800 && c <= 0xDBFF) {
        if (i + 1 >= s.length) return true;
        final d = s.codeUnitAt(i + 1);
        if (d < 0xDC00 || d > 0xDFFF) return true;
        i++;
      } else if (c >= 0xDC00 && c <= 0xDFFF) {
        return true;
      }
    }
    return false;
  }

  group('previewSlice', () {
    test('kısa metin AYNI örnek döner (kopya yok)', () {
      const text = 'kısa not\nikinci satır';
      expect(identical(previewSlice(text), text), isTrue);
    });

    test('uzun gövde: en çok 600 karakter, satır ortasında `…`', () {
      final text = 'kelime ' * 2000;
      final slice = previewSlice(text);
      expect(slice.length, lessThanOrEqualTo(kPreviewMaxChars + 1));
      expect(slice, endsWith('…'));
      expect(text.startsWith(slice.substring(0, slice.length - 1)), isTrue);
    });

    test('uzun gövde: en çok 10 satır, satır sonunda `…` eklenmez', () {
      final slice = previewSlice(lines(500));
      expect('\n'.allMatches(slice), hasLength(kPreviewMaxLines - 1));
      expect(slice, endsWith('satır 9'));
    });

    test('kesim grafem sınırında: emoji ve birleşik harf bölünmez', () {
      // 👍🏽 dört kod birimi, TEK grafem; 600. birim içine düşer.
      final emoji = '${'a' * 598}👍🏽${'b' * 50}';
      final s1 = previewSlice(emoji);
      expect(hasLoneSurrogate(s1), isFalse);
      expect(s1, '${'a' * 598}…');
      // e + birleşik vurgu (U+0301) tek grafem: 600. birim vurguya düşer.
      final accent = '${'a' * 599}é${'b' * 50}';
      expect(previewSlice(accent), '${'a' * 599}…');
    });

    test('dilimin sonunda açık kalan biçim işareti düz metin çizilir', () {
      final text = '${'x' * 590} **kalın ama kapanmıyor** son';
      final slice = previewSlice(text);
      expect(slice, contains('**kalın'));
      // Çözümleyici eşleşmeyen işareti düz sayar: hiçbir şey yutulmaz.
      expect(stripRichMarkers(slice), slice);
      final spans = richSpans(
        slice,
        null,
        palette: const [],
        markerColor: const Color(0x00000000),
      );
      expect(TextSpan(children: spans).toPlainText(), slice);
    });

    test('kesimde bölünen kart numarası da örtülür (yarısı açık kalmaz)', () {
      final text = '${'a' * 590} 4543 1234 5678 9012 son';
      final slice = previewSlice(text, mask: true);
      expect(slice, isNot(contains('4543')));
      expect(slice, contains('•'));
      // Kesilmeyen kısa metinde de örtme aynı.
      expect(
        previewSlice('Kart 4543 1234 5678 9012', mask: true),
        'Kart •••• •••• •••• 9012',
      );
    });
  });

  group('searchExcerpt', () {
    test('eşleşme kartın başında görünüyorsa kesit yok', () {
      const plain = 'Toplantı notu: ilaç dozu sabah';
      final i = plain.indexOf('ilaç');
      expect(searchExcerpt(plain, i, 4, maxLines: 4), isNull);
    });

    test('uzun satırın derininde: sözcük başından `… ` ile', () {
      final plain = '${'lorem ipsum ' * 80}benzersiz sözcük burada ve devam';
      final i = plain.indexOf('benzersiz');
      final excerpt = searchExcerpt(plain, i, 'benzersiz'.length, maxLines: 4)!;
      expect(excerpt, startsWith('… '));
      // Eşleşme kesitin ilk ~30 karakterinde: kartta görünür.
      expect(excerpt.indexOf('benzersiz'), lessThan(32));
      // Sözcük ortasından başlamaz.
      expect(
        excerpt.substring(2),
        anyOf(startsWith('lorem'), startsWith('ipsum')),
      );
    });

    test('300. satırdaki eşleşme: o satırın başından', () {
      final plain = '${lines(300)}\nbenzersiz ilaç\n${lines(20)}';
      final i = plain.indexOf('benzersiz');
      final excerpt = searchExcerpt(plain, i, 9, maxLines: 4)!;
      expect(excerpt, startsWith('… benzersiz ilaç'));
      expect(excerpt.length, lessThanOrEqualTo(kPreviewMaxChars + 3));
    });

    test('kesitin başında bölünen numara da örtülür', () {
      final plain = '${'x ' * 100}4543 1234 5678 9012 eşleşme';
      final i = plain.indexOf('eşleşme');
      final excerpt = searchExcerpt(plain, i, 7, maxLines: 2, mask: true)!;
      expect(excerpt, contains('eşleşme'));
      expect(RegExp(r'\d{4} \d{4}').hasMatch(excerpt), isFalse);
    });
  });

  group('CardPreview', () {
    Note note(String body, {List<String> items = const []}) => Note(
      id: 'p${body.hashCode}',
      type: NoteType.text,
      title: 'Başlık',
      body: body,
      items: [for (final (i, t) in items.indexed) NoteItem(id: 'i$i', text: t)],
      updatedAt: DateTime(2026, 11, 3),
    );

    test('not örneği başına bir kez; ayar değişince yenilenir', () {
      final n = note('wifi şifre: 1234\n${lines(400)}');
      final a = CardPreview.of(n, hideSensitive: true);
      expect(identical(CardPreview.of(n, hideSensitive: true), a), isTrue);
      expect(a.credential, isTrue);
      expect(a.body.length, lessThanOrEqualTo(kPreviewMaxChars + 1));
      final b = CardPreview.of(n, hideSensitive: false);
      expect(identical(b, a), isFalse);
    });

    test('parola sözcüğü dilimin DIŞINDA da yakalanır (tam metin)', () {
      final n = note('${lines(300)}\nbankamatik parola 0000');
      expect(CardPreview.of(n, hideSensitive: true).credential, isTrue);
    });

    test('madde metni 200 karakterle sınırlı', () {
      final n = note('', items: ['uzun ' * 300]);
      final item = CardPreview.of(
        n,
        hideSensitive: false,
      ).item(n.items.first.text);
      expect(item.length, lessThanOrEqualTo(kPreviewItemChars + 1));
    });

    test(
      'gövde eşleşmesi süzgecin önbelleğinden; maddede ya da kilitliyse yok',
      () {
        final n = note(
          '${lines(300)}\n**benzersiz** sözcük',
          items: ['madde içi'],
        );
        final match = bodySearchMatch(n, 'benzersiz')!;
        expect(match.$1.substring(match.$2, match.$2 + 9), 'benzersiz');
        expect(bodySearchMatch(n, 'madde ici'), isNull);
        final locked = Note(
          id: 'kilit',
          type: NoteType.text,
          body: 'benzersiz',
          locked: true,
        );
        expect(bodySearchMatch(locked, 'benzersiz'), isNull);
        final excerpt = CardPreview.of(
          n,
          hideSensitive: true,
        ).excerpt('Benzersiz', 4);
        expect(excerpt, startsWith('… benzersiz sözcük'));
      },
    );
  });

  group('kart', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pump(
      WidgetTester tester,
      Note note, {
      String query = '',
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: SizedBox(
                width: 300,
                child: NoteCard(note: note, highlightQuery: query),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    /// Kartın çizdiği en uzun metin.
    String longestText(WidgetTester tester) {
      var longest = '';
      for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
        final t = w.text.toPlainText();
        if (t.length > longest.length) longest = t;
      }
      return longest;
    }

    final long = Note(
      id: 'uzun',
      type: NoteType.text,
      title: 'Uzun',
      body: '${lines(400)}\nbenzersiz sözcük burada\n${lines(100)}',
      updatedAt: DateTime(2026, 11, 3),
    );

    testWidgets('500 satırlık notta kart yalnız dilimi yerleştirir', (
      tester,
    ) async {
      await pump(tester, long);
      final text = longestText(tester);
      expect(text, startsWith('satır 0'));
      expect(text.length, lessThanOrEqualTo(kPreviewMaxChars + 1));
    });

    testWidgets('aramada derindeki eşleşmenin kesiti vurgulu görünür', (
      tester,
    ) async {
      await pump(tester, long, query: 'benzersiz');
      final text = longestText(tester);
      expect(text, startsWith('… benzersiz sözcük'));
      final highlighted = tester
          .widgetList<RichText>(find.byType(RichText))
          .expand((w) {
            final spans = <TextSpan>[];
            w.text.visitChildren((s) {
              if (s is TextSpan && s.style?.fontWeight == FontWeight.w700) {
                spans.add(s);
              }
              return true;
            });
            return spans;
          })
          .map((s) => s.text);
      expect(highlighted, contains('benzersiz'));
    });

    testWidgets('"hassas içeriği gizle" değişince kart yenilenir', (
      tester,
    ) async {
      await prefs.setBool('card_hide_sensitive', true);
      final card = Note(
        id: 'kart',
        type: NoteType.text,
        body: 'Kart 4543 1234 5678 9012',
        updatedAt: DateTime(2026, 11, 3),
      );
      await pump(tester, card);
      expect(find.textContaining('5678'), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(NoteCard)),
      );
      container.read(cardHideSensitiveProvider.notifier).set(false);
      await tester.pump();
      expect(find.textContaining('5678'), findsOneWidget);
    });
  });
}
