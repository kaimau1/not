import 'web_history.dart';

/// Web DIŞINDA tarayıcı geçmişi yok; sürücü hiçbir şey yapmaz.
HistoryDriver createDriver() => _NoopDriver();

class _NoopDriver implements HistoryDriver {
  @override
  String? currentPath() => null;

  @override
  void update(Uri uri, Object? state, {required bool replace}) {}

  @override
  void back() {}
}
