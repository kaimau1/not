import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/stable_value.dart';
import '../../calendar/data/calendar_repository.dart';
import '../../calendar/domain/task_item.dart';
import '../../settings/settings_providers.dart' show sharedPreferencesProvider;
import '../domain/due_items.dart';
import '../domain/note.dart';
import '../presentation/notes_providers.dart' show NoteListSlices;
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

bool _sameDueNote(Note a, Note b) =>
    identical(a, b) ||
    (a.id == b.id &&
        a.reminderAt == b.reminderAt &&
        a.locked == b.locked &&
        (a.locked || a.displayTitle.trim() == b.displayTitle.trim()));

bool _sameDueNotes(List<Note> a, List<Note> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_sameDueNote(a[i], b[i])) return false;
  }
  return true;
}

final _dueItemsNotesBox = Provider<StableBox<List<Note>>>((ref) => StableBox());
final _dueNextNotesBox = Provider<StableBox<List<Note>>>((ref) => StableBox());
final _dueItemsBox = Provider<StableBox<List<DueItem>>>((ref) => StableBox());

List<Note> _notes(Ref ref, Provider<StableBox<List<Note>>> boxProvider) {
  final box = ref.watch(boxProvider);
  return ref.watch(
    notesStreamProvider.select(
      (async) => box.keep(
        NoteListSlices.of(async.value ?? const <Note>[]).activeReminded,
        _sameDueNotes,
      ),
    ),
  );
}

List<TaskItem> _tasks(Ref ref) =>
    ref.watch(tasksStreamProvider).value ?? const [];

/// Zamanı gelmiş, kapatılmamış hatırlatıcı ve görevler (eskisi önce).
final dueItemsProvider = Provider<List<DueItem>>((ref) {
  final now = ref.watch(dueClockProvider);
  final box = ref.watch(_dueItemsBox);
  return box.keep(
    dueItems(
      notes: _notes(ref, _dueItemsNotesBox),
      tasks: _tasks(ref),
      now: now,
      dismissed: ref.watch(dueDismissedProvider),
      lockedTitle: '🔒',
    ),
    sameValues,
  );
});

/// Şeridin/rozetin değişeceği bir sonraki an.
final dueNextProvider = Provider<DateTime?>(
  (ref) => nextDueAfter(
    notes: _notes(ref, _dueNextNotesBox),
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
