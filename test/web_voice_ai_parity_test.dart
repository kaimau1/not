import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/web_audio_record.dart';
import 'package:notlar/core/utils/web_speech_recognition.dart';
import 'package:notlar/features/ai/data/ai_cache.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/ai_speech.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/notes/data/doc_text.dart';
import 'package:notlar/features/notes/data/pdf_text.dart';
import 'package:record/record.dart';

void main() {
  group('Web ses tanıma ve kayıt yardımcıları', () {
    test(
      'combineWebSpeechSegments boşlukları kırpar ve parçaları birleştirir',
      () {
        expect(combineWebSpeechSegments(const []), '');
        expect(
          combineWebSpeechSegments(const [
            (transcript: '  Merhaba  ', isFinal: true),
            (transcript: '   ', isFinal: false),
            (transcript: 'hasta ateşi var', isFinal: false),
          ]),
          'Merhaba hasta ateşi var',
        );
      },
    );

    test('mimeHintForEncoder kodlayıcıya göre doğru MIME ipucu döner', () {
      expect(mimeHintForEncoder(AudioEncoder.opus), 'audio/webm');
      expect(mimeHintForEncoder(AudioEncoder.aacLc), 'audio/mp4');
      expect(mimeHintForEncoder(AudioEncoder.wav), 'audio/wav');
      expect(mimeHintForEncoder(AudioEncoder.flac), 'audio/flac');
    });
  });

  group('AiCache & belge okuma yardımcıları', () {
    test(
      'AiCache.keyFor tür ve girdi sınırlarını ayırt eder; yazma/okuma çalışır',
      () async {
        expect(AiCache.keyFor('a', 'bc'), isNot(AiCache.keyFor('ab', 'c')));

        final tmp = Directory.systemTemp.createTempSync('ai_cache_test_');
        final prevDir = AiCache.overrideDir;
        AiCache.overrideDir = tmp;
        addTearDown(() {
          AiCache.overrideDir = prevDir;
          if (tmp.existsSync()) tmp.deleteSync(recursive: true);
        });

        final key = AiCache.keyFor('note_summary', 'klinik not metni');
        expect(await AiCache.read(key), isNull);
        await AiCache.write(key, 'Özet sonuç');
        expect(await AiCache.read(key), 'Özet sonuç');
      },
    );

    test('DocText dosya adını ve web blob yolunu doğru ayırt eder', () {
      expect(DocText.extensionOf('rapor.pdf'), 'pdf');
      expect(DocText.extensionOf('sunum.PPTX'), 'pptx');
      expect(DocText.supports('ek.docx'), isTrue);
      expect(
        DocText.extensionOf('blob:https://hekimasistani.com/1234-abcd'),
        '',
      );
      expect(
        DocText.supports('blob:https://hekimasistani.com/1234-abcd'),
        isFalse,
      );
    });

    test('PdfText.cleanForSpeechSync satır sonu tiresini birleştirir', () {
      final cleaned = PdfText.cleanForSpeechSync('kardiyo-\nloji muayenesi');
      expect(cleaned, contains('kardiyoloji muayenesi'));
    });
  });

  group('AiSpeechController Web/Gemini uygunluğu', () {
    test('Gemini sağlayıcıda isAvailable true, diğerinde false döner', () {
      final geminiContainer = ProviderContainer(
        overrides: [
          geminiServiceProvider.overrideWithValue(
            GeminiService(const ApiKeyStore()),
          ),
        ],
      );
      addTearDown(geminiContainer.dispose);
      expect(
        geminiContainer.read(aiSpeechProvider.notifier).isAvailable,
        isTrue,
      );

      final otherContainer = ProviderContainer(
        overrides: [
          geminiServiceProvider.overrideWithValue(
            GeminiService(const ApiKeyStore(), provider: AiProvider.openai),
          ),
        ],
      );
      addTearDown(otherContainer.dispose);
      expect(
        otherContainer.read(aiSpeechProvider.notifier).isAvailable,
        isFalse,
      );

      expect(
        AiSpeechController.chunk('Birinci cümle. İkinci cümle.'),
        hasLength(1),
      );
    });
  });
}
