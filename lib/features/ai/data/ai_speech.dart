import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/speech_output.dart';
import '../../settings/settings_providers.dart';
import 'gemini_service.dart';
import 'pcm_wav.dart';

/// **Yapay zekâ sesiyle** okuma: metin Gemini'nin seslendirme modeline
/// gönderilir, dönen ses çalınır. Cihaz TTS'inin ([SpeechOutputController])
/// yerine geçer, arayüzü de aynıdır ([SpeechOutputState]) — "AI ile dinle"
/// düğmesi yalnız hangi denetleyicinin konuşacağını değiştirir, ekranın geri
/// kalanı (oynat/duraklat/ilerleme) hiç değişmez.
///
/// Neden parça parça: seslendirme modeli tek istekte sınırlı uzunluk alır ve
/// uzun bir podcast metni tek çağrıda ne sığar ne de makul sürede döner. Metin
/// cümle sınırlarından [_chunkChars] boyutunda parçalara bölünür; bir parça
/// ÇALARKEN sonraki parça arka planda üretilir (ön yükleme), böylece parçalar
/// arasında sessizlik olmaz.
///
/// Maliyet uyarısı çağıran ekranın işidir: burada her parça bir model
/// çağrısıdır ve kullanıcının kendi Gemini kotasından düşer.
final aiSpeechProvider =
    NotifierProvider<AiSpeechController, SpeechOutputState>(
      AiSpeechController.new,
    );

class AiSpeechController extends Notifier<SpeechOutputState> {
  /// Bir parçanın en çok karakter sayısı. Cümle sınırında bölünür; 900
  /// karakter kabaca bir paragraf — model gecikmesi (birkaç saniye) ile
  /// parçalar arası akıcılık arasındaki denge.
  static const _chunkChars = 900;

  AudioPlayer? _player;
  int _generation = 0;

  /// Üretilen geçici WAV dosyaları; okuma bitince silinir.
  final _temp = <File>[];

  @override
  SpeechOutputState build() {
    ref.onDispose(() {
      _generation++;
      unawaited(_player?.dispose());
      _cleanTemp();
    });
    return const SpeechOutputState();
  }

  /// Yapay zekâ seslendirmesi bu kurulumda kullanılabilir mi? (Kendi Gemini
  /// anahtarı gerekir — dahili yol ses döndürmüyor.)
  bool get isAvailable =>
      !kIsWeb && ref.read(geminiServiceProvider).provider.id == 'gemini';

  /// Metni cümle sınırlarından [_chunkChars]'lık parçalara böler.
  ///
  /// Cihaz TTS'inin cümle bölücüsü yeniden kullanılır (kısaltmalar, satır
  /// sonları, aşırı uzun cümleler orada çözülmüş); burada yalnız cümleler
  /// paragraf büyüklüğünde kümelenir — her cümle için ayrı model çağrısı
  /// hem yavaş hem pahalı olurdu.
  @visibleForTesting
  static List<String> chunk(String text) {
    final out = <String>[];
    final buffer = StringBuffer();
    for (final sentence in SpeechOutputController.splitSentences(text)) {
      if (buffer.isNotEmpty && buffer.length + sentence.length > _chunkChars) {
        out.add(buffer.toString().trim());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(sentence);
    }
    if (buffer.isNotEmpty) out.add(buffer.toString().trim());
    return out;
  }

  Future<File> _writeTemp(Uint8List bytes, int index) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ai_tts_${_generation}_$index.wav');
    await file.writeAsBytes(bytes, flush: true);
    _temp.add(file);
    return file;
  }

  void _cleanTemp() {
    for (final file in _temp) {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    _temp.clear();
  }

  Future<Uint8List> _synthesize(String text) => ref
      .read(geminiServiceProvider)
      .speech(
        text,
        voice: ref.read(ttsVoiceProvider),
        model: ref.read(ttsModelProvider),
      );

  /// Ses DENEMESİ: seçilen ses/model bir örnek cümle okur.
  ///
  /// Örnek AYNI ses için YALNIZ BİR KEZ üretilir; sonuç kalıcı klasöre yazılır
  /// ve sonraki denemeler dosyadan çalar. Ayarlarda ses seçerken her dokunuşta
  /// model çağırmak kullanıcının kotasını denemeye yakardı — oysa aynı cümle,
  /// aynı sesle her seferinde birebir aynı sesi verir (bkz. kullanıcı isteği
  /// 2026-08-09: "test sesi gelmeli ama kota harcayacağı için 1 kez indirilip
  /// storage'a kaydedilip oradan oynatılmalı").
  ///
  /// Döndürdüğü değer: örnek YENİ mi üretildi (true) yoksa kayıttan mı çalındı
  /// (false) — ekran kullanıcıya bunu söyleyebilsin.
  Future<bool> previewVoice(String sample) async {
    final voice = ref.read(ttsVoiceProvider);
    final model = ref.read(ttsModelProvider) ?? 'auto';
    final file = await _sampleFile(model: model, voice: voice, text: sample);
    var generated = false;
    if (!file.existsSync() || file.lengthSync() == 0) {
      final bytes = await _synthesize(sample);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      generated = true;
    }
    // Deneme, okuma durumunu (SpeechOutputState) DEĞİŞTİRMEZ: ayarlar ekranı
    // bir notu okumuyor; ilerleme çubuğu açılsaydı yanlış olurdu.
    final player = _player ??= AudioPlayer();
    await player.stop();
    await player.setFilePath(file.path);
    await player.play();
    return generated;
  }

  /// Örnek dosyanın yolu. Ad ses+model+metinden türetilir: ses değişince yeni
  /// dosya, aynı ses tekrar seçilince eski dosya bulunur. Geçici klasör DEĞİL
  /// kalıcı klasör: sistem geçici dosyaları silince örnek yeniden üretilir ve
  /// kota boşuna yanardı.
  Future<File> _sampleFile({
    required String model,
    required String voice,
    required String text,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final key = '${model}_${voice}_${text.hashCode}'.replaceAll(
      RegExp(r'[^A-Za-z0-9_.-]'),
      '_',
    );
    return File('${dir.path}/tts_samples/$key.wav');
  }

  /// Metni yapay zekâ sesiyle okur. Zaten okuyorsa önce durdurur.
  ///
  /// Hata (kota, anahtar, ağ) fırlatılır: çağıran ekran mesajı gösterip cihaz
  /// sesine düşebilsin. Fırlatmadan önce durum boşa çekilir ki ekran "hâlâ
  /// okuyor" sanmasın.
  Future<void> speak(String text) async {
    await stop();
    final chunks = chunk(text);
    if (chunks.isEmpty) return;
    final generation = ++_generation;
    // `loading: true` ile başlar: ilk parça modelden gelene kadar hoparlörden
    // ses çıkmıyor ve ekran bunu göstermek zorunda (bkz. SpeechOutputState).
    state = SpeechOutputState(
      state: SpeechState.speaking,
      total: chunks.length,
      loading: true,
    );
    final player = _player ??= AudioPlayer();

    // Sıradaki parçayı ÇALARKEN üret: ilk parça dışında bekleme duyulmaz.
    Future<Uint8List>? next = _synthesize(chunks.first);
    try {
      for (var i = 0; i < chunks.length; i++) {
        final bytes = await next!;
        if (generation != _generation) return; // durduruldu / yeniden başladı
        next = i + 1 < chunks.length ? _synthesize(chunks[i + 1]) : null;
        final file = await _writeTemp(bytes, i);
        if (generation != _generation) return;
        await player.setFilePath(file.path);
        await player.play();
        // Ses BAŞLADI: bekleme göstergesi kalksın. Ön yükleme yetişemezse
        // (uzun paragraf, yavaş ağ) bir sonraki turda yeniden açılır.
        if (generation == _generation && state.state != SpeechState.idle) {
          state = SpeechOutputState(
            state: state.state,
            total: chunks.length,
            spoken: i,
          );
        }
        // TUZAK: `play()` çalma bitince döner AMA duraklatıldığında da döner.
        // Yalnız ona güvenilirse duraklat→devam et sırasında döngü sıradaki
        // parçaya geçer ve iki parça üst üste çalar. Bu yüzden parçanın
        // gerçekten bittiği oynatıcının kendi durumundan doğrulanır.
        while (generation == _generation &&
            state.state != SpeechState.idle &&
            player.processingState != ProcessingState.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        if (generation != _generation || state.state == SpeechState.idle) {
          return;
        }
        state = SpeechOutputState(
          state: state.state,
          total: chunks.length,
          spoken: i + 1,
          // Son parça değilse sıradakini beklemeye geçiyoruz.
          loading: i + 1 < chunks.length,
        );
      }
      if (generation == _generation && state.state != SpeechState.idle) {
        state = const SpeechOutputState();
      }
    } catch (_) {
      if (generation == _generation) state = const SpeechOutputState();
      rethrow;
    } finally {
      // Beklemede kalan üretim varsa hatası yutulsun (durdurulmuş olabilir).
      unawaited(next?.catchError((Object _) => Uint8List(0)));
    }
  }

  Future<void> pause() async {
    if (state.state != SpeechState.speaking) return;
    state = SpeechOutputState(
      state: SpeechState.paused,
      total: state.total,
      spoken: state.spoken,
    );
    await _player?.pause();
  }

  Future<void> resume() async {
    if (state.state != SpeechState.paused) return;
    state = SpeechOutputState(
      state: SpeechState.speaking,
      total: state.total,
      spoken: state.spoken,
    );
    await _player?.play();
  }

  Future<void> stop() async {
    _generation++;
    state = const SpeechOutputState();
    await _player?.stop();
    _cleanTemp();
  }

  /// Metnin TAMAMINI seslendirip TEK bir WAV dosyası olarak yazar ve yolunu
  /// döndürür (kullanıcı isteği 2026-08-16: podcast'i ses dosyası olarak dışa
  /// aktarma).
  ///
  /// Okumadan ([speak]) iki farkı var:
  ///  1. Hiçbir şey ÇALINMAZ — dosya üretmek için parçaların sırayla
  ///     beklenmesi yeter, oynatıcıya hiç dokunulmaz.
  ///  2. Parçalar sırayla ve TEK TEK istenir. Okumada sıradaki parça çalarken
  ///     üretiliyor (bekleme duyulmasın diye); burada duyulacak bir şey yok ve
  ///     paralel istek kullanıcının kotasına aynı anda birden çok çağrı olarak
  ///     düşerdi.
  ///
  /// [onProgress] her parça bitince (üretilen, toplam) ile çağrılır — çağıran
  /// ekran "3/12" gösterebilsin. Model hatası olduğu gibi fırlatılır.
  ///
  /// MALİYET UYARISI çağıranın işi: burada her parça bir model çağrısıdır ve
  /// okuma sırasında zaten üretilmiş parçalar YENİDEN üretilir (geçici
  /// dosyalar okuma bitince siliniyor, ayrıca kullanıcı hiç dinlemeden de
  /// dışa aktarabilir).
  Future<String> renderToFile(
    String text, {
    required String fileName,
    void Function(int done, int total)? onProgress,
  }) async {
    final chunks = chunk(text);
    if (chunks.isEmpty) throw const GeminiException('Seslendirilecek metin yok');
    final parts = <Uint8List>[];
    for (var i = 0; i < chunks.length; i++) {
      parts.add(await _synthesize(chunks[i]));
      onProgress?.call(i + 1, chunks.length);
    }
    final merged = concatWav(parts);
    if (merged.isEmpty) {
      throw const GeminiException('Seslendirme modeli ses döndürmedi');
    }
    // Geçici klasör: dosya paylaşıldıktan sonra sistemin temizlemesi
    // beklenir; kalıcı klasörde tutmak kullanıcının depolamasını sessizce
    // şişirirdi (bir dakikalık ses ~3 MB).
    final dir = await getTemporaryDirectory();
    final safe = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_').trim();
    final file = File(
      '${dir.path}/${safe.isEmpty ? 'podcast' : safe}.wav',
    );
    await file.writeAsBytes(merged, flush: true);
    return file.path;
  }
}
