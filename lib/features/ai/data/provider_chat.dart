/// Uygulamanın iç istek biçimini (Gemini `contents`) sağlayıcının tel
/// biçimine çevirir ve yanıtı geri metne indirger.
///
/// Neden çeviri: `GeminiService`'teki 30'a yakın çağrı yeri (özet, OCR, PDF
/// sohbeti, asistan...) istek gövdesini Gemini şeklinde üretiyor ve
/// `AiCost.forContents` maliyeti de o şekilden ölçüyor. Her sağlayıcı için
/// çağrı yerlerini çoğaltmak yerine biçim TEK yerde çevrilir; yeni bir
/// sağlayıcı eklemek bu dosyaya bir `case` eklemek demektir.
library;

import 'dart:convert';

import 'ai_provider.dart';

/// Sağlayıcının bu içerik türünü kabul etmediği durumlarda atılır — çağıran
/// bunu kullanıcının anlayacağı bir mesaja çevirir.
class UnsupportedContentException implements Exception {
  const UnsupportedContentException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Sohbet uç noktasının [AiProvider.baseUrl]'e eklenecek yolu.
String chatPath(AiProvider provider, String model) => switch (provider.wire) {
  AiWire.gemini => '/models/$model:generateContent',
  AiWire.openai => '/chat/completions',
  AiWire.anthropic => '/messages',
};

/// Anthropic'te zorunlu; diğerlerinde gönderilmez. Notların en uzun çıktısı
/// (podcast metni, uzun özet) bu sınırın çok altında kalır.
const _anthropicMaxTokens = 8192;

const _jsonInstruction =
    'Yanıtı YALNIZCA geçerli JSON olarak ver. Açıklama, kod bloğu işareti '
    'veya başka hiçbir metin ekleme.';

/// İç `contents` biçimini sağlayıcının istek gövdesine çevirir.
///
/// [jsonOutput] Gemini'de `responseMimeType`, OpenAI'de `response_format` ile
/// karşılanır; Anthropic'in JSON kipi olmadığından talimat sistem mesajına
/// yazılır. (OpenAI'nin `json_object` kipi istemde "json" kelimesini şart
/// koşar — sistem mesajı bu şartı da karşılar.)
Map<String, dynamic> buildChatBody({
  required AiProvider provider,
  required String model,
  required List<Map<String, dynamic>> contents,
  bool jsonOutput = false,
}) {
  switch (provider.wire) {
    case AiWire.gemini:
      return {
        'contents': contents,
        'generationConfig': {
          if (jsonOutput) 'responseMimeType': 'application/json',
        },
      };
    case AiWire.openai:
      return {
        'model': model,
        'messages': [
          if (jsonOutput)
            {'role': 'system', 'content': _jsonInstruction},
          for (final content in contents)
            {
              'role': _role(content, assistant: 'assistant'),
              'content': [
                for (final part in _parts(content))
                  _openAiPart(provider, part),
              ],
            },
        ],
        if (jsonOutput) 'response_format': {'type': 'json_object'},
      };
    case AiWire.anthropic:
      return {
        'model': model,
        'max_tokens': _anthropicMaxTokens,
        if (jsonOutput) 'system': _jsonInstruction,
        'messages': [
          for (final content in contents)
            {
              'role': _role(content, assistant: 'assistant'),
              'content': [
                for (final part in _parts(content))
                  _anthropicPart(provider, part),
              ],
            },
        ],
      };
  }
}

String _role(Map<String, dynamic> content, {required String assistant}) =>
    (content['role'] as String? ?? 'user') == 'model' ? assistant : 'user';

List<Map<String, dynamic>> _parts(Map<String, dynamic> content) => [
  for (final part in content['parts'] as List<dynamic>? ?? const [])
    if (part is Map<String, dynamic>) part,
];

/// İç biçimdeki ikili ek: `{inline_data: {mime_type, data}}`.
/// (Bazı çağrı yerleri camelCase üretiyor — ikisi de kabul edilir.)
({String mime, String data})? _inline(Map<String, dynamic> part) {
  final raw = part['inline_data'] ?? part['inlineData'];
  if (raw is! Map) return null;
  final mime = (raw['mime_type'] ?? raw['mimeType'] ?? '').toString();
  final data = (raw['data'] ?? '').toString();
  if (data.isEmpty) return null;
  return (mime: mime.toLowerCase(), data: data);
}

Map<String, dynamic> _openAiPart(AiProvider provider, Map<String, dynamic> part) {
  final text = part['text'];
  if (text is String) return {'type': 'text', 'text': text};
  final inline = _inline(part);
  if (inline == null) return {'type': 'text', 'text': ''};
  if (inline.mime.startsWith('image/')) {
    return {
      'type': 'image_url',
      'image_url': {'url': 'data:${inline.mime};base64,${inline.data}'},
    };
  }
  if (inline.mime == 'application/pdf') {
    return {
      'type': 'file',
      'file': {
        'filename': 'belge.pdf',
        'file_data': 'data:application/pdf;base64,${inline.data}',
      },
    };
  }
  throw UnsupportedContentException(_unsupported(provider, inline.mime));
}

Map<String, dynamic> _anthropicPart(
  AiProvider provider,
  Map<String, dynamic> part,
) {
  final text = part['text'];
  if (text is String) return {'type': 'text', 'text': text};
  final inline = _inline(part);
  if (inline == null) return {'type': 'text', 'text': ''};
  if (inline.mime.startsWith('image/')) {
    return {
      'type': 'image',
      'source': {
        'type': 'base64',
        'media_type': inline.mime,
        'data': inline.data,
      },
    };
  }
  if (inline.mime == 'application/pdf') {
    return {
      'type': 'document',
      'source': {
        'type': 'base64',
        'media_type': 'application/pdf',
        'data': inline.data,
      },
    };
  }
  throw UnsupportedContentException(_unsupported(provider, inline.mime));
}

/// Ses ve video yalnızca Gemini'ye doğrudan gönderilebiliyor. Sessizce
/// atlamak yerine açıkça söylenir: kullanıcı "sesi neden okumadı" diye
/// aramasın, ne yapması gerektiğini görsün.
String _unsupported(AiProvider provider, String mime) {
  final kind = mime.startsWith('audio/')
      ? 'Ses'
      : mime.startsWith('video/')
      ? 'Video'
      : 'Bu dosya türü ($mime)';
  return '$kind dosyaları ${provider.label} ile gönderilemiyor. '
      "Ayarlar'dan sağlayıcıyı Google Gemini'ye çevirebilir ya da anahtarı "
      'kaldırıp dahili AI\'ı kullanabilirsin.';
}

/// Sağlayıcının yanıt gövdesinden düz metni çıkarır. Metin yoksa null döner
/// (çağıran "boş yanıt" hatası üretir).
String? parseChatText(AiProvider provider, Object? body) {
  if (body is! Map) return null;
  switch (provider.wire) {
    case AiWire.gemini:
      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final first = candidates.first;
      if (first is! Map) return null;
      final content = first['content'];
      if (content is! Map) return null;
      return _joinText(content['parts'], 'text');
    case AiWire.openai:
      final choices = body['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final message = first['message'];
      if (message is! Map) return null;
      final content = message['content'];
      // Yeni sürümler içeriği parça dizisi olarak da döndürebiliyor.
      if (content is String) return content.isEmpty ? null : content;
      return _joinText(content, 'text');
    case AiWire.anthropic:
      return _joinText(body['content'], 'text');
  }
}

String? _joinText(Object? parts, String field) {
  if (parts is! List) return null;
  final text = [
    for (final part in parts)
      if (part is Map && part[field] is String) part[field] as String,
  ].join();
  return text.isEmpty ? null : text;
}

// ---- Araç çağrısı (asistan) ------------------------------------------
//
// Gemini yolu `GeminiService._runToolLoop`'ta OLDUĞU GİBİ kaldı: oradaki
// döngü modelin gönderdiği parçaları GEÇMİŞE AYNEN geri koyuyor ve bu,
// modelin kendi iç imzalarını (thought signature vb.) koruduğu için
// bilerek bozulmadı. Aşağıdakiler OpenAI/Anthropic teli için AYRI bir
// döngünün yapı taşları; onlar da kendi ham yanıtlarını geçmişe aynen
// koyar, yani "verbatim" ilkesi üç sağlayıcıda da aynı.

/// Modelin çağırmak istediği tek bir araç.
class ToolCall {
  const ToolCall({required this.id, required this.name, required this.args});

  /// Sağlayıcının verdiği çağrı kimliği; sonucu doğru çağrıya bağlamak için
  /// geri gönderilmesi ZORUNLUDUR (OpenAI `tool_call_id`, Anthropic
  /// `tool_use_id`).
  final String id;

  final String name;
  final Map<String, dynamic> args;
}

/// Bir araç çağrısının sonucu.
typedef ToolResult = ({String id, String name, Map<String, dynamic> value});

/// İç `contents` biçimini sağlayıcının mesaj dizisine çevirir (araç
/// döngüsünün başlangıç geçmişi). Gemini teli için çağrılmaz.
List<Map<String, dynamic>> toWireMessages(
  AiProvider provider,
  List<Map<String, dynamic>> contents,
) => [
  for (final content in contents)
    {
      'role': _role(content, assistant: 'assistant'),
      'content': [
        for (final part in _parts(content))
          provider.wire == AiWire.anthropic
              ? _anthropicPart(provider, part)
              : _openAiPart(provider, part),
      ],
    },
];

/// Araçlı sohbet isteği gövdesi.
Map<String, dynamic> buildToolBody({
  required AiProvider provider,
  required String model,
  required List<Map<String, dynamic>> messages,
  required List<Map<String, dynamic>> geminiTools,
}) => switch (provider.wire) {
  AiWire.openai => {
    'model': model,
    'messages': messages,
    'tools': [
      for (final tool in geminiTools)
        {
          'type': 'function',
          'function': {
            'name': tool['name'],
            'description': tool['description'],
            'parameters': _toJsonSchema(tool['parameters']),
          },
        },
    ],
  },
  AiWire.anthropic => {
    'model': model,
    'max_tokens': _anthropicMaxTokens,
    'messages': messages,
    'tools': [
      for (final tool in geminiTools)
        {
          'name': tool['name'],
          'description': tool['description'],
          'input_schema': _toJsonSchema(tool['parameters']),
        },
    ],
  },
  // Gemini kendi döngüsünü kullanır; buraya düşmesi programlama hatasıdır.
  AiWire.gemini => throw StateError('Gemini kendi araç döngüsünü kullanır'),
};

/// Gemini şema lehçesini düz JSON Schema'ya çevirir.
///
/// Gemini tip adlarını BÜYÜK harf bekler ('OBJECT', 'STRING', 'ARRAY');
/// OpenAI ve Anthropic ise JSON Schema'nın küçük harfli adlarını. Araç
/// tanımları tek yerde (Gemini lehçesinde) tutulup burada çevriliyor —
/// aksi hâlde her araç iki kez yazılırdı ve biri güncellenmeyi unuturdu.
Object? _toJsonSchema(Object? schema) {
  if (schema is List) return [for (final item in schema) _toJsonSchema(item)];
  if (schema is! Map) return schema;
  return {
    for (final entry in schema.entries)
      entry.key: entry.key == 'type' && entry.value is String
          ? (entry.value as String).toLowerCase()
          : _toJsonSchema(entry.value),
  };
}

/// Yanıttan metni ve istenen araç çağrılarını çıkarır.
({String text, List<ToolCall> calls}) parseToolReply(
  AiProvider provider,
  Object? body,
) {
  if (body is! Map) return (text: '', calls: const []);
  if (provider.wire == AiWire.anthropic) {
    final content = body['content'];
    final calls = <ToolCall>[];
    if (content is List) {
      for (final part in content) {
        if (part is Map && part['type'] == 'tool_use') {
          calls.add(
            ToolCall(
              id: part['id'] as String? ?? '',
              name: part['name'] as String? ?? '',
              args: part['input'] is Map
                  ? Map<String, dynamic>.from(part['input'] as Map)
                  : <String, dynamic>{},
            ),
          );
        }
      }
    }
    return (text: _joinText(content, 'text') ?? '', calls: calls);
  }
  final choices = body['choices'];
  if (choices is! List || choices.isEmpty) return (text: '', calls: const []);
  final message = (choices.first as Map)['message'];
  if (message is! Map) return (text: '', calls: const []);
  final calls = <ToolCall>[];
  final toolCalls = message['tool_calls'];
  if (toolCalls is List) {
    for (final call in toolCalls) {
      if (call is! Map) continue;
      final fn = call['function'];
      if (fn is! Map) continue;
      calls.add(
        ToolCall(
          id: call['id'] as String? ?? '',
          name: fn['name'] as String? ?? '',
          // OpenAI argümanları JSON METNİ olarak gönderir, nesne olarak değil.
          args: _decodeArgs(fn['arguments']),
        ),
      );
    }
  }
  final content = message['content'];
  return (
    text: content is String ? content : _joinText(content, 'text') ?? '',
    calls: calls,
  );
}

Map<String, dynamic> _decodeArgs(Object? raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is! String || raw.isEmpty) return <String, dynamic>{};
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  } on FormatException {
    // Model bozuk JSON ürettiyse araç boş argümanla çağrılır; döngü
    // sonucu görüp kendini düzeltebilir.
    return <String, dynamic>{};
  }
}

/// Modelin ham yanıt mesajını geçmişe AYNEN eklemek için hazırlar.
/// Yeniden kurmak yerine ham hâlini korumak, araç çağrısı kimlikleri ve
/// sağlayıcıya özgü ek alanların bozulmamasını garanti eder.
Map<String, dynamic> assistantTurn(AiProvider provider, Object? body) {
  if (provider.wire == AiWire.anthropic) {
    final content = (body is Map ? body['content'] : null) ?? const [];
    return {'role': 'assistant', 'content': content};
  }
  final choices = (body is Map ? body['choices'] : null);
  final message = choices is List && choices.isNotEmpty
      ? (choices.first as Map)['message']
      : null;
  return message is Map
      ? Map<String, dynamic>.from(message)
      : {'role': 'assistant', 'content': ''};
}

/// Araç sonuçlarını geçmişe eklenecek mesaj(lar)a çevirir.
///
/// OpenAI her sonuç için AYRI bir `tool` mesajı ister; Anthropic hepsini TEK
/// bir kullanıcı mesajının içinde bekler.
List<Map<String, dynamic>> toolResultTurns(
  AiProvider provider,
  List<ToolResult> results,
) {
  if (provider.wire == AiWire.anthropic) {
    return [
      {
        'role': 'user',
        'content': [
          for (final result in results)
            {
              'type': 'tool_result',
              'tool_use_id': result.id,
              'content': jsonEncode(result.value),
            },
        ],
      },
    ];
  }
  return [
    for (final result in results)
      {
        'role': 'tool',
        'tool_call_id': result.id,
        'name': result.name,
        'content': jsonEncode(result.value),
      },
  ];
}
