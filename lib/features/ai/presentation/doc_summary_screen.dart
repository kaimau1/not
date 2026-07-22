import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n_ext.dart';
import '../../../core/widgets/speak_button.dart';
import '../../notes/data/attachment_repository.dart';
import '../../notes/data/doc_text.dart';
import '../../notes/data/notes_repository.dart';
import '../../notes/domain/attachment.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/note_type.dart';
import '../data/ai_cache.dart';
import '../data/gemini_service.dart';

/// Bir PDF ya da slayt (.pptx) ekini özetleyip nota dönüştürme ekranı.
///
/// İki özet düzeyi sunar: KISA (ana fikir) ve DETAYLI (belgeyi okumaya gerek
/// bırakmayan kapsamlı özet). Sonuç hem okunabilir bir anlatı hem de madde
/// madde önemli noktalar içerir; "Nota dönüştür" ile bunlar tek bir nota —
/// gövdesi anlatı, maddeleri liste olan gerçek bir nota — çevrilir.
class DocSummaryScreen extends ConsumerStatefulWidget {
  const DocSummaryScreen({super.key, required this.attachment});

  final Attachment attachment;

  @override
  ConsumerState<DocSummaryScreen> createState() => _DocSummaryScreenState();
}

class _DocSummaryScreenState extends ConsumerState<DocSummaryScreen> {
  bool _detailed = false;
  bool _loading = false;
  DocSummary? _summary;
  String? _error;

  bool get _isPdf => widget.attachment.kind == AttachmentKind.pdf;

  @override
  void initState() {
    super.initState();
    _run();
  }

  String get _cacheKey => AiCache.keyFor(
    'doc_summary_${_detailed ? 'long' : 'short'}',
    widget.attachment.id,
  );

  Future<void> _run() async {
    // Tüm metinler await'lerden ÖNCE yakalanır: async sonrası context'e
    // dokunmadan hata mesajları kurulabilsin (use_build_context_synchronously).
    final l10n = context.l10n;
    setState(() {
      _loading = true;
      _summary = null;
      _error = null;
    });

    // Önbellek: aynı ek + aynı düzey ikinci kez model çağırmaz.
    final cached = await AiCache.read(_cacheKey);
    if (cached != null && cached.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map) {
          if (mounted) {
            setState(() {
              _summary = DocSummary.fromMap(Map<String, dynamic>.from(decoded));
              _loading = false;
            });
          }
          return;
        }
      } on FormatException {
        // Bozuk önbellek: yeniden üret.
      }
    }

    try {
      final repo = ref.read(attachmentRepositoryProvider);
      final bytes = repo == null
          ? null
          : await repo.readBytes(widget.attachment);
      if (bytes == null) throw GeminiException(l10n.attachmentNotSynced);

      final service = ref.read(geminiServiceProvider);
      final DocSummary summary;
      if (_isPdf) {
        summary = await service.summarizeDocument(
          pdfBytes: bytes,
          fileName: widget.attachment.fileName,
          detailed: _detailed,
        );
      } else {
        // Slayt: Gemini pptx baytlarını okuyamaz; metni cihazda çıkarıp veririz.
        final text = await DocText.extractBytes('pptx', bytes);
        if (text.trim().isEmpty) {
          throw GeminiException(l10n.summaryNoText);
        }
        summary = await service.summarizeDocument(
          sourceText: text,
          fileName: widget.attachment.fileName,
          detailed: _detailed,
        );
      }
      await AiCache.write(_cacheKey, jsonEncode(summary.toMap()));
      if (mounted) setState(() => _summary = summary);
    } on GeminiException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.isAuthError
              ? l10n.aiNoApiKey
              : l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = l10n.aiError('$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Özeti "hem metin hem liste" bir nota çevirir: gövde = anlatı, maddeler =
  /// önemli noktalar (işaretsiz). Yeni not açılır.
  Future<void> _convertToNote() async {
    final summary = _summary;
    if (summary == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;

    const uuid = Uuid();
    final id = await repo.createNote(NoteType.text);
    final title = summary.title.trim().isEmpty
        ? widget.attachment.fileName
        : summary.title.trim();
    repo.updateFields(id, {
      'title': title,
      'body': summary.overview,
      'items': [
        for (final point in summary.points)
          NoteItem(id: uuid.v4(), text: point).toMap(),
      ],
      'tags': [_isPdf ? 'pdf' : 'slayt', 'ozet'],
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.summaryNoteCreated)));
    if (mounted) context.push('/note/$id');
  }

  Future<void> _copy() async {
    final summary = _summary;
    if (summary == null) return;
    final text = [
      summary.overview,
      for (final p in summary.points) '• $p',
    ].where((s) => s.trim().isNotEmpty).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attachment.fileName,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(l10n.summaryShort),
                  icon: const Icon(Icons.short_text, size: 18),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(l10n.summaryDetailed),
                  icon: const Icon(Icons.notes, size: 18),
                ),
              ],
              selected: {_detailed},
              onSelectionChanged: _loading
                  ? null
                  : (set) {
                      setState(() => _detailed = set.first);
                      _run();
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _detailed ? l10n.summaryDetailedInfo : l10n.summaryShortInfo,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l10n.aiThinking),
                      ],
                    ),
                  )
                : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _run,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : _summary == null
                ? const SizedBox.shrink()
                : _SummaryView(summary: _summary!),
          ),
          if (_summary != null && !_loading)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    SpeakButton(
                      text: [
                        _summary!.overview,
                        ..._summary!.points,
                      ].join('. '),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(l10n.copy),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _convertToNote,
                      icon: const Icon(Icons.note_add_outlined, size: 18),
                      label: Text(l10n.convertToNote),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.summary});

  final DocSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        if (summary.overview.trim().isNotEmpty)
          SelectableText(
            summary.overview,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (summary.points.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            l10n.summaryKeyPoints,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          for (final point in summary.points)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 10),
                    child: Icon(Icons.circle, size: 6, color: scheme.primary),
                  ),
                  Expanded(
                    child: SelectableText(
                      point,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
