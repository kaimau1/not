import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/auth/data/google_scope_auth.dart';
import 'package:notlar/features/gmail/data/gmail_api.dart';
import 'package:notlar/features/gmail/data/gmail_auth.dart';
import 'package:notlar/features/gmail/domain/gmail_note.dart';
import 'package:notlar/features/gmail/presentation/gmail_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

class _NoAuth implements GoogleScopeAuth {
  @override
  Future<({String token, DateTime expiry})?> connect() async => null;
  @override
  Future<({String token, DateTime expiry})?> silent() async => null;
}

/// Gmail ekranı baştan (kullanıcı isteği 2026-11-06).
void main() {
  test('süzgeç → Gmail sorgusu', () {
    expect(gmailQuery(GmailFilter.inbox, ''), '');
    expect(gmailQuery(GmailFilter.inbox, ' fatura '), 'fatura');
    expect(gmailQuery(GmailFilter.unread, ''), 'in:inbox is:unread');
    expect(
      gmailQuery(GmailFilter.attachments, 'pdf'),
      'in:inbox has:attachment pdf',
    );
    expect(gmailQuery(GmailFilter.today, ''), 'in:inbox newer_than:1d');
  });

  test('tarih kümesi ve baş harf', () {
    final now = DateTime(2026, 11, 6, 15);
    expect(gmailDayOf(DateTime(2026, 11, 6, 1), now), GmailDay.today);
    expect(gmailDayOf(DateTime(2026, 11, 5, 23), now), GmailDay.yesterday);
    expect(gmailDayOf(DateTime(2026, 11, 2), now), GmailDay.thisWeek);
    expect(gmailDayOf(DateTime(2026, 10, 1), now), GmailDay.older);
    expect(gmailDayOf(null, now), GmailDay.older);
    expect(senderInitial('"ilker A" <i@x.com>'), 'İ');
    expect(senderInitial('<"ayse@x.com">'), 'A');
    expect(senderInitial('***'), '?');
  });

  test('okunmamış / yıldızlı etiketten okunur', () {
    final s = parseSummary({
      'id': 'm1',
      'labelIds': ['INBOX', 'UNREAD', 'STARRED'],
      'payload': {'headers': []},
    });
    expect(s.unread, isTrue);
    expect(s.starred, isTrue);
    expect(parseSummary({'id': 'm2'}).unread, isFalse);
  });

  testWidgets('liste: tarih başlığı, satır, süzgeç sorguyu değiştirir', (
    tester,
  ) async {
    final queries = <String?>[];
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/messages')) {
        queries.add(req.url.queryParameters['q']);
        return http.Response(
          jsonEncode({
            'messages': [
              {'id': 'a'},
            ],
          }),
          200,
        );
      }
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'id': 'a',
            'internalDate': '${DateTime.now().millisecondsSinceEpoch}',
            'labelIds': ['UNREAD'],
            'snippet': 'Kasım faturası hazır',
            'payload': {
              'headers': [
                {'name': 'Subject', 'value': 'Fatura'},
                {'name': 'From', 'value': '"Ayşe" <a@x.com>'},
              ],
            },
          }),
        ),
        200,
      );
    });
    final tokens = ScopeTokenCache(silentRefresh: () async => null)
      ..put('t', DateTime.now().add(const Duration(hours: 1)));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gmailAvailableProvider.overrideWithValue(true),
          gmailSessionProvider.overrideWithValue((
            api: GmailApi(client: client, tokens: tokens),
            tokens: tokens,
            auth: _NoAuth(),
          )),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('tr'),
          home: GmailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bugün'), findsWidgets);
    expect(find.text('Ayşe'), findsOneWidget);
    expect(find.text('Fatura'), findsOneWidget);
    expect(queries.last, isNull);
    await tester.tap(find.byKey(const ValueKey('gmail-filter-unread')));
    await tester.pumpAndSettle();
    expect(queries.last, 'in:inbox is:unread');
  });
}
