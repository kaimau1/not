import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/task_item.dart';
import '../../settings/settings_providers.dart' show sharedPreferencesProvider;
import '../domain/due_items.dart';
import '../domain/note.dart';
import 'notes_repository.dart';

/// Şeridin "şimdi"si: yalnız gerektiğinde ilerler — bir sonraki hatırlatıcı
/// anına kurulan TEK seferlik zamanlayıcı ([armFor]) ve uygulama öne
/// gelince. Yoklama yok (pil).
final dueClockProvider = NotifierProvider<DueClock, DateTime>(DueClock.new);

class DueClock extends Notifier<DateTime> {
  Timer? _timer;
  AppLifecycleListener? _life;

  @override
  DateTime build() {
    _life ??= AppLifecycleListener(onResume: refresh);
    ref.onDispose(() {
      _timer?.cancel();
      _life?.dispose();
      _life = null;
    });
    return DateTime.now();
  }

  void refresh() => state = DateTime.now();

  /// [at] anında (bir saniye sonra) [refresh]; null = kurma.
  void armFor(DateTime? at) {
    _timer?.cancel();
    _timer = null;
    if (at == null) return;
    var wait = at.difference(DateTime.now()) + const Duration(seconds: 1);
    if (wait.isNegative) wait = Duration.zero;
    _timer = Timer(wait, refresh);
  }
}

/// Kapatılan şerit maddeleri (anahtar, bkz. [DueItem.key]) — cihaz tercihi.
final dueDismissedProvider = NotifierProvider<DueDismissed, Set<String>>(
  DueDismissed.new,
);

class DueDismissed extends Notifier<Set<String>> {
  static const _key = 'due_banner_dismissed';
  static const _max = 60;

  @override
  Set<String> build() =>
      (ref.read(sharedPreferencesProvider).getStringList(_key) ?? const [])
          .toSet();

  void dismiss(Iterable<String> keys) {
    final list = [...state, ...keys];
    final kept = list.length > _max ? list.sublist(list.length - _max) : list;
    state = kept.toSet();
    unawaited(ref.read(sharedPreferencesProvider).setStringList(_key, kept));
  }
}

List<Note> _notes(Ref ref) => ref.watch(notesStreamProvider).value ?? const [];
List<TaskItem> _tasks(Ref ref) =>
    ref.watch(tasksStreamProvider).value ?? const [];

/// Zamanı gelmiş, kapatılmamış hatırlatıcı ve görevler (eskisi önce).
final dueItemsProvider = Provider<List<DueItem>>((ref) {
  final now = ref.watch(dueClockProvider);
  return dueItems(
    notes: _notes(ref),
    tasks: _tasks(ref),
    now: now,
    dismissed: ref.watch(dueDismissedProvider),
    lockedTitle: '🔒',
  );
});

/// Şeridin/rozetin değişeceği bir sonraki an.
final dueNextProvider = Provider<DateTime?>(
  (ref) => nextDueAfter(
    notes: _notes(ref),
    tasks: _tasks(ref),
    now: ref.watch(dueClockProvider),
  ),
);

/// Uygulama simgesi rozeti (bkz. [badgeCount]).
final dueBadgeProvider = Provider<int>(
  (ref) => badgeCount(
    due: ref.watch(dueItemsProvider),
    tasks: _tasks(ref),
    now: ref.watch(dueClockProvider),
  ),
);
