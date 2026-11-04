import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../a11y/motion.dart';

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
      margin: const EdgeInsets.only(bottom: kGridGap),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTokens.of(context).cardRadius),
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
            padding: const EdgeInsets.fromLTRB(kGridInset, 8, kGridInset, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: kGridGap),
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

/// Liste ekranlarının (arşiv, çöp, klasör, Gelen, hatırlatıcılar) ilk
/// yükleme iskeleti (F16.4): ortada dönen çark yerine kartların yeri.
/// Sütun sayısı genişlikten (ızgaradaki gibi ~260 dp'lik kart); kaydırma
/// içinde de güvenli — taşan kısım kırpılır.
class NoteListSkeleton extends StatelessWidget {
  const NoteListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      // Kısa alanda (ör. Hatırlatıcılar'ın üst şeridinin altı) kartlar
      // taşmasın: kaydırılamaz kapsayıcı yüksekliği serbest bırakır, fazlası
      // kırpılır.
      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: NoteGridSkeleton(
          key: const ValueKey('list-skeleton'),
          columns: (width / 260).floor().clamp(1, 4),
        ),
      );
    },
  );
}

/// İskeletten içeriğe geçişte içerik 200 ms'de belirir (TEMA_PLANI F31.7):
/// iskelet sliver'ı yerini bıraktığı için tek kalem solma yeter. Yalnız gerçekten
/// iskelet görünmüşse [play] true (disk özetinden gelen içerik solmaz, F25.2).
class SliverRevealFade extends StatefulWidget {
  const SliverRevealFade({super.key, required this.play, required this.sliver});

  final bool play;
  final Widget sliver;

  @override
  State<SliverRevealFade> createState() => _SliverRevealFadeState();
}

class _SliverRevealFadeState extends State<SliverRevealFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.short,
    value: widget.play ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) {
      if (motionOf(context)) {
        unawaited(_c.forward());
      } else {
        _c.value = 1;
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SliverFadeTransition(opacity: _c, sliver: widget.sliver);
}
