/// Sayfaya sürüklenip bırakılan ya da yapıştırılan dosyalar (F40.8, F41.4).
/// Web'de belge olayları; Android'de (tablet/fare, başka uygulamadan
/// sürükleme) yerel `OnDragListener` köprüsü (`dev.kaimau.notlar/drop`).
library;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'web_file_drop_stub.dart'
    if (dart.library.js_interop) 'web_file_drop_web.dart';

typedef FileDropHandler = void Function(List<XFile> files);

final _handlers = <FileDropHandler>[];

/// Dosya pencerenin ÜSTÜNDE sürükleniyor (henüz bırakılmadı): "bırak"
/// çerçevesi bunu dinler (kullanıcı isteği 2026-11-20: "diğer uygulamalarda
/// çıkan, ekin algılandığını gösteren çerçeve çıkmalı").
final ValueNotifier<bool> fileDragHover = ValueNotifier<bool>(false);

void _setHover(bool v) {
  // Dinleyen işleyici yoksa (oturum açma ekranı) çerçeve çıkmaz.
  fileDragHover.value = v && _handlers.isNotEmpty;
}
void Function()? _stopListening;

/// Dosya gelince YALNIZ en son eklenen işleyici çalışır: not açıkken dosya o
/// nota, değilse ana ekranın yeni not akışına gider. Dönen işlev işleyiciyi
/// çıkarır; son işleyici gidince belge dinlenmez olur.
void Function() addFileDropHandler(FileDropHandler handler) {
  _handlers.add(handler);
  _stopListening ??= listenFileDrops(dispatchFileDrop, onHover: _setHover);
  return () {
    _handlers.remove(handler);
    if (_handlers.isEmpty) {
      _stopListening?.call();
      _stopListening = null;
      fileDragHover.value = false;
    }
  };
}

@visibleForTesting
void dispatchFileDrop(List<XFile> files) {
  fileDragHover.value = false;
  _handlers.lastOrNull?.call(files);
}
