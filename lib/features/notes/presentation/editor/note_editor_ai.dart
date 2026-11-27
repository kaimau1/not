part of 'note_editor_screen.dart';

/// Editör akıllı işleri: meşgul göstergesi, Decisions D4 + yerel etiket önerisi.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorAi on _NoteEditorScreenState {
  /// Uzun süren DOSYA işlerinin ortak sarmalayıcısı: şeritteki göstergeyi
  /// açar/kapatır; hata yönetimi çağırana bırakılır.
  Future<T> _runBusy<T>(String label, Future<T> Function() body) async {
    _busyTaskN.value = label;
    try {
      return await body();
    } finally {
      if (mounted) _busyTaskN.value = null;
    }
  }

  /// DA-2 için klasör seçenekleri: ORTAK ve gizli klasör adı dışarı gitmez.
  Map<String, String> _triageFolders(Note note) {
    final hidden = ref.read(hiddenFolderIdsProvider);
    return {
      for (final f in ref.read(foldersStreamProvider).value ?? const [])
        if (!f.isShared && !hidden.contains(f.id) && f.id != note.folderId)
          f.id: f.name,
    };
  }

  /// Etiket / klasör / hatırlatıcı önerisi al ve seçtir.
  ///
  /// DA-2 (bayrak `noteTriage`): tek Decisions çağrısında kullanıcının KENDİ
  /// etiketleri + klasör + "hatırlatıcı gerekli mi". Decisions kapalı veya
  /// sonuçsuzsa cihaz-içi [SmartNoteCategorizer] (0 kredi) devreye girer.
  Future<void> _suggestTags() async {
    final note = _note;
    if (note == null || note.isEmpty) return;
    final l10n = context.l10n;
    final decisions = ref.read(decisionServiceProvider);
    // Kilitli not hiçbir karar girdisine girmez (K7).
    var mode = note.locked
        ? DecisionMode.off
        : decisions.modeOf(DecisionFeature.noteTriage);
    if (mode == DecisionMode.live &&
        !ref.read(aiTurnedOffProvider) &&
        ref.read(proFeatureProvider(ProFeature.smartDecisions)) &&
        !ref.read(aiConsentProvider)) {
      final consented = await ensureAiConsent(context, ref);
      if (!mounted) return;
      if (!consented) mode = DecisionMode.off;
    }
    final folders = mode == DecisionMode.off
        ? const <String, String>{}
        : _triageFolders(note);
    final ownTags = [
      for (final t in ref.read(allTagsProvider))
        if (!note.tags.contains(t)) t,
    ];
    List<String> suggestions = const [];
    TriageSuggestion? triage;
    await _runBusy(l10n.aiThinking, () async {
      if (mode == DecisionMode.live) {
        triage = await decideNoteTriage(
          decisions,
          title: note.title,
          text: note.toPlainText(),
          tags: ownTags,
          folders: folders,
        );
      }
      if (triage?.tags.isNotEmpty ?? false) {
        suggestions = triage!.tags;
        return;
      }
      // Cihaz-içi kural tabanlı etiket önerisi (0 kredi).
      final local = SmartNoteCategorizer.classify(
        note.copyWith(tags: const []),
      );
      if (local.tags.isNotEmpty) {
        suggestions = local.tags;
      }
    });
    if (!mounted) return;
    suggestions = [
      for (final tag in suggestions)
        if (!note.tags.contains(tag)) tag,
    ];
    final t = triage;
    final folderId = t?.folderId;
    final askReminder = (t?.needsReminder ?? false) && note.reminderAt == null;
    if (suggestions.isEmpty && folderId == null && !askReminder) {
      return;
    }
    final selected = await showAppSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Wrap(
            spacing: 8,
            children: [
              for (final tag in suggestions)
                actionChip(ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => Navigator.pop(sheetContext, tag),
                )),
              if (folderId != null)
                actionChip(ActionChip(
                  key: const ValueKey('triage-folder'),
                  label: Text('${l10n.moveToFolder}: ${folders[folderId]}'),
                  onPressed: () =>
                      Navigator.pop(sheetContext, _TriagePick.folder),
                )),
              if (askReminder)
                actionChip(ActionChip(
                  key: const ValueKey('triage-reminder'),
                  label: Text(l10n.quickRowReminder),
                  onPressed: () =>
                      Navigator.pop(sheetContext, _TriagePick.reminder),
                )),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (selected) {
      case String tag:
        _mutate(
          (n) => n.copyWith(tags: {...n.tags, tag}.toList()),
          immediate: true,
        );
      case _TriagePick.folder:
        _mutate((n) => n.copyWith(folderId: folderId), immediate: true);
      case _TriagePick.reminder:
        await _pickReminder();
    }
  }

  String _cleanTag(String raw) =>
      raw.trim().replaceAll('#', '').replaceAll(' ', '-').toLowerCase();

  void _applyTag(String cleaned) {
    if (cleaned.isEmpty) return;
    _mutate(
      (n) => n.copyWith(tags: {...n.tags, cleaned}.toList()),
      immediate: true,
    );
  }
}

/// DA-2 öneri çipleri (etiket dışındakiler).
enum _TriagePick { folder, reminder }
