import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/sensitive_text.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kartta hassas içerik (geliştirme raporu B1): parola notu kartta
/// içeriksiz, IBAN/kart numarası örtülü; ayar kapalıyken her şey görünür.
void main() {
  group('isCredentialNote', () {
    Note note({
      String title = '',
      String body = '',
      List<String> items = const [],
    }) => Note(
      id: 'n',
      type: NoteType.text,
      title: title,
      body: body,
      items: [for (final (i, t) in items.indexed) NoteItem(id: 'i$i', text: t)],
    );

    test('parola sözcüğü başlıkta, gövdede ya da maddede', () {
      expect(isCredentialNote(note(title: 'Şifreler')), isTrue);
      expect(isCredentialNote(note(title: 'ŞİFRE')), isTrue);
      expect(isCredentialNote(note(body: 'wifi parola: 1234')), isTrue);
      expect(isCredentialNote(note(items: ['gmail password x'])), isTrue);
      expect(isCredentialNote(note(body: 'Kart PIN 0000')), isTrue);
    });

    test('benzer ama farklı sözcükler eşleşmez', () {
      expect(isCredentialNote(note(title: 'Alışveriş')), isFalse);
      expect(isCredentialNote(note(body: 'pinterest panosu')), isFalse);
      expect(isCredentialNote(note(body: 'şifreleme dersi notları')), isFalse);
    });
  });

  group('maskSensitiveNumbers', () {
    test('IBAN: ülke kodu + kontrol ve son dört hane görünür', () {
      expect(
        maskSensitiveNumbers('IBAN: TR12 0006 1005 1978 6457 8413 26'),
        'IBAN: TR12 •••• •••• •••• •••• ••13 26',
      );
      final masked = maskSensitiveNumbers('TR120006100519786457841326');
      expect(masked, startsWith('TR12'));
      expect(masked, endsWith('1326'));
      expect(masked, contains('•'));
      expect(masked.length, 'TR120006100519786457841326'.length);
    });

    test('kart numarası: son dört hane görünür, ayırıcılar korunur', () {
      expect(
        maskSensitiveNumbers('Kart 4543 1234 5678 9012'),
        'Kart •••• •••• •••• 9012',
      );
    });

    test('telefon ve kısa sayılar dokunulmaz', () {
      expect(
        maskSensitiveNumbers('Ara: 0532 123 45 67'),
        'Ara: 0532 123 45 67',
      );
      expect(
        maskSensitiveNumbers('2026 yılında 12 madde'),
        '2026 yılında 12 madde',
      );
    });
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
      bool hide = true,
    }) async {
      await prefs.setBool('card_hide_sensitive', hide);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: SizedBox(width: 300, child: NoteCard(note: note)),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    final credentials = Note(
      id: 'p',
      type: NoteType.text,
      title: 'Şifreler',
      body: 'instagram: ahmet / Gizli123',
      updatedAt: DateTime(2026, 10, 20),
    );

    testWidgets('parola notunun içeriği kartta yok, kilitle önerisi var', (
      tester,
    ) async {
      await pump(tester, credentials);
      expect(find.textContaining('Gizli123'), findsNothing);
      expect(find.text('Hassas içerik — kartta gizlendi'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('ayar kapalıyken içerik görünür', (tester) async {
      await pump(tester, credentials, hide: false);
      expect(find.textContaining('Gizli123'), findsOneWidget);
    });

    testWidgets('kart numarası örtülür', (tester) async {
      await pump(
        tester,
        Note(
          id: 'k',
          type: NoteType.text,
          body: 'Kart 4543 1234 5678 9012',
          updatedAt: DateTime(2026, 10, 20),
        ),
      );
      expect(find.textContaining('5678'), findsNothing);
      expect(find.textContaining('9012'), findsOneWidget);
    });
  });
}
