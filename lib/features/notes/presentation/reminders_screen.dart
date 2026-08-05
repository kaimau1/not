import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// Tüm hatırlatıcıların tek yerden görüldüğü ekran: yaklaşan ve geçmiş
/// hatırlatıcılar listelenir; buradan düzenlenir, kaldırılır veya yeni
/// hatırlatıcılı not oluşturulur. (Sesli notun/asistanın kurduğu
/// hatırlatıcılar da burada görünür.)
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  /// `static final` DEĞİL: biçimlendirici bir kez kurulsaydı ilk açılıştaki
  /// dili ömür boyu taşırdı — kullanıcı Ayarlar'dan dili değiştirince
  /// hatırlatıcı tarihleri eski dilde kalırdı.
  static DateFormat get _format => DateFormat('d MMMM y, EEEE HH:mm');

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _editReminder(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final picked = await _pickDateTime(
      context,
      note.reminderAt ?? DateTime.now().add(const Duration(hours: 1)),
    );
    if (picked == null) return;
    ref.read(notesRepositoryProvider)?.setReminder(note.id, picked);
  }

  /// Yeni hatırlatıcı: önce zaman seçilir, ardından o zamana kurulu boş bir
  /// not oluşturulup editör açılır.
  Future<void> _addReminder(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final picked = await _pickDateTime(
      context,
      DateTime.now().add(const Duration(hours: 1)),
    );
    if (picked == null || !context.mounted) return;
    final id = await repo.createNote(NoteType.text);
    repo.setReminder(id, picked);
    if (context.mounted) await context.push('/note/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context, ref),
        icon: const Icon(Icons.alarm_add_outlined),
        label: Text(l10n.newReminder),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(e.toString()),
        ),
        data: (notes) {
          final withReminder = [
            for (final n in notes)
              if (n.reminderAt != null) n,
          ]..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
          if (withReminder.isEmpty) {
            return EmptyState(
              icon: Icons.alarm_outlined,
              title: l10n.remindersEmpty,
              subtitle: l10n.remindersEmptyHint,
            );
          }
          final now = DateTime.now();
          final upcoming = [
            for (final n in withReminder)
              if (n.reminderAt!.isAfter(now)) n,
          ];
          final past = [
            for (final n in withReminder.reversed)
              if (!n.reminderAt!.isAfter(now)) n,
          ];
          // Düz kayıt listesi + builder: tembel kurulum, satırlar yalnız
          // görünür olunca (ve önizleme metni ancak o zaman) üretilir.
          final entries = <Object>[
            if (upcoming.isNotEmpty) l10n.remindersUpcoming,
            for (final n in upcoming) (note: n, past: false),
            if (past.isNotEmpty) l10n.remindersPast,
            for (final n in past) (note: n, past: true),
          ];
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              88 + MediaQuery.paddingOf(context).bottom,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              if (entry is String) return _SectionHeader(entry);
              final row = entry as ({Note note, bool past});
              return _ReminderTile(
                note: row.note,
                past: row.past,
                onEdit: () => _editReminder(context, ref, row.note),
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ReminderTile extends ConsumerWidget {
  const _ReminderTile({
    required this.note,
    required this.past,
    required this.onEdit,
  });

  final Note note;
  final bool past;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final preview = note.toPlainText().replaceAll('\n', ' · ');
    final title = note.title.trim().isNotEmpty
        ? note.title.trim()
        : (preview.isEmpty ? l10n.remindersUntitled : preview);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => context.push('/note/${note.id}'),
        leading: Icon(
          past ? Icons.alarm_on_outlined : Icons.alarm,
          color: past ? scheme.onSurfaceVariant : scheme.primary,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          RemindersScreen._format.format(note.reminderAt!),
          style: TextStyle(
            color: past ? scheme.onSurfaceVariant : scheme.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.remindersEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: l10n.remindersRemove,
              icon: const Icon(Icons.alarm_off_outlined, size: 20),
              onPressed: () =>
                  ref.read(notesRepositoryProvider)?.setReminder(note.id, null),
            ),
          ],
        ),
      ),
    );
  }
}
