import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_design.dart' show AppTone;
import '../../../app/theme/app_tokens.dart';
import '../../../core/a11y/min_tap_target.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_banner.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../settings/settings_providers.dart' show sharedPreferencesProvider;
import '../data/due_state.dart';
import '../data/notes_repository.dart';
import '../data/reminder_service.dart' show reminderTimePrefix;
import '../domain/carry_over.dart';
import '../domain/due_items.dart';
import '../domain/note.dart';

/// Önceki günden devir şeridinin bugün için kapatılıp kapatılmadığı.
final carryOverDismissedDayProvider =
    NotifierProvider<CarryOverDismissedDayNotifier, String>(
      CarryOverDismissedDayNotifier.new,
    );

class CarryOverDismissedDayNotifier extends Notifier<String> {
  @override
  String build() =>
      ref
          .watch(sharedPreferencesProvider)
          .getString(CarryOverEngine.dismissedDayPrefsKey) ??
      '';

  void dismissFor(DateTime now) {
    final day = CarryOverEngine.dayKey(now);
    state = day;
    unawaited(
      ref
          .read(sharedPreferencesProvider)
          .setString(CarryOverEngine.dismissedDayPrefsKey, day),
    );
  }
}

/// **ANA EKRANDA ZAMANI GELENLER & ÖNCEKİ GÜNDEN DEVİR** (Faz 3):
/// Tek satırlık şeritler — zamanı gelen hatırlatıcılar ve önceki günden kalan
/// bitmemiş görevler için tek dokunuşla "Bugüne aktar" şeridi aynı yuvada
/// yaşar. İkisi de yoksa sıfır yer kaplar.
class DueBanner extends ConsumerStatefulWidget {
  const DueBanner({super.key});

  @override
  ConsumerState<DueBanner> createState() => _DueBannerState();
}

class _DueBannerState extends ConsumerState<DueBanner> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<DateTime?>(
      dueNextProvider,
      (_, next) => ref.read(dueClockProvider.notifier).armFor(next),
      fireImmediately: true,
    );
  }

  void _open(DueItem item) {
    ref.read(dueDismissedProvider.notifier).dismiss([item.key]);
    if (item.noteId.isNotEmpty) {
      unawaited(
        context.pushNote(
          noteRoutePath(
            item.noteId,
            query: item.itemId.isEmpty
                ? ''
                : '?item=${Uri.encodeQueryComponent(item.itemId)}',
          ),
        ),
      );
    } else {
      unawaited(context.push('/calendar'));
    }
  }

  Future<void> _applyCarryOver(CarryOverPlan plan) async {
    final repo = ref.read(notesRepositoryProvider);
    final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
    if (repo == null || plan.isEmpty) return;
    final now = DateTime.now();
    final batch = CarryOverEngine.buildCarryOverBatch(notes, plan, now: now);
    if (batch.updates.isEmpty) return;
    unawaited(repo.batchUpdateEach(batch.updates));
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(
        l10n.carryOverDone(plan.totalItems),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () => unawaited(repo.batchUpdateEach(batch.undoSnapshots)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Yalnız görünen içerik değişince yeniden kurulur (not akışı her tuşta
    // yayın yapar).
    ref.watch(
      dueItemsProvider.select(
        (l) => l.map((e) => '${e.key}|${e.title}').join('\n'),
      ),
    );
    final items = ref.read(dueItemsProvider);

    final todayKey = CarryOverEngine.dayKey(DateTime.now());
    final dismissedDay = ref.watch(carryOverDismissedDayProvider);
    final carryOverCount = dismissedDay == todayKey
        ? 0
        : ref.watch(
            notesStreamProvider.select((asyncNotes) {
              final list = asyncNotes.value;
              if (list == null || list.isEmpty) return 0;
              return CarryOverEngine.scan(list).totalItems;
            }),
          );

    if (items.isEmpty && carryOverCount == 0) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = AppText.of(Theme.of(context));

    Widget? dueWidget;
    if (items.isNotEmpty) {
      final first = items.first;
      final title = first.title.isEmpty ? l10n.remindersUntitled : first.title;
      final ink = AppTone.attention.colors(scheme).fg;
      dueWidget = Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.m,
          AppSpace.s,
          AppSpace.m,
          0,
        ),
        // P62 PA6: tek şerit kılığı (AppBanner); TEK SATIR 44 dp — başlık
        // `label`, tarih `meta` (F74.3) aynı satırda.
        child: AppBanner(
          key: const ValueKey('due-banner'),
          tone: AppTone.attention,
          icon: first.taskId.isEmpty
              ? Icons.alarm_rounded
              : Icons.task_alt_rounded,
          title: title,
          detail: reminderTimePrefix(first.at, l10n: l10n),
          onTap: () => _open(first),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (items.length > 1)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: AppAlpha.pressed),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.s,
                      vertical: AppSpace.xxs,
                    ),
                    child: Text(
                      '+${items.length - 1}',
                      style: text.badge.copyWith(color: ink),
                    ),
                  ),
                ),
              MinTapTarget(
                child: IconButton(
                  key: const ValueKey('due-banner-close'),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: AppIconSize.s,
                    color: ink,
                  ),
                  onPressed: () => ref
                      .read(dueDismissedProvider.notifier)
                      .dismiss([for (final i in items) i.key]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget? carryOverWidget;
    if (carryOverCount > 0) {
      final notes = ref.read(notesStreamProvider).value ?? const <Note>[];
      final plan = CarryOverEngine.scan(notes);
      if (plan.isNotEmpty) {
        final ink = AppTone.action.colors(scheme).fg;
        carryOverWidget = Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.m,
            AppSpace.s,
            AppSpace.m,
            0,
          ),
          child: AppBanner(
            key: const ValueKey('carry-over-banner'),
            tone: AppTone.action,
            icon: Icons.event_repeat_rounded,
            title: l10n.carryOverBanner(plan.totalItems),
            onTap: () => unawaited(_applyCarryOver(plan)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  key: const ValueKey('carry-over-action'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s),
                    foregroundColor: ink,
                  ),
                  onPressed: () => unawaited(_applyCarryOver(plan)),
                  child: Text(l10n.carryOverAction),
                ),
                MinTapTarget(
                  child: IconButton(
                    key: const ValueKey('carry-over-close'),
                    tooltip: l10n.close,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: AppIconSize.s,
                      color: ink,
                    ),
                    onPressed: () => ref
                        .read(carryOverDismissedDayProvider.notifier)
                        .dismissFor(DateTime.now()),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (dueWidget != null && carryOverWidget != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [dueWidget, carryOverWidget],
      );
    }
    return dueWidget ?? carryOverWidget ?? const SizedBox.shrink();
  }
}
