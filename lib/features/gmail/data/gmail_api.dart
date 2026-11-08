import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../auth/data/google_scope_auth.dart' show ScopeTokenCache;

/// **GMAIL — YALNIZ OKUMA** (F28.1, 2026-11-04).
///
/// KARAR (kullanıcı, 2026-11-03): `gmail.readonly`; Gmail'de HİÇBİR ŞEY
/// değiştirilmez (etiket, arşiv, okundu işareti yok). Bu istemci bu yüzden
/// yalnız GET istekleri yapar — test (`gmail_api_test`) bunu doğrular.
///
/// Kapsam kısıtlı (restricted) sınıfta: OAuth "Testing" modunda kişisel
/// kullanım sorunsuz; yayına alınırsa Google güvenlik denetimi gerekir
/// (F19). Konsol adımı: Gmail API etkin + onay ekranına kapsam.
const kGmailReadonlyScope = 'https://www.googleapis.com/auth/gmail.readonly';

const _api = 'https://gmail.googleapis.com/gmail/v1/users/me';

class GmailApiException implements Exception {
  GmailApiException(this.status, this.body);
  final int status;
  final String body;
  bool get unauthorized => status == 401 || status == 403;
  @override
  String toString() => 'GmailApiException($status)';
}

/// Listede bir satır (gövde yok — açılınca [GmailApi.message]).
class GmailSummary {
  const GmailSummary({
    required this.id,
    required this.subject,
    required this.from,
    required this.snippet,
    this.date,
    this.hasAttachments = false,
    this.unread = false,
    this.starred = false,
    this.tags = const [],
  });
  final String id;
  final String subject;
  final String from;
  final String snippet;

  /// Liste çipleri: Gmail kategori/önem etiketlerinden (`promotions`,
  /// `social`, `updates`, `forums`, `important`). YALNIZ GÖSTERİM.
  final List<String> tags;
  final DateTime? date;
  final bool hasAttachments;

  /// Gmail etiketlerinden (`UNREAD`, `STARRED`) — YALNIZ GÖSTERİM; okundu
  /// işareti hiçbir zaman yazılmaz (gmail.readonly).
  final bool unread;
  final bool starred;
}

class GmailAttachmentRef {
  const GmailAttachmentRef({
    required this.attachmentId,
    required this.fileName,
    required this.mimeType,
    required this.size,
  });
  final String attachmentId;
  final String fileName;
  final String mimeType;
  final int size;
}

/// Açılmış e-posta.
class GmailMessage {
  const GmailMessage({
    required this.id,
    required this.subject,
    required this.from,
    required this.body,
    this.date,
    this.attachments = const [],
  });
  final String id;
  final String subject;
  final String from;
  final String body;
  final DateTime? date;
  final List<GmailAttachmentRef> attachments;

  /// Gmail web'de bu e-postanın adresi (nota kaynak bağlantısı).
  String get webUrl => 'https://mail.google.com/mail/u/0/#all/$id';
}

class GmailApi {
  GmailApi({required this._client, required this._tokens});

  final http.Client _client;
  final ScopeTokenCache _tokens;

  /// YALNIZ GET — yazma uç noktası bu sınıfta yok.
  Future<http.Response> _get(Uri uri) async {
    Future<http.Response> once() async {
      final token = await _tokens.get();
      if (token == null) throw GmailApiException(401, 'jeton yok');
      return _client.get(uri, headers: {'Authorization': 'Bearer $token'});
    }

    var res = await once();
    if (res.statusCode == 401) {
      _tokens.invalidate();
      res = await once();
    }
    if (res.statusCode >= 300) {
      throw GmailApiException(res.statusCode, res.body);
    }
    return res;
  }

  /// Gelen kutusu / arama. [query] Gmail arama sözdizimi (boş = gelen
  /// kutusu). Sayfalama: dönen `next` bir sonraki çağrıya [pageToken].
  Future<({List<GmailSummary> items, String? next})> list({
    String query = '',
    String? pageToken,
    int pageSize = 20,
  }) async {
    final res = await _get(
      Uri.parse('$_api/messages').replace(
        queryParameters: {
          'maxResults': '$pageSize',
          if (query.trim().isEmpty) 'labelIds': 'INBOX',
          if (query.trim().isNotEmpty) 'q': query.trim(),
          'pageToken': ?pageToken,
        },
      ),
    );
    final j = _json(res) as Map<String, dynamic>;
    final ids = [
      for (final m in (j['messages'] as List?) ?? const [])
        (m as Map)['id'] as String,
    ];
    // Başlıklar ayrı isteklerle (metadata biçimi — gövde inmez). Az sayıda
    // (sayfa ≤ 20) olduğundan eşzamanlı.
    final items = await Future.wait(ids.map(_summary));
    return (items: items, next: j['nextPageToken'] as String?);
  }

  Future<GmailSummary> _summary(String id) async {
    final res = await _get(
      Uri.parse('$_api/messages/$id').replace(
        queryParameters: {
          'format': 'metadata',
          'metadataHeaders': ['Subject', 'From', 'Date'],
        },
      ),
    );
    return parseSummary(_json(res) as Map<String, dynamic>);
  }

  Future<GmailMessage> message(String id) async {
    final res = await _get(
      Uri.parse('$_api/messages/$id')
          .replace(queryParameters: {'format': 'full'}),
    );
    return parseMessage(_json(res) as Map<String, dynamic>);
  }

  Future<Uint8List> attachment(String messageId, String attachmentId) async {
    final res = await _get(
      Uri.parse('$_api/messages/$messageId/attachments/$attachmentId'),
    );
    final data = (_json(res) as Map)['data'] as String? ?? '';
    return decodeBase64Url(data);
  }
}

/// Gövde HER ZAMAN UTF-8 çözülür: `http` başlıkta charset yoksa latin1
/// varsayar ve Türkçe karakterler bozulur.
dynamic _json(http.Response res) =>
    jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));

// ── Saf ayrıştırma (testli) ───────────────────────────────────────────────

Uint8List decodeBase64Url(String s) {
  var t = s.replaceAll('-', '+').replaceAll('_', '/');
  while (t.length % 4 != 0) {
    t += '=';
  }
  return base64.decode(t);
}

String _header(Map<String, dynamic> payload, String name) {
  for (final h in (payload['headers'] as List?) ?? const []) {
    final m = h as Map;
    if ((m['name'] as String).toLowerCase() == name.toLowerCase()) {
      return (m['value'] as String?) ?? '';
    }
  }
  return '';
}

DateTime? _date(Map<String, dynamic> j) {
  final ms = int.tryParse('${j['internalDate'] ?? ''}');
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

/// `"Ad Soyad <a@b.c>"` → `"Ad Soyad"` (ad yoksa adres).
String displayFrom(String from) {
  final m = RegExp(r'^\s*"?([^"<]*?)"?\s*<([^>]+)>').firstMatch(from);
  if (m == null) return from.trim();
  final name = m.group(1)!.trim();
  return name.isEmpty ? m.group(2)!.trim() : name;
}

void _walk(
  Map<String, dynamic> part,
  void Function(Map<String, dynamic> part) visit,
) {
  visit(part);
  for (final p in (part['parts'] as List?) ?? const []) {
    _walk(Map<String, dynamic>.from(p as Map), visit);
  }
}

GmailSummary parseSummary(Map<String, dynamic> j) {
  final payload = Map<String, dynamic>.from((j['payload'] as Map?) ?? {});
  final labels = {for (final l in (j['labelIds'] as List?) ?? const []) '$l'};
  var hasAttachments = false;
  _walk(payload, (p) {
    if (((p['filename'] as String?) ?? '').isNotEmpty) hasAttachments = true;
  });
  return GmailSummary(
    id: j['id'] as String,
    subject: _header(payload, 'Subject'),
    from: displayFrom(_header(payload, 'From')),
    snippet: htmlToText((j['snippet'] as String?) ?? ''),
    date: _date(j),
    hasAttachments: hasAttachments,
    unread: labels.contains('UNREAD'),
    starred: labels.contains('STARRED'),
    tags: [
      if (labels.contains('IMPORTANT')) 'important',
      if (labels.contains('CATEGORY_PROMOTIONS')) 'promotions',
      if (labels.contains('CATEGORY_SOCIAL')) 'social',
      if (labels.contains('CATEGORY_UPDATES')) 'updates',
      if (labels.contains('CATEGORY_FORUMS')) 'forums',
    ],
  );
}

GmailMessage parseMessage(Map<String, dynamic> j) {
  final payload = Map<String, dynamic>.from((j['payload'] as Map?) ?? {});
  String? plain, html;
  final attachments = <GmailAttachmentRef>[];
  _walk(payload, (p) {
    final mime = (p['mimeType'] as String?) ?? '';
    final body = Map<String, dynamic>.from((p['body'] as Map?) ?? {});
    final fileName = (p['filename'] as String?) ?? '';
    if (fileName.isNotEmpty && body['attachmentId'] != null) {
      attachments.add(
        GmailAttachmentRef(
          attachmentId: body['attachmentId'] as String,
          fileName: fileName,
          mimeType: mime,
          size: (body['size'] as num?)?.toInt() ?? 0,
        ),
      );
      return;
    }
    final data = body['data'] as String?;
    if (data == null) return;
    final text = utf8.decode(decodeBase64Url(data), allowMalformed: true);
    if (mime == 'text/plain') plain ??= text;
    if (mime == 'text/html') html ??= text;
  });
  return GmailMessage(
    id: j['id'] as String,
    subject: _header(payload, 'Subject'),
    from: _header(payload, 'From'),
    body: (plain ?? (html == null ? '' : htmlToText(html!))).trim(),
    date: _date(j),
    attachments: attachments,
  );
}

/// Kaba ama güvenli HTML → düz metin (yalnız e-posta gövdesi için; DOM
/// kurulmaz, betik çalıştırılmaz).
String htmlToText(String html) {
  var s = html
      .replaceAll(
        RegExp(
          r'<(script|style)[^>]*>.*?</\1>',
          caseSensitive: false,
          dotAll: true,
        ),
        '',
      )
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</(p|div|tr|li|h[1-6])>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]+>'), '');
  const entities = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
  };
  entities.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m.group(1)!)),
  );
  return s
      .split('\n')
      .map((l) => l.trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
