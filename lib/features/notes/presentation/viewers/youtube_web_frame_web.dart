import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Kayıtlı görünüm türleri: aynı video için fabrika bir kez kaydedilir.
final _registered = <String>{};

/// Kurulmuş iframe'ler (platform görünümü kimliğiyle) — durdurma komutu
/// bunlara gider.
final _frames = <int, web.HTMLIFrameElement>{};

bool _visibilityHooked = false;

/// [id] videosunu iframe'de oynatır (otomatik başlar).
///
/// Web'de Referer sorunu yok (sayfanın kendi `https` kökeni var — mobildeki
/// Hata 153 tuzağı burada geçerli değil, bkz. `youTubeEmbedHtml`); tam ekran
/// düğmesi de tarayıcıda çalıştığı için açık bırakılır.
///
/// **KENDİLİĞİNDEN DURUR** (kullanıcı isteği 2026-10-28: "webte videolu notta
/// başka sekmeye geçince veya uygulama içi başka sayfaya geçince video devam
/// ediyor"): sekme gizlenince (`visibilitychange`) bütün oynatıcılar, üstüne
/// başka sayfa açılınca (rota örtülür → `TickerMode` kapanır) o oynatıcı
/// durdurulur. Durdurma YouTube iframe API'sinin `postMessage` komutuyla
/// (`enablejsapi=1`); iframe yeniden kurulmaz, kullanıcı kaldığı yerden
/// sürdürür.
Widget youTubeWebFrame(String id, {int start = 0}) {
  _hookVisibility();
  final viewType = 'notlar-youtube-$id-$start';
  if (_registered.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final query =
          {
                'autoplay': '1',
                'playsinline': '1',
                'rel': '0',
                'modestbranding': '1',
                'enablejsapi': '1',
                'origin': web.window.location.origin,
                if (start > 0) 'start': '$start',
              }.entries
              .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
              .join('&');
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
      _frames[viewId] = frame;
      return frame;
    });
  }
  return _PausingFrame(viewType: viewType);
}

/// Sayfadaki BÜTÜN gömülü videoları durdurur (YouTube iframe'leri ve yerli
/// `<video>` öğeleri).
void pauseAllWebVideos() {
  for (final frame in _frames.values) {
    _pauseFrame(frame);
  }
  final videos = web.document.querySelectorAll('video');
  for (var i = 0; i < videos.length; i++) {
    final node = videos.item(i);
    if (node != null && node.isA<web.HTMLVideoElement>()) {
      (node as web.HTMLVideoElement).pause();
    }
  }
}

void _pauseFrame(web.HTMLIFrameElement frame) {
  frame.contentWindow?.postMessage(
    '{"event":"command","func":"pauseVideo","args":""}'.toJS,
    '*'.toJS,
  );
}

void _hookVisibility() {
  if (_visibilityHooked) return;
  _visibilityHooked = true;
  web.document.addEventListener(
    'visibilitychange',
    ((web.Event _) {
      if (web.document.visibilityState == 'hidden') pauseAllWebVideos();
    }).toJS,
  );
}

/// Rotası örtülünce (başka sayfa açıldı) ya da ağaçtan çıkınca kendi
/// oynatıcısını durduran sarmalayıcı.
class _PausingFrame extends StatefulWidget {
  const _PausingFrame({required this.viewType});

  final String viewType;

  @override
  State<_PausingFrame> createState() => _PausingFrameState();
}

class _PausingFrameState extends State<_PausingFrame> {
  int? _viewId;

  void _pause() {
    final frame = _frames[_viewId];
    if (frame != null) _pauseFrame(frame);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) _pause();
  }

  @override
  void dispose() {
    _pause();
    _frames.remove(_viewId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(
    viewType: widget.viewType,
    onPlatformViewCreated: (id) => _viewId = id,
  );
}
