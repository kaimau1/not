import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/doc_picker.dart';
import '../../../core/widgets/app_sheet.dart';
import 'capture_mode_sheet.dart';

/// "+ → Dosya"da seçilen dosyanın TÜRÜ (uzantıdan).
enum PickedFileKind {
  image,
  pdf,
  slides,
  video,
  audio;

  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'];
  static const videoExtensions = ['mp4', 'mov', 'mkv', '3gp', 'webm'];
  static const audioExtensions = [
    'mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac', 'amr', //
  ];

  /// Seçicinin kabul ettiği bütün uzantılar.
  static List<String> get allExtensions => [
    ...imageExtensions,
    'pdf',
    'pptx',
    ...videoExtensions,
    ...audioExtensions,
  ];

  /// Dosya adının türü; desteklenmiyorsa null.
  static PickedFileKind? of(String name) {
    final ext = DocPicker.extensionOf(name);
    if (imageExtensions.contains(ext)) return PickedFileKind.image;
    if (ext == 'pdf') return PickedFileKind.pdf;
    if (ext == 'pptx') return PickedFileKind.slides;
    if (videoExtensions.contains(ext)) return PickedFileKind.video;
    if (audioExtensions.contains(ext)) return PickedFileKind.audio;
    return null;
  }
}

/// HEIC/HEIF görselleri PNG'ye çevirir: görsel akışları, sıkıştırıcı ve PDF
/// yazıcısı HEIC okumuyor (eskiden "+ → Dosya"da HEIC seçilince akışın kendi
/// seçicisi dosyayı tanımıyor, seçici ikinci kez açılıyordu). Çözülemeyen
/// dosya atlanır; web'de HEIC desteklenmez.
Future<List<XFile>> normalizeHeicImages(List<XFile> files) async {
  final out = <XFile>[];
  for (final f in files) {
    final name = f.name.isEmpty ? p.basename(f.path) : f.name;
    final ext = DocPicker.extensionOf(name);
    if (ext != 'heic' && ext != 'heif') {
      out.add(f);
      continue;
    }
    if (kIsWeb) continue;
    try {
      final codec = await ui.instantiateImageCodec(await f.readAsBytes());
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      frame.image.dispose();
      codec.dispose();
      if (data == null) continue;
      final dir = await getTemporaryDirectory();
      final base = '${p.basenameWithoutExtension(name)}.png';
      final file = File(
        p.join(dir.path, 'heic_${DateTime.now().microsecondsSinceEpoch}_$base'),
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      out.add(XFile(file.path, name: base));
    } catch (_) {
      // Cihaz HEIC çözemiyor: dosya atlanır (çağıran "desteklenmiyor" der).
    }
  }
  return out;
}

/// Seçilen dosyayla ne yapılacağı.
enum FileUse {
  /// Balonlu: içerik belge sayfası olur (görsel/PDF/sunum).
  bubbles,

  /// Klasik: düz not, dosya notun içinde (görsel/PDF/sunum).
  classic,

  /// Videoyla not: video üstte oynar, not altında.
  video,

  /// Ses eki: kayıt notta çalınabilir durur.
  audio,

  /// Metne dök: konuşma/yazı metne çevrilip gövdeye yazılır.
  transcribe,
}

/// Levhadan dönen seçim.
typedef FileUseChoice = ({FileUse use, String title});

/// [FileUse.bubbles]/[FileUse.classic] seçimini akışların kip seçimine
/// çevirir (kip levhası bir daha sorulmasın).
CaptureChoice? captureChoiceOf(FileUseChoice choice) => switch (choice.use) {
  FileUse.bubbles => CaptureChoice(
    mode: CaptureMode.bubbles,
    noteTitle: choice.title,
  ),
  FileUse.classic => CaptureChoice(
    mode: CaptureMode.classic,
    noteTitle: choice.title,
  ),
  _ => null,
};

/// Türün sunduğu seçenekler, sırayla. Varsayılan kip ([preferred]) belge
/// türlerinde başa alınır. Web'de metne dökme ve ses/video eki yok.
@visibleForTesting
List<FileUse> fileUsesFor(
  PickedFileKind kind, {
  CaptureMode? preferred,
  bool web = kIsWeb,
}) {
  List<FileUse> modes() => preferred == CaptureMode.classic
      ? const [FileUse.classic, FileUse.bubbles]
      : const [FileUse.bubbles, FileUse.classic];
  return switch (kind) {
    PickedFileKind.image => [...modes(), if (!web) FileUse.transcribe],
    PickedFileKind.pdf || PickedFileKind.slides => modes(),
    PickedFileKind.video => [FileUse.video, if (!web) FileUse.transcribe],
    PickedFileKind.audio => [
      if (!web) FileUse.audio,
      if (!web) FileUse.transcribe,
    ],
  };
}

/// **DOSYAYLA NE YAPALIM — TEK LEVHA** (kullanıcı bulgusu 2026-10-20: "dosya
/// ekle aşaması çok sıkıntılı, güzel değil").
///
/// ESKİDEN dosya seçildikten sonra art arda iki-üç soru geliyordu: "Bu
/// dosyayla ne yapalım?" (Notuna ekle / Metne dök), sonra ilk seferde
/// balonlu/klasik kip levhası, sonra başlık. Hangisinin neyi değiştirdiği
/// belli değildi; ses dosyası sorulmadan metne dökülüyordu.
///
/// ŞİMDİ hepsi tek levhada: üstte dosyanın özeti (tür simgesi, ad, kaç
/// dosya), isteğe bağlı başlık ve türe göre iki-üç büyük seçenek — her
/// birinin altında ne olacağı yazılı. Varsayılan kip başta ve işaretli.
Future<FileUseChoice?> showFileUseSheet(
  BuildContext context, {
  required PickedFileKind kind,
  required List<String> names,
  CaptureMode? preferred,
}) {
  final uses = fileUsesFor(kind, preferred: preferred);
  return showAppSheet<FileUseChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      // Klavye açılınca levha yukarı kalkar; başlık alanı örtülmesin.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _FileUseSheet(
        kind: kind,
        names: names,
        uses: uses,
        preferred: preferred,
      ),
    ),
  );
}

class _FileUseSheet extends StatefulWidget {
  const _FileUseSheet({
    required this.kind,
    required this.names,
    required this.uses,
    required this.preferred,
  });

  final PickedFileKind kind;
  final List<String> names;
  final List<FileUse> uses;
  final CaptureMode? preferred;

  @override
  State<_FileUseSheet> createState() => _FileUseSheetState();
}

class _FileUseSheetState extends State<_FileUseSheet> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  static IconData _kindIcon(PickedFileKind kind) => switch (kind) {
    PickedFileKind.image => Icons.image_outlined,
    PickedFileKind.pdf => Icons.picture_as_pdf_outlined,
    PickedFileKind.slides => Icons.slideshow_outlined,
    PickedFileKind.video => Icons.movie_outlined,
    PickedFileKind.audio => Icons.audio_file_outlined,
  };

  ({IconData icon, String title, String info}) _describe(
    AppLocalizations l10n,
    FileUse use,
  ) => switch (use) {
    FileUse.bubbles => (
      icon: Icons.chat_bubble_outline_rounded,
      title: l10n.fileUseBubbles,
      info: l10n.captureModeBubblesInfo,
    ),
    FileUse.classic => (
      icon: Icons.note_add_outlined,
      title: l10n.fileUseClassic,
      info: widget.kind == PickedFileKind.image
          ? l10n.fileUseClassicImageInfo
          : l10n.captureModeClassicInfo,
    ),
    FileUse.video => (
      icon: Icons.smart_display_outlined,
      title: l10n.fileUseVideo,
      info: l10n.fileUseVideoInfo,
    ),
    FileUse.audio => (
      icon: Icons.graphic_eq,
      title: l10n.fileUseAudio,
      info: l10n.fileUseAudioInfo,
    ),
    FileUse.transcribe => (
      icon: Icons.subtitles_outlined,
      title: l10n.transcribeFile,
      info: widget.kind == PickedFileKind.image
          ? l10n.fileUseTranscribeImageInfo
          : l10n.fileUseTranscribeInfo,
    ),
  };

  bool _isDefault(FileUse use) =>
      (use == FileUse.bubbles && widget.preferred == CaptureMode.bubbles) ||
      (use == FileUse.classic && widget.preferred == CaptureMode.classic);

  void _pick(FileUse use) =>
      Navigator.pop(context, (use: use, title: _title.text.trim()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final first = widget.names.isEmpty ? '' : widget.names.first;
    final more = widget.names.length - 1;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.quickAddFileWhat, style: textTheme.titleMedium),
            const SizedBox(height: 12),
            // DOSYANIN ÖZETİ: neyin seçildiği soru sorulurken görünsün.
            Container(
              key: const ValueKey('file-use-summary'),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _kindIcon(widget.kind),
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (more > 0)
                          Text(
                            l10n.fileUseMore(more),
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('file-use-title'),
              controller: _title,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.captureNoteTitle,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (final use in widget.uses) ...[
              _UseTile(
                key: ValueKey('file-use-${use.name}'),
                icon: _describe(l10n, use).icon,
                title: _describe(l10n, use).title,
                info: _describe(l10n, use).info,
                badge: _isDefault(use) ? l10n.fileUseDefault : null,
                highlighted: use == widget.uses.first,
                onTap: () => _pick(use),
              ),
              const SizedBox(height: 8),
            ],
            if (widget.uses.contains(FileUse.bubbles))
              Text(
                l10n.captureModeChangeLater,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UseTile extends StatelessWidget {
  const _UseTile({
    super.key,
    required this.icon,
    required this.title,
    required this.info,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String info;
  final String? badge;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: highlighted
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlighted ? scheme.primary : scheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: highlighted ? scheme.onPrimary : scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
