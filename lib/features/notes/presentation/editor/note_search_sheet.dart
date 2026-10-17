import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n_ext.dart';
import '../../../../core/utils/local_file.dart';
import '../../../../core/utils/rich_text.dart';
import '../../../ai/data/gemini_service.dart';
import '../../data/attachment_repository.dart';
import '../../data/pdf_text.dart';
import '../../data/scan/scan_ocr.dart';
import '../../domain/attachment.dart';
import '../../domain/note.dart';
import '../../domain/page_notes.dart';
import '../viewers/text_recognize_screen.dart';
import '../../../../core/widgets/app_sheet.dart';

/// **Not içinde arama** — gövde, maddeler, sayfa notları VE eklerin içi.
///
/// Kullanıcı isteği 2026-08-16: "not içi arama ai ile görsel ve PDF ekler
/// içinde de arama". Uygulamanın araması ana ekranda, NOTLAR ARASINDA
/// çalışıyordu; tek bir uzun notun (ya da 200 sayfalık bir PDF ekinin)
/// içinde bir kelime aramanın yolu yoktu.
///
/// Üç katman, ucuzdan pahalıya:
///  1. **Metin** (anında, yerel): başlık, gövde, maddeler, sayfa notları.
///  2. **Ekler** (yerel, kotasız): PDF'in metin katmanı ([PdfText]) ve
///     görsellerin cihaz-içi OCR'ı ([ScanOcr]). Bu adım saniyeler sürebildiği
///     için AYRI ve kullanıcı isteğiyle başlar; sonuçlar geldikçe eklenir.
///  3. **AI** (isteğe bağlı, kota harcar): kelimesi kelimesine eşleşme
///     bulunamadığında "ne demek istediğini" sorar — eş anlamlı, yanlış
///     yazılmış ya da başka dilde yazılmış bir şeyi bulmanın tek yolu.
///
/// Ek metinleri OTURUM BOYUNCA önbelleklenir: aynı notta ikinci arama
/// PDF'i yeniden çözümlemez.
///
/// 2026-09-26: not içi aramanın ASIL yolu artık sayfadaki canlı arama
/// çubuğu (bkz. `NoteFindBar`); bu levha oradan "eklerde ve yapay zekâ ile
/// ara" ile, çubukta yazılı sorguyla ([initialQuery]) açılır.
Future<void> showNoteSearchSheet(
  BuildContext context,
  WidgetRef ref,
  Note note, {
  String initialQuery = '',
}) => showAppSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _NoteSearchSheet(note: note, initialQuery: initialQuery),
);

/// Tek bir bulgu: nerede geçtiği + çevresinden bir parça.
class _Hit {
  const _Hit({required this.where, required this.snippet, this.icon});

  final String where;
  final String snippet;
  final IconData? icon;
}

class _NoteSearchSheet extends ConsumerStatefulWidget {
  const _NoteSearchSheet({required this.note, this.initialQuery = ''});

  final Note note;
  final String initialQuery;

  @override
  ConsumerState<_NoteSearchSheet> createState() => _NoteSearchSheetState();
}

class _NoteSearchSheetState extends ConsumerState<_NoteSearchSheet> {
  late final _controller = TextEditingController(text: widget.initialQuery);

  /// Ek kimliği → o ekten çıkarılan düz metin. Bir kez çıkarılır.
  /// Transkriptler (metin ekleri) baştan dolu: içerikleri kayıtta, çıkarmak
  /// bedava — ek taraması beklemeden aranırlar.
  late final Map<String, String> _attachmentText = {
    for (final a in widget.note.attachments)
      if (a.kind == AttachmentKind.text) a.id: a.text,
  };

  bool _scanning = false;
  bool _scanned = false;
  bool _asking = false;
  String? _aiAnswer;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  /// Notun kendi metninde (başlık, gövde, madde, sayfa notu) arar.
  ///
  /// Biçim işaretleri SÖKÜLEREK aranır: "**süt**" yazan bir maddede "süt"
  /// aranınca bulunamaması kullanıcı için anlaşılmaz olurdu.
  List<_Hit> _textHits(String query) {
    final l10n = context.l10n;
    final note = widget.note;
    final hits = <_Hit>[];
    void probe(String where, String raw, IconData icon) {
      final text = stripRichMarkers(raw);
      final index = text.toLowerCase().indexOf(query.toLowerCase());
      if (index < 0) return;
      hits.add(_Hit(where: where, snippet: _snippet(text, index), icon: icon));
    }

    probe(l10n.noteTitleLabel, note.title, Icons.title);
    probe(l10n.noteBodyLabel, note.body, Icons.notes_outlined);
    for (var i = 0; i < note.items.length; i++) {
      probe('${l10n.itemLabel} ${i + 1}', note.items[i].text, Icons.check_box_outlined);
    }
    for (final attachment in note.attachments) {
      for (final entry in orderedPageNotes(
        attachment: attachment,
        pageNotes: note.pageNotes,
      )) {
        probe(
          l10n.pageLabel(entry.page),
          entry.text,
          Icons.sticky_note_2_outlined,
        );
      }
    }
    return hits;
  }

  /// Eklerin İÇİNDE arar (önce metinleri çıkarılmışsa).
  List<_Hit> _attachmentHits(String query) {
    final hits = <_Hit>[];
    for (final attachment in widget.note.attachments) {
      final text = _attachmentText[attachment.id];
      if (text == null || text.isEmpty) continue;
      final index = text.toLowerCase().indexOf(query.toLowerCase());
      if (index < 0) continue;
      hits.add(
        _Hit(
          where: attachment.fileName,
          snippet: _snippet(text, index),
          icon: switch (attachment.kind) {
            AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
            AttachmentKind.text => Icons.subject,
            _ => Icons.image_outlined,
          },
        ),
      );
    }
    return hits;
  }

  /// Eşleşmenin çevresinden okunabilir bir parça (tek satıra indirilmiş).
  static String _snippet(String text, int index) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ');
    // Düzleştirme konumu kaydırabilir; parçayı yeniden hizalamak yerine
    // yaklaşık pencere yeterli — amaç bağlam göstermek, imleç koymak değil.
    final start = (index - 40).clamp(0, flat.length);
    final end = (index + 90).clamp(start, flat.length);
    final piece = flat.substring(start, end).trim();
    return '${start > 0 ? '…' : ''}$piece${end < flat.length ? '…' : ''}';
  }

  /// PDF ve görsel eklerin metnini çıkarır (yerel, kotasız).
  ///
  /// PDF'te önce METİN KATMANI denenir; taranmış (katmansız) PDF'te
  /// sayfaları OCR'lamak dakikalar sürebileceği için ATLANIR — o belgenin
  /// aranabilir hâli zaten tarama akışında üretiliyor.
  Future<void> _scanAttachments() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final repo = ref.read(attachmentRepositoryProvider);
    for (final attachment in widget.note.attachments) {
      if (_attachmentText.containsKey(attachment.id)) continue;
      try {
        if (attachment.kind == AttachmentKind.pdf) {
          final path = attachment.localPath;
          if (path.isEmpty || !localFileExists(path)) continue;
          _attachmentText[attachment.id] = await PdfText.extract(path);
        } else if (attachment.kind == AttachmentKind.image &&
            ScanOcr.supported) {
          final path = await recognizableImagePath(attachment, repo);
          if (path == null) continue;
          final lines = await ScanOcr.recognizeImageLines(path);
          _attachmentText[attachment.id] = [
            for (final line in lines) line.text,
          ].join('\n');
        }
      } catch (_) {
        // Bozuk/okunamayan ek aramayı düşürmesin; o ek atlanır.
      }
      if (!mounted) return;
      setState(() {});
    }
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _scanned = true;
    });
  }

  /// Aranan şeyi NOTUN KENDİSİNE sorar (kota harcar).
  Future<void> _askAi() async {
    final query = _query;
    if (query.isEmpty || _asking) return;
    setState(() {
      _asking = true;
      _aiAnswer = null;
    });
    try {
      final answer = await ref
          .read(geminiServiceProvider)
          .askAboutNoteText(widget.note, query, extras: _attachmentText.values);
      if (!mounted) return;
      setState(() {
        _aiAnswer = answer;
        _asking = false;
      });
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _aiAnswer = e.message;
        _asking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiAnswer = context.l10n.aiError('$e');
        _asking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final query = _query;
    final hits = query.isEmpty
        ? const <_Hit>[]
        : [..._textHits(query), ..._attachmentHits(query)];
    final searchableAttachments = widget.note.attachments
        .where(
          (a) =>
              a.kind == AttachmentKind.pdf ||
              (a.kind == AttachmentKind.image && ScanOcr.supported),
        )
        .length;

    return Padding(
      // Klavye levhayı örtmesin.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() => _aiAnswer = null),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.noteSearchHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_controller.clear),
                        ),
                ),
              ),
            ),
            if (searchableAttachments > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _scanned
                            ? l10n.noteSearchAttachmentsReady(
                                _attachmentText.length,
                              )
                            : l10n.noteSearchAttachmentsInfo(
                                searchableAttachments,
                              ),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_scanning)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!_scanned)
                      TextButton(
                        onPressed: _scanAttachments,
                        child: Text(l10n.noteSearchScanAttachments),
                      ),
                  ],
                ),
              ),
            const Divider(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (query.isEmpty)
                    Text(
                      l10n.noteSearchEmptyHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else if (hits.isEmpty)
                    Text(
                      l10n.noteSearchNoHit,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  for (final hit in hits)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(hit.icon ?? Icons.search, size: 20),
                      title: Text(
                        hit.where,
                        style: theme.textTheme.labelMedium,
                      ),
                      subtitle: Text(hit.snippet),
                    ),
                  if (query.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    // AI YOLU: kelime eşleşmesi bulunmadığında asıl işe
                    // yarayan yol; bulunduğunda da "özetle" için duruyor.
                    // Düğme — otomatik DEĞİL: her tuş vuruşunda model
                    // çağırmak kotayı yakardı.
                    OutlinedButton.icon(
                      onPressed: _asking ? null : _askAi,
                      icon: _asking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(l10n.noteSearchAskAi),
                    ),
                    if (_aiAnswer != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SelectableText(_aiAnswer!),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
