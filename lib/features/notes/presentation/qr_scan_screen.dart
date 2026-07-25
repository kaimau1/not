import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n_ext.dart';

/// QR okuma yalnızca mobile_scanner'ın eklenti sağladığı platformlarda vardır
/// (Android/iOS/macOS). Windows'ta eklenti yok: menüde hiç görünmemesi için
/// çağıran her yer bunu sorar — çalışmayan bir düğme göstermektense.
bool get qrScanSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

/// QR/barkod okuma ekranını açar; okunan metni döndürür (iptalde null).
Future<String?> openQrScanner(BuildContext context) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScanScreen()),
    );

/// Kameradan ya da galerideki bir fotoğraftan QR/barkod okur.
///
/// İki yol tek ekranda: kamera önizlemesi sürekli tarar, alttaki düğme ise
/// galeriden seçilen görseli [MobileScannerController.analyzeImage] ile
/// çözer — kod ekrandaysa (WhatsApp'tan gelen bir görsel gibi) kamerayı
/// başka bir ekrana tutmak gerekmez.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  /// noDuplicates: aynı kod saniyede onlarca kez yakalanıyor; ilk okumada
  /// ekranı kapatacağımız için tekrarları motora hiç ürettirmiyoruz.
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// Tek sonuç kuralı: kamera ile galeri aynı anda sonuç döndürebilir; ilk
  /// gelen kazanır, ikinci pop çağrısı ekranı iki kez kapatmasın.
  bool _handled = false;
  bool _torchOn = false;
  bool _analyzing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String value) {
    if (_handled || value.trim().isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(value.trim());
  }

  /// Yakalanan kodlardan ilk anlamlı metni döndürür (yoksa null).
  String? _firstValue(BarcodeCapture? capture) {
    for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Işığı olmayan/açılmayan kamera: sessizce geç, tarama sürüyor.
    }
  }

  Future<void> _fromGallery() async {
    if (_analyzing) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() => _analyzing = true);
    try {
      final code = _firstValue(await _controller.analyzeImage(picked.path));
      if (!mounted) return;
      if (code == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.qrNotFound)));
      } else {
        _finish(code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.qrScanFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(l10n.qrScanTitle),
        actions: [
          IconButton(
            tooltip: l10n.qrTorch,
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = _firstValue(capture);
              if (code != null) _finish(code);
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.qrScanFailed('$error'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          // Nişangâh: kodu nereye tutması gerektiğini gösterir.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_analyzing)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.qrScanHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _analyzing ? null : _fromGallery,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(l10n.qrFromPhoto),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
