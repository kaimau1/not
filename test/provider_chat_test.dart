import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/provider_chat.dart';

/// İç istek biçimi (Gemini `contents`) her sağlayıcının teline doğru
/// çevriliyor mu. Bu çeviri yanlış olursa hata ancak gerçek bir API
/// çağrısında ve anlaşılmaz bir 400 olarak görünür — o yüzden burada
/// kilitleniyor.
void main() {
  const text = [
    {
      'role': 'user',
      'parts': [
        {'text': 'Merhaba'},
      ],
    },
  ];
  const withImage = [
    {
      'role': 'user',
      'parts': [
        {'text': 'Bu görselde ne yazıyor?'},
        {
          'inline_data': {'mime_type': 'image/png', 'data': 'QUJD'},
        },
      ],
    },
  ];

  group('chatPath', () {
    test('her sağlayıcı kendi uç noktasına gider', () {
      expect(
        chatPath(AiProvider.gemini, 'gemini-3.5-flash'),
        '/models/gemini-3.5-flash:generateContent',
      );
      expect(chatPath(AiProvider.openai, 'gpt-5-mini'), '/chat/completions');
      expect(chatPath(AiProvider.openrouter, 'x/y'), '/chat/completions');
      expect(chatPath(AiProvider.anthropic, 'claude-haiku-4-5'), '/messages');
    });
  });

  group('buildChatBody — Gemini', () {
    test('içerik olduğu gibi geçer, model gövdeye yazılmaz', () {
      final body = buildChatBody(
        provider: AiProvider.gemini,
        model: 'gemini-3.5-flash',
        contents: text,
      );
      // Gemini'de model YOLDA; gövdeye eklenirse API 400 verir.
      expect(body.containsKey('model'), isFalse);
      expect(body['contents'], text);
    });

    test('jsonOutput responseMimeType olur', () {
      final body = buildChatBody(
        provider: AiProvider.gemini,
        model: 'm',
        contents: text,
        jsonOutput: true,
      );
      final config = body['generationConfig'] as Map<String, dynamic>;
      expect(config['responseMimeType'], 'application/json');
    });
  });

  group('buildChatBody — OpenAI', () {
    test('roller ve metin parçaları messages biçimine çevrilir', () {
      final body = buildChatBody(
        provider: AiProvider.openai,
        model: 'gpt-5-mini',
        contents: const [
          {
            'role': 'model',
            'parts': [
              {'text': 'Önceki yanıt'},
            ],
          },
        ],
      );
      expect(body['model'], 'gpt-5-mini');
      final messages = body['messages'] as List<dynamic>;
      final first = messages.first as Map<String, dynamic>;
      // Gemini'deki 'model' rolü OpenAI'de 'assistant'tır.
      expect(first['role'], 'assistant');
      expect((first['content'] as List).first, {
        'type': 'text',
        'text': 'Önceki yanıt',
      });
    });

    test('görsel data URL olarak gömülür', () {
      final body = buildChatBody(
        provider: AiProvider.openai,
        model: 'gpt-5-mini',
        contents: withImage,
      );
      final content =
          ((body['messages'] as List).first as Map)['content'] as List;
      expect(content.last, {
        'type': 'image_url',
        'image_url': {'url': 'data:image/png;base64,QUJD'},
      });
    });

    test('jsonOutput hem sistem mesajı hem response_format üretir', () {
      // OpenAI'nin json_object kipi istemde "json" geçmesini ŞART koşar;
      // sistem mesajı bu şartı da karşılıyor.
      final body = buildChatBody(
        provider: AiProvider.openai,
        model: 'm',
        contents: text,
        jsonOutput: true,
      );
      expect(body['response_format'], {'type': 'json_object'});
      final first = (body['messages'] as List).first as Map<String, dynamic>;
      expect(first['role'], 'system');
      expect((first['content'] as String).toUpperCase(), contains('JSON'));
    });

    test('ses dosyası açık hatayla reddedilir', () {
      expect(
        () => buildChatBody(
          provider: AiProvider.openai,
          model: 'm',
          contents: const [
            {
              'role': 'user',
              'parts': [
                {
                  'inline_data': {'mime_type': 'audio/mp4', 'data': 'QQ=='},
                },
              ],
            },
          ],
        ),
        throwsA(
          isA<UnsupportedContentException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Ses'), contains('Gemini')),
          ),
        ),
      );
    });
  });

  group('buildChatBody — Anthropic', () {
    test('max_tokens zorunlu alanı her istekte gider', () {
      final body = buildChatBody(
        provider: AiProvider.anthropic,
        model: 'claude-haiku-4-5',
        contents: text,
      );
      expect(body['max_tokens'], isA<int>());
      expect(body['model'], 'claude-haiku-4-5');
    });

    test('görsel base64 source olarak gider', () {
      final body = buildChatBody(
        provider: AiProvider.anthropic,
        model: 'm',
        contents: withImage,
      );
      final content =
          ((body['messages'] as List).first as Map)['content'] as List;
      expect(content.last, {
        'type': 'image',
        'source': {
          'type': 'base64',
          'media_type': 'image/png',
          'data': 'QUJD',
        },
      });
    });

    test('PDF document parçasına çevrilir', () {
      final body = buildChatBody(
        provider: AiProvider.anthropic,
        model: 'm',
        contents: const [
          {
            'role': 'user',
            'parts': [
              {
                'inline_data': {
                  'mime_type': 'application/pdf',
                  'data': 'UERG',
                },
              },
            ],
          },
        ],
      );
      final content =
          ((body['messages'] as List).first as Map)['content'] as List;
      expect((content.first as Map)['type'], 'document');
    });

    test('JSON kipi olmadığından talimat system alanına yazılır', () {
      final body = buildChatBody(
        provider: AiProvider.anthropic,
        model: 'm',
        contents: text,
        jsonOutput: true,
      );
      expect((body['system'] as String).toUpperCase(), contains('JSON'));
    });
  });

  group('parseChatText', () {
    test('Gemini yanıtından metin toplanır', () {
      expect(
        parseChatText(AiProvider.gemini, {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Bir'},
                  {'text': ' iki'},
                ],
              },
            },
          ],
        }),
        'Bir iki',
      );
    });

    test('OpenAI yanıtı düz metin olarak okunur', () {
      expect(
        parseChatText(AiProvider.openai, {
          'choices': [
            {
              'message': {'content': 'Yanıt'},
            },
          ],
        }),
        'Yanıt',
      );
    });

    test('Anthropic içerik dizisi birleştirilir', () {
      expect(
        parseChatText(AiProvider.anthropic, {
          'content': [
            {'type': 'text', 'text': 'Ya'},
            {'type': 'text', 'text': 'nıt'},
          ],
        }),
        'Yanıt',
      );
    });

    test('boş/bozuk yanıtta null döner, istisna atmaz', () {
      expect(parseChatText(AiProvider.gemini, {'candidates': []}), isNull);
      expect(parseChatText(AiProvider.openai, {'choices': []}), isNull);
      expect(parseChatText(AiProvider.anthropic, {}), isNull);
      expect(parseChatText(AiProvider.openai, 'bozuk'), isNull);
    });
  });

  group('authHeaders', () {
    test('her sağlayıcı kendi kimlik başlığını kullanır', () {
      expect(AiProvider.gemini.authHeaders('K')['x-goog-api-key'], 'K');
      expect(AiProvider.openai.authHeaders('K')['Authorization'], 'Bearer K');
      expect(
        AiProvider.openrouter.authHeaders('K')['Authorization'],
        'Bearer K',
      );
      final anthropic = AiProvider.anthropic.authHeaders('K');
      expect(anthropic['x-api-key'], 'K');
      // Sürüm başlığı olmadan Anthropic isteği reddeder.
      expect(anthropic['anthropic-version'], isNotEmpty);
    });
  });

  group('araç çağrısı — istek gövdesi', () {
    const geminiTools = [
      {
        'name': 'create_note',
        'description': 'Yeni not oluşturur',
        'parameters': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'items': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'},
            },
          },
          'required': ['title'],
        },
      },
    ];

    test('Gemini şema lehçesi JSON Schema\'ya çevrilir (küçük harf)', () {
      // Gemini tip adlarını BÜYÜK harf ister, OpenAI/Anthropic küçük.
      // Araçlar tek yerde Gemini lehçesinde tutulup burada çevriliyor.
      final body = buildToolBody(
        provider: AiProvider.openai,
        model: 'gpt-5-mini',
        messages: const [],
        geminiTools: geminiTools,
      );
      final fn = ((body['tools'] as List).first as Map)['function'] as Map;
      final params = fn['parameters'] as Map;
      expect(params['type'], 'object');
      final props = params['properties'] as Map;
      expect((props['title'] as Map)['type'], 'string');
      expect((props['items'] as Map)['type'], 'array');
      // İç içe şemalar da çevrilmeli.
      expect(((props['items'] as Map)['items'] as Map)['type'], 'string');
      // Tip DIŞI alanlar olduğu gibi kalmalı.
      expect(params['required'], ['title']);
    });

    test('Anthropic input_schema ve max_tokens ile gider', () {
      final body = buildToolBody(
        provider: AiProvider.anthropic,
        model: 'claude-haiku-4-5',
        messages: const [],
        geminiTools: geminiTools,
      );
      final tool = (body['tools'] as List).first as Map;
      expect(tool['name'], 'create_note');
      expect((tool['input_schema'] as Map)['type'], 'object');
      expect(body['max_tokens'], isA<int>());
    });

    test('Gemini kendi döngüsünü kullanır, buraya düşmemeli', () {
      expect(
        () => buildToolBody(
          provider: AiProvider.gemini,
          model: 'm',
          messages: const [],
          geminiTools: geminiTools,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('araç çağrısı — yanıt çözümleme', () {
    test('OpenAI: argümanlar JSON METNİ olarak gelir, çözülür', () {
      final reply = parseToolReply(AiProvider.openai, {
        'choices': [
          {
            'message': {
              'content': null,
              'tool_calls': [
                {
                  'id': 'call_abc',
                  'function': {
                    'name': 'create_note',
                    'arguments': '{"title":"Market","type":"checklist"}',
                  },
                },
              ],
            },
          },
        ],
      });
      expect(reply.calls, hasLength(1));
      expect(reply.calls.first.id, 'call_abc');
      expect(reply.calls.first.name, 'create_note');
      expect(reply.calls.first.args['title'], 'Market');
    });

    test('OpenAI: bozuk JSON argüman çökmez, boş harita olur', () {
      final reply = parseToolReply(AiProvider.openai, {
        'choices': [
          {
            'message': {
              'tool_calls': [
                {
                  'id': 'c1',
                  'function': {'name': 'x', 'arguments': '{bozuk'},
                },
              ],
            },
          },
        ],
      });
      expect(reply.calls.first.args, isEmpty);
    });

    test('Anthropic: tool_use parçası okunur, metin ayrı toplanır', () {
      final reply = parseToolReply(AiProvider.anthropic, {
        'content': [
          {'type': 'text', 'text': 'Ekliyorum'},
          {
            'type': 'tool_use',
            'id': 'toolu_1',
            'name': 'create_note',
            'input': {'title': 'Market'},
          },
        ],
      });
      expect(reply.text, 'Ekliyorum');
      expect(reply.calls.first.id, 'toolu_1');
      expect(reply.calls.first.args['title'], 'Market');
    });

    test('araç çağrısı yoksa yalnız metin döner', () {
      final reply = parseToolReply(AiProvider.openai, {
        'choices': [
          {
            'message': {'content': 'Notlarında 3 madde var'},
          },
        ],
      });
      expect(reply.calls, isEmpty);
      expect(reply.text, 'Notlarında 3 madde var');
    });
  });

  group('araç çağrısı — sonuçların geçmişe eklenmesi', () {
    final results = <ToolResult>[
      (id: 'call_1', name: 'create_note', value: {'status': 'ok'}),
      (id: 'call_2', name: 'delete_note', value: {'status': 'ok'}),
    ];

    test('OpenAI her sonuç için AYRI tool mesajı ister', () {
      final turns = toolResultTurns(AiProvider.openai, results);
      expect(turns, hasLength(2));
      expect(turns.first['role'], 'tool');
      // Kimlik olmadan sonuç yanlış çağrıya bağlanır.
      expect(turns.first['tool_call_id'], 'call_1');
      expect(turns.last['tool_call_id'], 'call_2');
    });

    test('Anthropic hepsini TEK kullanıcı mesajında bekler', () {
      final turns = toolResultTurns(AiProvider.anthropic, results);
      expect(turns, hasLength(1));
      expect(turns.first['role'], 'user');
      final content = turns.first['content'] as List;
      expect(content, hasLength(2));
      expect((content.first as Map)['type'], 'tool_result');
      expect((content.first as Map)['tool_use_id'], 'call_1');
    });

    test('asistan turu HAM yanıttan alınır (kimlikler bozulmasın)', () {
      final turn = assistantTurn(AiProvider.openai, {
        'choices': [
          {
            'message': {
              'role': 'assistant',
              'tool_calls': [
                {'id': 'call_1'},
              ],
            },
          },
        ],
      });
      expect(((turn['tool_calls'] as List).first as Map)['id'], 'call_1');
    });
  });
}
