part of 'pinned_media_pane.dart';

  /// Videonun yükseklik/genişlik oranı; bilinmiyorsa (YouTube, ölçüsü
  /// henüz gelmemiş dosya) 16:9.
double _videoRatio(Attachment media) {
  final w = (media.width ?? 0).toDouble();
  final h = (media.height ?? 0).toDouble();
  return w > 0 && h > 0 ? h / w : 9 / 16;
}

double? _fitRatio(Attachment media) {
  final w = (media.width ?? 0).toDouble();
  final h = (media.height ?? 0).toDouble();
  final known = w > 0 && h > 0;
  return switch (media.kind) {
    AttachmentKind.video => _videoRatio(media),
    AttachmentKind.slide => known ? h / w : 9 / 16,
    AttachmentKind.image => known ? h / w : null,
    AttachmentKind.pdf =>
      known ? 1 / pdfBoxAspect(w, h, media.pdfTurns) : null,
    _ => null,
  };
}

extension _PinnedMediaPaneParts on _PinnedMediaPaneState {
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

  /// SABİT GÖRSELE BALON (kullanıcı isteği 2026-11-05: "sabitleme ile
  /// balonlu modu birleştir, tek mod sabitleme olsun, orada balon ekleme
  /// olabilir"). Balonlu görünüm kalktı; görselin balonları görselin KENDİ
  /// ekinde (`page: 1`, görüntüleyicideki "görsel üstüne metin"le aynı veri)
  /// yaşar. İlk düzenlemede görselden türetilmiş eski belgenin balonları
  /// görselin uzayına taşınıp ([_mappedBubbles]) görsele yazılır.
  ///
  /// SABİT KİPİN TEK DAVRANIŞI (kullanıcı bulgusu 2026-11-05: "balonlar
  /// taşınamıyor, düzenlenemiyor; uzun basış metin tanıma yapıyor"):
  /// yazılabilir notta balonlar HEP düzenlenebilir — tutamaç basılı tutulup
  /// taşınır, okuma kartında Düzenle çıkar; iki parmak ya da çift dokunuş
  /// yakınlaştırır. Yeni balon YALNIZ çubuktaki "Balon ekle" menüsünden
  /// (Balon / Açık metin) açılan bırakma kipinde dokunarak eklenir;
  /// basılı tutmak görseldeki yazıyı seçmeye açar (kullanıcı kararı

  bool get _inkableImage =>
      widget.media.kind == AttachmentKind.image &&
      _hasImageBounds &&
      !_bubbleEdit;

  /// Görselin çizim katmanı (görselin dikdörtgeninde, yakınlaştırma
  /// dönüşümünün içinde).
  Widget _imageInkLayer() => PinnedImageInkSurface(
    strokes: _shownInk,
    revision: _ink?.revision ?? 0,
    width: widget.media.width,
    height: widget.media.height,
    probedRatio: _mediaRatio,
    activeController: _penOn ? _inkFor(widget.media) : null,
  );

  /// **YAZILAR KAYBOLUP GERİ GELİYORDU** (kullanıcı bulgusu 2026-11-21):
  /// kalem kapalıyken katman [widget.media]'nın çizgilerini boyuyordu; editör
  /// eke yazılan çizgide kökü kurmadığı (F60.1) için o liste BAYAT — son
  /// çizilenler kök yeniden kurulana dek görünmüyordu. Denetleyici varsa ve
  /// ekin listesi dışarıdan değişmediyse (tam ekran, geri al, başka cihaz)
  /// denetleyicinin güncel çizgileri boyanır.
  List<InkStroke> get _shownInk {
    final c = _ink;
    if (c == null || !identical(widget.media.ink, _inkSeen)) {
      return widget.media.ink;
    }
    return c.ink;
  }

  /// Kalem kuralı tek yerde ([PenPolicy], F63.1).
  PenPolicy get _policy => PenPolicy.resolve(
    surface: PenSurface.pinnedDoc,
    penMode: _explicitPen,
    autoStylus: InkToolMemory.autoStylus,
    stylusEver: InkToolMemory.stylusEver,
    penOnly: InkToolMemory.penOnly,
  );

  /// Kalem kipi (editörün ya da bölmenin): parmak da çizer. Değilse ve
  /// yüzen düğme "kalem yazar" diyorsa YALNIZ kalem çizer, parmak kaydırır
  /// (kullanıcı bulgusu 2026-11-09: "sabitken yazı yazamıyorum").

  void _onOwnBubbles() {
    final own = _ownBubbles;
    if (own == null || !mounted) return;
    final adding = own.adding;
    final bar = (own.hidden, own.bubbles.isEmpty);
    if (adding == _lastAdding && bar == _lastBar) return;
    final closed = _lastAdding == true && !adding;
    _lastAdding = adding;
    _lastBar = bar;
    if (closed) own.save();
    _redraw(() {});
  }

  /// "Balon ekle" menüsünden seçilen tür ([plain]: açık metin) ile bırakma
  /// kipini açar; kip açıkken düğme kipi kapatır.
  void _startAdding({required bool plain}) {
    if (_canEditBubbles) {
      _ownController()
        ..setPlainMode(plain)
        ..setAdding(true);
    } else if (_canEditPdfBubbles) {
      _pdfPlain.value = plain;
      _pdfAdding.value = true;
    }
  }

  void _stopAdding() {
    if (_canEditBubbles) {
      _ownBubbles?.setAdding(false);
    } else {
      _pdfAdding.value = false;
    }
  }

  /// Sabit görselde çift dokunuş: sığdırılmışken dokunulan yer 2,5 kat
  /// büyür, yakınken geri sığar (PDF kutusuyla aynı).
  void _toggleImageZoom() {
    // Bütün görsel kipindeyken çift dokunuş genişliğe oturmaya döner.
    if (_wholeImage) {
      _redraw(() => _wholeImage = false);
      _imageZoom.value = Matrix4.identity();
      return;
    }
    if (_imageZoomed) {
      _imageZoom.value = Matrix4.identity();
      return;
    }
    final at = _doubleTapAt;
    if (at == null) return;
    const scale = 2.5;
    _imageZoom.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// **TEK TANIYICI** (kullanıcı bulgusu 2026-11-22, v1.2.115: "iki parmak
  /// zoom yapamıyorum, sabit görselde zoom in/out olmuyor"): genişliğe oturan
  /// görselde dikey kaydırma ayrı bir `onVerticalDrag` tanıyıcısıydı; İLK
  /// parmak kaydırma eşiğini geçince arenayı o kazanıyor, ikinci parmak
  /// gelince ölçek tanıyıcısı çoktan kaybetmiş oluyordu → kıstırma hiç
  /// çalışmıyordu. Artık tek parmak kaydırma da `InteractiveViewer`ın ölçek
  /// tanıyıcısından gelir (pan kapalıyken de güncelleme bildiriyor).
  void _onImageZoomUpdate(ScaleUpdateDetails d) {
    if (d.pointerCount >= 2) {
      _pinch = d.scale;
      final atFit = _pinchFrom <= 1.01;
      // UZAKLAŞ = BÖLME CANLI KÜÇÜLÜR (görsel bütün hâliyle sığar);
      // bütün kipte yakınlaşma bölmeyi büyütür.
      if (_fitsWidth && (_wholeImage || (atFit && d.scale < 0.97))) {
        final h = (_pinchStartH * d.scale).clamp(
          kPinnedMinHeight,
          math.max(kPinnedMinHeight, math.min(_dragMax, _dragNatural)),
        ).toDouble();
        _redraw(() {
          if (!_wholeImage) {
            _wholeImage = true;
            _imageScroll.offset = 0;
            _imageZoom.value = Matrix4.identity();
          }
          _resizing = true;
          _live = h;
        });
      }
      return;
    }
    if (_imageScrolls) _imageScroll.by(-d.focalPointDelta.dy);
  }

  /// Kıstırma bitince: canlı boy kaydedilir (ayraç sürüklemeyle aynı yol);
  /// tavana varan bütün görsel genişliğe oturmaya döner. Tek parmak
  /// kaydırmada ivme.
  void _onImageZoomEnd(ScaleEndDetails d) {
    final pinch = _pinch;
    _pinch = 1;
    if (_resizing) {
      _resizing = false;
      final h = _live ?? _dragHeight;
      final cap = math.min(_dragMax, _dragNatural);
      final widen = pinch > 1 && h >= cap * 0.98;
      _redraw(() {
        _live = null;
        if (widen) _wholeImage = false;
      });
      widget.onHeightChanged(_clamp(widen ? cap : h, _dragMax));
      return;
    }
    final v = -d.velocity.pixelsPerSecond.dy;
    if (_imageScrolls && d.pointerCount <= 1 && v.abs() >= 60) {
      unawaited(
        _fling.animateWith(
          ClampingScrollSimulation(position: _imageScroll.offset, velocity: v),
        ),
      );
    }
  }

  void _onImageZoom() {
    final zoomed = _imageZoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _imageZoomed && mounted) {
      _redraw(() => _imageZoomed = zoomed);
    }
  }

  Widget _imageBubbleLayer(BubbleController bubbles) => LayoutBuilder(
    builder: (context, box) {
      final rect = _imageRect(box.biggest);
      if (rect == null) return const SizedBox.shrink();
      final own = identical(bubbles, _ownBubbles);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fromRect(
            rect: rect,
            child: BubblePageLayer(
              controller: bubbles,
              page: 1,
              readOnly: !own,
            ),
          ),
        ],
      );
    },
  );

  /// Genişliğe oturan görsel parmakla/fareyle kayar mı: yakınken pan,
  /// kalem parmakla çizerken çizim kazanır.
  bool get _imageScrolls =>
      _fitsWidth &&
      !_wholeImage &&
      !_imageZoomed &&
      (!_penOn || _policy.fingerScrolls);

  bool get _fitsWidth =>
      widget.media.kind == AttachmentKind.image &&
      !widget.shrinkToFit &&
      !widget.fill &&
      _mediaRatio != null;

  /// **GÖRSEL GENİŞLİĞE OTURUR** ([PinnedMediaPane.shrinkToFit] kapalı):
  /// görsel bölmenin genişliğinde doğal boyuyla dizilir, bölme daha kısaysa
  /// dikeyde kayar (PDF'teki gibi). Balon/çizim katmanları aynı kutuda —
  /// `contain` dikdörtgeni kutunun kendisi olur, koordinatlar bozulmaz.
  ///
  /// TEK widget (keyboard_jank_guard S17: klavye geçiş karesinde medya
  /// alt ağacı yeniden kuruluyor, bütçede pay yok): kaydırıcı widget yerine
  /// kaydırmayı boyamada uygulayan bir kutu ([FitWidthBox]); sürükleme
  /// medyanın VAR OLAN jest algılayıcısında.
  Widget _fitWidthImage(bool isImage, Widget child) {
    if (!_fitsWidth) return child;
    return FitWidthBox(
      key: ValueKey('pinned-image-scroll-${widget.media.id}'),
      ratio: _mediaRatio!,
      whole: _wholeImage,
      scroll: _imageScroll,
      // Kaydırma yalnız ötelemeyi değiştirir: görsel + çizim + balon
      // katmanı kendi katmanında kalır, her karede yeniden boyanmaz.
      child: RepaintBoundary(child: child),
    );
  }

  /// **PDF KÜÇÜLEREK SIĞAR** ([PinnedMediaPane.shrinkToFit] açık): sayfa bir
  /// sayfa boyunda dizilir, bölme kısaysa bütün sayfa görünecek kadar
  /// küçültülerek boyanır (isabet testi dönüşümden geçer: kalem ve balon
  /// doğru yere düşer). Kapalıyken (varsayılan) dokunulmaz.
  Widget _shrinkPdf(Widget child) {
    final ratio = _mediaRatio;
    if (!widget.shrinkToFit || ratio == null) return child;
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.maxHeight.isFinite || box.maxWidth <= 0) return child;
        final natural = box.maxWidth * ratio;
        return FittedBox(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: box.maxWidth,
            height: math.max(natural, box.maxHeight),
            child: child,
          ),
        );
      },
    );
  }

  /// Görsel + balonlar iki parmakla yakınlaşır; yakınken tek parmak gezdirir.
  Widget _zoomable({required bool enabled, required Widget child}) {
    if (!enabled) return child;
    return WheelScrollViewer(
      controller: _imageZoom,
      panEnabled: _imageZoomed,
      // Bütün görsel kipinde iki parmak içeriği değil BÖLMEYİ büyütür.
      scaleEnabled: !_wholeImage,
      onInteractionStart: _onImageZoomStart,
      onInteractionUpdate: _onImageZoomUpdate,
      onInteractionEnd: _onImageZoomEnd,
      child: child,
    );
  }

  void _onStage() {
    final stage = _watcher.stage.value;
    _keyboardN.value = (open: stage.open, estimate: stage.estimate);
    if (stage.closing != _closing) {
      _closing = stage.closing;
      if (_laid >= 0) _retarget(_laid, animate: true);
    }
  }

  /// Yerleşim boyu [laid] oldu: görünen boy olduğu yerden hedefe kayar.
  void _retarget(double laid, {required bool animate}) {
    final first = _laid < 0;
    final from = first ? 0.0 : _laid + _dy.value - laid;
    _laid = laid;
    final to = _closing ? math.max(0.0, _full - laid) : 0.0;
    if (first || !animate || (from - to).abs() < 0.5) {
      _slide.stop();
      _dyFrom = _dyTo = to;
      _dy.value = to;
      return;
    }
    if (_slide.isAnimating && to == _dyTo) return;
    _dyFrom = from;
    _dyTo = to;
    _slide
      ..duration = AppMotion.of(context, AppMotion.short)
      ..forward(from: 0);
  }

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
  double _visibleHeight(
    BuildContext context, {
    required double layout,
    required double available,
    required double stable,
  }) {
    if (!_keyboard.open) return layout;
    // KISA PENCERE + KLAVYE (F67.4: yatay tablet 640 − 300): medya en küçük
    // penceresinde, yazı alanı ≥ 200 dp kalsın.
    final window = MediaQuery.sizeOf(context);
    if (WindowClass.fromSize(
          Size(window.width, window.height - _keyboard.estimate),
          web: kIsWeb,
        ).height ==
        WindowHeight.short) {
      return math.min(layout, kPinnedVisibleFloor);
    }
    // Gövde henüz kısalmadıysa (klavye açılıyor) kalacak yer tahminle
    // hesaplanır; kısaldıysa gerçek ölçü zaten elde.
    //
    // ZIPLAMA (kullanıcı bulgusu 2026-10-20: "klavye açılınca çubuk önce
    // yukarı gidiyor, sonra hafif alta iniyor"): klavye kapalıyken alt
    // çubuğun altında gezinme çubuğu payı var, oturunca yok (bkz.
    // KeyboardSlide) — gövde klavyenin TAMAMI kadar değil, gezinme payı
    // EKSİK kısalıyor. Tahmin de o kadar eksik düşülmeli; yoksa pencere önce
    // pay kadar fazla daralıp oturunca geri açılıyordu.
    final settled = stable - available > 40;
    final nav = MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    final room = settled
        ? available
        : available - math.max(0.0, _keyboard.estimate - nav);
    final fit = room - kPinnedBarHeight - kPinnedNoteMinHeight;
    return math.min(layout, math.max(kPinnedVisibleFloor, fit));
  }


  /// **HER EK VİDEO GİBİ OTURUR** (kullanıcı isteği 2026-11-05: "tüm
  /// eklerde YouTube videoları gibi kolay oto sığdırma, sabitlendiğinde"):
  /// medyanın bölme genişliğindeki doğal boyu için oran (yükseklik /
  /// genişlik). Video ve sunum ölçüsüz de 16:9; görsel ölçüsü biliniyorsa;
  /// PDF ilk sayfanın oranı (döndürme dahil). Metin ve seste null (doğal
  /// boy yok).
  /// Bölmenin oranı: ekte kayıtlıysa o, ölçüsüz görselde yoklanan oran
  /// ([probeImageRatio]; gelene dek null = sınırsız, eski davranış).
  double? get _mediaRatio {
    final known = _fitRatio(widget.media);
    if (known != null) return known;
    if (widget.media.kind != AttachmentKind.image) return null;
    if (_probedFor != widget.media.id) _probeRatio();
    return _probedFor == widget.media.id ? _probedRatio : null;
  }

  void _probeRatio() {
    final media = widget.media;
    _probedFor = media.id;
    _probedRatio = null;
    unawaited(
      probeImageRatio(media).then((r) {
        if (!mounted || r == null || _probedFor != media.id) return;
        // Uç oranlar (şerit/panorama hatası) sınır koymasın.
        if (r < 0.05 || r > 20) return;
        _redraw(() => _probedRatio = r);
      }),
    );
  }


  void _fit() {
    final target = _fitTarget;
    if (target == null) return;
    widget.onHeightChanged(target);
  }

  bool get _unpinArmed =>
      (_live != null && _live! < kPinnedUnpinHeight) ||
      (_pulling && _pullDown > 96);

  Widget _buildPinnedPane(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVideo = widget.media.kind == AttachmentKind.video;
    final isPdf = widget.media.kind == AttachmentKind.pdf;
    final isText = widget.media.kind == AttachmentKind.text;
    final isAudio = widget.media.kind == AttachmentKind.audio;
    // Zamanlı medya: denetim çubuğu ve ilerleme çizgisi (video + ses).
    final timed = isVideo || isAudio;
    final background = isVideo ? Colors.black : scheme.surfaceContainerHigh;
    // BİR KEZ KURULUR (P49): medya, çubuk ve not `build`'de kurulur; klavye
    // gövdeyi kısaltıp `LayoutBuilder` yeniden koşunca AYNI örnekler döner,
    // alt ağaçlar yeniden kurulmaz (S17 geçiş karesi).
    //
    // NOT AÇILIŞI HAFİF (kullanıcı bulgusu 2026-10-20: "notu açarken ufak
    // donma"): oynatıcı/belge görüntüleyicisi rota geçişi bitince kurulur
    // (bkz. AfterRouteTransition).
    final media = RepaintBoundary(
      child: AfterRouteTransition(
        placeholder: ColoredBox(color: background),
        child: _media(context),
      ),
    );
    // Yazarken not AĞAÇTA kalır (durumu, imleci korunur) ama yer kaplamaz
    // ve çizilmez; çubuk kalkar.
    final lower = RepaintBoundary(
      child: Column(
        children: [
          if (!_writing) _bar(context, timed: timed),
          Expanded(child: Offstage(offstage: _writing, child: widget.child)),
        ],
      ),
    );
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
        // VİDEO EKRANA TAM OTURUR (kullanıcı isteği 2026-10-20: "16:9
        // alanında sağda solda boşluk kalmayacak şekilde"): bölme videonun
        // genişlikteki doğal boyunu AŞMAZ — saklı yükseklik ondan büyükse
        // (eski sabitleme, başka ekran) yanlarda kara pay kalıyordu.
        // 2026-11-05: görsel ve sunum da aynı kuralla — yanlarda boş pay
        // kalmaz. PDF bölmede genişliğe oturup dikeyde kaydığından sınır
        // değil, yalnız "Sığdır" hedefi (bir sayfa boyu).
        final ratio = _mediaRatio;
        final capped = ratio != null && !isPdf;
        final natural = capped
            ? constraints.maxWidth * ratio
            : double.infinity;
        _fitTarget = ratio == null
            ? null
            : _clamp(constraints.maxWidth * ratio, layoutMax);
        // Sürüklerken bölme sınırın altına da iner (geri bırakma hissi);
        // bırakınca sınıra oturur ya da sayfaya döner.
        // Yanda: medya sütunun tamamı; klavye açılınca yeniden ölçülmez,
        // yalnız pencere kırpılır (bkz. KeyboardClipWindow).
        final fillFull = math.max(
          0.0,
          math.max(stable, constraints.maxHeight) - kPinnedBarHeight,
        );
        final height = widget.fill
            ? fillFull
            : live != null
            ? live.clamp(0.0, max < kPinnedMinHeight ? kPinnedMinHeight : max)
            : _clamp(math.min(widget.media.pinHeight, natural), layoutMax);
        // Evreye bağlı: pencere dinleyicisinde, o anki evreyle hesaplanır.
        double visible() => widget.fill
            ? math.max(0.0, constraints.maxHeight - kPinnedBarHeight)
            : live != null
            ? height
            : _visibleHeight(
                context,
                layout: height,
                available: constraints.maxHeight,
                stable: stable,
              );
        // Canlandırmasız kare yalnız bu kurulumun İLK çizimi içindir.
        var snap = _takeSnap();
        // Balon yazılırken medya bölmenin TAMAMI (bkz. [_writing]).
        final writing = _writing && constraints.maxHeight.isFinite;
        _dragHeight = height;
        _dragMax = max;
        _dragNatural = natural;
        return Column(
          children: [
            ValueListenableBuilder<KeyboardPhase>(
              valueListenable: _keyboardN,
              child: media,
              builder: (_, _, media) {
                // Balon yazılırken medya bölmenin TAMAMI (bkz. [_writing]).
                final full = writing ? constraints.maxHeight : height;
                final laid = writing ? full : math.min(full, visible());
                _full = full;
                _retarget(laid, animate: live == null && !writing && !snap);
                snap = false;
                return SizedBox(
                  key: const ValueKey('pinned-media-window'),
                  height: laid,
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: full,
                    maxHeight: full,
                    child: ClipRect(
                      clipper: _WindowClip(laid, _dy),
                      child: ColoredBox(
                        color: background,
                        child: Flow(
                          delegate: _FitFlow(
                            laid: laid,
                            full: full,
                            dy: _dy,
                            // Görsel/video/sunum klavye açılınca KIRPILMAZ,
                            // küçülür (kullanıcı isteği 2026-10-20); metin,
                            // belge ve ses kartı okunur kalsın diye kırpılır.
                            shrink: !isText && !isPdf && !isAudio,
                          ),
                          children: [media!],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Flow(delegate: _shift, children: [lower]),
            ),
          ],
        );
      },
    );
    return layout;
  }

  /// Bölmenin içi: türüne göre okuyucu / oynatıcı / belge / görsel.

  /// AYRAÇ ÇUBUĞU: dikey sürükleme bölmeyi boyutlar; düğmeler de BURADA
  /// (kullanıcı bulgusu 2026-10-11: medyanın üstüne konan düğmeler YouTube
  /// oynatıcısının kendi sağ üst düğmeleriyle üst üste geliyordu). Çubuk
  /// medyanın DIŞINDA, hiçbir şeyi örtmez.
  Widget _bar(BuildContext context, {required bool timed}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
              key: const ValueKey('pinned-media-bar'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: widget.fill
                  ? null
                  : (_) => _redraw(() => _live = _dragHeight),
              onVerticalDragUpdate: widget.fill
                  ? null
                  : (d) =>
                        _redraw(() => _live = (_live ?? _dragHeight) + d.delta.dy),
              onVerticalDragEnd: widget.fill ? null : (_) {
                final raw = _live ?? _dragHeight;
                _redraw(() => _live = null);
                if (raw < kPinnedUnpinHeight) {
                  widget.onUnpin();
                } else {
                  widget.onHeightChanged(_clamp(math.min(raw, _dragNatural), _dragMax));
                }
              },
              onVerticalDragCancel: () => _redraw(() => _live = null),
              child: Container(
                height: kPinnedBarHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: PdfReadStyle.barColor(scheme),
                  border: Border(
                    top: PdfReadStyle.barLine(scheme),
                    bottom: BorderSide(color: AppTokens.of(context).hairline),
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
            );
  }

  void _toggleShrink() {
    if (_shrinkActive) {
      if (_wholeImage) _redraw(() => _wholeImage = false);
      if (widget.shrinkToFit) widget.onShrinkToFitChanged?.call(false);
    } else {
      widget.onShrinkToFitChanged?.call(true);
    }
  }

  /// Son çizilen çubuk genişliği: döndür düğmesi çubukta mı menüde mi.

  Future<void> _openSmartActions() => showPinnedSmartActionsSheet(
    context,
    onOcr: widget.onExtractText,
    onSummarize: widget.onSmartSummarize,
    onExtractTasks: widget.onSmartTasks,
    onAreaAsk: _effectiveAreaAsk,
  );

  /// **PANELDEKİ KALEM ↔ YÜZEN DÜĞME TAM SENKRON** (P49 (b)).
  ///
  /// KÖK NEDEN: düğme yalnız `!penActive` iken çiziliyordu — yüzen düğme
  /// editörün kalem kipini açınca paneldeki KAYBOLUYORDU; kalemli cihazda ise
  /// `autoStylus` açık olduğundan `_policy.layerActive` zaten `true` idi ve
  /// düğmeye basınca normal kalem tepsisi açılmak yerine otomatik kalem
  /// kapanıyordu. Artık editör `onPenOn` verdiyse kapalıyken HEP editörün
  /// normal kalem tepsisini açar, açıkken kapatır; tek başına (test/gömülü)
  /// kullanıldığında bölmenin kendi hızlı kalemini açıp kapatır.
  void _togglePen() {
    if (widget.onPenOn != null) {
      if (!widget.penActive) {
        if (!InkToolMemory.autoStylus) InkToolMemory.saveAutoStylus(true);
        widget.onPenOn!();
        return;
      }
      widget.onPenOff?.call();
      if (_ownPen) _redraw(() => _ownPen = false);
      return;
    }
    final on = _policy.layerActive;
    _redraw(() => _ownPen = !on);
    if (on) {
      if (widget.penActive) widget.onPenOff?.call();
      if (InkToolMemory.stylusEver && InkToolMemory.autoStylus) {
        InkToolMemory.saveAutoStylus(false);
      }
    } else if (!InkToolMemory.autoStylus) {
      InkToolMemory.saveAutoStylus(true);
    }
  }

  /// **HIZLI KALEM** (P49 (c): "paneldeki kalem açılınca silgili hızlı kalem
  /// menüsü"). Bölmenin kendi kalemi açıkken (editörün kalem tepsisi yokken)
  /// çubuğun solu kalem araçlarına döner: silgi · hızlı renkler · geri al ·
  /// yinele · kalem ayarları. Araç seçimi ortak (`InkToolMemory`).
  bool get _penTools => _ownPen && !widget.penActive && _canPen;

  Widget _penQuickTools(BuildContext context) => PinnedPenQuickTools(
    ink: _inkFor(widget.media),
    wideBar: _wideBar,
  );

}
