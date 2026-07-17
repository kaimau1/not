import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;

import '../../ai/data/gemini_service.dart';
import 'gmail_auth.dart';

final gmailServiceProvider = Provider<GmailService>(
  (ref) => GmailService(ref.watch(gmailAuthProvider)),
);

/// Gelen kutusundan son e-postaların metadata'sını çeker.
/// Yalnızca From/Subject/Date başlıkları ve Gmail'in kısa önizlemesi
/// (snippet) okunur; e-posta gövdesi hiçbir yere kaydedilmez.
class GmailService {
  GmailService(this._auth);

  final GmailAuth _auth;

  Future<List<EmailMeta>> fetchRecentEmails({int maxResults = 25}) async {
    final client = await _auth.getClient();
    try {
      final api = gmail.GmailApi(client);
      var listResponse = await api.users.messages.list(
        'me',
        q: 'in:inbox category:primary newer_than:2d',
        maxResults: maxResults,
      );
      // Sekmesiz gelen kutularında (ör. Workspace) category:primary hiç
      // sonuç döndürmez; kategorisiz sorguya düş.
      if (listResponse.messages == null || listResponse.messages!.isEmpty) {
        listResponse = await api.users.messages.list(
          'me',
          q: 'in:inbox newer_than:2d',
          maxResults: maxResults,
        );
      }
      final refs = listResponse.messages ?? const <gmail.Message>[];
      // Metadata'ları tek tek beklemek 25 ardışık ağ turu demekti (en büyük
      // yavaşlık kaynağı); hepsi paralel çekilir.
      final messages = await Future.wait([
        for (final ref in refs)
          if (ref.id != null)
            api.users.messages.get(
              'me',
              ref.id!,
              format: 'metadata',
              metadataHeaders: ['From', 'Subject', 'Date'],
            ),
      ]);
      return [for (final message in messages) _toMeta(message)];
    } finally {
      client.close();
    }
  }

  static EmailMeta _toMeta(gmail.Message message) {
    final headers = message.payload?.headers ?? const [];
    String header(String name) =>
        headers
            .firstWhere(
              (h) => (h.name ?? '').toLowerCase() == name.toLowerCase(),
              orElse: gmail.MessagePartHeader.new,
            )
            .value ??
        '';
    return EmailMeta(
      id: message.id ?? '',
      from: header('From'),
      subject: header('Subject'),
      date: header('Date'),
      snippet: message.snippet ?? '',
    );
  }
}
