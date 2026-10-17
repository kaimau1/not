import 'package:flutter/material.dart';

import '../../../../app/theme/note_colors.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/rich_text.dart';
import 'text_wrap.dart';
import '../../../../core/widgets/app_sheet.dart';

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
  if (!controller.selection.isValid) return false;
  // KÖK NEDEN: bekleyen koşu ÖNCE metne işlenir (eskiden aşağıda
  // `clearPendingFormat()` ile ÇÖPE ATILIYORDU). Kullanıcı "kalın"a basıp
  // yazdıktan sonra bir parçayı seçip başka bir biçim verdiğinde, ekranda
  // kalın gördüğü metin bir anda düzleşiyordu.
  //
  // Flush BURADA, konumlar okunmadan ÖNCE: sarma metni uzattığı için
  // sonrasında okunan `start`/`end` işaretlerin içine düşerdi.
  if (!controller.selection.isCollapsed && controller.hasPendingFormat) {
    controller.flushPendingFormat();
  }
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
  // Biçimsiz imleç: metne boş kutu yazmak yerine biçim BEKLETİLİR, bir sonraki
  // yazılan metin işaretlerin içine girer. Metin değişmediği için false döner
  // (çağıranın notu kaydetmesine gerek yok).
  //
  // AÇ/KAPA ve ÇOKLU: aynı düğmeye yeniden basmak bekleyeni kaldırır, başka
  // bir düğme onun YANINA eklenir — Keep'te B, I, U aynı anda basılı kalıp
  // yazılan metnin üçünü birden alması gibi.
  final pending = result.pending;
  if (pending != null) {
    controller.togglePendingFormat(pending, result.pendingIndex);
    return false;
  }
  controller.clearPendingFormat();
  return _write(controller, logical, start, end, (
    text: result.text,
    start: result.start,
    end: result.end,
  ));
}

/// Denetleyicinin o anki seçiminde (ya da imlecinde) ETKİN olan biçimler.
///
/// Biçim şeridi hangi düğmeyi "basılı" göstereceğini buradan öğrenir.
/// [applyRichFormat] ile AYNI dönüşümden geçer (görüntü uzayı → mantıksal
/// metin): aksi hâlde vurgu ile düğmenin gerçekte uyguladığı biçim farklı
/// yerlere bakar ve şerit yalan söylerdi.
RichMark activeRichFormats(WrapTextController controller) {
  final selection = controller.selection;
  if (!selection.isValid) return RichMark.none;
  final display = controller.text;
  final logical = stripWrapAnchors(display);
  final start = wrapToLogicalOffset(display, selection.start);
  final end = wrapToLogicalOffset(display, selection.end);
  // Yalnız seçimin dokunduğu PARAGRAFLAR ayrıştırılır: biçim işaretleri
  // satır sonunu aşmaz (bkz. rich_text `_formatPattern`), sonuç birebir
  // aynı. Biçim çubuğu açıkken bu hesap HER TUŞTA koşuyor; tüm metni
  // ayrıştırmak uzun notta yazmayı yavaşlatıyordu.
  final from = start == 0 ? 0 : logical.lastIndexOf('\n', start - 1) + 1;
  var to = logical.indexOf('\n', end);
  if (to < 0) to = logical.length;
  var active = activeFormats(
    logical.substring(from, to),
    start - from,
    end - from,
  );
  // BEKLEYEN biçimler de "basılı" sayılır (kullanıcı: "basınca direkt
  // aktifleştiği belli olmalı"). Metinde henüz bir karşılığı yok — işaretler
  // ancak yazmaya başlayınca oluşuyor — ama kullanıcı açısından biçim O AN
  // açıldı; düğme yanmazsa basıp basmadığı anlaşılmıyordu.
  for (final entry in controller.pendingFormats.entries) {
    active = active.applied(entry.key, entry.value);
  }
  return active;
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

/// İmlecin satırını (ya da seçimin dokunduğu satırları) başlık yapar — bkz.
/// [setLineHeading]. Seçim görüntü uzayında, kural mantıksal metinde.
bool applyRichHeading(WrapTextController controller, RichHeading heading) {
  final selection = controller.selection;
  if (!selection.isValid) return false;
  if (controller.hasPendingFormat) controller.clearPendingFormat();
  final display = controller.text;
  final logical = stripWrapAnchors(display);
  final start = wrapToLogicalOffset(display, selection.start);
  final end = wrapToLogicalOffset(display, selection.end);
  return _write(
    controller,
    logical,
    start,
    end,
    setLineHeading(logical, start, end, heading),
  );
}

/// İmlecin satırının başlık düzeyi (biçim çubuğundaki vurgu).
RichHeading activeRichHeading(WrapTextController controller) {
  final selection = controller.selection;
  if (!selection.isValid) return RichHeading.normal;
  final display = controller.text;
  return lineHeadingAt(
    stripWrapAnchors(display),
    wrapToLogicalOffset(display, selection.start),
  );
}

/// Seçimden (ya da imlecin bulunduğu biçimli parçadan) **tek bir biçmi**
/// kaldırır — renk/vurgu paletindeki "Kaldır" bunu çağırır.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "biçim alanında seçiyorum geri
/// bırakamıyorum"): renk ve vurgu için geri dönüşün TEK yolu, paletten AYNI
/// rengi ikinci kez seçmekti ([toggleFormat] o durumda kaldırıyor). Hiçbir
/// yerde yazmadığı için bulunamıyordu; kullanıcının bildiği tek çıkış
/// "Biçimi temizle" idi, o da kalın/italik dahil HER ŞEYİ siliyordu. Artık
/// palet kendi "Kaldır"ını taşıyor ve yalnız o biçmi düşürüyor.
///
/// Bekleyen (henüz metne yazılmamış) biçim de düşer: kullanıcı renk seçip
/// hiç yazmadan vazgeçmiş olabilir.
bool removeRichFormat(WrapTextController controller, RichFormat format) {
  final selection = controller.selection;
  if (!selection.isValid) return false;
  var changedPending = false;
  if (controller.pendingFormats.containsKey(format)) {
    controller.togglePendingFormat(
      format,
      controller.pendingFormats[format],
    );
    changedPending = true;
  }
  final display = controller.text;
  final logical = stripWrapAnchors(display);
  final start = wrapToLogicalOffset(display, selection.start);
  final end = wrapToLogicalOffset(display, selection.end);
  if (start == end) {
    // İmleç: biçim gerçekten oradaysa [toggleFormat] o kesintisiz parçadan
    // kaldırır. Değilse metne dokunmaz (ve boş kutu da açmaz — bekleyen
    // biçim yukarıda zaten temizlendi).
    if (!activeFormats(logical, start, end).has(format)) return changedPending;
    final result = toggleFormat(logical, start, end, format);
    if (result.pending != null) return changedPending;
    return _write(controller, logical, start, end, (
          text: result.text,
          start: result.start,
          end: result.end,
        )) ||
        changedPending;
  }
  return _write(
        controller,
        logical,
        start,
        end,
        setRangeFormat(logical, start, end, format, null),
      ) ||
      changedPending;
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
  await showAppSheet<void>(
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
