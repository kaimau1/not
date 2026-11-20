import 'dart:async';
import 'dart:js_interop';

import 'package:file_selector/file_selector.dart';
import 'package:web/web.dart' as web;

import '../../app/theme/app_tokens.dart';

/// Belgeye bırakılan ya da yapıştırılan dosyaları [onDrop]'a verir; dönen işlev
/// dinlemeyi bırakır. `dragover` engellenmezse tarayıcı dosyayı sekmede açar.
void Function() listenFileDrops(
  void Function(List<XFile> files) onDrop, {
  void Function(bool hovering)? onHover,
}) {
  // "Bırak" çerçevesi: `dragover` sürükleme pencerenin üstündeyken sürekli
  // gelir; kesilince (pencereden çıktı, Esc) kısa süre sonra çerçeve iner.
  // `dragenter`/`dragleave` her alt öğede gelip gittiği için sayılmaz.
  Timer? idle;
  void hover(bool v) {
    idle?.cancel();
    idle = null;
    onHover?.call(v);
  }

  bool hasFiles(web.DragEvent e) {
    final types = e.dataTransfer?.types.toDart;
    return types != null && types.any((t) => t.toDart == 'Files');
  }

  final over = ((web.DragEvent e) {
    e.preventDefault();
    if (!hasFiles(e)) return;
    if (idle == null) onHover?.call(true);
    idle?.cancel();
    // Bekleme (hareket değil): dragover ~50 ms'de bir gelir.
    idle = Timer(AppMotion.medium, () => hover(false));
  }).toJS;

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
    hover(false);
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
    hover(false);
    web.document
      ..removeEventListener('dragover', over)
      ..removeEventListener('drop', drop)
      ..removeEventListener('paste', paste);
  };
}
