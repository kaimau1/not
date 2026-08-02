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
  const DrawingScreen({super.key});

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

  @override
  void dispose() {
    _ink.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_ink.ink.isEmpty) {
      Navigator.pop(context);
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
      InkPainter(_ink.ink, _page).paint(canvas, size);

      final image = await recorder.endRecording().toImage(
        (size.width * scale).round(),
        (size.height * scale).round(),
      );
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drawingTitle),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton.tonalIcon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.addToNote),
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
              child: InkPageLayer(controller: _ink, page: _page),
            ),
          ),
          // Geri al / temizle araç çubuğunun içinde; başlıkta ayrıca durmasına
          // gerek yok (PDF üstü çizimle aynı düzen).
          InkToolbar(controller: _ink),
        ],
      ),
    );
  }
}
