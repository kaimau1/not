import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/search_fold.dart';
import '../../../core/widgets/app_sheet.dart';
import '../domain/note.dart';
import '../domain/note_links.dart';
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
/// listelenmez.
Future<Note?> showNotePicker(
  BuildContext context, {
  required List<Note> notes,
  String? excludeId,
}) => showAppSheet<Note>(
  context: context,
  showDragHandle: true,
  useSafeArea: true,
  isScrollControlled: true,
  constraints: BoxConstraints(
    maxHeight: MediaQuery.sizeOf(context).height * 0.8,
  ),
  builder: (ctx) => _NotePicker(
    notes: [
      for (final n in notes)
        if (n.id != excludeId && n.deletedAt == null) n,
    ],
  ),
);

class _NotePicker extends StatefulWidget {
  const _NotePicker({required this.notes});
  final List<Note> notes;

  @override
  State<_NotePicker> createState() => _NotePickerState();
}

class _NotePickerState extends State<_NotePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = foldForSearch(_query.trim());
    final list = [
      for (final n in widget.notes)
        if (q.isEmpty || foldForSearch(noteLinkLabel(n, '')).contains(q)) n,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.noteLinkPickTitle,
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
