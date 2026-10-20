part of 'dashboard_screen.dart';

/// Ana ekranın seçim kipi toplu işlemleri ve kart çekişleri (C1, 2026-10-20: dashboard konu dosyalarına bölündü).
extension _DashSelection on _DashboardScreenState {
  /// Seçilen notları çöp kutusuna taşır; tek dokunuşla geri alınabilir.
  Future<void> _deleteSelected(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    // Kilitli not toplu yoldan da doğrulamasız silinmesin (tekli eylem
    // levhasıyla aynı kural).
    if (_selectedNotes(ids).any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    if (!mounted) return;
    ref.read(selectedNoteIdsProvider.notifier).clear();
    // Seçili kartlar birlikte küçülüp solar, sonra silinir (bkz.
    // leavingNotesProvider).
    await ref.read(leavingNotesProvider.notifier).leave(ids, () {
      repo.softDeleteAll(ids);
    });
    if (!mounted) return;
    showUndoSnackBar(
      context,
      message: l10n.notesDeletedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.restoreAll(ids),
    );
  }

  /// Seçilen notları TEK levhada bir klasöre taşır.
  ///
  /// NEDEN: klasöre taşıma yalnız TEKLİ eylem levhasındaydı. Yirmi notu
  /// düzenlemek isteyen kullanıcı yirmi kez basılı tutup yirmi kez levha
  /// açmak zorundaydı — oysa toplu seçim çubuğunda arşivleme, silme,
  /// renklendirme zaten vardı.
  Future<void> _moveSelectedToFolder(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    // Eski klasörler geri alma için önce not edilir.
    final previous = {for (final n in _selectedNotes(ids)) n.id: n.folderId};
    final picked = await showFolderPickSheet(context, ref);
    if (picked == null || !mounted) return;
    unawaited(
      repo.batchUpdate(ids, {'folderId': picked.isEmpty ? null : picked}),
    );
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesMovedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.batchUpdateEach({
        for (final entry in previous.entries)
          entry.key: {'folderId': entry.value},
      }),
    );
  }

  /// Seçilen notların kopyalarını oluşturur (bkz.
  /// [NotesRepository.duplicateNote] — ekler kopyalanmaz).
  Future<void> _duplicateSelected(Set<String> ids) async {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    final notes = _selectedNotes(ids);
    if (notes.any((n) => n.locked) &&
        !await authenticateForNote(l10n.unlockAuthReason)) {
      return;
    }
    final created = <String>[];
    for (final note in notes) {
      created.add(await repo.duplicateNote(note));
    }
    if (!mounted) return;
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      // Ekli notlarda ekler kopyaya taşınmaz (bkz. note_actions_sheet).
      message: notes.any((n) => n.attachments.isNotEmpty)
          ? l10n.noteDuplicatedNoAttachments
          : l10n.notesDuplicatedCount(created.length),
      undoLabel: l10n.undo,
      // Kopyalar henüz hiç düzenlenmedi: geri alma onları kalıcı siler,
      // çöpe düşürüp kullanıcıya ikinci bir temizlik işi bırakmaz.
      onUndo: () {
        for (final id in created) {
          repo.hardDelete(id);
        }
      },
    );
  }

  List<Note> _selectedNotes(Set<String> ids) {
    final all = ref.read(notesStreamProvider).value ?? const <Note>[];
    return [
      for (final n in all)
        if (ids.contains(n.id)) n,
    ];
  }

  void _archiveSelected(Set<String> ids) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null || ids.isEmpty) return;
    final l10n = context.l10n;
    repo.setArchivedAll(ids, true);
    ref.read(selectedNoteIdsProvider.notifier).clear();
    showUndoSnackBar(
      context,
      message: l10n.notesArchivedCount(ids.length),
      undoLabel: l10n.undo,
      onUndo: () => repo.setArchivedAll(ids, false),
    );
  }

  /// Liste satırını SAĞA çekmek: sabitle / sabitlemeyi kaldır.
  void _swipePin(Note note) {
    ref.read(notesRepositoryProvider)?.setPinned(note.id, !note.pinned);
    HapticFeedback.selectionClick();
  }

  /// Liste satırını SOLA çekmek: arşivle (geri alınabilir).
  void _swipeArchive(Note note) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.setArchived(note.id, true);
    HapticFeedback.mediumImpact();
    showUndoSnackBar(
      context,
      message: context.l10n.noteArchived,
      undoLabel: context.l10n.undo,
      onUndo: () => repo.setArchived(note.id, false),
    );
  }

  void _setPinnedSelected(Set<String> ids, bool pinned) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.batchUpdate(ids, {'pinned': pinned});
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  void _setStarredSelected(Set<String> ids, bool starred) {
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    repo.batchUpdate(ids, {'starred': starred});
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }

  /// Seçili notların metnini birleştirir. Kilitli notlardan yalnız başlık
  /// alınır (içerik kimlik doğrulaması olmadan sızmasın).
  String _joinSelected(Set<String> ids) {
    final l10n = context.l10n;
    // Paylaş levhasıyla AYNI biçim (bkz. noteShareText): `- [ ]` yerine
    // ☐/☑, sayfa notlarında "Sayfa 3". Kilitli notun yalnız başlığı gider.
    return joinShareTexts([
      for (final n in _selectedNotes(ids))
        // displayTitle: başlık biçimlendirilebiliyor, işaretler panoya sızmasın.
        if (n.locked)
          n.displayTitle.trim()
        else
          noteShareText(n, pageLabel: l10n.pageLabel),
    ]);
  }

  Future<void> _copySelected(Set<String> ids) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: _joinSelected(ids)));
    ref.read(selectedNoteIdsProvider.notifier).clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showMessage(l10n.copied);
  }

  Future<void> _shareSelected(Set<String> ids) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final text = _joinSelected(ids);
    ref.read(selectedNoteIdsProvider.notifier).clear();
    // Sessiz kapanmak YOK: yalnız belge notu seçildiyse (düz metni boştur)
    // düğmenin neden bir şey yapmadığı söylenir.
    if (text.trim().isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showMessage(l10n.shareAsTextEmpty);
      return;
    }
    await SharePlus.instance.share(ShareParams(text: text));
  }

  Future<void> _colorSelected(Set<String> ids, {required bool frame}) async {
    final picked = await showNoteColorPicker(context, frame: frame);
    if (picked == null) return;
    final repo = ref.read(notesRepositoryProvider);
    if (repo == null) return;
    unawaited(
      repo.batchUpdate(ids, {
        frame ? 'frameColor' : 'color': picked.color.id,
        frame ? 'customFrameColor' : 'customColor': picked.custom,
      }),
    );
    ref.read(selectedNoteIdsProvider.notifier).clear();
  }
}
