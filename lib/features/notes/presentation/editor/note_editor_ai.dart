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
    if (_aiTask != null) return;
    _aiTaskN.value = label;
    try {
      await body();
    } on GeminiException catch (e) {
      if (mounted) {
        _showSnack(
          e.isAuthError
              ? context.l10n.aiNoApiKey
              : context.l10n.aiError(e.message),
        );
      }
    } catch (e) {
      if (mounted) _showSnack(context.l10n.aiError('$e'));
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
        e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
      );
    } finally {
      if (mounted) _titleGeneratingN.value = false;
    }
  }

  /// AI'dan etiket önerisi al ve seçtir.
  Future<void> _suggestTags() async {
    final note = _note;
    if (note == null || note.isEmpty) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    // Etiket önerisi de görünür olsun: eskiden istek boyunca hiçbir belirti
    // yoktu, kullanıcı düğmeye ikinci kez basıyordu.
    List<String> suggestions = const [];
    var failed = false;
    await _runAi(l10n.aiThinking, () async {
      try {
        suggestions = await ref.read(geminiServiceProvider).suggestTags(note);
      } on GeminiException catch (e) {
        failed = true;
        messenger.showMessage(
          e.isAuthError ? l10n.aiNoApiKey : l10n.aiError(e.message),
        );
      }
    });
    if (failed || !mounted) return;
    suggestions = [
      for (final tag in suggestions)
        if (!note.tags.contains(tag)) tag,
    ];
    if (suggestions.isEmpty || !mounted) return;
    final selected = await showAppSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Wrap(
            spacing: 8,
            children: [
              for (final tag in suggestions)
                ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => Navigator.pop(sheetContext, tag),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      _mutate(
        (n) => n.copyWith(tags: {...n.tags, selected}.toList()),
        immediate: true,
      );
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
