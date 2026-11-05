/// Sayfaya sürüklenip bırakılan dosyalar (F40.8). Yalnız web'de; mobilde/masaüstü
/// derlemede işlevsiz.
library;

export 'web_file_drop_stub.dart'
    if (dart.library.js_interop) 'web_file_drop_web.dart';
