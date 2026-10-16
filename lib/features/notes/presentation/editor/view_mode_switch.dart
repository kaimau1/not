import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';

/// Bir ekin notta NASIL durduğu.
///
/// Kullanıcı isteği 2026-10-16: "PDF'lerde klasik ve balonlu var ama üste
/// sabitleme yapamıyorum; bu mantık yalnız PDF için değil TÜM ekler için
/// geçerli olmalı — sabit, yüzen ve balonlu arasında kolay geçiş olmalı,
/// geçişin yeri ve düzeni de iyi değil."
///
/// Eskiden üç ayrı yol vardı ve hiçbiri ötekini bilmiyordu: görsel/video
/// için menüde "Üste sabitle", PDF için başlığın altındaki iki çip (Balonlu
/// / Klasik) ve ⋮ menüsü. Şimdi her ekin YANINDA aynı üçlü anahtar durur:
/// sayfada seçilince araç panelinde, sabit bölmede ayraç çubuğunda, balonlu
/// görünümde sayfa çubuğunda.
enum AttachmentView {
  /// Notun TEPESİNDE sabit bölme; not altında kayar.
  pinned,

  /// Sayfada serbest yüzer, metin etrafından akar (klasik görünüm).
  floating,

  /// Ek notun belgesi olur: üstte sayfa, üzerinde balon/vurgu/kalem, altta
  /// sayfa notu.
  bubbles,
}

/// [kind] türündeki ekin geçebileceği görünümler. Video/YouTube balonlu
/// olamaz (balon bir SAYFANIN oranlı uzayında yaşar, videonun sayfası yok —
/// zaman damgalı not onun karşılığı); sunum dosyası sabit bölmede çizilemez.
///
/// Web'de görsel balonluya ÇEVRİLEMEZ (belge üretimi dosya sistemi ister).
Set<AttachmentView> availableViews(Attachment a) => switch (a.kind) {
  AttachmentKind.image when kIsWeb => const {
    AttachmentView.pinned,
    AttachmentView.floating,
  },
  AttachmentKind.image || AttachmentKind.pdf => const {
    AttachmentView.pinned,
    AttachmentView.floating,
    AttachmentView.bubbles,
  },
  AttachmentKind.video => const {
    AttachmentView.pinned,
    AttachmentView.floating,
  },
  AttachmentKind.slide => const {
    AttachmentView.floating,
    AttachmentView.bubbles,
  },
  _ => const {},
};

/// Üçlü görünüm anahtarı: hap biçiminde, seçili kip dolu. Dar yerde
/// ([dense]) yalnız simgeler — yazılar ipucu (tooltip) olur.
class AttachmentViewSwitch extends StatelessWidget {
  const AttachmentViewSwitch({
    super.key,
    required this.current,
    required this.available,
    required this.onChanged,
    this.dense = false,
  });

  final AttachmentView current;
  final Set<AttachmentView> available;
  final ValueChanged<AttachmentView> onChanged;
  final bool dense;

  static IconData iconOf(AttachmentView view) => switch (view) {
    AttachmentView.pinned => Icons.vertical_align_top_rounded,
    AttachmentView.floating => Icons.wrap_text_rounded,
    AttachmentView.bubbles => Icons.chat_bubble_outline_rounded,
  };

  static String labelOf(BuildContext context, AttachmentView view) {
    final l10n = context.l10n;
    return switch (view) {
      AttachmentView.pinned => l10n.viewModePinned,
      AttachmentView.floating => l10n.viewModeFloating,
      AttachmentView.bubbles => l10n.viewModeBubbles,
    };
  }

  static String hintOf(BuildContext context, AttachmentView view) {
    final l10n = context.l10n;
    return switch (view) {
      AttachmentView.pinned => l10n.viewModePinnedHint,
      AttachmentView.floating => l10n.viewModeFloatingHint,
      AttachmentView.bubbles => l10n.viewModeBubblesHint,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final views = [
      for (final v in AttachmentView.values)
        if (available.contains(v)) v,
    ];
    if (views.length < 2) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: context.l10n.viewModeTitle,
      child: Container(
        key: const ValueKey('attachment-view-switch'),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in views)
              _Segment(
                key: ValueKey('view-${v.name}'),
                icon: iconOf(v),
                label: labelOf(context, v),
                hint: hintOf(context, v),
                selected: v == current,
                dense: dense,
                onTap: v == current ? null : () => onChanged(v),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.selected,
    required this.dense,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Tooltip(
      message: hint,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 30,
            padding: EdgeInsets.symmetric(horizontal: dense ? 9 : 11),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                if (!dense) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
