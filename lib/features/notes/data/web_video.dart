import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/utils/youtube.dart';
import '../domain/attachment.dart';

/// YouTube bağlantısından **dosyasız video eki** kurar (bkz.
/// [Attachment.webUrl]). Bağlantı YouTube videosu değilse null.
///
/// Görsel gibi sayfaya yerleşir, 16:9 kutuda kapak görseliyle görünür;
/// dokununca gömülü oynatıcı (resim içinde resim destekli) açılır.
Attachment? webVideoAttachment(String url, {String title = ''}) {
  final id = youTubeVideoId(url);
  if (id == null) return null;
  final start = youTubeStartSeconds(url);
  return Attachment(
    id: const Uuid().v4(),
    kind: AttachmentKind.video,
    fileName: title.trim().isEmpty ? 'YouTube' : title.trim(),
    mimeType: 'video/youtube',
    // Kanonik adres (izleme parametreleri — `si=` gibi — atılır), başlangıç
    // saniyesi korunur.
    webUrl: start > 0 ? '${youTubeWatchUrl(id)}&t=$start' : youTubeWatchUrl(id),
    width: 16,
    height: 9,
    createdAt: DateTime.now(),
  );
}

/// Videonun başlığı (YouTube oEmbed — API anahtarı istemez). Ağ yoksa ya da
/// 4 sn içinde yanıt gelmezse null: ek yine "YouTube" adıyla eklenir.
Future<String?> fetchYouTubeTitle(String url, {http.Client? client}) async {
  final id = youTubeVideoId(url);
  if (id == null) return null;
  final uri = Uri.https('www.youtube.com', '/oembed', {
    'url': youTubeWatchUrl(id),
    'format': 'json',
  });
  final c = client ?? http.Client();
  try {
    final res = await c.get(uri).timeout(const Duration(seconds: 4));
    if (res.statusCode != 200) return null;
    final map = jsonDecode(utf8.decode(res.bodyBytes));
    if (map is! Map) return null;
    final title = (map['title'] as String?)?.trim();
    return title == null || title.isEmpty ? null : title;
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}
