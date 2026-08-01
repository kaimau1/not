import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/utils/markdown.dart';
import '../../notes/domain/note.dart';
import '../../settings/settings_providers.dart';
import 'ai_gate.dart';
import 'api_key_store.dart';
import 'firebase_ai_client.dart';

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(
    ref.watch(apiKeyStoreProvider),
    taskModel: (task) => ref.read(aiTaskModelsProvider)[task],
    // Anahtar girilmemişse istekler dahili (Firebase AI Logic) yoldan
    // yapılır; her çağrı önce premium/kota kapısından geçer.
    builtIn: FirebaseAiClient(
      // Maliyet isteğin içeriğinden ölçülür (ek dosya türü + metin uzunluğu);
      // çağrı yerlerinin doğru puanı geçmesi beklenmez.
      beforeCall: (contents) =>
          ref.read(aiGateProvider).consume(AiCost.forContents(contents)),
    ),
  ),
);

/// Kullanılabilir model listesi — bir kez çözülüp önbelleklenir. Ayarlardaki
/// model seçicileri bunu izler; her yeniden çizimde `availableModels()`
/// yeniden çağrılıp FutureBuilder'ı sıfırlamaz. Eskiden bölüm her rebuild'de
/// önce boşalıp (yükseklik 0) sonra dolduğu için ayarlar sayfası anlık
/// zıplıyordu (madde 3).
final availableModelsProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(geminiServiceProvider).availableModels(),
);

class GeminiException implements Exception {
  const GeminiException(this.message, {this.isAuthError = false});

  final String message;
  final bool isAuthError;

  @override
  String toString() => message;
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
    String? Function(AiTask)? taskModel,
    this._builtIn,
  }) : _taskModel = taskModel ?? _noModel,
       _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: AppConstants.geminiBaseUrl,
               connectTimeout: const Duration(seconds: 20),
               receiveTimeout: const Duration(minutes: 3),
             ),
           );

  static String? _noModel(AiTask task) => null;

  final ApiKeyStore _keyStore;
  final Dio _dio;

  /// Anahtarsız kullanımda devreye giren dahili yol (Firebase AI Logic).
  /// null ise (testler) anahtar zorunlu kalır.
  final FirebaseAiClient? _builtIn;

  /// Ayarlardan gelen kullanıcı model seçimleri (null = otomatik).
  final String? Function(AiTask) _taskModel;

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
        400 || 401 || 403 => const GeminiException(
          'API anahtarı geçersiz',
          isAuthError: true,
        ),
        404 => const GeminiException(
          'AI modeli bulunamadı. Uygulamanın güncel sürümünü kurun; '
          'sorun sürerse geliştiriciye bildirin.',
        ),
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
    final extras =
        available
            .where(
              (id) =>
                  id.startsWith('gemini-') &&
                  id.contains('flash') &&
                  !AppConstants.geminiModelPreference.contains(id) &&
                  !RegExp('tts|live|image|audio|embed').hasMatch(id),
            )
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
    final ordered = [?first, ...candidates.where((m) => m != first)];
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
  }) => _generateFromContents(
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
    // Anahtar yoksa dahili yol: istek Firebase AI Logic üzerinden gider.
    final stored = await _keyStore.read();
    if (stored == null || stored.isEmpty) {
      final builtIn = _builtIn;
      if (builtIn == null) {
        throw const GeminiException('API anahtarı yok', isAuthError: true);
      }
      return builtIn.generate(
        contents,
        jsonOutput: jsonOutput,
        preferModel: preferModel ?? _taskModel(AiTask.general),
      );
    }
    final key = stored;
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
      prefer: preferModel ?? _taskModel(AiTask.general),
    );
    final candidates = response.data?['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const GeminiException('Modelden yanıt alınamadı');
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final responseParts = content?['parts'] as List<dynamic>? ?? const [];
    final text = [
      for (final part in responseParts)
        if ((part as Map<String, dynamic>)['text'] != null)
          part['text'] as String,
    ].join();
    if (text.isEmpty) {
      throw const GeminiException('Modelden boş yanıt döndü');
    }
    return text;
  }

  /// Notu Türkçe, kısa ve madde işaretli özetler.
  Future<String> summarizeNote(Note note) => _generate([
    {
      'text':
          'Aşağıdaki notu Türkçe olarak kısa ve öz biçimde özetle. '
          'Uygunsa madde işaretleri kullan. Yalnızca özeti yaz, başka '
          'açıklama ekleme.\n\n---\n${note.toPlainText()}',
    },
  ]);

  /// Notu analiz eder: ana temalar, eksikler, yapılacaklar.
  Future<String> analyzeNote(Note note) => _generate([
    {
      'text':
          'Aşağıdaki notu Türkçe analiz et: ana temaları çıkar, varsa '
          'eksik veya belirsiz noktaları belirt ve nottan doğan yapılacak '
          'işleri listele. Kısa ve eyleme dönük yaz.\n\n---\n'
          '${note.toPlainText()}',
    },
  ]);

  /// Kısa özet istemi: birkaç cümlelik genel bakış + önemli maddeler.
  static const _shortSummaryPrompt =
      'Türkçe olarak KISA ve öz biçimde özetle: önce 2-3 cümlelik genel '
      'özet, ardından önemli noktaları madde madde ver.';

  /// Detaylı özet istemi: kaynağa dönmeyi gereksiz kılan kapsamlı özet.
  static const _detailedSummaryPrompt =
      'Türkçe olarak KAPSAMLI ve DETAYLI bir özet çıkar. Amaç: okuyucunun '
      'kaynağı (PDF/sunum) hiç açmadan içeriği tam olarak anlayabilmesi. '
      'Belgeyi baştan sona işle; tüm ana bölümleri, önemli fikirleri, '
      'tanımları, verileri, örnekleri ve sonuçları kapsa. Önemli ayrıntıları '
      'ATLAMA, uydurma da EKLEME. Konu başlıklarına ayırıp her başlığın '
      'altında açıklayıcı ama akıcı paragraflar ve gerekli yerlerde maddeler '
      'kullan. Sonunda kısa bir "Özetin özeti" (ana çıkarımlar) bölümü ekle.';

  /// PDF'i doğrudan Gemini'ye gönderip Türkçe özet alır (inline base64,
  /// ~20 MB istek sınırına kadar). [detailed] true ise kaynağa bakmayı
  /// gereksiz kılan kapsamlı özet, değilse kısa özet üretilir.
  Future<String> summarizePdf(
    Uint8List bytes,
    String fileName, {
    bool detailed = false,
  }) => _generate([
    {
      'inline_data': {
        'mime_type': 'application/pdf',
        'data': base64Encode(bytes),
      },
    },
    {
      'text':
          '"$fileName" adlı bu PDF belgesini özetle. '
          '${detailed ? _detailedSummaryPrompt : _shortSummaryPrompt}',
    },
  ]);

  /// Sunum/belge metninden (PPTX'ten yerelde çıkarılan) Türkçe özet üretir.
  /// PPTX Gemini'ye doğrudan gönderilemediğinden metin çıkarılıp gönderilir.
  Future<String> summarizeDocumentText(
    String text,
    String fileName, {
    bool detailed = false,
  }) => _generate([
    {
      'text':
          '"$fileName" adlı sunum/belgenin metni aşağıdadır. '
          '${detailed ? _detailedSummaryPrompt : _shortSummaryPrompt}'
          '\n\n---\n$text',
    },
  ]);


  /// Görseldeki metni çıkarır (OCR) ve düzenli bir not metnine dönüştürür.
  Future<String> extractTextFromImage(Uint8List bytes, String mimeType) =>
      _generate([
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)},
        },
        {
          'text':
              'Bu görseldeki tüm metni çıkar ve düzenli, okunaklı bir not '
              'metnine dönüştür. Görselin dilini koru. Liste görüyorsan madde '
              'işaretleri kullan. Yalnızca çıkarılan metni yaz, açıklama '
              'ekleme. Görselde metin yoksa görülen içeriği 1-2 cümleyle '
              'Türkçe betimle.',
        },
      ]);

  /// Görüntülü nottan (video: görüntü + ses birlikte) detaylı bir not çıkarır.
  /// Modele videonun tamamı gider; süre sınırı çağıran tarafta uygulanır
  /// (satır içi gönderim boyutu sınırlıdır).
  Future<String> noteFromVideo(Uint8List bytes, String mimeType) => _generate([
    {
      'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)},
    },
    {
      'text':
          'Bu videoyu (görüntü ve ses birlikte) izle ve içeriğini, kendi '
          'defterine not alır gibi Türkçe yaz. '
          'Sabit başlık şablonu KULLANMA: "Özet", "Görülenler", '
          '"Konuşulanlar" gibi bölümler açma. Videoda ne varsa doğal bir '
          'akışla anlat — kısa paragraflar, sıralı ya da çok maddeli yerlerde '
          '"- " ile maddeler. '
          'Anlatıcı kalıplarından kaçın: "videoda ... görülüyor", '
          '"konuşmacı ... diyor", "bu videoda" deme. Bilginin kendisini yaz: '
          'toplantı saati geçiyorsa saati yaz, tahtadaki formül varsa '
          'formülü yaz. '
          'Videodan bir iş ya da hatırlatma çıkıyorsa onları en sona kısa '
          'maddeler hâlinde ekle. '
          'Videoda olmayan şeyi uydurma, tahmin yürütme, yorum katma. '
          'Markdown kullanma: yıldız, kalın işareti veya # koyma.',
    },
  ]).then(stripMarkdown);

  /// Ses kaydını yazıya döker.
  Future<String> transcribeAudio(Uint8List bytes, String mimeType) =>
      _generate([
        {
          'inline_data': {'mime_type': mimeType, 'data': base64Encode(bytes)},
        },
        {
          'text':
              'Bu ses kaydını konuşulan dilde yazıya dök. Yalnızca '
              'konuşmanın metnini yaz; dolgu seslerini (ııı, eee) atla, '
              'noktalama ekle. Kayıt bir alışveriş listesi veya yapılacaklar '
              'sayıyorsa madde işaretli liste olarak yaz.',
        },
      ]);

  /// Metni hedef dile çevirir.
  Future<String> translateText(String text, String targetLanguage) =>
      _generate([
        {
          'text':
              'Aşağıdaki metni $targetLanguage diline çevir. Anlamı ve '
              'tonu koru; biçimlendirmeyi (madde işaretleri, satırlar) aynen '
              'aktar. Yalnızca çeviriyi yaz, açıklama ekleme.\n\n---\n$text',
        },
      ], preferModel: _taskModel(AiTask.translate));

  /// Belgeyi SESLİ DİNLENEBİLİR bir anlatıya çevirir.
  ///
  /// Ham belge metnini olduğu gibi okutmak dinlenmez: tablo parçaları,
  /// "bkz. dipnot 3", madde işaretleri ve başlık kırıntıları sesli okunur.
  /// Bu istem metni tek seferde akıcı bir anlatıma dönüştürür — asıl işi
  /// yapan adım budur, seslendirme değil.
  /// [summarize] true ise belgeyi kısaltarak anlatır — uzun bir PDF'i baştan
  /// sona dinleyecek vakti olmayan için. Yapılan iş aynı model çağrısı,
  /// değişen yalnız "hepsini koru" ile "en önemlisini seç" talimatı.
  Future<String> podcastScript(
    String documentText, {
    String? title,
    bool summarize = false,
  }) => _generate([
    {
      'text':
          'Aşağıdaki belgeyi, SESLİ DİNLENMEK üzere akıcı bir Türkçe '
          'anlatıya dönüştür.${title == null ? '' : ' Belgenin adı: $title.'}\n'
          'Kurallar:\n'
          '- Kısa bir giriş cümlesiyle başla (konu ne).\n'
          '- Düz konuşma metni yaz: madde işareti, numara, başlık, '
          'yıldız, tire KULLANMA. Hepsi sesli okunduğunda saçma durur.\n'
          '- Tablo ve şekilleri cümleye çevir; okunamayanları atla.\n'
          '- Dipnot, sayfa numarası, kaynakça atıflarını çıkar.\n'
          '${summarize ? '- ÖZET anlat: yalnızca ana fikirleri ve sonuçları '
                'al, ayrıntıyı, örnekleri ve tekrarları at. Hedef uzunluk '
                'belgenin beşte biri kadar olsun.\n' : '- Belgenin kendi '
                'sırasını ve TÜM ana fikirlerini koru; özet değil, '
                'dinlenebilir tam anlatım istiyorum.\n'}'
          '- Kısa cümleler kur; uzun cümle sesli dinlemede takip edilemiyor.\n'
          '- Sonunda tek cümlelik kapanış yap.\n'
          'Yalnızca anlatı metnini yaz.\n\n---\n$documentText',
    },
  ], preferModel: _taskModel(AiTask.document));

  /// Ham brifing verisini (hatırlatıcılar, notlar) samimi ve kısa bir günlük
  /// brifinge dönüştürür.
  Future<String> composeBriefing(String rawData) => _generate([
    {
      'text':
          'Aşağıdaki ham verilerden kısa, samimi bir Türkçe "günlük '
          'brifing" yaz. Yapı: 1-2 cümlelik selamlama ve günün özeti; '
          '"Bugün" başlığı altında hatırlatıcılar ve yapılacaklar; varsa '
          '"E-postalar" başlığı altında önemli e-postalar; kapanışta tek '
          'cümlelik öneri. Kısa tut; veri yoksa o bölümü atla. Markdown '
          'kullanma: yıldız, kalın işareti veya # koyma, düz metin yaz.'
          '\n\n$rawData',
    },
  ]).then(stripMarkdown);

  /// Nota kısa bir Türkçe başlık üretir. Basit bir iş olduğu için hızlı ve
  /// ucuz lite model ilk sırada denenir.
  Future<String> generateTitle(Note note) async {
    final text = note.toPlainText();
    final raw = await _generate([
      {
        'text':
            'Aşağıdaki not için en fazla 5 kelimelik, kısa ve açıklayıcı '
            'bir Türkçe başlık üret. Yalnızca başlığı yaz; tırnak, nokta '
            'veya açıklama ekleme.\n\n---\n'
            '${text.length > 600 ? text.substring(0, 600) : text}',
      },
    ], preferModel: _taskModel(AiTask.general) ?? AppConstants.fastGeminiModel);
    // Model tırnak/yeni satır eklerse temizle, aşırı uzunsa kısalt.
    var title = raw.trim().split('\n').first.trim();
    title = title.replaceAll(RegExp('^["\'#*-]+|["\'.]+\$'), '').trim();
    return title.length > 60 ? title.substring(0, 60).trim() : title;
  }

  /// Nota uygun 1-3 kısa etiket önerir.
  Future<List<String>> suggestTags(Note note) async {
    final raw = await _generate([
      {
        'text':
            'Aşağıdaki not için 1-3 kısa Türkçe etiket öner (tek '
            'kelime, küçük harf, Türkçe karakter yerine ASCII tercih et; '
            'ör. "is", "ev", "saglik", "alisveris", "okul", "finans"). '
            'Yanıtı YALNIZCA JSON dizisi olarak ver: ["etiket1", "etiket2"]'
            '\n\n---\n${note.toPlainText()}',
      },
    ], jsonOutput: true);
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
      'text':
          'Aşağıdaki metni şu yönergeye göre yeniden yaz: '
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
            'text':
                '"$fileName" adlı bu PDF hakkında sorulara Türkçe, kısa '
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
    return _generateFromContents(
      contents,
      preferModel: _taskModel(AiTask.document),
    );
  }

  /// Tek bir not üzerinde çok turlu soru-cevap: notun metni ve ekleri
  /// (PDF/görsel) bağlam olarak verilir, yanıtlar yalnızca buna dayanır.
  Future<String> chatAboutNote({
    required Note note,
    required List<({Uint8List bytes, String mimeType, String fileName})>
    attachments,
    required List<ChatTurn> history,
  }) {
    final title = note.displayTitle.trim();
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          for (final a in attachments)
            {
              'inline_data': {
                'mime_type': a.mimeType,
                'data': base64Encode(a.bytes),
              },
            },
          {
            'text':
                'Aşağıda bir notun içeriği'
                '${attachments.isEmpty ? '' : ' ve ekleri'} var'
                '${title.isEmpty ? '' : ' (not başlığı: "$title")'}. '
                'Bu not hakkındaki sorulara Türkçe, kısa ve net yanıt ver. '
                'Yanıtları yalnızca notun içeriğine ve eklerine dayandır; '
                'olmayanı uydurma, bulamazsan bulamadığını söyle. Markdown '
                'kullanma, düz metin yaz.\n\n---\n${note.toPlainText()}',
          },
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Notu ve eklerini inceledim. Sorularını yanıtlayabilirim.'},
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
    return _generateFromContents(
      contents,
      preferModel: _taskModel(AiTask.document),
    ).then(stripMarkdown);
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
            for (final v
                in ((e as Map<String, dynamic>)['values'] as List<dynamic>? ??
                    const []))
              (v as num).toDouble(),
          ],
      ];
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Modele verilen "şu an" damgası: yerel saat + SAAT DİLİMİ OFSETİ + gün adı.
  ///
  /// Eskiden düz `DateTime.now().toIso8601String()` gidiyordu; o biçimde ofset
  /// YOK ve modeller böyle bir damgayı çoğu zaman UTC sanıyor. Gece yarısına
  /// yakın saatlerde bu, "yarın"ı bir gün kaydırıyordu. Gün adı da eklendi:
  /// "haftaya salı" gibi ifadeleri saymadan çözebilsin.
  static String _nowStamp() {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final local = now.toIso8601String().split('.').first;
    return '$local$sign$hours:$minutes (${days[now.weekday - 1]})';
  }

  /// Asistan konuşmalarının ortak giriş turları (kimlik + not bağlamı).
  static List<Map<String, dynamic>> _assistantPreamble(String notesContext) => [
    {
      'role': 'user',
      'parts': [
        {
          'text':
              'Sen "Notlar" uygulamasının asistanısın. Türkçe, kısa ve '
              'net yanıt ver. Kullanıcı senden not oluşturmanı, düzenlemeni '
              'veya silmeni isteyebilir; bunun için sana verilen araçları '
              'kullan. Tarihler için ISO 8601 kullan; şu an: '
              '${_nowStamp()}. Alışveriş/yapılacak '
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

  /// Sesli hızlı not: konuşmadan uygun notu asistan araçlarıyla oluşturur.
  ///
  /// [transcript] verilirse (cihazın yerleşik tanıması) modele yalnızca kısa
  /// METİN gider — ses göndermeye göre çok daha az token harcar ve model
  /// sesi yorumlamak yerine hazır metni yapılandırdığı için tip/içerik
  /// tutarsızlığı (boş not) sorunu ortadan kalkar. Yerleşik tanıma yoksa
  /// [audioBytes] ile eski ses yolu kullanılır.
  Future<String> assistantVoiceNote({
    required String notesContext,
    Uint8List? audioBytes,
    String? mimeType,
    String? transcript,
    required Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> args,
    )
    onToolCall,
  }) async {
    const task =
        'uygun bir not oluştur: alışveriş/yapılacaklar sayılıyorsa '
        'checklist, aksi hâlde metin. '
        'NOTUN İÇERİĞİ, İSTEĞİN KENDİSİ DEĞİL SONUCUDUR: kullanıcı notun '
        'içinde ne yazmasını istediğini tarif ediyorsa (ör. "içinde kalın '
        'harflerle kırmızı bir merhaba yazsın") nota O İÇERİĞİ yaz, komut '
        'cümlesini DEĞİL. '
        'BİÇİM: not metnine satır içi biçim işaretleri koyabilirsin — '
        '**kalın**, _italik_, ~altı çizili~, %%1:renkli yazı%% ve '
        '==1:renkli vurgu== (renk indeksleri: 1 kırmızı, 2 sarı, 3 yeşil, '
        '4 mavi, 5 mor). İşaretler kullanıcıya görünmez, yalnız biçim '
        'görünür; istenmiyorsa hiç kullanma. '
        'HATIRLATICI: konuşmada herhangi bir gün ya da saat geçiyorsa '
        '(yarın, salı, sabah 9, 14:00 ...) create_note çağrısında '
        'reminderAt alanını MUTLAKA doldur. Kullanıcının "hatırlat" demesi '
        'GEREKMEZ — "yarın sabah 9\'da toplantım var" demesi yeterlidir. '
        'Anlaşılır bir istek yoksa not oluşturma ve bunu belirt.';
    final hasTranscript = transcript != null && transcript.trim().isNotEmpty;
    if (!hasTranscript && audioBytes == null) {
      throw const GeminiException('Sesli not için içerik yok');
    }
    final contents = [
      ..._assistantPreamble(notesContext),
      {
        'role': 'user',
        'parts': [
          if (hasTranscript)
            {
              'text':
                  'Kullanıcının sesli notu: "${transcript.trim()}"\n\n'
                  'Bu konuşmadan $task',
            }
          else ...[
            {
              'inline_data': {
                'mime_type': mimeType ?? 'audio/mp4',
                'data': base64Encode(audioBytes!),
              },
            },
            {'text': 'Bu ses kaydındaki konuşmadan $task'},
          ],
        ],
      },
    ];
    // Kullanıcı bir model seçmediyse hızlı "lite" yerine daha güvenilir
    // standart flash tercih edilir: lite, araç çağrılı not oluşturmada
    // tipi/içeriği tutarsız verip boş not üretebiliyordu (madde 15).
    final prefer = _taskModel(AiTask.voice) ?? AppConstants.voiceAssistantModel;
    final stored = await _keyStore.read();
    if (stored == null || stored.isEmpty) {
      final builtIn = _builtIn;
      if (builtIn == null) {
        throw const GeminiException('API anahtarı yok', isAuthError: true);
      }
      return builtIn.runToolLoop(contents, onToolCall, prefer: prefer);
    }
    return _runToolLoop(stored, contents, onToolCall, prefer: prefer);
  }

  /// Asistan modu: model gerektiğinde not oluşturma/düzenleme araçlarını
  /// çağırır; araç sonuçları geri beslenir ve nihai metin yanıtı döner.
  Future<String> assistantChat({
    required String notesContext,
    required List<ChatTurn> history,
    required Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> args,
    )
    onToolCall,
  }) async {
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
    final stored = await _keyStore.read();
    if (stored == null || stored.isEmpty) {
      final builtIn = _builtIn;
      if (builtIn == null) {
        throw const GeminiException('API anahtarı yok', isAuthError: true);
      }
      return builtIn.runToolLoop(
        contents,
        onToolCall,
        prefer: _taskModel(AiTask.general),
      );
    }
    return _runToolLoop(
      stored,
      contents,
      onToolCall,
      prefer: _taskModel(AiTask.general),
    );
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
    )
    onToolCall, {
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
      final content =
          (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>? ??
          const {};
      final parts = content['parts'] as List<dynamic>? ?? const [];

      final functionCalls = <Map<String, dynamic>>[];
      final textBuffer = StringBuffer();
      for (final part in parts) {
        final map = part as Map<String, dynamic>;
        if (map['functionCall'] is Map) {
          functionCalls.add(
            Map<String, dynamic>.from(map['functionCall'] as Map),
          );
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
          'functionResponse': {'name': name, 'response': result},
        });
      }
      contents.add({'role': 'user', 'parts': responseParts});
    }
    throw const GeminiException('İşlem tamamlanamadı, tekrar deneyin');
  }

  static const _assistantTools = <Map<String, dynamic>>[
    {
      'name': 'create_note',
      'description':
          'Yeni bir not oluşturur. Alışveriş/yapılacaklar için '
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
            'description':
                'ISO 8601 hatırlatıcı zamanı. Konuşmada bir gün ya da saat '
                'geçiyorsa ("yarın sabah 9", "salı 14:00", "akşam") bu alanı '
                'MUTLAKA doldur — kullanıcı "hatırlat" demese, sadece '
                'planını anlatsa bile.',
          },
        },
        'required': ['type', 'title'],
      },
    },
    {
      'name': 'update_note',
      'description':
          'Var olan bir notu günceller. noteId not defteri '
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

}
