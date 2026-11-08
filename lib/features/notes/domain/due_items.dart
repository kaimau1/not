import '../../calendar/domain/task_item.dart';
import 'note.dart';

/// Zamanı gelmiş bir hatırlatıcı ya da görev (ana ekran şeridi ve uygulama
/// simgesi rozeti, kullanıcı isteği 2026-11-08).
class DueItem {
  const DueItem({
    required this.key,
    required this.title,
    required this.at,
    this.noteId = '',
    this.itemId = '',
    this.taskId = '',
  });

  /// Kapatma kaydının anahtarı: aynı hatırlatıcı yeniden kurulunca (başka
  /// zaman) yeniden görünür.
  final String key;
  final String title;
  final DateTime at;

  /// Hedef not (görevde bağlı not; yoksa '').
  final String noteId;

  /// Not içi görev satırı (madde kimliği).
  final String itemId;
  final String taskId;
}

/// Şeritte görünecekler, en eskisi önce: zamanı geçmiş (ve "Tamam"
/// denmemiş) not hatırlatıcıları + son anı geçmiş, tamamlanmamış görevler.
/// [dismissed] kapatılmış anahtarlar. Kilitli notun başlığı gösterilmez.
List<DueItem> dueItems({
  required Iterable<Note> notes,
  required Iterable<TaskItem> tasks,
  required DateTime now,
  Set<String> dismissed = const {},
  required String lockedTitle,
}) {
  final out = <DueItem>[];
  for (final n in notes) {
    final at = n.reminderAt;
    if (at == null || at.isAfter(now)) continue;
    if (n.deletedAt != null || n.archivedAt != null) continue;
    final key = 'note:${n.id}@${at.millisecondsSinceEpoch}';
    if (dismissed.contains(key)) continue;
    out.add(
      DueItem(
        key: key,
        title: n.locked ? lockedTitle : n.displayTitle.trim(),
        at: at,
        noteId: n.id,
      ),
    );
  }
  for (final t in tasks) {
    final at = t.dueAt;
    if (at == null || at.isAfter(now) || t.completed || t.deletedAt != null) {
      continue;
    }
    final key = 'task:${t.id}@${t.due}T${t.dueTime}';
    if (dismissed.contains(key)) continue;
    out.add(
      DueItem(
        key: key,
        title: t.title.trim(),
        at: at,
        noteId: t.noteId,
        itemId: t.noteItemId,
        taskId: t.id,
      ),
    );
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out;
}

/// Şerit/rozetin bir sonraki değişeceği an (gelecekteki en yakın
/// hatırlatıcı ya da görev). Tek seferlik zamanlayıcı buna kurulur —
/// yoklama yok.
DateTime? nextDueAfter({
  required Iterable<Note> notes,
  required Iterable<TaskItem> tasks,
  required DateTime now,
}) {
  DateTime? best;
  void take(DateTime? at) {
    if (at == null || !at.isAfter(now)) return;
    if (best == null || at.isBefore(best!)) best = at;
  }

  for (final n in notes) {
    if (n.deletedAt == null && n.archivedAt == null) take(n.reminderAt);
  }
  for (final t in tasks) {
    if (!t.completed && t.deletedAt == null) take(t.dueAt);
  }
  return best;
}

/// Rozet sayısı: açılmamış (kapatılmamış) zamanı gelmişler + bugünün
/// tamamlanmamış görevleri (aynı görev iki kez sayılmaz).
int badgeCount({
  required List<DueItem> due,
  required Iterable<TaskItem> tasks,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final ids = <String>{for (final d in due) d.key};
  final dueTasks = {for (final d in due) d.taskId};
  for (final t in tasks) {
    final day = t.dueDay;
    if (day == null || t.completed || t.deletedAt != null) continue;
    if (day != today || dueTasks.contains(t.id)) continue;
    ids.add('today:${t.id}');
  }
  return ids.length;
}
