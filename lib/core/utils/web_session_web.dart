import 'package:web/web.dart' as web;

/// `sessionStorage`'dan okur; tarayıcı engellediyse (gizli kip) null.
String? sessionRead(String key) {
  try {
    return web.window.sessionStorage.getItem(key);
  } catch (_) {
    // Depolama kapalı: kayıt yokmuş gibi davran.
    return null;
  }
}

/// `sessionStorage`'a yazar; null siler. Engelliyse sessizce geçer.
void sessionWrite(String key, String? value) {
  try {
    if (value == null) {
      web.window.sessionStorage.removeItem(key);
    } else {
      web.window.sessionStorage.setItem(key, value);
    }
  } catch (_) {
    // Depolama kapalı: jeton yalnız bellekte kalır.
  }
}

/// `localStorage`'dan okur (sekmeler ve yeniden açılış arası kalıcı);
/// tarayıcı engellediyse null.
String? localRead(String key) {
  try {
    return web.window.localStorage.getItem(key);
  } catch (_) {
    return null;
  }
}

/// `localStorage`'a yazar; null siler. Engelliyse sessizce geçer.
void localWrite(String key, String? value) {
  try {
    if (value == null) {
      web.window.localStorage.removeItem(key);
    } else {
      web.window.localStorage.setItem(key, value);
    }
  } catch (_) {
    // Depolama kapalı: yalnız bellekte kalır.
  }
}
