import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/gemini_service.dart';
import '../../folders/data/folders_repository.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../../../core/friendly_error.dart';
import '../domain/trash_analysis.dart' show trashDigest;
import 'note_card.dart' show formatNoteDate, openNoteRoute;

/// **ARŞİV ÖZETİ** (geliştirme raporu D5, 2026-10-20: "Arşivimde neler
/// var?" — çöp analizinin arşiv karşılığı).
///
/// Cihazda anında: sayılar, klasörlere dağılım ve bir yıldır dokunulmamış
/// notlar. İsteğe bağlı "AI ile özetle": konu başlıkları + eskimiş görünen
/// notlar (kilitli notlar gönderilmez). Her satır açılır ya da (geri
/// alınabilir) çöpe atılır; hiçbir şey sormadan yapılmaz.
Future<void> showArchiveInsightsSheet(
  BuildContext context,
  List<Note> archived,
) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _ArchiveInsightsSheet(notes: archived),
);

/// Cihazdaki özet (saf — testli).
typedef ArchiveStats = ({
  int count,
  int attachments,
  List<({String? folderId, int count})> byFolder,
  List<Note> stale,
});

/// [now]dan bir yıl önce son güncellenen notlar "dokunulmamış" sayılır.
ArchiveStats archiveStats(List<Note> notes, {DateTime? now}) {
  final at = now ?? DateTime.now();
  final byFolder = <String?, int>{};
  var attachments = 0;
  final stale = <Note>[];
  for (final n in notes) {
    attachments += n.attachments.length;
    byFolder[n.folderId] = (byFolder[n.folderId] ?? 0) + 1;
    final touched = n.updatedAt ?? n.archivedAt;
    if (touched != null && at.difference(touched).inDays >= 365) stale.add(n);
  }
  stale.sort((a, b) {
    final at = a.updatedAt ?? a.archivedAt ?? DateTime(2000);
    final bt = b.updatedAt ?? b.archivedAt ?? DateTime(2000);
    return at.compareTo(bt);
  });
  final folders = [
    for (final e in byFolder.entries) (folderId: e.key, count: e.value),
  ]..sort((a, b) => b.count.compareTo(a.count));
  return (
    count: notes.length,
    attachments: attachments,
    byFolder: folders,
    stale: stale,
  );
}

class _ArchiveInsightsSheet extends ConsumerStatefulWidget {
  const _ArchiveInsightsSheet({required this.notes});

  final List<Note> notes;

  @override
  ConsumerState<_ArchiveInsightsSheet> createState() =>
      _ArchiveInsightsSheetState();
}

class _ArchiveInsightsSheetState extends ConsumerState<_ArchiveInsightsSheet> {
  late final ArchiveStats _stats = archiveStats(widget.notes);
  late final Map<String, Note> _byId = {for (final n in widget.notes) n.id: n};

  /// Bu levhada çöpe atılanlar (listelerden düşer).
  final _done = <String>{};

  bool _aiLoading = false;
  String? _aiError;
  String _aiSummary = '';
  List<({String name, int count})> _aiCategories = const [];
  List<({String id, String reason})> _aiStale = const [];

  Future<void> _runAi() async {
    final l10n = context.l10n;
    final (:digest, :ids) = trashDigest(widget.notes, limit: 80);
    if (ids.isEmpty) {
      setState(() => _aiError = l10n.trashAiNothing);
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final r = await ref.read(geminiServiceProvider).summarizeArchive(digest);
      if (!mounted) return;
      setState(() {
        _aiSummary = (r['ozet'] as String? ?? '').trim();
        _aiCategories = [
          for (final c in (r['kategori'] as List?) ?? const [])
            if (c is Map && c['ad'] is String)
              (
                name: (c['ad'] as String).trim(),
                count: (c['sayi'] as num?)?.toInt() ?? 0,
              ),
        ];
        _aiStale = [
          for (final e in (r['eski'] as List?) ?? const [])
            if (e is Map && ids[e['id']] != null)
              (id: ids[e['id']]!, reason: (e['neden'] as String? ?? '').trim()),
        ];
      });
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _aiError = e.isAuthError
              ? l10n.aiNoApiKey
              : l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _aiError = l10n.aiError(friendlyError(l10n, e)));
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _trash(Note note) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    final l10n = context.l10n;
    repo.softDelete(note.id);
    setState(() => _done.add(note.id));
    showUndoSnackBar(
      context,
      message: l10n.noteDeleted,
      undoLabel: l10n.undo,
      onUndo: () {
        repo.restore(note.id);
        if (mounted) setState(() => _done.remove(note.id));
      },
    );
  }

  String _title(Note n) {
    final t = stripRichMarkers(n.displayTitle).trim();
    if (t.isNotEmpty) return t;
    final body = n.toPlainText().trim();
    return body.isEmpty ? context.l10n.untitledNote : body.split('\n').first;
  }

  Widget _noteRow(Note note, String subtitle) => ListTile(
    key: ValueKey('archive-insight-${note.id}'),
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(_title(note), maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 1),
    onTap: () => openNoteRoute(context, note),
    trailing: IconButton(
      tooltip: context.l10n.delete,
      icon: const Icon(Icons.delete_outline),
      onPressed: () => _trash(note),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final folderNames = {
      for (final f in ref.watch(foldersStreamProvider).value ?? const [])
        f.id: f.name,
    };
    final stale = [
      for (final n in _stats.stale)
        if (!_done.contains(n.id)) n,
    ];
    final aiStale = [
      for (final s in _aiStale)
        if (!_done.contains(s.id) && _byId[s.id] != null) s,
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(l10n.archiveInsights, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.archiveInsightsStats(
              _stats.count,
              _stats.attachments,
              stale.length,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.archiveByFolder, style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in _stats.byFolder.take(8))
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    f.folderId == null
                        ? Icons.notes_outlined
                        : Icons.folder_outlined,
                    size: 16,
                  ),
                  label: Text(
                    '${f.folderId == null ? l10n.archiveNoFolder : (folderNames[f.folderId] ?? l10n.filterSectionFolder)} · ${f.count}',
                  ),
                ),
            ],
          ),
          if (stale.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.archiveStale, style: theme.textTheme.labelLarge),
            for (final n in stale.take(10))
              _noteRow(
                n,
                n.updatedAt == null ? '' : formatNoteDate(n.updatedAt!),
              ),
          ],
          const SizedBox(height: 16),
          if (_aiSummary.isEmpty && aiStale.isEmpty)
            FilledButton.tonalIcon(
              key: const ValueKey('archive-insights-ai'),
              onPressed: _aiLoading ? null : _runAi,
              icon: _aiLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(l10n.archiveInsightsAi),
            ),
          if (_aiError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_aiError!, style: TextStyle(color: scheme.error)),
            ),
          if (_aiSummary.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(_aiSummary)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in _aiCategories)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${c.name} · ${c.count}'),
                  ),
              ],
            ),
          ],
          if (aiStale.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.archiveAiStale, style: theme.textTheme.labelLarge),
            for (final s in aiStale) _noteRow(_byId[s.id]!, s.reason),
          ],
        ],
      ),
    );
  }
}
