/// Sayfaya sürüklenip bırakılan ya da yapıştırılan dosyalar (F40.8, F41.4).
/// Yalnız web'de; mobilde işlevsiz.
library;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'web_file_drop_stub.dart'
    if (dart.library.js_interop) 'web_file_drop_web.dart';

typedef FileDropHandler = void Function(List<XFile> files);

final _handlers = <FileDropHandler>[];
void Function()? _stopListening;

/// Dosya gelince YALNIZ en son eklenen işleyici çalışır: not açıkken dosya o
/// nota, değilse ana ekranın yeni not akışına gider. Dönen işlev işleyiciyi
/// çıkarır; son işleyici gidince belge dinlenmez olur.
void Function() addFileDropHandler(FileDropHandler handler) {
  _handlers.add(handler);
  _stopListening ??= listenFileDrops(dispatchFileDrop);
  return () {
    _handlers.remove(handler);
    if (_handlers.isEmpty) {
      _stopListening?.call();
      _stopListening = null;
    }
  };
}

@visibleForTesting
void dispatchFileDrop(List<XFile> files) => _handlers.lastOrNull?.call(files);
