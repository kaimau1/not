import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../app/theme/app_tokens.dart';
import '../domain/day_key.dart';
import 'calendar_views.dart' show kMonthPages, monthAtIndex, monthIndexOf;

/// Ayın ilk günü.
DateTime monthOf(DateTime d) => DateTime(d.year, d.month);

/// Ay ızgarasının ilk hücresi (yerel ayarın haftabaşına göre) — 6 × 7 hücre.
DateTime gridStartFor(DateTime month, int firstDayOfWeekIndex) {
  final first = monthOf(month);
  // DateTime.weekday: 1 = Pazartesi … 7 = Pazar; Material: 0 = Pazar.
  final offset = (first.weekday % 7 - firstDayOfWeekIndex + 7) % 7;
  return DateTime(first.year, first.month, 1 - offset);
}

/// Gün hücresinin boyu (dp): sayfa boyu = 6 × bu (iki yerde yazılmasın).
const double _kCell = 44;

/// **AY IZGARASI** (TAKVIM_PLANI F47.2/F47.3, K7: kendi çizimimiz). Dolu
/// günlerin altında nokta. Gün satırları PARMAĞI İZLEYEN sayfa (P62 PA8,
/// plan_tasarim_A §6.2): takvimin öbür dönem sayfalarıyla aynı his. Hafta
/// günü başlığı ve (genişte) ay başlığı sabit. Hücre başına sağlayıcı /
/// abonelik YOK — [busyOf] sayfa KURULURKEN bir kez çağrılır.
class MonthGrid extends StatefulWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.busyOf,
    this.busyKey,
    required this.onSelect,
    required this.onMonthChanged,
    this.showHeader = true,
    this.swipeEnabled = true,
    this.now,
  });

  final DateTime month;
  final DateTime selected;

  /// Ayın ızgarasında kaydı olan günlerin anahtarları (`YYYY-MM-DD`).
  final Set<String> Function(DateTime month) busyOf;

  /// [busyOf]'un sonucunu değiştiren veri (ör. takvim verisi örneği): aynı
  /// kaldıkça kurulmuş ay sayfası yeniden KURULMAZ (S34).
  final Object? busyKey;
  final ValueChanged<DateTime> onSelect;

  /// Görünen ay değişti (kaydırma ya da ‹ ›) — sayfa OTURUNCA bildirilir:
  /// geçiş sürerken çağıranın yeniden kurulması iki sayfayı birden kurardı
  /// (S34). MUTLAK ay: çok sayfalı geçişte ara sayfalar yanlış ay üretmez.
  final ValueChanged<DateTime> onMonthChanged;
  final bool showHeader;

  /// Yatay kaydırmayla ay değişimi (Ayarlar → Takvim kaydırma).
  final bool swipeEnabled;

  /// Test için "bugün".
  final DateTime? now;

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  late final PageController _pages = PageController(
    initialPage: monthIndexOf(widget.month),
  );

  /// Kurulmuş ay sayfaları (dizin → widget): çağıran yeniden kurulunca aynı
  /// örnek döner, sayfa ve 42 hücre yeniden kurulmaz. Seçim, bugün ya da
  /// veri değişince boşalır.
  final _built = <int, Widget>{};

  @override
  void didUpdateWidget(MonthGrid old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected ||
        old.now != widget.now ||
        old.showHeader != widget.showHeader ||
        !identical(old.busyKey, widget.busyKey) ||
        widget.busyKey == null) {
      _built.clear();
    }
    // Dışarıdan ay değişti (gri güne dokunuş, "Bugün"): sayfa oraya gider —
    // takvimin dönem sayfalarıyla aynı kural (uzaksa atlar). Yalnız ay
    // DEĞİŞTİYSE: çekiş sürerken gelen başka kurulum sayfayı geri çekmesin.
    if (old.month != widget.month &&
        _pages.hasClients &&
        monthIndexOf(widget.month) != _pages.page?.round()) {
      _go(monthIndexOf(widget.month));
    }
  }

  bool _settled(ScrollNotification n) {
    if (n is ScrollEndNotification && n.depth == 0 && _pages.hasClients) {
      final month = monthAtIndex(_pages.page!.round());
      if (month != widget.month) widget.onMonthChanged(month);
    }
    return false;
  }

  void _go(int page) {
    if (!_pages.hasClients) return;
    final current = _pages.page?.round() ?? page;
    final target = page.clamp(0, kMonthPages - 1);
    if ((target - current).abs() > 3) {
      _pages.jumpToPage(target);
    } else {
      _pages.animateToPage(
        target,
        duration: AppMotion.of(context, AppMotion.medium),
        curve: AppMotion.emphasized,
      );
    }
  }

  void _step(int delta) =>
      _go((_pages.page?.round() ?? monthIndexOf(widget.month)) + delta);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final firstDow = material.firstDayOfWeekIndex;
    final today = startOfDay(widget.now ?? DateTime.now());
    final labelStyle = AppText.of(theme).meta
        .copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.s, 0, AppSpace.s, AppSpace.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader)
            Row(
              children: [
                IconButton(
                  tooltip: l10n.calendarPrevMonth,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _step(-1),
                ),
                Expanded(
                  child: Text(
                    DateFormat.yMMMM().format(widget.month),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.calendarNextMonth,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _step(1),
                ),
              ],
            ),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpace.xs,
                      ),
                      child: Text(
                        material.narrowWeekdays[(firstDow + i) % 7],
                        style: labelStyle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Boy SABİT (geniş ekranda kaydırma görünümü içinde: sınırsız boy
          // olmasın). Komşu ay yalnız çekiş başlayınca kurulur
          // (allowImplicitScrolling kapalı).
          SizedBox(
            height: 6 * _kCell,
            child: NotificationListener<ScrollNotification>(
              onNotification: _settled,
              child: PageView.builder(
                controller: _pages,
                itemCount: kMonthPages,
                physics: widget.swipeEnabled
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemBuilder: (context, i) => _built.putIfAbsent(i, () {
                  final month = monthAtIndex(i);
                  return _MonthPage(
                    month: month,
                    start: gridStartFor(month, firstDow),
                    busy: widget.busyOf(month),
                    today: today,
                    selected: widget.selected,
                    onTap: widget.onSelect,
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir ayın altı gün satırı (sayfa).
class _MonthPage extends StatelessWidget {
  const _MonthPage({
    required this.month,
    required this.start,
    required this.busy,
    required this.today,
    required this.selected,
    required this.onTap,
  });

  final DateTime month;
  final DateTime start;
  final Set<String> busy;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var w = 0; w < 6; w++)
        Row(
          children: [
            for (var d = 0; d < 7; d++)
              Expanded(
                child: _DayCell(
                  day: DateTime(start.year, start.month, start.day + w * 7 + d),
                  inMonth:
                      DateTime(
                        start.year,
                        start.month,
                        start.day + w * 7 + d,
                      ).month ==
                      month.month,
                  today: today,
                  selected: selected,
                  busy: busy,
                  onTap: onTap,
                ),
              ),
          ],
        ),
    ],
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.today,
    required this.selected,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final DateTime today;
  final DateTime selected;
  final Set<String> busy;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final isSelected = day == startOfDay(selected);
    final hasItems = busy.contains(dayKey(day));
    final fg = isSelected
        ? scheme.onPrimary
        : isToday
        ? scheme.primary
        : inMonth
        ? scheme.onSurface
        : scheme.onSurfaceVariant.withValues(alpha: AppAlpha.muted);
    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat.yMMMMEEEEd().format(day),
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onTap(day),
        radius: _kCell / 2,
        child: SizedBox(
          height: _kCell,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : null,
                  border: isToday && !isSelected
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: fg,
                    fontWeight: isToday || isSelected
                        ? AppWeight.strong
                        : AppWeight.regular,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasItems
                      ? (inMonth
                            ? scheme.primary
                            : scheme.primary.withValues(
                                alpha: AppAlpha.disabled,
                              ))
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
