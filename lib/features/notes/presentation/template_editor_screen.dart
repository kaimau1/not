import 'package:flutter/material.dart';

import '../../../core/l10n_ext.dart';
import '../data/user_templates.dart';
import '../domain/note_type.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/a11y/chip_roles.dart';
import 'template_preview_card.dart';

/// Canlı kart önizlemesinin göründüğü en dar genişlik ve kartın eni.
const double _wideEditor = 840;
const double _previewWidth = 200;

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
  /// Değişti mi — yalnız [PopScope] dinler (S47): ilk tuşta `setState`
  /// bütün düzenleyiciyi (20 maddede ~1600 widget) baştan kuruyordu.
  final _dirtyN = ValueNotifier(false);
  bool get _dirty => _dirtyN.value;
  set _dirty(bool v) => _dirtyN.value = v;

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
    _dirtyN.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _touch() {
    _dirty = true;
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
    final tokens = AppTokens.fromTheme(theme);
    final editor = ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.l,
        AppSpace.s,
        AppSpace.l,
        AppSpace.xxxl,
      ),
      children: [
        TextField(
          key: const ValueKey('tpl-editor-name'),
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _touch(),
          decoration: InputDecoration(
            labelText: l10n.templateNameTitle,
            hintText: l10n.templateNameHint,
            filled: true,
            fillColor: scheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.m),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.m),
        Wrap(
          spacing: AppSpace.s,
          runSpacing: AppSpace.xs,
          children: [
            for (final (type, icon, label) in [
              (NoteType.checklist, Icons.checklist, l10n.templateListChecks),
              (
                NoteType.ordered,
                Icons.format_list_numbered,
                l10n.templateListNumbers,
              ),
              (NoteType.text, Icons.notes, l10n.templateTypeText),
            ])
              radioChip(
                ChoiceChip(
                  avatar: Icon(icon, size: AppIconSize.s),
                  label: Text(label),
                  selected: _type == type,
                  showCheckmark: false,
                  onSelected: (_) => _setType(type),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.m),
        // KÂĞIT (önizlemeyle aynı): not başlığı + maddeler / yazı.
        Material(
          color: tokens.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.l),
            side: BorderSide(color: tokens.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.m,
              AppSpace.m,
              AppSpace.xs,
              AppSpace.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpace.xs,
                    right: AppSpace.m,
                  ),
                  child: TextField(
                    key: const ValueKey('tpl-editor-title'),
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _touch(),
                    style: theme.textTheme.titleLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      filled: false,
                      hintText: l10n.captureNoteTitle,
                      helperText: l10n.templateTitleHelp,
                    ),
                  ),
                ),
                if (_isList)
                  ..._listEditor(context)
                else
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpace.xs,
                      right: AppSpace.m,
                    ),
                    child: TextField(
                      key: const ValueKey('tpl-editor-body'),
                      controller: _body,
                      minLines: 8,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _touch(),
                      style: AppText.of(theme).body,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        hintText: l10n.templateBody,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_isList) ...[
          const SizedBox(height: AppSpace.s),
          Text(l10n.templateHeadingHelp, style: AppText.of(theme).meta),
        ],
      ],
    );
    return ValueListenableBuilder<bool>(
      valueListenable: _dirtyN,
      builder: (context, dirty, scaffold) => PopScope(
        canPop: !dirty,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final navigator = Navigator.of(context);
          if (await _confirmDiscard() && mounted) navigator.pop();
        },
        child: scaffold!,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? l10n.templateNew : l10n.templateEdit),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.s),
              child: FilledButton(
                key: const ValueKey('tpl-editor-save'),
                onPressed: _save,
                child: Text(l10n.templateSave),
              ),
            ),
          ],
        ),
        // Geniş ekranda (≥ 840) sağda galerideki kartın CANLI önizlemesi.
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _wideEditor) return editor;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: editor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpace.l,
                    AppSpace.xxl,
                    0,
                  ),
                  child: SizedBox(
                    width: _previewWidth,
                    child: ListenableBuilder(
                      listenable: Listenable.merge([_name, _body]),
                      builder: (context, _) => TemplatePreviewCard(
                        key: const ValueKey('tpl-editor-preview'),
                        lines: templatePreviewLines(
                          type: _type,
                          body: editableToTemplateBody(_body.text),
                          items: _currentItems(),
                        ),
                        accent: scheme.primary,
                        icon: switch (_type) {
                          NoteType.checklist => Icons.checklist,
                          NoteType.ordered => Icons.format_list_numbered,
                          _ => Icons.notes,
                        },
                        name: _name.text.trim().isEmpty
                            ? l10n.templateUntitled
                            : _name.text.trim(),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _listEditor(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return [
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
          return _FadeIn(
            key: row.key,
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: AppSpace.s,
                    ),
                    child: Icon(Icons.drag_indicator, color: scheme.outline),
                  ),
                ),
                SizedBox(
                  width: AppSpace.xxl,
                  child: _type == NoteType.ordered
                      ? Text(
                          '${i + 1}.',
                          style: AppText.of(theme).body
                              .copyWith(color: scheme.onSurfaceVariant),
                        )
                      : Icon(
                          Icons.check_box_outline_blank,
                          size: AppIconSize.m,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
                Expanded(
                  child: TextField(
                    controller: row.controller,
                    focusNode: row.focus,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => _touch(),
                    style: AppText.of(theme).body,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: AppIconSize.s),
                  onPressed: () => _removeRow(i),
                ),
              ],
            ),
          );
        },
      ),
      // Kâğıdın son satırı: "Madde ekle" (simge tutamaç sütununda).
      Row(
        children: [
          const SizedBox(width: AppSpace.s),
          Icon(Icons.add, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.xxl),
          Expanded(
            child: TextField(
              key: const ValueKey('tpl-editor-add'),
              controller: _add,
              focusNode: _addFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              style: AppText.of(theme).body,
              decoration: InputDecoration.collapsed(
                hintText: l10n.templateAddItem,
              ),
              onSubmitted: (_) => _addRow(),
            ),
          ),
          IconButton(
            tooltip: l10n.templateAddItem,
            icon: const Icon(Icons.keyboard_return),
            onPressed: _addRow,
          ),
        ],
      ),
    ];
  }
}

/// Yeni eklenen satır SOLARAK belirir (boy tek adımda, yalnız boyama;
/// ekranı açarken var olan satırlar da bir kez solar — kısa ve sessiz).
class _FadeIn extends StatefulWidget {
  const _FadeIn({super.key, required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: _shown ? 1 : 0,
    duration: AppMotion.of(context, AppMotion.quick),
    child: widget.child,
  );
}
