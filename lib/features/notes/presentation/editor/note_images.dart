import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';

/// Notta gövdenin üstünde görselleri SERBEST TUVAL (canvas) olarak gösterir:
/// her görsel istenen yere sürüklenip serbest boyutlandırılabilir (madde 5 —
/// "boyut ve yer serbest olmalı"). Bir görsele dokununca seçilir; seçili
/// görsel sürüklenerek taşınır, sağ-alt tutamağından boyutlandırılır ve alttaki
/// araç çubuğundan genişlik/tam ekran/metni al (OCR)/sil işlemleri yapılır.
/// Boş bir alana dokununca seçim kalkar.
///
/// Konum [Attachment.x]/[Attachment.y] (tuval oranı 0–1), boyut ise
/// [Attachment.displayWidth] (tuval genişliğinin oranı) ile saklanır. Konumu
/// olmayan (eski) görseller otomatik sıralı yerleştirilir; kullanıcı taşıyınca
/// kalıcılaşır.
class NoteImages extends StatefulWidget {
  const NoteImages({
    super.key,
    required this.images,
    required this.onRemove,
    required this.onChanged,
    this.onExtractText,
  });

  final List<Attachment> images;

  /// Görseli nottan kaldırır.
  final ValueChanged<Attachment> onRemove;

  /// Konum/boyut değişince güncellenmiş eki bildirir.
  final ValueChanged<Attachment> onChanged;

  /// Görseldeki metni çıkarıp (OCR) nota ekler. null ise "Metni al" düğmesi
  /// gösterilmez.
  final Future<void> Function(Attachment)? onExtractText;

  @override
  State<NoteImages> createState() => _NoteImagesState();
}

class _NoteImagesState extends State<NoteImages> {
  /// Seçili (araç çubuğu açık) görselin id'si; null = seçim yok.
  String? _selectedId;

  /// Taşıma sırasındaki canlı sol/üst (piksel); bırakınca kaydedilir.
  String? _moveId;
  double? _moveLeft;
  double? _moveTop;

  /// Boyutlandırma sırasındaki canlı genişlik oranı; bırakınca kaydedilir.
  String? _resizeId;
  double? _resizeWFrac;

  static const double _minWidthFrac = 0.15;

  void _select(String id) {
    setState(() => _selectedId = _selectedId == id ? null : id);
  }

  void _deselect() {
    if (_selectedId != null) setState(() => _selectedId = null);
  }

  /// Konumu atanmamış görseller için otomatik başlangıç yerleşimi (sol-üst
  /// oranı). Üst üste binmesin diye indekse göre kaydırılır.
  double _defaultX(int index) => 0.06 + (index % 2) * 0.30;
  double _defaultY(int index) => 0.06 + (index ~/ 2) * 0.30;

  /// Bir görselin tuvaldeki nihai (sınırlar içine alınmış) yerleşimini çözer.
  /// Canlı taşıma/boyutlandırma değerleri varsa onları kullanır. Yükseklik
  /// tuvale sığmıyorsa oran korunarak küçültülür; kutu her zaman tuval içinde
  /// kalır.
  ({double left, double top, double w, double h}) _resolve(
    Attachment img,
    int index,
    double cw,
    double ch,
  ) {
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? 0.6))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    var w = cw * wFrac;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : 1.0;
    var h = w / aspect;
    if (h > ch) {
      h = ch;
      w = h * aspect;
      if (w > cw) {
        w = cw;
        h = w / aspect;
      }
    }
    final xFrac = img.x ?? _defaultX(index);
    final yFrac = img.y ?? _defaultY(index);
    var left = (_moveId == img.id && _moveLeft != null)
        ? _moveLeft!
        : xFrac * cw;
    var top = (_moveId == img.id && _moveTop != null) ? _moveTop! : yFrac * ch;
    left = left.clamp(0.0, (cw - w).clamp(0.0, cw)).toDouble();
    top = top.clamp(0.0, (ch - h).clamp(0.0, ch)).toDouble();
    return (left: left, top: top, w: w, h: h);
  }

  void _openViewer(Attachment img) {
    final hasLocal =
        img.localPath.isNotEmpty && File(img.localPath).existsSync();
    if (!hasLocal && !img.isUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.attachmentNotSynced)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewerScreen(attachment: img),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cw = constraints.maxWidth;
          // Tuval yüksekliği genişliğe bağlı ama sınırlı: dar ekranda kare-msi
          // bir çalışma alanı, geniş ekranda aşırı uzamaz.
          final ch = cw.clamp(220.0, 460.0).toDouble();
          final selected = _selectedId;
          Attachment? selectedImg;
          for (final img in widget.images) {
            if (img.id == selected) selectedImg = img;
          }
          return SizedBox(
            width: cw,
            height: ch,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Zemin: boş alana dokununca seçim kalkar; hafif çerçeveli
                // "tuval" görünümü verir.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _deselect,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final (index, img) in widget.images.indexed)
                  _positioned(context, img, index, cw, ch),
                if (selectedImg != null) _toolbar(context, selectedImg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _positioned(
    BuildContext context,
    Attachment img,
    int index,
    double cw,
    double ch,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final editing = _selectedId == img.id;
    final r = _resolve(img, index, cw, ch);
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.w,
      height: r.h,
      child: GestureDetector(
        onTap: () => _select(img.id),
        // Taşıma yalnız seçiliyken; aksi hâlde dikey kaydırma nota kalır.
        onPanStart: editing
            ? (_) => setState(() {
                _moveId = img.id;
                _moveLeft = r.left;
                _moveTop = r.top;
              })
            : null,
        onPanUpdate: editing
            ? (d) => setState(() {
                _moveLeft = ((_moveLeft ?? r.left) + d.delta.dx)
                    .clamp(0.0, (cw - r.w).clamp(0.0, cw))
                    .toDouble();
                _moveTop = ((_moveTop ?? r.top) + d.delta.dy)
                    .clamp(0.0, (ch - r.h).clamp(0.0, ch))
                    .toDouble();
              })
            : null,
        onPanEnd: editing
            ? (_) {
                final nl = _moveLeft ?? r.left;
                final nt = _moveTop ?? r.top;
                widget.onChanged(img.copyWith(x: nl / cw, y: nt / ch));
                setState(() {
                  _moveId = null;
                  _moveLeft = null;
                  _moveTop = null;
                });
              }
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: editing
                      ? Border.all(color: scheme.primary, width: 2)
                      : Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _image(context, img),
                ),
              ),
            ),
            // Sağ-alt köşe tutamağı: serbest boyutlandırma (yalnız seçiliyken).
            // Görsel sınırları İÇİNDE tutulur ki her yerde dokunulabilsin.
            if (editing)
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  onPanStart: (_) => setState(() {
                    _resizeId = img.id;
                    _resizeWFrac = (img.displayWidth ?? 0.6)
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                  }),
                  onPanUpdate: (d) => setState(() {
                    final base = (_resizeWFrac ?? (img.displayWidth ?? 0.6));
                    _resizeWFrac = (base + d.delta.dx / cw)
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                  }),
                  onPanEnd: (_) {
                    final f = _resizeWFrac;
                    if (f != null) {
                      widget.onChanged(img.copyWith(displayWidth: f));
                    }
                    setState(() {
                      _resizeId = null;
                      _resizeWFrac = null;
                    });
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.onPrimary, width: 2),
                    ),
                    child: Icon(
                      Icons.open_in_full,
                      size: 13,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _image(BuildContext context, Attachment img) {
    final scheme = Theme.of(context).colorScheme;
    final hasLocal =
        img.localPath.isNotEmpty && File(img.localPath).existsSync();
    if (hasLocal) {
      return Image.file(
        File(img.localPath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (img.isUploaded) {
      return CachedNetworkImage(
        imageUrl: img.downloadUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(
      color: scheme.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
    );
  }

  /// Seçili görselin işlem çubuğu: genişlik kaydırıcısı + tam ekran + metni al
  /// (OCR) + sil. Tuvalin altına sabitlenir.
  Widget _toolbar(BuildContext context, Attachment img) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? 0.6))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Material(
        color: scheme.surfaceContainerHighest,
        elevation: 3,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              Icon(Icons.photo_size_select_large, size: 18, color: scheme.primary),
              Expanded(
                child: Slider(
                  value: wFrac,
                  min: _minWidthFrac,
                  max: 1,
                  onChanged: (v) => setState(() {
                    _resizeId = img.id;
                    _resizeWFrac = v;
                  }),
                  onChangeEnd: (v) {
                    widget.onChanged(img.copyWith(displayWidth: v));
                    setState(() {
                      _resizeId = null;
                      _resizeWFrac = null;
                    });
                  },
                ),
              ),
              if (widget.onExtractText != null)
                IconButton(
                  tooltip: l10n.extractText,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.document_scanner_outlined, size: 20),
                  onPressed: () => widget.onExtractText!(img),
                ),
              IconButton(
                tooltip: 'Tam ekran',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.fullscreen, size: 20),
                onPressed: () => _openViewer(img),
              ),
              IconButton(
                tooltip: l10n.removeAttachment,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: scheme.error,
                onPressed: () => widget.onRemove(img),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
