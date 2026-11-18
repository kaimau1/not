part of 'note_editor_screen.dart';

/// AI işleri: başlık/etiket önerisi, arka plan etiketleme, meşgul göstergesi.
///
/// F9.3: editör konu başına bölündü; durum (alanlar) [_NoteEditorScreenState]da kalır.
extension _EditorAi on _NoteEditorScreenState {
  /// Uzun süren DOSYA işlerinin ortak sarmalayıcısı: şeritteki göstergeyi
  /// açar/kapatır. AI'nın [_runAi]'ı ile aynı desen; hata yönetimi çağırana
  /// bırakılır (her işin kendi anlamlı mesajı var).
  Future<T> _runBusy<T>(String label, Future<T> Function() body) async {
    _busyTaskN.value = label;
    try {
      return await body();
    } finally {
      if (mounted) _busyTaskN.value = null;
    }
  }

  /// Uzun süren AI işlerinin TEK giriş noktası: göstergeyi açar/kapatır,
  /// hataları tek biçimde bildirir. Yeni bir AI özelliği eklenirken
  /// göstergeyi ayrıca düşünmek gerekmesin diye burada toplandı.
  Future<void> _runAi(String label, Future<void> Function() body) async {
    if (_aiTask != null || !ensureAiReady(context, ref)) return;
    _aiTaskN.value = label;
    try {
      await body();
    } on GeminiException catch (e) {
      if (mounted) {
        _showSnack(
          aiErrorText(context.l10n, e),
        );
      }
    } catch (e) {
      if (mounted) _showSnack(aiErrorText(context.l10n, e));
    } finally {
      if (mounted) _aiTaskN.value = null;
    }
  }

  /// Ayarlarda açıksa, editör kapanırken etiketsiz notu arka planda
  /// AI ile etiketler.
  void _autoTagInBackground(Note note) {
    if (note.toPlainText().length < 20) return;
    if (!_autoTagEnabled) return;
    final service = _gemini;
    final repo = _notesRepo;
    if (repo == null || service == null) return;
    Future(() async {
      try {
        final tags = await service.suggestTags(note);
        if (tags.isNotEmpty) repo.updateFields(note.id, {'tags': tags});
      } catch (_) {
        // Anahtar yoksa veya istek başarısızsa sessizce geç.
      }
    });
  }

  /// Editör kapanırken başlıksız kalan nota arka planda AI başlık yazar
  /// (Ayarlar > Yapay Zeka > "Kapatırken başlık öner", varsayılan açık).
  /// "Başlık öner" çipiyle aynı üreticiyi kullanır; akışı kesmez.
  void _autoTitleInBackground(Note note) {
    if (note.isEmpty || !_autoTitleEnabled) return;
    final service = _gemini;
    final repo = _notesRepo;
    if (repo == null || service == null) return;
    Future(() async {
      try {
        final title = await service.generateTitle(note);
        if (title.isNotEmpty) repo.updateFields(note.id, {'title': title});
      } catch (_) {
        // Kota/anahtar hatasında sessizce geç — başlıksız kalması sorun değil.
      }
    });
  }

  /// "Başlık öner" çipi: nota AI ile kısa bir başlık üretir ve doğrudan
  /// başlık alanına yazar (etiket önerisi gibi bağımsız, isteğe bağlı buton;
  /// eski "kapanırken otomatik başlık" genel ayarının yerini aldı).
  Future<void> _suggestTitle() async {
    if (!ensureAiReady(context, ref)) return;
    final note = _note;
    if (note == null || note.isEmpty || _titleGeneratingN.value) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    _titleGeneratingN.value = true;
    try {
      final title = await ref.read(geminiServiceProvider).generateTitle(note);
      if (!mounted || title.isEmpty) return;
      _titleController.text = title;
      _mutate((n) => n.copyWith(title: title), immediate: true);
    } on GeminiException catch (e) {
      messenger.showMessage(
        aiErrorText(l10n, e),
      );
    } finally {
      if (mounted) _titleGeneratingN.value = false;
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

  /// AI'dan etiket önerisi al ve seçtir.
  ///
  /// DA-2 (plan_decisions_api, bayrak `noteTriage`): tek Decisions
  /// çağrısında kullanıcının KENDİ etiketleri (çoklu evet/hayır) + klasör +
  /// "başlık gerekli mi" + "hatırlatıcı gerekli mi". Hepsi yalnız ÖNERİ
  /// çipi; dokunulmadan hiçbir şey uygulanmaz. Etiket eşiği geçen yoksa
  /// bugünkü üretken öneri; bayrak kapalı/yanıtsızsa bugünkü yol AYNEN.
  Future<void> _suggestTags() async {
    final note = _note;
    if (note == null || note.isEmpty) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final decisions = ref.read(decisionServiceProvider);
    // Kilitli not hiçbir karar girdisine girmez (K7).
    final mode = note.locked
        ? DecisionMode.off
        : decisions.modeOf(DecisionFeature.noteTriage);
    final folders = mode == DecisionMode.off
        ? const <String, String>{}
        : _triageFolders(note);
    // ponytail: alfabetik ilk 30; kullanım sıklığı ölçüm gösterirse.
    final ownTags = [
      for (final t in ref.read(allTagsProvider))
        if (!note.tags.contains(t)) t,
    ];
    // Etiket önerisi de görünür olsun: eskiden istek boyunca hiçbir belirti
    // yoktu, kullanıcı düğmeye ikinci kez basıyordu.
    List<String> suggestions = const [];
    TriageSuggestion? triage;
    var failed = false;
    await _runAi(l10n.aiThinking, () async {
      final pending = mode == DecisionMode.off
          ? null
          : decideNoteTriage(
              decisions,
              title: note.title,
              text: note.toPlainText(),
              tags: ownTags,
              folders: folders,
            );
      if (mode == DecisionMode.live) triage = await pending;
      if (triage?.tags.isNotEmpty ?? false) {
        suggestions = triage!.tags;
        return;
      }
      try {
        suggestions = await ref.read(geminiServiceProvider).suggestTags(note);
      } on GeminiException catch (e) {
        failed = true;
        messenger.showMessage(
          aiErrorText(l10n, e),
        );
      }
      if (mode == DecisionMode.shadow) {
        final old = suggestions;
        unawaited(
          pending!.then(
            (t) => DecisionService.logShadow(
              DecisionFeature.noteTriage,
              t == null
                  ? 'none'
                  : 'tags=${t.tags.length} overlap='
                        '${t.tags.where(old.contains).length}/${old.length} '
                        'folder=${t.folderId != null} title=${t.needsTitle} '
                        'reminder=${t.needsReminder}',
            ),
          ),
        );
      }
    });
    if (!mounted || (failed && (triage?.isEmpty ?? true))) return;
    suggestions = [
      for (final tag in suggestions)
        if (!note.tags.contains(tag)) tag,
    ];
    final t = triage;
    final folderId = t?.folderId;
    final askTitle = (t?.needsTitle ?? false) && note.title.trim().isEmpty;
    final askReminder = (t?.needsReminder ?? false) && note.reminderAt == null;
    if (suggestions.isEmpty &&
        folderId == null &&
        !askTitle &&
        !askReminder) {
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
              if (askTitle)
                actionChip(ActionChip(
                  key: const ValueKey('triage-title'),
                  label: Text(l10n.suggestTitle),
                  onPressed: () =>
                      Navigator.pop(sheetContext, _TriagePick.title),
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
      case _TriagePick.title:
        await _suggestTitle();
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
enum _TriagePick { folder, title, reminder }
