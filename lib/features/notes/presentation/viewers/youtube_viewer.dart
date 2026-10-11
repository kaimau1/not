import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/pip.dart';
import '../../../../core/utils/youtube.dart';
import '../../domain/attachment.dart';
import 'youtube_web_frame.dart';

/// Uygulama İÇİNDE oynatma: mobilde WebView, WEB'de iframe (2026-10-11,
/// "web sitemizin yeniliklere uyum sağlaması" — web'de YouTube eki yalnız
/// "tarayıcıda aç" diyordu). Windows'ta webview_flutter eklentisi yok —
/// orada bağlantı tarayıcıda açılır.
bool get youTubeInAppSupported => kIsWeb || _webViewSupported;

bool get _webViewSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// Web'deki gömülü oynatıcı; bağlantı video değilse null.
Widget? _webFrameFor(String url) {
  final id = youTubeVideoId(url);
  if (!kIsWeb || id == null) return null;
  return youTubeWebFrame(id, start: youTubeStartSeconds(url));
}

/// Gömülü YouTube oynatıcısının denetleyicisi; bağlantı video değilse ya da
/// platformda WebView yoksa null.
WebViewController? createYouTubeController(String url) {
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
    youTubeEmbedHtml(id, start: youTubeStartSeconds(url)),
    baseUrl: youTubeEmbedOrigin,
  );
  return controller;
}

/// Sayfaya/üst bölmeye GÖMÜLÜ oynatıcı ("üstte video, altta not"): video
/// notun içinde oynarken altına yazılabilir. Kurulduğu an oynamaya başlar —
/// çağıran onu ancak oynat düğmesine basılınca ağaca koyar.
class YouTubeInlinePlayer extends StatefulWidget {
  const YouTubeInlinePlayer({super.key, required this.url});

  final String url;

  @override
  State<YouTubeInlinePlayer> createState() => _YouTubeInlinePlayerState();
}

class _YouTubeInlinePlayerState extends State<YouTubeInlinePlayer> {
  late final WebViewController? _controller = createYouTubeController(
    widget.url,
  );

  @override
  Widget build(BuildContext context) {
    final frame = _webFrameFor(widget.url);
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
  const YouTubeViewerScreen({super.key, required this.attachment});

  final Attachment attachment;

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
    final controller = createYouTubeController(_url);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = _controller;
    final webFrame = _webFrameFor(_url);
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
