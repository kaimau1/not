import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../auth/data/google_scope_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../notes/data/drive_store.dart' show isGoogleUser;
import '../../settings/settings_providers.dart';
import 'gmail_api.dart';

typedef GmailAuth = GoogleScopeAuth;

/// Gmail yalnız Google hesabında (misafirde yok) ve Android/web'de.
final gmailAvailableProvider = Provider<bool>((ref) {
  if (!isGoogleUser(ref.watch(authStateProvider).value)) return false;
  return kIsWeb || Platform.isAndroid;
});

/// Ek hesap yalnız Android'de (sistemin hesap seçicisi; web giriş hesabında).
bool get gmailMultiAccount => !kIsWeb && Platform.isAndroid;

/// GMAIL ÇOKLU HESAP (kullanıcı isteği 2026-11-08): [extra] cihazdaki ek
/// Google hesapları, [active] Gmail ekranının şu an okuduğu (null = giriş
/// hesabı). Uygulamanın giriş hesabı DEĞİŞMEZ; yalnız Gmail jetonu o
/// hesaptan istenir. Cihaz tercihidir.
typedef GmailAccounts = ({List<String> extra, String? active});

final gmailAccountsProvider =
    NotifierProvider<GmailAccountsNotifier, GmailAccounts>(
      GmailAccountsNotifier.new,
    );

class GmailAccountsNotifier extends Notifier<GmailAccounts> {
  static const _kExtra = 'gmail_accounts';
  static const _kActive = 'gmail_active';

  @override
  GmailAccounts build() {
    final p = ref.watch(sharedPreferencesProvider);
    final extra = p.getStringList(_kExtra) ?? const <String>[];
    final active = p.getString(_kActive);
    return (extra: extra, active: extra.contains(active) ? active : null);
  }

  void _save(GmailAccounts next) {
    final p = ref.read(sharedPreferencesProvider);
    p.setStringList(_kExtra, next.extra);
    next.active == null ? p.remove(_kActive) : p.setString(_kActive, next.active!);
    state = next;
  }

  /// null = giriş hesabına dön.
  void select(String? email) => _save((extra: state.extra, active: email));

  /// [primary] giriş hesabının e-postası (o ek olarak tutulmaz).
  void add(String email, {String? primary}) {
    if (email == primary) return select(null);
    _save((
      extra: state.extra.contains(email) ? state.extra : [...state.extra, email],
      active: email,
    ));
  }

  void remove(String email) => _save((
    extra: [for (final e in state.extra) if (e != email) e],
    active: state.active == email ? null : state.active,
  ));
}

final gmailAuthProvider = Provider<GmailAuth?>((ref) {
  if (!ref.watch(gmailAvailableProvider)) return null;
  final active = gmailMultiAccount
      ? ref.watch(gmailAccountsProvider.select((a) => a.active))
      : null;
  return googleScopeAuth(
    kGmailReadonlyScope,
    active == null ? 'notlar_gmail_token' : 'notlar_gmail_token_$active',
    account: active,
  );
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
