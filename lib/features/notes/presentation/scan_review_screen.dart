import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../data/scan/doc_edges.dart';
import '../data/scan/perspective.dart';
import '../data/scan/scan_enhance.dart';
import '../data/scan/scan_deskew.dart';
import '../data/scan/scan_ocr.dart';
import '../data/scan/scan_pdf.dart';
import '../data/scan/scan_title.dart';
import 'scan_edit_screen.dart';

/// İnceleme ekranının sonucu: sayfalar ya tek (aranabilir) PDF'e dönüştü
/// ya da düzeltilmiş görseller olarak eklenecek.
class ScanReviewResult {
  const ScanReviewResult.pdf(this.pdfBytes, this.title) : imagePaths = null;

  const ScanReviewResult.images(this.imagePaths)
    : pdfBytes = null,
      title = null;

  /// Dolu ise sayfalar tek PDF oldu (varsa görünmez OCR metin katmanıyla).
  final Uint8List? pdfBytes;

  /// PDF için önerilen belge adı (OCR'daki en büyük puntolu üst satırdan;
  /// OCR yoksa null — çağıran damgalı ada düşer).
  final String? title;

  /// Dolu ise kullanıcı "görsel olarak ekle" dedi; düzeltilmiş sayfa yolları.
  final List<String>? imagePaths;
}

/// Tarama sonrası **önizleme/düzeltme** ekranı.
///
/// (dosya-okuyucu projesinden uyarlandı.) Sayfalar nota eklenmeden önce
/// burada görülür: yamuk sayfanın köşeleri düzeltilir, gereksiz sayfa atılır,
/// sayfa **netleştirilir** ve sonuç tek dokunuşla ya ARANABİLİR PDF eki ya da
/// görsel ekleri olur.
///
/// ## Netleştirme neden AÇILIŞTA uygulanıyor
/// Kullanıcı zaten "daha iyi taransın" istiyor; filtreyi menüye gömüp
/// beklemek isteği karşılamamak olurdu. Ekran açılırken tüm sayfalara
/// [ScanFilter.auto] uygulanır (gölge giderme + keskinleştirme, renk KORUNUR)
/// ve isteyen tek dokunuşla "Özgün"e döner. Özgün dosyalar korunur — filtre
/// yıkıcı değil.
class ScanReviewScreen extends StatefulWidget {
  const ScanReviewScreen({
    super.key,
    required this.pages,
    this.autoCrop = false,
  });

  final List<String> pages;

  /// true: sayfalar ham fotoğraf (galeriden/masaüstünden geldi) — açılışta
  /// kenarlar otomatik bulunup perspektif düzeltilir. ML Kit çıktısında
  /// false: tarayıcı kırpmayı zaten yaptı.
  final bool autoCrop;

  static Future<ScanReviewResult?> open(
    BuildContext context,
    List<String> pages, {
    bool autoCrop = false,
  }) {
    return Navigator.of(context).push<ScanReviewResult>(
      MaterialPageRoute(
        builder: (_) => ScanReviewScreen(pages: pages, autoCrop: autoCrop),
      ),
    );
  }

  @override
  State<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends State<ScanReviewScreen> {
  /// Gösterilen (filtre uygulanmış olabilir) sayfa yolları.
  late final List<String> _pages = List.of(widget.pages);

  /// Filtrenin uygulanacağı KAYNAK. Filtre değiştirildiğinde zincirleme
  /// uygulama olmaz: keskinleştirilmiş bir görseli tekrar keskinleştirmek
  /// sayfayı gürültüye boğuyordu. Köşe düzeltme/döndürme yapılınca bu da
  /// güncellenir (o işlem sonucu yeni "özgün"dür).
  late final List<String> _sources = List.of(widget.pages);

  /// Sayfa başına seçili filtre.
  late final List<ScanFilter> _filters = List.filled(
    widget.pages.length,
    ScanFilter.auto,
    growable: true,
  );

  final _controller = PageController();
  int _index = 0;
  bool _busy = false;

  /// Açılıştaki toplu hazırlığın ilerlemesi (null = bitti).
  int? _preparing;

  /// PDF üretimi sürerken gösterilen durum metni (null = üretim yok).
  String? _exporting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAll());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Açılışta bütün sayfalar hazırlanır: otomatik kenar bulma + perspektif
  /// düzeltme, ardından varsayılan netleştirme filtresi.
  ///
  /// Ham fotoğrafta ([ScanReviewScreen.autoCrop]) kenar NE bulunursa
  /// kırpılır; ML Kit çıktısında ise sayfa çoğunlukla kırpık gelir ama eğik
  /// kalabilir — o yüzden **temkinli** kendiliğinden düzeltme koşar
  /// ([ScanDeskew.worthApplying]; dosya-okuyucu 2026-08-06 bulgusu). Emin
  /// değilse sayfaya dokunmaz, elle "Köşeleri ayarla" yolu hep açık.
  Future<void> _prepareAll() async {
    for (var i = 0; i < _pages.length; i++) {
      if (!mounted) return;
      setState(() => _preparing = i);
      if (widget.autoCrop) {
        await _autoCrop(i);
      } else {
        try {
          final straightened = await ScanDeskew.autoStraighten(_sources[i]);
          if (!mounted) return;
          if (straightened != null) {
            _sources[i] = straightened;
            setState(() => _pages[i] = straightened);
          }
        } catch (_) {
          // Düzeltme süs değil sigortadır: başarısızsa sayfa OLDUĞU GİBİ kalır.
        }
      }
      await _applyFilter(i, ScanFilter.auto, silent: true);
    }
    if (mounted) setState(() => _preparing = null);
  }

  /// Ham fotoğrafta kâğıdın kenarlarını bulup sayfayı düzleştirir; kenar
  /// bulunamazsa fotoğraf olduğu gibi kalır (uydurma dörtgen, dörtgen
  /// olmamasından kötüdür — kullanıcı köşe ekranından elle düzeltebilir).
  Future<void> _autoCrop(int index) async {
    try {
      final source = _sources[index];
      final bytes = await File(source).readAsBytes();
      final corners = await compute(_detectCorners, bytes);
      if (corners == null || !mounted) return;
      final image = await decodeImageFile(source);
      try {
        final png = await Perspective.warpToPng(image, [
          for (final c in corners) Offset(c.x, c.y),
        ]);
        final path = await writeTempPng(source, 'otokirp', png);
        if (!mounted) return;
        _sources[index] = path;
        setState(() => _pages[index] = path);
      } finally {
        image.dispose();
      }
    } catch (_) {
      // Kenar bulma en iyi çabadır; düşerse ham fotoğrafla devam edilir.
    }
  }

  /// Kullanıcının dokunduğu filtreyi uygular. Dokunulur dokunulmaz çip
  /// seçili işaretlenir (iyimser) ve ilerleme görünür — sessiz bekleyiş
  /// "dokunuşum kaydedilmedi" hissi veriyordu (dosya-okuyucu bulgusu).
  Future<void> _chooseFilter(int index, ScanFilter filter) async {
    if (_busy || _preparing != null) return;
    final previous = _filters[index];
    setState(() {
      _busy = true;
      _filters[index] = filter;
    });
    final ok = await _applyFilter(index, filter);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!ok) _filters[index] = previous;
    });
  }

  /// [index] sayfasına [filter] uygular. Kaynak hep `_sources[index]`.
  Future<bool> _applyFilter(
    int index,
    ScanFilter filter, {
    bool silent = false,
  }) async {
    final source = _sources[index];
    if (filter == ScanFilter.original) {
      if (!mounted) return false;
      setState(() {
        _filters[index] = filter;
        _pages[index] = source;
      });
      return true;
    }
    try {
      final target = await ScanEnhance.tempTarget(source, filter);
      final produced = await compute(
        ScanEnhance.runRequest,
        ScanEnhanceRequest(
          sourcePath: source,
          targetPath: target,
          filter: filter,
        ),
      );
      if (!mounted) return false;
      setState(() {
        _filters[index] = filter;
        _pages[index] = produced;
      });
      return true;
    } catch (e) {
      if (!mounted || silent) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.genericError('$e'))));
      return false;
    }
  }

  Future<void> _editCorners() async {
    // Köşe düzeltme ÖZGÜN sayfa üzerinde yapılır: filtre uygulanmış (örneğin
    // siyah-beyaza indirgenmiş) bir görseli kırpıp sonra tekrar filtrelemek
    // kaliteyi iki kez düşürürdü.
    final edited = await ScanEditScreen.open(context, _sources[_index]);
    if (edited == null || !mounted) return;
    final index = _index;
    _sources[index] = edited;
    setState(() {
      _pages[index] = edited;
      _busy = true;
    });
    await _applyFilter(index, _filters[index]);
    if (mounted) setState(() => _busy = false);
  }

  /// Geçerli sayfayı 90° saat yönünde çevirir (yeni dosyaya yazılır).
  Future<void> _rotate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final index = _index;
    final source = _sources[index];
    try {
      final image = await decodeImageFile(source);
      try {
        final png = await Perspective.rotateToPng(image, 1);
        final path = await writeTempPng(source, 'donduruldu', png);
        if (!mounted) return;
        _sources[index] = path;
        setState(() => _pages[index] = path);
        await _applyFilter(index, _filters[index]);
      } finally {
        image.dispose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.genericError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removeCurrent() {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanLastPage)),
      );
      return;
    }
    setState(() {
      _pages.removeAt(_index);
      _sources.removeAt(_index);
      _filters.removeAt(_index);
      if (_index >= _pages.length) _index = _pages.length - 1;
    });
    _controller.jumpToPage(_index);
  }

  /// Geçerli sayfanın filtresini **tüm sayfalara** yayar.
  Future<void> _applyToAll() async {
    final filter = _filters[_index];
    setState(() => _busy = true);
    for (var i = 0; i < _pages.length; i++) {
      if (i == _index) continue;
      if (!mounted) return;
      setState(() => _preparing = i);
      await _applyFilter(i, filter, silent: true);
    }
    if (mounted) {
      setState(() {
        _preparing = null;
        _busy = false;
      });
    }
  }

  /// Sayfaları (varsa OCR katmanıyla) tek PDF'e çevirip sonuçla kapanır.
  ///
  /// OCR cihazda ve ücretsiz (ML Kit) — desteklenmeyen platformda (masaüstü)
  /// katmansız PDF üretilir, soru sorulmaz ("kullanıcıya bir şey bırakma").
  Future<void> _finishAsPdf() async {
    final l10n = context.l10n;
    setState(() => _exporting = l10n.scanBuildingPdf);
    try {
      var ocr = const <List<OcrLine>>[];
      if (ScanOcr.supported) {
        ocr = await ScanOcr.recognizePages(
          _pages,
          onProgress: (done, total) {
            if (mounted && done < total) {
              setState(
                () => _exporting = l10n.scanOcrProgress(done + 1, total),
              );
            }
          },
        );
      }
      if (!mounted) return;
      setState(() => _exporting = l10n.scanBuildingPdf);
      final bytes = await ScanPdf.build(_pages, ocrLinesPerPage: ocr);
      final title = ocr.isEmpty ? null : suggestScanTitle(ocr.first);
      if (!mounted) return;
      Navigator.of(context).pop(ScanReviewResult.pdf(bytes, title));
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.genericError('$e'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preparing = _preparing;
    final exporting = _exporting;
    final locked = _busy || preparing != null || exporting != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.scanReviewPage(_index + 1, _pages.length)),
        actions: [
          IconButton(
            tooltip: l10n.scanRotatePage,
            icon: const Icon(Icons.rotate_right),
            onPressed: locked ? null : _rotate,
          ),
          IconButton(
            tooltip: l10n.scanDeletePage,
            icon: const Icon(Icons.delete_outline),
            onPressed: locked ? null : _removeCurrent,
          ),
        ],
      ),
      body: Column(
        children: [
          if (preparing != null)
            LinearProgressIndicator(
              value: _pages.isEmpty ? null : (preparing + 1) / _pages.length,
            )
          else if (_busy || exporting != null)
            const LinearProgressIndicator(),
          if (exporting != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                exporting,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    File(_pages[i]),
                    key: ValueKey(_pages[i]),
                    errorBuilder: (_, _, _) => Text(
                      l10n.scanPageFailed,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _filterRow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              l10n.scanCropHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: locked ? null : _editCorners,
                      icon: const Icon(Icons.crop_free),
                      label: Text(l10n.scanAdjustCorners),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: locked
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(ScanReviewResult.images(_pages)),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(l10n.scanAddAsImages),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: locked ? null : _finishAsPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l10n.scanAddAsPdf),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Filtre seçimi — yatay kaydırmalı çip şeridi.
  Widget _filterRow() {
    final l10n = context.l10n;
    final current = _filters.isEmpty ? ScanFilter.auto : _filters[_index];
    String label(ScanFilter f) => switch (f) {
      ScanFilter.original => l10n.scanFilterOriginal,
      ScanFilter.auto => l10n.scanFilterAuto,
      ScanFilter.gray => l10n.scanFilterGray,
      ScanFilter.blackWhite => l10n.scanFilterBw,
    };
    final locked = _busy || _preparing != null || _exporting != null;
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final filter in ScanFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(filter)),
                selected: current == filter,
                // Seçili çipte çalışırken küçük gösterge: dokunuşun
                // kaydedildiği ve işin SÜRDÜĞÜ ilk anda görünür.
                avatar: _busy && current == filter
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onSelected: locked ? null : (_) => _chooseFilter(_index, filter),
              ),
            ),
          if (_pages.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.done_all, size: 18),
                label: Text(l10n.scanApplyAll),
                onPressed: locked ? null : _applyToAll,
              ),
            ),
        ],
      ),
    );
  }
}

/// İzole giriş noktası — üst düzey fonksiyon olmalı (`compute` kuralı).
List<({double x, double y})>? _detectCorners(Uint8List bytes) =>
    DocEdges.detect(bytes);
