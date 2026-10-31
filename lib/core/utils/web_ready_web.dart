import 'package:flutter/scheduler.dart';
import 'package:web/web.dart' as web;

bool _sent = false;

/// Bir sonraki kare çizilince `notlar-ready` olayını yollar (bir kez).
void signalWebReady() {
  if (_sent) return;
  _sent = true;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    web.window.dispatchEvent(web.Event('notlar-ready'));
  });
}
