import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_alarms.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/line_task_chip.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/reminder_level.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Not içi hatırlatıcı/görev satırı + bildirim önem düzeyi (2026-11-08).
void main() {
  test('görev: düzey, kişi, Gmail kayda gider ve geri okunur', () {
    const t = TaskItem(
      id: 't',
      title: 'Ara',
      due: '2026-11-09',
      dueTime: '14:30',
      reminders: [0],
      noteId: 'n',
      noteItemId: 'i1',
      level: 'urgent',
      contact: 'Ayşe',
      gmailLink: 'https://mail.google.com/mail/u/0/#inbox/abc',
    );
    final back = TaskItem.fromMap('t', t.toMap());
    expect(back.level, 'urgent');
    expect(back.contact, 'Ayşe');
    expect(back.gmailLink, t.gmailLink);
    expect(back.extras, isEmpty);
    // Boş alanlar yazılmaz (eski kayıtlar şişmesin).
    expect(const TaskItem(id: 'x').toMap().containsKey('level'), isFalse);
  });

  test('görev alarmı düzeyi taşır; düzey değişince yeniden kurulur', () {
    const t = TaskItem(
      id: 't',
      title: 'Ara',
      due: '2026-11-09',
      dueTime: '14:30',
      reminders: [0],
      level: 'low',
    );
    final now = DateTime(2026, 11, 8, 12);
    final a = calendarAlarms(events: const [], tasks: const [t], now: now);
    expect(a.single.level, 'low');
    final b = calendarAlarms(
      events: const [],
      tasks: [t.copyWith(level: 'urgent')],
      now: now,
    );
    expect(a.single.signature, isNot(b.single.signature));
  });

  test('düzey: boş = sık (eski kanal), bilinmeyen de sık', () {
    expect(ReminderLevel.parse(''), ReminderLevel.high);
    expect(ReminderLevel.high.channelId, 'reminders');
    expect(ReminderLevel.parse('zzz'), ReminderLevel.high);
    expect(ReminderLevel.parse('urgent').channelId, 'reminders_urgent');
  });

  test('notun hatırlatıcı düzeyi kayda gider; kaldırınca sıfırlanır', () {
    final n = Note(
      id: 'n',
      type: NoteType.text,
      reminderAt: DateTime(2026, 11, 9, 9),
      reminderLevel: 'low',
    );
    expect(n.toMap()['reminderLevel'], 'low');
    expect(n.copyWith(clearReminderAt: true).reminderLevel, '');
  });

  testWidgets('satır çipi bağlı görevin saatini gösterir', (tester) async {
    final due = DateTime.now().add(const Duration(days: 1));
    final task = TaskItem(
      id: 't',
      title: 'Ara',
      due:
          '${due.year}-${due.month.toString().padLeft(2, '0')}-'
          '${due.day.toString().padLeft(2, '0')}',
      dueTime: '14:30',
      reminders: const [0],
      noteId: 'n',
      noteItemId: 'i1',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tasksStreamProvider.overrideWith((ref) => Stream.value([task])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('tr'),
          home: Scaffold(
            body: Row(
              children: [
                LineTaskChip(noteId: 'n', itemId: 'i1'),
                LineTaskChip(noteId: 'n', itemId: 'yok'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('line-task-i1')), findsOneWidget);
    expect(find.byKey(const ValueKey('line-task-yok')), findsNothing);
    expect(find.textContaining('14:30'), findsOneWidget);
  });
}
