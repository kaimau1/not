import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/search_fold.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import 'notes_providers.dart';
import '../../../app/theme/note_colors.dart';
import '../../../core/utils/rich_text.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../../../core/widgets/app_sheet.dart';

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
    messenger.showMessage(l10n.trashEmptied);
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
    List<Note> visible(List<Note> list) =>
        [
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
            final needle = foldForSearch(value.text.trim());
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
            // **DÜZENLİ IZGARA** (kullanıcı isteği 2026-09-23: "çöp kutusu
            // biraz dağınık görünüyor"). İlk sürüm ana ekranın dengeli
            // (masonry) ızgarasını kullanıyordu: farklı boyda kartlar ve
            // her kartın ALTINDA sallanan bir satır, ekranı basamak basamak
            // yapıyordu. Artık her kart EŞİT boyda, alt bilgi kartın İÇİNDE;
            // yakında silinecekler ayrı başlıkla en üstte. Çöpte not
            // okunmaz, yalnız TANINIR — tam içerik gerekmez.
            final soon = [
              for (final n in notes)
                if ((trashDaysLeft(n) ?? 99) <= 3) n,
            ];
            final rest = [
              for (final n in notes)
                if ((trashDaysLeft(n) ?? 99) > 3) n,
            ];
            const grid = SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: _TrashCard.height,
            );
            SliverGrid section(List<Note> list) => SliverGrid(
              gridDelegate: grid,
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TrashCard(
                  key: ValueKey('trash-${list[index].id}'),
                  note: list[index],
                ),
                childCount: list.length,
              ),
            );
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      needle.isEmpty
                          ? l10n.trashInfo
                          : l10n.searchResultCount(notes.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                if (soon.isNotEmpty) ...[
                  _TrashHeader(
                    title: l10n.trashSoonSection,
                    count: soon.length,
                    urgent: true,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: section(soon),
                  ),
                ],
                if (rest.isNotEmpty) ...[
                  if (soon.isNotEmpty)
                    _TrashHeader(
                      title: l10n.trashRestSection,
                      count: rest.length,
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      soon.isEmpty ? 8 : 0,
                      16,
                      0,
                    ),
                    sliver: section(rest),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
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

class _TrashHeader extends StatelessWidget {
  const _TrashHeader({
    required this.title,
    required this.count,
    this.urgent = false,
  });

  final String title;
  final int count;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.primary;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            if (urgent) ...[
              Icon(Icons.hourglass_bottom, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
          ],
        ),
      ),
    );
  }
}

class _TrashCard extends ConsumerWidget {
  const _TrashCard({super.key, required this.note});

  final Note note;

  /// Bütün kartlar eşit boyda: ızgara düzgün satırlar kursun.
  static const double height = 188;

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
    final action = await showAppSheet<String>(
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

  /// Kartın gövdesi: notu TANITACAK kadar içerik — kilitliyse hiçbir şey.
  Widget _preview(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.8),
      height: 1.35,
    );
    if (note.locked) {
      return Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: muted),
          const SizedBox(width: 6),
          Text(context.l10n.lockedNote, style: small),
        ],
      );
    }
    final items = [
      for (final i in note.items)
        if (i.text.trim().isNotEmpty) i,
    ];
    final body = stripRichMarkers(note.body).trim();
    final files = [
      for (final a in note.attachments)
        if (a.kind != AttachmentKind.image) a,
    ];
    final images = note.attachments
        .where((a) => a.kind == AttachmentKind.image)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (body.isNotEmpty)
          Text(
            body,
            maxLines: items.isEmpty ? 5 : 2,
            overflow: TextOverflow.ellipsis,
            style: small,
          ),
        for (final item in items.take(body.isEmpty ? 5 : 3))
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Row(
              children: [
                Icon(
                  item.checked
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 14,
                  color: muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stripRichMarkers(item.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small?.copyWith(
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.checked ? muted : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (files.isNotEmpty || images > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 10,
              runSpacing: 2,
              children: [
                if (images > 0)
                  _MetaChip(icon: Icons.image_outlined, label: '$images'),
                for (final f in files.take(2))
                  _MetaChip(
                    icon: switch (f.kind) {
                      AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
                      AttachmentKind.audio => Icons.mic_none,
                      AttachmentKind.slide => Icons.slideshow_outlined,
                      AttachmentKind.text => Icons.subject,
                      _ => Icons.attach_file,
                    },
                    label: f.fileName,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final daysLeft = trashDaysLeft(note);
    // Son gün kırmızı: "yarın gidiyor" bilgisi kartların arasında
    // kaybolmasın.
    final urgent = daysLeft != null && daysLeft <= 1;
    final title = note.locked
        ? l10n.lockedNote
        : (note.displayTitle.trim().isNotEmpty
              ? stripRichMarkers(note.displayTitle).trim()
              : note.toPlainText().trim().split('\n').first);
    final surface = NoteColors.surface(context, note.color);
    return Material(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showActions(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                // Taşan içerik ALTTA SOLAR, sert kesilmez.
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.black, Colors.transparent],
                    stops: [0, 0.75, 1],
                  ).createShader(rect),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      maxHeight: double.infinity,
                      child: _preview(context),
                    ),
                  ),
                ),
              ),
            ),
            // Alt bilgi KARTIN İÇİNDE: kalan gün + geri yükle + kalıcı sil.
            Container(
              height: 40,
              color: scheme.onSurface.withValues(alpha: 0.04),
              padding: const EdgeInsetsDirectional.only(start: 12, end: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_bottom,
                    size: 14,
                    color: urgent ? scheme.error : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Tooltip(
                      message: daysLeft == null
                          ? ''
                          : (daysLeft == 0
                                ? l10n.trashLastDay
                                : l10n.trashDaysLeft(daysLeft)),
                      child: Text(
                        daysLeft == null
                            ? ''
                            : (daysLeft == 0
                                  ? l10n.trashTodayShort
                                  : l10n.trashDaysShort(daysLeft)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: urgent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: urgent
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
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
                    icon: Icon(
                      Icons.delete_forever_outlined,
                      color: scheme.error,
                    ),
                    onPressed: () => _deleteForever(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
