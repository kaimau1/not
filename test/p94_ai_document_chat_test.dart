import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/presentation/ai_chat_screen.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDocGemini implements GeminiService {
  final prompts = <String>[];

  @override
  Future<String> chatWithPdf({
    required Uint8List bytes,
    required String fileName,
    required List<ChatTurn> history,
  }) async {
    prompts.add(history.last.text);
    return 'Sözleşme süresi 12 aydır [s. 2]. Ödeme koşulları ayrıntılıdır [s. 5-6].';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAttachments implements AttachmentRepository {
  @override
  Future<Uint8List?> readBytes(Attachment attachment) async =>
      Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('A4 extractPdfPageCitations', () {
    test('Türkçe ve İngilizce sayfa atıflarını benzersiz ve sıralı çıkarır', () {
      expect(
        extractPdfPageCitations(
          'Özet [s. 5], bütçe [s. 2-4], ek bilgi (Sayfa 10) ve p. 2.',
        ),
        [2, 3, 4, 5, 10],
      );
      expect(extractPdfPageCitations('Sayfa 0 veya metin yok'), isEmpty);
      expect(extractPdfPageCitations('Bkz. [s. 7, 12] ve page 1.'), [1, 7, 12]);
    });
  });

  group('A4 Belgeye sor: Özet ilk öneri + sayfa kaynak rozetleri', () {
    testWidgets('Özetle ilk öneri olarak çıkar ve yanıt sayfa çiplerini gösterir', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeDocGemini();
      const doc = Attachment(
        id: 'pdf1',
        kind: AttachmentKind.pdf,
        fileName: 'sozlesme.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 4,
      );
      const note = Note(
        id: 'n1',
        type: NoteType.text,
        title: 'Sözleşme',
        attachments: [doc],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
            attachmentRepositoryProvider.overrideWithValue(_FakeAttachments()),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AiChatScreen(
              note: note,
              document: doc,
              initialScope: ChatScope.document,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final summaryBtn = find.byKey(const ValueKey('chat-doc-suggest-summary'));
      final keyPointsBtn = find.byKey(
        const ValueKey('chat-doc-suggest-keypoints'),
      );
      final actionsBtn = find.byKey(const ValueKey('chat-doc-suggest-actions'));
      expect(summaryBtn, findsOneWidget);
      expect(keyPointsBtn, findsOneWidget);
      expect(actionsBtn, findsOneWidget);
      // Özet ilk önerilen soru: solda/üstte.
      expect(
        tester.getTopLeft(summaryBtn).dx,
        lessThan(tester.getTopLeft(keyPointsBtn).dx),
      );

      await tester.tap(summaryBtn);
      await tester.pumpAndSettle();

      expect(fake.prompts.single, contains('özetle'));
      expect(
        find.byKey(const ValueKey('chat-page-citation-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chat-page-citation-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('chat-page-citation-6')),
        findsOneWidget,
      );
      expect(find.text('s. 2'), findsOneWidget);
      expect(find.text('s. 5'), findsOneWidget);
      expect(find.text('s. 6'), findsOneWidget);
    });
  });
}
