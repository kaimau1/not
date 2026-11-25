import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/local_file.dart';
import '../domain/attachment.dart';
import 'attachment_repository.dart';
import 'scan/scan_ocr.dart';

final mediaTranscriberProvider = Provider<MediaTranscriber>(
  (ref) => MediaTranscriber(ref.watch(attachmentRepositoryProvider)),
);

/// Kaydın biçimi cihazda desteklenmiyor.
class UnsupportedMediaException implements Exception {
  const UnsupportedMediaException(this.format);

  final String format;
}

/// **Eki metne döken yerel motor (ML Kit OCR)** — sıfır AI maliyeti.
///
/// * GÖRSEL: cihaz içi ML Kit OCR (çevrimdışı, ücretsiz).
/// * SES / VİDEO: bulut üretken AI dökümü Faz 1'de kaldırıldı.
class MediaTranscriber {
  MediaTranscriber(this._repo);

  final AttachmentRepository? _repo;

  /// Görsel cihazda (çevrimdışı) okunabiliyor mu?
  static bool get deviceOcr => ScanOcr.supported;

  /// [media]'yı cihaz içi OCR ile metne döker.
  Future<String> transcribe(Attachment media) => switch (media.kind) {
    AttachmentKind.image => _image(media),
    _ => throw UnsupportedMediaException(media.kind.name),
  };

  Future<String> _image(Attachment image) async {
    if (!deviceOcr) {
      throw const UnsupportedMediaException('OCR');
    }
    final path = await _localCopy(image, ext: '.jpg');
    return ScanOcr.recognizeImageText(path);
  }

  Future<Uint8List> _bytes(Attachment a) async {
    final bytes = await _repo?.readBytes(a);
    if (bytes == null) throw const AttachmentMissingException();
    return bytes;
  }

  /// ML Kit dosya yolu ister: yerel kopya yoksa geçici dosyaya yazılır.
  Future<String> _localCopy(Attachment a, {required String ext}) async {
    if (localFileExists(a.localPath)) return a.localPath;
    final bytes = await _bytes(a);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'ocr_${a.id}$ext'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

/// Ses dosyasının GERÇEK biçimi, ilk baytlarından (yoksa [declared]).
String audioMimeOf(List<int> head, String declared) {
  bool at(int offset, String ascii) {
    if (head.length < offset + ascii.length) return false;
    for (var i = 0; i < ascii.length; i++) {
      if (head[offset + i] != ascii.codeUnitAt(i)) return false;
    }
    return true;
  }

  if (at(0, '#!AMR')) return 'audio/amr';
  if (at(4, 'ftyp')) return 'audio/mp4';
  if (at(0, 'ID3')) return 'audio/mpeg';
  if (head.length > 1 && head[0] == 0xFF && (head[1] & 0xE0) == 0xE0) {
    return (head[1] & 0x06) == 0 ? 'audio/aac' : 'audio/mpeg';
  }
  if (at(0, 'RIFF') && at(8, 'WAVE')) return 'audio/wav';
  if (at(0, 'OggS')) return 'audio/ogg';
  if (at(0, 'fLaC')) return 'audio/flac';
  if (head.length > 3 &&
      head[0] == 0x1A &&
      head[1] == 0x45 &&
      head[2] == 0xDF &&
      head[3] == 0xA3) {
    return 'audio/webm';
  }
  return declared.isEmpty ? 'audio/mp4' : declared;
}

/// Seçilen ses DOSYASININ adından MIME türü (bkz. `prepareAudioFile`).
String audioMimeFromName(String name) =>
    switch (p.extension(name).toLowerCase()) {
      '.mp3' => 'audio/mpeg',
      '.wav' => 'audio/wav',
      '.ogg' || '.oga' => 'audio/ogg',
      '.opus' => 'audio/opus',
      '.flac' => 'audio/flac',
      '.aac' => 'audio/aac',
      '.amr' => 'audio/amr',
      '.webm' => 'audio/webm',
      '.3gp' || '.3gpp' => 'audio/3gpp',
      _ => 'audio/mp4',
    };
