import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/web_audio_record.dart';
import 'package:notlar/core/utils/web_speech_recognition.dart';
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

  group('Belge okuma yardımcıları', () {
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
}
