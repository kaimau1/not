import '../../../../core/app_icons.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/markdown.dart';
import '../../../../core/utils/spoken_datetime.dart';
import '../../../../core/widgets/app_sheet.dart';
import '../../../../core/widgets/sheet_header.dart';
import '../../../../core/widgets/undo_snackbar.dart';
import '../../../ai/data/gemini_service.dart';
import '../../../ai/presentation/ai_result_note.dart';
import '../../../calendar/presentation/task_editor.dart';
import '../../data/attachment_repository.dart';
import '../../data/media_transcriber.dart';
import '../../data/note_pdf.dart';
import '../../domain/attachment.dart';
import '../../domain/transcript.dart';
import '../../../../core/friendly_error.dart';
import '../../../auth/presentation/account_required.dart';

/// Transkripti kaydeder (yoksa oluşturur, varsa içeriğini değiştirir) ve
/// nottaki güncel eki döndürür; kaydedilemiyorsa (salt okunur not) null.
typedef TranscriptSave = Attachment? Function(String text, Attachment? saved);

/// **TRANSKRİPT EKRANI** — ses/video/görselin metne dökümünü üretir, okutur
/// ve içinden seçileni nota ekletir (kullanıcı isteği 2026-10-17).
///
/// İki giriş:
/// * [transcript] verilirse (kayıtlı metin eki) doğrudan OKUMA ekranıdır.
/// * Yalnız [source] verilirse döküm burada başlar; biter bitmez nota METİN
///   EKİ olarak kaydedilir ([onSave]) — AI puanı bir kez harcanır, metin bir
///   daha sorulmadan okunur.
///
/// Okurken metin parmakla seçilir; seçim menüsünde ve alttaki büyük düğmede
/// "Seçimi nota ekle" durur (seçim yoksa "Tümünü nota ekle"). Yanlış duyulan
/// sözcük "Düzenle" ile düzeltilip kaydedilir.
class TranscriptScreen extends ConsumerStatefulWidget {
  const TranscriptScreen({
    super.key,
    this.source,
    this.transcript,
    this.onSave,
    this.onInsert,
    this.onCreateNote,
    this.onDelete,
    this.autoInsert = false,
  }) : assert(source != null || transcript != null);

  /// Metne dökülen ek (ses/video/görsel). Kaynağı silinmiş bağımsız metin
  /// ekinde null — o zaman "yeniden dök" seçeneği yok.
  final Attachment? source;

  /// Kayıtlı metin eki (yoksa döküm açılışta başlar).
  final Attachment? transcript;

  final TranscriptSave? onSave;

  /// Metni notun gövdesine/maddelerine ekler (salt okunur notta null).
  final ValueChanged<String>? onInsert;

  /// Metinden YENİ not açar. Ekran önce kendini kapatır.
  final Future<void> Function(String text)? onCreateNote;

  /// Transkript ekini nottan kaldırır.
  final ValueChanged<Attachment>? onDelete;

  /// Döküm bitince metnin tamamı nota KENDİLİĞİNDEN eklensin mi ("Dosyayı
  /// metne dök" akışı — boş nota dosyanın yazısı düşer).
  final bool autoInsert;

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  Attachment? _saved;
  String _text = '';
  bool _busy = false;
  String? _error;

  /// Döküm bitti ama metin çıkmadı (yazısız görsel / konuşmasız kayıt).
  bool _empty = false;

  /// Metin cihazda (ML Kit) mı okundu — bilgi satırı için.
  bool _onDevice = false;

  bool _editing = false;
  final _editController = TextEditingController();

  /// Zaman damgaları görünsün mü (yalnız metinde damga varsa sorulur).
  bool _showTimes = true;

  /// Okuma metnindeki seçim. ValueNotifier: seçim her değiştiğinde KOCA
  /// metni yeniden kurmamak için yalnız alttaki düğme dinler.
  final _selection = ValueNotifier<String>('');

  bool _autoInserted = false;

  @override
  void initState() {
    super.initState();
    _saved = widget.transcript;
    _text = widget.transcript?.text ?? '';
    if (_saved == null && widget.source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    _selection.dispose();
    super.dispose();
  }

  AttachmentKind? get _kind => widget.source?.kind;

  /// Ekranda gösterilen metin. Önbellekli: seçim her değiştiğinde (sürükleme
  /// boyunca kare kare) okunuyor; damga ayıklaması koca metinde her seferinde
  /// koşmasın.
  String get _shown {
    final cache = _shownCache;
    if (cache != null && identical(cache.$1, _text) && cache.$2 == _showTimes) {
      return cache.$3;
    }
    // Markdown eki (P54) ham işaretlerle değil okunur hâliyle gösterilir;
    // "nota ekle" de bu hâli alır.
    final saved = _saved;
    final text = saved != null &&
            isMarkdownFile(saved.fileName, mime: saved.mimeType)
        ? markdownReadable(_text)
        : _text;
    final value = _showTimes ? text : Transcripts.stripTimestamps(text);
    _shownCache = (_text, _showTimes, value);
    return value;
  }

  (String, bool, String)? _shownCache;

  /// Nota giden biçim: damgalar notun tanıdığı düz biçimde ("1:23 söz").
  String _forNote(String text) => _showTimes
      ? Transcripts.plainTimestamps(text)
      : Transcripts.stripTimestamps(text);

  Future<void> _run({bool preferAi = false}) async {
    if (preferAi && !ensureAiReady(context, ref)) return;
    final source = widget.source;
    if (source == null || _busy) return;
    final l10n = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
      _empty = false;
    });
    try {
      final transcriber = ref.read(mediaTranscriberProvider);
      final text = Transcripts.clamp(
        await transcriber.transcribe(source, preferAi: preferAi),
      );
      if (!mounted) return;
      final onDevice =
          source.kind == AttachmentKind.image &&
          !preferAi &&
          MediaTranscriber.deviceOcr;
      if (text.isEmpty || text == '[Konuşma yok]') {
        setState(() {
          _busy = false;
          _empty = true;
          _onDevice = onDevice;
        });
        return;
      }
      setState(() {
        _busy = false;
        _text = text;
        _onDevice = onDevice;
      });
      final saved = widget.onSave?.call(text, _saved);
      if (saved != null) {
        _saved = saved;
        _snack(l10n.transcriptSaved);
      }
      if (widget.autoInsert && !_autoInserted) {
        _autoInserted = true;
        widget.onInsert?.call(_forNote(text));
      }
    } on MediaTooLargeException catch (e) {
      _fail(l10n.transcriptTooLarge(e.sizeBytes ~/ (1024 * 1024)));
    } on UnsupportedMediaException catch (e) {
      _fail(l10n.transcriptUnsupported(e.format));
    } on AttachmentMissingException {
      _fail(l10n.attachmentNotSynced);
    } on GeminiException catch (e) {
      _fail(aiErrorText(l10n, e));
    } catch (e) {
      _fail(aiErrorText(l10n, e));
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(message);
  }

  /// Seçili parça (yoksa tümü) nota eklenir; ekran açık kalır ki birden çok
  /// parça sırayla alınabilsin.
  void _insert(String text) {
    final insert = widget.onInsert;
    final chunk = text.trim();
    if (insert == null || chunk.isEmpty) return;
    insert(_forNote(chunk));
    _snack(context.l10n.transcriptInserted);
  }

  Future<void> _newNote(String text) async {
    final create = widget.onCreateNote;
    final chunk = text.trim();
    if (create == null || chunk.isEmpty) return;
    Navigator.of(context).pop();
    await create(_forNote(chunk));
  }

  Future<void> _copy(String text) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (mounted) _snack(context.l10n.copied);
  }

  /// `.txt` DOSYASI olarak paylaşır (metin değil): kullanıcı istediği
  /// uygulamaya dosya olarak gönderir, karşı tarafta ek olarak açılır.
  Future<void> _share() async {
    if (_text.trim().isEmpty) return;
    final name =
        _saved?.fileName ??
        Transcripts.fileNameFor(
          widget.source!,
          context.l10n.transcriptFileSuffix,
        );
    final safe =
        '${NotePdf.safeFileName(p.basenameWithoutExtension(name))}.txt';
    final bytes = Uint8List.fromList(utf8.encode(_shown));
    final XFile file;
    if (kIsWeb) {
      file = XFile.fromData(bytes, name: safe, mimeType: 'text/plain');
    } else {
      final dir = await getTemporaryDirectory();
      final out = File(p.join(dir.path, safe));
      await out.writeAsBytes(bytes, flush: true);
      file = XFile(out.path, name: safe, mimeType: 'text/plain');
    }
    await SharePlus.instance.share(ShareParams(files: [file]));
  }

  void _startEdit() {
    _editController.text = _text;
    setState(() => _editing = true);
  }

  void _saveEdit() {
    final text = Transcripts.clamp(_editController.text);
    setState(() {
      _editing = false;
      _text = text;
    });
    final saved = widget.onSave?.call(text, _saved);
    if (saved != null) _saved = saved;
  }

  Future<void> _delete() async {
    final saved = _saved;
    final remove = widget.onDelete;
    if (saved == null || remove == null) return;
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.transcriptDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    remove(saved);
    Navigator.of(context).pop();
  }

  String _workingLabel() {
    final l10n = context.l10n;
    return switch (_kind) {
      AttachmentKind.video => l10n.transcriptWorkingVideo,
      AttachmentKind.image => l10n.transcriptWorkingImage,
      _ => l10n.transcriptWorkingAudio,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasText = _text.trim().isNotEmpty;
    final title =
        _saved?.fileName ?? widget.source?.fileName ?? l10n.transcriptTitle;
    final canRetry = widget.source != null && !_busy;
    final isImage = _kind == AttachmentKind.image;
    final saved = _saved;
    final markdown =
        saved != null && isMarkdownFile(saved.fileName, mime: saved.mimeType);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // .md eki (P54b): üstte dosya adı, altta "Markdown" — transkript
            // değil.
            Text(markdown ? title : l10n.transcriptTitle),
            Text(
              markdown ? 'Markdown' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          if (hasText && !_editing) ...[
            IconButton(
              tooltip: l10n.copy,
              icon: const Icon(AppIcons.copy),
              onPressed: () => _copy(
                _selection.value.isNotEmpty ? _selection.value : _shown,
              ),
            ),
            IconButton(
              tooltip: l10n.share,
              icon: const Icon(Icons.ios_share),
              onPressed: _share,
            ),
          ],
          if (_editing)
            TextButton(onPressed: _saveEdit, child: Text(l10n.transcriptSave))
          else if (hasText || canRetry || _saved != null)
            PopupMenuButton<String>(
              tooltip: l10n.more,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _startEdit();
                  case 'ai':
                    unawaited(_run(preferAi: true));
                  case 'times':
                    setState(() => _showTimes = !_showTimes);
                  case 'note':
                    unawaited(_newNote(_shown));
                  case 'delete':
                    unawaited(_delete());
                }
              },
              itemBuilder: (context) => [
                if (hasText && widget.onSave != null)
                  _menuItem('edit', Icons.edit_outlined, l10n.transcriptEdit),
                if (canRetry)
                  _menuItem(
                    'ai',
                    Icons.auto_awesome_outlined,
                    isImage
                        ? l10n.transcriptReadWithAi
                        : l10n.transcriptRetryAi,
                  ),
                if (hasText && Transcripts.hasTimestamps(_text))
                  CheckedPopupMenuItem(
                    value: 'times',
                    checked: _showTimes,
                    child: Text(l10n.transcriptShowTimes),
                  ),
                if (hasText && widget.onCreateNote != null)
                  _menuItem(
                    'note',
                    Icons.note_add_outlined,
                    l10n.transcriptNewNote,
                  ),
                if (_saved != null && widget.onDelete != null)
                  _menuItem(
                    'delete',
                    Icons.delete_outline,
                    l10n.transcriptDelete,
                  ),
              ],
            ),
        ],
      ),
      body: SafeArea(child: _body(context, hasText: hasText)),
      bottomNavigationBar: hasText && !_editing && !_busy
          ? _bottomBar(context)
          : null,
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon),
          title: Text(label),
        ),
      );

  Widget _body(BuildContext context, {required bool hasText}) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (_busy) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_workingLabel(), style: theme.textTheme.titleSmall),
              if (_kind != AttachmentKind.image) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.transcriptLongHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    if (!hasText && (_error != null || _empty)) {
      final isImage = _kind == AttachmentKind.image;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _error != null ? Icons.error_outline : Icons.subject,
                size: 40,
                color: _error != null ? scheme.error : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? l10n.transcriptEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (widget.source != null)
                    OutlinedButton.icon(
                      onPressed: _run,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  // Cihaz içi okuma yazı bulamadıysa (el yazısı, eğik
                  // fotoğraf) model çoğu zaman okur.
                  if (isImage && _onDevice)
                    FilledButton.icon(
                      onPressed: () => _run(preferAi: true),
                      icon: const AiIcon(),
                      label: Text(l10n.transcriptReadWithAi),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    if (_editing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          controller: _editController,
          autofocus: true,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      );
    }
    final words = RegExp(r'\S+').allMatches(_shown).length;
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    _sourceIcon(widget.source),
                    size: 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        l10n.transcriptWords(words),
                        if (_onDevice) l10n.transcriptOnDevice,
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ActionChip(
                    key: const ValueKey('transcript-ai-takeaways'),
                    avatar: Icon(
                      Icons.auto_awesome_outlined,
                      size: AppIconSize.xs,
                      color: scheme.primary,
                    ),
                    label: Text(l10n.transcriptTakeaways),
                    onPressed: _openTakeaways,
                  ),
                ],
              ),
            ),
            SelectableText(
              _shown,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
              onSelectionChanged: (selection, _) {
                final text = _shown;
                _selection.value =
                    selection.isValid &&
                        !selection.isCollapsed &&
                        selection.end <= text.length
                    ? selection.textInside(text)
                    : '';
              },
              contextMenuBuilder: (context, state) {
                final value = state.textEditingValue;
                final picked = value.selection.isValid
                    ? value.selection.textInside(value.text)
                    : '';
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: state.contextMenuAnchors,
                  buttonItems: [
                    if (widget.onInsert != null && picked.trim().isNotEmpty)
                      ContextMenuButtonItem(
                        label: l10n.transcriptInsertSelection,
                        onPressed: () {
                          state.hideToolbar();
                          _insert(picked);
                        },
                      ),
                    if (widget.onCreateNote != null && picked.trim().isNotEmpty)
                      ContextMenuButtonItem(
                        label: l10n.transcriptNewNote,
                        onPressed: () {
                          state.hideToolbar();
                          unawaited(_newNote(picked));
                        },
                      ),
                    ...state.contextMenuButtonItems,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// **KAYITTAN NOT** (PLAN §1.6 A2): döküm → özet + yapılacaklar +
  /// "hatırlatayım mı?" tek akış levhası.
  void _openTakeaways() {
    if (!ensureAiReady(context, ref)) return;
    final raw = Transcripts.stripTimestamps(_shown).trim();
    if (raw.isEmpty) return;
    unawaited(
      showAppSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        builder: (_) => _TranscriptTakeawaysSheet(
          transcript: raw,
          onInsert: widget.onInsert == null ? null : _insert,
          onCreateNote: widget.onCreateNote == null ? null : _newNote,
        ),
      ),
    );
  }

  static IconData _sourceIcon(Attachment? source) => switch (source?.kind) {
    AttachmentKind.audio => AppIcons.voiceRecord,
    AttachmentKind.video => Icons.videocam_outlined,
    AttachmentKind.image => Icons.image_outlined,
    _ => Icons.subject,
  };

  Widget _bottomBar(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ValueListenableBuilder<String>(
          valueListenable: _selection,
          builder: (context, picked, _) {
            final hasPick = picked.trim().isNotEmpty;
            return Row(
              children: [
                if (widget.onInsert != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _insert(hasPick ? picked : _shown),
                      icon: const Icon(Icons.playlist_add),
                      label: Text(
                        hasPick
                            ? l10n.transcriptInsertSelection
                            : l10n.transcriptInsertAll,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                if (widget.onInsert != null && widget.onCreateNote != null)
                  const SizedBox(width: 8),
                if (widget.onCreateNote != null)
                  OutlinedButton.icon(
                    onPressed: () => _newNote(hasPick ? picked : _shown),
                    icon: const Icon(Icons.note_add_outlined),
                    label: Text(l10n.transcriptNewNote),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TranscriptTakeawaysSheet extends ConsumerStatefulWidget {
  const _TranscriptTakeawaysSheet({
    required this.transcript,
    this.onInsert,
    this.onCreateNote,
  });

  final String transcript;
  final ValueChanged<String>? onInsert;
  final Future<void> Function(String text)? onCreateNote;

  @override
  ConsumerState<_TranscriptTakeawaysSheet> createState() =>
      _TranscriptTakeawaysSheetState();
}

class _TranscriptTakeawaysSheetState
    extends ConsumerState<_TranscriptTakeawaysSheet> {
  bool _loading = true;
  RecordingTakeaways? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(geminiServiceProvider)
          .summarizeTranscript(widget.transcript);
      if (!mounted) return;
      setState(() {
        _result = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = aiErrorText(context.l10n, e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final res = _result;
    final noteText = res == null
        ? ''
        : res.toNoteText(
            summaryHeading: l10n.transcriptTakeawaysSummary,
            actionsHeading: l10n.transcriptTakeawaysActions,
          );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpace.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(title: l10n.transcriptTakeaways),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xxl),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpace.m),
                      Text(l10n.aiThinking),
                    ],
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpace.xl),
                  child: Column(
                    children: [
                      Text(_error!, style: TextStyle(color: scheme.error)),
                      const SizedBox(height: AppSpace.m),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              else if (res != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (res.summary.isNotEmpty) ...[
                        Text(
                          l10n.transcriptTakeawaysSummary,
                          style: AppText.of(theme).meta.copyWith(
                            color: scheme.primary,
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Container(
                          padding: const EdgeInsets.all(AppSpace.m),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(AppRadius.m),
                          ),
                          child: SelectableText(
                            res.summary,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      if (res.actionItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.l),
                        Text(
                          l10n.transcriptTakeawaysActions,
                          style: AppText.of(theme).meta.copyWith(
                            color: scheme.primary,
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        for (final item in res.actionItems)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_box_outline_blank,
                                  size: AppIconSize.s,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: AppSpace.s),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      if (res.reminders.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.l),
                        Text(
                          l10n.transcriptTakeawaysRemind,
                          style: AppText.of(theme).meta.copyWith(
                            color: scheme.primary,
                            fontWeight: AppWeight.strong,
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        for (var i = 0; i < res.reminders.length; i++)
                          _ReminderSuggestionTile(
                            key: ValueKey('transcript-reminder-$i'),
                            hint: res.reminders[i],
                          ),
                      ],
                      AiResultNote(
                        content: noteText,
                        source: 'transcript_takeaways',
                      ),
                      const SizedBox(height: AppSpace.s),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: AppSpace.s,
                        runSpacing: AppSpace.s,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: noteText),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showMessage(l10n.copied);
                              }
                            },
                            icon: const Icon(
                              AppIcons.copy,
                              size: AppIconSize.xs,
                            ),
                            label: Text(l10n.copy),
                          ),
                          if (widget.onCreateNote != null &&
                              noteText.isNotEmpty)
                            FilledButton.tonalIcon(
                              onPressed: () {
                                Navigator.pop(context);
                                unawaited(widget.onCreateNote!(noteText));
                              },
                              icon: const Icon(
                                Icons.note_add_outlined,
                                size: AppIconSize.s,
                              ),
                              label: Text(l10n.transcriptNewNote),
                            ),
                          if (widget.onInsert != null && noteText.isNotEmpty)
                            FilledButton.icon(
                              key: const ValueKey('transcript-takeaways-insert'),
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onInsert!(noteText);
                              },
                              icon: const Icon(
                                Icons.playlist_add,
                                size: AppIconSize.s,
                              ),
                              label: Text(l10n.transcriptTakeawaysInsert),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderSuggestionTile extends StatelessWidget {
  const _ReminderSuggestionTile({super.key, required this.hint});

  final RecordingReminderHint hint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final parsedDue = hint.whenText.isEmpty
        ? null
        : parseSpokenDateTimeNow(hint.whenText);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.s),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.m,
        vertical: AppSpace.s,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.m),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: AppAlpha.soft),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            size: AppIconSize.s,
            color: scheme.primary,
          ),
          const SizedBox(width: AppSpace.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hint.title, style: AppText.of(theme).rowTitle),
                if (hint.whenText.isNotEmpty)
                  Text(
                    hint.whenText,
                    style: AppText.of(theme).meta.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => unawaited(
              showTaskEditor(
                context,
                initialTitle: hint.title,
                due: parsedDue,
              ),
            ),
            child: Text(l10n.transcriptTakeawaysAddTask),
          ),
        ],
      ),
    );
  }
}
