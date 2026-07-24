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

  Widget _image(BuildContext context, Attachment img) => _ImageBox(img: img);

  /// Seçili görselin işlem çubuğu: genişlik kaydırıcısı + tam ekran + metni al
  /// (OCR) + sil. Tuvalin altına sabitlenir.
  Widget _toolbar(BuildContext context, Attachment img) {
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
      child: _ImageTools(
        wFrac: wFrac,
        minWidthFrac: _minWidthFrac,
        onWidthChanged: (v) => setState(() {
          _resizeId = img.id;
          _resizeWFrac = v;
        }),
        onWidthEnd: (v) {
          widget.onChanged(img.copyWith(displayWidth: v));
          setState(() {
            _resizeId = null;
            _resizeWFrac = null;
          });
        },
        onExtractText: widget.onExtractText == null
            ? null
            : () => widget.onExtractText!(img),
        onFullscreen: () => _openViewer(img),
        onRemove: () => widget.onRemove(img),
      ),
    );
  }
}

/// Görsel ekin içeriği: yerel dosya → indirme adresi → yer tutucu sırasıyla.
class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.img});

  final Attachment img;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasLocal =
        img.localPath.isNotEmpty && File(img.localPath).existsSync();
    // Görseli EKRAN boyutunda çözdür: ekler 2048 px'e kadar saklanıyor ama
    // tuvalde ~300-400 px gösteriliyor; tam çözünürlükte decode etmek boşuna
    // bellek + işlemci (kaydırma takılması) demekti.
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final targetWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null;
        if (hasLocal) {
          return Image.file(
            File(img.localPath),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: targetWidth,
          );
        } else if (img.isUploaded) {
          return CachedNetworkImage(
            imageUrl: img.downloadUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: targetWidth,
          );
        }
        return Container(
          color: scheme.surfaceContainerHigh,
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        );
      },
    );
  }
}

/// Seçili görselin işlem çubuğu içeriği (genişlik kaydırıcısı + OCR + tam
/// ekran + sil): küçük tuval ve tam sayfa katmanı ortak kullanır.
class _ImageTools extends StatelessWidget {
  const _ImageTools({
    required this.wFrac,
    required this.minWidthFrac,
    required this.onWidthChanged,
    required this.onWidthEnd,
    required this.onFullscreen,
    required this.onRemove,
    this.onExtractText,
  });

  final double wFrac;
  final double minWidthFrac;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onWidthEnd;
  final VoidCallback onFullscreen;
  final VoidCallback onRemove;
  final VoidCallback? onExtractText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Material(
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
                min: minWidthFrac,
                max: 1,
                onChanged: onWidthChanged,
                onChangeEnd: onWidthEnd,
              ),
            ),
            if (onExtractText != null)
              IconButton(
                tooltip: l10n.extractText,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.document_scanner_outlined, size: 20),
                onPressed: onExtractText,
              ),
            IconButton(
              tooltip: 'Tam ekran',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.fullscreen, size: 20),
              onPressed: onFullscreen,
            ),
            IconButton(
              tooltip: l10n.removeAttachment,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: scheme.error,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// Metin notunda görselleri (el yazısı çizimleri dahil — onlar da görsel
/// ektir) TÜM SAYFA üzerinde serbest katman olarak gösterir: [child]
/// (başlık + gövde metni) normal akışında durur, görseller üstünde yüzer ve
/// sayfayla birlikte kayar. Görsel metnin sağına/soluna, sayfanın istenen
/// yerine sürüklenebilir; kalan alana metin yazılır ("çerçeve içi" küçük
/// tuvalin kaldırdığı sınır).
///
/// Konum: yatay [Attachment.x] (sayfa genişliği oranı), dikey
/// [Attachment.pageY] (sayfa tepesinden dp — sayfa yüksekliği metinle
/// değiştiğinden oran değil mutlak değer). Sayfa, en alttaki görseli
/// kapsayacak kadar uzar; görsel aşağı sürüklendikçe büyür.
class NotePageCanvas extends StatefulWidget {
  const NotePageCanvas({
    super.key,
    required this.images,
    required this.child,
    required this.minHeight,
    required this.onRemove,
    required this.onChanged,
    this.onExtractText,
    this.onTapEmpty,
  });

  final List<Attachment> images;

  /// Sayfa içeriği (başlık, çipler, gövde metni). Görseller bunun üstünde.
  final Widget child;

  /// Sayfanın en az yüksekliği (görünür alan — boş nota da tam sayfa tuval).
  final double minHeight;

  final ValueChanged<Attachment> onRemove;
  final ValueChanged<Attachment> onChanged;
  final Future<void> Function(Attachment)? onExtractText;

  /// Boş alana dokununca (seçili görsel yokken) çağrılır — editör bununla
  /// gövde metnine odaklanır ("aşağıya dokun, yazmaya başla" davranışı).
  final VoidCallback? onTapEmpty;

  @override
  State<NotePageCanvas> createState() => _NotePageCanvasState();
}

class _NotePageCanvasState extends State<NotePageCanvas> {
  String? _selectedId;

  /// Taşıma sırasındaki canlı sol/üst (dp); bırakınca kaydedilir.
  String? _moveId;
  double? _moveLeft;
  double? _moveTop;

  /// Boyutlandırma sırasındaki canlı genişlik oranı; bırakınca kaydedilir.
  String? _resizeId;
  double? _resizeWFrac;

  static const double _minWidthFrac = 0.15;

  /// Eski küçük tuvalden gelen y oranını (0–1) dp'ye çevirirken kullanılan
  /// varsayılan tuval yüksekliği (eski tuvalin üst sınırı).
  static const double _legacyCanvasHeight = 440;

  void _select(String id) =>
      setState(() => _selectedId = _selectedId == id ? null : id);

  void _deselect() {
    if (_selectedId != null) setState(() => _selectedId = null);
  }

  double _defaultTop(int index) => 8.0 + index * 130.0;

  /// Görselin sayfadaki nihai yerleşimi (dp). Canlı taşıma/boyutlandırma
  /// değerleri öncelikli. Üst sınır 0'a kırpılır; alt sınır yok — sayfa uzar.
  ({double left, double top, double w, double h}) _resolve(
    Attachment img,
    int index,
    double cw,
  ) {
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? 0.5))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    final w = cw * wFrac;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : 1.0;
    final h = w / aspect;
    var left = (_moveId == img.id && _moveLeft != null)
        ? _moveLeft!
        : (img.x ?? 0.06) * cw;
    var top = (_moveId == img.id && _moveTop != null)
        ? _moveTop!
        : img.pageY ??
              (img.y != null ? img.y! * _legacyCanvasHeight : _defaultTop(index));
    left = left.clamp(0.0, (cw - w).clamp(0.0, cw)).toDouble();
    top = top < 0 ? 0.0 : top;
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
    if (widget.images.isEmpty) {
      // Görsel yokken katmanın görsel maliyeti olmasın; dokun-odaklan kalır.
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTapEmpty,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.minHeight),
          child: widget.child,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth;
        // Sayfa en alttaki görseli (+ araç çubuğu payı) kapsayacak kadar uzar.
        var maxBottom = 0.0;
        for (final (index, img) in widget.images.indexed) {
          final r = _resolve(img, index, cw);
          final bottom = r.top + r.h + 72;
          if (bottom > maxBottom) maxBottom = bottom;
        }
        final selected = _selectedId;
        Attachment? selectedImg;
        var selectedIndex = 0;
        for (final (index, img) in widget.images.indexed) {
          if (img.id == selected) {
            selectedImg = img;
            selectedIndex = index;
          }
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // İçerik: boş alana dokununca önce seçim kalkar, seçim yoksa
            // gövdeye odaklanılır (dokunuş metin alanına da düşer).
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_selectedId != null) {
                  _deselect();
                } else {
                  widget.onTapEmpty?.call();
                }
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: maxBottom > widget.minHeight
                      ? maxBottom
                      : widget.minHeight,
                ),
                child: widget.child,
              ),
            ),
            for (final (index, img) in widget.images.indexed)
              _positioned(context, img, index, cw),
            if (selectedImg != null)
              _toolbar(context, selectedImg, selectedIndex, cw),
          ],
        );
      },
    );
  }

  Widget _positioned(
    BuildContext context,
    Attachment img,
    int index,
    double cw,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final editing = _selectedId == img.id;
    final r = _resolve(img, index, cw);
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.w,
      height: r.h,
      child: GestureDetector(
        onTap: () => _select(img.id),
        // Taşıma yalnız seçiliyken; aksi hâlde dikey kaydırma sayfaya kalır.
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
                final nt = (_moveTop ?? r.top) + d.delta.dy;
                _moveTop = nt < 0 ? 0.0 : nt;
              })
            : null,
        onPanEnd: editing
            ? (_) {
                final nl = _moveLeft ?? r.left;
                final nt = _moveTop ?? r.top;
                widget.onChanged(img.copyWith(x: nl / cw, pageY: nt));
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
                  child: _ImageBox(img: img),
                ),
              ),
            ),
            // Sağ-alt köşe tutamağı: serbest boyutlandırma (yalnız seçiliyken).
            if (editing)
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  onPanStart: (_) => setState(() {
                    _resizeId = img.id;
                    _resizeWFrac = (img.displayWidth ?? 0.5)
                        .clamp(_minWidthFrac, 1.0)
                        .toDouble();
                  }),
                  onPanUpdate: (d) => setState(() {
                    final base = (_resizeWFrac ?? (img.displayWidth ?? 0.5));
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

  /// Araç çubuğu seçili görselin hemen altında belirir (sayfa uzun olduğundan
  /// alta sabitlemek görünmez kalabilirdi).
  Widget _toolbar(
    BuildContext context,
    Attachment img,
    int index,
    double cw,
  ) {
    final r = _resolve(img, index, cw);
    final wFrac =
        ((_resizeId == img.id && _resizeWFrac != null)
                ? _resizeWFrac!
                : (img.displayWidth ?? 0.5))
            .clamp(_minWidthFrac, 1.0)
            .toDouble();
    return Positioned(
      left: 8,
      right: 8,
      top: r.top + r.h + 6,
      child: _ImageTools(
        wFrac: wFrac,
        minWidthFrac: _minWidthFrac,
        onWidthChanged: (v) => setState(() {
          _resizeId = img.id;
          _resizeWFrac = v;
        }),
        onWidthEnd: (v) {
          widget.onChanged(img.copyWith(displayWidth: v));
          setState(() {
            _resizeId = null;
            _resizeWFrac = null;
          });
        },
        onExtractText: widget.onExtractText == null
            ? null
            : () => widget.onExtractText!(img),
        onFullscreen: () => _openViewer(img),
        onRemove: () => widget.onRemove(img),
      ),
    );
  }
}
