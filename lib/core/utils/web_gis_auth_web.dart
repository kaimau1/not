import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

typedef WebGisToken = ({String token, int expiresIn});

JSObject? _oauth2Client() {
  try {
    final google = globalContext.getProperty<JSAny?>('google'.toJS);
    if (google == null || !google.isA<JSObject>()) return null;
    final accounts = (google as JSObject).getProperty<JSAny?>('accounts'.toJS);
    if (accounts == null || !accounts.isA<JSObject>()) return null;
    final oauth2 = (accounts as JSObject).getProperty<JSAny?>('oauth2'.toJS);
    if (oauth2 == null || !oauth2.isA<JSObject>()) return null;
    final oauthObj = oauth2 as JSObject;
    if (!oauthObj.has('initTokenClient')) return null;
    return oauthObj;
  } catch (_) {
    return null;
  }
}

bool get isWebGisAvailable => _oauth2Client() != null;

const _kGisPollStepMs = 150;

Future<WebGisToken?> requestWebGisToken({
  required String clientId,
  required List<String> scopes,
  String? loginHint,
  required bool silent,
}) async {
  if (clientId.isEmpty || scopes.isEmpty) return null;
  var oauth2 = _oauth2Client();
  if (oauth2 == null && silent) {
    // Betik async/defer yükleniyor olabilir; sessiz yenilemede kısa bekle.
    for (var i = 0; i < 10 && oauth2 == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: _kGisPollStepMs));
      oauth2 = _oauth2Client();
    }
  }
  if (oauth2 == null) return null;

  final completer = Completer<WebGisToken?>();
  void finish(WebGisToken? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  try {
    final config = JSObject();
    config.setProperty('client_id'.toJS, clientId.toJS);
    config.setProperty('scope'.toJS, scopes.join(' ').toJS);
    if (loginHint != null && loginHint.isNotEmpty) {
      config.setProperty('hint'.toJS, loginHint.toJS);
    }
    config.setProperty(
      'callback'.toJS,
      ((JSObject response) {
        try {
          final errorAny = response.getProperty<JSAny?>('error'.toJS);
          if (errorAny != null && !errorAny.isUndefinedOrNull) {
            finish(null);
            return;
          }
          final tokenAny = response.getProperty<JSAny?>('access_token'.toJS);
          if (tokenAny == null || !tokenAny.isA<JSString>()) {
            finish(null);
            return;
          }
          final token = (tokenAny as JSString).toDart;
          if (token.isEmpty) {
            finish(null);
            return;
          }
          var expiresIn = 3300;
          final expAny = response.getProperty<JSAny?>('expires_in'.toJS);
          if (expAny != null && expAny.isA<JSNumber>()) {
            expiresIn = (expAny as JSNumber).toDartInt;
          } else if (expAny != null && expAny.isA<JSString>()) {
            expiresIn = int.tryParse((expAny as JSString).toDart) ?? 3300;
          }
          finish((token: token, expiresIn: expiresIn));
        } catch (_) {
          finish(null);
        }
      }).toJS,
    );
    config.setProperty(
      'error_callback'.toJS,
      ((JSAny? _) => finish(null)).toJS,
    );

    final tokenClient = oauth2.callMethod<JSObject>(
      'initTokenClient'.toJS,
      config,
    );
    final req = JSObject();
    req.setProperty('prompt'.toJS, (silent ? 'none' : '').toJS);
    tokenClient.callMethod<JSAny?>('requestAccessToken'.toJS, req);
  } catch (_) {
    finish(null);
  }

  return completer.future.timeout(
    silent ? const Duration(seconds: 6) : const Duration(minutes: 2),
    onTimeout: () => null,
  );
}
