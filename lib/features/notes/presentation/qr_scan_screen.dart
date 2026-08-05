import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/link_text.dart';

/// Okunan kod bir adresse kullanıcının seçtiği eylem.
enum _QrAction { open, save, cancel }

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

class _QrScanScreenState extends State<QrScanScreen>
    with WidgetsBindingObserver {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Denetleyici ELLE verildiği için mobile_scanner yaşam döngüsünü kendisi
  /// yönetmiyor: ekran açıkken uygulama arka plana düşerse kamera + barkod
  /// çözümleyici çalışmaya devam ediyordu (pil + gizlilik).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Okunan kodu sonuçlandırır. Kod bir adresse önce ne yapılacağı sorulur:
  /// QR kodların çoğu linktir ve kullanıcı genelde siteye gitmek ister —
  /// eskiden tek yol adresi nota yazmaktı, açmak için elle kopyalamak
  /// gerekiyordu.
  Future<void> _finish(String value) async {
    if (_handled || value.trim().isEmpty) return;
    _handled = true;
    final code = value.trim();
    final url = soleLink(code);
    if (url == null) {
      if (mounted) Navigator.of(context).pop(code);
      return;
    }
    final action = await _askLinkAction(url);
    if (!mounted) return;
    if (action == _QrAction.open) {
      final opened = await openLink(url);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
        return;
      }
      // Link açıldı: not oluşturulmaz, tarayıcı kapanır.
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(action == _QrAction.save ? code : null);
  }

  /// Adres bulundu penceresi. Kapatılamaz (isDismissible: false): yarım
  /// durumda kalıp aynı kodun bir daha okunmamasını (noDuplicates) önler —
  /// üç seçenekten biri mutlaka seçilir.
  Future<_QrAction?> _askLinkAction(String url) {
    final l10n = context.l10n;
    return showModalBottomSheet<_QrAction>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.qrLinkFound, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                url,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, _QrAction.open),
                icon: const Icon(Icons.open_in_new),
                label: Text(l10n.qrOpenLink),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(sheetContext, _QrAction.save),
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.qrSaveToNote),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, _QrAction.cancel),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
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
