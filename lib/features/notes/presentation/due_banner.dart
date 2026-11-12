import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../data/due_state.dart';
import '../data/reminder_service.dart' show reminderTimePrefix;
import '../domain/due_items.dart';

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
    final first = items.first;
    final title = first.title.isEmpty ? l10n.remindersUntitled : first.title;
    final when = reminderTimePrefix(first.at, l10n: l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Material(
        key: const ValueKey('due-banner'),
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(first),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  first.taskId.isEmpty
                      ? Icons.alarm_rounded
                      : Icons.task_alt_rounded,
                  size: 20,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: '  ·  $when'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
                if (items.length > 1)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.onSecondaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${items.length - 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  key: const ValueKey('due-banner-close'),
                  tooltip: l10n.close,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: scheme.onSecondaryContainer,
                  ),
                  onPressed: () => ref
                      .read(dueDismissedProvider.notifier)
                      .dismiss([for (final i in items) i.key]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
