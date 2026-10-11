import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Kayıtlı görünüm türleri: aynı video için fabrika bir kez kaydedilir.
final _registered = <String>{};

/// [id] videosunu iframe'de oynatır (otomatik başlar).
///
/// Web'de Referer sorunu yok (sayfanın kendi `https` kökeni var — mobildeki
/// Hata 153 tuzağı burada geçerli değil, bkz. `youTubeEmbedHtml`); tam ekran
/// düğmesi de tarayıcıda çalıştığı için açık bırakılır.
Widget youTubeWebFrame(String id, {int start = 0}) {
  final viewType = 'notlar-youtube-$id-$start';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final query = {
        'autoplay': '1',
        'playsinline': '1',
        'rel': '0',
        'modestbranding': '1',
        if (start > 0) 'start': '$start',
      }.entries.map((e) => '${e.key}=${e.value}').join('&');
      final frame = web.HTMLIFrameElement()
        ..src = 'https://www.youtube-nocookie.com/embed/$id?$query'
        ..allow = 'autoplay; encrypted-media; picture-in-picture; fullscreen'
        ..allowFullscreen = true
        ..referrerPolicy = 'strict-origin-when-cross-origin';
      frame.style
        ..border = '0'
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = '#000';
      return frame;
    });
  }
  return HtmlElementView(viewType: viewType);
}
