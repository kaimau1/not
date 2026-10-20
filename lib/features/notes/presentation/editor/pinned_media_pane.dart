import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/personalize.dart';
import '../../../../core/widgets/after_route_transition.dart';
import '../../../../core/widgets/keyboard_snap.dart';
import '../../../../core/widgets/customizable.dart';
import '../../data/scan/scan_pdf.dart';
import '../../domain/attachment.dart';
import '../viewers/bubble_layer.dart';
import 'note_images.dart';
import 'audio_card_box.dart';
import 'pdf_page_box.dart';
import 'slide_page_box.dart';
import 'text_page_box.dart';
import 'video_transport.dart';

/// Sabit bölmenin yüksekliği bu sınırlar arasında kalır (dp / oran).
const double kPinnedMinHeight = 96;
const double kPinnedMaxFraction = 0.7;

/// Ayraç bu yüksekliğin altına çekilip bırakılırsa medya sayfaya geri döner.
const double kPinnedUnpinHeight = 72;

/// Medya ile not arasındaki çubuğun (tutamaç + düğmeler) yüksekliği.
const double kPinnedBarHeight = 44;

/// Klavye açıkken bölmenin altında notun yazılan satırına kalan en az yer.
const double kPinnedNoteMinHeight = 72;

/// Klavye açıkken medyanın görünür penceresinin en az yüksekliği.
const double kPinnedVisibleFloor = 56;

/// Bölmenin en büyük yüksekliği.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-10-19: "video sabitken klavye
/// açıldığında video yukarı itiliyor biraz"): sınır, O ANKİ yüksekliğin
/// %70'iydi. Klavye oturunca gövde klavye kadar kısalıyor, sınır da onunla
/// birlikte düşüyordu — bölme büzülüyor, video küçülüp yukarı kayıyor, çubuk
/// zıplıyordu. Artık oran klavyesiz (en büyük görülen) yükseklikten alınır;
/// klavye açıkken bölme YERİNDE kalır, yalnız not satırına
/// [kPinnedNoteMinHeight] kalmayacaksa küçülür.
double pinnedMaxHeight({required double available, required double stable}) {
  final byFraction = stable * kPinnedMaxFraction;
  final byRoom = available - kPinnedBarHeight - kPinnedNoteMinHeight;
  final max = byFraction < byRoom ? byFraction : byRoom;
  return max < kPinnedMinHeight ? kPinnedMinHeight : max;
}

/// Yeni sabitlenen medyanın ilk yüksekliği: ekran genişliğinde medyanın kendi
/// oranı, ekranın %45'ini geçmeden. Oranı bilinmeyen video 16:9 sayılır.
double defaultPinnedHeight(Attachment media, Size screen) {
  // Ses: oynatıcı kartı kadar; metin: okunacak kadar (ekranın %40'ı).
  if (media.kind == AttachmentKind.audio) return 104;
  if (media.kind == AttachmentKind.text) {
    return (screen.height * 0.4).clamp(kPinnedMinHeight, screen.height * 0.5);
  }
  final w = (media.width ?? 0).toDouble();
  final h = (media.height ?? 0).toDouble();
  final pdf = media.kind == AttachmentKind.pdf;
  final ratio = w > 0 && h > 0
      ? (pdf ? 1 / pdfBoxAspect(w, h, media.pdfTurns) : h / w)
      : (media.kind == AttachmentKind.video ||
                media.kind == AttachmentKind.slide
            ? 9 / 16
            : pdf
            ? 1.41
            : 3 / 4);
  final natural = screen.width * ratio;
  // Belge okunacak kadar uzun açılır (A4 sayfa ekranın yarısında bile
  // okunur); görsel/video ekranın %45'ini geçmez.
  final max = screen.height * (pdf ? 0.5 : 0.45);
  return natural.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );
}

/// **ÜSTTE MEDYA, ALTTA NOT** (kullanıcı isteği 2026-10-11).
///
/// Görsel ya da video notun tepesinde SABİT durur, not ([child]) altında
/// kendi başına kayar — video izlerken ya da bir görsele bakarken yazmak
/// için. Bölme ile not arasındaki AYRAÇ sürüklenerek boyutlanır (bırakınca
/// [onHeightChanged] kaydeder); ayraç en alta değil en ÜSTE, bölmeyi
/// kapatacak kadar çekilirse ya da medya basılı tutulup nota doğru aşağı
/// sürüklenirse medya sayfaya geri döner ([onUnpin]).
class PinnedMediaPane extends StatefulWidget {
  const PinnedMediaPane({
    super.key,
    required this.media,
    required this.onHeightChanged,
    required this.onUnpin,
    required this.onOpen,
    required this.child,
    this.onCopyLink,
    this.onChanged,
    this.viewSwitch,
    this.onNoteAt,
    this.bubbleDoc,
    this.onRemove,
    this.onDetach,
    this.onSaveAs,
    this.onTranscribe,
  });

  /// Sabit görselin/videonun TRANSKRİPTİ (metne dök / kayıtlıysa aç).
  final VoidCallback? onTranscribe;

  /// Eki nottan kaldırır (geri al ile döner) — çubuğun ⋮ menüsünde.
  ///
  /// Kullanıcı bulgusu 2026-10-16: "video sabitken kaldırmak ayarı yok,
  /// gömülü hale getirmek gerekiyor" — sabit bölmede yalnız simgeli görünüm
  /// anahtarı vardı; silmek için önce sayfaya almak, sonra seçip panelden
  /// silmek gerekiyordu. Menü YAZILI: Sayfaya göm · Alta ek olarak · Kaldır.
  final VoidCallback? onRemove;

  /// Eki sabit bölmeden alıp alttaki ek şeridine DOSYA olarak koyar.
  final VoidCallback? onDetach;

  /// EKİ FARKLI KAYDET (2026-10-17). null ise menüde yok.
  final VoidCallback? onSaveAs;

  /// GÖRSELDEN TÜRETİLMİŞ balonlu belge (bkz. `Attachment.sourceId`).
  /// Kullanıcı isteği 2026-10-16: "balonludan üste sabitlemeye alınca da
  /// balonlar görülsün ama göster/gizlesi olsun". Görsel balonluya alınınca
  /// balonlar A4 sayfadaki belgede yaşar; sabitlenen ise görselin kendisi.
  /// Balonlar görselin uzayına geri taşınıp ([unplaceBubbles]) üstünde salt
  /// okunur çizilir; çubukta göster/gizle (gizlilik belgede saklanır,
  /// [onChanged] ile yazılır). PDF'in kendi kutusu balonları zaten çizer.
  final Attachment? bubbleDoc;

  final Attachment media;
  final ValueChanged<double> onHeightChanged;
  final VoidCallback onUnpin;

  /// Tam ekran (görsel görüntüleyici / video oynatıcı).
  final VoidCallback onOpen;

  final Widget child;

  /// YouTube ekinin bağlantısını panoya yazar — ayraç çubuğunda düğme.
  final VoidCallback? onCopyLink;

  /// Sabitli PDF'in sayfa/yer imi/döndürme değişiklikleri (bkz.
  /// [PdfPageBox.onChanged]).
  final ValueChanged<Attachment>? onChanged;

  /// Ayraç çubuğunun sağındaki görünüm anahtarı (Sabit / Yüzen / Balonlu —
  /// bkz. `AttachmentViewSwitch`). null ise eski "sayfaya geri koy" düğmesi.
  final Widget? viewSwitch;

  /// "Bu ana not al" (yalnız video): ayraç çubuğunda yazılı düğme.
  final VoidCallback? onNoteAt;

  @override
  State<PinnedMediaPane> createState() => _PinnedMediaPaneState();
}

class _PinnedMediaPaneState extends State<PinnedMediaPane> {
  /// Sabit görselin üstündeki balonların denetleyicisi (bkz.
  /// [PinnedMediaPane.bubbleDoc]); aç/kapa durumu yazılmaz — görselin
  /// uzayındaki kopya belgeye geri yazılamaz, okuma için yeter.
  BubbleController? _imageBubbles;

  List<PageBubble> _mappedBubbles(Attachment doc) => unplaceBubbles(
    doc.bubbles,
    ScanPdf.imageFrameOnPage(widget.media.width ?? 0, widget.media.height ?? 0),
  );

  BubbleController? _bubblesFor(Attachment? doc) {
    if (doc == null || doc.bubbles.isEmpty) return null;
    return _imageBubbles ??= BubbleController(
      initial: _mappedBubbles(doc),
      hidden: doc.bubblesHidden,
      onChanged: (_) {},
    );
  }

  @override
  void didUpdateWidget(PinnedMediaPane old) {
    super.didUpdateWidget(old);
    final doc = widget.bubbleDoc;
    if (doc != null) {
      _imageBubbles
        ?..replace(_mappedBubbles(doc))
        ..syncHidden(doc.bubblesHidden);
    }
  }

  @override
  void dispose() {
    _imageBubbles?.dispose();
    super.dispose();
  }

  /// Görselin bölmede `contain` ile çizildiği dikdörtgen (balonlar onun
  /// oranlı uzayında). Ölçüsü bilinmeyen görselde null.
  Rect? _imageRect(Size box) {
    final w = (widget.media.width ?? 0).toDouble();
    final h = (widget.media.height ?? 0).toDouble();
    if (w <= 0 || h <= 0 || box.isEmpty) return null;
    final scale = (box.width / w) < (box.height / h)
        ? box.width / w
        : box.height / h;
    final dw = w * scale;
    final dh = h * scale;
    return Rect.fromLTWH((box.width - dw) / 2, (box.height - dh) / 2, dw, dh);
  }

  /// Ayraç sürüklenirken canlı yükseklik (ham — sınırlanmamış).
  double? _live;

  /// Medya basılı tutulup aşağı sürüklenirken parmağın yer değiştirmesi.
  double _pullDown = 0;
  bool _pulling = false;

  double _clamp(double h, double max) => h.clamp(
    kPinnedMinHeight,
    max < kPinnedMinHeight ? kPinnedMinHeight : max,
  );

  /// Klavyesiz yükseklik — klavye kapalıyken ölçülen yükseklik; genişlik
  /// değişince sıfırlanır (yönelim, pencere). Bkz. [pinnedMaxHeight].
  double _stableWidth = -1;
  double _stableHeight = 0;

  double _stable(BoxConstraints c) {
    if (c.maxWidth != _stableWidth) {
      _stableWidth = c.maxWidth;
      _stableHeight = 0;
    }
    if (!c.maxHeight.isFinite) return _stableHeight;
    // Klavye yokken gerçek değişimleri (ek şeridi açıldı, pencere) izler;
    // klavye açıkken en büyük görülen kalır.
    if (!_keyboard.open || c.maxHeight > _stableHeight) {
      _stableHeight = c.maxHeight;
    }
    return _stableHeight;
  }

  /// Klavyenin evresi (bkz. [KeyboardPhaseListener]).
  KeyboardPhase _keyboard = (open: false, estimate: 0);

  /// **KLAVYE AÇILINCA MEDYA KÜÇÜLMEZ** (kullanıcı bulgusu 2026-10-20:
  /// "görsel/video/PDF sabitken klavye açılınca odak kayması, görselin boyut
  /// değiştirmesi; zıplatmadan düzgün akış").
  ///
  /// KÖK NEDEN: gövde klavye OTURDUKTAN sonra tek seferde kısalıyor (bkz.
  /// KeyboardSnap), bölmenin sınırı da onunla birlikte düşüyordu: görsel
  /// bir karede küçülüp yukarı zıplıyor, not alanı sıçrıyor, imleç yeniden
  /// kaydırılıyordu. Artık medya klavyesiz boyunda yerleşir ve hiç yeniden
  /// ölçülmez; yer gerekiyorsa yalnız GÖRÜNÜR PENCERESİ, klavyeyle aynı anda
  /// ve yumuşakça daralır — alttaki çubuk ve not üstüne kayar gibi örter.
  /// Klavye kapanırken pencere aynı yoldan geri açılır.
  double _visibleHeight({
    required double layout,
    required double available,
    required double stable,
  }) {
    if (!_keyboard.open) return layout;
    // Gövde henüz kısalmadıysa (klavye açılıyor) kalacak yer tahminle
    // hesaplanır; kısaldıysa gerçek ölçü zaten elde.
    final settled = stable - available > 40;
    final room = settled ? available : available - _keyboard.estimate;
    final fit = room - kPinnedBarHeight - kPinnedNoteMinHeight;
    return math.min(layout, math.max(kPinnedVisibleFloor, fit));
  }

  bool get _unpinArmed =>
      (_live != null && _live! < kPinnedUnpinHeight) ||
      (_pulling && _pullDown > 96);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isVideo = widget.media.kind == AttachmentKind.video;
    final isPdf = widget.media.kind == AttachmentKind.pdf;
    final isText = widget.media.kind == AttachmentKind.text;
    final isAudio = widget.media.kind == AttachmentKind.audio;
    final isSlide = widget.media.kind == AttachmentKind.slide;
    // Zamanlı medya: denetim çubuğu ve ilerleme çizgisi (video + ses).
    final timed = isVideo || isAudio;
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final stable = _stable(constraints);
        // Sürükleme sınırı O ANKİ yerden (klavye açıksa notun satırı kalsın);
        // medyanın YERLEŞİM boyu ise klavyesiz yükseklikten — klavye açılınca
        // medya yeniden ölçülmez (bkz. [_visibleHeight]).
        final max = pinnedMaxHeight(
          available: constraints.maxHeight,
          stable: stable,
        );
        final layoutMax = pinnedMaxHeight(available: stable, stable: stable);
        final live = _live;
        // Sürüklerken bölme sınırın altına da iner (geri bırakma hissi);
        // bırakınca sınıra oturur ya da sayfaya döner.
        final height = live != null
            ? live.clamp(0.0, max < kPinnedMinHeight ? kPinnedMinHeight : max)
            : _clamp(widget.media.pinHeight, layoutMax);
        final visible = live != null
            ? height
            : _visibleHeight(
                layout: height,
                available: constraints.maxHeight,
                stable: stable,
              );
        return Column(
          children: [
            KeyboardClipWindow(
              full: height,
              visible: visible,
              animate: live == null,
              // NOT AÇILIŞI HAFİF (kullanıcı bulgusu 2026-10-20: "notu
              // açarken ufak donma"): oynatıcı/belge görüntüleyicisi rota
              // geçişi bitince kurulur (bkz. AfterRouteTransition).
              child: AfterRouteTransition(
                placeholder: ColoredBox(
                  color: isVideo ? Colors.black : scheme.surfaceContainerHigh,
                ),
                child: isText
                    // METİN (2026-10-17): kaydırılan, seçilebilen kâğıt. Basılı
                    // tutmak metni SEÇER (görseldeki "aşağı çekip bırak"
                    // jesti yok) — bölmeden çıkış anahtardan/menüden.
                    ? TextReaderView(
                        key: ValueKey('pinned-text-${widget.media.id}'),
                        attachment: widget.media,
                      )
                    : isAudio
                    // SES: oynatıcı kartı; ±sn, hız ve "Not al" çubukta.
                    ? AudioCardBox(
                        key: ValueKey('pinned-audio-${widget.media.id}'),
                        attachment: widget.media,
                        noteAtButton: false,
                      )
                    : isSlide
                    // SUNUM (2026-10-17): slayt çevrilebilen kutu; bölmeden
                    // çıkış görünüm anahtarından.
                    ? SlidePageBox(
                        key: ValueKey('pinned-slide-${widget.media.id}'),
                        attachment: widget.media,
                        onChanged: widget.onChanged ?? (_) {},
                      )
                    : isPdf
                    // Belge kutusu kendi jestlerini kullanır (yatay kaydırma
                    // sayfa çevirir, çubuğu sayfa atlar); bölmeden çıkış
                    // görünüm anahtarından.
                    ? ColoredBox(
                        color: scheme.surfaceContainerHigh,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: pdfBoxAspect(
                              (widget.media.width ?? 0).toDouble(),
                              (widget.media.height ?? 0).toDouble(),
                              widget.media.pdfTurns,
                            ),
                            child: PdfPageBox(
                              key: ValueKey('pinned-pdf-${widget.media.id}'),
                              attachment: widget.media,
                              onChanged: widget.onChanged ?? (_) {},
                              // Balonludan sabite alınan belge balonlarıyla
                              // görünür; çubukta göster/gizle.
                              showBubbles: true,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: isVideo ? null : widget.onOpen,
                        onLongPressStart: (_) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _pulling = true;
                            _pullDown = 0;
                          });
                        },
                        onLongPressMoveUpdate: (d) =>
                            setState(() => _pullDown = d.offsetFromOrigin.dy),
                        onLongPressEnd: (_) {
                          final unpin = _unpinArmed;
                          setState(() {
                            _pulling = false;
                            _pullDown = 0;
                          });
                          if (unpin) widget.onUnpin();
                        },
                        onLongPressCancel: () => setState(() {
                          _pulling = false;
                          _pullDown = 0;
                        }),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: isVideo
                                  ? Colors.black
                                  : scheme.surfaceContainerHigh,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  _pulling ? _pullDown.clamp(0, 140) : 0,
                                ),
                                child: Opacity(
                                  opacity: _pulling ? 0.6 : 1,
                                  child: NoteMediaBox(
                                    // Ek değişince (başka medya sabitlenince)
                                    // oynatıcı da yenilensin.
                                    key: ValueKey(widget.media.id),
                                    attachment: widget.media,
                                    fit: BoxFit.contain,
                                    inlineWebVideo: true,
                                    showWebTitle: true,
                                    // Denetim bölmenin çubuğunda.
                                    videoControls: false,
                                  ),
                                ),
                              ),
                            ),
                            if (!isVideo && !_pulling)
                              if (_bubblesFor(widget.bubbleDoc)
                                  case final bubbles?)
                                LayoutBuilder(
                                  builder: (context, box) {
                                    final rect = _imageRect(box.biggest);
                                    if (rect == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned.fromRect(
                                          rect: rect,
                                          child: BubblePageLayer(
                                            controller: bubbles,
                                            page: 1,
                                            readOnly: true,
                                            longPressAdd: false,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                            if (_unpinArmed)
                              _UnpinHint(label: l10n.unpinMediaRelease),
                          ],
                        ),
                      ),
              ),
            ),
            // AYRAÇ ÇUBUĞU: dikey sürükleme bölmeyi boyutlar; düğmeler de
            // BURADA (kullanıcı bulgusu 2026-10-11: medyanın üstüne konan
            // düğmeler YouTube oynatıcısının kendi sağ üst düğmeleriyle üst
            // üste geliyordu). Çubuk medyanın DIŞINDA, hiçbir şeyi örtmez.
            GestureDetector(
              key: const ValueKey('pinned-media-bar'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => setState(() => _live = height),
              onVerticalDragUpdate: (d) =>
                  setState(() => _live = (_live ?? height) + d.delta.dy),
              onVerticalDragEnd: (_) {
                final raw = _live ?? height;
                setState(() => _live = null);
                if (raw < kPinnedUnpinHeight) {
                  widget.onUnpin();
                } else {
                  widget.onHeightChanged(_clamp(raw, max));
                }
              },
              onVerticalDragCancel: () => setState(() => _live = null),
              child: Container(
                height: kPinnedBarHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainer,
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                // Dar ekranda önce süre yazısı, sonra "Not al" yazısı, en
                // son bağlantı düğmesi düşer — denetimler ve anahtar kalır.
                child: LayoutBuilder(
                  builder: (context, bar) => Stack(
                    children: [
                      _barRow(context, bar.maxWidth),
                      // Videonun ilerlemesi çubuğun üst kenarında ince çizgi.
                      if (timed)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: VideoProgressLine(video: widget.media),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
    return KeyboardPhaseListener(
      onChanged: (phase) {
        if (mounted) setState(() => _keyboard = phase);
      },
      child: layout,
    );
  }

  Widget _barRow(BuildContext context, double width) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isVideo = widget.media.kind == AttachmentKind.video;
    final isAudio = widget.media.kind == AttachmentKind.audio;
    final timed = isVideo || isAudio;
    final noteAtLabel = !timed || width >= 430;
    final showLink = !isVideo || width >= 360;
    return Row(
      children: [
        // Sesin tam ekranı yok (kart kendisi oynatıcı).
        if (!isAudio)
          _BarButton(
            tooltip: l10n.fullscreen,
            icon: Icons.fullscreen,
            onPressed: widget.onOpen,
          ),
        // VİDEO DENETİMİ (kullanıcı isteği 2026-10-16): ±10 sn ve
        // oynat/durdur medyanın HEMEN ALTINDA — oynatıcının
        // üstünü örtmez. Ses de aynı çubuğu kullanır (2026-10-17).
        if (timed)
          VideoTransportControls(
            video: widget.media,
            showTime: width >= 500,
            showSpeed: width >= 400,
          ),
        Expanded(
          child: Semantics(
            label: l10n.pinnedMediaResize,
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: _live != null
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        // Kişiselleştirmede gizlenebilir (bkz. UiItem.videoNoteAt).
        if (widget.onNoteAt != null)
          Customizable(
            id: UiItem.videoNoteAt,
            child: noteAtLabel
                ? Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: TextButton.icon(
                      key: const ValueKey('pinned-note-at'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: widget.onNoteAt,
                      icon: const Icon(Icons.more_time, size: 18),
                      label: Text(l10n.videoNoteAtTimeShort),
                    ),
                  )
                : IconButton(
                    key: const ValueKey('pinned-note-at'),
                    tooltip: l10n.videoNoteAtTime,
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    color: scheme.primary,
                    icon: const Icon(Icons.more_time),
                    onPressed: widget.onNoteAt,
                  ),
          ),
        // Görselden türetilmiş belgenin balonları: göster/gizle.
        if (widget.bubbleDoc case final doc?
            when doc.bubbles.isNotEmpty && !isVideo)
          IconButton(
            key: const ValueKey('pinned-bubbles-toggle'),
            tooltip: doc.bubblesHidden ? l10n.bubblesShow : l10n.bubblesHide,
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            isSelected: doc.bubblesHidden,
            icon: Icon(
              doc.bubblesHidden
                  ? Icons.speaker_notes_off_outlined
                  : Icons.chat_bubble_outline,
            ),
            onPressed: () => widget.onChanged?.call(
              doc.copyWith(bubblesHidden: !doc.bubblesHidden),
            ),
          ),
        if (showLink &&
            !hasMenu &&
            widget.onCopyLink != null &&
            widget.media.isWebVideo)
          _BarButton(
            tooltip: l10n.copyVideoLink,
            icon: Icons.link,
            onPressed: widget.onCopyLink!,
          ),
        // Dar çubukta (< 340 dp) ⋮ menüsü varken anahtar düşer: menüdeki
        // "Sayfaya göm" aynı işi yazılı olarak yapar.
        if (widget.viewSwitch case final viewSwitch?
            when width >= 340 || !hasMenu)
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2),
            child: viewSwitch,
          )
        else if (!hasMenu)
          _BarButton(
            tooltip: l10n.unpinMedia,
            icon: Icons.vertical_align_bottom,
            onPressed: widget.onUnpin,
          ),
        if (hasMenu) _menu(context),
      ],
    );
  }

  /// Çubuğun ⋮ menüsü verilmiş mi (salt okunurda kaldır/ek yok).
  bool get hasMenu =>
      widget.onRemove != null ||
      widget.onDetach != null ||
      widget.onTranscribe != null ||
      widget.onSaveAs != null;

  /// YAZILI işlemler: sayfaya göm (yüzen), alta ek olarak, bağlantı, kaldır.
  Widget _menu(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget item(IconData icon, String label, {Color? color}) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: color == null ? null : TextStyle(color: color)),
    );
    return PopupMenuButton<String>(
      key: const ValueKey('pinned-media-menu'),
      tooltip: l10n.more,
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (action) {
        switch (action) {
          case 'float':
            widget.onUnpin();
          case 'detach':
            widget.onDetach?.call();
          case 'link':
            widget.onCopyLink?.call();
          case 'transcribe':
            widget.onTranscribe?.call();
          case 'saveAs':
            widget.onSaveAs?.call();
          case 'remove':
            widget.onRemove?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'float',
          child: item(Icons.wrap_text_rounded, l10n.pinnedEmbedOnPage),
        ),
        if (widget.onDetach != null)
          PopupMenuItem(
            value: 'detach',
            child: item(Icons.attachment_outlined, l10n.moveImageToAttachments),
          ),
        if (widget.onCopyLink != null && widget.media.isWebVideo)
          PopupMenuItem(
            value: 'link',
            child: item(Icons.link, l10n.copyVideoLink),
          ),
        if (widget.onTranscribe != null)
          PopupMenuItem(
            value: 'transcribe',
            child: item(Icons.subtitles_outlined, l10n.transcriptAction),
          ),
        if (widget.onSaveAs != null && !widget.media.isWebVideo)
          PopupMenuItem(
            value: 'saveAs',
            child: item(Icons.save_alt_outlined, l10n.attachmentSaveAs),
          ),
        if (widget.onRemove != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'remove',
            child: item(
              Icons.delete_outline,
              l10n.removeAttachment,
              color: scheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    iconSize: 20,
    icon: Icon(icon),
    onPressed: onPressed,
  );
}

class _UnpinHint extends StatelessWidget {
  const _UnpinHint({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}
