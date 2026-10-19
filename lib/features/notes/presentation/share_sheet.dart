import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/note_colors.dart';
import '../../../core/l10n_ext.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../folders/data/folders_repository.dart';
import '../../folders/presentation/folder_sheets.dart' show showFolderShareSheet;
import '../../inbox/presentation/send_note_sheet.dart';
import '../../settings/settings_providers.dart' show sharedPreferencesProvider;
import '../data/attachment_repository.dart';
import '../data/note_pdf.dart';
import '../data/note_quick_export.dart';
import '../data/note_share.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_share_text.dart';
import '../domain/note_type.dart';
import 'collaborators_sheet.dart';
import 'pdf_export_screen.dart';
import '../../../core/widgets/app_sheet.dart';

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
/// * **Uygulama içinde** — iki kavram (F3.7): Birlikte düzenle (ortak not /
///   klasör) ve Kopya gönder (arkadaşın gelen kutusu).
///
///
/// 2026-10-16 YENİDEN DÜZEN (kullanıcı: "paylaşım seçenekleri düzenlenmeli
/// ve geliştirilmeli"): seçenekler uzun bir liste hâlindeydi ve notu dosya
/// olarak göndermenin tek yolu dışa aktarma ekranıydı. Artık önizlemenin
/// altında TEK DOKUNUŞLUK bir ızgara: Metin · Kopyala · PDF · Görsel ·
/// Ekler · Arkadaşa · Birlikte · Not paketi (bkz. [NoteQuickExport]); ince
/// ayarlı PDF/Word ve balonlu PDF "Daha fazla"da. İçerik çiplerine "Video
/// bağlantıları" eklendi; çip seçimi HATIRLANIR (son paylaşımdaki gibi açılır).
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
  final prefs = ref.read(sharedPreferencesProvider);
  final initial = ShareTextOptions.decode(prefs.getString(_optionsKey));
  final result = await showAppSheet<(String, ShareTextOptions)>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _ShareSheet(
      note: note,
      initial: initial,
      canCollaborate: ownerId == null && !ref.read(isAnonymousProvider),
    ),
  );
  if (result == null || !context.mounted) return;
  final (choice, options) = result;
  // Çiplerin son hâli bir sonraki paylaşımda da geçerli.
  await prefs.setString(_optionsKey, options.encode());
  if (!context.mounted) return;
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
    case 'folder':
      final folder = (ref.read(foldersStreamProvider).value ?? const [])
          .where((f) => f.id == note.folderId)
          .firstOrNull;
      if (folder != null) await showFolderShareSheet(context, ref, folder);
    default:
      await runNoteShare(context, ref, note, choice, options: options);
  }
}

/// Paylaşım çiplerinin saklandığı tercih anahtarı.
const _optionsKey = 'share_text_options';

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    required this.note,
    required this.canCollaborate,
    this.initial = const ShareTextOptions(),
  });

  final Note note;
  final bool canCollaborate;
  final ShareTextOptions initial;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  late var _options = widget.initial;

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
    final hasLinks = shareableVideoLinks(note).isNotEmpty;
    final stamped = countStampablePdfs(note);
    final files = shareableAttachments(note).length;

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
          if (hasTitle || hasChecked || hasLinks || note.tags.isNotEmpty)
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
                  if (hasLinks)
                    FilterChip(
                      key: const ValueKey('share-include-links'),
                      label: Text(l10n.shareIncludeVideoLinks),
                      selected: _options.links,
                      onSelected: (v) => setState(
                        () => _options = _options.copyWith(links: v),
                      ),
                    ),
                ],
              ),
            ),
          // **İKİ KAVRAM** (F3.7): uygulama içi paylaşım ya BİRLİKTE DÜZENLE
          // (aynı not/klasör, iki taraf da değiştirir) ya da KOPYA GÖNDER
          // (arkadaşın gelen kutusuna bağımsız kopya; dışarıya metin/dosya).
          if (widget.canCollaborate) ...[
            section(l10n.shareTogetherSection),
            _tile(
              context,
              onTap: () => _pop('collab'),
              icon: Icons.group_add_outlined,
              title: l10n.shareCollaborateShort,
              subtitle: l10n.shareTogetherInfo,
            ),
            if (widget.note.folderId != null)
              _tile(
                context,
                onTap: () => _pop('folder'),
                icon: Icons.folder_shared_outlined,
                title: l10n.shareFolderTogether,
                subtitle: l10n.folderShareInfo,
              ),
          ],
          section(l10n.shareCopySection),
          _tile(
            context,
            onTap: () => _pop('friend'),
            icon: Icons.send_outlined,
            title: l10n.shareToFriendShort,
            subtitle: l10n.shareCopyInfo,
          ),
          // TEK DOKUNUŞLUK IZGARA: dışarıya kopya (metin, PDF, görsel…).
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520 ? 6 : 4;
                final width = constraints.maxWidth / columns;
                Widget cell(Widget child) =>
                    SizedBox(width: width, child: child);
                return Wrap(
                  runSpacing: 6,
                  children: [
                    cell(
                      _QuickShareButton(
                        key: const ValueKey('share-quick-text'),
                        icon: Icons.share_outlined,
                        label: l10n.shareTextAction,
                        primary: true,
                        onTap: hasText ? () => _pop('text') : null,
                      ),
                    ),
                    cell(
                      _QuickShareButton(
                        key: const ValueKey('share-quick-copy'),
                        icon: Icons.copy_outlined,
                        label: l10n.copy,
                        onTap: hasText ? () => _pop('copy') : null,
                      ),
                    ),
                    cell(
                      _QuickShareButton(
                        key: const ValueKey('share-quick-pdf'),
                        icon: Icons.picture_as_pdf_outlined,
                        label: l10n.shareQuickPdf,
                        onTap: () => _pop('pdf_quick'),
                      ),
                    ),
                    if (!kIsWeb)
                      cell(
                        _QuickShareButton(
                          key: const ValueKey('share-quick-image'),
                          icon: Icons.image_outlined,
                          label: l10n.shareAsImage,
                          onTap: () => _pop('png'),
                        ),
                      ),
                    if (files > 0)
                      cell(
                        _QuickShareButton(
                          key: const ValueKey('share-quick-files'),
                          icon: Icons.attach_file,
                          label: l10n.shareAttachmentFiles(files),
                          onTap: () => _pop('files'),
                        ),
                      ),
                    cell(
                      _QuickShareButton(
                        key: const ValueKey('share-quick-package'),
                        icon: Icons.inventory_2_outlined,
                        label: l10n.shareAsNoteShort,
                        onTap: () => _pop('package'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          section(l10n.shareMoreSection),
          _tile(
            context,
            onTap: () => _pop('export'),
            icon: Icons.tune,
            title: l10n.exportNotesOption,
            subtitle: l10n.exportNotesOptionInfo,
          ),
          if (stamped > 0)
            _tile(
              context,
              onTap: () => _pop('pdf'),
              icon: Icons.picture_as_pdf_outlined,
              title: l10n.sharePdfWithBubbles,
              subtitle: l10n.sharePdfWithBubblesInfo,
            ),
        ],
      ),
    );
  }
}

/// Izgaradaki tek dokunuşluk paylaşım düğmesi: yuvarlak simge + altta ad.
class _QuickShareButton extends StatelessWidget {
  const _QuickShareButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final background = primary
        ? scheme.primary
        : scheme.secondaryContainer.withValues(alpha: 0.8);
    final foreground = primary ? scheme.onPrimary : scheme.onSecondaryContainer;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: foreground, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(height: 1.15),
                ),
              ],
            ),
          ),
        ),
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
  return showAppSheet<String>(
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
    case 'pdf_quick':
    case 'png':
      snack(l10n.shareQuickPreparing);
      try {
        final bytes = await NoteQuickExport.pdf(
          note,
          options: options,
          attachments: ref.read(attachmentRepositoryProvider),
          palette: NoteColors.richPalette,
        );
        final name = NotePdf.safeFileName(subject);
        if (choice == 'png') {
          final pages = await NoteQuickExport.pngPages(bytes, name: name);
          if (pages.isEmpty) {
            snack(l10n.shareAsTextEmpty);
            return;
          }
          await SharePlus.instance.share(
            ShareParams(
              files: [for (final p in pages) XFile(p, mimeType: 'image/png')],
              subject: subject,
            ),
          );
          return;
        }
        final file = kIsWeb
            ? XFile.fromData(
                bytes,
                name: '$name.pdf',
                mimeType: 'application/pdf',
              )
            : XFile(
                await NotePdf.writeTemp(bytes, subject),
                mimeType: 'application/pdf',
              );
        await SharePlus.instance.share(
          ShareParams(files: [file], subject: subject),
        );
      } catch (e) {
        snack(l10n.genericError('$e'));
      }
    case 'files':
      snack(l10n.shareQuickPreparing);
      try {
        final files = await NoteQuickExport.attachmentFiles(
          note,
          attachments: ref.read(attachmentRepositoryProvider),
        );
        if (files.isEmpty) {
          snack(l10n.shareAttachmentFilesNone);
          return;
        }
        await SharePlus.instance.share(
          ShareParams(files: files, subject: subject),
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
