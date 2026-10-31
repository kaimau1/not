import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import 'editor/note_images.dart';
import 'viewers/image_crop.dart';
import '../../../core/friendly_error.dart';

/// Seçilen görselleri NOT KURULMADAN ÖNCE düzeltme ekranı: kırp, döndür,
/// gereksizini at, sırayı gözden geçir.
///
/// Kullanıcı isteği (2026-08-09): "görsel ekle not al'da ilk başta görseli
/// seçince kırp/döndür gibi seçenekler çıkmalı, sonra not başlamalı." Eskiden
/// seçilen fotoğraflar doğrudan belgeye diziliyordu; yamuk çekilmiş ya da yan
/// duran bir kare ancak not kurulduktan sonra fark ediliyor ve düzeltmenin tek
/// yolu notu silip baştan başlamaktı.
///
/// Sonuç: işlenmiş dosyaların yolları (`Navigator.pop`). Kaynak dosyalara
/// DOKUNULMAZ — her düzenleme geçici klasöre yeni bir JPEG yazar, yani
/// galerideki özgün fotoğraf hiçbir zaman değişmez.
class ImagePrepareScreen extends StatefulWidget {
  const ImagePrepareScreen({super.key, required this.paths});

  final List<String> paths;

  /// Ekranı açar; iptalde null, onaylanınca işlenmiş yollar döner.
  static Future<List<String>?> open(BuildContext context, List<String> paths) =>
      Navigator.of(context).push<List<String>>(
        MaterialPageRoute(builder: (_) => ImagePrepareScreen(paths: paths)),
      );

  @override
  State<ImagePrepareScreen> createState() => _ImagePrepareScreenState();
}

class _ImagePrepareScreenState extends State<ImagePrepareScreen> {
  late final List<String> _paths = [...widget.paths];
  int _index = 0;
  bool _busy = false;

  /// Bu ekranın ÜRETTİĞİ dosyalar. Vazgeçilirse silinir (kaynak dosyalar
  /// listede olmadığı için yanlışlıkla galeriden bir şey silinmez).
  final _produced = <String>[];

  String get _current => _paths[_index];

  @override
  void dispose() {
    // Kullanılmayan ara dosyalar önbellekte birikmesin.
    for (final path in _produced) {
      if (_paths.contains(path)) continue;
      File(path).delete().ignore();
    }
    super.dispose();
  }

  Future<void> _run(Future<String?> Function(String path) work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await work(_current);
      if (!mounted || result == null) return;
      _produced.add(result);
      setState(() => _paths[_index] = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showMessage(context.l10n.genericError(friendlyError(context.l10n, e)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rotate(int quarterTurns) => _run(
    (path) async => compute(
      _transformImage,
      _ImageEditRequest(
        sourcePath: path,
        targetPath: await _nextPath(),
        quarterTurns: quarterTurns,
      ),
    ),
  );

  Future<void> _crop() async {
    final file = File(_current);
    final bytes = await file.readAsBytes();
    final size = await _decodeSize(bytes);
    if (!mounted || size == null) return;
    final rect = await Navigator.of(context).push<Rect>(
      MaterialPageRoute(
        builder: (_) => ImageCropScreen(
          // Kırpma oranlı (0-1) çalışır; ekran boyunda çözmek yeter (F5.2).
          image: boundedImage(
            MemoryImage(bytes),
            MediaQuery.sizeOf(context).width,
            MediaQuery.devicePixelRatioOf(context),
          ),
          aspect: size.width / size.height,
        ),
      ),
    );
    if (rect == null || !mounted) return;
    await _run(
      (path) async => compute(
        _transformImage,
        _ImageEditRequest(
          sourcePath: path,
          targetPath: await _nextPath(),
          crop: [rect.left, rect.top, rect.right, rect.bottom],
        ),
      ),
    );
  }

  /// Kırpma katmanı görselin KUTUSUYLA birebir aynı olmalı; oranı bilmek için
  /// tek karelik bir çözümleme yeter (bitmap hemen bırakılır).
  Future<Size?> _decodeSize(Uint8List bytes) async {
    final decoded = await decodeImageFromList(bytes);
    final size = Size(decoded.width.toDouble(), decoded.height.toDouble());
    decoded.dispose();
    return size.isEmpty ? null : size;
  }

  Future<String> _nextPath() async {
    final dir = await getTemporaryDirectory();
    final name = 'hazirla_${DateTime.now().microsecondsSinceEpoch}.jpg';
    return p.join(dir.path, name);
  }

  void _remove() {
    if (_paths.length <= 1) return;
    setState(() {
      _paths.removeAt(_index);
      if (_index >= _paths.length) _index = _paths.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.imagePrepareTitle),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, _paths),
            child: Text(l10n.imagePrepareDone),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.file(
                    File(_current),
                    // Anahtar yol: aynı karede dosya değişince Flutter'ın
                    // görsel önbelleği eskisini göstermeye devam ediyordu.
                    key: ValueKey(_current),
                    fit: BoxFit.contain,
                    cacheWidth: decodeWidthBucket(
                      MediaQuery.sizeOf(context).width,
                      MediaQuery.devicePixelRatioOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_paths.length > 1)
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _paths.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.all(6),
                  child: GestureDetector(
                    onTap: () => setState(() => _index = i),
                    child: Container(
                      width: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i == _index
                              ? scheme.primary
                              : scheme.outlineVariant,
                          width: i == _index ? 2.5 : 1,
                        ),
                        image: DecorationImage(
                          // 52 px'lik küçük resim: tam boy çözmek görsel
                          // başına ~48 MB'tı (F5.2).
                          image: boundedImage(
                            FileImage(File(_paths[i])),
                            52,
                            MediaQuery.devicePixelRatioOf(context),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    tooltip: l10n.imageRotateLeft,
                    onPressed: _busy ? null : () => _rotate(-1),
                    icon: const Icon(Icons.rotate_left),
                  ),
                  IconButton(
                    tooltip: l10n.imageRotateRight,
                    onPressed: _busy ? null : () => _rotate(1),
                    icon: const Icon(Icons.rotate_right),
                  ),
                  IconButton(
                    tooltip: l10n.crop,
                    onPressed: _busy ? null : _crop,
                    icon: const Icon(Icons.crop),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    onPressed: _busy || _paths.length <= 1 ? null : _remove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// İzolata geçen istek (tek argüman kuralı). [crop] 0–1 oranlı
/// `[left, top, right, bottom]`; null ise kırpma yok.
class _ImageEditRequest {
  const _ImageEditRequest({
    required this.sourcePath,
    required this.targetPath,
    this.quarterTurns = 0,
    this.crop,
  });

  final String sourcePath;
  final String targetPath;
  final int quarterTurns;
  final List<double>? crop;
}

/// Döndürme/kırpmayı ARKA PLANDA yapar: 12 MP'lik bir kareyi ana izolede
/// çözmek arayüzü saniyelerce dondurur (madde 9 — kasma olmamalı).
String? _transformImage(_ImageEditRequest request) {
  final bytes = File(request.sourcePath).readAsBytesSync();
  var picture = img.decodeImage(bytes);
  if (picture == null) return null;
  final crop = request.crop;
  if (crop != null) {
    final x = (crop[0] * picture.width).round().clamp(0, picture.width - 1);
    final y = (crop[1] * picture.height).round().clamp(0, picture.height - 1);
    final w = ((crop[2] - crop[0]) * picture.width).round().clamp(
      1,
      picture.width - x,
    );
    final h = ((crop[3] - crop[1]) * picture.height).round().clamp(
      1,
      picture.height - y,
    );
    picture = img.copyCrop(picture, x: x, y: y, width: w, height: h);
  }
  if (request.quarterTurns != 0) {
    picture = img.copyRotate(picture, angle: request.quarterTurns * 90);
  }
  File(
    request.targetPath,
  ).writeAsBytesSync(img.encodeJpg(picture, quality: 90));
  return request.targetPath;
}
