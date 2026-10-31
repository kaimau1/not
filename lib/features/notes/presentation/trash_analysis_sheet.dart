import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../../ai/data/gemini_service.dart';
import '../data/notes_repository.dart';
import '../domain/note.dart';
import '../domain/trash_analysis.dart';
import '../../../core/friendly_error.dart';
import 'trash_screen.dart' show trashDaysLeft;

/// Çöp kutusunun AKILLI ANALİZ levhası (kullanıcı isteği 2026-10-20: "çöp
/// kutusuna AI analiz ekle, akıllı bir analiz yapsın, seçenekler sende").
///
/// Açılınca cihazdaki kurallar ANINDA çalışır (bkz. [analyzeTrash]): boş ve
/// kopya notlar "güvenle silinebilir", içinde iş/bilgi kalmışlar "geri
/// yüklemeyi düşün" altına düşer. "AI ile derin analiz" içerik dökümünü
/// modele yollar; dönen öneriler aynı iki listeye eklenir (kilitli notlar
/// gönderilmez). Her satır tek dokunuşla geri yüklenir/silinir; listelerin
/// tamamı için toplu düğme var. Hiçbir şey sormadan yapılmaz.
Future<void> showTrashAnalysisSheet(BuildContext context, List<Note> trash) =>
    showAppSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _TrashAnalysisSheet(initial: trash),
    );

class _TrashAnalysisSheet extends ConsumerStatefulWidget {
  const _TrashAnalysisSheet({required this.initial});

  /// Açıldığı andaki (görünür) çöp; işlem yapıldıkça satırlar listeden düşer.
  final List<Note> initial;

  @override
  ConsumerState<_TrashAnalysisSheet> createState() =>
      _TrashAnalysisSheetState();
}

class _TrashAnalysisSheetState extends ConsumerState<_TrashAnalysisSheet> {
  late final Map<String, Note> _notes = {
    for (final n in widget.initial) n.id: n,
  };

  /// Bu levhada geri yüklenen ya da silinen notlar: listelerden düşer.
  final _done = <String>{};

  late TrashAnalysis _local;
  List<TrashSuggestion> _ai = const [];
  String _aiSummary = '';
  bool _aiLoading = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    final active = [
      for (final n in ref.read(notesStreamProvider).value ?? const <Note>[])
        if (n.deletedAt == null) n,
    ];
    _local = analyzeTrash(
      widget.initial,
      active: active,
      daysLeft: trashDaysLeft,
    );
  }

  Future<void> _runAi() async {
    final l10n = context.l10n;
    final (:digest, :ids) = trashDigest(widget.initial);
    if (ids.isEmpty) {
      setState(() => _aiError = l10n.trashAiNothing);
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiError = null;
    });
    try {
      final result = await ref.read(geminiServiceProvider).analyzeTrash(digest);
      List<TrashSuggestion> read(String key, TrashVerdict verdict) => [
        for (final entry in (result[key] as List?) ?? const [])
          if (entry is Map && ids[entry['id']] != null)
            TrashSuggestion(
              noteId: ids[entry['id']]!,
              verdict: verdict,
              reason: TrashReason.ai,
              note: (entry['neden'] as String? ?? '').trim(),
            ),
      ];
      if (!mounted) return;
      setState(() {
        _aiSummary = (result['ozet'] as String? ?? '').trim();
        _ai = [
          ...read('geri', TrashVerdict.restore),
          ...read('sil', TrashVerdict.delete),
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

  /// İki kaynağın birleşimi: not başına tek satır. Cihaz kuralı somut bir
  /// olguya dayanıyor (boş, kopya, hatırlatıcı) — çakışmada o kazanır; AI
  /// yalnız kuralın görmediği notları ekler.
  List<TrashSuggestion> _merged(TrashVerdict verdict) {
    final seen = <String>{};
    final out = <TrashSuggestion>[];
    for (final s in [..._local.suggestions, ..._ai]) {
      if (_done.contains(s.noteId) || !_notes.containsKey(s.noteId)) continue;
      if (!seen.add(s.noteId)) continue;
      if (s.verdict == verdict) out.add(s);
    }
    return out;
  }

  String _reasonText(TrashSuggestion s) {
    final l10n = context.l10n;
    return switch (s.reason) {
      TrashReason.empty => l10n.trashReasonEmpty,
      TrashReason.duplicateOfActive =>
        s.note.isEmpty
            ? l10n.trashReasonDuplicate
            : l10n.trashReasonDuplicateOf(s.note),
      TrashReason.duplicateInTrash => l10n.trashReasonDuplicateInTrash,
      TrashReason.openTasks => l10n.trashReasonOpenTasks(
        int.tryParse(s.note) ?? 1,
      ),
      TrashReason.futureReminder => l10n.trashReasonReminder,
      TrashReason.sensitiveInfo => l10n.trashReasonSensitive,
      TrashReason.hasAttachments => l10n.trashReasonAttachments(
        int.tryParse(s.note) ?? 1,
      ),
      TrashReason.substantial => l10n.trashReasonSubstantial,
      TrashReason.ai => s.note.isEmpty ? l10n.trashReasonAi : s.note,
    };
  }

  void _restore(List<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    for (final id in ids) {
      repo.restore(id);
    }
    setState(() => _done.addAll(ids));
    showUndoSnackBar(
      context,
      message: context.l10n.notesRestoredCount(ids.length),
      undoLabel: context.l10n.undo,
      onUndo: () {
        for (final id in ids) {
          repo.softDelete(id);
        }
        if (mounted) setState(() => _done.removeAll(ids));
      },
    );
  }

  Future<void> _delete(List<String> ids) async {
    final l10n = context.l10n;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteForever),
        content: Text(l10n.emptyTrashConfirm(ids.length)),
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
    if (!(confirmed ?? false) || !mounted) return;
    final notes = [for (final id in ids) ?_notes[id]];
    if (notes.any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    setState(() => _done.addAll(ids));
    for (final note in notes) {
      await repo.deleteNotePermanently(note);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = _local.stats;
    final restore = _merged(TrashVerdict.restore);
    final delete = _merged(TrashVerdict.delete);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.trashAnalysis,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(Icons.delete_outline, l10n.trashStatNotes(stats.count)),
              if (stats.attachmentCount > 0)
                _StatChip(
                  Icons.attach_file,
                  l10n.trashStatAttachments(stats.attachmentCount),
                ),
              if (stats.soonCount > 0)
                _StatChip(
                  Icons.hourglass_bottom,
                  l10n.trashStatSoon(stats.soonCount),
                  urgent: true,
                ),
              if (stats.lockedCount > 0)
                _StatChip(
                  Icons.lock_outline,
                  l10n.trashStatLocked(stats.lockedCount),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // AI DERİN ANALİZ: içerik modele gider — kullanıcı açıkça ister.
          if (_aiSummary.isNotEmpty)
            Card(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_aiSummary)),
                  ],
                ),
              ),
            )
          else
            FilledButton.tonalIcon(
              onPressed: _aiLoading ? null : _runAi,
              icon: _aiLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_aiLoading ? l10n.trashAiRunning : l10n.trashAiRun),
            ),
          if (_aiError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_aiError!, style: TextStyle(color: scheme.error)),
            ),
          if (_aiSummary.isEmpty && !_aiLoading)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.trashAiInfo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.trashSuggestRestore,
            icon: Icons.restore,
            color: scheme.primary,
            empty: l10n.trashSuggestNone,
            actionLabel: l10n.trashRestoreAllSuggested(restore.length),
            onAction: restore.isEmpty
                ? null
                : () => _restore([for (final s in restore) s.noteId]),
            children: [
              for (final s in restore)
                _SuggestionTile(
                  note: _notes[s.noteId]!,
                  reason: _reasonText(s),
                  fromAi: s.reason == TrashReason.ai,
                  actionIcon: Icons.restore,
                  actionTooltip: l10n.restore,
                  onAction: () => _restore([s.noteId]),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: l10n.trashSuggestDelete,
            icon: Icons.delete_sweep_outlined,
            color: scheme.error,
            empty: l10n.trashSuggestNone,
            actionLabel: l10n.trashDeleteAllSuggested(delete.length),
            destructive: true,
            onAction: delete.isEmpty
                ? null
                : () => _delete([for (final s in delete) s.noteId]),
            children: [
              for (final s in delete)
                _SuggestionTile(
                  note: _notes[s.noteId]!,
                  reason: _reasonText(s),
                  fromAi: s.reason == TrashReason.ai,
                  actionIcon: Icons.delete_forever_outlined,
                  actionTooltip: l10n.deleteForever,
                  onAction: () => _delete([s.noteId]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.icon, this.label, {this.urgent = false});

  final IconData icon;
  final String label;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = urgent ? scheme.error : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.empty,
    required this.actionLabel,
    required this.onAction,
    required this.children,
    this.destructive = false,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String empty;
  final String actionLabel;
  final VoidCallback? onAction;
  final List<Widget> children;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
            ),
            if (onAction != null)
              TextButton(
                style: destructive
                    ? TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      )
                    : null,
                onPressed: onAction,
                child: Text(actionLabel),
              ),
          ],
        ),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              empty,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...children,
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.note,
    required this.reason,
    required this.fromAi,
    required this.actionIcon,
    required this.actionTooltip,
    required this.onAction,
  });

  final Note note;
  final String reason;
  final bool fromAi;
  final IconData actionIcon;
  final String actionTooltip;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final title = note.locked
        ? l10n.lockedNote
        : note.displayTitle.trim().isNotEmpty
        ? note.displayTitle.trim()
        : note.toPlainText().replaceAll(RegExp(r'\s+'), ' ').trim();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        fromAi ? Icons.auto_awesome : Icons.rule,
        size: 18,
        color: fromAi ? scheme.primary : scheme.onSurfaceVariant,
      ),
      title: Text(
        title.isEmpty ? l10n.untitledNote : title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: actionTooltip,
        icon: Icon(actionIcon),
        onPressed: onAction,
      ),
    );
  }
}
