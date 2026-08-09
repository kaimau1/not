import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazın YERLEŞİK seslendirmesi (TTS). Uygulamadaki tüm sesli okuma bunu
/// kullanır: çeviri seslendirmesi, sesli özet, belge okuma.
///
/// Neden cihaz TTS'i, Gemini TTS değil: sesli okuma uzun metinlerde
/// çalışıyor (bir PDF'in tamamı olabilir). Her cümleyi modele göndermek
/// kotayı yakar, ağ bekletir ve API anahtarı ister. Cihaz TTS'i bedava,
/// anında ve çevrimdışı; ses listesi de sistemden gelir, böylece "ses tipi
/// seçimi" ayrıca kurgulanmak zorunda kalmaz.
///
/// Uzun metin tek parça verilmez: cümlelere bölünüp sırayla okunur. Böylece
/// duraklat/durdur anında tepki verir ve nerede kalındığı bilinir.
enum SpeechState { idle, speaking, paused }

@immutable
class SpeechVoice {
  const SpeechVoice({required this.name, required this.locale});

  final String name;
  final String locale;

  /// Ayarlarda saklanan biçim; sistem sesleri ada+dile göre eşlenir.
  String get id => '$name|$locale';

  static SpeechVoice? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('|');
    if (parts.length != 2) return null;
    return SpeechVoice(name: parts[0], locale: parts[1]);
  }
}

class SpeechOutputState {
  const SpeechOutputState({
    this.state = SpeechState.idle,
    this.total = 0,
    this.spoken = 0,
  });

  final SpeechState state;

  /// Sıraya alınan cümle sayısı ve kaçının okunduğu — ilerleme göstergesi.
  final int total;
  final int spoken;

  bool get isActive => state != SpeechState.idle;
  double get progress => total == 0 ? 0 : (spoken / total).clamp(0.0, 1.0);
}

final speechOutputProvider =
    NotifierProvider<SpeechOutputController, SpeechOutputState>(
      SpeechOutputController.new,
    );

class SpeechOutputController extends Notifier<SpeechOutputState> {
  /// Ses seçimi DİL BAŞINA saklanır: Türkçe ve İngilizce'yi kullanıcı seçer,
  /// kalan diller otomatik erkek sesiyle okunur (bkz. [pickAutoVoice]).
  static String _voiceKeyFor(String language) => 'tts_voice_$language';

  /// Dil başına ayrılmadan önceki tek anahtar; Türkçe seçimi kaybolmasın.
  static const _legacyVoiceKey = 'tts_voice';

  static const _rateKey = 'tts_rate';

  /// Yabancı diller için AYRI okuma hızı. Cihaz TTS motorları yabancı dil
  /// seslerini Türkçe'ye göre belirgin daha hızlı okuyabiliyor ("çok hızlı
  /// konuşuyor" — madde 2). Türkçe dışı her dil bu değerle okunur; varsayılan
  /// 0.4 (normal Türkçe hızı 0.5'ten yavaş).
  static const _foreignRateKey = 'tts_rate_foreign';

  /// Sesin TONU (perde). Motorlar 0.5–2.0 aralığını kabul eder; 1.0 sesin
  /// kendi tonudur. Ayarlarda eksikti (kullanıcı isteği 2026-08-09: "eksik
  /// ayar varsa eklenmeli") — aynı sesin daha kalın/ince okunması, uzun
  /// dinlemelerde okunabilirliği belirgin değiştiriyor.
  static const _pitchKey = 'tts_pitch';

  static const _defaultRate = 0.5;
  static const _defaultForeignRate = 0.4;
  static const _defaultPitch = 1.0;

  FlutterTts? _tts;
  List<String> _queue = const [];
  int _index = 0;

  /// Bir cümle bittiğinde tamamlanır; sıradakine bu tamamlanınca geçilir.
  Completer<void>? _sentenceDone;

  /// O anki okumanın dili; "devam et" aynı dille sürsün diye saklanır.
  String? _language;

  @override
  SpeechOutputState build() {
    ref.onDispose(() => _tts?.stop());
    return const SpeechOutputState();
  }

  /// Kısa dil kodu → TTS yerel ayarı. Motorlar 'en' yerine 'en-US' bekliyor;
  /// çevirmenin desteklediği diller burada karşılanır.
  static const _ttsLocales = <String, String>{
    'tr': 'tr-TR',
    'en': 'en-US',
    'de': 'de-DE',
    'fr': 'fr-FR',
    'es': 'es-ES',
    'it': 'it-IT',
    'ar': 'ar-SA',
    'ru': 'ru-RU',
    'fa': 'fa-IR',
    'nl': 'nl-NL',
    'pt': 'pt-PT',
    'el': 'el-GR',
    'ja': 'ja-JP',
    'ko': 'ko-KR',
    'zh': 'zh-CN',
    'az': 'az-AZ',
  };

  /// Kısa dil kodunun tam yerel ayarı. Konuşma TANIMA da aynı biçimi ister
  /// (SpeechRecognizer 'tr' değil 'tr-TR' bekler), bu yüzden dışarı açık.
  static String localeFor(String code) =>
      _ttsLocales[code.toLowerCase()] ?? code;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    // Android'de awaitSpeakCompletion olmadan speak() anında döner ve
    // cümleler üst üste binerdi.
    await tts.awaitSpeakCompletion(true);
    tts.setCompletionHandler(() => _sentenceDone?.complete());
    tts.setCancelHandler(() => _sentenceDone?.complete());
    tts.setErrorHandler((dynamic _) => _sentenceDone?.complete());
    final prefs = await SharedPreferences.getInstance();
    await tts.setSpeechRate(prefs.getDouble(_rateKey) ?? _defaultRate);
    await tts.setPitch(prefs.getDouble(_pitchKey) ?? _defaultPitch);
    _tts = tts;
    return tts;
  }

  /// O anki okuma diline göre hız: UYGULAMANIN dili kendi hızıyla, ötekiler
  /// ayrı (genelde daha yavaş) "yabancı dil" hızıyla okunur — [speak]/[resume]
  /// her okumada uygular.
  ///
  /// Karşılaştırma eskiden 'tr' sabitiyle yapılıyordu; uygulama Almanca'ya
  /// alındığında kullanıcının ANA dili "yabancı" sayılıp yavaş okunuyordu.
  /// Etkin yerel ayar `Intl` üzerinden okunur (bkz. `app.dart`) — böylece
  /// core katmanı ayarlar sağlayıcısına bağlanmak zorunda kalmaz.
  Future<double> _rateFor(String language) async {
    final prefs = await SharedPreferences.getInstance();
    final appLanguage = Intl.getCurrentLocale().split(RegExp('[-_]')).first;
    if (language.toLowerCase() == appLanguage.toLowerCase()) {
      return prefs.getDouble(_rateKey) ?? _defaultRate;
    }
    return prefs.getDouble(_foreignRateKey) ?? _defaultForeignRate;
  }

  /// Verilen dil için sesi ayarlar. Sıra:
  /// 1. Kullanıcı o dil için ses seçtiyse o (yalnız tr/en'de mümkün)
  /// 2. Yoksa o dilin OTOMATİK ERKEK sesi
  /// 3. O da yoksa yalnız dili ayarla (motor kendi varsayılanını kullanır)
  Future<void> _applyVoiceFor(FlutterTts tts, String language) async {
    final lang = language.toLowerCase();
    final saved = await selectedVoice(lang);
    if (saved != null) {
      await tts.setVoice({'name': saved.name, 'locale': saved.locale});
      return;
    }
    final auto = pickAutoVoice(await voices(language: lang));
    if (auto != null) {
      await tts.setVoice({'name': auto.name, 'locale': auto.locale});
      return;
    }
    final locale = _ttsLocales[lang] ?? lang;
    if (await tts.isLanguageAvailable(locale) == true) {
      await tts.setLanguage(locale);
    }
  }

  /// Cihazda kurulu sesler. [language] verilirse yalnız o dilinkiler
  /// (Ayarlar'da Türkçe listesine İngilizce sesler karışmasın).
  Future<List<SpeechVoice>> voices({String? language}) async {
    final tts = await _engine();
    final raw = await tts.getVoices as List<dynamic>? ?? const [];
    final result = <SpeechVoice>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final name = entry['name'] as String?;
      final locale = entry['locale'] as String?;
      if (name == null || locale == null) continue;
      if (language != null &&
          !locale.toLowerCase().startsWith(language.toLowerCase())) {
        continue;
      }
      result.add(SpeechVoice(name: name, locale: locale));
    }
    result.sort((a, b) {
      final byLocale = a.locale.compareTo(b.locale);
      return byLocale != 0 ? byLocale : a.name.compareTo(b.name);
    });
    return result;
  }

  Future<SpeechVoice?> selectedVoice(String language) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_voiceKeyFor(language));
    if (saved != null) return SpeechVoice.parse(saved);
    // Dil başına ayrılmadan önce tek bir ses saklanıyordu; Türkçe seçimi
    // kullanıcının elinden gitmesin.
    if (language == 'tr') {
      return SpeechVoice.parse(prefs.getString(_legacyVoiceKey));
    }
    return null;
  }

  Future<void> setVoice(String language, SpeechVoice voice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKeyFor(language), voice.id);
    await (await _engine()).setVoice({
      'name': voice.name,
      'locale': voice.locale,
    });
  }

  /// Ayarlarda bir ses seçilince okunan örnek cümle — SEÇİLEN DİLDE.
  ///
  /// KÖK NEDEN: cümle çağrı yerinde "dil 'en' mi?" diye tek bir koşulla
  /// seçiliyordu; Almanca ve İspanyolca ses seçilince TÜRKÇE cümle okunuyordu.
  /// Seçilen sesin asıl merak edilen özelliği (o dili nasıl telaffuz ettiği)
  /// böyle hiç duyulmuyor, üstelik yabancı ses Türkçe metni okuyunca tını da
  /// yanlış duyuluyordu. Cümle artık dilin yanında BURADA durur: yeni bir dil
  /// eklendiğinde ses seçici ile örnek cümle aynı yerden türer.
  ///
  /// Karşılığı olmayan dil için İngilizce'ye düşülür (sessiz kalmaktan iyi).
  static const _voiceSamples = <String, String>{
    'tr': 'Seçtiğin ses bu. Notların bundan sonra bu sesle, bu hızda okunacak.',
    'en':
        'This is the selected voice. Your notes will be read aloud like this.',
    'de': 'Das ist die ausgewählte Stimme. Deine Notizen werden so vorgelesen.',
    'es': 'Esta es la voz seleccionada. Tus notas se leerán en voz alta así.',
  };

  /// [language] için örnek cümle (bilinmeyen dilde İngilizce).
  static String voiceSample(String language) =>
      _voiceSamples[language.toLowerCase()] ?? _voiceSamples['en']!;

  /// Kullanıcının seçmediği diller için ses seçer: ERKEK sesi tercih edilir.
  ///
  /// Android ses cinsiyetini ayrı bir alan olarak vermez, ada gömer
  /// ("tr-tr-x-ama#male_1-local"). Tuzak: "female" kelimesi "male" içerir,
  /// bu yüzden önce dişil eleme yapılır. Hiç erkek ses yoksa ilk ses döner;
  /// hiç ses yoksa null (çağıran yalnız dili ayarlar).
  @visibleForTesting
  static SpeechVoice? pickAutoVoice(List<SpeechVoice> available) {
    if (available.isEmpty) return null;
    for (final voice in available) {
      final name = voice.name.toLowerCase();
      if (name.contains('female')) continue;
      if (name.contains('male')) return voice;
    }
    return available.first;
  }

  Future<double> rate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_rateKey) ?? _defaultRate;
  }

  /// 0.0–1.0 arası; 0.5 cihazın normal hızı.
  Future<void> setRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, value);
    await (await _engine()).setSpeechRate(value);
  }

  /// Yabancı dillerin (Türkçe dışı) okuma hızı.
  Future<double> foreignRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_foreignRateKey) ?? _defaultForeignRate;
  }

  Future<void> setForeignRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_foreignRateKey, value);
  }

  /// Sesin tonu (0.5–2.0; 1.0 = sesin kendi tonu).
  Future<double> pitch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_pitchKey) ?? _defaultPitch;
  }

  Future<void> setPitch(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pitchKey, value);
    await (await _engine()).setPitch(value);
  }

  /// Metni cümlelere bölüp sırayla okur. Zaten okuyorsa önce durdurur.
  ///
  /// [languageCode] verilirse (ör. 'en', 'de') metin O DİLDE okunur. Verilmezse
  /// Ayarlar'daki ses kullanılır. Çeviri seslendirmesinde bu şart: hedef dil
  /// söylenmezse İngilizce metin Türkçe sesle, Türkçe okunuşuyla okunuyordu.
  Future<void> speak(String text, {String? languageCode}) async {
    await stop();
    final sentences = splitSentences(text);
    if (sentences.isEmpty) return;
    _queue = sentences;
    _index = 0;
    state = SpeechOutputState(
      state: SpeechState.speaking,
      total: sentences.length,
    );
    final tts = await _engine();
    // Dil söylenmezse uygulama dili varsayılır: notlar Türkçe.
    _language = languageCode ?? 'tr';
    await _applyVoiceFor(tts, _language!);
    // Hız dile göre: yabancı diller ayrı (genelde daha yavaş) hızla okunur.
    await tts.setSpeechRate(await _rateFor(_language!));
    while (_index < _queue.length && state.state == SpeechState.speaking) {
      final done = Completer<void>();
      _sentenceDone = done;
      await tts.speak(_queue[_index]);
      await done.future;
      _sentenceDone = null;
      // Durdurulduysa sayaçları ilerletme.
      if (state.state == SpeechState.idle) return;
      _index++;
      state = SpeechOutputState(
        state: state.state,
        total: _queue.length,
        spoken: _index,
      );
    }
    if (state.state != SpeechState.idle) state = const SpeechOutputState();
  }

  Future<void> pause() async {
    if (state.state != SpeechState.speaking) return;
    state = SpeechOutputState(
      state: SpeechState.paused,
      total: state.total,
      spoken: state.spoken,
    );
    await _tts?.stop();
  }

  /// Duraklatılan yerden devam eder: kalan cümleler yeniden sıraya girer.
  Future<void> resume() async {
    if (state.state != SpeechState.paused) return;
    final remaining = _queue.skip(_index).toList();
    final alreadySpoken = _index;
    final total = _queue.length;
    _queue = remaining;
    _index = 0;
    state = SpeechOutputState(
      state: SpeechState.speaking,
      total: total,
      spoken: alreadySpoken,
    );
    final tts = await _engine();
    // Duraklatma motorun dilini sıfırlayabiliyor; kaldığımız dille sürsün.
    await _applyVoiceFor(tts, _language ?? 'tr');
    await tts.setSpeechRate(await _rateFor(_language ?? 'tr'));
    while (_index < _queue.length && state.state == SpeechState.speaking) {
      final done = Completer<void>();
      _sentenceDone = done;
      await tts.speak(_queue[_index]);
      await done.future;
      _sentenceDone = null;
      if (state.state == SpeechState.idle) return;
      _index++;
      state = SpeechOutputState(
        state: state.state,
        total: total,
        spoken: alreadySpoken + _index,
      );
    }
    if (state.state != SpeechState.idle) state = const SpeechOutputState();
  }

  Future<void> stop() async {
    _queue = const [];
    _index = 0;
    state = const SpeechOutputState();
    _sentenceDone?.complete();
    _sentenceDone = null;
    await _tts?.stop();
  }

  /// Metni okunabilir parçalara böler. Cümle sonu yoksa (madde listeleri,
  /// başlıklar) satır sonu da ayraç sayılır; çok uzun parçalar TTS motorunda
  /// kesilebildiği için ayrıca kırpılır.
  ///
  /// Dışarı AÇIK (eskiden yalnız testlere görünürdü): yapay zekâ seslendirmesi
  /// de metni aynı kurallarla bölmek zorunda — iki motorun cümle sınırı
  /// ayrışırsa aynı metin iki farklı yerde duraklar. Bkz. `AiSpeechController`.
  static List<String> splitSentences(String text) {
    const maxChunk = 300;
    final chunks = <String>[];
    for (final line in text.split('\n')) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      for (final raw in trimmedLine.split(RegExp(r'(?<=[.!?…])\s+'))) {
        var sentence = raw.trim();
        if (sentence.isEmpty) continue;
        while (sentence.length > maxChunk) {
          // Sınıra en yakın boşluktan böl; kelime ortasından kesme.
          final cut = sentence.lastIndexOf(' ', maxChunk);
          final at = cut > 0 ? cut : maxChunk;
          chunks.add(sentence.substring(0, at).trim());
          sentence = sentence.substring(at).trim();
        }
        if (sentence.isNotEmpty) chunks.add(sentence);
      }
    }
    return chunks;
  }
}
