import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../viewers/ink_layer.dart';

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
        final source = Size(
          image.width.toDouble(),
          image.height.toDouble(),
        );
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
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.attachmentFailed('$e'))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Geri tuşu/jesti dakikalarca süren çizimi ONAYSIZ siliyordu (kaydetme
    // yalnız "Nota ekle" düğmesindeydi; görüntü/PDF üstü çizim ise poplarken
    // kaydediyor). Tuval boş değilse geri = kaydet-ve-çık: çizim nota ek
    // olarak girer, istemeyen tek dokunuşla siler — kaybolan çizim geri
    // gelmez.
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
      appBar: AppBar(
        title: Text(l10n.drawingTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton.tonalIcon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(widget.saveLabel ?? l10n.addToNote),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              key: _canvasKey,
              color: Colors.white,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.background != null)
                    Image.memory(widget.background!, fit: BoxFit.contain),
                  InkPageLayer(controller: _ink, page: _page),
                ],
              ),
            ),
          ),
          // Geri al / temizle araç çubuğunun içinde; başlıkta ayrıca durmasına
          // gerek yok (PDF üstü çizimle aynı düzen).
          InkToolbar(controller: _ink),
        ],
      ),
      ),
    );
  }
}
