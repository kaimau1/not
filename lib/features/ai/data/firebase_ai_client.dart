import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/constants.dart';
import 'gemini_service.dart' show GeminiException;

/// Dahili AI'ın son ham hatalarını tutar. [FirebaseAiClient._mapError]
/// kullanıcıya sade Türkçe mesaj döndürdüğü için ham metin (hangi model,
/// hangi hata) aksi hâlde kayboluyor ve "çalışmıyor" şikâyeti teşhis
/// edilemiyordu. Ayarlar > AI tanılama bu listeyi gösterir.
///
/// Bellekte, en fazla [_max] kayıt; kalıcı değil (uygulama kapanınca silinir)
/// ve kişisel veri içermez — yalnız model adı, zaman ve hata metni.
class AiDiagnostics {
  AiDiagnostics._();

  static const int _max = 10;
  static final List<String> _entries = [];

  static List<String> get entries => List.unmodifiable(_entries.reversed);

  static void record(String model, Object error) {
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    _entries.add('[$stamp] $model → $error');
    if (_entries.length > _max) _entries.removeAt(0);
  }

  static void clear() => _entries.clear();
}

/// Anahtarsız "dahili AI": istekler Firebase AI Logic üzerinden (Gemini
/// Developer API arka ucu) uygulamanın kendi Firebase projesiyle yapılır.
/// Kullanıcıdan API anahtarı istenmez ve cihazda anahtar bulunmaz; kötüye
/// kullanım App Check + [beforeCall] kotasıyla sınırlanır.
///
/// İçerikler GeminiService'in REST biçimindeki ham map'leriyle gelir ve
/// burada firebase_ai tiplerine çevrilir; böylece tüm istem metinleri tek
/// yerde (GeminiService) kalır.
class FirebaseAiClient {
  FirebaseAiClient({
    Future<void> Function(List<Map<String, dynamic>> contents)? beforeCall,
  }) : _beforeCall = beforeCall ?? _noop;

  static Future<void> _noop(List<Map<String, dynamic>> _) async {}

  /// Kullanıcıya görünür her AI eylemi öncesi çağrılır (premium/kota kapısı).
  /// Gönderilecek içerik verilir ki kota isteğin gerçek maliyetine göre
  /// düşülebilsin. Kota bittiyse [GeminiException] fırlatarak isteği durdurur.
  final Future<void> Function(List<Map<String, dynamic>> contents) _beforeCall;

  static List<String> _candidates(String? prefer) => [
    ?prefer,
    for (final model in AppConstants.geminiModelPreference)
      if (model != prefer) model,
  ];

  GenerativeModel _model(
    String modelId, {
    bool jsonOutput = false,
    List<Tool>? tools,
  }) => FirebaseAI.googleAI().generativeModel(
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
        parts.add(
          InlineDataPart(
            inline['mime_type'] as String? ??
                inline['mimeType'] as String? ??
                'application/octet-stream',
            base64Decode(inline['data'] as String),
          ),
        );
      }
      // Bağlantıyla verilen dosya (YouTube videosu — bkz. transcribeMedia).
      final file = map['file_data'] ?? map['fileData'];
      if (file is Map) {
        parts.add(
          FileData(
            file['mime_type'] as String? ??
                file['mimeType'] as String? ??
                'video/mp4',
            (file['file_uri'] ?? file['fileUri']) as String,
          ),
        );
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
        _isTransient(e);
  }

  /// Modelin kendisiyle değil, o anki YÜKLE ilgili geçici hatalar. Bunlarda
  /// sıradaki modele atlamak çare değildir (arka uç zaten meşguldür); kısa
  /// bir bekleyişten sonra AYNI model yeniden denenir. Bu ayrım olmadan üç
  /// model saniyeler içinde tükeniyor ve istek "bazen çalışıyor bazen
  /// çalışmıyor" görünümü veriyordu.
  static bool _isTransient(Object e) {
    final message = e is FirebaseAIException
        ? e.message.toLowerCase()
        : e.toString().toLowerCase();
    return message.contains('overloaded') ||
        message.contains('unavailable') ||
        message.contains('deadline') ||
        message.contains('timeout') ||
        message.contains('timed out') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('503') ||
        message.contains('429');
  }

  /// Tek bir modele yapılan istek için üst sınır. Sınırsız bekleyiş, ağ
  /// koptuğunda kullanıcıyı süresiz dönen çarkla baş başa bırakıyordu.
  static const Duration _requestTimeout = Duration(seconds: 90);

  /// Geçici hatada aynı modelin yeniden denenme sayısı ve bekleyişleri.
  static const List<Duration> _backoff = [
    Duration(milliseconds: 400),
    Duration(milliseconds: 1200),
  ];

  Future<T> _withModel<T>(
    Future<T> Function(String model) run, {
    String? prefer,
    Duration? timeout,
  }) async {
    final models = _candidates(prefer);
    Object? lastSkipped;
    for (var i = 0; i < models.length; i++) {
      for (var attempt = 0; attempt <= _backoff.length; attempt++) {
        try {
          return await run(models[i]).timeout(timeout ?? _requestTimeout);
        } on Object catch (e) {
          AiDiagnostics.record(models[i], e);
          if (_isTransient(e) && attempt < _backoff.length) {
            await Future<void>.delayed(_backoff[attempt]);
            continue; // aynı model, kısa bekleyişten sonra
          }
          if (e is! FirebaseAIException) {
            if (_isTransient(e)) {
              lastSkipped = e;
              break; // sıradaki modeli dene
            }
            throw _mapError(e);
          }
          // İlk sıradaki [prefer] yalnızca bir HIZ tercihidir (ör. otomatik
          // başlıkta hızlı "lite" modeli). O model bu arka uçta yoksa dönen
          // hata her zaman "not found" kalıbına uymayabilir; bu durumda istek
          // tümden başarısız olmasın diye tercih denemesinin HER hatasında
          // sıradaki (standart) modele düşülür.
          final isPreferHint = prefer != null && i == 0;
          if (isPreferHint || _shouldTryNext(e)) {
            lastSkipped = e;
            break; // sıradaki modeli dene
          }
          throw _mapError(e);
        }
      }
    }
    throw _mapError(lastSkipped);
  }

  /// Firebase AI Logic hatalarını kullanıcının anlayacağı Türkçe mesaja
  /// çevirir. En sık karşılaşılan iki durum: (1) konsolda AI Logic hiç
  /// etkinleştirilmemiş, (2) App Check zorunlu ama token geçersiz.
  static GeminiException _mapError(Object? error) {
    final e = error is FirebaseAIException ? error : null;
    final message = (e?.message ?? error?.toString() ?? '').toLowerCase();
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
    // Projenin Gemini faturası/ön ödemeli kredisi bittiğinde tüm modeller bu
    // hatayı verir (İngilizce "prepayment credits are depleted / billing").
    // Kullanıcıya ham İngilizce metin yerine kendi anahtarını girme yolunu
    // gösteririz — dahili AI parası bitmiştir, kendi anahtarı sınırsızdır.
    if (message.contains('prepay') ||
        message.contains('billing') ||
        message.contains('credit') ||
        message.contains('depleted') ||
        message.contains('resource_exhausted')) {
      return const GeminiException(
        'Dahili yapay zeka şu an kullanılamıyor. Kendi Gemini anahtarını '
        "Ayarlar'dan girerek AI özelliklerini hemen kullanabilirsin.",
        isAuthError: true,
      );
    }
    return GeminiException(
      'Yapay zeka şu an yanıt veremiyor: '
      '${e?.message ?? error?.toString() ?? 'bilinmeyen hata'}',
    );
  }

  /// Tek seferlik üretim (REST'teki generateContent karşılığı).
  Future<String> generate(
    List<Map<String, dynamic>> contents, {
    bool jsonOutput = false,
    String? preferModel,
    Duration? timeout,
  }) async {
    await _beforeCall(contents);
    final converted = [for (final c in contents) _toContent(c)];
    final response = await _withModel(
      (model) =>
          _model(model, jsonOutput: jsonOutput).generateContent(converted),
      prefer: preferModel,
      timeout: timeout,
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
    )
    onToolCall, {
    String? prefer,
  }) async {
    await _beforeCall(contents);
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
          'type': Schema.enumString(
            enumValues: ['text', 'checklist', 'ordered'],
          ),
          'title': Schema.string(),
          'body': Schema.string(description: 'Yalnızca text tipinde'),
          'items': Schema.array(
            items: Schema.string(),
            description: 'Liste tiplerinde madde metinleri',
          ),
          'tags': Schema.array(items: Schema.string()),
          'reminderAt': Schema.string(
            description:
                'ISO 8601 hatırlatıcı zamanı. Konuşmada bir gün ya da saat '
                'geçiyorsa ("yarın sabah 9", "salı 14:00", "akşam") bu alanı '
                'MUTLAKA doldur — kullanıcı "hatırlat" demese, sadece '
                'planını anlatsa bile.',
          ),
        },
        optionalParameters: ['body', 'items', 'tags', 'reminderAt'],
      ),
      FunctionDeclaration(
        'update_note',
        'Var olan bir notu günceller: içeriği, maddeleri, etiketleri VE notun '
            'kendi görünümü/durumu (renk, çerçeve rengi, sabitle, yıldızla, '
            'arşivle, kilitle, hatırlatıcı). Kullanıcı "bu notu kırmızı '
            'çerçeveye al", "sarı yap", "yıldızla", "sütü işaretle" gibi bir '
            'şey isterse İSTEĞİ NOTUN İÇİNE MADDE OLARAK YAZMA — buradaki '
            'uygun alanı kullan. noteId not defteri listesindeki id değeridir.',
        parameters: {
          'noteId': Schema.string(),
          'title': Schema.string(),
          'body': Schema.string(),
          'addItems': Schema.array(
            items: Schema.string(),
            description: 'Liste notuna eklenecek yeni maddeler',
          ),
          'checkItems': Schema.array(
            items: Schema.string(),
            description: 'Tamamlandı olarak işaretlenecek maddeler',
          ),
          'uncheckItems': Schema.array(
            items: Schema.string(),
            description: 'İşareti kaldırılacak maddeler',
          ),
          'removeItems': Schema.array(
            items: Schema.string(),
            description: 'Silinecek maddeler',
          ),
          'setTags': Schema.array(items: Schema.string()),
          'color': Schema.string(
            description:
                'Notun ZEMİN rengi: red, peach, amber, green, sage, blue, '
                'storm, purple, blossom, clay, chalk ya da none.',
          ),
          'frameColor': Schema.string(
            description:
                'Notun ÇERÇEVE rengi (kartın kenarlığı); değerler color ile '
                'aynı. "kırmızı çerçeve" isteği bu alandır.',
          ),
          'starred': Schema.boolean(),
          'locked': Schema.boolean(),
          'reminderAt': Schema.string(description: 'ISO 8601'),
          'clearReminder': Schema.boolean(),
          'pinned': Schema.boolean(),
          'archived': Schema.boolean(),
        },
        optionalParameters: [
          'title',
          'body',
          'addItems',
          'checkItems',
          'uncheckItems',
          'removeItems',
          'setTags',
          'color',
          'frameColor',
          'starred',
          'locked',
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
