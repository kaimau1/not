import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../data/notes_repository.dart';
import '../../domain/note_version.dart';
import '../../../../core/friendly_error.dart';

/// **SÜRÜM GEÇMİŞİ** levhası (F4.2): notun saklanan sürümleri, yeniden
/// eskiye. Birine dokunmak önizlemeyi açar; "Bu sürüme dön" seçilen sürümü
/// döndürür (editör uygular).
Future<NoteVersion?> showNoteHistorySheet(
  BuildContext context,
  NotesRepository repo,
  String noteId,
) => showAppSheet<NoteVersion>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
      ),
      child: _HistoryList(future: repo.listVersions(noteId)),
    ),
  ),
);

String _reasonLabel(BuildContext context, String reason) {
  final l10n = context.l10n;
  return switch (reason) {
    'ai' => l10n.versionReasonAi,
    'restore' => l10n.versionReasonRestore,
    'open' => l10n.versionReasonOpen,
    _ => l10n.versionReasonAuto,
  };
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.future});

  final Future<List<NoteVersion>> future;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final format = DateFormat.yMMMd().add_Hm();
    return FutureBuilder<List<NoteVersion>>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.genericError(friendlyError(l10n, snap.error!))),
          );
        }
        final versions = snap.data;
        if (versions == null) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                l10n.versionHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(l10n.versionHistoryInfo),
            ),
            if (versions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.versionHistoryEmpty),
              ),
            for (final v in versions)
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(format.format(v.at)),
                subtitle: Text(
                  [
                    _reasonLabel(context, v.reason),
                    if (v.preview.isNotEmpty) v.preview,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  final ok = await _preview(context, v, format);
                  if (ok == true && context.mounted) Navigator.pop(context, v);
                },
              ),
          ],
        );
      },
    );
  }

  Future<bool?> _preview(
    BuildContext context,
    NoteVersion v,
    DateFormat format,
  ) {
    final l10n = context.l10n;
    final text = [
      if (v.title.trim().isNotEmpty) v.title.trim(),
      if (v.body.trim().isNotEmpty) v.body.trim(),
      for (final i in v.items) '${i.checked ? '☑' : '☐'} ${i.text}',
      for (final p in v.textPages)
        if (p.body.trim().isNotEmpty) p.body.trim(),
    ].join('\n\n');
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(format.format(v.at)),
        content: SingleChildScrollView(child: SelectableText(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.versionRestore),
          ),
        ],
      ),
    );
  }
}
