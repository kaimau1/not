import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/speech_output.dart';
import 'antalia_audio.dart';
import 'antalia_engine.dart';

/// **Antalia sesiyle** okuma: metin cihazdaki Türkçe seslendirme modeliyle
/// ([AntaliaEngine]) sese çevrilip çalınır. Arayüzü cihaz TTS'i ve Gemini
/// sesiyle aynıdır ([SpeechOutputState]); kapı [SpeechService].
///
/// Gemini sesinden farkı: kota, anahtar, ağ yok (model bir kez indirilir),
/// ama yalnız TÜRKÇE okur — başka dildeki metin Türkçe harf kurallarıyla
/// okunur. Bu yüzden servis Türkçe dışı okumada cihaz sesine geçer.
///
/// Parçalama Gemini sesindekiyle aynı fikir: bir parça ÇALARKEN sıradaki
/// üretilir. İlk parça kısa tutulur ki ilk ses çabuk gelsin (orta sınıf
/// telefonda bir cümle ~1 sn).
final antaliaSpeechProvider =
    NotifierProvider<AntaliaSpeechController, SpeechOutputState>(
      AntaliaSpeechController.new,
    );

class AntaliaSpeechController extends Notifier<SpeechOutputState> {
  static const _firstChunkChars = 120;
  static const _chunkChars = 400;

  /// Okuma bittikten sonra modelin bellekte kalma süresi: art arda okumalar
  /// yeniden yükleme beklemesin, ama ~50 MB sonsuza dek tutulmasın.
  static const _idleRelease = Duration(minutes: 3);

  AudioPlayer? _player;
  int _generation = 0;
  Timer? _idle;
  final _temp = <File>[];

  @override
  SpeechOutputState build() {
    ref.onDispose(() {
      _generation++;
      _idle?.cancel();
      unawaited(_player?.dispose());
      _cleanTemp();
    });
    return const SpeechOutputState();
  }

  /// Model bu cihazda kurulu mu (indirme Ayarlar → Ses'te).
  bool get isAvailable => ref.read(antaliaModelProvider).ready;

  /// Metni cümle sınırlarından parçalara böler; ilk parça kısa.
  @visibleForTesting
  static List<String> chunk(String text) {
    final out = <String>[];
    final buffer = StringBuffer();
    for (final sentence in SpeechOutputController.splitSentences(text)) {
      final limit = out.isEmpty ? _firstChunkChars : _chunkChars;
      if (buffer.isNotEmpty && buffer.length + sentence.length > limit) {
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
    final file = File('${dir.path}/antalia_${_generation}_$index.wav');
    await file.writeAsBytes(bytes, flush: true);
    _temp.add(file);
    return file;
  }

  void _cleanTemp() {
    for (final file in _temp) {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // Silinemeyen geçici ses dosyasını sistem toplar.
      }
    }
    _temp.clear();
  }

  void _scheduleRelease() {
    _idle?.cancel();
    _idle = Timer(_idleRelease, () {
      if (state.state == SpeechState.idle) {
        unawaited(ref.read(antaliaEngineProvider).release());
      }
    });
  }

  /// Metni Antalia sesiyle okur. Zaten okuyorsa önce durdurur. Model
  /// yüklenemez ya da çalışmazsa hata fırlatılır (servis cihaz sesine
  /// düşer).
  Future<void> speak(String text) async {
    await stop();
    final chunks = chunk(text);
    if (chunks.isEmpty) return;
    final generation = ++_generation;
    _idle?.cancel();
    state = SpeechOutputState(
      state: SpeechState.speaking,
      total: chunks.length,
      loading: true,
    );
    final engine = ref.read(antaliaEngineProvider);
    final tone = AntaliaDsp.tone();
    bool stopped() => generation != _generation;
    Future<Uint8List> synth(int i) async => AntaliaDsp.toWav(
      await engine.synthesize(
        chunks[i],
        tone: tone,
        last: i == chunks.length - 1,
        seedBase: i * 64,
        cancelled: stopped,
      ),
    );
    final player = _player ??= AudioPlayer();

    Future<Uint8List>? next = synth(0);
    try {
      for (var i = 0; i < chunks.length; i++) {
        final bytes = await next!;
        if (stopped()) return;
        // Sıradaki parça, bu parça ÇALARKEN üretilir. Ton filtresinin durumu
        // sırayla ilerlemeli: sıradaki üretim bu parçanın üretimi bittikten
        // sonra başlar (await yukarıda), sıra bozulmaz.
        next = i + 1 < chunks.length ? synth(i + 1) : null;
        final file = await _writeTemp(bytes, i);
        if (stopped()) return;
        await player.setFilePath(file.path);
        unawaited(player.play());
        if (!stopped() && state.state != SpeechState.idle) {
          state = SpeechOutputState(
            state: state.state,
            total: chunks.length,
            spoken: i,
          );
        }
        // TUZAK (AiSpeechController ile aynı): `play()` duraklatınca da
        // döner; parçanın bittiği oynatıcı durumundan doğrulanır.
        while (!stopped() &&
            state.state != SpeechState.idle &&
            player.processingState != ProcessingState.completed) {
          await Future<void>.delayed(const Duration(milliseconds: 120));
        }
        if (stopped() || state.state == SpeechState.idle) return;
        state = SpeechOutputState(
          state: state.state,
          total: chunks.length,
          spoken: i + 1,
          loading: i + 1 < chunks.length,
        );
      }
      if (!stopped() && state.state != SpeechState.idle) {
        state = const SpeechOutputState();
      }
    } catch (_) {
      if (!stopped()) state = const SpeechOutputState();
      rethrow;
    } finally {
      unawaited(next?.catchError((Object _) => Uint8List(0)));
      if (generation == _generation) _scheduleRelease();
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
    unawaited(_player?.play());
  }

  Future<void> stop() async {
    _generation++;
    state = const SpeechOutputState();
    await _player?.stop();
    _cleanTemp();
  }

  /// Ayarlardaki deneme: kısa bir cümleyi okur.
  Future<void> preview(String sample) => speak(sample);

  /// Metnin TAMAMINI tek WAV dosyasına yazar (podcast dışa aktarma; bkz.
  /// [AiSpeechController.renderToFile]). Burada kota yok — yalnız süre.
  Future<String> renderToFile(
    String text, {
    required String fileName,
    void Function(int done, int total)? onProgress,
  }) async {
    final chunks = chunk(text);
    if (chunks.isEmpty) throw StateError('Seslendirilecek metin yok');
    // Önceki okumanın boşta bırakma sayacı üretimin ortasında modeli
    // kapatmasın (okuma durumu burada "boşta" görünür).
    _idle?.cancel();
    final engine = ref.read(antaliaEngineProvider);
    final tone = AntaliaDsp.tone();
    final all = BytesBuilder(copy: false);
    for (var i = 0; i < chunks.length; i++) {
      final samples = await engine.synthesize(
        chunks[i],
        tone: tone,
        last: i == chunks.length - 1,
        seedBase: i * 64,
      );
      all.add(
        samples.buffer.asUint8List(
          samples.offsetInBytes,
          samples.lengthInBytes,
        ),
      );
      onProgress?.call(i + 1, chunks.length);
    }
    final bytes = all.takeBytes();
    final wav = AntaliaDsp.toWav(
      bytes.buffer.asFloat32List(bytes.offsetInBytes, bytes.lengthInBytes ~/ 4),
    );
    final dir = await getTemporaryDirectory();
    final safe = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_').trim();
    final file = File('${dir.path}/${safe.isEmpty ? 'podcast' : safe}.wav');
    await file.writeAsBytes(wav, flush: true);
    _scheduleRelease();
    return file.path;
  }
}
