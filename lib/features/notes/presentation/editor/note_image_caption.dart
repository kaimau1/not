part of 'note_images.dart';

/// Görselle açıklamasının arası (dp).
const double kCaptionGap = 6;

/// Açıklamanın yazısı: görselin altında küçük, yumuşak, okunur.
TextStyle captionTextStyle(ColorScheme scheme) => TextStyle(
  fontSize: 13.5,
  height: 1.35,
  letterSpacing: 0.1,
  color: scheme.onSurfaceVariant,
);

/// Açıklamanın en çok satırı (sayfada; tamamı düzenlerken okunur).
const int _kCaptionLines = 3;

/// **GÖRSEL AÇIKLAMASI** (kullanıcı isteği 2026-10-28). Görselin hemen
/// altında durur ve sayfa düzeninin parçasıdır: metin görselle açıklamasının
/// İKİSİNİN de etrafından akar ([_NotePageCanvasState._captionBand]).
///
/// Dokununca yerinde düzenlenir; klavyenin "bitti"si ya da odağın gitmesi
/// kaydeder. Boş açıklama sayfada yer kaplamaz — yalnız düzenlerken ipucuyla
/// ("Görüntü açıklaması") görünür.
class _ImageCaption extends StatefulWidget {
  const _ImageCaption({
    required this.caption,
    required this.editing,
    required this.onStartEdit,
    required this.onDraft,
    required this.onCommit,
  });

  final String caption;
  final bool editing;
  final VoidCallback onStartEdit;

  /// Yazılan taslak (sayfa açıklama bandının boyunu ona göre ölçer).
  final ValueChanged<String> onDraft;
  final ValueChanged<String> onCommit;

  @override
  State<_ImageCaption> createState() => _ImageCaptionState();
}

class _ImageCaptionState extends State<_ImageCaption> {
  TextEditingController? _controller;
  FocusNode? _focus;
  bool _committed = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing) _startEditing();
  }

  @override
  void didUpdateWidget(_ImageCaption old) {
    super.didUpdateWidget(old);
    if (widget.editing && !old.editing) _startEditing();
    if (!widget.editing && old.editing) _stopEditing();
  }

  void _startEditing() {
    _committed = false;
    _controller = TextEditingController(text: widget.caption);
    _focus = FocusNode()..addListener(_onFocus);
    // Kare sonunda odak: alan bu karede kuruluyor.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus?.requestFocus();
    });
  }

  void _stopEditing({bool now = false}) {
    final focus = _focus;
    final controller = _controller;
    _focus = null;
    _controller = null;
    focus?.removeListener(_onFocus);
    if (now) {
      focus?.dispose();
      controller?.dispose();
      return;
    }
    // Alan bu karede ağaçtan çıkıyor; ona bağlı nesneler kare SONRASINDA
    // bırakılır (yerleşim sürerken bırakılan odak düğümü iddiaya takılır).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focus?.dispose();
      controller?.dispose();
    });
  }

  void _onFocus() {
    if (!(_focus?.hasFocus ?? true)) _commit();
  }

  void _commit() {
    if (_committed) return;
    _committed = true;
    widget.onCommit(_controller?.text ?? widget.caption);
  }

  @override
  void dispose() {
    _stopEditing(now: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = captionTextStyle(scheme);
    final controller = _controller;
    final Widget child;
    if (widget.editing && controller != null) {
      child = TextField(
        key: const ValueKey('caption-field'),
        controller: controller,
        focusNode: _focus,
        style: style.copyWith(color: scheme.onSurface),
        minLines: 1,
        maxLines: _kCaptionLines,
        maxLength: Attachment.maxCaptionChars,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        cursorWidth: 1.6,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          hintText: context.l10n.imageCaptionHint,
          hintStyle: style.copyWith(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
        ),
        onChanged: widget.onDraft,
        onSubmitted: (_) => _commit(),
        onTapOutside: (_) => _focus?.unfocus(),
      );
    } else {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onStartEdit,
        child: Text(
          widget.caption,
          maxLines: _kCaptionLines,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
    }
    // Düzenlemeye geçiş yumuşak: alan (ya da kaydedilen yazı) yerinde
    // belirir. Anahtar kipe bağlı — her geçişte solma baştan oynar.
    return TweenAnimationBuilder<double>(
      key: ValueKey(widget.editing),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: child,
    );
  }
}

/// Açıklama metninin sayfadaki yüksekliği (dp) — metin sarması ve sayfanın
/// boyu bunu kullanır. Son ölçüm saklanır: aynı metin/genişlik her karede
/// yeniden ölçülmesin.
class _CaptionMeasure {
  String? _text;
  double? _width;
  double? _scale;
  double _height = 0;

  double heightOf(String text, double width, TextScaler scaler) {
    final scale = scaler.scale(1);
    if (text == _text && width == _width && scale == _scale) return _height;
    final painter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? ' ' : text,
        style: const TextStyle(
          fontSize: 13.5,
          height: 1.35,
          letterSpacing: 0.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: _kCaptionLines,
    )..layout(maxWidth: width.clamp(1.0, double.infinity));
    _text = text;
    _width = width;
    _scale = scale;
    _height = painter.height;
    painter.dispose();
    return _height;
  }
}
