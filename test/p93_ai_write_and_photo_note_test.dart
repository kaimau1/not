import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_cache.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/presentation/ai_sheet.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/scan/scan_ocr.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGemini implements GeminiService {
  final calls = <String>[];
  String rewriteResponse = 'İyileştirilmiş yeni metin.';
  String translateResponse = 'Translated clean note.';
  String imageOcrFallbackResponse = 'Tahtadan el yazısı metni\nİkinci satır';
  StructuredOcrNote structuredResponse = const StructuredOcrNote(
    title: 'Market fişi',
    lines: ['Süt 1L', 'Ekmek', 'Yumurta'],
    suggestedType: NoteType.checklist,
  );

  @override
  Future<String> rewriteText(String text, String instruction) async {
    calls.add('rewrite:$text|$instruction');
    return rewriteResponse;
  }

  @override
  Future<String> translateText(String text, String targetLanguage) async {
    calls.add('translate:$targetLanguage|$text');
    return translateResponse;
  }

  @override
  Future<String> extractTextFromImage(Uint8List bytes, String mimeType) async {
    calls.add('extractImage:${bytes.length}:$mimeType');
    return imageOcrFallbackResponse;
  }

  @override
  Future<StructuredOcrNote> structureOcrText(String rawOcrText) async {
    calls.add('structure:$rawOcrText');
    return structuredResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAttachments implements AttachmentRepository {
  _FakeAttachments(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> readBytes(Attachment attachment) async => bytes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('p93_ai_test_');
    AiCache.overrideDir = tempDir;
    ScanOcr.supportedOverride = null;
    ScanOcr.recognizeImageTextOverride = null;
  });

  tearDown(() async {
    ScanOcr.supportedOverride = null;
    ScanOcr.recognizeImageTextOverride = null;
    AiCache.overrideDir = null;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('A5 parseStructuredOcrNote', () {
    test('JSON checklist yanıtını temizler ve madde ön eklerini soyar', () {
      final parsed = parseStructuredOcrNote('''
```json
{"title":"Market fişi","kind":"checklist","lines":["- Süt 2L","[ ] Ekmek","1. Yumurta"]}
```
''');
      expect(parsed.title, 'Market fişi');
      expect(parsed.suggestedType, NoteType.checklist);
      expect(parsed.lines, ['Süt 2L', 'Ekmek', 'Yumurta']);
      expect(parsed.toFormattedText(), 'Süt 2L\nEkmek\nYumurta');
    });

    test('düz metin yanıtında başlık + gövdeyi biçimlendirir', () {
      final parsed = parseStructuredOcrNote(
        '{"title":"Kartvizit","kind":"text","lines":["Ayşe Yılmaz","0555 000 00 00"]}',
      );
      expect(parsed.suggestedType, NoteType.text);
      expect(parsed.toFormattedText(), 'Kartvizit\n\nAyşe Yılmaz\n0555 000 00 00');
    });

    test('bozuk JSON gelse de satırları kaybetmeden düz metne düşer', () {
      final parsed = parseStructuredOcrNote(
        'Birinci satır\nİkinci satır',
        fallbackText: 'yedek',
      );
      expect(parsed.suggestedType, NoteType.text);
      expect(parsed.lines, ['Birinci satır', 'İkinci satır']);
    });
  });

  group('A6 Yazıyı iyileştir tek menü + önce/sonra önizleme', () {
    testWidgets('tek menüde uzat/samimi/çevir sunar ve önce/sonra gösterir', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      String? replacedText;
      const note = Note(
        id: 'n1',
        type: NoteType.text,
        title: 'Taslak',
        body: 'Kısa taslak cümle.',
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
            home: Scaffold(
              body: AiSheet(
                note: note,
                onReplaceText: (text, {asType, keepChecked = false}) {
                  replacedText = text;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tek "Yazıyı iyileştir" girişi var.
      final row = find.byKey(const ValueKey('ai-sheet-write-improve'));
      expect(row, findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();

      // Yeni ton/uzunluk seçenekleri ve çeviri çipleri aynı menüde.
      expect(find.byKey(const ValueKey('ai-write-expand')), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-write-casual')), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-translate-İngilizce')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('ai-write-casual')));
      await tester.pumpAndSettle();

      expect(fake.calls.single, contains('samimi'));
      expect(find.text('İyileştirilmiş yeni metin.'), findsOneWidget);

      // Önce / sonra karşılaştırma anahtarı çalışır.
      final compareChip = find.byKey(const ValueKey('ai-preview-compare'));
      expect(compareChip, findsOneWidget);
      expect(find.byKey(const ValueKey('ai-preview-before-box')), findsNothing);
      await tester.tap(compareChip);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ai-preview-before-box')), findsOneWidget);
      expect(find.text('Kısa taslak cümle.'), findsOneWidget);

      await tester.tap(find.text('Notu değiştir'));
      await tester.pumpAndSettle();
      expect(replacedText, 'İyileştirilmiş yeni metin.');
    });

    testWidgets('aynı menüden çeviri tek dokunuşla çalışır', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      const note = Note(
        id: 'n2',
        type: NoteType.text,
        body: 'Merhaba dünya',
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
            home: Scaffold(body: AiSheet(note: note)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ai-sheet-write-improve')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ai-translate-İngilizce')));
      await tester.pumpAndSettle();

      expect(fake.calls.single, 'translate:İngilizce|Merhaba dünya');
      expect(find.text('Translated clean note.'), findsOneWidget);
      expect(find.byKey(const ValueKey('ai-preview-compare')), findsOneWidget);
    });
  });

  group('A5 Fotoğraftan yapılı not (önce cihazda OCR)', () {
    testWidgets('cihaz içi OCR metni bulursa görsel yüklemeden AI yapılandırır', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final imgFile = File('${tempDir.path}/fis.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
      ScanOcr.supportedOverride = true;
      ScanOcr.recognizeImageTextOverride = (_) async =>
          'SUT 1L\nEKMEK\nYUMURTA 15LI';

      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      String? createdText;
      NoteType? createdType;
      final note = Note(
        id: 'n3',
        type: NoteType.text,
        attachments: [
          Attachment(
            id: 'img1',
            kind: AttachmentKind.image,
            fileName: 'fis.jpg',
            mimeType: 'image/jpeg',
            localPath: imgFile.path,
            sizeBytes: 4,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
            attachmentRepositoryProvider.overrideWithValue(
              _FakeAttachments(Uint8List.fromList([1, 2, 3, 4])),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AiSheet(
                note: note,
                onCreateNote: (text, {asType, keepChecked = false}) {
                  createdText = text;
                  createdType = asType;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('ai-image-tile-img1')),
      );
      await tester.tap(find.byKey(const ValueKey('ai-image-tile-img1')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('ai-photo-structured-img1')),
      );
      await tester.tap(find.byKey(const ValueKey('ai-photo-structured-img1')));
      await tester.pumpAndSettle();

      // Görsel baytı gönderilmedi; yalnız cihaz OCR metni yapılandırıldı.
      expect(fake.calls, ['structure:SUT 1L\nEKMEK\nYUMURTA 15LI']);
      expect(find.byKey(const ValueKey('ai-structured-title')), findsOneWidget);
      expect(find.text('Market fişi'), findsOneWidget);

      await tester.tap(find.text('Yeni not olarak'));
      await tester.pumpAndSettle();
      expect(createdText, 'Süt 1L\nEkmek\nYumurta');
      expect(createdType, NoteType.checklist);
    });

    testWidgets('cihaz içi OCR boşsa görsel yedeğine düşer ve yine yapılandırır', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      ScanOcr.supportedOverride = false;
      final prefs = await SharedPreferences.getInstance();
      final fake = _FakeGemini();
      const note = Note(
        id: 'n4',
        type: NoteType.text,
        attachments: [
          Attachment(
            id: 'img2',
            kind: AttachmentKind.image,
            fileName: 'tahta.jpg',
            mimeType: 'image/jpeg',
            sizeBytes: 4,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            aiAvailabilityProvider.overrideWithValue(AiAvailability.ready),
            geminiServiceProvider.overrideWithValue(fake),
            attachmentRepositoryProvider.overrideWithValue(
              _FakeAttachments(Uint8List.fromList([1, 2, 3, 4])),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AiSheet(note: note)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey('ai-image-tile-img2')),
      );
      await tester.tap(find.byKey(const ValueKey('ai-image-tile-img2')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('ai-photo-structured-img2')),
      );
      await tester.tap(find.byKey(const ValueKey('ai-photo-structured-img2')));
      await tester.pumpAndSettle();

      expect(fake.calls, [
        'extractImage:4:image/jpeg',
        'structure:Tahtadan el yazısı metni\nİkinci satır',
      ]);
      expect(find.text('Market fişi'), findsOneWidget);
    });
  });
}
