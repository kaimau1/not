import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../notes/domain/note.dart';
import '../../settings/settings_providers.dart';
import 'api_key_store.dart';

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(
    ref.watch(apiKeyStoreProvider),
    chatModel: () => ref.read(chatModelProvider),
    voiceModel: () => ref.read(voiceModelProvider),
  ),
);

class GeminiException implements Exception {
  const GeminiException(this.message, {this.isAuthError = false});

  final String message;
  final bool isAuthError;

  @override
  String toString() => message;
}

class EmailMeta {
  const EmailMeta({
    required this.id,
    required this.from,
    required this.subject,
    required this.date,
    required this.snippet,
  });

  final String id;
  final String from;
  final String subject;
  final String date;
  final String snippet;
}

class ImportantEmail {
  const ImportantEmail({
    required this.from,
    required this.subject,
    required this.summary,
    required this.reason,
    this.dueDate,
  });

  final String from;
  final String subject;
  final String summary;
  final String reason;

  /// E-postadan çıkarılan son tarih (fatura/randevu vb.), varsa.
  final DateTime? dueDate;
}

class ChatTurn {
  const ChatTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

/// Konuşma çevirmeninin tek bir tur sonucu.
class SpeechTranslation {
  const SpeechTranslation({
    required this.detectedLanguage,
    required this.transcript,
    required this.translation,
  });

  /// Konuşulan dilin adı (ör. "Türkçe").
  final String detectedLanguage;

  /// Konuşmanın kendi dilindeki dökümü.
  final String transcript;

  /// Karşı dile çevirisi.
  final String translation;
}

/// Gemini REST API istemcisi. Kullanıcının kendi anahtarıyla çalışır;
/// tüm istekler doğrudan Google'a gider, araya sunucu girmez.
class GeminiService {
  GeminiService(
    this._keyStore, {
    Dio? dio,
    String? Function()? chatModel,
    String? Function()? voiceModel,
  })  : _chatModel = chatModel ?? _noModel,
        _voiceModel = voiceModel ?? _noModel,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.geminiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 3),
            ));

  static String? _noModel() => null;

  final ApiKeyStore _keyStore;
  final Dio _dio;

  /// Ayarlardan gelen kullanıcı model seçimleri (null = otomatik).
  final String? Function() _chatModel;
  final String? Function() _voiceModel;

  /// Oturum önbelleği: API'den çekilen aday modeller ve son çalışan model.
  List<String>? _candidates;
  String? _activeModel;

  /// Anahtarın çalıştığını model listesini çekerek doğrular.
  Future<bool> validateKey(String key) async {
    try {
      final response = await _dio.get<dynamic>(
        '/models',
        options: Options(headers: {'x-goog-api-key': key}),
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  Future<String> _apiKey() async {
    final key = await _keyStore.read();
    if (key == null || key.isEmpty) {
      throw const GeminiException('API anahtarı yok', isAuthError: true);
    }
    return key;
  }

  static GeminiException _mapDioError(DioException e) =>
      switch (e.response?.statusCode) {
        400 || 401 || 403 =>
          const GeminiException('API anahtarı geçersiz', isAuthError: true),
        404 => const GeminiException(
            'AI modeli bulunamadı. Uygulamanın güncel sürümünü kurun; '
            'sorun sürerse geliştiriciye bildirin.'),
        429 => const GeminiException('Kota aşıldı, sonra tekrar deneyin'),
        _ => GeminiException('Bağlantı hatası: ${e.message}'),
      };

  /// Denenecek modeller: tercih listesi ∩ API'deki gerçek liste, ardından
  /// listede olmayan diğer genel amaçlı flash modelleri (yeniden eskiye).
  /// Liste çekilemezse tercih listesi olduğu gibi kullanılır.
  Future<List<String>> _fetchCandidates(String key) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/models',
        queryParameters: {'pageSize': 1000},
        options: Options(headers: {'x-goog-api-key': key}),
      );
      final models = response.data?['models'] as List<dynamic>? ?? const [];
      final available = <String>{
        for (final m in models)
          if (((m as Map<String, dynamic>)['supportedGenerationMethods']
                      as List<dynamic>? ??
                  const [])
              .contains('generateContent'))
            (m['name'] as String? ?? '').replaceFirst('models/', ''),
      };
      final list = rankModels(available);
      if (list.isNotEmpty) return list;
    } on DioException {
      // Liste çekilemedi; sabit tercih listesiyle devam edilir.
    }
    return AppConstants.geminiModelPreference;
  }

  /// API'deki modellerden deneme sırasını üretir: önce tercih listesi
  /// (mevcut olanlar), ardından tercihte olmayan genel amaçlı flash
  /// modelleri yeniden eskiye. TTS/canlı/görüntü/embedding elenir.
  static List<String> rankModels(Set<String> available) {
    final preferred = [
      for (final id in AppConstants.geminiModelPreference)
        if (available.contains(id)) id,
    ];
    final extras = available
        .where((id) =>
            id.startsWith('gemini-') &&
            id.contains('flash') &&
            !AppConstants.geminiModelPreference.contains(id) &&
            !RegExp('tts|live|image|audio|embed').hasMatch(id))
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return [...preferred, ...extras];
  }

  /// [run]'ı modellerle sırayla dener: 404 ve 429'da sıradaki modele geçer,
  /// diğer hatalar aynen fırlatılır. Çalışan model hatırlanır; sonraki
  /// çağrılar doğrudan onunla başlar. [prefer] verilirse o çağrı için ilk
  /// sıraya alınır (hız tercihi) ama genel sıralamayı değiştirmez.
  Future<T> _withModel<T>(
    String key,
    Future<T> Function(String model) run, {
    String? prefer,
  }) async {
    final candidates = _candidates ??= await _fetchCandidates(key);
    final first = prefer != null && candidates.contains(prefer)
        ? prefer
        : _activeModel;
    final ordered = [
      ?first,
      ...candidates.where((m) => m != first),
    ];
    DioException? lastSkipped;
    for (final model in ordered) {
      try {
        final result = await run(model);
        if (prefer == null) _activeModel = model;
        return result;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 404 || status == 429) {
          lastSkipped = e;
          continue;
        }
        throw _mapDioError(e);
      }
    }
    // ordered hiç boş olamaz; buraya düştüysek hepsi 404/429 verdi.
    throw _mapDioError(lastSkipped!);
  }

  Future<String> _generate(
    List<Map<String, dynamic>> parts, {
    bool jsonOutput = false,
    String? preferModel,
  }) =>
      _generateFromContents(
        [
          {'role': 'user', 'parts': parts},
        ],
        jsonOutput: jsonOutput,
        preferModel: preferModel,
      );

  Future<String> _generateFromContents(
    List<Map<String, dynamic>> contents, {
    bool jsonOutput = false,
    String? preferModel,
  }) async {
    final key = await _apiKey();
    final response = await _withModel(
      key,
      (model) => _dio.post<Map<String, dynamic>>(
        '/models/$model:generateContent',
        options: Options(headers: {'x-goog-api-key': key}),
        data: {
          'contents': contents,
          'generationConfig': {
            if (jsonOutput) 'responseMimeType': 'application/json',
          },
        },
      ),
      prefer: preferModel ?? _chatModel(),
    );
    final candidates = response.data?['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('Modelden yanıt alınamadı');
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    final responseParts = content?['parts'] as List<dynamic>? ?? const [];
    final text = [
      for (final part in responseParts)
        if ((part as Map<String, dynamic>)['text'] != null) part['text'] as String,
    ].join();
    if (text.isEmpty) {
      throw const GeminiException('Modelden boş yanıt döndü');
    }
    return text;
  }

  /// Notu Türkçe, kısa ve madde işaretli özetler.
  Future<String> summarizeNote(Note note) => _generate([
        {
          'text': 'Aşağıdaki notu Türkçe olarak kısa ve öz biçimde özetle. '
              'Uygunsa madde işaretleri kullan. Yalnızca özeti yaz, başka '
              'açıklama ekleme.\n\n---\n${note.toPlainText()}',
        },
      ]);

  /// Notu analiz eder: ana temalar, eksikler, yapılacaklar.
  Future<String> analyzeNote(Note note) => _generate([
        {
          'text': 'Aşağıdaki notu Türkçe analiz et: ana temaları çıkar, varsa '
              'eksik veya belirsiz noktaları belirt ve nottan doğan yapılacak '
              'işleri listele. Kısa ve eyleme dönük yaz.\n\n---\n'
              '${note.toPlainText()}',
        },
      ]);

  /// PDF'i doğrudan Gemini'ye gönderip Türkçe özet alır (inline base64,
  /// ~20 MB istek sınırına kadar).
  Future<String> summarizePdf(Uint8List bytes, String fileName) => _generate([
        {
          'inline_data': {
            'mime_type': 'application/pdf',
            'data': base64Encode(bytes),
          },
        },
        {
          'text': '"$fileName" adlı bu PDF belgesini Türkçe olarak özetle: '
              'önce 2-3 cümlelik genel özet, ardından önemli noktaları madde '
              'madde ver.',
        },
      ]);

  /// Son notlara bakarak eyleme dönük öneriler üretir (birleştirilebilecek
  /// notlar dahil).
  Future<String> suggestFromNotes(List<Note> notes) {
    final buffer = StringBuffer();
    for (final note in notes.take(30)) {
      final text = note.toPlainText();
      buffer
        ..writeln('---')
        ..writeln(text.length > 300 ? text.substring(0, 300) : text);
    }
    return _generate([
      {
        'text': 'Aşağıda bir kullanıcının not defterindeki son notlar var. '
            'Bu notlara bakarak Türkçe, kısa ve eyleme dönük 3-6 öneri üret: '
            'tamamlanmamış işler, unutulmuş alışveriş kalemleri, takip '
            'gerektiren konular gibi. Ayrıca konusu örtüşen veya tekrar eden '
            'notlar varsa hangilerinin birleştirilebileceğini ayrı bir maddede '
            'belirt. Her öneriyi tek maddede yaz.\n\n${buffer.toString()}',
      },
    ]);
  }

  /// Son 7 günün notlarından haftalık özet ve yapılacaklar çıkarır.
  Future<String> weeklySummary(List<Note> notes) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = [
      for (final note in notes)
        if ((note.updatedAt ?? note.createdAt)?.isAfter(cutoff) ?? false) note,
    ];
    if (recent.isEmpty) return Future.value('');
    final buffer = StringBuffer();
    for (final note in recent.take(40)) {
      final text = note.toPlainText();
      buffer
        ..writeln('---')
        ..writeln(text.length > 400 ? text.substring(0, 400) : text);
    }
    return _generate([
      {
        'text': 'Aşağıda kullanıcının son 7 günde yazdığı/güncellediği notlar '
            'var. Türkçe bir haftalık özet çıkar: (1) öne çıkan konular, '
            '(2) tamamlanmamış işler ve yapılacaklar, (3) önümüzdeki hafta '
            'için kısa öneriler. Bölüm başlıkları kullan, kısa ve öz yaz.'
            '\n\n${buffer.toString()}',
      },
    ]);
  }

  /// Görseldeki metni çıkarır (OCR) ve düzenli bir not metnine dönüştürür.
  Future<String> extractTextFromImage(Uint8List bytes, String mimeType) =>
      _generate([
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)},
        },
        {
          'text': 'Bu görseldeki tüm metni çıkar ve düzenli, okunaklı bir not '
              'metnine dönüştür. Görselin dilini koru. Liste görüyorsan madde '
              'işaretleri kullan. Yalnızca çıkarılan metni yaz, açıklama '
              'ekleme. Görselde metin yoksa görülen içeriği 1-2 cümleyle '
              'Türkçe betimle.',
        },
      ]);

  /// Ses kaydını yazıya döker.
  Future<String> transcribeAudio(Uint8List bytes, String mimeType) =>
      _generate([
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)},
        },
        {
          'text': 'Bu ses kaydını konuşulan dilde yazıya dök. Yalnızca '
              'konuşmanın metnini yaz; dolgu seslerini (ııı, eee) atla, '
              'noktalama ekle. Kayıt bir alışveriş listesi veya yapılacaklar '
              'sayıyorsa madde işaretli liste olarak yaz.',
        },
      ]);

  /// Metni hedef dile çevirir.
  Future<String> translateText(String text, String targetLanguage) =>
      _generate([
        {
          'text': 'Aşağıdaki metni $targetLanguage diline çevir. Anlamı ve '
              'tonu koru; biçimlendirmeyi (madde işaretleri, satırlar) aynen '
              'aktar. Yalnızca çeviriyi yaz, açıklama ekleme.\n\n---\n$text',
        },
      ]);

  /// Konuşma çevirmeni: ses kaydındaki konuşmanın dilini (A veya B) tespit
  /// eder, dökümünü çıkarır ve karşı dile çevirir.
  Future<SpeechTranslation> translateSpeech({
    required Uint8List bytes,
    required String mimeType,
    required String languageA,
    required String languageB,
  }) async {
    final raw = await _generate(
      [
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)},
        },
        {
          'text': 'Bu ses kaydı, $languageA ve $languageB konuşan iki kişi '
              'arasındaki bir sohbetin tek cümlesidir/turudur. '
              '1) Konuşulan dili tespit et ($languageA mı $languageB mi). '
              '2) Konuşmayı kendi dilinde yazıya dök. '
              '3) Karşı dile doğal biçimde çevir. '
              'Yanıtı YALNIZCA şu JSON şemasında ver: '
              '{"detectedLanguage": "dil adı", "transcript": "döküm", '
              '"translation": "çeviri"}',
        },
      ],
      jsonOutput: true,
    );
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const GeminiException('Çeviri yanıtı çözümlenemedi');
    }
    return SpeechTranslation(
      detectedLanguage: decoded['detectedLanguage'] as String? ?? '',
      transcript: decoded['transcript'] as String? ?? '',
      translation: decoded['translation'] as String? ?? '',
    );
  }

  /// Metni sese çevirir (TTS). Ham PCM (24 kHz, 16-bit, mono) döner.
  Future<Uint8List> synthesizeSpeech(String text) async {
    final key = await _apiKey();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/models/${AppConstants.geminiTtsModel}:generateContent',
        options: Options(headers: {'x-goog-api-key': key}),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': text},
              ],
            },
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': 'Kore'},
              },
            },
          },
        },
      );
      final candidates = response.data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException('Ses üretilemedi');
      }
      final content = (candidates.first as Map<String, dynamic>)['content']
          as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>? ?? const [];
      for (final part in parts) {
        final inline = (part as Map<String, dynamic>)['inlineData'] ??
            part['inline_data'];
        if (inline is Map && inline['data'] is String) {
          return base64Decode(inline['data'] as String);
        }
      }
      throw const GeminiException('Ses üretilemedi');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Ham brifing verisini (hatırlatıcılar, notlar, e-postalar) samimi ve
  /// kısa bir günlük brifinge dönüştürür.
  Future<String> composeBriefing(String rawData) => _generate([
        {
          'text': 'Aşağıdaki ham verilerden kısa, samimi bir Türkçe "günlük '
              'brifing" yaz. Yapı: 1-2 cümlelik selamlama ve günün özeti; '
              '"Bugün" başlığı altında hatırlatıcılar ve yapılacaklar; varsa '
              '"E-postalar" başlığı altında önemli e-postalar; kapanışta tek '
              'cümlelik öneri. Kısa tut; veri yoksa o bölümü atla.'
              '\n\n$rawData',
        },
      ]);

  /// Nota kısa bir Türkçe başlık üretir. Basit bir iş olduğu için hızlı ve
  /// ucuz lite model ilk sırada denenir.
  Future<String> generateTitle(Note note) async {
    final text = note.toPlainText();
    final raw = await _generate(
      [
        {
          'text': 'Aşağıdaki not için en fazla 5 kelimelik, kısa ve açıklayıcı '
              'bir Türkçe başlık üret. Yalnızca başlığı yaz; tırnak, nokta '
              'veya açıklama ekleme.\n\n---\n'
              '${text.length > 600 ? text.substring(0, 600) : text}',
        },
      ],
      preferModel: AppConstants.fastGeminiModel,
    );
    // Model tırnak/yeni satır eklerse temizle, aşırı uzunsa kısalt.
    var title = raw.trim().split('\n').first.trim();
    title = title.replaceAll(RegExp('^["\'#*-]+|["\'.]+\$'), '').trim();
    return title.length > 60 ? title.substring(0, 60).trim() : title;
  }

  /// Nota uygun 1-3 kısa etiket önerir.
  Future<List<String>> suggestTags(Note note) async {
    final raw = await _generate(
      [
        {
          'text': 'Aşağıdaki not için 1-3 kısa Türkçe etiket öner (tek '
              'kelime, küçük harf, Türkçe karakter yerine ASCII tercih et; '
              'ör. "is", "ev", "saglik", "alisveris", "okul", "finans"). '
              'Yanıtı YALNIZCA JSON dizisi olarak ver: ["etiket1", "etiket2"]'
              '\n\n---\n${note.toPlainText()}',
        },
      ],
      jsonOutput: true,
    );
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final tag in decoded.take(3))
        tag
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll('#', '')
            .replaceAll(' ', '-'),
    ];
  }

  /// Metni verilen yönergeye göre yeniden yazar (düzelt/resmîleştir/kısalt...).
  Future<String> rewriteText(String text, String instruction) => _generate([
        {
          'text': 'Aşağıdaki metni şu yönergeye göre yeniden yaz: '
              '"$instruction". Metnin dilini koru. Yalnızca yeniden yazılmış '
              'metni ver, açıklama ekleme.\n\n---\n$text',
        },
      ]);

  /// Ekli PDF üzerinde çok turlu soru-cevap.
  Future<String> chatWithPdf({
    required Uint8List bytes,
    required String fileName,
    required List<ChatTurn> history,
  }) {
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {
            'inline_data': {
              'mime_type': 'application/pdf',
              'data': base64Encode(bytes),
            },
          },
          {
            'text': '"$fileName" adlı bu PDF hakkında sorulara Türkçe, kısa '
                've net yanıt ver. Yanıtları yalnızca belgeye dayandır; '
                'belgede olmayanı uydurma, bulamazsan söyle.',
          },
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Belgeyi inceledim. Sorularını yanıtlamaya hazırım.'},
        ],
      },
      for (final turn in history)
        {
          'role': turn.isUser ? 'user' : 'model',
          'parts': [
            {'text': turn.text},
          ],
        },
    ];
    return _generateFromContents(contents);
  }

  /// Metinleri vektörlere çevirir (semantik arama için, toplu istek).
  Future<List<List<double>>> embedTexts(List<String> texts) async {
    if (texts.isEmpty) return const [];
    final key = await _apiKey();
    const embedModel = 'models/gemini-embedding-001';
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/$embedModel:batchEmbedContents',
        options: Options(headers: {'x-goog-api-key': key}),
        data: {
          'requests': [
            for (final text in texts)
              {
                'model': embedModel,
                'content': {
                  'parts': [
                    {'text': text},
                  ],
                },
                'outputDimensionality': 256,
              },
          ],
        },
      );
      final embeddings = response.data?['embeddings'] as List<dynamic>? ?? [];
      return [
        for (final e in embeddings)
          [
            for (final v in ((e as Map<String, dynamic>)['values']
                    as List<dynamic>? ??
                const []))
              (v as num).toDouble(),
          ],
      ];
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Asistan konuşmalarının ortak giriş turları (kimlik + not bağlamı).
  static List<Map<String, dynamic>> _assistantPreamble(String notesContext) => [
        {
          'role': 'user',
          'parts': [
            {
              'text': 'Sen "Notlar" uygulamasının asistanısın. Türkçe, kısa ve '
                  'net yanıt ver. Kullanıcı senden not oluşturmanı, düzenlemeni '
                  'veya silmeni isteyebilir; bunun için sana verilen araçları '
                  'kullan. Tarihler için ISO 8601 kullan; şu an: '
                  '${DateTime.now().toIso8601String()}. Alışveriş/yapılacak '
                  'listeleri için "checklist" tipini kullan. Bir aracı '
                  'çağırdıktan sonra kullanıcıya ne yaptığını tek cümleyle '
                  'özetle.\n\nKULLANICININ NOT DEFTERİ:\n$notesContext',
            },
          ],
        },
        {
          'role': 'model',
          'parts': [
            {'text': 'Anladım. Notların üzerinde çalışmaya hazırım.'},
          ],
        },
      ];

  /// Sesli hızlı not: ses kaydı TEK çağrıda yazıya dökülür ve asistan uygun
  /// notu araçlarıyla oluşturur (eski akış: ayrı transkripsiyon + asistan =
  /// iki kat gecikme). Hız için küçük model ilk sırada denenir.
  Future<String> assistantVoiceNote({
    required String notesContext,
    required Uint8List audioBytes,
    required String mimeType,
    required Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> args,
    ) onToolCall,
  }) async {
    final key = await _apiKey();
    final contents = [
      ..._assistantPreamble(notesContext),
      {
        'role': 'user',
        'parts': [
          {
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Encode(audioBytes),
            },
          },
          {
            'text': 'Bu ses kaydındaki konuşmadan uygun bir not oluştur: '
                'alışveriş/yapılacaklar sayılıyorsa checklist, aksi hâlde '
                'metin; tarih/saat geçiyorsa hatırlatıcı ekle. Kayıtta '
                'anlaşılır konuşma yoksa not oluşturma ve bunu belirt.',
          },
        ],
      },
    ];
    return _runToolLoop(
      key,
      contents,
      onToolCall,
      prefer: _voiceModel() ?? AppConstants.fastGeminiModel,
    );
  }

  /// Asistan modu: model gerektiğinde not oluşturma/düzenleme araçlarını
  /// çağırır; araç sonuçları geri beslenir ve nihai metin yanıtı döner.
  Future<String> assistantChat({
    required String notesContext,
    required List<ChatTurn> history,
    required Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> args,
    ) onToolCall,
  }) async {
    final key = await _apiKey();
    final contents = [
      ..._assistantPreamble(notesContext),
      for (final turn in history)
        {
          'role': turn.isUser ? 'user' : 'model',
          'parts': [
            {'text': turn.text},
          ],
        },
    ];
    return _runToolLoop(key, contents, onToolCall, prefer: _chatModel());
  }

  /// Ayarlardaki model seçicileri için kullanılabilir model listesi.
  Future<List<String>> availableModels() async {
    final key = await _keyStore.read();
    if (key == null || key.isEmpty) return AppConstants.geminiModelPreference;
    return _candidates ??= await _fetchCandidates(key);
  }

  /// Araç çağrısı döngüsü: model araç isterse çalıştırılır, sonuç geri
  /// beslenir; metin yanıtı gelince döner.
  Future<String> _runToolLoop(
    String key,
    List<Map<String, dynamic>> contents,
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> args,
    ) onToolCall, {
    String? prefer,
  }) async {

    for (var round = 0; round < 6; round++) {
      final response = await _withModel(
        key,
        (model) => _dio.post<Map<String, dynamic>>(
          '/models/$model:generateContent',
          options: Options(headers: {'x-goog-api-key': key}),
          data: {
            'contents': contents,
            'tools': [
              {'functionDeclarations': _assistantTools},
            ],
          },
        ),
        prefer: prefer,
      );
      final data = response.data;

      final candidates = data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException('Modelden yanıt alınamadı');
      }
      final content = (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>? ??
          const {};
      final parts = content['parts'] as List<dynamic>? ?? const [];

      final functionCalls = <Map<String, dynamic>>[];
      final textBuffer = StringBuffer();
      for (final part in parts) {
        final map = part as Map<String, dynamic>;
        if (map['functionCall'] is Map) {
          functionCalls.add(Map<String, dynamic>.from(map['functionCall'] as Map));
        }
        if (map['text'] is String) textBuffer.write(map['text'] as String);
      }

      if (functionCalls.isEmpty) {
        final text = textBuffer.toString();
        if (text.isEmpty) {
          throw const GeminiException('Modelden boş yanıt döndü');
        }
        return text;
      }

      contents.add({
        'role': 'model',
        'parts': [for (final part in parts) part as Map<String, dynamic>],
      });
      final responseParts = <Map<String, dynamic>>[];
      for (final call in functionCalls) {
        final name = call['name'] as String? ?? '';
        final args = call['args'] is Map
            ? Map<String, dynamic>.from(call['args'] as Map)
            : <String, dynamic>{};
        Map<String, dynamic> result;
        try {
          result = await onToolCall(name, args);
        } catch (e) {
          result = {'status': 'error', 'message': e.toString()};
        }
        responseParts.add({
          'functionResponse': {
            'name': name,
            'response': result,
          },
        });
      }
      contents.add({'role': 'user', 'parts': responseParts});
    }
    throw const GeminiException('İşlem tamamlanamadı, tekrar deneyin');
  }

  static const _assistantTools = <Map<String, dynamic>>[
    {
      'name': 'create_note',
      'description': 'Yeni bir not oluşturur. Alışveriş/yapılacaklar için '
          'checklist, numaralı adımlar için ordered, diğerleri için text tipi.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'type': {
            'type': 'STRING',
            'enum': ['text', 'checklist', 'ordered'],
          },
          'title': {'type': 'STRING'},
          'body': {'type': 'STRING', 'description': 'Yalnızca text tipinde'},
          'items': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
            'description': 'Liste tiplerinde madde metinleri',
          },
          'tags': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'reminderAt': {
            'type': 'STRING',
            'description': 'ISO 8601 hatırlatıcı zamanı (isteğe bağlı)',
          },
        },
        'required': ['type', 'title'],
      },
    },
    {
      'name': 'update_note',
      'description': 'Var olan bir notu günceller. noteId not defteri '
          'listesindeki id değeridir.',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'noteId': {'type': 'STRING'},
          'title': {'type': 'STRING'},
          'body': {'type': 'STRING'},
          'addItems': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
            'description': 'Liste notuna eklenecek yeni maddeler',
          },
          'setTags': {
            'type': 'ARRAY',
            'items': {'type': 'STRING'},
          },
          'reminderAt': {'type': 'STRING', 'description': 'ISO 8601'},
          'clearReminder': {'type': 'BOOLEAN'},
          'pinned': {'type': 'BOOLEAN'},
          'archived': {'type': 'BOOLEAN'},
        },
        'required': ['noteId'],
      },
    },
    {
      'name': 'delete_note',
      'description': 'Bir notu çöp kutusuna taşır (geri alınabilir).',
      'parameters': {
        'type': 'OBJECT',
        'properties': {
          'noteId': {'type': 'STRING'},
        },
        'required': ['noteId'],
      },
    },
  ];

  /// Kullanıcının notları üzerinde çok turlu sohbet.
  Future<String> chatWithNotes({
    required List<Note> notes,
    required List<ChatTurn> history,
  }) {
    final buffer = StringBuffer();
    for (final note in notes.take(60)) {
      final text = note.toPlainText();
      buffer
        ..writeln('---')
        ..writeln(text.length > 500 ? text.substring(0, 500) : text);
    }
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {
            'text': 'Sen "Notlar" uygulamasının asistanısın. Kullanıcının not '
                'defteri aşağıdadır. Sorulara bu notlara dayanarak Türkçe, '
                'kısa ve net yanıt ver; notlarda olmayan bilgiyi uydurma, '
                'bulamazsan söyle.\n\nNOT DEFTERİ:\n${buffer.toString()}',
          },
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Anladım. Notlarına göre sorularını yanıtlamaya hazırım.'},
        ],
      },
      for (final turn in history)
        {
          'role': turn.isUser ? 'user' : 'model',
          'parts': [
            {'text': turn.text},
          ],
        },
    ];
    return _generateFromContents(contents);
  }

  /// E-posta metadata'larından önemlilerini seçer ve kısa Türkçe özet döner.
  Future<List<ImportantEmail>> triageEmails(List<EmailMeta> emails) async {
    final list = [
      for (final email in emails)
        {
          'id': email.id,
          'from': email.from,
          'subject': email.subject,
          'date': email.date,
          'snippet': email.snippet,
        },
    ];
    final now = DateTime.now();
    final raw = await _generate(
      [
        {
          'text': 'Aşağıda bir gelen kutusundaki son e-postaların listesi var '
              '(JSON). Bugünün tarihi: ${now.year}-${now.month}-${now.day}. '
              'Önemli olanları seç (fatura/ödeme, randevu, iş, resmi '
              'kurum, son tarih içeren, kişisel önemli mesajlar; reklam ve '
              'toplu bültenleri ele). Yanıtı YALNIZCA şu şemada bir JSON '
              'dizisi olarak ver: '
              '[{"from": "...", "subject": "...", "summary": "1-2 cümle Türkçe '
              'özet", "reason": "neden önemli, birkaç kelime", "dueDate": '
              '"YYYY-MM-DDTHH:MM" veya son tarih/randevu yoksa null}]. '
              'Önemli e-posta yoksa boş dizi döndür.\n\n${jsonEncode(list)}',
        },
      ],
      jsonOutput: true,
    );
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final entry in decoded)
        if (entry is Map)
          ImportantEmail(
            from: entry['from'] as String? ?? '',
            subject: entry['subject'] as String? ?? '',
            summary: entry['summary'] as String? ?? '',
            reason: entry['reason'] as String? ?? '',
            dueDate: entry['dueDate'] is String
                ? DateTime.tryParse(entry['dueDate'] as String)
                : null,
          ),
    ];
  }
}
