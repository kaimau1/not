import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../notes/data/due_state.dart' show dueClockProvider;
import '../../settings/settings_providers.dart';
import '../domain/agenda.dart';
import '../domain/day_key.dart';
import '../domain/holidays.dart';
import 'calendar_screen.dart' show calendarDataProvider, showCalendarDaySheet;
import 'calendar_views.dart';

/// Şeritte tek seferde görünen gün sayısı (bugün dahil; 2026-11-21).
const kHomeStripDays = 7;

/// Şeritte ileri doğru kaydırılabilen toplam gün sayısı (bugün dahil).
const kHomeStripTotalDays = 30;

/// **ANA EKRAN TAKVİM ŞERİDİ** (kullanıcı isteği 2026-11-08; güncelleme
/// 2026-11-21: "7 gün göstersin ve ileri doğru 30 gün kaydırılabilir olsun"):
///
/// Açıkken 7 eşit hücre görünür, yatay kaydırmayla bugünden ileri 30 güne
/// kadar gezilir. Üst satır gün (ay başında kısa ay adı, tatilde kırmızı,
/// bugün dolgulu hap), alt satır o günün kayıtları — hücre genişse ilk kaydın
/// adı, darsa renkli noktalar ya da üç harfli gün adı. Hücreye dokunmak günün
/// levhasını açar; basılı tutmak takvimi o günde açar. Sağdaki ⌃ şeridi tek
/// ince satıra indirir (tercih hatırlanır).
///
/// Takvim aboneliği (etkinlik/görev/hatırlatıcı) yalnız şerit AÇIKKEN kurulur
/// — kapalı ya da ayarla gizliyken ana ekran Firestore'a ek yük bindirmez.
class HomeCalendarStrip extends ConsumerWidget {
  const HomeCalendarStrip({super.key, this.now});

  /// Test için "bugün".
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(homeCalendarStripProvider)) return const SizedBox.shrink();
    final open = ref.watch(homeCalendarStripOpenProvider);
    // GÜN DÖNÜMÜ (2026-11-09): uygulama gece arka planda kalıp sabah öne
    // gelince şerit dünü "bugün" gösteriyordu (yeniden kurulmuyordu). Saat
    // öne gelişte ilerler; yalnız GÜN değişince yeniden kurulur.
    ref.watch(dueClockProvider.select(dayKey));
    final today = startOfDay(now ?? DateTime.now());
    void toggle() =>
        ref.read(homeCalendarStripOpenProvider.notifier).set(!open);
    if (!open) {
      return _CollapsedRow(today: today, onExpand: toggle);
    }
    final data = ref.watch(calendarDataProvider);
    return HomeCalendarStripView(
      today: today,
      data: data,
      onDayTap: (d) => unawaited(showCalendarDaySheet(context, ref, d)),
      onDayLongPress: (d) =>
          unawaited(context.push('/calendar?day=${dayKey(d)}')),
      onCollapse: toggle,
    );
  }
}

class _CollapsedRow extends StatelessWidget {
  const _CollapsedRow({required this.today, required this.onExpand});

  final DateTime today;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      key: const ValueKey('home-calendar-expand'),
      onTap: onExpand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.l,
          AppSpace.xxs,
          AppSpace.s,
          AppSpace.xxs,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_view_week_outlined,
              size: AppIconSize.xs,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                DateFormat.MMMMEEEEd().format(today),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.of(theme).meta,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: AppIconSize.s,
              color: scheme.onSurfaceVariant,
              semanticLabel: context.l10n.homeCalendarStripExpand,
            ),
          ],
        ),
      ),
    );
  }
}

/// Saf çizim (sağlayıcısız; test edilebilir).
class HomeCalendarStripView extends StatelessWidget {
  const HomeCalendarStripView({
    super.key,
    required this.today,
    required this.data,
    required this.onDayTap,
    this.onDayLongPress,
    this.onCollapse,
  });

  final DateTime today;
  final CalendarData data;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime>? onDayLongPress;
  final VoidCallback? onCollapse;

  static const double _stripHeight = 38;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final end = DateTime(
      today.year,
      today.month,
      today.day + kHomeStripTotalDays,
    );
    final byDay = data.range(today, end);
    return Padding(
      // SIKI (kullanıcı 2026-11-09: "takvim satırı fazla yer kaplıyor,
      // boşluğu kapat"): alt dolgu yok, 7 gün tam eni doldurur ve yatay
      // kaydırmayla ileri doğru 30 gün gezilir.
      padding: const EdgeInsetsDirectional.only(start: AppSpace.s),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _stripHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = constraints.maxWidth / kHomeStripDays;
                  return ListView.builder(
                    key: const ValueKey('home-calendar-scroll'),
                    scrollDirection: Axis.horizontal,
                    // İlk karede yalnız görünen 7 gün kurulur (S24 bütçesi).
                    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                    itemExtent: cellWidth,
                    itemCount: kHomeStripTotalDays,
                    itemBuilder: (context, i) {
                      final d = DateTime(today.year, today.month, today.day + i);
                      return _DayCell(
                        day: d,
                        today: today,
                        width: cellWidth,
                        entries: byDay[dayKey(d)] ?? const [],
                        holiday: data.holidays.on(d),
                        onTap: () => onDayTap(d),
                        onLongPress: onDayLongPress == null
                            ? null
                            : () => onDayLongPress!(d),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          if (onCollapse != null)
            SizedBox(
              width: 28,
              child: IconButton(
                key: const ValueKey('home-calendar-collapse'),
                tooltip: l10n.homeCalendarStripCollapse,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: _stripHeight,
                ),
                // KÖK NEDEN (boşluk): varsayılan 48 dp dokunma alanı bütün
                // şeridi 48 dp'ye çekiyordu.
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconSize: AppIconSize.s,
                icon: const Icon(Icons.expand_less),
                onPressed: onCollapse,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.width,
    required this.entries,
    required this.holiday,
    required this.onTap,
    this.onLongPress,
  });

  final DateTime day;
  final DateTime today;
  final double width;
  final List<AgendaEntry> entries;
  final Holiday? holiday;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppText.of(theme);
    final isToday = day == today;
    final isMonthStart = day.day == 1 && !isToday;
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final red = holiday != null;
    final numberColor = isToday
        ? scheme.onPrimary
        : red
        ? scheme.error
        : weekend
        ? scheme.primary
        : scheme.onSurface;
    final weekday = DateFormat.E().format(day);
    final monthShort = isMonthStart ? DateFormat.MMM().format(day) : null;
    final title =
        holiday?.name ??
        (entries.isEmpty ? null : entryTitle(entries.first, l10n));
    final count = entries.length + (holiday != null ? 1 : 0);
    final innerWidth = width - 6;
    final wide = innerWidth >= 60;
    return Semantics(
      button: true,
      label: [
        DateFormat.MMMMEEEEd().format(day),
        if (holiday != null) holiday!.name,
        for (final e in entries) entryTitle(e, l10n),
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.s),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          height: HomeCalendarStripView._stripHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
          decoration: BoxDecoration(
            color: red
                ? scheme.errorContainer.withValues(alpha: AppAlpha.muted)
                : isMonthStart
                ? scheme.primaryContainer.withValues(alpha: AppAlpha.muted)
                : count > 0
                ? scheme.surfaceContainerHigh
                : null,
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. satır: gün (bugün dolgulu hap, ay başında kısa ay adı).
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  decoration: isToday
                      ? BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.s),
                        )
                      : null,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (wide)
                          TextSpan(
                            text: '$weekday ',
                            style: text.badge.copyWith(
                              fontWeight: AppWeight.regular,
                            ),
                          ),
                        TextSpan(text: '${day.day}'),
                        if (monthShort != null)
                          TextSpan(
                            text: ' $monthShort',
                            style: text.badge.copyWith(
                              fontWeight: AppWeight.medium,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    style: text.label.copyWith(
                      fontWeight: AppWeight.strong,
                      color: numberColor,
                      height: 1.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              // 2. satır: kayıtlar ya da üç harfli gün adı.
              SizedBox(
                height: 13,
                child: count == 0
                    // KT-3: 24 dp altında tek harfe düşen ad yazılmaz.
                    ? (wide || innerWidth < 24
                          ? const SizedBox.shrink()
                          : Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  weekday,
                                  maxLines: 1,
                                  style: text.badge.copyWith(
                                    height: 1.15,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ))
                    : wide && title != null
                    ? Text(
                        count > 1 ? '$title +${count - 1}' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: text.badge.copyWith(
                          height: 1.15,
                          fontWeight: AppWeight.regular,
                          color: red ? scheme.error : scheme.onSurface,
                        ),
                      )
                    : _Dots(
                        colors: [
                          if (red) scheme.error,
                          for (final e in entries) entryColor(e, scheme),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final shown = colors.take(3).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final c in shown)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 0.75),
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
      ],
    );
  }
}
