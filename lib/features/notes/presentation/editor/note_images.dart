import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../domain/attachment.dart';
import '../viewers/image_viewer.dart';
import '../viewers/ink_layer.dart';
import 'text_wrap.dart';

/// Görseli tam ekran açar (yoksa "henüz senkronlanmadı" der). Tam ekranda
/// görselin üzerine elle yazılabilir; çizim [onChanged] ile ekin `ink`
/// alanına döner.
void openImageViewer(
  BuildContext context,
  Attachment img,
  ValueChanged<Attachment> onChanged, {
  Future<void> Function(Attachment, Rect)? onCrop,
}) {
  final hasLocal = localFileExists(img.localPath);
  if (!hasLocal && !img.isUploaded) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.attachmentNotSynced)));
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ImageViewerScreen(
        attachment: img,
        onChanged: onChanged,
        onCrop: onCrop,
      ),
    ),
  );
}

/// Görsel ekin içeriği: yerel dosya → indirme adresi → yer tutucu sırasıyla.
/// Tam ekranda görselin üzerine yazılan çizim (ekin `ink` alanı) burada da
/// çizilir — yoksa çizim "kaybolmuş" görünürdü. Kutunun en-boy oranı görselin
/// oranıyla aynı tutulduğu için oranlı noktalar birebir oturur.
class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.img, this.fit = BoxFit.cover});

  final Attachment img;

  /// Tuvalde `cover` (kutuyu doldurur), büyük önizlemede `contain`
  /// (görselin tamamı görünsün — önizlemenin amacı bu).
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (img.ink.isEmpty) return _content(context);
    return Stack(
      children: [
        Positioned.fill(child: _content(context)),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: InkPainter(img.ink, 1)),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // build sıcak yolunda senkron stat yapmamak için önbellekli denetim.
    final hasLocal = localFileExists(img.localPath);
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
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: targetWidth,
          );
        } else if (img.isUploaded) {
          return CachedNetworkImage(
            imageUrl: img.downloadUrl,
            fit: fit,
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
    this.onCopy,
    this.onDetach,
  });

  final double wFrac;
  final double minWidthFrac;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onWidthEnd;
  final VoidCallback onFullscreen;
  final VoidCallback onRemove;
  final VoidCallback? onExtractText;

  /// Görseli panoya kopyalar (uygulama içi ek panosu + sistem panosu).
  final VoidCallback? onCopy;

  /// Görseli sayfadan alıp alt şeritte DOSYA eki yapar.
  final VoidCallback? onDetach;

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
            Icon(
              Icons.photo_size_select_large,
              size: 18,
              color: scheme.primary,
            ),
            Expanded(
              child: Slider(
                value: wFrac,
                min: minWidthFrac,
                max: 1,
                onChanged: onWidthChanged,
                onChangeEnd: onWidthEnd,
              ),
            ),
            IconButton(
              tooltip: l10n.fullscreen,
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
            // Seyrek kullanılan işlemler menüde: hepsi ayrı düğme olsaydı
            // çubuk dar ekranda kaydırıcıya yer bırakmazdı. Hiçbiri
            // verilmemişse düğme de çizilmez (boş menü açılışta patlar).
            if (onExtractText != null || onCopy != null || onDetach != null)
              PopupMenuButton<String>(
                tooltip: l10n.more,
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case 'ocr':
                      onExtractText?.call();
                    case 'copy':
                      onCopy?.call();
                    case 'detach':
                      onDetach?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (onExtractText != null)
                    PopupMenuItem(
                      value: 'ocr',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.document_scanner_outlined),
                        title: Text(l10n.extractText),
                      ),
                    ),
                  if (onCopy != null)
                    PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.copy_outlined),
                        title: Text(l10n.copy),
                      ),
                    ),
                  if (onDetach != null)
                    PopupMenuItem(
                      value: 'detach',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attachment_outlined),
                        title: Text(l10n.moveImageToAttachments),
                      ),
                    ),
                ],
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
/// İpucunun oturacağı yükseklik: gövdenin ilk satırı ([bodyTop]), onu kesen
/// görsel bantlarının altına itilmiş hâli.
///
/// Bantlar yukarıdan aşağı taranır ve tek geçiş yeter: ipucu her itilişte
/// aşağı gider, itildikten sonra o bandı bir daha kesemez, sıradaki bantlar
/// ise zaten daha aşağıdadır. Kesişme yoksa sonuç [bodyTop]'tur — yani
/// görselsiz notta ipucu her zamanki yerinde kalır.
@visibleForTesting
double hintTopFor(List<FloatBox> floats, double bodyTop, double lineHeight) {
  final sorted = [...floats]..sort((a, b) => a.top.compareTo(b.top));
  var y = bodyTop;
  for (final f in sorted) {
    if (f.top < y + lineHeight && y < f.bottom) y = f.bottom;
  }
  return y;
}

class NotePageCanvas extends StatefulWidget {
  const NotePageCanvas({
    super.key,
    required this.images,
    required this.child,
    required this.minHeight,
    required this.onRemove,
    required this.onChanged,
    this.onCrop,
    this.onExtractText,
    this.onCopy,
    this.onDetach,
    this.onTapEmpty,
    this.topLimit = 0,
    this.onFloats,
    this.hint,
    this.hintLineHeight = 0,
  });

  final List<Attachment> images;

  /// Sayfa içeriği (başlık, çipler, gövde metni). Görseller bunun üstünde.
  final Widget child;

  /// Görsellerin inebileceği en üst nokta (dp) — başlık ve çip satırının
  /// altı. Görsel başlığın üzerine hiç çıkamaz. Gövde metninin ilk satırının
  /// tepesi de burasıdır ([hint] bu noktadan aşağı itilir).
  final double topLimit;

  /// Boş gövdenin ipucu metni ("Not yaz…"), tuval üzerinde konumlandırılır.
  ///
  /// KÖK NEDEN: ipucu metin değil dekorasyondur — sarma motoru onu görselin
  /// etrafından akıtamaz, sabit yerinde durur ve üste sürüklenen görselin
  /// altında kaybolur. Eskiden görsel bir satır aşağı ZORLANARAK çözülüyordu;
  /// kullanıcı görseli en üste koyamıyordu. Artık görsel serbest, ipucu iner.
  final Widget? hint;

  /// İpucu satırının yüksekliği (dp) — hangi görsellerin ipucunu kestiği
  /// bu bantla ölçülür.
  final double hintLineHeight;

  /// Görsellerin SAYFA üzerinde kapladığı bantları bildirir; metin bunların
  /// etrafından akar (bkz. text_wrap.dart). Konumlar sayfanın (bu tuvalin
  /// [child]'ının) sol-üst köşesine göredir.
  final ValueChanged<List<FloatBox>>? onFloats;

  /// Sayfanın en az yüksekliği (görünür alan — boş nota da tam sayfa tuval).
  final double minHeight;

  final ValueChanged<Attachment> onRemove;
  final ValueChanged<Attachment> onChanged;

  /// Tam ekranda seçilen kırpma alanını uygular (bkz. [ImageViewerScreen]).
  final Future<void> Function(Attachment, Rect)? onCrop;
  final Future<void> Function(Attachment)? onExtractText;

  /// Görseli panoya kopyalar; null ise menüde görünmez.
  final ValueChanged<Attachment>? onCopy;

  /// Görseli sayfadan alıp ek şeridine taşır; null ise menüde görünmez.
  final ValueChanged<Attachment>? onDetach;

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

  /// Sürüklemenin başladığı yer — parmağın toplam yer değiştirmesi buna
  /// eklenir (canlı değere eklemek hareketi katlardı).
  double? _moveOriginLeft;
  double? _moveOriginTop;

  /// Sürükleme bitince yeni konumu kaydeder ve canlı değerleri temizler.
  void _commitMove(Attachment img, double cw) {
    if (_moveId != img.id) return;
    final nl = _moveLeft;
    final nt = _moveTop;
    if (nl != null && nt != null) {
      widget.onChanged(img.copyWith(x: nl / cw, pageY: nt));
    }
    setState(() {
      _moveId = null;
      _moveLeft = null;
      _moveTop = null;
      _moveOriginLeft = null;
      _moveOriginTop = null;
    });
  }

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

  /// Büyük önizlemede duran görselin kimliği (null = kapalı).
  ///
  /// Önizleme SAYFA DÜZENİNE dokunmaz: görselin `displayWidth`/konumu
  /// değişmez, dolayısıyla metnin sarması da değişmez. Yalnızca üstte,
  /// geçici bir katmanda büyük çizilir.
  String? _previewId;

  void _togglePreview(String id) =>
      setState(() => _previewId = _previewId == id ? null : id);

  void _closePreview() {
    if (_previewId != null) setState(() => _previewId = null);
  }

  Attachment? _previewOf(List<Attachment> images) {
    final id = _previewId;
    if (id == null) return null;
    for (final img in images) {
      if (img.id == id) return img;
    }
    return null;
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
              (img.y != null
                  ? img.y! * _legacyCanvasHeight
                  : _defaultTop(index));
    left = left.clamp(0.0, (cw - w).clamp(0.0, cw)).toDouble();
    // Başlık/çip bölgesi görsele kapalı: üst sınırın altına inemez.
    if (top < widget.topLimit) top = widget.topLimit;
    return (left: left, top: top, w: w, h: h);
  }

  /// Görsellerin SAYFA uzayındaki dışlama bantları. Metin alanları kendi
  /// konumlarını ölçüp bunları kendi uzaylarına çevirir (bkz.
  /// [WrapFieldMeasure]). Metnin görsele değmemesi için yatayda 12, dikeyde
  /// 8 dp pay bırakılır.
  List<FloatBox> _floatsFor(double cw) {
    final boxes = <FloatBox>[];
    for (final (index, img) in widget.images.indexed) {
      final r = _resolve(img, index, cw);
      boxes.add(
        FloatBox(
          top: r.top,
          left: r.left - 12,
          right: r.left + r.w + 12,
          height: r.h + 8,
        ),
      );
    }
    return boxes;
  }

  double _hintTop(double cw) =>
      hintTopFor(_floatsFor(cw), widget.topLimit, widget.hintLineHeight);

  void _reportFloats(double cw) {
    final cb = widget.onFloats;
    if (cb == null) return;
    final next = _floatsFor(cw);
    if (_lastFloats != null && sameFloatList(_lastFloats!, next)) return;
    _lastFloats = next;
    // Ölçüm build sırasında yapılır; bildirimi kare sonuna erteleriz ki
    // gövde denetleyicisi build içinde setState tetiklemesin.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(next);
    });
  }

  List<FloatBox>? _lastFloats;

  void _openViewer(Attachment img) =>
      openImageViewer(context, img, widget.onChanged, onCrop: widget.onCrop);

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      // Son görsel silinince bantların BOŞALDIĞI da bildirilmeli — yoksa
      // metin, artık var olmayan bir görselin etrafından akmaya devam eder.
      _reportFloats(0);
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
    // Geri tuşu önce ÖNİZLEMEYİ, sonra görsel seçimini kapatır; not ancak
    // ikisi de kapalıyken kapanır (madde: "geri butonu direk anasayfaya
    // dönmesin bu tür durumlarda").
    return PopScope(
      canPop: _previewId == null && _selectedId == null,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_previewId != null) {
          _closePreview();
        } else {
          _deselect();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cw = constraints.maxWidth;
          _reportFloats(cw);
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
          final previewImg = _previewOf(widget.images);
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
              // İpucu görsellerin ALTINDA çizilir: zaten kesişmeyecek yere
              // konuyor, dokunuşu da yutmamalı (boş alana dokun → gövdeye odak).
              if (widget.hint != null)
                Positioned(
                  left: 0,
                  right: 0,
                  top: _hintTop(cw),
                  child: IgnorePointer(child: widget.hint!),
                ),
              for (final (index, img) in widget.images.indexed)
                _positioned(context, img, index, cw),
              if (selectedImg != null)
                _toolbar(context, selectedImg, selectedIndex, cw),
              // Büyük önizleme en üstte: sayfa ölçüleriyle oynamadığı için
              // metnin sarması olduğu gibi kalır.
              if (previewImg != null) _preview(context, previewImg, cw),
            ],
          );
        },
      ),
    );
  }

  /// Görseli sayfanın üzerinde BÜYÜK gösteren geçici katman. Boyut/konum
  /// değiştirmez; herhangi bir yere dokunmak kapatır.
  Widget _preview(BuildContext context, Attachment img, double cw) {
    final scheme = Theme.of(context).colorScheme;
    final aspect =
        (img.width != null &&
            img.height != null &&
            img.width! > 0 &&
            img.height! > 0)
        ? img.width! / img.height!
        : 1.0;
    // Görünür alanın içinde kal: hem genişlik hem yükseklik sınırlanır ki
    // uzun görseller taşmasın.
    final maxW = cw - 16;
    final maxH = widget.minHeight - 32;
    var w = maxW;
    var h = w / aspect;
    if (h > maxH && maxH > 0) {
      h = maxH;
      w = h * aspect;
    }
    return Positioned(
      left: 0,
      right: 0,
      // Önizleme, sayfanın GÖRÜNEN kısmının ortasında durur; sayfa
      // kaydırıldığında da görselin bandına yakın kalsın diye üst sınır
      // görselin konumuna göre verilir.
      top: (widget.topLimit + 8).clamp(0.0, double.infinity),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closePreview,
        child: Center(
          child: Material(
            elevation: 8,
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _ImageBox(img: img, fit: BoxFit.contain),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      tooltip: context.l10n.close,
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black45,
                      ),
                      onPressed: _closePreview,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        // Taşıma TEK jestte: basılı tut, parmağını kaldırmadan sürükle.
        // (Önce seçip sonra sürüklemek gerekiyordu — kullanımı zordu.)
        // Uzun basma dikey kaydırmayla çakışmaz: sayfa kaydırma anlık
        // sürüklemeyle başlar, taşıma ise basılı tutmayı bekler.
        onLongPressStart: (d) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedId = img.id;
            _moveId = img.id;
            // Sürükleme başlangıcı ayrı tutulur: _resolve taşıma sırasında
            // canlı değeri döndürdüğü için onu baz almak kaymayı katlardı.
            _moveOriginLeft = r.left;
            _moveOriginTop = r.top;
            _moveLeft = r.left;
            _moveTop = r.top;
          });
        },
        onLongPressMoveUpdate: (d) {
          if (_moveId != img.id) return;
          setState(() {
            _moveLeft = ((_moveOriginLeft ?? r.left) + d.offsetFromOrigin.dx)
                .clamp(0.0, (cw - r.w).clamp(0.0, cw))
                .toDouble();
            final nt = (_moveOriginTop ?? r.top) + d.offsetFromOrigin.dy;
            _moveTop = nt < widget.topLimit ? widget.topLimit : nt;
          });
        },
        onLongPressEnd: (_) => _commitMove(img, cw),
        onLongPressCancel: () => _commitMove(img, cw),
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
                  // Köşe tutamağı SÜRÜKLENİYOR ama dokunmak hiçbir şey
                  // yapmıyordu; küçültülmüş bir görseli okumak için ya tam
                  // ekrana gitmek ya da büyütüp sonra geri küçültmek
                  // gerekiyordu. Dokunuş artık BÜYÜK ÖNİZLEME açar: görsel
                  // sayfanın üstünde büyük çizilir, düzen (ve metnin akışı)
                  // hiç değişmez — kapanınca her şey yerli yerinde kalır.
                  onTap: () => _togglePreview(img.id),
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
  Widget _toolbar(BuildContext context, Attachment img, int index, double cw) {
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
        onCopy: widget.onCopy == null ? null : () => widget.onCopy!(img),
        onDetach: widget.onDetach == null
            ? null
            : () {
                _deselect();
                widget.onDetach!(img);
              },
        onFullscreen: () => _openViewer(img),
        onRemove: () => widget.onRemove(img),
      ),
    );
  }
}
