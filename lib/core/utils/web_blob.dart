/// Web'de byte dizisinden `blob:` URL üreten koşullu dışa aktarım.
///
/// Yalnız `kIsWeb` iken çağrılmalı — masaüstü/mobil derlemede `dart:html`
/// yerine derlenen gövde (`web_blob_stub.dart`) çağrılırsa hata fırlatır.
export 'web_blob_stub.dart' if (dart.library.js_interop) 'web_blob_web.dart';
