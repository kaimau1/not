import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Byte dizisini tarayıcı belleğinde bir `Blob`'a sarıp geçici bir
/// `blob:` URL'i döner. `pdfrx`'in `PdfViewer.uri` ve görsel widget'larının
/// zaten bildiği `http(s)`/`blob` şemasını kullandığı için ayrı bir web
/// önizleme yolu yazmaya gerek kalmıyor — üretilen PDF/görsel, Storage'dan
/// gelen bir dosyaymış gibi aynı `downloadUrl` alanına konur.
///
/// URL kasıtlı olarak `revokeObjectURL` ile serbest bırakılmıyor: önizleme
/// ekranı kapanana kadar (hatta paylaşım sekmesi açık kalırken) canlı
/// kalmalı; sekme kapanınca tarayıcı zaten belleği geri alır.
String createBlobUrl(List<int> bytes, String mimeType) {
  final blob = web.Blob(
    [Uint8List.fromList(bytes).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  return web.URL.createObjectURL(blob);
}
