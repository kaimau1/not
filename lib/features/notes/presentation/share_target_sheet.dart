import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/utils/rich_text.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';
import 'capture_mode_sheet.dart';
import 'note_grid.dart';
import '../../../core/widgets/app_sheet.dart';

/// Paylaşımla / "Birlikte aç" ile gelen içeriğin levhada görünen özeti.
@immutable
class ShareIncoming {
  const ShareIncoming({this.text = '', this.files = const []});

  /// Gövdeye gidecek metin (bağlantı, paylaşılan yazı, .txt içeriği).
  final String text;

  /// Ek olacak dosyalar: ad + tür.
  final List<({String name, AttachmentKind kind})> files;

  bool get hasFiles => files.isNotEmpty;
}

/// Levhadan dönen karar: YENİ not mu, VAR OLAN bir not mu?
@immutable
class ShareDestination {
  /// Yeni not. [choice] belge paylaşımında kipi (balonlu/klasik) ve başlığı,
  /// diğerlerinde yalnız başlığı taşır.
  const ShareDestination.newNote(CaptureChoice this.choice) : noteId = null;

  /// İçerik bu nota eklenir.
  const ShareDestination.existing(String this.noteId) : choice = null;

  final String? noteId;
  final CaptureChoice? choice;

  bool get isExisting => noteId != null;
}

/// Paylaşılan içerik bu nota eklenebilir mi?
///
/// * Kilitli not LİSTELENMEZ: kilidi açmadan başlığı/içeriği göstermek ve
///   içine yazmak kilidin anlamını boşa çıkarırdı.
/// * Arşivlenmiş not listelenmez (ana ekranda da görünmüyor).
/// * YALNIZ METİN gelen paylaşım belge (PDF/sunum) notuna gitmez: o notun
///   gövdesi ekranda yok, yazı kaybolmuş gibi görünürdü.
bool canReceiveShare(Note note, {required bool hasFiles}) {
  if (note.locked || note.archivedAt != null) return false;
  if (!hasFiles && note.type.isPageNoteType) return false;
  return true;
}

/// Seçim listesinin sırası ve araması (saf, testli): en son düzenlenen üstte;
/// sorgu başlıkta VE içerikte aranır (Türkçe büyük/küçük harf farkı yok).
List<Note> shareCandidates(
  List<Note> notes, {
  required bool hasFiles,
  String query = '',
}) {
  final q = _fold(query.trim());
  final out = [
    for (final n in notes)
      if (canReceiveShare(n, hasFiles: hasFiles) &&
          (q.isEmpty || _fold(n.toPlainText()).contains(q)))
        n,
  ];
  out.sort((a, b) {
    final at = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bt = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bt.compareTo(at);
  });
  return out;
}

String _fold(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

/// **PAYLAŞIM HEDEFİ LEVHASI** (kullanıcı isteği 2026-09-29: "PDF açmak
/// istediğimde Notlar ana sayfası açılıp, ister eski bir notuma ekleme
/// istersem yeni not oluşturma seçenekleri gelsin bir arayüzde").
///
/// Eskiden paylaşılan belge HER ZAMAN yeni bir not açıyordu (yalnız kipi
/// soruluyordu); var olan bir nota eklemek için önce yeni not açıp dosyayı
/// oradan taşımak gerekiyordu. Levha artık iki yolu yan yana sunar:
/// * **Yeni not** — belge ise balonlu/klasik kip kartları (eski levhanın
///   aynısı), değilse tek düğme; isteğe bağlı başlık.
/// * **Var olan nota ekle** — aranabilir not listesi, en son düzenlenen
///   üstte; klasör adı ve tarih her satırda.
///
/// [askMode]: belge (PDF/sunum) paylaşımında yeni not kipi sorulur.
/// [folderNames]: satırlarda klasör adını göstermek için (id → ad).
/// Vazgeçilirse null.
Future<ShareDestination?> showShareTargetSheet(
  BuildContext context, {
  required ShareIncoming incoming,
  required List<Note> notes,
  Map<String, String> folderNames = const {},
  bool askMode = false,
  String? newNoteLabel,
  Widget Function(Note note)? cardBuilder,
}) => showAppSheet<ShareDestination>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (sheetContext) => Padding(
    // Klavye (başlık / arama) açılınca levha yukarı kalkar.
    padding: EdgeInsets.only(
      bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
    child: ShareTargetSheet(
      incoming: incoming,
      notes: notes,
      folderNames: folderNames,
      askMode: askMode,
      newNoteLabel: newNoteLabel,
      cardBuilder: cardBuilder,
    ),
  ),
);

/// Levhanın kendisi (testte doğrudan kurulabilsin diye açık).
class ShareTargetSheet extends StatefulWidget {
  const ShareTargetSheet({
    super.key,
    required this.incoming,
    required this.notes,
    this.folderNames = const {},
    this.askMode = false,
    this.newNoteLabel,
    this.cardBuilder,
  });

  final ShareIncoming incoming;
  final List<Note> notes;
  final Map<String, String> folderNames;
  final bool askMode;
  final String? newNoteLabel;

  /// Verilirse "Var olan nota" notları ANA EKRAN KARTLARIYLA iki sütunlu
  /// ızgarada gösterir (kullanıcı isteği 2026-10-28: "var olan nota ekle
  /// sayfasında direk tümü sayfası görülsün, aynı dashboard görünümünde").
  /// Kart sağlayıcılara bağlı olduğundan dışarıdan verilir; verilmezse
  /// (test) sade satır listesi.
  final Widget Function(Note note)? cardBuilder;

  @override
  State<ShareTargetSheet> createState() => _ShareTargetSheetState();
}

class _ShareTargetSheetState extends State<ShareTargetSheet> {
  final _title = TextEditingController();
  final _search = TextEditingController();
  bool _existing = false;
  String _query = '';

  @override
  void dispose() {
    _title.dispose();
    _search.dispose();
    super.dispose();
  }

  void _create(CaptureMode mode) => Navigator.pop(
    context,
    ShareDestination.newNote(
      CaptureChoice(mode: mode, noteTitle: _title.text.trim()),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = MediaQuery.sizeOf(context).height;
    // KAYAR: kısa ekranda / yatayda / klavye açıkken (başlık, arama) kip
    // kartları ya da not listesi levhaya sığmayabilir.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.shareTargetTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _IncomingSummary(incoming: widget.incoming),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(l10n.shareTargetNew),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.playlist_add),
                  label: Text(l10n.shareTargetExisting),
                ),
              ],
              selected: {_existing},
              showSelectedIcon: false,
              onSelectionChanged: (v) {
                FocusScope.of(context).unfocus();
                setState(() => _existing = v.first);
              },
            ),
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _existing
                  ? _existingPane(context, height)
                  : _newPane(context, scheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _newPane(BuildContext context, ColorScheme scheme) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('share-new'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            isDense: true,
            labelText: l10n.captureNoteTitle,
            hintText: l10n.captureNoteTitleHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: widget.askMode
              ? null
              : (_) => _create(CaptureMode.classic),
        ),
        const SizedBox(height: 14),
        if (widget.askMode) ...[
          Text(
            widget.newNoteLabel == null
                ? l10n.captureModeQuestion
                : '${widget.newNoteLabel} · ${l10n.captureModeQuestion}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          CaptureModeCards(onPick: _create),
        ] else
          FilledButton.icon(
            onPressed: () => _create(CaptureMode.classic),
            icon: const Icon(Icons.note_add_outlined),
            label: Text(l10n.shareTargetCreate),
          ),
      ],
    );
  }

  Widget _existingPane(BuildContext context, double screenHeight) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final candidates = shareCandidates(
      widget.notes,
      hasFiles: widget.incoming.hasFiles,
      query: _query,
    );
    final cardBuilder = widget.cardBuilder;
    final listHeight = cardBuilder == null
        ? (screenHeight * 0.45).clamp(200.0, 460.0)
        : (screenHeight * 0.62).clamp(260.0, 720.0);
    return Column(
      key: const ValueKey('share-existing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: const Icon(Icons.search),
            hintText: l10n.shareTargetSearch,
            border: const OutlineInputBorder(),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clearSearch,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _search.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: listHeight,
          child: candidates.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty
                        ? l10n.shareTargetNoNotes
                        : l10n.shareTargetNoMatch,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              : cardBuilder != null
              ? NoteBalancedGrid(
                  notes: candidates,
                  columns: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, i) => _PickableCard(
                    onTap: () => Navigator.pop(
                      context,
                      ShareDestination.existing(candidates[i].id),
                    ),
                    child: cardBuilder(candidates[i]),
                  ),
                )
              : ListView.separated(
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, i) => _NoteRow(
                    note: candidates[i],
                    folderName: widget.folderNames[candidates[i].folderId],
                    onTap: () => Navigator.pop(
                      context,
                      ShareDestination.existing(candidates[i].id),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Gelen içeriğin özeti: dosya çipleri (tür simgesi + ad) ya da metnin ilk
/// satırları. Kullanıcı neyi nereye koyduğunu levhada görür.
class _IncomingSummary extends StatelessWidget {
  const _IncomingSummary({required this.incoming});

  final ShareIncoming incoming;

  static IconData _icon(AttachmentKind kind) => switch (kind) {
    AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
    AttachmentKind.slide => Icons.slideshow_outlined,
    AttachmentKind.image => Icons.image_outlined,
    AttachmentKind.video => Icons.videocam_outlined,
    AttachmentKind.audio => Icons.audiotrack_outlined,
    _ => Icons.insert_drive_file_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const shown = 3;
    final files = incoming.files;
    final text = incoming.text.trim();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (files.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in files.take(shown))
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(_icon(f.kind), size: 18),
                      label: Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (files.length > shown)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      context.l10n.shareTargetMore(files.length - shown),
                    ),
                  ),
              ],
            ),
          if (text.isNotEmpty) ...[
            if (files.isNotEmpty) const SizedBox(height: 6),
            Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ana ekran kartı, ama dokununca NOTU AÇMAZ, seçer: kartın kendi
/// dokunuş/uzun basış işleri devre dışı, üstte "ekle" rozeti.
class _PickableCard extends StatelessWidget {
  const _PickableCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          IgnorePointer(child: child),
          Positioned(
            right: 6,
            bottom: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.add, size: 18, color: scheme.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Listede tek not: tür simgesi, başlık (yoksa ilk satır), klasör ve tarih.
class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note, required this.onTap, this.folderName});

  final Note note;
  final String? folderName;
  final VoidCallback onTap;

  IconData get _icon => switch (note.type) {
    NoteType.checklist => Icons.checklist,
    NoteType.ordered => Icons.format_list_numbered,
    NoteType.pdf => Icons.picture_as_pdf_outlined,
    NoteType.slides => Icons.slideshow_outlined,
    NoteType.archive => Icons.inventory_2_outlined,
    NoteType.text => Icons.notes,
  };

  String _headline(BuildContext context) {
    final title = note.displayTitle.trim();
    if (title.isNotEmpty) return title;
    for (final line in stripRichMarkers(note.toPlainText()).split('\n')) {
      if (line.trim().isNotEmpty) return line.trim();
    }
    for (final a in note.attachments) {
      if (a.fileName.trim().isNotEmpty) return a.fileName.trim();
    }
    return context.l10n.remindersUntitled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final updated = note.updatedAt;
    final meta = [
      if (folderName != null && folderName!.trim().isNotEmpty) folderName!,
      if (updated != null)
        DateFormat.MMMd(context.l10n.localeName).format(updated),
      if (note.attachments.isNotEmpty) '📎 ${note.attachments.length}',
    ].join(' · ');
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_icon, size: 20, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _headline(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
