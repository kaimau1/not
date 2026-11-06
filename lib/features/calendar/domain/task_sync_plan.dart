import 'task_item.dart';

/// **GOOGLE GÖREVLER EŞLEME PLANI** (TAKVIM_PLANI F50.4, K1).
///
/// Saf işlev: yerel görevler (Firestore) + Google'daki görevler → yapılacak
/// işler. Kural (§5): çakışmada `updated` daha yeni olan kazanır; silme iki
/// yöne de taşınır. Google saat ve tekrar TUTMAZ — `dueTime`, `repeat`,
/// hatırlatma, yıldız, not bağı yalnız bizde kalır ve eşlemede korunur.
///
/// "Değişti mi" ölçütü: yerelde `updatedAt` son başarılı eşlemeden
/// ([lastSync]) sonra mı; Google'da `updated` bağda saklanan son görülen
/// `updated`tan ([TaskItem.google]`.updated`) sonra mı. İçerik aynıysa
/// hiçbir yöne yazılmaz (eşlemenin kendi yazımı bir sonraki tura "değişiklik"
/// diye dönmesin).
class RemoteTask {
  const RemoteTask({
    required this.id,
    required this.listId,
    this.title = '',
    this.notes = '',
    this.due = '',
    this.completed = false,
    this.completedAt,
    this.parent = '',
    this.deleted = false,
    this.updated,
    this.etag = '',
  });

  final String id;

  /// Google liste kimliği.
  final String listId;
  final String title;
  final String notes;

  /// `YYYY-MM-DD` ya da ''.
  final String due;
  final bool completed;
  final DateTime? completedAt;

  /// Üst görevin Google kimliği ('' = üst düzey).
  final String parent;
  final bool deleted;
  final DateTime? updated;
  final String etag;
}

sealed class TaskSyncAction {
  const TaskSyncAction();
}

/// Yerel görev Google'a eklenecek.
class CreateRemote extends TaskSyncAction {
  const CreateRemote(this.local, this.remoteListId);
  final TaskItem local;
  final String remoteListId;
}

/// Yereldeki değişiklik Google'a yazılacak.
class UpdateRemote extends TaskSyncAction {
  const UpdateRemote(this.local, this.remote);
  final TaskItem local;
  final RemoteTask remote;
}

/// Yerelde silinen görev Google'dan silinecek.
class DeleteRemote extends TaskSyncAction {
  const DeleteRemote(this.local);
  final TaskItem local;
}

/// Google'daki yeni görev yerelde açılacak.
class CreateLocal extends TaskSyncAction {
  const CreateLocal(this.remote, this.localListId);
  final RemoteTask remote;
  final String localListId;
}

/// Google'daki değişiklik yerele yazılacak.
class UpdateLocal extends TaskSyncAction {
  const UpdateLocal(this.local, this.remote);
  final TaskItem local;
  final RemoteTask remote;
}

/// Google'da silinen görev yerelde çöpe.
class TrashLocal extends TaskSyncAction {
  const TrashLocal(this.local);
  final TaskItem local;
}

/// İki tarafın Google'da tutulan alanları aynı mı.
bool sameTaskContent(TaskItem l, RemoteTask r) =>
    l.title.trim() == r.title.trim() &&
    l.notes.trim() == r.notes.trim() &&
    l.due == r.due &&
    l.completed == r.completed;

/// Google görevinin yerele uygulanmış hâli (yerele özgü alanlar korunur).
TaskItem applyRemote(TaskItem l, RemoteTask r) => l.copyWith(
  title: r.title,
  notes: r.notes,
  due: r.due,
  // Gün değiştiyse saat de anlamını yitirmez; tarih kalktıysa saat de kalkar.
  dueTime: r.due.isEmpty ? '' : l.dueTime,
  completed: r.completed,
  completedAt: r.completed ? (r.completedAt ?? l.completedAt) : null,
  clearCompletedAt: !r.completed,
);

/// [locals] silinmişler DAHİL yerel görevler; [remotes] Google'daki görevler
/// (silinmişler `deleted`); [localToRemoteList] yerel liste → Google liste
/// (varsayılan liste '' anahtarıyla). Eşlenmemiş listedeki görev atlanır.
List<TaskSyncAction> planTaskSync({
  required List<TaskItem> locals,
  required List<RemoteTask> remotes,
  required Map<String, String> localToRemoteList,
  required DateTime? lastSync,
}) {
  final remoteToLocalList = {
    for (final e in localToRemoteList.entries) e.value: e.key,
  };
  final remoteById = {for (final r in remotes) r.id: r};
  final linked = <String>{};
  final out = <TaskSyncAction>[];

  bool localChanged(TaskItem l) {
    final at = l.updatedAt;
    if (at == null) return false;
    return lastSync == null || at.isAfter(lastSync);
  }

  bool remoteChanged(TaskItem l, RemoteTask r) {
    final seen = l.google?.updated;
    final at = r.updated;
    if (at == null) return false;
    return seen == null || at.isAfter(seen);
  }

  for (final l in locals) {
    final g = l.google;
    if (g == null || g.id.isEmpty) {
      if (l.deletedAt != null) continue;
      final list = localToRemoteList[l.listId];
      if (list != null) out.add(CreateRemote(l, list));
      continue;
    }
    linked.add(g.id);
    final r = remoteById[g.id];
    if (l.deletedAt != null) {
      if (r != null && !r.deleted) out.add(DeleteRemote(l));
      continue;
    }
    if (r == null || r.deleted) {
      // Google'da yok: yerelde değiştirilmediyse çöpe; değiştirildiyse
      // yeniden oluşturulur (kullanıcının son emeği kaybolmasın).
      if (localChanged(l)) {
        final list = localToRemoteList[l.listId];
        if (list != null) out.add(CreateRemote(l, list));
      } else {
        out.add(TrashLocal(l));
      }
      continue;
    }
    if (sameTaskContent(l, r)) continue;
    final lc = localChanged(l), rc = remoteChanged(l, r);
    if (lc && rc) {
      final la = l.updatedAt!, ra = r.updated!;
      out.add(la.isAfter(ra) ? UpdateRemote(l, r) : UpdateLocal(l, r));
    } else if (rc) {
      out.add(UpdateLocal(l, r));
    } else if (lc) {
      out.add(UpdateRemote(l, r));
    } else {
      // İkisi de "değişmedi" ama farklı (ilk bağlanma): Google kazanır.
      out.add(UpdateLocal(l, r));
    }
  }

  // Üst görevler önce: alt görev açılırken üstünün yerel kimliği bilinsin.
  final fresh = [
    for (final r in remotes)
      if (!r.deleted && !linked.contains(r.id)) r,
  ]..sort((a, b) => (a.parent.isEmpty ? 0 : 1) - (b.parent.isEmpty ? 0 : 1));
  for (final r in fresh) {
    final list = remoteToLocalList[r.listId];
    if (list != null) out.add(CreateLocal(r, list));
  }
  return out;
}
