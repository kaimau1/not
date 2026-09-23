import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import 'notes_providers.dart';
import '../domain/note.dart';
import 'note_card.dart';
import 'note_grid.dart';

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
            // **NOTLAR SAYFASI GİBİ** (kullanıcı isteği 2026-09-23: "çöp
            // kutusu da güzel değil, o da normal notlar sayfası gibi
            // olabilir"). Eskiden tam genişlikte düz satırlardı; geniş
            // ekranda her satır bir ucundan öbürüne uzanıyor, notun rengi,
            // maddeleri ve görselleri hiç görünmüyordu. Artık ana ekranla
            // AYNI kart ve AYNI dengeli ızgara; kartın altında kalan gün ve
            // geri yükle / kalıcı sil.
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 220).floor().clamp(
                  2,
                  6,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        needle.isEmpty
                            ? l10n.trashInfo
                            : l10n.searchResultCount(notes.length),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: NoteBalancedGrid(
                        notes: notes,
                        columns: columns,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemBuilder: (context, index) =>
                            _TrashCard(note: notes[index]),
                      ),
                    ),
                  ],
                );
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

class _TrashCard extends ConsumerWidget {
  const _TrashCard({required this.note});

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

  /// Karta dokununca: ne yapılacağı sorulur. Çöpteki not düzenlenemez —
  /// açmak önce geri yüklemeyi gerektirir, bunu dokunuşun kendisi söyler.
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore_from_trash_outlined),
              title: Text(l10n.restore),
              onTap: () => Navigator.pop(sheetContext, 'restore'),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
              title: Text(
                l10n.deleteForever,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'restore':
        _restore(context, ref);
      case 'delete':
        await _deleteForever(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final daysLeft = trashDaysLeft(note);
    // Son gün kırmızı: "yarın gidiyor" bilgisi kartların arasında
    // kaybolmasın.
    final urgent = daysLeft != null && daysLeft <= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Çöpteki not SOLUK: canlı notlardan bakışta ayrılsın.
        Opacity(
          opacity: 0.85,
          child: NoteCard(note: note, onTap: () => _showActions(context, ref)),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 6, top: 2),
          child: Row(
            children: [
              // Kısa biçim + tam metin ipucunda: dar kartta "26 gün sonra
              // kalıcı silinir" iki düğmenin yanına sığmıyor, kesiliyordu.
              if (daysLeft != null)
                Expanded(
                  child: Tooltip(
                    message: daysLeft == 0
                        ? l10n.trashLastDay
                        : l10n.trashDaysLeft(daysLeft),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_bottom,
                          size: 13,
                          color: urgent ? scheme.error : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            daysLeft == 0
                                ? l10n.trashTodayShort
                                : l10n.trashDaysShort(daysLeft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: urgent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: urgent
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                tooltip: l10n.restore,
                icon: const Icon(Icons.restore_from_trash_outlined),
                onPressed: () => _restore(context, ref),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                tooltip: l10n.deleteForever,
                icon: Icon(Icons.delete_forever_outlined, color: scheme.error),
                onPressed: () => _deleteForever(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
