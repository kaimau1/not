import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/domain/smart_categorize.dart' show SmartNoteLearn;

import '../../../core/l10n_ext.dart';
import '../../../core/utils/search_fold.dart';
import '../../../core/widgets/app_sheet.dart';
import '../data/notes_repository.dart' show notesStreamProvider;
import '../domain/note.dart';
import '../domain/note_links.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import 'note_card.dart' show openNoteRoute;

/// Bağlantı etiketinin yazısı: hedefin başlığı (kilitliyse de başlık —
/// içerik değil), başlıksızsa ilk satır, o da yoksa [fallback].
String noteLinkLabel(Note note, String fallback) {
  final title = note.displayTitle.trim();
  if (title.isNotEmpty) return title;
  if (!note.locked) {
    final first = note.toPlainText().trim().split('\n').first.trim();
    if (first.isNotEmpty) {
      return first.length > 40 ? '${first.substring(0, 40)}…' : first;
    }
  }
  return fallback;
}

/// Bağlanacak notu seçtirir (aramalı liste). Çöptekiler ve [excludeId]
/// listelenmez. [title] verilmezse "Hangi nota bağlansın?" (hızlı ekle
/// hedef araması kendi sorusunu verir).
Future<Note?> showNotePicker(
  BuildContext context, {
  required List<Note> notes,
  String? excludeId,
  String? title,
}) => showAppSheet<Note>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.8,
  ),
  builder: (ctx) => _NotePicker(
    title: title,
    notes: [
      for (final n in notes)
        if (n.id != excludeId && n.deletedAt == null) n,
    ],
  ),
);

class _NotePicker extends StatefulWidget {
  const _NotePicker({required this.notes, this.title});
  final List<Note> notes;
  final String? title;

  @override
  State<_NotePicker> createState() => _NotePickerState();
}

class _NotePickerState extends State<_NotePicker> {
  String _query = '';

  // K-08: etiketler bir kez katlanır; süzme yalnız sorgu değişince.
  late final List<String> _folded = [
    for (final n in widget.notes) foldForSearch(noteLinkLabel(n, '')),
  ];
  String? _listQuery;
  List<Note> _list = const [];

  List<Note> _filtered() {
    final q = foldForSearch(_query.trim());
    if (q == _listQuery) return _list;
    _listQuery = q;
    return _list = [
      for (var i = 0; i < widget.notes.length; i++)
        if (q.isEmpty || _folded[i].contains(q)) widget.notes[i],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = _filtered();
    return SheetInsetPadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              widget.title ?? l10n.noteLinkPickTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (context, i) {
                final n = list[i];
                return ListTile(
                  leading: Icon(
                    n.locked
                        ? Icons.lock_outline
                        : Icons.sticky_note_2_outlined,
                  ),
                  title: Text(
                    noteLinkLabel(n, l10n.remindersUntitled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(context, n),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "Bu nota bağlananlar" (geri bağlantılar) çipi; yoksa hiçbir şey.
class BacklinksChip extends StatelessWidget {
  const BacklinksChip({
    super.key,
    required this.noteId,
    required this.notes,
    this.labelStyle,
  });

  final String noteId;
  final List<Note> notes;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final back = backlinksTo(noteId, notes);
    if (back.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    return ActionChip(
      key: const ValueKey('backlinks-chip'),
      avatar: const Icon(Icons.call_received, size: 14),
      label: Text(l10n.backlinksCount(back.length)),
      labelStyle: labelStyle,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => showAppSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.backlinksTitle,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              for (final n in back)
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: Text(
                    noteLinkLabel(n, l10n.remindersUntitled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    openNoteRoute(context, n);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yerel kelime/etiket örtüşmesiyle ilgili notları bulur (sıfır AI maliyeti).
List<Note> localRelatedNotes(String noteId, List<Note> notes) {
  Note? target;
  for (final n in notes) {
    if (n.id == noteId) {
      target = n;
      break;
    }
  }
  if (target == null || target.locked) return const [];
  final targetTokens = SmartNoteLearn.extractTokens(target);
  final targetTags = target.tags.toSet();
  if (targetTokens.isEmpty && targetTags.isEmpty) return const [];
  final alreadyLinked = outgoingNoteLinks(target).toSet();
  final scored = <(Note, double)>[];
  for (final n in notes) {
    if (n.id == noteId ||
        alreadyLinked.contains(n.id) ||
        n.locked ||
        n.deletedAt != null ||
        n.archivedAt != null) {
      continue;
    }
    var score = SmartNoteLearn.jaccardSimilarity(
      targetTokens,
      SmartNoteLearn.extractTokens(n),
    );
    if (targetTags.isNotEmpty && n.tags.isNotEmpty) {
      final shared = targetTags.intersection(n.tags.toSet()).length;
      if (shared > 0) score += 0.25 * shared;
    }
    if (score >= 0.15) scored.add((n, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final s in scored.take(6)) s.$1];
}

/// "İlgili notlar" levhası (F18.17): yerel benzerlik önerileri, dokununca
/// açılır; "Bağla" tek dokunuşla bağlantıya çevirir.
Future<void> showRelatedNotesSheet(
  BuildContext context, {
  required String noteId,
  required ValueChanged<Note> onLink,
}) => showAppSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (ctx) => SafeArea(
    child: Consumer(
      builder: (ctx, ref, _) {
        final l10n = ctx.l10n;
        final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
        final list = localRelatedNotes(noteId, notes);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.relatedNotesTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.relatedNotesNone),
              )
            else
              for (final n in list)
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_outlined),
                  title: Text(
                    noteLinkLabel(n, l10n.remindersUntitled),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    openNoteRoute(context, n);
                  },
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.link, size: 18),
                    label: Text(l10n.relatedNotesLink),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onLink(n);
                    },
                  ),
                ),
          ],
        );
      },
    ),
  ),
);
