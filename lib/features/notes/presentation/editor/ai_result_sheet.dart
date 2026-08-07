import 'package:flutter/material.dart';

import '../../../../core/l10n_ext.dart';
import '../../domain/note_type.dart';

/// AI çıktısını NOTA YAZMADAN ÖNCE gösteren geniş inceleme/düzenleme sayfası.
///
/// Çıktı doğrudan nota eklendiğinde kullanıcı sonucu göremeden notu bozulmuş
/// oluyordu; burada metin tam ekrana yakın bir alanda düzenlenebilir, biçimi
/// (düz metin / madde listesi / sıralı liste) değiştirilebilir ve ancak sonra
/// nota eklenir ya da yeni not olarak açılır.
///
/// Biçim dönüşümü METİN üzerinde yapılır: satır başlarındaki işaretler
/// (`- `, `1. `) dışa aktarma ve liste editörüyle aynı dili konuşur.
Future<void> showAiResultSheet(
  BuildContext context, {
  required String title,
  required String text,
  required void Function(String text) onInsert,
  required void Function(String text, {NoteType? asType}) onCreateNote,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _AiResultSheet(
    title: title,
    text: text,
    onInsert: onInsert,
    onCreateNote: onCreateNote,
  ),
);

class _AiResultSheet extends StatefulWidget {
  const _AiResultSheet({
    required this.title,
    required this.text,
    required this.onInsert,
    required this.onCreateNote,
  });

  final String title;
  final String text;
  final void Function(String text) onInsert;
  final void Function(String text, {NoteType? asType}) onCreateNote;

  @override
  State<_AiResultSheet> createState() => _AiResultSheetState();
}

class _AiResultSheetState extends State<_AiResultSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  NoteType _format = NoteType.text;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Satır başlarındaki liste işaretlerini temizler — biçim değiştirirken
  /// eski işaretler üst üste binmesin.
  static String _bare(String line) => line
      .replaceFirst(RegExp(r'^\s*[-•*]\s+'), '')
      .replaceFirst(RegExp(r'^\s*\d+[.)]\s+'), '')
      .trim();

  void _applyFormat(NoteType type) {
    final lines = _controller.text
        .split('\n')
        .map(_bare)
        .where((l) => l.isNotEmpty)
        .toList();
    final formatted = switch (type) {
      NoteType.text => lines.join('\n'),
      NoteType.checklist => [for (final l in lines) '- $l'].join('\n'),
      NoteType.ordered => [
        for (var i = 0; i < lines.length; i++) '${i + 1}. ${lines[i]}',
      ].join('\n'),
      // PDF notu bu levhada bir BİÇİM seçeneği değil (aşağıdaki seçici yalnız
      // üç liste biçimini sunar); yine de switch tam olsun diye metin biçimine
      // eşitlenir — buraya düşülse bile satırlar olduğu gibi kalır.
      NoteType.pdf => lines.join('\n'),
    };
    setState(() {
      _format = type;
      _controller.text = formatted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Klavye açıkken alan daralmasın: sayfa görünür yüksekliğin %85'ine kadar.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SegmentedButton<NoteType>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: NoteType.text,
                      icon: const Icon(Icons.notes, size: 18),
                      label: Text(l10n.filterText),
                    ),
                    ButtonSegment(
                      value: NoteType.checklist,
                      icon: const Icon(Icons.check_box_outlined, size: 18),
                      label: Text(l10n.filterChecklist),
                    ),
                    ButtonSegment(
                      value: NoteType.ordered,
                      icon: const Icon(
                        Icons.format_list_numbered_rounded,
                        size: 18,
                      ),
                      label: Text(l10n.filterOrdered),
                    ),
                  ],
                  selected: {_format},
                  onSelectionChanged: (s) => _applyFormat(s.first),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: false,
                    keyboardType: TextInputType.multiline,
                    style: theme.textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                    const Spacer(),
                    // Önce sayfayı kapat, SONRA uygula: geri çağırma editörde
                    // setState yapıyor, istisna atarsa sayfa açık kalmasın.
                    TextButton.icon(
                      onPressed: () {
                        final text = _controller.text.trim();
                        final type = _format;
                        Navigator.pop(context);
                        if (text.isNotEmpty) {
                          widget.onCreateNote(text, asType: type);
                        }
                      },
                      icon: const Icon(Icons.note_add_outlined, size: 18),
                      label: Text(l10n.openAsNewNote),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: () {
                        final text = _controller.text.trim();
                        Navigator.pop(context);
                        if (text.isNotEmpty) widget.onInsert(text);
                      },
                      icon: const Icon(Icons.playlist_add, size: 18),
                      label: Text(l10n.addToNote),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
