import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/app_icons.dart';
import '../../../../core/l10n_ext.dart';
import '../../domain/attachment.dart';
import '../viewers/ink_layer.dart';
import 'page_ink_layer.dart';

/// **NOT PAKETİ** (kullanıcı isteği 2026-11-08): uzun yazı nota açık hâlde
/// yer kaplamasın — pakete alınır, satırda çerçeveli küçük bir etiket olarak
/// durur, dokununca önizlemede açılır; orada okunur, yazılır, kalemle
/// üstüne çizilir.
///
/// * METİN modu: paket bir METİN EKİ ([AttachmentKind.text], `extras.package`)
///   — gövdede ek etiketi ("📎 ad") olarak durur; içeriği ve çizimi ekte.
/// * LİSTE modu: maddeler [NoteItem.package] ile gruplanır (bkz.
///   `ItemsEditorState.togglePackage`), [NotePackagePill] özetini çizer.

const kPackageExtra = 'package';

bool isNotePackage(Attachment a) =>
    a.kind == AttachmentKind.text && a.extras[kPackageExtra] == true;

/// Uzun yazı ipucu eşiği: bu kadar satır ya da karakter.
const kPackageHintLines = 14;
const kPackageHintChars = 900;

/// Metin pakete önerilecek kadar uzun mu (en uzun paragrafa bakılır).
bool suggestsPackage(String text) {
  for (final p in text.split(RegExp(r'\n\s*\n'))) {
    if (p.length >= kPackageHintChars ||
        '\n'.allMatches(p).length + 1 >= kPackageHintLines) {
      return true;
    }
  }
  return false;
}

/// Paketin etiket adı: ilk satırın başı (en çok 40 karakter); [taken]
/// adlarla çakışırsa sonuna sayı eklenir (etiket ADLA eşleşir).
String packageName(String text, Set<String> taken) {
  final first = text.trim().split('\n').first.trim();
  var base = first.length > 40 ? '${first.substring(0, 40).trimRight()}…' : first;
  if (base.isEmpty) base = '…';
  var name = base;
  for (var n = 2; taken.contains(name); n++) {
    name = '$base ($n)';
  }
  return name;
}

Attachment newNotePackage(String text, Set<String> takenNames) {
  final body = text.length > Attachment.maxTextChars
      ? text.substring(0, Attachment.maxTextChars)
      : text;
  return Attachment(
    id: const Uuid().v4(),
    kind: AttachmentKind.text,
    fileName: packageName(body, takenNames),
    mimeType: 'text/plain',
    text: body,
    sizeBytes: body.length,
    createdAt: DateTime.now(),
    extras: const {kPackageExtra: true},
  );
}

/// Liste modunda kapalı paket: hafif çerçeveli, en çok iki satırlık özet.
class NotePackagePill extends StatelessWidget {
  const NotePackagePill({
    super.key,
    required this.text,
    required this.count,
    required this.onTap,
  });

  final String text;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          key: const ValueKey('note-package-pill'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Icon(Icons.view_agenda_outlined, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    l10n.notePackageCount(count),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paketin önizlemesi: okunur, yazılır, kalemle üstüne çizilir. Kapanınca
/// [onSave] güncel eki alır (değişmediyse çağrılmaz). [onUnpack]: içeriği
/// nota geri koy (paketi çöz).
class NotePackageScreen extends StatefulWidget {
  const NotePackageScreen({
    super.key,
    required this.package,
    this.onSave,
    this.onUnpack,
  });

  final Attachment package;
  final ValueChanged<Attachment>? onSave;
  final ValueChanged<Attachment>? onUnpack;

  @override
  State<NotePackageScreen> createState() => _NotePackageScreenState();
}

class _NotePackageScreenState extends State<NotePackageScreen> {
  late final _text = TextEditingController(text: widget.package.text);
  final _scroll = ScrollController();
  late List<InkStroke> _strokes = widget.package.ink;
  late final _ink = InkController(
    initial: widget.package.ink,
    onChanged: (s) => _strokes = s,
  );
  bool _pen = false;

  bool get _readOnly => widget.onSave == null;

  Attachment get _current => widget.package.copyWith(
    text: _text.text,
    sizeBytes: _text.text.length,
    ink: _strokes,
  );

  void _save() {
    if (_readOnly) return;
    final p = widget.package;
    if (_text.text == p.text && identical(_strokes, p.ink)) return;
    widget.onSave!(_current);
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    _ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _save();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.package.fileName, overflow: TextOverflow.ellipsis),
          actions: [
            if (!_readOnly) ...[
              IconButton(
                key: const ValueKey('package-pen'),
                tooltip: l10n.quickRowPen,
                isSelected: _pen,
                icon: const Icon(Icons.draw_outlined),
                selectedIcon: const Icon(Icons.draw),
                onPressed: () => setState(() => _pen = !_pen),
              ),
              if (_pen)
                ListenableBuilder(
                  listenable: _ink,
                  builder: (_, _) => IconButton(
                    tooltip: l10n.eraser,
                    isSelected: _ink.eraser,
                    icon: const Icon(Icons.auto_fix_normal_outlined),
                    onPressed: () => _ink.eraser
                        ? _ink.setPen(_ink.pen)
                        : _ink.setEraser(true),
                  ),
                ),
              if (widget.onUnpack != null)
                IconButton(
                  key: const ValueKey('package-unpack'),
                  tooltip: l10n.notePackageUnpack,
                  icon: const Icon(AppIcons.unarchive),
                  onPressed: () {
                    final unpack = widget.onUnpack!;
                    final current = _current;
                    Navigator.of(context).pop();
                    unpack(current);
                  },
                ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          controller: _scroll,
          physics: _pen ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: PageInkStack(
            ink: _ink,
            page: 1,
            penActive: _pen,
            scroll: _scroll,
            child: TextField(
              key: const ValueKey('package-text'),
              controller: _text,
              readOnly: _readOnly || _pen,
              maxLines: null,
              decoration: const InputDecoration.collapsed(hintText: ''),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
