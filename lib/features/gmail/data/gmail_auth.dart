import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/google_scope_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/drive_store.dart' show isGoogleUser;
import 'gmail_api.dart';

typedef GmailAuth = GoogleScopeAuth;

/// Gmail yalnız Google hesabında (misafirde yok) ve Android/web'de.
final gmailAvailableProvider = Provider<bool>((ref) {
  if (!isGoogleUser(ref.watch(authStateProvider).value)) return false;
  return kIsWeb || Platform.isAndroid;
});

final gmailAuthProvider = Provider<GmailAuth?>((ref) {
  if (!ref.watch(gmailAvailableProvider)) return null;
  return googleScopeAuth(kGmailReadonlyScope, 'notlar_gmail_token');
});

/// Oturum boyunca tek jeton önbelleği + istemci (hesap değişince yenilenir).
final gmailSessionProvider =
    Provider<({GmailApi api, ScopeTokenCache tokens, GmailAuth auth})?>((ref) {
      ref.watch(currentUidProvider);
      final auth = ref.watch(gmailAuthProvider);
      if (auth == null) return null;
      final tokens = ScopeTokenCache(silentRefresh: auth.silent);
      final client = http.Client();
      ref.onDispose(client.close);
      return (
        api: GmailApi(client: client, tokens: tokens),
        tokens: tokens,
        auth: auth,
      );
    });
