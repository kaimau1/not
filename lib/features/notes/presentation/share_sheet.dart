import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../inbox/presentation/send_note_sheet.dart';
import '../data/attachment_repository.dart';
import '../data/note_pdf.dart';
import '../data/note_share.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_type.dart';
import 'collaborators_sheet.dart';
import 'pdf_export_screen.dart';

/// Notun PAYLAŞ levhası.
///
/// Kök neden (kullanıcı bulgusu 2026-08-08: "paylaş seçenekleri doğru
/// çalışmıyor"): tek bir "Paylaş" düğmesi vardı ve o da notun DÜZ METNİNİ
/// gönderiyordu. PDF notunun düz metni çoğu zaman boş olduğu için düğme hiçbir
/// şey yapmadan kapanıyor, üstelik belgenin üzerindeki balonlar hiçbir yoldan
/// karşı tarafa gitmiyordu.
///
/// 2026-09-26 YENİDEN DÜZEN (kullanıcı: "not paylaşım seçenekleri ve
/// paylaşım içeriğinin düzeni iyileştirilmeli", "kopyalama vb. şeylerin
/// düzeni"): levha üç düz satırdı; ne gideceği görülmüyor, metin Markdown
/// işaretleriyle (`- [ ]`) gidiyordu, kopyalama ve PDF/Word başka
/// menülerdeydi. Artık:
/// * **Önizleme** — gönderilecek metin levhanın tepesinde, seçeneklerle
///   canlı değişir (bkz. [noteShareText]).
/// * **İçerik çipleri** — başlık, tamamlanan maddeler, etiketler.
/// * **Metin** — Paylaş ve Kopyala yan yana, aynı metin.
/// * **Dosya olarak** — PDF / Word, not paketi (`.notpaket`), balonlu PDF.
/// * **Uygulama içinde** — arkadaşa gönder, birlikte düzenle (ortak not).
///
/// [ownerId] doluysa not BAŞKASININ (ortak not / paylaşılan klasör): ortak
/// çalışan ekleme yetkisi yalnız sahipte, o satır çizilmez. [onExport]
/// verilirse PDF/Word satırı onu çağırır (editör sayfa ölçülerini geçirir).
Future<void> showNoteShareSheet(
  BuildContext context,
  WidgetRef ref,
  Note note, {
  String? ownerId,
  VoidCallback? onExport,
}) async {
  final result = await showModalBottomSheet<(String, ShareTextOptions)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _ShareSheet(
      note: note,
      canCollaborate: ownerId == null && !ref.read(isAnonymousProvider),
    ),
  );
  if (result == null || !context.mounted) return;
  final (choice, options) = result;
  switch (choice) {
    case 'export':
      if (onExport != null) {
        onExport();
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PdfExportScreen(note: note)),
        );
      }
    case 'friend':
      await showSendNoteToFriendSheet(context, ref, note);
    case 'collab':
      await showCollaboratorsSheet(context, ref, noteId: note.id);
    default:
      await runNoteShare(context, ref, note, choice, options: options);
  }
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({required this.note, required this.canCollaborate});

  final Note note;
  final bool canCollaborate;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  var _options = const ShareTextOptions();

  void _pop(String choice) => Navigator.pop(context, (choice, _options));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final note = widget.note;
    final text = noteShareText(
      note,
      options: _options,
      pageLabel: l10n.pageLabel,
    );
    final hasText = text.trim().isNotEmpty;
    final hasChecked =
        note.type != NoteType.ordered &&
        note.type != NoteType.archive &&
        note.items.any((i) => i.checked && i.text.trim().isNotEmpty);
    final hasTitle = note.displayTitle.trim().isNotEmpty;
    final stamped = countStampablePdfs(note);

    Widget section(String label) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(l10n.share, style: theme.textTheme.titleLarge),
          ),
          // ÖNİZLEME: gönderilecek metnin kendisi — seçenekler değişince
          // anında güncellenir. KAYDIRILABİLİR (bkz. [_SharePreview]).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SharePreview(
              text: hasText ? text : l10n.shareAsTextEmpty,
              muted: !hasText,
            ),
          ),
          if (hasTitle || hasChecked || note.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (hasTitle)
                    FilterChip(
                      label: Text(l10n.shareIncludeTitle),
                      selected: _options.title,
                      onSelected: (v) => setState(
                        () => _options = _options.copyWith(title: v),
                      ),
                    ),
                  if (hasChecked)
                    FilterChip(
                      label: Text(l10n.shareIncludeChecked),
                      selected: _options.checked,
                      onSelected: (v) => setState(
                        () => _options = _options.copyWith(checked: v),
                      ),
                    ),
                  if (note.tags.isNotEmpty)
                    FilterChip(
                      label: Text(l10n.shareIncludeTags),
                      selected: _options.tags,
                      onSelected: (v) => setState(
                        () => _options = _options.copyWith(tags: v),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasText ? () => _pop('text') : null,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(l10n.shareTextAction),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasText ? () => _pop('copy') : null,
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: Text(l10n.copy),
                  ),
                ),
              ],
            ),
          ),
          section(l10n.shareAsFileSection),
          _tile(
            context,
            onTap: () => _pop('export'),
            icon: Icons.description_outlined,
            title: l10n.exportNotesOption,
            subtitle: l10n.exportNotesOptionInfo,
          ),
          _tile(
            context,
            onTap: () => _pop('package'),
            icon: Icons.inventory_2_outlined,
            title: l10n.shareAsNote,
            subtitle: l10n.shareAsNoteInfo,
          ),
          if (stamped > 0)
            _tile(
              context,
              onTap: () => _pop('pdf'),
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.sharePdfWithBubbles,
              subtitle: l10n.sharePdfWithBubblesInfo,
            ),
          section(l10n.shareInAppSection),
          _tile(
            context,
            onTap: () => _pop('friend'),
            icon: Icons.send_outlined,
            title: l10n.sendNoteAction,
            subtitle: l10n.shareSendFriendInfo,
          ),
          if (widget.canCollaborate)
            _tile(
              context,
              onTap: () => _pop('collab'),
              icon: Icons.group_add_outlined,
              title: l10n.collaborators,
              subtitle: l10n.shareCollaborateInfo,
            ),
        ],
      ),
    );
  }
}

/// Paylaşım levhasının ÖNİZLEMESİ — gönderilecek metnin tamamı.
///
/// KÖK NEDEN (kullanıcı isteği 2026-09-29: "paylaş kısmında önizleme aşağı
/// yukarı kaydırılabilmeli"): önizleme 168 dp'lik bir kutuda
/// `NeverScrollableScrollPhysics` ile duruyordu — uzun notun yalnız ilk
/// satırları görünüyor, sonu soluyor ve geri kalanı hiçbir yoldan
/// okunamıyordu. Artık:
/// * kutunun içi parmakla aşağı-yukarı kayar, kaydırma çubuğu görünür;
/// * solma YALNIZ gerçekten devamı olan kenarda (üstte/altta) çizilir;
/// * sağ üstteki düğme kutuyu ekranın yarısına kadar BÜYÜTÜR / küçültür.
///
/// Levhanın kendisi de kayar (SingleChildScrollView); iç kaydırma parmak
/// kutunun içindeyken kutuyu, dışındayken levhayı kaydırır.
class _SharePreview extends StatefulWidget {
  const _SharePreview({required this.text, required this.muted});

  final String text;
  final bool muted;

  @override
  State<_SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<_SharePreview> {
  final _scroll = ScrollController();
  bool _expanded = false;

  /// Kenarlarda devam var mı (solma buna göre çizilir).
  bool _moreAbove = false;
  bool _moreBelow = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateEdges);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateEdges());
  }

  @override
  void didUpdateWidget(_SharePreview old) {
    super.didUpdateWidget(old);
    // Seçenek değişince metin kısalıp uzayabilir: kenarlar yeniden ölçülür.
    if (old.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateEdges());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _updateEdges() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    final above = position.pixels > 1;
    final below = position.pixels < position.maxScrollExtent - 1;
    if (above != _moreAbove || below != _moreBelow) {
      setState(() {
        _moreAbove = above;
        _moreBelow = below;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final maxHeight = _expanded
        ? (MediaQuery.sizeOf(context).height * 0.5).clamp(220.0, 560.0)
        : 180.0;
    final scrollable = _moreAbove || _moreBelow || _expanded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _moreAbove ? Colors.transparent : Colors.black,
                  Colors.black,
                  Colors.black,
                  _moreBelow ? Colors.transparent : Colors.black,
                ],
                stops: const [0, 0.1, 0.86, 1],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _updateEdges(),
                  );
                  return false;
                },
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: _moreAbove || _moreBelow,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(14, 12, 34, 12),
                    child: Text(
                      widget.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: widget.muted ? scheme.onSurfaceVariant : null,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (scrollable)
            Positioned(
              top: 2,
              right: 2,
              child: IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                tooltip: _expanded
                    ? l10n.sharePreviewCollapse
                    : l10n.sharePreviewExpand,
                icon: Icon(
                  _expanded ? Icons.unfold_less : Icons.unfold_more,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ),
        ],
      ),
    );
  }
}

/// **Dışa aktarma yolu seçimi** — yalnız balonlu/çizimli belge taşıyan
/// notlarda sorulur (bkz. not editöründeki `_export`).
///
/// İki çıktı birbirinin yerine geçmez:
/// * `document` — belgenin KENDİSİ, balonlar/vurgular/el yazısı içine
///   basılmış hâlde (herhangi bir PDF okuyucu açar).
/// * `notes` — notun YAZISI (+ görselleri) PDF ya da Word olarak.
///
/// İptalde null.
Future<String?> showExportChoiceSheet(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tile(
            sheetContext,
            onTap: () => Navigator.pop(sheetContext, 'document'),
            icon: Icons.picture_as_pdf_outlined,
            title: l10n.sharePdfWithBubbles,
            subtitle: l10n.sharePdfWithBubblesInfo,
          ),
          _tile(
            sheetContext,
            onTap: () => Navigator.pop(sheetContext, 'notes'),
            icon: Icons.notes_outlined,
            title: l10n.exportNotesOption,
            subtitle: l10n.exportNotesOptionInfo,
          ),
        ],
      ),
    ),
  );
}

/// Notta damgalanabilecek (balonu ya da çizimi olan) PDF eki sayısı.
int countStampablePdfs(Note note) => note.attachments
    .where(
      (a) =>
          a.kind == AttachmentKind.pdf &&
          (a.bubbles.isNotEmpty || a.ink.isNotEmpty),
    )
    .length;

/// Seçilen paylaşım yolunu koşar. Menüden de (bkz. [showNoteShareSheet]) not
/// işlemleri ızgarasından da aynı gövde çağrılır.
Future<void> runNoteShare(
  BuildContext context,
  WidgetRef ref,
  Note note,
  String choice, {
  ShareTextOptions options = const ShareTextOptions(),
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final subject = note.displayTitle.trim().isEmpty
      ? l10n.appName
      : note.displayTitle.trim();
  void snack(String message) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  switch (choice) {
    case 'text':
    case 'copy':
      final text = noteShareText(
        note,
        options: options,
        pageLabel: l10n.pageLabel,
      );
      // Sessiz kapanmak YOK: boş notta düğmenin neden bir şey yapmadığı
      // söylenir (eski davranışta hiçbir geri bildirim yoktu).
      if (text.trim().isEmpty) {
        snack(l10n.shareAsTextEmpty);
        return;
      }
      if (choice == 'copy') {
        await Clipboard.setData(ClipboardData(text: text));
        snack(l10n.copied);
        return;
      }
      await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
    case 'package':
      snack(l10n.shareAsNotePreparing);
      try {
        await NoteShare.share(
          note,
          attachments: ref.read(attachmentRepositoryProvider),
          fallbackName: l10n.appName,
          shareSubject: subject,
        );
      } catch (e) {
        snack(l10n.genericError('$e'));
      }
    case 'pdf':
      if (countStampablePdfs(note) == 0) {
        snack(l10n.sharePdfWithBubblesNone);
        return;
      }
      snack(l10n.sharePdfWithBubblesPreparing);
      try {
        // Font ANA izolede okunur: `rootBundle` izolede yok (bkz. NotePdf).
        final font = await rootBundle.load(NotePdf.fontAsset);
        final count = await NoteShare.shareAnnotatedPdfs(
          note,
          attachments: ref.read(attachmentRepositoryProvider),
          fontBytes: font.buffer.asUint8List(
            font.offsetInBytes,
            font.lengthInBytes,
          ),
          fileSuffix: l10n.sharePdfWithBubblesSuffix,
          shareSubject: subject,
        );
        if (count == 0) snack(l10n.sharePdfWithBubblesNone);
      } catch (e) {
        snack(l10n.genericError('$e'));
      }
  }
}

Widget _tile(
  BuildContext context, {
  required VoidCallback onTap,
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  final scheme = Theme.of(context).colorScheme;
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    leading: Icon(icon, color: scheme.primary),
    title: Text(title),
    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    onTap: onTap,
  );
}
