/// WEB'de YouTube'u sayfanın içinde oynatan iframe (koşullu dışa aktarım).
///
/// Mobilde gömülü oynatıcı `webview_flutter` ile kuruluyor; o eklentinin web
/// karşılığı yok. Tarayıcıda ise iframe zaten yerli: Flutter'ın platform
/// görünümü ([HtmlElementView]) içine konur. Mobil dışı/web dışı derlemede
/// gövde boş bir kutudur ve hiç çağrılmaz (bkz. `youTubeInAppSupported`).
library;

export 'youtube_web_frame_stub.dart'
    if (dart.library.js_interop) 'youtube_web_frame_web.dart';
