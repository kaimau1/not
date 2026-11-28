import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/sheet_header.dart';
import '../../../core/widgets/sheet_keyboard.dart';
import '../domain/list_mode.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import '../domain/smart_lexicon_v2.dart';
import '../domain/smart_list.dart';

/// Hedef seçici sonucu: mevcut bir not, `"Hızlı Not"` klasörü veya yeni not.
sealed class QuickDropTargetChoice {
  const QuickDropTargetChoice();
}

class QuickDropTargetQuickInbox extends QuickDropTargetChoice {
  const QuickDropTargetQuickInbox();
}

class QuickDropTargetNewNote extends QuickDropTargetChoice {
  const QuickDropTargetNewNote();
}

class QuickDropTargetNote extends QuickDropTargetChoice {
  const QuickDropTargetNote(this.note);
  final Note note;
}

/// Hızlı Ekle hedef çipine dokunulunca açılan kompakt, aramalı hedef seçici.
Future<QuickDropTargetChoice?> showQuickDropTargetPicker(
  BuildContext context, {
  required List<Note> candidates,
  String? selectedNoteId,
  bool quickInboxSelected = false,
  bool newNoteSelected = false,
}) => showAppSheet<QuickDropTargetChoice>(
  context: context,
  isScrollControlled: true,
  builder: (sheetCtx) => _QuickDropTargetPickerSheet(
    candidates: candidates,
    selectedNoteId: selectedNoteId,
    quickInboxSelected: quickInboxSelected,
    newNoteSelected: newNoteSelected,
  ),
);

class _QuickDropTargetPickerSheet extends StatefulWidget {
  const _QuickDropTargetPickerSheet({
    required this.candidates,
    required this.selectedNoteId,
    required this.quickInboxSelected,
    required this.newNoteSelected,
  });

  final List<Note> candidates;
  final String? selectedNoteId;
  final bool quickInboxSelected;
  final bool newNoteSelected;

  @override
  State<_QuickDropTargetPickerSheet> createState() =>
      _QuickDropTargetPickerSheetState();
}

class _QuickDropTargetPickerSheetState
    extends State<_QuickDropTargetPickerSheet> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    focusAfterRouteOpens(this, _focus);
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  IconData _iconForNote(Note n) {
    if (n.isQuickInbox) return Icons.bolt_outlined;
    final mode = n.listMode;
    switch (mode) {
      case ListMode.shopping:
        return Icons.shopping_cart_outlined;
      case ListMode.routine:
        return Icons.repeat_rounded;
      case ListMode.template:
        return Icons.checklist_rtl_outlined;
      case ListMode.project:
        return Icons.flag_outlined;
      case ListMode.general:
        final kind = smartListKindFromId(n.listKind);
        if (kind != SmartListKind.generic) {
          return kSmartKindSpecs[kind]?.icon ?? Icons.checklist_outlined;
        }
        return n.type == NoteType.text
            ? Icons.notes_outlined
            : Icons.checklist_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final q = _filter.trim().toLowerCase();
    final visible = [
      for (final n in widget.candidates)
        if (!n.isQuickInbox &&
            (q.isEmpty || n.displayTitle.toLowerCase().contains(q)))
          n,
    ];
    return SheetInsetPadding(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: l10n.quickDropWhich),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.l,
                0,
                AppSpace.l,
                AppSpace.s,
              ),
              child: TextField(
                key: const ValueKey('quick-drop-picker-search'),
                controller: _query,
                focusNode: _focus,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.quickDropFindNote,
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: AppSpace.l),
                children: [
                  if (q.isEmpty) ...[
                    ListTile(
                      key: const ValueKey('quick-drop-pick-quick-inbox'),
                      leading: Icon(Icons.bolt_outlined, color: scheme.primary),
                      title: Text(l10n.quickInboxFolderName),
                      subtitle: Text(
                        l10n.quickInboxSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: widget.quickInboxSelected
                          ? Icon(Icons.check, color: scheme.primary)
                          : null,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(const QuickDropTargetQuickInbox()),
                    ),
                    ListTile(
                      key: const ValueKey('quick-drop-pick-new-note'),
                      leading: const Icon(Icons.add),
                      title: Text(l10n.newNoteShort),
                      trailing: widget.newNoteSelected
                          ? Icon(Icons.check, color: scheme.primary)
                          : null,
                      onTap: () =>
                          Navigator.of(context)
                              .pop(const QuickDropTargetNewNote()),
                    ),
                    if (visible.isNotEmpty) const Divider(height: 1),
                  ],
                  for (final n in visible)
                    ListTile(
                      key: ValueKey('quick-drop-pick-note-${n.id}'),
                      leading: Icon(_iconForNote(n)),
                      title: Text(
                        n.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: widget.selectedNoteId == n.id
                          ? Icon(Icons.check, color: scheme.primary)
                          : null,
                      onTap: () =>
                          Navigator.of(context).pop(QuickDropTargetNote(n)),
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
