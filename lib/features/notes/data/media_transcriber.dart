import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/local_file.dart';
import '../../../core/utils/markdown.dart';
import '../../ai/data/gemini_service.dart';
import '../domain/attachment.dart';
import 'attachment_repository.dart';
import 'scan/scan_ocr.dart';
import 'video_frame.dart' show AudioTrack;

final mediaTranscriberProvider = Provider<MediaTranscriber>(
  (ref) => MediaTranscriber(
    ref.watch(geminiServiceProvider),
    ref.watch(attachmentRepositoryProvider),
  ),
);

/// Kaydın biçimi metne dökülemiyor (ör. Google sesli girişinin AMR kaydı —
/// Gemini AMR kabul etmiyor). Arayüz biçimi söyler.
class UnsupportedMediaException implements Exception {
  const UnsupportedMediaException(this.format);

  final String format;
}

/// **Eki metne döken motor** — kaynağın türüne göre doğru yolu seçer.
///
/// * GÖRSEL: önce CİHAZ İÇİ OCR (ML Kit — internet ve AI puanı gerekmez);
///   [preferAi] ya da cihazda OCR yoksa (Windows) Gemini okur. El yazısı ve
///   bozuk düzende model belirgin daha iyi; kullanıcı ekrandan "AI ile oku"
///   diyerek yeniden okutabilir.
/// * SES: Gemini transkripti (bkz. [GeminiService.transcribeMedia]).
/// * VİDEO: Android'de önce SES İZİ ayrılır ([AudioTrack]) — döküm için
///   görüntü gerekmez, ses aynı kaydın 20-50'de biri. Ayrılamazsa video
///   kendisi gider. YouTube videosunu model bağlantıdan kendisi açar.
class MediaTranscriber {
  MediaTranscriber(this._ai, this._repo);

  final GeminiService _ai;
  final AttachmentRepository? _repo;

  /// Görsel cihazda (çevrimdışı) okunabiliyor mu?
  static bool get deviceOcr => ScanOcr.supported;

  /// [media]'yı metne döker. Boş dönüş = metin bulunamadı (görselde yazı
  /// yok / kayıtta konuşma yok).
  Future<String> transcribe(Attachment media, {bool preferAi = false}) =>
      switch (media.kind) {
        AttachmentKind.image => _image(media, preferAi: preferAi),
        AttachmentKind.audio => _audio(media),
        AttachmentKind.video => _video(media),
        _ => throw UnsupportedError('${media.kind} metne dökülemez'),
      };

  Future<String> _image(Attachment image, {required bool preferAi}) async {
    if (!preferAi && deviceOcr) {
      final path = await _localCopy(image, ext: '.jpg');
      return ScanOcr.recognizeImageText(path);
    }
    final bytes = await _bytes(image);
    final text = await _ai.extractTextFromImage(bytes, image.mimeType);
    return stripMarkdown(text).trim();
  }

  Future<String> _audio(Attachment audio) async {
    if (localFileExists(audio.localPath)) {
      final mime = await _audioMime(audio.localPath, audio.mimeType);
      return _ai.transcribeMedia(mimeType: mime, filePath: audio.localPath);
    }
    final bytes = await _bytes(audio);
    final mime = audioMimeOf(bytes, audio.mimeType);
    if (mime == 'audio/amr') throw const UnsupportedMediaException('AMR');
    return _ai.transcribeMedia(mimeType: mime, bytes: bytes);
  }

  Future<String> _video(Attachment video) async {
    if (video.isWebVideo) {
      return _ai.transcribeMedia(
        mimeType: 'video/mp4',
        webUrl: video.webUrl,
        video: true,
      );
    }
    // Görüntülü not yalnız cihazda yaşar (buluta yüklenmez).
    if (!localFileExists(video.localPath)) {
      throw const AttachmentMissingException();
    }
    if (AudioTrack.supported) {
      final dir = await getTemporaryDirectory();
      final out = File(p.join(dir.path, 'transkript_${video.id}.m4a'));
      try {
        if (await AudioTrack.extract(video.localPath, out.path) &&
            await out.exists()) {
          return await _ai.transcribeMedia(
            mimeType: 'audio/mp4',
            filePath: out.path,
          );
        }
      } finally {
        if (await out.exists()) await out.delete();
      }
    }
    return _ai.transcribeMedia(
      mimeType: video.mimeType.isEmpty ? 'video/mp4' : video.mimeType,
      filePath: video.localPath,
      video: true,
    );
  }

  Future<Uint8List> _bytes(Attachment a) async {
    final bytes = await _repo?.readBytes(a);
    if (bytes == null) throw const AttachmentMissingException();
    return bytes;
  }

  /// ML Kit dosya yolu ister: yerel kopya yoksa (başka cihazdan gelen ek)
  /// baytlar geçici bir dosyaya yazılır.
  Future<String> _localCopy(Attachment a, {required String ext}) async {
    if (localFileExists(a.localPath)) return a.localPath;
    final bytes = await _bytes(a);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'ocr_${a.id}$ext'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<String> _audioMime(String path, String declared) async {
    final raf = await File(path).open();
    try {
      final head = await raf.read(16);
      final mime = audioMimeOf(head, declared);
      if (mime == 'audio/amr') throw const UnsupportedMediaException('AMR');
      return mime;
    } finally {
      await raf.close();
    }
  }
}

/// Ses dosyasının GERÇEK biçimi, ilk baytlarından (yoksa [declared]).
///
/// KÖK NEDEN: Google sesli girişinin döndürdüğü kayıt AMR-NB ama nota
/// `.m4a` / `audio/mp4` adıyla bağlanıyordu (bkz. `prepareAudio`). Oynatıcı
/// içeriği kokladığı için çalıyordu; AI'a yanlış türle gönderilince istek
/// reddediliyor. Baytlar her zaman doğruyu söyler.
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
    // MPEG çerçeve senkronu: 0xFFF1/0xFFF9 ADTS-AAC, gerisi MP3.
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
