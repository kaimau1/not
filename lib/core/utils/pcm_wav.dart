import 'dart:typed_data';

/// Gemini TTS'in döndürdüğü ham PCM (16-bit, mono) veriyi oynatılabilir
/// bir WAV dosyasına çevirir.
Uint8List pcmToWav(
  Uint8List pcm, {
  int sampleRate = 24000,
  int channels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final dataSize = pcm.length;
  final builder = BytesBuilder();

  void writeString(String value) => builder.add(value.codeUnits);
  void writeUint32(int value) {
    final b = ByteData(4)..setUint32(0, value, Endian.little);
    builder.add(b.buffer.asUint8List());
  }

  void writeUint16(int value) {
    final b = ByteData(2)..setUint16(0, value, Endian.little);
    builder.add(b.buffer.asUint8List());
  }

  writeString('RIFF');
  writeUint32(36 + dataSize);
  writeString('WAVE');
  writeString('fmt ');
  writeUint32(16);
  writeUint16(1); // PCM
  writeUint16(channels);
  writeUint32(sampleRate);
  writeUint32(byteRate);
  writeUint16(blockAlign);
  writeUint16(bitsPerSample);
  writeString('data');
  writeUint32(dataSize);
  builder.add(pcm);

  return builder.toBytes();
}
