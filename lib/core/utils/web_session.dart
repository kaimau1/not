/// Tarayıcı SEKMESİNE bağlı küçük kayıt (`sessionStorage`): sekme kapanınca
/// silinir, yenilemede kalır. Web dışında hiçbir şey saklamaz.
library;

export 'web_session_stub.dart'
    if (dart.library.js_interop) 'web_session_web.dart';
