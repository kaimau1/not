import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../viewers/ink_layer.dart';
import 'note_images.dart';
import 'pen_tray.dart';
import '../../../../core/friendly_error.dart';

/// El yazısı notu: beyaz bir tuvale çizilir, kaydedilirse PNG baytları döner
/// ve nota görsel eki olarak girer.
///
/// Tuval, çizgi modeli ve araç çubuğu PDF/slayt/görsel üstü çizimle AYNI
/// parçalardır ([InkController], [InkPageLayer], [InkToolbar]): kalem türleri,
/// renkler, kalınlık, silgi, geri al ve temizle iki yerde birden, tek bir
/// yerden gelir. Eskiden bu ekranın kendi küçük çizim motoru vardı ve PDF
/// tarafına eklenen seçenekler buraya gelmiyordu.
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key, this.background, this.saveLabel});

  /// **ÜZERİNE ÇİZİLECEK GÖRSEL** (kullanıcı isteği 2026-09-04: sohbette
  /// "gönderilirken üzerine çizme gibi işlevler olabilsin").
  ///
  /// Verilirse tuvalin zemini beyaz değil BU GÖRSEL olur; sonuç, görselin
  /// üstüne çizilmiş hâlidir. Hiç çizilmezse görselin KENDİSİ döner —
  /// "çiz" ekranına girip vazgeçen kullanıcı gönderisini kaybetmesin.
  final Uint8List? background;

  /// Onay düğmesinin yazısı (varsayılan: "Nota ekle"). Sohbette "Gönder".
  final String? saveLabel;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  /// Tek sayfalık çizim: [InkPageLayer] sayfa numarası ister, burada hep 1.
  static const _page = 1;

  /// Çizgiler yalnız bu ekranda yaşar (PNG'ye dönüştürülüp atılır), bu yüzden
  /// `onChanged` bir yere yazmaz.
  late final InkController _ink = InkController(
    initial: const [],
    onChanged: (_) {},
  )..setEditing(true);

  final _canvasKey = GlobalKey();

  /// Tuvalin yakınlaştırması (kullanıcı isteği 2026-10-23: "not içi zoom"):
  /// iki parmak yakınlaştırır/kaydırır, "yalnız kalem" açıkken tek parmak da
  /// kaydırır ([InkNavLayer]). Çizgiler tuvalin oranında saklandığından
  /// yakınlaştırma kaydı etkilemez; ince ayrıntı büyütülüp yazılır.
  final _zoom = ValueNotifier<Matrix4>(Matrix4.identity());
  bool _saving = false;

  /// Çözülmüş zemin görseli — yeniden çizimde ([_save]) gerekiyor: ekrandaki
  /// katmanı yakalamak yerine aynı sahne yeni bir tuvale kuruluyor.
  ui.Image? _background;

  /// Kayıt bir kez başarısız olduysa sonraki geri basışı KAYDETMEDEN çıkar:
  /// kalıcı bir hatada (bellek/kodlama) geri tuşu sonsuza dek başarısız
  /// kaydı yeniden dener, ekrandan çıkış yolu kalmazdı.
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    final bytes = widget.background;
    if (bytes != null) unawaited(_decodeBackground(bytes));
  }

  Future<void> _decodeBackground(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _background = frame.image);
    } catch (_) {
      // Çözülemeyen görselde ekran beyaz tuval olarak çalışmaya devam eder.
    }
  }

  @override
  void dispose() {
    _background?.dispose();
    _ink.dispose();
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ink.ink.isEmpty) {
      // Çizim yoksa zemin görselin KENDİSİ döner (varsa): "üzerine çiz"
      // ekranından hiçbir şey çizmeden çıkmak gönderiyi iptal etmemeli.
      Navigator.pop(context, widget.background);
      return;
    }
    setState(() => _saving = true);
    try {
      // Çizim, ekrandaki katmanı yakalayarak (RepaintBoundary.toImage) değil
      // AYNI painter'la yeni bir tuvale yeniden çizilerek üretilir.
      // Katman yakalama CanvasKit'te (web) ekranda görüneni birebir vermiyordu:
      // beyaz zemin geliyor, çizgiler gelmiyordu. Yeniden çizim platformdan ve
      // kare zamanlamasından bağımsız, sonuç her yerde aynı.
      final box = _canvasKey.currentContext!.findRenderObject()! as RenderBox;
      final size = box.size;
      const scale = 2.0; // Retina/yüksek DPI ekranlarda bulanık çıkmasın.

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(scale);
      // Zemin: ekrandaki tuval de beyaz. Şeffaf bırakılırsa JPEG'e
      // dönüştürülürken siyaha döner.
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      // Zemin görseli EKRANDAKİYLE AYNI oturur: `BoxFit.contain` matematiği
      // burada elle kuruluyor, çünkü sahne yeniden çiziliyor (yukarıdaki
      // gerekçe) ve `Image` widget'ının yerleşimi bu tuvale taşınmıyor.
      final image = _background;
      if (image != null) {
        final source = Size(image.width.toDouble(), image.height.toDouble());
        final fitted = applyBoxFit(BoxFit.contain, source, size);
        final destination = Alignment.center.inscribe(
          fitted.destination,
          Offset.zero & size,
        );
        canvas.drawImageRect(
          image,
          Offset.zero & source,
          destination,
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
      InkPainter(_ink.ink, _page).paint(canvas, size);

      final rendered = await recorder.endRecording().toImage(
        (size.width * scale).round(),
        (size.height * scale).round(),
      );
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      // `data.buffer.asUint8List()` (offset/uzunluk vermeden) TÜM arabelleği
      // döndürür — ByteData bir DİLİM ise PNG'nin sonuna çöp bayt eklenir.
      // Android'de toByteData tam arabellek verdiğinden fark edilmiyordu;
      // CanvasKit'te dilim geldiği için tarayıcı çizimi çözemiyor ve
      // "EncodingError: The source image cannot be decoded" hatası veriyordu.
      Navigator.pop(
        context,
        data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (e) {
      // Sessizce yutulursa kullanıcı "Nota ekle"ye basar, ekran kapanmaz ve
      // neden olduğunu anlamaz.
      if (!mounted) return;
      _saveFailed = true;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showMessage(context.l10n.attachmentFailed(friendlyError(context.l10n, e)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Geri tuşu/jesti dakikalarca süren çizimi ONAYSIZ siliyordu (kaydetme
    // yalnız "Nota ekle" düğmesindeydi; görüntü/PDF üstü çizim ise poplarken
    // kaydediyor). Tuval boş değilse geri = kaydet-ve-çık: çizim nota ek
    // olarak girer, istemeyen tek dokunuşla siler — kaybolan çizim geri
    // gelmez.
    //
    // YENİ GÖRÜNÜM (kullanıcı isteği 2026-10-28: "çizim ekranı görsel olarak
    // bütün, menüsü güzel olsun"): üstte yalnız geri · geri al · yinele · ⋮ ·
    // ✓, altta KALEM TEPSİSİ ([PenTray]) — araçlar simge değil tepside
    // duran kalemler; tuval ekranın tamamı.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        if (_saveFailed) {
          Navigator.pop(context);
          return;
        }
        _save();
      },
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor: scheme.surfaceContainerLow,
          scrolledUnderElevation: 0,
          leading: IconButton(
            tooltip: widget.saveLabel ?? l10n.addToNote,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _saving ? null : _save,
          ),
          actions: [
            ListenableBuilder(
              listenable: _ink,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.undo,
                    icon: const Icon(Icons.undo_rounded),
                    onPressed: _ink.canUndo ? _ink.undo : null,
                  ),
                  IconButton(
                    tooltip: l10n.redo,
                    icon: const Icon(Icons.redo_rounded),
                    onPressed: _ink.canRedo ? _ink.redo : null,
                  ),
                ],
              ),
            ),
            // Yakınlaştırılmışken tek dokunuşla tam görünüme dön.
            ValueListenableBuilder<Matrix4>(
              valueListenable: _zoom,
              builder: (context, m, _) => m.getMaxScaleOnAxis() > 1.01
                  ? IconButton(
                      tooltip: l10n.inkZoomReset,
                      icon: const Icon(Icons.zoom_out_map_rounded),
                      onPressed: () => _zoom.value = Matrix4.identity(),
                    )
                  : const SizedBox.shrink(),
            ),
            ListenableBuilder(
              listenable: _ink,
              builder: (context, _) => PopupMenuButton<String>(
                tooltip: l10n.more,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  switch (value) {
                    case 'penOnly':
                      _ink.setPenOnly(!_ink.penOnly);
                    case 'settings':
                      showModalBottomSheet<void>(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (_) => InkSettingsSheet(controller: _ink),
                      );
                    case 'clear':
                      _ink.clear();
                  }
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: 'penOnly',
                    checked: _ink.penOnly,
                    child: Text(l10n.inkPenOnlyOn),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tune_rounded),
                      title: Text(l10n.inkSettings),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    enabled: _ink.ink.isNotEmpty,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_sweep_outlined),
                      title: Text(l10n.clearInk),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4, end: 10),
              child: IconButton.filled(
                tooltip: widget.saveLabel ?? l10n.addToNote,
                // Üst çubuğun simge teması dolgulu düğmenin rengini ezmesin.
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                ),
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              // Tuval kâğıt gibi: kenarlarda ince pay, yuvarlak köşe, hafif
              // gölge — çevresindeki sakin zeminden ayrışır.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: InkNavLayer(
                      enabled: true,
                      controller: _ink,
                      getMatrix: () => _zoom.value,
                      setMatrix: (m) => _zoom.value = m,
                      minScale: 1,
                      maxScale: 6,
                      clampToBounds: true,
                      child: ValueListenableBuilder<Matrix4>(
                        valueListenable: _zoom,
                        builder: (context, m, child) =>
                            Transform(transform: m, child: child),
                        child: _canvas(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PenTray(controller: _ink),
          ],
        ),
      ),
    );
  }

  /// Beyaz tuval (+ varsa zemin görseli) ve çizim katmanı.
  Widget _canvas(BuildContext context) {
    return Container(
      key: _canvasKey,
      color: Colors.white,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.background != null)
            Image.memory(
              widget.background!,
              fit: BoxFit.contain,
              cacheWidth: decodeWidthBucket(
                MediaQuery.sizeOf(context).width,
                MediaQuery.devicePixelRatioOf(context),
              ),
            ),
          InkPageLayer(controller: _ink, page: _page),
        ],
      ),
    );
  }
}
