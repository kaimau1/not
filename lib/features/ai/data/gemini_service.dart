import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../notes/domain/note.dart';
import 'api_key_store.dart';

final geminiServiceProvider = Provider<GeminiService>(
  (ref) => GeminiService(ref.watch(apiKeyStoreProvider)),
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
  });

  final String from;
  final String subject;
  final String summary;
  final String reason;
}

/// Gemini REST API istemcisi. Kullanıcının kendi anahtarıyla çalışır;
/// tüm istekler doğrudan Google'a gider, araya sunucu girmez.
class GeminiService {
  GeminiService(this._keyStore, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.geminiBaseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(minutes: 3),
            ));

  final ApiKeyStore _keyStore;
  final Dio _dio;

  static const _model = AppConstants.defaultGeminiModel;

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

  Future<String> _generate(
    List<Map<String, dynamic>> parts, {
    bool jsonOutput = false,
  }) async {
    final key = await _apiKey();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/models/$_model:generateContent',
        options: Options(headers: {'x-goog-api-key': key}),
        data: {
          'contents': [
            {'role': 'user', 'parts': parts},
          ],
          'generationConfig': {
            if (jsonOutput) 'responseMimeType': 'application/json',
          },
        },
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
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw switch (status) {
        400 || 401 || 403 =>
          const GeminiException('API anahtarı geçersiz', isAuthError: true),
        429 => const GeminiException('Kota aşıldı, sonra tekrar deneyin'),
        _ => GeminiException('Bağlantı hatası: ${e.message}'),
      };
    }
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

  /// Son notlara bakarak eyleme dönük öneriler üretir.
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
            'tamamlanmamış işler, unutulmuş alışveriş kalemleri, birleştirilecek '
            'notlar, takip gerektiren konular gibi. Her öneriyi tek maddede yaz.'
            '\n\n${buffer.toString()}',
      },
    ]);
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
    final raw = await _generate(
      [
        {
          'text': 'Aşağıda bir gelen kutusundaki son e-postaların listesi var '
              '(JSON). Önemli olanları seç (fatura/ödeme, randevu, iş, resmi '
              'kurum, son tarih içeren, kişisel önemli mesajlar; reklam ve '
              'toplu bültenleri ele). Yanıtı YALNIZCA şu şemada bir JSON '
              'dizisi olarak ver: '
              '[{"from": "...", "subject": "...", "summary": "1-2 cümle Türkçe '
              'özet", "reason": "neden önemli, birkaç kelime"}]. Önemli e-posta '
              'yoksa boş dizi döndür.\n\n${jsonEncode(list)}',
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
          ),
    ];
  }
}
