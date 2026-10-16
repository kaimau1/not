import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/pip.dart';
import '../../../../core/utils/video_time.dart';
import '../../../../core/utils/youtube.dart';
import '../../domain/attachment.dart';
import '../editor/video_hub_scope.dart';
import 'video_viewer.dart' show NoteAtTimeButton;
import 'youtube_web_frame.dart';

/// Uygulama İÇİNDE oynatma: mobilde WebView, WEB'de iframe (2026-10-11,
/// "web sitemizin yeniliklere uyum sağlaması" — web'de YouTube eki yalnız
/// "tarayıcıda aç" diyordu). Windows'ta webview_flutter eklentisi yok —
/// orada bağlantı tarayıcıda açılır.
bool get youTubeInAppSupported => kIsWeb || _webViewSupported;

bool get _webViewSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Web'deki gömülü oynatıcı; bağlantı video değilse null. Web'de konum
/// okunamıyor: damgaya dokunmak oynatıcıyı o saniyeden YENİDEN kurar
/// ([start] değişince görünüm türü de değişir).
Widget? _webFrameFor(String url, {int? start}) {
  final id = youTubeVideoId(url);
  if (!kIsWeb || id == null) return null;
  return youTubeWebFrame(id, start: start ?? youTubeStartSeconds(url));
}

/// Gömülü YouTube oynatıcısının denetleyicisi; bağlantı video değilse ya da
/// platformda WebView yoksa null. [start] verilirse (saniye) bağlantıdaki
/// başlangıcın yerine geçer — zaman damgasına dokununca video oradan açılır.
WebViewController? createYouTubeController(String url, {int? start}) {
  final id = youTubeVideoId(url);
  if (id == null || !_webViewSupported) return null;
  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..setNavigationDelegate(
      NavigationDelegate(
        // Oynatıcının içindeki YouTube logosu/öneri bağlantıları WebView'u
        // youtube.com'a götürüyordu (oynatıcı kayboluyor, geri dönülemiyor).
        // Gömülü sayfa dışındaki her gezinme YouTube uygulamasında açılır.
        onNavigationRequest: (request) {
          final target = request.url;
          if (target.startsWith(youTubeEmbedOrigin) ||
              target.startsWith('about:') ||
              target.startsWith('https://www.youtube-nocookie.com/embed/') ||
              target.startsWith('https://www.youtube.com/embed/')) {
            return NavigationDecision.navigate;
          }
          if (request.isMainFrame) {
            launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ),
    );
  final platform = controller.platform;
  if (platform is AndroidWebViewController) {
    // Otomatik oynatma: Android WebView varsayılanı "dokunuş bekle".
    platform.setMediaPlaybackRequiresUserGesture(false);
  }
  controller.loadHtmlString(
    youTubeEmbedHtml(id, start: start ?? youTubeStartSeconds(url)),
    baseUrl: youTubeEmbedOrigin,
  );
  return controller;
}

/// Gömülü sayfanın JS köprüsü üzerinden konum okuyan/saran kaynak (bkz.
/// `youTubeEmbedHtml` → `notlarTime`/`notlarSeek`).
class _WebViewTimeSource implements VideoTimeSource {
  _WebViewTimeSource(this.attachmentId, this.controller);

  @override
  final String attachmentId;
  final WebViewController controller;

  @override
  Future<Duration?> position() async {
    try {
      final raw = await controller.runJavaScriptReturningResult(
        'window.notlarTime ? notlarTime() : -1',
      );
      final seconds = raw is num ? raw.toDouble() : double.tryParse('$raw');
      if (seconds == null || seconds < 0) return null;
      return Duration(milliseconds: (seconds * 1000).round());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      await controller.runJavaScript(
        'window.notlarSeek && notlarSeek(${position.inSeconds})',
      );
    } catch (_) {}
  }
}

/// Sayfaya/üst bölmeye GÖMÜLÜ oynatıcı ("üstte video, altta not"): video
/// notun içinde oynarken altına yazılabilir. Kurulduğu an oynamaya başlar —
/// çağıran onu ancak oynat düğmesine basılınca ağaca koyar.
class YouTubeInlinePlayer extends StatefulWidget {
  const YouTubeInlinePlayer({
    super.key,
    required this.url,
    this.start,
    this.attachmentId,
  });

  final String url;

  /// Başlangıç saniyesi (null = bağlantıdaki `t=`).
  final int? start;

  /// Verilirse oynatıcı notun video merkezine ([VideoHubScope]) kaydolur:
  /// zaman damgaları ona gider, "Bu ana not al" konumunu ondan okur.
  final String? attachmentId;

  @override
  State<YouTubeInlinePlayer> createState() => _YouTubeInlinePlayerState();
}

class _YouTubeInlinePlayerState extends State<YouTubeInlinePlayer> {
  late final WebViewController? _controller = createYouTubeController(
    widget.url,
    start: widget.start,
  );

  NoteVideoHub? _hub;
  _WebViewTimeSource? _source;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = _controller;
    final id = widget.attachmentId;
    if (_source != null || controller == null || id == null) return;
    final hub = VideoHubScope.maybeOf(context);
    if (hub == null) return;
    final source = _WebViewTimeSource(id, controller);
    _hub = hub;
    _source = source;
    hub
      ..register(source)
      // Oynatıcı ancak "oynat"a basılınca kurulur: kullanıcının izlediği
      // video budur.
      ..touch(source);
  }

  @override
  void dispose() {
    final source = _source;
    if (source != null) _hub?.unregister(source);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _webFrameFor(widget.url, start: widget.start);
    if (frame != null) return ColoredBox(color: Colors.black, child: frame);
    final controller = _controller;
    if (controller == null) return const ColoredBox(color: Colors.black);
    return ColoredBox(
      color: Colors.black,
      child: WebViewWidget(controller: controller),
    );
  }
}

/// YouTube videosunu (bkz. [Attachment.isWebVideo]) uygulama İÇİNDE oynatır.
///
/// **RESİM İÇİNDE RESİM** (kullanıcı isteği 2026-10-11): ekran açıkken ana
/// ekrana çıkmak videoyu küçük pencereye alır, üst çubuktaki düğme de hemen
/// geçirir. Küçük pencerede çubuklar gizlenir, yalnız video çizilir; pencere
/// büyütülünce ekran olduğu gibi geri gelir.
class YouTubeViewerScreen extends StatefulWidget {
  const YouTubeViewerScreen({
    super.key,
    required this.attachment,
    this.start,
    this.onNoteAt,
  });

  final Attachment attachment;

  /// Açılış konumu (zaman damgası); null = bağlantıdaki `t=`.
  final Duration? start;

  /// "Bu ana not al" (bkz. [VideoViewerScreen.onNoteAt]).
  final ValueChanged<Duration>? onNoteAt;

  @override
  State<YouTubeViewerScreen> createState() => _YouTubeViewerScreenState();
}

class _YouTubeViewerScreenState extends State<YouTubeViewerScreen> {
  WebViewController? _controller;
  bool _pipSupported = false;

  String get _url => widget.attachment.webUrl;

  @override
  void initState() {
    super.initState();
    final controller = createYouTubeController(
      _url,
      start: widget.start?.inSeconds,
    );
    if (controller == null) return;
    _controller = controller;
    PictureInPicture.setAuto(true);
    PictureInPicture.supported().then((value) {
      if (mounted) setState(() => _pipSupported = value);
    });
  }

  @override
  void dispose() {
    // Oynatıcı kapanınca otomatik geçiş KAPANMALI: yoksa not listesinde ana
    // ekrana çıkmak da uygulamayı küçük pencereye alırdı.
    PictureInPicture.setAuto(false);
    super.dispose();
  }

  Future<void> _copyLink() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _url));
    messenger.showSnackBar(SnackBar(content: Text(l10n.videoLinkCopied)));
  }

  Future<void> _openExternal() =>
      launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication);

  /// Oynatıcının konumunu okuyup notu o anın damgasıyla açar.
  Future<void> _noteAt() async {
    final controller = _controller;
    final callback = widget.onNoteAt;
    if (controller == null || callback == null) return;
    final position = await _WebViewTimeSource(
      widget.attachment.id,
      controller,
    ).position();
    if (!mounted) return;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.videoTimeUnknown)),
      );
      return;
    }
    Navigator.of(context).pop();
    callback(position);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = _controller;
    final webFrame = _webFrameFor(_url, start: widget.start?.inSeconds);
    if (webFrame != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            widget.attachment.fileName,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: l10n.copyVideoLink,
              icon: const Icon(Icons.link),
              onPressed: _copyLink,
            ),
            IconButton(
              tooltip: l10n.youTubeOpenExternal,
              icon: const Icon(Icons.open_in_new),
              onPressed: _openExternal,
            ),
          ],
        ),
        body: Center(
          child: AspectRatio(aspectRatio: 16 / 9, child: webFrame),
        ),
      );
    }
    if (controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.attachment.fileName)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.smart_display_outlined, size: 48),
                const SizedBox(height: 12),
                Text(
                  youTubeVideoId(_url) == null
                      ? l10n.youTubeInvalidLink
                      : l10n.youTubeOpenInBrowserInfo,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (youTubeVideoId(_url) != null)
                  FilledButton.icon(
                    onPressed: _openExternal,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.youTubeOpenExternal),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    final player = WebViewWidget(controller: controller);
    return ValueListenableBuilder<bool>(
      valueListenable: PictureInPicture.active,
      // Ağaç PiP'te ve normalde AYNI WebView'u taşır (yalnız çevresi değişir)
      // — WebView yeniden kurulsaydı video baştan başlardı.
      child: player,
      builder: (context, inPip, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: inPip
              ? null
              : AppBar(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text(
                    widget.attachment.fileName,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    if (widget.onNoteAt != null)
                      NoteAtTimeButton(onPressed: _noteAt),
                    if (_pipSupported)
                      IconButton(
                        tooltip: l10n.pictureInPicture,
                        icon: const Icon(Icons.picture_in_picture_alt),
                        onPressed: () => PictureInPicture.enter(),
                      ),
                    IconButton(
                      tooltip: l10n.copyVideoLink,
                      icon: const Icon(Icons.link),
                      onPressed: _copyLink,
                    ),
                    IconButton(
                      tooltip: l10n.youTubeOpenExternal,
                      icon: const Icon(Icons.open_in_new),
                      onPressed: _openExternal,
                    ),
                  ],
                ),
          // Gövdenin YAPISI PiP'te de aynı (yalnız güvenli alan kalkar):
          // pencere zaten 16:9, oran kutusu onu tümüyle doldurur.
          body: SafeArea(
            top: !inPip,
            bottom: !inPip,
            left: !inPip,
            right: !inPip,
            child: Center(
              child: AspectRatio(aspectRatio: 16 / 9, child: player),
            ),
          ),
        );
      },
    );
  }
}
