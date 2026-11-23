typedef WebGisToken = ({String token, int expiresIn});

bool get isWebGisAvailable => false;

Future<WebGisToken?> requestWebGisToken({
  required String clientId,
  required List<String> scopes,
  String? loginHint,
  required bool silent,
}) async => null;
