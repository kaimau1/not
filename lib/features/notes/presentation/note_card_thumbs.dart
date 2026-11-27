part of 'note_card_media.dart';

/// Kartta sayfa üstü el yazısının başı (bkz. `Note.pageInk`). Bölünmüş notta
/// çizgiler kartta yüklü değildir: yalnız "el yazısı var" denir.
class CardPageInk extends StatelessWidget {
  const CardPageInk({super.key, required this.note});

  final Note note;

  static const double _maxHeight = 120;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (note.pageInk.isEmpty) {
      return Row(
        children: [
          Icon(Icons.draw_outlined, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              context.l10n.pageInkOnCard,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        var top = double.infinity;
        var bottom = 0.0;
        for (final s in note.pageInk) {
          if (s.page != 1) continue;
          for (var i = 1; i < s.points.length; i += 2) {
            top = math.min(top, s.points[i]);
            bottom = math.max(bottom, s.points[i]);
          }
        }
        // Çizimin üstündeki boş sayfa kartta gösterilmez (yazının altında
        // ayrıca boşluk kalıyordu); çizim kutunun tepesinden başlar.
        final w = box.maxWidth;
        final lift = top.isFinite ? math.max(0.0, top * w - 4) : 0.0;
        return ClipRect(
          child: SizedBox(
            width: w,
            height: math.min(_maxHeight, bottom * w + 4 - lift),
            // Kare tuval kutudan TAŞAR (kırpılır): Align'la kutunun ≤ 120
            // boyuna sıkışıyor, y genişlik yerine 120'yle ölçeklenip çizim
            // kartta basık görünüyordu (tablet bulgusu 2026-11-07).
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: w,
              maxWidth: w,
              minHeight: w,
              maxHeight: w,
              child: Transform.translate(
                offset: Offset(0, -lift),
                child: RepaintBoundary(
                  child: CustomPaint(painter: InkPainter(note.pageInk, 1)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissingTile extends StatelessWidget {
  const _MissingTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black12,
    child: Center(child: Icon(icon, size: AppIconSize.m, color: Colors.black38)),
  );
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white70, width: 1.5),
    ),
    child: Icon(Icons.play_arrow, color: Colors.white, size: size * 0.62),
  );
}

/// Cihazdaki videonun kapak karesi. Kare çıkarılamazsa (masaüstü, video bu
/// cihazda değil) koyu zemin üstünde kamera simgesi.
class _LocalVideoCover extends StatelessWidget {
  const _LocalVideoCover({required this.video});

  final Attachment video;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFF263238),
      child: Center(
        child: Icon(Icons.videocam_outlined, color: Colors.white54, size: 22),
      ),
    );
    if (!VideoFrame.supported || !localFileExists(video.localPath)) {
      return fallback;
    }
    return _AsyncThumb(
      future: CardThumbs.videoCover(video),
      fallback: fallback,
    );
  }
}

/// Not sayfasındaki videonun KAPAK KARESİ — oynatıcı kurulmadan önce
/// (bkz. `_VideoBox`'un tembel kurulumu). Kart kapağından büyük (720 px)
/// üretilir: sayfa genişliğinde bulanık durmasın. Diskte önbelleklenir.
class VideoPoster extends StatelessWidget {
  const VideoPoster({super.key, required this.video, this.fit = BoxFit.cover});

  final Attachment video;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFF263238),
      child: Center(
        child: Icon(Icons.videocam_outlined, color: Colors.white54, size: 26),
      ),
    );
    if (!VideoFrame.supported || !localFileExists(video.localPath)) {
      return fallback;
    }
    return FutureBuilder<Uint8List?>(
      future: CardThumbs.videoPoster(video),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return fallback;
        return Image.memory(
          bytes,
          fit: fit,
          cacheWidth: 720,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

/// PDF'in (yer imli sayfası, yoksa ilk) sayfasının önbellekli küçük resmi —
/// kartın dışında da kullanılır (not ekranının alt ek şeridi).
class PdfFirstPageThumb extends StatelessWidget {
  const PdfFirstPageThumb({super.key, required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) =>
      _PdfFirstPage(attachment: attachment, iconSize: 28);
}

class _PdfFirstPage extends StatelessWidget {
  const _PdfFirstPage({required this.attachment, this.iconSize = 24});

  final Attachment attachment;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Center(
      child: Icon(
        Icons.picture_as_pdf_outlined,
        color: scheme.error,
        size: iconSize,
      ),
    );
    if (!localFileExists(attachment.localPath)) {
      // Bulut önizlemesi (F65.5, ilk sayfa): web/diğer cihaz indirmeden çizer.
      if (attachment.thumbUrl.isEmpty) return fallback;
      return CachedNetworkImage(
        imageUrl: attachment.thumbUrl,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        fadeInDuration: AppMotion.quick,
        memCacheWidth: 480,
        placeholder: (context, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      );
    }
    return _AsyncThumb(
      future: CardThumbs.pdfPage(attachment, math.max(1, attachment.pdfPage)),
      fallback: fallback,
      alignment: Alignment.topCenter,
    );
  }
}

/// Önbellekteki küçük resmi gösterir; hazır olana dek [fallback].
class _AsyncThumb extends StatelessWidget {
  const _AsyncThumb({
    required this.future,
    required this.fallback,
    this.alignment = Alignment.center,
  });

  final Future<Uint8List?> future;
  final Widget fallback;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: future,
    builder: (context, snap) {
      final bytes = snap.data;
      if (bytes == null) return fallback;
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        alignment: alignment,
        cacheWidth: 480,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      );
    },
  );
}

/// Kart küçük resimlerinin (video kapağı, PDF ilk sayfası) önbelleği.
///
/// Anahtar çizimde G/Ç YAPMADAN ekin alanlarından kurulur (yol + boyut +
/// sayfa); üretilen resim diske yazılır (`<önbellek>/card_thumbs/`), üretim
/// TEK SIRADA (kaydırmada çözücüler yarışmaz), video karesi arka planda ve
/// doğrudan küçük. Bellekteki baytlar bütçeli (F7.1).
abstract final class CardThumbs {
  static final _cache = <String, Future<Uint8List?>>{};
  static const _cap = 64;

  /// Bellekteki baytların tavanı (F7.1): 64 PDF kapağı PNG'yken yüzlerce
  /// KB'tan onlarca MB'a çıkabiliyordu. Aşınca en eski kullanılan düşer
  /// (disk kopyası kalır).
  static const _byteBudget = 6 * 1024 * 1024;
  static final _sizes = <String, int>{};
  static int _bytes = 0;

  /// Bellekte tutulan küçük resim baytları (teşhis — F9.2).
  static int get memoryBytes => _bytes;

  /// Üretim kuyruğu: bir önceki iş bitmeden yenisi başlamaz.
  static Future<void> _queue = Future.value();

  static Future<Uint8List?> videoCover(Attachment video) => _get(
    'v|${video.localPath}|${video.sizeBytes}',
    () => VideoFrame.thumbnail(video.localPath),
  );

  /// Sayfadaki video kutusunun kapağı (bkz. [VideoPoster]) — 720 px.
  static Future<Uint8List?> videoPoster(Attachment video) => _get(
    'vp|${video.localPath}|${video.sizeBytes}',
    () => VideoFrame.thumbnail(video.localPath, maxSide: 720),
  );

  /// Bellekteki küçük resim baytlarını bırakır (disk önbelleği kalır).
  /// Uygulama arka plana geçince ve sistem bellek sıkışıklığı bildirince
  /// çağrılır — geri dönüşte diskten anında okunur.
  static void clearMemory() {
    _cache.clear();
    _sizes.clear();
    _bytes = 0;
  }

  static Future<Uint8List?> pdfPage(Attachment pdf, int page) => _get(
    // 'pj': kapak JPEG (eski 'p' anahtarlı PNG'ler diskte yeniden kullanılmaz).
    'pj|${pdf.localPath}|${pdf.sizeBytes}|$page',
    () => _renderPdf(pdf.localPath, page),
  );

  static Future<Uint8List?> _get(
    String key,
    Future<Uint8List?> Function() make,
  ) {
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit; // en yeni kullanılan sona
      return hit;
    }
    final future = _load(key, make).catchError((Object _) => null);
    _cache[key] = future;
    if (_cache.length > _cap) _forget(_cache.keys.first);
    future.then((bytes) {
      // Bu arada düşürüldüyse sayılmaz.
      if (bytes == null || !identical(_cache[key], future)) return;
      _bytes += bytes.length - (_sizes[key] ?? 0);
      _sizes[key] = bytes.length;
      _trim(key);
    });
    return future;
  }

  static void _forget(String key) {
    _cache.remove(key);
    _bytes -= _sizes.remove(key) ?? 0;
  }

  /// Bütçe aşılınca en eski kullanılanları düşürür; [keep] (az önce gelen)
  /// tek başına bütçeyi aşsa da kalır.
  static void _trim(String keep) {
    while (_bytes > _byteBudget) {
      final oldest = _cache.keys.firstWhere(
        (k) => k != keep,
        orElse: () => keep,
      );
      if (oldest == keep) break;
      _forget(oldest);
    }
  }

  static Future<Uint8List?> _load(
    String key,
    Future<Uint8List?> Function() make,
  ) async {
    final file = await _diskFile(key);
    if (file != null && await file.exists()) return file.readAsBytes();
    // Sıraya gir: önceki üretim bitince başla.
    final previous = _queue;
    final done = Completer<void>();
    _queue = done.future;
    try {
      await previous;
      final bytes = await make();
      if (bytes != null && file != null) {
        try {
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
        } catch (_) {
          // Disk dolu/erişilemez: küçük resim yalnız bellekte kalır.
        }
      }
      return bytes;
    } finally {
      done.complete();
    }
  }

  static String? _dir;

  static Future<File?> _diskFile(String key) async {
    if (kIsWeb) return null;
    try {
      _dir ??= (await getApplicationCacheDirectory()).path;
    } catch (_) {
      return null;
    }
    final name = sha1.convert(utf8.encode(key)).toString();
    return File('$_dir/card_thumbs/$name.img');
  }

  static Future<Uint8List?> _renderPdf(String path, int pageNumber) async {
    final document = await PdfDocument.openFile(path);
    try {
      final pages = document.pages;
      if (pages.isEmpty) return null;
      final page = pages[(pageNumber - 1).clamp(0, pages.length - 1)];
      // Kart kapağı ~200 dp genişlikte: 3x ekranda ~600 px; 480 px yeter.
      return await renderPdfPageJpeg(page, width: 480);
    } finally {
      await document.dispose();
    }
  }

  @visibleForTesting
  static void clear() => clearMemory();

  /// Testte üretimi taklit etmek için (disk ve pdfium olmadan).
  @visibleForTesting
  static Future<Uint8List?> debugGet(
    String key,
    Future<Uint8List?> Function() make,
  ) => _get(key, make);
}
