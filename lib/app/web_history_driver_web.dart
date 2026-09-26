import 'dart:ui_web' as ui_web;

import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import 'web_history.dart';

HistoryDriver createDriver() => _BrowserDriver();

class _BrowserDriver implements HistoryDriver {
  bool _selected = false;

  @override
  String? currentPath() => ui_web.urlStrategy?.getPath();

  @override
  void update(Uri uri, Object? state, {required bool replace}) {
    if (!_selected) {
      _selected = true;
      SystemNavigator.selectMultiEntryHistory();
    }
    SystemNavigator.routeInformationUpdated(
      uri: uri,
      state: state,
      replace: replace,
    );
  }

  @override
  void back() => web.window.history.back();
}
