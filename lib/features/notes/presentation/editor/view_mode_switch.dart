import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// ALT ŞERİTTE dosya eki olarak durur (kullanıcı isteği 2026-10-17: "alt
  /// kısımdaki ek kısmında da tüm türlerde uyum olmalı, geçiş kolay
  /// olmalı"). Eskiden bu dördüncü durum anahtarda yoktu — şeride inmek
  /// yalnız menülerdeki "Ek olarak taşı" ile, şeritten çıkmak da yalnız
  /// türüne göre değişen küçük düğmelerle oluyordu.
  attached,
}

/// [a]'nın geçebileceği görünümler. Video/YouTube ve ses balonlu olamaz
/// (balon bir SAYFANIN oranlı uzayında yaşar — zaman damgalı not onların
/// karşılığı). Sunum da sayfaya gömülür ve sabitlenir (2026-10-17).
///
/// METİN ve SES 2026-10-17'de katıldı: metin sayfada sayfası çevrilen bir
/// kâğıt kutusu (bkz. `TextPageBox`), tepede okunan bir bölme ve balonluda
/// A4 belge olur; ses sayfada ve tepede oynatıcı kartı olur.
///
/// Web'de görsel/metin balonluya ÇEVRİLEMEZ (belge üretimi dosya sistemi
/// ister). YouTube şeride inmez (dosyası yok; bağlantı sayfada ya da tepede
/// oynar).
Set<AttachmentView> availableViews(Attachment a) => switch (a.kind) {
  AttachmentKind.image || AttachmentKind.text when kIsWeb => const {
    AttachmentView.pinned,
    AttachmentView.floating,
    AttachmentView.attached,
  },
  AttachmentKind.image || AttachmentKind.pdf || AttachmentKind.text => const {
    AttachmentView.pinned,
    AttachmentView.floating,
    AttachmentView.bubbles,
    AttachmentView.attached,
  },
  AttachmentKind.video when a.webUrl.isNotEmpty => const {
    AttachmentView.pinned,
    AttachmentView.floating,
  },
  AttachmentKind.video || AttachmentKind.audio => const {
    AttachmentView.pinned,
    AttachmentView.floating,
    AttachmentView.attached,
  },
  // SUNUM 2026-10-17'de sayfaya gömülür ve sabitlenir (bkz. SlidePageBox).
  AttachmentKind.slide => const {
    AttachmentView.pinned,
    AttachmentView.floating,
    AttachmentView.bubbles,
    AttachmentView.attached,
  },
};

/// Görünüm anahtarı: iOS'un bölümlü denetimi gibi EŞİT genişlikte dilimler
/// ve seçili dilimin altında KAYAN bir zemin (seçim değişince yaylı bir
/// eğriyle yeni dilime kayar — anahtarın "hangi kipteyim" cevabı tek
/// bakışta, geçiş de gözle izlenir). Dar yerde ([dense]) yalnız simgeler —
/// yazılar ipucu (tooltip) olur. [compact] ek şeridindeki küçük döşemeler
/// için daha alçak ve sık dizilir.
class AttachmentViewSwitch extends StatelessWidget {
  const AttachmentViewSwitch({
    super.key,
    required this.current,
    required this.available,
    required this.onChanged,
    this.dense = false,
    this.compact = false,
  });

  final AttachmentView current;
  final Set<AttachmentView> available;
  final ValueChanged<AttachmentView> onChanged;
  final bool dense;
  final bool compact;

  /// Kayan zeminin süresi/eğrisi — uygulamanın öbür geçişleriyle aynı dil.
  static const slideDuration = Duration(milliseconds: 280);

  static IconData iconOf(AttachmentView view) => switch (view) {
    AttachmentView.pinned => Icons.vertical_align_top_rounded,
    AttachmentView.floating => Icons.wrap_text_rounded,
    AttachmentView.bubbles => Icons.chat_bubble_outline_rounded,
    AttachmentView.attached => Icons.attach_file_rounded,
  };

  static String labelOf(BuildContext context, AttachmentView view) {
    final l10n = context.l10n;
    return switch (view) {
      AttachmentView.pinned => l10n.viewModePinned,
      AttachmentView.floating => l10n.viewModeFloating,
      AttachmentView.bubbles => l10n.viewModeBubbles,
      AttachmentView.attached => l10n.viewModeAttached,
    };
  }

  static String hintOf(BuildContext context, AttachmentView view) {
    final l10n = context.l10n;
    return switch (view) {
      AttachmentView.pinned => l10n.viewModePinnedHint,
      AttachmentView.floating => l10n.viewModeFloatingHint,
      AttachmentView.bubbles => l10n.viewModeBubblesHint,
      AttachmentView.attached => l10n.viewModeAttachedHint,
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
    // SIĞMAZSA SİMGEYE İNER: eşit dilimler en uzun yazının boyunu alır;
    // dört kip ve uzun bir dil (Almanca, Rusça) dar panele sığmayabilir.
    // Sınırlı genişlik verilmişse (Expanded/Flexible içinde) yazılı hâlin
    // genişliği ölçülür, taşacaksa yalnız simgeler çizilir.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight =
            !dense &&
            !compact &&
            constraints.hasBoundedWidth &&
            _labeledWidth(context, views) > constraints.maxWidth;
        return _build(context, scheme, views, dense || tight);
      },
    );
  }

  /// Yazılı (dar olmayan) anahtarın yaklaşık genişliği: en uzun yazılı
  /// dilim × dilim sayısı + çerçeve.
  double _labeledWidth(BuildContext context, List<AttachmentView> views) {
    var widest = 0.0;
    for (final v in views) {
      final painter = TextPainter(
        text: TextSpan(
          text: labelOf(context, v),
          style: DefaultTextStyle.of(context).style.merge(
            const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > widest) widest = painter.width;
      painter.dispose();
    }
    return (widest + 16 + 5 + 22) * views.length + 8;
  }

  Widget _build(
    BuildContext context,
    ColorScheme scheme,
    List<AttachmentView> views,
    bool dense,
  ) {
    final index = views.indexOf(current);
    final n = views.length;
    final radius = compact ? 13.0 : 20.0;
    return Semantics(
      container: true,
      label: context.l10n.viewModeTitle,
      child: Container(
        key: const ValueKey('attachment-view-switch'),
        padding: EdgeInsets.all(compact ? 2 : 3),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        // Eşit dilimler: IntrinsicWidth, Row'daki Expanded çocukları EN
        // GENİŞ dilimin boyuna eşitler (kayan zemin her dilime aynı oturur).
        child: IntrinsicWidth(
          child: Stack(
            children: [
              if (index >= 0)
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: slideDuration,
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(
                      n == 1 ? 0 : -1 + 2 * index / (n - 1),
                      0,
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 1 / n,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(radius - 3),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final v in views)
                    Expanded(
                      child: _Segment(
                        key: ValueKey('view-${v.name}'),
                        icon: iconOf(v),
                        label: labelOf(context, v),
                        hint: hintOf(context, v),
                        selected: v == current,
                        dense: dense || compact,
                        compact: compact,
                        onTap: v == current
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onChanged(v);
                              },
                      ),
                    ),
                ],
              ),
            ],
          ),
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
    required this.compact,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final bool selected;
  final bool dense;
  final bool compact;
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
          child: SizedBox(
            height: compact ? 24 : 30,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 5 : (dense ? 8 : 11),
              ),
              // Renk de kayan zeminle AYNI sürede döner (zemin gelince yazı
              // beyazlaşır — iki ayrı an görünmesin).
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: fg),
                duration: AttachmentViewSwitch.slideDuration,
                curve: Curves.easeOutCubic,
                builder: (context, color, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: compact ? 14 : 16, color: color),
                    if (!dense) ...[
                      const SizedBox(width: 5),
                      Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: color,
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
