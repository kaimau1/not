import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../../../core/utils/note_fonts.dart';
import '../../../core/utils/note_guard.dart';
import '../../../core/utils/rich_text.dart';
import '../../../core/widgets/undo_snackbar.dart';
import '../data/notes_repository.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'note_actions_sheet.dart';
import 'notes_providers.dart';

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// Not tarihini kısa gösterir: bugünse saat, aynı yılsa "5 Tem",
/// eski yıllarsa "5 Tem 2025".
String formatNoteDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return DateFormat('HH:mm').format(date);
  }
  if (date.year == now.year) return DateFormat('d MMM').format(date);
  return DateFormat('d MMM y').format(date);
}

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
    spans.add(
      TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: scheme.primary,
          backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
        ),
      ),
    );
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

  Future<void> _openNote(BuildContext context) async {
    // Kilitli not: önce kimlik doğrulaması (biyometrik/ekran kilidi).
    if (note.locked) {
      final ok = await authenticateForNote(context.l10n.unlockAuthReason);
      if (!ok || !context.mounted) return;
    }
    if (context.mounted) await context.push('/note/${note.id}');
  }

  void _delete(BuildContext context, WidgetRef ref) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.softDelete(note.id);
    final l10n = context.l10n;
    showUndoSnackBar(
      context,
      message: l10n.noteDeleted,
      undoLabel: l10n.undo,
      onUndo: () => repo.restore(note.id),
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
          value: 'star',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(note.starred ? Icons.star : Icons.star_outline),
            title: Text(note.starred ? l10n.unstar : l10n.star),
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
      case 'star':
        ref.read(notesRepositoryProvider)?.setStarred(note.id, !note.starred);
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

    final hasTitle = note.title.trim().isNotEmpty;
    // Durum rozetleri (yıldız/sabit/AI) başlık satırının sağında akar.
    final badges = <Widget>[
      if (note.starred) Icon(Icons.star, size: 14, color: Colors.amber.shade600),
      if (note.pinned)
        Icon(Icons.push_pin, size: 14, color: scheme.onSurfaceVariant),
      // AI özeti göstergesi rozet olarak sağ üstte durur.
      if (!note.locked && note.aiSummary != null)
        Icon(Icons.auto_awesome, size: 14, color: scheme.primary),
    ];
    // Üst satır yalnızca başlık ya da rozet varsa çizilir. Başlıksız notta
    // (madde 5) boş bir üst bant bırakılmaz; içerik doğrudan tepeden başlar,
    // "yazılar ortaya kayıyor" izlenimi ortadan kalkar.
    final showTopRow = hasTitle || badges.isNotEmpty;

    final content = Padding(
      // Başlıksız kartta sağdan biraz içerik payı bırakılır ki ilk satır
      // köşedeki üç nokta düğmesinin altına girmesin.
      padding: EdgeInsets.fromLTRB(12, 10, showTopRow ? 12 : 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTopRow)
            Padding(
              // Sağdaki 30px köşedeki üç nokta düğmesine yer açar; uzun başlık
              // düğmenin altına girmeden kısalır (…).
              padding: const EdgeInsets.only(bottom: 6, right: 30),
              child: Row(
                children: [
                  Expanded(
                    child: hasTitle
                        ? highlightedText(
                            context,
                            note.title,
                            highlightQuery,
                            maxLines: 2,
                            // Başlık da notun yazı tipini kullanır.
                            style: applyNoteFont(
                              (Theme.of(context).textTheme.titleSmall ??
                                      const TextStyle())
                                  .copyWith(fontWeight: FontWeight.w600),
                              note.fontFamily,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  for (final badge in badges)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: badge,
                    ),
                ],
              ),
            ),
          // Kilitli not: içerik kartta gösterilmez; yalnızca kilit satırı.
          if (note.locked)
            Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.lockedNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          else ...[
            _NotePreview(note: note, highlightQuery: highlightQuery),
            if (note.attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              _AttachmentPreview(attachments: note.attachments),
            ],
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
                for (final tag in note.tags.take(2)) _MiniBadge(label: '#$tag'),
                if (note.tags.length > 2)
                  _MiniBadge(label: '+${note.tags.length - 2}'),
              ],
            ),
          ],
          if (note.updatedAt != null) ...[
            const SizedBox(height: 6),
            // Son güncelleme: kartın sağ altında sessiz bir zaman damgası.
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatNoteDate(note.updatedAt!),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final card = Material(
      color: NoteColors.surface(context, note.color),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Seçim modunda dokunuş seçimi değiştirir; normalde notu açar. Uzun
        // basış dashboard sarmalayıcısında yönetilir: yerinde bırakınca çoklu
        // seçim, sürükleyince yeniden sıralama (üç nokta menüsündeki "Seç" de
        // durur).
        onTap: selectionActive ? toggleSelection : () => _openNote(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Öncelik: seçim > renkli çerçeve > ince varsayılan kenarlık.
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : note.frameColor != NoteColor.none
                  ? NoteColors.swatch(note.frameColor)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected
                  ? 2
                  : note.frameColor != NoteColor.none
                  ? 2.5
                  : 1,
            ),
          ),
          child: content,
        ),
      ),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onSecondaryTapUp: _isDesktop
            ? (details) =>
                  _showContextMenu(context, ref, details.globalPosition)
            : null,
        child: Stack(
          children: [
            card,
            // Üç nokta hızlı işlem düğmesi (madde 5): kartın SAĞ ÜST KÖŞESİnde
            // durur — ikon köşeye hizalı, dokunma alanı 36dp. Seçim modunda
            // gizlenir; yerine tik rozeti gelir. Katmandan bağımsız olduğu için
            // başlık satırının yerleşimini değiştirmez (masonry sütun dengesi
            // seçim sırasında sabit kalır).
            if (!selectionActive)
              Positioned(
                top: 2,
                right: 2,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => showNoteActionsSheet(context, ref, note),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
          // fontSize 10 kaldırıldı: tip ölçeğinin dışında keyfi bir değerdi.
          // labelSmall (11sp) Material'in kendi en küçük rolü.
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
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
    // Kart önizlemesi notun KENDİ yazı tipini ve boyut çarpanını kullanır:
    // kullanıcı yazı tipini değiştirdiğinde ana ekranda da görmeli, yoksa
    // seçim yalnız editörde varmış gibi duruyordu. Kartın kendi küçük taban
    // boyutu korunur; çarpan onun üzerine biner (ızgara bozulmasın diye
    // makul bir tavanla).
    final cardBase = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final bodyStyle = applyNoteFont(
      cardBase.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.85),
        fontSize: (cardBase.fontSize ?? 12) * note.fontScale.clamp(0.8, 1.4),
      ),
      note.fontFamily,
    );

    switch (note.type) {
      case NoteType.text:
        // Karışık içerik: metin notu hem gövde hem checklist maddesi taşıyabilir.
        final hasBody = note.body.trim().isNotEmpty;
        // Editörle aynı düzen: işaretsiz (aktif) maddeler üstte, işaretliler
        // altta. Depodaki ham sıra işaretlileri araya serpiştirebiliyor; kart
        // bunları sıralamadan gösterince aktif maddelerin bir kısmı önizlemede
        // görünmüyordu (kullanıcı: "notta 4 madde var, kartta 2 görünüyor").
        final rawItems = [
          for (final i in note.items)
            if (i.text.trim().isNotEmpty) i,
        ];
        final items = [
          for (final i in rawItems)
            if (!i.checked) i,
          for (final i in rawItems)
            if (i.checked) i,
        ];
        if (!hasBody && items.isEmpty) return const SizedBox.shrink();
        // Madde varsa metin 2 satıra kısalır ki maddelere yer kalsın; yoksa
        // 4 satır (8 satır 2 sütunlu ızgarada metin duvarına dönüşüyordu).
        final maxItems = hasBody ? 3 : 5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBody)
              highlightedText(
                context,
                // Kartta biçim işaretleri (**kalın** gibi) gösterilmez:
                // önizleme okunabilir kalmalı.
                stripRichMarkers(note.body),
                highlightQuery,
                maxLines: items.isEmpty ? 4 : 2,
                style: bodyStyle,
              ),
            if (items.isNotEmpty) ...[
              if (hasBody) const SizedBox(height: 6),
              for (final item in items.take(maxItems))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6, top: 1),
                        child: Icon(
                          item.checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          stripRichMarkers(item.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: item.checked
                              ? bodyStyle.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: scheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                )
                              : bodyStyle,
                        ),
                      ),
                    ],
                  ),
                ),
              if (items.length > maxItems)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    context.l10n.moreItemsCount(items.length - maxItems),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        );
      case NoteType.checklist:
      case NoteType.ordered:
        final raw = [
          for (final item in note.items)
            if (item.text.trim().isNotEmpty) item,
        ];
        // Checklist'te işaretsizler önce (editördeki düzen); sıralı listede
        // numara sırası korunmalı, dokunma.
        final visible = note.type == NoteType.checklist
            ? [
                for (final i in raw)
                  if (!i.checked) i,
                for (final i in raw)
                  if (i.checked) i,
              ]
            : raw;
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
                        style:
                            shown[i].checked && note.type == NoteType.checklist
                            ? bodyStyle.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
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
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
    final slides = [
      for (final a in attachments)
        if (a.kind == AttachmentKind.slide) a,
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
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 14,
                  color: scheme.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    pdf.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (final slide in slides.take(2))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.slideshow_outlined,
                  size: 14,
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    slide.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _thumb(Attachment attachment) {
    // Kart küçük resmi için 2048 px'lik eki tam boy çözdürmek boşuna bellek
    // ve CPU (liste kaydırma takılması); 480 px, 3x ekranda bile yeterli.
    if (attachment.isUploaded) {
      return CachedNetworkImage(
        imageUrl: attachment.downloadUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        memCacheWidth: 480,
      );
    }
    if (attachment.localPath.isNotEmpty &&
        File(attachment.localPath).existsSync()) {
      return Image.file(
        File(attachment.localPath),
        fit: BoxFit.cover,
        cacheWidth: 480,
      );
    }
    return Container(
      color: Colors.black12,
      child: const Icon(Icons.image_outlined, size: 20),
    );
  }
}
