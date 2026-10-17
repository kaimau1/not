import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/smooth_routes.dart';
import '../../data/attachment_repository.dart';
import '../../data/pptx_render.dart';
import '../../data/slide_deck.dart';
import '../../domain/attachment.dart';
import '../viewers/slide_canvas.dart';
import '../viewers/slide_scroll.dart';
import '../viewers/slide_viewer_screen.dart';

/// Sunumun yüklenmiş slaytları — aynı dosya sayfada, bölmede ve büyük
/// önizlemede aynı anda çizilebiliyor; .pptx her kutuda yeniden
/// ayrıştırılmasın (unzip + XML ağır).
final _deckCache = <String, Future<List<SlideVM>>>{};

/// **SAYFAYA GÖMÜLÜ / SABİT SUNUM** (kullanıcı isteği 2026-10-17: "sunum
/// gibi diğer tipteki dosyalarda gömülü, Sabit, Balonlu, Ek seçeneklerinin
/// hepsi olmalı; gömülü iken ve sabitken de sayfaları değiştirilebilsin").
///
/// [PdfPageBox]'ın sunum karşılığı: tek slayt, altında ‹ 3 / 12 › çubuğu,
/// yatay kaydırma ile çevirme, ⤢ tam ekran. Kaldığın slayt ekte
/// [Attachment.pdfPage] alanında saklanır (PDF'teki gibi senkronlanır).
class SlidePageBox extends ConsumerStatefulWidget {
  const SlidePageBox({
    super.key,
    required this.attachment,
    required this.onChanged,
    this.swipeToTurn = true,
    this.controls = true,
  });

  final Attachment attachment;
  final ValueChanged<Attachment> onChanged;

  /// Kutu üzerinde yatay kaydırma slayt çevirsin mi (bkz. PdfPageBox).
  final bool swipeToTurn;

  /// false ise alt çubuk çizilmez (salt görüntü).
  final bool controls;

  @override
  ConsumerState<SlidePageBox> createState() => _SlidePageBoxState();
}

class _SlidePageBoxState extends ConsumerState<SlidePageBox> {
  List<SlideVM>? _slides;
  bool _failed = false;
  PageController? _pager;
  late int _page = widget.attachment.pdfPage < 1
      ? 1
      : widget.attachment.pdfPage;
  Timer? _save;

  String get _key {
    final a = widget.attachment;
    return a.downloadUrl.isNotEmpty ? a.downloadUrl : '${a.id}:${a.localPath}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SlidePageBox old) {
    super.didUpdateWidget(old);
    // Dosya bu arada indi/yüklendi: yeniden denenir.
    if (_failed &&
        old.attachment.downloadUrl != widget.attachment.downloadUrl) {
      _failed = false;
      _load();
    }
    final page = widget.attachment.pdfPage;
    if (page != _page && _save == null && _slides != null) {
      _jump(page);
    }
  }

  Future<void> _load() async {
    final repo = ref.read(attachmentRepositoryProvider);
    try {
      final future = _deckCache[_key] ??= () async {
        final bytes = await repo?.readBytes(widget.attachment);
        if (bytes == null) throw StateError('no-bytes');
        return SlideDeck.fromBytes(bytes);
      }();
      final slides = await future;
      if (!mounted) return;
      final page = _page.clamp(1, slides.isEmpty ? 1 : slides.length);
      setState(() {
        _slides = slides;
        _page = page;
        _pager?.dispose();
        _pager = PageController(initialPage: page - 1);
      });
      _fitAspect(slides);
    } catch (_) {
      _deckCache.remove(_key);
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Kutunun oranı ilk slayttan alınır ve ekte saklanır (16:9 varsayımıyla
  /// ezilmiş 4:3 sunum olmasın).
  void _fitAspect(List<SlideVM> slides) {
    if (slides.isEmpty) return;
    final s = slides.first;
    if (s.widthPt <= 0 || s.heightPt <= 0) return;
    final w = (s.widthPt * 10).round();
    final h = (s.heightPt * 10).round();
    final a = widget.attachment;
    if (a.width == w && a.height == h) return;
    // Kullanıcı kutuyu kendi boyutlandırdıysa oran yine slaydınki olmalı.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onChanged(widget.attachment.copyWith(width: w, height: h));
      }
    });
  }

  @override
  void dispose() {
    _flush();
    _pager?.dispose();
    super.dispose();
  }

  void _flush() {
    final t = _save;
    if (t == null) return;
    t.cancel();
    _save = null;
    if (widget.attachment.pdfPage != _page) {
      widget.onChanged(widget.attachment.copyWith(pdfPage: _page));
    }
  }

  void _onPage(int index) {
    if (_page == index + 1) return;
    setState(() => _page = index + 1);
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 700), _flush);
  }

  void _jump(int page) {
    final slides = _slides;
    final pager = _pager;
    if (slides == null || pager == null || !pager.hasClients) return;
    final target = page.clamp(1, slides.length);
    pager.animateToPage(
      target - 1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openFull() async {
    _flush();
    await Navigator.of(context).push(
      MediaRoute<void>(
        builder: (_) => SlideViewerScreen(
          attachment: widget.attachment,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slides = _slides;
    final Widget body;
    if (_failed || (slides != null && slides.isEmpty)) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            context.l10n.slideOpenFailed,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
      );
    } else if (slides == null) {
      body = const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      body = PageView.builder(
        key: const ValueKey('slide-box-pager'),
        controller: _pager,
        physics: widget.swipeToTurn
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: slides.length,
        onPageChanged: _onPage,
        itemBuilder: (context, i) => Center(
          child: AspectRatio(
            aspectRatio: slideAspect(slides[i]),
            child: RepaintBoundary(child: SlideCanvas(slide: slides[i])),
          ),
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(child: ClipRect(child: body)),
          if (widget.controls && slides != null && slides.isNotEmpty)
            _SlideBar(
              page: _page,
              count: slides.length,
              onPrev: _page > 1 ? () => _jump(_page - 1) : null,
              onNext: _page < slides.length ? () => _jump(_page + 1) : null,
              onFull: _openFull,
            ),
        ],
      ),
    );
  }
}

class _SlideBar extends StatelessWidget {
  const _SlideBar({
    required this.page,
    required this.count,
    required this.onPrev,
    required this.onNext,
    required this.onFull,
  });

  final int page;
  final int count;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const ink = Colors.white;
    Widget button(IconData icon, String tip, VoidCallback? onTap) => SizedBox(
      width: 32,
      height: 28,
      child: IconButton(
        tooltip: tip,
        padding: EdgeInsets.zero,
        iconSize: 18,
        color: ink,
        disabledColor: ink.withValues(alpha: 0.3),
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
    return Container(
      height: 28,
      color: Colors.black.withValues(alpha: 0.85),
      child: Row(
        children: [
          button(Icons.chevron_left, l10n.pdfPreviousPage, onPrev),
          Expanded(
            child: Text(
              '$page / $count',
              key: const ValueKey('slide-box-counter'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          button(Icons.chevron_right, l10n.pdfNextPage, onNext),
          button(Icons.open_in_full, l10n.fullscreen, onFull),
        ],
      ),
    );
  }
}
