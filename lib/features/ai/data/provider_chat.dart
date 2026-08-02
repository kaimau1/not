import 'ai_provider.dart';

/// Uygulamanın iç istek biçimini (Gemini `contents`) sağlayıcının tel
/// biçimine çevirir ve yanıtı geri metne indirger.
///
/// Neden çeviri: `GeminiService`'teki 30'a yakın çağrı yeri (özet, OCR, PDF
/// sohbeti, asistan...) istek gövdesini Gemini şeklinde üretiyor ve
/// `AiCost.forContents` maliyeti de o şekilden ölçüyor. Her sağlayıcı için
/// çağrı yerlerini çoğaltmak yerine biçim TEK yerde çevrilir; yeni bir
/// sağlayıcı eklemek bu dosyaya bir `case` eklemek demektir.
library;

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
