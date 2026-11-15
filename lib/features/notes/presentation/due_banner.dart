import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/a11y/min_tap_target.dart';
import '../../../core/l10n_ext.dart';
import '../data/due_state.dart';
import '../data/reminder_service.dart' show reminderTimePrefix;
import '../domain/due_items.dart';
import '../../../app/theme/app_design.dart' show AppTone;
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/app_banner.dart';

/// **ANA EKRANDA ZAMANI GELENLER** (kullanıcı isteği 2026-11-08): tek
/// satırlık şerit — ilk maddenin başlığı ve saati, fazlası "+N". Dokununca
/// hedefe (nota / satırın notuna; notsuz görevde takvime) gider ve madde
/// görülmüş sayılır; ✕ hepsini kapatır. Yoksa sıfır yer.
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
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = AppText.of(Theme.of(context));
    final first = items.first;
    final title = first.title.isEmpty ? l10n.remindersUntitled : first.title;
    final ink = AppTone.attention.colors(scheme).fg;
    return Padding(
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
            // Görünen simge 18, dokunma hedefi 48 (F74.3) — şerit 44 dp
            // kalır (yerleşim değişmez).
            MinTapTarget(
              child: IconButton(
                key: const ValueKey('due-banner-close'),
                tooltip: l10n.close,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: AppIconSize.s, color: ink),
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
}
