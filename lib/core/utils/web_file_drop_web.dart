import 'dart:js_interop';

import 'package:file_selector/file_selector.dart';
import 'package:web/web.dart' as web;

/// Belgeye bırakılan dosyaları [onDrop]'a verir; dönen işlev dinlemeyi bırakır.
/// `dragover` engellenmezse tarayıcı dosyayı sekmede açar.
void Function() listenFileDrops(void Function(List<XFile> files) onDrop) {
  final over = ((web.DragEvent e) => e.preventDefault()).toJS;
  final drop = ((web.DragEvent e) {
    e.preventDefault();
    final list = e.dataTransfer?.files;
    if (list == null || list.length == 0) return;
    final files = [for (var i = 0; i < list.length; i++) list.item(i)!];
    Future.wait([
      for (final f in files)
        f.arrayBuffer().toDart.then(
          (b) => XFile.fromData(
            b.toDart.asUint8List(),
            name: f.name,
            mimeType: f.type,
            length: f.size,
          ),
        ),
    ]).then(onDrop);
  }).toJS;
  web.document
    ..addEventListener('dragover', over)
    ..addEventListener('drop', drop);
  return () {
    web.document
      ..removeEventListener('dragover', over)
      ..removeEventListener('drop', drop);
  };
}
