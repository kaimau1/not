import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/widgets/delayed_spinner.dart';
import '../../domain/attachment.dart';
import '../note_card_media.dart' show PdfFirstPageThumb;

/// **YÜKLEME HÂLİ** (DENEYIM F78.3b): sabit/gömülü PDF belgesi açılırken
/// gri kutu yerine ekin küçük resmi (kartta zaten önbellekte) + %24 siyah
/// perde + gecikmeli halka. Küçük resim yoksa `surfaceContainer` + tür
/// simgesi (perdesiz). Bulunduğu kutuyu doldurur; boyu belirlemez.
///
/// Rota geçişi SIRASINDA kullanılmaz (`AfterRouteTransition` yer tutucusu tek
/// renk kalır — geçiş kareleri hafif olsun); geçiş bitince, belge açılana dek.
class MediaLoadingCover extends StatelessWidget {
  const MediaLoadingCover({super.key, required this.attachment});

  final Attachment attachment;

  /// Küçük resim çizilebilir mi: yerel dosya (önbellekten üretilir) ya da
  /// PDF'in bulut önizlemesi.
  static bool hasThumb(Attachment a) =>
      localFileExists(a.localPath) || a.thumbUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final a = attachment;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).colorScheme.surfaceContainer),
        PdfFirstPageThumb(attachment: a),
        if (hasThumb(a))
          ColoredBox(color: Colors.black.withValues(alpha: AppAlpha.soft)),
        const Center(
          child: SizedBox.square(
            dimension: 22,
            child: DelayedSpinner(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ],
    );
  }
}
