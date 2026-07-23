import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../editor/drawing_screen.dart' show kInkPalette;

/// Uygulama içi PDF görüntüleyici. Yerel kopya varsa onu, yoksa Storage
/// indirme adresini kullanır.
///
/// [onChanged] verilirse sayfaların üzerine elle yazma/çizme açılır: çizimler
/// PDF dosyasına gömülmez, ekin `ink` alanında sayfa oranlı vektör olarak
/// saklanır (not ile birlikte Firestore'a gider) — bu yüzden her açılışta
/// yeniden düzenlenebilir, silinebilir.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.attachment, this.onChanged});

  final Attachment attachment;

  /// null ise salt görüntüleme (ör. dışa aktarma önizlemesi): çizim kapalı.
  final ValueChanged<Attachment>? onChanged;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late List<InkStroke> _ink = [...widget.attachment.ink];
  bool _editing = false;
  bool _eraser = false;
  bool _dirty = false;
  Color _color = kInkPalette.first;

  /// Ekrandaki (yakınlaştırılmış) sayfa üzerinde piksel cinsinden kalınlık;
  /// kaydedilirken sayfa genişliğinin oranına çevrilir.
  double _widthPx = 3;

  /// Silginin çizgiye "değmiş" sayıldığı yarıçap (sayfa genişliğinin oranı).
  static const _eraseRadius = 0.02;

  void _save() {
    if (!_dirty) return;
    _dirty = false;
    widget.onChanged?.call(widget.attachment.copyWith(ink: _ink));
  }

  void _startStroke(int page, Offset local, Size pageSize) {
    if (_eraser) {
      _eraseAt(page, local, pageSize);
      return;
    }
    setState(() {
      _dirty = true;
      _ink = [
        ..._ink,
        InkStroke(
          page: page,
          color: _color.toARGB32(),
          width: _widthPx / pageSize.width,
          points: [local.dx / pageSize.width, local.dy / pageSize.height],
        ),
      ];
    });
  }

  void _extendStroke(int page, Offset local, Size pageSize) {
    if (_eraser) {
      _eraseAt(page, local, pageSize);
      return;
    }
    final last = _ink.last;
    final x = local.dx / pageSize.width;
    final y = local.dy / pageSize.height;
    // Çok yakın noktalar atlanır: hem çizim yumuşar hem de Firestore'a giden
    // nokta listesi (dolayısıyla not dokümanı) şişmez.
    final n = last.points.length;
    if (math.max(
          (last.points[n - 2] - x).abs(),
          (last.points[n - 1] - y).abs(),
        ) <
        0.002) {
      return;
    }
    setState(() => last.points.addAll([x, y]));
  }

  void _eraseAt(int page, Offset local, Size pageSize) {
    final x = local.dx / pageSize.width;
    final y = local.dy / pageSize.height;
    final kept = <InkStroke>[];
    for (final s in _ink) {
      var hit = false;
      if (s.page == page) {
        for (var i = 0; i < s.points.length; i += 2) {
          if ((s.points[i] - x).abs() < _eraseRadius &&
              (s.points[i + 1] - y).abs() < _eraseRadius) {
            hit = true;
            break;
          }
        }
      }
      if (!hit) kept.add(s);
    }
    if (kept.length == _ink.length) return;
    setState(() {
      _dirty = true;
      _ink = kept;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final attachment = widget.attachment;
    final hasLocal =
        attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync();

    final params = PdfViewerParams(
      // Metin seçimi açık: kullanıcı PDF içindeki yazıyı seçip kopyalayabilsin
      // (madde 2 — önceden PDF salt görüntüydü, içeriğe erişilemiyordu).
      // Çizim modunda kapalı: seçim katmanı parmak hareketini kapıyor.
      enableTextSelection: !_editing,
      pageOverlaysBuilder: (context, pageRect, page) => [
        Positioned.fill(
          child: IgnorePointer(
            // Çizim kapalıyken katman dokunmayı geçirir: PDF normal kayar,
            // yakınlaşır. Açıkken parmağı bu katman yakalar.
            ignoring: !_editing,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) =>
                  _startStroke(page.pageNumber, d.localPosition, pageRect.size),
              onPanUpdate: (d) => _extendStroke(
                page.pageNumber,
                d.localPosition,
                pageRect.size,
              ),
              onPanEnd: (_) => _save(),
              child: CustomPaint(
                painter: _InkPainter(_ink, page.pageNumber),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );

    Widget viewer;
    if (hasLocal) {
      viewer = PdfViewer.file(attachment.localPath, params: params);
    } else if (attachment.isUploaded) {
      viewer = PdfViewer.uri(Uri.parse(attachment.downloadUrl), params: params);
    } else {
      viewer = const Center(
        child: Icon(Icons.picture_as_pdf_outlined, size: 64),
      );
    }

    return PopScope(
      // Ekrandan çıkarken son çizim kaydedilmemişse kaydedilir (parmak
      // hareketiyle geri gidiş dahil).
      onPopInvokedWithResult: (_, _) => _save(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(attachment.fileName, style: const TextStyle(fontSize: 14)),
          actions: [
            if (widget.onChanged != null)
              IconButton(
                tooltip: _editing ? l10n.annotateDone : l10n.annotate,
                isSelected: _editing,
                icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                onPressed: () => setState(() {
                  _editing = !_editing;
                  if (!_editing) _save();
                }),
              ),
          ],
        ),
        body: viewer,
        bottomNavigationBar: _editing ? _toolbar(l10n) : null,
      ),
    );
  }

  Widget _toolbar(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Material(
        color: scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.pen,
                    isSelected: !_eraser,
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => _eraser = false),
                  ),
                  IconButton(
                    tooltip: l10n.eraser,
                    isSelected: _eraser,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    onPressed: () => setState(() => _eraser = true),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.undo,
                    icon: const Icon(Icons.undo),
                    onPressed: _ink.isEmpty
                        ? null
                        : () => setState(() {
                            _dirty = true;
                            _ink = _ink.sublist(0, _ink.length - 1);
                            _save();
                          }),
                  ),
                  IconButton(
                    tooltip: l10n.clearInk,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _ink.isEmpty
                        ? null
                        : () => setState(() {
                            _dirty = true;
                            _ink = [];
                            _save();
                          }),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final color in kInkPalette)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() {
                          _color = color;
                          _eraser = false;
                        }),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: !_eraser && _color == color
                                  ? scheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Slider(
                      value: _widthPx,
                      min: 1,
                      max: 12,
                      onChanged: (v) => setState(() => _widthPx = v),
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
}

/// Bir sayfanın üzerindeki çizgileri, sayfa oranından ekran boyutuna
/// ölçekleyerek çizer.
class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes, this.page);

  final List<InkStroke> strokes;
  final int page;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.page != page) continue;
      final paint = Paint()
        ..color = Color(s.color)
        ..strokeWidth = s.width * size.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 2) {
        canvas.drawCircle(
          Offset(s.points[0] * size.width, s.points[1] * size.height),
          s.width * size.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()
        ..moveTo(s.points[0] * size.width, s.points[1] * size.height);
      for (var i = 2; i < s.points.length; i += 2) {
        path.lineTo(s.points[i] * size.width, s.points[i + 1] * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) => true;
}
