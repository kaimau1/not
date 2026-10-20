part of 'note_images.dart';

/// YouTube ekinin kutusu: kapak görseli + oynat düğmesi + küçük YouTube
/// rozeti. Kapak ağsız da çizilemezse koyu zemin üstünde simge kalır.
class _WebVideoBox extends StatefulWidget {
  const _WebVideoBox({
    required this.video,
    required this.fit,
    required this.inline,
    this.playing,
    this.onPlay,
    this.showTitle = false,
  });

  final Attachment video;
  final BoxFit fit;
  final bool inline;
  final bool? playing;
  final VoidCallback? onPlay;
  final bool showTitle;

  @override
  State<_WebVideoBox> createState() => _WebVideoBoxState();
}

class _WebVideoBoxState extends State<_WebVideoBox> {
  bool _playing = false;

  /// Zaman damgasından gelen başlangıç saniyesi ve isteğin sırası (aynı
  /// saniyeye ikinci dokunuş da oynatıcıyı yeniden kurar).
  int? _startAt;
  int _startSerial = 0;
  NoteVideoHub? _hub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final hub = VideoHubScope.maybeOf(context);
    if (identical(hub, _hub)) return;
    _hub?.startRequest.removeListener(_onStartRequest);
    _hub = hub?..startRequest.addListener(_onStartRequest);
  }

  @override
  void dispose() {
    _hub?.startRequest.removeListener(_onStartRequest);
    super.dispose();
  }

  /// Notta bu videonun damgasına dokunuldu ama oynatıcısı kayıtlı değil
  /// (henüz oynatılmadı ya da web): oynatıcı o saniyeden kurulur.
  void _onStartRequest() {
    final request = _hub?.startRequest.value;
    if (request == null || request.id != widget.video.id || !mounted) return;
    setState(() {
      _startAt = request.seconds;
      _startSerial = request.serial;
    });
    if (!(widget.playing ?? _playing)) _play();
  }

  void _play() {
    if (widget.inline && youTubeInAppSupported) {
      if (widget.onPlay != null) {
        widget.onPlay!();
      } else {
        setState(() => _playing = true);
      }
      return;
    }
    Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => VideoViewerScreen(attachment: widget.video),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _WebVideoBox old) {
    super.didUpdateWidget(old);
    if (old.video.webUrl != widget.video.webUrl) {
      _playing = false;
      _startAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playing ?? _playing) {
      return YouTubeInlinePlayer(
        key: ValueKey('yt-${widget.video.id}-$_startSerial'),
        url: widget.video.webUrl,
        start: _startAt,
        attachmentId: widget.video.id,
      );
    }
    final id = youTubeVideoId(widget.video.webUrl);
    final placeholder = Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: const Icon(Icons.smart_display_outlined, color: Colors.white70),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (id == null)
          placeholder
        else if (widget.fit == BoxFit.contain)
          // KAPAK 16:9 KIRPILIR (kullanıcı bulgusu 2026-10-20: "video sağda
          // solda boşluk bırakıyor"): `hqdefault` 4:3 ve üstte/altta kara
          // şerit taşıyor; `contain` ile 16:9 kutuda şeritler kalıyor,
          // görüntü daralıp yanlarda boşluk açılıyordu. 16:9 pencerede
          // `cover` şeritleri tam keser.
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: youTubeThumbnailUrl(id),
                  fit: BoxFit.cover,
                  placeholder: (_, _) => placeholder,
                  errorWidget: (_, _, _) => placeholder,
                ),
              ),
            ),
          )
        else
          CachedNetworkImage(
            imageUrl: youTubeThumbnailUrl(id),
            fit: widget.fit,
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          ),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _play,
            child: Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        // Başlık YouTube'daki gibi üstte, koyu geçişli şeritte. Dokunuşu
        // yutmaz (kutu taşınabilir/seçilebilir kalsın). Ad henüz gelmediyse
        // ("YouTube" yer tutucusu) şerit çizilmez.
        if (widget.showTitle && widget.video.fileName != 'YouTube')
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                key: const ValueKey('web-video-title'),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
                child: Text(
                  widget.video.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Video ekin sayfa üzerindeki kutusu: video **olduğu yerde** oynar — ortada
/// oynat/durdur düğmesi, ayrı ekrana gitmek gerekmez (tam ekran, araç
/// çubuğundaki düğmede). Dosya yoksa (video buluta çıkmaz — başka cihazda
/// yalnız yer tutucu olur) ya da oynatıcı desteklenmiyorsa (masaüstü) kamera
/// simgeli yer tutucu çizilir; kutu taşınıp boyutlandırılabilir kalır.
class _VideoBox extends StatefulWidget {
  const _VideoBox({
    required this.video,
    this.fit = BoxFit.cover,
    this.onSize,
    this.noteAtButton = false,
    this.controls = true,
  });

  final Attachment video;

  /// Oynatılınca dipte denetim şeridi (±10 sn, oynat/durdur). Sabit
  /// bölmede kapalı — orada denetim bölmenin çubuğunda.
  final bool controls;

  /// Köşede "Bu ana not al" düğmesi (bkz. [NoteMediaBox.noteAtButton]).
  final bool noteAtButton;

  /// Tuvalde `cover`, büyük önizlemede `contain` (bkz. [_ImageBox.fit]).
  final BoxFit fit;

  /// Video çözülünce doğal boyutunu bildirir — ekin `width`/`height` alanları
  /// boşsa kalıcılaştırılır ki kutunun oranı (1:1 varsayılan yerine) sonraki
  /// açılışta da doğru olsun. null = zaten biliniyor, bildirme.
  final ValueChanged<Size>? onSize;

  @override
  State<_VideoBox> createState() => _VideoBoxState();
}

class _VideoBoxState extends State<_VideoBox> {
  VideoPlayerController? _controller;
  bool _failed = false;
  bool _playing = false;
  bool _sizeReported = false;

  /// **TEMBEL KURULUM** (pil/RAM — 2026-10-17). Eskiden oynatıcı
  /// `initState`te kuruluyordu: notu açmak, videoyu hiç oynatmasan da her
  /// video için bir yerel çözücü (Android'de ExoPlayer + donanım kod çözücü
  /// tamponları, onlarca MB) ayağa kaldırıyordu. O zaman tembel kurulum
  /// reddedilmişti çünkü kutunun İLK KARESİ oynatıcıdan geliyordu; artık
  /// kapak karesi ayrıca üretiliyor ve diskte önbellekte ([VideoPoster]).
  /// Kutu ▶'ye basılana (ya da notta bir zaman damgasına dokunulana) dek
  /// kapağı gösterir. Kapak çıkarılamayan yerde (masaüstü) ve videonun
  /// boyu henüz bilinmiyorken ([_VideoBox.onSize] — yerleşim için gerekli)
  /// eski hemen-kurulum sürer.
  Future<void>? _initFuture;
  bool _initializing = false;

  bool get _lazy => VideoFrame.supported && widget.onSize == null;

  /// Notun video merkezi ve bu oynatıcının oradaki kaydı (zaman damgaları).
  /// Tembel kutuda oynatıcı kurulana dek yerinde [_DeferredTimeSource] durur.
  NoteVideoHub? _hub;
  VideoTimeSource? _source;

  @override
  void initState() {
    super.initState();
    if (!_lazy) _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lazy && _controller == null && _source == null) _registerDeferred();
  }

  /// Oynatıcı kurulmadan zaman damgası dokunuşu da çalışsın: kayıt, ilk
  /// istekte oynatıcıyı kurup asıl kaynağa devreder.
  void _registerDeferred() {
    final hub = VideoHubScope.maybeOf(context);
    if (hub == null) return;
    final source = _DeferredTimeSource(widget.video.id, () async {
      await _init();
      return _controller;
    });
    _hub = hub..register(source);
    _source = source;
  }

  void _register(VideoPlayerController controller) {
    _unregister();
    final hub = VideoHubScope.maybeOf(context);
    if (hub == null) return;
    final source = _PlayerTimeSource(widget.video.id, controller);
    _hub = hub..register(source);
    _source = source;
  }

  void _unregister() {
    final source = _source;
    if (source != null) _hub?.unregister(source);
    _source = null;
  }

  /// Oynatıcıyı BİR KEZ kurar; eşzamanlı çağrılar aynı işi bekler.
  Future<void> _init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    // Dosya yoksa denemeye gerek yok: yer tutucu kalır.
    if (!localFileExists(widget.video.localPath)) return;
    final controller = VideoPlayerController.file(File(widget.video.localPath));
    _controller = controller;
    if (mounted && _lazy) setState(() => _initializing = true);
    try {
      await controller.initialize();
      if (!mounted) return;
      _initializing = false;
      controller.addListener(_onTick);
      _register(controller);
      setState(() {});
      final size = controller.value.size;
      if (!_sizeReported && size.width > 0 && size.height > 0) {
        _sizeReported = true;
        widget.onSize?.call(size);
      }
    } catch (_) {
      // Oynatıcı bu platformda yok ya da dosya bozuk.
      if (mounted) {
        setState(() {
          _failed = true;
          _initializing = false;
        });
      }
    }
  }

  /// Yalnız oynuyor/durdu geçişinde yeniden çizim — her karede setState
  /// çağırmak kutuyu boşuna ısıtırdı (VideoPlayer kendi karesini kendisi
  /// tazeliyor).
  void _onTick() {
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _playing && mounted) {
      setState(() {
        _playing = playing;
        if (playing) _started = true;
      });
    }
  }

  /// Video bir kez oynatıldı mı — alttaki denetim şeridi ancak o zaman
  /// görünür (oynatılmamış video yalnız kapağını ve ▶'yi gösterir).
  bool _started = false;

  @override
  void didUpdateWidget(covariant _VideoBox old) {
    super.didUpdateWidget(old);
    if (old.video.localPath != widget.video.localPath) {
      _unregister();
      _controller?.removeListener(_onTick);
      _controller?.dispose();
      _controller = null;
      _failed = false;
      _initFuture = null;
      _initializing = false;
      if (_lazy) {
        _registerDeferred();
      } else {
        _init();
      }
    }
  }

  @override
  void dispose() {
    _unregister();
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    // İlk dokunuşta oynatıcı burada kurulur (bkz. [_initFuture]).
    await _init();
    if (!mounted) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
      return;
    }
    // Bittiyse oynat = baştan.
    final v = controller.value;
    if (v.duration > Duration.zero && v.position >= v.duration) {
      await controller.seekTo(Duration.zero);
    }
    final source = _source;
    if (source != null) _hub?.touch(source);
    await controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;
    // Tembel kutu: oynatıcı kurulana dek kapak + ▶ (kurulurken çark).
    if (_lazy &&
        !_failed &&
        (controller == null || !controller.value.isInitialized)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          VideoPoster(video: widget.video, fit: widget.fit),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: _initializing
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ],
      );
    }
    if (controller == null || _failed || !controller.value.isInitialized) {
      return Container(
        color: scheme.surfaceContainerHigh,
        alignment: Alignment.center,
        child: Icon(Icons.videocam_outlined, color: scheme.onSurfaceVariant),
      );
    }
    final size = controller.value.size;
    return LayoutBuilder(
      builder: (context, constraints) => _player(
        controller,
        size,
        constraints.maxWidth,
        constraints.maxHeight,
      ),
    );
  }

  Widget _player(
    VideoPlayerController controller,
    Size size,
    double boxWidth,
    double boxHeight,
  ) {
    // DENETİM ŞERİDİ (kullanıcı isteği 2026-10-16: "videonun hemen altında
    // oynat/durdur, 10 sn sarma"): video bir kez oynatılınca kutunun dibinde
    // koyu geçişli şerit. Küçük kutuda çizilmez — videoyu örterdi. Notun
    // video merkezi yoksa (kart önizlemesi) denetim de yok.
    final strip =
        widget.controls &&
        _started &&
        _source != null &&
        boxWidth >= 170 &&
        boxHeight >= 110;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: FittedBox(
            fit: widget.fit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
        // Oynat/durdur dokunuşu KENDİ alır: dıştaki jest (seçim) çalışmaya
        // devam eder — videonun kenarına dokunmak seçer, ortasına dokunmak
        // oynatır. Oynarken düğme yarı saydamlaşır, video okunur kalır.
        // Şerit varken ortadaki düğme yalnız DURURKEN görünür (oynarken
        // durdurmak şeritten).
        if (!(strip && _playing))
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: AnimatedOpacity(
                opacity: _playing ? 0.35 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        if (strip)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              key: const ValueKey('video-box-controls'),
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xAA000000)],
                ),
              ),
              alignment: Alignment.center,
              child: VideoTransportControls(
                video: widget.video,
                onDark: true,
                iconSize: 20,
                showTime: boxWidth >= 270,
                showSpeed: boxWidth >= 320,
              ),
            ),
          ),
        // "BU ANA NOT AL" (kullanıcı isteği 2026-10-16): video akarken
        // kenardaki düğme o anın damgasını nota yazar ve yazma alanına
        // odaklanır. Küçük kutuda düğme videoyu örtmesin diye çizilmez.
        if (widget.noteAtButton &&
            _source != null &&
            _hub?.onNoteAt != null &&
            boxWidth >= 140)
          Positioned(
            right: 4,
            top: 4,
            child: _NoteAtChip(
              onTap: () {
                final source = _source;
                if (source != null) _hub?.noteAt(source);
              },
            ),
          ),
      ],
    );
  }
}

/// Video kutusunun köşesindeki küçük "⏱ Not" düğmesi.
class _NoteAtChip extends StatelessWidget {
  const _NoteAtChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Customizable(
    // Kişiselleştirmede gizlenebilir (bkz. UiItem.videoNoteAt).
    id: UiItem.videoNoteAt,
    child: _chip(context),
  );

  Widget _chip(BuildContext context) => Tooltip(
    message: context.l10n.videoNoteAtTime,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.more_time, size: 15, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              context.l10n.videoNoteAtTimeShort,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Henüz KURULMAMIŞ oynatıcının not tarafındaki yer tutucusu (bkz.
/// `_VideoBoxState._lazy`): zaman damgasına dokununca ya da çubuktan
/// oynatılınca oynatıcı kurulur, istek ona iletilir; kurulunca kutu asıl
/// kaynağı ([_PlayerTimeSource]) kaydeder ve bu kayıt düşer.
class _DeferredTimeSource extends VideoTimeSource {
  _DeferredTimeSource(this.attachmentId, this._start);

  @override
  final String attachmentId;
  final Future<VideoPlayerController?> Function() _start;

  /// Hiç oynatılmamış video için konum bilinmiyor sayılır: "bu ana not al"
  /// yanlış bir 0:00 yazmasın (okunamadı uyarısı çıkar).
  @override
  Future<Duration?> position() async => null;

  @override
  Future<void> seekTo(Duration position) async {
    final controller = await _start();
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    var target = position;
    if (duration > Duration.zero && target > duration) target = duration;
    await controller.seekTo(target);
    await controller.play();
  }

  @override
  Future<void> play() async {
    final controller = await _start();
    if (controller == null || !controller.value.isInitialized) return;
    await controller.play();
  }

  @override
  Future<void> seekBy(Duration delta) async {
    final controller = await _start();
    if (controller == null || !controller.value.isInitialized) return;
    final v = controller.value;
    await controller.seekTo(shiftedPosition(v.position, delta, v.duration));
  }
}

/// Yerel oynatıcının (video_player) not tarafına açılan yüzü.
class _PlayerTimeSource extends VideoTimeSource {
  _PlayerTimeSource(this.attachmentId, this.controller);

  @override
  final String attachmentId;
  final VideoPlayerController controller;

  @override
  Future<Duration?> position() async =>
      controller.value.isInitialized ? controller.value.position : null;

  @override
  Future<void> seekTo(Duration position) async {
    if (!controller.value.isInitialized) return;
    final duration = controller.value.duration;
    var target = position;
    if (duration > Duration.zero && target > duration) target = duration;
    await controller.seekTo(target);
    await controller.play();
  }

  @override
  Listenable get changes => controller;

  @override
  bool get isPlaying => controller.value.isPlaying;

  @override
  Duration? get lastPosition =>
      controller.value.isInitialized ? controller.value.position : null;

  @override
  Duration? get duration =>
      controller.value.isInitialized ? controller.value.duration : null;

  @override
  Future<void> play() async {
    final v = controller.value;
    if (!v.isInitialized) return;
    // Bittiyse oynat = baştan.
    if (v.duration > Duration.zero && v.position >= v.duration) {
      await controller.seekTo(Duration.zero);
    }
    await controller.play();
  }

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> seekBy(Duration delta) async {
    final v = controller.value;
    if (!v.isInitialized) return;
    await controller.seekTo(shiftedPosition(v.position, delta, v.duration));
  }

  @override
  double get speed => controller.value.playbackSpeed;

  @override
  Future<void> setSpeed(double value) => controller.setPlaybackSpeed(value);
}
