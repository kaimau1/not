import 'package:flutter/material.dart';

/// Notlar yüklenirken ızgaranın İSKELETİ — ortada dönen tek bir çark
/// yerine kartların yerini tutan, yumuşakça nabız atan kutular (kullanıcı
/// isteği 2026-10-17: "uygulama olmamış hissi uyandırıyor; premium
/// görünüm"). Yükleme bitince gerçek kartlar AYNI yerlerde belirir — ekran
/// boş/dolu arasında zıplamaz.
///
/// Maliyet: tek bir denetleyici bütün iskeletin saydamlığını oynatır
/// (kutu başına animasyon yok, gölge/gradyan yok).
class NoteGridSkeleton extends StatefulWidget {
  const NoteGridSkeleton({super.key, required this.columns});

  final int columns;

  @override
  State<NoteGridSkeleton> createState() => _NoteGridSkeletonState();
}

class _NoteGridSkeletonState extends State<NoteGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  // Masonry hissi: sütunlarda farklı yükseklikte kartlar (sabit desen —
  // her açılışta aynı, titremez).
  static const _heights = [132.0, 92.0, 168.0, 110.0, 148.0, 84.0, 124.0];

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columns = widget.columns.clamp(1, 6);
    final color = scheme.surfaceContainerHigh;
    Widget card(double h) => Container(
      height: h,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    final opacity = Tween<double>(
      begin: 0.45,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: ClipRect(
        child: FadeTransition(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        for (var i = 0; i < 4; i++)
                          card(_heights[(c * 3 + i) % _heights.length]),
                      ],
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
