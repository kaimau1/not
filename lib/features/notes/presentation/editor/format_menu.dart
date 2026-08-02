import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/rich_text.dart';
import 'text_wrap.dart';

/// Seçili metne biçim uygular (ya da varsa kaldırır).
///
/// Seçim, düzenleme tamponunun GÖRÜNTÜ uzayındadır (sarma çapaları içerir);
/// biçim ise nota yazılan MANTIKSAL metne uygulanmalı. Dönüşüm burada tek
/// yerde yapılır — çağrı yerleri (gövde ve liste maddeleri) çapaları hiç
/// bilmez.
///
/// Uygulandıysa true döner; çağıran notu kaydeder (programlı değişiklikte
/// TextField'ın `onChanged`'i ÇALIŞMAZ).
bool applyRichFormat(
  WrapTextController controller,
  RichFormat format, {
  int? colorIndex,
}) {
  final selection = controller.selection;
  if (!selection.isValid) return false;
  final display = controller.text;
  final logical = stripWrapAnchors(display);
  final start = wrapToLogicalOffset(display, selection.start);
  final end = wrapToLogicalOffset(display, selection.end);
  final result = toggleFormat(
    logical,
    start,
    end,
    format,
    colorIndex: colorIndex,
  );
  return _write(controller, logical, start, end, result);
}

/// SEÇİLİ metne boyut ya da opaklık kademesi yazar (aç/kapa değil: kaydırıcı
/// hangi değerdeyse o uygulanır). [index] null ise kademe kaldırılır — metin
/// notun kendi boyutuna/opaklığına döner.
///
/// Seçim yoksa hiçbir şey yapmaz ve false döner; çağıran o zaman değişikliği
/// NOT GENELİNE uygular ("seçim varsa ona, yoksa tüm sayfaya").
bool applyRichStep(
  WrapTextController controller,
  RichFormat format,
  int? index,
) {
  final selection = controller.selection;
  if (!selection.isValid || selection.isCollapsed) return false;
  final display = controller.text;
  final logical = stripWrapAnchors(display);
  final start = wrapToLogicalOffset(display, selection.start);
  final end = wrapToLogicalOffset(display, selection.end);
  return _write(
    controller,
    logical,
    start,
    end,
    setRangeFormat(logical, start, end, format, index),
  );
}

/// Seçimdeki (ya da imlecin içinde bulunduğu parçadaki) TÜM biçimleri siler.
bool clearRichFormat(WrapTextController controller) {
  final selection = controller.selection;
  if (!selection.isValid) return false;
  final display = controller.text;
  final logical = stripWrapAnchors(display);
  final start = wrapToLogicalOffset(display, selection.start);
  final end = wrapToLogicalOffset(display, selection.end);
  return _write(
    controller,
    logical,
    start,
    end,
    clearFormat(logical, start, end),
  );
}

/// Sonucu denetleyiciye yazar. SEÇİM KORUNUR: biçim verilen metin seçili
/// kalır, böylece kullanıcı arka arkaya kalın + renk verebilir (eskiden
/// imleç sona toplanıyor ve ikinci biçim için yeniden seçmek gerekiyordu).
bool _write(
  WrapTextController controller,
  String logical,
  int start,
  int end,
  ({String text, int start, int end}) result,
) {
  if (result.text == logical && result.start == start && result.end == end) {
    return false;
  }
  controller.setLogical(result.text, result.start, result.end);
  return true;
}

/// Biçim menüsü: seçim araç çubuğundaki "Biçim" düğmesi bunu açar.
///
/// Alt sayfa (menü değil) bilinçli: renk seçenekleri satır hâlinde ancak
/// burada sığıyor ve parmakla dokunulacak kadar büyük duruyor.
Future<void> showFormatSheet(
  BuildContext context, {
  required WrapTextController controller,
  required VoidCallback onApplied,
}) async {
  final l10n = context.l10n;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      void apply(RichFormat format, {int? colorIndex}) {
        if (applyRichFormat(controller, format, colorIndex: colorIndex)) {
          onApplied();
        }
        Navigator.pop(sheetContext);
      }

      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.formatTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FormatButton(
                      icon: Icons.format_bold,
                      label: l10n.formatBold,
                      onPressed: () => apply(RichFormat.bold),
                    ),
                    _FormatButton(
                      icon: Icons.format_italic,
                      label: l10n.formatItalic,
                      onPressed: () => apply(RichFormat.italic),
                    ),
                    _FormatButton(
                      icon: Icons.format_underlined,
                      label: l10n.formatUnderline,
                      onPressed: () => apply(RichFormat.underline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.formatTextColor,
                  style: Theme.of(sheetContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _ColorRow(
                  onPick: (index) => apply(RichFormat.color, colorIndex: index),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.formatHighlight,
                  style: Theme.of(sheetContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                _ColorRow(
                  filled: true,
                  onPick: (index) =>
                      apply(RichFormat.highlight, colorIndex: index),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.formatInfo,
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _FormatButton extends StatelessWidget {
  const _FormatButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 20),
    label: Text(label),
  );
}

/// Palet satırı: 1..5 indeksleri (bkz. NoteColors.richPalette).
class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.onPick, this.filled = false});

  final ValueChanged<int> onPick;

  /// true: vurgu (dolu daire), false: yazı rengi (halka).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final palette = NoteColors.richPalette;
    return Row(
      children: [
        for (var i = 0; i < palette.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: InkWell(
              onTap: () => onPick(i + 1),
              customBorder: const CircleBorder(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? palette[i].withValues(alpha: 0.45)
                      : Colors.transparent,
                  border: Border.all(color: palette[i], width: 3),
                ),
                child: filled
                    ? null
                    : Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: palette[i],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
