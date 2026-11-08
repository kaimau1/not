part of 'note_editor_screen.dart';

/// NOT PAKETİ işleri (kullanıcı isteği 2026-11-08; bkz. note_package.dart).
extension _EditorPackage on _NoteEditorScreenState {
  /// Hızlı satırdaki "Pakete al": liste notunda seçili/odaktaki maddeler;
  /// metinde seçim, seçim yoksa imlecin bulunduğu uzun paragraf.
  void _packageFromQuickRow(Note note) {
    if (note.type != NoteType.text) {
      if (_itemsEditorKey.currentState?.togglePackage() ?? false) return;
      _packageHelp();
      return;
    }
    final c = _bodyController;
    final logical = c.logicalText;
    final sel = c.selection;
    if (!sel.isValid) return _packageHelp();
    var start = wrapToLogicalOffset(c.text, sel.start).clamp(0, logical.length);
    var end = wrapToLogicalOffset(c.text, sel.end).clamp(start, logical.length);
    if (start == end) {
      // Seçim yok: imlecin paragrafı (boş satırlarla ayrılan), uzunsa.
      final before = logical.lastIndexOf('\n\n', start);
      final after = logical.indexOf('\n\n', start);
      start = before < 0 ? 0 : before + 2;
      end = after < 0 ? logical.length : after;
      if (!suggestsPackage(logical.substring(start, end))) {
        return _packageHelp();
      }
    }
    final range = trimmedRange(logical, start, end);
    if (range == null) return _packageHelp();
    final text = logical.substring(range.start, range.end);
    final pkg = newNotePackage(text, {
      for (final a in note.attachments) a.fileName,
    });
    final tag = attachmentTagFor(pkg.fileName);
    final body = logical.replaceRange(range.start, range.end, tag);
    c.setLogical(body, range.start + tag.length);
    _mutate(
      (n) => n.copyWith(body: body, attachments: [...n.attachments, pkg]),
      immediate: true,
    );
    // Yazıdan açılıyor: ek şeridinde ikinci kez görünmesin.
    unawaited(
      _setAttachmentView(pkg, AttachmentView.attached, announce: false),
    );
  }

  void _packageHelp() => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showMessage(context.l10n.notePackageSelectFirst);

  /// Gövdedeki paket etiketine dokunuldu.
  void _openPackage(Attachment pkg) {
    final readOnly = _readOnly;
    _dismissKeyboard();
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => NotePackageScreen(
            package: pkg,
            onSave: readOnly
                ? null
                : (updated) {
                    if (mounted) _updateAttachment(updated);
                  },
            onUnpack: readOnly ? null : _unpack,
          ),
        ),
      ),
    );
  }

  /// Paketi çöz: etiketin yerine içeriği yazılır, ek kalkar.
  void _unpack(Attachment pkg) {
    if (!mounted) return;
    final tag = attachmentTagFor(pkg.fileName);
    final logical = _bodyController.logicalText;
    final at = logical.indexOf(tag);
    final body = at < 0
        ? '$logical\n\n${pkg.text}'
        : logical.replaceRange(at, at + tag.length, pkg.text);
    _bodyController.setLogical(body, (at < 0 ? body.length : at) + 0);
    _mutate(
      (n) => n.copyWith(
        body: body,
        attachments: [
          for (final a in n.attachments)
            if (a.id != pkg.id) a,
        ],
      ),
      immediate: true,
    );
  }
}
