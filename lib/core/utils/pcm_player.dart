// just_audio'nun StreamAudioSource API'si "experimental" işaretli olsa da
// yıllardır kararlı; bellekteki WAV'ı çalmanın önerilen yolu budur.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'pcm_wav.dart';

/// Bellekteki WAV baytlarını çalan just_audio kaynağı.
class BytesAudioSource extends StreamAudioSource {
  BytesAudioSource(this._bytes);

  final Uint8List _bytes;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(_bytes.sublist(from, to)),
      contentType: 'audio/wav',
    );
  }
}

/// Canlı çeviriden gelen ham PCM (24 kHz) parçalarını biriktirip küçük WAV
/// segmentleri hâlinde sırayla çalar. Gerçek zamanlı akışa yakın, basit ve
/// tüm platformlarda çalışan bir yaklaşım.
class PcmSegmentPlayer {
  PcmSegmentPlayer({this.sampleRate = 24000});

  final int sampleRate;
  final _player = AudioPlayer();
  final _queue = <Uint8List>[];
  final _buffer = BytesBuilder();
  Timer? _flushTimer;
  int _lastBufferLength = 0;
  bool _draining = false;
  bool _disposed = false;

  /// ~1 saniyelik ses (24kHz * 2 bayt).
  int get _flushThreshold => sampleRate * 2;

  void addPcm(Uint8List pcm) {
    if (_disposed) return;
    _buffer.add(pcm);
    if (_buffer.length >= _flushThreshold) {
      flush();
    } else {
      // Konuşma sonlarında kalan kuyruğu da çal: buffer 350 ms boyunca
      // büyümezse boşalt.
      _flushTimer ??= Timer.periodic(const Duration(milliseconds: 350), (_) {
        if (_buffer.length > 0 && _buffer.length == _lastBufferLength) {
          flush();
        }
        _lastBufferLength = _buffer.length;
      });
    }
  }

  void flush() {
    if (_disposed || _buffer.isEmpty) return;
    final wav = pcmToWav(_buffer.takeBytes(), sampleRate: sampleRate);
    _queue.add(wav);
    _drain();
  }

  Future<void> _drain() async {
    if (_draining) return;
    _draining = true;
    try {
      while (_queue.isNotEmpty && !_disposed) {
        final wav = _queue.removeAt(0);
        try {
          await _player.setAudioSource(BytesAudioSource(wav));
          await _player.play();
        } catch (_) {
          // Tek segment çalınamazsa akışı durdurma.
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> stop() async {
    _queue.clear();
    _buffer.clear();
    _flushTimer?.cancel();
    _flushTimer = null;
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _player.dispose();
  }
}
