/// Web açılış katmanını (`web/index.html` → `#splash`) kaldırma sinyali.
///
/// F10.6 (2026-10-31): HTML açılışı Flutter'ın İLK karesinde kalkıyordu; o
/// kare ise sessiz misafir girişi sürerken çizilen ara ekrandı — iki açılış
/// üst üste biniyordu. Artık HTML katmanı uygulama İLK ANLAMLI ekranını
/// (giriş düğmeleri ya da notlar) çizince kalkar. Mobilde işlevsizdir.
library;

export 'web_ready_stub.dart' if (dart.library.js_interop) 'web_ready_web.dart';
