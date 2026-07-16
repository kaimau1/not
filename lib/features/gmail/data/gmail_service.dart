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
      final listResponse = await api.users.messages.list(
        'me',
        q: 'in:inbox category:primary newer_than:2d',
        maxResults: maxResults,
      );
      final refs = listResponse.messages ?? const <gmail.Message>[];
      final result = <EmailMeta>[];
      for (final ref in refs) {
        final id = ref.id;
        if (id == null) continue;
        final message = await api.users.messages.get(
          'me',
          id,
          format: 'metadata',
          metadataHeaders: ['From', 'Subject', 'Date'],
        );
        final headers = message.payload?.headers ?? const [];
        String header(String name) =>
            headers
                .firstWhere(
                  (h) => (h.name ?? '').toLowerCase() == name.toLowerCase(),
                  orElse: gmail.MessagePartHeader.new,
                )
                .value ??
            '';
        result.add(EmailMeta(
          id: id,
          from: header('From'),
          subject: header('Subject'),
          date: header('Date'),
          snippet: message.snippet ?? '',
        ));
      }
      return result;
    } finally {
      client.close();
    }
  }
}
