import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/speech_output.dart';
import '../../settings/settings_providers.dart';
import 'gemini_service.dart';

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
    state = SpeechOutputState(
      state: SpeechState.speaking,
      total: chunks.length,
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
}
