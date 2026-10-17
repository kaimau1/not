import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'attachment.dart';

/// **TRANSKRİPT** — ses/video/görselin metne dökümü (kullanıcı isteği
/// 2026-10-17: "ses dosyalarının, videoların ve görsellerin transkriptini
/// alma, görüntüleri OCR ile okuma, nota dönüştürme; transkripti metin dosyası
/// olarak ek olarak nota ekleme, okuyabilme, içinden seçip nota ekleyebilme").
///
/// Transkript bir METİN EKİDİR ([AttachmentKind.text]): kaynağına
/// [Attachment.transcriptOf] ile bağlıdır, içeriği [Attachment.text]'te
/// durur. Bu dosyadaki saf kurallar arayüzden ayrı — test edilir.
abstract final class Transcripts {
  static const _uuid = Uuid();

  /// [media] metne dökülebilir mi? Ses, video (yerel ya da YouTube) ve
  /// görsel. PDF/sunumun zaten seçilebilir metni (ve taranmışsa OCR'ı) var.
  static bool canTranscribe(Attachment media) =>
      media.kind == AttachmentKind.audio ||
      media.kind == AttachmentKind.video ||
      media.kind == AttachmentKind.image;

  /// [media]'nın notta KAYITLI transkripti (yoksa null). Birden çoksa (eski
  /// sürüm/iki cihaz aynı anda döktüyse) en yenisi.
  static Attachment? of(List<Attachment> attachments, Attachment media) {
    Attachment? best;
    for (final a in attachments) {
      if (a.kind != AttachmentKind.text || a.transcriptOf != media.id) {
        continue;
      }
      final newer =
          best == null ||
          (a.createdAt ?? DateTime(0)).isAfter(best.createdAt ?? DateTime(0));
      if (newer) best = a;
    }
    return best;
  }

  /// Transkriptin dosya adı: kaynağın adı + [suffix] + `.txt`
  /// ("kayit_12s.m4a" → "kayit_12s (transkript).txt"). YouTube ekinin adı
  /// videonun başlığıdır; yol ayırıcıları temizlenir.
  static String fileNameFor(Attachment media, String suffix) {
    var base = p.basenameWithoutExtension(media.fileName).trim();
    if (media.isWebVideo) base = media.fileName.trim();
    base = base.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (base.isEmpty) base = 'not';
    if (base.length > 60) base = base.substring(0, 60).trimRight();
    return '$base ($suffix).txt';
  }

  /// Metni metin ekinin tavanına ([Attachment.maxTextChars]) indirir ve
  /// uçlardaki boşluğu atar. Kesilirse sona "…" konur — okuyan, metnin
  /// bittiğini sanmasın.
  static String clamp(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= Attachment.maxTextChars) return trimmed;
    return '${trimmed.substring(0, Attachment.maxTextChars).trimRight()}…';
  }

  /// [media] için YENİ bir transkript eki (kimlik yeni, içerik [text]).
  static Attachment create(
    Attachment media,
    String text, {
    required String fileSuffix,
  }) {
    final body = clamp(text);
    return Attachment(
      id: _uuid.v4(),
      kind: AttachmentKind.text,
      fileName: fileNameFor(media, fileSuffix),
      mimeType: 'text/plain',
      text: body,
      transcriptOf: media.id,
      sizeBytes: _utf8Length(body),
      createdAt: DateTime.now(),
    );
  }

  /// Var olan transkriptin içeriğini değiştirir (kimlik ve kaynak aynı).
  static Attachment withText(Attachment transcript, String text) {
    final body = clamp(text);
    return transcript.copyWith(text: body, sizeBytes: _utf8Length(body));
  }

  /// Satır başındaki zaman damgaları: `[1:23]`, `[01:02:03]`, `(0:15)`.
  static final _stamp = RegExp(
    r'^[ \t]*[\[(](?:\d{1,2}:)?\d{1,2}:\d{2}[\])][ \t]*',
    multiLine: true,
  );

  /// Metinde satır başı zaman damgası var mı (görünüm anahtarı yalnız o
  /// zaman gösterilir).
  static bool hasTimestamps(String text) => _stamp.hasMatch(text);

  /// Satır başındaki zaman damgalarını atar ("[0:12] Merhaba" → "Merhaba").
  static String stripTimestamps(String text) => text.replaceAll(_stamp, '');

  /// Köşeli parantezli damgayı notun TANIDIĞI biçime çevirir: `[1:23] söz`
  /// → `1:23 söz`. Not içindeki çıplak "1:23" dokunulunca videoyu oraya
  /// sarar (bkz. `video_time.dart`); parantezli hâli de tanınıyor ama düz
  /// biçim nota daha temiz düşer.
  static String plainTimestamps(String text) => text.replaceAllMapped(
    RegExp(
      r'^([ \t]*)[\[(]((?:\d{1,2}:)?\d{1,2}:\d{2})[\])][ \t]*',
      multiLine: true,
    ),
    (m) => '${m[1]}${m[2]} ',
  );

  static int _utf8Length(String s) {
    var n = 0;
    for (final rune in s.runes) {
      n += rune < 0x80
          ? 1
          : rune < 0x800
          ? 2
          : rune < 0x10000
          ? 3
          : 4;
    }
    return n;
  }
}
