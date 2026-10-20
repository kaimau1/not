import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../data/attachment_repository.dart';
import '../../data/scan/recognized_text.dart';
import '../../data/scan/scan_ocr.dart';
import '../../domain/attachment.dart';
import '../editor/note_images.dart';

/// **Metni Tanı** — görseldeki yazıyı seçilebilir hâle getiren TEK ekran.
///
/// KÖK NEDEN (kullanıcı isteği 2026-08-09): metin tanıma uygulamada üç ayrı
/// yerden, üç ayrı davranışla çıkıyordu — sayfadaki görselin ⋮ menüsündeki
/// "Metni al" modele gidip **bütün metni doğrudan notun içine döküyordu**
/// (kullanıcı: "böyle olmaz, yine metni tanı ekranı gelmeli"), tam ekran
/// görüntüleyicide satır satır seçilen ayrı bir katman vardı, taranmış PDF
/// sayfasında ise bambaşka bir seçim motoru. Artık görselden metin isteyen
/// her yol BURAYA gelir: aynı görünüm, aynı jestler, aynı çıktı.
///
/// Ne yapar:
/// * Tanıma tamamen **cihaz içi** (ML Kit — bkz. [ScanOcr]): internet
///   gerekmez, AI puanı harcamaz.
/// * Seçim **karakter karakter** (bkz. [RecognizedText]): dokunmak sözcüğü
///   seçer, basılı tutup sürüklemek harf harf büyütür, iki uçtaki tutamaç
///   seçimi tek karakter hassasiyetinde ayarlar.
/// * Seçili metin panoya kopyalanır ya da (çağıran verdiyse) **nota eklenir**.
///
/// Dönüş değeri: kullanıcı "Nota ekle" dediyse eklenen metin, yoksa null.
class TextRecognizeScreen extends StatefulWidget {
  const TextRecognizeScreen({
    super.key,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    this.title,
    this.canInsert = false,
  });

  /// Tanınacak görselin YEREL dosya yolu (ML Kit dosya ister).
  final String imagePath;

  /// Görselin piksel ölçüleri — tanınan kutular bu uzayda geliyor.
  final int imageWidth;
  final int imageHeight;

  /// Üst barda görünen ad (ekin dosya adı gibi).
  final String? title;

  /// "Nota ekle" düğmesi çizilsin mi (not editöründen açıldıysa).
  final bool canInsert;

  @override
  State<TextRecognizeScreen> createState() => _TextRecognizeScreenState();
}

class _TextRecognizeScreenState extends State<TextRecognizeScreen> {
  RecognizedText _text = RecognizedText.empty;
  bool _busy = true;

  /// Seçim çapası ve ucu (karakter indeksi). Eşitse seçim yok.
  int _anchor = 0;
  int _extent = 0;

  /// TANINAN metnin tamamı aydınlık bir katmanla vurgulansın mı?
  ///
  /// Kullanıcı isteği 2026-08-16: "metin tanımada tanınan metinleri beyaz
  /// aydınlık vurgulama". Ekran görselin üstünde hiçbir iz bırakmıyordu:
  /// tanımanın hangi yazıyı gördüğü (ve hangisini kaçırdığı) ancak
  /// seçmeye çalışınca anlaşılıyordu. Beyaz yıkama karanlık zeminli
  /// belgelerde de okunur kalsın diye ince bir çerçeveyle birlikte çizilir.
  bool _highlightAll = true;

  /// Görselin ekrandaki ölçeği: 1 = genişliğe sığdır. Yakınlaştırma
  /// InteractiveViewer yerine ölçek düğmeleriyle yapılır — iç içe jest
  /// tanıyıcıları seçimi güvenilmez kılıyordu.
  double _zoom = 1;

  int get _start => math.min(_anchor, _extent);
  int get _end => math.max(_anchor, _extent);
  bool get _hasSelection => _end > _start;

  @override
  void initState() {
    super.initState();
    unawaited(_recognize());
  }

  Future<void> _recognize() async {
    setState(() => _busy = true);
    RecognizedText result;
    try {
      result = RecognizedText.fromWordLines(
        await ScanOcr.recognizeImageWordLines(widget.imagePath),
      );
    } catch (_) {
      result = RecognizedText.empty;
    }
    if (!mounted) return;
    setState(() {
      _text = result;
      _busy = false;
      _anchor = 0;
      _extent = 0;
    });
  }

  void _selectAll() => setState(() {
    _anchor = 0;
    _extent = _text.text.length;
  });

  void _clearSelection() => setState(() {
    _anchor = 0;
    _extent = 0;
  });

  /// Seçili metin; hiçbir şey seçili değilse TÜMÜ (kullanıcı çoğu zaman
  /// hepsini istiyor, boş seçimle düğmeye basmak sessizce hiçbir şey
  /// yapmasın).
  String get _effectiveText =>
      _hasSelection ? _text.textOf(_start, _end) : _text.text;

  Future<void> _copy() async {
    final text = _effectiveText.trim();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(context.l10n.copied);
  }

  void _insert() {
    final text = _effectiveText.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final aspect = widget.imageHeight <= 0
        ? 1.0
        : widget.imageWidth / widget.imageHeight;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.title?.trim().isNotEmpty == true
              ? widget.title!
              : l10n.imageOcrTitle,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          // Tanınan metnin aydınlık vurgusu açık/kapalı: fotoğrafın kendisini
          // net görmek gerektiğinde kapatılabilsin.
          IconButton(
            tooltip: _highlightAll
                ? l10n.imageOcrHideRecognized
                : l10n.imageOcrShowRecognized,
            isSelected: _highlightAll,
            onPressed: () => setState(() => _highlightAll = !_highlightAll),
            icon: Icon(
              _highlightAll ? Icons.highlight : Icons.highlight_outlined,
            ),
          ),
          IconButton(
            tooltip: l10n.imageOcrZoomOut,
            onPressed: _zoom <= 1
                ? null
                : () => setState(() => _zoom = math.max(1, _zoom - 0.5)),
            icon: const Icon(Icons.zoom_out),
          ),
          IconButton(
            tooltip: l10n.imageOcrZoomIn,
            onPressed: _zoom >= 4
                ? null
                : () => setState(() => _zoom = math.min(4, _zoom + 0.5)),
            icon: const Icon(Icons.zoom_in),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _busy
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.imageOcrWorking,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _text.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.imageOcrNone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Görsel genişliğe sığar; yakınlaştırma genişliği katlar ve
                // fazlası iki eksende kaydırılır.
                final width = constraints.maxWidth * _zoom;
                final height = width / aspect;
                return SingleChildScrollView(
                  // Seçim sürerken kaydırma KAPALI: parmak harf harf seçim
                  // yaparken sayfa da kaymasın (bkz. [_SelectLayer]).
                  physics: _dragging
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: _dragging
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.fill,
                              // Kutunun boyunda çöz (F5.2). Seçim katmanı
                              // görselin ÖLÇÜSÜNE (imageSize) göre oranlı
                              // çalışır, çözülen piksel boyuna bağlı değil.
                              cacheWidth: decodeWidthBucket(
                                width,
                                MediaQuery.devicePixelRatioOf(context),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: _SelectLayer(
                              text: _text,
                              highlightAll: _highlightAll,
                              imageSize: Size(
                                widget.imageWidth.toDouble(),
                                widget.imageHeight.toDouble(),
                              ),
                              start: _start,
                              end: _end,
                              accent: scheme.primary,
                              onDraggingChanged: (v) =>
                                  setState(() => _dragging = v),
                              onSelect: (a, b) => setState(() {
                                _anchor = a;
                                _extent = b;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _busy || _text.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _hasSelection
                                ? l10n.imageOcrCharsSelected(_end - _start)
                                : l10n.imageOcrSelectHint,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _hasSelection ? _clearSelection : _selectAll,
                          child: Text(
                            _hasSelection ? l10n.cancel : l10n.selectAllItems,
                          ),
                        ),
                      ],
                    ),
                    // CANLI OKUMA (kullanıcı isteği 2026-08-16: "seçilen
                    // metinde ne okunduğunu canlı görme"). Seçim sürerken
                    // parmağın altındaki harfler görselin üstünde kalıyor ve
                    // tanımanın onları NE OKUDUĞU görünmüyordu — el yazısı
                    // ya da düşük çözünürlüklü bir belgede asıl merak edilen
                    // tam olarak bu. Kutu SABİT yükseklikte: seçim büyüyüp
                    // küçülürken alt çubuk zıplamasın.
                    if (_hasSelection) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 64,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _text.textOf(_start, _end),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (widget.canInsert) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _insert,
                              icon: const Icon(Icons.note_add_outlined),
                              label: Text(l10n.imageOcrInsert),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                            ),
                            onPressed: _copy,
                            icon: const Icon(Icons.copy_outlined),
                            label: Text(l10n.copy),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Parmak o an seçim sürüklüyor mu — kaydırma bu sırada kilitlenir.
  bool _dragging = false;
}

/// Görselin üzerindeki seçim katmanı.
///
/// **Jest arenasına GİRMEZ** — yalnız [Listener] kullanır. Buraya bir
/// `GestureDetector` konsaydı, dıştaki kaydırma görünümleriyle arenada
/// yarışır ve ikisinden biri (çoğu zaman kaydırma) hep kaybederdi; uzun basış
/// bu yüzden elle ölçülüyor (zamanlayıcı + kayma toleransı). Aynı gerekçe
/// taranmış PDF katmanında da yazılı (bkz. `pdf_select_layer.dart`).
class _SelectLayer extends StatefulWidget {
  const _SelectLayer({
    required this.text,
    required this.highlightAll,
    required this.imageSize,
    required this.start,
    required this.end,
    required this.accent,
    required this.onSelect,
    required this.onDraggingChanged,
  });

  final RecognizedText text;

  /// Tanınan metnin TAMAMI aydınlık bir katmanla gösterilsin mi
  /// (bkz. `_TextRecognizeScreenState._highlightAll`).
  final bool highlightAll;

  final Size imageSize;
  final int start;
  final int end;
  final Color accent;

  /// (çapa, uç) — ikisi de karakter indeksi.
  final void Function(int anchor, int extent) onSelect;
  final ValueChanged<bool> onDraggingChanged;

  @override
  State<_SelectLayer> createState() => _SelectLayerState();
}

class _SelectLayerState extends State<_SelectLayer> {
  static const _longPress = Duration(milliseconds: 320);

  /// Parmağın "kıpırdamadı" sayılacağı en büyük kayma.
  static const _slop = 14.0;

  /// Tutamacın dokunma yarıçapı — 24 dp, Material'ın en küçük hedefi.
  static const _handleTouch = 24.0;

  Timer? _timer;
  Offset? _downAt;

  /// Sürükleyerek seçim sürüyor mu ve hangi ucu taşıyoruz.
  bool _dragging = false;
  bool _movingStart = false;

  /// Sürükleme sırasında sabit kalan uç.
  int _fixed = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setDragging(bool value) {
    if (_dragging == value) return;
    _dragging = value;
    widget.onDraggingChanged(value);
  }

  /// Ekran (yerel) noktasını GÖRÜNTÜ PİKSEL uzayına çevirir.
  Offset _toImage(Offset local, Size box) => Offset(
    local.dx * widget.imageSize.width / box.width,
    local.dy * widget.imageSize.height / box.height,
  );

  /// Görüntü pikselini ekrana çevirir (tutamaç ve vurgu çizimi).
  Rect _toScreen(Rect r, Size box) => Rect.fromLTRB(
    r.left * box.width / widget.imageSize.width,
    r.top * box.height / widget.imageSize.height,
    r.right * box.width / widget.imageSize.width,
    r.bottom * box.height / widget.imageSize.height,
  );

  int _charAt(Offset local, Size box) {
    final p = _toImage(local, box);
    return widget.text.nearestChar(p.dx, p.dy);
  }

  /// Dokunulan nokta seçim tutamaçlarından birine mi denk geliyor?
  /// (-1 yok, 0 baş, 1 son)
  int _handleAt(Offset local, Size box) {
    if (widget.end <= widget.start) return -1;
    final rects = widget.text.selectionRects(widget.start, widget.end);
    if (rects.isEmpty) return -1;
    final first = _toScreen(rects.first, box);
    final last = _toScreen(rects.last, box);
    final startPoint = Offset(first.left, first.bottom);
    final endPoint = Offset(last.right, last.bottom);
    if ((local - startPoint).distance <= _handleTouch) return 0;
    if ((local - endPoint).distance <= _handleTouch) return 1;
    return -1;
  }

  void _extendTo(Offset local, Size box) {
    final index = _charAt(local, box);
    if (index < 0) return;
    // Uç DAHİL seçilsin: parmağın üstündeki harf de seçimin içinde kalmalı.
    final extent = _movingStart ? index : index + 1;
    widget.onSelect(_fixed, extent);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = Size(constraints.maxWidth, constraints.maxHeight);
        final rects = widget.end > widget.start
            ? [
                for (final r in widget.text.selectionRects(
                  widget.start,
                  widget.end,
                ))
                  _toScreen(r, box),
              ]
            : const <Rect>[];
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _downAt = event.localPosition;
            final handle = _handleAt(event.localPosition, box);
            if (handle >= 0) {
              // Tutamaç: uzun basış beklemeden hemen sürüklemeye başla.
              _movingStart = handle == 0;
              _fixed = handle == 0 ? widget.end : widget.start;
              _setDragging(true);
              return;
            }
            _timer?.cancel();
            _timer = Timer(_longPress, () {
              if (!mounted || _downAt == null) return;
              HapticFeedback.selectionClick();
              final index = _charAt(_downAt!, box);
              if (index < 0) return;
              final (s, e) = widget.text.wordAt(index);
              _movingStart = false;
              _fixed = s;
              widget.onSelect(s, e);
              _setDragging(true);
            });
          },
          onPointerMove: (event) {
            final down = _downAt;
            if (!_dragging) {
              // Parmak kaydıysa uzun basış iptal: kullanıcı sayfayı kaydırmak
              // istiyor.
              if (down != null && (event.localPosition - down).distance > _slop) {
                _timer?.cancel();
                _downAt = null;
              }
              return;
            }
            _extendTo(event.localPosition, box);
          },
          onPointerUp: (event) {
            _timer?.cancel();
            final down = _downAt;
            _downAt = null;
            if (_dragging) {
              _setDragging(false);
              return;
            }
            // Kısa dokunuş: altındaki SÖZCÜĞÜ seç (yoksa seçimi bırak).
            if (down == null ||
                (event.localPosition - down).distance > _slop) {
              return;
            }
            final index = _charAt(event.localPosition, box);
            if (index < 0) return;
            final (s, e) = widget.text.wordAt(index);
            widget.onSelect(s, e);
          },
          onPointerCancel: (_) {
            _timer?.cancel();
            _downAt = null;
            _setDragging(false);
          },
          child: CustomPaint(
            painter: _SelectionPainter(
              rects: rects,
              // Tanınan metnin tamamı: seçim kutularıyla AYNI birleştirme
              // yolundan geçer (satır satır), böylece iki katman birbirine
              // birebir oturur.
              recognized: widget.highlightAll
                  ? [
                      for (final r in widget.text.selectionRects(
                        0,
                        widget.text.text.length,
                      ))
                        _toScreen(r, box),
                    ]
                  : const <Rect>[],
              accent: widget.accent,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

/// Seçim vurgusu + iki uçtaki tutamaç.
class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.rects,
    required this.recognized,
    required this.accent,
  });

  final List<Rect> rects;

  /// Tanınan METNİN TAMAMI (seçili olsun olmasın). Seçim kutularının ALTINA
  /// çizilir: seçilen bölge vurgulu renkte, geri kalan tanınan metin soluk
  /// beyaz kalır.
  final List<Rect> recognized;

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // Tanınan metnin aydınlık katmanı (kullanıcı isteği 2026-08-16).
    if (recognized.isNotEmpty) {
      final wash = Paint()..color = Colors.white.withValues(alpha: 0.28);
      final edge = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (final r in recognized) {
        final rr = RRect.fromRectAndRadius(
          r.inflate(1),
          const Radius.circular(2),
        );
        canvas
          ..drawRRect(rr, wash)
          ..drawRRect(rr, edge);
      }
    }
    if (rects.isEmpty) return;
    final fill = Paint()..color = accent.withValues(alpha: 0.35);
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final r in rects) {
      final rr = RRect.fromRectAndRadius(r.inflate(1), const Radius.circular(2));
      canvas
        ..drawRRect(rr, fill)
        ..drawRRect(rr, stroke);
    }
    // Tutamaçlar: seçimin ilk kutusunun sol-altı ve son kutusunun sağ-altı.
    final knob = Paint()..color = accent;
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final p in [
      Offset(rects.first.left, rects.first.bottom),
      Offset(rects.last.right, rects.last.bottom),
    ]) {
      canvas
        ..drawCircle(p, 8, knob)
        ..drawCircle(p, 8, ring);
    }
  }

  @override
  bool shouldRepaint(_SelectionPainter old) =>
      old.accent != accent ||
      old.recognized.length != recognized.length ||
      old.rects.length != rects.length ||
      (rects.isNotEmpty && old.rects.first != rects.first) ||
      (rects.isNotEmpty && old.rects.last != rects.last);
}

/// Tanıma için bir ekin YEREL dosya yolu: ek zaten cihazdaysa onun yolu,
/// değilse baytlar geçici bir dosyaya yazılır (ML Kit yalnız dosya okur).
///
/// Görselin piksel ölçüsü de gerekli — tanınan kutular o uzayda geliyor;
/// ölçüsü bilinmeyen (çok eski) ekte tanıma yapılamaz, null döner.
Future<String?> recognizableImagePath(
  Attachment image,
  AttachmentRepository? repo,
) async {
  if ((image.width ?? 0) <= 0 || (image.height ?? 0) <= 0) return null;
  if (image.localPath.isNotEmpty && localFileExists(image.localPath)) {
    return image.localPath;
  }
  final bytes = await repo?.readBytes(image);
  if (bytes == null) return null;
  try {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'ocr_${image.id}.jpg'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}
