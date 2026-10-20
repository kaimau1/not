import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';

/// Not yazım sorunlarını (F1.6: belge 1 MiB sınırına yaklaştı / sunucu
/// yazımı reddetti) uygulamanın KÖK bildirim alanında gösterir. Editör her
/// kayıtta yazdığından aynı not için uyarı kısa aralıklarla tekrar
/// gösterilmez.
class NoteWriteIssueListener extends StatefulWidget {
  const NoteWriteIssueListener({super.key, required this.child});

  final Widget child;

  /// Aynı not + aynı tür uyarı en fazla bu aralıkla bir kez.
  static const quiet = Duration(minutes: 5);

  @override
  State<NoteWriteIssueListener> createState() => _NoteWriteIssueListenerState();
}

class _NoteWriteIssueListenerState extends State<NoteWriteIssueListener> {
  StreamSubscription<NoteWriteIssue>? _sub;
  final Map<String, DateTime> _lastShown = {};

  @override
  void initState() {
    super.initState();
    _sub = NotesRepository.writeIssues.listen(_show);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _show(NoteWriteIssue issue) {
    final key = '${issue.noteId}:${issue.isRejected}';
    final now = DateTime.now();
    final last = _lastShown[key];
    if (last != null && now.difference(last) < NoteWriteIssueListener.quiet) {
      return;
    }
    _lastShown[key] = now;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null || !mounted) return;
    final l10n = context.l10n;
    final String text;
    if (issue.isRejected) {
      text = l10n.noteSaveRejected(
        issue.reason == 'too-large' ? l10n.noteTooLargeShort : issue.reason!,
      );
    } else {
      final part = issue.largest!;
      final name = switch (part.kind) {
        NotePartKind.body => l10n.noteSizeBody,
        NotePartKind.items => l10n.noteSizeItems,
        NotePartKind.pageNotes => l10n.noteSizePageNotes,
        NotePartKind.attachment => '"${part.name}"',
      };
      text = l10n.noteTooLarge('${issue.bytes! ~/ 1024} KB', name);
    }
    messenger.showMessage(text, duration: const Duration(seconds: 8));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
