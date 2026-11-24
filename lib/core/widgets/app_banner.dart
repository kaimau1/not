import 'package:flutter/material.dart';

import '../../app/theme/app_design.dart';
import '../../app/theme/app_tokens.dart';

/// **ŞERİT** (P62 ortak dil, docs/plan_tasarim_A.md §5): içerikle AYNI AKIŞTA
/// duran kalıcı uyarı/durum satırı — "yeni sürüm var", "zamanı gelenler",
/// "ekler bekliyor", "yalnız bu cihazda", düzenleme modunun ipucu satırı.
/// Hiçbir şeyin ÜSTÜNE binmez: yer kaplar, alttakini iter.
///
/// Geçici (kendiliğinden kalkan) ileti bu DEĞİL — o `AppNotice`.
///
/// Tek satır 44 dp; [subtitle] varsa içerik kadar. Renk [tone]'dan gelir;
/// yeni renk uydurulmaz. Boyu ANİMASYONLA değişmez (kasma listesi madde 6):
/// görünür/gizli tek adımda.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.detail,
    this.tone = AppTone.neutral,
    this.trailing,
    this.onTap,
    this.progress,
  });

  final String title;
  final String? subtitle;

  /// Başlıkla AYNI satırdaki ikincil bilgi (`meta` stili, ör. tarih). Verilince
  /// şerit TEK SATIR, tam 44 dp (zamanı gelenler şeridi, F74.3).
  final String? detail;
  final IconData? icon;
  final AppTone tone;

  /// Sağdaki küçük parça: eylem düğmesi, sayı rozeti, ok.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 0–1: şeridin dibinde ince ilerleme çizgisi (indirme, yükleme).
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = tone.colors(theme.colorScheme);
    final text = AppText.of(theme);
    final row = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppIconSize.m, color: c.fg),
          const SizedBox(width: AppSpace.s),
        ],
        Expanded(
          child: detail != null
              ? Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: text.label.copyWith(color: c.fg),
                      ),
                      TextSpan(
                        text: '  ·  $detail',
                        style: text.meta.copyWith(color: c.fg),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.label.copyWith(color: c.fg),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: text.meta.copyWith(color: c.fg)),
                  ],
                ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpace.s),
          IconTheme.merge(
            data: IconThemeData(size: AppIconSize.m, color: c.fg),
            child: trailing!,
          ),
        ],
      ],
    );
    final tokens = AppTokens.fromTheme(theme);
    return Material(
      color: c.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        side: BorderSide(color: tokens.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (detail != null)
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpace.m),
                  child: row,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.m,
                    vertical: AppSpace.s,
                  ),
                  child: row,
                ),
              ),
            if (progress != null)
              LinearProgressIndicator(
                value: progress,
                minHeight: AppSpace.xxs,
                color: c.fg,
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }
}
