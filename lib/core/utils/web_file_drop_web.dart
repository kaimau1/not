import 'dart:js_interop';

import 'package:file_selector/file_selector.dart';
import 'package:web/web.dart' as web;

/// Belgeye bırakılan ya da yapıştırılan dosyaları [onDrop]'a verir; dönen işlev
/// dinlemeyi bırakır. `dragover` engellenmezse tarayıcı dosyayı sekmede açar.
void Function() listenFileDrops(void Function(List<XFile> files) onDrop) {
  final over = ((web.DragEvent e) => e.preventDefault()).toJS;
  void deliver(web.FileList list) {
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
  }

  final drop = ((web.DragEvent e) {
    e.preventDefault();
    final list = e.dataTransfer?.files;
    if (list == null || list.length == 0) return;
    deliver(list);
  }).toJS;
  // Word/Excel kopyası metnin yanında resim de taşır: metin varsa yapıştırma
  // metin alanının işidir, dosya sayılmaz.
  final paste = ((web.ClipboardEvent e) {
    final data = e.clipboardData;
    final list = data?.files;
    if (data == null || list == null || list.length == 0) return;
    if (data.getData('text/plain').isNotEmpty) return;
    e.preventDefault();
    deliver(list);
  }).toJS;
  web.document
    ..addEventListener('dragover', over)
    ..addEventListener('drop', drop)
    ..addEventListener('paste', paste);
  return () {
    web.document
      ..removeEventListener('dragover', over)
      ..removeEventListener('drop', drop)
      ..removeEventListener('paste', paste);
  };
}
