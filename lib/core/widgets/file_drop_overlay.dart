import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../l10n_ext.dart';
import '../utils/web_file_drop.dart';

/// **"BIRAK" ÇERÇEVESİ** (kullanıcı isteği 2026-11-20: web'de ve tablette
/// fareyle dosya sürüklenince "diğer uygulamalarda çıkan, ekin algılandığını
/// gösteren çerçeve çıkmalı"). Dosya pencerenin üstündeyken ([fileDragHover])
/// bütün pencereye renkli kenarlı yarı saydam bir perde ve ortada "bırakın"
/// hapı çizer. Dokunuşu hiç yutmaz; ağacın şekli sabit (perde yokken boş
/// kutu), dinleyen yalnız bu katman.
class FileDropOverlay extends StatelessWidget {
  const FileDropOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: ValueListenableBuilder<bool>(
            valueListenable: fileDragHover,
            builder: (context, hovering, _) => AnimatedOpacity(
              opacity: hovering ? 1 : 0,
              duration: AppMotion.quick,
              child: hovering ? const _DropFrame() : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ],
  );
}

class _DropFrame extends StatelessWidget {
  const _DropFrame();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      key: const ValueKey('file-drop-frame'),
      padding: const EdgeInsets.all(AppSpace.s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: AppAlpha.hairline),
          borderRadius: BorderRadius.circular(AppRadius.l),
          border: Border.all(color: scheme.primary, width: 2),
        ),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.xl,
                vertical: AppSpace.m,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    size: AppIconSize.l,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: AppSpace.s),
                  Text(
                    context.l10n.fileDropHint,
                    style: AppText.of(
                      theme,
                    ).rowTitle.copyWith(color: scheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
