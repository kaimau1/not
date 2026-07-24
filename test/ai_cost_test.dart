import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';

/// Kota puanlari isteğin icerigi'nden turetiliyor: bu hesap bozulursa
/// bir PDF ozeti bir baslik uretimi kadar ucuz sayilir ve fatura patlar.
void main() {
  List<Map<String, dynamic>> textOnly(String body) => [
    {
      'parts': [
        {'text': body},
      ],
    },
  ];

  List<Map<String, dynamic>> withFile(String mime) => [
    {
      'parts': [
        {'text': 'ozetle'},
        {
          'inline_data': {'mime_type': mime, 'data': 'AAAA'},
        },
      ],
    },
  ];

  test('kisa metin istegi taban puan', () {
    expect(AiCost.forContents(textOnly('basligi yaz')), 1);
  });

  test('uzun metin uzunlukla orantili puan ekler', () {
    final long = 'a' * (AppConstants.aiCharsPerPoint * 3);
    expect(AiCost.forContents(textOnly(long)), 1 + 3);
  });

  test('gorsel eki metinden pahali', () {
    expect(
      AiCost.forContents(withFile('image/jpeg')),
      1 + AppConstants.aiPointsPerImage,
    );
  });

  test('PDF eki gorselden pahali', () {
    expect(
      AiCost.forContents(withFile('application/pdf')),
      1 + AppConstants.aiPointsPerDocument,
    );
    expect(
      AppConstants.aiPointsPerDocument,
      greaterThan(AppConstants.aiPointsPerImage),
    );
  });

  test('gunluk butce bir kac PDF ozetine yeter, sinirsiz degil', () {
    final pdfCost = AiCost.forContents(withFile('application/pdf'));
    final perDay = AppConstants.freeDailyAiPoints ~/ pdfCost;
    expect(perDay, greaterThanOrEqualTo(2));
    expect(perDay, lessThanOrEqualTo(5));
  });

  test('camelCase inlineData anahtari da sayilir', () {
    final contents = [
      {
        'parts': [
          {
            'inlineData': {'mimeType': 'image/png', 'data': 'AAAA'},
          },
        ],
      },
    ];
    expect(
      AiCost.forContents(contents),
      1 + AppConstants.aiPointsPerImage,
    );
  });
}
