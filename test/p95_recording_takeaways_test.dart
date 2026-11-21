import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/transcript_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRecordingGemini implements GeminiService {
  final inputs = <String>[];

  @override
  Future<RecordingTakeaways> summarizeTranscript(String transcript) async {
    inputs.add(transcript);
    return const RecordingTakeaways(
      summary: 'Ekip yeni sürüm takvimini netleştirdi.',
      actionItems: ['Tasarımı sonlandır', 'Test senaryolarını çalıştır'],
      reminders: [
        RecordingReminderHint(title: 'Müşteri sunumu', whenText: 'yarın 14:00'),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('A2 chunkTranscriptText & parseRecordingTakeaways', () {
    test('uzun dökümü satır sınırlarından parçalara böler', () {
      expect(chunkTranscriptText('kısa metin', maxChars: 100), ['kısa metin']);
      final long = List.generate(10, (i) => 'Satır $i içeriği').join('\n');
      final chunks = chunkTranscriptText(long, maxChars: 40);
      expect(chunks.length, greaterThan(2));
      for (final c in chunks) {
        expect(c.length, lessThanOrEqualTo(40));
      }
      expect(chunks.join('\n'), long);
    });

    test('JSON yanıtını özet, yapılacaklar ve hatırlatıcılara ayrıştırır', () {
      final parsed = parseRecordingTakeaways('''
```json
{
  "summary": "Toplantı özeti.",
  "actions": ["- Raporu gönder", "1. Bütçeyi onayla"],
  "reminders": [{"title": "Sunum provası", "when": "cuma 10:00"}]
}
```
''');
      expect(parsed.summary, 'Toplantı özeti.');
      expect(parsed.actionItems, ['Raporu gönder', 'Bütçeyi onayla']);
      expect(parsed.reminders.single.title, 'Sunum provası');
      expect(parsed.reminders.single.whenText, 'cuma 10:00');
      expect(
        parsed.toNoteText(summaryHeading: 'Özet', actionsHeading: 'Yapılacaklar'),
        'Özet\nToplantı özeti.\n\nYapılacaklar\n- Raporu gönder\n- Bütçeyi onayla',
      );
    });

    test('bozuk JSON gelse de düz özet olarak düşer', () {
      final parsed = parseRecordingTakeaways('Sade özet metni.');
      expect(parsed.summary, 'Sade özet metni.');
      expect(parsed.actionItems, isEmpty);
      expect(parsed.reminders, isEmpty);
    });
  });

  group('A2 TranscriptScreen Kayıttan not akışı', () {
    testWidgets('döküm → özet + yapılacaklar + hatırlatıcı önerisi ve nota ekleme', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeRecordingGemini();
      String? inserted;

      const transcript = Attachment(
        id: 'tr1',
        kind: AttachmentKind.text,
        fileName: 'toplanti.txt',
        mimeType: 'text/plain',
        text: '[00:05] Yeni sürümü yarın 14:00 sunumuna yetiştiriyoruz.\n'
            '[00:22] Tasarımı bitirip testleri koşalım.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: TranscriptScreen(
              transcript: transcript,
              onInsert: (text) => inserted = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = find.byKey(const ValueKey('transcript-ai-takeaways'));
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      // Zaman damgaları temizlenerek gönderildi.
      expect(fake.inputs.single, isNot(contains('[00:05]')));
      expect(find.text('Ekip yeni sürüm takvimini netleştirdi.'), findsOneWidget);
      expect(find.text('Tasarımı sonlandır'), findsOneWidget);
      expect(find.text('Hatırlatayım mı?'), findsOneWidget);
      expect(find.byKey(const ValueKey('transcript-reminder-0')), findsOneWidget);
      expect(find.text('Müşteri sunumu'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const ValueKey('transcript-takeaways-insert')),
      );
      await tester.tap(
        find.byKey(const ValueKey('transcript-takeaways-insert')),
      );
      await tester.pumpAndSettle();

      expect(inserted, contains('Ekip yeni sürüm takvimini netleştirdi.'));
      expect(inserted, contains('- Tasarımı sonlandır'));
    });
  });
}
