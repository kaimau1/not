// Çeviri üretim aracı: kaynak ARB'yi hedef dillere çevirir.
//
// NEDEN BİR ARAÇ: uygulamada 450'ye yakın çeviri anahtarı var. 100 dil,
// 45.000 dizge demek — elle yazılamaz, yazılsa gözden geçirilemez. Bu araç
// çeviriyi modele yaptırır, ARB dosyasını üretir ve TEKRAR çalıştırıldığında
// yalnız EKSİK anahtarları çevirir (var olanlara dokunmaz). Yani yeni bir
// anahtar eklendiğinde 100 dili baştan çevirmek gerekmez.
//
// KULLANIM:
//   dart run tool/translate_arb.dart --key=<API_ANAHTARI> --langs=fr,it,ja
//   dart run tool/translate_arb.dart --key=... --langs=fr --force
//
//   --provider  gemini (varsayılan) | openai | openrouter | anthropic
//   --model     sağlayıcının model kimliği (varsayılanlar aşağıda)
//   --source    kaynak ARB (varsayılan lib/l10n/app_en.arb)
//   --force     var olan çevirileri de yeniden üretir
//
// Çeviri bittikten sonra `flutter pub get` (ya da `flutter gen-l10n`)
// üretilen sınıfları tazeler; dil, ARB dosyası var olduğu anda Ayarlar'daki
// listede kendiliğinden görünür (bkz. `supportedLanguages`).
//
// ⚠️ Yalnız `language_names.dart` içindeki dillere çeviri üretin: Flutter'ın
// hazır Material/Cupertino çevirisi olmayan bir yerel ayar uygulamayı o dilde
// çalışma anında hataya düşürür.

import 'dart:convert';
import 'dart:io';

const _defaultModels = <String, String>{
  'gemini': 'gemini-3.1-flash',
  'openai': 'gpt-5-mini',
  'openrouter': 'google/gemini-3.1-flash',
  'anthropic': 'claude-haiku-4-5',
};

/// Tek istekte gönderilen anahtar sayısı. Küçük tutmanın nedeni doğruluk
/// değil dayanıklılık: model tek bir dev JSON'da bir anahtarı atlarsa o
/// paketin tamamı boşa gider ve hangi anahtarın kaybolduğu belli olmaz.
const _batchSize = 40;

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final key = options['key'];
  final langs = (options['langs'] ?? '')
      .split(',')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  if (key == null || key.isEmpty || langs.isEmpty) {
    stderr.writeln(
      'Kullanım: dart run tool/translate_arb.dart '
      '--key=<API_ANAHTARI> --langs=fr,it,ja [--provider=gemini] '
      '[--model=...] [--source=lib/l10n/app_en.arb] [--force]',
    );
    exitCode = 64; // EX_USAGE
    return;
  }

  final provider = options['provider'] ?? 'gemini';
  if (!_defaultModels.containsKey(provider)) {
    stderr.writeln('Bilinmeyen sağlayıcı: $provider');
    exitCode = 64;
    return;
  }
  final model = options['model'] ?? _defaultModels[provider]!;
  final sourcePath = options['source'] ?? 'lib/l10n/app_en.arb';
  final force = options.containsKey('force');

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    stderr.writeln('Kaynak bulunamadı: $sourcePath');
    exitCode = 66; // EX_NOINPUT
    return;
  }
  final source = jsonDecode(sourceFile.readAsStringSync()) as Map<String, dynamic>;

  final client = HttpClient();
  try {
    for (final lang in langs) {
      await _translateLanguage(
        client: client,
        lang: lang,
        source: source,
        provider: provider,
        model: model,
        apiKey: key,
        force: force,
      );
    }
  } finally {
    client.close();
  }
}

Future<void> _translateLanguage({
  required HttpClient client,
  required String lang,
  required Map<String, dynamic> source,
  required String provider,
  required String model,
  required String apiKey,
  required bool force,
}) async {
  final targetFile = File('lib/l10n/app_$lang.arb');
  final existing = targetFile.existsSync()
      ? jsonDecode(targetFile.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};

  // '@' ile başlayan anahtarlar meta veridir (açıklama, yer tutucu tipleri);
  // çevrilmez, kaynaktan aynen taşınır.
  final translatable = <String, String>{
    for (final entry in source.entries)
      if (!entry.key.startsWith('@') && entry.value is String)
        entry.key: entry.value as String,
  };
  final missing = <String, String>{
    for (final entry in translatable.entries)
      if (force || !existing.containsKey(entry.key)) entry.key: entry.value,
  };

  if (missing.isEmpty) {
    stdout.writeln('$lang: eksik anahtar yok, atlandı');
    return;
  }
  stdout.writeln('$lang: ${missing.length} anahtar çevriliyor...');

  final result = <String, dynamic>{...existing};
  final keys = missing.keys.toList();
  for (var i = 0; i < keys.length; i += _batchSize) {
    final slice = keys.sublist(
      i,
      i + _batchSize > keys.length ? keys.length : i + _batchSize,
    );
    final batch = {for (final k in slice) k: missing[k]!};
    final translated = await _translateBatch(
      client: client,
      lang: lang,
      batch: batch,
      provider: provider,
      model: model,
      apiKey: apiKey,
    );
    // Modelin atladığı anahtar KAYNAK metniyle doldurulur. Anahtarı hiç
    // yazmamak, gen-l10n'un o dizgede sessizce şablon dile düşmesi demek —
    // aynı sonuç ama eksiğin izi kalmaz. Böyle bir anahtar bir sonraki
    // koşuda 'var' sayılacağından `--force` ile yeniden denenebilir.
    for (final entry in batch.entries) {
      result[entry.key] = translated[entry.key] ?? entry.value;
    }
    stdout.writeln(
      '  ${i + slice.length}/${keys.length}'
      '${translated.length < slice.length ? ' (${slice.length - translated.length} eksik, kaynak metin kondu)' : ''}',
    );
  }

  // Anahtar sırası kaynakla aynı tutulur: dosyalar arası diff okunabilir kalır.
  final ordered = <String, dynamic>{
    for (final k in source.keys)
      if (result.containsKey(k)) k: result[k],
  };
  targetFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(ordered)}\n',
  );
  stdout.writeln('$lang: yazıldı → ${targetFile.path}');
}

Future<Map<String, String>> _translateBatch({
  required HttpClient client,
  required String lang,
  required Map<String, String> batch,
  required String provider,
  required String model,
  required String apiKey,
}) async {
  final prompt =
      'Aşağıdaki JSON, bir not alma uygulamasının arayüz metinleridir. '
      'Değerleri "$lang" diline çevir.\n'
      'KURALLAR:\n'
      '- Anahtarları AYNEN koru, çevirme.\n'
      '- {name} gibi süslü parantezli yer tutucuları AYNEN koru.\n'
      '- Arayüz metni olduğunu unutma: kısa ve doğal ol, düğme metinlerini '
      'uzatma.\n'
      '- Yalnız JSON döndür, açıklama veya kod bloğu işareti ekleme.\n\n'
      '${jsonEncode(batch)}';

  final raw = await _callModel(
    client: client,
    provider: provider,
    model: model,
    apiKey: apiKey,
    prompt: prompt,
  );
  final decoded = _decodeJsonObject(raw);
  return {
    for (final entry in decoded.entries)
      if (entry.value is String && batch.containsKey(entry.key))
        entry.key: entry.value as String,
  };
}

/// Modelin yanıtından JSON nesnesini çıkarır.
///
/// "Yalnız JSON döndür" denmiş olsa da modeller yanıtı ```json çitiyle
/// sarmayı ya da başına bir cümle eklemeyi sürdürüyor; ilk '{' ile son '}'
/// arasını almak bu iki durumu da kurtarır.
Map<String, dynamic> _decodeJsonObject(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return const {};
  try {
    final decoded = jsonDecode(raw.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : const {};
  } on FormatException catch (e) {
    stderr.writeln('  JSON çözülemedi, paket atlandı: $e');
    return const {};
  }
}

Future<String> _callModel({
  required HttpClient client,
  required String provider,
  required String model,
  required String apiKey,
  required String prompt,
}) async {
  final (uri, headers, body) = switch (provider) {
    'gemini' => (
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
      ),
      {'x-goog-api-key': apiKey},
      {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      },
    ),
    'anthropic' => (
      Uri.parse('https://api.anthropic.com/v1/messages'),
      {'x-api-key': apiKey, 'anthropic-version': '2023-06-01'},
      {
        'model': model,
        'max_tokens': 8192,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      },
    ),
    // openai ve openrouter aynı teli konuşur.
    _ => (
      Uri.parse(
        provider == 'openrouter'
            ? 'https://openrouter.ai/api/v1/chat/completions'
            : 'https://api.openai.com/v1/chat/completions',
      ),
      {'Authorization': 'Bearer $apiKey'},
      {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
        'response_format': {'type': 'json_object'},
      },
    ),
  };

  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  headers.forEach(request.headers.set);
  request.add(utf8.encode(jsonEncode(body)));
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException('HTTP ${response.statusCode}: $text', uri: uri);
  }

  final data = jsonDecode(text) as Map<String, dynamic>;
  return switch (provider) {
    'gemini' =>
      ((((data['candidates'] as List).first as Map)['content']
                  as Map)['parts']
              as List)
          .map((p) => (p as Map)['text'] ?? '')
          .join(),
    'anthropic' => (data['content'] as List)
        .map((p) => (p as Map)['text'] ?? '')
        .join(),
    _ =>
      (((data['choices'] as List).first as Map)['message']
              as Map)['content']
          as String? ??
          '',
  };
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (final arg in args) {
    if (!arg.startsWith('--')) continue;
    final body = arg.substring(2);
    final eq = body.indexOf('=');
    if (eq < 0) {
      result[body] = '';
    } else {
      result[body.substring(0, eq)] = body.substring(eq + 1);
    }
  }
  return result;
}
