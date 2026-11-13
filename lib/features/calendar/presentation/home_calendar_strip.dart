import 'dart:async';

import 'package:flutter/material.dart';
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

/// Şeritte görünen gün sayısı (bugün dahil).
const kHomeStripDays = 10;

/// **ANA EKRAN TAKVİM ŞERİDİ** (kullanıcı isteği 2026-11-08: "takvim zeminini
/// kaldır, yerine en üstte 2 satır yüksekliğinde takvim satırı getir;
/// bugünden itibaren 10 gün görünsün, yapılacaklar, tatiller vs görülsün,
/// isteğe göre açılıp kapansın, tıklanabilsin, düzenleme yapılabilsin").
///
/// Açıkken 10 eşit hücre: üst satır gün (tatilde kırmızı, bugün dolgulu),
/// alt satır o günün kayıtları — hücre genişse ilk kaydın adı, darsa renkli
/// noktalar. Hücreye dokunmak günün levhasını açar (kayıtlar, düzenle, SİL,
/// yeni etkinlik/görev); basılı tutmak takvimi o günde açar. Sağdaki ⌃
/// şeridi tek ince satıra indirir (tercih hatırlanır).
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const ValueKey('home-calendar-expand'),
      onTap: onExpand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
        child: Row(
          children: [
            Icon(
              Icons.calendar_view_week_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                DateFormat.MMMMEEEEd().format(today),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 18,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final end = DateTime(today.year, today.month, today.day + kHomeStripDays);
    final byDay = data.range(today, end);
    final days = [
      for (var i = 0; i < kHomeStripDays; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
    return Padding(
      // SIKI (kullanıcı 2026-11-09: "takvim satırı fazla yer kaplıyor,
      // boşluğu kapat"): alt dolgu yok, hücre 36 dp.
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      child: Row(
        children: [
          for (final d in days)
            Expanded(
              child: _DayCell(
                day: d,
                today: today,
                entries: byDay[dayKey(d)] ?? const [],
                holiday: data.holidays.on(d),
                onTap: () => onDayTap(d),
                onLongPress: onDayLongPress == null
                    ? null
                    : () => onDayLongPress!(d),
              ),
            ),
          if (onCollapse != null)
            SizedBox(
              width: 28,
              child: IconButton(
                key: const ValueKey('home-calendar-collapse'),
                tooltip: l10n.homeCalendarStripCollapse,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 36),
                // KÖK NEDEN (boşluk): varsayılan 48 dp dokunma alanı bütün
                // şeridi 48 dp'ye çekiyordu (hücreler 36).
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                iconSize: 18,
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
    required this.entries,
    required this.holiday,
    required this.onTap,
    this.onLongPress,
  });

  final DateTime day;
  final DateTime today;
  final List<AgendaEntry> entries;
  final Holiday? holiday;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    final red = holiday != null;
    final numberColor = isToday
        ? scheme.onPrimary
        : red
        ? scheme.error
        : weekend
        ? scheme.onSurfaceVariant
        : scheme.onSurface;
    final weekday = DateFormat.E().format(day);
    final title = holiday?.name ??
        (entries.isEmpty ? null : entryTitle(entries.first, l10n));
    final count = entries.length + (holiday != null ? 1 : 0);
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
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          decoration: BoxDecoration(
            color: red
                ? scheme.errorContainer.withValues(alpha: 0.35)
                : count > 0
                ? scheme.surfaceContainerHigh
                : null,
            borderRadius: BorderRadius.circular(AppRadius.s),
          ),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 60;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. satır: gün (bugün dolgulu hap).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            TextSpan(text: '${day.day}'),
                          ],
                        ),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: numberColor,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  // 2. satır: kayıtlar.
                  SizedBox(
                    height: 13,
                    child: count == 0
                        ? (wide
                              ? const SizedBox.shrink()
                              // Gün adı ÜÇ HARF (K-D4, F74.2): tek harf
                              // "P" Pazartesi mi Perşembe mi Pazar mı
                              // söylemiyordu. 360 dp'de hücre içi ~26 dp,
                              // "Cmt" 11 pt sığar; daha darda tek harf.
                              // Büyük yazıda (1,3×) "Cmt" hücreye sığmayıp
                              // "Cm" diye kesiliyordu (F80.2): sığmazsa
                              // küçülür, kesilmez.
                              : Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      c.maxWidth >= 24
                                          ? weekday
                                          : weekday.characters.first,
                                      maxLines: 1,
                                      style: AppText.of(Theme.of(context)).badge
                                          .copyWith(
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
                            style: TextStyle(
                              fontSize: 10,
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
              );
            },
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
