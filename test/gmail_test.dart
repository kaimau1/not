import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/gmail/data/gmail_api.dart';
import 'package:notlar/features/gmail/domain/gmail_note.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';

String b64(String s) => base64Url.encode(utf8.encode(s)).replaceAll('=', '');

Map<String, dynamic> fullMessage() => {
  'id': 'm1',
  'internalDate': '${DateTime(2026, 11, 3, 10).millisecondsSinceEpoch}',
  'snippet': 'Merhaba &amp; selam',
  'payload': {
    'mimeType': 'multipart/mixed',
    'headers': [
      {'name': 'Subject', 'value': 'Fatura Kasım'},
      {'name': 'From', 'value': '"Ayşe Y" <ayse@ornek.com>'},
    ],
    'parts': [
      {
        'mimeType': 'multipart/alternative',
        'parts': [
          {
            'mimeType': 'text/html',
            'body': {'data': b64('<p>HTML <b>gövde</b></p>')},
          },
          {
            'mimeType': 'text/plain',
            'body': {'data': b64('Düz gövde: 120 TL')},
          },
        ],
      },
      {
        'mimeType': 'application/pdf',
        'filename': 'fatura.pdf',
        'body': {'attachmentId': 'att1', 'size': 1234},
      },
    ],
  },
};

ScopeTokenCache tokens() => ScopeTokenCache(
  silentRefresh: () async =>
      (token: 'g', expiry: DateTime.now().add(const Duration(hours: 1))),
);

void main() {
  test('ayrıştırma: düz metin önce, ekler, gönderen adı', () {
    final m = parseMessage(fullMessage());
    expect(m.subject, 'Fatura Kasım');
    expect(m.body, 'Düz gövde: 120 TL');
    expect(m.attachments.single.fileName, 'fatura.pdf');
    expect(m.attachments.single.attachmentId, 'att1');
    expect(displayFrom(m.from), 'Ayşe Y');
    expect(displayFrom('a@b.c'), 'a@b.c');
    expect(displayFrom('<a@b.c>'), 'a@b.c');

    final s = parseSummary(fullMessage());
    expect(s.hasAttachments, isTrue);
    expect(s.snippet, 'Merhaba & selam');
  });

  test('yalnız HTML gövde düz metne çevrilir, betik atılır', () {
    expect(
      htmlToText(
        '<style>x{}</style><p>Bir</p><script>alert(1)</script>İki<br>Üç &#65;',
      ),
      'Bir\nİki\nÜç A',
    );
  });

  test('istemci YALNIZ GET yapar (gmail.readonly kararı)', () async {
    final methods = <String>{};
    final client = MockClient((r) async {
      methods.add(r.method);
      if (r.url.path.endsWith('/messages')) {
        expect(r.url.queryParameters['labelIds'], 'INBOX');
        return http.Response(
          jsonEncode({
            'messages': [
              {'id': 'm1'},
            ],
            'nextPageToken': 'p2',
          }),
          200,
        );
      }
      if (r.url.path.contains('/attachments/')) {
        return http.Response(jsonEncode({'data': b64('PDF')}), 200);
      }
      return http.Response.bytes(utf8.encode(jsonEncode(fullMessage())), 200);
    });
    final api = GmailApi(client: client, tokens: tokens());
    final page = await api.list();
    expect(page.items.single.subject, 'Fatura Kasım');
    expect(page.next, 'p2');
    await api.message('m1');
    expect(utf8.decode(await api.attachment('m1', 'att1')), 'PDF');
    expect(methods, {'GET'});
  });

  test('arama sorgusu q ile gider, gelen kutusu süzgeci kalkar', () async {
    late Uri listUri;
    final client = MockClient((r) async {
      if (r.url.path.endsWith('/messages')) {
        listUri = r.url;
        return http.Response('{}', 200);
      }
      return http.Response('{}', 500);
    });
    final api = GmailApi(client: client, tokens: tokens());
    final page = await api.list(query: ' from:ayse ');
    expect(page.items, isEmpty);
    expect(listUri.queryParameters['q'], 'from:ayse');
    expect(listUri.queryParameters.containsKey('labelIds'), isFalse);
  });

  test('not taslağı: konu başlık, gövde + kaynak satırı', () {
    final d = noteDraftFromEmail(parseMessage(fullMessage()));
    expect(d.title, 'Fatura Kasım');
    expect(d.body, startsWith('Düz gövde: 120 TL\n\n— Ayşe Y · 2026-11-03'));
    expect(d.body, endsWith('https://mail.google.com/mail/u/0/#all/m1'));
    final ai = noteDraftFromEmail(
      parseMessage(fullMessage()),
      replacementBody: 'Özet',
    );
    expect(ai.body, startsWith('Özet\n\n—'));
  });

  test('AI görev satırları maddeye çevrilir', () {
    expect(
      taskItemsFromAi('Başlık\n- Öde\n• Ara\n2. Gönder\n[ ] Kontrol\n-yok'),
      ['Öde', 'Ara', 'Gönder', 'Kontrol'],
    );
    expect(taskItemsFromAi('Hiç madde yok'), isEmpty);
  });
}
