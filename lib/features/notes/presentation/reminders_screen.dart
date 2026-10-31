import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/relative_time.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'note_card.dart';
import 'notes_providers.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/friendly_error.dart';

/// Kullanıcının "ne zaman?" sorusuna en sık verdiği üç cevap. Tarih+saat
/// seçici İKİ ayrı diyalog demek (önce takvim, sonra saat); "yarın sabah"
/// gibi olağan bir istek için altı dokunuş gerekiyordu.
enum _QuickWhen { tonight, tomorrow, nextWeek, custom }

/// Tüm hatırlatıcıların tek yerden görüldüğü ekran: yaklaşan ve geçmiş
/// hatırlatıcılar listelenir; buradan düzenlenir, ertelenir, kaldırılır veya
/// yeni hatırlatıcılı not oluşturulur. (Sesli notun/asistanın kurduğu
/// hatırlatıcılar da burada görünür.)
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  /// Biçimlendirici SATIR BAŞINA değil, DİL BAŞINA bir kez kurulur.
  ///
  /// Eskiden `static DateFormat get _format => DateFormat(...)` idi ve her
  /// satırın her yeniden çiziminde yeni bir [DateFormat] kuruluyordu (yerel
  /// ayar sembollerinin aranması dahil). `static final` de olamazdı: o zaman
  /// ilk açılıştaki dil ömür boyu takılı kalır, kullanıcı Ayarlar'dan dili
  /// değiştirince tarihler eski dilde yazardı. Önbellek anahtarı DİL olunca
  /// iki sorun da kalmıyor.
  static final Map<String, DateFormat> _formatCache = {};

  static DateFormat _format() => _formatCache.putIfAbsent(
    Intl.defaultLocale ?? '',
    () => DateFormat('d MMMM y, EEEE HH:mm'),
  );

  /// Hızlı seçenekler levhası → seçilen zaman. `custom` takvimi açar.
  static Future<DateTime?> _pickWhen(
    BuildContext context,
    DateTime initial,
  ) async {
    final l10n = context.l10n;
    final choice = await showAppSheet<_QuickWhen>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.reminderQuickTitle,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wb_twilight_outlined),
              title: Text(l10n.reminderQuickTonight),
              onTap: () => Navigator.pop(sheetContext, _QuickWhen.tonight),
            ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(l10n.reminderQuickTomorrow),
              onTap: () => Navigator.pop(sheetContext, _QuickWhen.tomorrow),
            ),
            ListTile(
              leading: const Icon(Icons.next_week_outlined),
              title: Text(l10n.reminderQuickNextWeek),
              onTap: () => Navigator.pop(sheetContext, _QuickWhen.nextWeek),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.reminderQuickCustom),
              onTap: () => Navigator.pop(sheetContext, _QuickWhen.custom),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return null;
    final now = DateTime.now();
    switch (choice) {
      case _QuickWhen.tonight:
        final tonight = DateTime(now.year, now.month, now.day, 18);
        // Saat 18'i geçtiysek "bu akşam" bir saat sonrasıdır; geçmişe
        // hatırlatıcı kurulamaz (aşağıdaki denetim onu zaten reddederdi).
        return tonight.isAfter(now) ? tonight : now.add(const Duration(hours: 1));
      case _QuickWhen.tomorrow:
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9);
      case _QuickWhen.nextWeek:
        final next = now.add(const Duration(days: 7));
        return DateTime(next.year, next.month, next.day, 9);
      case _QuickWhen.custom:
        return _pickDateTime(context, initial);
    }
  }

  static Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      // Geçmiş TARİH seçilemez: geçmişe kurulan hatırlatıcı hiç planlanmıyor
      // (reminder_service gelecek olmayanı atlar), kullanıcı "kurdum" sanıp
      // hiçbir bildirim almıyordu.
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    // Bugünün geçmiş bir SAATİ de seçilebiliyor; sessizce "Geçmiş" bölümüne
    // düşürmek yerine uyar ve hiç kurma.
    if (!picked.isAfter(DateTime.now())) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showMessage(context.l10n.reminderInPast);
      }
      return null;
    }
    return picked;
  }

  Future<void> _editReminder(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final picked = await _pickWhen(
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
    final picked = await _pickWhen(
      context,
      DateTime.now().add(const Duration(hours: 1)),
    );
    if (picked == null || !context.mounted) return;
    // Hatırlatıcı TEK yazımda: createNote + ayrı setReminder arasında doküman
    // bir an hatırlatıcısız kalıyordu (boş-doküman penceresi kuralı).
    final id = await repo.createNote(NoteType.text, reminderAt: picked);
    if (context.mounted) await context.pushNote(noteRoutePath(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notesAsync = ref.watch(notesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.remindersTitle),
            // Kaç hatırlatıcı var: listeyi kaydırmadan görünsün.
            Consumer(
              builder: (context, ref, _) {
                final count = (ref.watch(notesStreamProvider).value ?? const [])
                    .where((n) => n.reminderAt != null)
                    .length;
                if (count == 0) return const SizedBox.shrink();
                return Text(
                  l10n.reminderCountLabel(count),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addReminder(context, ref),
        icon: const Icon(Icons.alarm_add_outlined),
        label: Text(l10n.newReminder),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(friendlyError(l10n, e)),
        ),
        data: (notes) {
          // Gizli klasör bastırması: hatırlatıcılı gizli-klasör notu burada
          // başlık+içerikle listeleniyordu (ana ekran kuralıyla aynı).
          final suppressed = ref.watch(suppressedFolderIdsProvider);
          final withReminder = [
            for (final n in notes)
              if (n.reminderAt != null &&
                  (n.folderId == null || !suppressed.contains(n.folderId)))
                n,
          ]..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
          if (withReminder.isEmpty) {
            return EmptyState(
              icon: Icons.alarm_outlined,
              title: l10n.remindersEmpty,
              subtitle: l10n.remindersEmptyHint,
              actionLabel: l10n.newReminder,
              actionIcon: Icons.alarm_add_outlined,
              onAction: () => _addReminder(context, ref),
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

  /// Hatırlatıcıyı kaldırmak TEK DOKUNUŞLUK ve GERİ ALINAMAZ bir işti:
  /// yanlış satıra basan kullanıcı zamanı yeniden kurmak zorunda kalıyordu
  /// (üstelik eski zamanı artık göremeden).
  void _remove(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final previous = note.reminderAt;
    repo.setReminder(note.id, null);
    showUndoSnackBar(
      context,
      message: context.l10n.reminderRemoved,
      undoLabel: context.l10n.undo,
      onUndo: () => repo.setReminder(note.id, previous),
    );
  }

  /// Geçmiş hatırlatıcıyı bir saat sonrasına atar — "şimdi vaktim yok"
  /// durumunun karşılığı. Zamanı elle yeniden seçmek üç diyalog demekti.
  void _snooze(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final previous = note.reminderAt;
    repo.setReminder(note.id, DateTime.now().add(const Duration(hours: 1)));
    showUndoSnackBar(
      context,
      message: context.l10n.reminderSnoozed,
      undoLabel: context.l10n.undo,
      onUndo: () => repo.setReminder(note.id, previous),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kilitli notun içeriği kimlik doğrulamasız yüzeylerde gösterilmez.
    final preview = note.locked
        ? ''
        : note.toPlainText().replaceAll('\n', ' · ');
    final title = note.locked
        ? l10n.lockedNote
        : (note.displayTitle.trim().isNotEmpty
              ? note.displayTitle.trim()
              : (preview.isEmpty ? l10n.remindersUntitled : preview));
    final at = note.reminderAt!;
    // GECİKMİŞ = zamanı geçmiş ama hâlâ duran hatırlatıcı. Eskiden yalnız
    // gri bir "Geçmiş" başlığının altındaydı; satırın kendisi yaklaşan bir
    // hatırlatıcıdan ayırt edilemiyordu.
    final overdue = past;
    final timeColor = overdue ? scheme.error : scheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => openNoteRoute(context, note),
        leading: Icon(
          overdue ? Icons.alarm_on_outlined : Icons.alarm,
          color: overdue ? scheme.error : scheme.primary,
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              RemindersScreen._format().format(at),
              style: TextStyle(color: timeColor),
            ),
            // "Ne zaman?" değil "ne kadar kaldı?": mutlak tarihi bugünün
            // tarihiyle kafadan çıkarmak gerekmesin.
            Row(
              children: [
                if (overdue) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.reminderOverdue,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  relativeTimeLabel(l10n, at),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (overdue)
              IconButton(
                tooltip: l10n.reminderSnooze,
                icon: const Icon(Icons.snooze_outlined, size: 20),
                onPressed: () => _snooze(context, ref),
              ),
            IconButton(
              tooltip: l10n.remindersEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: l10n.remindersRemove,
              icon: const Icon(Icons.alarm_off_outlined, size: 20),
              onPressed: () => _remove(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
