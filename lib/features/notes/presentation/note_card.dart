import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../data/notes_repository.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'notes_providers.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Aranan kelimeyi kalın ve renkli vurgulayan metin parçaları üretir.
Widget highlightedText(
  BuildContext context,
  String text,
  String query, {
  TextStyle? style,
  int? maxLines,
}) {
  if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }
  final scheme = Theme.of(context).colorScheme;
  final lower = text.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final index = lower.indexOf(lowerQuery, start);
    if (index < 0) {
      spans.add(TextSpan(text: text.substring(start)));
      break;
    }
    if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
    spans.add(TextSpan(
      text: text.substring(index, index + query.length),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: scheme.primary,
        backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
      ),
    ));
    start = index + query.length;
  }
  return Text.rich(
    TextSpan(style: style, children: spans),
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
  );
}

/// Dashboard'daki kompakt not kartı.
class NoteCard extends ConsumerWidget {
  const NoteCard({super.key, required this.note, this.highlightQuery = ''});

  final Note note;

  /// Aktif arama sorgusu; boş değilse eşleşmeler vurgulanır.
  final String highlightQuery;

  void _openNote(BuildContext context) => context.push('/note/${note.id}');

  void _delete(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.softDelete(note.id);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.noteDeleted),
          // Ekranın ortasında süzülmesin, en altta kısa süre dursun.
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => repo.restore(note.id),
          ),
        ),
      );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final l10n = context.l10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'pin',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(note.pinned ? l10n.unpin : l10n.pin),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.delete),
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (action) {
      case 'pin':
        ref.read(notesRepositoryProvider)?.setPinned(note.id, !note.pinned);
      case 'delete':
        _delete(context, ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final selectedIds = ref.watch(selectedNoteIdsProvider);
    final selectionActive = selectedIds.isNotEmpty;
    final selected = selectedIds.contains(note.id);

    void toggleSelection() =>
        ref.read(selectedNoteIdsProvider.notifier).toggle(note.id);

    final card = Material(
      color: NoteColors.surface(context, note.color),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Seçim modunda dokunuş seçimi değiştirir; uzun basış seçim modunu
        // başlatır (toplu silme için).
        onTap: selectionActive ? toggleSelection : () => _openNote(context),
        onLongPress: _isDesktop ? null : toggleSelection,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.title.trim().isNotEmpty || note.pinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: highlightedText(
                            context,
                            note.title,
                            highlightQuery,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (note.pinned)
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                      ],
                    ),
                  ),
                _NotePreview(note: note, highlightQuery: highlightQuery),
                if (note.attachments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _AttachmentPreview(attachments: note.attachments),
                ],
                if (note.tags.isNotEmpty || note.reminderAt != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (note.reminderAt != null)
                        _MiniBadge(
                          icon: Icons.alarm,
                          label:
                              '${note.reminderAt!.day}.${note.reminderAt!.month} '
                              '${note.reminderAt!.hour.toString().padLeft(2, '0')}:'
                              '${note.reminderAt!.minute.toString().padLeft(2, '0')}',
                        ),
                      // Kart etiketlerle uzamasın: en fazla 2 etiket + "+N".
                      for (final tag in note.tags.take(2))
                        _MiniBadge(label: '#$tag'),
                      if (note.tags.length > 2)
                        _MiniBadge(label: '+${note.tags.length - 2}'),
                    ],
                  ),
                ],
                if (note.aiSummary != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: scheme.primary.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.aiSummaryTitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.primary.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onSecondaryTapUp: _isDesktop
            ? (details) => _showContextMenu(context, ref, details.globalPosition)
            : null,
        child: Stack(
          children: [
            card,
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.check, size: 14, color: scheme.onPrimary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: scheme.onSurfaceVariant),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.note, this.highlightQuery = ''});

  final Note note;
  final String highlightQuery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.85));

    switch (note.type) {
      case NoteType.text:
        if (note.body.trim().isEmpty) return const SizedBox.shrink();
        return highlightedText(
          context,
          note.body,
          highlightQuery,
          maxLines: 8,
          style: bodyStyle,
        );
      case NoteType.checklist:
      case NoteType.ordered:
        final visible = [
          for (final item in note.items)
            if (item.text.trim().isNotEmpty) item,
        ];
        if (visible.isEmpty) return const SizedBox.shrink();
        final shown = visible.take(6).toList();
        final remaining = visible.length - shown.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.type == NoteType.checklist)
                      Padding(
                        padding: const EdgeInsets.only(right: 6, top: 1),
                        child: Icon(
                          shown[i].checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('${i + 1}.', style: bodyStyle),
                      ),
                    Expanded(
                      child: Text(
                        shown[i].text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: shown[i].checked &&
                                note.type == NoteType.checklist
                            ? bodyStyle?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              )
                            : bodyStyle,
                      ),
                    ),
                  ],
                ),
              ),
            if (remaining > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  context.l10n.moreItemsCount(remaining),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        );
    }
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachments});

  final List<Attachment> attachments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = [
      for (final a in attachments)
        if (a.kind == AttachmentKind.image) a,
    ];
    final pdfs = [
      for (final a in attachments)
        if (a.kind == AttachmentKind.pdf) a,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (images.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  for (final image in images.take(3)) ...[
                    Expanded(child: _thumb(image)),
                    if (image != images.take(3).last) const SizedBox(width: 2),
                  ],
                ],
              ),
            ),
          ),
        for (final pdf in pdfs.take(2))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_outlined,
                    size: 14, color: scheme.error),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    pdf.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _thumb(Attachment attachment) {
    if (attachment.isUploaded) {
      return CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
      );
    }
    if (attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync()) {
      return Image.file(File(attachment.localPath), fit: BoxFit.cover);
    }
    return Container(
      color: Colors.black12,
      child: const Icon(Icons.image_outlined, size: 20),
    );
  }
}
