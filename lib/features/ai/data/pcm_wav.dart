import 'dart:typed_data';

/// Gemini seslendirme modelinin döndürdüğü HAM PCM'e WAV başlığı yazar.
///
/// Model sesi `audio/L16;codec=pcm;rate=24000` olarak, yani başlıksız 16 bit
/// işaretli little-endian tek kanal örnekleri olarak verir. Hiçbir oynatıcı
/// (just_audio dahil) başlıksız akışı çalamaz — 44 baytlık kanonik RIFF/WAVE
/// başlığı burada yazılır. Saf fonksiyon → birim testli.
Uint8List pcmToWav(
  Uint8List pcm, {
  int sampleRate = 24000,
  int channels = 1,
  int bitsPerSample = 16,
}) {
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final header = ByteData(44);

  void ascii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      header.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little); // dosya boyutu - 8
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little); // fmt bloğu uzunluğu
  header.setUint16(20, 1, Endian.little); // 1 = PCM (sıkıştırmasız)
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, byteRate, Endian.little);
  header.setUint16(32, blockAlign, Endian.little);
  header.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);

  final out = Uint8List(44 + pcm.length);
  out.setRange(0, 44, header.buffer.asUint8List());
  out.setRange(44, out.length, pcm);
  return out;
}

/// `audio/L16;codec=pcm;rate=24000` gibi bir MIME'dan örnekleme hızını okur.
///
/// Model bugün 24 kHz veriyor ama bunu koda gömmek riskli: hız değişirse ses
/// başlıkta yanlış yazılır ve kayıt tiz/pes çalar (bozuk değil, YANLIŞ
/// çaldığı için fark edilmesi de zor). Okunamazsa 24 kHz varsayılır.
int pcmSampleRate(String mimeType) {
  final match = RegExp(r'rate=(\d+)').firstMatch(mimeType);
  final value = int.tryParse(match?.group(1) ?? '');
  return value == null || value <= 0 ? 24000 : value;
}
