import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import 'notes_providers.dart';
import '../domain/note.dart';

/// Çöp kutusu: silinen notlar geri alınabilir veya kalıcı silinebilir.
///
/// **2026-09-05 turu** — dört eksik kapandı:
/// 1. Not başına KALAN GÜN yazıyor; "30 gün" bilgisi ekranın tepesinde tek
///    bir cümleydi, hangi notun yarın gideceği hiç görünmüyordu.
/// 2. "Geri al" sessizdi (not listeden kayboluyor, nereye gittiği belirsiz);
///    artık bildirim veriyor ve GERİ ALINABİLİYOR.
/// 3. "Çöpü boşalt" onaydan sonra hiçbir şey göstermeden notları tek tek
///    siliyordu; yüz notta ekran donmuş görünüyordu. Artık ilerleme
///    gösteriliyor ve düğme kilitleniyor.
/// 4. Arama yoktu — çöpte bir notu bulmanın tek yolu gözle kaydırmaktı.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final _searchController = TextEditingController();
  bool _searching = false;

  /// Boşaltma sürüyor: düğme kilitli, üstte ilerleme çubuğu var. İkinci
  /// dokunuş aynı notları ikinci kez silmeye kalkardı.
  bool _emptying = false;
  int _emptyDone = 0;
  int _emptyTotal = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) _searchController.clear();
    });
  }

  Future<void> _emptyTrash(List<Note> notes) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.emptyTrash),
        content: Text(l10n.emptyTrashConfirm(notes.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.deleteForever),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    // İçlerinde kilitli not varsa toplu boşaltma da doğrulama ister.
    if (notes.any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || !mounted) return;
    setState(() {
      _emptying = true;
      _emptyDone = 0;
      _emptyTotal = notes.length;
    });
    try {
      for (final note in notes) {
        await repo.deleteNotePermanently(note);
        if (!mounted) return;
        setState(() => _emptyDone++);
      }
    } finally {
      if (mounted) setState(() => _emptying = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.trashEmptied)));
  }

  /// Görünen notların TAMAMINI geri yükler. Çöpe toplu düşen bir seçimi
  /// (ana ekranda çok not seçip silmek tek dokunuş) tek dokunuşla geri
  /// almanın yolu yoktu; notu notu geri yüklemek gerekiyordu.
  void _restoreAll(List<Note> notes) {
    final l10n = context.l10n;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    for (final note in notes) {
      repo.restore(note.id);
    }
    showUndoSnackBar(
      context,
      message: l10n.notesRestoredCount(notes.length),
      undoLabel: l10n.undo,
      onUndo: () {
        for (final note in notes) {
          repo.softDelete(note.id);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trash = ref.watch(trashStreamProvider);
    // Gizli klasör bastırması: çöp, gizli notların içeriğini doğrulamasız
    // sızdırıyordu (ana ekran kuralıyla aynı). Bastırılan not çöpte gizli
    // kalır; 30 günlük otomatik boşaltma onu yine kapsar.
    final suppressed = ref.watch(suppressedFolderIdsProvider);
    // SİLİNME ZAMANINA GÖRE, en son silinen en üstte: kullanıcı çöpe
    // neredeyse her zaman "az önce sildiğim şey" için girer.
    List<Note> visible(List<Note> list) => [
      for (final n in list)
        if (n.folderId == null || !suppressed.contains(n.folderId)) n,
    ]..sort((a, b) {
      final at = a.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.deletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l10n.searchHint,
                ),
              )
            : Text(l10n.trashTitle),
        bottom: _emptying
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _emptyTotal == 0 ? null : _emptyDone / _emptyTotal,
                  minHeight: 4,
                ),
              )
            : null,
        actions: [
          IconButton(
            tooltip: _searching ? l10n.close : l10n.searchHint,
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _emptying ? null : _toggleSearch,
          ),
          Consumer(
            builder: (context, ref, _) {
              final notes = visible(
                ref.watch(trashStreamProvider).value ?? const <Note>[],
              );
              if (notes.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.restoreAll,
                    icon: const Icon(Icons.restore_outlined),
                    onPressed: _emptying ? null : () => _restoreAll(notes),
                  ),
                  IconButton(
                    tooltip: l10n.emptyTrash,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: _emptying ? null : () => _emptyTrash(notes),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: trash.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.genericError(e.toString()),
        ),
        data: (raw) => ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            final needle = value.text.trim().toLowerCase();
            final all = visible(raw);
            final notes = needle.isEmpty
                ? all
                : [
                    for (final n in all)
                      if (noteMatchesQuery(n, needle)) n,
                  ];
            if (notes.isEmpty) {
              return EmptyState(
                icon: needle.isEmpty ? Icons.delete_outline : Icons.search_off,
                title: needle.isEmpty ? l10n.trashEmpty : l10n.noteSearchNoHit,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      needle.isEmpty
                          ? l10n.trashInfo
                          : l10n.searchResultCount(notes.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return _TrashTile(note: notes[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

/// Çöpteki notun kalıcı silinmesine kaç gün kaldı? 0 = bugün gidiyor,
/// null = silinme zamanı bilinmiyor (eski kayıt).
int? trashDaysLeft(Note note, {DateTime? now}) {
  final deleted = note.deletedAt;
  if (deleted == null) return null;
  final due = deleted.add(NotesRepository.trashRetention);
  final left = due.difference(now ?? DateTime.now()).inHours / 24;
  return left <= 0 ? 0 : left.ceil();
}

class _TrashTile extends ConsumerWidget {
  const _TrashTile({required this.note});

  final Note note;

  Future<void> _deleteForever(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    // Kilitli notun KALICI silinmesi doğrulama ister (geri alınamaz).
    if (note.locked && !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteForever),
        content: Text(l10n.deleteForeverConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      // Ekler de Storage'dan silinsin; yalnız dokümanı silmek dosya bırakır.
      await ref.read(notesRepositoryProvider)?.deleteNotePermanently(note);
    }
  }

  /// Geri yükleme SESSİZ değil: not listeden kayboluyor ve kullanıcı onun
  /// nereye gittiğini göremiyordu. Yanlış nota basıldıysa geri alınabilir.
  void _restore(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.restore(note.id);
    showUndoSnackBar(
      context,
      message: context.l10n.noteRestored,
      undoLabel: context.l10n.undo,
      onUndo: () => repo.softDelete(note.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // Kilitli notun başlığı/içeriği kimlik doğrulamasız yüzeylerde gösterilmez
    // (ana ekran kartıyla aynı kural).
    final preview = note.locked ? '' : note.toPlainText();
    final title = note.locked
        ? l10n.lockedNote
        : (note.displayTitle.trim().isNotEmpty
              ? note.displayTitle
              : preview.split('\n').first);
    final daysLeft = trashDaysLeft(note);
    // Son gün kırmızı: "yarın gidiyor" bilgisi listedeki diğer satırların
    // arasında kaybolmasın.
    final urgent = daysLeft != null && daysLeft <= 1;
    return ListTile(
      tileColor: scheme.surfaceContainerLow,
      leading: note.locked ? const Icon(Icons.lock_outline) : null,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview.isNotEmpty)
            Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (daysLeft != null)
            Text(
              daysLeft == 0 ? l10n.trashLastDay : l10n.trashDaysLeft(daysLeft),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
                color: urgent ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      isThreeLine: preview.isNotEmpty && daysLeft != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.restore,
            icon: const Icon(Icons.restore_from_trash_outlined),
            onPressed: () => _restore(context, ref),
          ),
          IconButton(
            tooltip: l10n.deleteForever,
            icon: Icon(Icons.delete_forever_outlined, color: scheme.error),
            onPressed: () => _deleteForever(context, ref),
          ),
        ],
      ),
    );
  }
}
