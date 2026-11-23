import 'package:record/record.dart';

import '../constants.dart';

/// Kodlayıcıya göre Web kayıt MIME ipucu.
String mimeHintForEncoder(AudioEncoder encoder) => switch (encoder) {
  AudioEncoder.opus => 'audio/webm',
  AudioEncoder.aacLc ||
  AudioEncoder.aacEld ||
  AudioEncoder.aacHe => 'audio/mp4',
  AudioEncoder.wav => 'audio/wav',
  AudioEncoder.flac => 'audio/flac',
  _ => 'audio/webm',
};

/// Tarayıcının desteklediği en verimli tek-kanal ses kayıt ayarını seçer.
///
/// Chrome/Edge/Firefox `opus` (WebM), Safari `aacLc` (MP4), hiçbiri yoksa
/// evrensel yedek olarak `wav` seçilir.
Future<RecordConfig> pickWebRecordConfig(
  AudioRecorder recorder, {
  int bitRate = AppConstants.audioBitRate,
  int sampleRate = AppConstants.audioSampleRate,
}) async {
  const candidates = [AudioEncoder.opus, AudioEncoder.aacLc, AudioEncoder.wav];
  var chosen = AudioEncoder.wav;
  for (final encoder in candidates) {
    try {
      if (await recorder.isEncoderSupported(encoder)) {
        chosen = encoder;
        break;
      }
    } catch (_) {}
  }
  return RecordConfig(
    encoder: chosen,
    bitRate: bitRate,
    sampleRate: sampleRate,
    numChannels: 1,
  );
}
