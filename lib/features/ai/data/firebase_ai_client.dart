import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/constants.dart';
import 'gemini_service.dart' show GeminiException;

/// Anahtarsız "dahili AI": istekler Firebase AI Logic üzerinden (Gemini
/// Developer API arka ucu) uygulamanın kendi Firebase projesiyle yapılır.
/// Kullanıcıdan API anahtarı istenmez ve cihazda anahtar bulunmaz; kötüye
/// kullanım App Check + [beforeCall] kotasıyla sınırlanır.
///
/// İçerikler GeminiService'in REST biçimindeki ham map'leriyle gelir ve
/// burada firebase_ai tiplerine çevrilir; böylece tüm istem metinleri tek
/// yerde (GeminiService) kalır.
class FirebaseAiClient {
  FirebaseAiClient({Future<void> Function()? beforeCall})
      : _beforeCall = beforeCall ?? _noop;

  static Future<void> _noop() async {}

  /// Kullanıcıya görünür her AI eylemi öncesi çağrılır (premium/kota kapısı).
  /// Kota bittiyse [GeminiException] fırlatarak isteği durdurur.
  final Future<void> Function() _beforeCall;

  static List<String> _candidates(String? prefer) => [
        ?prefer,
        for (final model in AppConstants.geminiModelPreference)
          if (model != prefer) model,
      ];

  GenerativeModel _model(
    String modelId, {
    bool jsonOutput = false,
    List<Tool>? tools,
  }) =>
      FirebaseAI.googleAI().generativeModel(
        model: modelId,
        generationConfig: GenerationConfig(
          responseMimeType: jsonOutput ? 'application/json' : null,
        ),
        tools: tools,
      );

  /// REST biçimindeki content map'ini firebase_ai [Content] nesnesine çevirir.
  static Content _toContent(Map<String, dynamic> raw) {
    final parts = <Part>[];
    for (final part in raw['parts'] as List<dynamic>? ?? const []) {
      final map = part as Map<String, dynamic>;
      if (map['text'] is String) parts.add(TextPart(map['text'] as String));
      final inline = map['inline_data'] ?? map['inlineData'];
      if (inline is Map) {
        parts.add(InlineDataPart(
          inline['mime_type'] as String? ??
              inline['mimeType'] as String? ??
              'application/octet-stream',
          base64Decode(inline['data'] as String),
        ));
      }
    }
    return Content(raw['role'] as String? ?? 'user', parts);
  }

  /// Modeli yok/kota dolu benzeri hatalarda sıradaki model denenir;
  /// diğer hatalar kullanıcıya anlaşılır bir mesajla iletilir.
  static bool _shouldTryNext(FirebaseAIException e) {
    final message = e.message.toLowerCase();
    return message.contains('not found') ||
        message.contains('not_found') ||
        message.contains('quota') ||
        message.contains('exhausted') ||
        message.contains('overloaded') ||
        message.contains('unavailable');
  }

  Future<T> _withModel<T>(
    Future<T> Function(String model) run, {
    String? prefer,
  }) async {
    final models = _candidates(prefer);
    FirebaseAIException? lastSkipped;
    for (var i = 0; i < models.length; i++) {
      try {
        return await run(models[i]);
      } on FirebaseAIException catch (e) {
        // İlk sıradaki [prefer] yalnızca bir HIZ tercihidir (ör. otomatik
        // başlıkta hızlı "lite" modeli). O model bu arka uçta yoksa dönen
        // hata her zaman "not found" kalıbına uymayabilir; bu durumda istek
        // tümden başarısız olmasın diye tercih denemesinin HER hatasında
        // sıradaki (standart) modele düşülür.
        final isPreferHint = prefer != null && i == 0;
        if (isPreferHint || _shouldTryNext(e)) {
          lastSkipped = e;
          continue;
        }
        throw _mapError(e);
      }
    }
    throw _mapError(lastSkipped);
  }

  /// Firebase AI Logic hatalarını kullanıcının anlayacağı Türkçe mesaja
  /// çevirir. En sık karşılaşılan iki durum: (1) konsolda AI Logic hiç
  /// etkinleştirilmemiş, (2) App Check zorunlu ama token geçersiz.
  static GeminiException _mapError(FirebaseAIException? e) {
    final message = (e?.message ?? '').toLowerCase();
    if (message.contains('app check') ||
        message.contains('app-check') ||
        message.contains('token') ||
        message.contains('unauthenticated') ||
        message.contains('permission') ||
        message.contains('403')) {
      return const GeminiException(
        'Dahili yapay zeka bu sürümde etkinleştirilmemiş. Kendi Gemini '
        "anahtarını Ayarlar'dan girerek AI özelliklerini hemen "
        'kullanabilirsin.',
        isAuthError: true,
      );
    }
    if (message.contains('not enabled') ||
        message.contains('has not been used') ||
        message.contains('disabled') ||
        message.contains('service_disabled')) {
      return const GeminiException(
        'Dahili yapay zeka altyapısı henüz hazır değil. Kendi Gemini '
        "anahtarını Ayarlar'dan girerek AI özelliklerini kullanabilirsin.",
        isAuthError: true,
      );
    }
    return GeminiException(
      'Yapay zeka şu an yanıt veremiyor: ${e?.message ?? 'bilinmeyen hata'}',
    );
  }

  /// Tek seferlik üretim (REST'teki generateContent karşılığı).
  Future<String> generate(
    List<Map<String, dynamic>> contents, {
    bool jsonOutput = false,
    String? preferModel,
  }) async {
    await _beforeCall();
    final converted = [for (final c in contents) _toContent(c)];
    final response = await _withModel(
      (model) =>
          _model(model, jsonOutput: jsonOutput).generateContent(converted),
      prefer: preferModel,
    );
    final text = response.text ?? '';
    if (text.isEmpty) throw const GeminiException('Modelden boş yanıt döndü');
    return text;
  }

  /// Araç çağrısı döngüsü (asistan/sesli not): model araç isterse çalıştırılır,
  /// sonuç geri beslenir; metin yanıtı gelince döner. Kota bir kez tüketilir.
  Future<String> runToolLoop(
    List<Map<String, dynamic>> contents,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> args,
    ) onToolCall, {
    String? prefer,
  }) async {
    await _beforeCall();
    final history = [for (final c in contents) _toContent(c)];
    for (var round = 0; round < 6; round++) {
      final response = await _withModel(
        (model) =>
            _model(model, tools: _assistantTools).generateContent(history),
        prefer: prefer,
      );
      final calls = response.functionCalls.toList();
      if (calls.isEmpty) {
        final text = response.text ?? '';
        if (text.isEmpty) {
          throw const GeminiException('Modelden boş yanıt döndü');
        }
        return text;
      }
      if (response.candidates.isNotEmpty) {
        history.add(response.candidates.first.content);
      }
      final results = <FunctionResponse>[];
      for (final call in calls) {
        Map<String, dynamic> result;
        try {
          result = await onToolCall(
            call.name,
            Map<String, dynamic>.from(call.args),
          );
        } catch (e) {
          result = {'status': 'error', 'message': e.toString()};
        }
        results.add(FunctionResponse(call.name, result));
      }
      history.add(Content.functionResponses(results));
    }
    throw const GeminiException('İşlem tamamlanamadı, tekrar deneyin');
  }

  /// GeminiService._assistantTools ile aynı sözleşme, firebase_ai tipleriyle.
  static final _assistantTools = [
    Tool.functionDeclarations([
      FunctionDeclaration(
        'create_note',
        'Yeni bir not oluşturur. Alışveriş/yapılacaklar için checklist, '
            'numaralı adımlar için ordered, diğerleri için text tipi.',
        parameters: {
          'type': Schema.enumString(enumValues: ['text', 'checklist', 'ordered']),
          'title': Schema.string(),
          'body': Schema.string(description: 'Yalnızca text tipinde'),
          'items': Schema.array(
            items: Schema.string(),
            description: 'Liste tiplerinde madde metinleri',
          ),
          'tags': Schema.array(items: Schema.string()),
          'reminderAt': Schema.string(
            description: 'ISO 8601 hatırlatıcı zamanı (isteğe bağlı)',
          ),
        },
        optionalParameters: ['body', 'items', 'tags', 'reminderAt'],
      ),
      FunctionDeclaration(
        'update_note',
        'Var olan bir notu günceller. noteId not defteri listesindeki id '
            'değeridir.',
        parameters: {
          'noteId': Schema.string(),
          'title': Schema.string(),
          'body': Schema.string(),
          'addItems': Schema.array(
            items: Schema.string(),
            description: 'Liste notuna eklenecek yeni maddeler',
          ),
          'setTags': Schema.array(items: Schema.string()),
          'reminderAt': Schema.string(description: 'ISO 8601'),
          'clearReminder': Schema.boolean(),
          'pinned': Schema.boolean(),
          'archived': Schema.boolean(),
        },
        optionalParameters: [
          'title',
          'body',
          'addItems',
          'setTags',
          'reminderAt',
          'clearReminder',
          'pinned',
          'archived',
        ],
      ),
      FunctionDeclaration(
        'delete_note',
        'Bir notu çöp kutusuna taşır (geri alınabilir).',
        parameters: {'noteId': Schema.string()},
      ),
    ]),
  ];
}
