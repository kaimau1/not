import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../data/user_templates.dart';
import '../domain/note_type.dart';

/// **ŞABLON OLUŞTUR / DÜZENLE** (kullanıcı isteği 2026-10-02: "şablon
/// oluşturma ve düzenleme, şablonları geliştir").
///
/// Eskiden kendi şablonu edinmenin TEK yolu bir notu "Şablon olarak
/// kaydet"mekti; kaydedilen şablonun yalnız ADI değişebiliyordu — bir madde
/// eklemek için şablondan not açıp düzeltip yeniden kaydetmek, eskisini
/// silmek gerekiyordu. Bu ekran:
/// * sıfırdan şablon kurar (galerideki "Yeni şablon");
/// * var olan şablonun adını, türünü, not başlığını, maddelerini (sürükleyip
///   sıralama, metnini değiştirme, silme) ya da yazısını düzenler;
/// * hazır bir şablonun önizlemede biçilmiş hâlini "Şablonlarıma kaydet" ile
///   kişisel şablona çevirir ([initial] kimliksiz gelir).
///
/// Yazı şablonunda `# ` büyük başlık, `## ` alt başlık satırıdır (bkz.
/// [templateBodyToEditable]). Kaydedilince şablon döner, vazgeçilirse null.
Future<UserTemplate?> showTemplateEditor(
  BuildContext context, {
  UserTemplate? initial,
}) => Navigator.of(context).push<UserTemplate>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => TemplateEditorScreen(initial: initial),
  ),
);

class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({super.key, this.initial});

  /// Düzenlenecek şablon; null ya da kimliği boşsa YENİ şablon kurulur.
  final UserTemplate? initial;

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

/// Düzenlenen madde: denetleyicisi ve sürükleme anahtarı kendinde.
class _Row {
  _Row(String text) : controller = TextEditingController(text: text);

  static int _seq = 0;
  final key = ValueKey('tpl-row-${_seq++}');
  final TextEditingController controller;
  final focus = FocusNode();

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late final UserTemplate? _initial = widget.initial;
  late final _name = TextEditingController(text: _initial?.name ?? '');
  late final _title = TextEditingController(text: _initial?.title ?? '');
  late final String _initialEditable = templateBodyToEditable(
    _initial?.body ?? '',
  );
  late final _body = TextEditingController(text: _initialEditable);
  final _add = TextEditingController();
  final _addFocus = FocusNode();
  late NoteType _type = _normalize(_initial?.type ?? NoteType.checklist);
  late final List<_Row> _rows = [
    for (final i in _initial?.items ?? const <String>[]) _Row(i),
  ];
  bool _dirty = false;

  static NoteType _normalize(NoteType t) =>
      t == NoteType.ordered || t == NoteType.checklist ? t : NoteType.text;

  bool get _isList => _type != NoteType.text;

  bool get _isNew => (_initial?.id ?? '').isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _title.dispose();
    _body.dispose();
    _add.dispose();
    _addFocus.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// Liste ↔ yazı geçişinde içerik taşınır, kaybolmaz.
  void _setType(NoteType next) {
    if (next == _type) return;
    setState(() {
      final wasList = _isList;
      _type = next;
      _dirty = true;
      if (wasList && !_isList) {
        final text = itemsToEditableText(_currentItems());
        if (text.isNotEmpty) {
          _body.text = _body.text.trim().isEmpty
              ? text
              : '${_body.text}\n$text';
        }
        for (final r in _rows) {
          r.dispose();
        }
        _rows.clear();
      } else if (!wasList && _isList && _rows.isEmpty) {
        _rows.addAll([
          for (final i in editableTextToItems(_body.text)) _Row(i),
        ]);
        _body.clear();
      }
    });
  }

  List<String> _currentItems() => [
    for (final r in _rows)
      if (r.controller.text.trim().isNotEmpty) r.controller.text.trim(),
  ];

  void _addRow() {
    final text = _add.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _rows.add(_Row(text));
      _add.clear();
      _dirty = true;
    });
    _addFocus.requestFocus();
  }

  void _removeRow(int index) {
    setState(() {
      _rows.removeAt(index).dispose();
      _dirty = true;
    });
  }

  void _save() {
    if (_add.text.trim().isNotEmpty) _addRow();
    final l10n = context.l10n;
    final title = _title.text.trim();
    var name = _name.text.trim();
    if (name.isEmpty) name = title.isNotEmpty ? title : l10n.templateUntitled;
    // Yazı değişmediyse asıl (satır içi biçimli) gövde korunur.
    final body = _isList
        ? ''
        : _body.text == _initialEditable && _initial != null
        ? _initial.body
        : editableToTemplateBody(_body.text.trimRight());
    final template = UserTemplate(
      id: _isNew ? newUserTemplateId() : _initial!.id,
      name: name,
      type: _type,
      title: title,
      body: body,
      items: _isList ? _currentItems() : const [],
    );
    Navigator.pop(context, template);
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.templateDiscardTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.templateDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? l10n.templateNew : l10n.templateEdit),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                key: const ValueKey('tpl-editor-save'),
                onPressed: _save,
                child: Text(l10n.templateSave),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextField(
              key: const ValueKey('tpl-editor-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
              decoration: InputDecoration(
                labelText: l10n.templateNameTitle,
                hintText: l10n.templateNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<NoteType>(
              segments: [
                ButtonSegment(
                  value: NoteType.checklist,
                  icon: const Icon(Icons.checklist),
                  label: Text(l10n.templateListChecks),
                ),
                ButtonSegment(
                  value: NoteType.ordered,
                  icon: const Icon(Icons.format_list_numbered),
                  label: Text(l10n.templateListNumbers),
                ),
                ButtonSegment(
                  value: NoteType.text,
                  icon: const Icon(Icons.notes),
                  label: Text(l10n.templateTypeText),
                ),
              ],
              selected: {_type},
              showSelectedIcon: false,
              onSelectionChanged: (v) => _setType(v.first),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('tpl-editor-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _touch(),
              decoration: InputDecoration(
                labelText: l10n.captureNoteTitle,
                helperText: l10n.templateTitleHelp,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            if (_isList)
              ..._listEditor(context)
            else ...[
              TextField(
                key: const ValueKey('tpl-editor-body'),
                controller: _body,
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _touch(),
                decoration: InputDecoration(
                  labelText: l10n.templateBody,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.templateHeadingHelp,
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

  List<Widget> _listEditor(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
      Text(
        _rows.isEmpty
            ? l10n.templateItems
            : '${l10n.templateItems} · ${_rows.length}',
        style: theme.textTheme.labelLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _rows.length,
        onReorderItem: (from, to) => setState(() {
          _rows.insert(to, _rows.removeAt(from));
          _dirty = true;
        }),
        itemBuilder: (context, i) {
          final row = _rows[i];
          return Row(
            key: row.key,
            children: [
              ReorderableDragStartListener(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 10,
                  ),
                  child: Icon(Icons.drag_indicator, color: scheme.outline),
                ),
              ),
              SizedBox(
                width: 26,
                child: _type == NoteType.ordered
                    ? Text(
                        '${i + 1}.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.check_box_outline_blank,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
              ),
              Expanded(
                child: TextField(
                  controller: row.controller,
                  focusNode: row.focus,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _touch(),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeRow(i),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 6),
      TextField(
        key: const ValueKey('tpl-editor-add'),
        controller: _add,
        focusNode: _addFocus,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.add),
          hintText: l10n.templateAddItem,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: l10n.templateAddItem,
            icon: const Icon(Icons.keyboard_return),
            onPressed: _addRow,
          ),
        ),
        onSubmitted: (_) => _addRow(),
      ),
    ];
  }
}
