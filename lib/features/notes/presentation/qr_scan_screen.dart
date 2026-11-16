import '../../../app/theme/app_tokens.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/link_text.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../../core/friendly_error.dart';

/// Okunan kod bir adresse kullanıcının seçtiği eylem.
enum _QrAction { open, save, cancel }

/// QR okuma yalnızca mobile_scanner'ın eklenti sağladığı platformlarda vardır
/// (Android/iOS/macOS). Web'de kullanılmıyor: menüde hiç görünmemesi için
/// çağıran her yer bunu sorar — çalışmayan bir düğme göstermektense.
bool get qrScanSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

/// QR/barkod okuma ekranını açar; okunan metni döndürür (iptalde null).
Future<String?> openQrScanner(BuildContext context) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScanScreen()),
    );

/// Birleşik "Tara" ekranının sonucu: belge taraması istendi ya da QR okundu.
@immutable
class ScanAnyOutcome {
  const ScanAnyOutcome.document() : code = null;
  const ScanAnyOutcome.qr(String this.code);

  /// Okunan QR metni; belge istendiyse null.
  final String? code;

  bool get document => code == null;
}

/// Belge düğmesinin ekrandan dönüş işareti (rota sonucu `Object`).
const _documentRequested = #scanDocument;

/// **TARA — BELGE + QR** (kullanıcı isteği 2026-11-16: "belge tara ve QR da
/// birleşsin, oto algılasın; taranan belgede QR varsa karışmamalı").
/// Kamera açılır, QR kendiliğinden tanınır ama ekranı KAPATMAZ: altta
/// "QR kod bulundu" kartı belirir, kullanmak bir dokunuş. Belge için "Belge
/// tara" belge tarayıcısını açar — üzerinde QR olan bir belge böylece QR
/// akışına kaçmaz; taranan sayfalarda QR hiç aranmaz.
Future<ScanAnyOutcome?> openScanAny(BuildContext context) async {
  final result = await Navigator.of(context).push<Object>(
    MaterialPageRoute<Object>(
      builder: (_) => const QrScanScreen(document: true),
    ),
  );
  if (result == _documentRequested) return const ScanAnyOutcome.document();
  if (result is String) return ScanAnyOutcome.qr(result);
  return null;
}

/// Kameradan ya da galerideki bir fotoğraftan QR/barkod okur.
///
/// İki yol tek ekranda: kamera önizlemesi sürekli tarar, alttaki düğme ise
/// galeriden seçilen görseli [MobileScannerController.analyzeImage] ile
/// çözer — kod ekrandaysa (WhatsApp'tan gelen bir görsel gibi) kamerayı
/// başka bir ekrana tutmak gerekmez.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.document = false});

  /// Birleşik kip (bkz. [openScanAny]): okunan QR ekranı kapatmaz, kart
  /// olarak önerilir; "Belge tara" düğmesi var.
  final bool document;

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

  /// Birleşik kipte görülen son QR (kart); null = yok.
  final _found = ValueNotifier<String?>(null);

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
    _found.dispose();
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
        ).showMessage(context.l10n.linkOpenFailed);
        return;
      }
      // Link açıldı: not oluşturulmaz, tarayıcı kapanır.
      Navigator.of(context).pop();
      return;
    }
    if (action == _QrAction.save) {
      Navigator.of(context).pop(code);
      return;
    }
    // Vazgeç: "bu kodu boş ver, taramaya devam et" demek — ekranı komple
    // kapatmak değil. Kilit açılmazsa (_handled) bir daha hiçbir kod
    // okunmuyordu; kullanıcı yanlış kodu okutup vazgeçince akışa baştan
    // girmek zorunda kalıyordu.
    _handled = false;
  }

  /// Adres bulundu penceresi. Kapatılamaz (isDismissible: false): yarım
  /// durumda kalıp aynı kodun bir daha okunmamasını (noDuplicates) önler —
  /// üç seçenekten biri mutlaka seçilir.
  Future<_QrAction?> _askLinkAction(String url) {
    final l10n = context.l10n;
    return showAppSheet<_QrAction>(
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
          ..showMessage(context.l10n.qrNotFound);
      } else {
        unawaited(_finish(code));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showMessage(context.l10n.qrScanFailed(friendlyError(context.l10n, e)));
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
        title: Text(widget.document ? l10n.scanAny : l10n.qrScanTitle),
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
              if (code == null) return;
              // Birleşik kipte QR yalnız ÖNERİLİR: belge taranırken
              // üzerindeki QR akışı kaçırmasın.
              if (widget.document) {
                _found.value = code.trim();
              } else {
                _finish(code);
              }
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.qrScanFailed(friendlyError(l10n, error)),
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
                  borderRadius: BorderRadius.circular(AppRadius.l),
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
                    if (widget.document)
                      ValueListenableBuilder<String?>(
                        valueListenable: _found,
                        builder: (context, code, _) => code == null
                            ? const SizedBox.shrink()
                            : _FoundCard(
                                code: code,
                                onUse: () => _finish(code),
                              ),
                      ),
                    Text(
                      widget.document ? l10n.scanAnyHint : l10n.qrScanHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    if (widget.document) ...[
                      FilledButton.icon(
                        key: const ValueKey('scan-any-document'),
                        onPressed: () =>
                            Navigator.of(context).pop(_documentRequested),
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: Text(l10n.newScanNote),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: _analyzing ? null : _fromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l10n.qrFromPhoto),
                      ),
                    ] else
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

/// Birleşik kipte okunan QR'ın önerisi: metnin başı + "QR'ı kullan".
class _FoundCard extends StatelessWidget {
  const _FoundCard({required this.code, required this.onUse});

  final String code;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        key: const ValueKey('scan-any-qr-card'),
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Icon(Icons.qr_code_2, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.scanQrFound, style: theme.textTheme.titleSmall),
                    Text(
                      code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('scan-any-use-qr'),
                onPressed: onUse,
                child: Text(l10n.scanUseQr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
