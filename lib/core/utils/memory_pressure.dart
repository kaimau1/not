/// Merkezi bellek baskısı ve arka plana geçiş önbellek temizliği.
///
/// [critical] `true`: sistem bellek baskısı (`didHaveMemoryPressure` /
/// `onTrimMemory`) — büyük arama, küçük resim ve yazım önbellekleri atılır.
/// [critical] `false`: uygulama arka plana geçiyor (`hidden`/`paused`) —
/// hafif temizlik ve zamanlayıcı duraklatma yapılır (ekrandaki görseller F26
/// gereği korunur).
abstract final class MemoryPressure {
  static final List<void Function(bool critical)> _listeners = [];

  static void register(void Function(bool critical) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  static void unregister(void Function(bool critical) listener) {
    _listeners.remove(listener);
  }

  static void dispatch({required bool critical}) {
    for (final fn in List<void Function(bool critical)>.of(_listeners)) {
      try {
        fn(critical);
      } catch (_) {}
    }
  }
}
