/// Web'de byte dizisinden `blob:` URL üreten koşullu dışa aktarım ve oturum
/// boyunca blob URL önbellekleri.
///
/// Yalnız `kIsWeb` iken `createBlobUrl`/`downloadBytes` çağrılmalı — masaüstü/
/// mobil derlemede gövde (`web_blob_stub.dart`) hata fırlatır.
library;

import 'package:flutter/foundation.dart' show ValueNotifier;

export 'web_blob_stub.dart' if (dart.library.js_interop) 'web_blob_web.dart';

/// Drive kimliğine göre bu oturumda çözülmüş `blob:` adresleri.
final ValueNotifier<Map<String, String>> webDriveBlobUrls =
    ValueNotifier<Map<String, String>>(const {});

/// Henüz buluta çıkmamış yerel (`local:*`) eklerin `blob:` adresleri.
final ValueNotifier<Map<String, String>> webLocalBlobUrls =
    ValueNotifier<Map<String, String>>(const {});

void rememberWebDriveBlobUrl(String driveId, String url) =>
    webDriveBlobUrls.value = {...webDriveBlobUrls.value, driveId: url};

void rememberWebLocalBlobUrl(String attachmentId, String url) =>
    webLocalBlobUrls.value = {...webLocalBlobUrls.value, attachmentId: url};
